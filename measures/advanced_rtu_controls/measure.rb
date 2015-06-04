#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see your EnergyPlus installation or the URL below for information on EnergyPlus objects
# http://apps1.eere.energy.gov/buildings/energyplus/pdfs/inputoutputreference.pdf

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on workspace objects (click on "workspace" in the main window to view workspace objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/utilities/html/idf_page.html

#start the measure
class AdvancedRTUControls < OpenStudio::Ruleset::WorkspaceUserScript

  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "AdvancedRTUControls"
  end

  #define the arguments that the user will input
  def arguments(workspace)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(workspace, runner, user_arguments)
    super(workspace, runner, user_arguments)

    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(workspace), user_arguments)
      return false
    end
   
     #get all emsProgram in model
#    emsProgram = workspace.getObjectsByType("EnergyManagementSystem:Program".to_IddObjectType)

  #  if emsProgram.size == 0
  #    runner.registerAsNotApplicable("The model does not contain any emsProgram. The model will not be altered.")
  #    return true
  #  end

require 'openstudio'
require 'json'
translator = OpenStudio::OSVersion::VersionTranslator.new
path = OpenStudio::Path.new(File.dirname(__FILE__) + "/SmallOffice_90_1-2010.osm")
#path = OpenStudio::Path.new(File.dirname(__FILE__) + "/SmallOffice_DOE Ref 1980-2004.osm")
#path = OpenStudio::Path.new(File.dirname(__FILE__) + "/SmallOffice_DOE Ref Pre-1980.osm")
model = translator.loadModel(path)
model = model.get
#always_on = model.alwaysOnDiscreteSchedule
results = {}
airloop_name = []
# get the cooling coil and fan from a unitary heatpump

