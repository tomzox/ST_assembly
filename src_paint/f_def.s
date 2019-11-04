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

;-----------------------------------------------------------------------------
;                       *** Offsets to data section "dsect_a6" ***
;-----------------------------------------------------------------------------

               ;        *** Interface to AES/VDI (aescall, vdicall) ***
GRHANDLE       equ   0   ; ds.w
APPL_ID        equ   2   ; ds.w
AESPB          equ   4   ; CONTRL,GLOBAL,INTIN,INTOUT,ADDRIN,ADDROUT
VDIPB          equ   28  ; CONTRL,INTIN,PTSIN,INTOUT,PTSOUT
CONTRL         equ   48  ; ds.w 11
GLOBAL         equ   70  ; ds.w 20
INTIN          equ  110  ; ds.w 20
PTSIN          equ  150  ; ds.w 10
INTOUT         equ  170  ; ds.w 50
PTSOUT         equ  270  ; ds.w 20
ADDRIN         equ  310  ; ds.l 3
ADDROUT        equ  322  ; ds.l 3

EV_MSG_BUF     equ  334  ; ds.w 10 ; message buffer filled by AES evnt_multi/evnt_mesag
                         ;           +0: event ID (e.g. 20=WM_REDRAW)
                         ;           +2: AES app.ID.
                         ;           rest depends on event ID

                  ;        *** State of the mouse pointer & buttons ***
MOUSE_LBUT        equ  354  ; dc.l ; left button flags (0-1:pressed?; 1:also special!?; 2-3:in menu or outside window)
MOUSE_VEC_BUT     equ  358  ; dc.l ; old VDI Button_Vec
MOUSE_VEC_MOV     equ  362  ; dc.l ; old VDI Mouse_Vec
MOUSE_CUR_XY      equ  366  ; dc.l ; current mouse pointer X/Y
MOUSE_ORIG_XY     equ  370  ; dc.l ; pointer X/Y at time of button press
MOUSE_RBUT        equ  374  ; dc.w ; right button-flags
;                 equ  376  ; dc.w ; unused

                  ;        *** State of the selection frame ***
SEL_STATE         equ  378  ; dc.w ; flag 0:no selection; -1:ongoing selection;
                  ;                       $00ff:temporary for sub fram_del
SEL_FRM_X1Y1      equ  380  ; dc.l ; X/Y of upper-left corner (rel. to bild_adr)
SEL_FRM_X2Y2      equ  384  ; dc.l ; X/Y of lower-right corner (rel. to bild_adr)
                  ;
SEL_OPT_COPY      equ  388  ; dc.b ; copy-mode (i.e. copy image area into sel.buf. instead of erasing)
SEL_OPT_COMB      equ  389  ; dc.b ; configured selection combination mode
SEL_FLAG_PASTABLE equ  390  ; dc.b ; previous selection in buffer could be pasted (buf.addr.=UNDO_BUF_ADDR)
                            ;        $ff00:=old frame exists, $00ff
SEL_TMP_OVERLAY   equ  393  ; dc.b ; temporary overlay mode, used after pasting selection
;                 equ  394  ; dc.b ; -unused-
SEL_FLAG_DEL      equ  395  ; dc.b ; delete old selection before move?
SEL_OPT_OVERLAY   equ  396  ; dc.b ; overlay mode? (i.e. selection not copied into image until sel. is fully released)
SEL_OV_BUF        equ  398  ; dc.l ; Addresss of buffer for overlay mode, else 0
                  ;                  contains a copy of the image *excluding* the selected area
SEL_FLAG_CHG      equ  402  ; dc.b ; modified?
SEL_FLAG_CUTOFF   equ  403  ; dc.b ; selection only partially visible? (due to cut-off at screen border)
                            ;        tri-state: 0:no $7f:??  $ff:??
