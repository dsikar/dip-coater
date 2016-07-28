/*********************************************************************
 *
 *                  External LCD access routines
 *
 *********************************************************************
 * FileName:        XLCD.c
 * Dependencies:    xlcd.h
 * Processor:       PIC18
 * Complier:        MCC18 v1.00.50 or higher
 *                  HITECH PICC-18 V8.10PL1 or higher
 * Company:         Microchip Technology, Inc.
 *
 * Software License Agreement
 * The software supplied herewith by Microchip Technology Incorporated
 * (the “Company”) for its PICmicro® Microcontroller is intended and
 * supplied to you, the Company’s customer, for use solely and
 * exclusively on Microchip PICmicro Microcontroller products. The
 * software is owned by the Company and/or its supplier, and is
 * protected under applicable copyright laws. All rights are reserved.
 * Any use in violation of the foregoing restrictions may subject the
 * user to criminal sanctions under applicable laws, as well as to
 * civil liability for the breach of the terms and conditions of this
 * license.
 *
 * THIS SOFTWARE IS PROVIDED IN AN “AS IS” CONDITION. NO WARRANTIES,
 * WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED
 * TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE COMPANY SHALL NOT,
 * IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL OR
 * CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
 *
 * HiTech PICC18 Compiler Options excluding device selection:
 *                  -FAKELOCAL -G -E -C
 *
 * Author               Date    Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Naveen Raj          6/9/03         Original        (Rev 1.0)
 ********************************************************************/
#include "xlcd.h"
#include "delays.h"

#include "xlcd.h"

#define XLCDCursorOnBlinkOn()        XLCDCommand(0x0F)	//the user may refer the LCD data sheet
#define XLCDCursorOnBlinkOff()       XLCDCommand(0x0E)	//and generate commands like this
#define XLCDDisplayOnCursorOff()     XLCDCommand(0x0C)
#define XLCDDisplayOff()             XLCDCommand(0x08)
#define XLCDCursorMoveLeft()         XLCDCommand(0x10)
#define XLCDCursorMoveRight()        XLCDCommand(0x14)
#define XLCDDisplayMoveLeft()        XLCDCommand(0x18)
#define XLCDDisplayMoveRight()       XLCDCommand(0x1C)

// constants
#define LCD_SETCGRAMADDR 0x40
#define BACK_SLASH 0x00
#define UP_ARROW 0x01
#define DOWN_ARROW 0x02
#define HIGH 0x01
#define LOW 0x00



// prototypes
void eeprom_set_values(void);
void eepromWrite(unsigned char, unsigned char);
unsigned char eepromRead(unsigned char);
void printSpeed(int);
void printSpeed2(int);
void reverse(char s[]);
void itoa(int n, char s[]);
void XLCD_Welcome(void);
void saveSpeed(void);
int speedInit(void);
void checkIntervals(void);
void resetIntervals(void);
void XLCDPrintMotionCharacters(char);
unsigned char get_direction(void);
unsigned char get_speed(unsigned char, unsigned char);
int two_exp(int);

// control variables
volatile char bChangedOnOffState = 0;
volatile char bChangedUpState = 0;
volatile char bChangedDownState = 0;
volatile char bChangedFasterState = 0;
volatile char bChangedSlowerState = 0;
volatile char bOn = 0;
unsigned char bDown = 1; // going down by default

// special characters
unsigned int upArrow[8] = {
	0b00000100,
	0b00001110,
	0b00011111,
	0b00000100,
	0b00000100,
	0b00000100,
	0b00000100,
	0b00000100
};

unsigned int downArrow[8] = {
	0b00000100,
	0b00000100,
	0b00000100,
	0b00000100,
	0b00000100,
	0b00011111,
	0b00001110,
	0b00000100
};

unsigned int backSlash[8] = {
	0b00000000,
	0b00010000,
	0b00001000,
	0b00000100,
	0b00000010,
	0b00000001,
	0b00000000,
	0b00000000
};

// speed variables
int iSpeed = 0;
// int iMaxSpeed = 10;
// int iMaxSpeed = 169;
/*
Total number of values written to eeprom = 255
Every sequence of 3 values contains the integer and decimal part of the speed (1st and 2nd value)
and the speed itself, to be written to the 16f84A (working as the oscillator).

Max speed in cm/m = 84 (index starting at 0, 85 distinct speeds)

Max speed in mm/s = 31 (index starting at 0) 32 distinct speeds



To obtain the speed to be printed to lcd
1. Multiply speed (i) by three.
2. eepromRead(i) = integer part
3. eepromRead(i+1) = decimal part
4. eepromRead(i+2) = speed to be written to oscillator
*/

// cm/min
//int iMaxSpeed = 84; // trying to de-gremlin the system
// int iMaxSpeed = 79;
// mm/seg
int iMaxSpeed = 31; 
int iMinSpeed = -1;
int lCurrentCounter = 0;
int CONTINUOUS_CHANGE_INTERVAL = 30000;
int iCCI = 30000;
int MIN_CCI = 10000;
int CCI_STEP = 20000;
int iChange = 0;
int iMaxChanges = 1;
int iIncreasedExp = 0;
int iMaxIncreasedExp = 5;

char line1[]="   CONSTRUMAQ   ";
char line2[]="   DIP COATER   ";
// cm/m
//char line3[]="Vel 00,00 cm/min";
// mm/s
char line3[]="Vel  0,00 mm/seg";
char line4[]="                ";

char STOP = '-';
char START = '*';

char _vXLCDreg =0;          //Used as a flag to check if from XLCDInit()

/*********************************************************************
 * Function         : void XLCDInit(void)
 * PreCondition     : None
 * Input            : None
 * Output           : None
 * Side Effects     : None
 * Overview         : LCD is intialized
 * Note             : This function will work with all Hitachi HD447780
 *                    LCD controller.
 ********************************************************************/
// additional functions lifted from
// http://www.electro-tech-online.com/microcontrollers/117408-hd44780-timing-problem.html

/*** START DELAY FUNCTIONS ***/

void XLCDDelay2s (void)
{
	/* 	Assuming 5MHz internal clock
	*/
	Delay10KTCYx(250);
	Delay10KTCYx(250);
	Delay10KTCYx(250);
	Delay10KTCYx(250);
    return;
}

void XLCDDelay15ms (void)
{
	/* 	4000000 _ 1
	   	x       _ 0.0015
	   	x = 6000
		Delay1KTCYx(6);
		5000000 _ 1
		x	    _ 0.0015
		x = 7500
		Delay1KTCYx(8);
	*/
	Delay1KTCYx(8); // delaying 8k cyles, instead of 7.5
    return;
}

void XLCDDelay4ms (void)
{
	/*
		5000000 _ 1
		x	    _ 0.0004
		x = 2000
	*/
	Delay1KTCYx(2);
    return;
}

void XLCDDelay2ms(void)
{
	/*
		5000000 _ 1
		x	    _ 0.0002
		x = 1000
	*/
	Delay1KTCYx(1);
    return;
}

void XLCD_Delay500ns(void)
{
	/*
		500 billionths of a second = 1/2 millionth of a second.
		Clock ticking at 5MHz, 5 million cycles per second.
		5 cycles = 1 millionth of a second
		2.5 cycles = 1/2 millionth of a second
	*/
    Nop();
    Nop();
    Nop();
}

