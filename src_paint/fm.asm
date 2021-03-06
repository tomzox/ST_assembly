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
 module    MENU_1
 ;section   drei
 ;pagelen   32767
 ;pagewid   133
 ;noexpand
 include "f_sys.s"
 include "f_def.s"
 ;
 XREF  aescall,vdicall,stack
 XREF  bildbuff,wi1,wi_count,rec_adr,menu_adr,win_xy
 XREF  last_koo,aes_rsrc_gad,save_scr,aes_win_set,win_rdw,form_wrt
 XREF  form_do,form_del,form_buf
 XREF  frinfobo,frkoordi,frdrucke,frdatei,koanztab,choofig
 XREF  init_ted,copy_blk,maus_neu,maus_bne,fram_ins,fram_del
 ;
 XDEF  evt_menu_desk,evt_menu_file
 XDEF  get_koos,over_que
 XDEF  alertbox,wind_chg,init_itemslct

*-----------------------------------------------------------------------------
* This module handles menu commands in the Desk and File menus. The respective
* handlers are called out of the main event loop when notified by AES that a
* menu entry in one of the menus was selected by the user.
*
*-----------------------------------------------------------------------------
*   Global register mapping:
*
*   a4   Address of address of current window record
*   a6   Base address of data section
*-----------------------------------------------------------------------------

*-----------------------------------------------------------------------------
*               D E S K   M E N U
*-----------------------------------------------------------------------------
evt_menu_desk:
          cmp.w     #MEN_IT_ABOUT,d0
          bne.s     evt_menu_rts
          moveq.l   #1,d2
          lea       frinfobo,a2
          bsr       form_do             --- Show "About..." dialog ---
          bsr       form_del
evt_menu_rts:
          rts

*-----------------------------------------------------------------------------
*               F I L E   M E N U
*-----------------------------------------------------------------------------
evt_menu_file:
          cmp.w     #MEN_IT_UNDO,d0
          beq       evt_menu_file_undo
          cmp.w     #MEN_IT_DISC,d0
          beq       evt_menu_file_discard
          cmp.w     #MEN_IT_NEW,d0
          beq       evt_menu_file_new
          cmp.w     #MEN_IT_LOAD,d0
          beq       evt_menu_file_load
          cmp.w     #MEN_IT_SAV_AS,d0
          beq       evt_menu_file_save
          cmp.w     #MEN_IT_SAVE,d0
          beq       evt_menu_file_save
          cmp.w     #MEN_IT_PRINT,d0
          beq       evt_menu_file_print
          cmp.w     #MEN_IT_QUIT,d0
          beq       evt_menu_file_quit
          rts

*-----------------------------------------------------------------------------
evt_menu_file_quit:
          bsr       wind_chg            --- Command: Quit ---
          bne.s     quitapp3            top-level image modified?
          moveq.l   #WIN_STRUCT_CNT-1,d0
          lea       wi1,a0
quitapp2  btst.b    #1,WIN_STATE_FLAGS(a0)  ;any other image modified?
          bne.s     quitapp3
          add.l     #WIN_STRUCT_SZ,a0
          dbra      d0,quitapp2
          bra.s     quitapp1
quitapp3  moveq.l   #1,d0               yes -> ask for confirmation
          lea       stralneu,a0
          bsr       alertbox
          cmp.w     #1,d0               abort unless confirmed
          bne       evt_menu_rts
quitapp1  ;
          move.l    MOUSE_VEC_BUT(a6),CONTRL+14(a6)
          vdi       125 0 0             ;old button-vector
          move.l    MOUSE_VEC_MOV(a6),CONTRL+14(a6)
          vdi       127 0 0             ;old mouse-vector
          aes       111 0 1 0 0         ;rsrc_free
          vdi       101 0 0             ;close_vwork
          aes       19 0 1 0 0          ;appl_exit
          clr.l     -(sp)               ;Pterm0
          trap      #1
          rts                           ;never reached
          ;
*-----------------------------------------------------------------------------
evt_menu_file_discard:
          bsr       wind_chg            --- Command: Discard ---
          beq.s     new1
          moveq.l   #1,d0
          lea       stralneu,a0         warning "discard image?"
          bsr       alertbox
          cmp.w     #1,d0
          bne       evt_menu_rts        not confirmed -> abort
new1      bsr       fram_del
          moveq.l   #MEN_IT_UNDO,d0     disable "undo"
          bsr       men_idis
          moveq.l   #MEN_IT_SAVE,d0     disable "save"
          bsr       men_idis
          move.l    UNDO_BUF_ADDR(a6),d0
          cmp.l     WIN_IMGBUF_ADDR(a4),d0
          bne.s     new4
          moveq.l   #MEN_IT_SEL_PAST,d0 ;disable "paste (selection)"
          bsr       men_idis
          clr.w     SEL_FLAG_PASTABLE(a6)
new4      clr.w     SEL_STATE(a6)
          move.b    #1,WIN_STATE_FLAGS(a4)  ;only open-flag set
          clr.w     UNDO_STATE(a6)
          move.w    #3999,d0
          move.l    WIN_IMGBUF_ADDR(a4),a0
new2      clr.l     (a0)+               clear window buffer
          clr.l     (a0)+
          dbra      d0,new2
          move.l    WIN_IMGBUF_ADDR(a4),a0  ;clear window title
          add.w     #32010,a0
          clr.w     (a0)
          bsr       aes_win_set_title
          bra       win_rdw
          ;
*-----------------------------------------------------------------------------
evt_menu_file_new:
          bsr       over_que            --- Command: New ---
          bne       evt_menu_rts
open_ld   bsr       save_scr            +++ open a new window +++
          bsr       fram_del
          move.w    wi_count,d0
          cmp.w     #6,d0
          bne.s     open11
          moveq.l   #1,d0               warn when opening 7th window
          lea       stralwi7,a0
          bsr       alertbox
          cmp.w     #1,d0
          bne.s     open13
