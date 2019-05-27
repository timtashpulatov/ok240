EESchema Schematic File Version 4
LIBS:OceanKbd-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L MCU_Module:Arduino_Nano_v3.x A1
U 1 1 5CEA5507
P 6000 3500
F 0 "A1" H 6000 2411 50  0000 C CNN
F 1 "Arduino_Nano_v3.x" H 6000 2320 50  0000 C CNN
F 2 "Module:Arduino_Nano" H 6550 2500 50  0000 C CNN
F 3 "http://www.mouser.com/pdfdocs/Gravitech_Arduino_Nano3_0.pdf" H 6000 2500 50  0001 C CNN
	1    6000 3500
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0101
U 1 1 5CEA7998
P 6000 4850
F 0 "#PWR0101" H 6000 4600 50  0001 C CNN
F 1 "GND" H 6005 4677 50  0001 C CNN
F 2 "" H 6000 4850 50  0001 C CNN
F 3 "" H 6000 4850 50  0001 C CNN
	1    6000 4850
	1    0    0    -1  
$EndComp
Wire Wire Line
	6000 4850 6000 4750
Wire Wire Line
	6100 4500 6100 4750
Wire Wire Line
	6100 4750 6000 4750
Connection ~ 6000 4750
Wire Wire Line
	6000 4750 6000 4500
$Comp
L Connector_Generic:Conn_02x15_Odd_Even X2
U 1 1 5CEBDC95
P 7850 3550
F 0 "X2" H 7900 4467 50  0000 C CNN
F 1 "Conn_02x15_Odd_Even" H 7900 4376 50  0000 C CNN
F 2 "Connector_PinHeader_2.54mm:PinHeader_2x15_P2.54mm_Vertical" H 8450 2700 50  0000 C CNN
F 3 "~" H 7850 3550 50  0001 C CNN
	1    7850 3550
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0102
U 1 1 5CEC25D4
P 8250 2850
F 0 "#PWR0102" H 8250 2600 50  0001 C CNN
F 1 "GND" H 8255 2677 50  0001 C CNN
F 2 "" H 8250 2850 50  0001 C CNN
F 3 "" H 8250 2850 50  0001 C CNN
	1    8250 2850
	0    -1   -1   0   
$EndComp
Wire Wire Line
	8150 2850 8250 2850
Wire Wire Line
	8250 2850 8250 2950
Wire Wire Line
	8250 2950 8150 2950
Connection ~ 8250 2850
$Comp
L power:GND #PWR0103
U 1 1 5CEC3A32
P 7650 2850
F 0 "#PWR0103" H 7650 2600 50  0001 C CNN
F 1 "GND" H 7655 2677 50  0001 C CNN
F 2 "" H 7650 2850 50  0001 C CNN
F 3 "" H 7650 2850 50  0001 C CNN
	1    7650 2850
	0    1    1    0   
$EndComp
Wire Wire Line
	7650 3050 7400 3050
Wire Wire Line
	8150 3050 8450 3050
Wire Wire Line
	8450 3050 8450 2550
Wire Wire Line
	8450 2550 7400 2550
Wire Wire Line
	7400 2550 7400 3050
Connection ~ 7400 3050
Wire Wire Line
	7400 3050 7150 3050
$Comp
L power:+5V #PWR0104
U 1 1 5CEC5A1B
P 7150 3050
F 0 "#PWR0104" H 7150 2900 50  0001 C CNN
F 1 "+5V" V 7165 3178 50  0000 L CNN
F 2 "" H 7150 3050 50  0001 C CNN
F 3 "" H 7150 3050 50  0001 C CNN
	1    7150 3050
	0    -1   -1   0   
$EndComp
$Comp
L power:GND #PWR0105
U 1 1 5CEC6060
P 7650 4150
F 0 "#PWR0105" H 7650 3900 50  0001 C CNN
F 1 "GND" H 7655 3977 50  0001 C CNN
F 2 "" H 7650 4150 50  0001 C CNN
F 3 "" H 7650 4150 50  0001 C CNN
	1    7650 4150
	0    1    1    0   
