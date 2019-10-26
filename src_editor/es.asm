; ----------------------------------------------------------------------------
; Copyright 1986-1990 by T.Zoerner (tomzo at users.sf.net)
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
 ;section eins ;                                          E S . A S M
 ;title    ES: Command-Line-Interpreter fÅr CLI-EDIT
 ;pagelen  32767
 ;pagewid  133
 ;
 XREF dezaus2,dezaus,dezausl,dolinkom,dolinsyn,escaus,memtop,newline
 XREF nospequ,print3,readdez,readnum,setcurs,syntax,zeilaus,dezausw
 XREF textbase,logbase
 ;
 XDEF alarm1,alarm3,alarmtim,almonstr
 XDEF gemdoser,getstr4,lastdrv,readline
 XDEF befehle,blank,breakvor,buff12,buff80,buffzeil,check,chkstep
 XDEF chkwith,copycom,creaflag,curradr,currlin,dellins
 XDEF eradat,eradir2,fijodata
 XDEF findadr,findflag,fiwoflag,saveflag,fodcomsf
 XDEF getspec,getstr,getfiln,getsetas,getsnasp,inslins,inslinse
 XDEF inzeile,loadmang,lprtflag,macros,modeflag,nocomhre,nospezi
 XDEF readlin0,repldata,runflag,savestr,setpat
 XDEF testflag,timeflag,wromaker,ende
          ;
setpat    subq.b    #1,d0
          bne.s     almoff
          bsr       getfiln             * CD: Set Path *
          move.l    a0,-(sp)
          move.l    a1,-(sp)            ;ch_dir
          move.w    #$3b,-(sp)
          trap      #1
          addq.l    #6,sp
          move.l    (sp)+,a0
          tst.w     d0                  Fehler ?
          bne       gemdoser
          bra       dolinkom
          ;
almoff    subq.b    #1,d0
          bne.s     alarm
          move.l    a0,-(sp)            * Alarm Off *
          pea       almofstr
          move.w    #32,-(sp)           ;dosound
          trap      #14
          addq.l    #6,sp
          clr.b     timeflag
          pea       alarm2              ;supexec
          move.w    #38,-(sp)
          trap      #14                 Sysvar.im Supervisormode regen
          addq.l    #6,sp
          move.l    (sp)+,a0
          bra       dolinkom
          ;
alarm     subq.b    #1,d0
          bne.s     time
          bsr       time_in             * Alarm *
          move.l    a4,d0
          bne       erax
          move.w    d2,alarmtim         Weckzeit merken;Flag setzen
          move.b    #1,timeflag
          move.l    a0,a2
          move.w    #$2c,-(sp)          ;gettime
          trap      #1
          addq.l    #2,sp
          move.l    a2,a0
          and.w     #$ffe0,d0
          move.w    d0,alarm3+2         Stellzeit merken
          bra       dolinkom
alarm1    move.b    $484,alarm3         !! Nur im Supervisor-Mode !!
          and.b     #$fe,$484           Tasten-Click aus
          rts
alarm2    move.b    alarm3,$484
          rts
alarm3    ds.w      2                   Weck-/Stellzeit
          ;
time      subq.b    #1,d0
          bne.s     date
          bsr       copycom             * Time *
          move.l    a0,a2
          bsr       newline
          move.w    #$2c,-(sp)          ;get_time
          trap      #1
          addq.l    #2,sp
          lea       timestr,a1
          bsr       time_out
          lea       timestr,a0
          bsr       zeilaus
          move.l    a2,a0
          bra       dolinkom
timestr   dc.b      '##:##:##',0
datestr   dc.b      '##.##.####',0
          ;
date      subq.b    #1,d0
          bne.s     settime
          bsr       copycom             * Date *
          move.l    a0,a2
          bsr       newline
          move.w    #$2a,-(sp)          ;get_date
          trap      #1
          addq.l    #2,sp
          lea       datestr,a1
          bsr       date_out
          lea       datestr,a0
          bsr       zeilaus
          move.l    a2,a0
          bra       dolinkom
          ;
settime   subq.b    #1,d0
          bne.s     setdate
          bsr       time_in             * Set Time *
          move.l    a4,d0
          bne       erax
          move.l    a0,a2
          move.w    d2,-(sp)            ;set_time
          move.w    #$2d,-(sp)
          trap      #1
          addq.l    #4,sp
          move.l    a2,a0
          bra       dolinkom
          ;
setdate   subq.b    #1,d0
          bne.s     getdir
          bsr       date_in             * Set Date *
          move.l    a4,d0
          bne       erax
          move.l    a0,a2
          move.w    d2,-(sp)            ;set_date
          move.w    #$2b,-(sp)
          trap      #1
          addq.l    #4,sp
          move.l    a2,a0
          bra       dolinkom
          ;
getdir    subq.b    #1,d0
          bne.s     setdrv
          bsr       copycom             * Get Dir *
          move.l    a0,-(sp)
          lea       buff80,a1
          move.w    #'A:',(a1)        A1: Zeiger Ausgabe-String
          move.w    #$19,-(sp)          ;current_disk
          trap      #1
          addq.l    #2,sp
          add.b     d0,(a1)             akt. Laufwerk einsetzen
          clr.w     -(sp)               ;getdir
          pea       2(a1)
          move.w    #$47,-(sp)
          trap      #1
          addq.l    #8,sp
          bsr       newline             neue Zeile beginnen
          move.l    a1,a0
          bsr       filn_out            Pfad ausgeben
          move.l    (sp)+,a0
          bra       dolinkom
          ;
setdrv    subq.b    #1,d0
          bne.s     dir
          move.l    a0,-(sp)            * Set Drive *
          move.w    #$19,-(sp)
          trap      #1                  ;current_disk
          addq.l    #2,sp
          move.l    (sp)+,a0
          move.w    d0,d5               D5: zuletzt aktives Laufwerk
          bsr       blank
          beq.s     setdrv1             kein Laufwerk angegeben
          move.b    (a0),d0
          cmp.b     #',',d0
          beq.s     setdrv1             kein Laufwerk angegeben
          and.w     #%11011111,d0
          sub.b     #'A',d0
          bmi       dolinsyn            kein gÅltiges Laufwerk
          move.l    a0,-(sp)
          move.w    d0,-(sp)            ;set_drv
          move.w    #$e,-(sp)
          trap      #1
          addq.l    #4,sp
          tst.w     d0                  Fehler ?
          bmi       gemdoser
          move.w    d5,lastdrv          bis eben akt.Laufwerk merken
          move.l    (sp)+,a0
          addq.l    #1,a0
          cmp.b     #':',(a0)         Doppelpunkt hinter Drivenr.?
          bne       dolinkom
          addq.l    #1,a0               ja -> öberspringen
          bra       dolinkom
setdrv1   move.l    a0,-(sp)
          move.w    lastdrv,-(sp)       zuletzt aktives Drive setzen
          move.w    #$e,-(sp)           ;set_drv
          trap      #1
          addq.l    #4,sp
          move.w    d5,lastdrv
          move.l    (sp)+,a0
          bra       dolinkom
lastdrv   dc.w      0                   Nr.des zuletzt akt.Laufwerks
          ;
dir       subq.b    #1,d0
          bne       mkdir
          bsr       copycom             * Dir *
          lea       diratt,a1
          clr.b     (a1)+
          move.b    #$10,(a1)+
          clr.b     (a1)+
          lea       dirnum,a1
          clr.b     (a1)
          cmp.b     #':',(a0)         -- Attribute lesen --
          bne.s     dir20
          addq.l    #1,a0
dir21     move.b    (a0)+,d0
          cmp.b     #' ',d0           Keine weiteren Att
          beq.s     dir20
          and.w     #%11011111,d0
          lea       diratt+3,a1
          moveq.l   #2,d1
dir22     cmp.b     (a1)+,d0
          beq.s     dir23
          dbra      d1,dir22
          bra       dolinsyn
dir23     seq.b     -4(a1)              Attr-Flag setzen
          bra       dir21
dir20     bsr       getfiln
          tst.b     d1                  String vorhanden ?
          bne.s     dir6
          lea       dirstr,a1           nein -> keine Spezifikation
          bra.s     dir1
dir6      cmp.b     #':',1(a1)        -- Spez. untersuchen --
          bne.s     dir11
          tst.b     2(a1)               2.Zeichen Doppelpunkt und..
          bne.s     dir11               ..String nur 2 Zeichen lang ?
          lea       dirstr1,a1          -> "*.*" anhÑngen
          move.b    buff80,(a1)
          bra.s     dir1
