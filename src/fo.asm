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
 module    MENU_3
 section   sechs
 pagelen   32767
 pagewid   133
 noexpand
 ;
 XREF  aescall,vdicall,contrl,intin,intout,ptsin,ptsout,addrin,addrout
 XREF  logbase,bildbuff,rec_adr,maus_rec,mark_buf,drawflag,rand_tab
 XREF  show_m,hide_m,save_buf,save_scr,win_rdw,copy_blk,alertbox
 XREF  cent_koo,form_buf,menu_adr,men_inv,mrk,over_cut,over_old
 XREF  win_xy,work_blk,form_do,frrotier,frzoomen,frzerren,frprojekt
 XREF  work_bl2,form_del,stack
 ;
 XDEF  fuenf_4c,sinus
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
          ;       *** Offsets zu Window-Records ***
bild_adr  equ  2   Adresse des Bildpuffers
yx_off    equ  16  Abstand Fensterursprung zu 0/0
fenster   equ  22  Pos. und Ausmaûe
          ;       *** Offsets zu Rahmen-Rec ***
copy      equ  0   Kopieren?
vmod      equ  1   akt. VerknÅpf-mode
einf      equ  2   Auss im Buff(Adr. drawflag+12)?
del       equ  5   alten Auss lîschen vor schub?
ov        equ  6   OV-Mode?
buff      equ  8   Adr. OV-Buffer
chg       equ  12  bearbeitet?
part      equ  13  öberhang?
modi      equ  14  VerknÅpfungsmodi akt/letzter Auss
old       equ  16  öberhang-->alte Koo/Offset
*-------------------------------------------------MENö-HANDLER(Forts.)
fuenf_4c  cmp.b     #$4c,d0
          bne       fuenf_4d
          move.w    mark_buf,d0         --- Rotieren ---
          beq       men_inv
          bsr       over_cut
          lea       frrotier,a2
          moveq.l   #18,d2
          bsr       form_do
          bsr       form_del
          cmp.b     #14,d4              Abbruch ?
          beq       men_inv
          bsr       over_old            +++ Fix-Winkel +++
          bsr       save_scr
          bsr       save_buf
          move.w    frrotier+6,d0       Sin/Cos berechnen
          lsl.w     #1,d0
          lea       sinus,a0
          move.w    (a0,d0.w),d1
          neg.w     d0
          add.w     #180,d0
          move.w    (a0,d0.w),d0
          move.l    bildbuff,a0
          move.l    bild_adr(a4),a1
          lea       stack,a4
          bsr       rota_aus
          ;
          lea       drawflag,a0         RÅckgÑngig enabeln
          move.w    #-1,(a0)
          move.l    menu_adr,a0
          bclr.b    #3,491(a0)
          lea       mrk,a0              kurzer Overlay-Mode
          move.w    #$ff,einf(a0)
          move.b    #-1,del(a0)         vor schub alten Auss. lîschen
          bsr       men_inv
          bra       win_rdw
          ;
fuenf_4d  cmp.b     #$4d,d0
          bne       fuenf_4e
          move.w    mark_buf,d0         --- Zoomen ---
          beq       men_inv
          bsr       over_cut
          lea       frzoomen,a2
          moveq.l   #19,d2
          bsr       form_do
          bsr       form_del
          cmp.b     #14,d4
          beq       men_inv
          move.b    frzoomen+65,d0      Manuell ?
          beq       zoom3
          lea       mark_buf+2,a2       +++ Fix-Faktor +++
          lea       stack,a3
          move.w    4(a2),d0            X-Differenz
          sub.w     (a2),d0
          move.w    d0,d1
          move.w    d0,d2
          mulu      frzoomen+6,d0
          mulu      frzoomen+20,d1
          divu      #1000,d1
          add.w     d1,d0
          clr.b     d7                  D7: GrenzÅberschreitung
          cmp.w     #639,d0
          bls.s     zoom31
          moveq.l   #-1,d7
          move.w    #639,d0
