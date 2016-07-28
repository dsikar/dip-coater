; ###############################################################################
; Name of this file:           USB18.ASM
;
; USB library routines for use by HIDMaker FS with Microchip C18
;
; Based on a USB source file for PicBasic Pro [Copyright (c) 2005 by microEngineering Labs, Inc.],
; developed jointly by microEngineering Labs, Inc. and Trace Systems, Inc..
; Enhancements for use with HIDmaker FS are Copyright (c) 2005 by Trace Systems, Inc.
;
; All rights reserved by Trace Systems Inc. and microEngineering Labs, Inc..
;
; This version works with Microchip C18
;
; ###############################################################################


; Enable ONE SET of the following pairs of lines, to select processor:
  list p=18f4550
  #include p18f4550.inc
;  list p=18f2550
;  #include p18f2550.inc
;  list p=18f4555
;  #include p18f4555.inc
;  list p=18f4455
;  #include p18f4455.inc
;  list p=18f4450
;  #include p18f4450.inc
;  list p=18f2450
;  #include p18f2450.inc
  
  #include usb18.inc
  #include pdconsts.inc
  #include USBwatch.inc

; Externs from usb18mem.asm:

  extern R0

#if(0 <= MAX_EP_NUMBER)
  extern ep0Bo, ep0Bi
#endif

#if(1 <= MAX_EP_NUMBER)
  extern ep1Bo, ep1Bi
#endif

#if(2 <= MAX_EP_NUMBER)
  extern ep2Bo, ep2Bi
#endif

#if(3 <= MAX_EP_NUMBER)
  extern ep3Bo, ep3Bi
#endif

#if(4 <= MAX_EP_NUMBER)
  extern ep4Bo, ep4Bi
#endif

#if(5 <= MAX_EP_NUMBER)
  extern ep5Bo, ep5Bi
#endif

#if(6 <= MAX_EP_NUMBER)
  extern ep6Bo, ep6Bi
#endif

#if(7 <= MAX_EP_NUMBER)
  extern ep7Bo, ep7Bi
#endif

#if(8 <= MAX_EP_NUMBER)
  extern ep8Bo, ep8Bi
#endif

#if(9 <= MAX_EP_NUMBER)
  extern ep9Bo, ep9Bi
#endif

#if(10 <= MAX_EP_NUMBER)
  extern ep10Bo, ep10Bi
#endif

#if(11 <= MAX_EP_NUMBER)
  extern ep11Bo, ep11Bi
#endif

#if(12 <= MAX_EP_NUMBER)
  extern ep12Bo, ep12Bi
#endif

#if(13 <= MAX_EP_NUMBER)
  extern ep13Bo, ep13Bi
#endif

#if(14 <= MAX_EP_NUMBER)
  extern ep14Bo, ep14Bi
#endif

#if(15 <= MAX_EP_NUMBER)
  extern ep15Bo, ep15Bi
#endif

  extern  usb_temp, pSrc, pDst
  extern  SavedFSR0, SavedFSR1, SavedFSR2
  extern  ctrl_trf_state, ctrl_trf_session_owner, wCount
  extern  usb_device_state, usb_active_cfg, usb_alt_intf, usb_stat
  extern  SetupPktLen, SetupPkt, CtrlTrfDataLen, CtrlTrfData, CtrlTrfDataStorage
  extern  C1_InEpTable, C1_OutEpTable, C2_InEpTable, C2_OutEpTable

  
#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
  extern  USBWtemp, USBWstate, UmsgBuf
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif  ;  #ifdef USB_WATCH

  extern  MaxPacketSize, PacketBitIndex, PacketByteIndex, TempByte
  extern  TempCount, VarBits, VarBytes, VarSign, VarSize

#ifdef  USB_USE_CDC    ; (See  )
  extern  line_coding, control_signal_bitmap, dummy_encapsulated_cmd_response
  extern  dwDTERate, bCharFormat, bParityType, bDataBits
  extern  cdc_notice, cdc_data_rx, cdc_data_tx
#endif   ;  #ifdef USB_USE_CDC

; Externs from descript.asm:

  extern  DeviceDescriptor, Config1, Config1Len, HID0, Config2, Config2Len
  extern  C1_RD_Table, C2_RD_Table, USB_SD_Ptr

  #include VTextern.inc

; Externs from main module:
  extern  HLL_IdleRate, HLL_ActiveProtocol, USB_Curr_Config, USB_Curr_Identity
  extern  FeatureIn, RcvFeatureRpt, RcvOutRpt

#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
  extern  USBW_On
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif  ;  #ifdef USB_WATCH
  
  code

;=====================================================================
; Wrapper routines callable from C18
;=====================================================================


;/******************************************************************************
; * Function:        void USBInit(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine initializes the USB module and driver 
; *                  routines.
; *
; * Note:            None
; *****************************************************************************/
USBInit
  global USBInit

; Save C18 FSR0, FSR1 and FSR2
  rcall   SaveFSRs
  
#ifdef USE_USB_BUS_SENSE_IO
  bsf  tris_usb_bus_sense
#endif
  
#ifdef USE_USB_SELF_PWER_SENSE_IO
  bsf  tris_self_power
#endif
  
  rcall   InitializeUSBDriver
  
; Restore C18 FSR0, FSR1 and FSR2
  rcall   RestoreFSRs
  
  return


;/******************************************************************************
; * Function:        void USBService(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine must be called regularly to service
; *                  all USB requests from PC.
; *
; *****************************************************************************/
USBService
  global USBService
  
; Save C18 FSR0, FSR1 and FSR2
  rcall   SaveFSRs
  
  rcall    USBCheckBusStatus
  
  rcall    USBDriverService
  
; Restore C18 FSR0, FSR1 and FSR2
  rcall   RestoreFSRs
  
  return


; ************************************************************************
; ReadAndUnpackOnePacket
;
; Precondition: None
;
; Inputs:  EpNum: number of the OUTPUT endpoint to get this Output Report from
;          VarTable: address of the corresponding Variable Info Table
;                      (located in file DESCRIPT.ASM)
;
; Output:  0 if report is done or no report is in progress
;          0xFF if a multi-paccket report is in progress,
;                  (i.e., more packets are expected)
;
; Side effects:
;
; Overview: This function is called multiple times from the main loop.
;           It should be called repeatedly, until it returns 0 (FALSE),
;           which indicates that the entire Output Report has been received,
;           and is now ready for processing of the data.
;
; unsigned char ReadAndUnpackOnePacket( unsigned char EpNum, rom const * VarTable);
;
; ************************************************************************
ReadAndUnpackOnePacket
  global ReadAndUnpackOnePacket
  
; Adjust the C18 software stack. As in C18, assumes FSR2H = FSR1H
  movff   FSR2L, POSTINC1     ; push FSR2 on stack
  movff   FSR1L, FSR2L        ; Copy FSR1 to FSR2
;  movf    POSTINC1, F, a      ; OPTIONAL: Increment stack ptr to allocate space for 1 local var
  movlb   4                   ; point to USB ram

; Save C18 FSR1 and FSR2
  rcall   SaveFSRs
  
; Rearrange the C18 parameters and call UnPacket  
  movlw   0xFD                ; high (Arg2 = &VarTable) is at offset -3 from FSR2
  movf    PLUSW2, W           ; VarTable -> W
  movwf   TBLPTRH			  ; parameter VarTable -> local var pVarTable

  movlw   0xFC                ; low (Arg2 = &VarTable) is at offset -4 from FSR2
  movf    PLUSW2, W           ; VarTable -> W
  movwf   TBLPTRL			  ; parameter VarTable -> local var pVarTable
  clrf	TBLPTRU

  movlw   0xFE                ; Arg1, EpNum, is at offset -2 from FSR2
  movf    PLUSW2, W           ; EpNum -> W
  
  call   UnPacket
  
; Result to be returned is already in W
   
; Restore C18 FSR1 and FSR2
  rcall   RestoreFSRs

; Adjust s/w stack for return
  movf    POSTDEC1, F         ; Point to previous frame pointer
  movff   INDF1, FSR2L        ; Restore previous value of FSR2 (calling frame ptr) 
  
  return  


; ************************************************************************
; PackAndSendOnePacket
;
; Precondition: None
;
; Inputs:  EpNum: number of the INPUT endpoint to send this Input Report to
;          VarTable: address of the corresponding Variable Info Table
;                      (located in file DESCRIPT.ASM)
;
; Output:  0 if report is done or no report is in progress
;          0xFF if a multi-paccket report is in progress,
;                  (i.e., more packets remain to be sent)
;
; Side effects:
;
; Overview: This function is called multiple times from the main loop.
;           It should be called repeatedly, until it returns 0 (FALSE),
;           which indicates that the entire Input Report has been sent to the PC.
;
; unsigned char PackAndSendOnePacket( unsigned char EpNum, rom const * VarTable);
;
; ************************************************************************

PackAndSendOnePacket
  global PackAndSendOnePacket

  
; Adjust the C18 software stack. As in C18, assumes FSR2H = FSR1H
  movff   FSR2L, POSTINC1     ; push FSR2 on stack
  movff   FSR1L, FSR2L        ; Copy FSR1 to FSR2
;  movf    POSTINC1, F, a      ; OPTIONAL: Increment stack ptr to allocate space for 1 local var    
  movlb   4                   ; point to USB ram

; Save C18 FSR1 and FSR2
  rcall   SaveFSRs
;  movff   FSR1L, SavedFSR1
;  movff   FSR1H, SavedFSR1+1
;  movff   FSR2L, SavedFSR2
;  movff   FSR2H, SavedFSR2+1
  
; Rearrange the C18 parameters and call PackandShipPacket
; * Input:           W contains EndPoint number
; *                  TBLPTRH/L is VarTable address
  movlw   0xFD                ; high (Arg2 = &VarTable) is at offset -3 from FSR2
  movf    PLUSW2, W           ; VarTable -> W
  movwf   TBLPTRH			  ; parameter VarTable -> local var pVarTable

  movlw   0xFC                ; low (Arg2 = &VarTable) is at offset -4 from FSR2
  movf    PLUSW2, W           ; VarTable -> W
  movwf   TBLPTRL			  ; parameter VarTable -> local var pVarTable
  clrf	TBLPTRU

  movlw   0xFE                ; Arg1, EpNum, is at offset -2 from FSR2
  movf    PLUSW2, W           ; EpNum -> W

  call   PackandShipPacket
; *
; * Output:          Returns W = 0 when Report is all packed,
; *                  W != 0 if there are still more packets to go or if Endpoint busy
  
; Result to be returned is already in W
   
; Restore C18 FSR1 and FSR2
  rcall   RestoreFSRs
;  movff   SavedFSR1, FSR1L
;  movff   SavedFSR1+1, FSR1H
;  movff   SavedFSR2, FSR2L
;  movff   SavedFSR2+1, FSR2H
  
; Adjust s/w stack for return
  movf    POSTDEC1, F         ; Point to previous frame pointer
  movff   INDF1, FSR2L        ; Restore previous value of FSR2 (calling frame ptr) 
  
  return  


; ************************************************************************
; UsbPutPacket
;
; Precondition: Buffer must be of suitable length to hold data
;
; Inputs:  EpNum    : number of the OUTPUT endpoint to which to send this Output packet
;          pBuffPtr : pointer into the buffer which holds data to be sent
;          Count    : Number of bytes in Buffer
;
;
; Returns: 0 if endpoint is unavailable due to a pending transfer
;          0xFF data was sent to endpoint buffer
;          Count is modified to hold number of bytes actually SENT, if any
;          pBuffPtr is updated as well
;
; Side effects:  
;
; Overview: Takes Count number of bytes from Buffer and sends them to USB endpoint EpNum.
;           If buffer size > Count, 
;           If buffer size < Count, 
;
; unsigned char UsbPutPacket( unsigned char EpNum, unsigned char * * pBuffPtr, unsigned char * Count);
;
; ************************************************************************
UsbPutPacket
  global UsbPutPacket

; Adjust the C18 software stack. As in C18, assumes FSR2H = FSR1H
  movff   FSR2L, POSTINC1     ; push FSR2 on stack
  movff   FSR1L, FSR2L        ; Copy FSR1 to FSR2
;  movf    POSTINC1, F, a      ; OPTIONAL: Increment stack ptr to allocate space for 1 local var
  movlb   4                   ; point to USB ram

; Save C18 FSR1 and FSR2
  rcall   SaveFSRs

; Rearrange the C18 parameters and call PutUSB
; * Input:           FSR0L is endpoint number (FSR0H = 0)
; *                  FSR1 is source buffer pointer
; *                  W is count
  movlw   0xFC                ; Low (Arg2 = &pBuffPtr) is at offset -4 from FSR2
  movff   PLUSW2, FSR0L       ; Low(&pBuffPtr) -> FSR0L
  movlw   0xFD                ; High (Arg2 = pBuffPtr) is at offset -3 from FSR2
  movff   PLUSW2, FSR0H       ; High(&pBuffPtr) -> FSR0H
  movff   POSTINC0, FSR1L     ; Now copy contents of pBuffPtr to FSR1
  movff   POSTINC0, FSR1H     

  movlw   0xFA                ; Low (Arg3 = &Count) is at offset -6 from FSR2
  movff   PLUSW2, FSR0L       ; Low(&Count) -> FSR0L
  movlw   0xFB                ; High (Arg3 = &Count) is at offset -5 from FSR2
  movff   PLUSW2, FSR0H       ; High(&Count) -> FSR0H
  movff   INDF0, usb_temp     ; Count -> usb_temp

  movlw   0xFE                ; Arg1, EpNum, is at offset -2 from FSR2
  movff   PLUSW2, FSR0L       ; EpNum -> FSR0L
  movlw   0
  movwf   FSR0H

  movf    usb_temp, W

  call   PutUSB

; Rearrange the C18 parameters returned from PutUSB
; * Output:          FSR1 is updated source buffer pointer
; *                  W returns number sent
; *                  Carry is clear for buffer not available
  movwf   usb_temp            ; Temporarily stash number sent
  movlw   0                   ; Determine return value based on Carry...
  btfsc   STATUS, C
  movlw   0xFF
  movwf   usb_temp+1          ; .. & temporarily stash return value

; Restore C18 FSR2
  movff   SavedFSR2, FSR2L
  movff   SavedFSR2+1, FSR2H

  ; Update pBuffPtr
  movlw   0xFC                ; Low (Arg2 = &pBuffPtr) is at offset -4 from FSR2
  movff   PLUSW2, FSR0L       ; Low(&pBuffPtr) -> FSR0L
  movlw   0xFD                ; High (Arg2 = pBuffPtr) is at offset -3 from FSR2
  movff   PLUSW2, FSR0H       ; High(&pBuffPtr) -> FSR0H
  movff   FSR1L, POSTINC0     ; Now copy contents of FSR1 to pBuffPtr
  movff   FSR1H, POSTINC0

  ; Update Count
  movlw   0xFA                ; Low (Arg3 = &Count) is at offset -6 from FSR2
  movff   PLUSW2, FSR1L       ; Low(&Count) -> FSR1L
  movlw   0xFB                ; High (Arg3 = &Count) is at offset -5 from FSR2
  movff   PLUSW2, FSR1H       ; High(&Count) -> FSR1H
  movff   usb_temp, INDF1     ; Update value of Count

; Now we can restore C18 FSR0 and FSR1
  movff   SavedFSR0, FSR0L
  movff   SavedFSR0+1, FSR0H
  movff   SavedFSR1, FSR1L
  movff   SavedFSR1+1, FSR1H

  ; Set return value
  movf    usb_temp+1, W

; Adjust s/w stack for return
  movf    POSTDEC1, F         ; Point to previous frame pointer
  movff   INDF1, FSR2L        ; Restore previous value of FSR2 (calling frame ptr)
  
  return


; ************************************************************************
; UsbGetPacket
;
; Precondition: Buffer must be of suitable length to hold data
;
; Inputs:  EpNum    : number of the INPUT endpoint from which to send this Input packet
;          pBuffPtr : pointer into the buffer which holds data to be sent
;          Count    : max buffer length
;
;
; Returns: 0 if endpoint is unavailable due to a pending transfer
;          0xFF data was transferred from endpoint buffer
;          Count is modified to hold number of bytes actually RECEIVED, if any
;          pBuffPtr is updated as well
;
; Side effects:  
;
; Overview: Transfers up to Count number of bytes from USB endpoint EpNum to pBuffer*.
;           If buffer size > Count, 
;           If buffer size < Count, 
;
; unsigned char UsbGetPacket( unsigned char EpNum, unsigned char * * pBuffPtr, unsigned char * Count);
;
; ************************************************************************
UsbGetPacket
  global UsbGetPacket

; Adjust the C18 software stack. As in C18, assumes FSR2H = FSR1H
  movff   FSR2L, POSTINC1     ; push FSR2 on stack
  movff   FSR1L, FSR2L        ; Copy FSR1 to FSR2
;  movf    POSTINC1, F, a      ; OPTIONAL: Increment stack ptr to allocate space for 1 local var
  movlb   4                   ; point to USB ram

; Save C18 FSR1 and FSR2
  rcall   SaveFSRs