void Pulse_E(void)
{
	/*
		In the example given (http://www.electro-tech-online.com/microcontrollers/117408-hd44780-timing-problem.html),
		the author has it "working on a PIC 18F4685 @ 48MHz"
		Delay10TCYx(3); ~ 30000
		48000000 _ 1
		30000    _ x
		x = 0.000625 ~ 625us
       
		Datasheet says on pg 50, "Bus Timing Characteristics"
		Enable pulse width (high level) 450ns minimum
		
		So I'll change this to 500ns.
	*/
	XLCD_ENPIN = 1;
	XLCD_Delay500ns();
	XLCD_ENPIN = 0;
}

void XLCDDelay120ms(void){
	Delay10KTCYx(6);
}

/*** END DELAY FUNCTIONS ***/

void XLCDInit(void)
{
	// Delay 1/2 second to give LCD time to power up properly
	XLCDDelay120ms();
	XLCDDelay120ms();
	XLCDDelay120ms();
	XLCDDelay120ms();
	XLCDDelay120ms();
	/*This par of the code is initialization by instruction*/
	_vXLCDreg=1; 

	//end of data port initialization
	//control port initialization
	XLCD_RSPIN_TRIS =0;                         //make control ports output
	XLCD_ENPIN_TRIS =0;	
	XLCD_RSPIN  =0;                             //clear control ports
	XLCD_ENPIN  =0;

    //Lower 4-bits of the DATAPORT output
	XLCD_DATAPORT_TRIS  &= 0xf0;
    XLCD_DATAPORT &= 0xf0;

	// Set control buttons and led, on/off, on/off led, up, down, increment, decrement
	// on/off
	XLCD_ONOFF_TRIS  = 1; // input
    XLCD_LED_TRIS = 0; // output
	XLCD_LED_PIN = 0; // led off
	// up
	XLCD_UP_TRIS = 1; // input
	// down
	XLCD_DOWN_TRIS = 1;
	// increment
	XLCD_FASTER_TRIS = 1;
	// decrement
	XLCD_SLOWER_TRIS = 1;

	//initialization by instruction
	
	/* From datasheet pg 36 :
	Wait for more than 40 ms after VCC rises to 2.7 V
	Wait for more than 15 ms after VCC rises to 4.5 V
	*/
	XLCDDelay15ms(); 

                          // Lower nibble interface
    XLCD_DATAPORT       &= 0xf0;    // Clear lower port
    XLCD_DATAPORT   |= 0b00000011;  // Function set cmd(4-bit interface)

	Pulse_E();
	// Wait for more than 4.1 ms
	XLCDDelay4ms();
	XLCDDelay2ms();

	Pulse_E();
	// Wait for more than 100 µs ~ from datasheet,
	// in practice, 120 ms
	XLCDDelay120ms(); //LCD_Delay();  // 1k cycles Delay1KTCYx(1);
	Pulse_E();
     
	//required only for 4 bit interface as per LCDdatasheet    
  
    XLCD_DATAPORT       &= 0xf0;    // Clear lower port
    XLCD_DATAPORT   |= 0b00000010;  // Function set cmd(4-bit interface)

	Pulse_E();
	XLCDDelay120ms();
	
	//-----------------------------------------------------------------------
	//function set command "0 0 1 DL N F X X"
	//-----------------------------------------------------------------------

    XLCDCommand(0b00101000);    //if 2Line 5x8
    
	XLCDCommand(0b00001100); //display on cursor on blink oFF

    XLCDCommand(0b00000001);        //display clear

	/////////////////////////////////////////////////////////////////////////////////
	//Entry mode setting
	////////////////////////////////////////////////////////////////////////////////
	//Entry mode command " 0 0 0 0 0 1 ID S "
	//ID =0 no cursor increment during read and write
	//ID =1 cursor increment during read and write
	//S =0 no display during read and write
	//S =1 display shift 
       
    XLCDCommand(0b00000111);    //if cursor inc and display shift

	///////////////////////////////////////////////////////////////////////////////////
	//Display on off ,Blink ,cursor command set 
	// ///////////////////////////////////////////////////////////////////////////////
	//"0 0 0 0 1 D C B "
	//D=1 dislay on, C=1 cursor on, B=1 blink on

    //XLCDCommand(0b00001111);    //display on cursor on blink on
	// XLCDCommand(0b00001111); //display on cursor on blink oFF
           
	_vXLCDreg=0;
	// end of initialization

	// welcome
	XLCD_Welcome();

    return;
}

/*********************************************************************
 * Function         : void XLCDCommand(unsigned char cmd)
 * PreCondition     : None
 * Input            : cmd - Command to be set to LCD.
 * Output           : None
 * Side Effects     : None
 * Overview         : None
 * Note             : None
 ********************************************************************/
void XLCDCommand(unsigned char cmd)
{

	XLCDDelay2ms();

	XLCD_RSPIN=0;
	XLCD_ENPIN=0;
	

    XLCD_DATAPORT &=0xF0;               //clear port
    XLCD_DATAPORT |=((cmd>>4)&0x0f);
    Pulse_E();
    
    XLCD_DATAPORT &= 0xF0;              //clear port
    XLCD_DATAPORT |= cmd&0x0f ;	        //shift left 4 times
    Pulse_E();

	XLCDDelay4ms();
	
    return;
}
/*********************************************************************
 * Function         :XLCDPut()
 * PreCondition     :None
 * Input            :cmd - Command to be set to LCD.
 * Output           :None
 * Side Effects     :None
 * Overview         :None
 * Note             :None
 ********************************************************************/
void XLCDPut(char data)
{
	XLCD_RSPIN=1;
	XLCD_ENPIN=0;

	 XLCD_DATAPORT &=0xF0;               //clear port
	 XLCD_DATAPORT |=((data>>4)&0x0f);
	 Pulse_E();                     // Clock the cmd in
	 
	 XLCD_DATAPORT &= 0xF0;              //clear port
	 XLCD_DATAPORT |= data&0x0f ;	    //shift left 4 times
	 Pulse_E();

	// another delay added by me,
	// idea copied from LiquidCrystal.cpp
	// // commands need > 37us to settle
	
	XLCDDelay2ms();

	 return;
}

// *** DELETED RW Functions ~ RW pin is grounded *** //


/*********************************************************************
 * Function         :XLCDPutRomString(rom char *string)
 * PreCondition     :None    
 * Input            :None
 * Output           :Displays string in Program memory
 * Side Effects     :None
 * Overview         :None
 * Note             :is lways blocking till the string is written fully
 ********************************************************************/

void XLCDPutRomString(rom char *string)
{
     while(*string)                         // Write data to LCD up to null
    {    
        XLCDPut(*string);                   // Write character to LCD
        string++;                           // Increment buffer
    }
    return;
}
/*********************************************************************
 * Function         :XLCDPutRomString(rom char *string)
 * PreCondition     :None    
 * Input            :None
 * Output           :Displays string in Program memory
 * Side Effects     :None
 * Overview         :None
 * Note             :is lways blocking till the string is written fully
 ********************************************************************/