zoom31    move.w    d0,d5               D5: Breite
          sub.w     d2,d0
          move.w    d0,18(a3)
          move.w    6(a2),d0            Y-Differenz
          sub.w     2(a2),d0
          move.w    d0,d1
          move.w    d0,d2
          mulu      frzoomen+34,d0
          mulu      frzoomen+48,d1
          divu      #1000,d1
          add.w     d1,d0
          cmp.w     #399,d0
          bls.s     zoom32
          move.w    #399,d0
          moveq.l   #-1,d7
zoom32    move.w    d0,d6               D6: Hîhe
          sub.w     d2,d0
          move.w    d0,20(a3)
          tst.b     d7
          beq.s     zoom34
          moveq.l   #1,d0               Warnung: "Faktor beschnitten"
          lea       stralzoo,a0
          bsr       alertbox
          cmp.b     #1,d0
          bne       men_inv
zoom34    bsr       over_old
          bsr       save_scr
          lea       drawflag+4,a0
          lea       mark_buf+2,a1
          move.l    (a1)+,(a0)+
          move.l    (a1),(a0)
          move.w    d5,(a1)+
          move.w    d6,(a1)
          bsr       manu_en2
          bra       zoom35
          ;
zoom3     clr.l     d7                  +++ Manuell +++
          bsr       manu_pre
zoom1     bsr       manu_mak
          bne       zoom4
          lea       mark_buf+6,a0
          move.w    drawflag+8,d2
          sub.w     drawflag+4,d2
          move.w    drawflag+10,d3
          sub.w     drawflag+6,d3
          move.w    maus_rec+12,d4
          move.w    maus_rec+14,d5
          move.l    frzoomen+60,d6
          and.l     #$f000f,d6
          cmp.l     #10000,d6           équivalent strecken ?
          bls.s     zoom8
          clr.l     d6
          move.w    d4,d0
          move.w    d5,d1
          ext.l     d0
          ext.l     d1
          divu      d2,d0               D0/D1: X/Y-Faktor
          divu      d3,d1
          swap      d0
          swap      d1
          cmp.l     d0,d1               kleineren Faktor nehmen
          bhs.s     zoom9
          move.w    d2,d4
          mulu      d5,d4
          divu      d3,d4
          bra.s     zoom8
zoom9     beq.s     zoom8
          move.w    d3,d5
          mulu      d4,d5
          divu      d2,d5
zoom8     move.w    d5,d1
          tst.b     d6                  D1: Y-Differenz
          beq.s     zoom5
          move.w    d3,d1
zoom5     move.w    d1,2(a0)
          sub.w     d3,d1
          move.w    d4,d0               D0: X-Differenz
          cmp.l     #$ffff,d6
          bls.s     zoom7
          move.w    d2,d0
zoom7     move.w    d0,(a0)
          sub.w     d2,d0
          move.l    rec_adr,a0
          move.l    bild_adr(a0),a0
          move.l    bildbuff,a1
          move.w    d0,18(a4)
          move.w    d1,20(a4)
          bsr       zoom_aus            Auss neu erzeugen
          bra       zoom1
          ;
zoom4     bsr       manu_end            +++ Neuen Auss einfÅgen +++
          cmp.l     #$80008000,18(a4)
          bne.s     zoom35
          lea       mark_buf+2,a0
          move.l    drawflag+4,(a0)+
          move.l    drawflag+8,(a0)
          bra.s     zoom36