open11    move.l    #-1,-(sp)           ;malloc
          move.w    #$48,-(sp)
          trap      #1
          addq.l    #6,sp
          cmp.l     #32100,d0           still 32 kB free?
          bge.s     open9
          lea       stralnom,a0
          moveq.l   #1,d0
          bsr       alertbox
          moveq.l   #-1,d0
open13    rts
open9     ;
          aes       100 5 1 0 0 $fef 0 18 640 382  ;wind_create
          move.w    INTOUT+0(a6),d1
          bpl.s     open1
open2     moveq.l   #1,d0
          lea       stralnow,a0         error creating window -> abort
          bsr       alertbox
          moveq.l   #-1,d0
          rts
open1     moveq.l   #WIN_STRUCT_CNT-1,d0   search for free window record...
          move.l    a4,a0
          lea       wi1,a4
open3     btst.b    #0,WIN_STATE_FLAGS(a4)
          beq.s     open4
          add.w     #WIN_STRUCT_SZ,a4
          dbra      d0,open3
open12    move.l    a0,a4               already 7 windows -> abort
          bra       open2
open4     movem.l   a0/d1,-(sp)
          move.l    #32100,-(sp)        ;malloc
          move.w    #$48,-(sp)
          trap      #1
          addq.l    #6,sp
          movem.l   (sp)+,a0/d1
          move.l    d0,WIN_IMGBUF_ADDR(a4)
          bmi       open12              malloc failed?
          move.w    d1,WIN_HNDL(a4)     initialize window record
          move.b    #1,WIN_STATE_FLAGS(a4)  ;initialze window state flags: open,unmodified
          move.b    1(a0),WIN_PREV_HNDL(a4)
          move.l    d0,a0               clear window buffer
          move.w    #1999,d0
open6     clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,open6
          lea       rec_adr,a0
          move.l    a4,(a0)
          moveq.l   #MEN_IT_DISC,d0     enable "discard"
          bsr       men_iena
          moveq.l   #MEN_IT_SAV_AS,d0   enable "save as"
          bsr       men_iena
          moveq.l   #MEN_IT_SAVE,d0     disable "save"
          bsr       men_idis
          moveq.l   #MEN_IT_PRINT,d0    enable "print"
          bsr       men_iena
          bsr       koo_chk             disable "Coordinates" if needed
          lea       wi_count,a0
          add.w     #1,(a0)
          cmp.w     #7,(a0)             7 windows open?
          blo.s     open7
          move.l    menu_adr,a3         yes -> disable accessories
          add.w     #MEN_IT_ACC0*RSC_OBJ_SZ+11,a3
          moveq.l   #5,d0
open8     bset.b    #3,(a3)
          add.w     #RSC_OBJ_SZ,a3
          dbra      d0,open8
open7     moveq.l   #8,d0               slider: position 0
          clr.w     d1
          bsr       aes_win_set
          moveq.l   #9,d0
          clr.w     d1
          bsr       aes_win_set
          clr.l     WIN_HSLIDER_OFF(a4)
          moveq.l   #15,d0              previous size
          move.w    WIN_HSLIDER_SZ(a4),d1
          bsr       aes_win_set
          moveq.l   #16,d0
          move.w    WIN_VSLIDER_SZ(a4),d1
          bsr       aes_win_set
          move.l    WIN_CUR_XY(a4),INTIN+8(a6)   ;graf_growbox
          move.l    WIN_CUR_WH(a4),INTIN+12(a6)
          move.l    WIN_CUR_XY(a4),INTIN+0(a6)
          move.l    #$100010,INTIN+4(a6)
          aes       73 8 1 0 0
          move.l    WIN_IMGBUF_ADDR(a4),a0  ;set window title
          add.w     #32010,a0
          clr.w     (a0)
          bsr       aes_win_set_title
          move.l    WIN_CUR_XY(a4),INTIN+4(a6)
          move.l    WIN_CUR_WH(a4),INTIN+8(a6)
          aes       108 6 5 0 0 0 $fef  ;wind_calc
          move.l    INTOUT+2(a6),INTIN+2(a6)
          move.l    INTOUT+6(a6),INTIN+6(a6)
          aes       101 5 1 0 0 !(a4)   ;wind_open
          clr.b     d0
          rts
          ;
*-----------------------------------------------------------------------------
evt_menu_file_load:
          bsr       over_que            --- Command: Load ---
          bne       evt_menu_rts
          lea       filename,a0
          clr.b     (a0)
          clr.w     d3
          bsr       itemslct            open item selector
          tst.b     d0
          bne       evt_menu_rts
          clr.w     -(sp)               open: mode:read-only
          pea       dta+30
          move.w    #$3d,-(sp)
          trap      #1
          addq.l    #8,sp
          lea       handle,a0
          move.w    d0,(a0)
          bmi       tos_err
          move.b    frdatei+33,d1       D1: format
          bne.s     load2               +++ Format RAW +++
          move.l    bildbuff,a2         A2: address of (temporary) buffer
          move.l    a2,a0
          move.w    #1999,d0
load7     clr.l     (a0)+               clear image buffer
          clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,load7
          move.w    frdatei+6,d0        convert image width to bytes
          move.w    d0,d2
          lsr.w     #3,d2
          and.w     #7,d0
          beq.s     load4
          addq.w    #1,d2               ask confirmation "rounding width to multiple of 8?"
          lea       stralbyt,a0
          moveq.l   #1,d0
          bsr       alertbox
          cmp.w     #2,d0
          beq       load3               not confirmed -> abort
load4     move.w    d2,d3
          mulu.w    frdatei+20,d2
          bsr       maus_bne
          bsr       load_red            load image data
          bsr       load_opn
          move.w    frdatei+20,d0
load12    subq.w    #1,d0
          moveq.l   #80,d2
          sub.w     d3,d2
          subq.w    #1,d3
          move.l    WIN_IMGBUF_ADDR(a4),a0
          move.l    bildbuff,a2
load5     move.w    d3,d1               copy image data into buffer
load6     move.b    (a2)+,(a0)+
          dbra      d1,load6
          add.w     d2,a0
          dbra      d0,load5
          bra       load3
