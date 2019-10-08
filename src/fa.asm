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

 module    SHELL
 section   eins
 pagelen   32767
 pagewid   133
 noexpand
 ;
 XREF  aescall,vdicall,grhandle,appl_id,contrl,intin,intout,ptsin
 XREF  addrin,addrout,now_offs,evt_butt,evt_menu,fram_drw,save_buf
 XREF  menu_adr,directory,alertbox,mark_buf,mrk,koos_mak,wind_chg
 ;
 XDEF  bildbuff,wi1,rec_adr,maus_rec,win_rdw,show_m,hide_m
 XDEF  save_scr,set_xx,rsrc_gad,vslidrw,wi_count,drawflag,logbase
 XDEF  fram_del,copy_blk,rand_tab,msg_buff
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
info      equ  6    0:open/1:change/2:virgin/3:was already changed
lastnum   equ  7    Handle des zuletzt akt. Win.
lastwin   equ  8    Grîûe vor Full-Window
yx_off    equ  16   Abstand Fensterursprung zu 0/0
fenster   equ  22   Pos. und Ausmaûe
schieber  equ  30   Schieber hor./ver.:Pos./Grîûe
          ;        *** Offsets zu markflags ***
einf      equ  2    Auss im Buff(Adr. drawflag+12)?
ovku      equ  4    OV-Kurz-Mode?
del       equ  5    alten Auss vor schub lîschen
          ;
**********************************************************************
*   A4   Zeiger auf Zeiger auf akt. Fenster-Record
*   A5   Zeiger auf CONTRL
*   A6   Zeiger auf INTIN
**********************************************************************
          ;
          move.l    a7,a5               --- Applikation einrichten ---
          move.l    4(a5),a5
          move.l    $c(a5),d0
          add.l     $14(a5),d0
          add.l     $1c(a5),d0
          add.l     #$800,d0            $300 Bytes Stack
          move.l    a5,a7               neuer Stack
          add.l     d0,a7
          add.l     #32266,d0           Platz fÅr Buffer
          move.l    d0,-(sp)            setblock
          move.l    a5,-(sp)
          clr.w     -(sp)
          move.w    #$4a,-(sp)
          trap      #1
          add.w     #12,sp
          tst.w     d0                  Fehler -> Abbruch
          bne       mainrts
          ;
          lea       bildbuff,a0         Zeiger auf Bildschirmbuffer
          move.l    a7,d0
          add.l     #256,d0
          and.l     #$ffff00,d0         auf page-Anfang
          move.l    d0,(a0)
          subq.l    #8,a7
          lea       intin,a6
          lea       contrl,a5
          aes       10 0 1 0 0          ;APPL_INIT
          move.w    intout,appl_id
          bmi       mainrts
          aes       77 0 5 0 0          ;GRAF_HANDLE
          move.w    intout,grhandle
          vdi       100 0 11 1 1 1 1 1 1 1 1 1 1 2
          ;
*---------------------------------------------------------VORBEREITUNG
          ;
          aes       110 0 1 1 0 rscname ;rsrc_load
          move.w    intout,d0
          beq       mainrts             Fehler -> Abbruch
          clr.w     d1
          bsr       rsrc_gad
          move.l    addrout,menu_adr
          lea       directory,a2        -- Itemslct initialisieren --
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
          move.w    #3,-(sp)            ;get logbase
          trap      #14
          addq.l    #2,sp
          move.l    d0,logbase
          bsr       hide_m              ;hide_mouse
          moveq.l   #16,d1
          bsr       rsrc_gad
          move.l    addrout,a3
          aes       104 2 5 0 0 0 4     ;wind_get
          move.l    intout+2,16(a3)
          move.l    intout+6,20(a3)
          move.l    a3,4(a6)
          clr.l     8(a6)
          aes       105 6 1 0 0 0 14    ;wind_set
          move.l    intout+2,2(a6)
          move.l    intout+6,6(a6)
          move.l    intout+2,10(a6)
          move.l    intout+6,14(a6)
          aes       51 9 1 1 0 3        ;form_dial
          aes       30 1 1 1 0 1 !menu_adr  ;menu_bar
          move.l    #maus_kno,14(a5)
          vdi       125 0 0
          move.l    18(a5),maus_rec+4
          move.l    #maus_mov,14(a5)
          vdi       127 0 0
          move.l    18(a5),maus_rec+8
          aes       78 1 1 0 0 0        ;GRAF_MOUSE (Pfeilform)
          bsr       show_m              ;show_mouse
          lea       wi1,a4              Zeiger auf erstes Fenster
          move.l    a4,rec_adr
*--------------------------------------------------------EVENT-HANDLER
evt_multi ;
          aes       25 16 7 1 0 %110000 0 0 0 0 0 0 0 0 0 0 0 0 0 \
                    70 0 msg_buff       ;evt_multi
          btst.b    #4,intout+1
          bne.s     evt_mul1
          bsr       koos_mak            evtll. Koordin. ausgeben
          lea       maus_rec,a2
          tst.w     20(a2)              Rechte Maustaste ?
          bne       absmod
          tst.w     (a2)                Linke Maustaste ?
          beq       evt_multi
          tst.w     2(a2)               wÑhrend MenÅauswahl ?
          bne.s     evt_mul2
          move.l    rec_adr,a4
          aes       104 2 5 0 0 !(a4) 10  ;wind_get
          move.w    intout+2,d0
          cmp.w     (a4),d0
          beq.s     evt_mul3            Accessory-Fenster aktiv ?
          move.w    #-1,2(a2)
          bra.s     evt_mul2