zoom35    lea       drawflag+4,a2
          move.l    (a2)+,d0
          sub.l     d0,(a2)
          addq.l    #2,a2
          lea       stack,a3
          clr.l     (a3)
          move.l    mark_buf+6,d2
          bsr       cent_koo            neue Pos
          lea       mark_buf+2,a0
          move.l    d0,(a0)+
          move.l    d1,(a0)
          clr.w     d3                  neue Auss-Pos lîschen
          move.l    bild_adr(a4),a0
          bsr       work_bl2
          lea       drawflag,a0
          move.w    #-1,(a0)            RÅckgÑngig enabeln
          move.l    4(a0),d0
          add.l     d0,8(a0)
          move.l    bildbuff,a0         Zoom-Parameter
          move.l    bild_adr(a4),a1
          lea       stack,a4
          move.w    18(a4),d0
          move.w    20(a4),d1
          bsr       zoom_aus            Auss zoomen
          move.l    rec_adr,a4
          move.l    menu_adr,a0         Flags setzen
          bclr.b    #3,491(a0)
          lea       mrk,a0
          move.w    #$ff,einf(a0)
          move.b    #-1,del(a0)
zoom36    bsr       men_inv
          bra       win_rdw
          ;
fuenf_4e  cmp.b     #$4e,d0
          bne       fuenf_4f
          move.w    mark_buf,d0         --- Verzerren ---
          beq       men_inv
          bsr       over_cut
          lea       frzerren,a2
          moveq.l   #20,d2
          bsr       form_do
          bsr       form_del
          cmp.b     #17,d4
          beq       men_inv
          move.l    #$27f018f,d7        D7: zentrierte Pos
          sub.l     mark_buf+6,d7
          add.l     mark_buf+2,d7
          lsr.l     #1,d7
          bclr      #15,d7
          bsr       manu_pre
zerr2     bsr       manu_mak            +++ Warteschleife +++
          bne.s     zerr1
          move.l    rec_adr,a0
          move.l    bild_adr(a0),a0
          move.l    bildbuff,a1
          bsr       zerr_aus
          bra       zerr2
zerr1     clr.l     18(a4)
          bsr       manu_end
          lea       mark_buf,a0         Flags setzen
          clr.w     (a0)+
          move.l    #-1,(a0)+
          move.l    #-1,(a0)
          move.l    menu_adr,a0
          bclr.b    #3,491(a0)
          lea       drawflag,a0
          move.w    #-1,(a0)
          bsr       men_inv
          bra       win_rdw
          ;
fuenf_4f  cmp.b     #$4f,d0
          bne       men_inv
          move.w    mark_buf,d0         --- Projezieren ---
          beq       men_inv
          bsr       over_cut
          lea       frprojek,a2
          moveq.l   #21,d2
          bsr       form_do
          bsr       form_del
          cmp.b     #14,d4
          beq       men_inv
          bsr       over_old
          bsr       save_scr
          bsr       save_buf
          bra       men_inv
*----------------------------------------------------------SUBROUTINEN
          ;
zoom_aus  move.w    drawflag+4,d2       ** Auss zoomen **
          and.w     #$1f,d2
          move.w    #31,(a4)            { Parameter: A0,A1,A4,D0,D1 }
          sub.w     d2,(a4)
          move.w    mark_buf+2,d2       Start-Bit-Nr
          and.w     #$1f,d2
          move.w    #31,2(a4)
          sub.w     d2,2(a4)
          move.w    drawflag+8,d2       Breite/Hîhe
          sub.w     drawflag+4,d2
          move.w    d2,4(a4)
          move.w    drawflag+10,d7
          sub.w     drawflag+6,d7
          move.w    d0,d4               StreckabstÑnde und -faktoren
          move.w    d2,d3
          addq.w    #1,d3
          bsr       zoom_div
          move.w    d6,8(a4)
          move.l    d3,10(a4)
          move.w    d1,d4
          move.w    d7,d3
          addq.w    #1,d3
          bsr       zoom_div
          move.w    d6,6(a4)
          move.l    d3,14(a4)
          move.w    drawflag+6,d0    *********************************
          mulu.w    #80,d0           ** R0/1:  Q/Z-Anfang-Bit-Nr.
          add.l     d0,a0            ** R2:    Breite-1
          move.w    drawflag+4,d0    ** R3/4:  Speicher Zei/Pix-Faktor
          lsr.w     #3,d0            ** R5/7:  ZÑhl-Max-Streckdiff.P/Z
          and.w     #$fc,d0          ** D0/1:  Zw-Speicher Q/Z-Long
          add.w     d0,a0            ** D2/3:  Maske Quelle/Ziel
          move.w    mark_buf+4,d0    ** D4/5:  Streckdiff Pixel/Zeile
          mulu.w    #80,d0           ** D6,lo: Zeile-Faktor-Dbra
          add.l     d0,a1            **    hi: Pix-Faktor-Dbra
          move.w    mark_buf+2,d0    ** D7,lo: Hîhen-Dbra
          lsr.w     #3,d0            **    hi: Breite-Dbra
          and.w     #$fc,d0          ** A0/1:  Zeiger Quelle/Ziel
          add.w     d0,a1            ** A2/3:  Zw.Speicher Q/Z-Zeiger
          move.l    14(a4),d5        ** A4:    Zeiger Daten-Record
          add.l     #10000,d5        *********************************