SEL_CUR_COMB      equ  404  ; dc.b ; combination mode currently used
SEL_PREV_COMB     equ  405  ; dc.b ; prev. used combination mode (copy of SEL_CUR_COMB upon moving sel.frm.): for undo
SEL_PREV_X1Y1     equ  406  ; dc.l ; prev. selection frame coords. (for undo after cut-off at screen border)
SEL_PREV_X2Y2     equ  410  ; dc.l ;   ... lower-right corner
SEL_PREV_OFFSET   equ  414  ; dc.l ;   ... X/Y offsets (?)

                  ;        *** Flags for undo and paste ***
UNDO_STATE        equ  418  ; dc.w ; undo flag: 0:disabled -1:enabled $ff00:selection-moved
UNDO_SEL_X1Y1     equ  420  ; dc.l ; old selection X1/Y1
UNDO_SEL_X2Y2     equ  424  ; dc.l ; old selection X2/Y2
UNDO_BUF_ADDR     equ  428  ; dc.l ; #$12345678 for undo of shape draw,
                  ;                ; or copy of "BILD_ADR(a4)" = selection buffer address

DSECT_SZ          equ  432  ; total size of data section managed via A6

;-----------------------------------------------------------------------------
;                          *** Offsets within window struct ("wi1") ***

WIN_HNDL          equ  0    ; window handle or -1 if window not open
WIN_IMGBUF_ADDR   equ  2    ; Address of image buffer
WIN_STATE_FLAGS   equ  6    ; 0:open/1:modified (more than once)/2:non-virgin/3:undo flag while single modif.
                            ; note to #1: first modification is noted via UNDO_STATE && !#3
WIN_PREV_HNDL     equ  7    ; Handle of last active window
WIN_PREMAX_XY     equ  8    ; X/Y pos before maximizing window
WIN_PREMAX_WH     equ  12   ; W/H size before maximizing window
WIN_ROOT_YX       equ  16   ; Delta of window root to coord. root (X/Y=0/0)
;                 equ  20   ; unused - has to be zero (YX_OFF+2 is read from as long)
WIN_CUR_XY        equ  22   ; Current window position (i.e. of window frame)
WIN_CUR_WH        equ  26   ; Current window size
WIN_HSLIDER_OFF   equ  30   ; horizontal slider position
WIN_VSLIDER_OFF   equ  32   ; vertical slider position
WIN_HSLIDER_SZ    equ  34   ; horizontal slider size
WIN_VSLIDER_SZ    equ  36   ; vertical slider size

WIN_STRUCT_SZ equ 38 ; size of this data struct
WIN_STRUCT_CNT equ 7 ; number of window structs in array

;-----------------------------------------------------------------------------
;                  *** Offsets within TEDINFO struct ***

TED_NR    equ  0    ; Index of TEDINFO struct
TED_LEN   equ  2    ; length of string -1
TED_VAL   equ  4    ; current, valid value
TED_MIN   equ  6    ; Minimum
TED_INX   equ  7    ; Index in object tree
TED_MAX   equ  8    ; Maximum
TED_ADR   equ  10   ; Address of AES "struct text_edinfo"

;-----------------------------------------------------------------------------
;                             *** Constants for resources ***
;-----------------------------------------------------------------------------
RSC_OBJ_SZ      equ  24         ; size of AES "struct object"

RSC_MENU        equ   0         ; menu object tree
RSC_FORM_ABOUT  equ   1
RSC_FORM_SEGMT  equ   2
RSC_FORM_COORD  equ   3
RSC_FORM_COMB   equ   4         ; attribute dialogs...
RSC_FORM_PENC   equ   5
RSC_FORM_BRUSH  equ   6
RSC_FORM_SPRAY  equ   7
RSC_FORM_FILL   equ   8
RSC_FORM_TEXT   equ   9
RSC_FORM_ERASER equ  10
RSC_FORM_LINE   equ  11
RSC_FORM_PRINT  equ  12
RSC_FORM_FILE   equ  13
RSC_FORM_SELCMB equ  14
RSC_FORM_GRID   equ  15
RSC_DESKTOP     equ  16         ; desktop background & image
RSC_FORM_CHAR   equ  17
RSC_FORM_ROTATE equ  18         ; selection operations...
RSC_FORM_ZOOM   equ  19
RSC_FORM_DISTRT equ  20
RSC_FORM_PROJ   equ  21
RSC_FORM_COMMIT equ  22

                ;             *** Constants for menu tree ***
