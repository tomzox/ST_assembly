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
 module    MENU_2
 section   drei
 pagelen   32767
 pagewid   133
 noexpand
 ;
 XREF  aescall,vdicall,contrl,intin,intout,ptsin,ptsout,addrin
 XREF  addrout,msg_buff,bildbuff,rec_adr,maus_rec,mark_buf,drawflag
 XREF  show_m,hide_m,save_scr,win_rdw,rsrc_gad,set_xx,drei_chg
 XREF  save_buf,win_abs,choofig,copy_blk,win_xy,koos_mak,alertbox
 XREF  rand_tab,logbase,get_koos,over_que,fram_del,fuenf_4c
 ;
 XDEF  chootxt,chooras,choopat,menu_adr,frraster,frinfobo,frsegmen
 XDEF  frkoordi,frmodus,frpunkt,frpinsel,frsprayd,frmuster,frtext
 XDEF  frradier,frlinie,frdrucke,frdatei,nr_vier,men_inv,check_xx
 XDEF  work_blk,form_do,form_del,form_buf,form_wrt,mrk,frzeiche
 XDEF  chookoo,work_bl2,init_ted,koanztab,maus_neu,over_beg,over_old
 XDEF  maus_bne,cent_koo,over_cut,frrotier,frzerren,frzoomen,frprojek
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
          ifnum     [sptsin] = 0 goto vdi2
          ifnum     [parnum] >= [.nparms] goto vdi3
          moove     w,[.parm([parnum])],ptsin+([parnum]-4)*2
          moove     w,[.parm([parnum]+1)],ptsin+([parnum]-3)*2
parnum    setnum    [parnum]+2
sptsin    setnum    [sptsin]-1
          goto      vdi1
vdi2      maclab
          ifnum     [sintin] = 0 goto vdi3
          ifnum     [parnum] > [.nparms] goto vdi3
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
yx_off    equ  16   Abstand Fensterursprung zu 0/0
          ;        *** Offsets zu Formular-Rec.s ***
ted_nr    equ  0    Nr. der TEDINFO-Struktur
ted_len   equ  2    LÑnge des Strings -1
ted_val   equ  4    akt., gÅltiger Wert
ted_min   equ  6    Minimum
ted_inx   equ  7    Index im Objektbaum
ted_max   equ  8    Maximum
ted_adr   equ  10   Adresse der TEDINFO-Struktur
          ;        *** Offsets zu markflags ***
copy      equ  0    Kopieren?
vmod      equ  1    akt. VerknÅpf-mode
einf      equ  2    Auss im Buff(Adr. drawflag+12)?
ovku      equ  3    OV-Kurz-Mode?
del       equ  5    alten Auss lîschen vor schub?
ov        equ  6    OV-Mode?
buff      equ  8    Adr. OV-Buffer
chg       equ  12   bearbeitet?
part      equ  13   öberhang?
modi      equ  14   VerknÅpfungsmodi akt/letzter Auss
old       equ  16   öberhang->alte Koo/Offset
*---------------------------------------------------------MENU-HANDLER
nr_vier   cmp.l     #$70000,d0
          bhs       nr_fuenf
          cmp.b     #$41,d0             *** Attribute-MenÅ ***
          blo.s     vier_3f
          lea       choomou,a2          --- Mausform wÑhlen ---
          not.b     1(a2)
          bsr       maus_neu
          move.l    menu_adr,a1
          add.w     #1572,a1
          tst.w     (a2)
          beq.s     mausel1
          move.l    (a1),2(a2)          ++ Kreuz-Maus ++
          addq.l    #6,a2
          move.l    a2,(a1)
          bra       men_inv
mausel1   move.l    2(a2),(a1)          ++ Pfeil-Maus ++
          bra       men_inv
          ;
vier_3f   cmp.b     #$3f,d0
          bne.s     vier_33
          moveq.l   #1,d0               --- Fenster-Attribute ---
          lea       stralfat,a0
          bsr       alertbox
          bra       men_inv
          ;
vier_33   sub.b     #47,d0              --- Einstellungen ---
          cmp.b     #6,d0
          blo.s     attrib11
          sub.b     #1,d0
          cmp.b     #13,d0
          blo.s     attrib11
          sub.b     #1,d0
attrib11  move.w    d0,d2
          sub.b     #4,d0
          lsl.w     #1,d0
          lea       fr_tab,a0
          lea       frmodus,a2
          add.w     (a0,d0.w),a2
          bsr       form_do             Formular aufrufen
attrib13  cmp.w     (a2),d4             Touchexit geclickt ?
          bhs       attrib12
          cmp.w     #13,2(a2)           Muster-Formular ?
          bne       attrib20
          cmp.b     #5,d4
          beq       attrib14            -> nur Demobox neu zeichnen
          move.w    6(a2),d0
          move.w    20(a2),d1
          cmp.b     #3,d4
          bne.s     attrib18
          cmp.b     #2,d0               -- Muster erniedrigen --
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
attrib18  cmp.b     #6,d4               -- Muster erhîhen --
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
attrib16  move.w    d0,6(a2)            Formular erneuern
          move.w    d1,20(a2)
          addq.l    #2,a2
          moveq.l   #1,d2
attrib17  move.w    ted_val(a2),d0
          bsr       form_wrt
          clr.w     d0
          clr.w     d1
          move.b    ted_inx(a2),d0
          bsr       obj_draw
          add.w     #14,a2
          dbra      d2,attrib17
          lea       frmuster,a2
attrib14  bsr       form_mus            ZurÅck ins Formular
          bra       attrib23
