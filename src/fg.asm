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
 module    BUTTON_1
 ;section   zwei
 ;pagelen   32767
 ;pagewid   133
 ;noexpand
 include "f_sys.s"
 include "f_def.s"
 ;
 XREF  frmodus,frmuster,frtext,frlinie,frraster,frzeiche
 XREF  chookoo,choofig,chooset,chooras,chootxt,choopat,chooseg
 XREF  rec_adr,logbase,bildbuff
 XREF  copy_blk,save_scr,fram_del,form_do,form_del
 XREF  hide_m,show_m,work_blk,work_bl2,alertbox,pinsel,spdose,gummi
 XREF  punkt,kurve,radier,over_old,over_que,over_beg,mfdb_q,stack
 ;
 XDEF  evt_butt
 XDEF  win_xy,fram_drw,save_buf,win_abs,noch_qu,return,set_wrmo
 XDEF  koos_mak,clip_on,new_1koo,new_2koo,set_att2,ret_att2
 XDEF  ret_attr,set_attr,fram_ins,last_koo

**********************************************************************
*   Global register mapping:
*
*   a4   Address of address of current window record
*   a6   Base address of data section
**********************************************************************
          ;
evt_butt  lea       win_xy,a0           WIN_XY: window coords.
          move.l    YX_OFF(a4),8(a0)
          clr.w     12(a0)
          bsr       win_abs
          move.l    MOUSE_ORIG_XY(a6),d0
          bsr       alrast              round X/Y to closest point in grid, if enabled
          move.l    d0,MOUSE_ORIG_XY(a6)
          move.w    d0,d1
          swap      d0
          bsr       noch_in             click into window?
          bne       donot               no -> abort
          move.w    choofig,d2          ++ Selection tool active? ++
          cmp.w     #$43,d2
          bne.s     evt_but5
          tst.w     SEL_STATE(a6)       selection ongoing?
          beq.s     evt_but4
          add.w     win_xy+8,d1         click into selection area?
          add.w     win_xy+10,d0
          lea       SEL_FRM_X1Y1(a6),a0
          bsr       noch_in
          beq       schub               -> move selection
          bsr       fram_drw
          bra.s     evt_but4
evt_but5  move.l    UNDO_BUF_ADDR(a6),d0      ++ regular tool ++
          cmp.l     BILD_ADR(a4),d0
          bne.s     evt_but4
          tst.w     SEL_FLAG_PASTABLE(a6)   ;disable "paste" flag
          beq.s     evt_but4
          clr.w     SEL_FLAG_PASTABLE(a6)
          moveq.l   #$44,d0             disable "paste (selection)" menu entry
          bsr       men_idis
evt_but4  bsr       save_scr
          move.w    #$ff00,UNDO_STATE(a6)
          lea       last_koo,a0
          clr.w     8(a0)
          move.l    MOUSE_ORIG_XY(a6),d3      D3: mouse X/Y-pos.
*- - - - - - - - - - - - - - - - - - - - - - - - - - -GRAPHICS-HANDLER
          move.w    choofig,d0
          cmp.b     #$55,d0
          beq       pospe               save position
          cmp.b     #$43,d0
          bne.s     evt_but6
          moveq.l   #$27,d0             mark selection
evt_but6  sub.w     #$1f,d0
          lsl.w     #1,d0
          lea       tool_func_table,a0
          move.w    (a0,d0.w),d0
          jsr       (a0,d0.w)
          ;
*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit_beg  lea       last_koo,a1         + convert coordinates to absolute +
          move.w    8(a1),d2
          beq.s     exit1
          move.l    rec_adr,a0
          move.w    YX_OFF+0(a0),d0
          move.w    YX_OFF+2(a0),d1
          cmp.w     #1,d2
          beq.s     exit2
          add.w     d0,2(a1)
          add.w     d1,(a1)
exit2     add.w     d0,6(a1)
          add.w     d1,4(a1)
exit1     tst.b     UNDO_STATE(a6)
          beq.s     exit6
          move.l    rec_adr,a0          abs window?
          move.w    SCHIEBER(a0),d0     -> no backup needed
          bmi       exit6
          bsr       save_buf            copy image into undo buffer
          bsr       win_abs             re-calc. window clipping rect.
          move.l    win_xy,d0
          move.l    win_xy+4,d1
          move.l    d0,d2
          move.l    rec_adr,a1          calc. X/Y of window root in image buffer
          add.w     YX_OFF+0(a1),d2
          add.l     YX_OFF+2(a1),d2
          move.l    logbase,a0          copy from window clipping rect. on phys. screen...
          move.l    BILD_ADR(a1),a1     ...into image buffer
          bsr       copy_blk
          ;
exit3     moveq.l   #$14,d0             enable "undo" menu entry
          bsr       men_iena
          tst.w     SEL_STATE(a6)       selection ongoing?
          beq.s     exit6
          bsr       fram_drw            draw frame around selected area
exit6     bsr       show_m
exit7     tst.b     MOUSE_LBUT+1(a6)    wait for mouse button to be released
          bne       exit7
          clr.w     MOUSE_LBUT(a6)
          rts
          ;
donot     move.w    #-1,MOUSE_LBUT+2(a6)   mouse click unhandled
          rts
          ;
*---------------------------------------------------------------------
tool_func_table:
          dc.w     punkt-tool_func_table
          dc.w     pinsel-tool_func_table
          dc.w     spdose-tool_func_table
          dc.w     fuellen-tool_func_table
          dc.w     text-tool_func_table
          dc.w     radier-tool_func_table
          dc.w     gummi-tool_func_table
          dc.w     linie-tool_func_table
          dc.w     quadrat-tool_func_table
          dc.w     quadrat-tool_func_table
          dc.w     linie-tool_func_table
          dc.w     kreis-tool_func_table
          dc.w     kreis-tool_func_table
          dc.w     kurve-tool_func_table
          ;
*---------------------------------------------------GRAPHICS-FUNCTIONS
pospe     clr.w     UNDO_STATE(a6)      *** Save position ***
          move.l    rec_adr,a0
          add.w     YX_OFF(a0),d3
          add.l     YX_OFF+2(a0),d3
          lea       last_koo,a0
          move.l    4(a0),(a0)+
          move.l    d3,(a0)
          bra       exit7
          ;
linie     dc.w      $a000               *** Shape: Line ***
          move.l    a0,a3
          move.l    d3,38(a3)           D3: starting X/Y coord.
          moveq.l   #-1,d4              D4: ending X/Y coord., or -1 until mouse moved
linie2    bsr       noch_qu             --- Loop while mouse button pressed ---
          bsr       hide_m
          move.w    #$aaaa,34(a3)       line pattern: gray
          move.w    #2,36(a3)           drawing mode XOR
          tst.l     d4
          bmi.s     linie3
          move.l    d4,42(a3)           remove previous line
          dc.w      $a003
