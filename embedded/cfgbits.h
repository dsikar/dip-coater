// ************************************************************************
// Default Configuration Bit Settings: (Change these to suit your needs)
//
// The comments above each show the actual descriptions used in the
// Configuration Bits dialog window of MPLAB 7.00.  For your convenience,
// these configuration settings are also shown in the same order as in
// MPLAB 7.00
//
// For PIC18F4550 family processors, including:
// 18F4550, 18F2550, 18F4455, 18F2455
//
// ************************************************************************

#ifndef __CONFIG_BITS
  #define  __CONFIG_BITS

// === CONFIG1L (300000h) ===
// "Full-Speed USB Clock Source Selection":	"Clock src from 96 MHz PLL/2"
#pragma config USBDIV = 2
//
// "CPU System Clock Postscaler":		"[OSC1/OSC2 Src: /1][96 MHz PLL Src: /2]"
#pragma config CPUDIV = OSC1_PLL2
//
// "96MHz PLL Prescaler":			"Divide by 5 (20 MHz input)"
#pragma config PLLDIV = 5


// === CONFIG1H (300001h) ===
// "Oscillator":				"HS: USB-HS"
#pragma config FOSC = HS
//
// "Fail-Safe Clock Monitor Enable":		"Enabled"
#pragma config FCMEN = ON
//
// "Internal External Switch Over Mode": 	"Enabled"
#pragma config IESO = ON


// === CONFIG2L (300002h) ===
// "USB Voltage Regulator":			"Enabled"
#pragma config VREGEN = ON 
//
// "Power Up Timer":				"Disabled"
#pragma config PWRT = OFF
//
// "Brown Out Detect":			"Enabled in hardware, SBOREN disabled"
#pragma config BOR = ON
//
// "Brown Out Voltage":			"2.0V"
#pragma config BORV = 2


// === CONFIG2H (300003h) ===
// "Watchdog Timer":				"Disabled"
#pragma config WDT = OFF
//
// "Watchdog Postscaler":			"1:128"
#pragma config WDTPS = 128


// === CONFIG3H (300005h) ===
// "CCP2 Mux":				"RC1"
#pragma config CCP2MX = ON
//
// "PortB A/D Enable":			"PORTB<4:0> configured as digital I/O on reset"
#pragma config PBADEN = OFF
//
// "Low Power Timer1 Osc enable":		"Enabled"
#pragma config LPT1OSC = ON
//
// "Master Clear Enable":			"MCLR Enabled,RE3 Disabled"
#pragma config MCLRE = ON


// === CONFIG4L (300006h) ===
// "Stack Overflow Reset":			"Enabled"
#pragma config STVREN = OFF
//
// "Low Voltage Program":			"Disabled"
#pragma config LVP = OFF
//
// "Dedicated In-Circuit Port (ICD/ICSP)":	"Disabled"
#pragma config ICPRT = OFF
//
// "Extended CPU Enable":			"Disabled"
#pragma config XINST = OFF
//
// <Background debugger enable bit>
//#pragma config DEBUG = OFF 


// === CONFIG5L (300008h) ===
// "Code Protect 00800-001FFF": "Disabled" 
#pragma config CP0 = OFF
//
// "Code Protect 02000-003FFF": "Disabled"
#pragma config CP1 = OFF 
//
// "Code Protect 04000-005FFF": "Disabled"
#pragma config CP2 = OFF 
//
// "Code Protect 06000-007FFF": "Disabled"
#pragma config CP3 = OFF 


// === CONFIG5H (300009h) ===
// "Data EE Read Protect": "DISABLED"
#pragma config CPD = OFF 
//
// "Data Code Protect Boot": "DISABLED"
#pragma config CPB = OFF 


// === CONFIG6L (30000Ah) ===
// "Table Write Protect 00800-001FFF": "Disabled" 
#pragma config WRT0 = OFF
//
// "Table Write Protect 02000-003FFF": "Disabled"
#pragma config WRT1 = OFF
//
// "Table Write Protect 04000-005FFF": "Disabled"
#pragma config WRT2 = OFF
//
// "Table Write Protect 06000-007FFF": "Disabled"
#pragma config WRT3 = OFF

 

// === CONFIG6H (30000Bh) ===
// "Data EE Write Protect": "DISABLED"
#pragma config WRTD = OFF
//
// "Table Write Protect Boot": "DISABLED"
#pragma config WRTB = OFF
//
// "Config Write Protect": "DISABLED"
#pragma config WRTC = OFF


// === CONFIG7L (30000Ch) ===
// "Table Read Protect 00800-001FFF": "Disabled" 
#pragma config EBTR0 = OFF 
//
// "Table Read Protect 02000-003FFF": "Disabled"
#pragma config EBTR1 = OFF 
//
// "Table Read Protect 04000-005FFF": "Disabled"
#pragma config EBTR2 = OFF 
//
// "Table Read Protect 06000-007FFF": "Disabled"
#pragma config EBTR3 = OFF 
 

// === CONFIG7H (30000Dh) ===
// "Table Read Protect Boot": "DISABLED"
#pragma config EBTRB = OFF 


#endif  // #ifndef __CONFIG_BITS