attrib30  cmp.b     #4,d4
          bne.s     attrib34
          moveq.l   #4,d0               -- Muster definieren --
          bsr       obj_off
          move.w    maus_rec+12,d0
          sub.w     intout+2,d0
          move.w    maus_rec+14,d1      D0/1: XY-Offset
          sub.w     intout+4,d1
          lsr.w     #3,d0               Bitpos
          lsr.w     #3,d1
          move.w    d1,d2
          add.w     d2,d2
          moveq.l   #15,d3
          sub.w     d0,d3
          bclr      #3,d3
          bne.s     attrib33
          addq.w    #1,d2
attrib33  lea       choofil,a0          im Muster umschalten
          bchg      d3,(a0,d2.w)
          bsr       hide_m
          move.l    maus_rec+12,d0
          sub.l     intout+2,d0
          and.l     #$780078,d0
          add.l     intout+2,d0
          move.l    d0,d1
          add.l     #$70007,d1
          moveq.l   #10,d3
          move.l    logbase,a0          in Def-Box umschalten
          bsr       work_bl2
          bsr       show_m
          bsr       form_mus
          bra.s     attrib23
attrib34  moveq.l   #4,d0               -- Def-Box lîschen --
          bsr       obj_off
          move.l    intout+2,d0
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
attrib20  cmp.w     #20,2(a2)           -- Linie --
          bne.s     attrib12
          cmp.b     #4,d4
          beq.s     attrib21
          cmp.b     #7,d4
          bne.s     attrib21
          moveq.l   #7,d0               Linienmusterdefinition
          bsr       obj_off
          move.w    maus_rec+12,d0
          sub.w     intout+2,d0
          lsr.w     #3,d0
          move.l    180(a3),a0
          eor.b     #%1101,(a0,d0.w)
          move.w    choopat,d1
          eor.b     #15,d0
          bchg      d0,d1
          move.w    d1,choopat
          moveq.l   #6,d0
          moveq.l   #1,d1
          bsr       obj_draw
attrib21  bsr       form_lin            Linien-Demo
attrib23  moveq.l   #-1,d1              Auf Click-Ende warten
          move.l    a0,a0
          move.l    a0,a0
          move.b    maus_rec+1,d0
          dbeq      d1,attrib23+2
          clr.w     maus_rec
          pea       attrib13
          bra       form_do2            ZurÅck ins Formular
          ;
attrib12  bsr       form_del
          bra       men_inv
          ;
nr_fuenf  cmp.l     #$80000,d0          *** Ausschnitt-MenÅ ***
          bhs       nr_sechs
          cmp.b     #$43,d0
          bne.s     fuenf_48
          move.w    d0,d2               --- Markieren ein/aus ---
          bra       drei_chg
          ;
fuenf_48  cmp.b     #$48,d0
          blo.s     fuenf_52
          cmp.b     #$4a,d0
          bhi.s     fuenf_52
          move.w    mark_buf,d1         --- Lîsch./SchwÑrz./Neg. ---
          beq       men_inv
          bsr       over_cut
          sub.b     #$48,d0
          lsl.w     #1,d0
          lea       work_dat,a0
          move.w    (a0,d0.w),d3
          cmp.b     #10,d3              Negieren ?
          bne.s     white1
          bsr       over_old            -> VerknÅpfung aufheben
white1    bsr       save_scr
          bsr       save_buf
          move.l    bild_adr(a4),a0
          bsr       work_blk            Ausschnitt bearbeiten
          move.w    #$ff00,drawflag
          move.l    menu_adr,a0
          bclr.b    #3,491(a0)
          bsr       men_inv
          bra       win_rdw
          ;
fuenf_52  cmp.b     #$52,d0
          bne.s     fuenf_51
          lea       frverknu,a2         --- VerknÅpfen ---
          moveq.l   #14,d2
          bsr       form_do
          bsr       form_del
          cmp.w     #17,d4
          beq       men_inv
          move.b    frverknu+5,d1
          lea       mrk,a0
          lea       comb_dat,a1
          ext.w     d1
          move.b    (a1,d1.w),vmod(a0)
          beq.s     knupf1
          moveq.l   #1,d1
knupf1    moveq.l   #$52,d0
          bsr       check_xx
          bra       men_inv
          ;
fuenf_51  cmp.b     #$51,d0
          bne.s     fuenf_53
          lea       mrk,a0              --- Kopieren ---
          not.b     copy(a0)
          move.b    copy(a0),d1
          and.w     #1,d1
          bsr       check_xx
          bra       men_inv
          ;
fuenf_53  cmp.b     #$53,d0
          bne       fuenf_44
          move.b    mrk+ov,d0           --- Overlay-Modus ---
          beq.s     overlay1
          bsr       over_que            ++ Ende ++
          bne       men_inv
          move.l    mrk+buff,-(sp)
          move.w    #$49,-(sp)
          trap      #1                  mfree
          addq.l    #6,sp
          tst.l     d0
          bne       men_inv
          lea       mrk,a0
          clr.b     ov(a0)
          move.l    #-1,buff(a0)
          move.l    menu_adr,a0
          bset.b    #3,1643(a0)         Einf+Wegw+öbern.disabeln
          bset.b    #3,1667(a0)
          bset.b    #3,1691(a0)
          bra.s     overlay2
overlay1  move.l    #32010,-(sp)        ++ Setzen ++
          move.w    #$48,-(sp)
          trap      #1
          addq.l    #6,sp
          tst.l     d0
          bmi.s     overlay3
          lea       mrk,a2
          move.w    #$ff00,ov(a2)
          move.l    d0,buff(a2)
          move.w    mark_buf,d0         Ausschnitt vorhanden ?
          beq.s     overlay2
          bsr       over_beg
          move.l    menu_adr,a0         "Wegw" enabeln
          bclr.b    #3,1667(a0)
overlay2  moveq.l   #$53,d0             MenÅeintrag ab-/enthaken
          move.b    mrk+ov,d1
          ext.w     d1
          bsr       check_xx
          bra       men_inv
overlay3  moveq.l   #1,d0               Abbruch wg Speichermangel
          lea       stralovn,a0
          bsr       alertbox
          bra       men_inv
          ;