linie3    tst.b     MOUSE_LBUT+1(a6)    mouse button released? -> exit loop
          beq.s     linie1
          move.l    d3,42(a3)           draw new line
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          bsr       show_m
          move.l    d3,d4               D4: prev. end point
          bra       linie2
          ;
linie1    tst.l     d4                  mouse moved at all?
          bmi.s     linie4
          move.w    choofig,d0
          cmp.w     #$29,d0             polygon?
          beq.s     vieleck
linie4    bsr       set_att2            --- finalize line ---
          move.l    frlinie+46,d0
          and.l     #$30003,d0
          move.l    d0,INTIN+0(a6)
          vdi       108 0 2             ;...end_styles
          move.l    38(a3),d0
          move.l    d3,d1
          bsr       new_2koo
          move.l    d0,PTSIN+0(a6)
          move.l    d3,PTSIN+4(a6)
          vdi       6 2 0               ;polyline
          bra       ret_attr
          ;
vieleck   clr.w     MOUSE_LBUT(a6)      *** Shape: Polygon ***
          move.l    bildbuff,a2
          move.l    38(a3),(a2)+
          move.l    d4,(a2)
          move.l    a2,d7
          move.l    d4,d6
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          bsr       show_m
vieleck7  moveq.l   #-1,d3              wait for first mouse movement
          bsr       vieleck3            handle RETURN and backspace keys
          move.l    MOUSE_CUR_XY(a6),d0
          lea       win_xy,a0
          bsr       corr_adr
          cmp.l     d6,d3
          beq       vieleck7
          bsr       hide_m
          move.l    d7,d0               first/starting line drawn?
          sub.l     bildbuff,d0
          cmp.l     #4,d0
          bls.s     vieleck2
          move.l    d6,42(a3)           delete previous "root" line
          move.l    bildbuff,a0
          move.l    (a0),38(a3)
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
vieleck2  move.l    d3,d4               +++ Loop +++
          bsr       viele_dr            draw new line
          bsr       show_m
vieleck4  bsr.s     vieleck3            handle RETURN and backspace keys
          moveq.l   #-1,d3
          tst.w     MOUSE_LBUT(a6)      mouse button clicked?
          bne.s     vieleck5
          move.l    MOUSE_CUR_XY(a6),d0    mouse moved?
          lea       win_xy,a0
          bsr       corr_adr
          cmp.l     d3,d4
          beq       vieleck4
          bsr       hide_m              delete old lines
          bsr       viele_dr
          bra       vieleck2
          ;
vieleck5  bsr       hide_m              +++ mouse click +++
          addq.l    #4,d7
          move.l    d7,a2
          move.l    d4,(a2)
          move.l    d4,d6
vieleck6  tst.b     MOUSE_LBUT+1(a6)
          bne       vieleck6
          clr.w     MOUSE_LBUT(a6)
          bsr       show_m
          move.l    d7,d0               more than 128 corners?
          sub.l     bildbuff,d0
          lsr.w     #2,d0
          sub.b     #2,d0
          bpl       vieleck7
          lea       stralmax,a0         yes -> display error dialog
          moveq.l   #1,d0
          bsr       alertbox
          bra.s     vielec10
          ;
vieleck3  move.w    #$b,-(sp)           ;bconstat: check for keypress
          trap      #1
          addq.l    #2,sp
          tst.w     d0
          bpl       tool_rts
          move.w    #1,-(sp)            ;conin: read pressed key
          trap      #1
          addq.l    #2,sp
          cmp.w     #13,d0              Return key?
          beq.s     vielec12
          move.l    d7,d0               +++ Backspace key pressed +++
          sub.l     bildbuff,d0
          cmp.l     #4,d0
          bls       tool_rts
          addq.l    #4,sp               pop return address from stack
          bsr       hide_m
          bsr       viele_dr
          subq.l    #4,d7
          move.l    d7,a0
          move.l    (a0),38(a3)
          move.l    4(a0),42(a3)
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          bra       vieleck2
vielec12  lea       stralvie,a0         +++ Return key pressed +++
          moveq.l   #1,d0
          bsr       alertbox            ask if really done
          cmp.w     #2,d0               "continue" selected?
          beq       exit7               yes -> wait for mouse button release, then rts
          addq.l    #4,sp               pop return address of this sub from stack
vielec10  bsr       hide_m
          move.l    bildbuff,a0         delete polygon
          move.w    #2,36(a3)
          addq.l    #4,d7
          move.l    d7,a1
          tst.l     d3
          bmi.s     vieleck9
          move.l    d4,(a1)+
          addq.l    #4,d7
vieleck9  move.l    (a0),(a1)
          move.l    d7,d5               only two corners?
          sub.l     bildbuff,d5
          subq.l    #8,d5
          bne.s     vieleck8
          clr.l     d7
          move.l    -4(a1),d3
vieleck8  move.l    (a0)+,38(a3)
          move.l    (a0),42(a3)
          move.l    a0,d6
          move.w    #$aaaa,34(a3)
          dc.w      $a003
          move.l    d6,a0
          cmp.l     a0,d7
          bhi       vieleck8
          tst.w     d5
          beq       linie4
          bsr       set_attr            set attributes
          moveq.l   #9,d0
          move.w    chooset,d1          filling enabled?
          bne.s     vieleck1
          move.l    frlinie+46,d0
          and.l     #$30003,d0
          btst      #16,d0
          bne.s     vielec11            round corners
          bset      #17,d0
vielec11  move.l    d0,INTIN+0(a6)
          vdi       108 0 2             ;line end mode
          moveq.l   #6,d0
vieleck1  move.w    d0,CONTRL+0(a6)     Polyline/Fill area
          move.l    bildbuff,VDIPB+8(a6)  temporarily replace PTSIN with larger buffer
          move.l    d7,d0
          sub.l     bildbuff,d0
          lsr.w     #2,d0
          addq.w    #1,d0
          move.w    d0,CONTRL+2(a6)
          clr.w     CONTRL+6(a6)
          bsr       vdicall
          lea       PTSIN(a6),a2
          move.l    a2,VDIPB+8(a6)      restore PTSIN
          bra       ret_attr
          ;
viele_dr  move.l    d7,a0               +++ Draw lines on screen +++
          move.l    d4,42(a3)
          move.l    (a0),38(a3)
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          move.l    bildbuff,a0
          move.l    (a0),38(a3)
          move.w    #$aaaa,34(a3)
          dc.w      $a003
          rts
          ;
fuellen   bsr       new_1koo            *** Shape: Bucket fill ***
          vdi       23 0 1 !frmuster+6  ;fill_style
          vdi       24 0 1 !frmuster+20 ;fill_index
          vdi       25 0 1 !frmuster+34 ;fill_color
          bsr       hide_m
          bsr       clip_on
          move.l    d3,PTSIN+0(a6)
          move.w    frmuster+34,INTIN+0(a6)
          vdi       103 1 1             ;contour_fill
          vdi       23 0 1 1
          bra       return
          ;
