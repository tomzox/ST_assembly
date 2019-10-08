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
 module    BUTTON_1
 section   zwei
 pagelen   32767
 pagewid   133
 noexpand
 ;
 XREF  frmodus,frmuster,frtext,frlinie,frraster,frzeiche
 XREF  chookoo,choofig,chooset,chooras,chootxt,choopat,chooseg
 XREF  menu_adr,rec_adr,drawflag,mrk,logbase,bildbuff
 XREF  maus_rec,copy_blk,save_scr,fram_del,form_do,form_del
 XREF  hide_m,show_m,work_blk,work_bl2,alertbox,pinsel,spdose,gummi
 XREF  punkt,kurve,radier,over_old,over_que,over_beg
 ;
 XDEF  evt_button,stack,appl_id,aescall,vdicall,grhandle,aespb,vdipb
 XDEF  contrl,intin,intout,ptsin,ptsout,addrin,addrout,mark_buf
 XDEF  win_xy,fram_drw,save_buf,win_abs,noch_qu,return,set_wrmo
 XDEF  koos_mak,clip_on,new_1koo,new_2koo,noch_qu,set_att2,ret_att2
 XDEF  noch_qu,ret_attr,set_attr,fram_ins,last_koo
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
          ;       *** Offsets zu Window-Records ***
bild_adr  equ  2   Adresse des Bildpuffers
yx_off    equ  16  Abstand Fensterursprung zu 0/0
fenster   equ  22  Pos und Grîûe
schieber  equ  30  Schieber oder -1 -> Abs-Fenster
      ;       *** Offsets zu Window-Records ***
copy  equ  0   Kopieren?
vmod  equ  1   akt. VerknÅpf-mode
einf  equ  2   Auss im Buff(Adr. drawflag+12)?
ovku  equ  3   OV-Kurz-Mode?
del   equ  5   alten Auss lîschen vor schub?
ov    equ  6   OV-Mode?
buff  equ  8   Adr. OV-Buffer
chg   equ  12  bearbeitet?
part  equ  13  öberhang?
modi  equ  14  VerknÅpfungsmodi akt/letzter Auss
old   equ  16  öberhang-->alte Koo/Offset
      ;
**********************************************************************
*  A6  Zeiger auf INTIN
*  A5  Zeiger auf CONTRL
*  A4  Zeiger auf PTSIN
**********************************************************************
          ;
evt_butt  lea       win_xy,a0           WIN_XY: Fensterkoordinaten
          move.l    yx_off(a4),8(a0)
          clr.w     12(a0)
          bsr       win_abs
          move.l    maus_rec+16,d0
          bsr       raster              Rastern falls gewÅnscht
          move.l    d0,maus_rec+16
          move.w    d0,d1
          swap      d0
          bsr       noch_in             Click innerhalb Fenster ?
          bne       donot               nein -> Abbruch
          cmp.w     #$43,choofig        ++ Markieren gewÑhlt ? ++
          bne.s     evt_but5
          move.w    mark_buf,d2         Ausschnitt markiert ?
          beq.s     evt_but4
          lea       mark_buf+2,a0
          add.w     win_xy+8,d1
          add.w     win_xy+10,d0
          bsr       noch_in             Click im mark. Bereich ?
          beq       schub               -> Ausschnitt verschieben
          bsr       fram_drw
          bra.s     evt_but4
evt_but5  move.l    drawflag+12,d0      ++ Norm-Werkzeug ++
          cmp.l     bild_adr(a4),d0
          bne.s     evt_but4
          clr.w     mrk+einf            EinfÅgen disabeln
          move.l    menu_adr,a0
          bset.b    #3,1643(a0)
evt_but4  bsr       save_scr
          lea       drawflag,a0
          move.w    #$ff00,(a0)
          lea       last_koo,a0
          clr.w     8(a0)
          lea       ptsin,a4            A4: Zeiger auf PTSIN
          move.l    maus_rec+16,d3      D3: X/Y-Position der Maus
*- - - - - - - - - - - - - - - - - - - - - - - - - - -GRAPHICS-HANDLER
          move.w    choofig,d0
          cmp.b     #$55,d0
          beq       pospe               Pos speichern
          cmp.b     #$43,d0
          bne.s     evt_but6
          moveq.l   #$27,d0             Auss markieren
evt_but6  sub.w     #$1f,d0
          lsl.w     #1,d0
          lea       a,a0
          move.w    (a0,d0.w),d0
          jsr       (a0,d0.w)           Graphik-Routine abarbeiten
*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit_beg  lea       last_koo,a1         + Koordinaten absolut machen +
          move.w    8(a1),d2
          beq.s     exit1
          move.l    rec_adr,a0
          move.w    yx_off(a0),d0
          move.w    yx_off+2(a0),d1
          cmp.w     #1,d2
          beq.s     exit2
          add.w     d0,2(a1)
          add.w     d1,(a1)
exit2     add.w     d0,6(a1)
          add.w     d1,4(a1)
exit1     move.b    drawflag,d0
          beq.s     exit6
          move.l    rec_adr,a0          Abs-Fenster ?
          move.w    schieber(a0),d0     -> Keine Kopie nîtig
          bmi       exit6
          bsr       save_buf            Buffer sichern
          bsr       win_abs             + neuen Ausschnitt einfÅgen +
          move.l    win_xy,d0
          move.l    win_xy+4,d1
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     yx_off(a0),d2
          add.l     yx_off+2(a0),d2
          move.l    bild_adr(a0),a1
          move.l    logbase,a0
          bsr       copy_blk
exit3     move.l    menu_adr,a0
          bclr.b    #3,491(a0)          "RÅckgÑngig" enabeln
          move.w    mark_buf,d0
          beq.s     exit6
          bsr       fram_drw
exit6     bsr       show_m
exit7     move.b    maus_rec+1,d0       Auf Click-Ende warten
          bne       exit7
          clr.w     maus_rec
exit      rts
          ;
donot     lea       maus_rec,a0         Click ist unbrauchbar
          move.w    #-1,2(a0)
          rts
          ;
*---------------------------------------------------------------------
a         dc.w     punkt-a,pinsel-a,spdose-a,fuellen-a,text-a,radier-a
          dc.w     gummi-a,linie-a,quadrat-a,quadrat-a,linie-a,kreis-a
          dc.w     kreis-a,kurve-a
          ;
