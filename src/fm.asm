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
 module    MENU_1
 section   drei
 pagelen   32767
 pagewid   133
 noexpand
 ;
 XREF  aescall,vdicall,contrl,intin,intout,ptsin,addrin,addrout,stack
 XREF  msg_buff,bildbuff,wi1,wi_count,rec_adr,menu_adr,nr_vier,win_xy
 XREF  last_koo,maus_rec,rsrc_gad,save_scr,set_xx,win_rdw,form_wrt,mrk
 XREF  drawflag,fram_del,mark_buf,form_do,form_del,men_inv,form_buf
 XREF  frinfobo,frsegmen,frkoordi,frdrucke,frdatei,check_xx,koanztab
 XREF  init_ted,copy_blk,maus_neu,fram_ins,maus_bne
 ;
 XDEF  choofig,chooset,chooseg,drei_chg,get_koos,over_que,directory
 XDEF  now_offs,alertbox,evt_menu,wind_chg
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
info      equ  6    0:open/1:change/2:virgin/3:wieder unchanged
lastnum   equ  7    Handle des zuletzt akt. Win.
yx_off    equ  16   Abstand Fensterursprung zu 0/0
fenster   equ  22   Pos. und Ausmaûe
schieber  equ  30   Schieber hor./ver.:Pos./Grîûe
          ;        *** Offsets zu Formular-Rec.s ***
ted_val   equ  4    akt., gÅltiger Wert
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
evt_menu  move.l    msg_buff+6,d0
          cmp.l     #$40000,d0
          bhs.s     nr_zwei
          moveq.l   #1,d2               ********* Desk-MenÅ **********
          lea       frinfobo,a2
          bsr       form_do             --- Info-Box ---
          bsr       form_del
          bra       men_inv
nr_zwei   cmp.l     #$50000,d0
          bhs       nr_drei
          cmp.b     #$1d,d0             ******** Befehle-MenÅ ********
          bne       new
          bsr       wind_chg            --- Abbruch ---
          bne.s     mainrts3
          moveq.l   #6,d0
          lea       wi1,a0
mainrts2  btst.b    #1,info(a0)         Speicher gesichert oder leer ?
          bne.s     mainrts3
          dbra      d0,mainrts2
          bra.s     mainrts1
mainrts3  moveq.l   #1,d0
          lea       stralneu,a0
          bsr       alertbox            nein -> um Ok bitten
          cmp.w     #1,d0
          bne       men_inv
mainrts1  ;
          move.l    maus_rec+4,14(a5)
          vdi       125 0 0             ;alter Button-Vektor
          move.l    maus_rec+8,14(a5)
          vdi       127 0 0             ;alter Mouse-Vektor
          aes       111 0 1 0 0         ;rsrc_free
          vdi       101 0 0             ;close_vwork
          aes       19 0 1 0 0          ;appl_exit
          clr.l     -(sp)               ;term
          trap      #1
          ;
new       cmp.b     #$16,d0
          bne.s     zwei_17
          bsr       wind_chg            --- Neu ---
          beq.s     new1
          moveq.l   #1,d0
          lea       stralneu,a0         "Arbeit lîschen ?"
          bsr       alertbox
          cmp.w     #1,d0
          bne       men_inv             nein -> Abbruch
new1      bsr       fram_del
          move.l    menu_adr,a0
          bset      #3,491(a0)          RÅckgÑngig disabeln
          bset.b    #3,635(a0)          Abspeichern disabeln
          lea       drawflag,a1
          move.l    12(a1),d0
          cmp.l     bild_adr(a4),d0
          bne.s     new4
          bset.b    #3,1643(a0)         EinfÅgen disabeln
          lea       mrk,a0
          clr.w     einf(a0)
new4      lea       mark_buf,a0
          clr.w     (a0)
          move.b    #1,info(a4)         nur Open-Flag gesetzt
          clr.w     (a1)
          move.w    #3999,d0
          move.l    bild_adr(a4),a0
new2      clr.l     (a0)+               Fensterpuffer lîschen
          clr.l     (a0)+
          dbra      d0,new2
          bsr       men_inv
          move.l    bild_adr(a4),a0     Fenstertitel lîschen
          add.w     #32010,a0
          clr.w     (a0)
          bsr       name_xx
          bra       win_rdw
          ;
zwei_17   cmp.b     #$17,d0
          bne       zwei_18
          bsr       over_que            --- ôffnen ---
          bne       men_inv
          pea       men_inv
open      bsr       save_scr            +++ Fenster îffnen +++
          bsr       fram_del
          cmp.w     #6,wi_count
          bne.s     open11
          moveq.l   #1,d0               7-Fenster-Warnung ausgeben
          lea       stralwi7,a0
          bsr       alertbox
          cmp.w     #1,d0
          bne.s     exit
open11    move.l    #-1,-(sp)           ;malloc
          move.w    #$48,-(sp)
          trap      #1
          addq.l    #6,sp
          cmp.l     #32100,d0           noch 32 K frei ?
          bge.s     open9
          lea       stralnom,a0
          moveq.l   #1,d0
          bsr       alertbox
          moveq.l   #-1,d0
          rts
open9     ;
          aes       100 5 1 0 0 $fef 0 18 640 382  ;wind_create
          move.w    intout,d1
          bpl.s     open1
open2     moveq.l   #1,d0
          lea       stralnow,a0         kein weiteres Fenster->Abbruch
          bsr       alertbox
          moveq.l   #-1,d0