model.getAirLoopHVACs.each do |air_loop|
  found_coil = 0  #have not found any cooling coils
  found_hcoil = 0  #have not found any heating coils
  found_fan = 0   #have not found any fans 
  temp = {}
  air_loop.supplyComponents.each do |component|
    # Get the unitary equipment
    if component.to_AirLoopHVACUnitaryHeatPumpAirToAir.is_initialized
      unitary = component.to_AirLoopHVACUnitaryHeatPumpAirToAir.get
      # Get the cooling coil from inside the unitary equipment
      clg_coil = unitary.coolingCoil
      if clg_coil.to_CoilCoolingDXSingleSpeed.is_initialized
        clg_coil = clg_coil.to_CoilCoolingDXSingleSpeed.get
        puts "Found #{clg_coil.name} on #{air_loop.name}"
        found_coil += 1  #found necessary cooling coil DX singlespeed
        temp[:cool_coil] = "#{clg_coil.name}"
      end
      # get heating coil
      htg_coil = unitary.heatingCoil
      if htg_coil.to_CoilHeatingDXSingleSpeed.is_initialized
        puts "Found #{htg_coil.name} on #{air_loop.name}"
        found_hcoil += 1  #found necessary cooling coil DX singlespeed
        temp[:heat_coil] = "#{htg_coil.name}"
      end
      # get the supply fan from inside the unitary equipment
      supply_fan = unitary.supplyAirFan
      if supply_fan.to_FanConstantVolume.is_initialized
        supply_fan = supply_fan.to_FanConstantVolume.get
        puts "Found #{supply_fan.name} on #{air_loop.name}"
        found_fan += 1  #found necessary Fan object
        temp[:fan] = "#{supply_fan.name}"
      elsif supply_fan.to_FanOnOff.is_initialized
        supply_fan = supply_fan.to_FanOnOff.get
        puts "Found #{supply_fan.name} on #{air_loop.name}"
        found_fan += 1  #found necessary Fan object
        temp[:fan] = "#{supply_fan.name}"
      else
        puts "No OnOff or Constant Volume Fan in the Unitary system on #{air_loop.name}"      
      end
    end
    # Get the cooling coil directly from the airloop
    if component.to_CoilCoolingDXSingleSpeed.is_initialized
      clg_coil = component.to_CoilCoolingDXSingleSpeed.get
      puts "Found #{clg_coil.name} on #{air_loop.name}"
      found_coil += 1  #found necessary cooling coil DX singlespeed
      temp[:cool_coil] = "#{clg_coil.name}"
    end
    # Get the heating coil directly from the airloop
    if component.to_CoilHeatingDXSingleSpeed.is_initialized
      htg_coil = component.to_CoilHeatingDXSingleSpeed.get
      puts "Found #{htg_coil.name} on #{air_loop.name}"
      found_hcoil += 1  #found necessary heating coil DX singlespeed
      temp[:heat_coil] = "#{htg_coil.name}"
    end
    # Get the heating coil directly from the airloop
    if component.to_CoilHeatingGas.is_initialized
      htg_coil = component.to_CoilHeatingGas.get
      puts "Found #{htg_coil.name} on #{air_loop.name}"
      found_hcoil += 1  #found necessary heating coil gas
      temp[:heat_coil] = "#{htg_coil.name}"
    end
    # Get the heating coil directly from the airloop
    if component.to_CoilHeatingElectric.is_initialized
      htg_coil = component.to_CoilHeatingElectric.get
      puts "Found #{htg_coil.name} on #{air_loop.name}"
      found_hcoil += 1  #found necessary heating coil gas
      temp[:heat_coil] = "#{htg_coil.name}"
    end
    # get the supply fan directly from the airloop
    if component.to_FanConstantVolume.is_initialized
      supply_fan = component.to_FanConstantVolume.get
      puts "Found #{supply_fan.name} on #{air_loop.name}"
      found_fan += 1  #found necessary Fan object
      temp[:fan] = "#{supply_fan.name}"
    end
    if component.to_FanOnOff.is_initialized
      supply_fan = component.to_FanOnOff.get
      puts "Found #{supply_fan.name} on #{air_loop.name}"
      found_fan += 1  #found necessary Fan object
      temp[:fan] = "#{supply_fan.name}"
    end
  end
  puts "airloop #{air_loop.name} found = #{(found_coil + found_fan)} \n"
  found_oa = 0
  found_act = 0
  found_oasch = 0
  found_oafsch = 0
  #found too many objects on an airloop
  if (found_coil + found_hcoil + found_fan) > 3
    puts "Too many objects on airloop #{air_loop.name}. Airloop N/A"
  #found a Fan and Cooling Coil DX Single Speed, get rest of info
  elsif (found_coil + found_hcoil + found_fan) < 3
    puts "Not enough objects on airloop #{air_loop.name}. Airloop N/A"
  elsif (found_coil + found_hcoil + found_fan) == 3 
      # get outdoorair controller
      if air_loop.airLoopHVACOutdoorAirSystem.is_initialized
        controller_oa = air_loop.airLoopHVACOutdoorAirSystem.get.getControllerOutdoorAir
        puts "Found #{controller_oa.name} on #{air_loop.name}"
        found_oa += 1 #found necessary OA controller
        temp[:controller_oa] = "#{controller_oa.name}"
        # get actuator node name
        actuatorNodeName = air_loop.airLoopHVACOutdoorAirSystem.get.outboardOANode.get.name.get
        puts "Found #{actuatorNodeName} on #{air_loop.name}" 
        found_act += 1  #found necessary actuator node
        temp[:actuatorNodeName] = "#{actuatorNodeName}"
        # get minimumFractionofOutdoorAirSchedule
        minimumFractionofOutdoorAirSchedule = controller_oa.minimumFractionofOutdoorAirSchedule
        # get minimumOutdoorAirSchedule
        minimumOutdoorAirSchedule = controller_oa.minimumOutdoorAirSchedule
        if minimumFractionofOutdoorAirSchedule.is_initialized && minimumOutdoorAirSchedule.is_initialized
          puts "Both minimumOutdoorAirSchedule and minimumFractionofOutdoorAirSchedule in Airloop #{air_loop.name} are missing."
        end
        if minimumFractionofOutdoorAirSchedule.is_initialized
          puts "Found #{minimumFractionofOutdoorAirSchedule.get.name} on #{air_loop.name}"
          found_oafsch += 1 #found necessary fraction OA schedule
          temp[:minimumFractionofOutdoorAirSchedule] = "#{minimumFractionofOutdoorAirSchedule.get.name}"
        else
          always_on = model.alwaysOnDiscreteSchedule
          controller_oa.setMinimumFractionofOutdoorAirSchedule(always_on)
          puts "Added #{controller_oa.minimumFractionofOutdoorAirSchedule.get.name} on #{air_loop.name}"
          found_oafsch += 1  #added necessary fraction OA schedule
          temp[:minimumFractionofOutdoorAirSchedule] = "#{controller_oa.minimumFractionofOutdoorAirSchedule.get.name}"
        end
        if minimumOutdoorAirSchedule.is_initialized
          puts "Found #{minimumOutdoorAirSchedule.get.name} on #{air_loop.name}"
          found_oasch += 1 #found necessary OA schedule
          temp[:minimumOutdoorAirSchedule] = "#{minimumOutdoorAirSchedule.get.name}"
        else
          always_on = model.alwaysOnDiscreteSchedule
          controller_oa.setMinimumOutdoorAirSchedule(always_on) 
          puts "Added #{controller_oa.minimumOutdoorAirSchedule.get.name} on #{air_loop.name}"
          found_oasch += 1 #added necessary OA schedule
          temp[:minimumOutdoorAirSchedule] = "#{controller_oa.minimumOutdoorAirSchedule.get.name}"
        end
      end
      if (found_oasch + found_oafsch + found_act + found_oa) == 4  #add valid air loop to results
        results["#{air_loop.name}"] = temp
        airloop_name << "#{air_loop.name}"
        puts "Adding valid AirLoop #{air_loop.name} to results. \n"
      end  
  end