void XLCDPutRamString(char *string)
{
    while(*string)                          // Write data to LCD up to null
    {                      
        XLCDPut(*string);                   // Write character to LCD
        string++;                           // Increment buffer
    }
    return;
}

unsigned char readEepromSpeed(int idx)
{
	if(idx == -1)
		return 0;
	
	// see notes in printSpeed
	idx = idx * 3 + 2;
	return eepromRead((unsigned char)idx);

}

void printSpeed2(int i)
{
	// 10,50 12,60 15,75 21,01 31,51
	// exceptions to get around itoa bug being called twice in this same function
	if(i==80){XLCDPut('1'); XLCDPut('0'); XLCDPut(','); XLCDPut('5'); XLCDPut('0'); return;}
	if(i==81){XLCDPut('1'); XLCDPut('2'); XLCDPut(','); XLCDPut('6'); XLCDPut('0'); return;}
	if(i==82){XLCDPut('1'); XLCDPut('5'); XLCDPut(','); XLCDPut('7'); XLCDPut('5'); return;}
	if(i==83){XLCDPut('2'); XLCDPut('1'); XLCDPut(','); XLCDPut('0'); XLCDPut('1'); return;}
	if(i==84){XLCDPut('3'); XLCDPut('1'); XLCDPut(','); XLCDPut('5'); XLCDPut('1'); return;}
	return;
}

void printSpeed(int i)
{
	char str[2];
	unsigned char idx = 0;

	if(i == -1 || i == 85) // special cases, -1 on the counter equivalent to 85 in the eeprom
	{
		XLCDL1home();
		XLCDPutRamString(line3);
		return;
	}

	// position the cursor, first line, 5th character
	XLCDCommand(0b10000100);
	
	if(i>= 80 && i<=84)
	{	printSpeed2(i);
		return;
	}

	/*
	// speed held in three values such
	integer part = 0
	decimal part = 51
	speed to be displayed on LCD = 00.51
	speed to be written to PIC16F84A = 249
	
	eepromWrite(0, 0 );
	eepromWrite(1, 51);
	eepromWrite(2, 249);
	*/	

	idx = (unsigned char)i * 3;
	i = (int)eepromRead(idx);
	itoa(i, str);

	// integer part
	if(i < 10)
	{
		// cm/min
		// XLCDPut('0');		
		// mm/seg
		XLCDPut(' ');		
		XLCDPut(str[0]);
	}
	else				
	{
		XLCDPut(str[1]);
		XLCDPut(str[0]);
	}
	
/*
	// START DEBUG //
	// 1. position cursor on first character, second line
	XLCDL2home();
	// 2. convert idx to a character array
	itoa((int)idx, str);
	// 3. print out characters ~ a maximum of 3
	XLCDPut(str[2]);
 	XLCDPut(str[1]);
	XLCDPut(str[0]);
	// reposition cursor, 1st line, 7th character
	XLCDCommand(0b10000110);
	// END DEBUG
*/

/*
	// deal with exceptions when reading from flaky eeprom
	if(idx==240){XLCDPut('5'); XLCDPut('0'); return;}
	if(idx==243){XLCDPut('6'); XLCDPut('0'); return;}
	if(idx==246){XLCDPut('7'); XLCDPut('5'); return;}
	if(idx==249){XLCDPut('0'); XLCDPut('1'); return;}
	if(idx==252)
	{
		// position cursor on the first character
		XLCDCommand(0b10000000);
		XLCDPut('Y'); 
		// position cursor on the eight character
		XLCDCommand(0b10000111);
		XLCDPut('5'); 
		XLCDPut('1'); 
		return;
	}
*/

	// print separator
	XLCDPut(',');		

	idx++;
	i = eepromRead(idx);
	itoa(i, str);
	// decimal part
	if(i < 10)
	{
		XLCDPut('0');		
		XLCDPut(str[0]);
	}
	else				
	{
		XLCDPut(str[1]);
		XLCDPut(str[0]);
	}

	return;
}

