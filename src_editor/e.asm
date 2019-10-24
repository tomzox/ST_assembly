 ;section eins ;                                            E . A S M
 ;title    E : Shell fÅr 4 Editoren und Command-Line-Interpreter
 ;pagelen   32767
 ;pagewid   133
 ;
 XREF alarm1,alarm3,alarmtim,almonstr,blank,buff80,buffzeil,creaflag
 XREF curradr,fodcom,gemdoser,getstr4,lastdrv,modeflag,readline
 XREF testflag,timeflag,ende,inslins,dellins,buff12
 ;
 XDEF dezaus2,dezausw,dezaus
 XDEF dezstr,doline,dolinkom,dolinrts,dolinsyn,drknorm
 XDEF illegal,linfed
 XDEF memtop,textbase,funkbase,newline
 XDEF readnum,initstr,initstr2,initstr3
 XDEF tabs,tabswid,zeilaus
 XDEF dezausl,escaus,print3,readdez
 XDEF setcurs,syntax,tabelle,logbase
          ;
          move.w    #4,-(sp)            Get Resolution
          trap      #14
          addq.l    #2,sp
          tst.w     d0                  Lo-Res ?
          bne.s     midorhi
          lea       nolores,a0
          bsr       zeilaus             Frage schreiben
          move.w    #1,-(sp)
          trap      #1                  ;conin
          addq.l    #2,sp
          and.b     #%11011111,d2
          cmp.b     #'J',d2           J oder j fÅr ja ?
          beq.s     swapmod
          move.w    #-1,d0
term      move.w    d0,-(sp)            Term
          move.w    #$4c,-(sp)
          trap      #1
swapmod   move.w    #1,-(sp)            Set Screen: MidRes
          move.l    #-1,-(sp)
          move.l    #-1,-(sp)
          move.w    #5,-(sp)
          trap      #14
          add.w     #12,sp
          ;
midorhi   lea       memtop,a0
          move.l    a7,(a0)             obere Speichergrenze merken
          lea       ende+$300,a7        neuer Stack
          move.l    a7,a6               Beginn Bildschirmspeicher (A6)
          lea       240(a6),a5          Poszeiger im Bildschirmtextsp.
          lea       2100(a6),a3         Zeiger hinter Bildtextsp.
          lea       funkbase,a0
          move.l    a3,(a0)
          lea       funkbuff,a0         Funktionsspeicher fÅllen
          move.w    (a0)+,d0
initfu    move.w    (a0)+,(a3)+
          dbra      d0,initfu
          move.l    memtop,a0           -- Setblock (MemShrink) --
          move.l    a3,d0
          sub.l     4(a0),d0
          move.l    d0,-(sp)            LÑnge benîtig. Speicher
          move.l    4(a0),-(sp)         Beg. res. Speicher
          clr.w     -(sp)
          move.w    #$4a,-(sp)
          trap      #1
          add.w     #12,sp
          tst.l     d0                  Fehler? -> Abbruch
          bne       term
          move.l    #-1,-(sp)           Malloc
          move.w    #$48,-(sp)
          trap      #1
          addq.l    #6,sp
          lea       memtop,a3           LÑnge zwischenspeichern
          move.l    d0,(a3)
          move.l    d0,-(sp)            Max Anz freier Bytes
          move.w    #$48,-(sp)          reservieren
          trap      #1
          addq.l    #6,sp
          tst.l     d0                  Fehler? -> Abbruch
          bmi       term
          add.l     d0,(a3)
          ;
          move.l    d0,a3               A3: Zeiger letzte Zeile
          lea       textbase,a0
          move.l    a3,(a0)
          clr.w     (a3)                Letzte Zeile: Zeile Nr. Null
          lea       curradr,a0
          move.l    a3,(a0)             Zeiger auf aktuelle Zeile
          move.l    #$30000,d7          Pos am Bildschirm: (3/0)
          move.l    #499,d0
          move.l    a6,a0
initsp    move.l    #$20202020,(a0)+    Bildschirmspeicher lîschen
          dbra      d0,initsp
          lea       initstr,a0
          bsr       zeilaus
          move.l    memtop,d0           Anz freie Bytes errechnen
          sub.l     a3,d0
          bsr       dezausl
          lea       initstr2,a0         "Bytes free"
          bsr       zeilaus
          move.w    #3,-(sp)            ;get_logbase
          trap      #14
          addq.l    #2,sp
          lea       logbase,a0
          move.l    d0,(a0)             log.Adr.Bild im Speicher
          move.w    #$19,-(sp)          ;current_disk
          trap      #1
          addq.l    #2,sp
          lea       lastdrv,a0
          move.w    d0,(a0)             Ex-akt.Laufwerk fÅr Set_Drive
          move.w    #$11,-(sp)          ;prtout_stat
          trap      #1
          addq.l    #2,sp
          tst.w     d0
          bne.s     curanrts
          lea       initstr3,a0         "kein Drucker an Centronics"
          bsr       zeilaus
          add.l     #$10000,d7
          lea       80(a5),a5
          ;
curanrts  moveq.l   #'e',d0
          bsr       escaus
          move.b    timeflag,d0         Wecker ein ?
          beq.s     conin
          bmi.s     conin               Gong schon an
gettime   move.w    #$2c,-(sp)          ;get_time
          trap      #1
          addq.l    #2,sp
          and.w     #$ffe0,d0
          move.w    alarmtim,d1
          cmp.w     d1,d0               Jetzt < Weckzeit ? -> nein
          blo.s     gettime1
          cmp.w     alarm3+2,d1         Weckzeit >= Stellzeit ? -> ja
          bhs.s     gongon
          cmp.w     alarm3+2,d0         Jetzt < Stellzeit ? -> ja
          blo.s     gongon