end

#results[results.keys[1].to_s][:cool_coil]  

ems_string = ""

ems_string << "EnergyManagementSystem:GlobalVariable," + "\n"
ems_string << " FanPwrExp,  ! Exponent used in fan power law" + "\n"
ems_string << " Stage1Speed,  ! Fan speed in cooling mode" + "\n"
ems_string << " HeatSpeed,    ! Fan speed in heating mode" + "\n"
ems_string << " VenSpeed,   ! Fan speed in ventilation mode" + "\n"
ems_string << " EcoSpeed; ! Fan speed in economizer mode" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:Program," + "\n"
ems_string << " Set_FanCtl_Par1," + "\n"
ems_string << " SET FanPwrExp = 2.2," + "\n"
ems_string << " SET HeatSpeed = 0.9," + "\n"
ems_string << " SET VenSpeed = 0.4," + "\n"
ems_string << " SET Stage1Speed = 0.9," + "\n"
ems_string << " SET EcoSpeed = 0.75;" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:Program," + "\n"
ems_string << " Set_FanCtl_Par2," + "\n"

results.each_with_index do |(key, value), i|  
  if i < results.size - 1
  ems_string << " SET PSZ#{i}_OADesignMass = PSZ#{i}_DesignFlowMass," + "\n"
  else
  ems_string << " SET PSZ#{i}_OADesignMass = PSZ#{i}_DesignFlowMass;" + "\n"
  end
end

ems_string << "\n"
ems_string << "EnergyManagementSystem:ProgramCallingManager," + "\n"
ems_string << " Fan_Parameter_manager,  !- Name" + "\n"
ems_string << " BeginNewEnvironment,  !- EnergyPlus Model Calling Point" + "\n"
ems_string << " Set_FanCtl_Par1,        !- Program Name 1" + "\n"
ems_string << " Set_FanCtl_Par2;        !- Program Name 1" + "\n"
ems_string << "\n"