zoom16    swap      d7                  ++ Schleife ++
          move.w    6(a4),d6
          bmi.s     zoom18
zoom14    move.w    4(a4),d7
          move.w    2(a4),d3
          move.w    (a4),d2
          move.l    a0,a2
          move.l    a1,a3
          move.l    (a1),d1
          move.l    (a0)+,d0
          move.l    10(a4),d4
          add.l     #10000,d4
          swap      d6
zoom15    move.w    8(a4),d6            + Zeilen-Schleife +
          bmi.s     zoom17
zoom13    btst      d2,d0
          beq.s     zoom10
          bset      d3,d1
zoom10    subq.w    #1,d3
          bpl.s     zoom11
          move.l    d1,(a1)+
          moveq.l   #31,d3
          clr.l     d1
zoom11    dbra      d6,zoom13           hor. Streckung
zoom17    add.l     #10000,d4
          bmi.s     zoom19
          clr.w     d6
          add.l     10(a4),d4
          bra       zoom13
zoom19    subq.w    #1,d2
          bpl.s     zoom12
          move.l    (a0)+,d0
          moveq.l   #31,d2
zoom12    dbra      d7,zoom15           + Zeilen-Ende +
          or.l      d1,(a1)
          lea       80(a3),a1
          move.l    a2,a0
          swap      d6
          dbra      d6,zoom14           vert. Streckung
zoom18    add.l     #10000,d5
          bmi.s     zoom101
          clr.w     d6
          add.l     14(a4),d5
          bra       zoom14
zoom101   add.w     #80,a0
          swap      d7
          dbra      d7,zoom16
exit      rts
          ;
zoom_div  move.w    d4,d6               ** D3/D4 auf 4 Dezimale **
          add.w     d3,d6
          add.w     d3,d6
          ext.l     d6
          divu      d3,d6
          subq.w    #2,d6
zoom_di3  tst.w     d4
          beq.s     zoom_di2
          bmi.s     zoom_di1
          sub.w     d3,d4
          bra       zoom_di3
zoom_di1  add.w     d3,d4
          addq.w    #1,d4               D3 := D3*10000/(D4+1)
          and.l     #$ffff,d3
          divu      d4,d3
          move.w    d3,d5
          mulu      #10000,d5
          swap      d3
          mulu      #10000,d3
          divu      d4,d3
          and.l     #$ffff,d3
          add.l     #10016,d3
          add.l     d5,d3
          neg.l     d3
          rts
zoom_di2  move.l    #-7000000,d3
          rts
          ;
manu_pre  bsr       over_old            ** Bildschirmwechsel **
          bsr       save_scr
          lea       drawflag+4,a0       (D7: Ausspos)
          lea       mark_buf+2,a1
          move.l    (a1),(a0)+
          move.l    d7,(a1)+
          move.l    (a1),(a0)
          move.w    #1999,d0
          move.l    bildbuff,a0
