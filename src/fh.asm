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
 XREF  frradier,frmodus,frpinsel,frmuster,new_1koo,new_2koo,vdicall
 XREF  maus_rec,hide_m,show_m,noch_qu,return,set_wrmo,win_xy,logbase
 XREF  bildbuff,frsprayd,frlinie,frpunkt,noch_qu,clip_on
 XREF  set_attr,set_att2,ret_attr,ret_att2,maus_rec,chooset,sinus
 ;
 XDEF  punkt,pinsel,spdose,radier,gummi,kurve
          ;
**********************************************************************
*   Global register mapping:
*
*  [a4   Address of address of current window record] - unused
*   a6   Base address of data section
**********************************************************************
          ;
punkt     clr.w     d1                  *** Shape: Pencil ***
          move.b    frpunkt+33,d1
          bne.s     punkt2
          clr.l     d0                  ------- Single Pixel ------
          move.b    frpunkt+35,d0       set drawing mode
          lea       punktdat,a0
          move.b    (a0,d0.l),punkt1+1
punkt4    move.l    d3,d1
          move.l    d3,d0
          swap      d0
          ext.l     d0
          move.l    logbase,a2          calc. address
          mulu.w    #80,d1
          add.l     d1,a2
          divu      #8,d0
          add.w     d0,a2
          swap      d0
          moveq.l   #7,d2
          sub.b     d0,d2
          bsr       hide_m
punkt1    bclr.b    d2,(a2)             draw dot
          bsr       show_m
          bsr       new_1koo            Pos. merken
          bsr       noch_qu
          move.b    maus_rec+1,d0
          bne       punkt4              -> another dot to draw
          bra       hide_m
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
punkt3    bsr       hide_m
          bsr       new_1koo
          move.l    d3,PTSIN+0(a6)
          vdi       7 1 0               ;polymarker
          bsr       show_m
          bsr       noch_qu
          move.b    maus_rec+1,d0
          bne       punkt3              loop to next marker
          bsr       hide_m
          bra       return
          ;
pinsel    cmp.b     #4,frpinsel+33      *** Shape: Brush ***
          beq       pinsel7
pinsel6   bsr       set_wrmo            -- initialization --
          bsr       clip_on
          vdi       23 0 1 !frmuster+6
          vdi       24 0 1 !frmuster+20
          vdi       25 0 1 !frpinsel+20
          vdi       104 0 1 0
          clr.w     d0                  calc. the offset table
          move.b    frpinsel+33,d0      get shape of the brush from config
          lsl.w     #2,d0
          lea       pin_data,a0
          add.w     d0,a0
          move.w    frpinsel+6,d6       get size of the brush from config
          move.w    d6,d7
          muls.w    (a0)+,d6            D6: X-offset
          muls.w    (a0),d7
pinsel1   move.l    d3,d4               -- Loop --
          bsr       noch_qu
          bsr       hide_m
          move.b    maus_rec+1,d0
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
          vdi       9 4 0               ;filled area
          bsr       show_m
          bra       pinsel1
pinsel7   move.w    frpinsel+6,d0       --- Shape "O" brush ---
          beq       pinsel6
          lsl.w     #1,d0
          addq.w    #1,d0
          vdi       16 1 0 !d0 0
          vdi       17 0 1 !frpinsel+20
          vdi       108 0 2 0 2
          bsr       set_wrmo
          bsr       clip_on
pinsel8   move.l    d3,d4
          bsr       noch_qu
          move.b    maus_rec+1,d0
          beq.s     pinsel9
          bsr       hide_m
          move.l    d3,PTSIN+0(a6)
          move.l    d4,PTSIN+4(a6)
          vdi       6 2 0
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
spdose    bsr       hide_m              *** Shape: Spraycan ***
          moveq.l   #1,d6
          moveq.l   #1,d7
          clr.w     d0
          move.b    frsprayd+19,d0      get spray mode from config
          lea       mode_dat,a0
          move.b    (a0,d0.w),spdose7+1
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
          cmp.b     #3,frsprayd+19      INV mode?
          blo.s     spdose8
          move.l    bildbuff,a1
          add.l     a0,a1
          bset.b    d4,(a1)
          bne.s     spdose6
spdose8   add.l     logbase,a0
spdose7   bset.b    d4,(a0)
spdose6   move.l    maus_rec+12,d3
          move.b    maus_rec+1,d0
          bne       spdose1
          rts
          ;
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
          move.b    maus_rec+1,d0
          beq       ret_attr
          move.l    d7,PTSIN+0(a6)
          move.l    d3,PTSIN+4(a6)
          vdi       6 2 0               ;polyline
          bra       gummi1
          ;
radier    move.b    frradier+33,d0      *** Shape: Eraser ***
          bne.s     radier3
          bsr       clip_on             -- normal mode --
          vdi       32 0 1 1
          vdi       23 0 1 1
          vdi       25 0 1 0
          bra.s     radier4
radier3   lea       chooset,a3          -- pattern mode --
          move.w    (a3),d6
          move.w    4(a3),d7
          move.w    #-1,(a3)
          clr.w     4(a3)
          bsr       set_attr
          move.w    d6,(a3)
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
          move.b    maus_rec+1,d0
          bne       radier1             -> continue loop
          bsr       hide_m
          bra       ret_att2
          ;
kurve     bra       hide_m              *** Curve ***
          ;
*=================================================================DATA
punktdat  dc.b  %10010010,%11010010,%01010010,0
pin_data  dc.w  0,1,-1,0,1,-1,1,1
mode_dat  dc.b  %10010000,%11010000,%01010000,%01010000
spr_dich  dc.w  60,76,85,90,95,96,97,98,99,103,108,111,115,120,124,128
*---------------------------------------------------------------------
          end
