 ;section eins ;                                          E I . A S M
 ;title    EI: Befehlsinterpreter fÅr Macro+Zeileneditor in CLI-EDIT
 ;pagelen  32767
 ;pagewid  133
 ;
 XREF befehle,blank,breakvor,buff12,buff80,buffzeil,check,chkstep
 XREF chkwith,copycom,creaflag,curradr,currlin,dellins,dezaus2,dezausw
 XREF dezstr,doline,dolinkom,dolinsyn,drknorm,eradat,fijodata
 XREF findadr,findflag,fiwoflag,fodcomsf,gemdoser,getsetas,getsnasp
 XREF getspec,getstr,illegal,inslins,inslinse,inzeile,linfed,loadmang
 XREF lprtflag,macros,memtop,modeflag,newline,nocomhre,nospezi,getfiln
 XREF readlin0,readnum,repldata,runflag,savestr,setpat,syntax,tabelle
 XREF tabs,tabswid,testflag,wromaker,zeilaus,dezausl,saveflag
 XREF textbase
 ;XREF funkbase
 ;
 XDEF fodcom,nospequ
          ;
fodcom    move.l    a0,a1
          lea       buff80,a2
fodcomkg  cmp.l     d6,a1               -- Wort in Groûbuchst. kop.--
          bhs.s     fodcomsd
          move.b    (a1)+,d0
          cmp.b     #'a',d0
          blo.s     fodcomkk
          cmp.b     #'z'+1,d0
          bhs.s     fodcomkk
          bclr      #5,d0               zw. a und z -> vergrîûern
fodcomkk  move.b    d0,(a2)+
          bra       fodcomkg            weiter
fodcomsd  move.l    a2,d5
          lea       macros,a1           -- STEUERZEICHEN --
          bsr       fodcomsf            String suchen
          beq.s     fodcomb             nicht gefund.-> neue Testreihe
          move.b    testflag,d4
          move.l    a1,a2
fodcomnx  move.b    (a2)+,d0
          bmi.s     fodcomsk            Ende der Steuercodes ?
          tst.b     d4                  Test-Modus -> nichts drucken
          bne       fodcomnx
          bsr       drknorm             Byte senden
          move.l    a4,d0
          beq       fodcomnx
          bra       renumx
fodcomsk  cmp.b     #$ff,d0             Parameter erwartet ?
          beq       dolinkom
          bra       doline              ja -> kein Komma erwarten
          ;
fodcomb   lea       befehle,a1          -- BEFEHLE --
          bsr       fodcomsf
          beq       dolinsyn            kein Befehl -> Syntax-Fehler
          move.b    (a1),d0             Nummer des Befehls
          ;
          cmp.b     #4,d0               ------------------------------
          bhs.s     runn
          subq.b    #1,d0
          lea       modeflag,a1         * Mode: Original - XText *
          move.b    d0,(a1)
          bra       dolinkom
          ;
runn      move.b    runflag,d1          RUN-Modus -> keine Befehle
          beq.s     runm
          lea       nocomhre,a4
          rts
runm      subq.b    #4,d0
          bne       list
run       move.b    #1,runflag          * Print / Test / Create *
          bsr       blank
          bne.s     run1
          lea       buff12,a1           - keine Spezifikationen -
          move.l    textbase,4(a1)      ab der ersten Zeile
          move.w    #$ffff,2(a1)        bis zur letzten
          bra.s     run2
run1      bsr       getspec             -- Spezifikation holen --
          move.l    a4,d0
          bne       runrts              Syntax-Fehler
          tst.w     buff12
          beq       runrts              keine weiteren Specs
run2      move.l    buff12+4,a1
          move.w    buff12+2,d5
          movem.l   a0/d6,-(sp)
run3      tst.w     (a1)                -- Spezifikation abarbeiten --
          beq       run4                Text zuende -> fertig
          cmp.w     (a1),d5
          blo       run4                fertig
          lea       curradr,a0
          move.l    a1,(a0)
          move.w    (a1),4(a0)
          clr.l     d0
          move.b    2(a1),d0            LÑnge der Zeile
          lea       3(a1),a0            Beginn der Zeile im Speicher
          move.l    a0,d6
          add.l     d0,d6               Ende der Zeile im Speicher
          subq.l    #1,d6
          movem.l   a1/d5,-(sp)
          move.l    a0,-(sp)
          move.w    #-1,-(sp)           - kbshift: abbrechen ? -
          move.w    #11,-(sp)
          trap      #13
          addq.l    #4,sp
          and.b     #%1111,d0
          tst.b     d0                  Status- Taste gedrÅckt ?
          beq.s     run6
run7      btst      #0,d0
          bne.s     run8
          lsr.b     #1,d0
          bra       run7
run8      cmp.b     #1,d0               mehr als eine Taste ?
          bls.s     run6
          addq.l    #4,sp               Abbruch !!
          movem.l   (sp)+,a1/d5
          bsr       newline
          lea       breakvor,a0         "Unterbrochen vor Zeile ..."
          bsr       zeilaus
          bra.s     run9
run6      move.l    (sp)+,a0
          bsr       doline              - Zeile ausfÅhren -
          movem.l   (sp)+,a1/d5
          move.l    a4,d0               Fehler aufgetreten ?
          beq.s     run5
          bsr       newline             - Fehler  -
          move.l    a4,a0               Meldung ausgeben, ...
          bsr       zeilaus
          lea       inzeile,a0          " in Zeile " und ...
          bsr       zeilaus
run9      move.w    (a1),d0             Zeilennummer anhÑngen
          bsr       dezausw
          sub.l     a4,a4               Fehler ist ausgegeben -> Ok
          addq.l    #8,sp               A0/D6 Åberspringen
          lea       runflag,a1
          clr.b     (a1)
          moveq.l   #-1,d0
          rts
run5      addq.l    #2,a1               - keine Fehler -
          clr.l     d0
          move.b    (a1)+,d0            A1 auf nÑchste Zeile
          add.l     d0,a1
          bra       run3                Text weiter drucken
run4      movem.l   (sp)+,a0/d6
          bsr       blank               -- nÑchst Spez. suchen --
          bne.s     run10               Zeilenende -> fertig
          move.b    testflag,d0
          beq.s     runrts
          lea       buff80,a4
          move.l    #$4f6b0000,(a4)     Test-Modus -> Ok ausgeben
          bra.s     runrts
run10     cmp.b     #',',(a0)+
          beq       run1                weiteren Spez. folgen
          lea       syntax,a4           kein Komma -> Syntax-Fehler
runrts    clr.b     runflag             wieder im Direktmodus
          rts
          ;
list      subq.b    #1,d0
          bne       lprint