manu_pr1  clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,manu_pr1
          bsr       hide_m
          aes       107 1 1 0 0 3       ;wind_update
          aes       107 1 1 0 0 1
          move.w    #-1,-(sp)           ;set screen
          move.l    bildbuff,-(sp)
          move.l    bildbuff,-(sp)
          move.w    #5,-(sp)
          trap      #14
          add.w     #12,sp
          move.l    drawflag+4,d0       Auss einkopieren
          move.l    drawflag+8,d1
          move.l    mark_buf+2,d2
          move.l    bild_adr(a4),a0
          move.l    bildbuff,a1
          bsr       copy_blk
          lea       stack,a4            A4: Zeiger auf Datenrecord
          move.l    #$80008000,18(a4)
          lea       maus_rec,a0
          clr.w     20(a0)
          rts
          ;
manu_mak  bsr       show_m              ** Warte-Schleife **
          lea       maus_rec,a0
          clr.w     (a0)
manu_ma1  tst.b     21(a0)              fertig ?
          bne       exit
          tst.b     1(a0)               Mausclick erwarten
          beq       manu_ma1
          bsr       hide_m
          move.w    #1999,d0
          move.l    bildbuff,a0
manu_ma2  clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,manu_ma2
          clr.b     d0                  EQ: kein Abbruch
          rts
          ;
manu_end  bsr       hide_m              ** Alte Logbase **
          move.w    #-1,-(sp)
          move.l    logbase,-(sp)
          move.l    logbase,-(sp)
          move.w    #5,-(sp)            ;set_screen
          trap      #14
          add.w     #12,sp
          aes       107 1 1 0 0 2       ;wind_update
          aes       107 1 1 0 0 0
          move.l    rec_adr,a4
manu_en2  bsr       save_buf            altes Bild retten
          bsr       show_m
          cmp.l     #$80008000,18(a4)   keine Bearbeitung ?
          beq       exit
          move.l    drawflag+4,d0
          move.l    drawflag+8,d1
          clr.w     d3                  alten Auss lîschen
          move.l    bild_adr(a4),a0
          bra       work_bl2
          ;
zerr_aus  jsr       zerr_p1             ** Auss verzerren **
          move.w    drawflag+4,d2       Start-Bit-Nr.
          and.w     #$1f,d2
          move.w    #31,(a4)
          sub.w     d2,(a4)
          move.w    mark_buf+2,d2
          and.w     #$1f,d2
          move.w    #31,2(a4)
          sub.w     d2,2(a4)
          move.w    drawflag+8,d2       Breite/Hîhe
          sub.w     drawflag+4,d2
          move.w    d2,4(a4)
          move.w    drawflag+10,d7
          sub.w     drawflag+6,d7
          move.w    drawflag+6,d0       Zeiger
          mulu.w    #80,d0
          add.l     d0,a0
          move.w    drawflag+4,d0
          lsr.w     #3,d0
          and.w     #$fc,d0
          add.w     d0,a0
          move.w    mark_buf+4,d0
          mulu.w    #80,d0
          add.l     d0,a1
          move.w    mark_buf+2,d0       Breite kann neg sein
          asr.w     #3,d0
          and.w     #$fffc,d0
          add.w     d0,a1
zerr14    swap      d7                  ++ Schleife ++
          move.w    4(a4),d7
          move.w    2(a4),d3
          move.w    (a4),d2
          move.l    a0,a2
          move.l    a1,a3
          move.l    (a1),d1
          move.l    (a0)+,d0
zerr13    btst      d2,d0               + Zeilen-Schleife +
          beq.s     zerr10
          bset      d3,d1
zerr10    subq.w    #1,d3
          bpl.s     zerr11
          move.l    d1,(a1)+
          moveq.l   #31,d3
          clr.l     d1
