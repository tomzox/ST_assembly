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
 module    BUTTON_2
 ;section   fuenf
 ;pagelen   32767
 ;pagewid   133
 ;noexpand
 include "f_sys.s"
 include "f_def.s"
 ;
 XREF  frradier,frpinsel,frmuster,new_1koo,new_2koo,vdicall
 XREF  hide_m,show_m,noch_qu,return,set_wrmo,win_xy,logbase
 XREF  bildbuff,frsprayd,frlinie,frpunkt,noch_qu,clip_on
 XREF  set_attr,set_att2,ret_attr,ret_att2,chooset,sinus
 ;
 XDEF  punkt,pinsel,spdose,radier,gummi,kurve

*-----------------------------------------------------------------------------
* This module (together with "fg.asm") contains handlers for drawing
* operations, which all start with a mouse click into an image window.
* See "fg.asm for details.
*-----------------------------------------------------------------------------
*   Global register mapping:
*
*  [a4   Address of address of current window record] - unused
*   a6   Base address of data section
*-----------------------------------------------------------------------------
          ;
punkt     clr.w     d1                  *** Shape: Pencil ***
          move.b    frpunkt+33,d1
          bne       punkt2
          ;                             ------- Pencil ------
          vdi       15 0 1 1            ;polyline type: solid
          vdi       16 1 0 !frpunkt+6 0 ;line width
          vdi       17 0 1 !frpunkt+20  ;polyline color index
          vdi       108 0 2 0 0         ;polyline end style: squared
          bsr       set_wrmo            ;writing mode
          bsr       hide_m
          move.l    d3,d4
          move.w    frpunkt+6,d0
          cmp       #1,d0               line width larger than 1?
          beq       punkt1
          subq.w    #1,d0               yes: draw initial dot: square with line width
          swap      d0                  ;(needed as VDI does not draw anything when X1/Y1==X2/Y2)
          ext.w     d0
          add.l     d3,d0
          move.l    d0,PTSIN+0(a6)
          move.l    d3,PTSIN+4(a6)
          vdi       6 2 0               ;polyline
          bra.s     punkt4
punkt1    move.l    d3,PTSIN+0(a6)      -- Loop while mouse button pressed --
          move.l    d4,PTSIN+4(a6)
          vdi       6 2 0               ;polyline: draw from prev. to current mouse coord.
punkt4    bsr       show_m
          bsr       new_1koo            Pos. merken
          move.l    d3,d4
          bsr       noch_qu
          bsr       hide_m
          move.l    last_koo+4,d0
          tst.b     MOUSE_LBUT+1(a6)
          bne       punkt1              -> another dot to draw
          bra       ret_attr
          ;
punkt2    addq.b    #1,d1               ------ Polymarker ------
          vdi       18 0 1 !d1          ;set_polymarker_type
          move.w    frpunkt+6,d0
          mulu.w    #11,d0
          sub.w     #5,d0
          vdi       19 1 0 0 !d0        ;...height
          vdi       20 0 1 !frpunkt+20  ;...color_index
          bsr       set_wrmo            ;...writing_mode
          bsr       clip_on
punkt3    bsr       hide_m              -- Loop while mouse button pressed --
          bsr       new_1koo
          move.l    d3,PTSIN+0(a6)
          vdi       7 1 0               ;polymarker
          bsr       show_m
          bsr       noch_qu
          tst.b     MOUSE_LBUT+1(a6)
          bne       punkt3              loop to next marker
          bsr       hide_m
          bra       return
          ;
*-----------------------------------------------------------------------------
pinsel    move.b    frpinsel+33,d0      *** Shape: Brush ***
          cmp.b     #4,d0
          beq       pinsel7
pinsel6   bsr       set_wrmo            -- initialization --
          bsr       clip_on
          vdi       23 0 1 !frmuster+6  ; fill style
          vdi       24 0 1 !frmuster+20 ; fill index
          vdi       25 0 1 !frpinsel+20 ; fill color
          vdi       104 0 1 0           ; border off
          clr.w     d0                  calc. the offset table
          move.b    frpinsel+33,d0      get shape of the brush from config
          lsl.w     #2,d0
          lea       pin_data,a0
          add.w     d0,a0
          move.w    frpinsel+6,d6       get size of the brush from config
          move.w    d6,d7
          muls.w    (a0)+,d6            D6: X-offset
          bne.s     pinsel11
          add.w     #1,d6
