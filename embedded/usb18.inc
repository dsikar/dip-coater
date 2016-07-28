; Compiler directives:

  radix dec
  
; MUID = Microchip USB Class ID
; Used to identify which of the USB classes owns the current
; session of control transfer over EP0
#define	MUID_NULL		0
#define	MUID_USB9		1
#define	MUID_HID		2
#define	MUID_CDC		3
#define	MUID_MSD		4

; Buffer Descriptor Status Register Initialization Parameters
#define	_BSTALL			0x04	; Buffer Stall enable
#define	_DTSEN			0x08	; Data Toggle Synch enable
#define	_INCDIS			0x10	; Address increment disable
#define	_KEN			0x20	; SIE keeps buff descriptors enable
#define	_DAT0			0x00	; DATA0 packet expected next
#define	_DAT1			0x40	; DATA1 packet expected next
#define	_DTSMASK		0x40	; DTS Mask
#define	_USIE			0x80	; SIE owns buffer
#define	_UCPU			0x00	; CPU owns buffer

; USB Device States - To be used with [byte usb_device_state]
#define	DETACHED_STATE		0
#define	ATTACHED_STATE		1
#define	POWERED_STATE		2
#define	DEFAULT_STATE		3
#define	ADR_PENDING_STATE	4
#define	ADDRESS_STATE		5
#define	CONFIGURED_STATE	6

; Memory Types for Control Transfer - used in USB_DEVICE_STATUS
;#define	_RAM			0
;#define	_ROM			1


; From usbdefs_std_dsc.h
; Descriptor Types
#define DSC_DEV     0x01
#define DSC_CFG     0x02
#define DSC_STR     0x03
#define DSC_INTF    0x04
#define DSC_EP      0x05

; USB Endpoint Definitions
#define _EP01_OUT   0x01
#define _EP01_IN    0x81
#define _EP02_OUT   0x02
#define _EP02_IN    0x82
#define _EP03_OUT   0x03
#define _EP03_IN    0x83
#define _EP04_OUT   0x04
#define _EP04_IN    0x84
#define _EP05_OUT   0x05
#define _EP05_IN    0x85
#define _EP06_OUT   0x06
#define _EP06_IN    0x86
#define _EP07_OUT   0x07
#define _EP07_IN    0x87
#define _EP08_OUT   0x08
#define _EP08_IN    0x88
#define _EP09_OUT   0x09
#define _EP09_IN    0x89
#define _EP10_OUT   0x0A
#define _EP10_IN    0x8A
#define _EP11_OUT   0x0B
#define _EP11_IN    0x8B
#define _EP12_OUT   0x0C
#define _EP12_IN    0x8C
#define _EP13_OUT   0x0D
#define _EP13_IN    0x8D
#define _EP14_OUT   0x0E
#define _EP14_IN    0x8E
#define _EP15_OUT   0x0F
#define _EP15_IN    0x8F

; Configuration Attributes
;#define	_DEFAULT	0x01<<7		; Default Value (Bit 7 is set)
;#define	_SELF		0x01<<6		; Self-powered (Supports if set)
;#define	_RWU		0x01<<5		; Remote Wakeup (Supports if set)

; Endpoint Transfer Type
;#define	_CTRL		0x00		; Control Transfer
;#define	_ISO		0x01		; Isochronous Transfer
;#define	_BULK		0x02		; Bulk Transfer
;#define	_INT		0x03		; Interrupt Transfer

; Isochronous Endpoint Synchronization Type
;#define	_NS		0x00<<2		; No Synchronization
;#define	_AS		0x01<<2		; Asynchronous
;#define	_AD		0x02<<2		; Adaptive
;#define	_SY		0x03<<2		; Synchronous

; Isochronous Endpoint Usage Type
;#define	_DE		0x00<<4		; Data endpoint
;#define	_FE		0x01<<4		; Feedback endpoint
;#define	_IE		0x02<<4		; Implicit feedback Data endpoint