gettime1  move.w    #$ff,-(sp)          Zeichen da ? (ja -> holen)
          move.w    #6,-(sp)
          trap      #1                  ;rawconio
          addq.l    #4,sp
          tst.l     d0
          beq       gettime
          bra.s     charin
gongon    pea       alarm1              Tastatur-Click aus
          move.w    #$26,-(sp)
          trap      #14                 ;supexec
          addq.l    #6,sp
          pea       almonstr            Gong einschalten
          move.w    #32,-(sp)
          trap      #14                 ;dosound
          addq.l    #6,sp
          lea       timeflag,a0
          move.b    #$ff,(a0)
conin     move.w    #7,-(sp)            ;conin_witout_echo
          trap      #1
          addq.l    #2,sp
charin    pea       curanrts            Adr. auf den Stack fÅr RTS
          move.l    d0,d5
          moveq.l   #'f',d0           Cursor ausschalten
          bsr       escaus
          move.l    d5,d0
          ;
editor    cmp.w     #32,d0              normales ASCII-Zeichen ?
          blo       noasc
          cmp.b     #$7f,d0             * DELETE- Taste ? *
          bne.s     clrhome
          move.l    a5,a2
          moveq.l   #78,d0              max. Anz.zu verschieb. Bytes
          sub.b     d7,d0               - Cursorspaltenposition
          bmi.s     delchr2             < 0 -> in letzter Spalte -> kein Verschieben
          move.l    d0,d4
delchr1   move.b    1(a2),(a2)+         im Bildschirmsp. verschieben
          dbra      d0,delchr1
          move.b    #' ',(a2)
          move.l    logbase,a0          A0: Bildursprung (0/0)
          move.l    d7,d0
          lsr.l     #8,d0
          mulu      #5,d0
          add.l     d0,a0               ... plus Y-Off * 1280 (=80*16)
          add.w     d7,a0               ... plus X-Off
          moveq.l   #15,d1
delchr3   move.l    d4,d0
          move.l    a0,a1
delchr4   move.b    1(a0),(a0)+         Verschieben am Bildschirm
          dbra      d0,delchr4
          clr.b     (a0)                Letzte Spalte lîschen
          lea       80(a1),a0
          dbra      d1,delchr3
          rts
delchr2   move.b    #' ',(a5)         - In der letzten Spalte -
          moveq.l   #'K',d0
          bra       escaus              -> nur lîschen
          ;
clrhome   cmp.w     #'7',d0           Shift-Clr/Home ?
          bne       print               nein -> normales ASCII-Zeichen -> ausgeben
          swap      d0
          cmp.b     #$47,d0             Scan-Code von CLR/HOME
          beq.s     clrhome1
          swap      d0
          bne       print
clrhome1  move.l    a6,a5               * CLR HOME *
          clr.l     d7                  Cursor an den Ursprung (0/0)
          move.l    #499,d0
          move.l    a6,a0
clrhome2  move.l    #$20202020,(a0)+    Bildschirmspeicher voll Blanks
          dbra      d0,clrhome2
          moveq.l   #'E',d0           Bildschirm lîschen
          bra       escaus
          ;
noasc     cmp.b     #13,d0
          bne.s     back
return    sub.w     d7,a5               * RETURN *
          moveq.l   #80,d6
          add.l     a5,d6               D6: Zeiger Anf. nÑchste Zeile
          move.l    a5,a0
          sub.l     a4,a4
          bsr       dolinefi            - Zeile ausfÅhren -
          move.l    a4,d0
          beq.s     return2             Fehler passiert ?
          bsr       newline
          move.l    a4,a0
          bsr       zeilaus             -> Meldung ausgeben
return2   bra       linfed
          ;
back      cmp.b     #8,d0
          bne.s     scankeys
          tst.w     d7                  * BACKSPACE *
          bne.s     back1               schon in linkester Spalte ?
          swap      d7
          tst.w     d7
          bne.s     back2
          swap      d7                  schon oben+links -> Abbruch
          rts
back2     sub.w     #1,d7               - in letzte Zeile zurÅck -
          lea       setpos,a0
          move.w    #$206f,2(a0)
          add.b     d7,2(a0)
          swap      d7
          move.b    #79,d7
          bsr       zeilaus             Cursor auf neue Position
          subq.l    #1,a5
          move.b    #32,(a5)
          moveq.l   #'K',d0
          bra       escaus
back1     lea       delstr,a0           - normales Backspace -
          subq.w    #1,d7
          subq.l    #1,a5
          move.b    #32,(a5)
          bra       zeilaus
          ;
scankeys  swap      d0                  ab jetzt SCAN-Code betrachten
          cmp.b     #$f,d0
          bne.s     cursup              * TAB *
          lea       tabs,a0
          clr.l     d0                  Pos in Tabelle errechnen
          move.b    d7,d0
          add.l     d0,a0
          addq.l    #1,a0
tab1      addq.l    #1,a5               nach Tab-Markierung suchen
          addq.b    #1,d7               und Zeiger mitfÅhren
          tst.b     (a0)+
          beq       tab1
          cmp.b     #80,d7              neue Zeile ?
          blo       setcurs
          clr.w     d7
          add.l     #$10000,d7
          cmp.l     #$190000,d7         unten aus dem Bilschirm ?
          blo       setcurs             nein -> Cursor auf neue Pos
          move.l    #$180000,d7         Bildschirm scrollen
          lea       1920(a6),a5
          bra       linfed
          ;