dir11     move.l    a1,a2               "\" am Ende ?
dir12     tst.b     (a2)+
          bne       dir12
          subq.l    #2,a2
          cmp.b     #'\',(a2)+
          bne.s     dir1
          lea       dirstr,a1           -> *.* anhÑngen
dir13     move.b    (a1)+,(a2)+
          bne       dir13
          lea       buff80,a1
dir1      move.l    a0,-(sp)
          move.w    #70,d7
          pea       buffzeil            ;set_DTA
          move.w    #$1a,-(sp)
          trap      #1
          addq.l    #6,sp
          clr.w     d0                  ;search_first
          move.b    diratt+1,d0
          move.w    d0,-(sp)
          move.l    a1,-(sp)
          move.w    #$4e,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.w     d0                  Datei gefunden ?
          bmi       dir3
dir2      lea       buffzeil,a0         -- Timestamps aussortieren --
          cmp.b     #$10,21(a0)
          bne.s     dir8
          cmp.w     #$2e00,30(a0)       falls . oder ..-Ordner:
          beq.s     dir20
          cmp.w     #'..',30(a0)
          bne.s     dir8
          tst.b     32(a0)
          bne.s     dir8
          move.b    diratt+1,d0         Nicht ausgeben ?
          bpl       dir7
          move.w    22(a0),d0           Datum und Zeit vom INTEL- ...
          ror.w     #8,d0               ..ins 68K-Format
          move.w    d0,22(a0)
          move.w    24(a0),d0
          ror.w     #8,d0
          move.w    d0,24(a0)
dir8      move.b    diratt,d0
          bne.s     dir31
          bsr       dirline             -- Namen kurz ausgeben --
          move.b    buffzeil+21,d0
          btst      #4,d0               Subdirectoryname ?
          beq.s     dir32
          moveq.l   #7,d0               -> Raute vor Namen
          bsr       print3
dir32     lea       buffzeil+30,a0
          bsr       filn_out
          add.w     #16,d7
          bra       dir7
dir31     bsr       dirline             -- Namen lang ausgeben --
          lea       buff80,a0
          move.l    #$20202020,d0       - Name -
          move.l    d0,(a0)
          move.l    d0,4(a0)
          move.l    d0,8(a0)
          move.l    d0,12(a0)
          move.l    d0,16(a0)
          lea       buffzeil+30,a1
dir34     move.b    (a1)+,(a0)+
          bne       dir34
          move.b    #32,-(a0)
          lea       buff80+20,a0        - LÑnge -
          move.l    buffzeil+26,d0
          divu      #10000,d0
          move.l    d0,d2
          swap      d0
          lea       buff80+20,a0
          bsr       dezaus2
          tst.w     d2
          beq.s     dir35
          lea       buff80+16,a1
dir36     cmp.l     a1,a0
          bls.s     dir37
          move.b    #'0',-(a0)
          bra       dir36
dir37     move.w    d2,d0
          bsr       dezaus2
dir35     lea       buff80+20,a1        - Attribut -
          move.l    #'  00',(a1)+
          move.b    buffzeil+21,d0
          move.b    d0,d1
          lsr.b     #4,d0
          cmp.b     #10,d0
          blo.s     dir38
          addq.b    #7,d0
dir38     add.b     d0,-2(a1)
          and.w     #$f,d1
          cmp.b     #10,d1
          blo.s     dir39
          addq.b    #7,d1
dir39     add.b     d1,-1(a1)
          move.w    #'  ',(a1)+       - Time -
          move.w    buffzeil+22,d0
          move.b    #':',2(a1)
          move.b    #':',5(a1)
          bsr       time_out
          move.b    #32,-1(a1)
          move.b    #32,(a1)+           - Date -
          move.w    buffzeil+24,d0
          move.b    #'-',2(a1)
          move.b    #'-',5(a1)
          clr.b     10(a1)
          bsr       date_out
          lea       buff80,a0
          bsr       filn_out
          move.w    #70,d7
dir7      move.w    #$4f,-(sp)          ;search next  -- Schl.ende --
          trap      #1
          addq.l    #2,sp
          tst.w     d0
          beq       dir2
dir3      move.l    (sp)+,a0            fertig
          bra       dolinkom
dirline   cmp.w     #70,d7              -- Cursor auf Position --
          blo       setcurs
          move.b    diratt+2,d0
          beq       newline             -> kein Paged-Output
          lea       dirnum,a0
          addq.b    #1,(a0)
          cmp.b     #25,(a0)
          blo       newline             Bildschirm noch nicht voll
          clr.b     (a0)
          bsr       newline
          lea       waitkey,a0          "Taste drÅcken"
          bsr       zeilaus
          move.w    #7,-(sp)            ;conin
          trap      #1
          addq.l    #2,sp
          moveq.l   #'l',d0
          bra       escaus
dirstr1   dc.b      'A:'
dirstr    dc.b      '*.*',0
diratt    dc.b      0,0,0,'LAP'         ; Attribute Long/All/Paged
dirnum    dc.b      0                   ; Anz ausgegeb.Zeilen
          dc.b      0                   ; filler for word-alignment
          ;
mkdir     subq.b    #1,d0
          bne.s     eradir
          bsr       getfiln             * MkDir *
          move.l    a0,a2
          move.l    a1,-(sp)            ;mkdir
          move.w    #$39,-(sp)
          trap      #1
          addq.l    #6,sp
          move.l    a2,a0
          tst.w     d0
          bne       gemdoser            Fehler
          bra       dolinkom
          ;
eradir    subq.b    #1,d0
          bne       new
          bsr       getfiln             * RmDir *
          bsr       copycom
          move.l    a0,-(sp)
          clr.b     d3
          clr.b     d4
          clr.b     d5
eradir4   move.l    a1,-(sp)            ;RmDir (Remove Directory)
          move.w    #$3a,-(sp)
          trap      #1
          addq.l    #6,sp
          tst.l     d0
          bmi.s     eradir1
          tst.b     d4                  im zu lîschenden Dir ?
          bne.s     eradir11            nein -> eines hîher
          move.l    (sp)+,a0            keine Fehler -> fertig
          bra       dolinkom
eradir1   cmp.l     #-36,d0             No-Access-Fehler ?
          bne       eradir2
          tst.b     d5                  Dritter Versuch ? -> Abruch
          bne       eradir2
          moveq.l   #1,d5               --- Directory leeren ---
          move.l    a1,-(sp)
          move.w    #$3b,-(sp)          ;chdir ins zu lîschende Dir
          trap      #1
          addq.l    #6,sp
          addq.b    #1,d4               ein Sub-Dir tiefer;merken
          lea       13(a1),a1
          pea       1000(a6)            ;set_dta
          move.w    #$1a,-(sp)
          trap      #1
          addq.l    #6,sp
eradir11  move.w    #$3f,-(sp)          ;search first
          pea       dirstr
          move.w    #$4e,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.l     d0                  Datei gefunden ?
          bmi.s     eradir6             keine einzige -> 2.Versuch
eradir5   cmp.b     #$10,1021(a6)
          bne.s     eradir7
          lea       1030(a6),a2         -- Sub-Dir lîschen --
          cmp.w     #$2e00,(a2)
          beq.s     eradir9             . und .. ignorieren
          cmp.w     #$2e2e,(a2)
          bne.s     eradir8-2
          tst.b     2(a2)
          beq.s     eradir9
          moveq.l   #12,d0
eradir8   move.b    (a2)+,(a1)+         Namen merken
          dbra      d0,eradir8
          lea       -13(a1),a1
          clr.b     d5
          bra       eradir4             ein Dir tiefer
eradir7   tst.b     d3                  schon gefragt ?
          bne.s     eradir10
          bsr       newline             -- Frage: Dateien lîschen ? --
          lea       wirera,a0
          bsr       zeilaus
          move.w    #1,-(sp)            ;conin
          trap      #1                  Antwortzeichen holen
          addq.l    #2,sp
          move.w    d0,d1
          moveq.l   #'f',d0
          bsr       escaus
          and.w     #%11011111,d1
          cmp.b     #'J',d1
          bne.s     eradir3             kein j/J ? -> Fehlermeldung
          moveq.l   #1,d3
eradir10  pea       1030(a6)            -- Datei lîschen --
          move.w    #$41,-(sp)          ;unlink
          trap      #1
          addq.l    #6,sp
          tst.l     d0                  Fehler -> Abbruch
          bmi.s     eradir2
eradir9   move.w    #$4f,-(sp)          ;search_next
          trap      #1
          addq.l    #2,sp
          tst.l     d0
          bpl       eradir5