exit      rts
open1     moveq.l   #6,d0               freies Record suchen...
          move.l    a4,a0
          lea       wi1,a4
open3     btst.b    #0,info(a4)
          beq.s     open4
          add.w     #38,a4
          dbra      d0,open3
open12    move.l    a0,a4               schon 7 Fenster->Abbruch
          bra       open2
open4     movem.l   a0/d1,-(sp)
          move.l    #32100,-(sp)        ;malloc
          move.w    #$48,-(sp)
          trap      #1
          addq.l    #6,sp
          movem.l   (sp)+,a0/d1
          move.l    d0,bild_adr(a4)
          bmi       open12              Fehler ?
          move.w    d1,(a4)             Record initialisieren
          move.b    #1,info(a4)
          move.b    1(a0),lastnum(a4)
          move.l    d0,a0               Bild-Buffer lîschen
          move.w    #1999,d0
open6     clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,open6
          move.l    a4,rec_adr
          move.l    menu_adr,a0
          bset      #3,635(a0)          Abspeichern disabeln
          lea       now_offs,a1
          moveq.l   #4,d0               MenÅeintrÑge enabeln
open5     add.w     (a1)+,a0
          bclr.b    #3,(a0)
          dbra      d0,open5
          bsr       koo_chk             "Koordinaten" evtll. disabeln
          add.w     #1,wi_count
          cmp.w     #7,wi_count         7 Fenster offen ?
          blo.s     open7
          move.l    menu_adr,a3         -> Accessories disabeln
          add.w     #323,a3
          moveq.l   #5,d0
open8     bset.b    #3,(a3)
          add.w     #24,a3
          dbra      d0,open8
open7     moveq.l   #8,d0               Schieber: Position 0
          clr.w     d1
          bsr       set_xx
          moveq.l   #9,d0
          clr.w     d1
          bsr       set_xx
          clr.l     schieber(a4)
          moveq.l   #15,d0              alte Grîûe
          move.w    schieber+4(a4),d1
          bsr       set_xx
          moveq.l   #16,d0
          move.w    schieber+6(a4),d1
          bsr       set_xx
          move.l    fenster(a4),8(a6)   ;graf_growbox
          move.l    fenster+4(a4),12(a6)
          move.l    fenster(a4),(a6)
          move.l    #$100010,4(a6)
          aes       73 8 1 0 0
          move.l    bild_adr(a4),a0     Fenstertitel setzen
          add.w     #32010,a0
          clr.w     (a0)
          bsr       name_xx
          move.l    fenster(a4),4(a6)
          move.l    fenster+4(a4),8(a6)
          aes       108 6 5 0 0 0 $fef  ;wind_calc
          move.l    intout+2,2(a6)
          move.l    intout+6,6(a6)
          aes       101 5 1 0 0 !(a4)   ;wind_open
          clr.b     d0
          rts
          ;
zwei_18   cmp.b     #$18,d0
          bne       zwei_14
          bsr       over_que            --- Laden ---
          bne       men_inv
          clr.b     filename
          clr.w     d3
          bsr       itemslct            Item-Selector aufrufen
          tst.b     d0
          bne       men_inv
          clr.w     -(sp)               open
          pea       dta+30
          move.w    #$3d,-(sp)
          trap      #1
          addq.l    #8,sp
          move.w    d0,handle
          bmi       tos_err
          move.b    frdatei+33,d1       D1: Format
          bne.s     load2               +++ Format OHNE +++
          move.l    bildbuff,a2         A2: Bufferadresse
          move.l    a2,a0
          move.w    #1999,d0
load7     clr.l     (a0)+               Zwischenspeicher lîschen
          clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,load7
          move.w    frdatei+6,d0        Bildbreite in Bytes umrechnen
          move.w    d0,d2
          lsr.w     #3,d2
          and.w     #7,d0
          beq.s     load4
          addq.w    #1,d2               Breite auf Bytes runden ?
          lea       stralbyt,a0
          moveq.l   #1,d0
          bsr       alertbox
          cmp.w     #2,d0
          beq       load3               ..nicht erwÅnscht -> Abbruch
load4     move.w    d2,d3
          mulu.w    frdatei+20,d2
          bsr       maus_bne
          bsr       load_red            Bild laden
          bsr       load_opn
          move.w    frdatei+20,d0
load12    subq.w    #1,d0
          moveq.l   #80,d2
          sub.w     d3,d2
          subq.w    #1,d3
          move.l    bild_adr(a4),a0
          move.l    bildbuff,a2
load5     move.w    d3,d1               Bild in Puffer kopieren
load6     move.b    (a2)+,(a0)+
          dbra      d1,load6
          add.w     d2,a0
          dbra      d0,load5
          bra       load3
load2     cmp.b     #1,d1
          bne.s     load10
          cmp.l     #32034,dta+26       +++ Format DEGAS +++
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
          bsr       maus_bne            Biene-Maus
          move.l    bild_adr(a4),a2
          move.l    #32000,d2           Bild laden
          bsr.s     load_red
          bra.s     load3
load10    moveq.l   #10,d2              +++ Format LOGO +++
          move.l    bildbuff,a2
          bsr.s     load_red
          cmp.w     #1,(a2)             Header-Test
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
          move.w    d3,d0               D3: Breite in Bytes
          lsr.w     #3,d3
          bclr      #0,d3
          and.b     #15,d0
          beq.s     load11
          addq.w    #2,d3