quadrat   dc.w      $a000               *** Tools: Square, Rectangle ***
          move.l    a0,a3
          move.w    #-1,32(a3)          dummy
          move.l    d3,38(a3)
          move.w    d3,d7               D7: Y-root
          move.l    d3,d6               D6: X-root
          swap      d6
          clr.w     d4
quadrat1  bsr       noch_qu
          bsr       hide_m
          move.w    #$aaaa,34(a3)       line pattern
          tst.w     d4
          beq.s     quadrat5
          bsr       quadr_dr
quadrat5  tst.b     MOUSE_LBUT+1(a6)    mouse button still pressed?
          beq.s     quadrat2
          move.w    d3,d5               D5: Y-new
          move.l    d3,d4               D4: X-new
          swap      d4
          move.w    choofig,d0          square?
          cmp.w     #$28,d0
          bne.s     quadra10
          move.w    d4,d0               --- select. equal W/H for square ---
          move.w    d5,d1
          sub.w     d6,d0
          bpl.s     quadra11
          not.w     d0
          addq.w    #1,d0
quadra11  sub.w     d7,d1
          bpl.s     quadra12
          not.w     d1
          addq.w    #1,d1
quadra12  cmp.w     d0,d1               height >= width?
          bhs.s     quadra13
          cmp.w     d4,d6
          bhs.s     quadra14
          move.w    d6,d4
          add.w     d1,d4               no -> width := height
          bra.s     quadra10
quadra14  move.w    d6,d4
          sub.w     d1,d4
          bra.s     quadra10
quadra13  cmp.w     d5,d7
          bhs.s     quadra15
          move.w    d7,d5
          add.w     d0,d5               yes -> height := width
          bra.s     quadra10
quadra15  move.w    d7,d5
          sub.w     d0,d5
quadra10  bsr       quadr_dr
          bsr       show_m
          bra       quadrat1
quadrat2  move.w    choofig,d0          --- finalize rectangle/square ---
          cmp.w     #$43,d0             selection?
          beq       markier
          tst.w     d4                  mouse never moved -> abort
          beq       tool_rts
          bsr       set_attr            set attributes
          move.w    chooset+2,d0
          bne       quadrat7            -> rounded corners
          move.w    chooset,CONTRL+10(a6)
          bne.s     quadrat6            -> fill
          vdi       108 0 2 0 2
          vdi       6 5 0 !d6 !d7 !d4 !d7 !d4 !d5 !d6 !d5 !d6 !d7
          vdi       108 0 2 0 0
          bra.s     quadrat9
quadrat6  move.w    #1,CONTRL+10(a6)    ;bar
          bra.s     quadrat8
quadrat7  move.w    #8,CONTRL+10(a6)    ;rounded_rec
          move.w    chooset,d0
          beq.s     quadrat8
          move.w    #9,CONTRL+10(a6)    ;filled_rounded_rec
quadrat8  ;
          vdi       11 2 0 !d6 !d7 !d4 !d5
quadrat9  lea       last_koo,a0         store coords.
          move.w    d6,(a0)
          move.w    d7,2(a0)
          move.w    d4,4(a0)
          move.w    d5,6(a0)
          move.w    #-1,8(a0)
          bra       ret_attr
          ;
quadr_dr  move.w    #2,36(a3)           ++ Draw rubberband-rectangle ++
          move.w    #1,24(a3)
          move.w    d6,38(a3)
          move.w    d7,40(a3)
          move.w    d4,42(a3)
          move.w    d7,44(a3)
          dc.w      $a003               x1y1-x2y1
          move.w    d6,42(a3)
          move.w    d5,44(a3)
          dc.w      $a003               x1y1-x1y2
          move.w    d4,42(a3)
          move.w    d5,40(a3)
          dc.w      $a003               x1y2-x2y2
          move.w    d4,38(a3)
          move.w    d7,40(a3)
          dc.w      $a003               x2y1-x2y2
          rts
          ;
markier   move.b    SEL_OPT_OVERLAY(a6),d0   *** Start new selection ***
          beq.s     markier6
          tst.w     SEL_STATE(a6)       previous selection frame still active=
          beq.s     markier6
          tst.b     SEL_FLAG_CHG(a6)    selection content modified?
          beq.s     markier6
          bsr       show_m
          bsr       over_que            ask to confirm "commit selection?"
          move.w    d0,d2
          bsr       hide_m
          cmp.w     #1,d2
          beq.s     markier6
          addq.l    #4,sp
          bra       exit3
markier6  clr.w     UNDO_STATE(a6)      disable "undo"
          tst.w     d4
          bne.s     markier4
          clr.b     SEL_STATE(a6)       --- only delete borders ---
          bsr       fram_del
          addq.l    #4,sp
          bra       exit6
markier4  cmp.w     d4,d6               --- new borders ---
          blo.s     markier1
          exg       d4,d6
markier1  cmp.w     d5,d7
          blo.s     markier2
          exg       d5,d7
markier2  add.w     win_xy+8,d5         convert coords. to abs.
          add.w     win_xy+8,d7
          add.w     win_xy+10,d4
          add.w     win_xy+10,d6
          move.w    #-1,SEL_STATE(a6)   selection active now
          move.w    d6,SEL_FRM_X1Y1+0(a6)  store X1Y1 & X2Y2
          move.w    d7,SEL_FRM_X1Y1+2(a6)
          move.w    d4,SEL_FRM_X2Y2+0(a6)
          move.w    d5,SEL_FRM_X2Y2+2(a6)
          lea       last_koo,a1         save coords.
          move.l    SEL_FRM_X1Y1(a6),(a1)
          move.l    SEL_FRM_X2Y2(a6),4(a1)
          bsr       fram_drw            draw selection border
          move.b    SEL_OPT_OVERLAY(a6),d0           overlay mode?
          beq.s     markier7
          bsr       over_beg
          moveq.l   #$45,d0             enable "discard (selection)" menu entry
          bsr       men_iena
          tst.b     SEL_OPT_COPY(a6)    copy mode enabled?
          bne.s     markier5
          moveq.l   #$44,d0             enable "paste (selection)" menu entry
          bsr       men_iena
          bra.s     markier5
markier7  moveq.l   #$44,d0             copy mode -> disable "paste (selection)" menu entry
          bsr       men_idis
markier5  moveq.l   #7,d2               enable menu commands
markier3  move.l    d2,d0
          add.l     #$48,d0
          bsr       men_iena
          dbra      d2,markier3
          clr.b     SEL_FLAG_PASTABLE(a6)  ;no paste
          clr.b     SEL_TMP_OVERLAY(a6)
          clr.b     SEL_CUR_COMB(a6)    no combination mode
          clr.b     SEL_PREV_COMB(a6)
          clr.b     SEL_FLAG_CHG(a6)    unmodified
          clr.b     SEL_FLAG_CUTOFF(a6) no cut-off
          rts
          ;