*-----------------------------------------------------GRAPHIK-ROUTINEN
pospe     lea       drawflag,a0         *** Pos speichern ***
          clr.w     (a0)
          move.l    rec_adr,a0
          add.w     yx_off(a0),d3
          add.l     yx_off+2(a0),d3
          lea       last_koo,a0
          move.l    4(a0),(a0)+
          move.l    d3,(a0)
          bra       exit7
          ;
linie     dc.w      $a000               *** Gerade ziehen ***
          move.l    a0,a3
          move.l    d3,38(a3)           Anfangspunkt
          clr.l     d4
          bra.s     linie2+2
linie2    move.l    d3,d4               D2: Letzter Endpunkt
          bsr       noch_qu
          bsr       hide_m
          move.w    #$aaaa,34(a3)       Linienmuster grau
          move.w    #2,36(a3)           Schreibmodus XOR
          tst.w     d4
          beq.s     linie3
          move.l    d4,42(a3)           alte Linie lîschen
          dc.w      $a003
linie3    move.b    maus_rec+1,d0
          beq.s     linie1
          move.l    d3,42(a3)           neue Linie zeichnen
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          bsr       show_m
          bra       linie2
linie1    tst.w     d4                  Maus bewegt ?
          beq.s     linie4
          move.w    choofig,d0
          cmp.w     #$29,d0             Vieleck zeichnen ?
          beq.s     vieleck
linie4    bsr       set_att2            --- entgÅltige Linie ---
          move.l    frlinie+46,d0
          and.l     #$30003,d0
          move.l    d0,(a6)
          vdi       108 0 2             ;...end_styles
          move.l    38(a3),d0
          move.l    d3,d1
          bsr       new_2koo
          move.l    d0,(a4)
          move.l    d3,4(a4)
          vdi       6 2 0               ;polyline
          bra       ret_att2
          ;
vieleck   clr.w     maus_rec            *** Vieleck ***
          move.l    bildbuff,a2
          move.l    38(a3),(a2)+
          move.l    d4,(a2)
          move.l    a2,d7
          move.l    d4,d6
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
          bsr       show_m
vieleck7  moveq.l   #-1,d3              erste Mausbewegung erwarten
          bsr       vieleck3            Return ?
          move.l    maus_rec+12,d0
          lea       win_xy,a0
          bsr       corr_adr
          cmp.l     d6,d3
          beq       vieleck7
          bsr       hide_m
          move.l    d7,d0               erst Startlinie gez. ?
          sub.l     bildbuff,d0
          cmp.l     #4,d0
          bls.s     vieleck2
          move.l    d6,42(a3)           letzte Ursprungs-Linie lîschen
          move.l    bildbuff,a0
          move.l    (a0),38(a3)
          move.w    #$aaaa,34(a3)
          move.w    #2,36(a3)
          dc.w      $a003
vieleck2  move.l    d3,d4               +++ Schleife +++
          bsr       viele_dr            neue Linien zeichnen
          bsr       show_m
vieleck4  bsr.s     vieleck3            Return ?
          moveq.l   #-1,d3
          move.w    maus_rec,d0         Mausknopf ?
          bne.s     vieleck5
          move.l    maus_rec+12,d0      Maus bewegt ?
          lea       win_xy,a0
          bsr       corr_adr
          cmp.l     d3,d4
          beq       vieleck4
          bsr       hide_m              alte Linien lîschen
          bsr       viele_dr
          bra       vieleck2
          ;
vieleck5  bsr       hide_m              +++ Knopfdruck +++
          addq.l    #4,d7
          move.l    d7,a2
          move.l    d4,(a2)
          move.l    d4,d6
vieleck6  move.b    maus_rec+1,d0
          bne       vieleck6
          clr.w     maus_rec
          bsr       show_m
          move.l    d7,d0               Schon 128 Ecken ?
          sub.l     bildbuff,d0
          lsr.w     #2,d0
          sub.b     #2,d0
          bpl       vieleck7
          lea       stralmax,a0
          moveq.l   #1,d0
          bsr       alertbox
          bra.s     vielec10
          ;
vieleck3  move.w    #$b,-(sp)           ;bconstat
          trap      #1
          addq.l    #2,sp
          tst.w     d0
          bpl       exit
          move.w    #1,-(sp)            ;conin
          trap      #1
          addq.l    #2,sp
          cmp.w     #13,d0              Return ?
          beq.s     vielec12
          move.l    d7,d0               +++ Backspace +++
          sub.l     bildbuff,d0
          cmp.l     #4,d0
          bls       exit
          addq.l    #4,sp
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
vielec12  lea       stralvie,a0         +++ Return +++
          moveq.l   #1,d0
          bsr       alertbox
          cmp.w     #2,d0
          beq       exit7               Mausclickende abwarten
          addq.l    #4,sp
vielec10  bsr       hide_m
          move.l    bildbuff,a0         Vieleck lîschen
          move.w    #2,36(a3)
          addq.l    #4,d7
          move.l    d7,a1
          tst.l     d3
          bmi.s     vieleck9
          move.l    d4,(a1)+
          addq.l    #4,d7
vieleck9  move.l    (a0),(a1)
          move.l    d7,d5               Nur 2 Ecken ?
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
          bsr       set_attr            Attribute setzen
          moveq.l   #9,d0
          move.w    chooset,d1          FÅllen ?
          bne.s     vieleck1
          move.l    frlinie+46,d0
          and.l     #$30003,d0
          btst      #16,d0
          bne.s     vielec11            Endlinie abrunden
          bset      #17,d0
vielec11  move.l    d0,(a6)
          vdi       108 0 2             ;Linienenden
          moveq.l   #6,d0
vieleck1  move.w    d0,(a5)             Polyline/Fill area
          lea       vdipb+8,a2
          move.l    bildbuff,(a2)
          move.l    d7,d0
          sub.l     bildbuff,d0
          lsr.w     #2,d0
          addq.w    #1,d0
          move.w    d0,2(a5)
          clr.w     6(a5)
          bsr       vdicall
          move.l    a4,(a2)
          bra       ret_attr
          ;