void eeprom_set_values(void)
{
	int i = eepromRead(1); // NOTE, these values need to be checked on a per dip coater basis, as torque, etc, will vary
	// cm/m
	//if(i == 25) // Array has been previously loaded, don't do it again.
	// mm/s
	if(i == 1)
		return;
/* FULL SPEED ARRAY
	eepromWrite(0, 0 );
	eepromWrite(1, 51);
	eepromWrite(2, 249);
	eepromWrite(3, 0 );
	eepromWrite(4, 55);
	eepromWrite(5, 231);
	eepromWrite(6, 0 );
	eepromWrite(7, 59);
	eepromWrite(8, 215);
	eepromWrite(9, 0 );
	eepromWrite(10, 60);
	eepromWrite(11, 212);
	eepromWrite(12, 0 );
	eepromWrite(13, 65);
	eepromWrite(14, 195);
	eepromWrite(15, 0 );
	eepromWrite(16, 69);
	eepromWrite(17, 184);
	eepromWrite(18, 0 );
	eepromWrite(19, 70);
	eepromWrite(20, 181);
	eepromWrite(21, 0 );
	eepromWrite(22, 75);
	eepromWrite(23, 169);
	eepromWrite(24, 0 );
	eepromWrite(25, 79);
	eepromWrite(26, 161);
	eepromWrite(27, 0 );
	eepromWrite(28, 80);
	eepromWrite(29, 159);
	eepromWrite(30, 0 );
	eepromWrite(31, 85);
	eepromWrite(32, 149);
	eepromWrite(33, 0 );
	eepromWrite(34, 89);
	eepromWrite(35, 143);
	eepromWrite(36, 0 );
	eepromWrite(37, 90);
	eepromWrite(38, 141);
	eepromWrite(39, 0 );
	eepromWrite(40, 95);
	eepromWrite(41, 134);
	eepromWrite(42, 0 );
	eepromWrite(43, 99);
	eepromWrite(44, 128);
	eepromWrite(45, 1 );
	eepromWrite(46, 0 );
	eepromWrite(47, 127);
	eepromWrite(48, 1 );
	eepromWrite(49, 5 );
	eepromWrite(50, 121);
	eepromWrite(51, 1 );
	eepromWrite(52, 10);
	eepromWrite(53, 115);
	eepromWrite(54, 1 );
	eepromWrite(55, 11);
	eepromWrite(56, 114);
	eepromWrite(57, 1 );
	eepromWrite(58, 13);
	eepromWrite(59, 112);
	eepromWrite(60, 1 );
	eepromWrite(61, 15);
	eepromWrite(62, 110);
	eepromWrite(63, 1 );
	eepromWrite(64, 18);
	eepromWrite(65, 108);
	eepromWrite(66, 1 );
	eepromWrite(67, 20);
	eepromWrite(68, 106);
	eepromWrite(69, 1 );
	eepromWrite(70, 22);
	eepromWrite(71, 104);
	eepromWrite(72, 1 );
	eepromWrite(73, 25);
	eepromWrite(74, 102);
	eepromWrite(75, 1 );
	eepromWrite(76, 27);
	eepromWrite(77, 100);
	eepromWrite(78, 1 );
	eepromWrite(79, 30);
	eepromWrite(80, 98);
	eepromWrite(81, 1 );
	eepromWrite(82, 32);
	eepromWrite(83, 96);
	eepromWrite(84, 1 );
	eepromWrite(85, 35);
	eepromWrite(86, 94);
	eepromWrite(87, 1 );
	eepromWrite(88, 38);
	eepromWrite(89, 92);
	eepromWrite(90, 1 );
	eepromWrite(91, 41);
	eepromWrite(92, 90);
	eepromWrite(93, 1 );
	eepromWrite(94, 44);
	eepromWrite(95, 88);
	eepromWrite(96, 1 );
	eepromWrite(97, 48);
	eepromWrite(98, 86);
	eepromWrite(99, 1 );
	eepromWrite(100, 51);
	eepromWrite(101, 84);
	eepromWrite(102, 1 );
	eepromWrite(103, 55);
	eepromWrite(104, 82);
	eepromWrite(105, 1 );
	eepromWrite(106, 59);
	eepromWrite(107, 80);
	eepromWrite(108, 1 );
	eepromWrite(109, 63);
	eepromWrite(110, 78);
	eepromWrite(111, 1 );
	eepromWrite(112, 67);
	eepromWrite(113, 76);
	eepromWrite(114, 1 );
	eepromWrite(115, 72);
	eepromWrite(116, 74);
	eepromWrite(117, 1 );
	eepromWrite(118, 76);
	eepromWrite(119, 72);
	eepromWrite(120, 1 );
	eepromWrite(121, 81);
	eepromWrite(122, 70);
	eepromWrite(123, 1 );
	eepromWrite(124, 87);
	eepromWrite(125, 68);
	eepromWrite(126, 1 );
	eepromWrite(127, 92);
	eepromWrite(128, 66);
	eepromWrite(129, 1 );
	eepromWrite(130, 98);
	eepromWrite(131, 64);
	eepromWrite(132, 2 );
	eepromWrite(133, 5 );
	eepromWrite(134, 62);
	eepromWrite(135, 2 );
	eepromWrite(136, 12);
	eepromWrite(137, 60);
	eepromWrite(138, 2 );
	eepromWrite(139, 19);
	eepromWrite(140, 58);
	eepromWrite(141, 2 );
	eepromWrite(142, 27);
	eepromWrite(143, 56);
	eepromWrite(144, 2 );
	eepromWrite(145, 35);
	eepromWrite(146, 54);
	eepromWrite(147, 2 );
	eepromWrite(148, 44);
	eepromWrite(149, 52);
	eepromWrite(150, 2 );
	eepromWrite(151, 54);
	eepromWrite(152, 50);
	eepromWrite(153, 2 );
	eepromWrite(154, 65);
	eepromWrite(155, 48);
	eepromWrite(156, 2 );
	eepromWrite(157, 76);
	eepromWrite(158, 46);
	eepromWrite(159, 2 );
	eepromWrite(160, 89);
	eepromWrite(161, 44);
	eepromWrite(162, 3 );
	eepromWrite(163, 2 );
	eepromWrite(164, 42);
	eepromWrite(165, 3 );
	eepromWrite(166, 18);
	eepromWrite(167, 40);
	eepromWrite(168, 3 );
	eepromWrite(169, 34);
	eepromWrite(170, 38);
	eepromWrite(171, 3 );
	eepromWrite(172, 53);
	eepromWrite(173, 36);
	eepromWrite(174, 3 );
	eepromWrite(175, 74);
	eepromWrite(176, 34);
	eepromWrite(177, 3 );
	eepromWrite(178, 97);
	eepromWrite(179, 32);
	eepromWrite(180, 4 );
	eepromWrite(181, 23);
	eepromWrite(182, 30);
	eepromWrite(183, 4 );
	eepromWrite(184, 54);
	eepromWrite(185, 28);
	eepromWrite(186, 4 );
	eepromWrite(187, 89);
	eepromWrite(188, 26);
	eepromWrite(189, 5 );
	eepromWrite(190, 29);
	eepromWrite(191, 24);
	eepromWrite(192, 5 );
	eepromWrite(193, 77);
	eepromWrite(194, 22);
	eepromWrite(195, 6 );
	eepromWrite(196, 5 );
	eepromWrite(197, 21);
	eepromWrite(198, 6 );
	eepromWrite(199, 35);
	eepromWrite(200, 20);
	eepromWrite(201, 6 );
	eepromWrite(202, 68);
	eepromWrite(203, 19);
	eepromWrite(204, 7 );
	eepromWrite(205, 6 );
	eepromWrite(206, 18);
	eepromWrite(207, 7 );
	eepromWrite(208, 47);
	eepromWrite(209, 17);
	eepromWrite(210, 7 );
	eepromWrite(211, 94);
	eepromWrite(212, 16);
	eepromWrite(213, 8 );
	eepromWrite(214, 47);
	eepromWrite(215, 15);
	eepromWrite(216, 9 );
	eepromWrite(217, 7 );
	eepromWrite(218, 14);
	eepromWrite(219, 9 );
	eepromWrite(220, 77);
	eepromWrite(221, 13);
	eepromWrite(222, 10);
	eepromWrite(223, 58);
	eepromWrite(224, 12);
	eepromWrite(225, 11);
	eepromWrite(226, 55);
	eepromWrite(227, 11);
	eepromWrite(228, 12);
	eepromWrite(229, 70);
	eepromWrite(230, 10);
	eepromWrite(231, 14);
	eepromWrite(232, 11);
	eepromWrite(233, 9);
	eepromWrite(234, 15);
	eepromWrite(235, 88);
	eepromWrite(236, 8);
	eepromWrite(237, 18);
	eepromWrite(238, 14);
	eepromWrite(239, 7);
	eepromWrite(240, 21);
	eepromWrite(241, 17);
	eepromWrite(242, 6);
	eepromWrite(243, 25);
	eepromWrite(244, 40);
	eepromWrite(245, 5);
	eepromWrite(246, 31);
	eepromWrite(247, 75);
	eepromWrite(248, 4);
	eepromWrite(249, 42);
	eepromWrite(250, 34);
	eepromWrite(251, 3);
	eepromWrite(252, 63);
	eepromWrite(253, 51);
	eepromWrite(254, 2);
*/
// HALF SPEED ARRAY
/*  55 is repeated, use a different speed

id          SpeedCPMTwoDecDiv2                      int_part dec_part
----------- --------------------------------------- -------- --------
117         0.54                                    00       54

	eepromWrite(51, 0 );
	eepromWrite(52, 55);	eepromWrite(53, 115);
*/
	// cm/m
/*
	// grafted in this new value:
	eepromWrite((unsigned char)0, (unsigned char)0);
	eepromWrite((unsigned char)1, (unsigned char)25);
	eepromWrite((unsigned char)2, (unsigned char)249);
	eepromWrite((unsigned char)3, (unsigned char)0);
	eepromWrite((unsigned char)4, (unsigned char)27);
	eepromWrite((unsigned char)5, (unsigned char)231);
	eepromWrite((unsigned char)6, (unsigned char)0);
	eepromWrite((unsigned char)7, (unsigned char)29);
	eepromWrite((unsigned char)8, (unsigned char)215);
	eepromWrite((unsigned char)9, (unsigned char)0);
	eepromWrite((unsigned char)10, (unsigned char)30);
	eepromWrite((unsigned char)11, (unsigned char)212);
	eepromWrite((unsigned char)12, (unsigned char)0);
	eepromWrite((unsigned char)13, (unsigned char)32);
	eepromWrite((unsigned char)14, (unsigned char)195);
	eepromWrite((unsigned char)15, (unsigned char)0);
	eepromWrite((unsigned char)16, (unsigned char)34);
	eepromWrite((unsigned char)17, (unsigned char)184);
	eepromWrite((unsigned char)18, (unsigned char)0);
	eepromWrite((unsigned char)19, (unsigned char)35);
	eepromWrite((unsigned char)20, (unsigned char)181);
	eepromWrite((unsigned char)21, (unsigned char)0);
	eepromWrite((unsigned char)22, (unsigned char)37);
	eepromWrite((unsigned char)23, (unsigned char)169);
	eepromWrite((unsigned char)24, (unsigned char)0);
	eepromWrite((unsigned char)25, (unsigned char)39);
	eepromWrite((unsigned char)26, (unsigned char)161);
	eepromWrite((unsigned char)27, (unsigned char)0);
	eepromWrite((unsigned char)28, (unsigned char)40);
	eepromWrite((unsigned char)29, (unsigned char)159);
	eepromWrite((unsigned char)30, (unsigned char)0);
	eepromWrite((unsigned char)31, (unsigned char)42);
	eepromWrite((unsigned char)32, (unsigned char)149);
	eepromWrite((unsigned char)33, (unsigned char)0);
	eepromWrite((unsigned char)34, (unsigned char)44);
	eepromWrite((unsigned char)35, (unsigned char)143);
	eepromWrite((unsigned char)36, (unsigned char)0);
	eepromWrite((unsigned char)37, (unsigned char)45);
	eepromWrite((unsigned char)38, (unsigned char)141);
	eepromWrite((unsigned char)39, (unsigned char)0);
	eepromWrite((unsigned char)40, (unsigned char)47);
	eepromWrite((unsigned char)41, (unsigned char)134);
	eepromWrite((unsigned char)42, (unsigned char)0);
	eepromWrite((unsigned char)43, (unsigned char)49);
	eepromWrite((unsigned char)44, (unsigned char)128);
	eepromWrite((unsigned char)45, (unsigned char)0);
	eepromWrite((unsigned char)46, (unsigned char)50);
	eepromWrite((unsigned char)47, (unsigned char)127);
	eepromWrite((unsigned char)48, (unsigned char)0);
	eepromWrite((unsigned char)49, (unsigned char)52);
	eepromWrite((unsigned char)50, (unsigned char)121);
	eepromWrite((unsigned char)51, (unsigned char)0);
	eepromWrite((unsigned char)52, (unsigned char)54);
	eepromWrite((unsigned char)53, (unsigned char)117);
	eepromWrite((unsigned char)54, (unsigned char)0);
	eepromWrite((unsigned char)55, (unsigned char)55);
	eepromWrite((unsigned char)56, (unsigned char)114);
	eepromWrite((unsigned char)57, (unsigned char)0);
	eepromWrite((unsigned char)58, (unsigned char)56);
	eepromWrite((unsigned char)59, (unsigned char)112);
	eepromWrite((unsigned char)60, (unsigned char)0);
	eepromWrite((unsigned char)61, (unsigned char)57);
	eepromWrite((unsigned char)62, (unsigned char)110);
	eepromWrite((unsigned char)63, (unsigned char)0);
	eepromWrite((unsigned char)64, (unsigned char)59);
	eepromWrite((unsigned char)65, (unsigned char)108);
	eepromWrite((unsigned char)66, (unsigned char)0);
	eepromWrite((unsigned char)67, (unsigned char)60);
	eepromWrite((unsigned char)68, (unsigned char)106);
	eepromWrite((unsigned char)69, (unsigned char)0);
	eepromWrite((unsigned char)70, (unsigned char)61);
	eepromWrite((unsigned char)71, (unsigned char)104);
	eepromWrite((unsigned char)72, (unsigned char)0);
	eepromWrite((unsigned char)73, (unsigned char)62);
	eepromWrite((unsigned char)74, (unsigned char)102);
	eepromWrite((unsigned char)75, (unsigned char)0);
	eepromWrite((unsigned char)76, (unsigned char)63);
	eepromWrite((unsigned char)77, (unsigned char)100);
	eepromWrite((unsigned char)78, (unsigned char)0);
	eepromWrite((unsigned char)79, (unsigned char)64);
	eepromWrite((unsigned char)80, (unsigned char)99);
	eepromWrite((unsigned char)81, (unsigned char)0);
	eepromWrite((unsigned char)82, (unsigned char)65);
	eepromWrite((unsigned char)83, (unsigned char)96);
	eepromWrite((unsigned char)84, (unsigned char)0);
	eepromWrite((unsigned char)85, (unsigned char)67);
	eepromWrite((unsigned char)86, (unsigned char)94);
	eepromWrite((unsigned char)87, (unsigned char)0);
	eepromWrite((unsigned char)88, (unsigned char)68);
	eepromWrite((unsigned char)89, (unsigned char)92);
	eepromWrite((unsigned char)90, (unsigned char)0);
	eepromWrite((unsigned char)91, (unsigned char)70);
	eepromWrite((unsigned char)92, (unsigned char)90);
	eepromWrite((unsigned char)93, (unsigned char)0);
	eepromWrite((unsigned char)94, (unsigned char)71);
	eepromWrite((unsigned char)95, (unsigned char)88);
	eepromWrite((unsigned char)96, (unsigned char)0);
	eepromWrite((unsigned char)97, (unsigned char)73);
	eepromWrite((unsigned char)98, (unsigned char)86);
	eepromWrite((unsigned char)99, (unsigned char)0);
	eepromWrite((unsigned char)100, (unsigned char)75);
	eepromWrite((unsigned char)101, (unsigned char)84);
	eepromWrite((unsigned char)102, (unsigned char)0);
	eepromWrite((unsigned char)103, (unsigned char)77);
	eepromWrite((unsigned char)104, (unsigned char)82);
	eepromWrite((unsigned char)105, (unsigned char)0);
	eepromWrite((unsigned char)106, (unsigned char)79);
	eepromWrite((unsigned char)107, (unsigned char)80);
	eepromWrite((unsigned char)108, (unsigned char)0);
	eepromWrite((unsigned char)109, (unsigned char)81);
	eepromWrite((unsigned char)110, (unsigned char)78);
	eepromWrite((unsigned char)111, (unsigned char)0);
	eepromWrite((unsigned char)112, (unsigned char)83);
	eepromWrite((unsigned char)113, (unsigned char)76);
	eepromWrite((unsigned char)114, (unsigned char)0);
	eepromWrite((unsigned char)115, (unsigned char)85);
	eepromWrite((unsigned char)116, (unsigned char)74);
	eepromWrite((unsigned char)117, (unsigned char)0);
	eepromWrite((unsigned char)118, (unsigned char)87);
	eepromWrite((unsigned char)119, (unsigned char)72);
	eepromWrite((unsigned char)120, (unsigned char)0);
	eepromWrite((unsigned char)121, (unsigned char)90);
	eepromWrite((unsigned char)122, (unsigned char)70);
	eepromWrite((unsigned char)123, (unsigned char)0);
	eepromWrite((unsigned char)124, (unsigned char)93);
	eepromWrite((unsigned char)125, (unsigned char)68);
	eepromWrite((unsigned char)126, (unsigned char)0);
	eepromWrite((unsigned char)127, (unsigned char)95);
	eepromWrite((unsigned char)128, (unsigned char)66);
	eepromWrite((unsigned char)129, (unsigned char)0);
	eepromWrite((unsigned char)130, (unsigned char)98);
	eepromWrite((unsigned char)131, (unsigned char)64);
	eepromWrite((unsigned char)132, (unsigned char)1);
	eepromWrite((unsigned char)133, (unsigned char)2);
	eepromWrite((unsigned char)134, (unsigned char)62);
	eepromWrite((unsigned char)135, (unsigned char)1);
	eepromWrite((unsigned char)136, (unsigned char)5);
	eepromWrite((unsigned char)137, (unsigned char)60);
	eepromWrite((unsigned char)138, (unsigned char)1);
	eepromWrite((unsigned char)139, (unsigned char)9);
	eepromWrite((unsigned char)140, (unsigned char)58);
	eepromWrite((unsigned char)141, (unsigned char)1);
	eepromWrite((unsigned char)142, (unsigned char)13);
	eepromWrite((unsigned char)143, (unsigned char)56);
	eepromWrite((unsigned char)144, (unsigned char)1);
	eepromWrite((unsigned char)145, (unsigned char)17);
	eepromWrite((unsigned char)146, (unsigned char)54);
	eepromWrite((unsigned char)147, (unsigned char)1);
	eepromWrite((unsigned char)148, (unsigned char)21);
	eepromWrite((unsigned char)149, (unsigned char)52);
	eepromWrite((unsigned char)150, (unsigned char)1);
	eepromWrite((unsigned char)151, (unsigned char)26);
	eepromWrite((unsigned char)152, (unsigned char)50);
	eepromWrite((unsigned char)153, (unsigned char)1);
	eepromWrite((unsigned char)154, (unsigned char)31);
	eepromWrite((unsigned char)155, (unsigned char)48);
	eepromWrite((unsigned char)156, (unsigned char)1);
	eepromWrite((unsigned char)157, (unsigned char)37);
	eepromWrite((unsigned char)158, (unsigned char)46);
	eepromWrite((unsigned char)159, (unsigned char)1);
	eepromWrite((unsigned char)160, (unsigned char)43);
	eepromWrite((unsigned char)161, (unsigned char)44);
	eepromWrite((unsigned char)162, (unsigned char)1);
	eepromWrite((unsigned char)163, (unsigned char)50);
	eepromWrite((unsigned char)164, (unsigned char)42);
	eepromWrite((unsigned char)165, (unsigned char)1);
	eepromWrite((unsigned char)166, (unsigned char)58);
	eepromWrite((unsigned char)167, (unsigned char)40);
	eepromWrite((unsigned char)168, (unsigned char)1);
	eepromWrite((unsigned char)169, (unsigned char)66);
	eepromWrite((unsigned char)170, (unsigned char)38);
	eepromWrite((unsigned char)171, (unsigned char)1);
	eepromWrite((unsigned char)172, (unsigned char)75);
	eepromWrite((unsigned char)173, (unsigned char)36);
	eepromWrite((unsigned char)174, (unsigned char)1);
	eepromWrite((unsigned char)175, (unsigned char)86);
	eepromWrite((unsigned char)176, (unsigned char)34);
	eepromWrite((unsigned char)177, (unsigned char)1);
	eepromWrite((unsigned char)178, (unsigned char)97);
	eepromWrite((unsigned char)179, (unsigned char)32);
	eepromWrite((unsigned char)180, (unsigned char)2);
	eepromWrite((unsigned char)181, (unsigned char)10);
	eepromWrite((unsigned char)182, (unsigned char)30);
	eepromWrite((unsigned char)183, (unsigned char)2);
	eepromWrite((unsigned char)184, (unsigned char)25);
	eepromWrite((unsigned char)185, (unsigned char)28);
	eepromWrite((unsigned char)186, (unsigned char)2);
	eepromWrite((unsigned char)187, (unsigned char)43);
	eepromWrite((unsigned char)188, (unsigned char)26);
	eepromWrite((unsigned char)189, (unsigned char)2);
	eepromWrite((unsigned char)190, (unsigned char)62);
	eepromWrite((unsigned char)191, (unsigned char)24);
	eepromWrite((unsigned char)192, (unsigned char)2);
	eepromWrite((unsigned char)193, (unsigned char)86);
	eepromWrite((unsigned char)194, (unsigned char)22);
	eepromWrite((unsigned char)195, (unsigned char)3);
	eepromWrite((unsigned char)196, (unsigned char)0);
	eepromWrite((unsigned char)197, (unsigned char)21);
	eepromWrite((unsigned char)198, (unsigned char)3);
	eepromWrite((unsigned char)199, (unsigned char)15);
	eepromWrite((unsigned char)200, (unsigned char)20);
	eepromWrite((unsigned char)201, (unsigned char)3);
	eepromWrite((unsigned char)202, (unsigned char)31);
	eepromWrite((unsigned char)203, (unsigned char)19);
	eepromWrite((unsigned char)204, (unsigned char)3);
	eepromWrite((unsigned char)205, (unsigned char)50);
	eepromWrite((unsigned char)206, (unsigned char)18);
	eepromWrite((unsigned char)207, (unsigned char)3);
	eepromWrite((unsigned char)208, (unsigned char)71);
	eepromWrite((unsigned char)209, (unsigned char)17);
	eepromWrite((unsigned char)210, (unsigned char)3);
	eepromWrite((unsigned char)211, (unsigned char)94);
	eepromWrite((unsigned char)212, (unsigned char)16);
	eepromWrite((unsigned char)213, (unsigned char)4);
	eepromWrite((unsigned char)214, (unsigned char)20);
	eepromWrite((unsigned char)215, (unsigned char)15);
	eepromWrite((unsigned char)216, (unsigned char)4);
	eepromWrite((unsigned char)217, (unsigned char)50);
	eepromWrite((unsigned char)218, (unsigned char)14);
	eepromWrite((unsigned char)219, (unsigned char)4);
	eepromWrite((unsigned char)220, (unsigned char)85);
	eepromWrite((unsigned char)221, (unsigned char)13);
	eepromWrite((unsigned char)222, (unsigned char)5);
	eepromWrite((unsigned char)223, (unsigned char)25);
	eepromWrite((unsigned char)224, (unsigned char)12);
	eepromWrite((unsigned char)225, (unsigned char)5);
	eepromWrite((unsigned char)226, (unsigned char)73);
	eepromWrite((unsigned char)227, (unsigned char)11);
	eepromWrite((unsigned char)228, (unsigned char)6);
	eepromWrite((unsigned char)229, (unsigned char)30);
	eepromWrite((unsigned char)230, (unsigned char)10);
	eepromWrite((unsigned char)231, (unsigned char)7);
	eepromWrite((unsigned char)232, (unsigned char)0);
	eepromWrite((unsigned char)233, (unsigned char)9);
	eepromWrite((unsigned char)234, (unsigned char)7);
	eepromWrite((unsigned char)235, (unsigned char)88);
	eepromWrite((unsigned char)236, (unsigned char)8);
	eepromWrite((unsigned char)237, (unsigned char)9);
	eepromWrite((unsigned char)238, (unsigned char)0);
	eepromWrite((unsigned char)239, (unsigned char)7);
	eepromWrite((unsigned char)240, (unsigned char)10);
	eepromWrite((unsigned char)241, (unsigned char)50); // HERE 
	eepromWrite((unsigned char)242, (unsigned char)6);
	eepromWrite((unsigned char)243, (unsigned char)12);
	eepromWrite((unsigned char)244, (unsigned char)60); // HERE 
	eepromWrite((unsigned char)245, (unsigned char)5);
	eepromWrite((unsigned char)246, (unsigned char)15); 
	eepromWrite((unsigned char)247, (unsigned char)75); // HERE
	eepromWrite((unsigned char)248, (unsigned char)4);
	eepromWrite((unsigned char)249, (unsigned char)21);
	eepromWrite((unsigned char)250, (unsigned char)1); // HERE 
	eepromWrite((unsigned char)251, (unsigned char)3); 
	eepromWrite((unsigned char)252, (unsigned char)31);
	eepromWrite((unsigned char)253, (unsigned char)51); // HERE  
	eepromWrite((unsigned char)254, (unsigned char)2);
*/

	eepromWrite(0, 0);	eepromWrite(1, 1 );	eepromWrite(2, 255);
	eepromWrite(3, 0);	eepromWrite(4, 2 );	eepromWrite(5, 133);
	eepromWrite(6, 0);	eepromWrite(7, 3 );	eepromWrite(8, 89);
	eepromWrite(9, 0);	eepromWrite(10, 4 );	eepromWrite(11, 67);
	eepromWrite(12, 0);	eepromWrite(13, 5 );	eepromWrite(14, 54);
	eepromWrite(15, 0);	eepromWrite(16, 6 );	eepromWrite(17, 45);
	eepromWrite(18, 0);	eepromWrite(19, 7 );	eepromWrite(20, 38);
	eepromWrite(21, 0);	eepromWrite(22, 8 );	eepromWrite(23, 34);
	eepromWrite(24, 0);	eepromWrite(25, 9 );	eepromWrite(26, 30);
	eepromWrite(27, 0);	eepromWrite(28, 10);	eepromWrite(29, 27);
	eepromWrite(30, 0);	eepromWrite(31, 11);	eepromWrite(32, 25);
	eepromWrite(33, 0);	eepromWrite(34, 12);	eepromWrite(35, 23);
	eepromWrite(36, 0);	eepromWrite(37, 13);	eepromWrite(38, 21);
	eepromWrite(39, 0);	eepromWrite(40, 14);	eepromWrite(41, 19);
	eepromWrite(42, 0);	eepromWrite(43, 15);	eepromWrite(44, 18);
	eepromWrite(45, 0);	eepromWrite(46, 16);	eepromWrite(47, 17);
	eepromWrite(48, 0);	eepromWrite(49, 17);	eepromWrite(50, 16);
	eepromWrite(51, 0);	eepromWrite(52, 18);	eepromWrite(53, 15);
	eepromWrite(54, 0);	eepromWrite(55, 20);	eepromWrite(56, 14);
	eepromWrite(57, 0);	eepromWrite(58, 21);	eepromWrite(59, 13);
	eepromWrite(60, 0);	eepromWrite(61, 23);	eepromWrite(62, 12);
	eepromWrite(63, 0);	eepromWrite(64, 25);	eepromWrite(65, 11);
	eepromWrite(66, 0);	eepromWrite(67, 28);	eepromWrite(68, 10);
	eepromWrite(69, 0);	eepromWrite(70, 31);	eepromWrite(71, 9);
	eepromWrite(72, 0);	eepromWrite(73, 35);	eepromWrite(74, 8);
	eepromWrite(75, 0);	eepromWrite(76, 41);	eepromWrite(77, 7);
	eepromWrite(78, 0);	eepromWrite(79, 48);	eepromWrite(80, 6);
	eepromWrite(81, 0);	eepromWrite(82, 59);	eepromWrite(83, 5);
	eepromWrite(84, 0);	eepromWrite(85, 76);	eepromWrite(86, 4);
	eepromWrite(87, 1);	eepromWrite(88, 6 );	eepromWrite(89, 3);
	eepromWrite(90, 1);	eepromWrite(91, 77);	eepromWrite(92, 2);
	eepromWrite(93, 5);	eepromWrite(94, 31);	eepromWrite(95, 1);

	// store the last selected speed index, 85 == -1 ~ 0 cm/min  
	// to be able to recall the value on power up
	// cm/min
	// eepromWrite((unsigned char)255, (unsigned char)85);
	// mm/seg
	eepromWrite((unsigned char)96, (unsigned char)32);
	return;
}