fuenf_44  cmp.b     #$44,d0
          bne       fuenf_45
          move.w    mark_buf,d0         --- EinfÅgen ---
          bne       einfug5
          move.b    mrk+einf,d0
          beq       men_inv
          bsr       save_scr
          bsr       save_buf
          move.b    mrk+ov,d0           Overlay-Mode ?
          beq.s     einfug2
          lea       mrk,a2
          move.b    copy(a2),d2
          move.b    #-1,copy(a2)
          bsr       over_beg
          move.b    d2,copy(a2)
einfug2   bsr       win_abs             Fensterkoo berechnen
          move.l    (a0),d0
          sub.l     d0,4(a0)
          move.l    drawflag+8,d2
          sub.l     drawflag+4,d2
          lea       win_xy+6,a2
          lea       yx_off(a4),a3
          bsr       cent_koo            Rahmen im Fenster zentrieren
          lea       mark_buf,a0         Rahmen-Record erzeugen
          move.w    #-1,(a0)+
          move.l    d0,(a0)+
          move.l    d1,(a0)
          move.l    d0,d2
          move.l    drawflag+4,d0       Auss. in akt. Bild einkopieren
          move.l    drawflag+8,d1
          move.l    drawflag+12,a0
          move.l    bild_adr(a4),a1
          cmp.l     a0,a1
          bne.s     einfug3
          move.l    bildbuff,a0
einfug3   bsr       copy_blk
          move.w    #$43,d2             Markieren abhaken
          bsr       drei_chg
          lea       drawflag,a0         RÅckgÑngig enabeln
          move.l    #$ffff0000,(a0)+
          move.l    #-1,(a0)+
          move.l    #-1,(a0)
          move.l    menu_adr,a0         MenÅeintrÑge dis-/enabeln
          bclr.b    #3,491(a0)
          bset.b    #3,1643(a0)
          lea       mrk,a1
          tst.b     ov(a1)
          beq.s     einfug4
          bclr.b    #3,1667(a0)
          clr.b     chg(a1)
          clr.b     part(a1)
          clr.w     modi(a1)
einfug4   add.w     #1739,a0
          moveq.l   #7,d0
einfug1   bclr.b    #3,(a0)
          add.w     #24,a0
          dbra      d0,einfug1
          move.w    #$ff,mrk+einf       EinfÅg-Modus fÅr >schub<
          bra       win_rdw
einfug5   lea       mrk,a2              ++ OV-Mode-II ++
          tst.b     ov(a2)
          beq       men_inv
          bsr       over_que
          bne       men_inv
          move.b    modi(a2),chg(a2)
          move.b    copy(a2),d3
          move.b    #-1,copy(a2)
          bsr       over_beg            Auss in Hintergrund einfÅgen
          move.b    d3,copy(a2)
          lea       drawflag,a0
          clr.w     (a0)
          move.l    menu_adr,a0
          bset.b    #3,491(a0)
          bset.b    #3,1643(a0)
          bra       men_inv
          ;
fuenf_45  cmp.b     #$45,d0
          bne.s     fuenf_46
          move.w    mark_buf,d0         --- Wegwerfen ---
          beq       men_inv
          move.b    mrk+ov,d0
          beq       men_inv
          bsr       save_scr
          move.b    mrk+part,d0
          bmi.s     werfweg2
          move.b    mrk+modi,d0
          bne.s     werfweg3
werfweg2  bsr       save_buf
werfweg3  lea       mark_buf,a0
          clr.b     (a0)
          bsr       fram_del
          lea       drawflag,a0
          move.w    #-1,(a0)
          move.l    #$12345678,12(a0)   Magic fÅr "RÅckgÑngig"
          lea       mrk,a0              -> EinfÅgen nicht mîglich
          clr.w     einf(a0)
          move.b    modi(a0),modi+1(a0)
          clr.b     modi(a0)
          move.w    #3999,d0
          move.l    buff(a0),a0
          move.l    bild_adr(a4),a1
werfweg1  move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d0,werfweg1
          move.l    menu_adr,a0
          bclr.b    #3,491(a0)
          bset.b    #3,1643(a0)
          bsr       men_inv
          bra       win_rdw
          ;
fuenf_46  cmp.b     #$46,d0
          bne       fuenf_4b
          move.w    mark_buf,d0         --- öbernehmen ---
          beq       exit
          lea       mrk,a2
          tst.b     ov(a2)
          beq       exit
          moveq.l   #22,d1              + Disabeln +
          bsr       rsrc_gad
          move.l    addrout,a3
          clr.w     82(a3)
          move.w    #8,106(a3)
          move.w    #8,130(a3)
          move.w    #7,80(a3)
          move.w    #5,104(a3)
          tst.b     modi(a2)            VerknÅpft ?
          bne.s     ueber1
          tst.b     part(a2)
          beq.s     ueber4
          bset.b    #3,83(a3)
          bclr.b    #3,107(a3)
          move.b    #5,81(a3)
          move.b    #7,105(a3)
          bra.s     ueber2
ueber1    tst.b     part(a2)            öberhang ?
          beq.s     ueber2
          bclr.b    #3,107(a3)
          bclr.b    #3,131(a3)
ueber2    lea       fruebern,a2         + Frage +
          moveq.l   #22,d2
          bsr       form_do
          bsr       form_del
          cmp.b     #6,d4               Abbruch ?
          beq       men_inv
          lea       mrk,a0
          subq.b    #2,d4
          btst      #0,d4
          beq.s     ueber3
          clr.b     modi(a0)            VerknÅpfung Åbernehmen
ueber3    btst      #1,d4
          beq.s     ueber4
          clr.b     part(a0)            öberhang abschneiden
          lea       drawflag,a0         und RÅckg disabeln
          clr.w     (a0)
          move.l    menu_adr,a0
          bset.b    #3,491(a0)
