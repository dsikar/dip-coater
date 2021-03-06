/*********************************************************************
 *
 *                  External LCD access routines defs
 *
 *********************************************************************
 * FileName:        XLCD.h
 * Dependencies:    compiler.h
 * Processor:       PIC18
 * Complier:        MCC18 v1.00.50 or higher
 *                  HITECH PICC-18 V8.10PL1 or higher
 * Company:         Microchip Technology, Inc.
 *
 * Software License Agreement 
 *
 * The software supplied herewith by Microchip Technology Incorporated
 * (the �Company�) for its PICmicro� Microcontroller is intended and
 * supplied to you, the Company�s customer, for use solely and
 * exclusively on Microchip PICmicro Microcontroller products. The
 * software is owned by the Company and/or its supplier, and is
 * protected under applicable copyright laws. All rights are reserved.
 * Any use in violation of the foregoing restrictions may subject the
 * user to criminal sanctions under applicable laws, as well as to
 * civil liability for the breach of the terms and conditions of this
 * license.
 *
 * THIS SOFTWARE IS PROVIDED IN AN �AS IS� CONDITION. NO WARRANTIES,
 * WHETHER EXPRESS, IMPLIED OR STATUTORY, INCLUDING, BUT NOT LIMITED
 * TO, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE APPLY TO THIS SOFTWARE. THE COMPANY SHALL NOT,
 * IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL OR
 * CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
 *
 * Author               Date    Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Naveen Raj     6/9/03  Original        (Rev 1.0)
 ********************************************************************/
#ifndef __XLCD_H
#define __XLCD_H
// #define AddFile ///ADD_PROC_INC_FILE
#include "p18cxxx.h"
// #include "XLCD.Def"
// #define    CLOCK_FREQ    .20000000

/* DATA_PORT defines the port to which the LCD data lines are connected */

#define XLCD_DATAPORT       PORTA
#define XLCD_DATAPORT_TRIS  TRISA

//////////////////////////////////////////////////////////////////////////////
//RS Pin
//////////////////////////////////////////////////////////////////////////////

#define XLCD_RSPIN   PORTBbits.RB7
#define XLCD_RSPIN_TRIS  TRISBbits.TRISB7

//////////////////////////////////////////////////////////////////////////////
//Enable Pin
//////////////////////////////////////////////////////////////////////////////

#define XLCD_ENPIN   PORTBbits.RB6
#define XLCD_ENPIN_TRIS  TRISBbits.TRISB6

//////////////////////////////////////////////////////////////////////////////
// On Off Pin
//////////////////////////////////////////////////////////////////////////////

#define XLCD_ONOFF_PIN   PORTCbits.RC0
#define XLCD_ONOFF_TRIS  TRISCbits.TRISC0

//////////////////////////////////////////////////////////////////////////////
// Led Pin
//////////////////////////////////////////////////////////////////////////////

#define XLCD_LED_PIN   PORTCbits.RC1
#define XLCD_LED_TRIS  TRISCbits.TRISC1

//////////////////////////////////////////////////////////////////////////////
// Up Pin
//////////////////////////////////////////////////////////////////////////////

#define XLCD_UP_PIN   PORTAbits.RA4
#define XLCD_UP_TRIS  TRISAbits.TRISA4

//////////////////////////////////////////////////////////////////////////////
// Down Pin
//////////////////////////////////////////////////////////////////////////////


#define XLCD_DOWN_PIN   PORTCbits.RC2
#define XLCD_DOWN_TRIS  TRISCbits.TRISC2

//////////////////////////////////////////////////////////////////////////////
// Faster Pin
//////////////////////////////////////////////////////////////////////////////

#define XLCD_FASTER_PIN   PORTCbits.RC6
#define XLCD_FASTER_TRIS  TRISCbits.TRISC6

//////////////////////////////////////////////////////////////////////////////
// Slower Pin
//////////////////////////////////////////////////////////////////////////////

#define XLCD_SLOWER_PIN   PORTCbits.RC7
#define XLCD_SLOWER_TRIS  TRISCbits.TRISC7

void XLCDInit(void);                                //to initialise the LCD
void XLCDPut(char data);                            //to put dtat to be displayed
void XLCDPutRamString(char *string);                //to display data string in RAM
void XLCDPutRomString(rom char *string);            //to display data stringin ROM
char XLCDIsBusy(void);                              //to check Busy flag
void XLCDCommand(unsigned char cmd);                //to send commands to LCD           
unsigned char XLCDGetAddr(void);
char XLCDGet(void);
void check_pins(void);
unsigned char get_direction(void);
unsigned char get_speed(unsigned char, unsigned char);

#define XLCDL1home()    XLCDCommand(0x80)
#define XLCDL2home()    XLCDCommand(0xC0)
#define XLCDClear()     XLCDCommand(0x01)
#define XLCDReturnHome() XLCDCommand(0x02)


void XLCDDelay2s(void);
void XLCDDelay15ms(void);
void XLCDDelay4ms(void);
void XLCD_Delay500ns(void);
void Pulse_E(void);
void XLCDDelay120ms(void);
void XLCDDelay2ms(void);

#endif