void eepromWrite(unsigned char addr, unsigned char data) {
	INTCONbits.GIE = 0; // Disable interupts
	EECON1bits.EEPGD = 0; // Select the EEPROM memory
	EECON1bits.CFGS = 0; // Access the EEPROM memory
	EECON1bits.WREN = 1; // Enable writing
	EEADR = addr; // Set the address
	EEDATA = data; // Set the data
	EECON2 = 0x55; // Write initiate sequence
	EECON2 = 0xaa; // Write initiate sequence
	EECON1bits.WR = 1; // Start writing
	while (!PIR2bits.EEIF)
	; // Wait for write to finish
	PIR2bits.EEIF = 0; // Clear EEIF bit
	INTCONbits.GIE = 1; // Enable interupts
}

unsigned char eepromRead(unsigned char addr) {
	EECON1bits.EEPGD = 0; // Select the EEPROM memory
	EECON1bits.CFGS = 0; // Access the EEPROM memory
	EEADR = addr; // Set the address
	EECON1bits.RD = 1; // Start reading
	return EEDATA; // Return the read value
}

 /* itoa:  convert n to characters in s */
 void itoa(int n, char s[])
 {
     int i;
     i = 0;
     do {       /* generate digits in reverse order */
         s[i++] = n % 10 + '0';   /* get next digit */
     } while ((n /= 10) > 0);     /* delete it */
     s[i] = '\0';
 }