cursup    cmp.b     #$48,d0
          bne.s     cursdow
          swap      d7                  * Cursor up *
          tst.w     d7
          bne.s     cursup1
          move.w    #24,d7              oben aus dem Bildschirm
          add.w     #1920,a5
          swap      d7
          lea       setpos,a0           -> 24 Zeilen nach unten
          move.w    #$3820,2(a0)
          add.b     d7,3(a0)
          bra       zeilaus
cursup1   sub.b     #1,d7
          swap      d7
          sub.w     #80,a5
          moveq.l   #'A',d0           1 Zeile nach oben
          bra       escaus
          ;
cursdow   cmp.b     #$50,d0
          bne.s     curslef
          swap      d7                  * Cursor down *
          cmp.b     #24,d7
          blo.s     cursdow1
          sub.w     #1920,a5            unten aus dem Bildschirm
          clr.w     d7
          swap      d7
          lea       setpos,a0           -> 24 Zeilen nach oben
          move.w    #$2020,2(a0)
          add.b     d7,3(a0)
          bra       zeilaus
cursdow1  add.b     #1,d7
          swap      d7
          add.w     #80,a5
          moveq.l   #'B',d0           1 Zeile runter
          bra       escaus
          ;
curslef   cmp.b     #$4b,d0
          bne.s     cursrig
          tst.b     d7                  * Cursor left *
          bne.s     curslef1            Spalte 0 ?
          swap      d7
          tst.b     d7                  Zeile  0 ?
          bne.s     curslef2
          swap      d7                  in oberster Zeile -> Abbruch
          rts
curslef2  sub.b     #1,d7               - ganz links in der Zeile -
          lea       setpos,a0
          move.w    #$206f,2(a0)        -> 1 Zeile hîher + nach rechts
          add.b     d7,2(a0)
          swap      d7
          move.w    #79,d7
          subq.l    #1,a5
          bra       zeilaus
curslef1  subq.l    #1,a5               - 1 nach links -
          sub.w     #1,d7
          moveq.l   #'D',d0
          bra       escaus
          ;
cursrig   cmp.b     #$4d,d0
          bne.s     home
          cmp.b     #79,d7              * Cursor rechts *
          bne.s     cursrig1
          swap      d7                  in rechtester Spalte
          cmp.b     #24,d7
          bne.s     cursrig2
          sub.w     #79,a5              unterste Zeile, ganz rechts
          swap      d7
          clr.w     d7
          lea       setpos,a0           -> unterste Zeile, ganz links
          move.w    #$3820,2(a0)
          bra       zeilaus
cursrig2  addq.w    #1,d7               nÑchste Zeile
          lea       setpos,a0
          move.w    #$2020,2(a0)
          add.b     d7,2(a0)
          swap      d7
          clr.w     d7
          addq.l    #1,a5
          bra       zeilaus
cursrig1  addq.w    #1,d7               1 Spalte rechts
          addq.l    #1,a5
          moveq.l   #'C',d0
          bra       escaus
          ;
home      cmp.b     #$47,d0
          bne.s     escape
          clr.l     d7                  * HOME *
          move.l    a6,a5
          moveq.l   #'H',d0
          bra       escaus
          ;
escape    cmp.b     #1,d0
          bne.s     insert
          moveq.l   #'E',d0           * ESCAPE *
          bsr       print
          moveq.l   #'S',d0
          bsr       print
          moveq.l   #'C',d0
          bra       print
          ;
insert    cmp.b     #$52,d0
          bne.s     funkmak             * INSERT *
          move.w    #79,d0              Anz.zu verschieb.Zeichen -1
          sub.b     d7,d0
          beq.s     insert2             ganz rechts ?
          add.l     d0,a5
          subq.b    #1,d0
insert1   move.b    -(a5),1(a5)         im Speicher verschieben
          dbra      d0,insert1
          move.b    #' ',(a5)
          move.l    logbase,a1          Bildbasis
          move.l    d7,d0
          lsr.l     #8,d0
          mulu      #5,d0
          add.l     d0,a1
          add.w     #79,a1
          moveq.l   #15,d1
          moveq.l   #78,d2
          sub.b     d7,d2
insert3   move.l    a1,a0
          lea       1(a0),a2
          move.w    d2,d0
insert4   move.b    -(a0),-(a2)
          dbra      d0,insert4
          clr.b     (a0)
          add.w     #80,a1
          dbra      d1,insert3
          rts
insert2   move.b    #32,(a5)            - in der letzten Spalte -
          moveq.l   #'K',d0
          bra       escaus              nur ein Zeichen lîschen
          ;
funkmak   cmp.w     #$3c,d0
          blo       funk1
          cmp.w     #$44,d0
          bhi       funk1
          sub.b     #$3c,d0             * F2 bis F10 *
          lea       funkdata,a0
          move.w    (a0),d1             erste F-Taste ?
          bset      d0,d1               gleiche schon gewÑhlt ?
          beq.s     funkmak1
          bsr       newline
          lea       keiversc,a0         -> "Keine Rekursion Bitte"
          bsr       zeilaus
          sub.w     d7,a5
          bra       linfed
funkmak1  move.w    d1,(a0)+            Verschachtelungstiefe
          addq.w    #1,(a0)
          move.l    funkbase,a0         Adr.Belegungsspeicher
          subq.w    #1,d0
          bmi.s     funkmak3
funkmak2  tst.w     (a0)+               Zu Anfang F-Speicher
          bne       funkmak2
          dbra      d0,funkmak2
funkmak3  move.w    (a0)+,d0            -- Schleife --
          beq.s     funkmak6
          move.l    a0,-(sp)
          lsl.l     #8,d0
          lsr.w     #8,d0
          and.l     #$ff00ff,d0
          move.l    d0,d1
          swap      d1                  HW = 0 ?
          tst.w     d1
          bne.s     funkmak4
          bsr       print               -> ASCII-Zeichen
          bra.s     funkmak5
