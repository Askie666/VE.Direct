#Version 8.81 Autor: Askie (31.08.2020)
#########################################################################
# fhem Modul fuer Victron VE.Direct Hex-Protokoll
#  
# general rebuild
# ToDo: in den Specialsetget-Werten die "bitwise" werte einpflegen

package main;

use strict;                          #
##use warnings;                        #
use Time::HiRes qw(gettimeofday);    #
use Scalar::Util qw(looks_like_number);
use DevIo;
use GPUtils qw(:all);

my %startBlock = (
"BMV"=>"\r\nH1|\r\nPID",
"MPPT"=>"\r\nPID",
"Inverter"=>"\r\nPID"
);


#########################################################################
#Key: "Register-ID"=>"Bezeichnung,Einheit,Skalierung/Bit,L?ngePayload(nibbles),min,max,zyklisch abfragen, getConfigAll, BMV,MPPT,Inverter,specialset/getValues,setGetItems",my %Register = ("0x0004"=>"Restore_default?-?-?-?-?-?000?000?-*-?-*-?-*-?-",
my %BMV = (
"0x0100"=>{"Bezeichnung"=>"PID", "ReadingName"=>"Devicetype_PID", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"PID:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0300"=>{"Bezeichnung"=>"Depth of the deepest discharge", "ReadingName"=>"Depth_of_the_deepest_discharge", "Einheit"=>"Ah", "Skalierung"=>"0.1", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Depth_of_the_deepest_discharge:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0301"=>{"Bezeichnung"=>"Depth of the last discharge", "ReadingName"=>"Depth_of_the_last_discharge", "Einheit"=>"Ah", "Skalierung"=>"0.1", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Depth_of_the_last_discharge:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0302"=>{"Bezeichnung"=>"Depth of the average discharge", "ReadingName"=>"Depth_of_the_averag_discharge", "Einheit"=>"Ah", "Skalierung"=>"0.1", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Depth_of_the_average_discharge:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0303"=>{"Bezeichnung"=>"Number of cycles", "ReadingName"=>"Number_of_cycles", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_cycles:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0304"=>{"Bezeichnung"=>"Number of full discharges", "ReadingName"=>"Number_of_full discharges", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_full_discharges:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0305"=>{"Bezeichnung"=>"Cumulative Amp Hours", "ReadingName"=>"Cumulative_Amp_Hours", "Einheit"=>"Ah", "Skalierung"=>"0.1", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Cumulative_Amp_Hours:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0306"=>{"Bezeichnung"=>"Minimum Voltage", "ReadingName"=>"Minimum_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Minimum_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0307"=>{"Bezeichnung"=>"Maximum Voltage", "ReadingName"=>"Maximum_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Maximum_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0308"=>{"Bezeichnung"=>"Seconds since full charge", "ReadingName"=>"Seconds_since_full_charge", "Einheit"=>"s", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Seconds_since_full_charge:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0309"=>{"Bezeichnung"=>"Number of automatic synchronizations", "ReadingName"=>"Number_of_automatic_synchronizations", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_automatic_synchronizations:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x030A"=>{"Bezeichnung"=>"Number of Low Voltage Alarms", "ReadingName"=>"Number_of_Low_Voltage_Alarms", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_Low_Voltage_Alarms:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x030B"=>{"Bezeichnung"=>"Number of High Voltage Alarms", "ReadingName"=>"Number_of_High_Voltage_Alarms", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_High_Voltage_Alarms:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x030E"=>{"Bezeichnung"=>"Minimum Starter Voltage", "ReadingName"=>"Minimum_Starter_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Minimum_Starter_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x030F"=>{"Bezeichnung"=>"Maximum Starter Voltage", "ReadingName"=>"Maximum_Starter_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Maximum_Starter_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0310"=>{"Bezeichnung"=>"Amount of discharged energy", "ReadingName"=>"Amount_of_discharged_energy", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Amount_of_discharged_energy:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0311"=>{"Bezeichnung"=>"Amount of charged energy", "ReadingName"=>"Amount_of_charged_energy", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Amount_of_charged_energy:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0320"=>{"Bezeichnung"=>"ALARM_LOW_VOLTAGE_SET", "ReadingName"=>"ALARM_LOW_VOLTAGE_SET", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"ALARM_LOW_VOLTAGE_SET:noArg", "setValues"=>"ALARM_LOW_VOLTAGE_SET", "spezialSetGet"=>"-"},
"0x0321"=>{"Bezeichnung"=>"ALARM_LOW_VOLTAGE_CLEAR", "ReadingName"=>"ALARM_LOW_VOLTAGE_CLEAR", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"ALARM_LOW_VOLTAGE_CLEAR:noArg", "setValues"=>"ALARM_LOW_VOLTAGE_CLEAR", "spezialSetGet"=>"-"},
"0x0322"=>{"Bezeichnung"=>"Alarm High Voltage", "ReadingName"=>"Alarm_High_Voltage", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Voltage:noArg", "setValues"=>"Alarm_High_Voltage:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0323"=>{"Bezeichnung"=>"Alarm High Voltage Clear", "ReadingName"=>"Alarm_High_Voltage_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Voltage_Clear:noArg", "setValues"=>"Alarm_High_Voltage_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0324"=>{"Bezeichnung"=>"Alarm Low Starter", "ReadingName"=>"Alarm_Low_Starter", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_Starter:noArg", "setValues"=>"Alarm_Low_Starter:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0325"=>{"Bezeichnung"=>"Alarm Low Starter Clear", "ReadingName"=>"Alarm_Low Starter_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_Starter_Clear:noArg", "setValues"=>"Alarm_Low_Starter_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0326"=>{"Bezeichnung"=>"Alarm High Starter", "ReadingName"=>"Alarm_High_Starter", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Starter:noArg", "setValues"=>"Alarm_High_Starter:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0327"=>{"Bezeichnung"=>"Alarm High Starter Clear", "ReadingName"=>"Alarm_High_Starter_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Starter_Clear:noArg", "setValues"=>"Alarm_High_Starter_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0328"=>{"Bezeichnung"=>"Alarm Low SOC", "ReadingName"=>"Alarm_Low_SOC", "Einheit"=>"proz", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_SOC:noArg", "setValues"=>"Alarm_Low_SOC:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0329"=>{"Bezeichnung"=>"Alarm Low SOC Clear", "ReadingName"=>"Alarm_Low_SOC Clear", "Einheit"=>"proz", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_SOC_Clear:noArg", "setValues"=>"Alarm_Low_SOC_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x032A"=>{"Bezeichnung"=>"Alarm Low Temperature", "ReadingName"=>"Alarm_Low_Temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_Temperature:noArg", "setValues"=>"Alarm_Low_Temperature:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x032B"=>{"Bezeichnung"=>"Alarm Low Temperature Clear", "ReadingName"=>"Alarm_Low_Temperature_Clear", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_Temperature_Clear:noArg", "setValues"=>"Alarm_Low_Temperature_Clear:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x032C"=>{"Bezeichnung"=>"Alarm High Temperature", "ReadingName"=>"Alarm_High_Temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Temperature:noArg", "setValues"=>"Alarm_High_Temperature:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x032D"=>{"Bezeichnung"=>"Alarm High Temperature Clear", "ReadingName"=>"Alarm_High_Temperature_Clear", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Temperature_Clear:noArg", "setValues"=>"Alarm_High_Temperature_Clear:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x0331"=>{"Bezeichnung"=>"Alarm Mid Voltage", "ReadingName"=>"Alarm_Mid_Voltage", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Mid_Voltage:noArg", "setValues"=>"Alarm_Mid_Voltage:slider,0,0.1,99", "spezialSetGet"=>"-"},
"0x0332"=>{"Bezeichnung"=>"Alarm Mid Voltage Clear", "ReadingName"=>"Alarm_Mid_Voltage_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Mid_Voltage_Clear:noArg", "setValues"=>"Alarm_Mid_Voltage_Clear:slider,0,0.1,99", "spezialSetGet"=>"-"},
"0x034D"=>{"Bezeichnung"=>"Relay Invert", "ReadingName"=>"Relay_Invert", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Invert:noArg", "setValues"=>"Relay_Invert:off,on", "spezialSetGet"=>"0:1"},
"0x034E"=>{"Bezeichnung"=>"Relay State_Control", "ReadingName"=>"Relay_State_Control", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"1", "getConfigAll"=>"1", "getValues"=>"Relay_State_Control:noArg", "setValues"=>"Relay_State_Control:open,closed", "spezialSetGet"=>"0:1"},
"0x034F"=>{"Bezeichnung"=>"Relay Mode", "ReadingName"=>"Relay_Mode", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"2", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Mode:noArg", "setValues"=>"Relay_Mode:default,chrg,rem", "spezialSetGet"=>"0:1:2"},
"0x0350"=>{"Bezeichnung"=>"Relay_battery_low_voltage_set", "ReadingName"=>"Relay_battery_low_voltage_set", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_low_voltage_set:noArg", "setValues"=>"Relay_battery_low_voltage_set:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0351"=>{"Bezeichnung"=>"Relay_battery_low_voltage_clear", "ReadingName"=>"Relay_battery_low_voltage_clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_low_voltage_clear:noArg", "setValues"=>"Relay_battery_low_voltage_clear:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0352"=>{"Bezeichnung"=>"Relay_battery_high_voltage_set", "ReadingName"=>"Relay_battery_high_voltage_set", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_high_voltage_set:noArg", "setValues"=>"Relay_battery_high_voltage_set:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0353"=>{"Bezeichnung"=>"Relay_battery_high_voltage_clear", "ReadingName"=>"Relay_battery_high_voltage_clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_high_voltage_clear:noArg", "setValues"=>"Relay_battery_high_voltage_clear:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0354"=>{"Bezeichnung"=>"Relay Low Starter", "ReadingName"=>"Relay_Low_Starter", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Starter:noArg", "setValues"=>"Relay_Low_Starter:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0355"=>{"Bezeichnung"=>"Relay Low Starter Clear", "ReadingName"=>"Relay_Low_Starter Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Starter_Clear:noArg", "setValues"=>"Relay_Low_Starter_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0356"=>{"Bezeichnung"=>"Relay High Starter", "ReadingName"=>"Rela_High_Starter", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_High_Starter:noArg", "setValues"=>"Relay_High_Starter:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0357"=>{"Bezeichnung"=>"Relay High Starter Clear", "ReadingName"=>"Relay_High_Starter_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_High_Starter_Clear:noArg", "setValues"=>"Relay_High_Starter_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x035A"=>{"Bezeichnung"=>"Relay Low Temperature", "ReadingName"=>"Relay_Low_Temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Temperature:noArg", "setValues"=>"Relay_Low_Temperature:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x035B"=>{"Bezeichnung"=>"Relay Low Temperature Clear", "ReadingName"=>"Relay_Low_Temperature_Clear", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Temperature_Clear:noArg", "setValues"=>"Relay_Low_Temperature_Clear:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x035C"=>{"Bezeichnung"=>"Relay High Temperature", "ReadingName"=>"Relay_High_Temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_High_Temperature:noArg", "setValues"=>"Relay_High_Temperature:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x035D"=>{"Bezeichnung"=>"Relay High Temperature Clear", "ReadingName"=>"Relay High Temperature Clear", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_High_Temperature_Clear:noArg", "setValues"=>"Relay_High_Temperature_Clear:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x0361"=>{"Bezeichnung"=>"Relay Mid Voltage", "ReadingName"=>"Relay_Mid_Voltage", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Mid_Voltage:noArg", "setValues"=>"Relay_Mid_Voltage:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0362"=>{"Bezeichnung"=>"Relay Mid Voltage Clear", "ReadingName"=>"Relay_Mid_Voltage_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Mid_Voltage_Clear:noArg", "setValues"=>"Relay_Mid_Voltage_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0382"=>{"Bezeichnung"=>"Mid-point voltage", "ReadingName"=>"Mid-point_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Mid-point_voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0383"=>{"Bezeichnung"=>"Mid-point voltage deviation", "ReadingName"=>"Mid-point_voltage_deviation", "Einheit"=>"proz", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Mid-point_voltage_deviation:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0FFE"=>{"Bezeichnung"=>"TTG", "ReadingName"=>"TTG", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"TTG:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0FFF"=>{"Bezeichnung"=>"SOC", "ReadingName"=>"SOC", "Einheit"=>"proz", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"SOC:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1000"=>{"Bezeichnung"=>"Battery Capacity", "ReadingName"=>"Battery_Capacity", "Einheit"=>"Ah", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"9999", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_Capacity:noArg", "setValues"=>"Battery_Capacity", "spezialSetGet"=>"-"},
"0x1001"=>{"Bezeichnung"=>"Charged Voltage", "ReadingName"=>"Charged_Voltage", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Charged_Voltage:noArg", "setValues"=>"Charged_Voltage", "spezialSetGet"=>"-"},
"0x1002"=>{"Bezeichnung"=>"Tail Current", "ReadingName"=>"Tail_Current", "Einheit"=>"proz", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0.5", "max"=>"10", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Tail_Current:noArg", "setValues"=>"Tail_Current:slider,0.5,0.1,10", "spezialSetGet"=>"-"},
"0x1003"=>{"Bezeichnung"=>"Charged Detection Time", "ReadingName"=>"Charged_Detection_Time", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"1", "max"=>"50", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Charged_Detection_Time:noArg", "setValues"=>"Charged_Detection_Time:slider,1,1,50", "spezialSetGet"=>"-"},
"0x1004"=>{"Bezeichnung"=>"Charge Efficiency", "ReadingName"=>"Charge_Efficiency", "Einheit"=>"proz", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"50", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Charge_Efficiency:noArg", "setValues"=>"Charge_Efficiency:slider,50,1,99", "spezialSetGet"=>"-"},
"0x1005"=>{"Bezeichnung"=>"Peukert Coefficient", "ReadingName"=>"Peukert_Coefficient", "Einheit"=>"", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"1", "max"=>"1.5", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Peukert_Coefficient:noArg", "setValues"=>"Peukert_Coefficient:slider,1,0.01,1.5", "spezialSetGet"=>"-"},
"0x1006"=>{"Bezeichnung"=>"Current Threshold", "ReadingName"=>"Current_Threshold", "Einheit"=>"A", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"2", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Current_Threshold:noArg", "setValues"=>"Current_Threshold:slider,0,0.01,2", "spezialSetGet"=>"-"},
"0x1007"=>{"Bezeichnung"=>"TTG Delta T", "ReadingName"=>"TTG_Delta_T", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"12", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"TTG_Delta_T:noArg", "setValues"=>"TTG_Delta_T:slider,0,1,12", "spezialSetGet"=>"-"},
"0x1008"=>{"Bezeichnung"=>"Discharge Floor Relay Low Soc Set", "ReadingName"=>"Discharge_Floor_Relay_Low_Soc_Set", "Einheit"=>"proz", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Discharge_Floor_Relay_Low_Soc_Set:noArg", "setValues"=>"Discharge_Floor_Relay_Low_Soc_Set:slider,0,0.1,99", "spezialSetGet"=>"-"},
"0x1009"=>{"Bezeichnung"=>"Relay Low Soc Clear", "ReadingName"=>"Relay_Low_Soc_Clear", "Einheit"=>"proz", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Soc_Clear:noArg", "setValues"=>"Relay_Low_Soc_Clear:slider,0,0.1,99", "spezialSetGet"=>"-"},
"0x100A"=>{"Bezeichnung"=>"Relay_minimum_enabled_time", "ReadingName"=>"Relay_minimum_enabled_time", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"500", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_minimum_enabled_time:noArg", "setValues"=>"Relay_minimum_enabled_time:slider,0,1,500", "spezialSetGet"=>"-"},
"0x100B"=>{"Bezeichnung"=>"Relay Disable Time", "ReadingName"=>"Relay_Disable_Time", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"500", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Disable_Time:noArg", "setValues"=>"Relay_Disable_Time:slider,0,1,500", "spezialSetGet"=>"-"},
"0x1029"=>{"Bezeichnung"=>"set Zero Current", "ReadingName"=>"set_Zero_Current", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"-", "setValues"=>"set_Zero_Current:noArg", "spezialSetGet"=>"-"},
"0x1034"=>{"Bezeichnung"=>"User Current Zero (read only)", "ReadingName"=>"User_Current_Zero_(read only)", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"User_Current_Zero:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED7D"=>{"Bezeichnung"=>"Aux (starter) Voltage", "ReadingName"=>"Aux_(starter)_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Aux_(starter)_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED8D"=>{"Bezeichnung"=>"Battery_Voltage", "ReadingName"=>"Battery_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Battery_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED8E"=>{"Bezeichnung"=>"Power", "ReadingName"=>"Power", "Einheit"=>"W", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Power:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED8F"=>{"Bezeichnung"=>"Current", "ReadingName"=>"Current", "Einheit"=>"A", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Current:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDDD"=>{"Bezeichnung"=>"System_yield", "ReadingName"=>"System_yield", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"System_yield:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDEC"=>{"Bezeichnung"=>"Battery_temperature", "ReadingName"=>"Battery_temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Battery_temperature:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEEE0"=>{"Bezeichnung"=>"Show Voltage", "ReadingName"=>"Show_Voltage", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Voltage:noArg", "setValues"=>"Show_Voltage:off,on", "spezialSetGet"=>"0:1"},
"0xEEE1"=>{"Bezeichnung"=>"Show Auxiliary Voltage", "ReadingName"=>"Show_Auxiliary_Voltage", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Auxiliary_Voltage:noArg", "setValues"=>"Show_Auxiliary_Voltage:off,on", "spezialSetGet"=>"0:1"},
"0xEEE2"=>{"Bezeichnung"=>"Show Mid Voltage", "ReadingName"=>"Show_Mid_Voltage", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Mid_Voltage:noArg", "setValues"=>"Show_Mid_Voltage:off,on", "spezialSetGet"=>"0:1"},
"0xEEE3"=>{"Bezeichnung"=>"Show Current", "ReadingName"=>"Show_Current", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Current:noArg", "setValues"=>"Show_Current:off,on", "spezialSetGet"=>"0:1"},
"0xEEE4"=>{"Bezeichnung"=>"Show Cunsumed AH", "ReadingName"=>"Show_Cunsumed_AH", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Cunsumed_AH:noArg", "setValues"=>"Show_Cunsumed_AH:off,on", "spezialSetGet"=>"0:1"},
"0xEEE5"=>{"Bezeichnung"=>"Show SOC", "ReadingName"=>"Show_SOC", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_SOC:noArg", "setValues"=>"Show_SOC:off,on", "spezialSetGet"=>"0:1"},
"0xEEE6"=>{"Bezeichnung"=>"Show TTG", "ReadingName"=>"Show_TTG", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_TTG:noArg", "setValues"=>"Show_TTG:off,on", "spezialSetGet"=>"0:1"},
"0xEEE7"=>{"Bezeichnung"=>"Show Temperature", "ReadingName"=>"Show_Temperature", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Temperature:noArg", "setValues"=>"Show_Temperature:off,on", "spezialSetGet"=>"0:1"},
"0xEEE8"=>{"Bezeichnung"=>"Show Power", "ReadingName"=>"Show_Power", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Power:noArg", "setValues"=>"Show_Power:off,on", "spezialSetGet"=>"0:1"},
"0xEEF4"=>{"Bezeichnung"=>"Temperature coefficient", "ReadingName"=>"Temperature_coefficient", "Einheit"=>"prozCAP_degC", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"20", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Temperature_coefficient:noArg", "setValues"=>"Temperature_coefficient:slider,0,0.1,20", "spezialSetGet"=>"-"},
"0xEEF5"=>{"Bezeichnung"=>"Scroll Speed", "ReadingName"=>"Scroll_Speed", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"1", "max"=>"5", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Scroll_Speed:noArg", "setValues"=>"Scroll_Speed:slider,0,1,5", "spezialSetGet"=>"-"},
"0xEEF6"=>{"Bezeichnung"=>"Setup Lock", "ReadingName"=>"Setup_Lock", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Setup_Lock:noArg", "setValues"=>"Setup_Lock:off,on", "spezialSetGet"=>"0:1"},
"0xEEF7"=>{"Bezeichnung"=>"Temperature Unit", "ReadingName"=>"Temperature_Unit", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Temperature_Unit:noArg", "setValues"=>"Temperature_Unit:Celsius,Fahrenheit", "spezialSetGet"=>"0:1"},
"0xEEF8"=>{"Bezeichnung"=>"Auxiliary Input", "ReadingName"=>"Auxiliary_Input", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"2", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Auxiliary_Input:noArg", "setValues"=>"Auxiliary_Input:start,mid,temp", "spezialSetGet"=>"0:1"},
"0xEEF9"=>{"Bezeichnung"=>"SW Version", "ReadingName"=>"SW_Version", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"SW_Version:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEEFA"=>{"Bezeichnung"=>"Shunt Volts", "ReadingName"=>"Shunt_Volts", "Einheit"=>"V", "Skalierung"=>"0.001", "Payloadnibbles"=>"4", "min"=>"0.001", "max"=>"0.1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Shunt_Volts:noArg", "setValues"=>"Shunt_Volts", "spezialSetGet"=>"-"},
"0xEEFB"=>{"Bezeichnung"=>"Shunt Amps", "ReadingName"=>"Shunt_Amps", "Einheit"=>"A", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"9999", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Shunt_Amps:noArg", "setValues"=>"Shunt_Amps", "spezialSetGet"=>"-"},
"0xEEFC"=>{"Bezeichnung"=>"Alarm Buzzer", "ReadingName"=>"Alarm_Buzzer", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Buzzer:noArg", "setValues"=>"Alarm_Buzzer:off,on", "spezialSetGet"=>"0:1"},
"0xEEFE"=>{"Bezeichnung"=>"Backlight Intensity", "ReadingName"=>"Backlight_Intensity", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"9", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Backlight_Intensity:noArg", "setValues"=>"Backlight_Intensity:0,1,2,3,4,5,6,7,8,9", "spezialSetGet"=>"-"},
"0xEEFF"=>{"Bezeichnung"=>"Consumed_Ah", "ReadingName"=>"Consumed_Ah", "Einheit"=>"Ah", "Skalierung"=>"0.1", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Consumed_Ah:noArg", "setValues"=>"-", "spezialSetGet"=>"-"});


my %MPPT = (
"0x0100"=>{"Bezeichnung"=>"PID", "ReadingName"=>"Devicetype_PID", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"PID:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0104"=>{"Bezeichnung"=>"Group_Id", "ReadingName"=>"Group_Id", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Group_Id:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0105"=>{"Bezeichnung"=>"Device_instance", "ReadingName"=>"Device_instance", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Device_instance:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0106"=>{"Bezeichnung"=>"Device_class", "ReadingName"=>"Device_class", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Device_class:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x010A"=>{"Bezeichnung"=>"Serial_number", "ReadingName"=>"Serial_number", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"0", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Serial_number:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x010B"=>{"Bezeichnung"=>"Model_name", "ReadingName"=>"Model_name", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"0", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Model_name:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0140"=>{"Bezeichnung"=>"Capabilities", "ReadingName"=>"Capabilities", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Capabilities:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0200"=>{"Bezeichnung"=>"Charger_mode", "ReadingName"=>"Charger_mode", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Charger_mode:off,on,off", "setValues"=>"Charger_mode:off,on", "spezialSetGet"=>"0:1:4"},
"0x0201"=>{"Bezeichnung"=>"Device_state", "ReadingName"=>"Charger_state", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Charger_state:not_charging,,fault,bulk,absorption,float,equalize,ess", "setValues"=>"-", "spezialSetGet"=>"0:1:2:3:4:5:7:9:252"},
"0x0205"=>{"Bezeichnung"=>"Device_off_reason", "ReadingName"=>"Device_off_reason", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Charger_off_reason:noArg", "setValues"=>"-", "spezialSetGet"=>"bitwise"},
"0x0350"=>{"Bezeichnung"=>"Relay_battery_low_voltage_set", "ReadingName"=>"Relay_battery_low_voltage_set", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_low_voltage_set:noArg", "setValues"=>"Relay_battery_low_voltage_set:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0351"=>{"Bezeichnung"=>"Relay_battery_low_voltage_clear", "ReadingName"=>"Relay_battery_low_voltage_clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_low_voltage_clear:noArg", "setValues"=>"Relay_battery_low_voltage_clear:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0352"=>{"Bezeichnung"=>"Relay_battery_high_voltage_set", "ReadingName"=>"Relay_battery_high_voltage_set", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_high_voltage_set:noArg", "setValues"=>"Relay_battery_high_voltage_set:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0353"=>{"Bezeichnung"=>"Relay_battery_high_voltage_clear", "ReadingName"=>"Relay_battery_high_voltage_clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_high_voltage_clear:noArg", "setValues"=>"Relay_battery_high_voltage_clear:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0400"=>{"Bezeichnung"=>"Display_backlight_mode", "ReadingName"=>"Display_backlight_mode", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Display_backlight_mode:noArg", "setValues"=>"Display_backlight_mode:keypress,on,auto", "spezialSetGet"=>"0:1:2"},
"0x0401"=>{"Bezeichnung"=>"Display_backlight_intensity", "ReadingName"=>"Display_backlight_intensity", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Display_backlight_intensity:noArg", "setValues"=>"Display_backlight_intensity:off,on", "spezialSetGet"=>"0:1"},
"0x0402"=>{"Bezeichnung"=>"Display_scroll_text_speed", "ReadingName"=>"Display_scroll_text_speed", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Display_scroll_text_speed:noArg", "setValues"=>"Display_scroll_text_speed:1,2,3,4,5", "spezialSetGet"=>"-"},
"0x0403"=>{"Bezeichnung"=>"Display_setup_lock", "ReadingName"=>"Display_setup_lock", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Display_setup_lock:noArg", "setValues"=>"Display_setup_lock:unlocked,locked", "spezialSetGet"=>"0:1"},
"0x0404"=>{"Bezeichnung"=>"Display_temperature_unit", "ReadingName"=>"Display_temperature_unit", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Display_temperature_unit:noArg", "setValues"=>"Display_temperature_unit:Celsius,Fahrenheit", "spezialSetGet"=>"0:1"},
"0x100A"=>{"Bezeichnung"=>"Relay_minimum_enabled_time", "ReadingName"=>"Relay_minimum_enabled_time", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"500", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_minimum_enabled_time:noArg", "setValues"=>"Relay_minimum_enabled_time:slider,0,1,500", "spezialSetGet"=>"-"},
"0x1030"=>{"Bezeichnung"=>"Clear_history", "ReadingName"=>"Clear_history", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Clear_history:noArg", "setValues"=>"Clear_history:noArg", "spezialSetGet"=>"-"},
"0x104F"=>{"Bezeichnung"=>"Total_history", "ReadingName"=>"Total_history", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Total_history:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1050"=>{"Bezeichnung"=>"History_today", "ReadingName"=>"History_today", "Einheit"=>"", "Skalierung"=>"0", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"History_today:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1051"=>{"Bezeichnung"=>"History-1", "ReadingName"=>"History-1", "Einheit"=>"", "Skalierung"=>"-1", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-1:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1052"=>{"Bezeichnung"=>"History-2", "ReadingName"=>"History-2", "Einheit"=>"", "Skalierung"=>"-2", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-2:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1053"=>{"Bezeichnung"=>"History-3", "ReadingName"=>"History-3", "Einheit"=>"", "Skalierung"=>"-3", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-3:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1054"=>{"Bezeichnung"=>"History-4", "ReadingName"=>"History-4", "Einheit"=>"", "Skalierung"=>"-4", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-4:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1055"=>{"Bezeichnung"=>"History-5", "ReadingName"=>"History-5", "Einheit"=>"", "Skalierung"=>"-5", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-5:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1056"=>{"Bezeichnung"=>"History-6", "ReadingName"=>"History-6", "Einheit"=>"", "Skalierung"=>"-6", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-6:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1057"=>{"Bezeichnung"=>"History-7", "ReadingName"=>"History-7", "Einheit"=>"", "Skalierung"=>"-7", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-7:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1058"=>{"Bezeichnung"=>"History-8", "ReadingName"=>"History-8", "Einheit"=>"", "Skalierung"=>"-8", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-8:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1059"=>{"Bezeichnung"=>"History-9", "ReadingName"=>"History-9", "Einheit"=>"", "Skalierung"=>"-9", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-9:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x105A"=>{"Bezeichnung"=>"History-10", "ReadingName"=>"History-10", "Einheit"=>"", "Skalierung"=>"-10", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-10:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x105B"=>{"Bezeichnung"=>"History-11", "ReadingName"=>"History-11", "Einheit"=>"", "Skalierung"=>"-11", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-11:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x105C"=>{"Bezeichnung"=>"History-12", "ReadingName"=>"History-12", "Einheit"=>"", "Skalierung"=>"-12", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-12:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x105D"=>{"Bezeichnung"=>"History-13", "ReadingName"=>"History-13", "Einheit"=>"", "Skalierung"=>"-13", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-13:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x105E"=>{"Bezeichnung"=>"History-14", "ReadingName"=>"History-14", "Einheit"=>"", "Skalierung"=>"-14", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-14:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x105F"=>{"Bezeichnung"=>"History-15", "ReadingName"=>"History-15", "Einheit"=>"", "Skalierung"=>"-15", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-15:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1060"=>{"Bezeichnung"=>"History-16", "ReadingName"=>"History-16", "Einheit"=>"", "Skalierung"=>"-16", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-16:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1061"=>{"Bezeichnung"=>"History-17", "ReadingName"=>"History-17", "Einheit"=>"", "Skalierung"=>"-17", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-17:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1062"=>{"Bezeichnung"=>"History-18", "ReadingName"=>"History-18", "Einheit"=>"", "Skalierung"=>"-18", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-18:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1063"=>{"Bezeichnung"=>"History-19", "ReadingName"=>"History-19", "Einheit"=>"", "Skalierung"=>"-19", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-19:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1064"=>{"Bezeichnung"=>"History-20", "ReadingName"=>"History-20", "Einheit"=>"", "Skalierung"=>"-20", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-20:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1065"=>{"Bezeichnung"=>"History-21", "ReadingName"=>"History-21", "Einheit"=>"", "Skalierung"=>"-21", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-21:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1066"=>{"Bezeichnung"=>"History-22", "ReadingName"=>"History-22", "Einheit"=>"", "Skalierung"=>"-22", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-22:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1067"=>{"Bezeichnung"=>"History-23", "ReadingName"=>"History-23", "Einheit"=>"", "Skalierung"=>"-23", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-23:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1068"=>{"Bezeichnung"=>"History-24", "ReadingName"=>"History-24", "Einheit"=>"", "Skalierung"=>"-24", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-24:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1069"=>{"Bezeichnung"=>"History-25", "ReadingName"=>"History-25", "Einheit"=>"", "Skalierung"=>"-25", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-25:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x106A"=>{"Bezeichnung"=>"History-26", "ReadingName"=>"History-26", "Einheit"=>"", "Skalierung"=>"-26", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-26:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x106B"=>{"Bezeichnung"=>"History-27", "ReadingName"=>"History-27", "Einheit"=>"", "Skalierung"=>"-27", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-27:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x106C"=>{"Bezeichnung"=>"History-28", "ReadingName"=>"History-28", "Einheit"=>"", "Skalierung"=>"-28", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-28:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x106D"=>{"Bezeichnung"=>"History-29", "ReadingName"=>"History-29", "Einheit"=>"", "Skalierung"=>"-29", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-29:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x106E"=>{"Bezeichnung"=>"History-30", "ReadingName"=>"History-30", "Einheit"=>"", "Skalierung"=>"-30", "Payloadnibbles"=>"68", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History-30:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2000"=>{"Bezeichnung"=>"Charge_algorithm_version", "ReadingName"=>"Charge_algorithm_version", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Charge_algorithm_version:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2001"=>{"Bezeichnung"=>"Charge_voltage_set-point", "ReadingName"=>"Charge_voltage_set-point", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Charge_voltage_set-point:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2002"=>{"Bezeichnung"=>"Battery_voltage_sense", "ReadingName"=>"Battery_voltage_sense", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Battery_voltage_sense:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2003"=>{"Bezeichnung"=>"Battery_temperature_sense", "ReadingName"=>"Battery_temperature_sense", "Einheit"=>"degC", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Battery_temperature_sense:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2004"=>{"Bezeichnung"=>"Remote_command", "ReadingName"=>"Remote_command", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Remote_command:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2005"=>{"Bezeichnung"=>"Switch_bank_status", "ReadingName"=>"Switch_bank_status", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Switch_bank_status:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2006"=>{"Bezeichnung"=>"Switch_bank_mask", "ReadingName"=>"Switch_bank_mask", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Switch_bank_mask:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2007"=>{"Bezeichnung"=>"Charge_state_elapsed_time", "ReadingName"=>"Charge_state_elapsed_time", "Einheit"=>"ms", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Charge_state_elapsed_time:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2008"=>{"Bezeichnung"=>"Absorption_time_left", "ReadingName"=>"Absorption_time_left", "Einheit"=>"h", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Absorption_time_left:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x200E"=>{"Bezeichnung"=>"Network_mode", "ReadingName"=>"Network_mode", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Network_mode:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x200F"=>{"Bezeichnung"=>"Network_status", "ReadingName"=>"Network_status", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Network_status:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2015"=>{"Bezeichnung"=>"Charge_current_limit", "ReadingName"=>"Charge_current_limit", "Einheit"=>"A", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Charge_current_limit:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2030"=>{"Bezeichnung"=>"Solar_activity", "ReadingName"=>"Solar_activity", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Solar_activity:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2031"=>{"Bezeichnung"=>"Time-of-day", "ReadingName"=>"Time-of-day", "Einheit"=>"min", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Time-of-day:noArg", "setValues"=>"Time-of-day", "spezialSetGet"=>"-"},
"0x2211"=>{"Bezeichnung"=>"Adjustable_voltage_range_minimum", "ReadingName"=>"Adjustable_voltage_range_minimum", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Adjustable_voltage_range_minimum:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2212"=>{"Bezeichnung"=>"Adjustable_voltage_range_maximum", "ReadingName"=>"Adjustable_voltage_range_maximum", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Adjustable_voltage_range_maximum:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED90"=>{"Bezeichnung"=>"AES_Timer", "ReadingName"=>"AES_Timer", "Einheit"=>"min", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"AES_Timer:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED91"=>{"Bezeichnung"=>"Load_output_off_reason", "ReadingName"=>"Load_output_off_reason", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Load_output_off_reason:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED96"=>{"Bezeichnung"=>"Sunset_delay", "ReadingName"=>"Sunset_delay", "Einheit"=>"min", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Sunset_delay:noArg", "setValues"=>"Sunset_delay", "spezialSetGet"=>"-"},
"0xED97"=>{"Bezeichnung"=>"Sunrise_delay", "ReadingName"=>"Sunrise_delay", "Einheit"=>"min", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Sunrise_delay:noArg", "setValues"=>"Sunrise_delay", "spezialSetGet"=>"-"},
"0xED98"=>{"Bezeichnung"=>"RX_Port_operation_mode", "ReadingName"=>"RX_Port_operation_mode", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"RX_Port_operation_mode:noArg", "setValues"=>"RX_Port_operation_mode:Remote_On_off,Load_output_configuration,Load_output_on_off_remote_control_inverted,Load_output_on_off_remote_control_normal", "spezialSetGet"=>"0:1:2:3"},
"0xED99"=>{"Bezeichnung"=>"Panel_voltage_day", "ReadingName"=>"Panel_voltage_day", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Panel_voltage_day:noArg", "setValues"=>"Panel_voltage_day", "spezialSetGet"=>"-"},
"0xED9A"=>{"Bezeichnung"=>"Panel_voltage_night", "ReadingName"=>"Panel_voltage_night", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Panel_voltage_night:noArg", "setValues"=>"Panel_voltage_night", "spezialSetGet"=>"-"},
"0xED9B"=>{"Bezeichnung"=>"Gradual_dim_speed", "ReadingName"=>"Gradual_dim_speed", "Einheit"=>"s", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"254", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Gradual_dim_speed:noArg", "setValues"=>"Gradual_dim_speed:slider,0,1,254", "spezialSetGet"=>"-"},
"0xED9C"=>{"Bezeichnung"=>"Load_switch_low_level", "ReadingName"=>"Load_switch_low_level", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Load_switch_low_level:noArg", "setValues"=>"Load_switch_low_level", "spezialSetGet"=>"-"},
"0xED9D"=>{"Bezeichnung"=>"Load_switch_high_level", "ReadingName"=>"Load_switch_high_level", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Load_switch_high_level:noArg", "setValues"=>"Load_switch_high_level", "spezialSetGet"=>"-"},
"0xED9E"=>{"Bezeichnung"=>"TX_Port_operation_mode", "ReadingName"=>"TX_Port_operation_mode", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"TX_Port_operation_mode:noArg", "setValues"=>"TX_Port_operation_mode:Pulse_every0_01kWh,Lighting_control_pwm_normal,Lighting_control_pwm_inverted,Virtual_load_output", "spezialSetGet"=>"0:1:2:3:4"},
"0xEDA0"=>{"Bezeichnung"=>"Lightning Controller timer event 0", "ReadingName"=>"Lightning Controller timer event 0", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_0:noArg", "setValues"=>"Lightning_Controller_timer_event_0", "spezialSetGet"=>"-"},
"0xEDA1"=>{"Bezeichnung"=>"Lightning Controller timer event 1", "ReadingName"=>"Lightning Controller timer event 1", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_1:noArg", "setValues"=>"Lightning_Controller_timer_event_1", "spezialSetGet"=>"-"},
"0xEDA2"=>{"Bezeichnung"=>"Lightning Controller timer event 2", "ReadingName"=>"Lightning Controller timer event 2", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_2:noArg", "setValues"=>"Lightning_Controller_timer_event_2", "spezialSetGet"=>"-"},
"0xEDA3"=>{"Bezeichnung"=>"Lightning Controller timer event 3", "ReadingName"=>"Lightning Controller timer event 3", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_3:noArg", "setValues"=>"Lightning_Controller_timer_event_3", "spezialSetGet"=>"-"},
"0xEDA4"=>{"Bezeichnung"=>"Lightning Controller timer event 4", "ReadingName"=>"Lightning Controller timer event 4", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_4:noArg", "setValues"=>"Lightning_Controller_timer_event_4", "spezialSetGet"=>"-"},
"0xEDA5"=>{"Bezeichnung"=>"Lightning Controller timer event 5", "ReadingName"=>"Lightning Controller timer event 5", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_5:noArg", "setValues"=>"Lightning_Controller_timer_event_5", "spezialSetGet"=>"-"},
"0xEDA7"=>{"Bezeichnung"=>"Mid-point_shift", "ReadingName"=>"Mid-point_shift", "Einheit"=>"min", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Mid-point_shift:noArg", "setValues"=>"Mid-point_shift", "spezialSetGet"=>"-"},
"0xEDA8"=>{"Bezeichnung"=>"Load_output_state", "ReadingName"=>"Load_output_state", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Load_output_state:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDA9"=>{"Bezeichnung"=>"Load_output_voltage", "ReadingName"=>"Load_output_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Load_output_voltage:noArg", "setValues"=>"Load_output_voltage", "spezialSetGet"=>"-"},
"0xEDAB"=>{"Bezeichnung"=>"Load_output_control", "ReadingName"=>"Load_output_control", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Load_output_control:noArg", "setValues"=>"Load_output_control:off,auto,alt1,alt2,on,user1,user2,automatic_energy_selector", "spezialSetGet"=>"0:1:2:3:4:5:6:7"},
"0xEDAC"=>{"Bezeichnung"=>"Load_offset_voltage", "ReadingName"=>"Load_offset_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Load_offset_voltage:noArg", "setValues"=>"Load_offset_voltage", "spezialSetGet"=>"-"},
"0xEDAD"=>{"Bezeichnung"=>"Load_current", "ReadingName"=>"Load_current", "Einheit"=>"A", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Load_current:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDB8"=>{"Bezeichnung"=>"Panel_maximum_voltage", "ReadingName"=>"Panel_maximum_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Panel_maximum_voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDB9"=>{"Bezeichnung"=>"Relay_panel_high_voltage_clear", "ReadingName"=>"Relay_panel_high_voltage_clear", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_panel_high_voltage_clear:noArg", "setValues"=>"Relay_panel_high_voltage_clear", "spezialSetGet"=>"-"},
"0xEDBA"=>{"Bezeichnung"=>"Relay_panel_high_voltage_set", "ReadingName"=>"Relay_panel_high_voltage_set", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_panel_high_voltage_set:noArg", "setValues"=>"Relay_panel_high_voltage_set", "spezialSetGet"=>"-"},
"0xEDBB"=>{"Bezeichnung"=>"Panel_voltage", "ReadingName"=>"Panel_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Panel_voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDBC"=>{"Bezeichnung"=>"Panel_power", "ReadingName"=>"Panel_power", "Einheit"=>"W", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Panel_power:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDBD"=>{"Bezeichnung"=>"Panel_current", "ReadingName"=>"Panel_current", "Einheit"=>"A", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Panel_current:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDCC"=>{"Bezeichnung"=>"Streetlight_version", "ReadingName"=>"Streetlight_version", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Streetlight_version:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDCD"=>{"Bezeichnung"=>"History_version", "ReadingName"=>"History_version", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"History_version:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDCE"=>{"Bezeichnung"=>"Voltage_settings_range", "ReadingName"=>"Voltage_settings_range", "Einheit"=>"V", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Voltage_settings_range:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDD0"=>{"Bezeichnung"=>"Maximum_power_yesterday", "ReadingName"=>"Maximum_power_yesterday", "Einheit"=>"W", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Maximum_power_yesterday:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDD1"=>{"Bezeichnung"=>"Yield_yesterday", "ReadingName"=>"Yield_yesterday", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Yield_yesterday:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDD2"=>{"Bezeichnung"=>"Maximum_power_today", "ReadingName"=>"Maximum_power_today", "Einheit"=>"W", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Maximum_power_today:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDD3"=>{"Bezeichnung"=>"Yield_today", "ReadingName"=>"Yield_today", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Yield_today:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDD4"=>{"Bezeichnung"=>"Additional_charger_state_info", "ReadingName"=>"Additional_charger_state_info", "Einheit"=>"-", "Skalierung"=>"-", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Additional_charger_state_info:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDD5"=>{"Bezeichnung"=>"Battery_voltage", "ReadingName"=>"Battery_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Charger_voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDD7"=>{"Bezeichnung"=>"Charger_current", "ReadingName"=>"Charger_current", "Einheit"=>"A", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Charger_current:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDD9"=>{"Bezeichnung"=>"Relay_operation_mode", "ReadingName"=>"Relay_operation_mode", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_operation_mode:noArg", "setValues"=>"Relay_operation_mode:off,PV_V_high,int_temp_high,Batt_Voltage_low,equalization_active,Error_cond_present,int_temp_low,Batt_Voltage_too_high,Charger_in_float_or_storage,day_detection,load_control", "spezialSetGet"=>"0:1:2:3:4:5:6:7:8:9:10"},
"0xEDDA"=>{"Bezeichnung"=>"Charger_error_code", "ReadingName"=>"Charger_error_code", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Charger_error_code:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDDB"=>{"Bezeichnung"=>"Charger_internal_temperature", "ReadingName"=>"Charger_internal_temperature", "Einheit"=>"degC", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Charger_internal_temperature:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDDC"=>{"Bezeichnung"=>"User_yield_resettable", "ReadingName"=>"User_yield_resettable", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"User_yield_resettable:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDDD"=>{"Bezeichnung"=>"System_yield", "ReadingName"=>"System_yield", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"System_yield:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDDF"=>{"Bezeichnung"=>"Charger_maximum_current", "ReadingName"=>"Charger_maximum_current", "Einheit"=>"A", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Charger_maximum_current:noArg", "setValues"=>"Charger_maximum_current", "spezialSetGet"=>"-"},
"0xEDE0"=>{"Bezeichnung"=>"Battery_low_temperature_level", "ReadingName"=>"Battery_low_temperature_level", "Einheit"=>"degC", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_low_temperature_level:noArg", "setValues"=>"Battery_low_temperature_level", "spezialSetGet"=>"-"},
"0xEDE6"=>{"Bezeichnung"=>"Low_temperature_charge_current", "ReadingName"=>"Low_temperature_charge_current", "Einheit"=>"A", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Low_temperature_charge_current:noArg", "setValues"=>"Low_temperature_charge_current", "spezialSetGet"=>"-"},
"0xEDE8"=>{"Bezeichnung"=>"BMS_present", "ReadingName"=>"BMS_present", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"BMS_present:noArg", "setValues"=>"BMS_present", "spezialSetGet"=>"-"},
"0xEDEA"=>{"Bezeichnung"=>"Battery_voltage_setting", "ReadingName"=>"Battery_voltage_setting", "Einheit"=>"V", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_voltage_setting:noArg", "setValues"=>"Battery_voltage_setting", "spezialSetGet"=>"-"},
"0xEDEC"=>{"Bezeichnung"=>"Battery_temperature", "ReadingName"=>"Battery_temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Battery_temperature:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDEF"=>{"Bezeichnung"=>"Battery_voltage_nominal", "ReadingName"=>"Battery_voltage_nominal", "Einheit"=>"V", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_voltage:noArg", "setValues"=>"Battery_voltage", "spezialSetGet"=>"-"},
"0xEDF0"=>{"Bezeichnung"=>"Battery_maximum_current", "ReadingName"=>"Battery_maximum_current", "Einheit"=>"A", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_maximum_current:noArg", "setValues"=>"Battery_maximum_current", "spezialSetGet"=>"-"},
"0xEDF1"=>{"Bezeichnung"=>"Battery_type", "ReadingName"=>"Battery_type", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_type:noArg", "setValues"=>"Battery_type:TYPE_1_GEL_Victron_Long_Life_14_1V,TYPE_2_GEL_Victron_Deep_discharge_14_3V,TYPE_3_GEL_Victron_Deep_discharge_14_4V,TYPE_4_AGM_Victron_Deep_discharge_14_7V,TYPE_5_Tubular_plate_cyclic_mode_1_14_9V,TYPE_6_Tubular_plate_cyclic_mode_2_15_1V,TYPE_7_Tubular_plate_cyclic_mode_3_15_3V,TYPE_8_LiFEPO4_14_2V,User_defined", "spezialSetGet"=>"1:2:3:4:5:6:7:8:255"},
"0xEDF2"=>{"Bezeichnung"=>"Battery_temp_compensation", "ReadingName"=>"Battery_temp_compensation", "Einheit"=>"mV_K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_temp_compensation:noArg", "setValues"=>"Battery_temp_compensation", "spezialSetGet"=>"-"},
"0xEDF4"=>{"Bezeichnung"=>"Battery_equalization_voltage", "ReadingName"=>"Battery_equalization_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"8", "max"=>"17", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_equalization_voltage:noArg", "setValues"=>"Battery_equalization_voltage", "spezialSetGet"=>"-"},
"0xEDF6"=>{"Bezeichnung"=>"Battery_float_voltage", "ReadingName"=>"Battery_float_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_float_voltage:noArg", "setValues"=>"Battery_float_voltage", "spezialSetGet"=>"-"},
"0xEDF7"=>{"Bezeichnung"=>"Battery_absorption_voltage", "ReadingName"=>"Battery_absorption_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_absorption_voltage:noArg", "setValues"=>"Battery_absorption_voltage", "spezialSetGet"=>"-"},
"0xEDFB"=>{"Bezeichnung"=>"Battery_absorption_time_limit", "ReadingName"=>"Battery_absorption_time_limit", "Einheit"=>"h", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_absorption_time_limit:noArg", "setValues"=>"Battery_absorption_time_limit", "spezialSetGet"=>"-"},
"0xEDFC"=>{"Bezeichnung"=>"Battery_bulk_time_limit", "ReadingName"=>"Battery_bulk_time_limit", "Einheit"=>"h", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_bulk_time_limit:noArg", "setValues"=>"Battery_bulk_time_limit", "spezialSetGet"=>"-"},
"0xEDFD"=>{"Bezeichnung"=>"Automatic_equalization_mode", "ReadingName"=>"Automatic_equalization_mode", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"250", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Automatic_equalization_mode:noArg", "setValues"=>"Automatic_equalization_mode:multiple,disabled", "spezialSetGet"=>"0:alt"});


my %Inverter = (
"0x0100"=>{"Bezeichnung"=>"PID", "ReadingName"=>"Devicetype_PID", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"PID:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0101"=>{"Bezeichnung"=>"Hardwareversion", "ReadingName"=>"Hardwareversion", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Hardwareversion:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0102"=>{"Bezeichnung"=>"Softwareversion", "ReadingName"=>"Softwareversion", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Softwareversion:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x010A"=>{"Bezeichnung"=>"Serial_number", "ReadingName"=>"Serial_number", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"0", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Serial_number:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x010B"=>{"Bezeichnung"=>"Model_name", "ReadingName"=>"Model_name", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"0", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Model_name:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0200"=>{"Bezeichnung"=>"Device_mode", "ReadingName"=>"Device_mode", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Device_mode:noArg", "setValues"=>"Device_mode:on,off,eco", "spezialSetGet"=>"2:4:5"},
"0x0201"=>{"Bezeichnung"=>"Device_state", "ReadingName"=>"Device_state", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Device_state:off,low_power,fault,,,,,inverting,", "setValues"=>"-", "spezialSetGet"=>"0:1:2:3:4:5:7:9:252"},
"0x0230"=>{"Bezeichnung"=>"AC_OUT_VOLTAGE_SETPOINT", "ReadingName"=>"AC_OUT_VOLTAGE_SETPOINT", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"AC_OUT_VOLTAGE_SETPOINT:noArg", "setValues"=>"AC_OUT_VOLTAGE_SETPOINT", "spezialSetGet"=>"-"},
"0x0231"=>{"Bezeichnung"=>"AC_OUT_VOLTAGE_SETPOINT_MIN", "ReadingName"=>"AC_OUT_VOLTAGE_SETPOINT_MIN", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"AC_OUT_VOLTAGE_SETPOINT_MIN:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0232"=>{"Bezeichnung"=>"AC_OUT_VOLTAGE_SETPOINT_MAX", "ReadingName"=>"AC_OUT_VOLTAGE_SETPOINT_MAX", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"AC_OUT_VOLTAGE_SETPOINT_MAX:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x031C"=>{"Bezeichnung"=>"Warning_reason", "ReadingName"=>"Warning_reason", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Warning_reason:noArg", "setValues"=>"-", "spezialSetGet"=>"bitwise"},
"0x031E"=>{"Bezeichnung"=>"Alarm_reason", "ReadingName"=>"Alarm_reason", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Alarm_reason:noArg", "setValues"=>"-", "spezialSetGet"=>"bitwise"},
"0x0320"=>{"Bezeichnung"=>"ALARM_LOW_VOLTAGE_SET", "ReadingName"=>"ALARM_LOW_VOLTAGE_SET", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"ALARM_LOW_VOLTAGE_SET:noArg", "setValues"=>"ALARM_LOW_VOLTAGE_SET", "spezialSetGet"=>"-"},
"0x0321"=>{"Bezeichnung"=>"ALARM_LOW_VOLTAGE_CLEAR", "ReadingName"=>"ALARM_LOW_VOLTAGE_CLEAR", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"ALARM_LOW_VOLTAGE_CLEAR:noArg", "setValues"=>"ALARM_LOW_VOLTAGE_CLEAR", "spezialSetGet"=>"-"},
"0x2200"=>{"Bezeichnung"=>"AC_OUT_VOLTAGE", "ReadingName"=>"AC_OUT_VOLTAGE", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"AC_OUT_VOLTAGE:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2201"=>{"Bezeichnung"=>"AC_OUT_CURRENT", "ReadingName"=>"AC_OUT_CURRENT", "Einheit"=>"A", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"AC_OUT_CURRENT:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2202"=>{"Bezeichnung"=>"VE_REG_AC_OUT_NOM_VOLTAGE", "ReadingName"=>"VE_REG_AC_OUT_NOM_VOLTAGE", "Einheit"=>"V", "Skalierung"=>1, "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"VE_REG_AC_OUT_NOM_VOLTAGE:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2203"=>{"Bezeichnung"=>"VE_REG_AC_OUT_RATED_POWER", "ReadingName"=>"VE_REG_AC_OUT_RATED_POWER", "Einheit"=>"VA", "Skalierung"=>1, "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"VE_REG_AC_OUT_RATED_POWER:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2210"=>{"Bezeichnung"=>"SHUTDOWN_LOW_VOLTAGE_SET", "ReadingName"=>"SHUTDOWN_LOW_VOLTAGE_SET", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"SHUTDOWN_LOW_VOLTAGE_SET:noArg", "setValues"=>"SHUTDOWN_LOW_VOLTAGE_SET", "spezialSetGet"=>"-"},
"0x2211"=>{"Bezeichnung"=>"Adjustable_voltage_range_minimum", "ReadingName"=>"Adjustable_voltage_range_minimum", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Adjustable_voltage_range_minimum:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x2212"=>{"Bezeichnung"=>"Adjustable_voltage_range_maximum", "ReadingName"=>"Adjustable_voltage_range_maximum", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Adjustable_voltage_range_maximum:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEB04"=>{"Bezeichnung"=>"INV_OPER_ECO_MODE_INV_MIN", "ReadingName"=>"INV_OPER_ECO_MODE_INV_MIN", "Einheit"=>"A", "Skalierung"=>"0.001", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"INV_OPER_ECO_MODE_INV_MIN:noArg", "setValues"=>"INV_OPER_ECO_MODE_INV_MIN", "spezialSetGet"=>"-"},
"0xEBB1"=>{"Bezeichnung"=>"INV_PROT_UBAT_DYN_CUTOFF_VOLTAGE", "ReadingName"=>"INV_PROT_UBAT_DYN_CUTOFF_VOLTAGE", "Einheit"=>"V", "Skalierung"=>"0.001", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"INV_PROT_UBAT_DYN_CUTOFF_VOLTAGE:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEBB2"=>{"Bezeichnung"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR5", "ReadingName"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR5", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR5:noArg", "setValues"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR5", "spezialSetGet"=>"-"},
"0xEBB3"=>{"Bezeichnung"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR250", "ReadingName"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR250", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR250:noArg", "setValues"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR250", "spezialSetGet"=>"-"},
"0xEBB5"=>{"Bezeichnung"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR2000", "ReadingName"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR2000", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR2000:noArg", "setValues"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR2000", "spezialSetGet"=>"-"},
"0xEBB7"=>{"Bezeichnung"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR", "ReadingName"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR:noArg", "setValues"=>"INV_PROT_UBAT_DYN_CUTOFF_FACTOR", "spezialSetGet"=>"-"},
"0xEBBA"=>{"Bezeichnung"=>"INV_PROT_UBAT_DYN_CUTOFF_ENABLE", "ReadingName"=>"INV_PROT_UBAT_DYN_CUTOFF_ENABLE", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"INV_PROT_UBAT_DYN_CUTOFF_ENABLE:noArg", "setValues"=>"INV_PROT_UBAT_DYN_CUTOFF_ENABLE:disabled,enabled", "spezialSetGet"=>"0:1"},
"0xED8D"=>{"Bezeichnung"=>"Battery_voltage", "ReadingName"=>"Battery_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Battery_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"});



my %Register = ("BMV" => {%BMV}, "MPPT" => {%MPPT}, "Inverter"=> {%Inverter});

## my $bezeichnung = $Register{"Inverter"}->{"0x0200"}->{Bezeichnung};
#  foreach my $key (keys %{ $Register{$type} })
#    {
#      if ($cmd eq $Register{ $type }->{ $key }->{"Bezeichnung"})
#      {
#        $reg = $key;
#        fhem("setreading $SELF Key $key");
#        last if ($reg ne "");
#      }
#    }
# ;       
##  "Device-Typ"->[Register,Skalierungsmultiplikator,Readingname wenn kein Register vorhanden]
my %TextMapping = (
"V"=>{"BMV"=>{"Register"=>"0xED8D","scale"=>0.001,"ReName"=>"Battery_voltage", "Einheit"=>"V"}, "MPPT"=>{"Register"=>"0xEDD5","scale"=>0.001,"ReName"=>"Battery_voltage", "Einheit"=>"V"}, "Inverter"=>{"Register"=>"0xED8D","scale"=>0.001,"ReName"=>"-", "Einheit"=>"V"}},
"VS"=>{"BMV"=>{"Register"=>"0xED7D","scale"=>0.001,"ReName"=>"Battery_voltageVS", "Einheit"=>"V"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-", "Einheit"=>"V"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-", "Einheit"=>"V"}},
"VM"=>{"BMV"=>{"Register"=>"0x0382","scale"=>1,"ReName"=>"-", "Einheit"=>"mV"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-", "Einheit"=>"V"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-", "Einheit"=>"V"}},
"DM"=>{"BMV"=>{"Register"=>"0x0383","scale"=>0.01,"ReName"=>"-", "Einheit"=>"V"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-", "Einheit"=>"V"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-", "Einheit"=>"V"}} ,
"VPV"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-", "Einheit"=>"V"}, "MPPT"=>{"Register"=>"0xEDBB","scale"=>0.001,"ReName"=>"-", "Einheit"=>"V"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-", "Einheit"=>"V"}},
"PPV"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDBC","scale"=>1,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"P"=>{"BMV"=>{"Register"=>"0xED8E","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"I"=>{"BMV"=>{"Register"=>"0xED8F","scale"=>0.001,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0.001,"ReName"=>"Battery_current", "Einheit"=>"A"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"IL"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDAD","scale"=>0.001,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"IPV"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDBD","scale"=>0.001,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"LOAD"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDA8","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"SOC"=>{"BMV"=>{"Register"=>"0x0FFF","scale"=>0.1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"T"=>{"BMV"=>{"Register"=>"0xEDEC","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"TTG"=>{"BMV"=>{"Register"=>"0x0FFE","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"CE"=>{"BMV"=>{"Register"=>"0xEEFF","scale"=>0.001,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H1"=>{"BMV"=>{"Register"=>"0x0300","scale"=>0.001,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H2"=>{"BMV"=>{"Register"=>"0x0301","scale"=>0.001,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H3"=>{"BMV"=>{"Register"=>"0x0302","scale"=>0.001,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H4"=>{"BMV"=>{"Register"=>"0x0303","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H5"=>{"BMV"=>{"Register"=>"0x0304","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H6"=>{"BMV"=>{"Register"=>"0x0305","scale"=>0.001,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H7"=>{"BMV"=>{"Register"=>"0x0306","scale"=>0.001,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H8"=>{"BMV"=>{"Register"=>"0x0307","scale"=>0.001,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H9"=>{"BMV"=>{"Register"=>"0x0308","scale"=>0.01666666667,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H10"=>{"BMV"=>{"Register"=>"0x0309","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H11"=>{"BMV"=>{"Register"=>"0x030A","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H12"=>{"BMV"=>{"Register"=>"0x030B","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H13"=>{"BMV"=>{"Register"=>"-","scale"=>1,"ReName"=>"Nr_of_low_aux_voltage_alarms"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H14"=>{"BMV"=>{"Register"=>"0x030C","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H15"=>{"BMV"=>{"Register"=>"0x030D","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H16"=>{"BMV"=>{"Register"=>"0x030E","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H17"=>{"BMV"=>{"Register"=>"0x0310","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H18"=>{"BMV"=>{"Register"=>"0x0311","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"H19"=>{"BMV"=>{"Register"=>"0xEDDC","scale"=>0.01,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDDC","scale"=>0.01,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0.01,"ReName"=>"-"}},
"H20"=>{"BMV"=>{"Register"=>"0xEDD3","scale"=>0.01,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDD3","scale"=>0.01,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0.01,"ReName"=>"-"}},
"H21"=>{"BMV"=>{"Register"=>"0xEDD2","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDD2","scale"=>1,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>1,"ReName"=>"-"}},
"H22"=>{"BMV"=>{"Register"=>"0xEDD1","scale"=>0.01,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDD1","scale"=>0.01,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0.01,"ReName"=>"-"}},
"H23"=>{"BMV"=>{"Register"=>"0xEDD0","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDD0","scale"=>1,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>1,"ReName"=>"-"}},
"ERR"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0xEDDA","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"0xEDDA","scale"=>0,"ReName"=>"-"}},
"CS"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0x0201","scale"=>1,"ReName"=>"-"}, "Inverter"=>{"Register"=>"0x0201","scale"=>1,"ReName"=>"-"}},
"SER#"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0x010A","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"0x010A","scale"=>0,"ReName"=>"-"}},
"HSDS"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"Day_sequence_nr"}, "Inverter"=>{"Register"=>"-","scale"=>1,"ReName"=>"Day_sequence_nr"}},
"MODE"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"0x0200","scale"=>1,"ReName"=>"Device_mode"}},
"AC_OUT_V"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"0x2200","scale"=>0.01,"ReName"=>"AC_OUT_VOLTAGE"}},
"AC_OUT_I"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"0x2201","scale"=>0.1,"ReName"=>"AC_OUT_CURRENT"}},
"WARN"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"0x031C","scale"=>0,"ReName"=>"-"}},
"Alarm"=>{"BMV"=>{"Register"=>"-","scale"=>1,"ReName"=>"Alarm_aktive"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
"AR"=>{"BMV"=>{"Register"=>"0x031E","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"0x031E","scale"=>0,"ReName"=>"Alarm_reason"}},
"OR"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"Off_reason"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"Off_reason"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"Off_reason"}},
"FW"=>{"BMV"=>{"Register"=>"-","scale"=>1,"ReName"=>"Firmwareversion"}, "MPPT"=>{"Register"=>"-","scale"=>1,"ReName"=>"Firmwareversion"}, "Inverter"=>{"Register"=>"-","scale"=>1,"ReName"=>"Firmwareversion"}},
"PID"=>{"BMV"=>{"Register"=>"0x0100","scale"=>0,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0x0100","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"0x0100","scale"=>0,"ReName"=>"-"}},
"BMV"=>{"BMV"=>{"Register"=>"-","scale"=>1,"ReName"=>"BMV"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},,
"Relay"=>{"BMV"=>{"Register"=>"0x034F","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"0x034F","scale"=>1,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}}, 
"MPPT"=>{"BMV"=>{"Register"=>"0x034F","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>1,"ReName"=>"MPP_Tracker_operation_mode"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}}, 
"Checksum"=>{"BMV"=>{"Register"=>"-","scale"=>0,"ReName"=>"Checksum"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"Checksum"}, "Inverter"=>{"Register"=>"Checksum","scale"=>0,"ReName"=>"-"}},
);


my %HistoryRecord = ("0"=>"Reserved,-,-,2" ,
                  "2"=>"Error_database,-,-,2" ,
                  "4"=>"Error_0,-,-,2" ,
                  "6"=>"Error_1,-,-,2" ,
                  "8"=>"Error_2,-,-,2" ,
                  "10"=>"Error_3,-,-,2" ,
                  "12"=>"Total_yield_resettable,kWh,0.01,8" ,
                  "20"=>"Total_yield_system,kWh,0.01,8" ,
                  "28"=>"Panel_voltage_maximum,V,0.01,4" ,
                  "32"=>"Battery_voltage_maximum,V,0.01,4" ,
                  "36"=>"Number_of_days_available,-,-,2" );
#0  1  2  3  4  5  6  7  8  9  10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33
#00 0B 00 00 00 03 00 00 00 9E 05 ED 04 00 00 00 00 00 9B 01 3C 00 5A 01 1E 00 00 00 14 00 1A 08 28 00
#00 Reserved
#0B Error_Database
#00 Error_0
#00 Error_1
#00 Error_2
#00 Error_3
#0000009E --> 0000 0300  --> Total_yield_resettable*0.01 kWh  6-9
#05 ED 04 00 --> 0004ED05  --> Total_yield_system,kWh,0.01
               
my %PrID =   ("600S"=>"BMV-600S ",
              "712 Smart"=>"BMV-712 Smart ",
              "0x203"=>"BMV-700 ", 
              "0x204"=>"BMV-702 ", 
              "0x205"=>"BMV-700H ",
              "0xA381"=>"BMV-712 Smart", 
              "0x0300"=>"BlueSolar MPPT 70|15* ", 
              "0xA040"=>"BlueSolar MPPT 75|50* ", 
              "0xA041"=>"BlueSolar MPPT 150|35* ", 
              "0xA042"=>"BlueSolar MPPT 75|15 ", 
              "0xA043"=>"BlueSolar MPPT 100|15 ", 
              "0xA044"=>"BlueSolar MPPT 100|30* ", 
              "0xA045"=>"BlueSolar MPPT 100|50* ", 
              "0xA046"=>"BlueSolar MPPT 150|70 ", 
              "0xA047"=>"BlueSolar MPPT 150|100 ", 
              "0xA049"=>"BlueSolar MPPT 100|50 rev2 ", 
              "0xA04A"=>"BlueSolar MPPT 100|30 rev2 ", 
              "0xA04B"=>"BlueSolar MPPT 150|35 rev2 ", 
              "0xA04C"=>"BlueSolar MPPT 75|10 ", 
              "0xA04D"=>"BlueSolar MPPT 150|45 ", 
              "0xA04E"=>"BlueSolar MPPT 150|60 ", 
              "0xA04F"=>"BlueSolar MPPT 150|85 ", 
              "0xA050"=>"SmartSolar MPPT 250|100 ", 
              "0xA051"=>"SmartSolar MPPT 150|100* ", 
              "0xA052"=>"SmartSolar MPPT 150|85* ", 
              "0xA053"=>"SmartSolar MPPT 75|15 ", 
              "0xA054"=>"SmartSolar MPPT 75|10 ", 
              "0xA055"=>"SmartSolar MPPT 100|15 ", 
              "0xA056"=>"SmartSolar MPPT 100|30 ", 
              "0xA057"=>"SmartSolar MPPT 100|50 ", 
              "0xA058"=>"SmartSolar MPPT 150|35 ", 
              "0xA059"=>"SmartSolar MPPT 150|100 rev2 ", 
              "0xA05A"=>"SmartSolar MPPT 150|85 rev2 ", 
              "0xA05B"=>"SmartSolar MPPT 250|70 ", 
              "0xA05C"=>"SmartSolar MPPT 250|85 ", 
              "0xA05D"=>"SmartSolar MPPT 250|60 ", 
              "0xA05E"=>"SmartSolar MPPT 250|45 ", 
              "0xA05F"=>"SmartSolar MPPT 100|20 ", 
              "0xA060"=>"SmartSolar MPPT 100|20 48V ", 
              "0xA061"=>"SmartSolar MPPT 150|45 ", 
              "0xA062"=>"SmartSolar MPPT 150|60 ", 
              "0xA063"=>"SmartSolar MPPT 150|70 ", 
              "0xA064"=>"SmartSolar MPPT 250|85 rev2 ", 
              "0xA065"=>"SmartSolar MPPT 250|100 rev2 ", 
              "0xA201"=>"Phoenix Inverter 12V 250VA 230V* ", 
              "0xA202"=>"Phoenix Inverter 24V 250VA 230V* ", 
              "0xA204"=>"Phoenix Inverter 48V 250VA 230V* ", 
              "0xA211"=>"Phoenix Inverter 12V 375VA 230V* ", 
              "0xA212"=>"Phoenix Inverter 24V 375VA 230V* ", 
              "0xA214"=>"Phoenix Inverter 48V 375VA 230V* ", 
              "0xA221"=>"Phoenix Inverter 12V 500VA 230V* ", 
              "0xA222"=>"Phoenix Inverter 24V 500VA 230V* ", 
              "0xA224"=>"Phoenix Inverter 48V 500VA 230V* ", 
              "0xA231"=>"Phoenix Inverter 12V 250VA 230V ", 
              "0xA232"=>"Phoenix Inverter 24V 250VA 230V ", 
              "0xA234"=>"Phoenix Inverter 48V 250VA 230V ", 
              "0xA239"=>"Phoenix Inverter 12V 250VA 120V ", 
              "0xA23A"=>"Phoenix Inverter 24V 250VA 120V ", 
              "0xA23C"=>"Phoenix Inverter 48V 250VA 120V ", 
              "0xA241"=>"Phoenix Inverter 12V 375VA 230V ", 
              "0xA242"=>"Phoenix Inverter 24V 375VA 230V ", 
              "0xA244"=>"Phoenix Inverter 48V 375VA 230V ", 
              "0xA249"=>"Phoenix Inverter 12V 375VA 120V ", 
              "0xA24A"=>"Phoenix Inverter 24V 375VA 120V ", 
              "0xA24C"=>"Phoenix Inverter 48V 375VA 120V ", 
              "0xA251"=>"Phoenix Inverter 12V 500VA 230V ", 
              "0xA252"=>"Phoenix Inverter 24V 500VA 230V ", 
              "0xA254"=>"Phoenix Inverter 48V 500VA 230V ", 
              "0xA259"=>"Phoenix Inverter 12V 500VA 120V ", 
              "0xA25A"=>"Phoenix Inverter 24V 500VA 120V ", 
              "0xA25C"=>"Phoenix Inverter 48V 500VA 120V ", 
              "0xA261"=>"Phoenix Inverter 12V 800VA 230V ", 
              "0xA262"=>"Phoenix Inverter 24V 800VA 230V ", 
              "0xA264"=>"Phoenix Inverter 48V 800VA 230V ", 
              "0xA269"=>"Phoenix Inverter 12V 800VA 120V ", 
              "0xA26A"=>"Phoenix Inverter 24V 800VA 120V ", 
              "0xA26C"=>"Phoenix Inverter 48V 800VA 120V ", 
              "0xA271"=>"Phoenix Inverter 12V 1200VA 230V ", 
              "0xA272"=>"Phoenix Inverter 24V 1200VA 230V ", 
              "0xA274"=>"Phoenix Inverter 48V 1200VA 230V ", 
              "0xA279"=>"Phoenix Inverter 12V 1200VA 120V ", 
              "0xA27A"=>"Phoenix Inverter 24V 1200VA 120V ", 
              "0xA27C"=>"Phoenix Inverter 48V 1200VA 120V ");  

#Alarm-Reason

my %ARtext=   ("0"=>"--",
               "2048"=>" High V AC out",
               "1024"=>" Low V AC out",
               "512"=>" DC-ripple",
               "256"=>" Overload",
               "128"=>"Mid Voltage",
               "64"=>" High Temperature",
               "32"=>" Low Temperature",
               "17"=>" Charger internal temperature too high",
               "16"=>" High Starter Voltage",
               "8"=>" Low Starter Voltage",
               "4"=>" Low SOC",
               "2"=>" High Voltage",
               "1"=>" Low Voltage");

                 
# ERR (Fehlercode)
#my %ERR =    ('0'=>"kein Fehler",
#              '2'=> "Battery voltage too high",
#              '17'=>"Charger temperature too high",
#              '18'=>"Charger over current",
#              '20'=>"Bulk time limit exceeded",
#              '26'=>"Terminals overheated",
#              '33'=>"Input voltage too high (solar panel)",
#              '34'=>"Input current too high (solar panel)",
#              '38'=>"Input shutdown (due to excessive battery voltage)",
#              '116'=>"Factory calibration data lost",
#              '117'=>"Invalid/incompatible firmware",
#              '119'=>"User settings invalid");
#
###### Mode
#my %MODE =   ('0'=>"--",
#              '1'=>"1",
#              '2'=>"Inverter",
#              '3'=>"3",
#              '4'=>"Off",
#              '5'=>"Eco");
#
#
## CS (State of Operation) 
#my %CS =    ('0'=>"OFF",
#             '1'=>"Low Power(load search)",
#             '2'=>"Fehler(off bis user reset)",
#             '3'=>"Bulk",
#             '4'=>"Absorption",
#             '5'=>"Float",
#             '6'=>"6 unknown",
#             '7'=>"Cell balancing",
#             '8'=>"8 unknown",
#             '9'=>"Inverting(on)");

##################################################################################################################################################
#Initialize 
##################################################################################################################################################

sub VEDirect_Initialize($)
{
  my ($hash) = @_;

  require "$attr{global}{modpath}/FHEM/DevIo.pm";

  $hash->{ReadFn}     = "VEDirect_Read";
  $hash->{ReadyFn}    = "VEDirect_Ready";
  $hash->{DefFn}      = "VEDirect_Define";
  $hash->{AttrFn}     = "VEDirect_Attr";
  $hash->{UndefFn}    = "VEDirect_Undef";
  $hash->{SetFn}      = "VEDirect_Set";
  $hash->{GetFn}      = "VEDirect_Get"; 
  $hash->{ShutdownFn} = "VEDirect_Shutdown";
  $hash->{AttrList}   = "do_not_notify:1,0 disable:0,1 disabledForIntervals IgnoreChecksum:1,0 LogHistoryToFile ".$readingFnAttributes;
  $hash->{helper}{BUFFER} = "";
} #UpdateTime_s:2,3,4,5,6,7,8,9,10,15,20,25,30  


##################################################################################################################################################
# Define
##################################################################################################################################################

sub VEDirect_Define($$)
{
  my ( $hash, $def ) = @_;
  my @a = split( "[ \t][ \t]*", $def );  
  
  return "wrong syntax: define <name> VEDirect [connection|none] [DeviceType]"
    if ( @a != 4 );

  DevIo_CloseDev($hash);
  my $name = $a[0];
  my $dev  = $a[2];
  my $type = $a[3];

  if ( $dev eq "none" )
  {
    Log3 undef, 1, "VEDirect device is none, commands will be echoed only";
    return undef;
  }
  $dev .= '@19200' if(not $dev =~ m/\@\d+$/);
  $hash->{DeviceName} = $dev;
  if ($type eq "BMV" || $type eq "MPPT" || $type eq "Inverter" )
  {
   $hash->{DeviceType} = $type;
  }
  else
  {
    return "wrong syntax: [DeviceType] must be 'BMV', 'MPPT' or 'Inverter'";
  }; 
  my $tmpSets = "";
  my $tmpGets = ""; 

  foreach my $key (sort keys %{ $Register{ $type } })
    {
      $tmpGets .= $Register{ $type }->{ $key }->{'getValues'}." " if($Register{ $type }->{ $key }->{'getValues'} ne "-");
      $tmpSets .= $Register{ $type }->{ $key }->{'setValues'}." " if($Register{ $type }->{ $key }->{'setValues'} ne "-");
    }
    Log3 $name, 2, "VEDirect ($name) - GET-Values fuer $type gesetzt: $tmpGets";
    Log3 $name, 2, "VEDirect ($name) - SET-Values fuer $type gesetzt: $tmpSets";
    $tmpGets .= "ConfigAll:noArg"." ";                   ## general Configuration request
    $tmpGets .= "History_all:noArg"." " if ($type eq "MPPT"); ##only MPPT
    $tmpSets .= "Restart:noArg"; #Restart command
    
    Log3 $name, 5, "$name - SET/GET-Values fuer $type gesetzt";
    $hash->{helper}{setusage} =" ".$tmpSets;
    $hash->{helper}{getusage} =" ".$tmpGets;
  
  $tmpSets = "";
  $tmpGets = "";
  $hash->{DeviceName} = $dev;
  $hash->{helper}{BUFFER} = "";
  #$hash->{helper}{updatetime} = "-";  
  my $ret = DevIo_OpenDev( $hash, 0, undef );

  ##("Timername", gettimeofday() + 30, "Funktionsname", $hash, 0);  
  #InternalTimer(gettimeofday() + 2, "VEDirect_PollShort", $hash, 0);
  return $ret; 
}

##################################################################################################################################################
# 
##################################################################################################################################################
sub VEDirect_Undef($$)    #
{                     #
  my ( $hash, $arg ) = @_;       #
  DevIo_CloseDev($hash);         #
  RemoveInternalTimer($hash);    #
  return undef;                  #
}    #

##################################################################################################################################################
# 
##################################################################################################################################################
sub VEDirect_Attr($$$$)
{
  my ( $cmd, $name, $attrName, $attrValue ) = @_;
  my $hash = $defs{$name};  
  # $cmd  - Vorgangsart - kann die Werte "del" (l?schen) oder "set" (setzen) annehmen
  # $name - Ger?tename
  # $attrName/$attrValue sind Attribut-Name und Attribut-Wert
    
  if ($cmd eq "set") 
  {
    if ($attrName eq "UpdateTime_s")
    {
      if ($attrValue < 1 || $attrValue >= 31) 
      {
        Log3 $name, 5, "VEDirect ($name) - Invalid attr $name $attrName $attrValue";
        return "Invalid value for $attrName: $attrValue";
      }
      else  {$hash->{helper}{updatetime} = "-";}
    }
    if ($attrName eq "LogHistoryToFile")
    {
      if ($attrValue eq "") 
      {
        Log3 $name, 5, "VEDirect ($name) - Invalid attr $name $attrName $attrValue";
        return "Invalid value for $attrName: $attrValue --> Please enter a /path/Filename.log";
      }
      else  
      {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        my @time = localtime();
        my $logtime = (23*3600)+(0*60)+0;
        my $secofday = ($hour * 3600) + ($min * 60) + $sec;
        if ($logtime > $secofday)
        {
         InternalTimer(gettimeofday() + ($logtime - $secofday), "VEDirect_LogHistory", $hash, 0); 
        }
        else
        {
          InternalTimer(gettimeofday() + (86400 -$secofday +  $logtime), "VEDirect_LogHistory", $hash, 0);
        }
        
      }
    }
  }
  if ($cmd eq "del") 
  {
    if ($attrName eq "UpdateTime_s")
    {
      $hash->{helper}{updatetime} = "-"; ##$shortPollTime_s = 10;
    }
  }
  return undef;
}
##################################################################################################################################################
# 
##################################################################################################################################################
sub VEDirect_Set($$@)
{
    my ($hash, $name, $cmd, @args) = @_;
    my $error;
    my $type = $hash->{DeviceType} ;
    my $usage = "unknown argument $cmd, choose one of $hash->{helper}{setusage}"; 
    return $usage if(($cmd eq "" || $cmd eq "?")); 
    Log3 $name, 4, "VEDirect ($name) - Set command: $cmd Arguments $args[0]";
 #------------------------------------------------------------------------
 # Register zum cmd suchen
    my $reg = "-";
    my $debugarg = $args[0];   
    my @keylist = keys %{ $Register{ $type } };
    Log3 $name, 4, "VEDirect ($name) - Set command --> Keylist: @keylist";
    for my $key (@keylist)
    {
      if (index($Register{ $type }->{ $key }->{'setValues'}, $cmd) != -1)
      {
          $reg = $key;
          last;  
      }
    }
 ##------------------------------------------------------------------------
 ## Informationen aus dem %Register zum Befehl holen und verarbeiten
    if ($reg ne "-")
      {
        Log3 $name, 5, "VEDirect ($name) - Set command: $cmd Arguments $args[0] ---> Register $reg identified";
        ##$reg = substr($reg, 2, 4);     # "0x" entfernen
        ##Befehlsaufbau: ":8"(Set-Befehl) plus "00" Flags plus "Datavalue"
        ##Command 8 ("Set") Returns a set response with the requested data or error is returned.
        ##uint16 the id of the value to set
        ##uint8 flags, should be set to zero
        ##type depends on id value
        my $command = ":8".substr($reg, 4, 2).substr($reg, 2, 2)."00";
        ##wenn args[0] eine nummer ist
        if ( $args[0] =~ /^[0-9,.]+.+/ ) 
        {
          $args[0] =~ /^[0-9,.]+$/;
          Log3 $name, 5, "VEDirect ($name) - Set pr?fe $args[0] auf Min- und Max-Werte";
          ##Auf min und max-Werte pr?fen
          if ($Register{ $type }->{ $reg }->{'min'} ne "-" && $Register{ $type }->{ $reg }->{'min'} ne "")
          {
             $args[0] = $Register{ $type }->{ $reg }->{'min'} if ($args[0] < $Register{ $type }->{ $reg }->{'min'});  
          }
          if ($Register{ $type }->{ $reg }->{'max'} ne "-" && $Register{ $type }->{ $reg }->{'max'} ne "")
          {
             $args[0] = $Register{ $type }->{ $reg }->{'max'} if ($args[0] > $Register{ $type }->{ $reg }->{'max'});  
          }

          $args[0] = $args[0] * ( 1 / ( $Register{ $type }->{ $reg }->{'Skalierung'} ));    
          Log3 $name, 5, "VEDirect ($name) - Set skalierter Setzwert: $args[0] ";
          $args[0] = sprintf("%02X", $args[0]);
          while(length($args[0]) < $Register{ $type }->{ $reg }->{'Payloadnibbles'})   
            {
              $args[0] = "0".$args[0];
            }
          $args[0] = substr($args[0],2,2).substr($args[0],0,2) if(length($args[0]) == 4); ##1234 --> 3412
          $args[0] = substr($args[0],6,2).substr($args[0],4,2).substr($args[0],2,2).substr($args[0],0,2) if(length($args[0]) == 8); ##01234567 --> 67452301 
        }
        else 
        {
          ##wenn args[0] keine nummer enth?lt
          my@setItems = split(",",substr($Register{ $type }->{ $reg }->{'setValues'}, index($Register{ $type }->{ $reg }->{'setValues'},":")));
          $setItems[0] = substr($setItems[0],1);
          my @setValues = split(':',$Register{ $type }->{ $reg }->{'spezialSetGet'});
          for my $v (0 .. $#setItems)
            {
              Log3 $name, 5, "VEDirect ($name) - SET: setItems: $setItems[$v] --> InputValue: $args[0]";
              if ($setItems[$v] eq $args[0])
              {
                $args[0] = $setValues[$v];
                $args[0] = "0".$args[0] if (length($args[0])==1 ||length($args[0])==3);
                last;
              }
            } 
        }
        $command .= $args[0];
        $command .= VEDirect_ChecksumHEX(0x55,$command);
        Log3 $name, 5, "VEDirect ($name) - VEDirect_Set command $cmd $debugarg - sending --> $command";
        DevIo_SimpleWrite($hash, $command, 2, 1) ;
    }    
    elsif($reg eq "-" && $cmd eq "Restart")
    {
      DevIo_SimpleWrite($hash, ":64F", 2, 1) ;
    }     
    else
    {
        return $usage;
    }  
  
  
  }

##################################################################################################################################################
# Get functions - !!!!!!!!!!!!!!!TBD!!!!!!!!!!!!!!!!
##################################################################################################################################################
sub VEDirect_Get($$@)
{
    my ($hash, $name, $cmd, @args) = @_;
    my $usage = "unknown argument $cmd, choose one of $hash->{helper}{getusage}";
    my $ret = "";
    my $type = $hash->{DeviceType} ; 
#------------------------------------------------------------------------
 # Register zum cmd suchen
    my $key = ""; 
    my $reg = "-"; 
    my $debugarg = $args[0]; 
 ##------------------------------------------------------------------------
 ## Informationen aus dem %Register zum Befehl holen und verarbeiten
    if ($cmd eq "History_all" && $type eq "MPPT")
    { 
       ## MPPT special Gets
       Log3 $name, 4, "VEDirect ($name) - get History_all ++++++++++++++++++++++++++++++++++++";  
       my @c;
       for my $c (0 ..29)
       {
        $reg = ":7".sprintf("%02X", (0x50 + $c))."1000";
        $reg .= VEDirect_ChecksumHEX(0x55,$reg);
        Log3 $name, 4, "VEDirect ($name) - get command $cmd $debugarg - sending --> $reg";  
        DevIo_SimpleWrite($hash, $reg, 2, 1) ; 
        push @c,$reg;
        Time::HiRes::sleep(0.2);
        my $resp = DevIo_SimpleRead($hash) ;
        
        $hash->{helper}{BUFFER} .= $resp;
        my $hexMsg ;
        if($resp =~ /(\:[0-9A-F][0-9A-F]++)\n/)
         {$hexMsg = $1;
          my $parse = VEDirect_ParseHEX($hash, $hexMsg) if(defined($hexMsg));
          push @c,$parse;
          Log3 $name, 4, "VEDirect $name Get: received >$parse<"; 
         }
       }
     return join("\n",@c)
    }
    elsif ($cmd eq "ConfigAll")
    {
      Log3 $name, 4, "VEDirect ($name) - get ConfigAll ++++++++++++++++++++++++++++++++++++";
      foreach my $key (keys %{ $Register{ $type } })
        {
          if ($Register{ $type }->{ $key }->{"getConfigAll"} == 1)
          {
            ##Befehlsaufbau: ":7"(Get-Befehl) plus "00" Flags plus checksum
            ##Command 7 ("Get") Returns a get response with the requested data or error is returned.
            ##uint16 the id of the value to set
            ##uint8 flags, should be set to zero         0x1234
            my $command = ":7".substr($key, -2, 2).substr($key, 2, 2)."00";
            $command .= VEDirect_ChecksumHEX(0x55,$command);
            DevIo_SimpleWrite($hash, $command, 2, 1) ; 
            Log3 $name, 4, "VEDirect ($name) - get command $cmd $debugarg - sending --> $command";
            Time::HiRes::sleep(0.1); 
            my $resp = DevIo_SimpleRead($hash) ;
            my $readAnswer = 0;
            if ($readAnswer == 1)
            {
              $hash->{helper}{BUFFER} .= $resp;
              my $hexMsg ;
              if($resp =~ /(\:[0-9A-F][0-9A-F]++)\n/)
               {$hexMsg = $1;
                return VEDirect_ParseHEX($hash, $hexMsg) if(defined($hexMsg));
               }
            }
          }
          
        }
    }
    else
    { 
      my @keylist = keys %{ $Register{ $type } };
      Log3 $name, 5, "VEDirect ($name) - VEDirect_Get Keylist: @keylist";
      for my $key (@keylist)
      {
        if (index($Register{ $type }->{ $key }->{"getValues"}, $cmd) != -1)
        {
            $reg = $key;
            last;  
        }
      }
      ##------------------------------------------------------------------------
      if ($reg ne "-")
      {
        Log3 $name, 4, "VEDirect ($name) - Get command: $cmd  ---> Register $reg identified";    
        ##Befehlsaufbau: ":7"(Get-Befehl) plus "00" Flags plus checksum
        ##Command 7 ("Get") Returns a get response with the requested data or error is returned.
        ##uint16 the id of the value to set
        ##uint8 flags, should be set to zero
        my $command = ":7".substr($reg, -2, 2).substr($reg, 2, 2)."00";
        if ($Register{ $type }->{ $key }->{"getValues"} ne "-")
        {
          $command .= VEDirect_ChecksumHEX(0x55,$command); 
          Log3 $name, 4, "VEDirect ($name) - get command $cmd $debugarg - sending --> $command";
          DevIo_SimpleWrite($hash, $command, 2, 1) ;  
          ##++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
          my $buf = "";
          
          ##Log3 $name, 5, "VEDirect ($name) - Read Received DATA --> /n".$buf;
            #**********************************************************************************************************
            #pruefen, ob Hex-Nachrichten enthalten sind
           my $cntWhile = 0;    
           while (index($buf,":") != -1 && $cntWhile <= 50)         
            { 
              ##return "" if ( !defined($buf) ); #keine Daten im Buffer enthalten -> abbruch 
              $buf = DevIo_SimpleRead($hash) ;
              $buf = $hash->{helper}{BUFFER}.$buf ;
              $cntWhile +=1;
              my $hexMsg = "" ;
              if($buf =~ /(\:[0-9A-F][0-9A-F]++\n)/)
              {
               $hexMsg = $1;
               $buf =~ s/$hexMsg//;  #hex-Nachricht entfernen
               Log3 $name, 5, "VEDirect ($name) - Read: cutting Hex-MSG: >$hexMsg<";
               return VEDirect_ParseHEX($hash, $hexMsg);  #ParseHex-funktion aufrufen (direkte Auswerung der Daten) 
               last;
              } 
            } 
          
        }
      }
      else
      {
        return $usage;
      }
    }  
}
##################################################################################################################################################
# 
##################################################################################################################################################

sub VEDirect_PollShort($)
{
    ##shortpoll -> regelm??ig einen Ping senden das senden von HEX-Nachrichten der Ger?te aufrecht zu halten
    my $hash = shift;
    RemoveInternalTimer($hash);    #delete all old timer
    my $name = $hash->{NAME};
    my $key = "";
    my $type = $hash->{DeviceType} ; 
    my $command = ":154";
      DevIo_SimpleWrite($hash, $command, 2, 1) ;    
      InternalTimer(gettimeofday() + 10, "VEDirect_PollShort", $hash, 0);
}

##################################################################################################################################################
# Read-Funktion
# 1. Daten aus dem Buffer holen
# 2. Daten von Seriell einlesen und an buffer anh?ngen 
# 3. Pr?fen, on Hex-Nachrichten enthalten sind
# 4. Pr?fen ob eini kompletter block enthalten ist 
# nein --> Daten in Buffer schreiben
# ja -->  auswerten
##################################################################################################################################################
sub VEDirect_Read($$$)
{
  my ($hash,$Values,$Text) = @_;
  my $name = $hash->{NAME};   
  return if(IsDisabled($name));
  my $hexMsg;   #Variable fuer HEX-Nachrichten
  my $cntChecksum = 0; 
  my $type = $hash->{DeviceType} ; 
  my @tmpData;
  ###### Daten der seriellen Schnittstelle holen 
  my $buf = DevIo_SimpleRead($hash) ;
  return "" if ( !defined($buf) ); #keine Daten im Buffer enthalten -> abbruch 
  $buf = $hash->{helper}{BUFFER}.$buf ;
  ##Log3 $name, 5, "VEDirect ($name) - Read Received DATA --> /n".$buf;
    #**********************************************************************************************************
    #pruefen, ob Hex-Nachrichten enthalten sind
   my $cntWhile = 0;    
   while (index($buf,":") != -1 && $cntWhile <= 50)         
    { 
      $cntWhile +=1;
      my $hexMsg = "" ;
      if($buf =~ /(\:[0-9A-F][0-9A-F]++\n)/)
      {
       $hexMsg = $1;
       $buf =~ s/$hexMsg//;  #hex-Nachricht entfernen
       Log3 $name, 5, "VEDirect ($name) - Read: cutting Hex-MSG: >$hexMsg<";
       VEDirect_ParseHEX($hash, $hexMsg);  #ParseHex-funktion aufrufen (direkte Auswerung der Daten)
      } 
    } 
    #----------------------------------------------------------------------------------------------------------------
    #Text-Nachrichten Auswerten
#   if(defined($attr{$name}) && defined($attr{$name}{"UpdateTime_s"}))
#   {
#     Log3 $name, 3, "VEDirect ($name) - Read: Updatetime: $hash->{helper}{updatetime}";
#     if($hash->{helper}{updatetime} ne "-")
#     {
#       #pr?fen, ob die aktuelle zeit gr??er als die mindestzeit ist
#       #$hash->{helper}{updatetime} = gettimeofday() + $attr{$name}{"UpdateTime_s"} if(gettimeofday() < ($hash->{helper}{updatetime} - $attr{$name}{"UpdateTime_s"})); 
#       my @tod = gettimeofday();
#       Log3 $name, 3, "VEDirect ($name) - Read: Updatetime: $hash->{helper}{updatetime} --> timeofday: $tod[0]";
#       if($tod[0] < $hash->{helper}{updatetime}) 
#       {
#         $hash->{helper}{BUFFER} = "";
#         Log3 $name, 3, "VEDirect ($name) - Read: Buffer cleared";
#         return "";
#       }
#     }
#     else
#     {
#       #neue mindestzeit setzen
#       my @tod = gettimeofday();
#       $hash->{helper}{updatetime} = $tod[0] + $attr{$name}{"UpdateTime_s"};
#       #funktion verlassen
#       $hash->{helper}{BUFFER} = "";
#       Log3 $name, 2, "VEDirect ($name) - Read: Buffer cleared";
#       return "";
#     }
#   }
   
   
   #Pr?fen auf Text-Felder und Checksum

   Log3 $name, 4, "VEDirect ($name) - Read: Actual Buffer: >$buf<";
   my ($start1, $start2);
   if(index($startBlock{$type},"|") != -1)
   {
    ($start1, $start2) = split("|",$startBlock{$type});
   }
   else
   {
    $start1 = $start2 = $startBlock{$type};
   }
   if ((index($buf,$start1) != -1 || index($buf,$start2) != -1) && index($buf,"Checksum\t") != -1)
   {
     $start1 =~ s/\r\n//gm;
     $start2 =~ s/\r\n//gm;
     my $outstr;
     my @buffer = split("\r\n",$buf);
     for my $i (0 .. $#buffer)
      {
        my $txtMsg = shift(@buffer);
        if($txtMsg =~ /(Checksum\t.)/)
        {
          $outstr .= "\r\n".$txtMsg;
          Log3 $name, 5, "VEDirect ($name) - Read: Checksum found - Block completed";
          last;
        }
        elsif($txtMsg =~ /([A-Z]+.*[0-9]{0,2}\t.+)/) 
        {
          $outstr .= "\r\n" if!(index($txtMsg,$start1) > -1 || index($txtMsg,$start2) > -1) ;
          $outstr .= $txtMsg ;
          Log3 $name, 5, "VEDirect ($name) - Read: TXT-MSG found: >$txtMsg<";
        }
      }
     #$buf = s/ eval($outstr) //gm;
     my $chk = VEDirect_ChecksumTXT($outstr);
     Log3 $name, 4, "VEDirect ($name) - Read: Checksum-Testergebnis: $chk";
     if($chk == 0)
     {
       @buffer = split("\r\n",$outstr);
       Log3 $name, 4, "VEDirect ($name) - Read: Checksum ok --> start parsing <<$outstr>>";
       VEDirect_ParseTXT($hash, @buffer);
       @buffer = ();
     }
     else
     {
       Log3 $name, 4, "VEDirect ($name) - Read: Checksum not ok --> CLR block in Buffer";
       @buffer = ();
     }
     $hash->{helper}{BUFFER} = "";#$buf if(defined($buf)); 
   }
   else
   {
     Log3 $name, 5, "$name - Read: Nachrichtenblock unvollstaendig - warte...";
     # update $hash->{PARTIAL} with the current buffer content 
     $hash->{helper}{BUFFER} = $buf;
   }
   
    $hash->{helper}{BUFFER} = "" if (length($hash->{helper}{BUFFER}) > 2000);   
}     

##################################################################################################################################################
# 
##################################################################################################################################################
sub VEDirect_ParseTXT($@)
{
    my ($hash, @e) = @_;
    my $name = $hash->{NAME}; 
    my $type = $hash->{DeviceType} ;
    my $ChecksumValue = 1;

    Log3 $name, 4, "VEDirect ($name) - ParseTXT: Checksumme ok --> Start Auswertung";
    readingsBeginUpdate($hash);
    readingsBulkUpdate($hash,"SerialTextInput",join("\n",@e));
    for my $i (0 .. int(@e))
    {
      #Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- ";
      
      my $cnt = int(@e);
      Log3 $name, 5, "VEDirect ($name) - ParseTXT: Schleife $i von $cnt";
      next if(index($e[$i],"\t") == -1);
      my @raw = split("\t",$e[$i]); 
      next if($raw[0] eq "Checksum");
      next if($raw[0] eq "");
      $raw[0] =~ s/\r\n//g;
      if (defined($TextMapping{ $raw[0] } )) 
      {
        if($raw[0] eq "WARN")
        {
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: SelCase Warn";
          my $Reg =$TextMapping{ $raw[0] }->{ $type }->{'Register'};
          my $Reading = $Register{ $type }->{ $Reg }->{'ReadingName'};
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- Updating Register $Reg -->$Reading --> $raw[1] ";
          readingsBulkUpdateIfChanged($hash,$Reading,$raw[1]);
        }
        elsif($raw[0] eq "AR")
        {
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: SelCase AR";
          my $Reading;
          if ($TextMapping{ $raw[0] }->{ $type }->{'Register'} eq "-")
          {
            $Reading = $TextMapping{ $raw[0] }->{ $type }->{'ReName'};
          }
          else
          {
            my $Reading = $Register{ $type }->{ $TextMapping{ $raw[0] }->{ $type }->{'Register'} }->{'ReadingName'};
          } 
          
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- Updating Register >--< --> $Reading --> $raw[1] ";
          $raw[1] = $ARtext{$raw[1]} if (defined($ARtext{$raw[1]}));
          readingsBulkUpdateIfChanged($hash,$Reading,$raw[1]);
        }
        elsif($raw[0] eq "MPPT")
        {
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: SelCase MPPT";
          my $Reading = $TextMapping{ $raw[0] }->{ $type }->{'ReName'};
          
          my $Rvalue;
          $Rvalue = "Off" if($raw[1] == 0);
          $Rvalue = "Voltage_or_current_limited" if($raw[1] == 1);
          $Rvalue = "Active" if($raw[1] == 2);
          readingsBulkUpdateIfChanged($hash,$Reading,$Rvalue);
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- Updating Register - --> $Reading --> $Rvalue ";
        }
        elsif($raw[0] eq "OR")
        {
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: SelCase OR(off-reason)";
          my $Reading = $TextMapping{ $raw[0] }->{ $type }->{'ReName'};
          
          my $Rvalue;
          $Rvalue = "Device is active" if($raw[1] eq "0x00000000");
          $Rvalue = "No input power" if($raw[1] eq "0x00000001");
          $Rvalue = "Switched off(power switch)" if($raw[1] eq "0x00000002");
          $Rvalue = "Switched off(device mode register)" if($raw[1] eq "0x00000004");
          $Rvalue = "Remote input" if($raw[1] eq "0x00000008");
          $Rvalue = "Protection active" if($raw[1] eq "0x00000010");
          $Rvalue = "Paygo" if($raw[1] eq "0x00000020");
          $Rvalue = "BMS" if($raw[1] eq "0x00000040");
          $Rvalue = "Engine shutdown detection" if($raw[1] eq "0x00000080");
          $Rvalue = "Analysing input voltage" if($raw[1] eq "0x00000100");
          readingsBulkUpdateIfChanged($hash,$Reading,$Rvalue);
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- Updating Register - --> $Reading --> $Rvalue ";
        }
        elsif($raw[0] eq "PID")
        {
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: SelCase PID1";
          my $Reg =$TextMapping{ $raw[0] }->{ $type }->{'Register'};
          my $Reading = $Register{ $type }->{ $Reg }->{'ReadingName'}; 
          $raw[1] =~ s{^\s+|\s+$}{}g ;
          if($PrID{$raw[1]} ne "")
          {
           Log3 $name, 5, "VEDirect ($name) - ParseTXT: SelCase PID2";
           my $Rvalue = $PrID{ $raw[1] }; 
           Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- Updating Register $Reg -->$Reading --> $Rvalue ";
           readingsBulkUpdateIfChanged($hash,$Reading,$Rvalue);
          }
          else
          {
            Log3 $name, 5, "VEDirect ($name) - ParseTXT: SelCase PID3";
            Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- Updating Register $Reg -->$Reading --> $raw[1] ";
            readingsBulkUpdateIfChanged($hash,$Reading,$raw[1]);
          }
        }
        elsif($raw[0] eq "FW")
        {
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: SelCase FW";
          my $Reading = $TextMapping{ $raw[0] }->{ $type }->{'ReName'};
          my $Rvalue = substr($raw[1],1,1).".".substr($raw[1],2);
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- Updating Register <--> -->$Reading --> $Rvalue ";
          readingsBulkUpdateIfChanged($hash,$Reading,$Rvalue);
        }
        elsif ($TextMapping{$raw[0]}->{$type}->{'Register'} ne "-" && $raw[0] ne "PID" && $raw[0] ne "WARN" && $raw[0] ne "AR" && $raw[0] ne "FW")
        {
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: SelCase Reg ne -";
          #Register bekannt --> Auswerten und Reading schreiben
          my $Reg = $TextMapping{ $raw[0] }->{ $type }->{'Register'}; 
          my $scale = $TextMapping{ $raw[0] }->{ $type }->{'scale'};
          my $Reading = $Register{ $type }->{ $Reg }->{'ReadingName'};
          my $Rvalue = $raw[1];
          #Keine Spezial-Se/getwerte vorhanden
          if ($Register{ $type }->{ $Reg }->{'spezialSetGet'} eq "-")
          {
            $Rvalue = $Rvalue * $scale if($scale != 0);
            $Rvalue .= " ".$Register{ $type }->{ $Reg }->{'Einheit'};
          }
          #Spezial-Se/getwerte vorhanden
          else
          {
            #0x0201'=>{"Bezeichnung"=>"Device_state", "ReadingName"=>"Charger_state", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", 
            #"getValues"=>"Charger_state:not_charging,,fault,bulk,absorption,float,equalize,ess", "setValues"=>"-", "spezialSetGet"=>"0:1:2:3:4:5:7:9:252"},
            my @setvalues; 
            Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- setvalues: $Register{ $type }->{ $Reg }->{'setValues'}";
            Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- getvalues: $Register{ $type }->{ $Reg }->{'getValues'}";
            if($Register{ $type }->{ $Reg }->{'setValues'} ne "-")
            {@setvalues = split(",",substr($Register{ $type }->{ $Reg }->{'setValues'}, index($Register{ $type }->{ $Reg }->{'setValues'},":")));
             $setvalues[0] = substr($setvalues[0],1);}
            elsif($Register{ $type }->{ $Reg }->{'getValues'} ne "-")
            {@setvalues = split(",",substr($Register{ $type }->{ $Reg }->{'getValues'},index($Register{ $type }->{ $Reg }->{'getValues'},":")));
             $setvalues[0] = substr($setvalues[0],1);} 
            my @specialsetvalues = split(":", $Register{ $type }->{ $Reg }->{'spezialSetGet'}) ;
            for my $v (0 .. $#specialsetvalues)
            {
              Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- spezialgetValue: $specialsetvalues[$v] --> InputValue: $Rvalue";
              if ($specialsetvalues[$v] == $Rvalue)
              {
                $Rvalue = $setvalues[$v];
                last;
              }
            }
          }
          #readingsBulkUpdateIfChanged($hash, $reading, $value);
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- Updating Register $Reg -->$Reading --> $Rvalue ";
          readingsBulkUpdateIfChanged($hash,$Reading,$Rvalue);
        }
        else
        {
          #Register unbekannt --> Auswerten und ReadinNamen aus TexMapping nutzen   
          my $scale = $TextMapping{ $raw[0] }->{ $type }->{'scale'};
          my $Reading = $TextMapping{ $raw[0] }->{ $type }->{'ReName'};
          my $Rvalue = $raw[1];
          my $Einheit = $TextMapping{ $raw[0] }->{ $type }->{'Einheit'};
          $Rvalue = $Rvalue * $scale if ($scale ne "0");
          $Rvalue .= " ".$Einheit if defined($Einheit) ;
          #readingsBulkUpdateIfChanged($hash, $reading, $value); 
          Log3 $name, 5, "VEDirect ($name) - ParseTXT: Text --> $e[$i] <-- Updating Register unbekannt -->$Reading --> $Rvalue ";
          readingsBulkUpdateIfChanged($hash,$Reading,$Rvalue) if($Reading ne "Checksum" && $Reading ne "-");
        }  
      }
      else
      {
        Log3 $name, 5, "VEDirect ($name) - ParseTXT: Txt-Value <( $raw[0] )> unbekannt --> Wert: $raw[1]";
      }
    }
  readingsEndUpdate( $hash, 1 );  
  @e = ();

}

##################################################################################################################################################
# ParseHEX
##################################################################################################################################################
sub VEDirect_ParseHEX($$)
{
 my ($hash, $msg) = @_;
 my $name = $hash->{NAME};
 my $type = $hash->{DeviceType}; 
 my $id; # = substr($msg,2,4);
 my @reading;
 my $checksum; # = substr($msg,-2,2);


 Log3 $name, 4, "VEDirect ($name) - ParseHex received $msg";       #:AD5ED009D05E7
 ##auf g?ltige Checksumme pr?fen
 if(substr($msg,0,2) eq ":A")
  {return undef if(VEDirect_ChecksumHEX(0x55,$msg) eq 0xD);}
 else
  {return undef if(VEDirect_ChecksumHEX(0x55,$msg) eq 0);} 
  
 Log3 $name, 4, "VEDirect ($name) - ParseHex Checksum ok in $msg";   
 
 ##-----------------------------------------------------------------
 ##g?ltige Checksumm empfangen - Auswerten
 my $response = substr($msg,1,1);
 my $registerNummer;
 my $flags = substr($msg,6,2);
  my $payload; 
 if(substr($msg,0,2) eq ":A")
  {
   #Async message
   $id = "0x".substr($msg,4,2).substr($msg,2,2);   #:A D7ED 00 0E00 79     --> Reg:EDD7 Flag:00, Value 000E  (Scalierung 0,1A , 4 Paylodnibbles)
   Log3 $name, 5, "VEDirect ($name) - ParseHex: Receives Async Msg: $msg for RegisterID $id";
    if ( defined ($Register{ $type }->{ $id }))
    { 
      
      if(defined($Register{ $type }->{ $id }->{'Payloadnibbles'}))
      {
         my $Payloadnibbles = $Register{ $type }->{ $id }->{'Payloadnibbles'};
         if($Payloadnibbles >=30)
         {
            Log3 $name, 4, "VEDirect ($name) - ParseHex: ReceiveHistory MSG";
            $payload = substr($msg,8,length($msg)-10);
            $payload =  VEDirect_ParseHistory($hash, $id, $payload);
            my $Hdate = POSIX::strftime("%Y%m%d",localtime(time+86400*$Register{ $type }->{ $id }->{'Skalierung'}));
            readingsSingleUpdate($hash, "History_".$Hdate, $payload, 1);
            #readingsSingleUpdate($hash, "H_".$Register{ $type }->{ $id }->{'ReadingName'}, $payload." ".$Einheit, 1);
         }
         else
         {
          $payload = substr($msg,8,$Payloadnibbles);
          $payload = substr($payload,2,2).substr($payload,0,2) if($Payloadnibbles ==4); #1234 --> 3412
          $payload = substr($payload,6,2).substr($payload,4,2).substr($payload,2,2).substr($payload,0,2) if($Payloadnibbles ==8); #01234567 --> 67452301
          $payload = int(hex($payload))*$Register{ $type }->{ $id }->{'Skalierung'} if($Register{ $type }->{ $id }->{'Skalierung'} != "" || !defined($Register{ $type }->{ $id }->{'Skalierung'}));
         }
        if ($Register{ $type }->{ $id }->{'spezialSetGet'} ne "-")
          {
             my @setvalues; 
            Log3 $name, 5, "VEDirect ($name) - ParseHEX: payload --> $payload <-- setvalues: $Register{ $type }->{ $id }->{'setValues'}";
            Log3 $name, 5, "VEDirect ($name) - ParseHEX: payload --> $payload <-- getvalues: $Register{ $type }->{ $id }->{'getValues'}";
            if($Register{ $type }->{ $id }->{'setValues'} ne "-")
            {@setvalues = split(",",substr($Register{ $type }->{ $id }->{'setValues'}, index($Register{ $type }->{ $id }->{'setValues'},":")));
             $setvalues[0] = substr($setvalues[0],1);}
            elsif($Register{ $type }->{ $id }->{'getValues'} ne "-")
            {@setvalues = split(",",substr($Register{ $type }->{ $id }->{'getValues'},index($Register{ $type }->{ $id }->{'getValues'},":")));
             $setvalues[0] = substr($setvalues[0],1);} 
            my @specialsetvalues = split(":", $Register{ $type }->{ $id }->{'spezialSetGet'}) ;
            for my $v (0 .. $#specialsetvalues)
            {
              $payload = int(hex($payload)) ;
              Log3 $name, 5, "VEDirect ($name) - ParseHEX: Text --> $payload <-- spezialgetValue: $specialsetvalues[$v] --> InputValue: $payload";
              if ($specialsetvalues[$v] == $payload)
              {
                $payload = $setvalues[$v];
                last;
              }
            }
          }
         
         readingsSingleUpdate($hash, $Register{ $type }->{ $id }->{'ReadingName'}, $payload." ".$Register{ $type }->{ $id }->{'Einheit'}, 1); 
         Log3 $name, 4, "VEDirect ($name) - VEDirect_ParseHex Updated Reading $Register{ $type }->{ $id }->{'ReadingName'} with Value $payload";
      }
      else
      {
       #$payload = substr($msg,8,length($msg)-10);
       #readingsSingleUpdate($hash, "H_ID_".$id, $payload, 1);
      }
    }
  }   
 elsif($response == "1")
  {
   #Done
  }
 elsif($response == "3")
  {
   #Unknown
   Log3 $name, 2, "VEDirect ($name) - Hex_Message_Error -Unknown command";   
   return "Hex_Message_Error -Unknown command";
   
  }
 elsif($response == "4")
  {
   #Error
   Log3 $name, 2, "VEDirect ($name) - Hex_Message_Error -Frame error";
   return "Hex_Message_Error -Frame error"; 
   
  }
 elsif($response == "5")
  {
   #Ping
   $payload = substr($msg,2,4);
   $payload = substr($payload, 3, 1).".".substr($payload, 1, 2);
   readingsSingleUpdate($hash, "Firmware", $payload, 1);  
   return "Firmware: ".$payload;
  }
 elsif($response == "7" || $response == "8")
  {
   #Get
   #Nibble 0:':'
   #Nibble 1:'7'
   #Nibble 2,3,4,5:ID
   #Nibble 6,7:Flag
   #Nibble 8 bis 8+laengePayload;Payload
    $id = "0x".substr($msg,4,2).substr($msg,2,2);
     Log3 $name, 4, "VEDirect ($name) - ParseHex: Received set / get-answer for ID: $id";
    if (defined $Register{ $type }->{ $id })
     { 
        if(defined($Register{ $type }->{ $id }->{'Payloadnibbles'}))
        {
           my $Payloadnibbles = $Register{ $type }->{ $id }->{'Payloadnibbles'};
           $payload = substr($msg,8,length($msg)-10);
           #History empfangen, wenn Payloadnibbles > 30
           if ($Payloadnibbles >= 30)
           {
            $payload =  VEDirect_ParseHistory($hash, $id, $payload);
            my $Hdate = POSIX::strftime("%Y%m%d",localtime(time+86400*$Register{ $type }->{ $id }->{'Skalierung'}));
            readingsSingleUpdate($hash, "History_".$Hdate, $payload, 1);
            ##readingsSingleUpdate($hash, "H_".$Bezeichnung, $payload." ".$Einheit, 1);
           }
           else
           {
              #normale get-Response erhalten   
              $payload = $payload if($Payloadnibbles == 0);   #Payload enthaelt einen String
              $payload = substr($payload,2,2).substr($payload,0,2) if($Payloadnibbles == 4); #1234 --> 3412
              $payload = substr($payload,6,2).substr($payload,4,2).substr($payload,2,2).substr($payload,0,2) if($Payloadnibbles == 8); #01234567 --> 67452301
              $payload = int(hex($payload))*$Register{ $type }->{ $id }->{'Skalierung'} if($Register{ $type }->{ $id }->{'Skalierung'} ne "-"); 
              #SpecialSetGet auswerten 
              if ($Register{ $type }->{ $id }->{'spezialSetGet'} ne "-")
                {
                   my @setvalues; 
                  Log3 $name, 5, "VEDirect ($name) - ParseHEX: payload --> $payload <-- setvalues: $Register{ $type }->{ $id }->{'setValues'}";
                  Log3 $name, 5, "VEDirect ($name) - ParseHEX: payload --> $payload <-- getvalues: $Register{ $type }->{ $id }->{'getValues'}";
                  if($Register{ $type }->{ $id }->{'setValues'} ne "-")
                  {@setvalues = split(",",substr($Register{ $type }->{ $id }->{'setValues'}, index($Register{ $type }->{ $id }->{'setValues'},":")));
                   $setvalues[0] = substr($setvalues[0],1);}
                  elsif($Register{ $type }->{ $id }->{'getValues'} ne "-")
                  {@setvalues = split(",",substr($Register{ $type }->{ $id }->{'getValues'},index($Register{ $type }->{ $id }->{'getValues'},":")));
                   $setvalues[0] = substr($setvalues[0],1);} 
                  my @specialsetvalues = split(":", $Register{ $type }->{ $id }->{'spezialSetGet'}) ;
                  $payload = int(hex($payload)) ;
                  for my $v (0 .. $#specialsetvalues)
                  {
                    
                    Log3 $name, 5, "VEDirect ($name) - ParseHEX: Text --> $payload <-- spezialgetValue: $specialsetvalues[$v] --> InputValue: $payload";
                    if ($specialsetvalues[$v] == $payload)
                    {
                      $payload = $specialsetvalues[$v];
                      last;
                    }
                  }
                }
              else
                {
                    
                }
              if ($Register{ $type }->{ $id }->{'Einheit'} eq "-")
                {
                  readingsSingleUpdate($hash, $Register{ $type }->{ $id }->{'ReadingName'}, $payload, 1);
                  Log3 $name, 5, "VEDirect ($name) - ParseHEX: Setting Reading".$Register{ $type }->{ $id }->{'ReadingName'}."($id) to $payload.";## ".$Register{ $type }->{ $id }->{'Einheit'}";  
                  return $payload;        
                }
              else
                {
                  readingsSingleUpdate($hash, $Register{ $type }->{ $id }->{'ReadingName'}, $payload." ".$Register{ $type }->{ $id }->{'Einheit'}, 1); 
                  Log3 $name, 5, "VEDirect ($name) - ParseHEX: Setting Reading".$Register{ $type }->{ $id }->{'ReadingName'}."($id) to $payload.";## ".$Register{ $type }->{ $id }->{'Einheit'}"; 
                  return $payload." ".$Register{ $type }->{ $id }->{'Einheit'};
                }
           }
        }
      else
      {
       Log3 $name, 5, "VEDirect ($name) - ParseHEX: Undefined payloadlength for $Register{ $type }->{ $id }->{'Bezeichnung'} ($id)"; 
       return undef;
      }
     }
   else
     {
      #nichts tun
     }
  }
  else{}
 return  $payload;
}
##################################################################################################################################################
#ParseHistory 
##################################################################################################################################################

sub VEDirect_ParseHistory($$$)
{
 my ($hash, $register, $msg) = @_;
 my $name = $hash->{NAME};
 my $type = $hash->{DeviceType}; 
 my $ret = $msg;
 my $totalYieldres;
 my $totalYieldSys;
 my $pvMax;
 my $BattVMax;
 my $NrDayAvailable;
 my $BattVMin ;
 my @databytes;
 my $logstr;
 my $faktorWh = 0.01;
 my $ReadingWh = " kWh";
 my $i=0;
 for $i (0 .. length($msg))
 {
  next if $i % 2 == 1; 
  my $sustr = substr($msg,$i,2);
  push @databytes, $sustr;
 }
 readingsBeginUpdate($hash);
 $logstr = join("-",@databytes);
 Log3 $name, 5, "VEDirect ($name) - VEDirect_ParseHistory: $register --> $logstr"; 
 if ($register eq "0x104F")
 {
   $totalYieldres = $databytes[9].$databytes[8].$databytes[7].$databytes[6] if(defined($databytes[9])); 
   $totalYieldres = (int(hex($totalYieldres)) * $faktorWh).$ReadingWh if(defined($databytes[9])) ;
   
   $totalYieldSys = $databytes[13].$databytes[12].$databytes[11].$databytes[10] if(defined($databytes[13]));
   $totalYieldSys = (int(hex($totalYieldSys)) * $faktorWh).$ReadingWh if(defined($databytes[13]));
   
   $pvMax = $databytes[15].$databytes[14] if(defined($databytes[15]));
   $pvMax = (int(hex($pvMax)) * 0.01)." V"    if(defined($databytes[15]));
   
   $BattVMax =  $databytes[17].$databytes[16] if(defined($databytes[17]));
   $BattVMax = (int(hex($BattVMax)) * 0.01)." V" if(defined($databytes[17]));
   
   $NrDayAvailable =  $databytes[18] if(defined($databytes[18]));
   $NrDayAvailable = int(hex($NrDayAvailable)) if(defined($databytes[18]));
   
   $BattVMin = $databytes[20].$databytes[19] if(defined($databytes[20]));
   $BattVMin = (int(hex($BattVMin)) * 0.01)." V" if(defined($databytes[20]));
   readingsBulkUpdateIfChanged($hash,$Register{ $type }->{'0xEDDC'}->{'ReadingName'},$totalYieldres);
   readingsBulkUpdateIfChanged($hash,$Register{ $type }->{'0xEDDD'}->{'ReadingName'},$totalYieldSys);
   
   $ret = "Tot_Sys_res: ".$totalYieldres.
         " |Tot_Sys: ".$totalYieldSys.
      " |PvMax: ".$pvMax.
      " |BattVMax: ".$BattVMax.
      " |BattVMin: ".$BattVMin.
      " |NrDays: ".$NrDayAvailable;
 }
 else
 {
   my $consumed; my $timeBulk; my $timeAbsorb; my $timeFloat; my $Pmax; my $Imax; my $dsn;
   Log3 $name, 5, "VEDirect ($name) - VEDirect_ParseHistory: $register --> $logstr"; 
   $totalYieldres = $databytes[4].$databytes[3].$databytes[2].$databytes[1] if(defined($databytes[4])); 
   $totalYieldres = (int(hex($totalYieldres)) * $faktorWh)." kWh" if(defined($databytes[4])) ;
   
   $consumed = $databytes[8].$databytes[7].$databytes[6].$databytes[5] if(defined($databytes[13]));
   if(defined($databytes[13]) && $consumed ne "FFFFFFFF")
   {
    ##$consumed = "n.a.";
    $consumed = (int(hex($consumed)) * $faktorWh).$ReadingWh if($consumed ne "FFFFFFFF");
   }
   
   $BattVMax =  $databytes[10].$databytes[9] if(defined($databytes[10]));
   $BattVMax = (int(hex($BattVMax)) * 0.01)." V" if(defined($databytes[10]));
   
   $BattVMin = $databytes[12].$databytes[11] if(defined($databytes[12]));
   $BattVMin = (int(hex($BattVMin)) * 0.01)." V" if(defined($databytes[12])); 
   
   $timeBulk = $databytes[19].$databytes[18] if(defined($databytes[19]));
   $timeBulk = (int(hex($timeBulk))) if(defined($databytes[19]));
   #$timeBulk = int($timeBulk * 0.0166666)." h ".($timeBulk % 60)." min";
   
   $timeAbsorb = $databytes[21].$databytes[20] if(defined($databytes[19]));
   $timeAbsorb = (int(hex($timeAbsorb))) if(defined($databytes[19]));
   #$timeAbsorb = int($timeAbsorb * 0.0166666)." h ".($timeAbsorb % 60)." min";
   
   $timeFloat = $databytes[23].$databytes[22] if(defined($databytes[23]));
   $timeFloat = (int(hex($timeFloat))) if(defined($databytes[23]));
   #$timeFloat = int($timeFloat * 0.0166666)." h ".($timeFloat % 60)." min";
   
   $Pmax = $databytes[27].$databytes[26].$databytes[25].$databytes[24] if(defined($databytes[27])); 
   $Pmax = (int(hex($Pmax)))." W" if(defined($databytes[27])) ;
   
   $Imax =  $databytes[29].$databytes[28] if(defined($databytes[29]));
   $Imax = (int(hex($Imax)) * 0.1)." A" if(defined($databytes[29])); 
   
   $pvMax = $databytes[31].$databytes[30] if(defined($databytes[31]));
   $pvMax = (int(hex($pvMax)) * 0.01)." V"    if(defined($databytes[31]));
      
   $dsn = $databytes[33].$databytes[32] if(defined($databytes[33]));
   $dsn = (int(hex($dsn))) if(defined($databytes[33])); 
   readingsBulkUpdateIfChanged($hash, "Time_Bulk", $timeBulk, 1);
   readingsBulkUpdateIfChanged($hash, "Time_Absorbtion", $timeAbsorb, 1);
   readingsBulkUpdateIfChanged($hash, "Time_Float", $timeFloat, 1);
   readingsBulkUpdateIfChanged($hash, "Day_sequence_nr", $dsn, 1);
   readingsBulkUpdateIfChanged($hash, "Consumed_Wh", $consumed, 1);
   $ret = "Yield: ".$totalYieldres.
          " |Consum: ".$consumed.
          " |Batt_VMax: ".$BattVMax.
          " |Batt_VMin: ".$BattVMin.
          " |t_Bulk: ".$timeBulk.
          " |t_Absorb: ".$timeAbsorb.
          " |t_float: ".$timeFloat.
          " |Pv_PMax: ".$Pmax.
          " |Batt_IMax: ".$Imax.
          " |Pv_VMax: ".$pvMax.
          " |DaySeqNr: ".$dsn; 
          
       
 }
 readingsEndUpdate( $hash, 1 );
 return $ret;
}
##################################################################################################################################################
# 
##################################################################################################################################################
sub VEDirect_Ready($)
{
  my ($hash) = @_;

  return DevIo_OpenDev( $hash, 1, undef )
    if ( $hash->{STATE} eq "disconnected" );

  # This is relevant for windows/USB only
  my $po = $hash->{USBDev};
  my ( $BlockingFlags, $InBytes, $OutBytes, $ErrorFlags ) = $po->status;
  return ( $InBytes > 0 );
}

##################################################################################################################################################
# 
##################################################################################################################################################
sub VEDirect_ChecksumHEX($$)
{
  my ($startVal, $cmd) = @_;
  $startVal = 0x55;
  
  for my $i (1 .. length($cmd))
   {
      my $val = 0; 
      $val = hex(substr($cmd,$i,1)) if($i==1);
      $val = hex(substr($cmd,$i,2)) if $i % 2 == 0;   
      $startVal -= $val if( looks_like_number($val));
      
   } 
   $startVal &= 0xFF;
   return (sprintf("%02X", $startVal));;
} 
##################################################################################################################################################
# 
################################################################################################################################################## 
sub VEDirect_ChecksumTXT($)
{
  my $chkbuff = @_;
  #my (@chk) = @_;
  #my $chkbuff = join("\r\n",@chk);
  my $chksum = 0;
  for my $i (1 .. length($chkbuff))
  {
   $chksum += ord(substr($chkbuff,$i,1));     #string in Nummer verwandeln und aufaddieren
  }
  $chksum = $chksum % 256;   
  return $chksum;     
}
##################################################################################################################################################
# 
##################################################################################################################################################
sub VEDirect_myInternalTimer($$$$$) {
   my ($modifier, $tim, $callback, $hash, $waitIfInitNotDone) = @_;

   my $mHash;
   if ($modifier eq "") {
      $mHash = $hash;
   } else {
      my $timerName = "$hash->{NAME}_$modifier";
      if (exists  ($hash->{TIMER}{$timerName})) {
          $mHash = $hash->{TIMER}{$timerName};
      } else {
          $mHash = { HASH=>$hash, NAME=>"$hash->{NAME}_$modifier", MODIFIER=>$modifier};
          $hash->{TIMER}{$timerName} = $mHash;
      }
   }
   InternalTimer($tim, $callback, $mHash, $waitIfInitNotDone);
}
##################################################################################################################################################
# 
##################################################################################################################################################
sub VEDirect_myRemoveInternalTimer($$) {
   my ($modifier, $hash) = @_;

   my $timerName = "$hash->{NAME}_$modifier";
   if ($modifier eq "") {
      RemoveInternalTimer($hash);
   } else {
      my $myHash = $hash->{TIMER}{$timerName};
      if (defined($myHash)) {
         delete $hash->{TIMER}{$timerName};
         RemoveInternalTimer($myHash);
      }
   }
}
##################################################################################################################################################
# 
##################################################################################################################################################          
sub VEDirect_Shutdown($)
{
  my ($hash) = @_;

  # Verbindung schlie?en
  DevIo_CloseDev($hash);
  return undef;
}   
##################################################################################################################################################
# 
##################################################################################################################################################
sub VEDirect_LogHistory($)
{
    ##Log History Data to File -> regelm??ig einen Ping senden das senden von HEX-Nachrichten der Ger?te aufrecht zu halten
    my $hash = shift;
    RemoveInternalTimer($hash);    #delete all old timer
    my $name = $hash->{NAME};
    my $type = $hash->{DeviceType} ;
    return if $type ne "MPPT"; 
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $reg = ":7501000";
    $reg .= VEDirect_ChecksumHEX(0x55,$reg);
    Log3 $name, 5, "VEDirect ($name) - LogHistory get command $reg ";  
    DevIo_SimpleWrite($hash, $reg, 2, 1) ; 
    Time::HiRes::sleep(0.2);
  my $Hdate = POSIX::strftime("%Y%m%d",localtime(time));
    my $Data = ReadingsVal($name, "History_".$Hdate,"Reading nicht vorhanden");  
    $year += 1900;
    my $filename = '/mnt/ramdisk/History'.$year.'.log';
    open(my $fh, '>>', $filename) or die "VEDirect ($name) - LogHistory: Could not open file '$filename' $!";
    say $fh $Data;
    close $fh; 
 
    
    my $logtime = (23*3600)+(0*60)+0;
    my $secofday = ($hour * 3600) + ($min * 60) + $sec;
    if ($logtime > $secofday)
    {
     InternalTimer(gettimeofday() + ($logtime - $secofday), "VEDirect_LogHistory", $hash, 0); 
    }
    else
    {
      InternalTimer(gettimeofday() + (86400 -$secofday +  $logtime), "VEDirect_LogHistory", $hash, 0);
    }
}
##################################################################################################################################################
# 
##################################################################################################################################################
1;

# Beginn der Commandref

=pod
=begin html       

<a name="VEDirect"></a>
<h3>VEDirect</h3>
<ul>
  <p>Verbindet FHEM mit einem Victron Ger?t (MPPT, BMV oder Inverter)<br>
  mittels einer seriellen Verbindung. Set-Funktionen sind derzeit nicht implementiet</p><br><br>
  <p><b>Define</b></p>
  <ul>
    <p><code>define &lt;name&gt; VEDirect &lt;serial device&gt; Devivetype[BMV|MPPT|Inverter]</code></p>
    <p>Specifies the VE.Direct device.</p>
  </ul>
  <a name="VEDirectsets"></a>
  <p><b>Set</b></p>
  <ul>
    <li>
      <p>Set-Values tbd</p>
    </li>
  </ul>
  <a name="VEDirectattr"></a>
  <p><b>Attributes</b></p>
  <ul> 
    <li>
      <p><code>att &lt;name&gt; Raw_Readings</code><br/>
         "On": Es werden zus?tzliche Readings ausgegeben (Rohdaten vom Batteriemonitor)<br/>
         "Off": (Standartwert) Es wird nur Klartext ausgegeben </p>    
    </li> 
        <li>
      <p><code>att &lt;name&gt; berechneteWerte</code><br/>
         "On": Es werden zus?tzliche Readings aus den Rohdaten berechnet: Leistung, Wh_geladen, Wh_entnommen<br/>
         "Off":zus?tzliche Readings werden nicht berechnet (aber ggf. vom Device zur Verf?gung gestellt </p>    
    </li>
  </ul>
</ul>
=end html

=cut