// timer function 

void change_speed(int increment)
{
   iSpeed += increment;
   iSpeed=(iSpeed>iMaxSpeed?iMaxSpeed:iSpeed); 
   iSpeed=(iSpeed<iMinSpeed?iMinSpeed:iSpeed);  
	printSpeed(iSpeed);
} 

void createChar(unsigned int location, unsigned int charmap[])
{
	int i;
	location &= 0x7;
	XLCDCommand(LCD_SETCGRAMADDR | (location << 3));
  	for(i=0; i<8; i++) 
    	XLCDPut(charmap[i]);		
}

void XLCDPrintArrows(char ARROW)
{
	int i;
	// position the lcd
    XLCDCommand(0b11000110);
	for(i = 0; i < 4; i++)
		XLCDPut(ARROW);
}

void XLCDPrintMotionCharacters(char bMotion)
{
    XLCDCommand(0b11000011);
	XLCDPut(bMotion);
   	XLCDCommand(0b11001100);
	XLCDPut(bMotion);
}

void XLCD_Welcome(void)
{
	// create special characters
	// no play with zero, so starting at 1
/*
	createChar(0, backSlash);
	createChar(1, upArrow);
	createChar(2, downArrow);
*/
	// int iSpeed;

	createChar(BACK_SLASH, backSlash);
	createChar(UP_ARROW, upArrow);
	createChar(DOWN_ARROW, downArrow);

	XLCDL1home();
	XLCDPutRamString(line1);
	XLCDL2home();
	XLCDPutRamString(line2);
	// delay 2 seconds
	// clear and add standard text
	XLCDDelay2s();
	XLCDL1home();
	XLCDPutRamString(line3);

	// XLCDCommand(0b10000100);

	// Clear 2nd line
	XLCDL2home();
	XLCDPutRamString(line4);
	
	// write motion characters
	XLCDPrintMotionCharacters(STOP);

	// write arrows
	XLCDPrintArrows(DOWN_ARROW);

	// write values to eeprom for LCD 
	eeprom_set_values();

	iSpeed = speedInit();
	printSpeed(iSpeed);
}