load11    move.w    8(a2),d4            D4: Hîhe
          move.w    d3,d2
          mulu.w    8(a2),d2            D2: Anz. aller Bytes
          bsr.s     load_red            Bild laden+in Buffer kopieren
          bsr.s     load_opn            Fenster îffnen
          move.w    d4,d0
          bra       load12
load3     bset.b    #2,info(a4)         Virgin-Flag setzen
          clr.l     d3
load9     move.w    handle,-(sp)        ++ close ++
          move.w    #$3e,-(sp)
          trap      #1
          addq.l    #4,sp
          bsr       maus_neu
          tst.b     d3
          bne       men_inv
          bsr       men_inv
          bra       win_rdw
load_red  move.l    a2,-(sp)            ++ Daten einlesen ++
          move.l    d2,-(sp)            D0: Anz der Bytes
          move.w    handle,-(sp)
          move.w    #$3f,-(sp)
          trap      #1
          lea       12(sp),sp
          rts
load_bad  lea       stralbad,a0         ++ Formatfehler ++
          moveq.l   #1,d0
          bsr       alertbox
          moveq.l   #-1,d3
          bra       load9
load_opn  bsr       wind_chg            ++ Fenster vorbereiten ++
          bne.s     load_op2
          btst.b    #2,info(a4)
          bne.s     load_op2
          move.w    mark_buf,d0
          beq       set_name
load_op2  bsr       open
          tst.b     d0                  Fehler ?
          beq       set_name
          addq.l    #4,sp
          moveq.l   #-1,d3
          bra       load9
tos_err   neg.w     d0                  ++ Fehler ausgeben ++
          aes       53 1 1 0 0 !d0
          bra       men_inv
          ;
zwei_14   cmp.b     #$14,d0
          bne       zwei_1b
          move.b    drawflag,d0         --- RÅckgÑngig ---
          beq       exit
          btst.b    #1,info(a4)         bisher nur 1 Bearbeitung ?
          bne.s     regen8
          bchg.b    #3,info(a4)         -> Bild wieder unverÑndert
regen8    move.w    mark_buf,d0
          beq       regen10
          lea       mrk,a2
          tst.b     ov(a2)
          beq       regen10
          tst.b     part(a2)            ++ OV-Mode (KnÅpf/öberhang) ++
          bne.s     regen11
          move.b    modi(a2),d0
          bne       regen10
regen11   move.w    #3999,d0            Hintergrund
          move.l    mrk+buff,a0
          move.l    bild_adr(a4),a1
regen12   move.l    (a0)+,(a1)+
          move.l    (a0)+,(a1)+
          dbra      d0,regen12
          lea       stack,a0            Parameter
          lea       drawflag+4,a1
          move.l    (a1),d0
          move.l    mark_buf+2,(a1)+
          move.l    (a1),d1
          move.l    mark_buf+6,(a1)
          move.l    d1,d2
          sub.l     d0,d2
          move.l    d0,4(a0)
          move.l    d2,8(a0)
          move.l    d0,24(a0)
          move.l    d1,28(a0)
          move.b    vmod(a2),chg(a0)
          move.b    modi+1(a2),vmod(a2)
          tst.b     part(a2)            öberhang-Status
          beq.s     regen13
          bset.b    #7,part(a2)
          beq.s     regen15
          sub.l     d0,d1
          move.l    mrk+old+4,d0
          sub.l     mrk+old,d0
          sub.l     d1,d0
          bne.s     regen15
          bclr.b    #7,part(a2)
          clr.l     old+4(a2)
          bra.s     regen14
regen15   clr.l     old+4(a2)
          move.w    mark_buf+2,d0
          bne.s     regen16
          move.w    d1,old+4(a2)
regen16   move.w    mark_buf+4,d0
          bne.s     regen14
          swap      d1
          move.w    d1,old+6(a2)
regen14   move.l    old(a2),d0
          move.l    old+4(a2),28(a0)
          add.l     old+8(a2),d0
          move.l    d0,24(a0)
regen13   move.l    bild_adr(a4),a1
          move.l    bildbuff,20(a0)
          lea       win_xy,a0
          clr.l     (a0)+
          move.l    #$27f018f,(a0)
          bsr       fram_ins            Auss einsetzen
          lea       mrk,a0
          move.b    stack+12,vmod(a0)
          move.l    rec_adr,a4
          bsr       men_inv
          bra       win_rdw
          ;
regen10   move.l    bildbuff,a0         ++ NORM-Mode ++
          move.l    bild_adr(a4),a1
          move.w    #3999,d1            Bilder vertauschen
regen1    move.l    (a0),d0
          move.l    (a1),(a0)+
          move.l    d0,(a1)+
          move.l    (a0),d0
          move.l    (a1),(a0)+
          move.l    d0,(a1)+
          dbra      d1,regen1
          move.b    drawflag+1,d0       Verschiebung ?
          beq       regen2
          lea       drawflag+4,a0
          lea       mark_buf,a1
          move.w    #-1,(a1)+
          move.l    (a0),d0
          move.l    4(a0),d1
          move.l    (a1),(a0)
          move.l    4(a1),4(a0)
          move.l    d0,(a1)
          move.l    d1,4(a1)
          bpl.s     regen4
          clr.w     -2(a1)              ++ Rahmen lîschen ++
          move.l    menu_adr,a2
          bset.b    #3,1667(a2)
          cmp.l     #$12345678,8(a0)    EinfÅgen erlaubt ?
          beq.s     regen7
          bclr.b    #3,1643(a2)         -> EinfÅgen enabeln
          move.w    #$ff00,mrk+einf
          move.l    bild_adr(a4),8(a0)