funkmak4  cmp.w     #$62,d1             HELP ?
          bne.s     funkmak7
          tst.w     (a0)
          beq.s     funkmak7
          addq.l    #2,(sp)
          move.w    (a0)+,d0
          lsl.l     #8,d0
          lsr.w     #8,d0
          and.l     #$ff00ff,d0
          bsr       help2
          bra.s     funkmak5
funkmak7  bsr       editor              Taste verarbeiten
funkmak5  move.l    (sp)+,a0
          bra       funkmak3
funkmak6  lea       funkdata+2,a0       Verschachtelungstiefe -1
          subq.w    #1,(a0)
          bne.s     funkrts
          clr.w     -(a0)
funkrts   rts
          ;
funk1     cmp.w     #$3b,d0
          bne       funkget
          move.w    #7,-(sp)            * F1 *
          trap      #1                  ;conin without echo
          addq.l    #2,sp
          tst.w     d0                  keine ASCII-Taste ?
          beq.s     funkbe
          bsr       getval              -- Sonderzeichen schreiben --
          tst.w     d0
          bmi       funkrts             Fehler -> Abbruch
          clr.b     d1
          move.b    d0,d1
          lsl.b     #4,d1
          move.w    #7,-(sp)            ;conin_without_echo
          trap      #1
          addq.l    #2,sp
          bsr       getval              in Low-Nibble umwandeln...
          tst.w     d0
          bmi       funkrts             und wenn kein Fehler...
          add.b     d1,d0
          bra       print               als Zeichen ausgeben
          ;
funkbe    swap      d0                  Scan-Code holen
          cmp.w     #$3c,d0
          blo       funkrts             keine F-Taste -> Abbruch
          cmp.w     #$44,d0
          bhi       funkrts
          move.l    d0,d5               -- Funktionstaste belegen --
          swap      d5
          lea       buff80,a1
funkbe2   lea       buff12,a0           Buffer voll ?
          cmp.l     a0,a1
          bhs.s     funkbe1
          move.w    #7,-(sp)            ;conin_witout_echo
          trap      #1
          addq.l    #2,sp
          cmp.l     d0,d5               Ausgangs-F-Taste -> fertig
          beq.s     funkbe1
          cmp.l     #$3b0000,d0         F1-Taste ?
          beq.s     funkbe3
          move.l    d0,d1               Tastencode komprimieren
          lsr.l     #8,d1
          or.w      d1,d0
          move.w    d0,(a1)+            im Buffer zwischenspeichern
          bra       funkbe2
funkbe3   swap      d0                  - Sonderzeichen -
          cmp.w     #$3b,d0
          bne.s     funkbe1
          move.w    #7,-(sp)            ;conin_without_echo
          trap      #1
          addq.l    #2,sp
          bsr       getval
          tst.w     d0
          bmi.s     funkbe1             Fehler -> Belegungsende
          move.b    d0,d1
          lsl.b     #4,d1
          move.w    #7,-(sp)            ;conin_without_echo
          trap      #1
          addq.l    #2,sp
          bsr       getval
          tst.w     d0
          bmi.s     funkbe1             Fehler
          add.b     d1,d0
          clr.b     (a1)+
          move.b    d0,(a1)+
          bra       funkbe2
funkbe1   clr.w     (a1)+               Ende-Null
          move.l    a1,a2
          swap      d5                  - Belegung speichern -
          move.l    funkbase,a1
          sub.w     #$3d,d5
          bmi.s     funkbe4
funkbe5   tst.w     (a1)+               A1: Adr. Fx-Speicher
          bne       funkbe5
          dbra      d5,funkbe5
funkbe4   move.l    a1,a0
          clr.l     d1                  D1: vorher. LÑnge
funkbe6   addq.l    #2,d1
          tst.w     (a0)+
          bne       funkbe6
          lea       buff80,a0           D0: Differenz-LÑnge (Neu-Alt)
          move.l    a2,d0
          sub.l     a0,d0
          lea       textbase,a0
          sub.l     d1,d0
          beq.s     funkbe10            gleichlang
          bmi.s     funkbe7
          add.l     d0,(a0)
          bsr       inslins             lÑnger
          move.l    a4,d0
          bne       funkrts
          bra.s     funkbe10
funkbe7   neg.l     d0                  kÅrzer
          sub.l     d0,(a0)
          bsr       dellins
funkbe10  lea       buff80,a0           Umkopieren
          move.l    a2,d0
          sub.l     a0,d0
          lsr.w     #1,d0
          subq.w    #1,d0
funkbe11  move.w    (a0)+,(a1)+
          dbra      d0,funkbe11
          rts
          ;
funkget   cmp.w     #$54,d0
          bne.s     help
          clr.w     d2                  * SHIFT-F1 *
          move.b    (a5),d2
          lea       80(a5),a4
          sub.w     d7,a4
          lea       getchrnr,a0
          move.b    #'B',1(a0)
          cmp.l     #$180000,d7         In letzter Zeile ?
          blo.s     funkget1
          move.b    #'A',1(a0)        -> Ausgebe in Zeile darÅber
          sub.w     #160,a4
funkget1  bsr       zeilaus
          move.w    d2,d0               Zeichencodenr. ausgeben
          bsr       dezausw
funkget3  move.l    #$bffff,-(sp)       ;kbshift
          trap      #13
          addq.l    #4,sp
          and.w     #3,d0               Auf Loslassen der SHIFT-..
          bne       funkget3            ..Tasten warten
          lea       getchrn1,a0
          move.l    d7,d0
          swap      d0
          addq.w    #1,d0
          cmp.b     #$18+1,d0
          blo.s     funkget4
          subq.b    #2,d0