eradir6   subq.b    #1,d4               Files und Sub-Dir gelîscht
          lea       -13(a1),a1
          lea       buffzeil,a0
          move.l    #$2e2e0000,(a0)     ;chdir ins alte Directory
          move.l    a0,-(sp)
          move.w    #$3b,-(sp)
          trap      #1
          addq.l    #6,sp
          bra       eradir4
eradir3   move.l    #-36,d0             Volles Dir nicht lîschbar ->
eradir2   move.l    (sp)+,a0            -- Fehler --
          bra       gemdoser
          ;
new       subq.b    #1,d0
          bne.s     free
          move.l    textbase,a0         * New *
          tst.w     (a0)
          beq       dolinkom
          move.b    saveflag,d0
          beq.s     new1
          lea       wirnew,a1           "Wirklich lîschen ?"
          bsr       decide
          bne       dolinkom
new1      move.l    textbase,a3
          clr.w     (a3)                erste Zeile ist Zeile Null
          lea       curradr,a1
          move.l    a3,(a1)
          move.w    #1,4(a1)
          lea       saveflag,a1         Flag: Datei gesichert
          clr.b     (a1)
          bra       dolinkom
          ;
free      subq.b    #1,d0
          bne.s     quit
          bsr       copycom             * Free *
          move.l    a0,a2
          bsr       newline             an Anfang der nÑchsten Zeile
          move.l    memtop,d0           Zeiger auf Speicherobergrenze
          sub.l     a3,d0               - Zeiger hinter letzte Zeile
          bsr       dezausl             = freie Bytes
          move.l    a2,a0
          bra       dolinkom
          ;
quit      subq.b    #1,d0
          bne.s     era
          move.l    textbase,a1         * Quit *
          tst.w     (a1)
          beq.s     quit1
          move.b    saveflag,d0
          beq.s     quit1
          lea       wirnew,a1           "Wirklich lîschen ?"
          bsr       decide
          bne.s     erax
quit1     clr.l     d0                  ;term
quit2     move.l    d0,-(sp)
          move.w    #$4c,-(sp)
          trap      #1
          bra       quit1
          ;
era       subq.b    #1,d0
          bne.s     rename
          bsr       getfiln             * Era *
eradat    move.l    a0,-(sp)            !!! Ansprungspunkt !!!
          move.l    a1,-(sp)            ;unlink
          move.w    #$41,-(sp)
          trap      #1
          addq.l    #6,sp
          move.l    (sp)+,a0
          tst.w     d0
          bmi       gemdoser
          bra       dolinkom
erax      rts
          ;
rename    subq.b    #1,d0
          bne.s     mklabel
          bsr       getfiln             * Rename *
          bsr       blank
          beq       dolinsyn
          move.l    a1,d5               D5: Zeiger auf alten Namen
          lea       chkas,a2
          bsr       check               Auf Folgendes 'as' prÅfen
          move.l    a4,d0
          bne       erax
          lea       buffzeil,a1
          bsr       getstr+4            neuen Namen einlesen
          move.l    a4,d0
          bne       erax
          move.l    a0,a2
          pea       buffzeil
          move.l    d5,-(sp)
          clr.w     -(sp)
          move.w    #$56,-(sp)          ;rename (GemDos)
          trap      #1
          lea       12(sp),sp
          move.l    a2,a0
          tst.w     d0
          bne       gemdoser
          bra       dolinkom
          ;
mklabel   subq.b    #1,d0
          bne.s     rmlabel
          bsr       getfiln             * MkLabel *
          move.l    a0,a2
          moveq.l   #8,d0
          bsr.s     rmlabel1
          move.l    a2,a0
          bra       dolinkom
          ;
rmlabel   subq.b    #1,d0
          bne.s     version
          bsr       getfiln             * RmLabel *
          move.l    a0,a2
          pea       buffzeil
          move.w    #$1a,-(sp)          ;set_DTA
          trap      #1
          addq.l    #6,sp
          move.w    #8,-(sp)            ;search_first
          move.l    a1,-(sp)
          move.w    #$4e,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.w     d0                  Label vorhanden ?
          bmi       gemdoser
          clr.w     d0
          bsr.s     rmlabel1
          pea       buff80              ;unlink
          move.w    #$41,-(sp)
          trap      #1
          addq.l    #6,sp
          tst.w     d0
          bmi       gemdoser
          move.l    a2,a0
          bra       dolinkom
rmlabel1  move.w    d0,-(sp)            - Datei erzeugen -
          move.l    a1,-(sp)
          move.w    #$3c,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.w     d0
          bmi.s     rmlabel2
          move.w    d0,-(sp)
          move.w    #$3e,-(sp)
          trap      #1
          addq.l    #4,sp
          tst.w     d0
          bmi.s     rmlabel2
          rts
rmlabel2  addq.l    #4,sp
          bra       gemdoser
          ;
version   subq.b    #1,d0
          bne.s     filetime
          bsr       copycom             * Version *
          move.l    a0,-(sp)
          bsr       newline
          lea       versistr,a0
          bsr       zeilaus
          move.w    #$30,-(sp)          ;get_vers_nr
          trap      #1
          addq.l    #2,sp
          move.w    d0,d2
          lsr.w     #8,d0
          bsr       dezausw
          moveq.l   #'.',d0
          bsr       print3
          move.w    d2,d0
          and.w     #$ff,d0
          bsr       dezausw
          move.l    (sp)+,a0
          bra       dolinkom
          ;
filetime  subq.b    #1,d0
          bne       filedate
          bsr       getfiln             * Filetime *
          bsr       blank
          beq       dolinsyn
          cmp.b     #',',(a0)+
          bne       dolinsyn
          bsr       time_in
          move.l    a4,d0
          bne       erax
          swap      d2
          clr.w     d2
          move.l    #$ffff,d3
filetim1  move.l    a0,a2
          move.w    #0,-(sp)            ;open
          pea       buff80
          move.w    #$3d,-(sp)
          trap      #1
          addq.l    #8,sp
          move.w    d0,d1
          bmi       gemdoser
          clr.w     -(sp)               ;gsd_tof (ermitteln)
          move.w    d1,-(sp)
          pea       buff12
          move.w    #$57,-(sp)
          trap      #1
          add.w     #10,sp
          lea       buff12,a0
          and.l     d3,(a0)
          or.l      d2,(a0)
          move.w    #1,-(sp)            ;gsd_tof (setzen)
          move.w    d1,-(sp)
          move.l    a0,-(sp)
          move.w    #$57,-(sp)
          trap      #1
          add.w     #10,sp
          tst.w     d0
          bmi       gemdoser
          move.l    a2,a0
          bra       dolinkom
          ;
filedate  subq.b    #1,d0
          bne.s     filemod
          bsr       getfiln             * Filedate *
          bsr       blank
          beq       dolinsyn
          cmp.b     #',',(a0)+
          bne       dolinsyn
          bsr       date_in
          move.l    a4,d0
          bne       erax
          and.l     #$ffff,d2
          move.l    #$ffff0000,d3
          bra       filetim1
          ;
filemod   subq.b    #1,d0
          bne.s     format
          bsr       getfiln             * Filemod *
          bsr       blank
          beq       dolinsyn
          cmp.b     #',',(a0)+
          bne       dolinsyn
          bsr       readnum
          and.w     #$3f,d1
          move.l    a0,a2
          move.w    d1,-(sp)            ;change_mod
          move.w    #1,-(sp)
          pea       buff80
          move.w    #$43,-(sp)
          trap      #1
          add.w     #10,sp
          tst.w     d0
          bmi       gemdoser
          move.l    a2,a0
          bra       dolinkom
          ;
format    subq.b    #1,d0
          bne       info
          lea       formaatt,a1         * Format *
          clr.w     (a1)
          move.l    memtop,d0
          sub.l     a3,d0
          cmp.l     #10240,d0           Min 10 K frei ?
          bhs.s     format19
          lea       nigenspe,a4
          rts
format19  cmp.b     #':',(a0)         -- Attribute lesen --
          bne.s     format1
          addq.l    #1,a0
format2   cmp.l     d6,a0
          bhs       dolinsyn
          cmp.b     #' ',(a0)         Keine Att mehr ?
          beq.s     format1
          move.b    (a0)+,d1
          and.w     #%11011111,d1
          lea       formaatt+2,a1
          cmp.b     (a1)+,d1            "F" ?
          beq.s     format4
          cmp.b     (a1)+,d1            "2" ?
          bne       dolinsyn
format4   seq.b     -3(a1)
          bra       format2