regen7    add.w     #1739,a2
          moveq.l   #7,d0
regen3    bset.b    #3,(a2)
          add.w     #24,a2
          dbra      d0,regen3
          bra.s     regen2
regen4    move.l    menu_adr,a0         ++ Rahmen erzeugen ++
          bset.b    #3,1643(a0)
          move.b    mrk+ov,d0
          beq.s     regen6
          bclr.b    #3,1643(a0)         Wegwerfen enabeln
          bclr.b    #3,1667(a0)
regen6    add.w     #1739,a0
          moveq.l   #7,d0
regen5    bclr.b    #3,(a0)
          add.w     #24,a0
          dbra      d0,regen5
regen2    bsr       men_inv
          bra       win_rdw
          ;
zwei_1b   cmp.b     #$1b,d0
          bne       zwei_19
          move.w    (a4),d0             --- Drucken ---
          bmi       men_inv
          moveq.l   #1,d0
          lea       stralpr2,a0
          bsr       alertbox
          cmp.w     #1,d0
          bne       men_inv
druck6    move.w    #$11,-(sp)          Drucker angeschlossen ?
          trap      #1
          addq.l    #2,sp
          tst.w     d0
          bmi.s     druck4
          moveq.l   #1,d0
          lea       stralpr1,a0         nein -> Warten
          bsr       alertbox
          cmp.w     #1,d0
          bne       men_inv
          bra       druck6
druck4    lea       form_buf,a5         Clipping-rectangle berechnen
          move.b    frdrucke+7,d0
          bne.s     druck21
          clr.l     (a5)                Total
          move.l    #$27f018f,4(a5)
          bra.s     druck20
druck21   cmp.b     #1,d0
          bne.s     druck22
          move.l    fenster(a4),d0      Fenster
          move.l    fenster+4(a4),d1
          add.w     yx_off(a4),d0
          add.l     yx_off+2(a4),d0
          add.l     d0,d1
          sub.l     #$10001,d1
          move.l    d0,(a5)
          move.l    d1,4(a5)
          bra.s     druck20
druck22   moveq.l   #3,d2               Koordinaten
          lea       contrl,a5
          bsr       get_koos
          cmp.w     #7,d4               Abbruch-Taste ?
          beq       men_inv
          lea       form_buf,a5
          move.l    last_koo,(a5)
          move.l    last_koo+4,4(a5)
druck20   lea       contrl,a5
          bsr       maus_bne
          lea       form_buf,a5
          move.l    bild_adr(a4),a6
          lea       escfeed,a2          Druckzeilenabstand = 1/8 inch
          bsr       prtout
          move.b    frdrucke+5,d0       Hoch- oder Querformat ?
          bne.s     druck10
          sub.l     a3,a3               +++ Hochformat +++
          move.w    2(a5),d0
          move.w    d0,a4               A3/A4: X/Y-Koordinate
          mulu.w    #80,d0
          add.w     d0,a6
druck5    moveq.l   #79,d6              80 Zeichen pro Zeile a 8 Pixel
          lea       stack,a0
druck3    move.w    #128,d4             Pos im Zeichen, horizontal
druck7    moveq.l   #1,d5               Pinnummer und -zÑhler
          clr.w     d1                  Sendebyte
          move.w    a3,d0
          cmp.w     (a5),d0             X-Pos im clip-rec ?
          blo.s     druck8
          cmp.w     4(a5),d0
          bhi.s     druck9
          add.w     #640,a6             Offset zu A6 im Byte
          addq.w    #8,a4
druck2    sub.w     #80,a6
          subq.w    #1,a4
          move.b    (a6),d0
          and.b     d4,d0
          beq.s     druck1
          move.w    a4,d0               Y-Pos im clip-rec ?
          cmp.w     6(a5),d0
          bhi.s     druck1
          or.b      d5,d1
druck1    lsl.b     #1,d5               nÑchster Pixel vertikal
          bcc       druck2
druck8    move.b    d1,(a0)+
druck9    addq.w    #1,a3
          lsr.b     #1,d4               nÑchster Pixel horizontal
          bcc       druck7
          addq.l    #1,a6               nÑchstes Byte
          dbra      d6,druck3
          bsr       druck30             Zeile ausdrucken
          add.w     #560,a6             nÑchste Zeile
          addq.w    #8,a4
          sub.l     a3,a3
          move.w    a4,d0               Y-mÑûig noch im clip-rec ?
          cmp.w     6(a5),d0
          bls       druck5
          lea       contrl,a5           Zeiger regenerieren
          lea       intin,a6
          bsr       maus_neu
          bra       men_inv
          ;
druck10   move.w    (a5),d0             +++ Querformat +++
          move.w    d0,d3
          lsr.w     #3,d3
          and.w     #7,d0
          lea       drucktab,a0
          move.b    (a0,d0.w),(a5)      (A5): Maske linker Rand
          move.w    4(a5),d0
          move.w    d0,d4
          lsr.w     #3,d4               D3/4: Byte-Min/Max
          and.w     #7,d0
          move.b    8(a0,d0.w),1(a5)    1(a5): Maske rechter Rand
          move.w    6(a5),d0
          move.w    d0,d1
          sub.w     2(a5),d0            Y-clipping umrechnen
          move.w    d0,2(a5)
          mulu.w    #80,d1
          add.w     #81,d1
          move.w    d1,4(a5)            4(A5): Zeilenende-Offset
          move.w    d4,d7
          add.w     d4,a6