; From usb9.h
; Standard Request Codes
; USB 2.0 Spec Ref Table 9-4
#define	GET_STATUS		0
#define	CLR_FEATURE		1
#define	SET_FEATURE		3
#define	SET_ADR			5
#define	GET_DSC			6
#define	SET_DSC			7
#define	GET_CFG			8
#define	SET_CFG			9
#define	GET_INTF		10
#define	SET_INTF		11
#define	SYNCH_FRAME		12

; Standard Feature Selectors
#define	DEVICE_REMOTE_WAKEUP	0x01
#define	ENDPOINT_HALT		0x00


; From hid.h
; Class-Specific Requests
#define	GET_REPORT		0x01
#define	GET_IDLE		0x02
#define	GET_PROTOCOL		0x03
#define	SET_REPORT		0x09
#define	SET_IDLE		0x0A
#define	SET_PROTOCOL		0x0B

; Class Descriptor Types
#define	DSC_HID			0x21
#define	DSC_RPT			0x22
#define	DSC_PHY			0x23

; Protocol Selection
#define	BOOT_PROTOCOL		0x00
#define	RPT_PROTOCOL		0x01

; HID Interface Class Code
#define	HID_INTF		0x03

; HID Interface Class SubClass Codes
#define	BOOT_INTF_SUBCLASS	0x01

; HID Interface Class Protocol Codes
#define	HID_PROTOCOL_NONE	0x00
#define	HID_PROTOCOL_KEYBOAD	0x01
#define	HID_PROTOCOL_MOUSE	0x02

; HID Report codes used in GET_REPORT and SET_REPORT requests
#define HID_INPUT_REPORT     1
#define HID_OUTPUT_REPORT    2
#define HID_FEATURE_REPORT   3

; From cdc.h
; Class-Specific Requests
#define	SEND_ENCAPSULATED_COMMAND 0x00
#define	GET_ENCAPSULATED_RESPONSE 0x01
#define	SET_COMM_FEATURE	0x02
#define	GET_COMM_FEATURE	0x03
#define	CLEAR_COMM_FEATURE	0x04
#define	SET_LINE_CODING		0x20
#define	GET_LINE_CODING		0x21
#define	SET_CONTROL_LINE_STATE	0x22
#define	SEND_BREAK		0x23

; Notifications
;  Note: Notifications are polled over
;  Communication Interface (Interrupt Endpoint)
#define	NETWORK_CONNECTION	0x00
#define	RESPONSE_AVAILABLE	0x01
#define	SERIAL_STATE		0x20

; Device Class Code
#define	CDC_DEVICE		0x02

; Communication Interface Class Code
#define	COMM_INTF		0x02

; Communication Interface Class SubClass Codes
#define	ABSTRACT_CONTROL_MODEL	0x02

; Communication Interface Class Control Protocol Codes
#define	V25TER			0x01	; Common AT commands ("Hayes(TM)")

; Data Interface Class Codes
#define	DATA_INTF		0x0A

; Data Interface Class Protocol Codes
#define	NO_PROTOCOL		0x00	; No class specific protocol required

; Communication Feature Selector Codes
#define	ABSTRACT_STATE		0x01
#define	COUNTRY_SETTING		0x02

; Functional Descriptors
; Type Values for the bDscType Field
#define	CS_INTERFACE		0x24
#define	CS_ENDPOINT		0x25

; bDscSubType in Functional Descriptors
#define	DSC_FN_HEADER		0x00
#define	DSC_FN_CALL_MGT		0x01
#define	DSC_FN_ACM		0x02	; ACM - Abstract Control Management
#define	DSC_FN_DLM		0x03	; DLM - Direct Line Managment
#define	DSC_FN_TELEPHONE_RINGER	0x04
#define	DSC_FN_RPT_CAPABILITIES	0x05
#define	DSC_FN_UNION		0x06
#define	DSC_FN_COUNTRY_SELECTION 0x07
#define	DSC_FN_TEL_OP_MODES	0x08
#define	DSC_FN_USB_TERMINAL	0x09
; more.... see Table 25 in USB CDC Specification 1.1