evt_mul3  pea       evt_multi
          bra       evt_butt
evt_mul2  tst.b     1(a2)               MenÅauswahl-> keine Reaktion
          bne       evt_multi
          clr.w     (a2)
          bra       evt_multi
evt_mul1  pea       evt_multi
          move.l    rec_adr,a4
          move.w    msg_buff,d0
          cmp.w     #10,d0              MenÅeintrag gewÑhlt ?
          beq       evt_menu
*-------------------------------------------------------WINDOW-HANDLER
          cmp.w     #20,d0
          bne       topped              --- WM_Redraw - Routine ---
redraw    bsr       hide_m              ;hide_mouse
          aes       107 1 1 0 0 1       ;wind_update
          move.l    msg_buff+8,d0
          move.l    msg_buff+12,d1
          add.l     d0,d1
          sub.l     #$10001,d1
          cmp.w     #400,d1             Ausschnitt korrigieren
          blo.s     redraw8
          move.w    #399,d1
redraw8   swap      d1
          cmp.w     #640,d1
          blo.s     redraw9
          move.w    #639,d1
redraw9   swap      d1
          move.l    d0,d4               D4/D5: X/Y-Min-lo-Ecke
          move.l    d0,d5
          move.l    d1,d6               D6/D7: X/Y-Max-ru-Ecke
          move.l    d1,d7
          swap      d4
          swap      d6
          moveq.l   #6,d0               ++ Window-Record bestimmen ++
          move.w    msg_buff+6,d2
          lea       wi1-38,a3
redraw1   add.w     #38,a3
          cmp.w     (a3),d2             A3: Zeiger auf Fenster-Record
          beq.s     redraw2
          dbra      d0,redraw1
          bra       rw_end              keins meiner Fenster -> fertig
redraw2   moveq.l   #11,d3
getreck   ;
          aes       104 2 5 0 0 !(a3) !d3  ;wind_get
          move.l    intout+2,d0
          move.l    intout+6,d1
          tst.l     d1
          beq       rw_end              Liste zuende ?
          add.l     d0,d1
          sub.l     #$10001,d1
          cmp.w     d5,d0               ++ SchnittflÑche bestimmen ++
          bhs.s     redraw3
          move.w    d5,d0
redraw3   cmp.w     d7,d1
          bls.s     redraw4
          move.w    d7,d1
redraw4   swap      d0
          swap      d1
          cmp.w     d4,d0
          bhs.s     redraw5
          move.w    d4,d0
redraw5   cmp.w     d6,d1
          bls.s     redraw6
          move.w    d6,d1
redraw6   cmp.w     d0,d1               kein Schnittpunkt ?
          blo.s     redraw7             -> nÑchstes Rechteck
          swap      d0
          swap      d1
          cmp.w     d0,d1
          blo.s     redraw7
redraw11  move.l    d0,d2
          add.w     yx_off(a3),d0
          add.w     yx_off(a3),d1
          add.l     yx_off+2(a3),d0
          add.l     yx_off+2(a3),d1
          move.l    bild_adr(a3),a0
          move.l    logbase,a1
          movem.l   d4-d7,-(sp)
          movem.l   a3/d0-d2,-(sp)
          bsr       copy_blk
          movem.l   (sp)+,a3/d0-d2
          move.w    mark_buf,d3         Ausschnitt nachzeichnen ?
          beq.s     redraw10
          cmp.l     rec_adr(pc),a3
          bne.s     redraw10
          move.l    fenster(a3),-(sp)
          move.l    fenster+4(a3),-(sp)
          move.l    d2,fenster(a3)
          sub.l     d0,d1
          add.l     #$10001,d1
          move.l    d1,fenster+4(a3)
          bsr       fram_drw            -> Rahmen nachzeichnen
          move.l    rec_adr,a3
          move.l    (sp)+,fenster+4(a3)
          move.l    (sp)+,fenster(a3)
redraw10  movem.l   (sp)+,d4-d7
redraw7   moveq.l   #12,d3
          bra       getreck
rw_end    ;
          aes       107 1 1 0 0 0       ;wind_update
          bra       show_m
          ;
topped    cmp.w     #21,d0
          bne.s     hslid
          move.w    msg_buff+6,d3       --- Topped ---
          move.w    (a4),d2
          cmp.w     d3,d2
          beq.s     topped5             Fenster nur reaktivieren
          bsr       save_scr
          move.l    a4,a0
          lea       wi1,a4
          moveq.l   #6,d0
topped1   cmp.w     (a4),d3             zugehîriges Record bestimmen
          beq.s     topped2
          add.w     #38,a4
          dbra      d0,topped1
          move.l    a0,a4               keins meiner Fenster
          rts
topped2   lea       wi1,a0              Referenzen zu diesem Record...
          moveq.l   #6,d0
topped3   cmp.b     lastnum(a0),d3
          bne.s     topped4
          move.b    lastnum(a4),lastnum(a0)   ...ersetzen