load2     cmp.b     #1,d1
          bne.s     load10
          lea       dta+26,a0           +++ Format DEGAS +++
          cmp.l     #32034,(a0)
          bne       load_bad
          moveq.l   #34,d2
          move.l    bildbuff,a2
          bsr       load_red
          cmp.w     #1,(a2)
          bne       load_bad
          pea       2(a2)               set color palette
          move.w    #6,-(sp)
          trap      #14
          addq.l    #6,sp
          bsr       load_opn
          bsr       maus_bne            switch mouse form to "bee"
          move.l    WIN_IMGBUF_ADDR(a4),a2
          move.l    #32000,d2           load image
          bsr       load_red
          bra.s     load3
load10    moveq.l   #10,d2              +++ Format LOGO +++
          move.l    bildbuff,a2
          bsr.s     load_red
          cmp.w     #1,(a2)             check header
          bne       load_bad
          move.w    6(a2),d3
          move.w    #640,d0
          sub.w     d3,d0
          cmp.w     2(a2),d0
          blo.s     load_bad
          move.w    #400,d0
          sub.w     8(a2),d0
          cmp.w     4(a2),d0
          blo.s     load_bad
          bsr       maus_bne
          move.w    d3,d0               D3: width in bytes
          lsr.w     #3,d3
          bclr      #0,d3
          and.b     #15,d0
          beq.s     load11
          addq.w    #2,d3
load11    move.w    8(a2),d4            D4: height
          move.w    d3,d2
          mulu.w    8(a2),d2            D2: total number of bytes
          bsr.s     load_red            load image data & copy to buffer
          bsr.s     load_opn            open window
          move.w    d4,d0
          bra       load12
load3     bset.b    #2,WIN_STATE_FLAGS(a4)  ;set "virgin" flag
          clr.l     d3
load9     move.w    handle,-(sp)        ++ close ++
          move.w    #$3e,-(sp)
          trap      #1
          addq.l    #4,sp
          bsr       maus_neu
          tst.b     d3
          bne       evt_menu_rts
          bra       win_rdw
          ;
load_red  move.l    a2,-(sp)            ++ read data from file ++
          move.l    d2,-(sp)            D0: length
          move.w    handle,-(sp)
          move.w    #$3f,-(sp)
          trap      #1
          lea       12(sp),sp
          rts
          ;
load_bad  lea       stralbad,a0         ++ format error ++
          moveq.l   #1,d0
          bsr       alertbox
          moveq.l   #-1,d3
          bra       load9
          ;
load_opn  bsr       wind_chg            ++ prepare window ++
          bne.s     load_op2
          btst.b    #0,WIN_STATE_FLAGS(a4)  ;a window already open?
          beq.s     load_op2
          btst.b    #2,WIN_STATE_FLAGS(a4)  ;virgin?
          bne.s     load_op2
          tst.w     SEL_STATE(a6)       selection ongoing?
          beq       set_name            no -> use already open window
load_op2  bsr       open_ld             open new window
          tst.b     d0                  error?
          beq       set_name
          addq.l    #4,sp
          moveq.l   #-1,d3
          bra       load9
          ;
*-----------------------------------------------------------------------------
evt_menu_file_undo:
          tst.b     UNDO_STATE(a6)      --- Command: Undo ---
          beq       evt_menu_rts
          btst.b    #1,WIN_STATE_FLAGS(a4)  ;at most one modification so far?
          bne.s     regen8                  ;(note "modified" flag is set before 2nd drawing op.)
          bchg.b    #3,WIN_STATE_FLAGS(a4)  ;yes -> toggle undo flag
regen8    tst.w     SEL_STATE(a6)
          beq       regen10
          tst.b     SEL_OPT_OVERLAY(a6)
          beq       regen10
          tst.b     SEL_FLAG_CUTOFF(a6) ;++ Overlay-Mode (comb./clip) ++
          bne.s     regen11
          tst.b     SEL_CUR_COMB(a6)
          bne       regen10
regen11   move.w    #3999,d0            background
          move.l    SEL_OV_BUF(a6),a0
          move.l    WIN_IMGBUF_ADDR(a4),a1
regen12   move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d0,regen12
          lea       stack,a0            parameter
          move.l    UNDO_SEL_X1Y1(a6),d0
          move.l    SEL_FRM_X1Y1(a6),UNDO_SEL_X1Y1(a6)
          move.l    UNDO_SEL_X2Y2(a6),d1
          move.l    SEL_FRM_X2Y2(a6),UNDO_SEL_X2Y2(a6)
          move.l    d1,d2
          sub.l     d0,d2
          lea       stack,a3
          move.l    d0,4(a3)
          move.l    d2,8(a3)
          move.l    d0,24(a3)
          move.l    d1,28(a3)
          move.b    SEL_OPT_COPY(a6),12(a3)
          ;move.b    SEL_PREV_COMB(a6),SEL_OPT_COPY(a6)  ; FIXME does not make sense to change config, esp. without updating menu item state!
          tst.b     SEL_FLAG_CUTOFF(a6)     ;clipping status
          beq.s     regen13
          bset.b    #7,SEL_FLAG_CUTOFF(a6)
          beq.s     regen15
          sub.l     d0,d1
          move.l    SEL_PREV_X2Y2(a6),d0
          sub.l     SEL_PREV_X1Y1(a6),d0
          sub.l     d1,d0
          bne.s     regen15
          bclr.b    #7,SEL_FLAG_CUTOFF(a6)
          clr.l     SEL_PREV_X2Y2(a6)
          bra.s     regen14
regen15   clr.l     SEL_PREV_X2Y2(a6)
          move.w    SEL_FRM_X1Y1+0(a6),d0
          bne.s     regen16
          move.w    d1,SEL_PREV_X2Y2+0(a6)
regen16   move.w    SEL_FRM_X1Y1+2(a6),d0
          bne.s     regen14
          swap      d1
          move.w    d1,SEL_PREV_X2Y2+2(a6)