results.each_with_index do |(key, value), i|
ems_string << "EnergyManagementSystem:InternalVariable," + "\n"
ems_string << " PSZ#{i}_DesignFlowMass, !- Name " + "\n"
ems_string << " #{value[:controller_oa]}, !- Internal Data Index Key Name" + "\n"
ems_string << " Outdoor Air Controller Minimum Mass Flow Rate; !- Internal Data Type" + "\n"
ems_string << "\n"
end

results.each_with_index do |(key, value), i|
ems_string << "EnergyManagementSystem:InternalVariable," + "\n"
ems_string << " PSZ#{i}_FanDesignPressure, !- Name " + "\n"
ems_string << " #{value[:fan]}, !- Internal Data Index Key Name" + "\n"
ems_string << " Fan Nominal Pressure Rise; !- Internal Data Type" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:InternalVariable," + "\n"
ems_string << " PSZ#{i}_DesignFlowMass, !- Name " + "\n"
ems_string << " #{value[:controller_oa]}, !- Internal Data Index Key Name" + "\n"
ems_string << " Outdoor Air Controller Maximum Mass Flow Rate; !- Internal Data Type" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:Sensor," + "\n"
ems_string << " PSZ#{i}_OASch," + "\n"
ems_string << " #{value[:minimumOutdoorAirSchedule]}," + "\n"
ems_string << " Schedule Value;" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:Sensor," + "\n"
ems_string << " PSZ#{i}_OAFracSch," + "\n"
ems_string << " #{value[:minimumFractionofOutdoorAirSchedule]}," + "\n"
ems_string << " Schedule Value;" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:Sensor," + "\n"
ems_string << " PSZ#{i}_OAFlowMass," + "\n"
ems_string << " #{value[:actuatorNodeName]}," + "\n"
ems_string << " System Node Mass Flow Rate;" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:Sensor," + "\n"
ems_string << " PSZ#{i}_HtgRTF," + "\n"
ems_string << " #{value[:heat_coil]}," + "\n"
ems_string << " Heating Coil Runtime Fraction;" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:Sensor," + "\n"
ems_string << " PSZ#{i}_ClgRTF," + "\n"
ems_string << " #{value[:cool_coil]}," + "\n"
ems_string << " Cooling Coil Runtime Fraction;" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:Actuator," + "\n"
ems_string << " PSZ#{i}_FanPressure, ! Name " + "\n"
ems_string << " #{value[:fan]}, ! Actuated Component Unique Name" + "\n"
ems_string << " Fan, ! Actuated Component Type" + "\n"
ems_string << " Fan Pressure Rise; ! Actuated Component Control Type" + "\n"
ems_string << "\n"
end

