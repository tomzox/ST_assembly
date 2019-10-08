; ----------------------------------------------------------------------------
; Copyright 1987-1988 by T.Zoerner (tomzo at users.sf.net)
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
 section   fuenf
 pagelen   32767
 pagewid   133
 noexpand
 ;
 XREF  frradier,frmodus,frpinsel,frmuster,new_1koo,new_2koo,vdicall
 XREF  maus_rec,hide_m,show_m,noch_qu,return,set_wrmo,win_xy,logbase
 XREF  bildbuff,ptsin,frsprayd,frlinie,frpunkt,noch_qu,clip_on
 XREF  set_attr,set_att2,ret_attr,ret_att2,maus_rec,chooset,sinus
 ;
 XDEF  punkt,pinsel,spdose,radier,gummi,kurve
          ;
moove     macro     l quelle ziel
          ifstr     [quelle] = 0 goto moove1
          ifstr     [.left(quelle,1)] = {!} goto moove2
quelle    setstr    { #[quelle]}
moove2    maclab
          move.[l]  [.right(quelle,[.len(quelle)]-1)],[ziel]
          goto      exit
moove1    maclab
          clr.[l]   [ziel]
exit      maclab
          endm
          ;
aes       macro     code sintin sintout saddrin saddrout
          local     parnum,count
          move.w    #[code],(a5)
          moove     l,[sintin]<<16+[sintout],2(a5)
          moove     l,[saddrin]<<16+[saddrout],6(a5)
parnum    setnum    6
count     setnum    0
aes1      maclab
          ifnum     [sintin] = 0 goto aes2
          ifnum     [parnum] > [.nparms] goto aescal
          moove     w,[.parm([parnum])],([parnum]-6)*2(a6)
parnum    setnum    [parnum]+1
sintin    setnum    [sintin]-1
          goto      aes1
aes2      maclab
          ifnum     [saddrin] = 0 goto aescal
          moove     l,[.parm([parnum])],addrin+[count]*4
count     setnum    [count]+1
saddrin   setnum    [saddrin]-1
parnum    setnum    [parnum]+1
          goto      aes2
aescal    maclab
          bsr       aescall
          endm
          ;
vdi       macro     code,sptsin,sintin
          local     parnum,count
          move.l    #[code]<<16+[sptsin],(a5)
          moove     w,[sintin],6(a5)
parnum    setnum    4
count     setnum    0
vdi1      maclab
          ifnum     [parnum] > [.nparms] goto vdi3
          ifnum     [sptsin] = 0 goto vdi2
          moove     w,[.parm([parnum])],([parnum]-4)*2(a4)
          moove     w,[.parm([parnum]+1)],([parnum]-3)*2(a4)
parnum    setnum    [parnum]+2
sptsin    setnum    [sptsin]-1
          goto      vdi1
vdi2      maclab
          tst.w     d6
          ifnum     [sintin] = 0 goto vdi3
          moove     w,[.parm([parnum])],[count]*2(a6)
count     setnum    [count]+1
parnum    setnum    [parnum]+1
sintin    setnum    [sintin]-1
          goto      vdi2
vdi3      maclab
          bsr       vdicall
          endm
          ;        *** Offsets zu Window-Records ***
bild_adr  equ  2    Adresse des Bildpuffers
          ;
**********************************************************************
*   A6   Zeiger auf INTIN
*   A5   Zeiger auf CONTRL
*   A4   Zeiger auf PTSIN
**********************************************************************
          ;
punkt     clr.w     d1                  *** Punkt ***
          move.b    frpunkt+33,d1
          bne.s     punkt2
          clr.l     d0                  ------- Ein Pixel ------
          move.b    frpunkt+35,d0       Schreibmodus festsetzen
          lea       punktdat,a0
          move.b    (a0,d0.l),punkt1+1
punkt4    move.l    d3,d1
          move.l    d3,d0
          swap      d0
          ext.l     d0
          move.l    logbase,a2          Adresse berechnen
          mulu.w    #80,d1
          add.l     d1,a2
          divu      #8,d0
          add.w     d0,a2
          swap      d0
          moveq.l   #7,d2
          sub.b     d0,d2
          bsr       hide_m
punkt1    bclr.b    d2,(a2)             Punkt setzen
          bsr       show_m
          bsr       new_1koo            Pos. merken
          bsr       noch_qu
          move.b    maus_rec+1,d0
          bne       punkt4              -> noch ein Punkt
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
          move.l    d3,(a4)
          vdi       7 1 0               ;polymarker
          bsr       show_m
          bsr       noch_qu
          move.b    maus_rec+1,d0
          bne       punkt3              n„chste Markierung
          bsr       hide_m
          bra       return
          ;
pinsel    cmp.b     #4,frpinsel+33      *** Pinsel ***
          beq       pinsel7
pinsel6   bsr       set_wrmo            -- Initialisierung --
          bsr       clip_on
          vdi       23 0 1 !frmuster+6
          vdi       24 0 1 !frmuster+20
          vdi       25 0 1 !frpinsel+20
          vdi       104 0 1 0
          clr.w     d0                  Berechnung der zug. Off.tab.
          move.b    frpinsel+33,d0      Pinselform
          lsl.w     #2,d0
          lea       pin_data,a0
          add.w     d0,a0
          move.w    frpinsel+6,d6       Pinselgr”že
          move.w    d6,d7
          muls.w    (a0)+,d6            D6: X-Off
          muls.w    (a0),d7
pinsel1   move.l    d3,d4               -- Schleife --
          bsr       noch_qu
          bsr       hide_m
          move.b    maus_rec+1,d0
          beq       ret_att2            -> fertig
          move.l    d3,(a4)
          move.l    d4,4(a4)
          move.l    d4,8(a4)
          move.l    d3,12(a4)
          sub.w     d6,(a4)
          sub.w     d6,4(a4)
          add.w     d6,8(a4)
          add.w     d6,12(a4)
          sub.w     d7,2(a4)
          sub.w     d7,6(a4)
          add.w     d7,10(a4)
          add.w     d7,14(a4)
          vdi       9 4 0               ;filled area
          bsr       show_m
          bra       pinsel1
pinsel7   move.w    frpinsel+6,d0       --- O-Pinsel ---
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
          move.l    d3,(a4)
          move.l    d4,4(a4)
          vdi       6 2 0
          bsr       show_m
          bra       pinsel8
pinsel9   move.l    (a4),d0
          move.l    4(a4),d1
          bsr       new_2koo
          vdi       16 1 0 1 0
          vdi       17 0 1 1
          vdi       108 0 2 0 0
          bsr       hide_m
          bra       return
          ;
spdose    bsr       hide_m              *** Sprhdose ***
          moveq.l   #1,d6
          moveq.l   #1,d7
          clr.w     d0
          move.b    frsprayd+19,d0      Schreibmodus festsetzen
          lea       mode_dat,a0
          move.b    (a0,d0.w),spdose7+1
          cmp.b     #3,d0               INV-Modus ?
          blo.s     spdose9
          move.l    bildbuff,a0
          move.w    #3999,d0
spdose10  clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,spdose10
spdose9   move.l    bildbuff,a0         Dichte-Tab initialisieren
          lea       spr_dich,a1
          moveq.l   #15,d0
spdose2   move.w    frsprayd+6,d1
          addq.w    #1,d1
          mulu.w    (a1)+,d1
          lsr.w     #7,d1
          move.w    d1,(a0)+
          dbra      d0,spdose2
          move.l    bildbuff,a3         A3: Zeiger auf Dichte-Tabelle
          lea       sinus,a4
spdose1   move.w    #17,-(sp)           Zufallszahl holen
          trap      #14
          addq.l    #2,sp
          move.l    d0,d5
          add.w     d0,d7               D7: Winkel * 2
          eor.w     d6,d7
          and.w     #$fe,d7
          cmp.w     #180,d7
          blo.s     spdose3
          sub.w     #180,d7
spdose3   lsr.l     #8,d0
          add.w     d0,d6               D6: Radius
          eor.w     d7,d6
          lsr.w     #8,d0
          and.w     #$1e,d0
          divu      (a3,d0.w),d6
          clr.w     d6
          swap      d6
          move.w    d6,d2
          mulu.w    (a4,d7.w),d2        D2: Y-Offset
          swap      d2
          rol.l     #1,d2
          move.w    d6,d1
          neg.w     d7
          add.w     #180,d7
          mulu.w    (a4,d7.w),d1        D1: X-Offset
          swap      d1
          rol.l     #1,d1
          btst      #23,d5
          beq.s     spdose4
          neg.w     d2
spdose4   btst      #22,d5
          beq.s     spdose5
          neg.w     d1
spdose5   sub.l     a0,a0               Pixel-Adresse berechnen
          move.w    d3,d4
          add.w     d2,d4
          cmp.w     win_xy+2,d4         Im Fenster ?
          blo.s     spdose6
          cmp.w     win_xy+6,d4
          bhi.s     spdose6
          mulu.w    #80,d4
          add.l     d4,a0               Y-Byte
          swap      d3
          add.w     d1,d3
          cmp.w     win_xy,d3           Im Fenster ?
          blo.s     spdose6
          cmp.w     win_xy+4,d3
          bhi.s     spdose6
          move.w    d3,d4
          lsr.w     #3,d3
          add.w     d3,a0               X-Byte
          and.w     #7,d4
          neg.w     d4
          add.w     #7,d4
          cmp.b     #3,frsprayd+19      INV-Modus ?
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
          lea       ptsin,a4
          rts
          ;
gummi     bsr       set_att2            *** Gummiband ***
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
          move.l    d7,(a4)
          move.l    d3,4(a4)
          vdi       6 2 0               ;polyline
          bra       gummi1
          ;
radier    move.b    frradier+33,d0      *** Radiergummi ***
          bne.s     radier3
          bsr       clip_on             -- Normal-Mode --
          vdi       32 0 1 1
          vdi       23 0 1 1
          vdi       25 0 1 0
          bra.s     radier4
radier3   lea       chooset,a3          -- Muster-Mode --
          move.w    (a3),d6
          move.w    4(a3),d7
          move.w    #-1,(a3)
          clr.w     4(a3)
          bsr       set_attr
          move.w    d6,(a3)
          move.w    d7,4(a3)
radier4   move.w    frradier+6,d5       X-Off
          move.w    d5,d7
          lsr.w     #1,d5
          lsr.w     #1,d7
          bcs.s     radier2
          subq.w    #1,d7
radier2   swap      d7
          move.w    frradier+20,d6      Y-Off
          move.w    d6,d7
          lsr.w     #1,d6
          lsr.w     #1,d7
          bcs.s     radier1
          subq.w    #1,d7
radier1   bsr       hide_m              ++ Schleife ++
          move.l    d3,(a4)
          move.l    d3,4(a4)
          sub.w     d5,(a4)
          sub.w     d6,2(a4)
          add.l     d7,4(a4)
          move.w    #1,10(a5)
          vdi       11 2 0              ;bar
          bsr       show_m
          bsr       noch_qu
          move.b    maus_rec+1,d0
          bne       radier1             -> weiter
          bsr       hide_m
          bra       ret_att2
          ;
kurve     bra       hide_m              *** Schwingung ***
          ;
*=================================================================DATA
punktdat  dc.b  %10010010,%11010010,%01010010,0
pin_data  dc.w  0,1,-1,0,1,-1,1,1
mode_dat  dc.b  %10010000,%11010000,%01010000,%01010000
spr_dich  dc.w  60,76,85,90,95,96,97,98,99,103,108,111,115,120,124,128
*---------------------------------------------------------------------
          ;
hexaus    movem.l   d0-d5/a0-a2,-(sp)
          move.l    d0,d4
          lea       hexzahl,a2
          moveq.l   #7,d5
hexloop   move.b    d4,d0
          and.b     #$0f,d0
          add.b     #48,d0
          cmp.b     #58,d0
          blt.s     ziffer
          add.b     #7,d0
ziffer    move.b    d0,-(a2)
          lsr.l     #4,d4
          dbra      d5,hexloop
          pea       hexstr
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          movem.l   (sp)+,d0-d5/a0-a2
          rts
hexstr    dc.b      '########'
hexzahl   dc.b      13,10,0
header    dc.b      27,'Y% ',0
hexraus   movem.l   d0-d3/a0-a3,-(sp)
          pea       header
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          movem.l   (sp)+,d0-d3/a0-a3
          movem.l   d0-d3/a0-a3,-(sp)
*         move.l    (a4),d0
*         bsr       hexaus
*         move.l    4(a4),d0
*         bsr       hexaus
*         move.l    8(a4),d0
*         bsr       hexaus
*         move.l    12(a4),d0
*         bsr       hexaus
*         move.l    d1,d0
*         bsr       hexaus
*         move.l    d5,d0
*         bsr       hexaus
*         move.l    d6,d0
*         bsr       hexaus
*         move.l    d6,d0
*         bsr       hexaus
*         move.w    #1,-(sp)
*         trap      #1
*         addq.l    #2,sp
*         tst.w     d0
*         beq.s     traprts
          movem.l   (sp)+,d0-d3/a0-a3
          rts
*raprts   movem.l   (sp)+,d0-d3/a0-a3
*         addq.l    #4,sp
*         lea       ptsin,a4
*         rts
          ;
          end