format1   bsr       blank               -- Disknr. best. --
          beq       dolinsyn
          move.b    (a0)+,d3
          and.w     #%11011111,d3
          sub.b     #'A',d3
          cmp.l     d6,a0
          bhs       dolinsyn
          cmp.b     #':',(a0)+
          bne       dolinsyn
          lea       wirforma,a1         -- Frage --
          bsr       decide
          bne       formatx
          move.l    a0,a2
          clr.l     d4                  -- Formatieren --
format6   clr.w     d4
format7   move.w    #$e5e5,-(sp)
          move.l    #$87654321,-(sp)
          move.w    #1,-(sp)
          move.l    d4,-(sp)            LW: Seite/HW: Track
          move.w    #9,-(sp)
          move.b    formaatt,d0
          beq.s     format11
          addq.w    #1,(sp)             Fat-Disk: 10 Sektoren
format11  move.w    d3,-(sp)            Disknr.
          clr.l     -(sp)
          pea       2(a3)
          move.w    #10,-(sp)
          trap      #14
          add.w     #26,sp
          tst.w     d0
          bmi       gemdoser
          move.b    formaatt+1,d0       2-seitig formatieren ?
          beq.s     format12
          tst.w     d4
          bne.s     format12
          addq.w    #1,d4
          bra       format7
format12  add.l     #$10000,d4
          cmp.l     #$500000,d4
          blo       format6
          clr.w     -(sp)               -- Bootsektor --
          move.w    #2,-(sp)
          move.b    formaatt+1,d0
          beq.s     format13
          addq.w    #1,(sp)             2-seitige Disk
format13  move.l    -1,-(sp)
          pea       2(a3)
          move.w    #18,-(sp)
          trap      #14
          add.w     #14,sp
          move.b    formaatt,d0         Fat-Disk ?
          beq.s     format14
          move.b    #$34,21(a3)         Sekanz=820 ($334)
          move.b    #3,22(a3)
          move.b    #10,26(a3)          10 Sek/Track
format14  lea       formadat,a3
          bsr.s     formawrt
          move.w    #288,d0             -- DIR/FAT initialisieren --
          lea       2(a3),a0
format8   clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          clr.l     (a0)+
          dbra      d0,format8
          move.b    formaatt,d0         Fat ?
          beq.s     format15
          add.w     #16,a3
format15  move.b    formaatt+1,d0       2-seitig ?
          beq.s     format16
          add.w     #8,a3
format16  bsr.s     formawrt
          bsr.s     formawrt
          move.l    a2,a0
          bra       dolinkom
formawrt  move.l    (a3)+,-(sp)         -- Sektoren auf Disk --
          move.l    (a3)+,-(sp)
          move.w    d3,-(sp)            Disknr.
          clr.l     -(sp)
          pea       2(a3)
          move.w    #9,-(sp)
          trap      #14
          add.w     #20,sp
          tst.w     d0
          bpl.s     formatx
          addq.l    #4,sp
          bra       gemdoser
formatx   rts
formaatt  dc.w      0,$4612             Attribute F und 2
formadat  dc.w      0,1,1,0             Bootsektor
          dc.w      0,8,2,0,0,9,1,1     einseitige Disk
          dc.w      0,8,2,0,1,9,1,0     zweiseitige Disk
          dc.w      0,9,2,0,0,8,1,1     einseitige Fat-Disk
          dc.w      0,9,2,0,1,8,1,0     zweiseitige Fat-Disk
          ;
info      subq.b    #1,d0
          bne       exe
          bsr       copycom             * Info *
          bsr       blank
          beq.s     info1
          move.b    (a0)+,d2            Drivenr. best.
          and.w     #%11011111,d2
          sub.b     #'A',d2
          cmp.l     d6,a0
          bhs       dolinsyn
          cmp.b     #':',(a0)+
          bne       dolinsyn
          bra.s     info2
info1     move.w    #$19,-(sp)          ;current_drive
          trap      #1
          addq.l    #2,sp
          move.w    d0,d2
info2     move.l    a0,a2
          lea       dirstr1,a0
          moveq.l   #'A',d0
          add.b     d2,d0
          move.b    d0,(a0)
          pea       buffzeil            ;set_dta
          move.w    #$1a,-(sp)
          trap      #1
          addq.l    #6,sp
          move.w    #8,-(sp)            ;search_first
          pea       dirstr1
          move.w    #$4e,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.w     d0
          beq.s     info3
          cmp.w     #-33,d0
          bne       gemdoser
          bsr       newline             - Kein Label -
          lea       infostr2,a0
          bsr       zeilaus
          bra.s     info4
info3     bsr       newline             - Label vorhanden -
          lea       infostr1,a0
          bsr       zeilaus
          lea       buffzeil+30,a0
          bsr       zeilaus
info4     move.w    d2,-(sp)            ;get_disk_free_space
          addq.w    #1,(sp)
          pea       buff80
          move.w    #$36,-(sp)
          trap      #1
          addq.l    #8,sp
          tst.w     d0
          bmi       gemdoser
          move.l    buff80+12,d2
          mulu.w    buff80+10,d2
          bsr       newline             - Insg. Bytes -
          move.l    buff80+4,d0
          mulu.w    d2,d0
          bsr       dezausl
          lea       infostr3,a0
          bsr       zeilaus
          bsr       newline             - Freie Bytes -
          move.l    buff80,d0
          mulu.w    d2,d0
          bsr       dezausl
          lea       infostr4,a0
          bsr       zeilaus
          move.l    a2,a0
          bra       dolinkom
          ;
exe       subq.b    #1,d0
          bne       dolinsyn
          bsr       getfiln             * Exe *
          tst.b     d1
          beq       dolinsyn
          move.l    a1,d5
          lea       nulstr,a1
          bsr       blank
          beq.s     exe1
          cmp.b     #',',(a0)         Kommandozeile lesen
          bne.s     exe2
          addq.l    #1,a0
exe2      lea       buffzeil,a1
          moveq.l   #19,d0
exe5      move.l    #$20202020,(a1)+    mit Blanks fÅllen
          dbra      d0,exe5
          lea       buffzeil+1,a1
          bsr       getstr+4
          move.l    a4,d0
          bne       formatx
          lea       buffzeil,a1
          move.b    #32,1(a1,d1.w)
          clr.b     79(a1)
exe1      move.l    a1,d4               --- Speicher freigeben ---
          move.b    saveflag,d0         Text verÑndert ?
          beq.s     exe3
          lea       wirnew,a1           "Wirklich lîschen ?"
          bsr       decide
          bne       dolinkom
exe3      move.l    textbase,-(sp)      mfree
          move.w    #$49,-(sp)
          trap      #1
          addq.l    #6,sp
          lea       execstr,a0          Neue Zeile
          bsr       zeilaus
          ;                             --- EXECUTE PROGRAM ---
          pea       nulstr              Environment
          move.l    d4,-(sp)            Kommandozeile
          move.l    d5,-(sp)            Filename
          clr.w     -(sp)
          move.w    #$4b,-(sp)          exec
          trap      #1
          add.w     #16,sp
          tst.w     d0                  RÅckmeldung?
          beq.s     exe4
          cmp.w     #-32,d0             Nur GEMDOS-Fehlerwerte
          ble.s     exe6
          lea       backval+37,a4
          tst.w     d0
          bpl.s     exe7
          neg.w     d0
          move.b    #'-',(a4)+
exe7      bsr       dezaus              -> Wert ausgeben
          move.b    (a0)+,(a4)+
          move.b    (a0)+,(a4)+
          move.b    (a0)+,(a4)+
          move.b    (a0)+,(a4)+
          move.b    (a0)+,(a4)+
          move.b    (a0)+,(a4)+
          lea       backval,a4
          bra.s     exe4
exe6      bsr       gemdoser            Fehlernummer ausgeben
          ;                             --- Speicher reparieren ---
exe4      move.l    #-1,-(sp)           Malloc
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
          bmi       quit2
          add.l     d0,(a3)             TextTop
          move.l    d0,a3               A3: Zeiger letzte Zeile
          lea       textbase,a0
          move.l    a3,(a0)
          clr.w     (a3)                Letzte Zeile: Zeilennr.= Null
          lea       curradr,a0
          move.l    a3,(a0)             Zeiger auf aktuelle Zeile
          clr.l     d7                  D7: Pos am Bildschirm
          move.l    a6,a5               A5: Zeiger TextPuffer
          move.l    a6,a0
          move.w    #249,d0
          move.l    #$20202020,d1
clearscr  move.l    d1,(a0)+            Bildschirmspeicher lîschen
          move.l    d1,(a0)+
          dbra      d0,clearscr
          move.l    logbase,a0          Text am Schirm "ausgrauen"
          move.w    #199,d0
          move.l    #$55555555,d2
          move.l    #$aaaaaaaa,d3