viele_dr  move.l    d7,a0               +++ Linien zeichnen +++
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
fuellen   bsr       new_1koo            *** FÅllen ***
          vdi       23 0 1 !frmuster+6  ;fill_style
          vdi       24 0 1 !frmuster+20 ;fill_index
          vdi       25 0 1 !frmuster+34 ;fill_color
          bsr       hide_m
          bsr       clip_on
          move.l    d3,(a4)
          move.w    frmuster+34,(a6)
          vdi       103 1 1             ;contour_fill
          vdi       23 0 1 1
          bra       return
          ;
quadrat   dc.w      $a000               *** Quadrat & Rechteck ***
          move.l    a0,a3
          move.w    #-1,32(a3)          Dummy
          move.l    d3,38(a3)
          move.w    d3,d7               D7: Y-Ursprung
          move.l    d3,d6               D6: X-Ursprung
          swap      d6
          clr.w     d4
quadrat1  bsr       noch_qu
          bsr       hide_m
          move.w    #$aaaa,34(a3)       Linienmuster
          tst.w     d4
          beq.s     quadrat5
          bsr       quadr_dr
quadrat5  move.b    maus_rec+1,d0
          beq.s     quadrat2
          move.w    d3,d5               D5: Y-neu
          move.l    d3,d4               D4: X-neu
          swap      d4
          cmp.b     #$28,choofig+1      Quadrat ?
          bne.s     quadra10
          move.w    d4,d0
          move.w    d5,d1
          sub.w     d6,d0
          bpl.s     quadra11
          not.w     d0
          addq.w    #1,d0
quadra11  sub.w     d7,d1
          bpl.s     quadra12
          not.w     d1
          addq.w    #1,d1
quadra12  cmp.w     d0,d1               Hîhe >= Breite ?
          bhs.s     quadra13
          cmp.w     d4,d6
          bhs.s     quadra14
          move.w    d6,d4
          add.w     d1,d4               nein -> Breite := Hîhe
          bra.s     quadra10
quadra14  move.w    d6,d4
          sub.w     d1,d4
          bra.s     quadra10
quadra13  cmp.w     d5,d7
          bhs.s     quadra15
          move.w    d7,d5
          add.w     d0,d5               ja -> Hîhe := Breite
          bra.s     quadra10
quadra15  move.w    d7,d5
          sub.w     d0,d5
quadra10  bsr       quadr_dr
          bsr       show_m
          bra       quadrat1
quadrat2  cmp.w     #$43,choofig        --- endgÅltiges Rechteck ---
          beq       markier
          tst.w     d4                  Maus unbewegt -> Abbruch
          beq       exit
          bsr       set_attr            Attribute setzen
          move.w    chooset+2,d0
          bne       quadrat7            -> runde Ecken
          move.w    chooset,10(a5)
          bne.s     quadrat6            -> FÅllen
          vdi       108 0 2 0 2
          vdi       6 5 0 !d6 !d7 !d4 !d7 !d4 !d5 !d6 !d5 !d6 !d7
          vdi       108 0 2 0 0
          bra.s     quadrat9
quadrat6  move.w    #1,10(a5)           ;bar
          bra.s     quadrat8
quadrat7  move.w    #8,10(a5)           ;rounded_rec
          move.w    chooset,d0
          beq.s     quadrat8
          move.w    #9,10(a5)           ;filled_rounded_rec
quadrat8  ;
          vdi       11 2 0 !d6 !d7 !d4 !d5
quadrat9  lea       last_koo,a0         Koordinaten merken
          move.w    d6,(a0)
          move.w    d7,2(a0)
          move.w    d4,4(a0)
          move.w    d5,6(a0)
          move.w    #-1,8(a0)
          bra       ret_attr
          ;
quadr_dr  move.w    #2,36(a3)           ++ Gummi-Viereck zeichnen ++
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
markier   move.b    mrk+ov,d0           *** Ausschnitt markieren ***
          beq.s     markier6
          move.w    mark_buf,d0
          beq.s     markier6
          move.b    mrk+chg,d0
          beq.s     markier6
          bsr       show_m
          bsr       over_que            "Auss einfÅgen" ?
          move.w    d0,d2
          bsr       hide_m
          cmp.w     #1,d2
          beq.s     markier6
          addq.l    #4,sp
          bra       exit3
markier6  lea       drawflag,a0         RÅckgÑngig disabeln
          clr.w     (a0)
          tst.w     d4
          bne.s     markier4
          lea       mark_buf,a2         --- Nur Rahmen lîschen ---
          clr.b     (a2)
          bsr       fram_del
          addq.l    #4,sp
          bra       exit6
markier4  cmp.w     d4,d6               --- Neuer Rahmen ---
          blo.s     markier1
          exg       d4,d6
markier1  cmp.w     d5,d7
          blo.s     markier2
          exg       d5,d7
markier2  add.w     win_xy+8,d5         Koordinaten absolut machen
          add.w     win_xy+8,d7
          add.w     win_xy+10,d4
          add.w     win_xy+10,d6
          lea       mark_buf,a0
          move.w    #-1,(a0)
          move.w    d6,2(a0)            X1Y1 & X2Y2 abspeichern
          move.w    d7,4(a0)
          move.w    d4,6(a0)
          move.w    d5,8(a0)
          lea       last_koo,a1         Koordinaten speichern
          move.l    2(a0),(a1)
          move.l    6(a0),4(a1)
          bsr       fram_drw
          move.l    menu_adr,a2
          bset.b    #3,1643(a2)
          move.b    mrk+ov,d0           Overlay-Mode ?
          beq.s     markier5
          bsr       over_beg
          bclr.b    #3,1667(a2)         "Wegwerfen" enabeln
          move.b    mrk+copy,d0
          bne.s     markier5
          bclr.b    #3,1643(a2)
markier5  lea       1739(a2),a0
          moveq.l   #7,d0               MenÅeintrÑge enabeln
markier3  bclr.b    #3,(a0)
          add.w     #24,a0
          dbra      d0,markier3
          lea       mrk,a0
          clr.b     einf(a0)            kein EinfÅgen
          clr.b     ovku(a0)
          clr.w     modi(a0)            unverknÅpft
          clr.b     chg(a0)             unbearbeitet
          clr.b     part(a0)            kein öberhang
          rts
          ;