kreis     bsr       clip_on             *** Shape: Circle/Arc & Ellipsis ***
          vdi       32 0 1 3            XOR
          vdi       15 0 1 7            self-defined line type
          vdi       16 1 0 1 0          line width 1
          vdi       17 0 1 1            line color black
          vdi       113 0 1 $aaaa       line style gray
          vdi       23 0 1 0            no filling
          move.w    d3,d5               D5: Y-coord. of center
          move.l    d3,d4               D4: X-coord.
          swap      d4
          moveq.l   #-1,d6
          clr.w     d7
kreis1    bsr       noch_qu             ---- Loop ----
          bsr       hide_m
          tst.w     d6
          bmi.s     kreis2
          bsr       kreis_k
kreis2    tst.b     MOUSE_LBUT+1(a6)
          beq.s     kreis3
          move.w    d3,d7               D7: Y-offset
          sub.w     d5,d7
          bpl.s     kreis4
          not.w     d7
          addq.w    #1,d7
kreis4    move.l    d3,d6               D6: X-offset
          swap      d6
          sub.w     d4,d6
          bpl.s     kreis9
          not.w     d6
          addq.w    #1,d6
kreis9    move.w    choofig,d0          Circle?
          cmp.w     #$2a,d0
          bne.s     kreis10
          cmp.w     d6,d7               yes -> choose larger of radius values
          bls.s     kreis10
          move.w    d7,d6
kreis10   bsr       kreis_k
          bsr       show_m
          bra       kreis1
          ;
kreis3    tst.w     d6                  ---- finalize circle ----
          bmi       tool_rts
          bsr       set_attr
          move.l    frlinie+46,d0
          and.l     #$30003,d0
          move.l    d0,INTIN+0(a6)
          vdi       108 0 2             ;end_styles
          move.w    chooseg,d1
          move.w    chooseg+2,d2
          move.w    choofig,d3
          moveq.l   #2,d0
          add.w     chooset,d0          arc or pie?
          cmp.b     #3,d0
          bne.s     kreis6
          tst.w     d1
          bne.s     kreis6
          cmp.w     #3600,d2
          beq.s     kreis8              -> circle
kreis6    cmp.w     #$2b,d3             ellipsis?
          beq       kreis12
          move.w    d0,CONTRL+10(a6)    3=pie, 2=arc
          vdi       11 4 2 !d4 !d5 0 0 0 0 !d6 0 !d1 !d2  ;arc/pie
          bra.s     kreis7
kreis8    cmp.w     #$2b,d3             ellipsis?
          beq.s     kreis11
          move.w    #4,CONTRL+10(a6)
          vdi       11 3 0 !d4 !d5 0 0 !d6 0  ;pie of circle
          bra.s     kreis7
kreis11   moveq.l   #1,d0
kreis12   add.w     #4,d0
          move.w    d0,CONTRL+10(a6)    5=ellipsis; 6=ell-arc; 7=ell-pie
          vdi       11 2 2 !d4 !d5 !d6 !d7 !d1 !d2  ;ellipse/arc/pie
kreis7    lea       last_koo,a0
          move.w    d4,(a0)             store coords.
          move.w    d5,2(a0)
          add.w     d6,d4
          add.w     d7,d5
          move.w    d4,4(a0)
          move.w    d5,6(a0)
          move.w    #-1,8(a0)
          bra       ret_attr
          ;
kreis_k   move.l    chooseg,INTIN+0(a6)  --- circle/ellipsis rubberband ---
          move.w    choofig,d0
          cmp.w     #$2b,d0
          beq.s     kreis_e
          move.w    #2,CONTRL+10(a6)
          vdi       11 4 2 !d4 !d5 0 0 0 0 !d6 0  ;arc (INTIN filled already above)
          rts
kreis_e   move.w    #6,CONTRL+10(a6)
          vdi       11 2 2 !d4 !d5 !d6 !d7  ;elliptical_arc
          rts
          ;
text      bsr       new_1koo            *** Shape: Text ***
          move.l    rec_adr,a0
          bsr       save_buf
          lea       data_buf,a2
          move.l    d3,(a2)             store mouse X/Y-pos
          bsr       text_att            configure attributes
          lea       stack,a3
text3     tst.b     MOUSE_LBUT+1(a6)    busy loop until mouse button is released
          bne       text3
          clr.w     MOUSE_LBUT(a6)
text1     bsr       show_m              +++ Loop +++
text11    tst.b     MOUSE_LBUT(a6)
          bne       text4
          move.w    #$b,-(sp)           ;constat
          trap      #1
          addq.l    #2,sp
          tst.w     d0
          bpl       text11
          bsr       hide_m
          move.w    #7,-(sp)            ;conin without echo
          trap      #1
          addq.l    #2,sp
          cmp.l     #$620000,d0         Help key pressed?
          bne.s     text13
          moveq.l   #-1,d0
text13    cmp.l     #$610000,d0         UNDO key pressed?
          bne.s     text14
          moveq.l   #-2,d0
text14    tst.b     d0                  not an ASCII-key?
          beq       text1
          cmp.b     #13,d0              Return?
          bne       text2
          move.w    6(a2),d1            -> down by one line
          lea       win_xy,a0
          move.w    4(a2),d0
          bne.s     text12
          add.w     d1,2(a2)            0 degree angle
          move.w    6(a0),d0
          cmp.w     2(a2),d0
          blo       text4
          bra.s     text17
text12    cmp.w     #1,d0               90 degree angle
          bne.s     text18
          add.w     d1,(a2)
          move.w    4(a0),d0
          cmp.w     (a2),d0
          blo       text4
          bra.s     text17
text18    cmp.w     #2,d0               180 degree angle
          bne.s     text19
          sub.w     d1,2(a2)
          move.w    2(a0),d0
          cmp.w     2(a2),d0
          bhi       text4
          bra.s     text17
text19    sub.w     d1,(a2)             270 degree angle
          move.w    (a0),d0
          cmp.w     2(a2),d0
          bhi       text4
text17    move.l    win_xy,d0           temporary copy of image
          move.l    win_xy+4,d1
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     YX_OFF+0(a0),d2
          add.l     YX_OFF+2(a0),d2
          move.l    BILD_ADR(a0),a1
          move.l    logbase,a0
          bsr       copy_blk
          lea       stack,a3
          lea       data_buf,a2
          bra       text1
          ;
text2     move.w    d0,d2
          lea       stack,a0
          move.l    a0,VDIPB+4(a6)      (!) temporarily use larger buffer for INTIN
          cmp.l     a0,a3               at least one char in the text buffer?
          beq       text7
          movem.l   d2/a2-a3,-(sp)      +++ restore image +++
          move.l    a3,d0
          sub.l     a0,d0
          lsr.w     #1,d0
          vdi       116 0 !d0           ;inquire_text_extend
          move.l    data_buf,d0
          move.l    d0,d1
          move.w    data_buf+4,d3       vertical text?
          btst      #0,d3
          bne.s     text20
          sub.l     PTSOUT+12(a6),d0    0+180 degrees
          add.l     PTSOUT+4(a6),d1
          bra.s     text21