druck11   cmp.b     d3,d7               X-Pos im clip-rec ?
          blo.s     druck15             nein -> fertig
          lea       stack,a0
          move.w    6(a5),d6
druck12   clr.b     d0
          cmp.w     2(a5),d6            Y-Pos im clip-rec ?
          bhi.s     druck14
          move.b    (a6),d0
          cmp.b     d3,d7               Byte X-mÑûig clippen
          bne.s     druck13
          and.b     (a5),d0
druck13   cmp.b     d4,d7
          bne.s     druck14
          and.b     1(a5),d0
druck14   moveq.l   #7,d1
druck17   lsr.b     #1,d0               Byte spiegeln
          roxl.b    #1,d2
          dbra      d1,druck17
          move.b    d2,(a0)+
          add.w     #80,a6              nÑchste Scanline
          dbra      d6,druck12
          bsr.s     druck30             Zeile ausdrucken
          sub.w     4(a5),a6            nÑchste Spalte
          dbra      d7,druck11
druck15   lea       contrl,a5
          lea       intin,a6
          bsr       maus_neu
          bra       men_inv
          ;
druck30   move.l    a0,-(sp)            +++ Graphikzeile drucken +++
          move.w    #-1,-(sp)
          move.w    #11,-(sp)           kbshift
          trap      #13
          addq.l    #4,sp
          btst      #3,d0               Alternate gedrÅckt ?
          beq.s     druck37
          moveq.l   #2,d0               -> "Druck abbrechen ?"
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
          move.l    a0,d5               LÑnge der Zeile berechnen
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
          lea       eschigh,a2          Header senden
          move.w    d0,2(a2)
          move.w    d5,-(sp)
          moveq.l   #3,d5
druck40   clr.w     d0
          move.b    (a2)+,d0
          bsr       chrout
          dbra      d5,druck40
          move.w    (sp)+,d5
          lea       stack,a2
druck32   clr.w     d0                  Graphik senden
          move.b    (a2),d0
          bsr       chrout
          btst      #1,d6               1: Flag fÅr Verdopplung
          bne.s     druck36
          btst      #0,d6               0: Flag fÅr nicht-verÑnd.
          beq.s     druck34
          btst      #2,d6               2: Flag fÅr jedes 2. Byte
          beq.s     druck35
druck36   bchg      #3,d6               3: Flag fÅr Wiederholung
          bne       druck32
druck35   bchg      #2,d6
druck34   addq.l    #1,a2
          dbra      d5,druck32
druck33   moveq.l   #13,d0
          bsr       chrout
          moveq.l   #10,d0
          bra       chrout
          ;
zwei_19   cmp.b     #$19,d0
          beq.s     save18
          cmp.b     #$1a,d0
          bne       men_inv
save18    move.b    frdatei+33,d0       --- (Ab-)Speichern ---
          bne       save3
          move.b    frdatei+35,d0       +++ Format OHNE +++
          bne.s     save4
          move.l    #32000,d7           Total
          move.l    bild_adr(a4),a3
save_all  clr.l     d6
          bsr       save_opn
          bsr       maus_bne
          move.l    a3,-(sp)
          move.l    d7,-(sp)
          bra       save_wrt
save4     cmp.b     #2,d0
          bne.s     save5
          moveq.l   #3,d2               Koordinaten
          bsr       get_koos
          cmp.w     #7,d4
          beq       men_inv
          move.l    (a1),d4
          move.l    4(a1),d5
          bra.s     save7
save5     move.l    fenster(a4),d4      Fenster
          move.l    fenster+4(a4),d5
          add.w     yx_off(a4),d4
          add.l     yx_off+2(a4),d4
          add.l     d4,d5
          sub.l     #$10001,d5
save7     move.l    d5,d2
          sub.l     d4,d2
          add.l     #$10001,d2          D2: Breite/Hîhe
          move.l    d2,d0
          swap      d0
          cmp.b     #2,frdatei+33       LOGO-Format ?
          bne.s     save14
          and.w     #15,d0              geht Breite in Wîrtern auf ?
          beq.s     save8
          and.l     #$3f003ff,d2
          add.l     #$100000,d2
          bra.s     save8
save14    and.w     #7,d0               geht Breite in Bytes auf ?
          beq.s     save8
          lea       stralbyt,a0
          moveq.l   #1,d0
          bsr       alertbox            "Runden ?"
          cmp.w     #2,d0
          beq       men_inv             Abbruch
          and.l     #$3f803ff,d2
          add.l     #$80000,d2
save8     cmp.l     #$2800000,d2        640 Pixel breit ?
          blo.s     save10
          move.w    d2,d7               -> Total-Routine verwenden
          mulu.w    #80,d7
          move.l    bild_adr(a4),a3
          mulu.w    #80,d4
          add.l     d4,a3
          bra       save_all