// TODO - get rid of magic numbers

int speedInit(void)
{
	// cm/min
	// read speed stored in element 255 and initialise speed
	//iSpeed = eepromRead(255);
	//return (iSpeed == 85 ? -1 : iSpeed); // 85 is the code for zero.
	// mm/set
	// read speed stored in element 96 and initialise speed
	iSpeed = eepromRead(96);
	return (iSpeed == 32 ? -1 : iSpeed); // 32 is the code for zero.
}

void saveSpeed(void)
{
	char bSpeed;
	// cm/min
	//bSpeed = (iSpeed == -1 ? 85 : iSpeed);
	//eepromWrite(255, bSpeed);
	// mm/seg
	bSpeed = (iSpeed == -1 ? 32 : iSpeed);
	eepromWrite(96, bSpeed);
	return;
}

void check_pins(void)
{
	// on off
	if(XLCD_ONOFF_PIN == (unsigned char)HIGH && bChangedOnOffState == 0)
	{
		bOn=(bOn == 1?0:1); // invert state
		XLCD_LED_PIN = bOn;
		bChangedOnOffState = 1;
	} 
	
	if(XLCD_ONOFF_PIN == (unsigned char)LOW && bChangedOnOffState == 1) // if the pin has gone low AND state has changed, act
	{
		bChangedOnOffState = 0;
		// save the speed, in case the unit is switched off
	    if(bOn==0)
		{	saveSpeed();
			// write motion characters
			XLCDPrintMotionCharacters(STOP);
		}
		else
			XLCDPrintMotionCharacters(START);
	} 	

 	// up
	if(XLCD_UP_PIN == (unsigned char)HIGH && bChangedUpState == 0)
	{
	   bDown = 0;
	   XLCDPrintArrows(UP_ARROW);	  
	   bChangedUpState = 1;
	} 
	
	if(XLCD_UP_PIN == (unsigned char)LOW && bChangedUpState == 1) // if the pin has gone low AND state has changed, act
	   bChangedUpState = 0;
	
	// going down
	if(XLCD_DOWN_PIN == (unsigned char)HIGH && bChangedDownState == 0)
	{
	   bDown = 1;
	   XLCDPrintArrows(DOWN_ARROW);
	   bChangedDownState = 1;
	}

	if(XLCD_DOWN_PIN == (unsigned char)LOW && bChangedDownState == 1)
	   bChangedDownState = 0;

  // faster and slower
  if(XLCD_FASTER_PIN == (unsigned char)HIGH && bChangedFasterState == 0)
  {
    //Serial.println("***faster***");
    bChangedFasterState = 1;
    // set timer for holding "faster pin"
    lCurrentCounter = 0;
  }

  if(XLCD_FASTER_PIN == (unsigned char)HIGH && bChangedFasterState == 1)
  {
    lCurrentCounter++;
    if(lCurrentCounter > CONTINUOUS_CHANGE_INTERVAL) // increase count
    { 
		change_speed(1*(two_exp(iIncreasedExp)));  
	   lCurrentCounter = 0;	
		iChange++;
		checkIntervals();
	}
  }
 
  if(XLCD_FASTER_PIN == (unsigned char)LOW && bChangedFasterState == 1) // if the pin has gone low AND state has changed, act
  { 
      change_speed(1);
      bChangedFasterState = 0;
	  lCurrentCounter = 0;	

	  // reset counters
		resetIntervals();
  }
  
  if(XLCD_SLOWER_PIN == (unsigned char)HIGH && bChangedSlowerState == 0)
  {
    bChangedSlowerState = 1;
    lCurrentCounter = 0;
  } 

  if(XLCD_SLOWER_PIN == (unsigned char)HIGH && bChangedSlowerState == 1)
  {
    lCurrentCounter++;
    if(lCurrentCounter > CONTINUOUS_CHANGE_INTERVAL) // increase count
    {  	// exponentiation does not seem to work with the C18 compiler, so implemented a homebrew solution
		// change_speed(-1*(two_exp(iIncreasedExp)));  
	   change_speed(-1*(two_exp(iIncreasedExp)));    
	   lCurrentCounter = 0;	 
	   iChange++;
	   checkIntervals();
    }
  }

  if(XLCD_SLOWER_PIN == (unsigned char)LOW && bChangedSlowerState == 1) // if the pin has gone low AND state has changed, act
  {
     change_speed(-1);
     bChangedSlowerState = 0;
	  // reset counters
		resetIntervals();
  }  

}