topped4   add.w     #38,a0
          dbra      d0,topped3
          move.b    d2,lastnum(a4)
          bsr       fram_del
          move.l    a4,rec_adr
          bsr       prep_men            Abspeichern-Status setzen
topped5   move.w    d3,d1
          moveq.l   #10,d0
          bra       set_xx
          ;
hslid     cmp.w     #25,d0
          bne.s     vslid
          clr.l     d1                  --- Horizontaler Schieber ---
          move.w    msg_buff+8,d1
          move.w    #640,d0
          sub.w     fenster+4(a4),d0
          mulu      d0,d1
          bsr       divu1000            D1:=D1/1000
hslid2    sub.w     fenster(a4),d1
          move.w    d1,yx_off+2(a4)
          move.w    msg_buff+8,d1
          move.w    d1,schieber(a4)
          moveq.l   #8,d0
          bsr       set_xx              Schieber einstellen
          bra.s     vslidrw
          ;
vslid     cmp.w     #26,d0
          bne       arrowed
          clr.l     d1                  --- Vertikaler Schieber ---
          move.w    msg_buff+8,d1
          move.w    #400,d0
          sub.w     fenster+6(a4),d0
          mulu      d0,d1
          bsr       divu1000            D1:=D1/1000
          sub.w     fenster+2(a4),d1
          move.w    d1,yx_off(a4)
          lsl.w     #4,d1
          moveq.l   #25,d0
          bsr       divu_d0
          move.w    msg_buff+8,d1
          move.w    d1,schieber+2(a4)
          moveq.l   #9,d0               Schieber neu einstellen
          bsr       set_xx
vslidrw   bsr       hide_m              ** Top-Window neuzeichnen **
          move.l    rec_adr,a0
          move.l    fenster(a0),d0
          move.l    fenster+4(a0),d1
          move.l    d0,d2
          add.l     d0,d1
          sub.l     #$10001,d1
          cmp.w     #400,d2             Auschnitt korrigieren
          bhs       show_m
          cmp.l     #$2800000,d2
          bhs       show_m
          cmp.w     #400,d1
          blo.s     vslidrw1
          move.w    #399,d1
vslidrw1  cmp.l     #$2800000,d1
          blo.s     vslidrw2
          swap      d1
          move.w    #639,d1
          swap      d1
vslidrw2  add.l     yx_off+2(a0),d0
          add.w     yx_off(a0),d0
          add.l     yx_off+2(a0),d1
          add.w     yx_off(a0),d1
          move.l    bild_adr(a0),a0
          move.l    logbase,a1
          bsr       copy_blk
          move.w    mark_buf,d0
          beq       show_m
          bsr       fram_drw
          bra       show_m
          ;
arrowed   cmp.w     #24,d0
          bne       sized
          move.l    #400,d2             D2: max. Y-Offset
          sub.w     fenster+6(a4),d2
          move.w    msg_buff+8,d0       --- Scrollpfeile + -balken ---
          cmp.b     #3,d0
          bne.s     arrowed1
          move.w    yx_off(a4),d1       -- 1 Pixel nach oben --
          add.w     fenster+2(a4),d1
          beq       exec_rts
          subq.w    #1,yx_off(a4)
          subq.w    #1,d1
arrowedA  mulu      #1000,d1
          cmp.l     d2,d1
          bhs.s     arrowedB
          clr.w     d1
          bra.s     arrowedC
arrowedB  divu      d2,d1
arrowedC  moveq.l   #9,d0
          move.w    d1,schieber+2(a4)
          bsr       set_xx
          bra       vslidrw
arrowed1  cmp.b     #2,d0
          bne.s     arrowed2
          move.w    yx_off(a4),d1       -- 1 Pixel runter --
          add.w     fenster+2(a4),d1
          cmp.w     d2,d1
          bhs       exec_rts
          addq.w    #1,yx_off(a4)
          addq.w    #1,d1
          bra       arrowedA
arrowed2  tst.b     d0
          bne.s     arrowed3
          clr.w     d1                  -- Ganz hoch --
          sub.w     fenster+2(a4),d1
          move.w    d1,yx_off(a4)
          clr.w     d1
          clr.w     schieber+2(a4)
          moveq.l   #9,d0
          bsr       set_xx
          bra       vslidrw
arrowed3  cmp.b     #1,d0
          bne.s     arrowed4
          move.w    d2,d1               -- Ganz runter --
          sub.w     fenster+2(a4),d1
          move.w    d1,yx_off(a4)
          move.w    #1000,d1
          move.w    #1000,schieber+2(a4)
          moveq.l   #9,d0
          bsr       set_xx
          bra       vslidrw
arrowed4  move.l    #640,d2             D2: max. X-Offset
          sub.w     fenster+4(a4),d2
          cmp.b     #7,d0
          bne.s     arrowed5
          move.w    yx_off+2(a4),d1     -- 1 Pixel nach links --
          add.w     fenster(a4),d1
          beq       exec_rts
          subq.w    #1,yx_off+2(a4)
          subq.w    #1,d1
arrowedD  mulu      #1000,d1
          cmp.l     d2,d1
          bhs.s     arrowedE
          clr.w     d1
          bra.s     arrowedF