kreis     bsr       clip_on             *** Kreis & Ellipse ***
          vdi       32 0 1 3            XOR
          vdi       15 0 1 7            Linientyp selbstdef.
          vdi       16 1 0 1 0          Liniendicke eins
          vdi       17 0 1 1            Linienfarbe schwarz
          vdi       113 0 1 $aaaa       Linienstil grau
          vdi       23 0 1 0            ungefÅllt
          move.w    d3,d5               D5: Y-Wert des Mittelpunkts
          move.l    d3,d4               D4: X-Wert
          swap      d4
          moveq.l   #-1,d6
          clr.w     d7
kreis1    bsr       noch_qu             ---- Schleife ----
          bsr       hide_m
          tst.w     d6
          bmi.s     kreis2
          bsr       kreis_k
kreis2    move.b    maus_rec+1,d0
          beq.s     kreis3
          move.w    d3,d7               D7: Y-Offset
          sub.w     d5,d7
          bpl.s     kreis4
          not.w     d7
          addq.w    #1,d7
kreis4    move.l    d3,d6               D6: X-Offset
          swap      d6
          sub.w     d4,d6
          bpl.s     kreis9
          not.w     d6
          addq.w    #1,d6
kreis9    cmp.b     #$2a,choofig+1      Kreis ?
          bne.s     kreis10
          cmp.w     d6,d7               ja -> grîûeren Radius nehmen
          bls.s     kreis10
          move.w    d7,d6
kreis10   bsr       kreis_k
          bsr       show_m
          bra       kreis1
kreis3    tst.w     d6                  ---- entgÅltiger Kreis ----
          bmi       exit
          bsr       set_attr
          move.l    frlinie+46,d0
          and.l     #$30003,d0
          move.l    d0,(a6)
          vdi       108 0 2             ;end_styles
          move.w    chooseg,d1
          move.w    chooseg+2,d2
          move.w    choofig,d3
          moveq.l   #2,d0
          add.w     chooset,d0          arc oder pie ?
          cmp.b     #3,d0
          bne.s     kreis6
          tst.w     d1
          bne.s     kreis6
          cmp.w     #3600,d2
          beq.s     kreis8              -> circle
kreis6    cmp.w     #$2b,d3
          beq.s     kreis12             -> Ellipsensegment
          move.w    d0,10(a5)
          vdi       11 4 2 !d4 !d5 0 0 0 0 !d6 0 !d1 !d2  ;arc/pie
          bra.s     kreis7
kreis8    cmp.w     #$2b,d3
          beq.s     kreis11             -> Ellipse
          move.w    #4,10(a5)
          vdi       11 3 0 !d4 !d5 0 0 !d6 0  ;filled_circle
          bra.s     kreis7
kreis11   moveq.l   #1,d0
kreis12   add.w     #4,d0
          move.w    d0,10(a5)
          vdi       11 2 2 !d4 !d5 !d6 !d7 !d1 !d2  ;ellipse/arc/pie
kreis7    lea       last_koo,a0
          move.w    d4,(a0)             Koordinaten merken
          move.w    d5,2(a0)
          add.w     d6,d4
          add.w     d7,d5
          move.w    d4,4(a0)
          move.w    d5,6(a0)
          move.w    #-1,8(a0)
          bra       ret_attr
          ;
kreis_k   move.l    chooseg,(a6)
          cmp.b     #$2b,choofig+1
          beq.s     kreis_e
          move.w    #2,10(a5)
          vdi       11 4 2 !d4 !d5 0 0 0 0 !d6 0  ;arc
          rts
kreis_e   move.w    #6,10(a5)
          vdi       11 4 2 !d4 !d5 !d6 !d7  ;elliptical_arc
          rts
          ;
text      bsr       new_1koo            *** Schrift ***
          move.l    rec_adr,a0
          bsr       save_buf
          lea       data_buf,a2
          move.l    d3,(a2)
          bsr       text_att            Attribute einstellen
          lea       stack,a3
text3     move.b    maus_rec+1,d0       Auf Click-Ende warten
          bne       text3
          clr.w     maus_rec
text1     bsr       show_m              +++ Schleife +++
text11    move.b    maus_rec,d0
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
          cmp.l     #$620000,d0         Help-Taste ?
          bne.s     text13
          moveq.l   #-1,d0
text13    cmp.l     #$610000,d0         UNDO-Taste ?
          bne.s     text14
          moveq.l   #-2,d0
text14    tst.b     d0                  kein ASCII-Zeichen ?
          beq       text1
          cmp.b     #13,d0              Return ?
          bne       text2
          move.w    6(a2),d1            -> Eine Zeile tiefer
          lea       win_xy,a0
          move.w    4(a2),d0
          bne.s     text12
          add.w     d1,2(a2)            0 Grad
          move.w    6(a0),d0
          cmp.w     2(a2),d0
          blo       text4
          bra.s     text17
text12    cmp.w     #1,d0               90 Grad
          bne.s     text18
          add.w     d1,(a2)
          move.w    4(a0),d0
          cmp.w     (a2),d0
          blo       text4
          bra.s     text17
text18    cmp.w     #2,d0               180 Grad
          bne.s     text19
          sub.w     d1,2(a2)
          move.w    2(a0),d0
          cmp.w     2(a2),d0
          bhi       text4
          bra.s     text17
text19    sub.w     d1,(a2)             270 Grad
          move.w    (a0),d0
          cmp.w     2(a2),d0
          bhi       text4
text17    move.l    win_xy,d0           Bild zwischenspeichern
          move.l    win_xy+4,d1
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     yx_off(a0),d2
          add.l     yx_off+2(a0),d2
          move.l    bild_adr(a0),a1
          move.l    logbase,a0
          bsr       copy_blk
          lea       stack,a3
          lea       data_buf,a2
          bra       text1
          ;
text2     move.w    d0,d2
          lea       stack,a0
          lea       vdipb+4,a1
          move.l    a0,(a1)
          cmp.l     a0,a3               min 1 Zeichen im Buffer ?
          beq       text7
          movem.l   d2/a2-a3,-(sp)      +++ Bild regenerieren +++
          move.l    a3,d0
          sub.l     a0,d0
          lsr.w     #1,d0
          vdi       116 0 !d0           ;inquire_text_extend
          move.l    data_buf,d0
          move.l    d0,d1
          move.w    data_buf+4,d3       Vertikal schreiben ?
          btst      #0,d3
          bne.s     text20
          sub.l     ptsout+12,d0        0+180 Grad
          add.l     ptsout+4,d1
          bra.s     text21