zerr11    subq.w    #1,d2
          bpl.s     zerr12
          move.l    (a0)+,d0
          moveq.l   #31,d2
zerr12    dbra      d7,zerr13           + Zeilen-Ende +
          or.l      d1,(a1)
          lea       80(a2),a0
          lea       80(a3),a1
          jsr       zerr_d1             Verzerren
          swap      d7
          dbra      d7,zerr14
          rts
          ;
zerr_p1   move.w    maus_rec+12,d4      ## SchrÑgen ##
          move.w    d4,d0
          move.w    drawflag+8,d1       Neue X-Pos
          sub.w     drawflag+4,d1
          lsr.w     #1,d1
          sub.w     d1,d0
          lea       mark_buf+2,a2
          move.w    d0,(a2)
          moveq.l   #-1,d3              Steigung
          sub.w     #320,d4
          bpl.s     zerr_p11
          clr.w     d3
          neg.w     d4
zerr_p11  lsl.w     #1,d4
          move.w    d3,10(a4)           10: Richtung
          move.w    drawflag+10,d3
          sub.w     drawflag+6,d3
          bsr       zoom_div
          add.l     #10000,d3
          move.l    d3,6(a4)
          move.w    d6,d5
          and.w     #31,d5
          move.w    d5,12(a4)           12: delta A1
          lsr.w     #3,d6
          and.w     #$fc,d6             D6: delte D3
          move.l    d3,d4               D4: ZÑhler
          rts
zerr_d1   move.w    12(a4),d5           ## SchrÑgen ##
          add.l     #10000,d4
          bmi.s     zerr_d12
          addq.w    #1,d5
          add.l     6(a4),d4
zerr_d12  tst.w     10(a4)
          bmi.s     zerr_d11
          add.w     d6,a1               Rechts
          sub.w     d5,2(a4)
          bpl.s     zerr_d1e
          add.w     #31,2(a4)
          addq.l    #4,a1
          rts
zerr_d11  add.w     d5,2(a4)            Links
          sub.w     d6,a1
          cmp.w     #31,2(a4)
          bls.s     zerr_d1e
          sub.w     #32,2(a4)
          subq.l    #4,a1
zerr_d1e  rts
          ;
rota_aus  move.w    drawflag+4,d2       ** Auss Rotieren **
          move.w    d2,d3
          lsr.w     #3,d2               Quellzeiger
          and.w     #$fc,d2
          add.w     d2,a0
          and.w     #31,d3
          move.w    d3,2(a4)
          move.w    drawflag+10,d7
          move.w    drawflag+6,d2
          sub.w     d2,d7
          mulu.w    #80,d2
          add.l     d2,a0
          move.w    drawflag+8,d2
          sub.w     drawflag+4,d2
          move.w    d2,(a4)
          move.w    d2,d3               Neue x1-Koo
          muls.w    d0,d3
          move.w    d7,d4
          muls.w    d1,d4
          sub.l     d4,d3
          swap      d3
          neg.w     d3
          add.w     #320,d3
          move.b    d3,d4               Z-Zeiger
          lsr.w     #3,d3
          add.w     d3,a1
          and.w     #7,d4
          move.w    d4,4(a4)
          move.w    d7,d3               Neue y1-Koo
          muls.w    d0,d3
          muls.w    d1,d2
          sub.l     d2,d3
          swap      d3
          neg.w     d3
          add.w     #200,d3             Z-Zeiger
          mulu.w    #80,d3
          add.l     d3,a1
          tst.w     d0                  Steigungen
          bpl.s     rota_au1
          neg.w     d0
rota_au1  tst.w     d1
          bpl.s     rota_au2
          neg.w     d1
rota_au2  mulu      #10000,d0
          mulu      #10000,d1
          swap      d0
          swap      d1
          lsl.l     #1,d0
          lsl.l     #1,d1
          move.w    d0,d5
          move.w    d1,d6
          move.w    #-10000,d3
          move.w    d3,d4