results.each_with_index do |(key, value), i|
ems_string << "EnergyManagementSystem:Program," + "\n"
ems_string << " PSZ#{i}_FanControl,        !- Name" + "\n"
ems_string << " IF PSZ#{i}_HtgRTF > 0," + "\n"
ems_string << "  SET PSZ#{i}_Htg = PSZ#{i}_HtgRTF,      ! Percent of time in heating mode" + "\n"
ems_string << "  SET PSZ#{i}_Ven = 1 - PSZ#{i}_HtgRTF,  ! Percent of time in ventilation mode" + "\n"
ems_string << "  SET PSZ#{i}_Eco = 0,       ! Percent of time in economizer mode" + "\n"
ems_string << "  SET PSZ#{i}_Stage1 = 0,    ! Percent of time in DX cooling" + "\n"
ems_string << " ELSE," + "\n"
ems_string << "  SET PSZ#{i}_Htg = 0," + "\n"
ems_string << "  SET PSZ#{i}_MinOA1 = PSZ#{i}_OADesignMass * PSZ#{i}_OASch," + "\n"
ems_string << "  SET PSZ#{i}_MinOA2 = PSZ#{i}_DesignFlowMass * PSZ#{i}_OAFracSch," + "\n"
ems_string << "  SET PSZ#{i}_MinOA = @Max PSZ#{i}_MinOA1 PSZ#{i}_MinOA2,  " + "\n"
ems_string << "  IF  PSZ#{i}_ClgRTF > 0,    ! Mechanical cooling is on" + "\n"
ems_string << "   SET PSZ#{i}_Stage1 = PSZ#{i}_ClgRTF," + "\n"
ems_string << "   IF PSZ#{i}_OAFlowMass > PSZ#{i}_MinOA,  ! Integrated Economzing mode" + "\n"
ems_string << "    SET PSZ#{i}_Eco = 1-PSZ#{i}_ClgRTF,  " + "\n"
ems_string << "    SET PSZ#{i}_Ven = 0," + "\n"
ems_string << "   ELSE," + "\n"
ems_string << "    SET PSZ#{i}_Eco = 0," + "\n"
ems_string << "    SET PSZ#{i}_Ven = 1-PSZ#{i}_ClgRTF," + "\n"
ems_string << "   ENDIF," + "\n"
ems_string << "  ELSE,               ! Mechanical cooling is off" + "\n"
ems_string << "   SET PSZ#{i}_Stage1 = 0, " + "\n"
ems_string << "   IF PSZ#{i}_OAFlowMass > PSZ#{i}_MinOA,  ! Economizer mode" + "\n"
ems_string << "    SET PSZ#{i}_Eco = 1.0," + "\n"
ems_string << "    SET PSZ#{i}_Ven = 0," + "\n"
ems_string << "   ELSE," + "\n"
ems_string << "    SET PSZ#{i}_Eco = 0," + "\n"
ems_string << "    SET PSZ#{i}_Ven = 1.0," + "\n"
ems_string << "   ENDIF," + "\n"
ems_string << "  ENDIF," + "\n"
ems_string << " ENDIF," + "\n"
ems_string << "\n"
ems_string << " ! For each mode, (percent time in mode) * (fanSpeed^PwrExp) is the contribution to weighted fan power over time step" + "\n"
ems_string << " SET PSZ#{i}_FPR = PSZ#{i}_Ven * (VenSpeed ^ FanPwrExp)," + "\n"
ems_string << " SET PSZ#{i}_FPR = PSZ#{i}_FPR + PSZ#{i}_Eco * (EcoSpeed ^ FanPwrExp)," + "\n"
ems_string << " SET PSZ#{i}_FPR1 = PSZ#{i}_Stage1 * (Stage1Speed ^ FanPwrExp)," + "\n"
ems_string << " SET PSZ#{i}_FPR = PSZ#{i}_FPR + PSZ#{i}_FPR1," + "\n"
ems_string << " SET PSZ#{i}_FPR3 = PSZ#{i}_Htg * (HeatSpeed ^ FanPwrExp)," + "\n"
ems_string << " SET PSZ#{i}_FanPwrRatio = PSZ#{i}_FPR +  PSZ#{i}_FPR3," + "\n"
ems_string << "\n"
ems_string << "! System fan power is directly proportional to static pressure, so this change linearly adjusts fan energy for speed control" + "\n"
ems_string << " SET PSZ#{i}_FanPressure = PSZ#{i}_FanDesignPressure * PSZ#{i}_FanPwrRatio;" + "\n"
ems_string << "\n"
ems_string << "EnergyManagementSystem:ProgramCallingManager," + "\n"
ems_string << " PSZ#{i}_Fan_Manager,   !- Name" + "\n"
ems_string << " BeginTimestepBeforePredictor,  !- EnergyPlus Model Calling Point" + "\n"
ems_string << " PSZ#{i}_FanControl;        !- Program Name 1" + "\n"
ems_string << "\n"
end

File.open("ems_1", "w") do |f|
  f.write(ems_string)
end
    #unique initial conditions based on
    # removed listing ranges for variable values since we are editing multiple fields vs. a single field.
    runner.registerInitialCondition("The building has #{emsProgram.size} EMS objects.")

    #reporting final condition of model
    runner.registerFinalCondition("The building finished with #{emsProgram.size} EMS objects.")
    #runner.registerValue("m value", mValue, "")
    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
AdvancedRTUControls.new.registerWithApplication