; Rearrange the C18 parameters and call GetUSB
; * Input:           FSR0L is endpoint number
; *                  FSR1 is destination buffer pointer
; *                  W is max buffer length
  movlw   0xFC                ; Low (Arg2 = &pBuffPtr) is at offset -4 from FSR2
  movff   PLUSW2, FSR0L       ; Low(&pBuffPtr) -> FSR0L
  movlw   0xFD                ; High (Arg2 = pBuffPtr) is at offset -3 from FSR2
  movff   PLUSW2, FSR0H       ; High(&pBuffPtr) -> FSR0H
  movff   POSTINC0, FSR1L     ; Now copy contents of pBuffPtr to FSR1
  movff   POSTINC0, FSR1H     

  movlw   0xFA                ; Low (Arg3 = &Count) is at offset -6 from FSR2
  movff   PLUSW2, FSR0L       ; Low(&Count) -> FSR0L
  movlw   0xFB                ; High (Arg3 = &Count) is at offset -5 from FSR2
  movff   PLUSW2, FSR0H       ; High(&Count) -> FSR0H
  movff   INDF0, usb_temp     ; Count -> usb_temp

  movlw   0xFE                ; Arg1, EpNum, is at offset -2 from FSR2
  movff   PLUSW2, FSR0L       ; EpNum -> FSR0L
  movlw   0
  movwf   FSR0H

  movf    usb_temp, W

  call   GetUSB

; Rearrange the C18 parameters returned from GetUSB
; * Output:          FSR1 is updated destination buffer pointer
; *                  W returns number received
; *                  Carry is clear for buffer not available
  movwf   usb_temp            ; Temporarily stash number sent
  movlw   0                   ; Determine return value based on Carry...
  btfsc   STATUS, C
  movlw   0xFF
  movwf   usb_temp+1          ; .. & temporarily stash return value

; Restore C18 FSR2
  movff   SavedFSR2, FSR2L
  movff   SavedFSR2+1, FSR2H

  ; Update pBuffPtr
  movlw   0xFC                ; Low (Arg2 = &pBuffPtr) is at offset -4 from FSR2
  movff   PLUSW2, FSR0L       ; Low(&pBuffPtr) -> FSR0L
  movlw   0xFD                ; High (Arg2 = pBuffPtr) is at offset -3 from FSR2
  movff   PLUSW2, FSR0H       ; High(&pBuffPtr) -> FSR0H
  movff   FSR1L, POSTINC0     ; Now copy contents of FSR1 to pBuffPtr
  movff   FSR1H, POSTINC0

  ; Update Count
  movlw   0xFA                ; Low (Arg3 = &Count) is at offset -6 from FSR2
  movff   PLUSW2, FSR1L       ; Low(&Count) -> FSR1L
  movlw   0xFB                ; High (Arg3 = &Count) is at offset -5 from FSR2
  movff   PLUSW2, FSR1H       ; High(&Count) -> FSR1H
  movff   usb_temp, INDF1     ; Update value of Count

; Now we can restore C18 FSR0 and FSR1
  movff   SavedFSR0, FSR0L
  movff   SavedFSR0+1, FSR0H
  movff   SavedFSR1, FSR1L
  movff   SavedFSR1+1, FSR1H

  ; Set return value
  movf    usb_temp+1, W

; Adjust s/w stack for return
  movf    POSTDEC1, F         ; Point to previous frame pointer
  movff   INDF1, FSR2L        ; Restore previous value of FSR2 (calling frame ptr)

  return

#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
; Add USBwatch activity reporting over hardware serial port
;
; Two wrapper functions to make it easy to send USBwatch user-defined 
; messages from C code

; ************************************************************************
; UsbwSendU
;
; Precondition: None
;
; Inputs:  ByteCount: number bytes to send
;          Buf: address of buffer (in data memory)
;
; Output:  none
;
; Side effects:
;
; Overview: Sends a user-defined USBwatch message, from data in RAM
;
; void UsbwSendU(unsigned char ByteCount, const unsigned char * Buf);
;
; ************************************************************************
UsbwSendU:
  global  UsbwSendU

; Adjust the C18 software stack. As in C18, assumes FSR2H = FSR1H
  movff   FSR2L, POSTINC1     ; push FSR2 on stack
  movff   FSR1L, FSR2L        ; Copy FSR1 to FSR2
;  movf    POSTINC1, F, a      ; OPTIONAL: Increment stack ptr to allocate space for 1 local var
  movlb   4                   ; point to USB ram

; Save C18 FSR1 and FSR2
  rcall   SaveFSRs
  
; Rearrange the C18 parameters and call UsbwSendUSR  
; UsbwSendUSR
;
; Sends a 'U' (User) message
;
; From within PicBasic Pro code, use: HSEROUT ["U", <byte count>, <data>]
;
; Use this version for sending 'U' messages from assembler code in this file
; INPUTS: WREG = byte count
;         FSR0 : IRP point to buffer
;
; Example:
; ========
;  lfsr    0, UmsgBuf     ; Address of buffer that contains your message
;  movlw   <byte count>   ; Number of bytes you want to send
;  rcall    UsbwSendUSR
;
; Rearrange the C18 parameters and call UsbwSendUSR

  movlw   0xFD                ; high (Arg2 = &Buf) is at offset -3 from FSR2
  movff    PLUSW2, FSR0H       ; high (Arg2 = &Buf) -> FSR0H

  movlw   0xFC                ; low (Arg2 = &Buf) is at offset -4 from FSR2
  movff    PLUSW2, FSR0L       ; low (Arg2 = &Buf) -> FSR0L

  movlw   0xFE                ; Arg1, EpNum, is at offset -2 from FSR2
  movf    PLUSW2, W           ; ByteCount -> W

  call    UsbwSendUSR

; Restore C18 FSR1 and FSR2
  rcall   RestoreFSRs
  
; Adjust s/w stack for return
  movf    POSTDEC1, F         ; Point to previous frame pointer
  movff   INDF1, FSR2L        ; Restore previous value of FSR2 (calling frame ptr) 
  
  return


; ************************************************************************
; UsbwSendU_R
;
; Precondition: None
;
; Inputs:  ByteCount: number bytes to send
;          Buf: address of buffer (in program memory)
;
; Output:  none
;
; Side effects:
;
; Overview: Sends a user-defined USBwatch message, from data in program ROM
;
; void UsbwSendU_R(unsigned char ByteCount, rom const unsigned char * RomStr);
;
; ************************************************************************
UsbwSendU_R:
  global  UsbwSendU_R

; Adjust the C18 software stack. As in C18, assumes FSR2H = FSR1H
  movff   FSR2L, POSTINC1     ; push FSR2 on stack
  movff   FSR1L, FSR2L        ; Copy FSR1 to FSR2
;  movf    POSTINC1, F, a      ; OPTIONAL: Increment stack ptr to allocate space for 1 local var
  movlb   4                   ; point to USB ram

; Save C18 FSR1 and FSR2
  rcall   SaveFSRs
  
; Rearrange the C18 parameters and call UsbwSendUSR  
  movlw   0xFD                ; high (Arg2 = &RomStr) is at offset -3 from FSR2
  movff    PLUSW2, TBLPTRH     ; high (Arg2 = &RomStr) -> TBLPTRH

  movlw   0xFC                ; low (Arg2 = &Buf) is at offset -4 from FSR2
  movff    PLUSW2, TBLPTRL     ; low (Arg2 = &Buf) -> TBLPTRL
  clrf	TBLPTRU

  movlw   0xFE                ; Arg1, ByteCount, is at offset -2 from FSR2
  movf    PLUSW2, W           ; ByteCount -> W
  bz      UsbwSendU_R2        ; Bail out if zero  

; Copy the bytes from RomStr to UmsgBuf
  lfsr    0, UmsgBuf
UsbwSendU_R1:
  tblrd   *+
  movff   TABLAT, POSTINC0
  decfsz   WREG
  bra     UsbwSendU_R1

; Now call UsbwSendUSR and transmit bytes from UmsgBuf
  lfsr    0, UmsgBuf
  movlw   0xFE                ; Arg1, ByteCount, is at offset -2 from FSR2
  movf    PLUSW2, W           ; ByteCount -> W

  call    UsbwSendUSR

; Restore C18 FSR1 and FSR2
UsbwSendU_R2:
  rcall   RestoreFSRs
  
; Adjust s/w stack for return
  movf    POSTDEC1, F         ; Point to previous frame pointer
  movff   INDF1, FSR2L        ; Restore previous value of FSR2 (calling frame ptr) 
  
  return

; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif  ;  #ifdef USB_WATCH


;=====================================================================
; Utility routines for C18 interface :
;=====================================================================

; Save FSR0 .. FSR2 in USB ram variables
SaveFSRs
; Push old values of SavedFSR0..2 onto software stack  
  movff   SavedFSR0,   POSTINC1       ; push SavedFSR0 on s/w stack
  movff   SavedFSR0+1, POSTINC1     
  movff   SavedFSR1,   POSTINC1       ; push SavedFSR1 on s/w stack
  movff   SavedFSR1+1, POSTINC1     
  movff   SavedFSR2,   POSTINC1       ; push SavedFSR2 on s/w stack
  movff   SavedFSR2+1, INDF1     
  
  movff   FSR0L, SavedFSR0
  movff   FSR0H, SavedFSR0+1
  movff   FSR1L, SavedFSR1
  movff   FSR1H, SavedFSR1+1
  movff   FSR2L, SavedFSR2
  movff   FSR2H, SavedFSR2+1

  return

; Restore FSR0 .. FSR2 from USB ram variables
RestoreFSRs
  movff   SavedFSR0, FSR0L
  movff   SavedFSR0+1, FSR0H
  movff   SavedFSR1, FSR1L
  movff   SavedFSR1+1, FSR1H
  movff   SavedFSR2, FSR2L
  movff   SavedFSR2+1, FSR2H

; Pop old values of SavedFSR0..2 from software stack  
  movff   POSTDEC1, SavedFSR2+1       ; pop SavedFSR2 from s/w stack      
  movff   POSTDEC1, SavedFSR2     
  movff   POSTDEC1, SavedFSR1+1       ; pop SavedFSR1 from s/w stack      
  movff   POSTDEC1, SavedFSR1     
  movff   POSTDEC1, SavedFSR0+1       ; pop SavedFSR0 from s/w stack      
  movff   INDF1, SavedFSR0     

  return






;=====================================================================
; Core routines :
;=====================================================================


; Put Address into source pointer
mSetSourcePointer macro Address
	movlw	low (Address)
	movwf	pSrc
	movlw	high (Address)
	movwf	pSrc + 1
	endm

; Put Address into destination pointer
mSetDestinationPointer macro Address
	movlw	low (Address)
	movwf	pDst
	movlw	high (Address)
	movwf	pDst + 1
	endm

; Get count from first location of ROM table pointed to by pSrc
mGetRomTableCount macro
	movff	pSrc, TBLPTRL		; Set source address
	movff	pSrc + 1, TBLPTRH
	clrf	TBLPTRU
        tblrd   *			; Read count
	movff	TABLAT, wCount
	clrf	wCount + 1
	endm


; From usb9.c  line 70
;/******************************************************************************
; * Function:        void USBCheckStdRequest(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine checks the setup data packet to see if it
; *                  knows how to handle it
; *
; * Note:            None
; *****************************************************************************/
USBCheckStdRequest
	movlb	high 0x400		; Point to proper bank
	movf	SetupPkt, W		; RequestType = STANDARD?
	andlw	0x60			; Mask to proper bits
	sublw	(STANDARD) << 5
	bnz	USBCheckStdRequestExit	; No
	movlw	SET_ADR			; Handle request
	cpfseq	SetupPkt + bRequest
	bra	USBCheckStdRequest1
	movlw	ADR_PENDING_STATE
	movwf	usb_device_state
	bra	USBStdSetSessionOwnerUSB9

; GET_DESCRIPTOR request?
USBCheckStdRequest1
	movlw	GET_DSC
	cpfseq	SetupPkt + bRequest
	bra	USBCheckStdRequest2
	bra	USBStdGetDscHandler

; GET_CONFIGURATION request?
USBCheckStdRequest2
	movlw	GET_CFG
	cpfseq	SetupPkt + bRequest
	bra	USBCheckStdRequest3
	mSetSourcePointer usb_active_cfg
	movlw	1
	movwf	wCount
	clrf	wCount + 1
	bcf	usb_stat, ctrl_trf_mem	; Indicate RAM
	bra	USBStdSetSessionOwnerUSB9

; SET_CONFIGURATION request?
USBCheckStdRequest3
	movlw	SET_CFG
	cpfseq	SetupPkt + bRequest
	bra	USBCheckStdRequest4
	bra	USBStdSetCfgHandler

; GET_STATUS request?
USBCheckStdRequest4
	movlw	GET_STATUS
	cpfseq	SetupPkt + bRequest
	bra	USBCheckStdRequest5
	bra	USBStdGetStatusHandler

; CLEAR_FEATURE request?
USBCheckStdRequest5
	movlw	CLR_FEATURE
	cpfseq	SetupPkt + bRequest
	bra	USBCheckStdRequest6
	bra	USBStdFeatureReqHandler

; SET_FEATURE request?
USBCheckStdRequest6
	movlw	SET_FEATURE
	cpfseq	SetupPkt + bRequest
	bra	USBCheckStdRequest7
	bra	USBStdFeatureReqHandler

; GET_INTERFACE request?
USBCheckStdRequest7
	movlw	GET_INTF
	cpfseq	SetupPkt + bRequest
	bra	USBCheckStdRequest8
	mSetSourcePointer usb_alt_intf
	movf	SetupPkt + bIntfID, W
	addwf	pSrc, F
	movlw	1
	movwf	wCount
	clrf	wCount + 1
	bcf	usb_stat, ctrl_trf_mem	; Indicate RAM
	bra	USBStdSetSessionOwnerUSB9

; SET_INTERFACE request?
USBCheckStdRequest8
	movlw	SET_INTF
	cpfseq	SetupPkt + bRequest
	return
	lfsr	2, usb_alt_intf
	movf	SetupPkt + bIntfID, W
	movff	SetupPkt + bAltID, PLUSW2
; Branch here after decoding one of the above USB standard requests.
; Assign a value to ctrl_trf_session_owner, to prevent stalling
USBStdSetSessionOwnerUSB9
	movlw	MUID_USB9
	movwf	ctrl_trf_session_owner
USBCheckStdRequestExit
	return

; From usb9.c  line 136
;/******************************************************************************
; * Function:        void USBStdGetDscHandler(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine handles the standard GET_DESCRIPTOR request.
; *                  It utilizes tables dynamically looks up descriptor size.
; *                  This routine should never have to be modified if the tables
; *                  in usbdsc.c are declared correctly.
; *
; * Note:            None
; *****************************************************************************/
USBStdGetDscHandler
;	movlb	high 0x400		; Point to proper bank
	movlw	0x80
	cpfseq	SetupPkt + bmRequestType
	return
	movlw	DSC_DEV
	cpfseq	SetupPkt + bDscType
	bra	USBStdGetDscHandler1
	mSetSourcePointer DeviceDescriptor
	mGetRomTableCount		; Set wCount
	bsf	usb_stat, ctrl_trf_mem	; Indicate ROM
	bra	USBStdSetSessionOwnerUSB9
USBStdGetDscHandler1
	movlw	DSC_CFG
	cpfseq	SetupPkt + bDscType
	bra	USBStdGetDscHandler2
	
#ifndef SUPPORT_MULTI_IDENTITY
	; Normal case: only a single Configuration or "Identity"
	mSetSourcePointer Config1
	movlw	low Config1Len		; Set wCount to total length
	movwf	TBLPTRL
	movlw	high Config1Len
	movwf	TBLPTRH
#else
    ; Used with Soft Detach devices: supports multiple "Identities"
    ; that are handled like "Configurations"
    movlw   2
    cpfseq  USB_Curr_Identity
    bra     USBStdGetDscHandler1_ID1
; Identity 2
	mSetSourcePointer Config2
	movlw	low Config2Len		; Set wCount to total length
	movwf	TBLPTRL
	movlw	high Config2Len
	movwf	TBLPTRH
	bra     USBStdGetDscHandler1_X
; Identity 1
USBStdGetDscHandler1_ID1:
	mSetSourcePointer Config1
	movlw	low Config1Len		; Set wCount to total length
	movwf	TBLPTRL
	movlw	high Config1Len
	movwf	TBLPTRH
USBStdGetDscHandler1_X:    
#endif

	clrf	TBLPTRU
	tblrd	*+			; Read count low
	movff	TABLAT, wCount
	tblrd	*+			; Ignore RETLW opcode
	tblrd	*+			; Read count high
	movff	TABLAT, wCount + 1
	bsf	usb_stat, ctrl_trf_mem	; Indicate ROM
	bra	USBStdSetSessionOwnerUSB9
USBStdGetDscHandler2
	movlw	DSC_STR
	cpfseq	SetupPkt + bDscType
	return
	clrf	TBLPTRU
	clrf	TBLPTRH
	rlncf	SetupPkt + bDscIndex, W	; Index * 2
	addlw	low (USB_SD_Ptr)	; Add element offset to low address
	movwf	TBLPTRL
	movlw	high (USB_SD_Ptr)
	addwfc	TBLPTRH, F
  tblrd   *+			; Get the data to TABLAT and move pointer forward
	movff	TABLAT, pSrc		; Get low source address
  tblrd   *
	movff	TABLAT, pSrc + 1	; Get high source address
	mGetRomTableCount		; Set wCount
	bsf	usb_stat, ctrl_trf_mem	; Indicate ROM
	bra	USBStdSetSessionOwnerUSB9