pinsel11  muls.w    (a0),d7             D7: Y-offset
          bne.s     pinsel1
          add.w     #1,d7
pinsel1   move.l    d3,d4               -- Loop while mouse button pressed --
          bsr       noch_qu
          bsr       hide_m
          tst.b     MOUSE_LBUT+1(a6)
          beq       ret_att2            -> done
          move.l    d3,PTSIN+0(a6)
          move.l    d4,PTSIN+4(a6)
          move.l    d4,PTSIN+8(a6)
          move.l    d3,PTSIN+12(a6)
          sub.w     d6,PTSIN+0(a6)
          sub.w     d6,PTSIN+4(a6)
          add.w     d6,PTSIN+8(a6)
          add.w     d6,PTSIN+12(a6)
          sub.w     d7,PTSIN+2(a6)
          sub.w     d7,PTSIN+6(a6)
          add.w     d7,PTSIN+10(a6)
          add.w     d7,PTSIN+14(a6)
          vdi       9 4 0               ;filled area (4 corners)
          bsr       show_m
          bra       pinsel1
          ;
pinsel7   move.w    frpinsel+6,d0       --- Shape "O" brush ---
          beq       pinsel6
          lsl.w     #1,d0
          addq.w    #1,d0
          vdi       16 1 0 !d0 0        ; polyline line width: brush width
          vdi       17 0 1 !frpinsel+20 ; polyline color
          vdi       108 0 2 0 2         ; polyline end style: round end
          bsr       set_wrmo
          bsr       clip_on
pinsel8   move.l    d3,d4               -- Loop while mouse button pressed --
          bsr       noch_qu
          tst.b     MOUSE_LBUT+1(a6)
          beq.s     pinsel9
          bsr       hide_m
          move.l    d3,PTSIN+0(a6)      ; X1/Y1 = X2/Y2
          move.l    d4,PTSIN+4(a6)
          vdi       6 2 0               ; polyline
          bsr       show_m
          bra       pinsel8
pinsel9   move.l    PTSIN+0(a6),d0
          move.l    PTSIN+4(a6),d1
          bsr       new_2koo
          vdi       16 1 0 1 0
          vdi       17 0 1 1
          vdi       108 0 2 0 0
          bsr       hide_m
          bra       return
          ;
*-----------------------------------------------------------------------------
spdose    bsr       hide_m              *** Shape: Spraycan ***
          moveq.l   #1,d6
          moveq.l   #1,d7
          clr.w     d0
          move.b    frsprayd+19,d0      get spray mode from config
          move.w    d0,d1
          lsl.w     #1,d1
          lea       spdosex,a0
          move.w    (a0,d1.w),spdose7-spdosex(a0)
          cmp.b     #3,d0               INV-Modus ?
          blo.s     spdose9
          move.l    bildbuff,a0
          move.w    #3999,d0
spdose10  clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,spdose10
spdose9   move.l    bildbuff,a0         initialize density table
          lea       spr_dich,a1
          moveq.l   #15,d0
spdose2   move.w    frsprayd+6,d1       get spray radius from config
          addq.w    #1,d1
          mulu.w    (a1)+,d1
          lsr.w     #7,d1
          move.w    d1,(a0)+
          dbra      d0,spdose2
          move.l    bildbuff,a3         A3: Address of density table
          lea       sinus,a4
spdose1   move.w    #17,-(sp)           get RAND number
          trap      #14
          addq.l    #2,sp
          move.l    d0,d5
          add.w     d0,d7               D7: angle * 2
          eor.w     d6,d7
          and.w     #$fe,d7
          cmp.w     #180,d7
          blo.s     spdose3
          sub.w     #180,d7
spdose3   lsr.l     #8,d0
          add.w     d0,d6               D6: radius
          eor.w     d7,d6
          lsr.w     #8,d0
          and.w     #$1e,d0
          divu      (a3,d0.w),d6
          clr.w     d6
          swap      d6
          move.w    d6,d2
          mulu.w    (a4,d7.w),d2        D2: Y-offset
          swap      d2
          rol.l     #1,d2
          move.w    d6,d1
          neg.w     d7
          add.w     #180,d7
          mulu.w    (a4,d7.w),d1        D1: X-offset
          swap      d1
          rol.l     #1,d1
          btst      #23,d5
          beq.s     spdose4
          neg.w     d2
spdose4   btst      #22,d5
          beq.s     spdose5
          neg.w     d1
