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
 module    MENU_2
 ;section   drei
 ;pagelen   32767
 ;pagewid   133
 ;noexpand
 include "f_sys.s"
 include "f_def.s"
 ;
 XREF  aescall,vdicall
 XREF  bildbuff,rec_adr,menu_adr,koanztab
 XREF  show_m,hide_m,save_scr,win_rdw,rsrc_gad,set_xx,drei_chg
 XREF  save_buf,win_abs,choofig,copy_blk,win_xy,koos_mak,alertbox
 XREF  rand_tab,logbase,get_koos,over_que,fram_del,fuenf_4c,koostr1
 ;
 XDEF  chootxt,chooras,choopat,frraster,frinfobo,frsegmen
 XDEF  frkoordi,frmodus,frpunkt,frpinsel,frsprayd,frmuster,frtext
 XDEF  frradier,frlinie,frdrucke,frdatei,check_xx
 XDEF  work_blk,form_do,form_del,form_buf,form_wrt,frzeiche
 XDEF  chookoo,work_bl2,init_ted,maus_neu,over_beg,over_old
 XDEF  maus_bne,cent_koo,over_cut,frrotier,frzerren,frzoomen,frprojek
 XDEF  evt_menu_attr
 ;
**********************************************************************
*   Global register mapping:
*
*   a4   Address of address of current window record
*   a6   Base address of data section
**********************************************************************

*---------------------------------------------------------------------
*               A T T R I B U T E S   M E N U
*---------------------------------------------------------------------
evt_menu_attr:
          cmp.b     #MEN_IT_CFG_MOUS,d0
          blo.s     vier_3f
          lea       choomou,a2          --- Mouse form attribute ---
          not.b     1(a2)
          bsr       maus_neu
          move.l    menu_adr,a1
          add.w     #MEN_IT_CFG_MOUS*RSC_OBJ_SZ+12,a1  ;A1: address of menu item string
          tst.w     (a2)
          beq.s     mausel1
          move.l    (a1),2(a2)          pre-select shape "cross"
          addq.l    #6,a2
          move.l    a2,(a1)
          rts
mausel1   move.l    2(a2),(a1)          pre-select shape "arrow"
evt_menu_rts2:
          rts
          ;
vier_3f   cmp.b     #MEN_IT_CFG_WIN,d0
          bne.s     vier_33
          moveq.l   #1,d0               --- Window attribute ---
          lea       stralfat,a0
          bsr       alertbox            "not implemented yet"
          rts
          ;
vier_33   sub.b     #MEN_IT_CFG_COMB,d0 ;--- Attribute dialog windows ---
          move.w    d0,d2
          add.w     #5,d2
          lsl.w     #2,d0
          ext.l     d0
          lea       fr_tab,a0           calc. address of the dialog data
          add.l     d0,a0
          lea       frbase,a2
          add.w     2(a0),a2
          move.w    (a0),d2
          bsr       form_do             display the dialog window
attrib13  cmp.w     (a2),d4             abort button clicked?
          bhs       attrib12
          cmp.w     #13,2(a2)           is pattern selection dialog?
          bne       attrib20
          cmp.b     #5,d4
          beq       attrib14            -> redraw demo box
          move.w    6(a2),d0
          move.w    20(a2),d1
          cmp.b     #3,d4
          bne.s     attrib18
          cmp.b     #2,d0               -- switch to next lower pattern --
          blo.s     attrib14
          cmp.b     #4,d0
          bne.s     attrib15
          moveq.l   #3,d0
          moveq.l   #12,d1
          bra.s     attrib16
attrib15  sub.b     #1,d1
          bne.s     attrib16
          sub.b     #1,d0
          moveq.l   #1,d1
          cmp.b     #2,d0
          bne.s     attrib16
          moveq.l   #24,d1
          bra.s     attrib16
attrib18  cmp.b     #6,d4               -- switch to next pattern --
          bne.s     attrib30
          cmp.b     #1,d0
          beq.s     attrib19
          addq.b    #1,d1
          cmp.b     #25,d1
          bhs.s     attrib19
          cmp.b     #3,d0
          bne.s     attrib16
          cmp.b     #13,d1
          blo.s     attrib16
attrib19  addq.b    #1,d0
          moveq.l   #1,d1
attrib16  move.w    d0,6(a2)            update dialog
          move.w    d1,20(a2)
          addq.l    #2,a2
          moveq.l   #1,d2
attrib17  move.w    TED_VAL(a2),d0
          bsr       form_wrt
          clr.w     d0
          clr.w     d1
          move.b    TED_INX(a2),d0
          bsr       obj_draw
          add.w     #14,a2
          dbra      d2,attrib17
          lea       frmuster,a2
attrib14  bsr       form_mus            return to dialog
          bra       attrib23
attrib30  cmp.b     #4,d4
          bne.s     attrib34
          moveq.l   #4,d0               -- User-defined pattern --
          bsr       obj_off
          move.w    MOUSE_CUR_XY(a6),d0
          sub.w     INTOUT+2(a6),d0
          move.w    MOUSE_CUR_XY+2(a6),d1      D0/1: XY-offset of pattern pixel clicked by user
          sub.w     INTOUT+4(a6),d1
          lsr.w     #3,d0               bit pos.
          lsr.w     #3,d1
          move.w    d1,d2
          add.w     d2,d2
          moveq.l   #15,d3
          sub.w     d0,d3
          bclr      #3,d3
          bne.s     attrib33
          addq.w    #1,d2
attrib33  lea       choofil,a0          flip bit within the pattern
          bchg      d3,(a0,d2.w)
          bsr       hide_m
          move.l    MOUSE_CUR_XY(a6),d0
          sub.l     INTOUT+2(a6),d0
          and.l     #$780078,d0
          add.l     INTOUT+2(a6),d0
          move.l    d0,d1
          add.l     #$70007,d1
          moveq.l   #10,d3
          move.l    logbase,a0          flip pixel in definition box within dialog
          bsr       work_bl2
          bsr       show_m
          bsr       form_mus
          bra       attrib23
attrib34  moveq.l   #4,d0               -- Clear pattern definition box --
          bsr       obj_off
          move.l    INTOUT+2(a6),d0
          move.l    d0,d1
          add.l     #$7f007f,d1
          move.l    logbase,a0
          clr.w     d3
          bsr       work_bl2
          moveq.l   #7,d0
          lea       choofil,a0
attrib35  clr.l     (a0)+
          dbra      d0,attrib35
          bsr       form_mus
          bra.s     attrib23
attrib20  cmp.w     #20,2(a2)           -- Linie attribute dialog --
          bne.s     attrib12
          cmp.b     #4,d4
          beq.s     attrib21
          cmp.b     #7,d4
          bne.s     attrib21
          moveq.l   #7,d0               line pattern definition
          bsr       obj_off
          move.w    MOUSE_CUR_XY(a6),d0
          sub.w     INTOUT+2(a6),d0
          lsr.w     #3,d0
          move.l    180(a3),a0
          eor.b     #%1101,(a0,d0.w)
          lea       choopat,a1
          move.w    (a1),d1
          eor.b     #15,d0
          bchg      d0,d1
          move.w    d1,(a1)
          moveq.l   #6,d0
          moveq.l   #1,d1
          bsr       obj_draw
