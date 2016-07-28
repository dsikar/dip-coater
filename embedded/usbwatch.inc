#ifdef __DO_NOT_DEFINE_THIS
; Note: In order to be able to #include this same file into both C modules and
; assembler modules, we put all comments in this file inside an #ifdef block that is
; never #define-d.  This is done because the assembler and C compiler both
; recognize #ifdef, but they do not agree on the syntax of comments.

; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------

; ************************************************************************
; USBwatch constant definitions

; To use use USBWatch feature, you must enable the line
; that #defines the constant  USB_WATCH  in this file.
;
; To do so, you should move the line "#define USB_WATCH" outside of this
; #ifdef block.
;
; To disable USBwatch again, you should move this line back inside this
; #ifdef block again.
;
; ************************************************************************
; -----u-s-b-w-a-t-c-h----------------u-s-b-w-a-t-c-h------------

#define USB_WATCH

#endif

#ifdef USB_WATCH

#define  USBW_POWERED_BIT    0
#define  USBW_DEFAULT_BIT    1
#define  USBW_ADDRESSED_BIT  2
#define  USBW_CONFIGURED_BIT 3
#define  USBW_SLEEPING_BIT   4
#define  USBW_EP0_BIT        5
#define  USBW_EP1_BIT        6
#define  USBW_EP2_BIT        7

#define  USBW_POWERED_STATE    0x01
#define  USBW_DEFAULT_STATE    0x02
#define  USBW_ADDRESSED_STATE  0x04
#define  USBW_CONFIGURED_STATE 0x08
#define  USBW_SLEEPING_STATE   0x10
#define  USBW_EP0_STATE        0x20
#define  USBW_EP1_STATE        0x40
#define  USBW_EP2_STATE        0x80

#endif