regen14   move.l    SEL_PREV_X1Y1(a6),d0
          move.l    SEL_PREV_X2Y2(a6),28(a3)
          add.l     SEL_PREV_OFFSET(a6),d0
          move.l    d0,24(a3)
regen13   move.l    WIN_IMGBUF_ADDR(a4),a1
          move.l    bildbuff,20(a3)
          lea       win_xy,a0
          clr.l     (a0)+
          move.l    #$27f018f,(a0)
          bsr       fram_ins            insert/commit selection
          move.b    stack+12,SEL_OPT_COPY(a6)
          move.l    rec_adr,a4
          bra       win_rdw
          ;
regen10   move.l    bildbuff,a0         ++ NORM-Mode ++
          move.l    WIN_IMGBUF_ADDR(a4),a1
          move.w    #3999,d1            swap images
regen1    move.l    (a0),d0
          move.l    (a1),(a0)+
          move.l    d0,(a1)+
          move.l    (a0),d0
          move.l    (a1),(a0)+
          move.l    d0,(a1)+
          dbra      d1,regen1
          tst.b     UNDO_STATE+1(a6)    undo of selection movement?
          beq       regen2
          move.w    #-1,SEL_STATE(a6)
          move.l    UNDO_SEL_X1Y1(a6),d0
          move.l    UNDO_SEL_X2Y2(a6),d1
          move.l    SEL_FRM_X1Y1(a6),UNDO_SEL_X1Y1(a6)
          move.l    SEL_FRM_X2Y2(a6),UNDO_SEL_X2Y2(a6)
          move.l    d0,SEL_FRM_X1Y1(a6)
          move.l    d1,SEL_FRM_X2Y2(a6)
          bpl.s     regen4
          clr.w     SEL_STATE(a6)       ++ clear window frame ++
          move.l    menu_adr,a2
          bset.b    #3,MEN_IT_SEL_PAST*RSC_OBJ_SZ+11(a2)  ;disable "discard" menu entry
          cmp.l     #$12345678,UNDO_BUF_ADDR(a6) ;is pasting allowed?
          beq.s     regen7
          move.l    WIN_IMGBUF_ADDR(a4),UNDO_BUF_ADDR(a6) ;yes
          move.w    #$ff00,SEL_FLAG_PASTABLE(a6)
          moveq.l   #MEN_IT_SEL_PAST,d0 ;enable "paste (selection)" menu entry
          bsr       men_iena
regen7    moveq.l   #6,d2
regen3    move.l    d2,d0
          add.l     #MEN_IT_SEL_ERA,d0 ;disable all selection commands
          bsr       men_idis
          dbra      d0,regen3
          bra.s     regen2
regen4    move.l    menu_adr,a0         ++ Generated frame ++
          bset.b    #3,MEN_IT_SEL_PAST*RSC_OBJ_SZ+11(a0)
          move.b    SEL_OPT_OVERLAY(a6),d0
          beq.s     regen6
          bclr.b    #3,MEN_IT_SEL_PAST*RSC_OBJ_SZ+11(a0)  ;enable "paste" menu entry
          bclr.b    #3,MEN_IT_SEL_DISC*RSC_OBJ_SZ+11(a0)  ;enable "discard" menu entry
regen6    moveq.l   #6,d2
regen5    move.l    d2,d0
          add.l     #MEN_IT_SEL_ERA,d0  ;Enable all selection commands
          bsr       men_iena
          dbra      d0,regen5
regen2    bra       win_rdw
          ;
*-----------------------------------------------------------------------------
evt_menu_file_print:
          move.w    WIN_HNDL(a4),d0    --- Command: Print ---
          bmi       evt_menu_rts
          moveq.l   #1,d0
          lea       stralpr2,a0
          bsr       alertbox
          cmp.w     #1,d0
          bne       evt_menu_rts
druck6    move.w    #$11,-(sp)          printer connected?
          trap      #1
          addq.l    #2,sp
          tst.w     d0
          bmi.s     druck4
          moveq.l   #1,d0
          lea       stralpr1,a0         no -> wait
          bsr       alertbox
          cmp.w     #1,d0
          bne       evt_menu_rts
          bra       druck6
druck4    lea       form_buf,a5         calc clipping-rectangle
          move.b    frdrucke+7,d0
          bne.s     druck21
          clr.l     (a5)                total
          move.l    #$27f018f,4(a5)
          bra.s     druck20
druck21   cmp.b     #1,d0
          bne.s     druck22
          move.l    WIN_CUR_XY(a4),d0      window
          move.l    WIN_CUR_WH(a4),d1
          add.w     WIN_ROOT_YX(a4),d0
          add.l     WIN_ROOT_YX+2(a4),d0
          add.l     d0,d1
          sub.l     #$10001,d1
          move.l    d0,(a5)
          move.l    d1,4(a5)
          bra.s     druck20
druck22   moveq.l   #3,d2               ask for coordinates
          bsr       get_koos
          cmp.w     #7,d4               cancelled by user?
          beq       evt_menu_rts
          move.l    last_koo,(a5)
          move.l    last_koo+4,4(a5)
druck20   bsr       maus_bne
          lea       form_buf,a5
          move.l    WIN_IMGBUF_ADDR(a4),a6  ;ATTN local redefinition of A6
          lea       escfeed,a2          printing line delta = 1/8 inch
          bsr       prtout
          move.b    frdrucke+5,d0       Portrait or landscape format?
          bne       druck10
          sub.l     a3,a3               +++ Portrait format +++
          move.w    2(a5),d0
          move.w    d0,a4               A3/A4: X/Y-coord.
          mulu.w    #80,d0
          add.w     d0,a6
druck5    moveq.l   #79,d6              80 characters per line, 8 pixels each
          lea       stack,a0