attrib21  bsr       form_lin            line pattern demo
attrib23  moveq.l   #-1,d1              wait for release of mouse button
          move.l    a0,a0
          move.l    a0,a0
          tst.b     MOUSE_LBUT+1(a6)
          dbeq      d1,attrib23+2
          clr.w     MOUSE_LBUT(a6)
          bsr       form_do2            back to dialog handler
          bra       attrib13
          ;
attrib12  bsr       form_del
          rts
          ;
*---------------------------------------------------------------------
*               S E L E C T I O N   M E N U
*---------------------------------------------------------------------
          ;
evt_menu_sel:
          cmp.b     #MEN_IT_CHK_SEL,d0
          bne.s     fuenf_48
          move.w    d0,d2               --- Selection on/off ---
          tst.b     SEL_OPT_OVERLAY(a6)
          beq       fuenf_43            overlay mode enabled?
          bsr       over_alo            allocate buffer for overlay, if not yet done
          tst.b     SEL_OPT_OVERLAY(a6) ;success?
          bne       fuenf_43
          moveq.l   #MEN_IT_SEL_OVL,d0  uncheck "overlay" menu item
          clr.w     d1
          bsr       check_xx
fuenf_43  moveq.l   #MEN_IT_CHK_SEL,d2
          bra       drei_chg
          ;
fuenf_48  cmp.b     #MEN_IT_SEL_ERA,d0
          blo.s     fuenf_52
          cmp.b     #MEN_IT_SEL_INV,d0
          bhi.s     fuenf_52
          tst.w     SEL_STATE(a6)       --- Clear/Fill black/Invert ---
          beq       evt_menu_rts2
          bsr       over_cut
          sub.b     #MEN_IT_SEL_ERA,d0
          lsl.w     #1,d0
          lea       work_dat,a0
          move.w    (a0,d0.w),d3
          cmp.b     #10,d3              Invert?
          bne.s     white1
          bsr       over_old            -> Release combination mode
white1    bsr       save_scr
          bsr       save_buf
          move.l    BILD_ADR(a4),a0
          bsr       work_blk            execute raster operation
          move.w    #$ff00,UNDO_STATE(a6)
          bsr       fram_mod
          moveq.l   #MEN_IT_UNDO,d0     enable "undo" menu entry
          bsr       men_iena
          bra       win_rdw
          ;
fuenf_52  cmp.b     #MEN_IT_SEL_COMB,d0
          bne.s     fuenf_51
          lea       frverknu,a2         --- Combine selection with background ---
          moveq.l   #14,d2
          bsr       form_do
          bsr       form_del
          cmp.w     #17,d4
          beq       evt_menu_rts2
          move.b    frverknu+5,d1
          lea       comb_dat,a1
          ext.w     d1
          move.b    (a1,d1.w),SEL_OPT_COMB(a6)
          beq.s     knupf1
          moveq.l   #1,d1
knupf1    moveq.l   #MEN_IT_SEL_COMB,d0
          bsr       check_xx
          rts
          ;
fuenf_51  cmp.b     #MEN_IT_SEL_COPY,d0
          bne.s     fuenf_53
          not.b     SEL_OPT_COPY(a6)    --- Copy ---
          move.b    SEL_OPT_COPY(a6),d1
          and.w     #1,d1
          bsr       check_xx
          rts
          ;
fuenf_53  cmp.b     #MEN_IT_SEL_OVL,d0
          bne       fuenf_44
          tst.b     SEL_OPT_OVERLAY(a6) ;--- Toggle Overlay Mode ---
          beq.s     overlay1
          bsr       over_que            ++ Leaving overlay mode ++
          bne       evt_menu_rts2
          tst.l     SEL_OV_BUF(a6)
          beq.s     overlay4
          move.l    SEL_OV_BUF(a6),-(sp)
          move.w    #$49,-(sp)
          trap      #1                  mfree
          addq.l    #6,sp
          tst.l     d0
          bne       tos_err
          clr.l     SEL_OV_BUF(a6)
overlay4  clr.b     SEL_OPT_OVERLAY(a6)
          moveq.l   #MEN_IT_SEL_PAST,d0 ;disable "paste (selection)"
          bsr       men_idis
          moveq.l   #MEN_IT_SEL_DISC,d0 ;disable "discard (selection)"
          bsr       men_idis
          moveq.l   #MEN_IT_SEL_COMI,d0 ;disable "commit (selection)"
          bsr       men_idis
          bra.s     overlay2
          ;
overlay1  bsr       over_alo            ++ Enable overlay mode: alloc memory ++
          tst.b     SEL_OPT_OVERLAY(a6) ;out of memory?
          beq.s     overlay3
          tst.w     SEL_STATE(a6)       Existing selection?
          beq.s     overlay2
          bsr       over_beg
          moveq.l   #MEN_IT_SEL_DISC,d0             enable "discard (selection)"
          bsr       men_iena
overlay2  moveq.l   #MEN_IT_SEL_OVL,d0  check/uncheck menu item
          move.b    SEL_OPT_OVERLAY(a6),d1
          and.w     #1,d1
          bsr       check_xx
          rts
overlay3  moveq.l   #1,d0               abort due to memory allocation failure
          lea       stralovn,a0
          bsr       alertbox
          rts
          ;
fuenf_44  cmp.b     #MEN_IT_SEL_PAST,d0
          bne       fuenf_45
          tst.w     SEL_STATE(a6)       --- Paste selection ---
          bne       einfug5
          tst.b     SEL_FLAG_PASTABLE(a6)
          beq       evt_menu_rts2
          bsr       save_scr
          bsr       save_buf
          tst.b     SEL_OPT_OVERLAY(a6) ;Overlay mode?
          beq.s     einfug2
          move.b    SEL_OPT_COPY(a6),d2
          move.b    #-1,SEL_OPT_COPY(a6)
          bsr       over_beg
          move.b    d2,SEL_OPT_COPY(a6)
einfug2   bsr       win_abs             calc window coords.
          move.l    (a0),d0
          sub.l     d0,4(a0)
          move.l    UNDO_SEL_X2Y2(a6),d2
          sub.l     UNDO_SEL_X1Y1(a6),d2
          lea       win_xy+6,a2
          lea       YX_OFF(a4),a3
          bsr       cent_koo            center selection within the window
          move.w    #-1,SEL_STATE(a6)   initialize selection state struct
          move.l    d0,SEL_FRM_X1Y1(a6)
          move.l    d1,SEL_FRM_X2Y2(a6)
          move.l    d0,d2
          move.l    UNDO_SEL_X1Y1(a6),d0       copy selection content to the image
          move.l    UNDO_SEL_X2Y2(a6),d1
          move.l    UNDO_BUF_ADDR(a6),a0
          move.l    BILD_ADR(a4),a1
          cmp.l     a0,a1
          bne.s     einfug3
          move.l    bildbuff,a0