save10    lea       form_buf,a0         Grîûe retten
          move.l    d2,(a0)
          move.w    d2,d6               D6: RAM-Bedarf
          mulu.w    #80,d6
          bsr       save_opn            Datei kreieren
          move.l    a3,-(sp)
          move.l    d4,d0
          move.l    d5,d1
          clr.l     d2                  Bild in Buffer kopieren
          move.l    bild_adr(a4),a0
          move.l    a3,a1               A3: Scratch-Buffer
          bsr       copy_blk
          bsr       maus_bne            Biene-Maus
          cmp.b     #2,frdatei+33
          bne.s     save13
          lea       logo_buf,a0         LOGO -> Header speichern
          moveq.l   #10,d0
          bsr       save_dat
save13    move.w    form_buf,d0
          lsr.w     #3,d0
          move.l    (sp),a0             Bild komprimieren
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
          move.w    #$49,-(sp)          (Adr schon auf Stack)
          trap      #1
          addq.l    #2,sp
          move.w    form_buf,d0
          lsr.w     #3,d0
          mulu.w    form_buf+2,d0       +++ Daten abspeichern +++
          move.l    d0,-(sp)
save_wrt  move.w    handle,-(sp)
          move.w    #$40,-(sp)
          trap      #1
          add.w     #12,sp
          tst.l     d0                  Fehler ?
          bpl.s     save1
          bsr       tos_err
          bra.s     save2
save1     and.b     #%11110101,info(a4) Fenster-sicher-Flag
save2     move.w    handle,-(sp)        ;close
          move.w    #$3e,-(sp)
          trap      #1
          addq.l    #4,sp
          bsr       maus_neu            Norm-Maus
          bra       men_inv
save_opn  move.l    bild_adr(a4),a0     +++ Filenamen holen +++
          add.w     #32010,a0
          moveq.l   #-1,d3              D3: Parameter fÅr itemslct
          move.l    a0,a2
save_op4  move.b    (a0)+,d0
          beq.s     save_op3
          cmp.b     #'\',d0
          bne       save_op4
          move.l    a0,a2
          bra       save_op4
save_op3  lea       filename,a0
save_op5  move.b    (a2)+,(a0)+
          bne       save_op5
save_op6  cmp.w     #$1a,msg_buff+8     "Abspeichern" ?
          bne.s     save_op7
          move.l    bild_adr(a4),a2
          add.w     #32010,a2
          tst.b     (a2)
          beq.s     save_op7
          moveq.l   #$7f,d3
          bsr       itemauto
          bra.s     save_op8
save_op7  bsr       itemslct            Dateiname erfragen
save_op8  tst.b     d0
          bne.s     save_op1
          tst.l     d6                  +++ Scratch-Buffer holen +++
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
          tst.l     d0                  Fehler ?
          bmi.s     save_op2
          move.w    d0,handle
          move.l    bild_adr(a4),a0
          add.w     #32010,a0
          tst.b     (a0)                Titel schon gesetzt ?
          beq       set_name
          rts
save_op2  addq.l    #4,sp               Fehlernummer ausgeben
          bra       tos_err
save_op1  addq.l    #4,sp               Abbruch
          bra       men_inv
save3     cmp.b     #2,d0
          bne.s     save15
          lea       logo_buf,a3         +++ Format LOGO +++
          move.w    #1,(a3)
          move.l    fenster(a4),2(a3)
          move.l    fenster+4(a4),6(a3)
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
          moveq.l   #15,d3              col-pal speichern
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
          bsr.s     save_dat            Header speichern
          move.l    bild_adr(a4),-(sp)
          move.l    #32000,-(sp)        Bild speichern
          bra       save_wrt
save_dat  move.l    a0,-(sp)            +++ Daten abspeichern +++
          move.l    d0,-(sp)
          move.w    handle,-(sp)
          move.w    #$40,-(sp)
          trap      #1
          add.w     #12,sp
          rts
          ;
nr_drei   cmp.l     #$60000,d0
          bhs       nr_vier
          cmp.b     #$2e,d0             ******** Figuren-MenÅ ********
          bhs       drei_2e
          move.w    d0,d2               --- Figur auswÑhlen ---
          move.w    choofig,d0
          cmp.w     #$43,d0
          bne.s     drei_chg
          bsr       over_que            "Markieren beenden" ?
          bne       men_inv
          move.w    d2,-(sp)
          bsr       fram_del
          move.w    (sp)+,d2
drei_chg  move.w    choofig,d0          alte Figur disabeln
          clr.w     d1
          bsr       check_xx
          move.w    d2,d0               neue enabeln
          lea       choofig,a0
          move.w    d2,(a0)
          moveq.l   #1,d1
          bsr       check_xx
          lea       chootab,a0
          cmp.b     #$43,d2
          bhs.s     figur1
          cmp.b     #$2c,d2
          beq.s     figur1
          cmp.b     #$26,d2
          bls.s     figur1
          addq.l    #1,a0
          cmp.b     #$28,d2
          bls.s     figur1
          addq.l    #1,a0
          cmp.b     #$29,d2
          beq.s     figur1
          addq.l    #1,a0
figur1    moveq.l   #3,d0               entspr. Attribute enabeln
          move.l    menu_adr,a3
          add.w     #1115,a3            Adr. der Status: 43*24+11
figur2    bset      #3,(a3)
          btst.b    d0,(a0)
          beq.s     figur3
          bclr      #3,(a3)
figur3    add.w     #24,a3
          dbra      d0,figur2
          bsr       koo_chk             "Koordinaten"-Status setzen
          bra       men_inv
          ;