druck3    move.w    #128,d4             pos within char, hor.
druck7    moveq.l   #1,d5               pin number and counter
          clr.w     d1                  byte to send
          move.w    a3,d0
          cmp.w     (a5),d0             X-pos within clipping-rect.?
          blo.s     druck8
          cmp.w     4(a5),d0
          bhi.s     druck9
          add.w     #640,a6             offset to A6 within byte
          addq.w    #8,a4
druck2    sub.w     #80,a6
          subq.w    #1,a4
          move.b    (a6),d0
          and.b     d4,d0
          beq.s     druck1
          move.w    a4,d0               Y-pos within clipping-rect.?
          cmp.w     6(a5),d0
          bhi.s     druck1
          or.b      d5,d1
druck1    lsl.b     #1,d5               next pixel vertically
          bcc       druck2
druck8    move.b    d1,(a0)+
druck9    addq.w    #1,a3
          lsr.b     #1,d4               next pixel horizontally
          bcc       druck7
          addq.l    #1,a6               next byte
          dbra      d6,druck3
          bsr       druck30             print line
          add.w     #560,a6             next line
          addq.w    #8,a4
          sub.l     a3,a3
          move.w    a4,d0               veritically still within clipping region?
          cmp.w     6(a5),d0
          bls       druck5
          lea       dsect_a6,a6         restore default address registers
          bra       maus_neu
          ;
druck10   move.w    (a5),d0             +++ Landscape format +++
          move.w    d0,d3
          lsr.w     #3,d3
          and.w     #7,d0
          lea       drucktab,a0
          move.b    (a0,d0.w),(a5)      (A5): mask left border
          move.w    4(a5),d0
          move.w    d0,d4
          lsr.w     #3,d4               D3/4: byte-min/max
          and.w     #7,d0
          move.b    8(a0,d0.w),1(a5)    1(a5): mask of right border
          move.w    6(a5),d0
          move.w    d0,d1
          sub.w     2(a5),d0            convert Y-clipping
          move.w    d0,2(a5)
          mulu.w    #80,d1
          add.w     #81,d1
          move.w    d1,4(a5)            4(A5): line end offset
          move.w    d4,d7
          add.w     d4,a6
druck11   cmp.b     d3,d7               X-pos within clipping rect.?
          blo.s     druck15             no -> done
          lea       stack,a0
          move.w    6(a5),d6
druck12   clr.b     d0
          cmp.w     2(a5),d6            Y-pos within clipping rect.?
          bhi.s     druck14
          move.b    (a6),d0
          cmp.b     d3,d7               Clip byte within range
          bne.s     druck13
          and.b     (a5),d0
druck13   cmp.b     d4,d7
          bne.s     druck14
          and.b     1(a5),d0
druck14   moveq.l   #7,d1
druck17   lsr.b     #1,d0               mirror byte
          roxl.b    #1,d2
          dbra      d1,druck17
          move.b    d2,(a0)+
          add.w     #80,a6              next scan line
          dbra      d6,druck12
          bsr.s     druck30             print line
          sub.w     4(a5),a6            next row
          dbra      d7,druck11
druck15   lea       dsect_a6,a6         restore default address registers
          bra       maus_neu
          ;
druck30   move.l    a0,-(sp)            +++ Print a line of graphical data +++
          move.w    #-1,-(sp)
          move.w    #11,-(sp)           kbshift
          trap      #13
          addq.l    #4,sp
          btst      #3,d0               ALT key pressed?
          beq.s     druck37
          moveq.l   #2,d0               yes -> ask to confirm cancelling print
          lea       stralpr3,a0
          bsr       alertbox
          cmp.b     #1,d0
          bne.s     druck37
          addq.l    #8,sp
          bra       druck15
druck37   move.l    (sp)+,a0
          lea       stack,a2
druck31   cmp.l     a2,a0
          bls.s     druck33
          tst.b     -(a0)
          beq       druck31
          move.l    a0,d5               calculate length of line
          sub.l     a2,d5
          move.w    d5,d0
          addq.w    #1,d0
          move.b    frdrucke+9,d6
          beq.s     druck38
          btst      #0,d6
          beq.s     druck39
          move.w    d0,d1
          lsr.w     #1,d1
          add.w     d1,d0
          subq.w    #1,d0
          bra.s     druck38
druck39   lsl.w     #1,d0
          subq.w    #1,d0
druck38   ror.w     #8,d0
          lea       eschigh,a2          send header
          move.w    d0,2(a2)
          move.w    d5,-(sp)
          moveq.l   #3,d5
druck40   clr.w     d0
          move.b    (a2)+,d0
          bsr       chrout
          dbra      d5,druck40
          move.w    (sp)+,d5
          lea       stack,a2
druck32   clr.w     d0                  send graphical data
          move.b    (a2),d0
          bsr       chrout
          btst      #1,d6               1: flag for double-size
          bne.s     druck36
          btst      #0,d6               0: flag for non-modif.(?)
          beq.s     druck34
          btst      #2,d6               2: flag for every 2nd byte
          beq.s     druck35
druck36   bchg      #3,d6               3: flag for repetition
          bne       druck32
druck35   bchg      #2,d6
druck34   addq.l    #1,a2
          dbra      d5,druck32
druck33   moveq.l   #13,d0
          bsr       chrout
          moveq.l   #10,d0
          bra       chrout
          ;
*-----------------------------------------------------------------------------
evt_menu_file_save:
          move.b    frdatei+33,d0       --- Command: Save/Save as ---
          bne       save3
          move.b    frdatei+35,d0       +++ Format RAW +++
          bne.s     save4
          move.l    #32000,d7           Total
          move.l    WIN_IMGBUF_ADDR(a4),a3
save_all  clr.l     d6
          bsr       save_opn
          bsr       maus_bne
          move.l    a3,-(sp)
          move.l    d7,-(sp)
          bra       save_wrt
save4     cmp.b     #2,d0
          bne.s     save5
          moveq.l   #3,d2               coordinates
          bsr       get_koos
          cmp.w     #7,d4
          beq       evt_menu_rts        cancelled
          move.l    (a1),d4
          move.l    4(a1),d5
          bra.s     save7
