# fhem Modul fuer Victron VE.Direct Hex-Protokoll
#     define SmartShunt VEDirect /dev/serial/by-id/usb-FTDI_FT232R_USB_UART_AL0404CO-if00-port0@19200 BMV
#
#Version 12.1 (16.11.2020)
#Autor: Askie 
#  
package main;

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use File::Spec::Functions;
use Scalar::Util qw(looks_like_number);
use DevIo; # load DevIo.pm if not already loaded

sub VEDirect_GetBMV ($$@);
sub VEDirect_GetMPPT($$@);
sub VEDirect_GetInverter($$@);


my %startBlock = (
"BMV"=>"\r\nH1|\r\nPID",
"MPPT"=>"\r\nPID",
"Inverter"=>"\r\nPID"
);


my %Text = ("V"=>{"ReadingName"=>"Main_or_channel_1_battery_voltage","Unit"=>"V","Scale"=>"0.001"},
            "V2"=>{"ReadingName"=>"Channel_2_battery_voltage","Unit"=>"V","Scale"=>"0.001"},
            "V3"=>{"ReadingName"=>"Channel_3_battery_voltage","Unit"=>"V","Scale"=>"0.001"},
            "VS"=>{"ReadingName"=>"Auxiliary_starter_voltage","Unit"=>"V","Scale"=>"0.001"},
            "VM"=>{"ReadingName"=>"Mid_point_voltage_of_the_battery_bank","Unit"=>"V","Scale"=>"0.001"},
            "DM"=>{"ReadingName"=>"Mid_point_deviation_of_the_battery_bank","Unit"=>"‰","Scale"=>"1"},
            "VPV"=>{"ReadingName"=>"Panel_voltage","Unit"=>"V","Scale"=>"0.001"},
            "PPV"=>{"ReadingName"=>"Panel_power","Unit"=>"W","Scale"=>"1"},
            "I"=>{"ReadingName"=>"Main_or_channel_1_battery_current","Unit"=>"A","Scale"=>"0.001"},
            "I2"=>{"ReadingName"=>"Channel_2_battery_current","Unit"=>"A","Scale"=>"0.001"},
            "I3"=>{"ReadingName"=>"Channel_3_battery_current","Unit"=>"A","Scale"=>"0.001"},
            "IL"=>{"ReadingName"=>"Load_current","Unit"=>"A","Scale"=>"0.001"},
            "LOAD"=>{"ReadingName"=>"Load_output_state","Unit"=>"-","Scale"=>"-"},
            "T"=>{"ReadingName"=>"Battery_temperature","Unit"=>"°C","Scale"=>"1"},
            "P"=>{"ReadingName"=>"Instantaneous_power","Unit"=>"W","Scale"=>"1"},
            "CE"=>{"ReadingName"=>"Consumed_Amp_Hours","Unit"=>"Ah","Scale"=>"0.001"},
            "SOC"=>{"ReadingName"=>"State_of_charge","Unit"=>"%","Scale"=>"0.1"},
            "TTG"=>{"ReadingName"=>"Time_to_go","Unit"=>"Minutes","Scale"=>"1"},
            "Alarm"=>{"ReadingName"=>"Alarm_condition_active","Unit"=>"ACA","Scale"=>"-"},
            "Relay"=>{"ReadingName"=>"Relay_state","Unit"=>"RS","Scale"=>"-"},
            "AR"=>{"ReadingName"=>"Alarm_reason","Unit"=>"AR","Scale"=>"-"},
            "OR"=>{"ReadingName"=>"Off_reason","Unit"=>"OR","Scale"=>"-"},
            "H1"=>{"ReadingName"=>"Depth_of_the_deepest_discharge","Unit"=>"Ah","Scale"=>"0.001"},
            "H2"=>{"ReadingName"=>"Depth_of_the_last_discharge","Unit"=>"Ah","Scale"=>"0.001"},
            "H3"=>{"ReadingName"=>"Depth_of_the_average_discharge","Unit"=>"Ah","Scale"=>"0.001"},
            "H4"=>{"ReadingName"=>"Number_of_charge_cycles","Unit"=>"-","Scale"=>"1"},
            "H5"=>{"ReadingName"=>"Number_of_full_discharges","Unit"=>"-","Scale"=>"1"},
            "H6"=>{"ReadingName"=>"Cumulative_Amp_Hours_drawn","Unit"=>"Ah","Scale"=>"0.001"},
            "H7"=>{"ReadingName"=>"Minimum_main_battery_voltage","Unit"=>"V","Scale"=>"0.001"},
            "H8"=>{"ReadingName"=>"Maximum_main_battery_voltage","Unit"=>"V","Scale"=>"0.001"},
            "H9"=>{"ReadingName"=>"Number_of_seconds_since_last_full_charge","Unit"=>"s","Scale"=>"1"},
            "H10"=>{"ReadingName"=>"Number_of_automatic_synchronizations","Unit"=>"-","Scale"=>"1"},
            "H11"=>{"ReadingName"=>"Number_of_low_main_voltage_alarms","Unit"=>"-","Scale"=>"1"},
            "H12"=>{"ReadingName"=>"Number_of_high_main_voltage_alarms","Unit"=>"-","Scale"=>"1"},
            "H13"=>{"ReadingName"=>"Number_of_low_auxiliary_voltage_alarms","Unit"=>"-","Scale"=>"1"},
            "H14"=>{"ReadingName"=>"Number_of_high_auxiliary_voltage_alarms","Unit"=>"-","Scale"=>"1"},
            "H15"=>{"ReadingName"=>"Minimum_auxiliary_battery_voltage","Unit"=>"V","Scale"=>"0.001"},
            "H16"=>{"ReadingName"=>"Maximum_auxiliary_battery_voltage","Unit"=>"V","Scale"=>"0.001"},
            "H17"=>{"ReadingName"=>"Amount_of_discharged_energy","Unit"=>"kWh","Scale"=>"0.01"},
            "H18"=>{"ReadingName"=>"Amount_of_charged_energy","Unit"=>"kWh","Scale"=>"100"},
            "H19"=>{"ReadingName"=>"Yield_total_user_resettable_counter","Unit"=>"kWh","Scale"=>"0.01"},
            "H20"=>{"ReadingName"=>"Yield_today","Unit"=>"kWh","Scale"=>"0.01"},
            "H21"=>{"ReadingName"=>"Maximum_power_today","Unit"=>"W","Scale"=>"1"},
            "H22"=>{"ReadingName"=>"Yield_yesterday","Unit"=>"-","Scale"=>"1"},
            "H23"=>{"ReadingName"=>"Maximum_power_yesterday","Unit"=>"W","Scale"=>"1"},
            "ERR"=>{"ReadingName"=>"Error_code","Unit"=>"ERR","Scale"=>"1"},
            "CS"=>{"ReadingName"=>"State_of_operation","Unit"=>"-","Scale"=>"1"},
            "BMV"=>{"ReadingName"=>"Model_description","Unit"=>"-","Scale"=>"1"},
            "FW"=>{"ReadingName"=>"Firmware_version_16_bit","Unit"=>"-","Scale"=>"1"},
            "FWE"=>{"ReadingName"=>"Firmware_version_24_bit","Unit"=>"-","Scale"=>"1"},
            "PID"=>{"ReadingName"=>"Product_ID","Unit"=>"-","Scale"=>"1"},
            "SER#"=>{"ReadingName"=>"Serial_number","Unit"=>"-","Scale"=>"1"},
            "HSDS"=>{"ReadingName"=>"Day_sequence_number","Unit"=>"-","Scale"=>"1"},
            "MODE"=>{"ReadingName"=>"Device_mode","Unit"=>"MODE","Scale"=>"1"},
            "AC_OUT_V"=>{"ReadingName"=>"AC_output_voltage","Unit"=>"V","Scale"=>"1"},
            "AC_OUT_I"=>{"ReadingName"=>"AC_output_current","Unit"=>"A","Scale"=>"1"},
            "AC_OUT_S"=>{"ReadingName"=>"AC_output_apparent_power","Unit"=>"VA","Scale"=>"1"},
            "WARN"=>{"ReadingName"=>"Warning_reason","Unit"=>"WR","Scale"=>"1"},
            "MPPT"=>{"ReadingName"=>"Tracker_operation_mode","Unit"=>"MPPT","Scale"=>"1"})    ;

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
               "1"=>"Low Voltage",
               "2"=>"High Voltage",
               "4"=>"Low SOC",
               "8"=>"Low Starter Voltage",
               "16"=>"High Starter Voltage",
               "32"=>"Low Temperature",
               "64"=>"High Temperature",
               "128"=>"Mid Voltage",
               "256"=>"Overload", 
               "512"=>"DC-ripple",
               "1024"=>"Low V AC out",
               "2048"=>"High V AC out",
               "4096"=>"Short Circuit",
               "8192"=>"BMS Lockout",);
               

                 
# ERR (Fehlercode)
my %ERR =    ('0'=>"No error",
              '2'=> "Battery voltage too high",
              '17'=>"Charger temperature too high",
              '18'=>"Charger over current",
              '19'=>"Charger current reversed",
              '20'=>"Bulk time limit exceeded",
              '21'=>"Current sensor issue (sensor bias/sensor broken)",
              '26'=>"Terminals overheated",
              '28'=>"Converter issue",
              '33'=>"Input voltage too high (solar panel)",
              '34'=>"Input current too high (solar panel)",
              '38'=>"Input shutdown (due to excessive battery voltage)",
              '39'=>"Input shutdown (due to current flow during off mode)",
              '65'=>"Lost communication with one of devices",
              '66'=>"Synchronised charging device configuration issue",
              '67'=>"BMS connection lost",
              '68'=>"Network misconfigured",
              '116'=>"Factory calibration data lost",
              '117'=>"Invalid/incompatible firmware",
              '119'=>"User settings invalid");

##### Mode
my %MODE =   ('1'=>"Charger",
              '2'=>"Inverter",
              '4'=>"Off",
              '5'=>"Eco",
              '253'=>"HIBERNATE");

# CS (State of Operation) 
my %CS =    ('0'=>"OFF",
             '1'=>"Low Power",
             '2'=>"Fault(off bis user reset)",
             '3'=>"Bulk",
             '4'=>"Absorption",
             '5'=>"Float",
             '6'=>"Storage",
             '7'=>"Equalize (manual)",
             '9'=>"Inverting",
             '11'=>"Power supply",
             '245'=>"Starting-up",
             '246'=>"Repeated absorption ",
             '247'=>"Auto equalize / Recondition",
             '248'=>"BatterySafe",
             '252'=>"External Control"); 
             
             
my %OR =    ('0x00000000'=>"Device is active",
             '0x00000001'=>"No input power",
             '0x00000002'=>"Switched off(power switch)",
             '0x00000004'=>"Switched off(device mode register)",
             '0x00000008'=>"Remote input",
             '0x00000010'=>"Protection active",
             '0x00000020'=>"Paygo",
             '0x00000040'=>"BMS",
             '0x00000080'=>"Engine shutdown detection",
             '0x00000100'=>"Analysing input voltage");

my %MPPT =    ('0'=>"Off",
               '1'=>"Voltage_or_current_limited",
               '2'=>"MPP Tracker active");

my %TOM =    ('0x00000000'=>"Device is active",
              '0x00000100'=>"Analysing input voltage");