; CDC Bulk IN transfer states
#define	CDC_TX_READY		0
#define	CDC_TX_BUSY		1
#define	CDC_TX_BUSY_ZLP		2	; ZLP: Zero Length Packet
#define	CDC_TX_COMPLETING	3

#define	LINE_CODING_LENGTH	0x07
#define dummy_length		0x08


; From usbctrltrf.h
; Control Transfer States
#define	WAIT_SETUP		0
#define	CTRL_TRF_TX		1
#define	CTRL_TRF_RX		2

; USB PID: Token Types - See chapter 8 in the USB specification
#define	SETUP_TOKEN		0x0d
#define	OUT_TOKEN		0x01
#define	IN_TOKEN		0x09

; bmRequestType Definitions
#define	HOST_TO_DEV		0
#define	DEV_TO_HOST		1

#define	STANDARD		0x00
#define	CLASS			0x01
#define	VENDOR			0x02

#define	RCPT_DEV		0
#define	RCPT_INTF		1
#define	RCPT_EP			2
#define	RCPT_OTH		3


; From usbdrv.h
; UCFG Initialization Parameters
#define	_PPBM0			0x00	; Pingpong Buffer Mode 0
#define	_PPBM1			0x01	; Pingpong Buffer Mode 1
#define	_PPBM2			0x02	; Pingpong Buffer Mode 2
#define	_LS			0x00	; Use Low-Speed USB Mode
#define	_FS			0x04	; Use Full-Speed USB Mode
#define	_TRINT			0x00	; Use internal transceiver
#define	_TREXT			0x08	; Use external transceiver
#define	_PUEN			0x10	; Use internal pull-up resistor
#define	_OEMON			0x40	; Use SIE output indicator
#define	_UTEYE			0x80	; Use Eye-Pattern test

; UEPn Initialization Parameters
#define	EP_CTRL			0x06	; Cfg Control pipe for this ep
#define	EP_OUT			0x0C	; Cfg OUT only pipe for this ep
#define	EP_IN			0x0A	; Cfg IN only pipe for this ep
#define	EP_OUT_IN		0x0E	; Cfg both OUT & IN pipes for this ep
#define	HSHK_EN			0x10	; Enable handshake packet

#define	OUT		0
#define	IN		1

#define	PIC_EP_NUM_MASK	0b01111000
#define	PIC_EP_DIR_MASK	0b00000100

#define	EP00_OUT	(0x00<<3)|(OUT<<2)
#define	EP00_IN		(0x00<<3)|(IN<<2)
#define	EP01_OUT	(0x01<<3)|(OUT<<2)
#define	EP01_IN		(0x01<<3)|(IN<<2)
#define	EP02_OUT	(0x02<<3)|(OUT<<2)
#define	EP02_IN		(0x02<<3)|(IN<<2)
#define	EP03_OUT	(0x03<<3)|(OUT<<2)
#define	EP03_IN		(0x03<<3)|(IN<<2)
#define	EP04_OUT	(0x04<<3)|(OUT<<2)
#define	EP04_IN		(0x04<<3)|(IN<<2)
#define	EP05_OUT	(0x05<<3)|(OUT<<2)
#define	EP05_IN		(0x05<<3)|(IN<<2)
#define	EP06_OUT	(0x06<<3)|(OUT<<2)
#define	EP06_IN		(0x06<<3)|(IN<<2)
#define	EP07_OUT	(0x07<<3)|(OUT<<2)
#define	EP07_IN		(0x07<<3)|(IN<<2)
#define	EP08_OUT	(0x08<<3)|(OUT<<2)
#define	EP08_IN		(0x08<<3)|(IN<<2)
#define	EP09_OUT	(0x09<<3)|(OUT<<2)
#define	EP09_IN		(0x09<<3)|(IN<<2)
#define	EP10_OUT	(0x0A<<3)|(OUT<<2)
#define	EP10_IN		(0x0A<<3)|(IN<<2)
#define	EP11_OUT	(0x0B<<3)|(OUT<<2)
#define	EP11_IN		(0x0B<<3)|(IN<<2)
#define	EP12_OUT	(0x0C<<3)|(OUT<<2)
#define	EP12_IN		(0x0C<<3)|(IN<<2)
#define	EP13_OUT	(0x0D<<3)|(OUT<<2)
#define	EP13_IN		(0x0D<<3)|(IN<<2)
#define	EP14_OUT	(0x0E<<3)|(OUT<<2)
#define	EP14_IN		(0x0E<<3)|(IN<<2)
#define	EP15_OUT	(0x0F<<3)|(OUT<<2)
#define	EP15_IN		(0x0F<<3)|(IN<<2)