drei_2e   cmp.w     #$31,d0
          beq.s     drei_31
          move.w    d0,d1               --- Attribute umschalten ---
          move.w    d0,d2
          sub.w     #$2e,d1
          lsl.w     #1,d1
          lea       chooset,a0
          add.w     d1,a0
          move.w    (a0),d1
          eor.b     #1,d1
drei_11   move.w    d1,(a0)
          bsr       check_xx
          lea       chooset,a0
          tst.w     (a0)
          bne       men_inv
          tst.w     4(a0)
          bne       men_inv
          moveq.l   #1,d1
          eor.b     #$1e,d2
          move.w    d2,d0
          sub.b     #$2e,d2
          lsl.w     #1,d2
          move.w    d1,(a0,d2.w)
          bsr       check_xx
          bra       men_inv
          ;
drei_31   moveq.l   #2,d2               --- Segment ---
          lea       frsegmen,a2
          bsr       form_do
          bsr       form_del
          move.w    frsegmen+6,d3       Winkel-10tel errechnen
          mulu.w    #10,d3
          add.w     frsegmen+20,d3
          swap      d3
          move.w    frsegmen+34,d4
          mulu.w    #10,d4
          add.w     frsegmen+48,d4
          move.w    d4,d3
          lea       chooseg,a0
          move.l    d3,(a0)
          moveq.l   #1,d1
          cmp.l     #360,d3             Vollen Kreis malen(0-360)?
          bne.s     segmen1
          clr.w     d1
segmen1   lea       chooset+6,a0        nein -> Segment-Eintrag..
          move.w    d1,(a0)
          moveq.l   #$31,d0
          bsr       check_xx            ..abhaken
          bra       men_inv
          ;
*----------------------------------------------------------SUBROUTINEN
prtout    clr.w     d0                  ** String an Drucker senden **
          move.b    (a2)+,d0
          beq.s     prtout1             zero-terminated -> fertig
          bsr.s     chrout
          tst.w     d0
          bne       prtout
prtout1   rts
          ;
chrout    move.w    d0,-(sp)            ** 1 Zeichen ausdrucken **
          move.w    #5,-(sp)
          trap      #1
          addq.l    #4,sp
          rts
          ;
koo_chk   move.l    menu_adr,a0         "Koordinaten" en-/disabeln
          bclr.b    #3,2075(a0)
          move.w    choofig,d0
          cmp.b     #$55,d0
          beq.s     koo_chk2
          cmp.b     #$43,d0
          beq       exit
          lea       koanztab,a1
          sub.w     #$1f,d0
          tst.b     (a1,d0.w)
          bne       exit
koo_chk2  bset.b    #3,2075(a0)
          rts
          ;
wind_chg  btst.b    #1,info(a4)         ** Bild bearbeitet ? **
          bne.s     wind_ch1
          move.w    drawflag,d0
          beq.s     wind_ch1
          bchg.b    #3,info(a4)
          bchg.b    #3,info(a4)
wind_ch1  rts
          ;
over_que  move.w    mark_buf,d0         ** "Ausschnitt einfÅgen" ? **
          beq       exit
          move.b    mrk+ov,d0
          beq       exit
          move.b    mrk+chg,d0
          beq       exit
          moveq.l   #1,d0
          lea       stralovq,a0
          bsr.s     alertbox
          cmp.w     #1,d0
          rts
alertbox  ;
          aes       52 1 1 1 0 !d0 !a0  ** AES-Alertbox ausfÅhren **
          move.w    intout,-(sp)
          bsr       maus_neu
          lea       intout,a0
          move.w    (sp)+,d0
          move.w    d0,(a0)             Exit-Taste nach D0
          rts
          ;
itemslct  lea       directory,a2        ** Item-Selector **
          aes       90 0 2 2 0 !a2 filename
          cmp.w     #1,intout+2
          bne.s     itemserr
itemauto  cmp.b     #':',1(a2)
          bne.s     items1
          move.b    (a2),d0             Drive setzen
          sub.b     #'A',d0
          move.w    d0,-(sp)
          move.w    #$e,-(sp)
          trap      #1
          addq.l    #4,sp
          addq.l    #2,a2
items1    move.l    a2,a0               Pfad setzen
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
          pea       dta                 DTA-Buffer setzen
          move.w    #$1a,-(sp)
          trap      #1
          addq.l    #6,sp
          clr.w     -(sp)               Datei suchen
          pea       filename
          move.w    #$4e,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.w     d0                  existiert die Datei ?
          beq.s     items4
          tst.w     d3                  + Nein +
          bne.s     itemsok             Speichern -> Egal
          lea       stralnof,a0
          moveq.l   #2,d0               "Nicht gefunden"
          bsr       alertbox
          cmp.w     #1,d0
          beq       itemslct
itemserr  moveq.l   #-1,d0
          rts
items4    tst.w     d3                  + Ja +
          beq.s     itemstak            Laden -> Ok
          lea       stralfsd,a0         "Datei Åberschreiben ?"
          moveq.l   #1,d0
          bsr       alertbox
          cmp.w     #1,d0
          bne       itemserr
itemstak  moveq.l   #7,d0               Filenamen kopieren
          lea       dta+30,a0
          lea       filename,a1
items5    move.b    (a0)+,(a1)+
          dbra      d0,items5
itemsok   clr.b     d0                  D0 = 0 -> Ok
          rts
          ;
set_name  move.l    bild_adr(a4),a0     ** Fenstertitel setzen **
          add.w     #32010,a0
          lea       director,a1
          move.l    a0,a2