save5     move.l    WIN_CUR_XY(a4),d4      window
          move.l    WIN_CUR_WH(a4),d5
          add.w     WIN_ROOT_YX(a4),d4
          add.l     WIN_ROOT_YX+2(a4),d4
          add.l     d4,d5
          sub.l     #$10001,d5
save7     move.l    d5,d2
          sub.l     d4,d2
          add.l     #$10001,d2          D2: width/height
          move.l    d2,d0
          swap      d0
          move.b    frdatei+33,d1       LOGO format?
          cmp.b     #2,d1
          bne.s     save14
          and.w     #15,d0              is width a multiple of words?
          beq.s     save8
          and.l     #$3f003ff,d2
          add.l     #$100000,d2
          bra.s     save8
save14    and.w     #7,d0               is width a multiple of bytes?
          beq.s     save8
          lea       stralbyt,a0
          moveq.l   #1,d0
          bsr       alertbox            no -> ask for confirmation "OK to round up?"
          cmp.w     #2,d0
          beq       evt_menu_rts        not confirmed -> abort
          and.l     #$3f803ff,d2
          add.l     #$80000,d2
save8     cmp.l     #$2800000,d2        width 640 pixels?
          blo.s     save10
          move.w    d2,d7               yes -> use function for complete save
          mulu.w    #80,d7
          move.l    WIN_IMGBUF_ADDR(a4),a3
          mulu.w    #80,d4
          add.l     d4,a3
          bra       save_all
save10    lea       form_buf,a0         backup size
          move.l    d2,(a0)
          move.w    d2,d6               D6: memory requirement
          mulu.w    #80,d6
          bsr       save_opn            create file
          move.l    a3,-(sp)
          move.l    d4,d0
          move.l    d5,d1
          clr.l     d2                  copy image data to buffer
          move.l    WIN_IMGBUF_ADDR(a4),a0
          move.l    a3,a1               A3: scratch buffer
          bsr       copy_blk
          bsr       maus_bne            switch mouse form to "bee"
          move.b    frdatei+33,d1
          cmp.b     #2,d1
          bne.s     save13
          lea       logo_buf,a0         LOGO format -> save header
          moveq.l   #10,d0
          bsr       save_dat
save13    move.w    form_buf,d0
          lsr.w     #3,d0
          move.l    (sp),a0             compress image
          move.l    a0,a1
          add.w     #80,a0
          add.w     d0,a1
          moveq.l   #80,d1
          sub.w     d0,d1
          move.w    form_buf+2,d2
          subq.w    #1,d0
          subq.w    #1,d2
save11    move.w    d0,d3
save12    move.b    (a0)+,(a1)+
          dbra      d3,save12
          add.w     d1,a0
          dbra      d2,save11
          move.w    #$49,-(sp)          (addr. already on stack)
          trap      #1
          addq.l    #2,sp
          move.w    form_buf,d0
          lsr.w     #3,d0
          mulu.w    form_buf+2,d0       +++ save data +++
          move.l    d0,-(sp)
save_wrt  move.w    handle,-(sp)
          move.w    #$40,-(sp)
          trap      #1
          add.w     #12,sp
          tst.l     d0                  error?
          bpl.s     save1
          bsr       tos_err
          bra.s     save2
save1     and.b     #%11110101,WIN_STATE_FLAGS(a4)  ;window-save-Flag
save2     move.w    handle,-(sp)        ;close
          move.w    #$3e,-(sp)
          trap      #1
          addq.l    #4,sp
          bsr       maus_neu            restore normal mouse form
          rts
          ;
save_opn  move.l    WIN_IMGBUF_ADDR(a4),a0    ;+++ ask user for file name +++
          add.w     #32010,a0
          moveq.l   #-1,d3              D3: parameter for itemslct
          move.l    a0,a2