text20    cmp.b     #1,d3               90 Grad
          bne.s     text22
          sub.l     ptsout+4,d0
          bra.s     text21
text22    move.l    ptsout+12,d2        270 Grad
          swap      d2
          add.l     d2,d1
text21    sub.l     #$30003,d0
          add.l     #$30003,d1
          bsr       lim_win             auf Fenster begrenzen
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     yx_off(a0),d0
          add.w     yx_off(a0),d1
          add.l     yx_off+2(a0),d0
          add.l     yx_off+2(a0),d1
          move.l    bild_adr(a0),a0
          move.l    logbase,a1
          bsr       copy_blk
          movem.l   (sp)+,d2/a2-a3
          cmp.b     #8,d2               Backspace ?
          bne.s     text8
          subq.w    #2,a3               -> letztes Zeichen lîschen
          lea       stack,a0            noch eine Zeichen im Buffer ?
          cmp.l     a0,a3
          bne       text15+2            ja -> String neu ausgeben
          bra       text9
          ;
text7     cmp.b     #8,d2               kein Backspace
          beq       text9
text8     move.w    d2,d3               HELP- oder UNDO-Taste ?
          bpl       text15
          lea       vdipb+4,a0          +++ Formulare +++
          move.l    a6,(a0)
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
          move.l    win_xy,d0           Bild neu anzeigen
          move.l    win_xy+4,d1
          move.l    d0,d2
          add.w     yx_off(a4),d0
          add.w     yx_off(a4),d1
          add.l     yx_off+2(a4),d0
          add.l     yx_off+2(a4),d1
          move.l    bild_adr(a4),a0
          move.l    logbase,a1
          bsr       copy_blk
          movem.l   (sp)+,a2-a4/d2
          bsr       text_att
text6     move.b    maus_rec+1,d0
          bne       text6
          clr.w     maus_rec
          lea       vdipb+4,a0
          lea       stack,a1
          move.l    a1,(a0)
          cmp.w     #-1,d2              UNDO-Taste ?
          beq.s     text15+2
          move.w    frzeiche+6,d2
          ;
text15    move.w    d2,(a3)+            +++ neuen String ausgeben +++
          clr.w     (a3)
          lea       stack,a0
          move.l    a3,d0
          sub.l     a0,d0
          lsr.w     #1,d0
          move.l    (a2),(a4)
          vdi       8 1 !d0             ;text
text9     lea       vdipb+4,a0
          move.l    a6,(a0)
          bra       text1
          ;
text4     move.l    bildbuff,a0         +++ Ende +++
          move.l    rec_adr,a1
          move.l    bild_adr(a1),a1
          move.w    #1999,d0
text5     move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d0,text5
          bsr       hide_m
text_rat  ;
          vdi       39 0 2 0 0          +++ Attribute regenerieren +++
          vdi       13 0 1 0
          vdi       106 0 1 0
          vdi       22 0 1 1
          vdi       12 1 0 0 13
          bra       return
text_att  move.w    frtext+20,d0        +++ Attribute einstellen +++
          move.w    d0,d1
          mulu.w    #10,d0
          ext.l     d1
          add.w     #45,d1              Quadranten berechnen
          divu      #90,d1
          move.w    d1,4(a2)
          vdi       13 0 1 !d0          ;Winkel
          vdi       22 0 1 !frtext+34   ;Farbe
          vdi       106 0 1 !chootxt    ;Effekte
          vdi       12 1 0 0 !frtext+6  ;Grîûe
          move.w    ptsout+6,d0
          btst.b    #4,chootxt+1        Umrahmung ?
          beq.s     text_at1
          addq.w    #2,d0
text_at1  move.w    d0,6(a2)            Zeilenhîhe
          vdi       39 0 2 0 3          ;Ausrichtung
          bsr       set_wrmo
          bra       clip_on
          ;
schub     move.b    mrk+modi,d7         *** Ausschnitt verschieben ***
          bsr       over_old
          lea       mrk,a2
          move.b    d7,modi(a2)
          move.l    copy(a2),d2
          bsr       save_scr
          move.l    d2,copy(a2)
          tst.b     del(a2)             alten Auss lîschen ?
          beq.s     schub1
          clr.b     del(a2)
          clr.w     d3
          move.l    bildbuff,a0
          move.l    drawflag+4,d0
          move.l    drawflag+8,d1
          bsr       work_bl2
schub1    lea       stack,a3            + Parameter setzen +
          move.l    mark_buf+2,d0
          move.l    mark_buf+6,d1
          lea       drawflag+4,a1
          move.l    d0,(a1)+            alte Rahmenkoo merken
          move.l    d1,(a1)
          move.l    d0,d2
          move.l    d1,d3
          move.b    mrk+part,d4         öberhang wiederherstellen ?
          bpl.s     schub7
          move.b    mrk+ov,d4
          beq.s     schub7
          move.l    mrk+old,d2
          move.l    mrk+old+4,d3
          sub.w     mrk+old+10,d0
          swap      d0
          sub.w     mrk+old+8,d0
          swap      d0
schub7    move.l    d2,24(a3)           24: Quellrasterkoo
          move.l    d3,28(a3)
          sub.l     d2,d3
          move.l    d3,8(a3)            8: Rahmenbreite
          move.l    rec_adr,a0
          sub.w     yx_off(a0),d0
          sub.l     yx_off+2(a0),d0
          sub.w     yx_off(a0),d1
          sub.l     yx_off+2(a0),d1
          move.l    maus_rec+16,(a3)    0: letzte Mauspos
          move.l    d0,4(a3)            4: akt Ausspos
          bsr       lim_win
          lea       mark_buf+2,a1       akt Rahmen(rel)
          move.l    d0,(a1)+
          move.l    d1,(a1)
          clr.b     12(a3)              12: Rahmen gelîscht?
          move.b    mrk+ov,d0
          beq.s     schub9
          move.b    mrk+part,d0         + OV-Mode +
          bmi.s     schub5
          bsr       save_buf
schub5    move.l    mrk+buff,16(a3)     16: Hintergrund-Quelle
          move.l    bildbuff,20(a3)     20: Raster-Quelle
          bra.s     schub4