einfug3   bsr       copy_blk
          move.w    #MEN_IT_CHK_SEL,d2  check "selection" menu item
          bsr       drei_chg
          move.w    #-1,UNDO_STATE(a6)  ;enable undo
          move.l    #-1,UNDO_SEL_X1Y1(a6)
          move.l    #-1,UNDO_SEL_X2Y2(a6)
          moveq.l   #MEN_IT_UNDO,d0     ;enable "undo" menu entry
          bsr       men_iena
          moveq.l   #MEN_IT_SEL_PAST,d0
          bsr       men_idis
          tst.b     SEL_OPT_OVERLAY(a6)
          beq.s     einfug4
          moveq.l   #MEN_IT_SEL_DISC,d0 ;enable "discard (selection)"
          bsr       men_iena
          clr.b     SEL_FLAG_CHG(a6)
          clr.b     SEL_FLAG_CUTOFF(a6)
          clr.b     SEL_CUR_COMB(a6)
          clr.b     SEL_PREV_COMB(a6)
einfug4   move.l    menu_adr,a0         ; enable "erase" and following menu entries
          add.w     #MEN_IT_SEL_ERA*RSC_OBJ_SZ+11,a0
          moveq.l   #7,d0
einfug1   bclr.b    #3,(a0)
          add.w     #RSC_OBJ_SZ,a0
          dbra      d0,einfug1
          move.w    #$00ff,SEL_FLAG_PASTABLE(a6)    select paste mode for moving
          bra       win_rdw
einfug5   ;                             ++ Overlay-Mode-II ++
          tst.b     SEL_OPT_OVERLAY(a6)
          beq       evt_menu_rts2
          bsr       over_que
          bne       evt_menu_rts2
          tst.b     SEL_CUR_COMB(a6)
          sne.b     SEL_FLAG_CHG(a6)
          move.b    SEL_OPT_COPY(a6),d3
          move.b    #-1,SEL_OPT_COPY(a6)
          bsr       over_beg            copy selection content into image
          move.b    d3,SEL_OPT_COPY(a6)
          clr.w     UNDO_STATE(a6)
          moveq.l   #MEN_IT_UNDO,d0     ;disable "undo"
          bsr       men_idis
          moveq.l   #MEN_IT_SEL_PAST,d0 ;disable "paste (selection)"
          bsr       men_idis
          rts
          ;
fuenf_45  cmp.b     #MEN_IT_SEL_DISC,d0
          bne       fuenf_46
          tst.w     SEL_STATE(a6)       --- Discard selection ---
          beq       evt_menu_rts2
          move.b    SEL_OPT_OVERLAY(a6),d0
          beq       evt_menu_rts2
          bsr       save_scr
          tst.b     SEL_FLAG_CUTOFF(a6)
          bmi.s     werfweg2
          tst.b     SEL_CUR_COMB(a6)
          bne.s     werfweg3
werfweg2  bsr       save_buf
werfweg3  clr.b     SEL_STATE(a6)
          bsr       fram_del
          move.w    #-1,UNDO_STATE(a6)
          move.l    #$12345678,UNDO_BUF_ADDR(a6)   Magic for "Undo"
          clr.w     SEL_FLAG_PASTABLE(a6)   ; disable pasting
          move.b    SEL_CUR_COMB(a6),SEL_PREV_COMB(a6)  ; store current combination mode for undo, then reset
          clr.b     SEL_CUR_COMB(a6)
          move.w    #3999,d0
          move.l    SEL_OV_BUF(a6),a0
          move.l    BILD_ADR(a4),a1
werfweg1  move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d0,werfweg1
          moveq.l   #MEN_IT_UNDO,d0     ;enable "undo"
          bsr       men_iena
          moveq.l   #MEN_IT_SEL_PAST,d0 ;disable "paste"
          bsr       men_idis
          bra       win_rdw
          ;
fuenf_46  cmp.b     #MEN_IT_SEL_COMI,d0
          bne       fuenf_4b
          tst.w     SEL_STATE(a6)       --- Commit selection ---
          beq       evt_menu_rts2
          tst.b     SEL_OPT_OVERLAY(a6)
          beq       evt_menu_rts2
          moveq.l   #RSC_FORM_COMMIT,d1 ;+ Disable +
          bsr       rsrc_gad
          move.l    ADDROUT+0(a6),a3
          clr.w     82(a3)
          move.w    #8,106(a3)
          move.w    #8,130(a3)
          move.w    #7,80(a3)
          move.w    #5,104(a3)
          tst.b     SEL_CUR_COMB(a6)    combine with image area?
          bne.s     ueber1
          tst.b     SEL_FLAG_CUTOFF(a6)
          beq.s     ueber4
          bset.b    #3,83(a3)
          bclr.b    #3,107(a3)
          move.b    #5,81(a3)
          move.b    #7,105(a3)
          bra.s     ueber2
ueber1    tst.b     SEL_FLAG_CUTOFF(a6) ;selection clipped?
          beq.s     ueber2
          bclr.b    #3,107(a3)
          bclr.b    #3,131(a3)
ueber2    lea       fruebern,a2         + ask user +
          moveq.l   #22,d2
          bsr       form_do
          bsr       form_del
          cmp.b     #6,d4               cancel?
          beq.s     ueber5
          subq.b    #2,d4
          btst      #0,d4
          beq.s     ueber3
          clr.b     SEL_CUR_COMB(a6)    choose combination mode
ueber3    btst      #1,d4
          beq.s     ueber4
          clr.b     SEL_FLAG_CUTOFF(a6) ;remove clipped part
          clr.w     UNDO_STATE(a6)      and disable "undo"
          moveq.l   #MEN_IT_UNDO,d0     disable "undo"
          bsr       men_idis
ueber4    tst.b     SEL_CUR_COMB(a6)    + keep "commit" enabled? +
          bne.s     ueber5
          tst.b     SEL_FLAG_CUTOFF(a6)
          bne.s     ueber5
          moveq.l   #MEN_IT_SEL_COMI,d0 ;disable "commit"
          bsr       men_idis
ueber5    rts
          ;