arrowedE  divu      d2,d1
arrowedF  moveq.l   #8,d0
          move.w    d1,schieber(a4)
          bsr       set_xx
          bra       vslidrw
arrowed5  cmp.b     #6,d0
          bne.s     arrowed6
          move.w    yx_off+2(a4),d1     -- 1 Pixel rechts --
          add.w     fenster(a4),d1
          cmp.w     d2,d1
          bhs       exec_rts
          addq.w    #1,yx_off+2(a4)
          addq.w    #1,d1
          bra       arrowedD
arrowed6  cmp.b     #4,d0
          bne.s     arrowed7
          clr.w     d1                  -- Ganz links --
          sub.w     fenster(a4),d1
          move.w    d1,yx_off+2(a4)
          clr.w     d1
          clr.w     schieber(a4)
          moveq.l   #8,d0
          bsr       set_xx
          bra       vslidrw
arrowed7  cmp.b     #5,d0
          bne       exec_rts
          move.w    d2,d1               -- Ganz rechts --
          sub.w     fenster(a4),d1
          move.w    d1,yx_off+2(a4)
          move.w    #1000,d1
          move.w    #1000,schieber(a4)
          moveq.l   #8,d0
          bsr       set_xx
          bra       vslidrw
          ;
sized     cmp.w     #27,d0
          bne.s     moved
          move.l    msg_buff+8,4(a6)    --- Fenstergrîûe Ñndern ---
          move.l    msg_buff+12,8(a6)
          aes       105 6 1 0 0 !(a4) 5   ;wind_set
          aes       108 6 5 0 0 1 $fef  ;wind_calc
          move.l    intout+6,d3
          bra       sizedsub
          ;
moved     cmp.w     #28,d0
          bne.s     fulled
          move.l    msg_buff+8,4(a6)    --- Fenster verschieben ---
          move.l    msg_buff+12,8(a6)
          aes       105 6 1 0 0 !(a4) 5  ;wind_set
          aes       108 6 5 0 0 1 $fef   ;wind_calc
          move.l    intout+2,d3
          bra       movedsub
          ;
fulled    cmp.w     #23,d0
          bne       closed
          move.l    fenster(a4),d0      --- Full-Button ---
          move.l    fenster+4(a4),d1
          cmp.l     maxwin,d0
          bne.s     fulled3
          cmp.l     maxwin+4,d1
          beq.s     fulled1
fulled3   move.l    d0,lastwin(a4)      - Maximalgrîûe -
          move.l    d1,lastwin+4(a4)
          move.l    maxwin,d3
          move.l    maxwin+4,d4
          bra.s     fulled2
fulled1   move.l    lastwin(a4),d3      - alte Grîûe -
          move.l    lastwin+4(a4),d4
fulled2   move.l    d3,4(a6)
          move.l    d4,8(a6)
          aes       108 6 5 0 0 0 $fef   ;wind_calc
          move.l    intout+2,4(a6)
          move.l    intout+6,8(a6)
          aes       105 6 1 0 0 !(a4) 5  ;wind_set
          bsr       movedsub
          move.l    d4,d3
          bra       sizedsub
          ;
closed    cmp.w     #22,d0
          bne       exec_rts
          bsr       wind_chg            --- Fenster schlieûen ---
          beq.s     closed5
          lea       straldel,a0
          moveq.l   #1,d0
          bsr       alertbox            "Wirklich lîschen ?"
          move.w    intout,d0
          cmp.w     #1,d0
          bne       exec_rts
closed5   move.l    fenster(a4),d0
          move.l    d0,8(a6)
          add.l     #$10001,d0
          move.l    d0,(a6)
          move.l    #$100010,4(a6)
          move.l    fenster+4(a4),12(a6)
          aes       74 8 1 0 0          ;graf_shrinkbox
          aes       102 1 1 0 0 !(a4)   ;wind_close
          aes       103 1 1 0 0 !(a4)   ;wind_delete
          move.l    bild_adr(a4),-(sp)  ;mfree
          move.w    #$49,-(sp)
          trap      #1
          addq.l    #6,sp
          clr.b     info(a4)
          move.l    menu_adr,a0         RÅckgÑngig disabeln
          bset.b    #3,491(a0)
          clr.w     drawflag
          move.w    mark_buf,d0
          bne.s     closed7
          move.l    drawflag+12,d0
          cmp.l     bild_adr(a4),d0
          bne.s     closed8
          clr.w     mrk+einf            EinfÅgen disabeln
          bset.b    #3,1643(a0)
          bra.s     closed8
closed7   clr.b     mark_buf            Rahmen lîschen
          bsr       fram_del
closed8   move.w    #-1,(a4)
          clr.w     d2
          move.b    lastnum(a4),d2
          sub.w     #1,wi_count
          ble.s     closed2
          lea       wi1-38,a4           zuletzt aktives Fenster...
          moveq.l   #6,d0
closed1   add.w     #38,a4
          cmp.w     (a4),d2             ..suchen und...
          dbeq      d0,closed1
          move.l    a4,rec_adr          ..als aktuell erklÑren
          bsr       prep_men            Abspeichern-Status setzen
          cmp.w     #6,wi_count
          blo.s     exec_rts
          move.l    menu_adr,a3         Accessories enabeln
          add.w     #323,a3
          moveq.l   #5,d0