schub9    move.l    bildbuff,16(a3)     + NORM-Mode +
          move.l    bild_adr(a4),20(a3)
          move.b    mrk+ovku,d0         Kurz-Overlay-Modus ?
          bne.s     schub4              -> alten Hintergrund lassen
          bsr       save_buf
          move.b    mrk+copy,d0         Kopier-Modus ?
          bne.s     schub4
          clr.w     d3
          move.l    bildbuff,a0
          move.l    drawflag+4,d0
          move.l    drawflag+8,d1
          bsr       work_bl2
schub4    move.b    mrk+vmod,d0         + neue KnÅpfart ? +
          cmp.b     mrk+modi,d0
          beq.s     schub2
          move.l    stack,d3            -> sofort neuzeichnen
          bsr       hide_m
          bra.s     schub8
schub2    lea       stack,a3            +++ Schleife +++
          move.l    (a3),d3
          bsr       noch_qu
          bsr       hide_m
          move.b    maus_rec+1,d0       fertig ?
          beq.s     schub3
schub8    move.l    d3,-(sp)            ++ Regenerieren ++
          spl.b     12(a3)
          move.l    mark_buf+2,d0
          move.l    mark_buf+6,d1
          move.l    d0,d2
          move.l    rec_adr,a0
          add.w     yx_off(a0),d0
          add.w     yx_off(a0),d1
          add.l     yx_off+2(a0),d0
          add.l     yx_off+2(a0),d1
          move.l    stack+16,a0
          move.l    logbase,a1
          bsr       copy_blk
          move.l    (sp)+,d3
          move.l    d3,d4               ++ Neuzeichnen ++
          lea       stack,a3
          sub.w     2(a3),d3
          add.w     d3,6(a3)
          swap      d3
          sub.w     (a3),d3             alte Pos + Maus-Offset =
          add.w     d3,4(a3)            4: neue Auss-Pos(lo-Ecke)
          move.l    d4,(a3)             0: neue Maus-Pos
          move.l    logbase,a1
          bsr       fram_ins            Auss einsetzen
          bsr       show_m
          bra       schub2
schub3    move.l    rec_adr,a2          +++ Ende +++
          move.b    mrk+ov,d0
          bne.s     schub20
          lea       mark_buf+2,a0       + NORM-Mode +
          move.w    yx_off(a2),d0
          move.w    yx_off+2(a2),d1
          add.w     d1,(a0)+
          add.w     d0,(a0)+
          add.w     d1,(a0)+
          add.w     d0,(a0)
          clr.b     mrk+part
          bra       schub21
schub20   move.w    #1999,d3            + OV-Mode +
          move.l    mrk+buff,a0
          move.l    bild_adr(a2),a1
schub26   move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d3,schub26
          lea       win_xy,a0
          clr.l     (a0)+
          move.l    #$27f018f,(a0)+
          lea       stack+4,a1
          move.w    (a0)+,d0
          move.w    (a0),d1
          add.w     d1,(a1)+
          add.w     d0,(a1)
          move.l    bild_adr(a2),a1
          bsr       fram_ins
          move.l    mark_buf+6,d0       Auss Åber Bildrand ?
          sub.l     mark_buf+2,d0
          move.l    stack+28,d1
          sub.l     stack+24,d1
          lea       mrk,a0
          move.l    menu_adr,a1
          cmp.l     d0,d1
          beq.s     schub22
          sne.b     part(a0)
          bclr.b    #3,1691(a1)         "öbernehmen" enabeln
          move.l    stack+24,old(a0)
          move.l    stack+28,old+4(a0)
          move.l    mark_buf+2,old+8(a0)
          move.w    stack+4,d0
          sub.w     d0,old+8(a0)
          move.w    stack+6,d0
          sub.w     d0,old+10(a0)
          bra.s     schub21
schub22   bset.b    #3,1691(a1)
          move.l    stack+24,old(a0)
          bclr.b    #7,part(a0)
          bne.s     schub21
          clr.b     part(a0)
schub21   lea       mrk,a0              + Flags setzen +
          clr.w     einf(a0)            EinfÅgen beendet
          move.b    stack+12,d0
          beq       exit6
          lea       drawflag,a1         RÅckgÑngig enabeln
          move.w    #-1,(a1)
          tst.b     ov(a0)
          beq       exit_beg
          move.b    vmod(a0),modi(a0)   V-Modus merken
          beq       exit3
          move.l    menu_adr,a0
          bclr.b    #3,1691(a0)         "öbernehmen" enabeln
          bra       exit3
*------------------------------------------------------GEM-SUBROUTINEN
          ;
set_attr  clr.w     d0                  ** Attribute setzen **
          move.w    chooset,d1
          beq.s     set_att1+4           Åberhaupt FÅllen ?
          vdi       24 0 1 !frmuster+20  ;FÅll-Nr.
          vdi       25 0 1 !frmuster+34  ;FÅllfarbe
set_att1  move.w    frmuster+6,d0
          vdi       23 0 1 !d0           ;FÅllstil
          vdi       104 0 1 !chooset+4   ;Rahmen ein/aus
set_att2  ;
          vdi       15 0 1 !frlinie+34   ;Linienstil
          vdi       16 1 0 !frlinie+20 0 ;Liniendicke
          vdi       17 0 1 !frlinie+6    ;Linienfarbe
          vdi       113 0 1 !choopat     ;Liniendef
          bsr.s     clip_on
          ;
set_wrmo  clr.w     d0                  ** Aktuellen Modus setzen **
          move.b    frmodus+5,d0
          addq.b    #1,d0
          vdi       32 0 1 !d0          ;set_writing_modus
          rts
          ;
clip_on   move.l    win_xy,(a4)         ** Clip-Rec setzen **
          move.l    win_xy+4,4(a4)
          move.w    #1,(a6)
          vdi       129 2 1
          rts
ret_attr  ;                             ** GEM-Attr. regenerieren **
          vdi       108 0 2 0 0
ret_att2  ;
          vdi       15 0 1 1
          vdi       16 1 0 1 0
          vdi       17 0 1 1
          vdi       23 0 1 1
return    ;
          vdi       129 0 1 0           ;clip_rec lîschen
          vdi       32 0 1 3            ;set_writing_mode XOR
          rts