MEN_TOP_DESK    equ   3         ; top-level menus
MEN_TOP_FILE    equ   4
MEN_TOP_SHAPE   equ   5
MEN_TOP_ATTR    equ   6
MEN_TOP_SEL     equ   7
MEN_TOP_TOOLS   equ   8

MEN_IT_ABOUT    equ  $b         ; DESK menu entries
MEN_IT_ACC0     equ  $d

MEN_IT_UNDO     equ $14         ; FILE menu entries
MEN_IT_DISC     equ $16
MEN_IT_NEW      equ $17
MEN_IT_LOAD     equ $18
MEN_IT_SAV_AS   equ $19
MEN_IT_SAVE     equ $1a
MEN_IT_PRINT    equ $1b
MEN_IT_QUIT     equ $1d

MEN_IT_PENCIL   equ $1f         ; SHAPES menu entries
MEN_IT_BRUSH    equ $20
MEN_IT_SPRAY    equ $21
MEN_IT_FLFILL   equ $22
MEN_IT_TEXT     equ $23
MEN_IT_ERASER   equ $24
MEN_IT_RUBBND   equ $25
MEN_IT_LINE     equ $26
MEN_IT_RECT     equ $27
MEN_IT_SQR      equ $28
MEN_IT_POLYGN   equ $29
MEN_IT_CIRCLE   equ $2a
MEN_IT_ELIPSIS  equ $2b
MEN_IT_CURVE    equ $2c
MEN_IT_CHK_FILL equ $2e
MEN_IT_CHK_RND  equ $2f
MEN_IT_CHK_BRD  equ $30
MEN_IT_ARC_SEG  equ $31

MEN_IT_CFG_COMB equ $33         ; ATTRIBUTES menu entries
MEN_IT_CFG_PENC equ $35
MEN_IT_CFG_BRUS equ $36
MEN_IT_CFG_SPRY equ $37
MEN_IT_CFG_FILL equ $38
MEN_IT_CFG_TEXT equ $39
MEN_IT_CFG_ERA  equ $3a
MEN_IT_CFG_LINE equ $3b
MEN_IT_CFG_PRT  equ $3d
MEN_IT_CFG_FILE equ $3e

MEN_IT_CHK_SEL  equ $40         ; SELECTION menu entries
MEN_IT_SEL_PAST equ $41
MEN_IT_SEL_DISC equ $42
MEN_IT_SEL_COMI equ $43
MEN_IT_SEL_ERA  equ $45
MEN_IT_SEL_BLCK equ $46
MEN_IT_SEL_INV  equ $47
MEN_IT_SEL_MIRR equ $48
MEN_IT_SEL_ROT  equ $49
MEN_IT_SEL_ZOOM equ $4a
MEN_IT_SEL_DIST equ $4b
MEN_IT_SEL_PROJ equ $4c
MEN_IT_SEL_COPY equ $4e
MEN_IT_SEL_COMB equ $4f
MEN_IT_SEL_OVL  equ $50

MEN_IT_CHK_COOR equ $52         ; TOOLS menu entries
MEN_IT_COORDS   equ $53
MEN_IT_VIEW_ZOM equ $54
MEN_IT_FULL_SCR equ $55
MEN_IT_CFG_MOUS equ $57
MEN_IT_SHOW_COO equ $58
MEN_IT_CHK_GRID equ $59
MEN_IT_CFG_GRID equ $5b

 endif /* __F_DEF_S */