; Buffer Descriptor Byte Aliases
#define  Stat   0   ; Buffer Descriptor Status Register
#define  Cnt    1   ; Buffer Count
;#define  ADR    2   ; Buffer Address
#define  ADRL   2   ; Buffer Address Low
#define  ADRH   3   ; Buffer Address High

; Stat Bit Aliases
#define  BC8    0   ; Upper Count Bit
#define  BC9    1   ; Upper Count Bit
#define  BSTALL 2   ; Buffer Stall Enable
#define  DTSEN  3   ; Data Toggle Synch Enable
#define  INCDIS 4   ; Address Increment Disable
#define  KEN    5   ; BD Keep Enable
#define  DTS    6   ; Data Toggle Synch Value
#define  UOWN   7   ; USB Ownership
#define  PID    2   ; Packet Identifier (4 bits)
;#define  PID0   2
;#define  PID1   3
;#define  PID2   4
;#define  PID3   5

; usb_stat bit aliases
#define  RemoteWakeup  0    ; [0]Disabled [1]Enabled
#define  ctrl_trf_mem  1    ; [0]RAM      [1]ROM
#define  cdc_mem_type  2    ; [0]RAM      [1]ROM

; SetupPkt Byte and Bit Aliases
#define  bmRequestType 0
#define  bRequest    1
#define  wValue      2
#define  wValueHi    3
#define  wIndex      4
#define  wIndexHi    5
#define  wLength     6
#define  wLengthHi   7

#define  Recipient   0    ; Device,Interface,Endpoint,Other (5 bits)
#define  RequestType 5    ; Standard,Class,Vendor,Reserved (2 bits)
#define  DataDir     7    ; Host-to-device,Device-to-host
#define  bFeature    2    ; DEVICE_REMOTE_WAKEUP,ENDPOINT_HALT

#define  bReportID   2    ; In a SET_REPORT or GET_REPORT request
#define  bReportType 3    ; In a SET_REPORT or GET_REPORT request

#define  bDscIndex   2    ; For Configuration and String DSC Only
#define  bDscType    3    ; Device,Configuration,String
#define  wLangID     4    ; Language ID

#define  bDevADR     2    ; Device Address 0-127
#define  bDevADRH    3    ; Must equal zero

#define  bCfgValue   2    ; Configuration Value 0-255
#define  bCfgRSD     3    ; Must equal zero (Reserved)

#define  bAltID      2    ; Alternate Setting Value 0-255
#define  bAltID_H    3    ; Must equal zero (Reserved)
#define  bIntfID     4    ; Interface Number Value 0-255
#define  bIntfID_H   5    ; Must equal zero

#define  bEPID       4    ; Endpoint ID (Number & Direction)
#define  bEPID_H     5    ; Must equal zero

#define  EPNum       0    ; Endpoint Number 0-15 (4 bits)
#define  EPDir       7    ; Endpoint Direction: 0-OUT, 1-IN

; For CDC device class
  
; line_coding Byte and Bit Aliases
#define  dwDTERate    0   ; Complex data structure
#define  bCharFormat  4
#define  bParityType  5
#define  bDataBits    6

; control_signal_bitmap Byte and Bit Aliases
#define  DTE_PRESENT      0   ; [0] Not Present  [1] Present
#define  CARRIER_CONTROL  1   ; [0] Deactivate   [1] Activate