funkget4  add.w     #32,d0
          move.b    d0,6(a0)
          bsr       zeilaus
          moveq.l   #79,d3
funkget2  clr.w     d0                  Zeile rekonstruieren
          move.b    (a4)+,d0
          move.w    d0,-(sp)            ;bconout
          move.l    #$30005,-(sp)
          trap      #13
          addq.l    #6,sp
          dbra      d3,funkget2
          bra       setcurs
          ;
help      cmp.w     #$62,d0
          bne       nofunk
          move.w    #7,-(sp)            * Help *
          trap      #1
          addq.l    #2,sp               ;conin without echo
help2     swap      d0
          cmp.b     #$53,d0
          bne.s     help10
          sub.w     d7,a5               -- Zeile entfernen --
          move.l    a5,a0
          clr.w     d7
          move.l    a6,d0
          add.l     #1920,d0
          sub.l     a5,d0
          beq.s     help02              Cursor in der letzten Zeile
          lsr.w     #4,d0
          subq.w    #1,d0
          lea       80(a0),a1
help01    move.l    (a1)+,(a0)+         Text eine Zeile hochschieben
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          dbra      d0,help01
help02    moveq.l   #19,d0              letzte Zeile lîschen
          move.l    #'    ',(a0)+
          dbra      d0,help02+2
          moveq.l   #'M',d0
          bra       escaus
help10    cmp.b     #$52,d0
          bne.s     help20
          sub.w     d7,a5               -- Zeile einfÅgen --
          clr.w     d7
          lea       1920(a6),a0
          move.l    a0,d0
          sub.l     a5,d0
          beq.s     help12
          lsr.w     #4,d0
          subq.w    #1,d0
          lea       80(a0),a1
help11    move.l    -(a0),-(a1)         Text eine Zeile runterschieben
          move.l    -(a0),-(a1)
          move.l    -(a0),-(a1)
          move.l    -(a0),-(a1)
          dbra      d0,help11
help12    moveq.l   #19,d0              Akt. Zeile lîschen
          move.l    #'    ',(a0)+
          dbra      d0,help12+2
          moveq.l   #'L',d0
          bra       escaus
help20    cmp.b     #$47,d0
          bne.s     help30
          sub.w     d7,a5               -- Zeile entleeren --
          clr.w     d7
          moveq.l   #19,d0
          move.l    a5,a0
help21    move.l    #'    ',(a0)+
          dbra      d0,help21
          moveq.l   #'l',d0
          bsr.s     escaus
          bra       setcurs             Cur.neu positio.wg.TOS-Fehler!
help30    cmp.b     #$48,d0
          bne.s     help40
          move.l    a5,d1               -- ClrBoS --
          sub.l     a6,d1
          move.l    a6,a0
help31    move.b    #' ',(a0)+        Bildschirm bis Cursorpos
          dbra      d1,help31           einschlieûlich lîschen
          moveq.l   #'d',d0
          bra.s     escaus
help40    cmp.b     #$50,d0
          bne.s     help50
          move.l    a6,d0               -- ClrEoS --
          sub.l     a5,d0
          add.w     #1999,d0
          lea       2000(a6),a0
help41    move.b    #' ',-(a0)        Bildschirm ab Cursorpos
          dbra      d0,help41           einschlieûlich lîschen
          moveq.l   #'J',d0
          bra.s     escaus
help50    cmp.b     #$4b,d0
          bne.s     help60
          move.l    a5,a0               -- ClrBol --
          sub.w     d7,a0
          move.w    d7,d0
help51    move.b    #' ',(a0)+        Zeile bis Cursorpos
          dbra      d0,help51           einschlieûlich lîschen
          moveq.l   #'o',d0
          bra.s     escaus
help60    cmp.b     #$4d,d0
          bne.s     nofunk
          moveq.l   #79,d0              -- ClrEoL --
          sub.b     d7,d0
          move.l    a5,a0
help61    move.b    #' ',(a0)+        Zeile ab Cursorpos
          dbra      d0,help61           einschlieûlich lîschen
          moveq.l   #'K',d0
          bra.s     escaus
          ;
nofunk    rts
          ;
escaus    lea       escstr,a0           * Steuerzeichen an Bildschirm *
          move.b    d0,1(a0)
zeilaus   move.l    a0,-(sp)            * Zeile auf Bildschirm *
          move.w    #9,-(sp)
          trap      #1                  ;print_line
          addq.l    #6,sp
          rts
escstr    dc.b      27,'#',0,0
          ;
print     move.b    d0,(a5)+            * Zeichen speichen *
          cmp.b     #79,d7              ganz rechts in der Zeile ?
          blo.s     print1
          bsr.s     print3              ja; Zeichen schreiben
          swap      d7
          cmp.b     #24,d7              letzte Zeile ?
          blo.s     print2
printscr  move.l    #119,d0             -- Bildschirm scrollen --
          move.l    a1,-(sp)
          move.l    a6,a0
          lea       80(a0),a1
print4    move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          dbra      d0,print4
          moveq.l   #19,d0              unterste Zeile voll Blanks
print5    move.l    #$20202020,(a0)+
          dbra      d0,print5
          move.l    #$180000,d7         neue Cursorpos
          lea       1920(a6),a5
          move.l    logbase,a0          Bildschirm hochschieben
          lea       1280(a0),a1
          move.l    #959,d0
print6    move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          move.l    (a1)+,(a0)+
          dbra      d0,print6
          move.l    (sp)+,a1
          move.l    #79,d0
print7    clr.l     (a0)+               Letzte Zeile lîschen
          clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,print7
          bra.s     setcurs
