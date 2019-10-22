; ----------------------------------------------------------------------------
; Copyright 1987-1988,2019 by T.Zoerner (tomzo at users.sf.net)
; All rights reserved.
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice, this
;    list of conditions and the following disclaimer.
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
; ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
; ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
; ----------------------------------------------------------------------------

 ifnd __F_DEF_S
__F_DEF_S equ 1

;----------------- *** Offsets to data section (A6) *** ----------------------
               ;        *** Interface to AES/VDI (aescall, vdicall) ***
GRHANDLE       equ   0   ; ds.w
APPL_ID        equ   2   ; ds.w
AESPB          equ   4   ; contrl,global,intin,intout,addrin,addrout
VDIPB          equ   28  ; contrl,intin,ptsin,intout,ptsout
CONTRL         equ   48  ; ds.w 11
GLOBAL         equ   70  ; ds.w 20
INTIN          equ  110  ; ds.w 20
PTSIN          equ  150  ; ds.w 10
INTOUT         equ  170  ; ds.w 50
PTSOUT         equ  270  ; ds.w 20
ADDRIN         equ  310  ; ds.l 3
ADDROUT        equ  322  ; ds.l 3
               ;
               ;        *** State of the mouse pointer & buttons ***
MOUSE_LBUT     equ  334  ; dc.l ; left button flags (0-1:pressed?; 1:also special!?; 2-3:in menu or outside window)
MOUSE_VEC_BUT  equ  338  ; dc.l ; old VDI Button_Vec
MOUSE_VEC_MOV  equ  342  ; dc.l ; old VDI Mouse_Vec
MOUSE_CUR_XY   equ  346  ; dc.l ; current mouse pointer X/Y
MOUSE_ORIG_XY  equ  350  ; dc.l ; pointer X/Y at time of button press
MOUSE_RBUT     equ  354  ; dc.w ; right button-flags
;              equ  356  ; dc.w ; unused
               ;
               ;        *** State of the selection frame ***
SEL_STATE      equ  358  ; dc.w ; flag 0:no selection; -1:ongoing selection;
               ;                       $00ff:temporary for sub fram_del
SEL_FRM_X1Y1   equ  360  ; dc.l ; X/Y of upper-left corner (rel. to bild_adr)
SEL_FRM_X2Y2   equ  364  ; dc.l ; X/Y of lower-right corner (rel. to bild_adr)
               ;
DSECT_SZ       equ  368  ; total size of data section managed via A6
;-----------------------------------------------------------------------------
          ;
          ;        *** Offsets within window struct ("wi1") ***
WIN_HNDL  equ  0    ; window handle or -1 if window not open
BILD_ADR  equ  2    ; Address of image buffer
INFO      equ  6    ; 0:open/1:change/2:virgin/3:was already changed
LASTNUM   equ  7    ; Handle of last active window
LASTWIN   equ  8    ; Size before maximizing window
YX_OFF    equ  16   ; Delta of window root to coord. root (X/Y=0/0)
;         equ  20   ; unused
FENSTER   equ  22   ; Position and size
SCHIEBER  equ  30   ; Slider hor./vert.: position and size
WIN_STRUCT_SZ equ 38 ; size of this data struct
WIN_STRUCT_CNT equ 7 ; number of window structs in array
          ;
          ;        *** Offsets within selection struct ("mrk") ***
COPY      equ  0    ; copying?
VMOD      equ  1    ; current selection combination mode
EINF      equ  2    ; Selection in buffer? (addr. drawflag+12)
OVKU      equ  3    ; OV-Kurz-Mode?
;OVKU      equ  4   ; OV-Kurz-Mode?
DEL       equ  5    ; delete old selection before move?
OV        equ  6    ; OV-mode?
BUFF      equ  8    ; Addresss OV-buffer
CHG       equ  12   ; modified?
PART      equ  13   ; partial/cut-off?
MODI      equ  14   ; combination mode of cur/prev selection
OLD       equ  16   ; cut-off -> prev coord./offset

          ;        *** Offsets within TEDINFO struct ***
TED_NR    equ  0    ; Index of TEDINFO struct
TED_LEN   equ  2    ; length of string -1
TED_VAL   equ  4    ; current, valid value
TED_MIN   equ  6    ; Minimum
TED_INX   equ  7    ; Index in object tree
TED_MAX   equ  8    ; Maximum
TED_ADR   equ  10   ; Address of TEDINFO struct

 endif /* __F_DEF_S */