text20    cmp.b     #1,d3               90 degrees
          bne.s     text22
          sub.l     PTSOUT+4(a6),d0
          bra.s     text21
text22    move.l    PTSOUT+12(a6),d2    270 degrees
          swap      d2
          add.l     d2,d1
text21    sub.l     #$30003,d0
          add.l     #$30003,d1
          bsr       lim_win             clip to window
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     YX_OFF+0(a0),d0
          add.w     YX_OFF+0(a0),d1
          add.l     YX_OFF+2(a0),d0
          add.l     YX_OFF+2(a0),d1
          move.l    BILD_ADR(a0),a0
          move.l    logbase,a1
          bsr       copy_blk
          movem.l   (sp)+,d2/a2-a3
          cmp.b     #8,d2               Backspace key?
          bne.s     text8
          subq.w    #2,a3               -> delete last character
          lea       stack,a0            char buffer empty?
          cmp.l     a0,a3
          bne       text15+2            no -> draw string again
          bra       text9
          ;
text7     cmp.b     #8,d2               not backspace
          beq       text9
text8     move.w    d2,d3               Help or Undo keys?
          bpl       text15
          lea       INTIN(a6),a1        +++ Formulare +++
          move.l    a1,VDIPB+4(a6)      restore INTIN
          bsr       show_m
          bsr       text_rat
          movem.l   a2-a4/d2,-(sp)
          move.l    rec_adr,a4
          moveq.l   #9,d2
          lea       frtext,a2
          cmp.w     #-1,d3
          beq.s     text16
          moveq.l   #17,d2
          lea       frzeiche,a2
text16    bsr       form_do
          bsr       form_del
          bsr       hide_m
          move.l    win_xy,d0           redisplay image
          move.l    win_xy+4,d1
          move.l    d0,d2
          add.w     YX_OFF+0(a4),d0
          add.w     YX_OFF+0(a4),d1
          add.l     YX_OFF+2(a4),d0
          add.l     YX_OFF+2(a4),d1
          move.l    BILD_ADR(a4),a0
          move.l    logbase,a1
          bsr       copy_blk
          movem.l   (sp)+,a2-a4/d2
          bsr       text_att
text6     tst.b     MOUSE_LBUT+1(a6)
          bne       text6
          clr.w     MOUSE_LBUT(a6)
          lea       stack,a1
          move.l    a1,VDIPB+4(a6)      (!) temporarily use larger buffer for INTIN
          cmp.w     #-1,d2              UNDO-key?
          beq.s     text15+2
          move.w    frzeiche+6,d2
          ;
text15    move.w    d2,(a3)+            +++ draw new string +++
          clr.w     (a3)
          lea       stack,a0
          move.l    a3,d0
          sub.l     a0,d0
          lsr.w     #1,d0
          move.l    (a2),PTSIN+0(a6)
          vdi       8 1 !d0             ;text
text9     lea       INTIN(a6),a1
          move.l    a1,VDIPB+4(a6)      restore INTIN
          bra       text1
          ;
text4     move.l    bildbuff,a0         +++ End +++
          move.l    rec_adr,a1
          move.l    BILD_ADR(a1),a1
          move.w    #1999,d0
text5     move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d0,text5
          bsr       hide_m
text_rat  ;
          vdi       39 0 2 0 0          +++ Restore attributes +++
          vdi       13 0 1 0
          vdi       106 0 1 0
          vdi       22 0 1 1
          vdi       12 1 0 0 13
          bra       return
text_att  move.w    frtext+20,d0        +++ Configure attributes +++
          move.w    d0,d1
          mulu.w    #10,d0
          ext.l     d1
          add.w     #45,d1              calc. quadrant
          divu      #90,d1
          move.w    d1,4(a2)
          vdi       13 0 1 !d0          ;angle
          vdi       22 0 1 !frtext+34   ;color
          vdi       106 0 1 !chootxt    ;effects
          vdi       12 1 0 0 !frtext+6  ;size
          move.w    PTSOUT+6(a6),d0
          move.w    chootxt,d1
          btst      #4,d1               border?
          beq.s     text_at1
          addq.w    #2,d0
text_at1  move.w    d0,6(a2)            line height
          vdi       39 0 2 0 3          ;orientation
          bsr       set_wrmo
          bra       clip_on
          ;
***************************************************************************
*  stack frame:
*        0: prev. mouse coords. (i.e. at time of starting to drag mouse)
*        4: cur selection frame coords.
*        8: selection width
*       12: borders deleted?
*       16: background source address
*       20: selection image source
*       24: source coord. X1Y1
*       28: source coord. X2Y2
***************************************************************************
schub     move.b    SEL_CUR_COMB(a6),d7  ;*** Move selection ***
          bsr       over_old
          move.b    d7,SEL_CUR_COMB(a6)
          move.l    SEL_OPT_COPY(a6),d2
          bsr       save_scr
          move.l    d2,SEL_OPT_COPY(a6)
          tst.b     SEL_FLAG_DEL(a6)             delete old selection?
          beq.s     schub1
          clr.b     SEL_FLAG_DEL(a6)
          clr.w     d3
          move.l    bildbuff,a0
          move.l    UNDO_SEL_X1Y1(a6),d0
          move.l    UNDO_SEL_X2Y2(a6),d1
          bsr       work_bl2
schub1    lea       stack,a3            + set parameters +
          move.l    SEL_FRM_X1Y1(a6),d0
          move.l    SEL_FRM_X2Y2(a6),d1
          move.l    d0,UNDO_SEL_X1Y1(a6)
          move.l    d1,UNDO_SEL_X2Y2(a6)
          move.l    d0,d2
          move.l    d1,d3
          tst.b     SEL_FLAG_CUTOFF(a6)   ;restore cut-off?
          bpl.s     schub7
          move.b    SEL_OPT_OVERLAY(a6),d4
          beq.s     schub7
          move.l    SEL_PREV_X1Y1(a6),d2
          move.l    SEL_PREV_X2Y2(a6),d3
          sub.w     SEL_PREV_OFFSET+2(a6),d0
          swap      d0
          sub.w     SEL_PREV_OFFSET+0(a6),d0
          swap      d0
schub7    move.l    d2,24(a3)           24: source coord.
          move.l    d3,28(a3)
          sub.l     d2,d3
          move.l    d3,8(a3)            8: selection width
          move.l    rec_adr,a0
          sub.w     YX_OFF+0(a0),d0
          sub.l     YX_OFF+2(a0),d0
          sub.w     YX_OFF+0(a0),d1
          sub.l     YX_OFF+2(a0),d1
          move.l    MOUSE_ORIG_XY(a6),(a3)    0: prev. mouse coords.
          move.l    d0,4(a3)            4: cur selection frame coords.
          bsr       lim_win
          move.l    d0,SEL_FRM_X1Y1(a6) ;cur frame (rel)
          move.l    d1,SEL_FRM_X2Y2(a6)
          clr.b     12(a3)              12: borders deleted?
          move.b    SEL_OPT_OVERLAY(a6),d0
          beq.s     schub9
          tst.b     SEL_FLAG_CUTOFF(a6) + Overlay mode +
          bmi.s     schub5
          bsr       save_buf