; From usb9.c  line 180
;/******************************************************************************
; * Function:        void USBStdSetCfgHandler(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine first disables all endpoints by clearing
; *                  UEP registers. It then configures (initializes) endpoints
; *                  specified in the modifiable section.
; *
; * Note:            HIDmaker compatible version: table driven, automatically
; *                  initializes endpoints, regardless of USB class, from info
; *                  in tables contained in HIDmaker's generated version of file
; *                  usb18mem.asm
; *****************************************************************************/
USBStdSetCfgHandler
;	movlb	high 0x400		; Point to proper bank
	movlw	MUID_USB9
	movwf	ctrl_trf_session_owner
	lfsr	2, UEP1			; Reset all non-EP0 UEPn registers
	movlw	15
USBStdSetCfgHandlerClearEPLoop
	clrf	POSTINC2
	decfsz	WREG, F
	bra	USBStdSetCfgHandlerClearEPLoop
	lfsr	2, usb_alt_intf		; Clear usb_alt_intf array
	movlw	MAX_NUM_INT
USBStdSetCfgHandlerClearAltLoop
	clrf	POSTINC2
	decfsz	WREG, F
	bra	USBStdSetCfgHandlerClearAltLoop
	movf	SetupPkt + bCfgValue, W
#ifdef SUPPORT_MULTI_IDENTITY
    ; If here, substitute _USB_Curr_Identity for requested Configuration:
    ; Windows has been told that this device only has one Configuration 
    ; anyway, so it is the Indentity number that we want:
    ; i.e., which identity do we want to be the new official Configuration 1?
	bz	USBStdSetCfgHandler_M
    movf    USB_Curr_Identity, W  ; Only make the switch if requested Config > 0
USBStdSetCfgHandler_M:
#endif
	movwf	usb_active_cfg
	movwf   USB_Curr_Config

	bnz	USBStdSetCfgHandler1
	movlw	ADDRESS_STATE		; SetupPkt + bCfgValue = 0
	movwf	usb_device_state

#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
; Add USBwatch activity reporting over hardware serial port
; (13a)  'L'
    bcf     USBWstate, USBW_CONFIGURED_BIT
    call   UsbwSendState
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif

	return
USBStdSetCfgHandler1
	movlw	CONFIGURED_STATE
	movwf	usb_device_state

#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
; Add USBwatch activity reporting over hardware serial port
; (13c)  'L'
    bsf     USBWstate, USBW_CONFIGURED_BIT
    call   UsbwSendState
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif

;#ifdef USB_USE_CDC
;	rcall	CDCInitEP
;#endif
; Initialize In endpoints
	movlw	1			; Start with endpoint 1
	movwf	usb_temp		; Save it
; See which Configuration we have to initialize: some projects may have 2 Configurations
        movlw   2                       ; Config no. 2?
        cpfseq  usb_active_cfg
        bra     InitC1_InEps              ; No
; Set up for Config 2
	movlw	low C2_InEpTable	; Point to In endpoint table in USB18MEM.ASM
	movwf	TBLPTRL
	movlw	high C2_InEpTable
        bra     Init_InEps
InitC1_InEps
	movlw	low C1_InEpTable	; Point to In endpoint table in USB18MEM.ASM
	movwf	TBLPTRL
	movlw	high C1_InEpTable
Init_InEps
	movwf	TBLPTRH
	clrf	TBLPTRU
	tblrd	*+			; Read number of endpoints
	movff	TABLAT, usb_temp + 1	; Save it somewhere
; Is the number of endpoints 0?
    movf    (usb_temp + 1), F
    bz     USBStdSetCfgHandlerInitOuts  ; No Input endpoints
	tblrd	*+			; Skip next location
USBStdSetCfgHandlerInLoop
	movff	usb_temp, FSR0L		; Save endpoint number in FSR0L
	incf	usb_temp, F		; Bump up endpoint number
	tblrd	*+			; Read endpoint buffer address low
	movff	TABLAT, FSR1L		; Save it in FSR1
	tblrd	*+			; Skip next location
	tblrd	*+			; Read endpoint buffer address high
	movff	TABLAT, FSR1H
	tblrd	*+			; Skip next location
	tblrd	*+			; Read endpoint size
	movf	TABLAT, W		; Move it to W
	tblrd	*+			; Skip next location
	btfss	STATUS, Z		; If endpoint size is 0, don't initialize
	rcall	InitEPIn		; Initialize the endpoint
	decfsz	usb_temp + 1		; Do next In endpoint, if any
	bra	USBStdSetCfgHandlerInLoop
USBStdSetCfgHandlerInitOuts:
; Initialize Out endpoints
	movlw	1			; Start with endpoint 1
	movwf	usb_temp		; Save it
; See which Configuration we have to initialize: some projects may have 2 Configurations
        movlw   2                       ; Config no. 2?
        cpfseq  usb_active_cfg
        bra     InitC1_OutEps              ; No
; Set up for Config 2
	movlw	low C2_OutEpTable	; Point to In endpoint table in USB18MEM.ASM
	movwf	TBLPTRL
	movlw	high C2_OutEpTable
        bra     Init_OutEps
InitC1_OutEps
	movlw	low C1_OutEpTable	; Point to Out endpoint table in USB18MEM.ASM
	movwf	TBLPTRL
	movlw	high C1_OutEpTable
Init_OutEps
	movwf	TBLPTRH
	clrf	TBLPTRU
	tblrd	*+			; Read number of endpoints
	movff	TABLAT, usb_temp + 1	; Save it somewhere
; Is the number of endpoints 0?
    movf    (usb_temp + 1), F
    bz      USBStdSetCfgHandlerExit  ; No Output endpoints
	tblrd	*+			; Skip next location
USBStdSetCfgHandlerOutLoop
	movff	usb_temp, FSR0L		; Save endpoint number in FSR0L
	incf	usb_temp, F		; Bump up endpoint number
	tblrd	*+			; Read endpoint buffer address low
	movff	TABLAT, FSR1L		; Save it in FSR1
	tblrd	*+			; Skip next location
	tblrd	*+			; Read endpoint buffer address high
	movff	TABLAT, FSR1H
	tblrd	*+			; Skip next location
	tblrd	*+			; Read endpoint size
	movf	TABLAT, W		; Move it to W
	tblrd	*+			; Skip next location
	btfss	STATUS, Z		; If endpoint size is 0, don't initialize
	rcall	InitEPOut		; Initialize the endpoint
	decfsz	usb_temp + 1		; Do next In endpoint, if any
	bra	USBStdSetCfgHandlerOutLoop
USBStdSetCfgHandlerExit:
	return


; From usb9.c  line 224
;/******************************************************************************
; * Function:        void USBStdGetStatusHandler(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine handles the standard GET_STATUS request
; *
; * Note:            None
; *****************************************************************************/
USBStdGetStatusHandler
;	movlb	high 0x400		; Point to proper bank
	clrf	CtrlTrfData		; Initialize content
	clrf	CtrlTrfData + 1
	movf	SetupPkt, W		; Recipient = RCPT_DEV?
	andlw	0x1f			; Mask to lower 5 bits
	sublw	RCPT_DEV
	bnz	USBStdGetStatusHandler1	; No
;
; Recipient of this Setup packet was "Device": set bits to indicate power & remote wakeup
; Decoding of "Self-powered" & "Remote Wakeup"
; _byte0: bit0: Self-Powered Status [0] Bus-Powered [1] Self-Powered
;         bit1: RemoteWakeup        [0] Disabled    [1] Enabled
;
#ifdef USB_SELF_POWER
	bsf	CtrlTrfData, 0
#endif
	btfsc	usb_stat, RemoteWakeup
	bsf	CtrlTrfData, 1
	bra	USBStdGetStatusSetSessionOwner
;
USBStdGetStatusHandler1
	movf	SetupPkt, W		; Recipient = RCPT_INTF?
	andlw	0x1f			; Mask to lower 5 bits
	sublw	RCPT_INTF
	bnz	USBStdGetStatusHandler2	; No
;
; Recipient of this Setup packet was "Interface": No data to update
	bra	USBStdGetStatusSetSessionOwner
;
USBStdGetStatusHandler2
	movf	SetupPkt, W		; Recipient = RCPT_EP?
	andlw	0x1f			; Mask to lower 5 bits
	sublw	RCPT_EP
	bnz	USBStdGetStatusHandler3	; No
;
; Recipient of this Setup packet was "Endpoint"
	rcall	USBCalcEPAddress	; Put endpoint buffer address in FSR2
	movf	INDF2, W
	andlw	_BSTALL
	bz	USBStdGetStatusSetSessionOwner
	bsf	CtrlTrfData, 0
USBStdGetStatusSetSessionOwner
	movlw	MUID_USB9
	movwf	ctrl_trf_session_owner
USBStdGetStatusHandler3
	movlw	MUID_USB9
	cpfseq	ctrl_trf_session_owner
	return
	mSetSourcePointer CtrlTrfData
	movlw	2			; Set count
	movwf	wCount
	clrf	wCount + 1
	bcf	usb_stat, ctrl_trf_mem	; Indicate RAM
	return

; From usb9.c  line 281
;/******************************************************************************
; * Function:        void USBStdFeatureReqHandler(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine handles the standard SET & CLEAR FEATURES
; *                  requests
; *
; * Note:            None
; *****************************************************************************/
USBStdFeatureReqHandler
;	movlb	high 0x400		; Point to proper bank
	movlw	DEVICE_REMOTE_WAKEUP	; If Feature = DEVICE_REMOTE_WAKEUP &
	cpfseq	SetupPkt + bFeature
	bra	USBStdFeatureReqHandler1
	movf	SetupPkt, W	; Recipient = RCPT_DEV?
	andlw	0x1f			; Mask to lower 5 bits
	sublw	RCPT_DEV
	bnz	USBStdFeatureReqHandler1	; No
	bsf	usb_stat, RemoteWakeup	; Preset RemoteWakeup to 1
	movlw	SET_FEATURE		; Request = SET_FEATURE?
	cpfseq	SetupPkt + bRequest
	bcf	usb_stat, RemoteWakeup	; No, RemoteWakeup = 0
	bra	USBStdSetSessionOwnerUSB9
USBStdFeatureReqHandler1
	movlw	ENDPOINT_HALT		; If Feature = ENDPOINT_HALT &
	cpfseq	SetupPkt + bFeature
USBStdFeatureReqHandlerExit
	return
	movf	SetupPkt, W	; Recepient = RCPT_EP &
	andlw	0x1f			; Mask to lower 5 bits
	sublw	RCPT_EP
	bnz	USBStdFeatureReqHandlerExit
	movf	SetupPkt + bEPID, W	; EPNum != 0
	andlw	0x0f			; Mask to EPNum
	bz	USBStdFeatureReqHandlerExit
	rcall	USBCalcEPAddress	; Put endpoint buffer address in FSR2
	movlw	SET_FEATURE		; Request = SET_FEATURE?
	cpfseq	SetupPkt + bRequest
	bra	USBStdFeatureReqHandler2	; No
	movlw	_USIE|_BSTALL
	movwf	INDF2			; Put in endpoint buffer
	bra	USBStdSetSessionOwnerUSB9
USBStdFeatureReqHandler2
	movlw	_UCPU			; IN
	btfss	SetupPkt + bEPID, EPDir	; EPDir = 1 (IN)?
	movlw	_USIE|_DAT0|_DTSEN	; No - OUT
	movwf	INDF2			; Put in endpoint buffer
	bra	USBStdSetSessionOwnerUSB9