fuenf_4b  cmp.b     #MEN_IT_SEL_MIRR,d0
          bne       fuenf_4c
          tst.w     SEL_STATE(a6)       --- Mirror selection ---
          beq       evt_menu_rts2
          bsr       over_cut
          lea       stralspi,a0
          moveq.l   #2,d0
          bsr       alertbox
          move.w    d0,d4
          cmp.b     #2,d4
          beq       evt_menu_rts2
          bsr       over_old
          bsr       save_scr
          bsr       save_buf
          cmp.b     #1,d4
          bne       spiver
          move.w    SEL_FRM_X2Y2+2(a6),d7    -- mirror at horizontal line --
          sub.w     SEL_FRM_X1Y1+2(a6),d7
          beq       evt_menu_rts2
          move.l    bildbuff,a0
          move.l    BILD_ADR(a4),a1
          move.w    SEL_FRM_X1Y1+2(a6),d0
          mulu.w    #80,d0                   address
          add.l     d0,a0
          move.w    SEL_FRM_X2Y2+2(a6),d0
          mulu.w    #80,d0
          add.l     d0,a1
          move.w    SEL_FRM_X1Y1+0(a6),d0
          move.w    SEL_FRM_X2Y2+0(a6),d1
          move.w    d0,d3
          move.w    d1,d4
          and.w     #15,d0
          and.w     #15,d1
          lsr.w     #3,d3
          lsr.w     #4,d4
          bclr      #0,d3
          add.w     d3,a0               X start offset
          add.w     d3,a1
          lea       rand_tab,a2
          lsl.w     #1,d0
          lsl.w     #1,d1
          move.w    (a2,d0.w),d6        bitmask for left-most word
          move.w    2(a2,d1.w),d2       bitmask for right-most word
          lsr.w     #1,d3
          sub.w     d3,d4               width of middle portion
          bne.s     spihor7
          not.w     d2                  left-most = right-most word
          and.w     d2,d6
spihor7   subq.w    #2,d4
          move.w    d6,d5
          not.w     d5
          move.w    d2,d3
          not.w     d3
spihor1   move.l    a0,a2               + Loop +
          move.l    a1,a3
          move.w    (a0)+,d0
          and.w     d6,d0
          and.w     d5,(a1)
          or.w      d0,(a1)+
          move.w    d4,d0               no middle portion?
          bmi.s     spihor5
spihor2   move.w    (a0)+,(a1)+
          dbra      d0,spihor2
spihor3   move.w    (a0)+,d0
          and.w     d3,d0
          and.w     d2,(a1)
          or.w      d0,(a1)+
spihor4   lea       80(a2),a0
          lea       -80(a3),a1
          dbra      d7,spihor1
          move.w    #$ff00,UNDO_STATE(a6)  ;enable "undo"
          bsr       fram_mod
          moveq.l   #MEN_IT_UNDO,d0
          bsr       men_iena
          bra       win_rdw
spihor5   cmp.w     #-1,d4              is width two words?
          beq       spihor3
          bra       spihor4
          ;
spiver    move.w    SEL_FRM_X2Y2+0(a6),d1    -- mirror at vertical line --
          cmp.w     SEL_FRM_X1Y1+0(a6),d1
          bls       evt_menu_rts2
          move.w    SEL_FRM_X2Y2+2(a6),d7    height
          move.w    SEL_FRM_X1Y1+2(a6),d0
          sub.w     d0,d7
          move.l    bildbuff,a0
          move.l    BILD_ADR(a4),a1
          mulu.w    #80,d0              Y start offset
          add.l     d0,a0
          add.l     d0,a1
          move.w    SEL_FRM_X1Y1(a6),d0
          move.w    d0,d3
          move.w    d1,d4
          and.w     #15,d0
          and.w     #15,d1
          lsr.w     #3,d3
          lsr.w     #3,d4
          bclr      #0,d3
          bclr      #0,d4
          add.w     d3,a0               X start offset
          add.w     d4,a1
          lea       rand_tab,a2
          lsl.w     #1,d0
          lsl.w     #1,d1
          moveq.l   #32,d6              bitmask right border
          sub.w     d0,d6
          move.w    (a2,d6.w),d6
          moveq.l   #30,d5              bitmask left border
          sub.w     d1,d5
          move.w    (a2,d5.w),d5
          sub.w     d3,d4               width of middle portion
          lsr.w     #1,d4
          bne.s     spiver9
          and.w     d5,d6               left-most = right-most word
spiver9   subq.w    #2,d4
spiver1   move.l    a0,a2               +++++ Loop +++++
          move.l    a1,a3
          move.w    (a0)+,d0
          moveq.l   #15,d2
spiver2   lsr.w     #1,d0               left border
          roxl.w    #1,d1
          dbra      d2,spiver2
          not.w     d6
          and.w     d6,d1
          not.w     d6
          and.w     d6,(a1)
          or.w      d1,(a1)
          move.w    d4,d3
          bmi       spiver3
spiver4   move.w    (a0)+,d0
          moveq.l   #15,d2
spiver5   lsr.w     #1,d0               middle part
          roxl.w    #1,d1
          dbra      d2,spiver5
          move.w    d1,-(a1)
          dbra      d3,spiver4
spiver6   move.w    (a0),d0             right border
          moveq.l   #15,d2
spiver7   lsr.w     #1,d0
          roxl.w    #1,d1
          dbra      d2,spiver7
          and.w     d5,d1
          not.w     d5
          and.w     d5,-(a1)
          not.w     d5
          or.w      d1,(a1)
spiver8   lea       80(a2),a0
          lea       80(a3),a1
          dbra      d7,spiver1
          move.w    SEL_FRM_X1Y1(a6),d0    ++ correct shift ++
          move.w    SEL_FRM_X2Y2(a6),d6
          and.w     #15,d0
          and.w     #15,d6
          moveq.l   #15,d5              D5/D6: remaining width left/right
          sub.w     d0,d5
          move.w    SEL_FRM_X1Y1(a6),d3       D3/D4: X1-X2 coords.
          move.w    SEL_FRM_X2Y2(a6),d4
          cmp.w     d5,d6
          beq.s     spiver10            not needed -> done
          blo.s     spiver11
          sub.w     d5,d6               + to the right +
          move.w    d3,d0
          sub.w     d6,d0
          move.w    d0,-(sp)
          move.w    d3,d1
          subq.w    #1,d1
          move.w    d1,-(sp)
          move.w    d4,d1
          sub.w     d6,d1
          bra.s     spiver12
spiver11  sub.w     d6,d5               + to the left +
          move.w    d4,d0
          addq.w    #1,d0
          move.w    d0,-(sp)
          move.w    d4,d1
          add.w     d5,d1
          move.w    d1,-(sp)
          move.w    d3,d0
          add.w     d5,d0
spiver12  move.l    SEL_FRM_X1Y1(a6),d2    + shift +
          swap      d0
          swap      d1
          move.w    SEL_FRM_X1Y1+2(a6),d0
          move.w    SEL_FRM_X2Y2+2(a6),d1
          move.l    BILD_ADR(a4),a0
          move.l    a0,a1
          bsr       copy_blk
          move.w    (sp)+,d1            + fill gap +
          move.w    (sp)+,d0
          swap      d0
          swap      d1
          move.w    SEL_FRM_X1Y1+2(a6),d0
          move.w    SEL_FRM_X2Y2+2(a6),d1
          move.l    d0,d2
          move.l    bildbuff,a0
          move.l    BILD_ADR(a4),a1
          bsr       copy_blk
spiver10  move.w    #$ff00,UNDO_STATE(a6) ;enable "undo"
          bsr       fram_mod
          moveq.l   #MEN_IT_UNDO,d0
          bsr       men_iena
          bra       win_rdw
spiver3   cmp.w     #-1,d4
          beq       spiver6
          bra       spiver8
          ;