$EndComp
Text Label 7650 3250 2    50   ~ 0
PA0
Text Label 8150 3250 0    50   ~ 0
PA1
Text Label 7650 3150 2    50   ~ 0
PA2
Text Label 8150 3150 0    50   ~ 0
PA3
Text Label 8150 3350 0    50   ~ 0
PA4
Text Label 7650 3350 2    50   ~ 0
PA5
Text Label 8150 3450 0    50   ~ 0
PA6
Text Label 7650 3450 2    50   ~ 0
PA7
Text Label 7650 3750 2    50   ~ 0
PC0
Text Label 8150 3850 0    50   ~ 0
PC1
Text Label 8150 3950 0    50   ~ 0
PC2
Text Label 8150 4050 0    50   ~ 0
PC3
Text Label 8150 3750 0    50   ~ 0
PC4
Text Label 7650 3650 2    50   ~ 0
PC5
Text Label 7650 3550 2    50   ~ 0
PC6
Text Label 8150 3550 0    50   ~ 0
PC7
Text Label 8150 3650 0    50   ~ 0
~RESET
Text Label 7650 4050 2    50   ~ 0
JST1
Text Label 7650 3950 2    50   ~ 0
JST2
Text Label 7650 3850 2    50   ~ 0
JST3
Text Label 8150 4150 0    50   ~ 0
BEEP
Text Label 7650 4250 2    50   ~ 0
Rst0
Text Label 8150 4250 0    50   ~ 0
Rst1
Text Notes 8350 4250 0    50   ~ 0
AKA Keybrd
Text Label 5500 4200 2    50   ~ 0
PA5
Text Label 5500 4100 2    50   ~ 0
PA4
Text Label 5500 4000 2    50   ~ 0
PA3
Text Label 5500 3900 2    50   ~ 0
PA2
Text Label 5500 3800 2    50   ~ 0
PA1
Text Label 5500 3700 2    50   ~ 0
PA0
Text Label 5500 3600 2    50   ~ 0
PA7
Text Label 5500 3500 2    50   ~ 0
PA6
Text Label 5500 3400 2    50   ~ 0
Rst1
Text Label 5500 3100 2    50   ~ 0
PC7
$Comp
L Device:Speaker LS1
U 1 1 5CEC30D2
P 10000 4150
F 0 "LS1" H 10170 4191 50  0000 L CNN
F 1 "Speaker" H 10170 4100 50  0000 L CNN
F 2 "Buzzer_Beeper:Buzzer_12x9.5RM7.6" H 10170 4009 50  0000 L CNN
F 3 "~" H 9990 4100 50  0001 C CNN
	1    10000 4150
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR0106
U 1 1 5CEC570E
P 9800 4250
F 0 "#PWR0106" H 9800 4000 50  0001 C CNN
F 1 "GND" H 9805 4077 50  0001 C CNN
F 2 "" H 9800 4250 50  0001 C CNN
F 3 "" H 9800 4250 50  0001 C CNN
	1    9800 4250
	1    0    0    -1  
$EndComp
$Comp
L Device:CP1 C1
U 1 1 5CEC75EF
P 9650 4150
F 0 "C1" V 9992 4150 50  0000 C CNN
F 1 "CP1" V 9901 4150 50  0000 C CNN
F 2 "Capacitor_THT:CP_Radial_D5.0mm_P2.50mm" V 9810 4150 50  0000 C CNN
F 3 "~" H 9650 4150 50  0001 C CNN
	1    9650 4150
	0    -1   -1   0   
$EndComp
Wire Wire Line
	8150 4150 9500 4150
Wire Wire Line
	6200 2500 6200 2450
Wire Wire Line
	6200 2450 7400 2450
Wire Wire Line
	7400 2450 7400 2550
Connection ~ 7400 2550
$Comp
L Ocean240:Mini-DIN-6 X1
U 1 1 5CEBF02D
P 4350 3000
F 0 "X1" H 4350 3367 50  0000 C CNN
F 1 "Mini-DIN-6" H 4350 3276 50  0000 C CNN
F 2 "ps2kbd:DS1093-01-XX6X" H 4350 2750 50  0000 C CNN
F 3 "http://service.powerdynamics.com/ec/Catalog17/Section%2011.pdf" H 4350 3000 50  0001 C CNN
	1    4350 3000
	1    0    0    -1  
$EndComp
NoConn ~ 4050 3100
Text Label 4650 3100 0    50   ~ 0
DATA
Text Label 4650 2900 0    50   ~ 0
CLK
$Comp
L power:GND #PWR0107
U 1 1 5CED3EC0
P 4650 3000
F 0 "#PWR0107" H 4650 2750 50  0001 C CNN
F 1 "GND" H 4655 2827 50  0001 C CNN
F 2 "" H 4650 3000 50  0001 C CNN
F 3 "" H 4650 3000 50  0001 C CNN
	1    4650 3000
	0    -1   -1   0   
$EndComp
NoConn ~ 4050 2900
Wire Wire Line
	6200 2450 3900 2450
Wire Wire Line
	3900 2450 3900 3000
Wire Wire Line
	3900 3000 4050 3000
Connection ~ 6200 2450
Wire Wire Line
	4650 2900 5250 2900
Wire Wire Line
	5250 2900 5250 3200
Wire Wire Line
	5250 3200 5500 3200
Wire Wire Line
	4650 3100 5150 3100
Wire Wire Line
	5150 3100 5150 3300
Wire Wire Line
	5150 3300 5500 3300
$Comp
L power:GND #PWR?
U 1 1 5CEDD196
P 4300 3350
F 0 "#PWR?" H 4300 3100 50  0001 C CNN
F 1 "GND" H 4305 3177 50  0001 C CNN
F 2 "" H 4300 3350 50  0001 C CNN
F 3 "" H 4300 3350 50  0001 C CNN
	1    4300 3350
	1    0    0    -1  
$EndComp
$EndSCHEMATC