ueber4    tst.b     modi(a0)            + "öbern" mîglich lassen ? +
          bne       men_inv
          tst.b     part(a0)
          bne       men_inv
          move.l    menu_adr,a0
          bset.b    #3,1691(a0)
          bra       men_inv
          ;
fuenf_4b  cmp.b     #$4b,d0
          bne       fuenf_4c
          move.w    mark_buf,d0         --- Spiegeln ---
          beq       men_inv
          bsr       over_cut
          lea       stralspi,a0
          moveq.l   #2,d0
          bsr       alertbox
          move.w    d0,d4
          cmp.b     #2,d4
          beq       men_inv
          bsr       over_old
          bsr       save_scr
          bsr       save_buf
          cmp.b     #1,d4
          bne       spiver
          move.w    mark_buf+8,d7       -- Horizontale Achse --
          sub.w     mark_buf+4,d7
          beq       men_inv
          move.l    bildbuff,a0
          move.l    bild_adr(a4),a1
          move.w    mark_buf+4,d0
          mulu.w    #80,d0              Zeiger
          add.l     d0,a0
          move.w    mark_buf+8,d0
          mulu.w    #80,d0
          add.l     d0,a1
          move.w    mark_buf+2,d0
          move.w    mark_buf+6,d1
          move.w    d0,d3
          move.w    d1,d4
          and.w     #15,d0
          and.w     #15,d1
          lsr.w     #3,d3
          lsr.w     #4,d4
          bclr      #0,d3
          add.w     d3,a0               X-Start-Offset
          add.w     d3,a1
          lea       rand_tab,a2
          lsl.w     #1,d0
          lsl.w     #1,d1
          move.w    (a2,d0.w),d6        Linker-Rand-Maske
          move.w    2(a2,d1.w),d2       Rechter-Rand-Not-Maske
          lsr.w     #1,d3
          sub.w     d3,d4               Breite Mittelteil
          bne.s     spihor7
          not.w     d2                  Links=Rechts
          and.w     d2,d6
spihor7   subq.w    #2,d4
          move.w    d6,d5
          not.w     d5
          move.w    d2,d3
          not.w     d3
spihor1   move.l    a0,a2               + Schleife +
          move.l    a1,a3
          move.w    (a0)+,d0
          and.w     d6,d0
          and.w     d5,(a1)
          or.w      d0,(a1)+
          move.w    d4,d0               Kein Mittelteil ?
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
          lea       drawflag,a0         RÅckgÑngig enabeln
          move.w    #$ff00,(a0)
          move.l    menu_adr,a0
          bclr.b    #3,491(a0)
          bsr       men_inv
          bra       win_rdw
spihor5   cmp.w     #-1,d4              Zwei Worte breit ?
          beq       spihor3
          bra       spihor4
          ;
spiver    move.w    mark_buf+6,d1       -- Vertikale Achse --
          cmp.w     mark_buf+2,d1
          bls       men_inv
          move.w    mark_buf+8,d7       Hîhe
          move.w    mark_buf+4,d0
          sub.w     d0,d7
          move.l    bildbuff,a0
          move.l    bild_adr(a4),a1
          mulu.w    #80,d0              Y-Start-Offset
          add.l     d0,a0
          add.l     d0,a1
          move.w    mark_buf+2,d0
          move.w    d0,d3
          move.w    d1,d4
          and.w     #15,d0
          and.w     #15,d1
          lsr.w     #3,d3
          lsr.w     #3,d4
          bclr      #0,d3
          bclr      #0,d4
          add.w     d3,a0               X-Start-Offset
          add.w     d4,a1
          lea       rand_tab,a2
          lsl.w     #1,d0
          lsl.w     #1,d1
          moveq.l   #32,d6              Rechter-Rand-Maske
          sub.w     d0,d6
          move.w    (a2,d6.w),d6
          moveq.l   #30,d5              Linker-Rand-Maske
          sub.w     d1,d5
          move.w    (a2,d5.w),d5
          sub.w     d3,d4               Mittelteil-Breite
          lsr.w     #1,d4
          bne.s     spiver9
          and.w     d5,d6               Rechts=Links
spiver9   subq.w    #2,d4
spiver1   move.l    a0,a2               +++++ Schleife +++++
          move.l    a1,a3
          move.w    (a0)+,d0
          moveq.l   #15,d2
spiver2   lsr.w     #1,d0               Linker Rand
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
spiver5   lsr.w     #1,d0               Mittelteil
          roxl.w    #1,d1
          dbra      d2,spiver5
          move.w    d1,-(a1)
          dbra      d3,spiver4
spiver6   move.w    (a0),d0             Rechter Rand
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
          move.w    mark_buf+2,d0       ++ Verschiebungskorrektur ++
          move.w    mark_buf+6,d6
          and.w     #15,d0
          and.w     #15,d6
          moveq.l   #15,d5              D5/D6: Restbreite li./re.
          sub.w     d0,d5
          move.w    mark_buf+2,d3       D3/D4: X1-X2-Koos
          move.w    mark_buf+6,d4
          cmp.w     d5,d6
          beq.s     spiver10            nicht nîtig -> fertig
          blo.s     spiver11
          sub.w     d5,d6               + Rechts +
          move.w    d3,d0
          sub.w     d6,d0
          move.w    d0,-(sp)
          move.w    d3,d1
          subq.w    #1,d1
          move.w    d1,-(sp)
          move.w    d4,d1
          sub.w     d6,d1
          bra.s     spiver12
spiver11  sub.w     d6,d5               + Links +
          move.w    d4,d0
          addq.w    #1,d0
          move.w    d0,-(sp)
          move.w    d4,d1
          add.w     d5,d1
          move.w    d1,-(sp)
          move.w    d3,d0
          add.w     d5,d0