*---------------------------------------------------------------------
*               T O O L S   M E N U
*---------------------------------------------------------------------
evt_menu_tools:
          cmp.b     #MEN_IT_CHK_COOR,d0
          bne.s     sechs_5c
          move.w    d0,d7               --- Command: Store mouse coords. ---
          bsr       over_que
          bne       evt_menu_rts2
          move.w    d7,-(sp)
          bsr       fram_del
          move.w    (sp)+,d2
          bra       drei_chg
          ;
sechs_5c  cmp.b     #MEN_IT_CFG_GRID,d0
          bne.s     sechs_5a
          moveq.l   #15,d2              --- Command: Configure grid size ---
          lea       frraster,a2
          bsr       form_do             display dialog window
          bsr       form_del
          moveq.l   #1,d2
          addq.l    #6,a2
raster1   move.w    28(a2),d1
          cmp.w     (a2),d1             starting offset > grid width?
          blo.s     raster2
          ext.l     d1
          divu      (a2),d1
          swap      d1
          move.w    d1,28(a2)           new offset
          add.w     #14,a2
raster2   dbra      d2,raster1
          rts
          ;
sechs_5a  cmp.b     #MEN_IT_CHK_GRID,d0
          bne.s     sechs_59
          lea       chooras,a0          --- Enable/disable rastering ---
          move.w    (a0),d1
          eor.b     #1,d1
          move.w    d1,(a0)
          bsr       check_xx
          rts
          ;
sechs_59  cmp.b     #MEN_IT_SHOW_COO,d0
          bne.s     sechs_56
          lea       chookoo,a0          --- Enable/disable: Show mouse coords. ---
          move.w    (a0),d1
          eor.b     #1,d1
          move.w    d1,(a0)
          move.w    #$777,2(a0)
          bsr.s     check_xx
          move.w    chookoo,d0
          bne       koos_mak            display & rts
          ;
          pea       koostr1             clear coords. display
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          rts
          ;
sechs_56  cmp.b     #MEN_IT_COORDS,d0
          bne.s     sechs_57
          move.w    choofig,d1          --- Coordinates ---
          cmp.b     #MEN_IT_CHK_SEL,d1
          bne.s     koord1
          moveq.l   #MEN_IT_RECT,d1
koord1    lea       koanztab,a0
          sub.w     #MEN_IT_PENCIL,d1
          clr.l     d2
          move.b    (a0,d1.w),d2        number of coords.
          beq.s     koord2
          bsr       get_koos            open dialog window
          ;cmp.w     #9,d4
          ;beq.s     koords              cancel
koord2    rts

sechs_57  rts                           --- Zoom View ---

*---------------------------------------------------------SUBFUNCTIONS

check_xx  ;
          aes       31 2 1 1 0 !d0 !d1 !menu_adr  ;menu_icheck
          rts                                      D0:index/D1:0-1
men_idis  ;
          aes       32 2 1 1 0 !d0 0 !menu_adr  ;menu_ienable (intin[1]:=disable)
          rts                                      D0:index/D1:0-1
men_iena  ;
          aes       32 2 1 1 0 !d0 1 !menu_adr  ;menu_ienable (intin[1]:=enable)
          rts                                      D0:index/D1:0-1
          ;
maus_bne  moveq.l   #2,d0               shape: bee
          bra.s     maus_al2
maus_neu  move.w    choomou,d0          ** current mouse pointer shape **
          bra.s     maus_al2
maus_alt  clr.w     d0                  shape: arrow
maus_al2  move.l    a0,-(sp)
          lea       maus_blk,a0
          aes       78 1 1 1 0 !d0 !a0  ;set_mouse_form
          move.l    (sp)+,a0
          rts
obj_off   ;
          aes       44 1 3 1 0 !d0 !a3  ;XY-Koo. des D0. Objektes
          rts
          ;
obj_draw  move.l    d6,INTIN+4(a6)            ** draw object **
          move.l    d7,INTIN+8(a6)
          move.l    a3,ADDRIN+0(a6)
          aes       42 6 1 1 0 !d0 !d1  ;obj_draw
          rts
          ;
over_cut                                ** "discard clipped selection?" **
          tst.b     SEL_OPT_OVERLAY(a6)
          beq.s     over_cu2
          tst.b     SEL_FLAG_CUTOFF(a6)
          bpl.s     over_cu2
          move.w    d0,d2
          lea       stralcut,a0
          moveq.l   #1,d0
          bsr       alertbox
          cmp.w     #1,d0
          bne.s     over_cu1
          move.w    d2,d0
          clr.b     SEL_FLAG_CUTOFF(a6)
over_cu2  rts
over_cu1  addq.l    #4,sp               no -> abort
          rts
          ;
over_old  move.b    SEL_OPT_OVERLAY(a6),d0  ;** undo combination **
          beq       over_ol3
          tst.b     SEL_CUR_COMB(a6)
          beq.s     over_ol1
          tst.b     SEL_FLAG_CUTOFF(a6)
          bmi.s     over_ol1
          movem.l   d2-d7/a2-a3,-(sp)
          move.l    UNDO_SEL_X1Y1(a6),d0
          move.l    UNDO_SEL_X2Y2(a6),d1
          tst.b     SEL_FLAG_CUTOFF(a6)
          beq.s     over_ol2
          move.l    SEL_PREV_X1Y1(a6),d0
          move.l    SEL_PREV_X2Y2(a6),d1
over_ol2  move.l    SEL_FRM_X1Y1(a6),d2
          move.l    bildbuff,a0
          move.l    rec_adr,a1
          move.l    BILD_ADR(a1),a1
          bsr       copy_blk
          movem.l   (sp)+,d2-d7/a2-a3
over_ol1  move.b    #-1,SEL_FLAG_CHG(a6)  ; modification done
          move.b    SEL_CUR_COMB(a6),SEL_PREV_COMB(a6)
          clr.b     SEL_CUR_COMB(a6)
          moveq.l   #MEN_IT_SEL_PAST,d0 ;enable "paste (selection)"
          bsr       men_iena
          tst.b     SEL_FLAG_CUTOFF(a6)
          bmi.s     over_ol3
          moveq.l   #MEN_IT_SEL_COMI,d0 ;disable "commit"
          bsr       men_idis
over_ol3  rts
          ;
over_alo  tst.l     SEL_OV_BUF(a6)      ** Allocate memory for selection overlay buffer **
          bne       over_al1
          move.l    #32010,-(sp)
          move.w    #$48,-(sp)
          trap      #1
          addq.l    #6,sp
          tst.l     d0
          bmi.s     over_al2
          move.l    d0,SEL_OV_BUF(a6)
over_al1  move.b    #$ff,SEL_OPT_OVERLAY(a6)
          rts
over_al2  clr.b     SEL_OPT_OVERLAY(a6)
          rts

over_beg  move.w    #1999,d0            ** Prepare overlay mode **
          move.l    rec_adr,a0
          move.l    BILD_ADR(a0),a0
          move.l    SEL_OV_BUF(a6),a1