*----------------------------------------------------------SUBROUTINEN
noch_qu   lea       win_xy,a0           ** Maus abfragen **
noch_qu5  move.b    maus_rec+1,d0
          beq       exit
          move.l    maus_rec+12,d0
corr_adr  bsr       raster
          swap      d0                  Pos im Fenster ?
          cmp.w     (a0),d0
          bhs.s     noch_qu1
          move.w    (a0),d0             nein -> Korrektur
          bra.s     noch_qu2
noch_qu1  cmp.w     4(a0),d0
          bls.s     noch_qu2
          move.w    4(a0),d0
noch_qu2  swap      d0
          cmp.w     2(a0),d0
          bhs.s     noch_qu3
          move.w    2(a0),d0
          bra.s     noch_qu4
noch_qu3  cmp.w     6(a0),d0
          bls.s     noch_qu4
          move.w    6(a0),d0
noch_qu4  cmp.l     d0,d3
          beq       noch_qu5
          move.l    d0,d3
          tst.w     chookoo
          beq       exit
          movem.l   a1/d1-d2,-(sp)
          bsr       koos_out            Koo anzeigen, falls gew.
          movem.l   (sp)+,a1/d1-d2
          rts
          ;
noch_in   cmp.w     (a0),d0             ** Pos. im Ausschnitt ? **
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
win_abs   move.l    rec_adr,a0          ** Fenster begrenzen **
          move.l    fenster(a0),d0
          move.l    fenster+4(a0),d1
          lea       win_xy,a0
          move.l    d0,(a0)
          add.l     d1,d0
          sub.l     #$10001,d0
          move.l    d0,4(a0)
          cmp.w     #400,6(a0)
          blo.s     win_abs1
          move.w    #399,6(a0)
win_abs1  cmp.w     #640,4(a0)
          blo       exit
          move.w    #639,4(a0)
          rts
          ;
lim_win   lea       win_xy,a0           ** Auf Fenster beschrÑnken **
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
new_1koo  lea       last_koo,a0         ** Mausposition merken **
          move.l    4(a0),(a0)
          move.l    d3,4(a0)
          addq.w    #1,8(a0)
          bpl       exit
          move.w    #-1,8(a0)
          rts
new_2koo  lea       last_koo,a0
          move.l    d0,(a0)
          move.l    d1,4(a0)
          move.w    #-1,8(a0)
          rts
          ;
save_buf  move.l    rec_adr,a1          ** Bild in Buffer sichern **
          move.l    bild_adr(a1),a1
          move.l    bildbuff,a2
          move.l    #1999,d0
save_bu1  move.l    (a1)+,(a2)+
          move.l    (a1)+,(a2)+
          move.l    (a1)+,(a2)+
          move.l    (a1)+,(a2)+
          dbra      d0,save_bu1
          rts
          ;
fram_ins  lea       stack+4,a3       ** Rahmen einfÅgen **
          move.l    (a3),d0
          move.l    d0,d1
          add.w     6(a3),d1
          swap      d1
          add.w     4(a3),d1
          swap      d1
          bsr       lim_win
          move.l    d0,d2
          lea       mark_buf+2,a0       neue Rahmenkoo merken
          move.l    d0,(a0)+
          move.l    d1,(a0)
          sub.w     2(a3),d0            Ausschnittquelle errechnen
          sub.w     2(a3),d1
          swap      d0
          swap      d1
          sub.w     (a3),d0
          sub.w     (a3),d1
          swap      d0
          swap      d1
          add.l     20(a3),d0
          add.l     20(a3),d1
          move.b    mrk+vmod,d3         nur Verschieben ?
          bne.s     fram_in1
          move.l    stack+20,a0      1:1-öbertragung
          bra       copy_blk
fram_in1  clr.w     d3                  VerknÅpfung
          move.b    mrk+vmod,d3
          lea       mfdb_q,a0
          move.l    stack+20,(a0)
          move.l    a1,20(a0)
          move.w    d3,(a6)             Modus
          move.l    d1,d3
          sub.l     d0,d3
          move.l    d3,4(a0)
          move.l    d3,24(a0)
          move.l    a0,14(a5)
          add.w     #20,a0
          move.l    a0,18(a5)
          lea       ptsin,a0
          move.l    d0,(a0)+
          move.l    d1,(a0)+
          move.l    d2,(a0)+
          add.l     d3,d2
          move.l    d2,(a0)
          vdi       109 4 1             ;copy_raster
          rts
          ;
fram_drw  lea       mark_buf,a0         ** Ausschnitt umrahmen **
          tst.w     (a0)
          beq       exit
          move.l    rec_adr,a1
          move.w    2(a0),d4            x1y1-x2y2: Rahmenkoordinaten
          move.w    4(a0),d5
          move.w    6(a0),d6
          move.w    8(a0),d7
          sub.w     yx_off(a1),d5
          sub.w     yx_off(a1),d7
          bmi       exit
          sub.w     yx_off+2(a1),d4
          sub.w     yx_off+2(a1),d6
          bmi       exit
          move.l    fenster(a1),d0      Fenstergrenzen
          move.l    fenster+4(a1),d1
          add.l     d0,d1
          sub.l     #$10001,d1
          cmp.w     #400,d0             Bildschirmgrenzen
          bhs       exit
          cmp.w     #400,d1
          blo.s     fram_d14
          move.w    #399,d1
fram_d14  swap      d0
          cmp.w     #640,d0
          bhs       exit
          swap      d0
          swap      d1
          cmp.w     #640,d1
          blo.s     fram_d16
          move.w    #639,d1
fram_d16  swap      d1
          moveq.l   #15,d3              D3: Rahmen-Kontrollflags
          cmp.w     d0,d5               Rahmen eingrenzen
          bge.s     fram_dr2            (D5 kann auch <0 sein !)
          move.w    d0,d5
          bclr      #1,d3               1: oben
fram_dr2  cmp.w     d1,d7
          bls.s     fram_dr3
          move.w    d1,d7
          bclr      #3,d3               3: unten
fram_dr3  swap      d0
          swap      d1
          cmp.w     d0,d4
          bge.s     fram_dr4
          move.w    d0,d4
          bclr      #0,d3               0: links
fram_dr4  cmp.w     d1,d6
          bls.s     fram_dr5
          move.w    d1,d6
          bclr      #2,d3               2: rechts