void checkIntervals(void)
{
	if(iChange==iMaxChanges) // the button has been pressed for too long, do something.
	{
		if(iCCI > MIN_CCI) // start by changing waiting intervals
			iCCI = iCCI - CCI_STEP;
		else // then use exponentiation to change speed
			iIncreasedExp = (iIncreasedExp < iMaxIncreasedExp ? iIncreasedExp + 1 : iMaxIncreasedExp);	
		// whatever happens, reset iChange
		iChange = 0;		
	}
	return;
}

void resetIntervals(void)
{
	iChange = 0;
	iCCI = CONTINUOUS_CHANGE_INTERVAL;
	iIncreasedExp = 0;
	return;
}

unsigned char get_direction(void)
{
	return bDown;
}

unsigned char get_speed(unsigned char startReached, unsigned char endReached)
{
	// 1. If the unit is turned on, there are special cases when it will not run
	if(bOn == 1)
	{
		// 1.1 If the end has been reached and the arrow is pointing downwards, speed equals zero
		if(endReached == 1 && bDown == 1)
			return 0;
		// 1.2 If the start has been reached, and the arrow is pointing upwards, speed equals zero
		if(startReached == 1 && bDown == 0)
			return 0;
	}
	// 2. If the unit is turned off, speed is also zero, even if display shows speed greater than zero
	if(bOn == 0)
		return 0;
	
	// 3. Return the speed stored in eeprom
	return readEepromSpeed(iSpeed);

}

int two_exp(int iIncreasedExp)
{
	// homebrew exp function given the lack herein (C18 compiler)
	int i;
	int r = 1;
	if(iIncreasedExp == 0)
		return 1;
	for(i = 1; i <= iIncreasedExp; i++)
		r *= 2;
	return r;
}