print2    addq.b    #1,d7               -- neue Zeile --
          swap      d7
          clr.w     d7
          bra.s     setcurs             Cursor in nÑchste Zeile
print1    add.b     #1,d7               -- normale Position --
print3    move.l    a1,-(sp)
          move.w    d0,-(sp)            -- Ausgabe --
          move.l    #$30005,-(sp)
          trap      #13                 ;bconout
          addq.l    #6,sp
          move.l    (sp)+,a1
          rts
          ;
newline   bsr.s     linfed              * Leere neue Zeile schaffen *
          moveq.l   #19,d0
          move.l    #'    ',a0
newline1  move.l    a0,(a5)+            mit Blanks fÅllen
          dbra      d0,newline1
          sub.w     #80,a5
          moveq.l   #'K',d0           Zeile am Bildschirm lîschen
          bra       escaus
          ;
linfed    clr.w     d7                  * Cursor usw. an Anfang nÑchster Zeile *
          lea       80(a5),a5
          add.l     #$10000,d7
          cmp.l     #$190000,d7
          bhs       printscr            scrollen
          ;
setcurs   lea       setpos,a0           * Cursor an D7- Pos. setzen *
          swap      d7
          move.b    d7,2(a0)
          swap      d7
          move.b    d7,3(a0)
          add.w     #$2020,2(a0)
          bra       zeilaus
          ;
dezaus    lea       dezstr,a0           * Zahl dezimal ausgeben *
dezaus2   and.l     #$ffff,d0
          cmp.w     #10,d0
          blo.s     dezaus10
dezaus1   divu      #10,d0              nÑchste Dezimalstelle holen
          swap      d0
          add.b     #'0',d0           in ASCII wandeln
          move.b    d0,-(a0)            in String einbauen
          clr.w     d0
          swap      d0
          cmp.w     #10,d0              noch mehr als eine Ziffer ?
          bhs       dezaus1
dezaus10  add.b     #'0',d0           hîchste Ziffer ausgeben
          move.b    d0,-(a0)
          rts
          ds.b      10                  Zahl hat max. 10 Stellen
dezstr    dc.w      0
          ;
dezausw   bsr       dezaus              * Wort dezimal ausgeben *
          bra       zeilaus
          ;
dezausl   divu      #10000,d0           * Long dezimal ausgeben *
          move.w    d0,-(sp)
          swap      d0
          bsr       dezaus              letzte 4 Stellen berechnen
          tst.w     (sp)                mehr als 4 Stellen ?
          beq.s     dezausl1
          move.l    #dezstr,d0
          subq.l    #4,d0
dezausl2  cmp.l     d0,a0               -> auf 4 Stellen strecken
          bls.s     dezausl1
          move.b    #'0',-(a0)
          bra       dezausl2
dezausl1  move.w    (sp)+,d0
          beq       zeilaus
          bsr       dezaus2             Obere Stellen berechnen ...
          bra       zeilaus             ... und ausgeben
          ;
getval    and.w     #%11011111,d0       * ASCII-Wert in 4-Bit-Nibble *
          sub.b     #16,d0
          bmi.s     getvalx
          cmp.b     #10,d0
          blo.s     getvalr             0 bis 9
          sub.b     #39,d0
          cmp.b     #10,d0
          blo.s     getvalx
          cmp.b     #16,d0              A bis F / a bis f
          bhs.s     getvalx
getvalr   rts
getvalx   moveq.l    #-1,d0             Fehler
          rts
          ;
readnum   clr.l     d0                  * Zahl einlesen *
read1     move.b    (a0)+,d0            A0/D6: Anfang/Ende Zeile
          cmp.b     #' ',d0           D1: Zahl
          bne.s     read2               Leerzeichen vor Zahl erlaubt
          cmp.l     d6,a0               Zeilenende erreicht ?
          blo       read1
readerr   subq.l    #1,a0               ja -> keine Zahl -> Fehler
          bra       dolinsyn
read2     cmp.b     #'$',d0
          beq.s     readhex             Zahl ist hexadezimal
          subq.l    #1,a0
          ;
readdez   clr.l     d0                  * Dezimalzahl einlesen *
          move.b    (a0)+,d0
          sub.b     #'0',d0
          bmi       readerr             keine einzige Ziffer
          cmp.b     #10,d0
          bhs       readerr             keine einzige Ziffer
          clr.l     d1
          move.b    d0,d1
read3     cmp.l     d6,a0               Zeilenende erreicht ?
          bhs.s     readx
          move.b    (a0)+,d0            nÑchstes Zeichen holen
          sub.b     #'0',d0
          bmi.s     readrts
          cmp.b     #10,d0
          bhs.s     readrts
          cmp.w     #6554,d1            Zahl wird/war zu groû ?
          bhs.s     read4
          mulu      #10,d1              noch eine Ziffer...
          add.w     d0,d1
          bcc.s     read3
read4     move.l    #$fffff,d1          Zahl grîûer Wort -> Konstante
          bra       read3
readrts   subq.l    #1,a0               A0 zeigt immer auf 1. unverarbeitetes Byte
readx     rts
          ;
readhex   move.b    (a0)+,d0            * Sedezimalzahl einlesen *
          bsr       getval
          tst.w     d0
          bmi       readerr             keine Hex-Ziffer -> Fehler
          clr.l     d1
          move.b    d0,d1
readhex2  cmp.l     d6,a0               - Schleife -
          bhs       readx               Zeilenende -> Zahlende
          move.b    (a0)+,d0
          bsr       getval              Wert des nÑchten Zeichens
          tst.w     d0                  Fehler ?
          bmi       readrts             ja -> keine weitere Hex-Ziffer
          lsl.w     #4,d1
          and.l     #$ff,d0
          add.l     d0,d1
          bra       readhex2
          ;