spiver12  move.l    mark_buf+2,d2       + Verschieben +
          swap      d0
          swap      d1
          move.w    mark_buf+4,d0
          move.w    mark_buf+8,d1
          move.l    bild_adr(a4),a0
          move.l    a0,a1
          bsr       copy_blk
          move.w    (sp)+,d1            + LÅcke fÅllen +
          move.w    (sp)+,d0
          swap      d0
          swap      d1
          move.w    mark_buf+4,d0
          move.w    mark_buf+8,d1
          move.l    d0,d2
          move.l    bildbuff,a0
          move.l    bild_adr(a4),a1
          bsr       copy_blk
spiver10  lea       drawflag,a0         RÅckgÑngig enabeln
          move.w    #$ff00,(a0)
          move.l    menu_adr,a0
          bclr.b    #3,491(a0)
          bsr       men_inv
          bra       win_rdw
spiver3   cmp.w     #-1,d4
          beq       spiver6
          bra       spiver8
          ;
nr_sechs  cmp.b     #$55,d0             *** Hilfen-MenÅ ***
          bne.s     sechs_5c
          move.w    d0,d7               --- Pos speichern ---
          bsr       over_que
          bne       men_inv
          move.w    d7,-(sp)
          bsr       fram_del
          move.w    (sp)+,d2
          bra       drei_chg
          ;
sechs_5c  cmp.b     #$5c,d0
          bne.s     sechs_5a
          moveq.l   #15,d2              --- Rastergrîûe ---
          lea       frraster,a2
          bsr       form_do
          bsr       form_del
          moveq.l   #1,d2
          addq.l    #6,a2
raster1   move.w    28(a2),d1
          cmp.w     (a2),d1             Startoff. > Rasterbreite ?
          blo.s     raster2
          ext.l     d1
          divu      (a2),d1
          swap      d1
          move.w    d1,28(a2)           neuer Offset
          add.w     #14,a2
raster2   dbra      d2,raster1
          bra.s     men_inv
          ;
sechs_5a  cmp.b     #$5a,d0
          bne.s     sechs_59
          move.w    chooras,d1          --- Rastern ---
          eor.b     #1,d1
          move.w    d1,chooras
          bsr       check_xx
          bra.s     men_inv
          ;
sechs_59  cmp.b     #$59,d0
          bne.s     sechs_56
          lea       chookoo,a0          --- Koord. zeigen ---
          move.w    (a0),d1
          eor.b     #1,d1
          move.w    d1,(a0)
          move.w    #$777,2(a0)
          bsr.s     check_xx
          move.w    chookoo,d0
          bne.s     koozeig1
          pea       koostr              Anzeige lîschen
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          bra.s     men_inv
koozeig1  bsr       koos_mak            Ausgabe
          ;
sechs_56  cmp.b     #$56,d0
          bne.s     men_inv
          move.w    choofig,d1          --- Koordinaten ---
          cmp.b     #$43,d1
          bne.s     koord1
          moveq.l   #$27,d1
koord1    lea       koanztab,a0
          sub.w     #$1f,d1
          clr.l     d2
          move.b    (a0,d1.w),d2        Anzahl der Punkte
          beq.s     men_inv
          bsr       get_koos            Formular aufrufen
          cmp.w     #9,d4
          beq.s     men_inv             Abbruch-Taste
          nop
          ;
*----------------------------------------------------------SUBROUTINEN
men_inv   ;
          aes       33 2 1 1 0 !msg_buff+6 1 !menu_adr  ;menu_tnormal
exit      rts
          ;
check_xx  ;
          aes       31 2 1 1 0 !d0 !d1 !menu_adr  ;wind_set:check
          rts                                      D0:Index/D1:0-1
          ;
maus_bne  moveq.l   #2,d0
          bra.s     maus_alt+2
maus_neu  move.w    choomou,d0          ** Aktuelle Mausform **
          bra.s     maus_alt+2
maus_alt  clr.w     d0
          aes       78 1 1 1 0 !d0 !maus_adr  ;set_mouse_form
          rts
obj_off   ;
          aes       44 1 3 1 0 !d0 !a3  ;XY-Koo. des D0. Objektes
          rts
          ;
obj_draw  move.l    d6,4(a6)            ** Objekt zeichnen **
          move.l    d7,8(a6)
          move.l    a3,addrin
          aes       42 6 1 1 0 !d0 !d1  ;obj_draw
          rts
          ;
over_cut  lea       mrk,a2              ** "öberhang verwerfen ?" **
          tst.b     ov(a2)
          beq       exit
          tst.b     part(a2)
          bpl       exit
          move.w    d0,d2
          lea       stralcut,a0
          moveq.l   #1,d0
          bsr       alertbox
          cmp.w     #1,d0
          bne.s     over_cu1
          move.w    d2,d0
          clr.b     part(a2)
          rts
over_cu1  addq.l    #4,sp               nein-> Abbruch
          bra       men_inv
          ;
over_old  move.b    mrk+ov,d0           ** VerknÅpfung aufheben **
          beq       exit
          move.b    mrk+modi,d0
          beq.s     over_ol1
          move.b    mrk+part,d0
          bmi.s     over_ol1
          movem.l   d2-d7/a2-a3,-(sp)
          move.l    drawflag+4,d0
          move.l    drawflag+8,d1
          move.b    mrk+part,d2
          beq.s     over_ol2
          move.l    mrk+old,d0
          move.l    mrk+old+4,d1
over_ol2  move.l    mark_buf+2,d2
          move.l    bildbuff,a0
          move.l    rec_adr,a1
          move.l    bild_adr(a1),a1
          bsr       copy_blk
          movem.l   (sp)+,d2-d7/a2-a3
over_ol1  lea       mrk,a0
          move.b    #-1,chg(a0)         VerÑnderung erfolgt
          move.b    modi(a0),modi+1(a0)
          clr.b     modi(a0)
          move.l    menu_adr,a1
          bclr.b    #3,1643(a1)
          tst.b     part(a0)
          bmi       exit
          bset.b    #3,1691(a1)         "öbernehmen" disabeln
          rts
          ;