greyscr   moveq.l   #19,d1
greyscr2  and.l     d2,(a0)+
          dbra      d1,greyscr2
          moveq.l   #19,d1
greyscr3  and.l     d3,(a0)+
          dbra      d1,greyscr3
          dbra      d0,greyscr
          rts
          ;
;----------------------------------------------------------SUBROUTINEN
          ;                             * Passenden String Suchen *
fodcomsf  lea       buff80,a2           EIN: A1=Vergleichsstrings
          move.b    (a1)+,d0            AUS: ZF=0/1=n./gefunden
          beq.s     fodcoms2            Stringende -> Macro gefunden
          cmp.l     d5,a2
          bhs.s     fodcoms1            nur bis Zeilenende
          cmp.b     (a2)+,d0            Zeichen der Str. vergleichen
          beq       fodcomsf+4          falls gleich -> weiter testen
fodcoms1  tst.b     (a1)+
          bpl       fodcoms1            hinter String und Steuercodes
          tst.b     (a1)                noch ein Vergleichsstring ?
          bne       fodcomsf
          rts
fodcoms2  cmp.l     d5,a2               Wort zuende ?
          bhs.s     fodcoms4            ja -> Ok
          cmp.b     #'A',(a2)
          blo.s     fodcoms4            ja -> Ok
          cmp.b     #'Z',(a2)
          bls       fodcoms1            nein -> nicht gefunden, weiter
fodcoms4  sub.l     #buff80,a2
          add.l     a2,a0
          moveq.l   #1,d1
          rts
          ;
filn_out  movem.l   a1-a3/d1-d2,-(sp)   * Filenamen ausgeben *
          move.l    a0,a3
filn_ou1  clr.w     d0
          move.b    (a3)+,d0
          beq.s     filn_ou2
          move.w    d0,-(sp)            ;bconout
          move.w    #5,-(sp)
          move.w    #3,-(sp)
          trap      #13
          addq.l    #6,sp
          bra       filn_ou1
filn_ou2  movem.l   (sp)+,a1-a3/d1-d2
          rts
          ;
getfiln   bsr.s     getstr              * Filenamen einlesen *
          move.l    a4,d0
          bne.s     getfiln1
          rts
getfiln1  addq.l    #4,sp
          rts
          ;
getstr    lea       buff80,a1           * String in Buffer * (max. 80)
          clr.l     d1                  !! Einsprungadresse !!
          bsr       blank
          beq.s     getstr1             Zeilenende -> Nulstring
          move.b    (a0),d0
          cmp.b     #39,d0
          bne.s     getword             kein Hochkomma -> nicht in AnfÅhrungszeichen
          addq.l    #1,a0
getstr2   cmp.l     d6,a0
          bhs.s     getstr4             Zeilenende -> kein 2. Hochkomma -> Fehler
          move.b    (a0)+,d0
          cmp.b     #39,d0              Hochkomma ?
          bne.s     getstr3
          cmp.b     #39,(a0)            ja -> Doppelhochkomma ?
          bne.s     getstr1             nein -> String-Ende
          addq.l    #1,a0
getstr3   cmp.b     #80,d1
          bhs.s     getstr4             String zu lang -> Fehler
          addq.b    #1,d1               LÑnge des Strings erhîht sich
          move.b    d0,(a1)+
          bra       getstr2
getstr4   lea       stringer,a4         Fehlermeldung
          rts
getstr1   clr.b     (a1)                String-Ende
          lea       buff80,a1
          rts
getword   exg       a1,d6
          cmp.b     #' ',-(a1)        Zeilenende hinter letztes Zeichen
          beq       getword+2
          exg       a1,d6
          addq.l    #1,d6
getword1  cmp.l     d6,a0               Zeilenende -> fertig
          bhs       getstr1
          move.b    (a0),d0
          cmp.b     #',',d0
          beq       getstr1             Komma -> fertig
          cmp.b     #' ',d0
          beq       getstr1
          move.b    d0,(a1)+
          addq.l    #1,a0
          addq.b    #1,d1
          bra       getword1
          ;
time_in   bsr       blank               * Zeitangabe einlesen *
          bsr       readdez
          move.l    a4,d0
          bne.s     time_inx
          cmp.l     #24,d1              - Stunde -
          bhs.s     time_in2
          move.w    d1,d2
          ror.w     #5,d2
          cmp.l     d6,a0               - Minute -
          bhs       dolinsyn
          cmp.b     #':',(a0)+
          bne       dolinsyn
          bsr       readdez
          move.l    a4,d0
          bne.s     time_inx
          cmp.l     #59,d1
          bhi.s     time_in2
          lsl.w     #5,d1
          or.w      d1,d2
          clr.l     d1                  - Sekunde (optional) -
          cmp.l     d6,a0
          bhs.s     time_inx
          cmp.b     #':',(a0)
          bne.s     time_inx
          addq.l    #1,a0
          bsr       readdez
          move.l    a4,d0
          bne.s     time_inx
          cmp.l     #59,d1
          bhi.s     time_in2
          lsr.w     #1,d1
          or.w      d1,d2
          rts
time_in2  lea       wrotida,a4          "Fehler"
time_inx  rts
          ;
date_in   bsr       blank               * Datumsangabe einlesen *
          bsr       readdez
          move.l    a4,d0
          bne       time_inx
          cmp.l     #31,d1              - Tag
          bhi       time_in2
          move.l    d1,d2
          beq       time_in2
          cmp.l     d6,a0               - Monat
          bhs       dolinsyn
          cmp.b     #'.',(a0)+
          bne       dolinsyn
          bsr       readdez
          move.l    a4,d0
          bne       time_inx
          cmp.l     #12,d1
          bhi       time_in2
          lsl.w     #5,d1
          beq       time_in2
          or.w      d1,d2
          move.l    a0,a2               - Jahr (optional)
          move.w    #$2a,-(sp)
          trap      #1
          addq.l    #2,sp
          move.l    a2,a0
          move.w    d0,d1
          and.w     #%1111111000000000,d1
          cmp.l     d6,a0
          bhs.s     date_in1
          cmp.b     #'.',(a0)
          bne.s     date_in1
          addq.l    #1,a0
          bsr       readdez
          move.l    a4,d0
          bne       time_inx
          sub.l     #1980,d1
          blo       time_in2
          cmp.l     #127,d1
          bhi       time_in2
          ror.w     #7,d1
date_in1  or.w      d1,d2
          rts
          ;
time_out  move.w    d0,d1               * Uhrzeit in String *
          rol.w     #5,d1
          and.w     #31,d1              - Stunde
          bsr.s     timediv
          move.w    d0,d1               - Minute
          lsr.w     #5,d1
          and.w     #63,d1
          bsr.s     timediv
          move.w    d0,d1               - Sekunde
          and.w     #31,d1
          lsl.w     #1,d1
          bra.s     timediv
          ;
date_out  move.w    d0,d1               * Datum in String *
          and.w     #31,d1
          bsr.s     timediv             - Tag
          move.w    d0,d1               - Monat
          lsr.w     #5,d1
          and.w     #$f,d1
          bsr.s     timediv
          lea       4(a1),a0            - Jahr
          rol.w     #7,d0
          and.w     #$7f,d0
          add.w     #1980,d0
          bra       dezaus2
          ;
timediv   cmp.w     #10,d1              * 2-Digit-Dez ausgeben *
          bhs.s     timediv1
          swap      d1
          clr.w     d1
          bra.s     timediv2
timediv1  and.l     #$7f,d1
          divu      #10,d1
timediv2  add.l     #$300030,d1
          move.b    d1,(a1)+
          swap      d1
          move.b    d1,(a1)+
          addq.l    #1,a1
          rts
          ;
blank     cmp.l     d6,a0               * Blanks Åberspringen *
          bhs.s     blank1
          cmp.b     #' ',(a0)+
          beq       blank
          subq.l    #1,a0
          rts
blank1    clr.b     d0                  Zeilenende -> Meldung: D0 = 0
          rts
          ;
copycom   lea       -768(a6),a2         * Zeile in Stackbereich kopieren *
          cmp.l     a6,a0
          blo       erax                schon gerettet
          move.l    d6,d0
          sub.l     a0,d0
          subq.l    #1,d0
          bmi.s     copycom2
copycom1  move.b    (a0)+,(a2)+
          dbra      d0,copycom1
copycom2  move.l    a2,d6
          lea       -768(a6),a0
          rts
          ;