over_be1  move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d0,over_be1
          tst.b     SEL_OPT_COPY(a6)    copy?
          bne       evt_menu_rts2
          move.l    SEL_OV_BUF(a6),a0
          clr.w     d3
          ;
work_blk  move.l    SEL_FRM_X1Y1(a6),d0       ** Execute raster copy via VDI **
          move.l    SEL_FRM_X2Y2(a6),d1
work_bl2  lea       mfdb_q,a1           address of source+target MFDB struct array
          move.l    a0,(a1)             set address of source bitmap (or 0 for screen)
          move.l    a0,20(a1)           set address of target bitmap = source
          move.l    d1,d2
          sub.l     d0,d2
          move.l    d2,4(a1)            width & height of the source region
          move.l    d2,24(a1)           = width & height of the destination region
          move.l    a1,CONTRL+14(a6)
          add.w     #20,a1              pointer to target MFDB
          move.l    a1,CONTRL+18(a6)
          move.l    d0,PTSIN+0(a6)      fill PTSIN: upper-left XY and lower-right XY in src and dest bitmaps
          move.l    d1,PTSIN+4(a6)
          move.l    d0,PTSIN+8(a6)
          move.l    d1,PTSIN+12(a6)
          move.w    d3,INTIN+0(a6)      D3: combination mode
          vdi       109 4 1             ;copy_raster
          rts
          ;
cent_koo  moveq.l   #1,d7               ** Center selection **
          move.l    #$27f018f,d6        D2: selection width/height; compare to max 640-1/400-1
cent_ko1  cmp.w     (a2),d2             does selection fit into the window?
          bhi.s     cent_ko2
          move.w    (a2),d0             +++  Selections fits into window  +++
          sub.w     d2,d0               D0: window width - selection width
          lsr.w     #1,d0               D0:=D0/2
          add.w     -4(a2),d0           D0:=D0+window root offset
          add.w     (a3),d0             convert to absolute coord.
          move.w    d0,d1
          add.w     d2,d1               D1: X2Y2 coords.
          bra.s     cent_ko3
cent_ko2  move.w    d2,d1               +++ Selection does not fit into window +++
          sub.w     (a2),d1
          lsr.w     #1,d1
          move.w    -4(a2),d0
          add.w     (a3),d0
          sub.w     d1,d0
          move.w    d0,d1
          add.w     d2,d1               D0/D1: new selection coords.
          tst.w     d0
          bpl.s     cent_ko4
          not.w     d0                  below screen border
          addq.w    #1,d0
          add.w     d0,d1
          clr.w     d0
          bra.s     cent_ko3
cent_ko4  move.w    d1,d3
          sub.w     d6,d3
          bmi.s     cent_ko3
          sub.w     d3,d0               beyond
          move.w    d6,d1
cent_ko3  subq.l    #2,a2               ++ end of loop ++
          addq.l    #2,a3
          swap      d6
          swap      d2
          swap      d1                  D0/D1: border coords.
          swap      d0
          dbra      d7,cent_ko1
          rts
          ;
form_do   bsr       maus_alt            ** Open dialog window **
          aes       107 1 1 0 0 1       ;wind_update
          move.w    d2,d1
          bsr       rsrc_gad
          move.l    ADDROUT+0(a6),a3    A3: address of object tree
          aes       54 0 5 1 0 !a3      ;form_center
          move.l    INTOUT+2(a6),d6
          move.l    INTOUT+6(a6),d7
          sub.l     #$30003,d6
          add.l     #$60006,d7
          move.l    d6,INTIN+2(a6)
          move.l    d7,INTIN+6(a6)
          move.l    d6,INTIN+10(a6)
          move.l    d7,INTIN+14(a6)
          aes       51 9 1 1 0 0        ;form_dial
          clr.w     d0
          moveq.l   #4,d1
          bsr       obj_draw            ;obj_draw
          bsr       init_ted            set addresses in TED record
          lea       form_buf,a0
          clr.w     (a0)
          cmp.w     #13,2(a2)
          bne.s     form_do3
          bsr       form_mud            fill pattern demo box
          bra.s     form_do4
form_do3  cmp.w     #20,2(a2)
          bne.s     form_do2
          bsr       form_lin            fill line demo box
form_do4  lea       form_buf,a0
          move.w    (a2),(a0)
          move.w    6(a2),2(a0)
          move.w    20(a2),4(a0)
          move.w    34(a2),6(a0)
form_do2  ;
          aes       50 1 1 1 0 0 !a3    ;form_do
          move.w    INTOUT+0(a6),d4     D4: index of exit button
          move.w    d4,d0
          mulu.w    #RSC_OBJ_SZ,d0              deselect exit button
          bclr      #0,11(a3,d0.l)
          move.w    (a2)+,d0
          addq.w    #1,d0
          cmp.w     d0,d4               cancel button?
          beq       form_rdw
          clr.b     d3                  --- validate input field content ---
          move.l    a2,-(sp)
form2     move.w    TED_NR(a2),d0
          bmi.s     form1
          bsr       read_num
          clr.w     d0
          move.b    TED_MIN(a2),d0
          cmp.w     d0,d1
          blo.s     form3
          move.w    TED_MAX(a2),d0
          cmp.w     d0,d1
          bls.s     form4
form3     bsr       form_wrt            invalid -> replace with default
          moveq.l   #-1,d3
          move.b    TED_INX(a2),d0
          ext.w     d0
          clr.w     d1
          bsr       obj_draw            ...and redraw
form4     add.w     #14,a2
          bra       form2
form1     move.l    (sp),a2
          tst.b     d3
          beq.s     form_tak            all Ok?
          move.w    form_buf,d0
          beq.s     form6
          cmp.w     d0,d4
          blo.s     form_tak
form6     addq.l    #4,sp
          subq.l    #2,a2               not ok -> back to dialog
          move.w    d4,d0
          clr.w     d1
          bsr       obj_draw
          bra       form_do2
          ;
form_tak  move.w    TED_NR(a2),d0       --- Process dialog input ---
          bmi.s     form_tk1
          bsr       read_num            ++ TEDINFOS ++
          move.w    d1,TED_VAL(a2)
          add.w     #14,a2
          bra       form_tak
form_tk1  move.w    form_buf,d0
          beq.s     form_tk2
          cmp.b     d0,d4               touch exit -> cancel
          bhi.s     form_tk5
form_tk2  move.b    (a2)+,d0            ++ radio-buttons ++
          beq.s     form_tk5
          move.l    a3,a0
          mulu.w    #RSC_OBJ_SZ,d0
          add.l     d0,a0
          clr.b     d0
          move.w    8(a0),d1
form_tk3  btst.b    #0,11(a0)           search for selected one...
          bne.s     form_tk4
          add.w     #RSC_OBJ_SZ,a0
          addq.b    #1,d0
          cmp.w     8(a0),d1            ..only within buttons
          beq       form_tk3
form_tk4  move.b    d0,(a2)+
          bra       form_tk1
form_tk5  move.l    (sp)+,a2            ++ check-buttons ++
          cmp.w     #16,(a2)
          bne       form_rw1
          lea       107(a3),a0
          moveq.l   #5,d0
          clr.w     d1