fram_dr5  cmp.w     d5,d7               Ausschnitt auûerhalb Fenster ?
          blo.s     fram_d10
          cmp.w     d4,d6
          bhs.s     fram_d12
fram_d10  clr.w     d3
fram_d12  tst.w     d3                  Rahmen sichtbar ?
          beq       exit                nein -> Abbruch
          bsr       hide_m
          dc.w      $a000               Line-A initialisieren
          move.l    a0,a3
          move.w    #-1,32(a3)
          move.w    #1,24(a3)
          move.w    #2,36(a3)
          move.w    d4,38(a3)           sichtbare Rahmenteile zeichnen
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
          cmp.w     d5,d7               Hîhe = 1 ?
          bne.s     fram_d17
          move.w    #$cccc,d7
          bra.s     fram_d18
fram_d17  move.w    #$cccc,d7
fram_d18  sub.w     mark_buf+4,d5
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
koos_mak  move.w    chookoo,d0          ** Mausposition anzeigen **
          beq       exit
          move.l    rec_adr,a1          Fenster offen ?
          move.w    (a1),d0
          bmi       koos_ou2
          lea       koo_buff,a0         Im Fenster ?
          move.l    fenster(a1),d1
          move.l    d1,d2
          add.l     fenster+4(a1),d2
          sub.l     #$10001,d2
          move.l    d1,(a0)
          move.l    d2,4(a0)
          move.w    maus_rec+12,d0
          move.w    maus_rec+14,d1
          bsr       noch_in
          bne.s     koos_ou2
          move.l    yx_off(a1),win_xy+8
          swap      d0
          move.w    d1,d0
          bsr.s     raster              Rastern
          lea       chookoo+2,a0
          cmp.l     (a0),d0             Koos verÑndert ?
          beq       exit
          move.l    d0,(a0)
koos_out  move.l    rec_adr,a1          ++ Koos in String einbauen ++
          move.w    d0,d1
          add.w     yx_off(a1),d1
          lea       koostr+11,a0
          bsr.s     koos_ou1
          move.l    d0,d1
          swap      d1
          add.w     yx_off+2(a1),d1
          subq.l    #1,a0
          bsr.s     koos_ou1
          pea       koostr
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          rts
koos_ou1  ext.l     d1                  ++ Zahl in String wandeln ++
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
koos_ou2  lea       chookoo+2,a0        ++ Zeiger nicht im Fenster ++
          move.l    (a0),d0
          bmi       exit
          move.l    #-1,(a0)
          pea       koostr2
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          rts
          ;
raster    tst.w     chooras             ** XY-Koordinaten rastern **
          beq       exit
          movem.l   d2-d4,-(sp)
          swap      d0
          move.w    d0,d3               X-Koordinate
          move.w    frraster+6,d2
          move.w    d2,d4
          lsr.w     #1,d4
          add.w     win_xy+10,d3
          bmi.s     raster1
          sub.w     frraster+34,d3
          ext.l     d3
          divu      d2,d3
          swap      d3
          sub.w     d3,d0
          cmp.w     d4,d3
          bls.s     raster1
          add.w     d2,d0
raster1   swap      d0                  Y-Koordinate
          move.w    d0,d3
          move.w    frraster+20,d2
          move.w    d2,d4
          lsr.w     #1,d4
          add.w     win_xy+8,d3
          bmi.s     raster2
          sub.w     frraster+48,d3
          ext.l     d3
          divu      d2,d3
          swap      d3
          sub.w     d3,d0
          cmp.w     d4,d3
          bls.s     raster2
          add.w     d2,d0
raster2   movem.l   (sp)+,d2-d4
          rts
*-----------------------------------------------------------------DATA
win_xy    ds.w   7
mark_buf  ds.w   5
data_buf  ds.w   4
koostr    dc.b   27,'Y h###/###',0
koostr2   dc.b   27,'Y h---/---',0
koo_buff  ds.w   4
last_koo  dcb.l  2,0
mfdb_q    dc.w   0000,0000,00,00,40,0,1,0,0,0
          dc.w   0000,0000,00,00,40,0,1,0,0,0
stralvie  dc.b   91,51,93,91,'Vieleck komplett ?',93,91,'Ok|Weite'
          dc.b   $72,93,0,0
stralmax  dc.b   91,51,93,91,'Maximal 128 Ecken !!',93,91,'Abbruc'
          dc.b   $68,93,0,0
stralove  dc.b   91,49,93,91,'Sie  wollen den  Ausschnitt an|diese '
          dc.b   ' Stelle kopieren ?  Dann|geht dort der Hintergrun'
          dc.b   'd ver-|loren !',93,91,'Ok|Abbruch',93,0,0
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
*         movem.l   d0-d3/a0-a3,-(sp)
*         move.l    d0,d0
*         bsr       hexaus
*         move.l    d1,d0
*         bsr       hexaus
*         move.l    d2,d0
*         bsr       hexaus
*         move.l    d3,d0
*         bsr       hexaus
*         move.l    d4,d0
*         bsr       hexaus
*         move.l    d5,d0
*         bsr       hexaus
*         move.l    d6,d0
*         bsr       hexaus
*         move.l    d7,d0
*         bsr       hexaus
*         move.w    #1,-(sp)
*         trap      #1
*         addq.l    #2,sp
*         tst.w     d0
*         beq.s     traprts
*         movem.l   (sp)+,d0-d3/a0-a3
          rts
*traprts   movem.l   (sp)+,d0-d3/a0-a3
*         addq.l    #4,sp
*         rts
**********************************************************************
          ;
aescall   move.l    #aespb,d1
          move.l    #$c8,d0
          trap      #2
          rts
vdicall   move.w    grhandle,12(a5)
          move.l    #vdipb,d1
          moveq.l   #$73,d0
          trap      #2
          rts
grhandle  ds.w   1
appl_id   ds.w   1
aespb     dc.l   contrl,global,intin,intout,addrin,addrout
vdipb     dc.l   contrl,intin,ptsin,intout,ptsout
contrl    ds.w   11
global    ds.w   20
intin     ds.w   20
ptsin     ds.w   10
intout    ds.w   50
ptsout    ds.w   20
addrin    ds.l   3
addrout   ds.l   3
stack     dc.w   0
          END