schub5    move.l    SEL_OV_BUF(a6),16(a3)   16: background source address
          move.l    bildbuff,20(a3)     20: selection image source
          bra.s     schub4
schub9    move.l    bildbuff,16(a3)     + NORM-Mode +
          move.l    BILD_ADR(a4),20(a3)
          tst.b     SEL_TMP_OVERLAY(a6) overlay mode temporaily enabled?
          bne.s     schub4              -> keep old background
          bsr       save_buf
          tst.b     SEL_OPT_COPY(a6)    copy mode?
          bne.s     schub4
          clr.w     d3
          move.l    bildbuff,a0
          move.l    UNDO_SEL_X1Y1(a6),d0
          move.l    UNDO_SEL_X2Y2(a6),d1
          bsr       work_bl2
schub4    move.b    SEL_OPT_COMB(a6),d0    + changed combination mode? +
          cmp.b     SEL_CUR_COMB(a6),d0
          beq.s     schub2
          move.l    stack,d3            -> draw immediately
          bsr       hide_m
          bra.s     schub8
          ;
schub2    lea       stack,a3            +++ Loop +++
          move.l    (a3),d3
          bsr       noch_qu
          bsr       hide_m
          tst.b     MOUSE_LBUT+1(a6)    done?
          beq.s     schub3
schub8    move.l    d3,-(sp)            ++ Restore ++
          spl.b     12(a3)
          move.l    SEL_FRM_X1Y1(a6),d0
          move.l    SEL_FRM_X2Y2(a6),d1
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     YX_OFF+0(a0),d0
          add.w     YX_OFF+0(a0),d1
          add.l     YX_OFF+2(a0),d0
          add.l     YX_OFF+2(a0),d1
          move.l    stack+16,a0
          move.l    logbase,a1
          bsr       copy_blk
          move.l    (sp)+,d3
          move.l    d3,d4               ++ Redraw ++
          lea       stack,a3
          sub.w     2(a3),d3
          add.w     d3,6(a3)
          swap      d3
          sub.w     (a3),d3             prev. pos. + mouse offset =
          add.w     d3,4(a3)            4: new selection coords. (upper-left corner)
          move.l    d4,(a3)             0: new mouse coords.
          move.l    logbase,a1
          bsr       fram_ins            commit selection
          bsr       show_m
          bra       schub2
          ;
schub3    move.l    rec_adr,a2          +++ End +++
          move.b    SEL_OPT_OVERLAY(a6),d0
          bne.s     schub20
          move.w    YX_OFF+0(a2),d0       + NORM mode +
          move.w    YX_OFF+2(a2),d1
          lea       SEL_FRM_X1Y1(a6),a0
          add.w     d1,(a0)+
          add.w     d0,(a0)+
          add.w     d1,(a0)+
          add.w     d0,(a0)
          clr.b     SEL_FLAG_CUTOFF(a6)
          bra       schub21
schub20   move.w    #1999,d3            + Overlay mode +
          move.l    SEL_OV_BUF(a6),a0
          move.l    BILD_ADR(a2),a1
schub26   move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d3,schub26
          lea       win_xy,a0
          clr.l     (a0)+
          move.l    #$27f018f,(a0)+     (640-1)x(400-1)
          lea       stack+4,a1
          move.w    (a0)+,d0
          move.w    (a0),d1
          add.w     d1,(a1)+
          add.w     d0,(a1)
          move.l    BILD_ADR(a2),a1
          bsr       fram_ins
          move.l    SEL_FRM_X2Y2(a6),d0   ; selection cut off at window borders?
          sub.l     SEL_FRM_X1Y1(a6),d0
          move.l    stack+28,d1
          sub.l     stack+24,d1
          cmp.l     d0,d1
          beq.s     schub22
          st.b      SEL_FLAG_CUTOFF(a6)   ; set partial flag
          move.l    stack+24,SEL_PREV_X1Y1(a6)
          move.l    stack+28,SEL_PREV_X2Y2(a6)
          move.l    SEL_FRM_X1Y1(a6),SEL_PREV_OFFSET(a6)
          move.w    stack+4,d0
          sub.w     d0,SEL_PREV_OFFSET+0(a6)
          move.w    stack+6,d0
          sub.w     d0,SEL_PREV_OFFSET+2(a6)
          moveq.l   #$46,d0             enable "commit (selection)"
          bsr       men_iena
          bra.s     schub21
schub22   move.l    stack+24,SEL_PREV_X1Y1(a6)
          bclr.b    #7,SEL_FLAG_CUTOFF(a6)
          bne.s     schub21
          clr.b     SEL_FLAG_CUTOFF(a6)
          moveq.l   #$46,d0             disable "commit (selection)"
          bsr       men_idis
schub21   ;                             + set flags +
          clr.w     SEL_FLAG_PASTABLE(a6)   pasting done
          move.b    stack+12,d0
          beq       exit6
          move.w    #-1,UNDO_STATE(a6)  enable undo
          tst.b     SEL_OPT_OVERLAY(a6)
          beq       exit_beg
          move.b    SEL_OPT_COMB(a6),SEL_CUR_COMB(a6)  store combination mode
          beq       exit3
          moveq.l   #$46,d0             enable "commit (selection)"
          bsr       men_iena
          bra       exit3
*----------------------------------------------------GEM-SUBFUNCTIONS
          ;
set_attr  move.w    frmuster+6,d0       ** set attributes **
          vdi       23 0 1 !d0           ;fill pattern type (0..4)
          vdi       24 0 1 !frmuster+20  ;fill pattern style (range depends on type)
          vdi       25 0 1 !frmuster+34  ;fill color
          vdi       104 0 1 !chooset+4   ;border on/off
set_att2  ;
          vdi       15 0 1 !frlinie+34   ;line style
          vdi       16 1 0 !frlinie+20 0 ;line width
          vdi       17 0 1 !frlinie+6    ;line color
          vdi       113 0 1 !choopat     ;line pattern
          bsr.s     clip_on
          ;
set_wrmo  clr.w     d0                  ** set current mode **
          move.b    frmodus+5,d0
          addq.b    #1,d0
          vdi       32 0 1 !d0          ;set_writing_modus
          rts
          ;
clip_on   move.l    win_xy,PTSIN+0(a6)  ** set clipping rect. **
          move.l    win_xy+4,PTSIN+4(a6)
          move.w    #1,INTIN+0(a6)
          vdi       129 2 1
          rts
ret_attr  ;                             ** set GEM-attributes **
          vdi       108 0 2 0 0
ret_att2  ;
          vdi       15 0 1 1
          vdi       16 1 0 1 0
          vdi       17 0 1 1
          vdi       23 0 1 1