spdose5   sub.l     a0,a0               calc pixel-addresse
          move.w    d3,d4
          add.w     d2,d4
          cmp.w     win_xy+2,d4         still within the window?
          blo.s     spdose6
          cmp.w     win_xy+6,d4
          bhi.s     spdose6
          mulu.w    #80,d4
          add.l     d4,a0               Y-byte
          swap      d3
          add.w     d1,d3
          cmp.w     win_xy,d3           still within the window?
          blo.s     spdose6
          cmp.w     win_xy+4,d3
          bhi.s     spdose6
          move.w    d3,d4
          lsr.w     #3,d3
          add.w     d3,a0               X-byte
          and.w     #7,d4
          neg.w     d4
          add.w     #7,d4
          move.b    frsprayd+19,d0      INV mode?
          cmp.b     #3,d0
          blo.s     spdose8
          move.l    bildbuff,a1
          add.l     a0,a1
          bset.b    d4,(a1)
          bne.s     spdose6
spdose8   add.l     logbase,a0
spdose7   bset.b    d4,(a0)
spdose6   move.l    MOUSE_CUR_XY(a6),d3
          tst.b     MOUSE_LBUT+1(a6)
          bne       spdose1
          rts
spdosex   bclr.b    d4,(a0)             op-code table for different spray modes
          bset.b    d4,(a0)
          bchg.b    d4,(a0)
          bchg.b    d4,(a0)
          ;
*-----------------------------------------------------------------------------
gummi     bsr       set_att2            *** Shape: Rubberband ***
          move.l    d3,d7
          clr.w     d0
          clr.w     d1
          move.b    frlinie+47,d0
          move.b    frlinie+49,d1
          vdi       108 0 2 !d0 !d1     ;set_line_end
gummi1    bsr       show_m
          bsr       noch_qu
          bsr       hide_m
          tst.b     MOUSE_LBUT+1(a6)
          beq       ret_attr
          move.l    d7,PTSIN+0(a6)
          move.l    d3,PTSIN+4(a6)
          vdi       6 2 0               ;polyline
          bra       gummi1
          ;
*-----------------------------------------------------------------------------
radier    move.b    frradier+33,d0      *** Shape: Eraser ***
          bne.s     radier3
          bsr       clip_on             -- normal mode --
          vdi       32 0 1 1            ;set writing mode: replace
          vdi       23 0 1 1            ;fill pattern type: opaque
          vdi       25 0 1 0            ;fill color: 0
          bra.s     radier4
radier3   lea       chooset,a3          -- pattern mode --
          move.w    (a3),d6             D6/D7: backup shape fill configuration
          move.w    4(a3),d7
          move.w    #-1,(a3)            temporarily enable fill & rounded corner (actually unused)
          clr.w     4(a3)               temporarily disable border
          bsr       set_attr
          move.w    d6,(a3)             restore config.
          move.w    d7,4(a3)
radier4   move.w    frradier+6,d5       X-offset
          move.w    d5,d7
          lsr.w     #1,d5
          lsr.w     #1,d7
          bcs.s     radier2
          subq.w    #1,d7
radier2   swap      d7
          move.w    frradier+20,d6      Y-offset
          move.w    d6,d7
          lsr.w     #1,d6
          lsr.w     #1,d7
          bcs.s     radier1
          subq.w    #1,d7
radier1   bsr       hide_m              ++ loop ++
          move.l    d3,PTSIN+0(a6)
          move.l    d3,PTSIN+4(a6)
          sub.w     d5,PTSIN+0(a6)
          sub.w     d6,PTSIN+2(a6)
          add.l     d7,PTSIN+4(a6)
          move.w    #1,CONTRL+10(a6)
          vdi       11 2 0              ;bar
          bsr       show_m
          bsr       noch_qu
          tst.b     MOUSE_LBUT+1(a6)
          bne       radier1             -> continue loop
          bsr       hide_m
          bra       ret_att2
          ;
kurve     bra       hide_m              *** Curve ***
          ;
*-----------------------------------------------------------------DATA--------
pin_data  dc.w  0,1     ; shape "|"
          dc.w  1,0     ; shape "-"
          dc.w  1,-1    ; shape "/"
          dc.w  1,1     ; shape "\"  (note shape "O" handled separately)
spr_dich  dc.w  60,76,85,90,95,96,97,98,99,103,108,111,115,120,124,128
*-----------------------------------------------------------------------------
          END