my %bmv_reg = ( 'ALARM_LOW_VOLTAGE_SET'=>{"Register"=>"0x0320","Scale"=>"0,01","Unit"=>"V","SetItems"=>"ALARM_LOW_VOLTAGE_SET","GetItems"=>"ALARM_LOW_VOLTAGE_SET:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'ALARM_LOW_VOLTAGE_CLEAR'=>{"Register"=>"0x0321","Scale"=>"0,01","Unit"=>"V","SetItems"=>"ALARM_LOW_VOLTAGE_CLEAR","GetItems"=>"ALARM_LOW_VOLTAGE_CLEAR:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmHighVoltage'=>{"Register"=>"0x0322","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Alarm_High_Voltage:slider,0,0.1,95","GetItems"=>"Alarm_High_Voltage:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmHighVoltageClear'=>{"Register"=>"0x0323","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Alarm_High_Voltage_Clear:slider,0,0.1,95","GetItems"=>"Alarm_High_Voltage_Clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmLowStarter'=>{"Register"=>"0x0324","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Alarm_Low_Starter:slider,0,0.1,95","GetItems"=>"Alarm_Low_Starter:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmLowStarterClear'=>{"Register"=>"0x0325","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Alarm_Low_Starter_Clear:slider,0,0.1,95","GetItems"=>"Alarm_Low_Starter_Clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmHighStarter'=>{"Register"=>"0x0326","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Alarm_High_Starter:slider,0,0.1,95","GetItems"=>"Alarm_High_Starter:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmHighStarterClear'=>{"Register"=>"0x0327","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Alarm_High_Starter_Clear:slider,0,0.1,95","GetItems"=>"Alarm_High_Starter_Clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmLowSOC'=>{"Register"=>"0x0328","Scale"=>"0,1","Unit"=>"%","SetItems"=>"Alarm_Low_SOC:slider,0,0.1,95","GetItems"=>"Alarm_Low_SOC:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmLowSOCClear'=>{"Register"=>"0x0329","Scale"=>"0,1","Unit"=>"%","SetItems"=>"Alarm_Low_SOC_Clear:slider,0,0.1,95","GetItems"=>"Alarm_Low_SOC_Clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmLowTemperature'=>{"Register"=>"0x032A","Scale"=>"0,01","Unit"=>"K","SetItems"=>"Alarm_Low_Temperature:multiple,disabled","GetItems"=>"Alarm_Low_Temperature:noArg","SpezialSetGet"=>"0:alt","Payloadnibbles"=>"4"},
                'AlarmLowTemperatureClear'=>{"Register"=>"0x032B","Scale"=>"0,01","Unit"=>"K","SetItems"=>"Alarm_Low_Temperature_Clear:multiple,disabled","GetItems"=>"Alarm_Low_Temperature_Clear:noArg","SpezialSetGet"=>"0:alt","Payloadnibbles"=>"4"},
                'AlarmHighTemperature'=>{"Register"=>"0x032C","Scale"=>"0,01","Unit"=>"K","SetItems"=>"Alarm_High_Temperature:multiple,disabled","GetItems"=>"Alarm_High_Temperature:noArg","SpezialSetGet"=>"0:alt","Payloadnibbles"=>"4"},
                'AlarmHighTemperatureClear'=>{"Register"=>"0x032D","Scale"=>"0,01","Unit"=>"K","SetItems"=>"Alarm_High_Temperature_Clear:multiple,disabled","GetItems"=>"Alarm_High_Temperature_Clear:noArg","SpezialSetGet"=>"0:alt","Payloadnibbles"=>"4"},
                'AlarmMidVoltage'=>{"Register"=>"0x0331","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Alarm_Mid_Voltage:slider,0,0.1,99","GetItems"=>"Alarm_Mid_Voltage:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmMidVoltageClear'=>{"Register"=>"0x0332","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Alarm_Mid_Voltage_Clear:slider,0,0.1,99","GetItems"=>"Alarm_Mid_Voltage_Clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RelayInvert'=>{"Register"=>"0x034D","Scale"=>"1","Unit"=>"","SetItems"=>"Relay_Invert:off,on","GetItems"=>"Relay_Invert:noArg","SpezialSetGet"=>"00:01","Payloadnibbles"=>"2"},
                'RelayState_Control'=>{"Register"=>"0x034E","Scale"=>"1","Unit"=>"","SetItems"=>"Relay_State_Control:open,closed","GetItems"=>"Relay_State_Control:noArg","SpezialSetGet"=>"00:01","Payloadnibbles"=>"2"},
                'RelayMode'=>{"Register"=>"0x034F","Scale"=>"1","Unit"=>"","SetItems"=>"Relay_Mode:default,chrg,rem","GetItems"=>"Relay_Mode:noArg","SpezialSetGet"=>"00:01:02","Payloadnibbles"=>"2"},
                'Relay_battery_low_voltage_set'=>{"Register"=>"0x0350","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_battery_low_voltage_set:slider,9,0.1,95","GetItems"=>"Relay_battery_low_voltage_set:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_battery_low_voltage_clear'=>{"Register"=>"0x0351","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_battery_low_voltage_clear:slider,9,0.1,95","GetItems"=>"Relay_battery_low_voltage_clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_battery_high_voltage_set'=>{"Register"=>"0x0352","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_battery_high_voltage_set:slider,9,0.1,95","GetItems"=>"Relay_battery_high_voltage_set:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_battery_high_voltage_clear'=>{"Register"=>"0x0353","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_battery_high_voltage_clear:slider,9,0.1,95","GetItems"=>"Relay_battery_high_voltage_clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RelayLowStarter'=>{"Register"=>"0x0354","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_Low_Starter:slider,0,0.1,95","GetItems"=>"Relay_Low_Starter:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RelayLowStarterClear'=>{"Register"=>"0x0355","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_Low_Starter_Clear:slider,0,0.1,95","GetItems"=>"Relay_Low_Starter_Clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RelayHighStarter'=>{"Register"=>"0x0356","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_High_Starter:slider,0,0.1,95","GetItems"=>"Relay_High_Starter:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RelayHighStarterClear'=>{"Register"=>"0x0357","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_High_Starter_Clear:slider,0,0.1,95","GetItems"=>"Relay_High_Starter_Clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RelayLowTemperature'=>{"Register"=>"0x035A","Scale"=>"0,01","Unit"=>"K","SetItems"=>"Relay_Low_Temperature:multiple,disabled","GetItems"=>"Relay_Low_Temperature:noArg","SpezialSetGet"=>"0:alt","Payloadnibbles"=>"4"},
                'RelayLowTemperatureClear'=>{"Register"=>"0x035B","Scale"=>"0,01","Unit"=>"K","SetItems"=>"Relay_Low_Temperature_Clear:multiple,disabled","GetItems"=>"Relay_Low_Temperature_Clear:noArg","SpezialSetGet"=>"0:alt","Payloadnibbles"=>"4"},
                'RelayHighTemperature'=>{"Register"=>"0x035C","Scale"=>"0,01","Unit"=>"K","SetItems"=>"Relay_High_Temperature:multiple,disabled","GetItems"=>"Relay_High_Temperature:noArg","SpezialSetGet"=>"0:alt","Payloadnibbles"=>"4"},
                'RelayHighTemperatureClear'=>{"Register"=>"0x035D","Scale"=>"0,01","Unit"=>"K","SetItems"=>"Relay_High_Temperature_Clear:multiple,disabled","GetItems"=>"Relay_High_Temperature_Clear:noArg","SpezialSetGet"=>"0:alt","Payloadnibbles"=>"4"},
                'RelayMidVoltage'=>{"Register"=>"0x0361","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_Mid_Voltage:slider,0,0.1,95","GetItems"=>"Relay_Mid_Voltage:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RelayMidVoltageClear'=>{"Register"=>"0x0362","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_Mid_Voltage_Clear:slider,0,0.1,95","GetItems"=>"Relay_Mid_Voltage_Clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'BatteryCapacity'=>{"Register"=>"0x1000","Scale"=>"1","Unit"=>"Ah","SetItems"=>"Battery_Capacity:slider,1,1,9999","GetItems"=>"Battery_Capacity:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'ChargedVoltage'=>{"Register"=>"0x1001","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Charged_Voltage","GetItems"=>"Charged_Voltage:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'TailCurrent'=>{"Register"=>"0x1002","Scale"=>"0,1","Unit"=>"%","SetItems"=>"Tail_Current:slider,0.5,0.1,10","GetItems"=>"Tail_Current:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'ChargedDetectionTime'=>{"Register"=>"0x1003","Scale"=>"","Unit"=>"min","SetItems"=>"Charged_Detection_Time:slider,1,1,50","GetItems"=>"Charged_Detection_Time:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'ChargeEfficiency'=>{"Register"=>"0x1004","Scale"=>"","Unit"=>"%","SetItems"=>"Charge_Efficiency:slider,50,1,99","GetItems"=>"Charge_Efficiency:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'PeukertCoefficient'=>{"Register"=>"0x1005","Scale"=>"0,01","Unit"=>"","SetItems"=>"Peukert_Coefficient:slider,1,0.01,1.5","GetItems"=>"Peukert_Coefficient:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'CurrentThreshold'=>{"Register"=>"0x1006","Scale"=>"0,01","Unit"=>"A","SetItems"=>"Current_Threshold:slider,0,0.01,2","GetItems"=>"Current_Threshold:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'DischargeFloorRelayLowSocSet'=>{"Register"=>"0x1008","Scale"=>"0,1","Unit"=>"%","SetItems"=>"Discharge_Floor_Relay_Low_Soc_Set:slider,0,0.1,99","GetItems"=>"Discharge_Floor_Relay_Low_Soc_Set:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RelayLowSocClear'=>{"Register"=>"0x1009","Scale"=>"0,1","Unit"=>"%","SetItems"=>"Relay_Low_Soc_Clear:slider,0,0.1,99","GetItems"=>"Relay_Low_Soc_Clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_minimum_enabled_time'=>{"Register"=>"0x100A","Scale"=>"","Unit"=>"min","SetItems"=>"Relay_minimum_enabled_time:slider,0,1,500","GetItems"=>"Relay_minimum_enabled_time:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RelayDisableTime'=>{"Register"=>"0x100B","Scale"=>"","Unit"=>"min","SetItems"=>"Relay_Disable_Time:slider,0,1,500","GetItems"=>"Relay_Disable_Time:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'setZeroCurrent'=>{"Register"=>"0x1029","Scale"=>"","Unit"=>"","SetItems"=>"set_Zero_Current:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Temperaturecoefficient'=>{"Register"=>"0xEEF4","Scale"=>"0,1","Unit"=>"%CAP_°C","SetItems"=>"Temperature_coefficient:slider,0,0.1,20","GetItems"=>"Temperature_coefficient:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'SetupLock'=>{"Register"=>"0xEEF6","Scale"=>"1","Unit"=>"","SetItems"=>"Setup_Lock:off,on","GetItems"=>"Setup_Lock:noArg","SpezialSetGet"=>"00:01","Payloadnibbles"=>"2"},
                'TemperatureUnit'=>{"Register"=>"0xEEF7","Scale"=>"1","Unit"=>"","SetItems"=>"Temperature_Unit:Celsius,Fahrenheit","GetItems"=>"Temperature_Unit:noArg","SpezialSetGet"=>"00:01","Payloadnibbles"=>"2"},
                'AuxiliaryInput'=>{"Register"=>"0xEEF8","Scale"=>"1","Unit"=>"","SetItems"=>"Auxiliary_Input:start,mid,temp","GetItems"=>"Auxiliary_Input:noArg","SpezialSetGet"=>"00:01:02","Payloadnibbles"=>"2"},
                'ShuntVolts'=>{"Register"=>"0xEEFA","Scale"=>"0,001","Unit"=>"V","SetItems"=>"Shunt_Volts","GetItems"=>"Shunt_Volts:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'ShuntAmps'=>{"Register"=>"0xEEFB","Scale"=>"1","Unit"=>"A","SetItems"=>"Shunt_Amps","GetItems"=>"Shunt_Amps:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'AlarmBuzzer'=>{"Register"=>"0xEEFC","Scale"=>"1","Unit"=>"","SetItems"=>"Alarm_Buzzer:off,on","GetItems"=>"Alarm_Buzzer:noArg","SpezialSetGet"=>"00:01","Payloadnibbles"=>"2"});

my $bmvSets = "Restart:noArg ALARM_LOW_VOLTAGE_SET:slider,0,0.1,95 ALARM_LOW_VOLTAGE_CLEAR:slider,0,0.1,95 Alarm_High_Voltage:slider,0,0.1,95 Alarm_High_Voltage_Clear:slider,0,0.1,95 Alarm_Low_Starter:slider,0,0.1,95 ".
             "Alarm_Low_Starter_Clear:slider,0,0.1,95 Alarm_High_Starter:slider,0,0.1,95 Alarm_High_Starter_Clear:slider,0,0.1,95 Alarm_Low_SOC:slider,0,0.1,95 Alarm_Low_SOC_Clear:slider,0,0.1,95 ".
             "Alarm_Low_Temperature:multiple,disabled Alarm_Low_Temperature_Clear:multiple,disabled Alarm_High_Temperature:multiple,disabled Alarm_High_Temperature_Clear:multiple,disabled ".
             "Alarm_Mid_Voltage:slider,0,0.1,99 Alarm_Mid_Voltage_Clear:slider,0,0.1,99 Relay_Invert:off,on Relay_State_Control:open,closed Relay_Mode:default,chrg,rem Relay_battery_low_voltage_set".
             ":slider,9,0.1,95 Relay_battery_low_voltage_clear:slider,9,0.1,95 Relay_battery_high_voltage_set:slider,9,0.1,95 Relay_battery_high_voltage_clear:slider,9,0.1,95 Relay_Low_Starter:".
             "slider,0,0.1,95 Relay_Low_Starter_Clear:slider,0,0.1,95 Relay_High_Starter:slider,0,0.1,95 Relay_High_Starter_Clear:slider,0,0.1,95 Relay_Low_Temperature:multiple,disabled ".
             "Relay_Low_Temperature_Clear:multiple,disabled Relay_High_Temperature:multiple,disabled Relay_High_Temperature_Clear:multiple,disabled Relay_Mid_Voltage:slider,0,0.1,95 ".
             "Relay_Mid_Voltage_Clear:slider,0,0.1,95 Battery_Capacity:multiple,disabled Charged_Voltage:slider,10,0.1,95 Tail_Current:slider,0.5,0.1,10 Charged_Detection_Time:slider,1,1,50 ".
             "Charge_Efficiency:slider,50,1,99 Peukert_Coefficient:slider,1,0.01,1.5 Current_Threshold:slider,0,0.01,2 Discharge_Floor_Relay_Low_Soc_Set:slider,0,0.1,99 ".
             "Relay_Low_Soc_Clear:slider,0,0.1,99 Relay_minimum_enabled_time:slider,0,1,500 Relay_Disable_Time:slider,0,1,500 set_Zero_Current:noArg Temperature_coefficient:slider,0,0.1,20 ".
             "Setup_Lock:off,on Temperature_Unit:Celsius,Fahrenheit Auxiliary_Input:start,mid,temp Shunt_Volts Shunt_Amps Alarm_Buzzer:off,on";

my $bmvGets = "ConfigAll:noArg ALARM_LOW_VOLTAGE_SET:noArg ALARM_LOW_VOLTAGE_CLEAR:noArg Alarm_High_Voltage:noArg Alarm_High_Voltage_Clear:noArg Alarm_Low_Starter:noArg Alarm_Low_Starter_Clear:noArg ".
             "Alarm_High_Starter:noArg Alarm_High_Starter_Clear:noArg Alarm_Low_SOC:noArg Alarm_Low_SOC_Clear:noArg Alarm_Low_Temperature:noArg Alarm_Low_Temperature_Clear:noArg Alarm_High_Temperature:noArg ".
             "Alarm_High_Temperature_Clear:noArg Alarm_Mid_Voltage:noArg Alarm_Mid_Voltage_Clear:noArg Relay_Invert:noArg Relay_State_Control:noArg Relay_Mode:noArg Relay_battery_low_voltage_set:noArg ".
             "Relay_battery_low_voltage_clear:noArg Relay_battery_high_voltage_set:noArg Relay_battery_high_voltage_clear:noArg Relay_Low_Starter:noArg Relay_Low_Starter_Clear:noArg Relay_High_Starter:noArg ".
             "Relay_High_Starter_Clear:noArg Relay_Low_Temperature:noArg Relay_Low_Temperature_Clear:noArg Relay_High_Temperature:noArg Relay_High_Temperature_Clear:noArg Relay_Mid_Voltage:noArg ".
             "Relay_Mid_Voltage_Clear:noArg Battery_Capacity:noArg Charged_Voltage:noArg Tail_Current:noArg Charged_Detection_Time:noArg Charge_Efficiency:noArg ".
             "Peukert_Coefficient:noArg Current_Threshold:noArg Discharge_Floor_Relay_Low_Soc_Set:noArg Relay_Low_Soc_Clear:noArg ".
             "Relay_minimum_enabled_time:noArg Relay_Disable_Time:noArg Temperature_coefficient:noArg Setup_Lock:noArg Temperature_Unit:noArg Auxiliary_Input:noArg Shunt_Volts:noArg Shunt_Amps:noArg ".
             "Alarm_Buzzer:noArg Auxiliary_Input:noArg Shunt_Volts:noArg Shunt_Amps:noArg";


my %mppt_reg = ('Charger_mode'=>{"Register"=>"0x0200","Scale"=>"1","Unit"=>"","SetItems"=>"Charger_mode:off,on","GetItems"=>"Charger_mode:off,on,off","SpezialSetGet"=>"00:01:04","Payloadnibbles"=>"2"},
                'Relay_battery_low_voltage_set'=>{"Register"=>"0x0350","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_battery_low_voltage_set:slider,9,0.1,95","GetItems"=>"Relay_battery_low_voltage_set:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_battery_low_voltage_clear'=>{"Register"=>"0x0351","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_battery_low_voltage_clear:slider,9,0.1,95","GetItems"=>"Relay_battery_low_voltage_clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_battery_high_voltage_set'=>{"Register"=>"0x0352","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_battery_high_voltage_set:slider,9,0.1,95","GetItems"=>"Relay_battery_high_voltage_set:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_battery_high_voltage_clear'=>{"Register"=>"0x0353","Scale"=>"0,1","Unit"=>"V","SetItems"=>"Relay_battery_high_voltage_clear:slider,9,0.1,95","GetItems"=>"Relay_battery_high_voltage_clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_minimum_enabled_time'=>{"Register"=>"0x100A","Scale"=>"","Unit"=>"min","SetItems"=>"Relay_minimum_enabled_time:slider,0,1,500","GetItems"=>"Relay_minimum_enabled_time:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Clear_history'=>{"Register"=>"0x1030","Scale"=>"","Unit"=>"","SetItems"=>"Clear_history:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Total_history'=>{"Register"=>"0x104F","Scale"=>"","Unit"=>"","GetItems"=>"Total_history:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History_today'=>{"Register"=>"0x1050","Scale"=>"0","Unit"=>"","GetItems"=>"History_today:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-1'=>{"Register"=>"0x1051","Scale"=>"-1","Unit"=>"","GetItems"=>"History-1:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-2'=>{"Register"=>"0x1052","Scale"=>"-2","Unit"=>"","GetItems"=>"History-2:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-3'=>{"Register"=>"0x1053","Scale"=>"-3","Unit"=>"","GetItems"=>"History-3:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-4'=>{"Register"=>"0x1054","Scale"=>"-4","Unit"=>"","GetItems"=>"History-4:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-5'=>{"Register"=>"0x1055","Scale"=>"-5","Unit"=>"","GetItems"=>"History-5:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-6'=>{"Register"=>"0x1056","Scale"=>"-6","Unit"=>"","GetItems"=>"History-6:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-7'=>{"Register"=>"0x1057","Scale"=>"-7","Unit"=>"","GetItems"=>"History-7:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-8'=>{"Register"=>"0x1058","Scale"=>"-8","Unit"=>"","GetItems"=>"History-8:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-9'=>{"Register"=>"0x1059","Scale"=>"-9","Unit"=>"","GetItems"=>"History-9:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-10'=>{"Register"=>"0x105A","Scale"=>"-10","Unit"=>"","GetItems"=>"History-10:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-11'=>{"Register"=>"0x105B","Scale"=>"-11","Unit"=>"","GetItems"=>"History-11:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-12'=>{"Register"=>"0x105C","Scale"=>"-12","Unit"=>"","GetItems"=>"History-12:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-13'=>{"Register"=>"0x105D","Scale"=>"-13","Unit"=>"","GetItems"=>"History-13:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-14'=>{"Register"=>"0x105E","Scale"=>"-14","Unit"=>"","GetItems"=>"History-14:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-15'=>{"Register"=>"0x105F","Scale"=>"-15","Unit"=>"","GetItems"=>"History-15:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-16'=>{"Register"=>"0x1060","Scale"=>"-16","Unit"=>"","GetItems"=>"History-16:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-17'=>{"Register"=>"0x1061","Scale"=>"-17","Unit"=>"","GetItems"=>"History-17:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-18'=>{"Register"=>"0x1062","Scale"=>"-18","Unit"=>"","GetItems"=>"History-18:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-19'=>{"Register"=>"0x1063","Scale"=>"-19","Unit"=>"","GetItems"=>"History-19:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-20'=>{"Register"=>"0x1064","Scale"=>"-20","Unit"=>"","GetItems"=>"History-20:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-21'=>{"Register"=>"0x1065","Scale"=>"-21","Unit"=>"","GetItems"=>"History-21:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-22'=>{"Register"=>"0x1066","Scale"=>"-22","Unit"=>"","GetItems"=>"History-22:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-23'=>{"Register"=>"0x1067","Scale"=>"-23","Unit"=>"","GetItems"=>"History-23:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-24'=>{"Register"=>"0x1068","Scale"=>"-24","Unit"=>"","GetItems"=>"History-24:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-25'=>{"Register"=>"0x1069","Scale"=>"-25","Unit"=>"","GetItems"=>"History-25:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-26'=>{"Register"=>"0x106A","Scale"=>"-26","Unit"=>"","GetItems"=>"History-26:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-27'=>{"Register"=>"0x106B","Scale"=>"-27","Unit"=>"","GetItems"=>"History-27:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-28'=>{"Register"=>"0x106C","Scale"=>"-28","Unit"=>"","GetItems"=>"History-28:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-29'=>{"Register"=>"0x106D","Scale"=>"-29","Unit"=>"","GetItems"=>"History-29:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'History-30'=>{"Register"=>"0x106E","Scale"=>"-30","Unit"=>"","GetItems"=>"History-30:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"68"},
                'Charge_voltage_set-point'=>{"Register"=>"0x2001","Scale"=>"0,01","Unit"=>"V","SetItems"=>"-","GetItems"=>"Charge_voltage_set-point:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Battery_voltage_sense'=>{"Register"=>"0x2002","Scale"=>"0,01","Unit"=>"V","SetItems"=>"-","GetItems"=>"Battery_voltage_sense:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Network_mode'=>{"Register"=>"0x200E","Scale"=>"","Unit"=>"","GetItems"=>"Network_mode:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"2"},
                'Network_status'=>{"Register"=>"0x200F","Scale"=>"","Unit"=>"","GetItems"=>"Network_status:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"2"},
                'Solar_activity'=>{"Register"=>"0x2030","Scale"=>"","Unit"=>"","GetItems"=>"Solar_activity:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"2"},
                'Sunset_delay'=>{"Register"=>"0xED96","Scale"=>"1","Unit"=>"min","SetItems"=>"Sunset_delay","GetItems"=>"Sunset_delay:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Sunrise_delay'=>{"Register"=>"0xED97","Scale"=>"1","Unit"=>"min","SetItems"=>"Sunrise_delay","GetItems"=>"Sunrise_delay:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'RX_Port_operation_mode'=>{"Register"=>"0xED98","Scale"=>"1","Unit"=>"","SetItems"=>"RX_Port_operation_mode:Remote_On_off,Load_output_configuration,Load_output_on_off_remote_control_inverted,Load_output_on_off_remote_control_normal","GetItems"=>"RX_Port_operation_mode:noArg","SpezialSetGet"=>"0:1:2:3","Payloadnibbles"=>"2"},
                'Load_switch_low_level'=>{"Register"=>"0xED9C","Scale"=>"0,01","Unit"=>"V","SetItems"=>"Load_switch_low_level","GetItems"=>"Load_switch_low_level:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Load_switch_high_level'=>{"Register"=>"0xED9D","Scale"=>"0,01","Unit"=>"V","SetItems"=>"Load_switch_high_level","GetItems"=>"Load_switch_high_level:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'TX_Port_operation_mode'=>{"Register"=>"0xED9E","Scale"=>"1","Unit"=>"","SetItems"=>"TX_Port_operation_mode:Pulse_every0_01kWh,Lighting_control_pwm_normal,Lighting_control_pwm_inverted,Virtual_load_output","GetItems"=>"TX_Port_operation_mode:noArg","SpezialSetGet"=>"0:1:2:3:4","Payloadnibbles"=>"2"},
                'Load_output_control'=>{"Register"=>"0xEDAB","Scale"=>"1","Unit"=>"","SetItems"=>"Load_output_control:off,auto,alt1,alt2,on,user1,user2,automatic_energy_selector","GetItems"=>"Load_output_control:noArg","SpezialSetGet"=>"0:1:2:3:4:5:6:7","Payloadnibbles"=>"2"},
                'Relay_panel_high_voltage_clear'=>{"Register"=>"0xEDB9","Scale"=>"0,01","Unit"=>"V","SetItems"=>"Relay_panel_high_voltage_clear","GetItems"=>"Relay_panel_high_voltage_clear:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_panel_high_voltage_set'=>{"Register"=>"0xEDBA","Scale"=>"0,01","Unit"=>"V","SetItems"=>"Relay_panel_high_voltage_set","GetItems"=>"Relay_panel_high_voltage_set:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Relay_operation_mode'=>{"Register"=>"0xEDD9","Scale"=>"1","Unit"=>"","SetItems"=>"Relay_operation_mode:off,PV_V_high,int_temp_high,Batt_Voltage_low,equalization_active,Error_cond_present,int_temp_low,Batt_Voltage_too_high,Charger_in_float_or_storage,day_detection,load_control","GetItems"=>"Relay_operation_mode:noArg","SpezialSetGet"=>"0:1:2:3:4:5:6:7:8:9:10","Payloadnibbles"=>"2"},
                'Charger_maximum_current'=>{"Register"=>"0xEDDF","Scale"=>"0,01","Unit"=>"A","SetItems"=>"Charger_maximum_current","GetItems"=>"Charger_maximum_current:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Battery_low_temperature_level'=>{"Register"=>"0xEDE0","Scale"=>"0,01","Unit"=>"degC","SetItems"=>"Battery_low_temperature_level","GetItems"=>"Battery_low_temperature_level:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Low_temperature_charge_current'=>{"Register"=>"0xEDE6","Scale"=>"0,1","Unit"=>"A","SetItems"=>"Low_temperature_charge_current","GetItems"=>"Low_temperature_charge_current:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Battery_temperature'=>{"Register"=>"0xEDEC","Scale"=>"0,01","Unit"=>"K","GetItems"=>"Battery_temperature:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Battery_maximum_current'=>{"Register"=>"0xEDF0","Scale"=>"0,1","Unit"=>"A","SetItems"=>"Battery_maximum_current","GetItems"=>"Battery_maximum_current:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Battery_type'=>{"Register"=>"0xEDF1","Scale"=>"1","Unit"=>"","SetItems"=>"Battery_type:TYPE_1_GEL_Victron_Long_Life_14_1V,TYPE_2_GEL_Victron_Deep_discharge_14_3V,TYPE_3_GEL_Victron_Deep_discharge_14_4V,TYPE_4_AGM_Victron_Deep_discharge_14_7V,TYPE_5_Tubular_plate_cyclic_mode_1_14_9V,TYPE_6_Tubular_plate_cyclic_mode_2_15_1V,TYPE_7_Tubular_plate_cyclic_mode_3_15_3V,TYPE_8_LiFEPO4_14_2V,User_defined","GetItems"=>"Battery_type:noArg","SpezialSetGet"=>"1:2:3:4:5:6:7:8:255","Payloadnibbles"=>"2"},
                'Battery_temp_compensation'=>{"Register"=>"0xEDF2","Scale"=>"0,01","Unit"=>"mV_K","SetItems"=>"Battery_temp_compensation","GetItems"=>"Battery_temp_compensation:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Battery_equalization_voltage'=>{"Register"=>"0xEDF4","Scale"=>"0,01","Unit"=>"V","SetItems"=>"Battery_equalization_voltage","GetItems"=>"Battery_equalization_voltage:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Battery_float_voltage'=>{"Register"=>"0xEDF6","Scale"=>"0,01","Unit"=>"V","SetItems"=>"Battery_float_voltage","GetItems"=>"Battery_float_voltage:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Battery_absorption_voltage'=>{"Register"=>"0xEDF7","Scale"=>"0,01","Unit"=>"V","SetItems"=>"Battery_absorption_voltage","GetItems"=>"Battery_absorption_voltage:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'Automatic_equalization_mode'=>{"Register"=>"0xEDFD","Scale"=>"1","Unit"=>"","SetItems"=>"Automatic_equalization_mode:multiple,disabled","GetItems"=>"Automatic_equalization_mode:noArg","SpezialSetGet"=>"0:alt});","Payloadnibbles"=>"2"});

my $MPPTSets = "Restart:noArg Charger_mode:off,on Relay_battery_low_voltage_set:slider,9,0.1,95 Relay_battery_low_voltage_clear:slider,9,0.1,95 Relay_battery_high_voltage_set:slider,9,0.1,95 ".
               "Relay_battery_high_voltage_clear:slider,9,0.1,95 Relay_minimum_enabled_time:slider,0,1,500 Clear_history:noArg RX_Port_operation_mode:Remote_On_off,Load_output_configuration,".
               "Load_output_on_off_remote_control_inverted,Load_output_on_off_remote_control_normal Load_switch_low_level:noArg Load_switch_high_level:noArg TX_Port_operation_mode:Pulse_every".
               "0_01kWh,Lighting_control_pwm_normal,Lighting_control_pwm_inverted,Virtual_load_output Load_output_control:off,auto,alt1,alt2,on,user1,user2,automatic_energy_selector ".
               "Relay_operation_mode:off,PV_V_high,int_temp_high,Batt_Voltage_low,equalization_active,Error_cond_present,int_temp_low,Batt_Voltage_too_high,Charger_in_float_or_storage,".
               "day_detection,load_control Charger_maximum_current:noArg Battery_low_temperature_level:noArg Low_temperature_charge_current:noArg Battery_maximum_current:noArg ".
               "Battery_type:TYPE_1_GEL_Victron_Long_Life_14_1V,TYPE_2_GEL_Victron_Deep_discharge_14_3V,TYPE_3_GEL_Victron_Deep_discharge_14_4V,TYPE_4_AGM_Victron_Deep_discharge_14_7V,".
               "TYPE_5_Tubular_plate_cyclic_mode_1_14_9V,TYPE_6_Tubular_plate_cyclic_mode_2_15_1V,TYPE_7_Tubular_plate_cyclic_mode_3_15_3V,TYPE_8_LiFEPO4_14_2V,User_defined ".
               "Battery_temp_compensation:noArg Battery_equalization_voltage Battery_float_voltage Battery_absorption_voltage:noArg Automatic_equalization_mode:multiple,disabled";

my $MPPTGets = "ConfigAll:noArg History_all:noArg Charger_mode:off,on,off Relay_battery_low_voltage_set:noArg Relay_battery_low_voltage_clear:noArg Relay_battery_high_voltage_set:noArg ".
               "Relay_battery_high_voltage_clear:noArg Relay_minimum_enabled_time:noArg Total_history:noArg History_today:noArg History-1:noArg History-2:noArg History-3:noArg ".
               "History-4:noArg History-5:noArg History-6:noArg History-7:noArg History-8:noArg History-9:noArg History-10:noArg History-11:noArg History-12:noArg History-13:noArg ".
               "History-14:noArg History-15:noArg History-16:noArg History-17:noArg History-18:noArg History-19:noArg History-20:noArg History-21:noArg History-22:noArg History-23:noArg ".
               "History-24:noArg History-25:noArg History-26:noArg History-27:noArg History-28:noArg History-29:noArg History-30:noArg Charge_voltage_set-point:noArg Battery_voltage_sense:noArg ".
               "Network_mode:noArg Network_status:noArg Solar_activity:noArg RX_Port_operation_mode:noArg Load_switch_low_level:noArg Load_switch_high_level:noArg TX_Port_operation_mode:noArg ".
               "oad_output_control:noArg Relay_operation_mode:noArg Charger_maximum_current:noArg Battery_low_temperature_level:noArg Low_temperature_charge_current:noArg ".
               "Battery_temperature:noArg Battery_maximum_current:noArg Battery_type:noArg Battery_temp_compensation:noArg Battery_equalization_voltage:noArg ".
               "Battery_float_voltage:noArg Battery_absorption_voltage:noArg Automatic_equalization_mode:noArg";



my %inverter_reg = ('Device_mode'=>{"Register"=>"0x0200","Scale"=>"1","Unit"=>"","SetItems"=>"Device_mode:on,off,eco","GetItems"=>"Device_mode:noArg","SpezialSetGet"=>"02:04:05","Payloadnibbles"=>"2"},
                'ALARM_LOW_VOLTAGE_SET'=>{"Register"=>"0x0320","Scale"=>"0,01","Unit"=>"V","SetItems"=>"ALARM_LOW_VOLTAGE_SET","GetItems"=>"ALARM_LOW_VOLTAGE_SET:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'ALARM_LOW_VOLTAGE_CLEAR'=>{"Register"=>"0x0321","Scale"=>"0,01","Unit"=>"V","SetItems"=>"ALARM_LOW_VOLTAGE_CLEAR","GetItems"=>"ALARM_LOW_VOLTAGE_CLEAR:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'SHUTDOWN_LOW_VOLTAGE_SET'=>{"Register"=>"0x2210","Scale"=>"0,01","Unit"=>"V","SetItems"=>"SHUTDOWN_LOW_VOLTAGE_SET","GetItems"=>"SHUTDOWN_LOW_VOLTAGE_SET:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"},
                'INV_OPER_ECO_MODE_INV_MIN'=>{"Register"=>"0xEB04","Scale"=>"0,001","Unit"=>"A","SetItems"=>"INV_OPER_ECO_MODE_INV_MIN","GetItems"=>"INV_OPER_ECO_MODE_INV_MIN:noArg","SpezialSetGet"=>"-","Payloadnibbles"=>"4"});

my $InverterSets = "Restart:noArg Device_mode:on,off,eco AC_OUT_VOLTAGE_SETPOINT:noArg ALARM_LOW_VOLTAGE_SET:noArg ALARM_LOW_VOLTAGE_CLEAR:noArg SHUTDOWN_LOW_VOLTAGE_SET:noArg ".
                   "INV_OPER_ECO_MODE_INV_MIN:noArg";

my $InverterGets = "ConfigAll:noArg Device_mode:noArg AC_OUT_VOLTAGE_SETPOINT:noArg ALARM_LOW_VOLTAGE_SET:noArg ALARM_LOW_VOLTAGE_CLEAR:noArg ".
                   "SHUTDOWN_LOW_VOLTAGE_SET:noArg INV_OPER_ECO_MODE_INV_MIN:noArg";

#########################################################################
#Key: "Register-ID"=>"Bezeichnung,Einheit,Skalierung/Bit,LängePayload(nibbles),min,max,zyklisch abfragen, getConfigAll, BMV,MPPT,Inverter,specialset/getValues,setGetItems",my %Register = ("0x0004"=>"Restore_default°-°-°-°-°-°000°000°-*-°-*-°-*-°-",
my %BMV = (
"0x0100"=>{"Bezeichnung"=>"Devicetype_PID", "ReadingName"=>"Devicetype_PID", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"PID:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0300"=>{"Bezeichnung"=>"Depth_of_the_deepest_discharge", "ReadingName"=>"Depth_of_the_deepest_discharge", "Einheit"=>"Ah", "Skalierung"=>"0.1", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Depth_of_the_deepest_discharge:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0301"=>{"Bezeichnung"=>"Depth_of_the_last_discharge", "ReadingName"=>"Depth_of_the_last_discharge", "Einheit"=>"Ah", "Skalierung"=>"0.1", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Depth_of_the_last_discharge:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0302"=>{"Bezeichnung"=>"Depth_of_the_average_discharge", "ReadingName"=>"Depth_of_the_average_discharge", "Einheit"=>"Ah", "Skalierung"=>"0.1", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Depth_of_the_average_discharge:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0303"=>{"Bezeichnung"=>"Number_of_cycles", "ReadingName"=>"Number_of_cycles", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_cycles:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0304"=>{"Bezeichnung"=>"Number_of_full_discharges", "ReadingName"=>"Number_of_full_discharges", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_full_discharges:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0305"=>{"Bezeichnung"=>"Cumulative_Amp_Hours", "ReadingName"=>"Cumulative_Amp_Hours", "Einheit"=>"Ah", "Skalierung"=>"0.1", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Cumulative_Amp_Hours:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0306"=>{"Bezeichnung"=>"Minimum_Voltage", "ReadingName"=>"Minimum_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Minimum_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0307"=>{"Bezeichnung"=>"Maximum_Voltage", "ReadingName"=>"Maximum_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Maximum_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0308"=>{"Bezeichnung"=>"Seconds_since_full_charge", "ReadingName"=>"Seconds_since_full_charge", "Einheit"=>"s", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Seconds_since_full_charge:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0309"=>{"Bezeichnung"=>"Number_of_automatic_synchronizations", "ReadingName"=>"Number_of_automatic_synchronizations", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_automatic_synchronizations:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x030A"=>{"Bezeichnung"=>"Number_of_Low_Voltage_Alarms", "ReadingName"=>"Number_of_Low_Voltage_Alarms", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_Low_Voltage_Alarms:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x030B"=>{"Bezeichnung"=>"Number_of_High_Voltage_Alarms", "ReadingName"=>"Number_of_High_Voltage_Alarms", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Number_of_High_Voltage_Alarms:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x030E"=>{"Bezeichnung"=>"Minimum_Starter_Voltage", "ReadingName"=>"Minimum_Starter_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Minimum_Starter_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x030F"=>{"Bezeichnung"=>"Maximum_Starter_Voltage", "ReadingName"=>"Maximum_Starter_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Maximum_Starter_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0310"=>{"Bezeichnung"=>"Amount_of_discharged_energy", "ReadingName"=>"Amount_of_discharged_energy", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Amount_of_discharged_energy:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0311"=>{"Bezeichnung"=>"Amount_of_charged_energy", "ReadingName"=>"Amount_of_charged_energy", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Amount_of_charged_energy:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0320"=>{"Bezeichnung"=>"ALARM_LOW_VOLTAGE_SET", "ReadingName"=>"ALARM_LOW_VOLTAGE_SET", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"ALARM_LOW_VOLTAGE_SET:noArg", "setValues"=>"ALARM_LOW_VOLTAGE_SET:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0321"=>{"Bezeichnung"=>"ALARM_LOW_VOLTAGE_CLEAR", "ReadingName"=>"ALARM_LOW_VOLTAGE_CLEAR", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"ALARM_LOW_VOLTAGE_CLEAR:noArg", "setValues"=>"ALARM_LOW_VOLTAGE_CLEAR:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0322"=>{"Bezeichnung"=>"Alarm_High_Voltage", "ReadingName"=>"Alarm_High_Voltage", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Voltage:noArg", "setValues"=>"Alarm_High_Voltage:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0323"=>{"Bezeichnung"=>"Alarm_High_Voltage_Clear", "ReadingName"=>"Alarm_High_Voltage_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Voltage_Clear:noArg", "setValues"=>"Alarm_High_Voltage_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0324"=>{"Bezeichnung"=>"Alarm_Low_Starter", "ReadingName"=>"Alarm_Low_Starter", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_Starter:noArg", "setValues"=>"Alarm_Low_Starter:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0325"=>{"Bezeichnung"=>"Alarm_Low_Starter_Clear", "ReadingName"=>"Alarm_Low_Starter_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_Starter_Clear:noArg", "setValues"=>"Alarm_Low_Starter_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0326"=>{"Bezeichnung"=>"Alarm_High_Starter", "ReadingName"=>"Alarm_High_Starter", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Starter:noArg", "setValues"=>"Alarm_High_Starter:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0327"=>{"Bezeichnung"=>"Alarm_High_Starter_Clear", "ReadingName"=>"Alarm_High_Starter_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Starter_Clear:noArg", "setValues"=>"Alarm_High_Starter_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0328"=>{"Bezeichnung"=>"Alarm_Low_SOC", "ReadingName"=>"Alarm_Low_SOC", "Einheit"=>"%", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_SOC:noArg", "setValues"=>"Alarm_Low_SOC:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0329"=>{"Bezeichnung"=>"Alarm_Low_SOC_Clear", "ReadingName"=>"Alarm_Low_SOC_Clear", "Einheit"=>"%", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_SOC_Clear:noArg", "setValues"=>"Alarm_Low_SOC_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x032A"=>{"Bezeichnung"=>"Alarm_Low_Temperature", "ReadingName"=>"Alarm_Low_Temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_Temperature:noArg", "setValues"=>"Alarm_Low_Temperature:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x032B"=>{"Bezeichnung"=>"Alarm_Low_Temperature_Clear", "ReadingName"=>"Alarm_Low_Temperature_Clear", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Low_Temperature_Clear:noArg", "setValues"=>"Alarm_Low_Temperature_Clear:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x032C"=>{"Bezeichnung"=>"Alarm_High_Temperature", "ReadingName"=>"Alarm_High_Temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Temperature:noArg", "setValues"=>"Alarm_High_Temperature:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x032D"=>{"Bezeichnung"=>"Alarm_High_Temperature_Clear", "ReadingName"=>"Alarm_High_Temperature_Clear", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_High_Temperature_Clear:noArg", "setValues"=>"Alarm_High_Temperature_Clear:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x0331"=>{"Bezeichnung"=>"Alarm_Mid_Voltage", "ReadingName"=>"Alarm_Mid_Voltage", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Mid_Voltage:noArg", "setValues"=>"Alarm_Mid_Voltage:slider,0,0.1,99", "spezialSetGet"=>"-"},
"0x0332"=>{"Bezeichnung"=>"Alarm_Mid_Voltage_Clear", "ReadingName"=>"Alarm_Mid_Voltage_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Mid_Voltage_Clear:noArg", "setValues"=>"Alarm_Mid_Voltage_Clear:slider,0,0.1,99", "spezialSetGet"=>"-"},
"0x034D"=>{"Bezeichnung"=>"Relay_Invert", "ReadingName"=>"Relay_Invert", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Invert:noArg", "setValues"=>"Relay_Invert:off,on", "spezialSetGet"=>"0:1"},
"0x034E"=>{"Bezeichnung"=>"Relay_State_Control", "ReadingName"=>"Relay_State_Control", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"1", "getConfigAll"=>"1", "getValues"=>"Relay_State_Control:noArg", "setValues"=>"Relay_State_Control:open,closed", "spezialSetGet"=>"0:1"},
"0x034F"=>{"Bezeichnung"=>"Relay_Mode", "ReadingName"=>"Relay_Mode", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"2", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Mode:noArg", "setValues"=>"Relay_Mode:default,chrg,rem", "spezialSetGet"=>"0:1:2"},
"0x0350"=>{"Bezeichnung"=>"Relay_battery_low_voltage_set", "ReadingName"=>"Relay_battery_low_voltage_set", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_low_voltage_set:noArg", "setValues"=>"Relay_battery_low_voltage_set:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0351"=>{"Bezeichnung"=>"Relay_battery_low_voltage_clear", "ReadingName"=>"Relay_battery_low_voltage_clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_low_voltage_clear:noArg", "setValues"=>"Relay_battery_low_voltage_clear:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0352"=>{"Bezeichnung"=>"Relay_battery_high_voltage_set", "ReadingName"=>"Relay_battery_high_voltage_set", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_high_voltage_set:noArg", "setValues"=>"Relay_battery_high_voltage_set:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0353"=>{"Bezeichnung"=>"Relay_battery_high_voltage_clear", "ReadingName"=>"Relay_battery_high_voltage_clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"9", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_battery_high_voltage_clear:noArg", "setValues"=>"Relay_battery_high_voltage_clear:slider,9,0.1,95", "spezialSetGet"=>"-"},
"0x0354"=>{"Bezeichnung"=>"Relay_Low_Starter", "ReadingName"=>"Relay_Low_Starter", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Starter:noArg", "setValues"=>"Relay_Low_Starter:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0355"=>{"Bezeichnung"=>"Relay_Low_Starter_Clear", "ReadingName"=>"Relay_Low_Starter_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Starter_Clear:noArg", "setValues"=>"Relay_Low_Starter_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0356"=>{"Bezeichnung"=>"Relay_High_Starter", "ReadingName"=>"Relay_High_Starter", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_High_Starter:noArg", "setValues"=>"Relay_High_Starter:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0357"=>{"Bezeichnung"=>"Relay_High_Starter_Clear", "ReadingName"=>"Relay_High_Starter_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_High_Starter_Clear:noArg", "setValues"=>"Relay_High_Starter_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x035A"=>{"Bezeichnung"=>"Relay_Low_Temperature", "ReadingName"=>"Relay_Low_Temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Temperature:noArg", "setValues"=>"Relay_Low_Temperature:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x035B"=>{"Bezeichnung"=>"Relay_Low_Temperature_Clear", "ReadingName"=>"Relay_Low_Temperature_Clear", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Temperature_Clear:noArg", "setValues"=>"Relay_Low_Temperature_Clear:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x035C"=>{"Bezeichnung"=>"Relay_High_Temperature", "ReadingName"=>"Relay_High_Temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_High_Temperature:noArg", "setValues"=>"Relay_High_Temperature:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x035D"=>{"Bezeichnung"=>"Relay_High_Temperature_Clear", "ReadingName"=>"Relay_High_Temperature_Clear", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"174", "max"=>"372", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_High_Temperature_Clear:noArg", "setValues"=>"Relay_High_Temperature_Clear:multiple,disabled", "spezialSetGet"=>"0:alt"},
"0x0361"=>{"Bezeichnung"=>"Relay_Mid_Voltage", "ReadingName"=>"Relay_Mid_Voltage", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Mid_Voltage:noArg", "setValues"=>"Relay_Mid_Voltage:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0362"=>{"Bezeichnung"=>"Relay_Mid_Voltage_Clear", "ReadingName"=>"Relay_Mid_Voltage_Clear", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Mid_Voltage_Clear:noArg", "setValues"=>"Relay_Mid_Voltage_Clear:slider,0,0.1,95", "spezialSetGet"=>"-"},
"0x0382"=>{"Bezeichnung"=>"Mid-point_voltage", "ReadingName"=>"Mid-point_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Mid-point_voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0383"=>{"Bezeichnung"=>"Mid-point_voltage_deviation", "ReadingName"=>"Mid-point_voltage_deviation", "Einheit"=>"%", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Mid-point_voltage_deviation:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0FFE"=>{"Bezeichnung"=>"TTG", "ReadingName"=>"TTG", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"TTG:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x0FFF"=>{"Bezeichnung"=>"SOC", "ReadingName"=>"SOC", "Einheit"=>"%", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"SOC:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0x1000"=>{"Bezeichnung"=>"Battery_Capacity", "ReadingName"=>"Battery_Capacity", "Einheit"=>"Ah", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"9999", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_Capacity:noArg", "setValues"=>"Battery_Capacity:multiple", "spezialSetGet"=>"-"},
"0x1001"=>{"Bezeichnung"=>"Charged_Voltage", "ReadingName"=>"Charged_Voltage", "Einheit"=>"V", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"95", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Charged_Voltage:noArg", "setValues"=>"Charged_Voltage", "spezialSetGet"=>"-"},
"0x1002"=>{"Bezeichnung"=>"Tail_Current", "ReadingName"=>"Tail_Current", "Einheit"=>"%", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0.5", "max"=>"10", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Tail_Current:noArg", "setValues"=>"Tail_Current:slider,0.5,0.1,10", "spezialSetGet"=>"-"},
"0x1003"=>{"Bezeichnung"=>"Charged_Detection_Time", "ReadingName"=>"Charged_Detection_Time", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"1", "max"=>"50", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Charged_Detection_Time:noArg", "setValues"=>"Charged_Detection_Time:slider,1,1,50", "spezialSetGet"=>"-"},
"0x1004"=>{"Bezeichnung"=>"Charge_Efficiency", "ReadingName"=>"Charge_Efficiency", "Einheit"=>"%", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"50", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Charge_Efficiency:noArg", "setValues"=>"Charge_Efficiency:slider,50,1,99", "spezialSetGet"=>"-"},
"0x1005"=>{"Bezeichnung"=>"Peukert_Coefficient", "ReadingName"=>"Peukert_Coefficient", "Einheit"=>"", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"1", "max"=>"1.5", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Peukert_Coefficient:noArg", "setValues"=>"Peukert_Coefficient:slider,1,0.01,1.5", "spezialSetGet"=>"-"},
"0x1006"=>{"Bezeichnung"=>"Current_Threshold", "ReadingName"=>"Current_Threshold", "Einheit"=>"A", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"2", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Current_Threshold:noArg", "setValues"=>"Current_Threshold:slider,0,0.01,2", "spezialSetGet"=>"-"},
"0x1007"=>{"Bezeichnung"=>"TTG_Delta_T", "ReadingName"=>"TTG_Delta_T", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"12", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"TTG_Delta_T:noArg", "setValues"=>"TTG_Delta_T:slider,0,1,12", "spezialSetGet"=>"-"},
"0x1008"=>{"Bezeichnung"=>"Discharge_Floor_Relay_Low_Soc_Set", "ReadingName"=>"Discharge_Floor_Relay_Low_Soc_Set", "Einheit"=>"%", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Discharge_Floor_Relay_Low_Soc_Set:noArg", "setValues"=>"Discharge_Floor_Relay_Low_Soc_Set:slider,0,0.1,99", "spezialSetGet"=>"-"},
"0x1009"=>{"Bezeichnung"=>"Relay_Low_Soc_Clear", "ReadingName"=>"Relay_Low_Soc_Clear", "Einheit"=>"%", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"99", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Low_Soc_Clear:noArg", "setValues"=>"Relay_Low_Soc_Clear:slider,0,0.1,99", "spezialSetGet"=>"-"},
"0x100A"=>{"Bezeichnung"=>"Relay_minimum_enabled_time", "ReadingName"=>"Relay_minimum_enabled_time", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"500", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_minimum_enabled_time:noArg", "setValues"=>"Relay_minimum_enabled_time:slider,0,1,500", "spezialSetGet"=>"-"},
"0x100B"=>{"Bezeichnung"=>"Relay_Disable_Time", "ReadingName"=>"Relay_Disable_Time", "Einheit"=>"min", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"500", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Relay_Disable_Time:noArg", "setValues"=>"Relay_Disable_Time:slider,0,1,500", "spezialSetGet"=>"-"},
"0x1029"=>{"Bezeichnung"=>"set_Zero_Current", "ReadingName"=>"set_Zero_Current", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"-", "setValues"=>"set_Zero_Current:noArg", "spezialSetGet"=>"-"},
"0x1034"=>{"Bezeichnung"=>"User_Current_Zero_(read_only)", "ReadingName"=>"User_Current_Zero_(read_only)", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"User_Current_Zero:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED7D"=>{"Bezeichnung"=>"Aux_(starter)_Voltage", "ReadingName"=>"Aux_(starter)_Voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Aux_(starter)_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED8D"=>{"Bezeichnung"=>"Main_or_channel_1_battery_voltage", "ReadingName"=>"Main_or_channel_1_battery_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Battery_Voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED8E"=>{"Bezeichnung"=>"Power", "ReadingName"=>"Power", "Einheit"=>"W", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Power:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xED8F"=>{"Bezeichnung"=>"Current", "ReadingName"=>"Current", "Einheit"=>"A", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Current:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDDD"=>{"Bezeichnung"=>"System_yield", "ReadingName"=>"System_yield", "Einheit"=>"kWh", "Skalierung"=>"0.01", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"System_yield:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEDEC"=>{"Bezeichnung"=>"Battery_temperature", "ReadingName"=>"Battery_temperature", "Einheit"=>"K", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"Battery_temperature:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEEE0"=>{"Bezeichnung"=>"Show_Voltage", "ReadingName"=>"Show_Voltage", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Voltage:noArg", "setValues"=>"Show_Voltage:off,on", "spezialSetGet"=>"0:1"},
"0xEEE1"=>{"Bezeichnung"=>"Show_Auxiliary_Voltage", "ReadingName"=>"Show_Auxiliary_Voltage", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Auxiliary_Voltage:noArg", "setValues"=>"Show_Auxiliary_Voltage:off,on", "spezialSetGet"=>"0:1"},
"0xEEE2"=>{"Bezeichnung"=>"Show_Mid_Voltage", "ReadingName"=>"Show_Mid_Voltage", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Mid_Voltage:noArg", "setValues"=>"Show_Mid_Voltage:off,on", "spezialSetGet"=>"0:1"},
"0xEEE3"=>{"Bezeichnung"=>"Show_Current", "ReadingName"=>"Show_Current", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Current:noArg", "setValues"=>"Show_Current:off,on", "spezialSetGet"=>"0:1"},
"0xEEE4"=>{"Bezeichnung"=>"Show_Cunsumed_AH", "ReadingName"=>"Show_Cunsumed_AH", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Cunsumed_AH:noArg", "setValues"=>"Show_Cunsumed_AH:off,on", "spezialSetGet"=>"0:1"},
"0xEEE5"=>{"Bezeichnung"=>"Show_SOC", "ReadingName"=>"Show_SOC", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_SOC:noArg", "setValues"=>"Show_SOC:off,on", "spezialSetGet"=>"0:1"},
"0xEEE6"=>{"Bezeichnung"=>"Show_TTG", "ReadingName"=>"Show_TTG", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_TTG:noArg", "setValues"=>"Show_TTG:off,on", "spezialSetGet"=>"0:1"},
"0xEEE7"=>{"Bezeichnung"=>"Show_Temperature", "ReadingName"=>"Show_Temperature", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Temperature:noArg", "setValues"=>"Show_Temperature:off,on", "spezialSetGet"=>"0:1"},
"0xEEE8"=>{"Bezeichnung"=>"Show_Power", "ReadingName"=>"Show_Power", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Show_Power:noArg", "setValues"=>"Show_Power:off,on", "spezialSetGet"=>"0:1"},
"0xEEF4"=>{"Bezeichnung"=>"Temperature_coefficient", "ReadingName"=>"Temperature_coefficient", "Einheit"=>"%CAP_degC", "Skalierung"=>"0.1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"20", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Temperature_coefficient:noArg", "setValues"=>"Temperature_coefficient:slider,0,0.1,20", "spezialSetGet"=>"-"},
"0xEEF5"=>{"Bezeichnung"=>"Scroll_Speed", "ReadingName"=>"Scroll_Speed", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"1", "max"=>"5", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Scroll_Speed:noArg", "setValues"=>"Scroll_Speed:slider,0,1,5", "spezialSetGet"=>"-"},
"0xEEF6"=>{"Bezeichnung"=>"Setup_Lock", "ReadingName"=>"Setup_Lock", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Setup_Lock:noArg", "setValues"=>"Setup_Lock:off,on", "spezialSetGet"=>"0:1"},
"0xEEF7"=>{"Bezeichnung"=>"Temperature_Unit", "ReadingName"=>"Temperature_Unit", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Temperature_Unit:noArg", "setValues"=>"Temperature_Unit:Celsius,Fahrenheit", "spezialSetGet"=>"0:1"},
"0xEEF8"=>{"Bezeichnung"=>"Auxiliary_Input", "ReadingName"=>"Auxiliary_Input", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"2", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Auxiliary_Input:noArg", "setValues"=>"Auxiliary_Input:start,mid,temp", "spezialSetGet"=>"0:1"},
"0xEEF9"=>{"Bezeichnung"=>"SW_Version", "ReadingName"=>"SW_Version", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"0", "getValues"=>"SW_Version:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
"0xEEFA"=>{"Bezeichnung"=>"Shunt_Volts", "ReadingName"=>"Shunt_Volts", "Einheit"=>"V", "Skalierung"=>"0.001", "Payloadnibbles"=>"4", "min"=>"0.001", "max"=>"0.1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Shunt_Volts:noArg", "setValues"=>"Shunt_Volts", "spezialSetGet"=>"-"},
"0xEEFB"=>{"Bezeichnung"=>"Shunt_Amps", "ReadingName"=>"Shunt_Amps", "Einheit"=>"A", "Skalierung"=>"1", "Payloadnibbles"=>"4", "min"=>"0", "max"=>"9999", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Shunt_Amps:noArg", "setValues"=>"Shunt_Amps", "spezialSetGet"=>"-"},
"0xEEFC"=>{"Bezeichnung"=>"Alarm_Buzzer", "ReadingName"=>"Alarm_Buzzer", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"1", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Alarm_Buzzer:noArg", "setValues"=>"Alarm_Buzzer:off,on", "spezialSetGet"=>"0:1"},
"0xEEFE"=>{"Bezeichnung"=>"Backlight_Intensity", "ReadingName"=>"Backlight_Intensity", "Einheit"=>"", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"0", "max"=>"9", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Backlight_Intensity:noArg", "setValues"=>"Backlight_Intensity:0,1,2,3,4,5,6,7,8,9", "spezialSetGet"=>"-"},
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
"0xEDA0"=>{"Bezeichnung"=>"Lightning_Controller_timer_event_0", "ReadingName"=>"Lightning_Controller_timer_event_0", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_0:noArg", "setValues"=>"Lightning_Controller_timer_event_0", "spezialSetGet"=>"-"},
"0xEDA1"=>{"Bezeichnung"=>"Lightning_Controller_timer_event_1", "ReadingName"=>"Lightning_Controller_timer_event_1", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_1:noArg", "setValues"=>"Lightning_Controller_timer_event_1", "spezialSetGet"=>"-"},
"0xEDA2"=>{"Bezeichnung"=>"Lightning_Controller_timer_event_2", "ReadingName"=>"Lightning_Controller_timer_event_2", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_2:noArg", "setValues"=>"Lightning_Controller_timer_event_2", "spezialSetGet"=>"-"},
"0xEDA3"=>{"Bezeichnung"=>"Lightning_Controller_timer_event_3", "ReadingName"=>"Lightning_Controller_timer_event_3", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_3:noArg", "setValues"=>"Lightning_Controller_timer_event_3", "spezialSetGet"=>"-"},
"0xEDA4"=>{"Bezeichnung"=>"Lightning_Controller_timer_event_4", "ReadingName"=>"Lightning_Controller_timer_event_4", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_4:noArg", "setValues"=>"Lightning_Controller_timer_event_4", "spezialSetGet"=>"-"},
"0xEDA5"=>{"Bezeichnung"=>"Lightning_Controller_timer_event_5", "ReadingName"=>"Lightning_Controller_timer_event_5", "Einheit"=>"", "Skalierung"=>"", "Payloadnibbles"=>"8", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Lightning_Controller_timer_event_5:noArg", "setValues"=>"Lightning_Controller_timer_event_5", "spezialSetGet"=>"-"},
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
"0xEDD5"=>{"Bezeichnung"=>"Main_or_channel_1_battery_voltage", "ReadingName"=>"Main_or_channel_1_battery_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Charger_voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"},
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
"0xEDEF"=>{"Bezeichnung"=>"Battery_voltage_nominal", "ReadingName"=>"Battery_voltage_nominal", "Einheit"=>"V", "Skalierung"=>"1", "Payloadnibbles"=>"2", "min"=>"", "max"=>"", "Zyklisch"=>"0", "getConfigAll"=>"1", "getValues"=>"Battery_voltage_nominal:noArg", "setValues"=>"Battery_voltage_nominal", "spezialSetGet"=>"-"},
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
"0xED8D"=>{"Bezeichnung"=>"Main_or_channel_1_battery_voltage", "ReadingName"=>"Main_or_channel_1_battery_voltage", "Einheit"=>"V", "Skalierung"=>"0.01", "Payloadnibbles"=>"4", "min"=>"", "max"=>"", "Zyklisch"=>"1", "getConfigAll"=>"0", "getValues"=>"Main_or_channel_1_battery_voltage:noArg", "setValues"=>"-", "spezialSetGet"=>"-"});



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
"SOC"=>{"BMV"=>{"Register"=>"0x0FFF","scale"=>1,"ReName"=>"-"}, "MPPT"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}, "Inverter"=>{"Register"=>"-","scale"=>0,"ReName"=>"-"}},
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
 
##################################################################################################################################################
# Define
##################################################################################################################################################
# called upon loading the module MY_MODULE
sub VEDirect_Initialize($)
{
  my ($hash) = @_;

  $hash->{DefFn}    = "VEDirect_Define";
  $hash->{UndefFn}  = "VEDirect_Undef";
  $hash->{SetFn}    = "VEDirect_Set"; 
  $hash->{GetFn}    = "VEDirect_Get";
  $hash->{ReadFn}   = "VEDirect_Read";
  $hash->{ReadyFn}  = "VEDirect_Ready"; 
  $hash->{AttrList} = "disable LogHistoryToFile ". $readingFnAttributes;
  $hash->{helper}{BUFFER} = "";
  $hash->{helper}{lastHex} = "1";  
  $hash->{helper}{tmpData} = {};
}
##################################################################################################################################################
# Define
##################################################################################################################################################
# called when a new definition is created (by hand or from configuration read on FHEM startup)
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

  $hash->{helper}{setusage} = $bmvSets if $type eq "BMV";       
  $hash->{helper}{getusage} = $bmvGets if $type eq "BMV";
  
  $hash->{helper}{setusage} = $MPPTSets if $type eq "MPPT";
  $hash->{helper}{getusage} = $MPPTGets if $type eq "MPPT";

  $hash->{helper}{setusage} = $InverterSets if $type eq "Inverter";
  $hash->{helper}{getusage} = $InverterGets if $type eq "Inverter";
  $hash->{DeviceName} = $dev;
  $hash->{helper}{BUFFER} = "";
  #$hash->{helper}{updatetime} = "-";  
  my $ret = DevIo_OpenDev( $hash, 0, undef );

  ##("Timername", gettimeofday() + 30, "Funktionsname", $hash, 0);  
  #InternalTimer(gettimeofday() + 2, "VEDirect_PollShort", $hash, 0);
  return $ret; 
}
##################################################################################################################################################
# Define
##################################################################################################################################################
sub VEDirect_Attr(@) {
  my ($cmd,$name,$attr_name,$attr_value) = @_;
  if($cmd eq "set") {
        if($attr_name eq "formal") {
      if($attr_value !~ /^yes|no$/) {
          my $err = "Invalid argument $attr_value to $attr_name. Must be yes or no.";
          Log 3, "Hello: ".$err;
          return $err;
      }
    } else {
        return "Unknown attr $attr_name";
    }
  }
  if ($attr_name eq "LogHistoryToFile")
    {
      if ($attr_value ne "") 
      {
        if (-e $attr_value) 
        { 
            Log3 $name, 5, "VEDirect ($name) - Datei existiert";
            if (-w $attr_value) 
            {
              Log3 $name, 5, "VEDirect ($name) - Schreibrecht vorhanden";
            } 
        }
        else
        {
          open(my $fh, "<<", $attr_value) or die "Can't open < $attr_value: $!";
          #open $fh $attr_value or die, "could not create $attr_value: $!";
          close $fh;
        }  
      }
    }
    else
    {
      my $err = "Invalid argument $attr_value to $attr_name. Must be a path and filename";
      Log3 $name, 5, "VEDirect ($name) - Invalid argument $attr_value to $attr_name. Must be a path and filename";
      return $err;
    }
    
  
  return undef;
}
##################################################################################################################################################
# Define
##################################################################################################################################################
# called when definition is undefined 
# (config reload, shutdown or delete of definition)
sub VEDirect_Undef($$)
{
  my ($hash, $name) = @_;
 
  # close the connection 
  DevIo_CloseDev($hash);
  
  return undef;
}
##################################################################################################################################################
# Ready
##################################################################################################################################################
# called repeatedly if device disappeared
sub VEDirect_Ready($)
{
  my ($hash) = @_;
  
  # try to reopen the connection in case the connection is lost
  return DevIo_OpenDev($hash, 1, "VEDirect_Init"); 
}
##################################################################################################################################################
# Define
##################################################################################################################################################
# called when data was received
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
  ###### Daten der seriellen Schnittstelle holen 
  my $buf = DevIo_SimpleRead($hash) ;
  return "" if ( !defined($buf) ); #keine Daten im Buffer enthalten -> abbruch 
  $buf = $hash->{helper}{BUFFER}.$buf ;
  Log3 $name, 5, "VEDirect ($name) - Read Received DATA --> ".$buf;
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
       Log3 $name, 4, "VEDirect ($name) - Read: cutting Hex-MSG: >$hexMsg<";
       VEDirect_ParseHEX($hash, $hexMsg);  #ParseHex-funktion aufrufen (direkte Auswerung der Daten)
      } 
    }  
   #**********************************************************************************************************
   #Prüfen auf Text-Felder und Checksum

   Log3 $name, 5, "VEDirect ($name) - Read: Actual Buffer: >$buf<";
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
          readingsSingleUpdate($hash,"SerialTextInput",$outstr,0) if (index($buf,$start1) != -1);
          readingsSingleUpdate($hash,"SerialTextInput2",$outstr,0) if (index($buf,$start2) != -1 && $start1 ne $start2);
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
     Log3 $name, 5, "VEDirect ($name) - Read: Checksum-Testergebnis: $chk";
     if($chk == 0)
     {
       @buffer = split("\r\n",$outstr);
       Log3 $name, 5, "VEDirect ($name) - Read: Checksum ok --> start parsing ";
       VEDirect_ParseTXT($hash, @buffer);
       @buffer = ();
     }
     else
     {
       Log3 $name, 5, "VEDirect ($name) - Read: Checksum not ok --> CLR block in Buffer";
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
   
    $hash->{helper}{BUFFER} = "" if (length($hash->{helper}{BUFFER}) > 800); 
    my $lastMin = $hash->{helper}{lastHex};
     
    #$teil=substr($original,startpos,anzahlzeichen,ersetzungszeichen);
    my $minu = POSIX::strftime("%M",localtime(time));
    if($lastMin != $minu)
    {
      my $command = ":154";
      DevIo_SimpleWrite($hash, $command, 2, 1) ;
      $hash->{helper}{lastHex} = $minu;
    }
}
##################################################################################################################################################
# ParseTXT
##################################################################################################################################################
sub VEDirect_ParseTXT($@)
{
    my ($hash, @e) = @_;
    my $name = $hash->{NAME}; 
    my $type = $hash->{DeviceType} ;
    my $ChecksumValue = 1;
    my $tmp = join("\r\n",@e);
    Log3 $name, 5, "VEDirect ($name) - ParseTXT: Checksumme ok --> Start Auswertung für $tmp";  
    readingsBeginUpdate($hash); 
    
    for my $i (0 .. int(@e))
    {
      next if(index($e[$i],"\t") == -1);
      my @raw = split("\t",$e[$i]);
      if (defined $Text{$raw[0]}) 
      {
       my $ReadingName = $Text{$raw[0]}->{ 'ReadingName' };
       my $Unit = $Text{$raw[0]}->{ 'Unit' };
       my $Scale = $Text{$raw[0]}->{ 'Scale' };
       my $Rout = $raw[1]; 
       $Rout *= $Scale if($Scale ne "-" && $Scale != "1" ); 
       $Rout .= " ".$Unit if($Unit ne "-" && $Unit ne "ACA" && $Unit ne "RS" && $Unit ne "AR" && $Unit ne "OR" && $Unit ne "WR" && $Unit ne "TOM" && $Unit ne "ERR" && $Unit ne "CS" && $Unit ne "MODE");
       
       if($Unit eq "CS")
       {
        #State_of_operation 
        $Rout = $CS{$Rout} if (defined $CS{$Rout});
       }
       elsif($Unit eq "AR" || $Unit eq "WR")
       {
        #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        #Alarm_reason
        my $tmpVal = $Rout;
        $Rout = "";
        my $bin = sprintf ("%.16b", $tmpVal); 
        Log3 $name, 5, "VEDirect ($name) - ParseTXT: AR: $tmpVal --> bin: $bin";
        my @bits = reverse split(//, $bin);  #my @bits = reverse split(//, $bin) so that $bits[0] ends up being the LSB
        if($raw[1] eq "0")
          {$Rout= $ARtext{$raw[1]}}
        else
        {
          my $cntOnes=0;
          for my $b (0 .. int(@bits))
          {$cntOnes+=1 if($bits[$b] == 1); }
          for my $b (0 .. int(@bits))
          {
            my $arVal = 2**$b;
            Log3 $name, 5, "VEDirect ($name) - ParseTXT: $b --> bits(b): $bits[$b] arVal: $arVal";
            $Rout .= $ARtext{$arVal} if (defined $ARtext{$arVal} && $bits[$b] == 1);
            $Rout .= ", " if ($cntOnes >1);
            $cntOnes-=1 if ($cntOnes >1);
            #readingsBulkUpdate($hash,$ReadingName,$Rout);
          } 
        }
        #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
       }
       elsif($Unit eq "ERR")
       {
        #Error_code
        $Rout = $ERR{$Rout} if (defined $ERR{$Rout});
        readingsBulkUpdate($hash,$ReadingName,$Rout);
       }
       elsif($Unit eq "OR")
       {
         #Off_reason 
         $Rout = $OR{$Rout} if (defined $OR{$Rout});
         readingsBulkUpdate($hash,$ReadingName,$Rout);
       }
       elsif($Unit eq "MPPT")
       {
        #MPPT Tracker_operation_mode 
        $Rout = $MPPT{$Rout} if (defined $MPPT{$Rout});
       }
       elsif($Unit eq "MODE")
       {
        #operation_mode
        $Rout = $MODE{$Rout} if (defined $MODE{$Rout});
       }  
       elsif($raw[0] eq "TTG")
       {
        if($raw[1] != "-1")
        {
          $Rout = sprintf "%02d Tage %02d Stunden %02d Minuten", (gmtime($raw[1]*60))[7,2,1];
        }
        elsif($raw[1] >= "14399")
        {
         $Rout = ">=".sprintf "%02d Tage %02d Stunden %02d Minuten", (gmtime($raw[1]*60))[7,2,1];
        }
        else
        {
         $Rout="unendlich";
        }
        
       }
       elsif($raw[0] eq "H9")
       {
          $Rout = sprintf "%02d Tage %02d Stunden %02d Minuten %02d Sekunden", (gmtime($raw[1]))[7,2,1,0];
       }
       elsif($raw[0] eq "FW")
       {
          $Rout = substr($raw[1],0,length($raw[1])-2).".".substr($raw[1],-2);
          $Rout = substr($Rout,1) if(substr($Rout,0,1) eq "0");
       }
       Log3 $name, 5, "VEDirect ($name) - ParseTXT: Reading: $ReadingName |> Unit: $Unit |> Scale: $Scale |> Output: $Rout";
       readingsBulkUpdateIfChanged($hash,$ReadingName,$Rout);
       #readingsBulkUpdate($hash,$ReadingName,$Rout);
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


 Log3 $name, 5, "VEDirect ($name) - ParseHex received $msg";       #:AD5ED009D05E7
 ##auf gültige Checksumme prüfen
 if(substr($msg,0,2) eq ":A")
  {return undef if(VEDirect_ChecksumHEX(0x55,$msg) eq 0xD);}
 else
  {return undef if(VEDirect_ChecksumHEX(0x55,$msg) eq 0);} 
  
 Log3 $name, 4, "VEDirect ($name) - ParseHex Checksum ok in $msg";   
 
 ##-----------------------------------------------------------------
 ##gültige Checksumm empfangen - Auswerten
 my $response = substr($msg,1,1);
 my $registerNummer;
 my $flags = substr($msg,6,2);
 my $payload; 
 if(substr($msg,0,2) eq ":A")
  {
   #Async message
   $id = "0x".substr($msg,4,2).substr($msg,2,2);   #:A D7ED 00 0E00 79     --> Reg:EDD7 Flag:00, Value 000E  (Scalierung 0,1A , 4 Paylodnibbles)
   Log3 $name, 4, "VEDirect ($name) - ParseHex: Receives Async Msg: $msg for RegisterID $id";
    if ( defined ($Register{ $type }->{ $id }))
    { 
      
      if(defined($Register{ $type }->{ $id }->{'Payloadnibbles'}))
      {
         my $Payloadnibbles = $Register{ $type }->{ $id }->{'Payloadnibbles'};
         if($Payloadnibbles >=30)
         {
            Log3 $name, 3, "VEDirect ($name) - ParseHex: Received Async History MSG";
            $payload = substr($msg,8,length($msg)-10);
            $payload =  VEDirect_ParseHistory($hash, $id, $payload);
            my $Hdate = POSIX::strftime("%Y%m%d",localtime(time+86400*$Register{ $type }->{ $id }->{'Skalierung'}));
            my $HdateOld = POSIX::strftime("%Y%m%d",localtime(time-86400*$Register{ $type }->{ $id }->{'Skalierung'}));
            Log3 $name, 3, "VEDirect ($name) - ParseHex: $Hdate | $HdateOld | $payload ";
            if (defined(AttrVal($name, "LogHistoryToFile", undef)))
            {
              my $logFile = AttrVal($name, "LogHistoryToFile", undef);
              my $found = 0;
              #-----------------------------------------------------------------
              open(my $fh, '<', $logFile) or die $!;
                while(<$fh>){
                   if(index($_, $Hdate." Y") != -1)
                    {
                      $found = 1;  #Wert ist schon vorhanden  
                      Log3 $name, 3, "VEDirect ($name) - ParseHex: $Hdate $payload NICHT in Logdatei $logFile geschrieben - schon vorhanden";
                      if($_ ne $Hdate." ".$payload."\n")
                      {
                        print $fh $Hdate." ".$payload."\n";
                        Log3 $name, 3, "VEDirect ($name) - ParseHex: $Hdate in Logdatei $logFile AKTUALISIERT";
                      };
                    }
                }
              close $fh;
              #-----------------------------------------------------------------
              if($found == 0)
              {
               open(my $fh, '>>', "$logFile") or die "Could not open file '$logFile' $!";
               print $fh $Hdate." ".$payload."\n";
               close $fh;
               Log3 $name, 3, "VEDirect ($name) - ParseHex: Async Msg $Hdate $payload in Logdatei $logFile geschrieben";
              }
              
            }
            
            
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
         Log3 $name, 5, "VEDirect ($name) - VEDirect_ParseHex Updated Reading $Register{ $type }->{ $id }->{'ReadingName'} with Value $payload";
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
   Log3 $name, 4, "VEDirect ($name) - VEDirect_ParseHex received response Type 1";
  }
 elsif($response == "3")
  {
   #Unknown
   Log3 $name, 4, "VEDirect ($name) - Hex_Message_Error -Unknown command";   
   return "Hex_Message_Error -Unknown command";
   
  }
 elsif($response == "4")
  {
   #Error
   Log3 $name, 4, "VEDirect ($name) - Hex_Message_Error -Frame error";
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
            if (defined(AttrVal($name, "LogHistoryToFile", undef)))
            {
              my $logFile = AttrVal($name, "LogHistoryToFile", undef);
              my $found = 0;
              #-----------------------------------------------------------------
              open(my $fh, '<', $logFile) or die $!;
                while(<$fh>){
                   if(index($_, $Hdate." Y") != -1)
                    {
                      $found = 1;  #Wert ist schon vorhanden  
                      Log3 $name, 3, "VEDirect ($name) - ParseHex: Get-Response $Hdate $payload NICHT in Logdatei $logFile geschrieben - schon vorhanden";
                      if($_ ne $Hdate." ".$payload."\n")
                      {
                        print $fh $Hdate." ".$payload."\n";
                        Log3 $name, 3, "VEDirect ($name) - ParseHex: Get-Response $Hdate in Logdatei $logFile AKTUALISIERT";
                      };
                    }
                }
              close $fh;
              #-----------------------------------------------------------------
              if($found == 0)
              {
               open(my $fh, '>>', "$logFile") or die "Could not open file '$logFile' $!";
               print $fh $Hdate." ".$payload."\n";
               close $fh;
               Log3 $name, 3, "VEDirect ($name) - ParseHex: Get-Response Msg $Hdate $payload in Logdatei $logFile geschrieben";
              }
              
            }
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
              if ($Register{ $type }->{ $id }->{'Einheit'} eq "-")
                {
                  readingsSingleUpdate($hash, $Register{ $type }->{ $id }->{'ReadingName'}, $payload, 1);
                  #Log3 $name, 5, "VEDirect ($name) - ParseHEX: Setting Reading $Register{ $type }->{ $id }->{'ReadingName'} ($id) to $payload"; 
                  return $payload;        
                }
              else
                {
                  readingsSingleUpdate($hash, $Register{ $type }->{ $id }->{'ReadingName'}, $payload." ".$Register{ $type }->{ $id }->{'Einheit'}, 1); 
                  #Log3 $name, 5, "VEDirect ($name) - ParseHEX: Setting Reading $Register{ $type }->{ $id }->{'ReadingName'} ($id) to $payload." ".$Register{ $type }->{ $id }->{'Einheit'}"; 
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
# ChecksumHEx
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
# ChecksumTXT
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
  #Log3 $name, 5, "VEDirect ($name) - ChecksumTXT: $chksum";
  return $chksum;     
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
# Set
##################################################################################################################################################

sub VEDirect_Set($$@)
{
    my ($hash, $name, $cmd, @args) = @_;
    my $error;
    my $type = $hash->{DeviceType} ;
    my $usage = "unknown argument $cmd, choose one of $hash->{helper}{setusage}"; 
    return $usage if(($cmd eq "" || $cmd eq "?")); 
    Log3 $name, 5, "VEDirect ($name) - Set command: $cmd Arguments $args[0]";
    my ($reg,$scale,$unit,$setitm,$spezSetGet,$payload);
    ## $cmd =~ s/_//g;
    if($type eq "BMV" && defined($bmv_reg{$cmd}))
    {
      $reg = $bmv_reg{$cmd}->{"Register"};
      $scale = $bmv_reg{$cmd}->{"Scale"};
      $unit = $bmv_reg{$cmd}->{"Unit"};
      $setitm = $bmv_reg{$cmd}->{"SetItems"};
      $spezSetGet = $bmv_reg{$cmd}->{"SpezialSetGet"};
      $payload = $bmv_reg{$cmd}->{"Payloadnibbles"}; #$Register{ $type }->{ $reg }->{'min'}
      Log3 $name, 5, "VEDirect ($name) - Set command: $cmd Arguments $args[0] ---> BMV-Register $reg identified";
    }
    elsif($type eq "MPPT" && defined($mppt_reg{$cmd}))
    {
      $reg = $mppt_reg{$cmd}->{"Register"};
      $scale = $mppt_reg{$cmd}->{"Scale"};
      $unit = $mppt_reg{$cmd}->{"Unit"};
      $setitm = $mppt_reg{$cmd}->{"SetItems"};
      $spezSetGet = $mppt_reg{$cmd}->{"SpezialSetGet"};
      $payload = $mppt_reg{$cmd}->{"Payloadnibbles"}; #$Register{ $type }->{ $reg }->{'min'}
      Log3 $name, 5, "VEDirect ($name) - Set command: $cmd Arguments $args[0] ---> MPPT-Register $reg identified";
    }
    elsif($type eq "Inverter" && defined($inverter_reg{$cmd}))
    {
      $reg = $inverter_reg{$cmd}->{"Register"};
      $scale = $inverter_reg{$cmd}->{"Scale"};
      $unit = $inverter_reg{$cmd}->{"Unit"};
      $setitm = $inverter_reg{$cmd}->{"SetItems"};
      $spezSetGet = $inverter_reg{$cmd}->{"SpezialSetGet"};
      $payload = $inverter_reg{$cmd}->{"Payloadnibbles"};
      Log3 $name, 5, "VEDirect ($name) - Set command: $cmd Arguments $args[0] ---> Inverter-Register $reg identified"; 
    }
    else{return $usage;} 
    $scale =~ s/,/./g;
 ##------------------------------------------------------------------------
 ## Informationen aus dem %Register zum Befehl holen und verarbeiten
    if(defined($reg))
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
          $args[0] = $args[0] * ( 1 / $scale );    
          Log3 $name, 5, "VEDirect ($name) - Set skalierter Setzwert: $args[0] ";
          $args[0] = sprintf("%02X", $args[0]);
          while(length($args[0]) < $payload)   
            {
              $args[0] = "0".$args[0];
            }
          $args[0] = substr($args[0],2,2).substr($args[0],0,2) if(length($args[0]) == 4); ##1234 --> 3412
          $args[0] = substr($args[0],6,2).substr($args[0],4,2).substr($args[0],2,2).substr($args[0],0,2) if(length($args[0]) == 8); ##01234567 --> 67452301 
        }
        else 
        {
          ##wenn args[0] keine nummer enthält
          my @tmtset = split(":",$setitm);
          my @setItems = split(",",$tmtset[1]); 
          #my @setItems = split(",",$setitm, index($setitm,":"));
          #$setItems[0] = substr($setItems[0],1);
          my @setValues = split(':',$spezSetGet);
          for my $v (0 .. $#setItems)
            {
              Log3 $name, 5, "VEDirect ($name) - SET: setItems: $setItems[$v] --> InputValue: $args[0]";
              if ($setItems[$v] eq $args[0])
              {
                Log3 $name, 5, "VEDirect ($name) - SET: setItems: $setItems[$v] --> SpezialSetGetValue: $setValues[$v]";
                $args[0] = $setValues[$v];
                $args[0] = "0".$args[0] if (length($args[0])==1 ||length($args[0])==3);
                last;
              }
            } 
        }
        $command .= $args[0];
        $command .= VEDirect_ChecksumHEX(0x55,$command);
        Log3 $name, 5, "VEDirect ($name) - VEDirect_Set command $cmd - sending --> $command";
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
    my $debugarg = "-";
    $debugarg = $args[0] if(defined($args[0])); 
    
 ##------------------------------------------------------------------------
 ## Informationen aus dem %Register zum Befehl holen und verarbeiten
    if ($cmd eq "History_all" && $type eq "MPPT")
    { 
       ## MPPT special Gets
       Log3 $name, 5, "VEDirect ($name) - get History_all ++++++++++++++++++++++++++++++++++++";  
       my @c;
       for my $c (0 ..29)
       {
        $reg = ":7".sprintf("%02X", (0x50 + $c))."1000";
        $reg .= VEDirect_ChecksumHEX(0x55,$reg);
        Log3 $name, 5, "VEDirect ($name) - get command $cmd $debugarg - sending --> $reg";  
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
          Log3 $name, 5, "VEDirect $name Get: received >$parse<"; 
         }
       }
     return join("\n",@c)
    }
    elsif ($cmd eq "ConfigAll")
    {
      Log3 $name, 5, "VEDirect ($name) - get ConfigAll ++++++++++++++++++++++++++++++++++++";
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
            Log3 $name, 5, "VEDirect ($name) - get command $cmd $debugarg - sending --> $command";
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
        Log3 $name, 5, "VEDirect ($name) - Get command: $cmd  ---> Register $reg identified";    
        ##Befehlsaufbau: ":7"(Get-Befehl) plus "00" Flags plus checksum
        ##Command 7 ("Get") Returns a get response with the requested data or error is returned.
        ##uint16 the id of the value to set
        ##uint8 flags, should be set to zero
        my $command = ":7".substr($reg, -2, 2).substr($reg, 2, 2)."00";
        if ($Register{ $type }->{ $key }->{"getValues"} ne "-")
        {
          $command .= VEDirect_ChecksumHEX(0x55,$command); 
          Log3 $name, 5, "VEDirect ($name) - get command $cmd - sending --> $command";
          DevIo_SimpleWrite($hash, $command, 2, 1) ;
        }  
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
      else
      {
        return $usage;
      }
    }  
}
##################################################################################################################################################
# Define
##################################################################################################################################################
# will be executed upon successful connection establishment (see DevIo_OpenDev())
sub VEDirect_Init($)
{
    my ($hash) = @_;

    # send a Device-ID request to the device
    DevIo_SimpleWrite($hash, ":451", 2, 1);
    return undef; 
}
1;