closed4   bclr.b    #3,(a3)
          add.w     #24,a3
          dbra      d0,closed4
          rts
closed2   move.l    menu_adr,a0         MenÅeintrÑge disabeln
          bset.b    #3,635(a0)
          lea       now_offs,a1
          moveq.l   #4,d0
closed3   add.w     (a1)+,a0
          bset.b    #3,(a0)
          dbra      d0,closed3
exec_rts  rts
          ;
absmod    move.l    rec_adr,a4          ** In Abs-Mode umschalten **
          move.w    (a4),d0
          bmi       evt_multi
          bsr       swap_buf
          bsr       hide_m
          move.w    #-1,-(sp)
          move.l    bildbuff,-(sp)
          move.l    bildbuff,-(sp)
          move.w    #5,-(sp)
          trap      #14
          add.w     #12,sp
          bsr       show_m
          move.l    a4,-(sp)            Fensterrecordzeiger retten
          move.l    bild_adr(a4),a0
          lea       wiabs,a4
          lea       rec_adr,a1
          move.l    a4,(a1)
          move.l    bildbuff,bild_adr(a4)
          lea       bildbuff,a1
          move.l    a0,(a1)
          lea       maus_rec+20,a0
absmod2   tst.b     (a0)
          bne       absmod2
          clr.w     (a0)
absmod3   move.w    maus_rec+20,d0      +++ Schleife +++
          bne.s     absmod4
          move.w    maus_rec,d0
          beq       absmod3
          move.l    rec_adr,a4
          bsr       evt_butt
          lea       maus_rec,a0
absmod6   tst.b     (a0)
          bne       absmod6
          clr.w     (a0)
          bra       absmod3
          ;
absmod4   bsr       hide_m              +++ Alter Bildschirm +++
          bsr       swap_buf
          move.w    #-1,-(sp)
          move.l    logbase,-(sp)
          move.l    logbase,-(sp)
          move.w    #5,-(sp)
          trap      #14
          add.w     #12,sp
          bsr       show_m
          lea       bildbuff,a1
          move.l    2(a4),(a1)
          lea       rec_adr,a0
          move.l    (sp)+,a4
          move.l    a4,(a0)
          lea       maus_rec+20,a0
absmod5   tst.b     (a0)
          bne.s     absmod5
          clr.w     (a0)
          bsr       win_rdw
          bra       evt_multi
*----------------------------------------------------------SUBROUTINEN
hide_m    move.l    #$7b0000,(a5)       hide_cursor
          clr.w     6(a5)
          bra       vdicall
show_m    move.l    #$7a0000,(a5)       show_cursor
          move.w    #1,6(a5)
          move.w    #1,(a6)
          bra       vdicall
set_xx    ;
          aes       105 3 1 0 0 !(a4) !d0 !d1  ;wind_set
          rts
rsrc_gad  clr.w     d0
          aes       112 2 1 0 1 !d0 !d1 ;rsrc_gaddr
          rts
          ;
get_top   move.l    rec_adr,a1          ** Top-Window-Handle holen **
          aes       104 2 5 0 0 !(a1) 10  ;wind_get
          move.w    intout+2,d0
          cmp.w     (a1),d0
          rts
          ;
win_rdw   bsr       get_top             ** Bildschirm neuzeichnen **
          beq       vslidrw             Bild ist top-window
          lea       msg_buff,a0
          move.w    (a1),6(a0)
          move.l    fenster(a1),8(a0)
          move.l    fenster+4(a1),12(a0)
          bra       redraw              Redraw-Routine verwenden
          ;
prep_men  move.l    bild_adr(a4),a0     ** MenÅeintragsstatus setz. **
          add.w     #32010,a0
          tst.b     (a0)                Fenstertitel gesetzt ?
          movea.l   menu_adr,a0
          beq.s     prep_me1
          bclr      #3,635(a0)          -> Abspeichern enabeln
          rts
prep_me1  bset      #3,635(a0)
          rts
          ;
divu1000  move.l    #1000,d0
divu_d0   cmp.l     d0,d1               ** D1 := D1 / D0 **
          bhs.s     divu_d01
          swap      d1
          bra.s     divu_d02
divu_d01  divu      d0,d1
divu_d02  rts
          ;
mainrts   clr.w     -(sp)               ** Fehler -> Prog.abbruch **
          trap      #1
          bra       mainrts
          ;
maus_kno  move.w    #1,$9ef0            ** Mausknopf-Interrupt **
          btst      #0,d0
          beq.s     maus_kn2
          tst.w     maus_rec            Click schon registriert ?
          bne.s     maus_kn5            -> Abbruch
          move.l    a0,-(sp)
          move.l    logbase,a0
          tst.b     $54(a0)             MenÅs aktiv ?
          bne.s     maus_kn3
          tst.b     $5a(a0)
          bne.s     maus_kn3
          tst.b     $63(a0)
          bne.s     maus_kn3
          tst.b     $6c(a0)
          bne.s     maus_kn3
          tst.b     $77(a0)
          bne.s     maus_kn3
          tst.b     $83(a0)
          bne.s     maus_kn3
          move.l    (sp)+,a0
          move.l    #$1010000,maus_rec
          move.l    maus_rec+12,maus_rec+16  Mauspos. merken
          bra.s     maus_kn5