over_beg  move.w    #1999,d0            ** Overlay-Mode vorbereiten **
          move.l    rec_adr,a0
          move.l    bild_adr(a0),a0
          move.l    mrk+buff,a1
over_be1  move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d0,over_be1
          move.b    mrk+copy,d0         Kopieren ?
          bne       exit
          move.l    mrk+buff,a0
          clr.w     d3
          ;
work_blk  move.l    mark_buf+2,d0       **  MFDBs initialisieren **
          move.l    mark_buf+6,d1
work_bl2  lea       mfdb_q,a1
          move.l    a0,(a1)
          move.l    a0,20(a1)
          move.l    d1,d2
          sub.l     d0,d2
          move.l    d2,4(a1)
          move.l    d2,24(a1)
          move.l    a1,14(a5)
          add.w     #20,a1
          move.l    a1,18(a5)
          lea       ptsin,a1
          move.l    d0,(a1)
          move.l    d1,4(a1)
          move.l    d0,8(a1)
          move.l    d1,12(a1)
          move.w    d3,(a6)             D3: VerknÅpfungsmodus
          vdi       109 4 1             ;copy_raster
          rts
          ;
cent_koo  moveq.l   #1,d7               ** Ausschnitt zentrieren **
          move.l    #$27f018f,d6        D2: Rahmenbreite+hîhe
cent_ko1  cmp.w     (a2),d2             Rahmen paût ins Fenster ?
          bhi.s     cent_ko2
          move.w    (a2),d0             +++  Ja  +++
          sub.w     d2,d0               D0: Fensterbreite-Aus.breite
          lsr.w     #1,d0               D0:=D0/2
          add.w     -4(a2),d0           D0:=D0+Fensterstartkoo.
          add.w     (a3),d0             absolut machen
          move.w    d0,d1
          add.w     d2,d1               D1: X2Y2-Koo
          bra.s     cent_ko3
cent_ko2  move.w    d2,d1               +++ Nein +++
          sub.w     (a2),d1
          lsr.w     #1,d1
          move.w    -4(a2),d0
          add.w     (a3),d0
          sub.w     d1,d0
          move.w    d0,d1
          add.w     d2,d1               D0/D1: neue Rahmenpos
          tst.w     d0
          bpl.s     cent_ko4
          not.w     d0                  unter Bildrand
          addq.w    #1,d0
          add.w     d0,d1
          clr.w     d0
          bra.s     cent_ko3
cent_ko4  move.w    d1,d3
          sub.w     d6,d3
          bmi.s     cent_ko3
          sub.w     d3,d0               drÅber raus
          move.w    d6,d1
cent_ko3  subq.l    #2,a2               ++ Schleifenende ++
          addq.l    #2,a3
          swap      d6
          swap      d2
          swap      d1                  D0/D1: Rahmenkoo-Ausgabe
          swap      d0
          dbra      d7,cent_ko1
          rts
          ;
form_do   bsr       maus_alt            ** Formular ausfÅren **
          aes       107 1 1 0 0 1       ;wind_update
          move.w    d2,d1
          bsr       rsrc_gad
          move.l    addrout,a3          A3: Baumadresse
          aes       54 0 5 1 0 !a3      ;form_center
          move.l    intout+2,d6
          move.l    intout+6,d7
          sub.l     #$30003,d6
          add.l     #$60006,d7
          move.l    d6,2(a6)
          move.l    d7,6(a6)
          move.l    d6,10(a6)
          move.l    d7,14(a6)
          aes       51 9 1 1 0 0        ;form_dial
          clr.w     d0
          moveq.l   #4,d1
          bsr       obj_draw            ;obj_draw
          bsr       init_ted            Adressen im Record setzen
          clr.w     form_buf
          cmp.w     #13,2(a2)
          bne.s     form_do3
          bsr       form_mud            Muster-Demobox fÅllen
          bra.s     form_do4
form_do3  cmp.w     #20,2(a2)
          bne.s     form_do2
          bsr       form_lin            Linien-Demo zeichnen
form_do4  lea       form_buf,a0
          move.w    (a2),(a0)
          move.w    6(a2),2(a0)
          move.w    20(a2),4(a0)
          move.w    34(a2),6(a0)
form_do2  ;
          aes       50 1 1 1 0 0 !a3    ;form_do
          move.w    intout,d4           D4: Index der Exit-Taste
          move.w    d4,d0
          mulu.w    #24,d0              Exit-Taste deselektieren
          bclr      #0,11(a3,d0.l)
          move.w    (a2)+,d0
          addq.w    #1,d0
          cmp.w     d0,d4               Abbruch-Taste ?
          beq       form_rdw
          clr.b     d3                  --- Editwerte prÅfen ---
          move.l    a2,-(sp)
form2     move.w    ted_nr(a2),d0
          bmi.s     form1
          bsr       read_num
          clr.w     d0
          move.b    ted_min(a2),d0
          cmp.w     d0,d1
          blo.s     form3
          move.w    ted_max(a2),d0
          cmp.w     d0,d1
          bls.s     form4
form3     bsr       form_wrt            auûerhalb -> Default einsetzen
          moveq.l   #-1,d3
          move.b    ted_inx(a2),d0
          ext.w     d0
          clr.w     d1
          bsr       obj_draw            und neu zeichnen
form4     add.w     #14,a2
          bra       form2
form1     move.l    (sp),a2
          tst.b     d3
          beq.s     form_tak            alles Ok ?
          move.w    form_buf,d0
          beq.s     form6
          cmp.w     d0,d4
          blo.s     form_tak
form6     addq.l    #4,sp
          subq.l    #2,a2               nein -> zurÅck ins Formular
          move.w    d4,d0
          clr.w     d1
          bsr       obj_draw
          bra       form_do2
          ;