save_op4  move.b    (a0)+,d0            search for start of file name (i.e. after last '\' in path)
          beq.s     save_op3
          cmp.b     #'\',d0
          bne       save_op4
          move.l    a0,a2               A2: address of last '\' +1
          bra       save_op4
save_op3  lea       filename,a0
save_op5  move.b    (a2)+,(a0)+         copy file name part of full path/name
          bne       save_op5
          move.w    EV_MSG_BUF+8(a6),d0  ;"Save" menu command? (i.e. not "Save as...")
          cmp.w     #MEN_IT_SAVE,d0
          bne.s     save_op7
          move.l    WIN_IMGBUF_ADDR(a4),a2
          add.w     #32010,a2
          tst.b     (a2)                filename of current buffer already set?
          beq.s     save_op7
          moveq.l   #$7f,d3
          bsr       itemauto
          bra.s     save_op8
save_op7  bsr       itemslct            open file slection dialog
save_op8  tst.b     d0
          bne.s     save_op1
          tst.l     d6                  +++ get scratch buffer +++
          beq.s     save_o10
          move.l    d6,-(sp)
          move.w    #$48,-(sp)
          trap      #1
          addq.l    #6,sp
          tst.l     d0
          bmi.s     save_op1
          move.l    d0,a3
save_o10  clr.w     -(sp)               ;create
          pea       filename
          move.w    #$3c,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.l     d0                  error?
          bmi.s     save_op2
          lea       handle,a0
          move.w    d0,(a0)
          move.l    WIN_IMGBUF_ADDR(a4),a0
          add.w     #32010,a0
          tst.b     (a0)                window title already set?
          beq       set_name
          rts
save_op2  addq.l    #4,sp               notify user about TOS error
          bra       tos_err
save_op1  addq.l    #4,sp               abort
          rts
          ;
save3     cmp.b     #2,d0
          bne.s     save15
          lea       logo_buf,a3         +++ Format LOGO +++
          move.w    #1,(a3)
          move.l    WIN_CUR_XY(a4),2(a3)
          move.l    WIN_CUR_WH(a4),6(a3)
          move.w    2(a3),d0
          add.w     6(a3),d0
          sub.w     #640,d0
          bls.s     save16
          sub.w     d0,2(a3)
save16    move.w    4(a3),d0
          add.w     8(a3),d0
          sub.w     #400,d0
          bls       save5
          sub.w     d0,4(a3)
          bra       save5
save15    clr.l     d6                  +++ Format DEGAS +++
          bsr       save_opn
          lea       stack,a3
          move.w    #1,(a3)
          add.w     #34,a3
          moveq.l   #15,d3              save color palette
save17    move.w    #-1,-(sp)
          move.w    d3,-(sp)
          move.w    #7,-(sp)
          trap      #14
          addq.l    #6,sp
          move.w    d0,-(a3)
          bsr       maus_bne
          dbra      d3,save17
          lea       stack,a0
          moveq.l   #34,d0
          bsr.s     save_dat            save header
          move.l    WIN_IMGBUF_ADDR(a4),-(sp)
          move.l    #32000,-(sp)        save image data
          bra       save_wrt
save_dat  move.l    a0,-(sp)            +++ Save image data +++
          move.l    d0,-(sp)
          move.w    handle,-(sp)
          move.w    #$40,-(sp)
          trap      #1
          add.w     #12,sp
          rts
          ;
*-----------------------------------------------------------------------------
*               S U B - F U N C T I O N S
*-----------------------------------------------------------------------------
prtout    clr.w     d0                  ** Send string to printer **
          move.b    (a2)+,d0
          beq.s     prtout1             zero-terminated -> done
          bsr.s     chrout
          tst.w     d0
          bne       prtout
prtout1   rts
          ;
*-----------------------------------------------------------------------------
chrout    move.w    d0,-(sp)            ** print one byte **
          move.w    #5,-(sp)
          trap      #1
          addq.l    #4,sp
          rts
          ;
*-----------------------------------------------------------------------------
tos_err   neg.w     d0                  ** report error **
          aes       53 1 1 0 0 !d0
          rts
          ;
*-----------------------------------------------------------------------------
koo_chk   move.w    choofig,d0          Enable/disable "Coordinates"
          cmp.w     #MEN_IT_CHK_COOR,d0 ;selected shape == coordinates?
          beq.s     koo_chk2
          cmp.w     #MEN_IT_CHK_SEL,d0  selection?
          beq.s     koo_chk3
          lea       koanztab,a1
          sub.w     #MEN_IT_PENCIL,d0
          tst.b     (a1,d0.w)
          bne.s     koo_chk3
koo_chk2  moveq.l   #MEN_IT_COORDS,d0   disable "coordinates"
          bra       men_idis
koo_chk3  moveq.l   #MEN_IT_COORDS,d0   enable "coordinates"
          bra       men_iena
          ;
*-----------------------------------------------------------------------------
wind_chg  btst.b    #1,WIN_STATE_FLAGS(a4)   ;** Image modified? **
          bne.s     wind_ch1                 ;more than one modification
          tst.w     UNDO_STATE(a6)           ;modification in undo buffer?
          beq.s     wind_ch1
          bchg.b    #3,WIN_STATE_FLAGS(a4)   ;change undone? (yes <=> bit is set)
          bchg.b    #3,WIN_STATE_FLAGS(a4)   ;NOTE: double bchg == inverse of btst
wind_ch1  rts
          ;
*-----------------------------------------------------------------------------
over_que  tst.w     SEL_STATE(a6)       ** Ask for confirmation "Commit selection?" **
          beq.s     over_qrts
          tst.b     SEL_OPT_OVERLAY(a6)
          beq.s     over_qrts
          tst.b     SEL_FLAG_CHG(a6)
          beq.s     over_qrts
          moveq.l   #1,d0
          lea       stralovq,a0
          bsr.s     alertbox
          cmp.w     #1,d0
over_qrts rts
          ;
*-----------------------------------------------------------------------------
alertbox  ;
          aes       52 1 1 1 0 !d0 !a0  ** Execute AES-alert dialog **
          move.w    INTOUT+0(a6),-(sp)
          bsr       maus_neu
          lea       INTOUT+0(a6),a0
          move.w    (sp)+,d0
          move.w    d0,(a0)             Exit-Taste nach D0
          rts
          ;
*-----------------------------------------------------------------------------
init_itemslct:
          lea       directory,a2        ** Initialitze Items-Selector **
          move.w    #$19,-(sp)
          trap      #1                  ;current_disk
          addq.l    #2,sp
          add.b     #'A',d0
          move.b    d0,(a2)+
          move.b    #':',(a2)+
          clr.w     -(sp)
          move.l    a2,-(sp)
          move.w    #$47,-(sp)          ;get_dir
          trap      #1
          addq.l    #8,sp
getdir1   tst.b     (a2)+
          bne       getdir1
          subq.l    #1,a2
          lea       picname,a0
getdir2   move.b    (a0)+,(a2)+
          bne       getdir2
          rts
          ;
*-----------------------------------------------------------------------------
itemslct  lea       directory,a2        ** Item-Selector **
          lea       filename,a0
          aes       90 0 2 2 0 !a2 !a0
          cmp.w     #1,INTOUT+2(a6)
          bne.s     itemserr
itemauto  cmp.b     #':',1(a2)
          bne.s     items1
          move.b    (a2),d0             set drive
          sub.b     #'A',d0
          move.w    d0,-(sp)
          move.w    #$e,-(sp)
          trap      #1
          addq.l    #4,sp
          addq.l    #2,a2
items1    move.l    a2,a0               set path
          move.l    a2,a1
items2    tst.b     (a2)
          beq.s     items3
          cmp.b     #'\',(a2)+
          bne       items2
          move.l    a2,a1
          bra       items2
items3    move.l    a1,a2
          move.b    (a2),d2
          clr.b     (a2)
          move.l    a0,-(sp)
          move.w    #$3b,-(sp)
          trap      #1
          addq.l    #6,sp
          move.b    d2,(a2)
          tst.w     d0
          bne       itemslct
          pea       dta                 set DTA-buffer
          move.w    #$1a,-(sp)
          trap      #1
          addq.l    #6,sp
          clr.w     -(sp)               search file
          pea       filename
          move.w    #$4e,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.w     d0                  does this file exist?
          beq.s     items4
          tst.w     d3                  + file does not exist +
          bne.s     itemsok             is for saving -> ok
          lea       stralnof,a0
          moveq.l   #2,d0               error "file not found"
          bsr       alertbox
          cmp.w     #1,d0
          beq       itemslct
itemserr  moveq.l   #-1,d0
          rts
items4    tst.w     d3                  + file exists +
          beq.s     itemstak            is for loading -> ok
          lea       stralfsd,a0         ask for confirmation to overwrite
          moveq.l   #1,d0
          bsr       alertbox
          cmp.w     #1,d0
          bne       itemserr
itemstak  moveq.l   #7,d0               copy file name
          lea       dta+30,a0
          lea       filename,a1
items5    move.b    (a0)+,(a1)+
          dbra      d0,items5
itemsok   clr.b     d0                  D0 = 0 -> ok
          rts
          ;
*-----------------------------------------------------------------------------
set_name  move.l    WIN_IMGBUF_ADDR(a4),a0     ** Set window title **
          add.w     #32010,a0
          lea       directory,a1
          move.l    a0,a2
set_nam1  move.b    (a1)+,d0            drive and path name
          move.b    d0,(a0)+
          beq.s     set_nam2
          cmp.b     #'\',d0
          bne       set_nam1
          move.l    a0,a2
          bra       set_nam1
set_nam2  move.l    a2,a0
          lea       filename,a1
set_nam3  move.b    (a1)+,(a0)+         file name
          bne       set_nam3
          move.l    WIN_IMGBUF_ADDR(a4),a0
          add.w     #32010,a0
          tst.b     (a0)
          beq.s     aes_win_set_title
          move.l    a0,a2
          moveq.l   #MEN_IT_SAVE,d0     enable "save"
          bsr       men_iena
          move.l    a2,a0
          ;
aes_win_set_title:
          move.l    a0,INTIN+4(a6)
          aes       105 4 1 0 0 !WIN_HNDL(a4) 2  ;wind_set: window title
          rts
          ;
*-----------------------------------------------------------------------------
get_koos  lea       frkoordi,a2         ** Ask for Coordinates **
          moveq.l   #RSC_FORM_COORD,d1
          bsr       aes_rsrc_gad
          move.l    ADDROUT+0(a6),a3
          bsr       init_ted            write addresses into TED-record
          addq.l    #2,a2
          move.w    #8,128(a3)
          lea       last_koo,a1
          move.w    d2,-(sp)
          cmp.w     #1,d2
          bhi.s     get_koo1
          addq.l    #4,a1
          move.w    #128,128(a3)
get_koo1  move.l    TED_ADR(a2),a0
          move.w    (a1)+,d0
          move.w    d0,TED_VAL(a2)
          bsr       form_wrt            print pos. value into dialog
          add.w     #14,a2
          dbra      d2,get_koo1
          moveq.l   #3,d2
          lea       frkoordi,a2
          bsr       form_do
          bsr       form_del
          lea       last_koo,a1
          move.w    (sp)+,d2
          cmp.w     #1,d2               single pair of coordinates?
          bhi.s     get_koo3
          sub.w     #28,a2
          bra.s     get_koo4
get_koo3  move.w    6(a2),(a1)
          move.w    20(a2),2(a1)
get_koo4  move.w    34(a2),4(a1)
          move.w    48(a2),6(a1)
          rts
*--------------------------------------------------------------STRINGS--------
stralneu  dc.b   '[1][Please confirm discarding|'
          dc.b   'your work!'
          dc.b   '][Ok|Cancel]',0
stralnof  dc.b   '[2][File not found!|'
          dc.b   'Choose another file?'
          dc.b   '][Yes|No]',0
stralfsd  dc.b   '[1][File with this name already|'
          dc.b   'exists! Overwrite this file?'
          dc.b   '][Ok|Cancel]',0
stralbyt  dc.b   '[2][Image width needs to be|'
          dc.b   'rounded to multiple of 8'
          dc.b   '][Ok|Cancel]',0
stralbad  dc.b   '[2][Invalid file format!'
          dc.b   '][Cancel]',0
stralpr1  dc.b   '[2][Printer is not connected!'
          dc.b   '][Ok|Cancel]',0
stralpr2  dc.b   '[1][Note: Press Return to start|'
          dc.b   'Stop with ALT'
          dc.b   '][Ok|Cancel]',0
stralpr3  dc.b   '[3][Really cancel printing?'
          dc.b   '][Yes|Continue]',0
stralwi7  dc.b   '[1][Note accessories no longer|'
          dc.b   'work when opening 7 windows!'
          dc.b   '][Ok|Cancel]',0
stralnow  dc.b   '[3][Maximum is 7 open windows.|'
          dc.b   'Please close another one first'
          dc.b   '][Cancel]',0
stralnom  dc.b   '[3][Not enough memeory available|'
          dc.b   'for this window!'
          dc.b   '][Cancel]',0
stralovq  dc.b   '[1][You are about to commit the|'
          dc.b   'selection and overwrite the|'
          dc.b   'background'
          dc.b   '][Ok|Cancel]',0
*------------------------------------------------------------------I/O--------
picname   dc.b    '\*.PIC',0
directory ds.w   35
filename  dcb.w  7,0
dta       ds.w   25             ; GEMDOS-internal buffer for directory searches (struct DTA, size 22*2 bytes)
logo_buf  ds.w   5
handle    ds.w   1              ; temporary used during load & store
*----------------------------------------------------------------PRINT--------
escfeed   dc.b   27,65,8,0
eschigh   dc.w   $1b4c,0000,0
drucktab  dc.b   $ff,$7f,$3f,$1f,$0f,$07,$03,$01
          dc.b   $80,$c0,$e0,$f0,$f8,$fc,$fe,$ff
*-----------------------------------------------------------------------------
          align 2
          END