dolinefi  bsr       blank               * Direktmodus / Neue Zeile *
          beq.s     dolinrts            leere Zeile -> fertig
          move.b    (a0),d0
          cmp.b     #'0',d0
          blo.s     doline1             keine Ziffer -> keine Zeilennummer
          cmp.b     #'9'+1,d0
          bhs.s     doline1             keine Ziffer
          bsr       readdez             Zahl einlesen
          bsr       blank               folgende Blanks Åberspringen
          beq.s     fodzahl3            Zeilenende -> keine Zeileneingabe
          cmp.b     #',',(a0)
          bne       readline            kein Komma -> Zeileneingabe
          bra.s     fodzahl3            normal Zahl ausgeben
          ;
doline    bsr       blank               **  Zeile ausfÅhren  **
          beq.s     dolinrts            Zeilenende -> fertig
doline1   move.b    (a0),d0
          cmp.b     #39,d0
          beq.s     fodstr              String
          cmp.b     #'$',d0
          beq.s     fodhex              Hexadezimalzahl
          cmp.b     #'0',d0
          blo.s     dolinsyn
          cmp.b     #'9',d0
          bls.s     fodzahl             Dezimalzahl
          and.b     #%11011111,d0
          cmp.b     #'A',d0
          blo.s     dolinsyn
          cmp.b     #'Z',d0
          bls       fodcom
dolinsyn  lea       syntax,a4           - Syntax-Error -
dolinrts  rts
          ;
dolinkom  bsr       blank               - Komma + nÑchster Befehl ? -
          beq       dolinrts
          cmp.b     #',',(a0)+
          bne       dolinsyn            kein Komma -> Syntax-Fehler
          cmp.l     d6,a0
          blo       doline              nÑchsten Befehl/Macro/Zahl
          rts
          ;
fodhex    addq.l    #1,a0               - Hex-Zahl lesen und senden -
          bsr       readhex
          bra.s     fodzahl1
          ;
fodzahl   bsr       readdez             - Dezimalzahl lesen und senden
fodzahl1  move.l    a4,d0
          bne       dolinrts            Fehler beim Zahleinlesen
fodzahl3  cmp.l     #$100,d1            Einsprungadresse von dolinefi
          blo.s     fodzahl2
          lea       illegal,a4          Zahl > Byte -> zu groû;Fehler
          rts
fodzahl2  move.b    testflag,d0
          bne       dolinkom            Test-Modus -> nicht drucken
          move.w    d1,d0
          bsr       drknorm             entsprechendes Zeichen ausdrucken
          move.l    a4,d0
          beq       dolinkom            nÑchster Befehl, falls fehlerfrei
          rts
          ;
fodstr    addq.l    #1,a0               - String senden -
          move.l    a0,a1
fodstr1   cmp.l     d6,a0
          bhs       getstr4             nach abschlieûendem Hochkomma suchen
          cmp.b     #39,(a0)+
          bne       fodstr1
          cmp.b     #39,(a0)
          bne.s     fodstr7             '' gefunden: ersetzt einfaches Hochkomma
          cmp.l     d6,a0
          bhs.s     fodstr7
          addq.l    #1,a0
          bra       fodstr1
fodstr7   move.b    testflag,d0         Test-Modus -> nicht drucken
          bne       dolinkom
          move.l    a0,d1               Anzahl der Zeichen
          sub.l     a1,d1
          move.b    creaflag,d0         CREATE-Modus -> String in Disk-Buffer
          bne.s     fodstr4
          subq.l    #2,d1
          bmi       dolinkom            Leerstring -> fertig
          move.l    d1,d2
fodstr2   move.b    (a1)+,d0            -- String Åbersetzen + drucken --
          cmp.b     #39,d0
          bne.s     fodstr3             2 Hochkommas werden als eines interpretiert
          addq.l    #1,a1
          subq.l    #1,d2
fodstr3   bsr.s     drucke              Drucken
          move.l    a4,d0
          bne       dolinrts            Time-Out -> Abbruch
          dbra      d2,fodstr2          nÑchstes Zeichen
          bra       dolinkom
fodstr4   subq.l    #1,d1               -- String auf Disk --
          beq       dolinkom
          move.l    a0,-(sp)
          lea       buff80,a0
          move.l    d1,d2
          subq.l    #1,d2
fodstr5   move.b    (a1)+,d0            Doppelhochkommas vereinfachen
          cmp.b     #39,d0
          bne.s     fodstr6
          subq.l    #1,d1
          subq.l    #1,d2
          addq.l    #1,a1
fodstr6   move.b    d0,(a0)+
          dbra      d2,fodstr5
          pea       buff80              ;write to Outputfile
          move.l    d1,-(sp)
          move.w    buffzeil+6,-(sp)
          move.w    #$40,-(sp)
          trap      #1
          lea       12(sp),sp
          move.l    (sp)+,a0
          tst.l     d0
          bmi       gemdoser
          cmp.l     -12(sp),d0          Disk zu voll ?
          beq       dolinkom
          lea       driveful,a4
          rts
          ;
drucke    tst.b     creaflag            ** Ein Zeichen ausgeben **
          bne.s     wrtdrk
          move.b    modeflag,d1
          beq.s     drknorm             -> Mode Original
          cmp.b     #2,d1
          beq.s     drkgemi             -> Mode XText
          ;
          move.l    a0,-(sp)            -- Mode Text --
          moveq.l   #8,d1
          lea       tabelle2,a0
drktext1  cmp.b     (a0)+,d0
          beq.s     drktext2
          addq.l    #1,a0
          dbra      d1,drktext1
          bra.s     drknorm2