form_tak  move.w    ted_nr(a2),d0       --- Werte Åbernehmen ---
          bmi.s     form_tk1
          bsr       read_num            ++ TEDINFOS ++
          move.w    d1,ted_val(a2)
          add.w     #14,a2
          bra       form_tak
form_tk1  move.w    form_buf,d0
          beq.s     form_tk2
          cmp.b     d0,d4               Touchexit -> Abbruch
          bhi.s     form_tk5
form_tk2  move.b    (a2)+,d0            ++ Radio-Buttons ++
          beq.s     form_tk5
          move.l    a3,a0
          mulu.w    #24,d0
          add.l     d0,a0
          clr.b     d0
          move.w    8(a0),d1
form_tk3  btst.b    #0,11(a0)           nach selektiertem suchen..
          bne.s     form_tk4
          add.w     #24,a0
          addq.b    #1,d0
          cmp.w     8(a0),d1            ..nur solange Buttons
          beq       form_tk3
form_tk4  move.b    d0,(a2)+
          bra       form_tk1
form_tk5  move.l    (sp)+,a2            ++ Switch-Buttons ++
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
form_tk6  add.w     #24,a0
          dbra      d0,form_tk7
          move.w    d1,chootxt
          bra       form_rw1
          ;
form_rdw  move.l    a2,-(sp)            --- Defaults einsetzen ---
          move.w    form_buf,d0
          beq.s     form_rw3
          move.w    form_buf+2,4(a2)
          move.w    form_buf+4,18(a2)
          move.w    form_buf+6,32(a2)
form_rw3  move.w    (a2),d0             ++ Tedinfos ++
          bmi.s     form_rw4
          move.w    ted_val(a2),d0      Default-Wert einsetzen
          bsr.s     form_wrt
          add.w     #14,a2
          bra       form_rw3
form_rw4  addq.l    #2,a2               ++ Radio-Buttons ++
          clr.w     d0
          move.b    (a2)+,d0
          beq.s     form_rw8
          mulu.w    #24,d0
          move.l    a3,a0
          add.l     d0,a0
          clr.b     d0
          move.b    (a2)+,d1
form_rw5  cmp.b     d0,d1
          bne.s     form_rw6
          move.b    #1,11(a0)
          bra.s     form_rw7
form_rw6  clr.b     11(a0)
form_rw7  add.w     #24,a0
          addq.b    #1,d0
          btst.b    #4,9(a0)
          bne       form_rw5
          bra       form_rw4+2
form_rw8  move.l    (sp)+,a2            ++ Switch-Buttons ++
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
form_rx2  add.w     #24,a0
          dbra      d0,form_rw9
form_rw1  subq.l    #2,a2
          rts
          ;
form_wrt  move.l    ted_adr(a2),a0      ** Zahl schreiben **
          move.w    ted_len(a2),d1      D0.w: Zahl / A0: Zei.a.Record
          add.w     d1,a0
          addq.l    #1,a0
          ext.l     d0
form_wr1  cmp.w     #10,d0              Dezimal-Zahl in String
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
form_del  move.l    rec_adr,a4          ** Formular lîschen **
          aes       104 2 5 0 0 !(a4) 10  ;wind_get
          move.w    intout+2,d0
          cmp.w     (a4),d0
          beq.s     form_de1            Bild ist top-window
          clr.l     d6
          move.l    #$2800190,d7
form_de1  move.l    d6,2(a6)
          move.l    d7,6(a6)
          move.l    d6,10(a6)
          move.l    d7,14(a6)
          aes       51 9 1 1 0 3        ;form_dial
          aes       107 1 1 0 0 0       ;wind_update
          move.w    choomou,d0
          bne       maus_neu
          rts
          ;
form_mud  bsr       hide_m              ** Muster-Def.box fÅllen **
          moveq.l   #4,d0
          bsr       obj_off
          move.l    logbase,a1
          move.w    intout+4,d0
          mulu.w    #80,d0
          add.l     d0,a1
          move.w    intout+2,d0
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
          bra.s     form_mus+4
form_mus  bsr.l     hide_m              ** Muster-Demobox zeichnen **
          vdi       23 0 1 !6(a2)
          vdi       24 0 1 !20(a2)
          vdi       25 0 1 1
          vdi       32 0 1 1
          cmp.w     #4,6(a2)
          bne.s     form_mu2
          moveq.l   #15,d0
          lea       choofil,a0
          lea       intin,a1
form_mu1  move.w    (a0)+,(a1)+
          dbra      d0,form_mu1
          vdi       112 0 16
form_mu2  moveq.l   #5,d0
          bsr       obj_off
          lea       ptsin,a0
          move.l    intout+2,d0
          move.l    d0,(a0)
          add.l     140(a3),d0
          sub.l     #$10001,d0
          move.l    d0,4(a0)
          vdi       114 2 0             ;fill_rectangle
          vdi       23 0 1 1
          vdi       25 0 1 1
          vdi       32 0 1 3
          bra       show_m
          ;
form_lin  bsr       hide_m              ** Linien-Demo zeichnen **
          moveq.l   #4,d0
          clr.w     d1
          bsr       obj_draw            Kasten lîschen
          vdi       15 0 1 !34(a2)
          vdi       16 1 0 !20(a2) 0
          vdi       17 0 1 1
          vdi       113 0 1 !choopat
          vdi       32 0 1 1
          moveq.l   #4,d0
          bsr       obj_off
          lea       ptsin,a0
          move.l    intout+2,d0
          move.w    118(a3),d1
          lsr.w     #1,d1
          add.w     d1,d0
          move.l    d0,(a0)
          swap      d0
          add.w     116(a3),d0
          subq.w    #1,d0
          swap      d0
          move.l    d0,4(a0)
          vdi       6 2 0               ;polyline
          vdi       16 1 0 1 0
          vdi       15 0 1 1
          vdi       32 0 1 3
          bra       show_m
          ;