; Put endpoint buffer address in FSR2 (ep0Bo+(EPNum*8)+(EPDir*4))
USBCalcEPAddress
	lfsr	2, ep0Bo		; Point FSR2 to beginning of buffer area
	rlncf	SetupPkt + bEPID, W	; Move endpoint direction to C
	rlcf	SetupPkt + bEPID, W	; Endpoint number * 8 (roll in ep direction)
	rlncf	WREG, F
	rlncf	WREG, F
	addwf	FSR2L, F		; Add to FSR2 (can't overflow to FSR2H)
	return



; From usbctrltrf.c line 78
;/******************************************************************************
; * Function:        void USBCtrlEPService(void)
; *
; * PreCondition:    USTAT is loaded with a valid endpoint address.
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        USBCtrlEPService checks for three transaction types that
; *                  it knows how to service and services them:
; *                  1. EP0 SETUP
; *                  2. EP0 OUT
; *                  3. EP0 IN
; *                  It ignores all other types (i.e. EP1, EP2, etc.)
; *
; * Note:            None
; *****************************************************************************/
USBCtrlEPService
;	movlb	high 0x400		; Point to proper bank
	movlw	EP00_OUT
	cpfseq	USTAT
	bra	USBCtrlEPService1
	movf	ep0Bo + Stat, W
	andlw	0x3c			; Mask to PID
	sublw	(SETUP_TOKEN) << 2
	bz	USBCtrlTrfSetupHandler
	bra	USBCtrlTrfOutHandler
USBCtrlEPService1
	movlw	EP00_IN
	cpfseq	USTAT
	return
	bra	USBCtrlTrfInHandler


; From usbctrltrf.c line 133
;/******************************************************************************
; * Function:        void USBCtrlTrfSetupHandler(void)
; *
; * PreCondition:    SetupPkt buffer is loaded with valid USB Setup Data
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine is a task dispatcher and has 3 stages.
; *                  1. It initializes the control transfer state machine.
; *                  2. It calls on each of the module that may know how to
; *                     service the Setup Request from the host.
; *                     Module Example: USB9, HID, CDC, MSD, ...
; *                     As new classes are added, ClassReqHandler table in
; *                     usbdsc.c should be updated to call all available
; *                     class handlers.
; *                  3. Once each of the modules has had a chance to check if
; *                     it is responsible for servicing the request, stage 3
; *                     then checks direction of the transfer to determine how
; *                     to prepare EP0 for the control transfer.
; *                     Refer to USBCtrlEPServiceComplete() for more details.
; *
; * Note:            Microchip USB Firmware has three different states for
; *                  the control transfer state machine:
; *                  1. WAIT_SETUP
; *                  2. CTRL_TRF_TX
; *                  3. CTRL_TRF_RX
; *                  Refer to firmware manual to find out how one state
; *                  is transitioned to another.
; *
; *                  A Control Transfer is composed of many USB transactions.
; *                  When transferring data over multiple transactions,
; *                  it is important to keep track of data source, data
; *                  destination, and data count. These three parameters are
; *                  stored in pSrc,pDst, and wCount. A flag is used to
; *                  note if the data source is from ROM or RAM.
; *
; *****************************************************************************/
USBCtrlTrfSetupHandler
;	movlb	high 0x400		; Point to proper bank
	movlw	WAIT_SETUP
	movwf	ctrl_trf_state
#ifdef  HID_SUPPORT_GET_SET_REPORT
  clrf  SetRptInProgress
  clrf  GetRptInProgress
#endif
	movlw	MUID_NULL		; Set owner to NULL
	movwf	ctrl_trf_session_owner
	clrf	wCount
	clrf	wCount + 1

#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
; Add USBwatch activity reporting over hardware serial port
; (11) 'R'
; Report USB Request parameter data, now in SetupPkt

; Test if USBwatch reporting is ON
    movf     USBW_On, W
    bz       ExitUSBW_11         ; Abort
UsbwSendSetupPkt
    movlw   'R'             ; Signal to USBwatch that we got a SETUP token
    call    UsbwSendChar
    lfsr     0, SetupPkt
    movlw    8
    movwf    USBWtemp
    call    UsbwSendBuf_NBC
ExitUSBW_11
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
 endif

	rcall	USBCheckStdRequest
	movlw	MUID_NULL
	cpfseq	ctrl_trf_session_owner
	bra	USBCtrlEPServiceComplete
#ifdef USB_USE_HID
	rcall	USBCheckHIDRequest
#endif ; USB_USE_HID
#ifdef USB_USE_CDC
	rcall	USBCheckCDCRequest
#endif ; USB_USE_CDC
	bra	USBCtrlEPServiceComplete


; From usbctrltrf.c line 176
;/******************************************************************************
; * Function:        void USBCtrlTrfOutHandler(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine handles an OUT transaction according to
; *                  which control transfer state is currently active.
; *
; * Note:            Note that if the the control transfer was from
; *                  host to device, the session owner should be notified
; *                  at the end of each OUT transaction to service the
; *                  received data.
; *
; *****************************************************************************/
USBCtrlTrfOutHandler
;	movlb	high 0x400		; Point to proper bank
	movlw	CTRL_TRF_RX
	cpfseq	ctrl_trf_state
	bra	USBPrepareForNextSetupTrf
	rcall	USBCtrlTrfRxService
	movlw	_USIE|_DAT1|_DTSEN
	btfsc	ep0Bo + Stat, DTS
	movlw	_USIE|_DAT0|_DTSEN
	movwf	ep0Bo + Stat
	return


; From usbctrltrf.c line 221
;/******************************************************************************
; * Function:        void USBCtrlTrfInHandler(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine handles an IN transaction according to
; *                  which control transfer state is currently active.
; *
; *
; * Note:            A Set Address Request must not change the acutal address
; *                  of the device until the completion of the control
; *                  transfer. The end of the control transfer for Set Address
; *                  Request is an IN transaction. Therefore it is necessary
; *                  to service this unique situation when the condition is
; *                  right. Macro mUSBCheckAdrPendingState is defined in
; *                  usb9.h and its function is to specifically service this
; *                  event.
; *****************************************************************************/
USBCtrlTrfInHandler
;	movlb	high 0x400		; Point to proper bank
	movlw	ADR_PENDING_STATE	; Must check if in ADR_PENDING_STATE
	cpfseq	usb_device_state
	bra	USBCtrlTrfInHandler1
	movf	SetupPkt + bDevADR, W
	movwf	UADDR
	movlw	ADDRESS_STATE		; If UADDR > 0
	btfsc	STATUS, Z
	movlw	DEFAULT_STATE
	movwf	usb_device_state

#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
; Add USBwatch activity reporting over hardware serial port
; (12)  'L'
	movf	UADDR, W
  bsf     USBWstate, USBW_ADDRESSED_BIT		; If UADDR > 0
	btfsc	  STATUS, Z
  bcf     USBWstate, USBW_ADDRESSED_BIT		; If UADDR > 0
  call   UsbwSendState
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif

USBCtrlTrfInHandler1
	movlw	CTRL_TRF_TX
	cpfseq	ctrl_trf_state
	bra	USBPrepareForNextSetupTrf
	rcall	USBCtrlTrfTxService
	movlw	_USIE|_DAT1|_DTSEN
	btfsc	ep0Bi + Stat, DTS
	movlw	_USIE|_DAT0|_DTSEN
	movwf	ep0Bi + Stat
	return


; From usbctrltrf.c line 260
;/******************************************************************************
; * Function:        void USBCtrlTrfTxService(void)
; *
; * PreCondition:    pSrc, wCount, and usb_stat.ctrl_trf_mem are setup properly.
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine should be called from only two places.
; *                  One from USBCtrlEPServiceComplete() and one from
; *                  USBCtrlTrfInHandler(). It takes care of managing a
; *                  transfer over multiple USB transactions.
; *
; * Note:            Copies one packet-ful of data pSrc (either ROM or RAM) to
; *                  EP0 IN buffer. It then updates pSrc to be ready for next
; *                  piece.
; *                  This routine works with isochronous endpoint larger than
; *                  256 bytes and is shown here as an example of how to deal
; *                  with BC9 and BC8. In reality, a control endpoint can never
; *                  be larger than 64 bytes.
; *****************************************************************************/
USBCtrlTrfTxService
;	movlb	high 0x400		; Point to proper bank

#ifdef  HID_SUPPORT_GET_SET_REPORT
; Added for HIDmaker: Handle each IN packet of a GetReport request
  movf GetRptInProgress, W
  bz    NoGetRpt
  movlb 0             ; The Basic code needs bank 0
  call  FeatureIn    ; Pack data and load into EP0 buffer
  movlb high 0x400		; Point to proper bank
;
; Because FeatureIn calls PackandShipPacket which toggles DTS, and the caller 
; of this routine, USBCtrlTrfInHandler, also toggles DTS, these would cancel.  
; We need to toggle DTS one more time here, to make things come out right.
	movlw	_USIE|_DAT1|_DTSEN
	btfsc	ep0Bi + Stat, DTS
	movlw	_USIE|_DAT0|_DTSEN
	movwf	ep0Bi + Stat
;  
  movf GetRptInProgress, W
  bnz    USBCtrlTrfTxServiceFinishUp  ; If GET_REPORT is still in progress, wait for next IN packet request
; Need to clear ctrl_trf_state here: GET_REPORT operation is done
	movlw	WAIT_SETUP
	movwf	ctrl_trf_state
  bra   USBCtrlTrfTxServiceFinishUp
NoGetRpt
#endif

	movf	wCount, W		; Preset wCount bytes to send
	movwf	usb_temp
	movf	wCount + 1, W
	movwf	usb_temp + 1
	sublw	high EP0_BUFF_SIZE	; Make sure count does not exceed maximium length
	bnc	USBCtrlTrfTxServiceCopy
	bnz	USBCtrlTrfTxServiceSub
	movf	wCount, W
	sublw	low EP0_BUFF_SIZE
	bc	USBCtrlTrfTxServiceSub
USBCtrlTrfTxServiceCopy
	movlw	low EP0_BUFF_SIZE	; Send buffer full of bytes
	movwf	usb_temp
	movlw	high EP0_BUFF_SIZE
	movwf	usb_temp + 1
USBCtrlTrfTxServiceSub
	movf	usb_temp, W		; Subtract actual bytes to be sent from the buffer
	movwf	ep0Bi + Cnt		; Save low number of bytes to send while we're here
	subwf	wCount, F
	movf	usb_temp + 1, W
	subwfb	wCount + 1, F
	movf	ep0Bi + Stat, W		; Get full Stat byte
	andlw	0xfc			; Clear bottom bits
	iorwf	usb_temp + 1, W		; Put in high bits of bytes to send
	movwf	ep0Bi + Stat		; Save it out
	lfsr	2, CtrlTrfData		; Set destination pointer
	movf	usb_temp + 1, W		; Check high byte for 0
	bnz	USBCtrlTrfTxServiceRomRam	; High byte not 0, must have something to do
	movf	usb_temp, W		; Check low byte for 0
	bz	USBCtrlTrfTxServiceExit	; If both 0 then nothing to send this time
USBCtrlTrfTxServiceRomRam
	btfss	usb_stat, ctrl_trf_mem	; ROM or RAM?
	bra	USBCtrlTrfTxServiceRam	; RAM
	movff	pSrc, TBLPTRL		; Move source pointer to TBLPTR
	movff	pSrc + 1, TBLPTRH
	clrf	TBLPTRU
USBCtrlTrfTxServiceRomLoop
	tblrd	*+
	movff	TABLAT, POSTINC2	; Copy one buffer to the other
	tblrd	*+			; Skip high location
	decf	usb_temp, F		; Count down number of bytes
	bnz	USBCtrlTrfTxServiceRomLoop
	decf	usb_temp + 1, F
	bc	USBCtrlTrfTxServiceRomLoop
	movff	TBLPTRL, pSrc		; Update source pointer
	movff	TBLPTRH, pSrc + 1
  bra   USBCtrlTrfTxServiceFinishUp
USBCtrlTrfTxServiceRam
	movff	pSrc, FSR1L		; Move source pointer to FSR1
	movff	pSrc + 1, FSR1H
USBCtrlTrfTxServiceRamLoop
	movff	POSTINC1, POSTINC2	; Copy one buffer to the other
	decf	usb_temp, F		; Count down number of bytes
	bnz	USBCtrlTrfTxServiceRamLoop
	decf	usb_temp + 1, F
	bc	USBCtrlTrfTxServiceRamLoop
	movff	FSR1L, pSrc		; Update source pointer
	movff	FSR1H, pSrc + 1
USBCtrlTrfTxServiceFinishUp


USBCtrlTrfTxServiceExit
	return


; From usbctrltrf.c line 330
;/******************************************************************************
; * Function:        void USBCtrlTrfRxService(void)
; *
; * PreCondition:    pDst and wCount are setup properly.
; *                  pSrc is always &CtrlTrfData
; *                  usb_stat.ctrl_trf_mem is always _RAM.
; *                  wCount should be set to 0 at the start of each control
; *                  transfer.
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        Transfers bytes received, at EP0 OUT buffer CtrlTrfData,
; *                  to user's buffer pointed by pDst.
; *                  This routine only knows how to handle raw byte data.
; *                  HIDmaker handles transferring and unpacking by a callback
; *                  function in the generated main program, called from here.
; *
; *
; * Note:            None
; *****************************************************************************/
USBCtrlTrfRxService
;	movlb	high 0x400		; Point to proper bank
#ifdef  HID_SUPPORT_GET_SET_REPORT
; Added for HIDmaker: Handle each OUT packet of a SET_REPORT request
  movf  SetRptInProgress, W
  bz    NoSetRpt
TryFeatureOut:
  movlw   HID_FEATURE_REPORT
  cpfseq  SetupPkt + bReportType
  bra     TryCtlOutRpt
  movlb 0              ; The Basic code needs bank 0
  call  RcvFeatureRpt    ; Transfer Feature Report data from EP0 buffer & unpack it
  bra   SetRptCommon
TryCtlOutRpt
  movlw   HID_OUTPUT_REPORT
  cpfseq  SetupPkt + bReportType
  bra     SetRptBailout
  movlb 0              ; The Basic code needs bank 0
  call  RcvOutRpt        ; Transfer Output Report data from EP0 buffer & unpack it
SetRptCommon
  movlb high 0x400		 ; Point to our proper bank again
;
; Because RcvFeatureRpt calls UnPacket which toggles DTS, and the caller 
; of this routine, USBCtrlTrfOutHandler, also toggles DTS, these would cancel.  
; We need to toggle DTS one more time here, to make things come out right.
	movlw	_USIE|_DAT1|_DTSEN
	btfsc	ep0Bo + Stat, DTS
	movlw	_USIE|_DAT0|_DTSEN
	movwf	ep0Bo + Stat
;  
  movf SetRptInProgress, W
  btfss  STATUS, Z
  return              ; If SET_REPORT is still in progress, wait for next OUT packet request
; Otherwise, need to clear ctrl_trf_state here: SET_REPORT operation is done
	movlw	WAIT_SETUP
	movwf	ctrl_trf_state
SetRptBailout
  return
NoSetRpt

#endif
	movf	ep0Bo + Cnt, W		; Get low number of bytes to read
	movwf	usb_temp		; usb_temp & usb_temp + 1 are bytes to read
	addwf	wCount, F		; Accumulate total number of bytes read
	movf	ep0Bo + Stat, W		; Get high bits to read
	andlw	0x03			; Mask to the count
	movwf	usb_temp + 1		; Save to high byte of bytes to read
	addwfc	wCount + 1, F		; Add overflow from low byte (C) and high byte to total number
	lfsr	1, CtrlTrfData		; Point FSR1 to source
	movff	pDst, FSR2L		; Move destination pointer to FSR2
	movff	pDst + 1, FSR2H
	movf	usb_temp + 1, W		; Check high byte for 0
	bnz	USBCtrlTrfRxServiceLoop	; High byte not 0, must have something to do
	movf	usb_temp, W		; Check low byte for 0
	bz	USBCtrlTrfRxServiceExit	; If both 0 then nothing to send this time
USBCtrlTrfRxServiceLoop
	movff	POSTINC1, POSTINC2	; Copy one buffer to the other
	decf	usb_temp, F		; Count down number of bytes
	bnz	USBCtrlTrfRxServiceLoop
	decf	usb_temp + 1, F
	bc	USBCtrlTrfRxServiceLoop
	movff	FSR2L, pDst		; Update destination pointer
	movff	FSR2H, pDst + 1
USBCtrlTrfRxServiceExit
	return


; From usbctrltrf.c line 382
;/******************************************************************************
; * Function:        void USBCtrlEPServiceComplete(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine wrap up the ramaining tasks in servicing
; *                  a Setup Request. Its main task is to set the endpoint
; *                  controls appropriately for a given situation. See code
; *                  below.
; *                  There are three main scenarios:
; *                  a) There was no handler for the Request, in this case
; *                     a STALL should be sent out.
; *                  b) The host has requested a read control transfer,
; *                     endpoints are required to be setup in a specific way.
; *                  c) The host has requested a write control transfer, or
; *                     a control data stage is not required, endpoints are
; *                     required to be setup in a specific way.
; *
; *                  Packet processing is resumed by clearing PKTDIS bit.
; *
; * Note:            None
; *****************************************************************************/
USBCtrlEPServiceComplete
;	movlb	high 0x400		; Point to proper bank
	movlw	MUID_NULL
	cpfseq	ctrl_trf_session_owner
	bra	USBCtrlEPServiceComplete1
;
; No handlers claimed ownership of this Setup packet.
; If no one knows how to service this request then stall.
; Must also prepare EP0 to receive the next SETUP transaction.
	movlw	EP0_BUFF_SIZE
	movwf	ep0Bo + Cnt
	movlw	low SetupPkt
	movwf	ep0Bo + ADRL
	movlw	high SetupPkt
	movwf	ep0Bo + ADRH
	movlw	_USIE|_BSTALL
	movwf	ep0Bo + Stat
	movwf	ep0Bi + Stat
	bra	USBCtrlEPServiceCompleteExit
;
; A module has claimed ownership of the control transfer session.
USBCtrlEPServiceComplete1
	btfss	SetupPkt, DataDir
	bra	USBCtrlEPServiceComplete2
	movf	wCount + 1, W		; Make sure count does not exceed max length requested by Host
	subwf	SetupPkt + wLengthHi, W
	bnc	USBCtrlEPServiceCompleteCopy
	bnz	USBCtrlEPServiceComplete11
	movf	wCount, W
	subwf	SetupPkt + wLength, W
	bc	USBCtrlEPServiceComplete11
USBCtrlEPServiceCompleteCopy
	movff	SetupPkt + wLength, wCount	; Set count to maximum
	movff	SetupPkt + wLengthHi, wCount + 1
;
; Setup packet's data direction is "Device to Host"
USBCtrlEPServiceComplete11
	rcall	USBCtrlTrfTxService    ; Actually copy the data to EP0 IN buffer
	movlw	CTRL_TRF_TX
	movwf	ctrl_trf_state
; Control Read:
; <SETUP[0]><IN[1]><IN[0]>...<OUT[1]> | <SETUP[0]>
; 1. Prepare OUT EP to respond to early termination
;
; NOTE:
; If something went wrong during the control transfer,
; the last status stage may not be sent by the host.
; When this happens, two different things could happen
; depending on the host.
; a) The host could send out a RESET.
; b) The host could send out a new SETUP transaction
;    without sending a RESET first.
; To properly handle case (b), the OUT EP must be setup
; to receive either a zero length OUT transaction, or a
; new SETUP transaction.
;
; Since the SETUP transaction requires the DTS bit to be
; DAT0 while the zero length OUT status requires the DTS
; bit to be DAT1, the DTS bit check by the hardware should
; be disabled. This way the SIE could accept either of
; the two transactions.
;
; Furthermore, the Cnt byte should be set to prepare for
; the SETUP data (8-byte or more), and the buffer address
; should be pointed to SetupPkt.
	movlw	EP0_BUFF_SIZE
	movwf	ep0Bo + Cnt
	movlw	low SetupPkt
	movwf	ep0Bo + ADRL
	movlw	high SetupPkt
	movwf	ep0Bo + ADRH
	movlw	_USIE			; Note: DTSEN is 0!
	movwf	ep0Bo + Stat
; 2. Prepare IN EP to transfer data, Cnt should have
;    been initialized by responsible request owner.
	movlw	low CtrlTrfData
	movwf	ep0Bi + ADRL
	movlw	high CtrlTrfData
	movwf	ep0Bi + ADRH
	movlw	_USIE|_DAT1|_DTSEN
	movwf	ep0Bi + Stat
	bra	USBCtrlEPServiceCompleteExit
;
; Setup packet's data direction is "Host to Device"
USBCtrlEPServiceComplete2
	movlw	CTRL_TRF_RX
	movwf	ctrl_trf_state
; Control Write:
; <SETUP[0]><OUT[1]><OUT[0]>...<IN[1]> | <SETUP[0]>
;
; 1. Prepare IN EP to respond to early termination
;
;    This is the same as a Zero Length Packet Response
;    for control transfer without a data stage
	clrf	ep0Bi + Cnt
	movlw	_USIE|_DAT1|_DTSEN
	movwf	ep0Bi + Stat
; 2. Prepare OUT EP to receive data.
	movlw	EP0_BUFF_SIZE
	movwf	ep0Bo + Cnt
	movlw	low CtrlTrfData
	movwf	ep0Bo + ADRL
	movlw	high CtrlTrfData
	movwf	ep0Bo + ADRH
	movlw	_USIE|_DAT1|_DTSEN
	movwf	ep0Bo + Stat
;
USBCtrlEPServiceCompleteExit
; PKTDIS bit is set when a Setup Transaction is received.
; Clear to resume packet processing.
	bcf	UCON, PKTDIS
	return


; From usbctrltrf.c line 490
;/******************************************************************************
; * Function:        void USBPrepareForNextSetupTrf(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        The routine forces EP0 OUT to be ready for a new Setup
; *                  transaction, and forces EP0 IN to be owned by CPU.
; *
; * Note:            None
; *****************************************************************************/
USBPrepareForNextSetupTrf
;	movlb	high 0x400		; Point to proper bank
	movlw	WAIT_SETUP
	movwf	ctrl_trf_state
	movlw	EP0_BUFF_SIZE
	movwf	ep0Bo + Cnt
	movlw	low SetupPkt
	movwf	ep0Bo + ADRL
	movlw	high SetupPkt
	movwf	ep0Bo + ADRH
	movlw	_USIE|_DAT0|_DTSEN	; EP0 buff dsc init
	movwf	ep0Bo + Stat
	movlw	_UCPU			; EP0 IN buffer initialization
	movwf	ep0Bi + Stat
	return