return    ;
          vdi       129 0 1 0           ;delete clipping rect.
          vdi       32 0 1 3            ;set_writing_mode XOR
          rts
*--------------------------------------------------------SUBFUNCTIONS
noch_qu   lea       win_xy,a0           ** Query mouse **
noch_qu5  tst.b     MOUSE_LBUT+1(a6)    --- start loop ---
          beq.s     noch_rts
          move.l    MOUSE_CUR_XY(a6),d0
corr_adr  bsr       alrast
          swap      d0                  X position within window?
          cmp.w     (a0),d0
          bhs.s     noch_qu1
          move.w    (a0),d0             no -> correct
          bra.s     noch_qu2
noch_qu1  cmp.w     4(a0),d0
          bls.s     noch_qu2
          move.w    4(a0),d0
noch_qu2  swap      d0                  Y position within window?
          cmp.w     2(a0),d0
          bhs.s     noch_qu3
          move.w    2(a0),d0
          bra.s     noch_qu4
noch_qu3  cmp.w     6(a0),d0
          bls.s     noch_qu4
          move.w    6(a0),d0
noch_qu4  cmp.l     d0,d3               loop until effective mouse position changed
          beq       noch_qu5
          move.l    d0,d3
          lea       chookoo,a0
          tst.w     (a0)
          beq.s     noch_rts
          movem.l   a1/d1-d2,-(sp)
          bsr       koos_out            display mouse coord., if enabled
          movem.l   (sp)+,a1/d1-d2
noch_rts  rts
          ;
noch_in   cmp.w     (a0),d0             ** Pos. within selection area? **
          blo.s     noch_in1
          cmp.w     4(a0),d0
          bhi.s     noch_in1
          cmp.w     2(a0),d1
          blo.s     noch_in1
          cmp.w     6(a0),d1
          bhi.s     noch_in1
          clr.w     d2
          rts
noch_in1  moveq.l   #1,d2
          rts
          ;
win_abs   move.l    rec_adr,a0          ** Limit window size **
          move.l    FENSTER(a0),d0
          move.l    FENSTER+4(a0),d1
          lea       win_xy,a0
          move.l    d0,(a0)
          add.l     d1,d0
          sub.l     #$10001,d0
          move.l    d0,4(a0)
          cmp.w     #400,6(a0)
          blo.s     win_abs1
          move.w    #399,6(a0)
win_abs1  cmp.w     #640,4(a0)
          blo.s     win_abs2
          move.w    #639,4(a0)
win_abs2  rts
          ;
lim_win   lea       win_xy,a0           ** Limit to window **
          cmp.w     2(a0),d0
          bge.s     lim_win1
          move.w    2(a0),d0
lim_win1  cmp.w     6(a0),d1
          bls.s     lim_win2
          move.w    6(a0),d1
lim_win2  swap      d0
          swap      d1
          cmp.w     (a0),d0
          bge.s     lim_win3
          move.w    (a0),d0
lim_win3  cmp.w     4(a0),d1
          bls.s     lim_win4
          move.w    4(a0),d1
lim_win4  swap      d0
          swap      d1
          rts
          ;
new_1koo  lea       last_koo,a0         ** Store mouse coord. **
          move.l    4(a0),(a0)
          move.l    d3,4(a0)
          addq.w    #1,8(a0)
          bpl.s     new_3koo
          move.w    #-1,8(a0)
          rts
new_2koo  lea       last_koo,a0
          move.l    d0,(a0)
          move.l    d1,4(a0)
          move.w    #-1,8(a0)
new_3koo  rts
          ;
save_buf  move.l    rec_adr,a1          ** Copy image to undo buffer **
          move.l    BILD_ADR(a1),a1
          move.l    bildbuff,a2
          move.l    #1999,d0
save_bu1  move.l    (a1)+,(a2)+
          move.l    (a1)+,(a2)+
          move.l    (a1)+,(a2)+
          move.l    (a1)+,(a2)+
          dbra      d0,save_bu1
          rts
          ;
fram_ins  lea       stack+4,a3          ** Copy selection content into image **
          move.l    (a3),d0
          move.l    d0,d1
          add.w     6(a3),d1
          swap      d1
          add.w     4(a3),d1
          swap      d1
          bsr       lim_win
          move.l    d0,d2
          move.l    d0,SEL_FRM_X1Y1(a6) ; store new border coord.
          move.l    d1,SEL_FRM_X2Y2(a6)
          sub.w     2(a3),d0            calc selection source addr.
          sub.w     2(a3),d1
          swap      d0
          swap      d1
          sub.w     (a3),d0
          sub.w     (a3),d1
          swap      d0
          swap      d1
          add.l     20(a3),d0
          add.l     20(a3),d1
          tst.b     SEL_OPT_COMB(a6)    just move?
          bne.s     fram_in1
          move.l    stack+20,a0         1:1-copy
          bra       copy_blk
fram_in1  clr.w     d3                  use combination mode
          move.b    SEL_OPT_COMB(a6),d3
          lea       mfdb_q,a0
          move.l    stack+20,(a0)
          move.l    a1,20(a0)
          move.w    d3,INTIN+0(a6)      mode
          move.l    d1,d3
          sub.l     d0,d3
          move.l    d3,4(a0)
          move.l    d3,24(a0)
          move.l    a0,CONTRL+14(a6)
          add.w     #20,a0
          move.l    a0,CONTRL+18(a6)
          lea       PTSIN(a6),a0
          move.l    d0,(a0)+
          move.l    d1,(a0)+
          move.l    d2,(a0)+
          add.l     d3,d2
          move.l    d2,(a0)
          vdi       109 4 1             ;copy_raster
          rts
          ;
fram_drw  tst.w     SEL_STATE(a6)       ** frame the selection **
          beq       tool_rts
          move.l    rec_adr,a1
          move.w    SEL_FRM_X1Y1+0(a6),d4  ; x1y1-x2y2: border coords.
          move.w    SEL_FRM_X1Y1+2(a6),d5
          move.w    SEL_FRM_X2Y2+0(a6),d6
          move.w    SEL_FRM_X2Y2+2(a6),d7
          sub.w     YX_OFF+0(a1),d5
          sub.w     YX_OFF+0(a1),d7
          bmi       tool_rts
          sub.w     YX_OFF+2(a1),d4
          sub.w     YX_OFF+2(a1),d6
          bmi       tool_rts
          move.l    FENSTER(a1),d0      window borders
          move.l    FENSTER+4(a1),d1
          add.l     d0,d1
          sub.l     #$10001,d1
          cmp.w     #400,d0             screen borders
          bhs       tool_rts
          cmp.w     #400,d1
          blo.s     fram_d14
          move.w    #399,d1
fram_d14  swap      d0
          cmp.w     #640,d0
          bhs       tool_rts
          swap      d0
          swap      d1
          cmp.w     #640,d1
          blo.s     fram_d16
          move.w    #639,d1