list15    bsr       copycom             * List *
          bsr       blank
          bne.s     list1
          move.l    textbase,a1         - Totales Listing -
          move.w    (a1),d0
          lea       buff12,a1
          move.w    d0,(a1)+            von der ersten...
          move.w    #$ffff,(a1)+        ...bis zur letzten Zeile
          move.l    textbase,(a1)
          bra.s     list2
list1     bsr       getspec             - Spezifikationiert -
          move.l    a4,d0
          bne       return1             Syntax-Fehler
          tst.w     buff12
          beq       return1             keine weiteren Specs
list2     move.l    a0,-(sp)
          move.l    buff12+4,a1         -- Listen --
          move.w    buff12+2,d5         D5: Letzte Zeile des Listings
list4     tst.w     (a1)
          beq       list5               Null-Zeile=Letzte -> fertig
          cmp.w     (a1),d5             erreichte Zeile > zu erreich.?
          blo       list5               ja -> fertig
          move.b    findflag,d0
          bne       find2               FIND-Modus -> Zeile prÅfen
list14    lea       curradr,a0
          move.l    a1,(a0)
          move.w    (a1),4(a0)
          bsr       linfed              neue Zeile
          move.w    (a1)+,d0
          lea       dezstr,a0
          move.l    a0,a2
          bsr       dezaus2             - Zeilennr.in String wandeln
          move.l    a2,d0
          move.l    a5,a2
          moveq.l   #5,d3
list6     move.b    (a0)+,(a2)+         Nr.in Bildschirmspeicher
          subq.b    #1,d3
          cmp.l     d0,a0               ... also in Ausgabestring
          blo       list6
list16    move.b    #' ',(a2)+        - folgendes Blank -
          dbra      d3,list16
          clr.b     (a2)
          move.l    a5,a0
          bsr       zeilaus             und ausgeben
          clr.l     d3
          move.b    (a1)+,d3            D3: LÑnge der Zeile
          move.l    a1,a4               A4: Position im Textspeicher
          add.l     d3,a1               A1 auf nÑchste Zeile und sich.
          movem.l   a1/a5,-(sp)
          move.l    a2,a5               A5: Pos im Bildspeicher
          subq.b    #2,d3
          clr.w     d4                  bcounout-Trap vorbereiten
          subq.l    #6,sp
list3     move.b    (a4)+,d4            - Text -
          move.b    d4,(a5)+            Zeichen in Bildschirmspeicher
          move.w    d4,4(sp)
          move.w    #5,2(sp)            Zeichen ausgeben
          move.w    #3,(sp)
          trap      #13
          dbra      d3,list3
          addq.l    #6,sp
list10    move.w    #-1,-(sp)           kbshift
          move.w    #11,-(sp)
          trap      #13
          addq.l    #4,sp
          move.b    d0,d1
          and.b     #3,d1               SHIFT -> Listing anhalten
          bne       list10
          btst      #3,d0
          beq.s     list13
          movem.l   (sp)+,a1/a5         Alternate -> Listing abbrechen
          move.l    (sp)+,a0
          sub.l     a4,a4
          bra.s     return1
list13    btst      #2,d0
          beq.s     list8
          move.l    #$fffe,d0           Control -> Zeitschleife
list12    move.l    d0,d1
          move.l    d0,d1
          dbra      d0,list12
list8     movem.l   (sp)+,a1/a5
          sub.l     a4,a4
          bra       list4               NÑchste Zeile Listen
list5     move.l    (sp)+,a0            - Spezifikation abgearbeitet -
          bsr       blank
          beq.s     return1             Zeilenende -> fertig
          cmp.b     #',',(a0)+
          beq       list1               weiteren Spez folgen
          lea       syntax,a4           kein Komma -> Syntax-Fehler
return1   rts
          ;
lprint    subq.b    #1,d0
          bne.s     findword
          move.b    #1,lprtflag         * LPrint *
          bsr       list15
          clr.b     lprtflag
          rts
          ;
findword  subq.b    #1,d0
          bne.s     find
          cmp.b     #':',(a0)         * Find Word *
          bne.s     findwor3
          addq.l    #1,a0               Ersatzzeichen-Def.
          lea       fijodata,a1
          move.b    #1,(a1)
          move.b    (a0)+,1(a1)
findwor3  bsr       getstr
          move.l    a4,d0
          bne.s     findxx
          clr.w     d2
          move.b    d1,d2
          beq.s     find0
          bsr.s     findwor1
          bra.s     find0
findwor1  move.b    (a1),d0             -- Klein- zu Groûbuchstaben --
          cmp.b     #'a',d0
          blo.s     findwor2
          cmp.b     #'z',d0
          bhi.s     findwor2
          bclr      #5,(a1)
findwor2  addq.l    #1,a1
          dbra      d2,findwor1
          move.b    #1,fiwoflag         Find_Word-Modus
          rts
findxsy   lea       syntax,a4
findxx    clr.w     fijodata
          clr.b     findflag
          clr.b     fiwoflag
          rts
          ;