rotate1   move.l    a0,a2               +++ Schleife +++
          move.l    a1,a3
          move.l    (a0)+,d0
          swap      d7
          move.w    (a4),d7
          move.w    2(a4),d1
          move.w    4(a4),d2
          swap      d3
          swap      d4
          move.w    #-10000,d3
          move.w    d3,d4
rotate2   btst      d1,d0               ++ Zeile-Schleife ++
          beq.s     rotate3
          bset.b    d2,(a1)
rotate3   add.w     d5,d3
          bmi.s     rotate4
          sub.w     #10000,d3
          subq.w    #1,d2
          bpl.s     rotate4
          moveq.l   #7,d2
          addq.l    #1,a1
          nop
          nop
rotate4   add.w     d6,d4
          bmi.s     rotate5
          sub.w     #10000,d4
          sub.w     #80,a1
rotate5   subq.w    #1,d1
          bpl.s     rotate6
          moveq.l   #32,d1
          move.l    (a0)+,d0
rotate6   dbra      d7,rotate2          ++ Zeilen-Ende ++
          lea       80(a2),a0
          move.l    a3,a1
          swap      d7
          swap      d3
          swap      d4
          add.w     d6,d3
          bmi.s     rotate7
          sub.w     #10000,d3
          subq.w    #1,4(a4)
          bpl.s     rotate7
          move.w    #7,4(a4)
          addq.l    #1,a1
          nop
          nop
rotate7   add.w     d5,d4
          bmi.s     rotate8
          sub.w     #10000,d4
          sub.w     #80,a1
rotate8   dbra      d7,rotate1
          rts
*--------------------------------------------------------------STRINGS
straldbr  dc.b   91,50,93,91,'Der Ausschnitt ist zu breit !|An welcher Seite abschneiden ?',93,91,'Links|Abbruch|Rechts',93,0,0
stralzoo  dc.b   91,49,93,91,'Um  die Formatgrenzen  einzu-|halten '
          dc.b   'muûte der Streckfaktor|erniedrigt werden.',93,91
          dc.b   'Ok|Abbruch',93,0,0
*-----------------------------------------------------------FUNKTIONEN
sinus  dc.w  0,572,1144,1715,2268,2856,3425,3993,4560,5126,5690
       dc.w  6252,6813,7371,7927,8481,9032,9580,10126,10668,11207
       dc.w  11743,12275,12803,13328,13848,14365,14876,15384,15886
       dc.w  16384,16877,17364,17847,18324,18795,19261,19720,20174
       dc.w  20622,21063,21498,21926,22348,22763,23170,23571,23965
       dc.w  24351,24730,25102,25466,25822,26170,26510,26842,27166
       dc.w  27482,27789,28088,28378,28660,28932,29197,29452,29698
       dc.w  29935,30163,30382,30592,30792,30983,31164,31336,31499
       dc.w  31651,31795,31928,32052,32166,32270,32365,32449,32524
       dc.w  32588,32643,32688,32723,32748,32763,32768
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
paus      movem.l   d0-d3/a0-a3,-(sp)
*         move.l    d0,d0
*         bsr       hexaus
*         move.l    d1,d0
*         bsr       hexaus
*         move.l    d2,d0
*         bsr       hexaus
*         move.l    d7,d0
*         bsr       hexaus
*         move.l    6(a4),d0
*         bsr       hexaus
*         move.l    10(a4),d0
*         bsr       hexaus
*         move.l    14(a4),d0
*         bsr       hexaus
*         move.l    d6,d0
*         bsr       hexaus
          move.w    #1,-(sp)
          trap      #1
          addq.l    #2,sp
*         tst.w     d0
*         beq.s     trap_rts
          movem.l   (sp)+,d0-d3/a0-a3
          rts
*rap_rts  movem.l   (sp)+,d0-d3/a0-a3
*         addq.l    #4,sp
*         rts
          END