; From usbdrv.c line ???
;/******************************************************************************
; * Function:        void InitializeUSBDriver(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine initializes variables used by the USB library
; *                  routines.
; *
; * Note:            None
; *****************************************************************************/
InitializeUSBDriver
	movlb	high 0x400		; Point to proper bank
	movlw	EP0_BUFF_SIZE
	movwf	SetupPktLen
	movwf	CtrlTrfDataLen
        clrf  (CtrlTrfDataStorage + 4)
	movlw	UCFG_VAL
	movwf	UCFG
	movlw	DETACHED_STATE
	movwf	usb_device_state
	clrf	usb_stat
	clrf	usb_active_cfg
;#ifdef USB_USE_CDC
;	rcall	CDCInitEP
;#endif

#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
; Add USBwatch activity reporting over hardware serial port
; (1)  'L'
    movlw   USBW_POWERED_STATE
    movwf	  USBWstate
    call   UsbwSendState
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif

	return


; From usbdrv.c line 76
;/******************************************************************************
; * Function:        void USBCheckBusStatus(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine enables/disables the USB module by monitoring
; *                  the USB power signal.
; *
; * Note:            None
; *****************************************************************************/
USBCheckBusStatus
	movlb	high 0x400		; Point to proper bank
; Bus Attachment & Detachment Detection
; usb_bus_sense is an i/o pin defined in io_cfg.h
#ifdef USE_USB_BUS_SENSE_IO
	btfss	usb_bus_sense		; Is USB bus attached?
	bra	USBCheckBusStatusDetached	; No
#endif
	btfss	UCON, USBEN		; Is the module off?
	rcall	USBModuleEnable		; Is off, enable it
#ifdef USE_USB_BUS_SENSE_IO
	bra	USBCheckBusStatus1
USBCheckBusStatusDetached
	btfsc	UCON, USBEN		; Is the module on?
	rcall	USBModuleDisable	; Is on, disable it
#endif
;
; After enabling the USB module, it takes some time for the voltage
; on the D+ or D- line to rise high enough to get out of the SE0 condition.
; The USB Reset interrupt should not be unmasked until the SE0 condition is
; cleared. This helps preventing the firmware from misinterpreting this
; unique event as a USB bus reset from the USB host.
USBCheckBusStatus1
	movlw	ATTACHED_STATE
	cpfseq	usb_device_state
	return
	btfsc	UCON, SE0
	return
	clrf	UIR			; Clear all USB interrupts
	clrf	UIE			; Mask all USB interrupts
	bsf	UIE, URSTIE		; Unmask RESET interrupt
	bsf	UIE, IDLEIE		; Unmask IDLE interrupt
	movlw	POWERED_STATE
	movwf	usb_device_state
	return


; From usbdrv.c line 135
USBModuleEnable
;	movlb	high 0x400		; Point to proper bank
	clrf	UCON
	clrf	UIE			; Mask all USB interrupts
	bsf	UCON, USBEN		; Enable module & attach to bus
	movlw	ATTACHED_STATE
	movwf	usb_device_state
	return


; From usbdrv.c line 192
USBSoftDetach
  global USBSoftDetach
; From usbdrv.c line 161
USBModuleDisable
	movlb	high 0x400		; Point to proper bank
	clrf	UCON			; Disable module & detach from bus
	clrf	UIE			; Mask all USB interrupts
	movlw	DETACHED_STATE
	movwf	usb_device_state
	return


; From usbdrv.c line 215
;/******************************************************************************
; * Function:        void USBDriverService(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine is the heart of this firmware. It manages
; *                  all USB interrupts.
; *
; * Note:            Device state transitions through the following stages:
; *                  DETACHED -> ATTACHED -> POWERED -> DEFAULT ->
; *                  ADDRESS_PENDING -> ADDRESSED -> CONFIGURED -> READY
; *****************************************************************************/
USBDriverService
	movlb	high 0x400		; Point to proper bank
	movlw	DETACHED_STATE
	subwf	usb_device_state, W
	bz	USBDriverServiceExit	; Pointless to continue servicing
					; if USB cable is not even attached.
;
; Task A: Service USB Activity Interrupt
	btfss	UIR, ACTVIF
	bra	USBDriverService1
	btfsc	UIE, ACTVIE
	rcall	USBWakeFromSuspend
;
USBDriverService1
	btfsc	UCON, SUSPND		; Are we suspended?
	return				; Pointless to continue servicing if the device is in suspend mode.
;
; Task B: Service USB Bus Reset Interrupt.
; When bus reset is received during suspend, ACTVIF will be set first,
; once the UCONbits.SUSPND is clear, then the URSTIF bit will be asserted.
; This is why URSTIF is checked after ACTVIF.
;
; The USB reset flag is masked when the USB state is in
; DETACHED_STATE or ATTACHED_STATE, and therefore cannot
; cause a USB reset event during these two states.
	btfss	UIR, URSTIF        ; USB Bus Reset Interrupt?
	bra	USBDriverService2
	btfsc	UIE, URSTIE
	rcall	USBProtocolResetHandler
;
; Task C: Check & service other USB interrupts
USBDriverService2
	btfss	UIR, IDLEIF
	bra	USBDriverService3
	btfsc	UIE, IDLEIE
	rcall	USBSuspend
USBDriverService3
	btfss	UIR, SOFIF
	bra	USBDriverService4
	btfsc	UIE, SOFIE
	rcall	USB_SOF_Handler
USBDriverService4
	btfss	UIR, STALLIF
	bra	USBDriverService5
	btfsc	UIE, STALLIE
	rcall	USBStallHandler
USBDriverService5
	btfss	UIR, UERRIF
	bra	USBDriverService6
	btfsc	UIE, UERRIE
	rcall	USBErrorHandler
;
; Pointless to continue servicing if the host has not sent a bus reset.
; Once bus reset is received, the device transitions into the DEFAULT
;     * state and is ready for communication.
USBDriverService6
	movlw	DEFAULT_STATE
	subwf	usb_device_state, W
	bnc	USBDriverServiceExit
;
; Task D: Servicing USB Transaction Complete Interrupt
	btfss	UIR, TRNIF
	bra	USBDriverServiceExit
	btfss	UIE, TRNIE
	bra	USBDriverServiceExit

#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
; Add USBwatch activity reporting over hardware serial port

;  If here, a new USB transaction has occurred, so report on it
  rcall  UsbwNewTransaction

; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif

;
; USBCtrlEPService only services transactions over EP0.
; It ignores all other EP transactions.
	rcall	USBCtrlEPService
; Other EPs can be serviced later by responsible device class firmware.
; Each device driver knows when an OUT or IN transaction is ready by
; checking the buffer ownership bit.
; An OUT EP should always be owned by SIE until the data is ready.
; An IN EP should always be owned by CPU until the data is ready.
;
; Because of this logic, it is not necessary to save the USTAT value
; of non-EP0 transactions.
	bcf	UIR, TRNIF
USBDriverServiceExit
	return