decide    bsr       copycom             * Entscheidungsfrage *
          move.l    a0,a2
          bsr       newline
          move.l    a1,a0
          bsr       zeilaus             Frage schreiben
          move.w    #1,-(sp)
          trap      #1                  ;conin
          addq.l    #2,sp
          move.w    d0,d2
          moveq.l   #'f',d0
          bsr       escaus              Cursor aus
          move.l    a2,a0
          and.b     #%11011111,d2
          cmp.b     #'J',d2           J oder j fÅr ja ?
          rts
          ;
readline  move.l    d6,a1               * Neue Zeile Abspeichern *
          cmp.l     #$10000,d1
          bhs.s     readlin0            Zeilennummer > 65535 --> Fehler
          tst.w     d1
          bne.s     readlin1
readlin0  lea       numerr,a4           Zeilennummer = 0  --> Fehler
          rts
readlin1  cmp.b     #' ',-(a1)        Ende der Zeile suchen
          beq       readlin1
          move.l    a1,d4
          sub.l     a0,d4               D4: wirkliche ZeilenlÑnge
          addq.b    #1,d4
          cmp.b     #74,d4              Zeile zu lang ?
          bls.s     readlin9
          lea       longline,a4
          rts
readlin9  move.w    d1,d5               D5: Zeilennummer
          bsr.s     findadr
          move.l    a1,curradr
          move.w    d5,currlin
          move.b    d4,d3               D3: berichtigte ZeilenlÑnge
          btst      #0,d3
          beq.s     readlin2
          addq.b    #1,d3
readlin2  addq.b    #1,d3
          cmp.w     (a1),d5             gefundene Nr. = gesuchte ?
          beq.s     readlin4            ja -> Zeile schon vorhanden
          clr.l     d0
          move.b    d3,d0               -- Vîllig neue Zeile --
          addq.b    #3,d0
          bsr.s     inslins             Platz im Speicher freimachen
          sub.l     d0,curradr
          move.l    a4,d0
          bne.s     readlinr            zu wenig Speicherplatz -> Fehler
          move.w    d5,(a1)+            Zeilennr. speichern
          move.b    d3,(a1)+            LÑnge speichern
readlin5  move.b    d4,d0
          subq.b    #1,d0
readlin3  move.b    (a0)+,(a1)+         Zeile vom Schirm in Speicher kopieren
          dbra      d0,readlin3
          move.b    d3,d0
          sne.b     saveflag            Flag: Datei verÑndert
          sub.b     d4,d0
          cmp.b     #1,d0               muû ZeilenlÑnge berichtigt werden ?
          beq.s     readlinr-2
          move.b    #' ',(a1)+        Blank anhÑngen, damit nÑchste Zeile auf Wort beginnt
          move.b    d3,(a1)+
readlinr  rts                           fertig
readlin4  addq.l    #2,a1               Zeilennummer Åberspringen (bleibt gleich)
          cmp.b     (a1),d3
          beq.s     readlin6            neue LÑnge = alte ?
          blo.s     readlin7
          clr.l     d0                  -- Zeile verlÑngern --
          move.b    d3,d0
          sub.b     (a1),d0
          bsr.s     inslins
          move.l    a4,d0
          bne       readlinr            nicht genug Speicher -> Abbruch
          move.b    d3,(a1)+
          bra       readlin5
readlin6  addq.l    #1,a1               -- Zeile gleichlang --
          clr.l     d0
          bra       readlin5
readlin7  move.b    (a1),d0             -- Zeile kÅrzen --
          sub.b     d3,d0
          bsr.s     dellins
          move.b    d3,(a1)+            LÑnge der Zeile speichern
          bra       readlin5
          ;
findadr   move.l    textbase,a1         * Adresse einer Zeilennummer *
          clr.l     d0
findadr2  tst.w     (a1)
          beq.s     findadr1            Zeile 0 -> Textende -> fertig
          cmp.w     (a1),d1
          bls.s     findadr1            ges. Zeile oder grîûere gef.
          addq.l    #2,a1               Zeilennummer Åberspringen
          move.b    (a1)+,d0            LÑnge der Zeile
          add.l     d0,a1               Zeile Åberspringen
          bra       findadr2
findadr1  rts
          ;
inslins   move.l    memtop,d1           * Bei A1 D0 Bytes Platz mach.*
          sub.l     a3,d1
          cmp.l     d0,d1               Anz.freie Bytes<eizufÅgender ?
          blo.s     inslinse            ja -> Fehler
          cmp.l     curradr,a1
          bhi.s     inslins3
          add.l     d0,curradr
inslins3  move.l    a3,d1
          sub.l     a1,d1               Anzahl zu verschiebender Bytes
          beq.s     inslins2            = 0 ? -> nicht verschieben
          movem.l   a1/a3,-(sp)
          addq.l    #1,a3
          move.l    a3,a1
          add.l     d0,a1               Adresse der Verschobenen
inslins1  move.b    -(a3),-(a1)
          dbra      d1,inslins1
          sub.l     #$10000,d1
          bpl       inslins1
          movem.l   (sp)+,a1/a3
inslins2  add.l     d0,a3
          clr.w     (a3)                Zeile Null am Programmende
          rts
inslinse  lea       notfree,a4          Fehler: zu wenig freier Speicher
          rts
          ;
dellins   move.l    a1,-(sp)            * Bei A1 D0 Bytes lîschen *
          cmp.l     curradr,a1
          bhi.s     dellins2
          move.l    a1,d1
          add.l     d0,d1
          cmp.l     curradr,d1
          blo.s     dellins5
          move.l    d1,curradr          akt. Zeile gelîscht
dellins5  sub.l     d0,curradr
dellins2  move.l    a3,d1
          move.l    a1,a3               Adresse der zu Verschiebenden
          add.l     d0,a3
          sub.l     a3,d1               Anzahl der zu Verschiebenden
          beq.s     dellins3            kein Text mehr hinter Lîschung
          subq.l    #1,d1
dellins1  move.b    (a3)+,(a1)+
          dbra      d1,dellins1
          sub.l     #$10000,d1
          bpl       dellins1
          move.l    a1,a3               Neues Ende des Textes
dellins4  clr.w     (a3)                Letzte Zeilennummer: Null
          move.l    (sp)+,a1
          rts
dellins3  sub.l     d0,a3
          bra       dellins4
          ;
getspec   lea       buff12,a1           * Zeilennummern lesen *
          clr.l     (a1)
          clr.b     8(a1)
          bsr       blank
          beq.s     getspecx            keine Spec da
          cmp.b     #'-',(a0)
          bne.s     getspec1
          move.l    textbase,a4         -- Bis zu einer Zeile --
          move.w    (a4),(a1)
          move.l    a4,4(a1)
          sub.l     a4,a4
          addq.l    #1,a0
          bsr       blank
          beq       nospequ
          bsr.s     calclin             zweite Nummer lesen
          move.l    a4,d0
          bne.s     getspecx            Syntax-Fehler
          move.l    a1,buff12+8
          move.w    d1,buff12+2
getspecx  rts
getspec1  bsr.s     calclin             erste Nummer lesen
          move.l    a4,d0
          bne       getspecx
          move.w    d1,buff12
          move.l    a1,d0
          bne.s     getspec4
          bsr       findadr
getspec4  move.l    a1,buff12+4
          bsr       blank
          beq.s     getspec3
          cmp.b     #'-',(a0)         'bis'- Strich ?
          bne.s     getspec3
          addq.l    #1,a0               -> öberspringen
          bsr       blank
          beq.s     getspec2            Zeilenende oder
          cmp.b     #',',(a0)         Komma -> Ende dieser Spec
          beq.s     getspec2+2
          bsr.s     calclin             zweite Znr. lesen
          move.l    a4,d0
          bne.s     getspec2
          move.w    d1,buff12+2         -- Zwischen zwei Zeilen --
          move.l    a1,buff12+8
          rts
getspec2  sub.l     a4,a4               -- Ab einer Zeile --
          move.w    #$ffff,buff12+2
          move.l    a3,buff12+8
          rts
getspec3  move.w    d1,buff12+2         -- Eine einzige Zeile --
          move.l    a1,buff12+8
          rts
          ;
calclin   move.b    (a0),d0             * Zeilennr. interpretieren *
          cmp.b     #'9',d0
          bhi.s     calclin1
          bsr       readdez             -- Zeilennummer --
          move.l    a4,d0
          bne       nospequ
          sub.l     a1,a1
          move.b    #$ff,buff12+8
          cmp.l     #65536,d1           zu groû ?
          blo       getspecx
          move.l    #$ffff,d1
          move.l    a3,a1
          rts
calclin1  bclr      #5,d0
          addq.l    #1,a0
          cmp.b     #'F',d0
          bne.s     calclin2
          move.l    textbase,a1         -- First --
          move.w    (a1),d1
          move.b    #$ff,buff12+8
          rts