read_num  move.l    ted_adr(a2),a0      ** TEDINFO-String auswerten **
          move.w    ted_len(a2),d2
          clr.w     d0
          move.w    ted_val(a2),d1      Default-Wert
          cmp.b     #'@',(a0)         Leer-String ?
          beq.s     read1
          tst.b     (a0)
          beq.s     read1
          clr.w     d1
readloop  move.b    (a0)+,d0
          sub.b     #'0',d0
          bmi.s     read1               keine Ziffer -> fertig
          cmp.b     #9,d0
          bhi.s     read1
          mulu.w    #10,d1
          add.w     d0,d1
          dbra      d2,readloop
read1     rts
          ;
init_ted  tst.w     2(a2)               ** TEDINFO-Adressen setzen **
          bmi       exit
          move.l    ted_adr+2(a2),a0
          cmp.l     #$10,a0
          bhi       exit
          move.l    a2,-(sp)
          addq.l    #2,a2
init_te1  moveq.l   #8,d0
          move.w    (a2),d1
          bsr       rsrc_gad+2
          move.l    addrout,a0
          move.l    (a0),a0
          add.w     ted_adr+2(a2),a0
          move.l    a0,ted_adr(a2)
          add.w     #14,a2
          tst.w     (a2)
          bpl       init_te1
          move.l    (sp)+,a2
          rts
*--------------------------------------------------------MENö-VARIABLE
menu_adr  ds.l    1
choopat   dc.w    $aaaa
chooras   dc.w    0
chootxt   dc.w    0
choomou   dc.w    0,0,0,'  Pfeil-Maus',0
chookoo   dc.w    0,-1,-1
choofil   dcb.w   16,0
koanztab  dc.b    1,0,0,1,1,1,0,3,3,3,1,3,3,3
*--------------------------------------------------------------RECORDS
mrk       dcb.w   14,0
comb_dat  dc.b    0,1,6,7,2,11,4,13,14,9,8
work_dat  dc.w    0,15,10
mfdb_q    dc.w    0000,0000,00,00,40,0,1,0,0,0
          dc.w    0000,0000,00,00,40,0,1,0,0,0
maus_adr  dc.l    maus_blk
maus_blk  dc.w    7,7,1,0,1,$fffe,$fffe,$c386,$c386,$c386,$c386,$fc7e
          dc.w    $fc7e,$fc7e,$c386,$c386,$c386,$c386,$fffe,$fffe,0
          dc.w    $fffe,$8102,$8102,$8102,$8102,$8102,$8002,$fc7e
          dc.w    $8002,$8102,$8102,$8102,$8102,$8102,$fffe,0
*--------------------------------------------------------------STRINGS
koostr    dc.b    27,'Y h       ',0
stralspi  dc.b    91,48,93,91,'An welcher Achse spiegeln ?           | |',93,91,'Horizontal|Abbruch|Vertikal',93,0,0
stralfat  dc.b    91,51,93,91,'Fenstergrîûeneinstellung|ist noch ni'
          dc.b    'cht implemen-|tiert !!',93,91,'Abbruch',93,0,0
stralovn  dc.b    91,51,93,91,'Nicht genug Speicher fÅr den|benîtig'
          dc.b    'ten Buffer !!',93,91,'Abbruch',93,0,0
stralcut  dc.b    91,49,93,91,'Der nicht im  Bild befind-|liche Teil de Ausschnitts|geht verloren !!',93,91,'Ok|Abbruch',93,0,0
*-----------------------------------------------------FORMULAR-RECORDS
*   Ok-Nr, { TED-Nr,LÑnge-1,Default,Index*256+min,max,Offset.l } ,-1,
*          { Button-Nr*256+selected Button } ,0
*- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
frinfobo  dc.w  08,-1,0
frsegmen  dc.w  09,4,2,0,8,360,0,0,4,0,0,8,9,0,3
          dc.w     4,2,0,8,360,0,4,4,0,0,8,9,0,7,-1,0
frkoordi  dc.w  08,6,2,0,4,639,0,0,6,2,0,4,399,0,3
          dc.w     7,2,0,5,639,0,0,7,2,0,5,399,0,3,-1,0
a:        ;
frmodus   dc.w  10,-1,$600,0
frpunkt   dc.w  18,8,0,1,$110,8,0,0,9,0,1,17,1,0,0,-1,$400,$b01,0
frpinsel  dc.w  11,10,0,4,9,9,0,0,11,0,1,10,1,0,0,-1,$302,0
frsprayd  dc.w  10,12,1,10,$108,99,0,0,-1,$401,0
frmuster  dc.w  11,13,0,1,$107,4,0,0,14,1,1,9,24,0,0
          dc.w     15,0,1,10,1,0,0,-1,0
frtext    dc.w  23,16,1,13,$40a,26,0,0,17,2,0,11,270,0,0
          dc.w     18,0,1,12,1,0,0,-1,$f01,$1300,0
frradier  dc.w  09,19,1,16,$103,99,0,0,19,1,10,$103,99,0,2,-1,$600,0
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
fr_tab    dc.w    frmodus-a,frpunkt-a,frpinsel-a,frsprayd-a,frmuster-a
          dc.w    frtext-a,frradier-a,frlinie-a,frdrucke-a,frdatei-a
form_buf  ds.w    4
*---------------------------------------------------------------------
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
          ;
hexraus   movem.l   d0-d3/a0-a3,-(sp)
          pea       header
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          movem.l   (sp)+,d0-d3/a0-a3
          movem.l   d0-d3/a0-a3,-(sp)
*         move.l    d0,d0
*         bsr       hexaus
*         move.l    d1,d0
*         bsr       hexaus
*         move.l    d3,d0
*         bsr       hexaus
*         move.l    a1,d0
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
*         bra       men_inv
          end