find      subq.b    #1,d0
          bne       replace
          cmp.b     #':',(a0)         * Find *
          bne.s     find7
          addq.l    #1,a0               Ersatzzeichen im String
          lea       fijodata,a1         (d.h. einige Stellen werden
          move.b    #1,(a1)             beim Vergleich nicht beachtet)
          move.b    (a0)+,1(a1)
find7     bsr       getstr
          move.l    a4,d0
          bne       findxx
find0     move.b    d1,findflag
find00    bsr       blank
          cmp.b     #',',(a0)
          bne.s     find1
          addq.l    #1,a0               Komma nach String ÅberflÅssig
find1     bsr       list15
          clr.b     findflag
          clr.b     fiwoflag
          clr.w     fijodata
          move.b    repldata,d0
          beq.s     find2-2
          move.l    a0,-(sp)            Anz. Modifikationen ausgeb.
          bsr       newline
          move.l    modanz,d0
          beq.s     find9
          lea       saveflag,a0         Flag: Datei verÑndert
          sne.b     (a0)
find9     bsr       dezausl
          lea       modrestr,a0
          bsr       zeilaus
          move.l    (sp)+,a0
          clr.w     repldata
          rts
find2     lea       2(a1),a0            ------------------------------
          move.b    findflag,d0         LÑnge
          subq.b    #1,d0
          clr.w     d1
          move.b    (a0)+,d1
          cmp.b     #' ',-2(a0,d1.w)
          bne.s     find8
          subq.b    #1,d1               Blank am Zeilenende ignorieren
find8     subq.b    #2,d1
          sub.b     d0,d1
          bmi.s     find4               Zeile kÅrzer als Test-String
          clr.l     d4
          move.b    d0,d4
          move.l    a0,d3
          tst.b     fijodata            find_str_with_joker-Modus
          bne.s     find20
          move.b    fiwoflag,d0         find_word-Modus ?
          bne       find10
find3     lea       buff80,a2           -- Find String --
          move.l    d3,a0
          move.w    d4,d0
find6     cmp.b     (a0)+,(a2)+
          bne.s     find5               ungleich
          dbra      d0,find6
          move.b    repldata,d0         REPLACE-Modus ?
          beq       list14
          bsr       replace3
find5     addq.l    #1,d3
          dbra      d1,find3
find4     clr.l     d0                  nicht listen
          addq.l    #2,a1
          move.b    (a1)+,d0
          add.l     d0,a1
          movem.l   a1/a5,-(sp)
          bra       list10              nicht listen
find20    move.w    d5,-(sp)            -- Find/Word mit Joker --
          move.w    fijodata,d5
find24    lea       buff80,a2
          move.l    d3,a0
          move.w    d4,d0
find23    cmp.b     (a2),d5             "Egal"-Zeichen ?
          beq.s     find21
          move.b    (a0)+,d2
          tst.b     fiwoflag            find_word-Modus ?
          beq.s     find25
          cmp.b     #'a',d2           -> Buchst.-Grîûe miûachten
          blo.s     find25
          cmp.b     #'z'+1,d2
          bhs.s     find25
          bclr      #5,d2
find25    cmp.b     (a2)+,d2            Zeichen vergleichen
          bne.s     find22              ungleich
          dbra      d0,find23
          move.b    repldata,d0         REPLACE-Modus ?
          beq.s     find26
find27    bsr       replace3
find22    addq.l    #1,d3
          dbra      d1,find24
          move.w    (sp)+,d5
          bra       find4
find21    addq.l    #1,a2               Joker Åberspringen
          addq.l    #1,a0
          dbra      d0,find23
          move.b    repldata,d0
          bne.s     find27
find26    move.w    (sp)+,d5
          bra       list14
find10    lea       buff80,a2           -- Find Word --
          move.l    d3,a0
          move.w    d4,d0
find11    move.b    (a0)+,d2
          cmp.b     #'a',d2
          blo.s     find13
          cmp.b     #'z'+1,d2
          bhs.s     find13
          bclr      #5,d2
find13    cmp.b     (a2)+,d2
          bne.s     find12              ungleich
          dbra      d0,find11
          move.b    repldata,d0         REPLACE-Modus ?
          beq       list14
          bsr       replace3
find12    addq.l    #1,d3
          dbra      d1,find10
          bra       find4
          ;
replace   subq.b    #1,d0
          bne       replwo
          cmp.b     #':',(a0)         * Replace *
          bne.s     replace1
          addq.l    #1,a0               Ersatzzeichen-Def.
          lea       fijodata,a1
          move.b    #1,(a1)
          move.b    (a0)+,1(a1)
replace1  lea       modanz,a1           ZÑhler Anz VerÑnderungen
          clr.l     (a1)
          bsr       getstr
          move.l    a4,d0
          bne       findxx
          tst.b     d1                  Nulstring -> Fehler
          beq       findxsy
replace2  move.b    d1,findflag
          bsr       blank
          beq       findxsy
          lea       chkwith,a2          "with" oder Komma erwarten
          bsr       check
          move.l    a4,d0
          bne       findxx
          lea       buff80,a1
          add.l     d1,a1
          bsr       getstr+4            Ersatz-String lesen
          move.l    a4,d0
          bne       findxx
          lea       repldata,a1
          move.b    #1,(a1)
          subq.b    #1,d1
          move.b    d1,1(a1)
          bra       find00              ------------------------------
replace3  clr.l     d0
          move.b    repldata+1,d0
          addq.l    #1,modanz
          cmp.b     d0,d4
          bne.s     replace6
          sub.w     d4,a0               -- String gleichlang --
          subq.l    #1,a0
replace4  move.b    (a2)+,(a0)+
          dbra      d0,replace4
          add.l     d4,d3
          sub.w     d4,d1
          bpl.s     replace5
          clr.w     d1
replace5  rts
replace6  movem.l   a1/d1/d3/d5,-(sp)   -- KÅrzen / VerlÑngern --
          addq.l    #2,a1
          clr.l     d5
          move.b    (a1)+,d5            D5: LÑnge alte Zeile
          subq.b    #1,d5
          lea       buffzeil,a0
replace8  cmp.l     d3,a1               Anfang der Zeile kopieren
          bhs.s     replace7
          move.b    (a1)+,(a0)+
          bra       replace8
replace7  tst.b     d0                  neuen String einfÅgen
          bmi.s     replace9
          add.l     d0,4(sp)
replac10  move.b    (a2)+,(a0)+
          dbra      d0,replac10
replace9  add.w     d4,a1               Rest der Zeile anhÑngen
          addq.l    #1,a1
          move.l    12(sp),d2
          add.l     d5,d2
          addq.l    #3,d2               D2: Zeiger hinter Zeile
replac11  cmp.l     d2,a1
          bhs.s     replac12
          move.b    (a1)+,(a0)+
          bra       replac11
replac12  move.l    a0,d0
          sub.l     #buffzeil,d0
          beq.s     replac19            leere Zeile -> vîllig lîschen
          btst      #0,d0
          beq.s     replac13            ZeilenlÑnge begradigen
          cmp.b     #' ',-1(a0)
          bne.s     replac14
          subq.b    #1,d0
          bra.s     replac13
replac14  move.b    #' ',(a0)
          addq.b    #1,d0
replac13  move.w    d0,d3               D3: LÑnge der neuen Zeile
          move.l    12(sp),a1
          addq.l    #2,a1
          cmp.b     d5,d0
          beq.s     replac16
          blo.s     replac15
          sub.b     d5,d0               Zeile verlÑngern
          bsr       inslins
          move.l    a4,d1
          bne.s     replac18            Fehler
          bra.s     replac16
replac15  move.b    d5,d0               Zeile verkÅrzen
          sub.b     d3,d0
          bsr       dellins
replac16  move.l    a1,d1               neue Zeile in Speicher
          addq.b    #1,d3
          move.b    d3,(a1)+
          subq.b    #2,d3
          lea       buffzeil,a0
replac17  move.b    (a0)+,(a1)+
          dbra      d3,replac17
          move.l    d1,a0
          move.b    (a0),(a1)
          movem.l   (sp)+,d1/d3/d5/a1
          sub.b     d4,d1
          bpl.s     replac18-2
          clr.w     d1
          rts
replac18  movem.l   (sp)+,d1/d3/d5/a1   Abbruch
          rts
replac19  move.l    12(sp),a1           Zeile entfernen
          move.l    d2,d0
          sub.l     a1,d0
          addq.b    #1,d0
          bsr       dellins
          movem.l   (sp)+,d1/d3/d5/a1
          clr.w     d1
          rts
          ;
replwo    subq.b    #1,d0
          bne.s     save
          cmp.b     #':',(a0)         * Replace Word *
          bne.s     replwo1
          addq.l    #1,a0               Ersatzzeichen-Def.
          lea       fijodata,a1
          move.b    #1,(a1)
          move.b    (a0)+,1(a1)
replwo1   bsr       getstr              Suchstring lesen
          move.l    a4,d0
          bne       findxx
          clr.w     d2
          move.b    d1,d2
          beq       findxsy             Nulstring -> Fehler
          bsr       findwor1
          bra       replace2
          ;
save      subq.b    #1,d0
          bne       load
          bsr       getfiln             * Save *
          clr.l     d2                  D2: Flags fÅr Header/Create
          move.l    textbase,d4         D4: Zeiger auf Sicherungsbeg.
          move.l    a3,d3               D3: Sicherungsende
          bsr       blank               kommt noch was ?
          beq.s     save2
          bset      #2,d2               Flag: Spec vorh.
          cmp.b     #',',(a0)
          bne.s     save3               kein Komma -> egal
          addq.l    #1,a0               Komma Åberspringen
save3     bsr       getspec             -- Spec - Routine --
          move.l    a4,d0
          bne       renumx              Syntax-Fehler
          tst.w     buff12
          beq       nospequ             keine  Spezifikation -> Fehler
          move.l    buff12+4,d4         Adr der 1.Zeile=Sicherungsbeg.
          move.w    buff12+2,d1
          move.l    buff12+8,a1
          move.l    a1,d3
          bne.s     save5
          move.l    d4,a1
          bsr       findadr+4           Adresse der 2. Zeile suchen
          move.l    a1,d3
save5     cmp.w     (a1),d1             Ende-Zeile vorhanden ?
          bne.s     save2
          moveq.l   #3,d0               ja -> mitspeichern
          add.b     2(a1),d0
          add.l     d0,a1
          move.l    a1,d3               D3: zeigt hint.letzt.sich.Byte
save2     move.l    a0,a2               -- Disk-Routine --
          btst      #0,d2               Datei schon creiert ?
          bne.s     save8
          bset      #0,d2
          clr.w     -(sp)               create
          pea       buff80
          move.w    #$3c,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.l     d0                  Fehler ?
          bmi       gemdoser
          move.w    d0,d5               D5: Handle
save8     sub.l     d4,d3               LÑnge = Null ?
          beq.s     save7
          btst      #1,d2               Header schon geschrieben ?
          bne.s     save4
          bset      #1,d2
          move.l    a2,a0               - Header codieren -
          bsr       blank               weitere Specs ?
          lea       savestr,a0
          sne.b     15(a0)              Kennzeichen fÅr vermutlich...
          move.l    d4,a1               falsche Nummerierung
          move.w    (a1),16(a0)
          eor.w     #$c957,16(a0)
          move.l    a0,-(sp)            write Header
          move.l    #18,-(sp)
          move.w    d5,-(sp)
          move.w    #$40,-(sp)
          trap      #1
          add.w     #12,sp
          tst.w     d0                  Fehler ? -> ausgeben
          bmi.s     save1
save4     move.l    d4,-(sp)            write Text
          move.l    d3,-(sp)
          move.w    d5,-(sp)
          move.w    #$40,-(sp)
          trap      #1
          lea       12(sp),sp
          tst.l     d0                  Fehler ?
          bmi.s     save1
save7     move.l    a2,a0               -- FortfÅhr - Routine --
          bsr       blank
          beq.s     save6               noch Specs da ?
          bset      #2,d2
          cmp.b     #',',(a0)+
          beq       save3
          lea       nospezi,a4          kein Komma -> Fehler
save6     btst      #2,d2
          bne       loadclo
          lea       saveflag,a1         Flag: Datei gesichert
          clr.b     (a1)
          bra       loadclo
save1     bsr       gemdoser            Fehlerbehandlung
          bsr       loadclo
          move.l    d6,a0
          lea       buff80,a1
          bra       eradat              Datei lîschen
          ;
load      subq.b    #1,d0
          bne       renum
          bsr       getfiln             * Load *
          clr.l     d4                  D4: Hw: STEP / Lw: Beginn-Nr.
          bsr       blank               kommt noch was ?
          beq.s     load8
          cmp.b     #',',(a0)         -- Spez verarbeiten --
          bne.s     load4
          addq.l    #1,a0               Komma -> öberspringen
load4     clr.l     d3                  D3: Merkmal, ob Nr.vorgegeben
          bsr       readnum             Zahl einzulesen versuchen
          move.l    a4,d0
          beq.s     load5
          sub.l     a4,a4               Fehler-> keine Z-Nr. vorgegeb.
load8     moveq.l   #1,d3               Meldung lîschen, mit D3 merken
          move.l    a3,a1
          move.l    textbase,a2
          tst.w     (a2)
          beq.s     load7               Speicher noch leer
          move.b    -(a1),d4
          sub.l     d4,a1
          subq.l    #2,a1
          move.w    (a1),d4             Hîchste Zeilennummer
          move.l    a3,a1
          bra.s     load7
load5     tst.w     d1                  Zeilennummer = 0 ?
          beq       readlin0            ja -> Fehlermeldung
          cmp.l     #$10000,d1          > 65535 ?
          bhs       readlin0
          move.w    d1,d4
load7     bsr       blank               kommt noch was ?
          beq.s     load3
          lea       chkstep,a2          "STEP" ?
          bsr       check
          move.l    a4,d0               nein -> Fehler
          bne       renumx
          bsr       readnum             Schrittweite lesen
          move.l    a4,d0
          bne       renumx              Fehler -> Abbruch
          swap      d4
          move.w    d1,d4               D4-HW: Schrittweite
          swap      d4
load3     pea       buffzeil            ;set_DTA   -- Fileverarb. --
          move.w    #$1a,-(sp)
          trap      #1
          addq.l    #6,sp
          move.w    #$27,-(sp)          ;search_first
          pea       buff80
          move.w    #$4e,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.l     d0                  Datei gefunden ?
          bne       gemdoser
          lea       buffzeil+26,a0
          move.l    (a0),d2             D2: LÑnge der Datei
          clr.w     -(sp)               open
          pea       buff80
          move.w    #$3d,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.w     d0                  Fehler ?
          bmi       gemdoser
          move.w    d0,d5               D5: Handle
          lea       buff80,a1
          move.l    a1,-(sp)            ;read: Header und 1. Zeilennr
          move.l    #20,-(sp)
          move.w    d5,-(sp)
          move.w    #$3f,-(sp)
          trap      #1
          lea       12(sp),sp
          tst.w     d0                  Fehler ?
          bmi       gemdoser
          cmp.l     #20,d2              Datei kÅrzer als Header ?
          blo       load2               -> kein TZ-Text
          btst      #0,d2               DateilÑnge ungerade ?
          bne       load2               -> kein TZ-Text
          move.w    16(a1),d0           -- gÅltiger Header ? --
          eor.w     #$c957,d0
          cmp.w     18(a1),d0
          bne       load2               Code ungÅltig
          lea       savestr,a0
          moveq.l   #14,d0
load1     cmp.b     (a0)+,(a1)+
          bne       load2               Kein Header -> Kein TZ-Text
          dbra      d0,load1
          tst.l     d4                  Step oder Startnr.vorgegeben..
          bne.s     load10              ... schon Text im Speicher -> Renumerierter Input
          tst.b     (a1)                Zeilennumerierung vermutlich falsch ->  -"-
          bne.s     load10
          move.l    memtop,d0           --- Nach NEW: Einfach einlesen ---
          move.l    textbase,a3
          sub.l     a3,d0
          sub.l     #20,d2
          sub.l     d2,d0
          subq.l    #4,d0
          bmi       inslinse            nicht genug Speicherplatz
          move.w    3(a1),(a3)+
          move.l    a3,-(sp)            read
          move.l    d2,-(sp)
          move.w    d5,-(sp)
          move.w    #$3f,-(sp)
          trap      #1
          lea       12(sp),sp
          tst.w     d0                  Fehler ?
          bmi.s     load11
          add.l     d2,a3               neues Programmende
          clr.w     (a3)
          bra       loadclo             close und ferig
load11    bsr       gemdoser
          move.l    textbase,a3
          clr.w     (a3)
          bra       loadclo
load10    bsr       loadlin             --- Renumerierter Input ---
          move.w    d4,d3               D3: aktuelle Zeilennummer
          swap      d4                  D4: Schrittweite
          move.w    d3,d1               Adresse der 1. Zeile errechnen
          bsr       findadr
          sub.l     #18,d2
          move.l    d2,d0               Platz schaffen fÅr neue Zeilen
          bsr       inslins
          move.l    a4,d0               genÅgend Speicher frei ?
          bne       renumx
          subq.l    #2,d2
          pea       2(a1)               read Text
          move.l    d2,-(sp)
          move.w    d5,-(sp)
          move.w    #$3f,-(sp)
          trap      #1
          lea       12(sp),sp
          tst.w     d0                  Fehler ?
          bmi.s     load12
          lea       2(a1),a2            A2: zeigt hinter den neuen Programmteil
          add.l     d2,a2
          clr.l     d2
          clr.l     d0
          move.w    (a2),d2
          subq.w    #1,d2               D2: max. Zeilennummer
load13    cmp.w     d3,d2
          blo       loaddel             nicht genug Nummern frei -> Abbruch
          move.w    d3,(a1)+            Zeilennummer speichern
          move.b    (a1)+,d0
          add.l     d0,a1               hinter Text der Zeile
          cmp.l     a2,a1
          bhs       loadclo             Programmende erreicht -> fertig
          add.w     d4,d3
          bcc       load13              Zeilennummer zu groû -> Abbruch
          bra       loaddel
load12    bsr       gemdoser
          addq.l    #2,d2
          bsr       dellins
          bra       loadclo
          ;
load2     bsr       loadlin             --- Norm - Editor - Text ---
          moveq.l   #20,d3              D3: LÑnge Zeile / LÑnge Buffer
          sub.l     #20,d2
          bpl.s     load28
          move.l    d2,d3               Datei kÅrzer 20 Bytes
          add.l     #20,d3
          beq       loadok              Nulldatei -> fertig
          clr.l     d2
load28    move.w    d4,d1               D4: Schrittweite / Zeilennr.
          bsr       findadr             A1: Zeiger in Programm
          lea       buff80,a4           A4: Zeiger in Buffer
          move.l    a1,a2               A2: Zeiger auf Zeile danach
          move.w    (a2),d6
          subq.w    #1,d6               D6: Zeilennummer danach
          and.l     #$ff,d5             D5: (18): Lf / LW: Dateihandle
          move.l    a1,d0
          addq.l    #2,d0
          move.l    d0,buff12+4         Buff12+4: Zeiger auf LÑnge der Zeile
          bra       load200             ------------------------------------
load20    tst.b     d3                  Buffer leer ? -> nachladen
          bne.s     load21
          move.l    #160,d0             160 Bytes buffern
          cmp.l     d0,d2
          bhs.s     load22              Datei kÅrzer ?
          move.b    d2,d0
          beq.s     load21              Datei leer -> nichts laden
load22    sub.l     d0,d2
          move.w    d0,d3
          lea       buff80,a4
          move.l    a4,-(sp)            read 160 Bytes vom Text
          move.l    d0,-(sp)
          move.w    d5,-(sp)
          move.w    #$3f,-(sp)
          trap      #1
          lea       12(sp),sp
          tst.l     d0
          bpl.s     load21
          bsr       gemdoser            Fehler -> Abbruch
          bra       loadel21
load21    swap      d3
          cmp.b     #73,d3              Zeile voll ?
          bhs.s     load23
          btst      #18,d5              letztes Zeichen LF ?
          bne.s     load23
          cmp.b     #70,d3              Zeile zu voll ...
          bls.s     load24
          cmp.b     #39,(a4)            ...fÅr folgendes Doppelhochkomma ?
          bne.s     load24
load23    and.l     #$ff,d5             -- neue Zeile --
          swap      d3
          bsr       loadsav
          move.b    #39,(a1)+           endendes Hochkomma
          add.l     #$10000,d3
          move.l    a1,d0
          btst      #0,d0
          bne.s     load26              ZeilenlÑnge falsch (ungerade) ?
          bsr       loadsav
          move.b    #' ',(a1)+
          add.l     #$10000,d3
load26    swap      d3
          move.l    buff12+4,a0
          addq.b    #1,d3
          move.b    d3,(a0)             ZeilenlÑnge speichern
          move.b    d3,(a1)+            (vor und hinter der Zeile)
          swap      d3
          tst.l     d2                  Datei zuende & ...
          bne.s     load30
          tst.b     d3                  ... Buffer leer -> Datei schlieûen; fertig
          beq.s     loadok
load30    swap      d4                  neue Nummer berechnen
          move.w    d4,d0
          swap      d4
          add.w     d0,d4               Nummer zu groû ?
          bcs.s     loadel2
load200   cmp.w     d6,d4               Zeilennummer schon vorhanden ?
          bhi.s     loadel2
          moveq.l   #6,d1               noch 6 Bytes frei ?
          bsr       loadsav1
          move.w    d4,(a1)+
          move.l    a1,buff12+4
          addq.l    #1,a1
          move.b    #39,(a1)+           beginnendes Hochkomma
          swap      d3
          move.w    #1,d3
load24    swap      d3
          bsr       loadsav             -- Zeichen abspeichern --
          move.b    (a4)+,d0
          move.b    d0,(a1)+
          add.l     #$10000,d3          Zeile lÑnger
          cmp.b     #39,d0
          bne.s     load25
          bsr       loadsav             Hochkomma -> weiteres anhÑngen
          move.b    #39,(a1)+
          add.l     #$10000,d3
load25    subq.b    #1,d3               Buffer kÅrzer
          bne.s     load29
          tst.l     d2                  letztes Zeichen Åberhaupt verarbeitet
          bne.s     load29
          swap      d3                  -> Zeile abschlieûen & fertig
          bra       load23
load29    cmp.b     #10,d0
          bne       load20
          bset      #18,d5              LF: merken
          bra       load20
          ;
loadok    sub.l     a4,a4               ----------------------------------
loadclo   move.w    d5,-(sp)            close
          move.w    #$3e,-(sp)
          trap      #1
          addq.l    #4,sp
          tst.l     d0
          bmi       gemdoser            Fehler
          rts
loadel2   lea       loadmang,a4         ----------------------------------
loadel21  move.l    buff12+4,a1
          subq.l    #2,a1
          bra.s     loaddel1
loaddel   lea       loadmang,a4         Fehlermeldung
loaddel1  move.l    a2,d0               Platz wieder lîschen
          sub.l     a1,d0
          beq       loadclo
          bsr       dellins
          bra       loadclo
loadlin   swap      d4                  ----------------------------------
          tst.w     d4                  bes. Schrittweite gewÅnscht ?
          bne.s     loadsav5
          move.w    #10,d4              nein -> 10
          swap      d4
          tst.b     d3                  Zeilennummer vorgegeben -> weg
          beq.s     loadsav5
          clr.l     d0                  - Selber 1. Zeile errechnen -
          move.w    d4,d0               D0: hîchste vorhandene Zeile
          swap      d4
          move.w    d4,d3               D3: Schrittweite
          swap      d4
          divu      d3,d0               D0 / D3 = x Rest y
          swap      d0
          sub.w     d0,d3               D3 - y
          add.w     d3,d4               + hîchste Zeilennr = Anfangs-Nr.
          rts
loadsav   moveq.l   #1,d1               ----------------------------------
loadsav1  move.l    a2,d0               genug Speicher reserviert ?
          sub.l     a1,d0
          cmp.l     d1,d0               ... min. (D1) Bytes
          bhs.s     loadsav5
          move.l    d0,loadsav4+2
          move.w    d3,d0               benîtigter Platz: Datei- + BufferlÑnge
          add.l     d2,d0
          cmp.l     d1,d0               DateilÑnge < benîtigter Platz ?
          blo.s     loadsav4            ja    : benîtigte LÑnge
          move.l    d0,d1               sonst : DateilÑnge
loadsav4  sub.l     #$00000000,d1       - noch vorhandener Platz
          btst      #0,d1               = anzufordernd.LÑnge=ungerade?
          beq.s     loadsav3
          addq.l    #1,d1               begradigen
loadsav3  move.l    d1,d0
          move.l    a4,-(sp)            A4 retten
          sub.l     a4,a4
          bsr       inslins
          move.l    a4,d1               noch genug Speicher frei ?
          beq.s     loadsav2
          addq.l    #8,sp
          bra       loadel21
loadsav2  add.l     d0,a2               Zeiger auf Zeile danach
          move.l    (sp)+,a4
loadsav5  rts
          ;
renum     subq.b    #1,d0
          bne.s     delete
          clr.w     d4                  * Renum *
          moveq.l   #10,d5
          bsr       blank
          beq.s     renum2
          bsr       getsnasp            Startnr.und Schrittweite lesen
renum2    clr.l     d0
          move.l    textbase,a1
          tst.w     (a1)                Speicher leer ?  -> fertig
          beq.s     renumx
          tst.w     d4                  Startnummer gegeben ?
          bne.s     renum3
          move.w    d5,d4
          bra.s     renum3
renum1    tst.w     (a1)
          beq.s     renumr              Ende des Textes -> fertig
          add.w     d5,d4               Zeilennummer erhîhen...
          bcs.s     renum4
renum3    move.w    d4,(a1)+            ...und abspeichern
          move.b    (a1)+,d0
          add.l     d0,a1               zur nÑchsten Zeile
          bra       renum1
renum4    moveq.l   #1,d5               Zeilennummern reichen nicht
          moveq.l   #1,d4
          lea       loadmang,a4         STEP 1 - renumerieren
          bra       renum2
renumr    move.l    curradr,a1
          move.w    (a1),currlin        Zeilennummer der akt. Zeile
renumx    rts
          ;
delete    subq.b    #1,d0
          bne.s     move
delete2   bsr       getspec             * Delete *
          move.l    a4,d0
          bne       renumx              Syntax-Fehler
          move.w    buff12,d0
          beq.s     nospequ             keine Spec -> Fehler
          move.l    a0,-(sp)
          move.w    buff12+2,d1
          move.l    buff12+8,a1         Adresse der Ende-Zeile
          move.l    a1,d0
          bne.s     delete3
          move.l    buff12+4,a1         ungÅltig -> neu berechnen
          bsr       findadr+4
delete3   cmp.w     (a1),d1
          bne.s     delete1             Ende-Znr. vorhanden ?
          moveq.l   #3,d0
          add.b     2(a1),d0            ja -> Zeile mitlîschen
          add.l     d0,a1
delete1   move.l    a1,d0               -- Zeilen lîschen --
          move.l    buff12+4,d1
          sub.l     d1,d0
          beq.s     delete4
          move.l    d1,a1
          bsr       dellins
          lea       saveflag,a0         Flag: Datei verÑndert
          move.b    #-1,(a0)
delete4   move.l    (sp)+,a0
          bsr       blank
          beq       renumx
          cmp.b     #',',(a0)+
          beq       delete2             Komma und weitere Specs
nospequ   lea       nospezi,a4
          rts
          ;
move      subq.b    #1,d0
          bne       copy
          bsr       copycom             * Move *
          lea       modanz+2,a2
          clr.w     (a2)
move0     lea       modanz,a2
          clr.w     (a2)
          bsr       getsetas
          move.l    a4,d0
          bne       renumx
          move.l    a1,d3
          move.w    (a1),d2             D2: Begrenzungs-Znr.
          cmp.l     4(a2),a1
          blo.s     move1
          cmp.l     8(a2),a1
          bhs.s     move1
          move.l    8(a2),a1
          move.w    (a1),d2
move1     move.l    4(a2),a1            A1: Beginn
          move.w    (a1),(a2)
          move.l    8(a2),a2            A2: Zeiger hinter Quell-Zeilen
          cmp.l     a1,a2
          beq       mover               nichts zu Bewegen/Renumerieren
          sub.w     #1,d2
          clr.l     d0
          bra.s     move10
move11    cmp.l     a2,a1               -- Renumerierschleife --
          bhs.s     move7
          add.w     d5,d4
          bcs.s     move12              Znr. > 65535
move10    cmp.w     d2,d4
          bhi.s     move12              Znr. > folgende Znr. -1
          move.w    d4,(a1)+
          move.b    (a1)+,d0
          add.l     d0,a1
          addq.w    #1,modanz
          bra       move11
move12    lea       loadmang,a4         Renum rÅckgÑngig machen
          moveq.l   #1,d5
          move.w    buff12,d4           alte Znr.
          move.l    buff12+4,a1
          move.l    #$ffff,d2
          bra       move10
move7     move.l    curradr,a1          -- Verschieben --
          move.w    (a1),currlin
          move.l    a4,d0               Fehler bei Renum -> Abbruch
          bne       mover
          move.l    buff12+4,a2
          cmp.l     a2,d3
          blo.s     move5
          cmp.l     buff12+8,d3
          bls.s     move8
          lea       modanz,a1           Anz. versch. Zeilen aufaddier.
          move.w    (a1)+,d0
          add.w     d0,(a1)
          move.l    d3,d5               -- Ziel Åber Quelle --
          move.l    buff12+8,d4
          sub.l     d4,d5
          sub.l     a2,d4
          move.l    a2,a1               A1: Zeiger auf unteren Block
          move.l    buff12+8,a2         A2: Zeiger auf oberen Block
          bra.s     move6
move5     lea       modanz,a1           -- Ziel unter Quelle --
          move.w    (a1)+,d0
          add.w     d0,(a1)
          move.l    d3,a1
          move.l    buff12+8,d5
          move.l    d5,d3
          sub.l     a2,d5               D5: LÑnge oberer Block
          move.l    a2,d4               D4: LÑnge unterer Block
          sub.l     a1,d4
move6     move.l    curradr,d2          -- curradr nachstellen --
          cmp.l     a1,d2
          blo.s     move13
          cmp.l     d3,d2
          bhs.s     move13
          cmp.l     a2,d2
          bhs.s     move14
          add.l     d5,curradr
          bra.s     move13
move14    sub.l     d4,curradr
move13    clr.l     d2                  D2: ZÑhler "gehobener" Bytes
          move.l    a0,-(sp)
          move.l    a1,a0               -- Verschiebe-Schleife --
          move.w    (a0),d0
move2     cmp.l     a2,a0               Im oberen oder unteren Block ?
          bhs.s     move3
          add.l     d5,a0               unten: Zeiger erhîhen
          addq.l    #2,d2
          bra.s     move3+2
move3     sub.l     d4,a0               oben : Zeiger erniedrigen
          move.w    (a0),d1
          move.w    d0,(a0)
          move.w    d1,d0
          cmp.l     a0,a1               Kopierkreis geschlossen ?
          blo       move2
          addq.l    #2,a1
          cmp.l     d4,d2               schon alle Bytes kopiert ?
          blo       move2-4
          move.l    (sp)+,a0
move8     bsr       blank
          beq.s     mover
          cmp.b     #',',(a0)+
          beq       move0
          bra       nospequ
mover     clr.l     d2
mover2    move.l    a0,-(sp)            -- Anz Mod ausgeben --
          bsr       newline
          move.w    modanz+2,d0
          beq.s     mover1
          lea       saveflag,a0         Flag: Datei verÑndert
          sne.b     (a0)
mover1    bsr       dezausw
          lea       modmostr,a0
          add.l     d2,a0
          bsr       zeilaus
          move.l    (sp)+,a0
          rts
          ;
copy      subq.b    #1,d0
          bne       test
          lea       modanz+2,a2         * Copy *
          clr.w     (a2)
copy1     lea       modanz,a2
          clr.w     (a2)
          bsr       getsetas
          move.l    a4,d0
          bne       copyr
          move.l    d6,-(sp)
          move.l    a1,d3
          move.l    8(a2),d0
          move.l    4(a2),a2
          clr.l     d6                  Ziel mitten im Quelltext ?
          cmp.l     a2,a1
          bls.s     copy9               nein, drunter
          cmp.l     d0,a1
          bhs.s     copy9               nein, drÅber
          move.l    a1,d6
          sub.l     a2,d6               D6: Anzahl der Bytes zw.Quell-
          lsr.l     #1,d6                   und Zielstart
          subq.l    #1,d6
copy9     sub.l     a2,d0
          beq.s     copy2               keine einzige Zeile -> fertig
          bsr       inslins             Speicher holen
          move.l    a4,d1
          bne       copyr1
          move.l    d0,d2               D2: Anz. der kopierten Bytes
          lsr.l     #1,d0
          subq.l    #1,d0
          tst.l     d6                  inmitten -> getrennt kopieren
          bne.s     copy6
          cmp.l     a1,a2
          bhs.s     copy8               Ziel Åber Quelle -> verschoben
          bra.s     copy8+2
copy6     sub.l     d6,d0               -- unter Quelle kopieren --
          subq.l    #1,d0
          move.w    (a2)+,(a1)+
          dbra      d6,copy6+2
          sub.l     #$10000,d6
          bpl       copy6+2
copy8     add.l     d2,a2
          move.w    (a2)+,(a1)+         -- Åber Quelle kopieren --
          dbra      d0,copy8+2
          sub.l     #$10000,d0
          bpl       copy8+2
          move.l    d3,a1               A1: Beginn neuer Text
          move.l    d3,a2
          add.l     d2,a2               A2: hinter neuem Text
          move.w    (a2),d2
          subq.w    #1,d2
          clr.l     d0
          bra.s     copy5
copy4     cmp.l     a2,a1               -- Renumerierschleife --
          bhs.s     copy2
          add.w     d5,d4
          bcs.s     copy3               Zeilennummer > 65535 ?
copy5     cmp.w     d4,d2
          blo.s     copy3               ... oder >= nÑchste Zeile ?
          move.w    d4,(a1)+
          move.b    (a1)+,d0
          addq.w    #1,modanz
          add.l     d0,a1
          bra       copy4
copy3     lea       loadmang,a4         Zeilen wieder lîschen
          move.l    a2,d0
          sub.l     a1,d0
          move.l    (sp)+,d6
          bsr       dellins             Speicher wieder lîschen
          bra.s     copyr
copy2     lea       modanz,a2
          move.w    (a2)+,d0
          add.w     d0,(a2)
          move.l    (sp)+,d6
          bsr       blank
          beq.s     copyr               keine weitere Spec
          cmp.b     #',',(a0)+
          beq       copy1
          lea       nospezi,a4
          rts
copyr1    addq.l    #4,sp
copyr     moveq.l   #modcostr-modmostr,d2
          bra       mover2
          ;
test      subq.b    #1,d0
          bne.s     create              * Test *
          move.b    #1,testflag
          bsr       run                 Test-Modus setzen ... und RUN
          clr.b     testflag
          rts
          ;                             ...und dann Run ausfÅhren
create    subq.b    #1,d0
          bne       settab
          bsr       getfiln             * Create *
          lea       buffzeil+8,a2
          clr.b     (a2)                Flag: Spec vorhanden ?
          bsr       blank
          beq.s     create1
          cmp.b     #',',(a0)+        kommt ein Komma nach Namen ?
          bne       dolinsyn
          seq.b     (a2)
create1   move.l    a0,a2
          clr.w     -(sp)               create Ausgabedatei
          move.l    a1,-(sp)
          move.w    #$3c,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.w     d0                  Fehler ?
          bmi       gemdoser
          lea       buffzeil,a1
          move.w    d0,6(a1)            Handle merken
          move.l    a2,a0
          move.l    curradr,(a1)
          move.w    currlin,4(a1)
          move.b    #1,creaflag
          bsr       run                 -- Run ausfÅhren --
          lea       buffzeil,a1
          sne.b     8(a1)               Fehler -> Datei ungesichert
          lea       curradr,a0
          move.l    (a1)+,(a0)+
          move.w    (a1)+,(a0)
          lea       saveflag,a0         Flag: Datei gesichert
          move.b    2(a1),(a0)
          move.w    (a1),-(sp)          ;close
          move.w    #$3e,-(sp)
          trap      #1
          addq.l    #4,sp
          clr.b     creaflag
          rts
          ;
settab    subq.b    #1,d0
          bne.s     guide
          lea       tabs,a1             * Set Tabs *
          moveq.l   #79,d0
settab1   clr.b     (a1)+               alte Tab-Markierungen lîschen
          dbra      d0,settab1
          lea       tabs,a1
settab2   bsr       readnum             Zahl einlesen
          move.l    a4,d0
          sub.l     a4,a4               Fehlermeldung wieder lîschen
          bne       dolinkom            keine Zahl -> Tabs sind zu Ende -> Abbruch
          cmp.b     #74,d1
          bhs.s     settab3             Zahl zu groû (nur Spalte 6 bis 79)
          move.b    #1,6(a1,d1.w)       Markierung setzen
          bsr       blank               Blanks Åberspringen
          beq       maker
          move.b    (a0)+,d0
          cmp.b     #',',d0           kommt noch was ?
          bne       dolinsyn            ja und kein Komma -> Fehler
          bra       settab2
settab3   lea       tabswid,a4          Fehlermeldung
          rts
          ;
guide     subq.b    #1,d0
          bne       make
          bsr       copycom             * Guide *
          move.l    a0,-(sp)
          bsr       linfed
          lea       buff80,a0           Zehner-Zeile erzeugen
          move.w    #'1 ',d1
          move.l    #'    ',(a0)+
          move.l    #'    ',(a0)+
          moveq.l   #6,d0
guide1    move.l    #'    ',(a0)+
          move.l    #'    ',(a0)+
          move.w    d1,(a0)+
          add.w     #$100,d1
          dbra      d0,guide1
          clr.b     (a0)+
          lea       buff80,a0
          bsr       zeilaus             ... und ausgeben
          bsr       linfed
          moveq.l   #73,d0              Tabulator-Zeile erzeugen
          lea       buff80,a0
          lea       tabs+6,a2
          move.l    #'    ',(a0)+
          move.w    #'  ',(a0)+
guide2    tst.b     (a2)+
          beq.s     guide3
          move.b    #'|',(a0)+
          bra.s     guide4
guide3    move.b    #'.',(a0)+
          moveq.l   #73,d1
          sub.l     d0,d1
          divu      #5,d1
          swap      d1
          tst.b     d1
          bne.s     guide4
          move.b    #'5',-(a0)
          btst      #16,d1
          bne.s     guide5
          move.b    #'0',(a0)
guide5    addq.l    #1,a0
guide4    dbra      d0,guide2
          clr.b     (a0)+
          lea       buff80,a0
          bsr       zeilaus
          move.l    (sp)+,a0
          bra       dolinkom
          ;
make      subq.b    #1,d0
          bne       setpat
          lea       tabelle,a2          * Make *
make5     bsr       readnum
          move.l    a4,d0
          bne.s     maker               ST-seitigen Wert lesen und prÅfen
          cmp.l     #256,d1
          bhs.s     make1
          cmp.b     #32,d1              0-31 oder 128-255
          blo.s     make6
          cmp.b     #128,d1
          blo.s     make1
make6     bsr       blank
          cmp.b     #'=',(a0)+        Zuweisungszeichen
          bne       dolinsyn
          move.l    d1,d3
          bsr       readnum             zugewiesenen Wert lesen
          move.l    a4,d0
          bne.s     maker
          cmp.l     #256,d1
          bhs.s     make2
          cmp.b     #32,d3
          blo.s     make3
          move.b    d1,-96(a2,d3.l)     Wert in Tabelle schreiben
          bra.s     make4
make3     move.b    d1,(a2,d3.l)
make4     bsr       blank
          beq.s     maker
          cmp.b     #',',(a0)+
          beq       make5
          bra       dolinsyn
make1     lea       wromaker,a4
maker     rts
make2     lea       illegal,a4
          rts
          ;
modanz    ds.l      1
modrestr  dc.b      ' Modifikationen vorgenommen',0
modmostr  dc.b      ' Zeilen wurden verschoben',0
modcostr  dc.b      ' Zeilen wurden kopiert',0
          ;
          align     2
          END