fram_d16  swap      d1
          moveq.l   #15,d3              D3: border control flags
          cmp.w     d0,d5               limit border
          bge.s     fram_dr2            (D5 may be <0)
          move.w    d0,d5
          bclr      #1,d3               1: top
fram_dr2  cmp.w     d1,d7
          bls.s     fram_dr3
          move.w    d1,d7
          bclr      #3,d3               3: bottom
fram_dr3  swap      d0
          swap      d1
          cmp.w     d0,d4
          bge.s     fram_dr4
          move.w    d0,d4
          bclr      #0,d3               0: left
fram_dr4  cmp.w     d1,d6
          bls.s     fram_dr5
          move.w    d1,d6
          bclr      #2,d3               2: right
fram_dr5  cmp.w     d5,d7               selection outside of window?
          blo.s     fram_d10
          cmp.w     d4,d6
          bhs.s     fram_d12
fram_d10  clr.w     d3
fram_d12  tst.w     d3                  Borders visible?
          beq       tool_rts            no -> abort
          bsr       hide_m
          dc.w      $a000               Line-A init
          move.l    a0,a3
          move.w    #-1,32(a3)
          move.w    #1,24(a3)
          move.w    #2,36(a3)
          move.w    d4,38(a3)           draw visible parts of border
          move.w    d5,40(a3)
          move.w    d6,42(a3)
          move.w    d5,44(a3)
          btst      #1,d3
          beq.s     fram_dr6
          move.w    #$cccc,34(a3)
          dc.w      $a003               X1Y1-X2Y1
fram_dr6  move.w    d7,40(a3)
          move.w    d7,44(a3)
          btst      #3,d3
          beq.s     fram_dr7
          move.w    #$cccc,34(a3)
          dc.w      $a003               X1Y2-X2Y2
fram_dr7  move.w    d5,40(a3)
          move.w    d4,42(a3)
          cmp.w     d5,d7               height = 1?
          bne.s     fram_d17
          move.w    #$cccc,d7
          bra.s     fram_d18
fram_d17  move.w    #$cccc,d7
fram_d18  sub.w     SEL_FRM_X1Y1+2(a6),d5
          and.w     #3,d5
          beq.s     fram_dr1
          rol.w     d5,d7
fram_dr1  btst      #0,d3
          beq.s     fram_dr8
          move.w    d7,34(a3)
          dc.w      $a003               X1Y1-X1Y2
fram_dr8  move.w    d6,38(a3)
          move.w    d6,42(a3)
          btst      #2,d3
          beq.s     fram_dr9
          move.w    d7,34(a3)
          dc.w      $a003               X2Y1-X2Y2
fram_dr9  bra       show_m
          ;
koos_mak  move.w    chookoo,d0          ** Display mouse position **
          beq       tool_rts
          move.l    rec_adr,a1          window open?
          move.w    (a1),d0
          bmi       koos_ou2
          lea       koo_buff,a0         within a window?
          move.l    FENSTER(a1),d1
          move.l    d1,d2
          add.l     FENSTER+4(a1),d2
          sub.l     #$10001,d2
          move.l    d1,(a0)
          move.l    d2,4(a0)
          move.w    MOUSE_CUR_XY(a6),d0
          move.w    MOUSE_CUR_XY+2(a6),d1
          bsr       noch_in
          bne.s     koos_ou2
          lea       win_xy+8,a0
          move.l    YX_OFF(a1),(a0)
          swap      d0
          move.w    d1,d0
          bsr.s     alrast              align with raster, if enabled
          lea       chookoo+2,a0
          cmp.l     (a0),d0             coords changed?
          beq       tool_rts
          move.l    d0,(a0)
koos_out  move.l    rec_adr,a1          ++ print coords into string ++
          move.w    d0,d1
          add.w     YX_OFF+0(a1),d1
          lea       koostr+11,a0
          bsr.s     koos_ou1
          move.l    d0,d1
          swap      d1
          add.w     YX_OFF+2(a1),d1
          subq.l    #1,a0
          bsr.s     koos_ou1
          pea       koostr
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          rts
koos_ou1  ext.l     d1                  ++ convert binary number to decimal string ++
          moveq.l   #2,d2
koos_ou3  cmp.l     #10,d1
          blo.s     koos_ou5
          divu      #10,d1
          swap      d1
koos_ou5  add.b     #'0',d1
          move.b    d1,-(a0)
          clr.w     d1
          swap      d1
          dbra      d2,koos_ou3
          rts
koos_ou2  lea       chookoo+2,a0        ++ address is not within window ++
          move.l    (a0),d0
          bmi       tool_rts
          move.l    #-1,(a0)
          pea       koostr2
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          rts
          ;
alrast    ;                             ** align XY-coords. with raster **
          move.w    chooras,-2(sp)      FIXME no register free: copy to stack to get "Z" status flag
          beq       tool_rts
          movem.l   d2-d4,-(sp)
          swap      d0
          move.w    d0,d3               X-coord.
          move.w    frraster+6,d2
          move.w    d2,d4
          lsr.w     #1,d4
          add.w     win_xy+10,d3
          bmi.s     alrast1
          sub.w     frraster+34,d3
          ext.l     d3
          divu      d2,d3
          swap      d3
          sub.w     d3,d0
          cmp.w     d4,d3
          bls.s     alrast1
          add.w     d2,d0
alrast1   swap      d0                  Y-coord.
          move.w    d0,d3
          move.w    frraster+20,d2
          move.w    d2,d4
          lsr.w     #1,d4
          add.w     win_xy+8,d3
          bmi.s     alrast2
          sub.w     frraster+48,d3
          ext.l     d3
          divu      d2,d3
          swap      d3
          sub.w     d3,d0
          cmp.w     d4,d3
          bls.s     alrast2
          add.w     d2,d0
alrast2   movem.l   (sp)+,d2-d4
tool_rts  rts
          ;
*-----------------------------------------------------------------DATA
          ;                   ; Clipping rectangle
win_xy    ds.w   2            ; Window X1/Y1 rel. to screen root 0/0
          ds.w   2            ; Window X2/Y2 (i.e. lower-right corner)
          ds.w   2            ; Y/X(!) offsets window X1/Y1 to image root 0/0 (negative!)
          ds.w   1            ; always zero (for allowing to read X off. via long?)
*---------------------------------------------------------------------
data_buf  ds.w   4                      ; scratch buffer for drawing text
koostr    dc.b   27,'Y h###/###',0
koostr1   dc.b   27,'Y h       ',0
koostr2   dc.b   27,'Y h---/---',0
koo_buff  ds.w   4
last_koo  ds.w   5   ; x0,y0; x1,y1; flag 0/-1
*---------------------------------------------------------------------
stralvie  dc.b   '[3][Polygon completed?][Ok|Continue]',0
stralmax  dc.b   '[3][Maximum is 128 corners!][Abort]',0
*---------------------------------------------------------------------
          align 2
          END