; From usbdrv.c line 301
;/******************************************************************************
; * Function:        void USBSuspend(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:
; *
; * Note:            None
; *****************************************************************************/
USBSuspend
; NOTE: Do not clear UIRbits.ACTVIF here!
; Reason:
; ACTVIF is only generated once an IDLEIF has been generated.
; This is a 1:1 ratio interrupt generation.
; For every IDLEIF, there will be only one ACTVIF regardless of
; the number of subsequent bus transitions.
;
; If the ACTIF is cleared here, a problem could occur when:
; [       IDLE       ][bus activity ->
; <--- 3 ms ----->     ^
;                ^     ACTVIF=1
;                IDLEIF=1
;  #           #           #           #   (#=Program polling flags)
;                          ^
;                          This polling loop will see both
;                          IDLEIF=1 and ACTVIF=1.
;                          However, the program services IDLEIF first
;                          because ACTIVIE=0.
;                          If this routine clears the only ACTIVIF,
;                          then it can never get out of the suspend
;                          mode.
	bsf	UIE, ACTVIE		; Enable bus activity interrupt
	bcf	UIR, IDLEIF
	bsf	UCON, SUSPND		; Put USB module in power conserve
; At this point the PIC can go into sleep,idle, or
; switch to a slower clock, etc.
	return


; From usbdrv.c line 353
;/******************************************************************************
; * Function:        void USBWakeFromSuspend(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:
; *
; * Note:            None
; *****************************************************************************/
USBWakeFromSuspend
; If using clock switching, this is the place to restore the
; original clock frequency.
	bcf	UCON, SUSPND
	bcf	UIE, ACTVIE
	bcf	UIR, ACTVIF
	return


; From usbdrv.c line 402
;/******************************************************************************
; * Function:        void USBRemoteWakeup(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This function should be called by user when the device
; *                  is waken up by an external stimulus other than ACTIVIF.
; *                  Please read the note below to understand the limitations.
; *
; * Note:            The modifiable section in this routine should be changed
; *                  to meet the application needs. Current implementation
; *                  temporary blocks other functions from executing for a
; *                  period of 1-13 ms depending on the core frequency.
; *
; *                  According to USB 2.0 specification section 7.1.7.7,
; *                  "The remote wakeup device must hold the resume signaling
; *                  for at lest 1 ms but for no more than 15 ms."
; *                  The idea here is to use a delay counter loop, using a
; *                  common value that would work over a wide range of core
; *                  frequencies.
; *                  That value selected is 1800. See table below:
; *                  ==========================================================
; *                  Core Freq(MHz)      MIP         RESUME Signal Period (ms)
; *                  ==========================================================
; *                      48              12          1.05
; *                       4              1           12.6
; *                  ==========================================================
; *                  * These timing could be incorrect when using code
; *                    optimization or extended instruction mode,
; *                    or when having other interrupts enabled.
; *                    Make sure to verify using the MPLAB SIM's Stopwatch
; *****************************************************************************/
USBRemoteWakeup
	movlb	high 0x400		; Point to proper bank
	btfss	usb_stat, RemoteWakeup	; Check if RemoteWakeup function has been enabled by the host.
	return				; No
	rcall	USBWakeFromSuspend	; Unsuspend USB modue
	bsf	UCON, RESUME		; Start RESUME signaling
	movlw	0x10			; Set RESUME line for 1-13 ms
	movwf	FSR2H			; Using FSR2 as temp
	clrf	FSR2L
USBRemoteWakeupLoop
	decfsz	FSR2L, F
	bra	USBRemoteWakeupLoop
	decfsz	FSR2H, F
	bra	USBRemoteWakeupLoop
	bcf	UCON, RESUME
	return


; From usbdrv.c line 443
;/******************************************************************************
; * Function:        void USB_SOF_Handler(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        The USB host sends out a SOF packet to full-speed devices
; *                  every 1 ms. This interrupt may be useful for isochronous
; *                  pipes. End designers should implement callback routine
; *                  as necessary.
; *
; * Note:            None
; *****************************************************************************/
USB_SOF_Handler
; Callback routine here
	bcf UIR, SOFIF
	return


; From usbdrv.c line 486
;/******************************************************************************
; * Function:        void USBStallHandler(void)
; *
; * PreCondition:    A STALL packet is sent to the host by the SIE.
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        The STALLIF is set anytime the SIE sends out a STALL
; *                  packet regardless of which endpoint causes it.
; *                  A Setup transaction overrides the STALL function. A stalled
; *                  endpoint stops stalling once it receives a setup packet.
; *                  In this case, the SIE will accepts the Setup packet and
; *                  set the TRNIF flag to notify the firmware. STALL function
; *                  for that particular endpoint pipe will be automatically
; *                  disabled (direction specific).
; *
; *                  There are a few reasons for an endpoint to be stalled.
; *                  1. When a non-supported USB request is received.
; *                     Example: GET_DESCRIPTOR(DEVICE_QUALIFIER)
; *                  2. When an endpoint is currently halted.
; *                  3. When the device class specifies that an endpoint must
; *                     stall in response to a specific event.
; *                     Example: Mass Storage Device Class
; *                              If the CBW is not valid, the device shall
; *                              STALL the Bulk-In pipe.
; *                              See USB Mass Storage Class Bulk-only Transport
; *                              Specification for more details.
; *
; * Note:            UEPn.EPSTALL can be scanned to see which endpoint causes
; *                  the stall event.
; *                  If
; *****************************************************************************/
USBStallHandler
; Does not really have to do anything here,
; even for the control endpoint.
; All BDs of Endpoint 0 are owned by SIE right now,
; but once a Setup Transaction is received, the ownership
; for EP0_OUT will be returned to CPU.
; When the Setup Transaction is serviced, the ownership
; for EP0_IN will then be forced back to CPU by firmware.
;
; NOTE: Above description is not quite true at this point.
;       It seems the SIE never returns the UOWN bit to CPU,
;       and a TRNIF is never generated upon successful
;       reception of a SETUP transaction.
;       Firmware work-around is implemented below.
;
	btfsc	UEP0, EPSTALL
	rcall	USBPrepareForNextSetupTrf	; Firmware Work-Around
	bcf	UEP0, EPSTALL
	bcf	UIR, STALLIF
	return

; From usbdrv.c line 528
;/******************************************************************************
; * Function:        void USBErrorHandler(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        The purpose of this interrupt is mainly for debugging
; *                  during development. Check UEIR to see which error causes
; *                  the interrupt.
; *
; * Note:            None
; *****************************************************************************/
USBErrorHandler
	bcf	UIR, UERRIF
	return


; From usbdrv.c line 555
;/******************************************************************************
; * Function:        void USBProtocolResetHandler(void)
; *
; * PreCondition:    A USB bus reset is received from the host.
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    Currently, this routine flushes any pending USB
; *                  transactions. It empties out the USTAT FIFO. This action
; *                  might not be desirable in some applications.
; *
; * Overview:        Once a USB bus reset is received from the host, this
; *                  routine should be called. It resets the device address to
; *                  zero, disables all non-EP0 endpoints, initializes EP0 to
; *                  be ready for default communication, clears all USB
; *                  interrupt flags, unmasks applicable USB interrupts, and
; *                  reinitializes internal state-machine variables.
; *
; * Note:            None
; *****************************************************************************/
USBProtocolResetHandler
;	movlb	high 0x400		; Point to proper bank
	clrf	UEIR			; Clear all USB error flags
	clrf	UIR			; Clears all USB interrupts
	movlw	0x9f			; Unmask all USB error interrupts
	movwf	UEIE
	movlw	0x7b			; Enable all interrupts except ACTVIE
	movwf	UIE
	clrf	UADDR			; Reset to default address
	lfsr	2, UEP1			; Reset all non-EP0 UEPn registers
	movlw	15
USBProtocolResetHandlerClearLoop
	clrf	POSTINC2
	decfsz	WREG, F
	bra	USBProtocolResetHandlerClearLoop
	movlw	EP_CTRL|HSHK_EN		; Init EP0 as a Ctrl EP
	movwf	UEP0
	btfsc	UIR, TRNIF		; Flush any pending transactions
USBProtocolResetHandlerFlushLoop
	bcf	UIR, TRNIF
	btfsc	UIR, TRNIF
	bra	USBProtocolResetHandlerFlushLoop
	bcf	UCON, PKTDIS		; Make sure packet processing is enabled
  	rcall	USBPrepareForNextSetupTrf
	bcf	usb_stat, RemoteWakeup	; Default status flag to disable
	clrf	usb_active_cfg		; Clear active configuration
	movlw	DEFAULT_STATE
  movwf	usb_device_state

#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
; Add USBwatch activity reporting over hardware serial port
; (3)
    movlw   USBW_DEFAULT_STATE
    movwf	  USBWstate
    call   UsbwSendState
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif

	return



#ifdef USB_USE_HID

; From hid.c  line 72
;/******************************************************************************
; * Function:        void USBCheckHIDRequest(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine checks the setup data packet to see if it
; *                  knows how to handle it
; *
; * Note:            HIDmaker version, enhanced to be able to handle multiple
; *                  Report Descriptors by reading tables in generated file
; *                  Descript.asm
; *****************************************************************************/
USBCheckHIDRequest
	movlb	high 0x400		; Point to proper bank
	movf	SetupPkt, W		; Recipient = RCPT_INTF?
	andlw	0x1f			; Mask to lower 5 bits
	sublw	RCPT_INTF
	bz	USBCheckHIDRequest01	; Yes
USBCheckHIDRequestExit
	return				; No: exit without setting session owner,
                                        ; which causes peripheral to STALL, signalling
                                        ; that this request is not supported

USBCheckHIDRequest01
;
; There are two standard requests that hid.c may support.
; 1. GET_DSC(DSC_HID,DSC_RPT,DSC_PHY);
; 2. SET_DSC(DSC_HID,DSC_RPT,DSC_PHY);
;
	movlw	GET_DSC			; Request = GET_DSC?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckHIDRequestClass	; No
	movlw	DSC_HID			; DscType = DSC_HID?
	cpfseq	SetupPkt + bDscType
	bra	USBCheckHIDRequest1	; No
	mSetSourcePointer HID0
	mGetRomTableCount		; Set wCount
	bsf	usb_stat, ctrl_trf_mem	; Indicate ROM
	bra	USBHIDSetSessionOwner
USBCheckHIDRequest1
	movlw	DSC_RPT			; DscType = DSC_RPT?
	cpfseq	SetupPkt + bDscType
	bra	USBCheckHIDRequest2	; No
; Set up to return the requested Report Descriptor
;
; New code: table driven
; First, choose correct table based on which Configuration we are in
; See which Configuration we have to initialize: some projects may have 2 Configurations
	clrf	usb_temp		; Start with RD table entry no. 0
  movlw   2                       ; Config no. 2?
  cpfseq  usb_active_cfg
  bra     SetC1_RDTable              ; No
; Set up for Config 2
	movlw	low C2_RD_Table	; Point to C2_RDTable in DESCRIPT.ASM
	movwf	TBLPTRL
	movlw	high C2_RD_Table
        bra     CheckRDT_NumEntries
SetC1_RDTable
	movlw	low C1_RD_Table	; Point to C1RDTable in DESCRIPT.ASM
	movwf	TBLPTRL
	movlw	high C1_RD_Table
CheckRDT_NumEntries
	movwf	TBLPTRH
	clrf	TBLPTRU
	tblrd	*+			; Read number of entries
	movff	TABLAT, usb_temp + 1	; Save it somewhere
	tblrd	*+			; Skip next location
  movf     usb_temp + 1, W            ; Does this Config even HAVE any entries?
  btfsc    STATUS, Z
  bra     USBCheckHIDRequestExit  ; No, exit and send a STALL
FindRDEntryLoop
	tblrd	*+			; Read Interface number of this entry
  movf    TABLAT, W
;  subwf   SetupPkt + bIntfID      ; Is it the Interface we are after?
  subwf   (SetupPkt + bIntfID),W      ; Is it the Interface we are after?
  bz      FoundRightIntfEntry     ; Yes, process it
; No, bump table pointer to next entry, if there is one
  dcfsnz  usb_temp + 1
  bra     USBCheckHIDRequestExit  ; Entry not found, so exit and send a STALL
	tblrd	*+			; Advance past RETLW opcode
	tblrd	*+			; Skip next location: low RD_size
	tblrd	*+			; Skip next location: RETLW opcode
	tblrd	*+			; Skip next location: high RD_size
	tblrd	*+			; Skip next location: RETLW opcode
	tblrd	*+			; Skip next location: low RD_Address
	tblrd	*+			; Skip next location: RETLW opcode
	tblrd	*+			; Skip next location: low RD_Address
	tblrd	*+			; Skip next location: RETLW opcode
        bra     FindRDEntryLoop
FoundRightIntfEntry
	tblrd	*+			; Advance past RETLW opcode
	tblrd	*+			; Read low RD_size
	movff	TABLAT, wCount
	tblrd	*+			; Skip RETLW opcode
	tblrd	*+			; Read high RD_size
	movff	TABLAT, wCount + 1
	tblrd	*+			; Skip RETLW opcode
	tblrd	*+			; Read low RD_Address
	movff	TABLAT, pSrc
	tblrd	*+			; Skip RETLW opcode
	tblrd	*+			; Read high RD_Address
	movff	TABLAT, pSrc + 1
	bsf	usb_stat, ctrl_trf_mem	; Indicate ROM
	bra	USBHIDSetSessionOwner   ; Go here to indicate the USB request has succeeded


USBCheckHIDRequest2
;	movlw	DSC_PHY			; DscType = DSC_PHY?
;	cpfseq	SetupPkt + bDscType
;	return				; No
USBCheckHIDRequestClass
	movf	SetupPkt, W		; RequestType = CLASS?
	andlw	0x60			; Mask to proper bits
	sublw	(CLASS) << 5
	bnz	USBCheckHIDRequestExit	; No

#ifdef  HID_SUPPORT_GET_SET_REPORT
; Added for HIDmaker
	movlw	SET_REPORT		; Request = SET_REPORT?
	subwf	SetupPkt + bRequest, W
	bz	HIDSetReportHandler	; Yes
	movlw	GET_REPORT		; Request = GET_REPORT?
	subwf	SetupPkt + bRequest, W
	bz	HIDGetReportHandler	; Yes
#endif

	movlw	GET_IDLE		; Request = GET_IDLE?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckHIDRequestClass1	; No
	mSetSourcePointer HLL_IdleRate
	movlw	1
	movwf	wCount
	clrf	wCount + 1
	bcf	usb_stat, ctrl_trf_mem	; Indicate RAM
	bra	USBHIDSetSessionOwner
USBCheckHIDRequestClass1
	movlw	SET_IDLE		; Request = SET_IDLE?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckHIDRequestClass2	; No
	movff	SetupPkt + wValueHi, HLL_IdleRate   ; Copy to vars in PBP prog
	bra	USBHIDSetSessionOwner
USBCheckHIDRequestClass2
	movlw	GET_PROTOCOL		; Request = GET_PROTOCOL?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckHIDRequestClass3	; No
	mSetSourcePointer HLL_ActiveProtocol
	movlw	1
	movwf	wCount
	clrf	wCount + 1
	bcf	usb_stat, ctrl_trf_mem	; Indicate RAM
	bra	USBHIDSetSessionOwner
USBCheckHIDRequestClass3
	movlw	SET_PROTOCOL		; Request = SET_PROTOCOL?
	cpfseq	SetupPkt + bRequest
	return				; No
	movff	SetupPkt + wValue, HLL_ActiveProtocol   ; Copy to vars in PBP prog
USBHIDSetSessionOwner
	movlw	MUID_HID
	movwf	ctrl_trf_session_owner
	return

#ifdef  HID_SUPPORT_GET_SET_REPORT

; Handle a SET_REPORT request by setting some variables, that will be used
; at the next OUT transaction.
HIDSetReportHandler
        setf    SetRptInProgress
        setf    FirstPacket
        movff   SetupPkt + bReportID, RptID
        movff   SetupPkt + bReportType, RptType
        movff   SetupPkt + bIntfID, RptInterfaceNum
        movff   usb_active_cfg, RptConfigNum
; We may need to do something here, to enable the OUT transaction. Not sure...
	bra	USBHIDSetSessionOwner

; Handle a GET_REPORT request by setting some variables, and then calling
; a PBP routine to pack the first packet of data
HIDGetReportHandler
        movff   SetupPkt + bReportID, RptID
        movff   SetupPkt + bReportType, RptType
        movff   SetupPkt + bIntfID, RptInterfaceNum
        movff   usb_active_cfg, RptConfigNum
        setf    GetRptInProgress
        setf    FirstPacket
;
	bra	USBHIDSetSessionOwner

#endif


#endif	; USB_USE_HID



#ifdef USB_USE_CDC

;/******************************************************************************
; * Function:        void USBCheckCDCRequest(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        This routine checks the setup data packet to see if it
; *                  knows how to handle it
; *
; * Note:            None
; *****************************************************************************/
USBCheckCDCRequest
;    /*
;     * If request recipient is not an interface then return
;     */
	movlb	high 0x400		; Point to proper bank
	movf	SetupPkt, W		; Recipient = RCPT_INTF?
	andlw	0x1f			; Mask to lower 5 bits
	sublw	RCPT_INTF
	bnz	USBCheckCDCRequestExit	; No

;    /*
;     * If request type is not class-specific then return
;     */
	movf	SetupPkt, W		; RequestType = CLASS?
	andlw	0x60			; Mask to proper bits
	sublw	(CLASS) << 5
	bnz	USBCheckCDCRequestExit	; No

;    /*
;     * Interface ID must match interface numbers associated with
;     * CDC class, else return
;     */
	movlw	CDC_COMM_INTF_ID	; IntfID = CDC_COMM_INTF_ID?
	subwf	SetupPkt + bIntfID, W
	bz	USBCheckCDCRequest1	; Yes
	movlw	CDC_DATA_INTF_ID	; IntfID = CDC_DATA_INTF_ID?
	cpfseq	SetupPkt + bIntfID
USBCheckCDCRequestExit
	return				; No

USBCheckCDCRequest1
	movlw	SEND_ENCAPSULATED_COMMAND	; Request = SEND_ENCAPSULATED_COMMAND?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckCDCRequest2	; No
	mSetSourcePointer dummy_encapsulated_cmd_response
	bcf	usb_stat, ctrl_trf_mem	; Indicate RAM
	movlw	dummy_length
	movwf	wCount
	clrf	wCount + 1
	bra	USBCDCSetSessionOwner
USBCheckCDCRequest2
	movlw	GET_ENCAPSULATED_RESPONSE	; Request = GET_ENCAPSULATED_RESPONSE?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckCDCRequest3	; No
;       // Populate dummy_encapsulated_cmd_response first.
	mSetDestinationPointer dummy_encapsulated_cmd_response
	bra	USBCDCSetSessionOwner
USBCheckCDCRequest3
	movlw	SET_COMM_FEATURE	; Request = SET_COMM_FEATURE?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckCDCRequest4	; No
	return				; Optional
USBCheckCDCRequest4
	movlw	GET_COMM_FEATURE	; Request = GET_COMM_FEATURE?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckCDCRequest5	; No
	return				; Optional
USBCheckCDCRequest5
	movlw	CLEAR_COMM_FEATURE	; Request = CLEAR_COMM_FEATURE?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckCDCRequest6	; No
	return				; Optional
USBCheckCDCRequest6
	movlw	SET_LINE_CODING		; Request = SET_LINE_CODING?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckCDCRequest7	; No
	mSetDestinationPointer line_coding
	bra	USBCDCSetSessionOwner
USBCheckCDCRequest7
	movlw	GET_LINE_CODING		; Request = GET_LINE_CODING?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckCDCRequest8	; No
	; Abstract line coding information
	movlw	low 115200		; baud rate
	movwf	line_coding + dwDTERate
	movlw	high 115200
	movwf	line_coding + dwDTERate + 1
	movlw	upper 115200
	movwf	line_coding + dwDTERate + 2
	clrf	line_coding + dwDTERate + 3
	clrf	line_coding + bCharFormat	; 1 stop bit
	clrf	line_coding + bParityType	; None
	movlw	8
	movwf	line_coding + bDataBits	; 5,6,7,8, or 16
	mSetSourcePointer line_coding
	bcf	usb_stat, ctrl_trf_mem	; Indicate RAM
	movlw	LINE_CODING_LENGTH
	movwf	wCount
	clrf	wCount + 1
	bra	USBCDCSetSessionOwner
USBCheckCDCRequest8
	movlw	SET_CONTROL_LINE_STATE	; Request = SET_CONTROL_LINE_STATE?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckCDCRequest9	; No
	movff	SetupPkt + wValue, control_signal_bitmap
	bra	USBCDCSetSessionOwner
USBCheckCDCRequest9
	movlw	SEND_BREAK		; Request = SEND_BREAK?
	cpfseq	SetupPkt + bRequest
	bra	USBCheckCDCRequest10	; No
	return				; Optional
USBCheckCDCRequest10
	return				; Default
USBCDCSetSessionOwner
	movlw	MUID_CDC
	movwf	ctrl_trf_session_owner
	return


;/******************************************************************************
; * Function:        void CDCInitEP(void)
; *
; * PreCondition:    None
; *
; * Input:           None
; *
; * Output:          None
; *
; * Side Effects:    None
; *
; * Overview:        CDCInitEP initializes CDC endpoints, buffer descriptors,
; *                  internal state-machine, and variables.
; *                  It should be called after the USB host has sent out a
; *                  SET_CONFIGURATION request.
; *                  See USBStdSetCfgHandler() in usb9.c for examples.
; *
; * Note:            None
; *****************************************************************************/
;CDCInitEP
;	movlw	2			; Endpoint 2 In
;	movwf	FSR0L
;	lfsr	1, cdc_notice		; FSR1 = endpoint buffer address
;	movlw	CDC_INT_EP_SIZE		; W = endpoint size
;	rcall	InitEPIn		; Inititalize the endpoint

;	movlw	3			; Endpoint 3
;	movwf	FSR0L
;	lfsr	1, cdc_data_rx		; FSR1 = endpoint buffer address
;	movlw	CDC_BULK_OUT_EP_SIZE	; W = endpoint size
;	rcall	InitEPOut		; Inititalize the endpoint

;	movlw	3			; Endpoint 3 In
;	movwf	FSR0L
;	lfsr	1, cdc_data_tx		; FSR1 = endpoint buffer address
;	movlw	CDC_BULK_IN_EP_SIZE	; W = endpoint size
;	bra	InitEPIn		; Inititalize the endpoint

#endif	; USB_USE_CDC


; Generic code for use by all the classes

; InitEPIn
;  Generic initialize In endpoint
; Input:
;  FSR0L is endpoint number
;  FSR1 is endpoint buffer address
;  W is endpoint buffer size
; Returns:
;  Nada
; Uses
;  FSR0 is BDT pointer
;  FSR1 is endpoint buffer pointer
;  FSR2 is endpoint table pointer

InitEPIn
; Save maximum count at front of endpoint buffer and move buffer pointer up (no need to put in Cnt for In)
	movwf	POSTINC1		; Store maximum count at front of endpoint buffer and move up pointer

; Need to zero the in-process flag at buffer address + MaxCount + 4
  addlw 4
  clrf  PLUSW1

; Point FSR2 to endpoint table
	lfsr	2, UEP0
	movf	FSR0L, W		; Add in endpoint number
	addwf	FSR2L, F

; Enable In endpoint
	movlw	EP_IN|HSHK_EN		; Enable In pipe
	iorwf	INDF2, F

; Point FSR0 to endpoint BDT
	rlncf	FSR0L, W		; Endpoint number * 8
	rlncf	WREG, F
	rlncf	WREG, F
	lfsr	0, ep0Bi		; Point FSR0 to beginning of BDT area
	addwf	FSR0L, F		; Add endpoint offset to FSR0 (can't overflow to FSR0H)

; Set endpoint buffer address from FSR1
	movlw	ADRL			; Point to ADRL
	movff	FSR1L, PLUSW0
	movlw	ADRH			; Point to ADRH
	movff	FSR1H, PLUSW0

; Set endpoint status
	movlw	_UCPU|_DAT1		; Set transmit status
	movwf	INDF0			; Set Stat
	return


; InitEPOut
;  Generic initialize Out endpoint
; Input:
;  FSR0L is endpoint number
;  FSR1 is endpoint buffer address
;  W is endpoint buffer size
; Returns:
;  Nada
; Uses
;  FSR0 is BDT pointer
;  FSR1 is endpoint buffer pointer
;  FSR2 is endpoint table pointer

InitEPOut
; Save maximum count at front of endpoint buffer and move buffer pointer up
	movwf	POSTINC1		; Store maximum count at front of endpoint buffer and move up pointer

; Need to zero the in-process flag at buffer address + MaxCount + 4
  addlw 4
  clrf  PLUSW1

; Point FSR2 to endpoint table
	lfsr	2, UEP0
	movf	FSR0L, W		; Add in endpoint number
	addwf	FSR2L, F

; Enable Out endpoint
	movlw	EP_OUT|HSHK_EN		; Enable Out pipe
	iorwf	INDF2, F

; Point FSR0 to endpoint BDT
	rlncf	FSR0L, W		; Endpoint number * 8
	rlncf	WREG, F
	rlncf	WREG, F
	lfsr	0, ep0Bo		; Point FSR0 to beginning of BDT area
	addwf	FSR0L, F		; Add endpoint offset to FSR0 (can't overflow to FSR0H)

; Set endpoint buffer address from FSR1 + 1
	movlw	ADRL			; Point to ADRL
	movff	FSR1L, PLUSW0
	movlw	ADRH			; Point to ADRH
	movff	FSR1H, PLUSW0

; Set Cnt to maximum count
	movf	POSTDEC1, W		; Back up endpoint buffer pointer (no PREDEC1!)
	incf	FSR0L, F		; Point to Cnt
	movff	INDF1, POSTDEC0		; Set maximum count and point back to Stat

; Set endpoint status
	movlw	_USIE|_DAT0|_DTSEN	; Set receive status
	movwf	INDF0			; Set Stat
	return


;/******************************************************************************
; * Function:        PutUSB
; *
; * PreCondition:    None
; *
; * Input:           FSR0L is endpoint number
; *                  FSR1 is source buffer pointer
; *                  W is count
; *
; * Output:          FSR1 is updated source buffer pointer
; *                  W returns number sent
; *                  Carry is clear for buffer not available
; *
; * Uses:            FSR0 is BDT pointer
; *                  FSR1 is source buffer pointer
; *                  FSR2 is endpoint buffer pointer
; *                  R0 in BANKA is temporary length storage
; *
; * Side Effects:    
; *
; * Overview:        Generic fill In endpoint for TX
; *
; * Note:            None
; *****************************************************************************/
; PutUSB
;  Generic fill In endpoint for TX
; Input:
;  FSR0L is endpoint number
;  FSR1 is source buffer pointer
;  W is count
; Returns:
;  FSR1 is updated source buffer pointer
;  W returns number sent
;  Carry is clear for buffer not available
; Uses:
;  FSR0 is BDT pointer
;  FSR1 is source buffer pointer
;  FSR2 is endpoint buffer pointer
;  R0 in BANKA is temporary length storage

PutUSB
	movwf	R0			; Save count

; Check to see if we're configured
	movlb	high 0x400		; Point to proper bank
	movlw	CONFIGURED_STATE	; We might not be configured yet
	subwf	usb_device_state, W
	movlw	0			; 0 characters sent, so far
	bcf	STATUS, C		; Clear Carry for possible error return
	bnz	PutUSBNotReady		; We're not configured

; Point FSR0 to requested endpoint In BDT
	rlncf	FSR0L, W		; Endpoint number * 8
	rlncf	WREG, F
	rlncf	WREG, F
	lfsr	0, ep0Bi		; Point FSR0 to beginning of BDT area
	addwf	FSR0L, F		; Add endpoint offset to FSR0 (can't overflow to FSR0H)

	clrf	WREG			; 0 characters sent, so far
	bcf	STATUS, C		; Clear Carry for possible error return
	btfsc	INDF0, UOWN		; Who owns the buffer (Stat, UOWN)?
PutUSBNotReady
	return				; Busy (we don't)

; Get endpoint buffer address to FSR2
	movlw	ADRL			; Point to ADRL
	movff	PLUSW0, FSR2L
	movlw	ADRH			; Point to ADRH
	movff	PLUSW0, FSR2H

	movlw	-1
	movf	PLUSW2, W		; Get maximum length from in front of endpoint buffer

	cpfslt	R0			; Find number of bytes to send this time
	movwf	R0			; Too big - send maximum allowed length

	incf	FSR0L, F		; Point to Cnt
	movf	R0, W			; Get number to send
	movwf	POSTDEC0		; Put length into Cnt and point back to Stat
	bz	PutUSBZero		; Zero to send

PutUSBRamLoop
	movff	POSTINC1, POSTINC2	; Copy source buffer to endpoint buffer
	decfsz	WREG, F			; Count down number of bytes to transfer
	bra	PutUSBRamLoop

PutUSBZero
	movlw	_DTSMASK		; Save only DTS bit
	andwf	INDF0, F
	btg	INDF0, DTS		; Toggle DTS bit
	movlw	_USIE|_DTSEN		; Turn ownership to SIE
	iorwf	INDF0, F
	movf	R0, W			; Return number of bytes sent
	bsf	STATUS, C		; Set Carry for non-error return
	return


;/******************************************************************************
; * Function:        GetUSB
; *
; * PreCondition:    None
; *
; * Input:           FSR0L is endpoint number
; *                  FSR1 is destination buffer pointer
; *                  W is max buffer length
; *
; * Output:          FSR1 is updated destination buffer pointer
; *                  W returns number received
; *                  Carry is clear for buffer not available
; *
; * Uses:            FSR0 is BDT pointer
; *                  FSR1 is destination buffer pointer
; *                  FSR2 is endpoint buffer pointer
; *                  R0 in BANKA is temporary length storage
; *
; * Side Effects:    
; *
; * Overview:        Generic get from Out endpoint for RX
; *
; * Note:            None
; *****************************************************************************/
; GetUSB
;  Generic get from Out endpoint for RX
; Input:
;  FSR0L is endpoint number
;  FSR1 is destination buffer pointer
;  W is max buffer length
; Returns:
;  FSR1 is updated destination buffer pointer
;  W returns number received
;  Carry is clear for buffer not available
; Uses
;  FSR0 is BDT pointer
;  FSR1 is destination buffer pointer
;  FSR2 is endpoint buffer pointer
;  R0 in BANKA is temporary length storage

GetUSB
	movwf	R0			; Save max buffer length

; Check to see if we're configured
	movlb	high 0x400		; Point to proper bank
	movlw	CONFIGURED_STATE	; We might not be configured yet
	subwf	usb_device_state, W
	movlw	0			; 0 characters sent, so far
	bcf	STATUS, C		; Clear Carry for possible error return
	bnz	GetUSBNotReady		; We're not configured

; Point FSR0 to requested endpoint Out BDT
	rlncf	FSR0L, W		; Endpoint number * 8
	rlncf	WREG, F
	rlncf	WREG, F
	lfsr	0, ep0Bo		; Point FSR0 to beginning of BDT area
	addwf	FSR0L, F		; Add endpoint offset to FSR0 (can't overflow to FSR0H)

	clrf	WREG			; 0 characters received, so far
	bcf	STATUS, C		; Clear Carry for possible error return
	btfsc	INDF0, UOWN		; Who owns the buffer (Stat, UOWN)?
GetUSBNotReady
	return				; Busy (we don't)

; Get endpoint buffer address to FSR2
	movlw	ADRL			; Point to ADRL
	movff	PLUSW0, FSR2L
	movlw	ADRH			; Point to ADRH
	movff	PLUSW0, FSR2H

	movf	PREINC0, W		; Get Cnt
	cpfslt	R0			; Make sure it's not longer than the buffer
	movwf	R0			; It's OK, save returned length

	movlw	-1
	movf	PLUSW2, W		; Get maximum length from in front of endpoint buffer
	movwf	POSTDEC0		; Reset max length and point back to Stat

	movf	R0, W			; Get count to W
	bz	GetUSBZero		; Nothing received

GetUSBRamLoop
	movff	POSTINC2, POSTINC1	; Copy endpoint buffer to destination buffer
	decfsz	WREG, F			; Count down number of bytes
	bra	GetUSBRamLoop

GetUSBZero
	movlw	_DTSMASK		; Save only DTS bit
	andwf	INDF0, F
	btg	INDF0, DTS		; Toggle DTS bit
	movlw	_USIE|_DTSEN		; Turn ownership to SIE
	iorwf	INDF0, F
	movf	R0, W			; Return number of bytes received
	bsf	STATUS, C		; Set Carry for non-error return
	return


;/******************************************************************************
; * Function:        PackandShipPacket
; *
; * PreCondition:    In-process flag, located at EPnbuffer + <buffer size> + 5,
; *                  must be initialized to 0
; *
; * Input:           W contains EndPoint number
; *                  TBLPTRH/L is VarTable address
; *
; * Output:          Returns W = 0 when Report is all packed,
; *                              0x02 when EP is busy, and
; *                              0xFF if there are still more packets to go
; *
; * Side Effects:    None
; *
; * Overview:        Pack packet with data from VarTable and send to EndPoint
; *
; * Note:            Jeff's fifth version, 2/28/2005
; *****************************************************************************/
; Pack packet with data from VarTable and send to EndPoint
; W contains EndPoint number and TBLPTRH/L is VarTable address
PackandShipPacket
	movlb	high 0x400	; Point to proper bank
	movwf	TempByte	; Save EndPoint number for the moment

; Check to see if we're configured
	movlw	CONFIGURED_STATE
	subwf	usb_device_state, W
	movlw	0x01		; We might not be configured yet
	bnz	NotReady	; We're not

; Point FSR0 to requested endpoint In BDT
	rlncf	TempByte, W	; Endpoint number * 8
	rlncf	WREG, W
	rlncf	WREG, W
	lfsr	0, ep0Bi	; Point FSR0 to beginning of BDT area
	addwf	FSR0L, F	; Add endpoint offset to FSR0 (can't overflow to FSR0H)

; Check for EndPoint busy
	movlw	0x02		; We might be busy
	btfsc	INDF0, UOWN	; Who owns the buffer (Stat, UOWN)?
NotReady
	return			; Busy (we don't)

; Get a few things ready for packing
	clrf	PacketByteIndex
	clrf	PacketBitIndex
	clrf	TBLPTRU		; Probably unnecessary

; Get packet size (need for PointToStorage, among other things)
	clrf	WREG		; Point FSR2 to beginning of packet
	rcall	PointToPacket
	movf	POSTDEC2, W	; Back up to right before packet
	movff	POSTINC2, MaxPacketSize	; Get packet size

; Check for first packet or in-process
	rcall	PointToStorage
	movf	POSTINC2, W	; Get last state
	bz	VarLoop		; If zero then first packet
; Check for ZLP???

; Packet in-process - recover last info
	movff	POSTINC2, TBLPTRL 	; Get pointer to VarTable
	movff	POSTINC2, TBLPTRH
	movff	POSTINC2, PacketByteIndex	; Get next byte pointer
	movff	POSTINC2, PacketBitIndex	; Get next bit pointer

	movf	MaxPacketSize, W	; Get packet size for end of packet buffer address
	rcall	PointToPacket	; Point to first old byte in packet
	movff	FSR2L, FSR1L	; Move source address to FSR1
	movff	FSR2H, FSR1H
	clrf	WREG		; Point FSR2 to beginning of packet
	rcall	PointToPacket

	movf	MaxPacketSize, W	; Find how many to move
	subwf	PacketByteIndex, W
	movwf	PacketByteIndex	; Save as new index while we're here
; Check for bad data???
InProcessLoop
	movff	POSTINC1, POSTINC2	; Move a byte
	decf	WREG, F		; Count through 0
	bc	InProcessLoop


; Get variable size and address
VarLoop
	tblrd*+			; Read VarTable
	movf	TABLAT, W
	bz	TheEnd		; At end of VarTable, send last packet
	movwf	VarSign		; Save for sign and single bit indicator
	andlw	0x3f		; Mask to size
	movwf	VarSize		; Save size in total bits
	andlw	0x07		; Mask to number of bits only
	movwf	VarBits
	rrncf	VarSize, W	; Shift down to bytes
	rrncf	WREG, W
	rrncf	WREG, W
	andlw	0x07		; Mask to number of bytes only
	movwf	VarBytes
	tstfsz	VarBits
	incf	VarBytes, F	; Adjust to actual bytes
	tblrd*+			; Read VarTable
	movf	TABLAT, W
	movwf	FSR1L		; Get address of variable to FSR1
	tblrd*+			; Read VarTable
	movf	TABLAT, W
	movwf	FSR1H

	btfsc	VarSign, 6	; Is it a single bit?
	bra	OneBit		; Yes

; Copy variable to packet
	movf	PacketByteIndex, W	; Get current byte position
	tstfsz	PacketBitIndex
	incf	WREG, W		; Bump to next location if bits not 0
	rcall	PointToPacket	; Set destination address

	movf	VarBytes, W	; How many to copy
copyvarloop
	movff	POSTINC1, POSTINC2	; Do the copy
	decfsz	WREG, F
	bra	copyvarloop

; Shift bits to the right to fill in any holes
	movf	PacketBitIndex, W
	bz	CalcNewIndexes	; No shift necessary
	sublw	8		; Calculate number of shifts necessary
	movwf	TempCount

; Point to beginning of shift area in packet
	movf	PacketByteIndex, W
	rcall	PointToPacket

; Clear any extra junk from current byte in packet
	movf	PacketBitIndex, W	; Find top bit number + 1
	rcall	GetMask		; Get mask to W (wrecks TempByte)
	andwf	INDF2, W	; Mask off any extra bits and get to W
	movwf	TempByte	; Save it for or later

	clrf	INDF2		; Start with nothing in byte 0
shiftloop
	movf	VarBytes, W	; W = number of bytes to shift and byte pointer
shiftloop1
	rrcf	PLUSW2, F	; Shift a byte one bit to the right
	decfsz	WREG, W
	bra	shiftloop1	; Shift all the bytes
	rrcf	PLUSW2, F	; Shift the 0th byte too
	decfsz	TempCount, F
	bra	shiftloop	; Shift all the bits

; Or original first byte into packet
	movf	TempByte, W	; Get first byte
	iorwf	INDF2, F	; Or it into packet

; Calculate new indexes
CalcNewIndexes
	movf	VarSize, W	; Get total bits in this variable
	addwf	PacketBitIndex, F	; Update bits
CalcNewIndexesOneBit
	rrcf	PacketBitIndex, W	; Shift to get to bytes
	rrcf	WREG, W
	rrcf	WREG, W
	andlw	0x07		; Mask to bytes
	addwf	PacketByteIndex, F
	movlw	0x07		; Mask to bits
	andwf	PacketBitIndex, F

; Does it fit in packet?  If not, we're done with this packet
	movf	MaxPacketSize, W
	subwf	PacketByteIndex, W
	bnc	VarLoop		; Go get next variable
	bnz	PacketFull
	movf	PacketBitIndex, W	; If Bit and Byte are zero, we want to get one more variable in here
    bnz PacketFull
    bra VarLoop 

; Packet full - with more to come
PacketFull
	rcall	SendPacket	; Make it gone
	rcall	PointToStorage
	setf	WREG		; More packets to come
	movwf	POSTINC2	; Save marker
	movff	TBLPTRL, POSTINC2	; Save pointer to VarTable
	movff	TBLPTRH, POSTINC2
	movff	PacketByteIndex, POSTINC2	; Save next byte pointer
	movff	PacketBitIndex, POSTINC2	; Save next bit pointer
	return			; W still set to 0xff


; Data is a single bit - handle special case
OneBit
	movff	VarBits, TempByte	; Get bit position in source
	rcall	ConvertBit	; Convert it to a single bit mask
	andwf	INDF1, W	; Mask to our bit
	movwf	VarBytes	; Save the result (don't need VarBytes for bits)

	movf	PacketByteIndex, W	; Get destination address to FSR2
	rcall	PointToPacket
	movff	PacketBitIndex, TempByte	; Get bit position in destination
	rcall	ConvertBit	; Convert it to a single bit mask
	iorwf	INDF2, F	; Put bit into destination
	xorlw	0xff		; Flip mask just in case
	movf	VarBytes, F	; Check source result
	btfsc	STATUS, Z	; Do we need to take it back out?
	andwf	INDF2, F	; Take bit out of destination

	incf	PacketBitIndex, F	; Add one to bits
	bra	CalcNewIndexesOneBit	; Finish updating indexes


; All variables packed
TheEnd
	rcall	SendPacket	; Make it gone
	rcall	PointToStorage
; Send ZLP if last byte???
	clrf	WREG		; This is the last packet
	movwf	POSTINC2	; Save marker
	return


; Send the finished packet
SendPacket
	movf	PacketByteIndex, W	; Set count
	tstfsz	PacketBitIndex	; Are we on the first bit?
	incf	WREG, W		; No - bump count
	cpfsgt	MaxPacketSize	; Bigger than max?
	movf	MaxPacketSize, W	; Yes - set to max
	incf	FSR0L, F	; Point to Cnt
	movwf	POSTDEC0	; Put length into Cnt and point back to Stat
; Fall through to ReleaseBuffer


; Common Pack / Unpack subroutines below
;=======================================

; Set IN or OUT EP buffer loose
ReleaseBuffer
	movlw	_DTSMASK	; Save only DTS bit
	andwf	INDF0, F
	btg	INDF0, DTS	; Toggle DTS bit
	movlw	_USIE|_DTSEN	; Turn ownership to SIE
	iorwf	INDF0, F
	return


; Point FSR2 to storage at end of Packet
PointToStorage
	movf	MaxPacketSize, W	; Get to end
	addlw	4		; Move past shift area
; Fall through to PointToPacket

; Point FSR2 to byte W in Packet
PointToPacket
	movwf	TempByte	; Save offset for a moment
; Get endpoint buffer address to FSR2
	movlw	ADRL		; Point to ADRL
	movff	PLUSW0, FSR2L
	movlw	ADRH		; Point to ADRH
	movff	PLUSW0, FSR2H
	movf	TempByte, W	; Retrieve offset
	addwf	FSR2L, F	; Add offset
	movlw	0
	addwfc	FSR2H, F
	return


; Create bit mask - W = top bit position + 1
GetMask
	clrf	TempByte	; Start with all 0s
GetMaskLoop
	bsf	STATUS, C	; Shift in 1s
	rlcf	TempByte, F
	decfsz	WREG, F
	bra	GetMaskLoop
	movf	TempByte, W
	return


; Convert a bit number in TempByte to a single bit mask in W
ConvertBit movlw 1		; Start with 1 for 0
	btfsc	TempByte, 0
	rlncf	WREG, F		; Times 2 for 1 or 3
	btfsc	TempByte, 1
	rlncf	WREG, F		; Times 4 for 2 or 3
	btfsc	TempByte, 1
	rlncf	WREG, F
	btfsc	TempByte, 2
	swapf	WREG, F		; Swap to top if 4 to 7
	return


;/******************************************************************************
; * Function:        UnPacket
; *
; * PreCondition:    In-process flag, located at EPnbuffer + <buffer size> + 5,
; *                  must be initialized to 0
; *
; * Input:           W contains EndPoint number
; *                  TBLPTRH/L is VarTable address
; *
; * Output:          Returns W = 0 when Report is all unpacked,
; *                              0x02 when EP is busy, and
; *                              0x04 when remainder of stuff to send has 0 length,
; *                              0xFF if there are still more packets to go
; *
; * Side Effects:    None
; *
; * Overview:        Unpack packet located in Endpoint buffer, using info from VarTable,
; *                  putting data into individual variables
; *
; * Note:
; *****************************************************************************/
; Unpack packet
; Unpack: W contains EndPoint number and TBLPTRH/L is VarTable address
UnPacket
	movlb	high 0x400	; Point to proper bank
	movwf	TempByte	; Save EndPoint number for the moment

; Check to see if we're configured
	movlw	CONFIGURED_STATE
	subwf	usb_device_state, W
	movlw	0x01		; We might not be configured yet
	bnz	UnPkNotReady	; We're not

; Point FSR0 to requested endpoint Out BDT
	rlncf	TempByte, W	; Endpoint number * 8
	rlncf	WREG, W
	rlncf	WREG, W
	lfsr	0, ep0Bo	; Point FSR0 to beginning of BDT area
	addwf	FSR0L, F	; Add endpoint offset to FSR0 (can't overflow to FSR0H)

; Check for EndPoint busy
	movlw	0x02		; We might be busy
	btfsc	INDF0, UOWN	; Who owns the buffer (Stat, UOWN)?
UnPkNotReady
	return			; Busy (we don't)

; Point to packet size
	clrf	WREG		; Point FSR2 to beginning of packet
	rcall	PointToPacket
	movf	POSTDEC2, W	; Back up to right before packet

; Get and reset Cnt
	incf	FSR0L, F	; Point to Cnt in BDT (Can't overflow to H)
	movff	INDF0, TempByte	; Save Cnt
	movf	INDF2, W	; Get max packet size
	movwf	MaxPacketSize	; Save max for storage lookup
	movwf	POSTDEC0	; Set Cnt to max packet size (for next time) and point back to Stat

; Check for Zero Length Packet
	tstfsz	TempByte	; Is it ZLP?
	bra	NotZLP		; No
	rcall	ReleaseBuffer	; ZLP
	movlw	0x04		; Tell caller to try again
	return			; Nothing there, try again later


; Get a few things ready for unpacking
NotZLP
	clrf	PacketByteIndex
	clrf	PacketBitIndex
	clrf	TBLPTRU		; Probably unnecessary

; Check for first packet or in-process
	rcall	PointToStorage
	movf	POSTINC2, W	; Check last state
	movwf	TempByte	; Update in-process indicator
	bz	UnpackLoop	; If zero then first packet


; Packet in-process - recover last info
	movff	POSTINC2, TBLPTRL 	; Get pointer to VarTable
	movff	POSTINC2, TBLPTRH
	movff	POSTINC2, PacketByteIndex	; Get next byte pointer
	movff	POSTINC2, PacketBitIndex	; Get next bit pointer


; Get variable size
UnpackLoop
	tblrd*+			; Read VarTable
	movf	TABLAT, W
	bnz UnpackLoop1
	bra	TheUnEnd	; At end of VarTable, we're done
UnpackLoop1
	movwf	VarSign		; Save for sign and single bit indicator
	andlw	0x3f		; Mask to size
	movwf	VarSize		; Save size in total bits
	andlw	0x07		; Mask to excess bits = (total bits) mod 8
	movwf	VarBits
	rrncf	VarSize, W	; Shift down total bits to bytes
	rrncf	WREG, W
	rrncf	WREG, W
	andlw	0x07		; Mask to number of whole bytes
	movwf	VarBytes
	tstfsz	VarBits
	incf	VarBytes, F	; Adjust to actual bytes needed to contain item

	movf	TempByte, W	; Check for in-process
	bz	CheckSize	; Not in-process, so continue with regular business

; In-Process here: a variable straddled a packet boundary, and we are resuming at next packet
; Now that we have the variable data, finish in-process tasks
	movf	PacketByteIndex, W	; Should be 1 or more for leftover data
	bz	CheckSize	; No leftover data from last packet (even packet)
	addwf	MaxPacketSize, W	; Point to first new byte location at end of packet
	rcall	PointToPacket
	movff	FSR2L, FSR1L	; Move destination to FSR1
	movff	FSR2H, FSR1H
	clrf	WREG		; Point FSR2 to beginning of packet
	rcall	PointToPacket

	movf	PacketByteIndex, W
	subwf	VarBytes, W
UnProcessLoop
	movff	POSTINC2, POSTINC1	; Move a byte
	decf	WREG, F		; Count through 0 to get 1 extra
	bc	UnProcessLoop

	negf	PacketByteIndex	; Negate current byte pointer so it will be correct for new index calculation

	movf	MaxPacketSize, W	; Point to shift or copy area
	rcall	PointToPacket

	movf	PacketBitIndex, W	; Are we on a byte boundary?
	bz	CopyToVar	; Yes - No shift necessary
	movwf	TempCount	; For shift later
	bra	UnPkShiftLoop


; Is entire variable in packet?
CheckSize
	movf	PacketByteIndex, W
	subwf	MaxPacketSize, W	; Result must be 1 or greater
	bz	SaveContext	; We're past the end: save part of item & wait for next packet w/ rest

	btfsc	VarSign, 6	; Is it a single bit?
	bra	UnOneBit	; Yes - it's got to fit so handle it

	rlcf	WREG, W		; Shift up for bit calculation
	rlcf	WREG, W
	bc	PlentyORoom	; If we rolled out a top bit there's plenty o' room
	rlcf	WREG, W
	bc	PlentyORoom	; If we rolled out a top bit there's plenty o' room
	andlw	0xf8		; Get rid of any junk that rolled in
	bsf	STATUS, C
	subfwb	PacketBitIndex, W	; W (remaining bytes * 3) - BitIndex - 0 (!C)
	subfwb	VarSize, W	; Is entire variable in packet? (C still set)
	bnc	SaveContext	; No

; Yes, entire data item is in this packet.  See if it is byte aligned
PlentyORoom
	movf	PacketByteIndex, W	; Get source address to FSR2
	rcall	PointToPacket
	movf	PacketBitIndex, W	; Are we on a byte boundary?
	bz	CopyToVar	; Yes - No shift necessary

; If here, we will have to shift the data item. First, copy it to shift buffer.
	movwf	TempCount	; For shift later
; Move pointer to variable in packet to FSR1
	movff	FSR2L, FSR1L	; FSR1 points to source
	movff	FSR2H, FSR1H

; Point to first byte of shift area in packet
	movf	MaxPacketSize, W	; Shift area is at end of packet buffer
	rcall	PointToPacket	; FSR2 points to destination

	movf	VarBytes, W	; Get number to copy + 1 extra
copyshiftloop
	movff	PLUSW1, PLUSW2	; Do the copy
	decf	WREG, F		; Copy through 0 for 1 extra
	bc	copyshiftloop


; Shift bits to the right to move to byte boundary
UnPkShiftLoop
	movf	VarBytes, W	; W = number of bytes to shift and byte pointer
UnPkShiftLoop1
	rrcf	PLUSW2, F	; Shift a byte one bit to the right
	decfsz	WREG, W
	bra	UnPkShiftLoop1	; Shift all the bytes + 1 extra
	rrcf	PLUSW2, F	; Shift the 0th byte too
	decfsz	TempCount, F
	bra	UnPkShiftLoop	; Shift all the bits


; Now that item has been byte-aligned,
; Copy to variable
CopyToVar
	tblrd*+			; Read VarTable for low variable address
	movf	TABLAT, W
	movwf	FSR1L		; Get address of variable to FSR1
	tblrd*+			; Read VarTable for high variable address
	movf	TABLAT, W
	movwf	FSR1H

	movf	VarBytes, W	; Get number of bytes to copy
uncopyvarloop
	movff	POSTINC2, POSTINC1	; Do the copy
	decfsz	WREG, F
	bra	uncopyvarloop

; Clear any extra junk from last (top) byte in variable
	movf	POSTDEC1, F	; Back up to last byte in variable
	movf	VarBits, W	; Get top bit number + 1
	bz	CheckFor3	; Full byte, nothing else to do
	rcall	GetMask		; Get mask to W and TempByte
	andwf	INDF1, F	; Mask off any extra bits

; Sign extend, if required
	btfss	VarSign, 7	; Check for signed
;	bra	CheckFor3Unsigned	; Unsigned
	bra	CheckFor3 	; Unsigned
	bcf	STATUS, C	; Clear carry
	rrcf	TempByte, W	; Shift mask (still in TempByte) to create single bit mask
	xorwf	TempByte, W	; W is now mask for sign bit
	andwf	INDF1, W	; Check for minus
	bz	CheckFor3	; Sign bit is zero so all set
	movlw	0xff		; Flip mask into sign extension
	xorwf	TempByte, W
	iorwf	INDF1, F	; Sign extend rest of byte


CheckFor3
; If we fit into 3 bytes, we need to fill out 4th byte of long (no short-longs)
    ifndef USE_SHORTLONGS
	movlw	3		; Check for 3 bytes
	cpfseq	VarBytes
	bra	UnPkCalcNewIndexes	; Not 3 bytes so go on
	btfss	VarSign, 7	; Check for signed
	bra	CheckFor3Unsigned	; Unsigned
	setf	WREG		; Set for minus
	btfss	INDF1, 7	; Test sign bit
CheckFor3Unsigned
	clrf	WREG		; Set for plus or unsigned
	movwf	PREINC1		; Fill in 4th byte
    endif


; Calculate new indexes
; I.e., bump indices to point to next item in packet, then loop back
UnPkCalcNewIndexes
	movf	VarSize, W	; Get total bits in this variable
	addwf	PacketBitIndex, F	; Update bits
UnPkCalcNewIndexesOneBit
	rrcf	PacketBitIndex, W	; Shift to get to bytes
	rrcf	WREG, W
	rrcf	WREG, W
	andlw	0x07		; Mask to bytes
	addwf	PacketByteIndex, F
	movlw	0x07		; Mask to bits
	andwf	PacketBitIndex, F

	clrf	TempByte	; Indicate we're not in-process any more
	bra	UnpackLoop	; Go do some more


; Data is a single bit - handle special case
UnOneBit
	tblrd*+			; Read VarTable for low variable address
	movf	TABLAT, W
	movwf	FSR1L		; Get address of variable to FSR1
	tblrd*+			; Read VarTable for high variable address
	movf	TABLAT, W
	movwf	FSR1H

	movf	PacketByteIndex, W	; Get source address to FSR2
	rcall	PointToPacket
	movff	PacketBitIndex, TempByte	; Get bit position in source
	rcall	ConvertBit	; Convert it to a single bit mask
	andwf	INDF2, W	; Mask to our bit
	movwf	VarBytes	; Save the result (don't need VarBytes for bits)

	movff	VarBits, TempByte	; Get bit position in destination
	rcall	ConvertBit	; Convert it to a single bit mask
	iorwf	INDF1, F	; Put bit into destination
	xorlw	0xff		; Flip mask just in case
	movf	VarBytes, F	; Check source result
	btfsc	STATUS, Z	; Do we need to take it back out?
	andwf	INDF1, F	; Take bit out of destination

	incf	PacketBitIndex, F	; Add one to bits
	bra	UnPkCalcNewIndexesOneBit	; Finish updating indexes


; All variables in this Report have been unpacked
TheUnEnd
	rcall	ReleaseBuffer	; Set EP buffer free
	rcall	PointToStorage
	clrf	WREG		; Signal that this is the last packet
	movwf	INDF2		; Save marker
	return

; If here, this Report has not been completely received,
; so we will have more packets to unpack.
; Save context for more to come
SaveContext
	rcall	ReleaseBuffer	; Set buffer free

	movf	MaxPacketSize, W	; Context save area is at end of packet buffer
	rcall	PointToPacket
	movff	FSR2L, FSR1L	; FSR1 points to destination
	movff	FSR2H, FSR1H

	movf	PacketByteIndex, W
	rcall	PointToPacket	; FSR2 points to source

	movf	PacketByteIndex, W	; Calculate number to copy
	subwf	MaxPacketSize, W
	movwf	PacketByteIndex	; Save as new index for next packet
	bz	SaveContextSave	; Nothing to copy so skip it
SaveContextLoop
	movff	POSTINC2, POSTINC1	; Do the copy
	decfsz	WREG, F
	bra	SaveContextLoop
SaveContextSave
	rcall	PointToStorage
	setf	WREG		; More packets to come
	movwf	POSTINC2	; Save marker
	tblrd	*-		; Back up VarTable pointer to beginning of in-process variable
	movff	TBLPTRL, POSTINC2	; Save pointer to VarTable
	movff	TBLPTRH, POSTINC2
	movff	PacketByteIndex, POSTINC2	; Save next byte pointer
	movff	PacketBitIndex, POSTINC2	; Save next bit pointer
	return			; W still set to 0xff




#ifdef USB_WATCH
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
; Add USBwatch activity reporting over hardware serial port
; (15)  Output routines

;*************************************************************************
; UsbwSendState
;
; Sends out the contents of USBWstate

UsbwSendState
; Test if reporting is ON
	movf	USBW_On, W
	btfsc	STATUS, Z
	return
; Report equivalent of LED status: send contents of USBWstate
UsbwSendState1
	movlw	'L'
	call	UsbwSendChar
	movf	USBWstate, W
; ...and just fall through to UsbwSendChar routine to send 2nd byte


;*************************************************************************
; UsbwSendChar
;
; Sends a single char in WREG

UsbwSendChar
	btfss	PIR1, TXIF
	bra	UsbwSendChar
	movwf	TXREG
	return


;*************************************************************************
; UsbwSendUSR
;
; Sends a 'U' (User) message
;
; From within PicBasic Pro code, use: HSEROUT ["U", <byte count>, <data>]
;
; Use this version for sending 'U' messages from assembler code in this file
; INPUTS: WREG = byte count
;         FSR0 : IRP point to buffer
;
; Example:
; ========
;  lfsr    0, UmsgBuf     ; Address of buffer that contains your message
;  movlw   <byte count>   ; Number of bytes you want to send
;  call    UsbwSendUSR


UsbwSendUSR
	movwf	USBWtemp	; First, save byte count in variable USBWtemp
; Test if USBwatch reporting is ON
	movf	USBW_On, W
	btfsc	STATUS, Z
	return
; Send out letter 'U' to indicate that this is a User message
	movlw	'U'
	rcall	UsbwSendChar
; Now we can just restore byte count to W...
	movf	USBWtemp, W
; ...and just fall through to UsbwSendBuf routine



;*************************************************************************
; UsbwSendBuf
;
; Sends a whole buffer
; INPUTS: WREG = byte count
;         FSR0 points to buffer

UsbwSendBuf
	movwf	USBWtemp	; but first, save it in variable USBWtemp
; Send out byte count
	rcall	UsbwSendChar

; Test for zero byte count, and exit if 0
UsbwSendBuf_NBC
	movf	USBWtemp, W
	btfsc	STATUS, Z
	return

Usbw_SB_Loop
	movf	POSTINC0, W	; Get next byte
; Send out next byte of buffer
	rcall	UsbwSendChar
; See if we have to loop back for more
	decfsz	USBWtemp, F
	bra	Usbw_SB_Loop
	return


;*************************************************************************
; UsbwNewTransaction
;
; Reports on occurance of a new USB transaction

UsbwNewTransaction
; Test if reporting is ON
	movf	USBW_On, W
	btfsc	STATUS, Z
	return
; (4) 'L'
; First, toggle EP0..2 EP in USBwatch to denote any activity on these EPs
	rrncf	USTAT, W
	rrncf	WREG, W
	rrncf	WREG, W		; Rotate EPnum bits to right
	andlw	0x0F		; This is the EP number
	movwf	USBWtemp	; Save EP number for later
	bz	UWEP0		; EP0
	dcfsnz	WREG, W
	bra	UWEP1		; EP1
	decfsz	WREG, W
	bra	UsbwNewTran1	; EP > 2, skip this part
	btg	USBWstate, 7	; Toggle bit 7 to show EP2 activity
	bra	UWmaskport
UWEP1
	btg	USBWstate, 6	; Toggle bit 6 to Show EP1 activity
	bra	UWmaskport
UWEP0
	btg	USBWstate, 5	; Toggle bit 5 to Show EP0 activity
UWmaskport
	rcall	UsbwSendState1
UsbwNewTran1
; (5) 'O' or (16) 'I'
; Next, report direction (IN or OUT), USTAT, and request
	movlw	'O'		; Signal to USBwatch that we got an OUT or SETUP token
	btfsc	USTAT, 2
	movlw	'I'		; Signal to USBwatch that we got an IN token
	rcall	UsbwSendChar
	movf	USTAT, W
	andlw	0x1C		; Adjust for current version of USBwatch
	rcall	UsbwSendChar
	movf	SetupPkt + bRequest, W
	rcall	UsbwSendChar
; 'A' or 'B'
; Next, report specific EP number, count, and actual (IN or OUT) packet contents
	movlw	'A'		; Signal to USBwatch that we got an OUT or SETUP token
	btfsc	USTAT, 2
	movlw	'B'		; Signal to USBwatch that we got an IN token
	rcall	UsbwSendChar
	movf	USBWtemp, W	; Endpoint number (0..15)
	rcall	UsbwSendChar
; Have to find the right BDT for this endpoint
	movf	USTAT, W
	andlw	0x1C		; Mask to endpoint and direction (already properly placed)
	lfsr	1, ep0Bo + 1    ; Point FSR1 to BDTnCNT of first OUT endpoint BDT
	addwf	FSR1L, F        ; Add EP offset to FSR0L (can't overflow to FSR0H)
; Get Endpoint buffer address to FSR0
	movf	POSTINC1, W	; Get byte count to W and point to ADRL
	movff	POSTINC1, FSR0L	; Copy low part of address and point to ADRH
	movff	INDF1, FSR0H	; Copy high part of address
	bra	UsbwSendBuf	; Now send out the buffer contents


; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------
#endif

 end