maus_kn3  move.l    #$101ffff,maus_rec
          move.l    (sp)+,a0
          bra.s     maus_kn5
maus_kn2  clr.b     maus_rec+1
maus_kn5  btst      #1,d0               rechte Maustaste ?
          beq.s     maus_kn4
          tst.w     maus_rec+20
          bne.s     maus_kn4
          move.w    #-1,maus_rec+20
          bra.s     maus_kn1
maus_kn4  clr.b     maus_rec+20
maus_kn1  move.l    maus_rec+4,-(sp)
          rts
          ;
maus_mov  move.w    d0,maus_rec+12      ** Mausbewegungs-Interrupt **
          move.w    d1,maus_rec+14
          move.l    maus_rec+8,-(sp)
          rts
          ;
save_scr  move.w    wi_count,d0         ** Bildpuffer freigeben **
          beq       exec_rts
          move.b    drawflag,d0
          beq       exec_rts
          move.l    rec_adr,a1
          bclr.b    #3,info(a1)
          bne.s     save_sc1
          bset.b    #1,info(a1)         Bild verÑndert ?
save_sc1  lea       drawflag,a0
          clr.w     (a0)                Buffer frei+Verschieben fertig
          lea       mrk,a0
          clr.b     ovku(a0)            kurz-Overlay-Modus-Ende
          clr.b     del(a0)             alten Rahmen nicht lîschen
          move.l    menu_adr,a0
          bset.b    #3,491(a0)          "RÅckgÑngig" disabeln
          rts
          ;
swap_buf  move.l    bildbuff,a1         ** Buffer vertauschen **
          move.l    rec_adr,a0
          move.l    bild_adr(a0),a0
          move.w    #3999,d1
swap_bu1  move.l    (a0),d0
          move.l    (a1),(a0)+
          move.l    d0,(a1)+
          move.l    (a0),d0
          move.l    (a1),(a0)+
          move.l    d0,(a1)+
          dbra      d1,swap_bu1
          rts
          ;
fram_del  move.w    mark_buf,d0         ** Markierung beenden **
          beq       exec_rts
          move.l    menu_adr,a0
          bclr.b    #3,1643(a0)         "EinfÅgen" enabeln
          add.w     #1667,a0
          moveq.l   #10,d0
fram_de1  bset.b    #3,(a0)             MenÅeintrÑge disabeln
          add.w     #24,a0
          dbra      d0,fram_de1
          move.l    rec_adr,a0          alte Rahmenpos merken
          move.l    bild_adr(a0),d0
          lea       drawflag+4,a0
          move.l    mark_buf+2,(a0)+
          move.l    mark_buf+6,(a0)+
          move.l    d0,(a0)+
          lea       mrk+einf,a0         Flag "alter Rahmen existiert"
          move.w    #$ff00,(a0)
          lea       mark_buf,a0
          move.b    (a0),d0             Rahmen gezeichnet ?
          beq.s     fram_de3
          movem.l   a1-a4/d2-d7,-(sp)
          bsr       get_top             Top-Window aktuell ?
          bne.s     fram_de2
          bsr       fram_drw            ja -> Rahmen lîschen
          movem.l   (sp)+,a1-a4/d2-d7
fram_de3  lea       mark_buf,a0
          clr.w     (a0)
          move.l    #-1,6(a0)           (fÅr "RÅckgÑngig")
          rts
fram_de2  lea       mark_buf,a0         nein
          clr.w     (a0)
          move.l    #-1,6(a0)
          move.w    msg_buff+6,-(sp)
          bsr       win_rdw             -> Bild neuzeichnen
          move.w    (sp)+,msg_buff+6
          movem.l   (sp)+,a1-a4/d2-d7
          rts
          ;
sizedsub  move.l    d3,fenster+4(a4)    ** Fenstergrîûe einstellen **
          move.w    d3,d1               +++ vert. Schieber +++
          mulu.w    #5,d1
          lsr.w     #1,d1               Schiebergrîûe
          move.w    d1,schieber+6(a4)
          moveq.l   #16,d0
          bsr       set_xx
          move.w    #400,d0             Schieberpos
          sub.w     fenster+6(a4),d0
          move.w    fenster+2(a4),d1
          add.w     yx_off(a4),d1
          mulu.w    #1000,d1
          bsr       divu_d0
          move.w    d1,schieber+2(a4)
          moveq.l   #9,d0
          bsr       set_xx
          add.w     fenster+2(a4),d3    Offset
          add.w     yx_off(a4),d3
          sub.w     #400,d3
          bls.s     sized1
          sub.w     d3,yx_off(a4)
sized1    swap      d3                  +++ hor. Schieber +++
          move.w    d3,d1
          mulu.w    #25,d1              Schiebergrîûe
          lsr.w     #4,d1
          move.w    d1,schieber+4(a4)
          moveq.l   #15,d0
          bsr       set_xx
          move.w    #640,d0             Schieberpos
          sub.w     fenster+4(a4),d0
          move.w    fenster(a4),d1
          add.w     yx_off+2(a4),d1
          mulu.w    #1000,d1
          bsr       divu_d0
          move.w    d1,schieber(a4)
          moveq.l   #8,d0
          bsr       set_xx
          add.w     fenster(a4),d3      Offset
          add.w     yx_off+2(a4),d3
          sub.w     #640,d3
          bls       exec_rts
          sub.w     d3,yx_off+2(a4)
          rts
          ;