drktext2  move.b    (a0),d0
          bra.s     drknorm2
drkgemi   move.l    a0,-(sp)            -- Mode XText --
          lea       tabelle,a0
          tst.b     d0
          bmi.s     drkgemi1
          cmp.b     #127,d0
          bne.s     drkgemi2
          move.w    #169,d0             D0 = 127
          bra.s     drknorm2
drkgemi2  cmp.b     #32,d0
          bhs.s     drknorm2            normales Zeichen: 32 < x < 127
          and.w     #$ff,d0
          move.b    (a0,d0.w),d0        x < 32
          bra.s     drknorm2
drkgemi1  and.w     #$7f,d0             D0 >= 128
          move.b    32(a0,d0.w),d0
          bra.s     drknorm2
          ;
drknorm   tst.b     creaflag            Ausgabe auf Disk ?
          bne.s     wrtdrk
          move.l    a0,-(sp)
drknorm2  move.w    d0,-(sp)            -- Mode Original --
          move.w    #5,-(sp)
          trap      #1                  ;printer_output
          addq.l    #4,sp
          tst.w     d0
          bne.s     drknorm1
          lea       drucker,a4          Fehler beim Drucken (Time-Out)
drknorm1  move.l    (sp)+,a0
          rts
wrtdrk    move.l    a0,-(sp)            * 1 Byte auf Disk schreiben *
          lea       buffzeil+6,a0
          move.b    d0,2(a0)
          pea       2(a0)               ;write
          move.l    #1,-(sp)
          move.w    (a0),-(sp)
          move.w    #$40,-(sp)
          trap      #1
          lea       12(sp),sp
          move.l    (sp)+,a0
          tst.l     d0                  Fehler ?
          bmi       gemdoser
          rts
          ;
*----------------------------------------------------------STEUERSEQUENZEN
initstr   dc.b   27,'E',27,'b',15,27,'c',16
          dc.b   '****  Drucker Editor 2.03  Ω Th. Zîrner 1986-90  ****',13,10,10,27,'w',0
initstr2  dc.b   ' Bytes fÅr Text frei',13,10,0
initstr3  dc.b   'Kein Drucker an Centronics-Schnittstelle angeschlossen',10,13,0
delstr    dc.b   27,'D ',27,'D',0
setpos    dc.w   $1b59,'##',0
nolores   dc.b   27,'E',27,'Y',32+8,32,27,'f'
          dc.b   ' ©------------------------------------™',10,13
          dc.b   ' |                                    |',10,13
          dc.b   ' |  Keine Textverarbeitung in Lo-Res  |',10,13
          dc.b   ' |                                    |',10,13
          dc.b   ' |      Umschalten in  Mid-Res ?      |',10,13
          dc.b   ' |                                    |',10,13
          dc.b   ' |                                    |',10,13
          dc.b   ' |         J=Ok     N=Abbruch         |',10,13
          dc.b   ' --------------------------------------',10,13,0
*------------------------------------------------------------MELDUNGEN
syntax    dc.b      'Syntax - Fehler',0
drucker   dc.b      'Der Drucker reagiert schon 30 s nicht',0
driveful  dc.b      'Diskette ist voll - Abbruch',0
illegal   dc.b      'Zahl zu groû - nur Bytes erlaubt',0
tabswid   dc.b      'Tabulator zu groû - nur Spalte 0 bis 79 mîglich',0
getchrnr  dc.b      27,'B',27,'l',27,'pZeichencode-Nr.: ',0
getchrn1  dc.b      27,'l',27,'q',27,'Y# ',0
keiversc  dc.b      'Rekursive Funktionsverschachtelung - Abbruch',0
*-------------BUFFER------------------------------------------------------------------------BUFFER---
tabs      dc.b      0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0
          dc.b      0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
funkbuff  dc.w      41,$d,$a,39,$4b00,$4b00,$4b00,$1c0d,0,0,0,0,0,0,0
          dc.w      $6200,$4700
          dc.b      'xLxIxSxTx xPx2x2x-xC'
          dc.w      $1c0d,0
          dc.w      $6200,$4700
          dc.b      'xLxIxSxTx xCx-xNx2x2'
          dc.w      $1c0d,0
funkdata  dc.w      0,0  ;Flags gedr.F-Tasten/Verschachtelungstiefe
*-----------------------------------------------------------------------ADRESSEN---
memtop    ds.l      1
logbase   ds.l      1
textbase  ds.l      1
funkbase  ds.l      1
*----------------------------------------------------------------MODE XTEXT-DATA---
tabelle   dc.b      000,164,165,167,166,239,239,239,008,009,010,011,012,013,014,015
          dc.b      048,049,050,051,052,053,054,055,056,057,218,027,028,029,030,031
          dc.b      194,216,219,196,214,193,196,194,218,218,221,105,105,105,209,177
          dc.b      069,032,032,111,215,111,220,220,121,210,211,212,195,208,217,223
          dc.b      097,105,111,220,222,110,097,111,063,240,242,206,204,105,060,032
          dc.b      196,111,048,111,032,032,192,192,210,032,039,200,032,203,203,020
          dc.b      032,032,032,032,032,032,032,032,032,032,032,032,032,032,032,032
          dc.b      032,032,032,032,032,032,032,032,032,032,032,032,032,201,094,186
          dc.b      032,217,032,187,184,185,197,032,032,179,182,032,032,178,032,032
          dc.b      032,188,032,032,032,032,191,032,198,198,032,032,032,032,032,032
tabelle2  dc.b      148,215,225,217,154,211,153,210,132,214,129,216,142,209,221,201,158,217
          ;
          align     2
          END