set_nam1  move.b    (a1)+,d0            Drive und Pfadname
          move.b    d0,(a0)+
          beq.s     set_nam2
          cmp.b     #'\',d0
          bne       set_nam1
          move.l    a0,a2
          bra       set_nam1
set_nam2  move.l    a2,a0
          lea       filename,a1
set_nam3  move.b    (a1)+,(a0)+         File-Name
          bne       set_nam3
          move.l    bild_adr(a4),a0
          add.w     #32010,a0
          tst.b     (a0)
          beq.s     name_xx
          move.l    menu_adr,a1         Abspeichern enabeln
          bclr.b    #3,635(a1)
name_xx   move.l    a0,4(a6)
          aes       105 4 1 0 0 !(a4) 2  ;wind_set: Fenstertitel
          rts
          ;
get_koos  lea       frkoordi,a2         ** Koordinaten erfragen **
          moveq.l   #3,d1
          bsr       rsrc_gad
          move.l    addrout,a3
          bsr       init_ted            Adressen im TED-Record setzen
          addq.l    #2,a2
          move.w    #8,128(a3)
          lea       last_koo,a1
          move.w    d2,-(sp)
          cmp.w     #1,d2
          bhi.s     get_koo1
          addq.l    #4,a1
          move.w    #128,128(a3)
get_koo1  move.l    ted_adr(a2),a0
          move.w    (a1)+,d0
          move.w    d0,ted_val(a2)
          bsr       form_wrt            Pos. in Formular eintragen
          add.w     #14,a2
          dbra      d2,get_koo1
          moveq.l   #3,d2
          lea       frkoordi,a2
          bsr       form_do
          bsr       form_del
          lea       last_koo,a1
          move.w    (sp)+,d2
          cmp.w     #1,d2               nur ein Koordinatenpaar ?
          bhi.s     get_koo3
          sub.w     #28,a2
          bra.s     get_koo4
get_koo3  move.w    6(a2),(a1)
          move.w    20(a2),2(a1)
get_koo4  move.w    34(a2),4(a1)
          move.w    48(a2),6(a1)
          rts
*--------------------------------------------------------MENU-VARIABLE
choofig   dc.w   $1f
chooseg   dc.w   0,3600
chooset   dc.w   0,0,1,0
chootab   dc.b   %0000,%1110,%1010,%1011
now_offs  dc.w   539,72,48,1344,24
*--------------------------------------------------------------STRINGS
nulstr    dc.b   0,0
directory ds.w   35
filename  dcb.w  7,0
stralneu  dc.b   91,49,93,91,'Ihre Arbeit wird so vernichtet !'
          dc.b   93,91,'Ok|Abbruch',93,0,0
stralnof  dc.b   91,50,93,91,'Datei nicht gefunden...|Eine andere D'
          dc.b   'atei laden ?',93,91,'Ja|Nein',93,0,0
stralnds  dc.b   91,51,93,91,'Auf der Disk ist nicht mehr|genug fre'
          dc.b   'ier Speicher|vorhanden !',93,91,'Abbruch',93,0,0
stralfsd  dc.b   91,49,93,91,'Damit  verwerfen Sie|den Inhalt der '
          dc.b   'Datei|gleichen Namens!',93,91,'Ok|Abbruch',93,0
stralbyt  dc.b   91,50,93,91,'Breite auf Bytes runden...?',93,91
          dc.b   'Ok|Abbruch',93,0,0
stralbad  dc.b   91,50,93,91,'Fehlerhaftes Format !!',93,91
          dc.b   'Abbruch',93,0,0
stralnow  dc.b   91,51,93,91,'Nur 7 Fenster mîglich...|Schlieûen'
          dc.b   ' Sie ein anderes',93,91,'Abbruch',93,0,0
stralpr1  dc.b   91,50,93,91,'Der Drucker ist nicht an !',93,91
          dc.b   'Ok|Abbruch',93,0,0
stralpr2  dc.b   91,49,93,91,'Starten Sie mit Return|Unterbreche'
          dc.b   'n mit Alternate',93,91,'Ok|Abbruch',93,0,0
stralpr3  dc.b   91,51,93,91,'Druck abbrechen ?',93,91,'Ja|Wei'
          dc.b   'ter',93,0,0
stralwi7  dc.b   91,49,93,91,'Bei 7 Fenstern sind keine|Accessor'
          dc.b   'ies mîglich !',93,91,'Ok|Abbruch',93,0,0
stralnom  dc.b   91,51,93,91,'Der Arbeitsspeicher reicht nicht meh'
          dc.b   'r |fÅr dieses Fenster !',93,91,'Abbruch',93,0,0
stralovq  dc.b   91,49,93,91,'Sie fÅgen so den Ausschnitt|ein und Åberschreiben|den Hintergrund !!',93,91,'Ok|Abbruch',93,0,0
*------------------------------------------------------------------I/O
dta       ds.w   25
logo_buf  ds.w   5
handle    ds.w   1
escfeed   dc.b   27,65,8,0
eschigh   dc.w   $1b4c,0000,0
drucktab  dc.b   $ff,$7f,$3f,$1f,$0f,$07,$03,$01
          dc.b   $80,$c0,$e0,$f0,$f8,$fc,$fe,$ff
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
          movem.l   (sp)+,d0-d3/a0-a3
          rts
*raprts   movem.l   (sp)+,d0-d3/a0-a3
*         addq.l    #4,sp
*         bra       men_inv
          ;
          end