movedsub  move.w    yx_off(a4),d1       ** Fensterpos. einstellen **
          add.w     fenster+2(a4),d1    D1: neuer Y-Offset
          sub.w     d3,d1
          move.w    yx_off+2(a4),d2     D2: neuer X-Offset
          add.w     fenster(a4),d2
          move.l    d3,fenster(a4)
          swap      d3
          sub.w     d3,d2
          swap      d1
          move.w    d2,d1
          move.l    d1,yx_off(a4)
          rts
          ;
**********************************************************************
**  öbergabeparameter:
**  ==================
**    D0:  X/Y-Koordinate der linken oberen Ecke der Quelle
**    D1:  X/Y-Koordinate der rechten unteren Ecke der Quelle
**    D2:  X/Y-Koordinate der linken oberen Ecke des Ziels
**
**********************************************************************
          ;
copy_blk  movem.l   a4,-(sp)           *** Bit-Block-Kopierroutine ***
          lea       blk_data,a3
          lea       rand_tab,a4
          move.w    d1,d3
          sub.w     d0,d3
          move.w    d2,d7
          mulu.w    #80,d7
          add.l     d7,a1
          move.w    d0,d7
          mulu.w    #80,d7
          add.l     d7,a0
          swap      d0
          swap      d1
          swap      d2
          sub.w     d0,d1
          add.w     d2,d1
          move.w    d0,d4
          move.w    d1,d5
          move.w    d2,d6
          and.w     #15,d0
          and.w     #15,d1
          and.w     #15,d2
          lsr.w     #4,d4
          lsr.w     #4,d5
          lsr.w     #4,d6
          add.w     d4,a0
          add.w     d4,a0
          add.w     d6,a1
          add.w     d6,a1
          move.w    d2,d7
          lsl.w     #1,d7
          move.w    (a4,d7.w),d7
          move.w    d7,2(a3)
          not.w     d7
          move.w    d7,6(a3)
          lsl.w     #1,d1
          move.w    2(a4,d1.w),d1
          move.w    d1,8(a3)
          not.w     d1
          move.w    d1,4(a3)
          move.w    d5,(a3)
          sub.w     d6,(a3)
          bne.s     init5
          move.w    4(a3),d1
          and.w     d1,2(a3)
          move.w    8(a3),d1
          or.w      d1,6(a3)
          move.w    2(a3),4(a3)
          move.w    6(a3),8(a3)
init5     subq.w    #2,(a3)
          bpl.s     init1
          move.w    #78,a2
          bra.s     init2
init1     move.w    #76,a2
          sub.w     (a3),a2
          sub.w     (a3),a2
init2     cmp.w     d0,d2
          bne.s     init3               ++ keine Verschiebung ++
          move.w    #%0100111001110001,d6
          move.w    #-1,d4
          clr.w     d5
          bra       rechts
init3     blo.s     init4               ++ Rechtsverschiebung ++
          move.w    #%1110000001011000,d6
          move.w    d2,d7
          sub.w     d0,d7
          move.w    d7,d1
          lsl.w     #1,d1
          move.w    (a4,d1.w),d4
          move.w    d4,d5
          not.w     d5
          cmp.w     #8,d7
          beq.s     rechts
          bhs.s     initr1
          ror.w     #7,d7
          or.w      d7,d6
          bra.s     rechts
initr1    moveq.l   #16,d1
          sub.b     d7,d1
          ror.w     #7,d1
          or.w      d1,d6
          bset      #8,d6
          bra.s     rechts
init4     move.w    #%1110000101011000,d6  ++ Linksverschiebung ++
          move.w    (a3),d7
          bpl.s     initl2
          addq.w    #2,a2
          cmp.w     #-2,d7
          beq.s     initl3
          addq.w    #2,a0
          addq.w    #2,a1
          addq.w    #2,a2
          bra.s     initl3
initl2    move.w    #80,d7
          sub.w     a2,d7
          add.w     d7,a0
          add.w     d7,a1
          add.w     #80,d7
          move.w    d7,a2
initl3    move.w    d0,d7
          sub.w     d2,d7
          move.w    d7,d1
          lsl.w     #1,d1
          move.w    #32,d4
          sub.w     d1,d4
          move.w    (a4,d4.w),d4
          move.w    d4,d5
          not.w     d5
          cmp.w     #8,d7
          beq       links
          bhs.s     initl1
          ror.w     #7,d7
          or.w      d7,d6
          bra.s     links
initl1    moveq.l   #16,d1
          sub.b     d7,d1
          ror.w     #7,d1
          or.w      d1,d6
          bclr      #8,d6
          bra.s     links
          ;
rechts    move.w    d6,ror1           ********  Rechts  ********
          move.w    d6,ror2
          move.w    d6,ror3
