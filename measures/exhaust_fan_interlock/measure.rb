# see the URL below for information on how to write OpenStudio measures
# http://nrel.github.io/OpenStudio-user-documentation/measures/measure_writing_guide/

# start the measure
class ExhaustFanInterlock < OpenStudio::Ruleset::ModelUserScript

  # human readable name
  def name
    return "Exhaust Fan Interlock"
  end

  # human readable description
  def description
    return "Exhaust fans that are not aligned with schedule of operations of the companion supply fan can impact the airflows of central air handlers by decreasing the flow of return air and sometimes increasing the outdoor air flow rate. A common operational practice is to interlock (or align) the operations of any exhaust fans with the companion system used to condition and pressurize a space. This measure examines all Fan:ZoneExhaust objects present in a model and coordinates the availability of the exhaust fan with the system supply fan. "
  end

  # human readable description of modeling approach
  def modeler_description
    return "For any thermal zones having zone equipment objects of type Fan:ZoneExhaust, this energy efficiency measure (EEM) maps the schedule used to define the availability of the associated Air Loop to the Availability Schedule attribute of the zone exhaust fan object. "
  end

  # define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    # Make integer arg to run measure [1 is run, 0 is no run]
    run_measure = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("run_measure",true)
    run_measure.setDisplayName("Run Measure")
    run_measure.setDescription("integer argument to run measure [1 is run, 0 is no run]")
    run_measure.setDefaultValue(1)
    args << run_measure
    
    return args
  end

  # define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    # use the built-in error checking
    if !runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end
	
    # Return N/A if not selected to run
    run_measure = runner.getIntegerArgumentValue("run_measure",user_arguments)
    if run_measure == 0
      runner.registerAsNotApplicable("Run Measure set to #{run_measure}.")
      return true     
    end  
  
	# assigning the arrays
	air_loops_array =[]
	fan_exhaust_array = []
	changed_sch_array_true = []
	changed_sch_array_false = []
	
	# Get all airloops in model and populate an array
	@all_airloops = model.getAirLoopHVACs   
	air_loops_array << @all_airloops
	#Loop through all airloops in model 
	@all_airloops.each do |loop| 
		# Retrieve the existing availability schedule for the airloop
		@airloops_availability_sch = loop.availabilitySchedule 
		# Retrieve all thermal zones associated with a single airloop
		@thermal_zones = loop.thermalZones 
		# Loop through each thermal zone
		@thermal_zones.each do |eqip_zn| 
			# Retrieve ZoneHVACEquipment objects attached to the thermal zone
			@thermal_zones_equipment = eqip_zn.equipment # zone equipments assigned to thermal zones
			@thermal_zones_equipment.each do |exh_fan|
				# Check to see if ZoneHVACEquipment object type = Exhaust Fan, if so map to variable and store in object array
				if exh_fan.to_FanZoneExhaust.is_initialized
					@fan_exhaust = exh_fan.to_FanZoneExhaust.get  
					fan_exhaust_array << @fan_exhaust				
					# Check to see if Exhaust Fan Object has an availability schedule already defined
					if @fan_exhaust.availabilitySchedule.is_initialized
						fan_exh_avail_sch = @fan_exhaust.availabilitySchedule.get 
						#Set availability schedule for current fan exhaust object. NOTE: boolean set method returns true if successful
						changed_sch = @fan_exhaust.setAvailabilitySchedule(@airloops_availability_sch) 
						runner.registerInfo("Availability Schedule for OS:FanZoneExhaust named: '#{@fan_exhaust.name}' has been changed to '#{@airloops_availability_sch.name}' from '#{fan_exh_avail_sch.name}'.")
						if changed_sch == true 
							changed_sch_array_true << changed_sch
						elsif  
							changed_sch_array_false << changed_sch
						end
					end #end fan exhaust availability if loop
				end  # end fan exhaust 
			end # end loop through zone HVAC equipment objects
		end	# end loop through thermal zones
	end	# end loop through airloops
	
	# not applicable message if there is no airloop or zone exhaust equipment
	if
		fan_exhaust_array.length == 0 or air_loops_array.length == 0
		runner.registerAsNotApplicable("Measure is not applicable.")
		return true
	end #end the not applicable if condition	

		
    # report initial condition of model
    runner.registerInitialCondition("The initial model contained #{fan_exhaust_array.length} 'Fan:ZoneExhaust' object for which this measure is applicable.")

    # report final condition of model
    runner.registerFinalCondition("The Availability Schedules for #{changed_sch_array_true.length} 'Fan:ZoneExhaust' schedule(s) were altered to match the availability schedules of supply fans. The number of unchanged 'Fan: ZoneExhaust' object(s) = #{changed_sch_array_false.length}.")
    return true

  end # end run method
  
end # end class 

# register the measure to be used by the application
ExhaustFanInterlock.new.registerWithApplication