form_tk7  btst.b    #0,(a0)
          beq.s     form_tk6
          moveq.l   #5,d2
          sub.b     d0,d2
          bset      d2,d1
form_tk6  add.w     #RSC_OBJ_SZ,a0
          dbra      d0,form_tk7
          lea       chootxt,a0
          move.w    d1,(a0)
          bra       form_rw1
          ;
form_rdw  move.l    a2,-(sp)            --- insert defaults ---
          move.w    form_buf,d0
          beq.s     form_rw2
          move.w    form_buf+2,4(a2)
          move.w    form_buf+4,18(a2)
          move.w    form_buf+6,32(a2)
form_rw2  move.w    (a2),d0             ++ Tedinfos ++
          bmi.s     form_rw3
          move.w    TED_VAL(a2),d0      insert default values
          bsr.s     form_wrt
          add.w     #14,a2
          bra       form_rw2
form_rw3  addq.l    #2,a2               ++ radio-buttons ++
form_rw4  clr.w     d0
          move.b    (a2)+,d0
          beq.s     form_rw8
          mulu.w    #RSC_OBJ_SZ,d0
          move.l    a3,a0
          add.l     d0,a0
          clr.b     d0
          move.b    (a2)+,d1
form_rw5  cmp.b     d0,d1
          bne.s     form_rw6
          move.b    #1,11(a0)
          bra.s     form_rw7
form_rw6  clr.b     11(a0)
form_rw7  add.w     #RSC_OBJ_SZ,a0
          addq.b    #1,d0
          btst.b    #4,9(a0)
          bne       form_rw5
          bra       form_rw4
form_rw8  move.l    (sp)+,a2            ++ check-buttons ++
          cmp.w     #16,(a2)
          bne.s     form_rw1
          lea       107(a3),a0
          move.w    chootxt,d1
          moveq.l   #5,d0
form_rw9  btst      d0,d1
          beq.s     form_rx1
          bset.b    #0,(a0)
          bra.s     form_rx2
form_rx1  bclr.b    #0,(a0)
form_rx2  add.w     #RSC_OBJ_SZ,a0
          dbra      d0,form_rw9
form_rw1  subq.l    #2,a2
          rts
          ;
form_wrt  move.l    TED_ADR(a2),a0      ** Print decimal number **
          move.w    TED_LEN(a2),d1      D0.w: value / A0: address of record
          add.w     d1,a0
          addq.l    #1,a0
          ext.l     d0
form_wr1  cmp.w     #10,d0              decimal value in string
          blo.s     form_wr2
          divu      #10,d0
          swap      d0
form_wr2  add.b     #'0',d0
          move.b    d0,-(a0)
          clr.w     d0
          swap      d0
          dbra      d1,form_wr1
          rts
          ;
form_del  move.l    rec_adr,a4          ** Remove dialog window **
          aes       104 2 5 0 0 !(a4) 10  ;wind_get
          move.w    INTOUT+2(a6),d0
          cmp.w     (a4),d0
          beq.s     form_de1            is in top-level window
          clr.l     d6
          move.l    #$2800190,d7
form_de1  move.l    d6,INTIN+2(a6)
          move.l    d7,INTIN+6(a6)
          move.l    d6,INTIN+10(a6)
          move.l    d7,INTIN+14(a6)
          aes       51 9 1 1 0 3        ;form_dial
          aes       107 1 1 0 0 0       ;wind_update
          move.w    choomou,d0
          bne       maus_neu
          rts
          ;
form_mud  bsr       hide_m              ** Fill pattern definition box **
          moveq.l   #4,d0
          bsr       obj_off
          move.l    logbase,a1
          move.w    INTOUT+4(a6),d0
          mulu.w    #80,d0
          add.l     d0,a1
          move.w    INTOUT+2(a6),d0
          lsr.w     #3,d0
          add.w     d0,a1
          lea       choofil,a0
          moveq.l   #15,d0
form_mu3  move.w    (a0)+,d2
          moveq.l   #15,d1
form_mu4  btst      d1,d2
          beq.s     form_mu5
          moveq.l   #7,d3
          add.w     #640,a1
form_mu6  sub.w     #80,a1
          move.b    #$ff,(a1)
          dbra      d3,form_mu6
form_mu5  addq.l    #1,a1
          dbra      d1,form_mu4
          add.w     #624,a1
          dbra      d0,form_mu3
          bra.s     form_mu7
form_mus  bsr       hide_m              ** Fill pattern demo box **
form_mu7  ;
          vdi       23 0 1 !6(a2)
          vdi       24 0 1 !20(a2)
          vdi       25 0 1 1
          vdi       32 0 1 1
          cmp.w     #4,6(a2)
          bne.s     form_mu2
          moveq.l   #15,d0
          lea       choofil,a0
          lea       INTIN(a6),a1
form_mu1  move.w    (a0)+,(a1)+
          dbra      d0,form_mu1
          vdi       112 0 16
form_mu2  moveq.l   #5,d0
          bsr       obj_off
          move.l    INTOUT+2(a6),d0
          move.l    d0,PTSIN+0(a6)
          add.l     140(a3),d0
          sub.l     #$10001,d0
          move.l    d0,PTSIN+4(a6)
          vdi       114 2 0             ;fill_rectangle
          vdi       23 0 1 1
          vdi       25 0 1 1
          vdi       32 0 1 3
          bra       show_m
          ;
form_lin  bsr       hide_m              ** Draw line pattern demo **
          moveq.l   #4,d0
          clr.w     d1
          bsr       obj_draw            remove box
          vdi       15 0 1 !34(a2)
          vdi       16 1 0 !20(a2) 0
          vdi       17 0 1 1
          vdi       113 0 1 !choopat
          vdi       32 0 1 1
          moveq.l   #4,d0
          bsr       obj_off
          move.l    INTOUT+2(a6),d0
          move.w    118(a3),d1
          lsr.w     #1,d1
          add.w     d1,d0
          move.l    d0,PTSIN+0(a6)
          swap      d0
          add.w     116(a3),d0
          subq.w    #1,d0
          swap      d0
          move.l    d0,PTSIN+4(a6)
          vdi       6 2 0               ;polyline
          vdi       16 1 0 1 0
          vdi       15 0 1 1
          vdi       32 0 1 3
          bra       show_m
          ;
read_num  move.l    TED_ADR(a2),a0      ** Evaluate TEDINFO string **
          move.w    TED_LEN(a2),d2
          clr.w     d0
          move.w    TED_VAL(a2),d1      default content
          cmp.b     #'@',(a0)           Nil-string?
          beq.s     read1
          tst.b     (a0)
          beq.s     read1
          clr.w     d1
readloop  move.b    (a0)+,d0
          sub.b     #'0',d0
          bmi.s     read1               no digits -> done
          cmp.b     #9,d0
          bhi.s     read1
          mulu.w    #10,d1
          add.w     d0,d1
          dbra      d2,readloop
read1     rts
          ;