calclin2  cmp.b     #'L',d0
          bne.s     calclin3
          moveq.l   #1,d1               -- Last
          move.l    a3,a1
          move.b    #$ff,buff12+8
          bra.s     calcpst3
calclin3  cmp.b     #'C',d0
          bne.s     calclin4
          move.w    currlin,d1          -- Current --
          move.l    curradr,a1
          rts
calclin4  cmp.b     #'P',d0
          bne.s     calclin5
          bsr       blank               -- Past --
          beq.s     calcli41
          bsr       readdez
          move.l    a4,d0
          beq.s     calcli41+2
          sub.l     a4,a4
calcli41  moveq.l   #1,d1
          bra.s     calcpast
calclin5  cmp.b     #'N',d0
          bne.s     calclin6
          bsr       blank               -- Next --
          beq.s     calcli51
          bsr       readdez
          move.l    a4,d0
          beq.s     calcnext
          sub.l     a4,a4
calcli51  moveq.l   #1,d1
          bra.s     calcnext
calclin6  subq.l    #1,a0
          bra       nospequ
          ;
calcpast  move.l    curradr,a1          * D1 Zeilen zurÅck *
          move.b    buff12+8,d0
          beq.s     calcpst3
          move.l    buff12+4,a1
calcpst3  subq.l    #1,d1
          bmi.s     calcpst2
          clr.l     d0
          move.l    textbase,d2
calcpst1  cmp.l     d2,a1
          bls.s     calcpst2
          move.b    -(a1),d0
          sub.l     d0,a1
          subq.l    #2,a1
          dbra      d1,calcpst1
          clr.l     d1
calcpst2  move.w    (a1),d1
          rts
calcnext  move.b    buff12+8,d0         * D1 Zeilen weiter *
          beq.s     calcnxt5
          move.l    buff12+4,a1
          move.w    buff12,d0
          bra.s     calcnxt3
calcnxt5  move.l    curradr,a1
          move.w    currlin,d0
calcnxt3  subq.l    #1,d1
          bmi.s     calcnxt4
          cmp.w     (a1),d0
          beq.s     calcnxt2-2
          subq.l    #1,d1               akt. Zeile gelîscht
          bmi.s     calcnxt4
          clr.l     d0
calcnxt2  tst.w     (a1)
          beq.s     calcnxt1
          addq.l    #2,a1
          move.b    (a1)+,d0
          add.l     d0,a1
          dbra      d1,calcnxt2
calcnxt4  move.w    (a1),d1
          beq.s     calcnxt1
          rts
calcnxt1  move.w    #$ffff,d1
          rts
          ;
getsetas  bsr       getspec             * Spec. fÅr Move + Copy *
          move.l    a4,d0
          bne       checkx              Start-Spezifikation
          move.w    buff12,d0
          beq       dolinsyn
          bsr       blank               to
          beq       dolinsyn
          lea       chkto,a2
          bsr.s     check
          move.l    a4,d0
          bne       checkx
          bsr.s     getsnasp            D4: Ziel-Zeilennummer
          tst.w     d4                  D5: Schrittweite
          beq       dolinsyn
          lea       buff12,a2
          move.l    8(a2),a1
          move.w    2(a2),d1            Adresse der Orginal-End-Zeile
          move.l    a1,d0
          bne.s     getseta2
          move.l    4(a2),a1
          bsr       findadr+4
getseta2  cmp.w     (a1),d1             Zeile vorhanden ?
          bne.s     getseta1
          moveq.l   #3,d0               -> dahinter zeigen
          add.b     2(a1),d0
          add.l     d0,a1
getseta1  move.l    a1,8(a2)
          move.w    d4,d1               Adresse der Ziel-Zeile
          bra       findadr
          ;
getsnasp  clr.l     d4                  * Startnr. und Step lesen *
          clr.w     d5
          bsr       blank
          beq.s     getsnas1
          bsr       readdez             Startnummer lesen
          move.w    d1,d4
          move.l    a4,d0
          beq.s     getsnas2
          clr.w     d4                  keine da
          sub.l     a4,a4
getsnas2  bsr       blank               kommt noch was ?
          beq.s     getsnas1
          lea       chkstep,a2
          bsr.s     check               kommt 'STEP' ?
          move.l    a4,d0
          bne.s     getsnas1            nein -> Default annehmen
          bsr       readnum             Schrittweite einlesen
          move.l    a4,d0
          bne.s     checkx
          move.w    d1,d5
getsnas1  sub.l     a4,a4
          tst.w     d5                  Schrittweite angegeben ?
          bne.s     checkx
          move.w    #10,d5              Default: 10
          rts
          ;
check     cmp.b     #',',(a0)         * Strings Ñquivalent ? *
          bne.s     check1
          addq.l    #1,a0               Komma anstatt String -> Ok
          bra.s     checkx
check1    move.l    a0,-(sp)
check2    tst.b     (a2)
          beq.s     checkr              PrÅfstringende -> Ok
          cmp.l     d6,a0
          bhs.s     check3
          move.b    (a0)+,d0
          and.b     #%11011111,d0       Klein- zu Groûbuchst. machen
          cmp.b     (a2)+,d0            Vergleichen
          beq       check2
check3    lea       syntax,a4           Fehler
          move.l    (sp)+,a0
checkx    rts
checkr    addq.l    #4,sp
          rts
          ;
gemdoser  cmp.w     #-33,d0             * GEMDOS-Meldung ausgeben *
          bne.s     gemdos1
          lea       gemdos33,a4
          rts
gemdos1   cmp.w     #-34,d0
          bne.s     gemdos2
          lea       gemdos34,a4
          rts
gemdos2   cmp.w     #-36,d0
          bne.s     gemdos3
          lea       gemdos36,a4
          rts
gemdos3   cmp.w     #-46,d0
          bne.s     gemdos4
          lea       gemdos46,a4
          rts
gemdos4   cmp.w     #-13,d0
          bne.s     gemdos5
          lea       gemdos13,a4
          rts
gemdos5   cmp.w     #-02,d0
          bne.s     gemdos6
          lea       gemdos02,a4
          rts
gemdos6   neg.w     d0                  sonstiger Fehler
          bsr       dezaus
          lea       gemdosxx+42,a1
          move.b    (a0)+,(a1)+
          move.b    (a0)+,(a1)+
          move.b    (a0)+,(a1)+
          move.b    (a0)+,(a1)+
          move.b    (a0)+,(a1)+
          move.b    (a0)+,(a1)+
          lea       gemdosxx,a4
          rts
          ;
*-----------------------------------------------GEMDOS-FEHLERMELDUNGEN
gemdos33  dc.b   'Datei nicht gefunden',0
gemdos34  dc.b   'Pfadname nicht gefunden',0
gemdos36  dc.b   'Zugriff nicht mîglich',0
gemdos46  dc.b   'ungÅltige Laufwerkbezeichnung',0
gemdos13  dc.b   'Diskette ist schreibgeschÅtzt',0
gemdos02  dc.b   'Floppy/Harddisk ist nicht betriebsbereit',0
gemdosxx  dc.b   'Das Betriebssystem meldet den Fehler Nr. -#####',0
*------------------------------------------------------------FöR CHECK
chkstep   dc.b   'STEP',0
chkto     dc.b   'TO',0
chkas     dc.b   'AS',0
chkwith   dc.b   'WITH',0
*--------------------------------------------------------------STRINGS
buff80    ds.w   40
buffzeil  ds.w   40
buff12    ds.w   6
savestr   dc.b   $bd,'Th.Zî`s DrkEdt###'
inzeile   dc.b   ' in Zeile ',0
almonstr  dc.b   00,0,01,4,02,0,03,4,04,4,05,4,06,0,07,$f8,08,16,09
          dc.b   16,10,16,12,90,13,8,$ff,0