nxt_lin1  move.w    (a0)+,d0            +++ Linker Rand +++
ror1      nop
          move.w    d0,d2
          and.w     2(a3),d0            linken Rand maskieren
          and.w     d4,d0               rechten Teil bestimmen
          move.w    (a1),d1
          and.w     6(a3),d1
          or.w      d0,d1               in Ziel einblenden
          move.w    d1,(a1)+
          move.w    (a3),d6             kein Mittelteil ?
          bmi.s     test1
nxt_wrd1  move.w    (a0)+,d0            +++ Mittelteil +++
ror2      nop
          move.w    d0,d1
          and.w     d4,d0               rechten Teil bestimmen
          and.w     d5,d2
          or.w      d2,d0               +linker Teil vom vorigen Wort
          move.w    d0,(a1)+            in Ziel-Raster ablegen
          move.w    d1,d2
          dbra      d6,nxt_wrd1
rand1     and.w     d5,d2               +++ Rechter Rand +++
          move.w    (a0),d0
ror3      nop
          and.w     d4,d0
          or.w      d0,d2
          and.w     4(a3),d2
          move.w    (a1),d1
          and.w     8(a3),d1
          or.w      d2,d1
          move.w    d1,(a1)
ende1     add.l     a2,a0
          add.l     a2,a1
          dbra      d3,nxt_lin1
          move.l    (sp)+,a4
          rts
test1     cmp.w     #-1,d6
          beq       rand1
          bra       ende1
          ;
links     move.w    d6,rol1           ********  Links  ********
          move.w    d6,rol2
          move.w    d6,rol3             Rotationsbefehle einsetzen
          move.w    d6,rol4
nxt_lin2  move.w    2(a0),d0            +++ Rechter Rand +++
rol4      nop
          and.w     d4,d0
          move.w    d0,d1
          move.w    (a0),d0
rol1      nop
          move.w    d0,d2
          and.w     d5,d0               linken Teil bestimmen
          or.w      d1,d0
          and.w     4(a3),d0            rechten Rand maskieren
          move.w    (a1),d1
          and.w     8(a3),d1
          or.w      d0,d1               in Ziel einblenden
          move.w    d1,(a1)
          move.w    (a3),d6             kein Mittelteil ?
          bmi.s     test2
nxt_wrd2  move.w    -(a0),d0            +++ Mittelteil +++
rol2      nop
          move.w    d0,d1
          and.w     d5,d0               linken Teil bestimmen...
          and.w     d4,d2
          or.w      d2,d0               +rechter Teil vom vorigen Wort
          move.w    d0,-(a1)            in Ziel-Raster ablegen
          move.w    d1,d2
          dbra      d6,nxt_wrd2
rand2     and.w     d4,d2               +++ Linker Rand +++
          move.w    -(a0),d0
rol3      nop
          and.w     d5,d0
          or.w      d0,d2
          and.w     2(a3),d2
          move.w    -(a1),d1
          and.w     6(a3),d1
          or.w      d2,d1
          move.w    d1,(a1)
ende2     add.l     a2,a0
          add.l     a2,a1
          dbra      d3,nxt_lin2
          move.l    (sp)+,a4
          rts
test2     cmp.w     #-1,d6
          beq       rand2
          bra       ende2
          ;
*----------------------------------------------------------BITBLK-DATA
rand_tab  dc.w      $ffff,$7fff,$3fff,$1fff,$fff,$7ff,$3ff,$1ff,$ff
          dc.w      $7f,$3f,$1f,$f,7,3,1,0
blk_data  ds.w      10
*-----------------------------------------------------FENSTER-VARIABLE
logbase   ds.l      1          Adresse des Bildschirmspeichers
bildbuff  ds.l      1          Adresse des allg. Buffers
rec_adr   ds.l      1          Adresse des akt. Win.-Records
maxwin    dc.w      1,37,620,342  Grîûe nach Full-Window
drawflag  dcb.w   8,0          Flags fÅr RÅckg.+Adr fÅr EinfÅgen
wi_count  dc.w      0          Anz der geîffneten Fenster
wi1       dc.w    -1,0,0,0,0,0,0,0,-40,-03,0,03,40,614,337,0,0,959,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-11,0,11,40,606,337,0,0,947,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-19,0,19,40,598,337,0,0,934,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-27,0,27,40,590,337,0,0,922,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-35,0,35,40,582,337,0,0,909,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-43,0,43,40,574,337,0,0,897,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-51,0,51,40,566,337,0,0,884,887
wiabs     dc.w    -1,0,0,0,0,0,0,0,0,0,0,0,0,640,320,-1,-1
*-------------------------------------------------------MAUS-KONTROLLE
maus_rec  dc.l    0     ;{ li.But-Flags/VDI_Button_Vec/VDI_Mouse_Vec/
          dcb.w   10,0  ;  akt_XY-Pos/Button-XY-Pos/re.But-Flags }
*--------------------------------------------------------------STRINGS
msg_buff  ds.w    10
rscname   dc.b    'FA.RSC',0,'FREI!!'
picname   dc.b    '\*.PIC',0
straldel  dc.b    91,49,93,91,'Sie verwerfen ihr ungesichertes '
          dc.b    'Bild !',93,91,'Ok|Abbruch',93,0,0
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
          ;
          END