init_ted  tst.w     2(a2)               ** set TEDINFO addresses **
          bmi       evt_menu_rts2
          move.l    TED_ADR+2(a2),a0
          cmp.l     #$10,a0
          bhi       evt_menu_rts2
          move.l    a2,-(sp)
          addq.l    #2,a2
init_te1  moveq.l   #8,d0
          move.w    (a2),d1
          bsr       rsrc_gad+2
          move.l    ADDROUT+0(a6),a0
          move.l    (a0),a0
          add.w     TED_ADR+2(a2),a0
          move.l    a0,TED_ADR(a2)
          add.w     #14,a2
          tst.w     (a2)
          bpl       init_te1
          move.l    (sp)+,a2
          rts
*-------------------------------------------------------MENU-VARIABLES
choopat   dc.w    $aaaa                 ; bitmask of user-defined line pattern
chooras   dc.w    0                     ; flag: grid mode enabled?
chootxt   dc.w    0
choomou   dc.w    0                     ; flag: 0:=normal mouse shape; $ff:cross
          dc.w    0,0                   ; address of "Cross" menu item text
          dc.b    '  Pfeil-Maus',0      ; alternative menu item text
chookoo   dc.w    0                     ; flag: 0:disabled; 1:enable mouse coord. display in menu bar
          dc.w    -1,-1                 ; last written mouse X/Y coords.
choofil   dcb.w   16,0                  ; bitmasks of user-defined fill pattern
*--------------------------------------------------------------STRUCTS
comb_dat  dc.b    0,1,6,7,2,11,4,13,14,9,8
work_dat  dc.w    0,15,10
mfdb_q    dc.w    0000,0000,00,00,40,0,1,0,0,0
          dc.w    0000,0000,00,00,40,0,1,0,0,0
maus_blk  dc.w    7,7,1,0,1,$fffe,$fffe,$c386,$c386,$c386,$c386,$fc7e
          dc.w    $fc7e,$fc7e,$c386,$c386,$c386,$c386,$fffe,$fffe,0
          dc.w    $fffe,$8102,$8102,$8102,$8102,$8102,$8002,$fc7e
          dc.w    $8002,$8102,$8102,$8102,$8102,$8102,$fffe,0
*--------------------------------------------------------------STRINGS
stralspi  dc.b    '[0][Mirror around which axis?| |'
          dc.b    '][Horizontal|Cancel|Vertical]',0
stralfat  dc.b    '[3][Sorry, this feature is|'
          dc.b    'not yet implemented.'
          dc.b    '][Cancel]',0
stralovn  dc.b    '[3][Not enough free memory'
          dc.b    '][Cancel]',0
stralcut  dc.b    '[1][The part of selection outside|'
          dc.b    'of the window will be lost!'
          dc.b    '][Ok|Cancel]',0
*-------------------------------------------------------DIALOG-STRUCTS
*   Ok-Nr, { TED-Nr,L„nge-1,Default,Index*256+min,max,Offset.l } ,-1,
*          { Button-Nr*256+selected Button } ,0
*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
frinfobo  dc.w   8,-1,0
frsegmen  dc.w   9,4,2,0,8,360,0,0,4,0,0,8,9,0,3
          dc.w     4,2,0,8,360,0,4,4,0,0,8,9,0,7,-1,0
frkoordi  dc.w   8,6,2,0,4,639,0,0,6,2,0,4,399,0,3
          dc.w     7,2,0,5,639,0,0,7,2,0,5,399,0,3,-1,0
frbase:
frmodus   dc.w  10,-1,$600,0
frpunkt   dc.w  18,8,0,1,$110,8,0,0,9,0,1,17,1,0,0,-1,$400,$b01,0  ;dot writing mode 0|1|INV at +35 unused
frpinsel  dc.w  11,10,0,4,9,9,0,0,11,0,1,10,1,0,0,-1,$302,0
frsprayd  dc.w  10,12,1,10,$108,99,0,0,-1,$401,0
frmuster  dc.w  11,13,0,1,$107,4,0,0,14,1,1,9,24,0,0
          dc.w     15,0,1,10,1,0,0,-1,0
frtext    dc.w  23,16,1,13,$40a,26,0,0,17,2,0,11,270,0,0
          dc.w     18,0,1,12,1,0,0,-1,$f01,$1300,0
frradier  dc.w   9,19,1,16,$103,99,0,0,19,1,10,$103,99,0,2,-1,$600,0
frlinie   dc.w  20,20,0,1,3,1,0,0,21,1,1,$105,40,0,0
          dc.w     22,0,1,$108,7,0,0,-1,$b00,$f00,0
frdrucke  dc.w  16,-1,$300,$600,$d00,0
frdatei   dc.w  15,25,2,640,$103,640,0,0,25,2,400,$103,400,0,3,-1
          dc.w     $a00,$600,0
frraster  dc.w  07,26,1,10,$104,99,0,0,27,1,10,$105,99,0,0
          dc.w     28,2,0,6,639,0,0,28,2,0,6,399,0,3,-1,0
frzeiche  dc.w  02,29,2,0,0,255,0,0,-1,0
frverknu  dc.w  16,-1,$500,0
frrotier  dc.w  13,30,2,180,12,359,0,0,-1,$401,$800,0
frzoomen  dc.w  13,31,0,1,10,9,0,0,31,2,500,10,999,0,1
          dc.w     31,0,1,10,9,0,4,31,2,500,10,999,0,5,-1,$400,$500
          dc.w     $700,0
frzerren  dc.w  16,32,1,4,15,99,0,0,-1,$400,$800,0
frprojek  dc.w  13,-1,$400,$800,0
fruebern  dc.w  05,-1,$300,0
*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          ; table of attribute forms, indexed by menu entry
fr_tab    dc.w    RSC_FORM_COMB,frmodus-frbase     ; MEN_IT_CFG_COMB
          dc.w    -1,-1                            ; menu separator
          dc.w    RSC_FORM_PENC,frpunkt-frbase     ; MEN_IT_CFG_PENC
          dc.w    RSC_FORM_BRUSH,frpinsel-frbase   ; MEN_IT_CFG_BRUS
          dc.w    RSC_FORM_SPRAY,frsprayd-frbase   ; MEN_IT_CFG_SPAY
          dc.w    RSC_FORM_FILL,frmuster-frbase    ; MEN_IT_CFG_FILL
          dc.w    RSC_FORM_TEXT,frtext-frbase      ; MEN_IT_CFG_TEXT
          dc.w    RSC_FORM_ERASER,frradier-frbase  ; MEN_IT_CFG_ERA
          dc.w    RSC_FORM_LINE,frlinie-frbase     ; MEN_IT_CFG_LINE
          dc.w    -1,-1                            ; menu separator
          dc.w    RSC_FORM_PRINT,frdrucke-frbase   ; MEN_IT_CFG_PRT
          dc.w    RSC_FORM_FILE,frdatei-frbase     ; MEN_IT_CFG_FILE
          dc.w    -1                               ; MEN_IT_CFG_WIN
form_buf  ds.w    4
*---------------------------------------------------------------------
          align   2
          end