almofstr  dc.b   07,$ff,08,0,09,0,10,0,$ff,0
curradr   ds.l   1
currlin   dc.w   0
*----------MELDUNGEN---------------------------------------------------------------------FEHLERMELDUNGEN-----
breakvor  dc.b      'AusfÅhrung unterbrochen vor Zeile ',0
loadmang  dc.b      'Die neuen Zeilen passen zeilennummernmÑûig nicht in den Speicher',0
wirnew    dc.b      'Sie mîchten die ungesicherte Datei verwerfen ? (j/n): ',27,'e',0
wirforma  dc.b      'Sie mîchten alle Daten auf dieser Diskette lîschen ? (j/n): ',27,'e',0
stringer  dc.b      'Hinter einem String fehlt das Hochkomma - Syntax Fehler',0
notfree   dc.b      'Der Speicherplatz reicht nicht mehr fÅr diese Zeile(n)',0
numerr    dc.b      'Als Zeilennummern sind nur Zahlen von 1 bis 65535 erlaubt',0
longline  dc.b      'Die Zeile hat mehr als 74 Zeichen - Keine Abspeicherung',0
wirera    dc.b      'Sie mîchten alle enthaltenen Dateien lîschen ? (j/n): ',27,'e',0
nospezi   dc.b      'Ein Zeilen-Spezifikation wurde erwartet - Syntax Fehler',0
nocomhre  dc.b      'Befehle sind nur im Direkt-Modus mîglich - Abbruch',0
wromaker  dc.b      'Nur den Zeichen 0-31 und 128-255 kînnen Werte zugewiesen werden',0
wrotida   dc.b      'UngÅltige Zeit- oder Datumsangabe',0
nigenspe  dc.b      'Nicht genug Speicher frei (min. 10 KB)',0
versistr  dc.b      'GEMDOS-Version ',0
infostr1  dc.b      'Die Disk hat den Namen ',0
infostr2  dc.b      'Die Disk hat keinen Namen',0
infostr3  dc.b      ' Bytes sind insgesamt verfÅgbar',0
infostr4  dc.b      ' Bytes sind derzeit frei',0
execstr   dc.b      13,10,0
waitkey   dc.b      '---> DrÅcken Sie eine Taste...',0
nulstr    dc.b      0
backval   dc.b      'Das Programm meldet den RÅckgabewert ######',0
*--------------FLAGS-------------------------------------------------------------------------------FLAGS-----
runflag   dc.b      0   : 0/1 = Direktmodus / Run,Test,Create-Modus
saveflag  dc.b      0   : 0/1 = Datei sicher /ungesichert
testflag  dc.b      0   : 0/1 = Drucken / nur Syntax prÅfen
creaflag  dc.b      0   : 0/1 = Drucken / auf Disk speichern
lprtflag  dc.b      0   : 0/1 = Listen auf Bildschirm / Drucker
modeflag  dc.b      1   : 0/1/2 = Drucken im Original / Text / Xtext -Mode
findflag  dc.b      0   : 0/x = Bedingungslos Listen / LÑnge des Test-Strings
fiwoflag  dc.b      0   : 0/x = Klein-,Groûbuchst. unterscheiden / u.u
timeflag  dc.b      0   : 0/x = Wecker an / aus
fijodata  dc.w      0   : 0/1 = kein/ein Joker im String // Jokerzeichen
repldata  dc.w      0   : 0/x = Replace-Modus aus/an // LÑnge des Replace-Strings
alarmtim  dc.w      0   : Stunde:Minute der Weckuhrzeit
*------------BEFEHLE-----------------------------------------------------------------------------BEFEHLE-----
befehle   dc.b      'MODE ORIGINAL',0,1,255,'MODE TEXT',0,2,255,'MODE XTEXT',0,3,255,'L',0,5,255
          dc.b      'PRINT',0,4,255,'LIST',0,5,255,'LPRINT',0,6,255,'FINDWORD',0,7,255,'FIND',0,8,255
          dc.b      'REPLACE',0,9,255,'REPLACEWORD',0,10,255,'SAVE',0,11,255,'LOAD',0,12,255
          dc.b      'RENUM',0,13,255,'DELETE',0,14,255,'MOVE',0,15,255,'COPY',0,16,255,'TEST',0,17,255
          dc.b      'CREATE',0,18,255,'SET TABS',0,19,255,'GUIDE',0,20,255,'MAKE',0,21,255
          dc.b      'CD',0,22,255,'ALARM OFF',0,23,255,'ALARM',0,24,255,'TIME',0,25,255
          dc.b      'DATE',0,26,255,'SET TIME',0,27,255,'SET DATE',0,28,255,'GET DIR',0,29,255
          dc.b      'DRIVE',0,30,255,'DIR',0,31,255,'MKDIR',0,32,255,'RMDIR',0,33,255,'QUIT',0,36,255
          dc.b      'ERA',0,37,255,'REN',0,38,255,'MKLABEL',0,39,255,'RMLABEL',0,40,255,'VERSION',0,41,255
          dc.b      'FILETIME',0,42,255,'FILEDATE',0,43,255,'FILEMOD',0,44,255,'FORMAT',0,45,255,'INFO',0,46,255
          dc.b      'NEW',0,34,255,'FREE',0,35,255,'EXE',0,47,255,0
*-------------MACROS------------------------------------------------------------------------------MACROS-----
macros    dc.b      'CR',0,13,255,'LF',0,10,255,'ITALIC',0,27,52,255,'NO ITALIC',0,27,53,255,'CHAR SET',0,27
          dc.b      55,254,'CPI 10',0,18,255,'CPI 12',0,27,66,1,255,'CPI 17',0,15,255,'PICA',0,18,255,'ELITE'
          dc.b      0,27,66,1,255,'COMPRESSED',0,15,255,'DOUBLE WIDE',0,14,255,'NO DOUBLE WIDE',0,20,255
          dc.b      'DOUBLE STRIKE',0,27,71,255,'NO DOUBLE STRIKE',0,27,72,255,'EMPHASIZE',0,27,69,255
          dc.b      'NO EMPHASIZE',0,27,70,255,'UNDERLINE',0,27,45,1,255,'NO UNDERLINE',0,27,45,0,255
          dc.b      'SUPERSCRIPT',0,27,83,0,255,'SUBSCRIPT',0,27,83,1,255,'NO SCRIPT',0,27,84,255
          dc.b      'UNIDIRECT',0,27,85,1,255,'BIDIRECT',0,27,85,0,255,'FEED 6',0,27,50,255,'FEED 8',0,27,48
          dc.b      255,'FEED 72',0,27,65,254,'FEED 144',0,27,51,254,'FEED ONCE 144',0,27,74,254,'FORM LINES'
          dc.b      0,27,67,254,'FORM INCHES',0,27,67,0,254,'HEADERLINES',0,27,82,254,'SKIP OVER',0,27,78,254
          dc.b      'NO SKIP OVER',0,27,79,255,'VERTICAL TABS',0,27,80,254,'FEED LINES',0,27,97,254
          dc.b      'LH MARGIN',0,27,77,254,'RH MARGIN',0,27,81,254,'HORIZONTAL TABS',0,27,68,254,'BLANKS',0
          dc.b      27,98,254,'DEFINE MACRO',0,27,43,254,'END MACRO',0,30,255,'MACRO',0,27,33,255
          dc.b      'DEFINE CHAR',0,27,42,1,254,'SHIFT',0,1,255,'NO SHIFT',0,0,255,'COPY FONTS',0,27,42,0,255
          dc.b      'DOWNLOAD',0,27,36,1,255,'NO DOWNLOAD',0,27,36,0,255,'ON LINE',0,17,255,'OFF LINE',0,19
          dc.b      255,'BUZZER',0,27,89,1,255,'NO BUZZER',0,27,89,0,255,'PAPER OUT',0,27,57,255
          dc.b      'NO PAPER OUT',0,27,56,255,'RESET',0,27,64,255,'NUL',0,0,255,'BEL',0,7,255,'BS',0,8,255
          dc.b      'HT',0,9,255,'VT',0,11,255,'FF',0,12,255,'SO',0,14,255,'SI',0,15,255,'DC1',0,17,255,'DC2'
          dc.b      0,18,255,'DC3',0,19,255,'DC4',0,20,255,'RS',0,30,255,'DEL',0,127,255,'NX',0,13,10,255,0
          ;
*---------------------------------------------------------------HEXAUS
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
hexhead   dc.b      27,'Y% ',0
          ;
hexraus   movem.l   d0-d3/a0-a3,-(sp)
          pea       hexhead
          move.w    #9,-(sp)
          trap      #1
          addq.l    #6,sp
          movem.l   (sp)+,d0-d3/a0-a3
paus      movem.l   d0-d3/a0-a3,-(sp)
*         move.l    d4,d0
*         bsr       hexaus
*         move.l    d5,d0
*         bsr       hexaus
*         move.l    d4,d0
*         bsr       hexaus
*         move.l    d5,d0
*         bsr       hexaus
*         move.l    d6,d0
*         bsr       hexaus
*         move.l    d7,d0
*         bsr       hexaus
          move.w    #1,-(sp)
          trap      #1
          addq.l    #2,sp
*         tst.w     d0
*         beq.s     traprts
          movem.l   (sp)+,d0-d3/a0-a3
          rts
traprts   movem.l   (sp)+,d0-d3/a0-a3
          addq.l    #4,sp
          rts
ende      dc.w      65535
          ;
          END
