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
 module    SHELL
 ;section   eins
 ;pagelen   32767
 ;pagewid   133
 ;noexpand
 include "f_sys.s"
 include "f_def.s"
 ;
 XREF  evt_butt,fram_drw,fram_del
 XREF  alertbox,koos_mak,wind_chg,init_itemslct
 XREF  evt_menu_attr,evt_menu_sel,evt_menu_tools
 XREF  evt_menu_desk,evt_menu_file,evt_menu_shapes
 ;
 XDEF  aescall,vdicall
 XDEF  bildbuff,wi1,rec_adr,win_rdw,show_m,hide_m
 XDEF  save_scr,aes_win_set,aes_rsrc_gad,vslidrw,wi_count,logbase
 XDEF  copy_blk,rand_tab,menu_adr

*-----------------------------------------------------------------------------
*   Module structure:
*   - FA: main entry, registered event+window+mouse handler entry funcs,
*         window event handling, raster-copy sub-function
*   - FG: Shape graphics handlers: line, rectangle, ... & sub-functions
*   - FH: ... cntd.: dot, brush, spraycan, rubberband, eraser
*   - FM: Menu command handler: desk & file menus, Shape selection
*   - FN: ... cntd: Attributes, Selection, and Tools menus
*   - FO: ... cntd: Selection rotate, zoom, distort
*
*-----------------------------------------------------------------------------
*   Global register mapping:
*   - a4   Address of address of current window record (rec_adr)
*   - a6   Base address of data section
*
*   General calling convention for sub-functions:
*   - parameters are passed via registers starting at A0/D0
*     (and in few cases via global variables)
*   - register A0-A1/D0-D1 are not preserved by the callee and
*     therefore values must be saved by caller if still needed;
*     callee has to restore A2-A6/D2-D7 if modified - except for
*     top-level functions such as message event handlers where it
*     is known that the caller does not need the register state.
*
*   - register A6 is globally reserved as base address of data section
*   - register A4 is reserved in several modules as address of the
*     data structure describing the current window (this is noted at
*     the top of these modules, such as this one)
*-----------------------------------------------------------------------------
          ;
          move.l    a7,a5               --- Initialize application ---
          move.l    4(a5),a5
          move.l    $c(a5),d0
          add.l     $14(a5),d0
          add.l     $1c(a5),d0
          add.l     #$800,d0            $800 bytes stack
          move.l    a5,a7               new stack
          add.l     d0,a7
          add.l     #32266,d0           space for buffer
          move.l    d0,-(sp)            setblock
          move.l    a5,-(sp)
          clr.w     -(sp)
          move.w    #$4a,-(sp)
          trap      #1
          add.w     #12,sp
          tst.w     d0                  Error -> abort
          bne       main_err
          ;
          lea       bildbuff,a0         Address of screen buffer
          move.l    a7,d0
          add.l     #256,d0
          and.l     #$ffff00,d0         to start of page
          move.l    d0,(a0)
          subq.l    #8,a7
          lea       dsect_a6,a6         initialize data section pointer a6
          lea       CONTRL(a6),a0       initialize AESPB and VDIPB pointer arrays
          move.l    a0,AESPB+0*4(a6)    AESPB := {CONTRL,GLOBAL,INTIN,INTOUT,ADDRIN,ADDROUT}
          move.l    a0,VDIPB+0*4(a6)    VDIPB := {CONTRL,INTIN,PTSIN,INTOUT,PTSOUT}
          lea       GLOBAL(a6),a0
          move.l    a0,AESPB+1*4(a6)
          lea       INTIN(a6),a0
          move.l    a0,AESPB+2*4(a6)
          move.l    a0,VDIPB+1*4(a6)
          lea       PTSIN(a6),a0
          move.l    a0,VDIPB+2*4(a6)
          lea       INTOUT(a6),a0
          move.l    a0,AESPB+3*4(a6)
          move.l    a0,VDIPB+3*4(a6)
          lea       ADDRIN(a6),a0
          move.l    a0,AESPB+4*4(a6)
          lea       ADDROUT(a6),a0
          move.l    a0,AESPB+5*4(a6)
          lea       PTSOUT(a6),a0
          move.l    a0,VDIPB+4*4(a6)

          aes       10 0 1 0 0          ;APPL_INIT
          move.w    INTOUT(a6),APPL_ID(a6)
          bmi       main_err
          aes       77 0 5 0 0          ;GRAF_HANDLE
          move.w    INTOUT(a6),GRHANDLE(a6)
          vdi       100 0 11 1 1 1 1 1 1 1 1 1 1 2
          ;
*---------------------------------------------------------SETUP---------------
          ;
          lea       rscname,a0
          aes       110 0 1 1 0 !a0 ;rsrc_load
          move.w    INTOUT(a6),d0
          beq       main_rcs_err
          moveq.l   #RSC_MENU,d1        Get address of menu object tree
          bsr       aes_rsrc_gad
          lea       menu_adr,a0
          move.l    ADDROUT(a6),(a0)
          bsr       init_itemslct       initialize item selector dialog
          move.w    #3,-(sp)            ;get logical screen RAM base
          trap      #14
          addq.l    #2,sp
          lea       logbase,a0
          move.l    d0,(a0)
          bsr       hide_m              ;hide_mouse
          moveq.l   #RSC_DESKTOP,d1
          bsr       aes_rsrc_gad
          move.l    ADDROUT(a6),a3
          aes       104 2 5 0 0 0 4     ;wind_get
          move.l    INTOUT+2(a6),16(a3)
          move.l    INTOUT+6(a6),20(a3)
          move.l    a3,INTIN+4(a6)
          clr.l     INTIN+8(a6)
          aes       105 6 1 0 0 0 14    ;wind_set
          move.l    INTOUT+2(a6),INTIN+2(a6)
          move.l    INTOUT+6(a6),INTIN+6(a6)
          move.l    INTOUT+2(a6),INTIN+10(a6)
          move.l    INTOUT+6(a6),INTIN+14(a6)
          aes       51 9 1 1 0 3              ;form_dial
          aes       30 1 1 1 0 1 !menu_adr    ;menu_bar
          lea       maus_kno,a0               ;replace handler for mouse button click
          move.l    a0,CONTRL+14(a6)
          vdi       125 0 0                   ;vex_butv
          move.l    CONTRL+18(a6),MOUSE_VEC_BUT(a6)
          lea       maus_mov,a0               ;replace handler for mouse movement
          move.l    a0,CONTRL+14(a6)
          vdi       127 0 0                   ;vex_curv
          move.l    CONTRL+18(a6),MOUSE_VEC_MOV(a6)
          aes       78 1 1 0 0 0              ;GRAF_MOUSE (arrow shape)
          bsr       show_m                    ;show_mouse
          lea       wi1,a4                    Address of first window
          lea       rec_adr,a0                assign to pointer to current window
          move.l    a4,(a0)
          move.b    #-1,SEL_OPT_OVERLAY(a6)   enable selection overlay mode by default
          ;
*-----------------------------------------------------------------------------
* This is the main loop and event handler of the application. The function
* waits for event messages (menu & window events) but no longer than 70 ms.
* Mouse movements and button events within the window are captured using
* hooks in the interrupt handlers. The state written there is polled here.
*
evt_multi ;                                   ; wait for message, but max. 70ms
          lea       EV_MSG_BUF(a6),a0
          aes       25 16 7 1 0 %110000 0 0 0 0 0 0 0 0 0 0 0 0 0 70 0 !a0  ;evt_multi
          btst.b    #4,INTOUT+1(a6)     message?
          bne.s     evt_mul1
          bsr       koos_mak            print mouse coords. in menu bar, if enabled
          tst.w     MOUSE_RBUT(a6)      right mouse button?
          bne       absmod
          tst.w     MOUSE_LBUT(a6)      left mouse button?
          beq       evt_multi
          tst.w     MOUSE_LBUT+2(a6)    during menu selection?
          bne.s     evt_mul2
          move.l    rec_adr,a4
          aes       104 2 5 0 0 !(a4) 10  ;wind_get
          move.w    INTOUT+2(a6),d0
          cmp.w     WIN_HNDL(a4),d0
          beq.s     evt_mul3            is accessory window active?
          move.w    #-1,MOUSE_LBUT+2(a6)
          bra.s     evt_mul2
evt_mul3  pea       evt_multi
          bra       evt_butt
evt_mul2  tst.b     MOUSE_LBUT+1(a6)    menu selection -> ignore
          bne       evt_multi
          clr.w     MOUSE_LBUT(a6)
          bra       evt_multi
          ;
evt_mul1  move.l    rec_adr,a4          --- Message ---
          move.w    EV_MSG_BUF(a6),d0
          cmp.w     #10,d0              menu item selected?
          bne.s     evt_mul4
          pea       evt_mul5            push handler address to stack -> "rts" returns to loop
          move.w    EV_MSG_BUF+6(a6),d1   object index of top-level menu
          move.w    EV_MSG_BUF+8(a6),d0   object index of selected entry
          cmp.w     #MEN_TOP_DESK,d1
          beq       evt_menu_desk
          cmp.w     #MEN_TOP_FILE,d1
          beq       evt_menu_file
          cmp.w     #MEN_TOP_SHAPE,d1
          beq       evt_menu_shapes
          cmp.w     #MEN_TOP_ATTR,d1
          beq       evt_menu_attr
          cmp.w     #MEN_TOP_SEL,d1
          beq       evt_menu_sel
          cmp.w     #MEN_TOP_TOOLS,d1
          beq       evt_menu_tools
          addq.l    #4,sp
evt_mul5  move.w    EV_MSG_BUF+6(a6),d1 ;undo inversion of top-level menu
          aes       33 2 1 1 0 !d1 1 !menu_adr  ;menu_tnormal
          bra       evt_multi
evt_mul4  ;                             check for window event types
          pea       evt_multi           push handler address to stack -> "rts" returns to loop
          cmp.w     #20,d0
          beq       redraw
          cmp.w     #21,d0
          beq       topped
          cmp.w     #22,d0
          beq       closed
          cmp.w     #23,d0
          beq       fulled
          cmp.w     #24,d0
          beq       arrowed
          cmp.w     #25,d0
          beq       hslid
          cmp.w     #26,d0
          beq       vslid
          cmp.w     #27,d0
          beq       sized
          cmp.w     #28,d0
          beq       moved
exec_rts  rts

*-----------------------------------------------------------------------------
* This function handles window redraw events, which usually are triggered by
* a window being created or being exposed. The function first determines which
* of the managed windows this event refers to, then iterates across all
* exposed areas to redraw them. The latter is done by copying the respective
* areas from the backing storage (i.e. window-specific image buffer)
*
* Additionally this function is called directly to force a redraw after
* changes to the content (e.g. undo of a drawing operation)
*
redraw    bsr       hide_m              --- WM_Redraw - Procedure ---
          aes       107 1 1 0 0 1       ;wind_update
          move.l    EV_MSG_BUF+8(a6),d0
          move.l    EV_MSG_BUF+12(a6),d1
          add.l     d0,d1
          sub.l     #$10001,d1
          cmp.w     #400,d1             Correct clipping rectangle
          blo.s     redraw8
          move.w    #399,d1
redraw8   swap      d1
          cmp.w     #640,d1
          blo.s     redraw9
          move.w    #639,d1
redraw9   swap      d1
          move.l    d0,d4               D4/D5: X/Y-Min-upper-left-corner
          move.l    d0,d5
          move.l    d1,d6               D6/D7: X/Y-Max-lower-right-corner
          move.l    d1,d7
          swap      d4
          swap      d6
          moveq.l   #WIN_STRUCT_CNT-1,d0  ++ Determine window-record ++
          move.w    EV_MSG_BUF+6(a6),d2
          lea       wi1-WIN_STRUCT_SZ,a3
redraw1   add.w     #WIN_STRUCT_SZ,a3
          cmp.w     (a3),d2             A3: address of window-record
          beq.s     redraw2
          dbra      d0,redraw1
          bra       rw_end              none of our windows -> done
redraw2   moveq.l   #11,d3
getreck   ;
          aes       104 2 5 0 0 !(a3) !d3  ;wind_get
          move.l    INTOUT+2(a6),d0
          move.l    INTOUT+6(a6),d1
          tst.l     d1
          beq       rw_end              end of list?
          add.l     d0,d1
          sub.l     #$10001,d1
          cmp.w     d5,d0               ++ calculate intersecting area ++
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
redraw6   cmp.w     d0,d1               no intersection?
          blo.s     redraw7             -> next rectangle
          swap      d0
          swap      d1
          cmp.w     d0,d1
          blo.s     redraw7
          move.l    d0,d2
          add.w     WIN_ROOT_YX(a3),d0
          add.w     WIN_ROOT_YX(a3),d1
          add.l     WIN_ROOT_YX+2(a3),d0
          add.l     WIN_ROOT_YX+2(a3),d1
          move.l    WIN_IMGBUF_ADDR(a3),a0
          move.l    logbase,a1
          movem.l   d4-d7,-(sp)
          movem.l   a3/d0-d2,-(sp)
          bsr       copy_blk            copy the area from the image buffer
          movem.l   (sp)+,a3/d0-d2
          tst.w     SEL_STATE(a6)       redraw rectangle?
          beq.s     redraw10
          cmp.l     rec_adr,a3
          bne.s     redraw10
          move.l    WIN_CUR_XY(a3),-(sp)
          move.l    WIN_CUR_WH(a3),-(sp)
          move.l    d2,WIN_CUR_XY(a3)
          sub.l     d0,d1
          add.l     #$10001,d1
          move.l    d1,WIN_CUR_WH(a3)
          bsr       fram_drw            -> redraw frame
          move.l    rec_adr,a3
          move.l    (sp)+,WIN_CUR_WH(a3)
          move.l    (sp)+,WIN_CUR_XY(a3)
redraw10  movem.l   (sp)+,d4-d7
redraw7   moveq.l   #12,d3
          bra       getreck
rw_end    ;
          aes       107 1 1 0 0 0       ;wind_update
          bra       show_m
          ;
*-----------------------------------------------------------------------------
* Handle the "topped" event which indicates a new window has been activated
* and will receive focus.
*
topped    move.w    EV_MSG_BUF+6(a6),d3   --- Topped ---
          move.w    WIN_HNDL(a4),d2
          cmp.w     d3,d2
          beq.s     topped5             only reactivate window
          bsr       save_scr
          move.l    a4,a0
          lea       wi1,a4
          moveq.l   #WIN_STRUCT_CNT-1,d0
topped1   cmp.w     WIN_HNDL(a4),d3     search matching window record
          beq.s     topped2
          add.w     #WIN_STRUCT_SZ,a4
          dbra      d0,topped1
          move.l    a0,a4               none of our windows
          rts
topped2   lea       wi1,a0              references to this record...
          moveq.l   #WIN_STRUCT_CNT-1,d0
topped3   cmp.b     WIN_PREV_HNDL(a0),d3
          bne.s     topped4
          move.b    WIN_PREV_HNDL(a4),WIN_PREV_HNDL(a0)   ...replace
topped4   add.w     #WIN_STRUCT_SZ,a0
          dbra      d0,topped3
          move.b    d2,WIN_PREV_HNDL(a4)
          bsr       fram_del
          lea       rec_adr,a0
          move.l    a4,(a0)             store address of new active window
          bsr       prep_men            set state of "Save" menu entry
topped5   move.w    d3,d1
          moveq.l   #10,d0
          bra       aes_win_set         ;wind_set WF_TOP

*-----------------------------------------------------------------------------
* The following function handle mouse clicks into the scrolling controls
* (i.e. hor/vert. sliders and arrows). The function updates the slider
* position and then redraws the window content accordingly.
*
hslid     clr.l     d1                  --- horizontal slider ---
          move.w    EV_MSG_BUF+8(a6),d1
          move.w    #640,d0
          sub.w     WIN_CUR_WH(a4),d0
          mulu      d0,d1
          bsr       divu1000            D1:=D1/1000
          sub.w     WIN_CUR_XY(a4),d1
          move.w    d1,WIN_ROOT_YX+2(a4)
          move.w    EV_MSG_BUF+8(a6),d1
          move.w    d1,WIN_HSLIDER_OFF(a4)
          moveq.l   #8,d0
          bsr       aes_win_set         ;wind_set WF_HSLIDE: update slider pos.
          bra.s     vslidrw
          ;
vslid     clr.l     d1                  --- vertical slider ---
          move.w    EV_MSG_BUF+8(a6),d1
          move.w    #400,d0
          sub.w     WIN_CUR_XY+6(a4),d0
          mulu      d0,d1
          bsr       divu1000            D1:=D1/1000
          sub.w     WIN_CUR_XY+2(a4),d1
          move.w    d1,WIN_ROOT_YX(a4)
          lsl.w     #4,d1
          moveq.l   #25,d0
          bsr       divu_d0
          move.w    EV_MSG_BUF+8(a6),d1
          move.w    d1,WIN_VSLIDER_OFF(a4)
          moveq.l   #9,d0               ;wind_set WF_VSLIDE: update slider pos.
          bsr       aes_win_set
vslidrw   bsr       hide_m              ** Top-Window neuzeichnen **
          move.l    rec_adr,a0
          move.l    WIN_CUR_XY(a0),d0
          move.l    WIN_CUR_WH(a0),d1
          move.l    d0,d2
          add.l     d0,d1
          sub.l     #$10001,d1
          cmp.w     #400,d2             correct clipping rectangle
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
vslidrw2  add.l     WIN_ROOT_YX+2(a0),d0
          add.w     WIN_ROOT_YX(a0),d0
          add.l     WIN_ROOT_YX+2(a0),d1
          add.w     WIN_ROOT_YX(a0),d1
          move.l    WIN_IMGBUF_ADDR(a0),a0
          move.l    logbase,a1
          bsr       copy_blk
          tst.w     SEL_STATE(a6)
          beq.s     vslidrw3
          bsr       fram_drw
vslidrw3  bra       show_m
          ;
arrowed   move.l    #400,d2             D2: max. Y-Offset
          sub.w     WIN_CUR_XY+6(a4),d2
          move.w    EV_MSG_BUF+8(a6),d0   --- Scrollbar or scrolling arrows ---
          cmp.b     #3,d0
          bne.s     arrowed1
          move.w    WIN_ROOT_YX(a4),d1    -- scroll up by one pixel --
          add.w     WIN_CUR_XY+2(a4),d1
          beq       exec_rts
          subq.w    #1,WIN_ROOT_YX(a4)
          subq.w    #1,d1
arrowedA  mulu      #1000,d1
          cmp.l     d2,d1
          bhs.s     arrowedB
          clr.w     d1
          bra.s     arrowedC
arrowedB  divu      d2,d1
arrowedC  moveq.l   #9,d0
          move.w    d1,WIN_VSLIDER_OFF(a4)
          bsr       aes_win_set         ;wind_set WF_VSLIDE: update slider pos.
          bra       vslidrw
arrowed1  cmp.b     #2,d0
          bne.s     arrowed2
          move.w    WIN_ROOT_YX(a4),d1    -- scroll down by one pixel --
          add.w     WIN_CUR_XY+2(a4),d1
          cmp.w     d2,d1
          bhs       exec_rts
          addq.w    #1,WIN_ROOT_YX(a4)
          addq.w    #1,d1
          bra       arrowedA
arrowed2  tst.b     d0
          bne.s     arrowed3
          clr.w     d1                  -- scroll to the top --
          sub.w     WIN_CUR_XY+2(a4),d1
          move.w    d1,WIN_ROOT_YX(a4)
          clr.w     d1
          clr.w     WIN_VSLIDER_OFF(a4)
          moveq.l   #9,d0
          bsr       aes_win_set
          bra       vslidrw
arrowed3  cmp.b     #1,d0
          bne.s     arrowed4
          move.w    d2,d1               -- scroll to the bottom --
          sub.w     WIN_CUR_XY+2(a4),d1
          move.w    d1,WIN_ROOT_YX(a4)
          move.w    #1000,d1
          move.w    #1000,WIN_VSLIDER_OFF(a4)
          moveq.l   #9,d0
          bsr       aes_win_set
          bra       vslidrw
arrowed4  move.l    #640,d2             D2: max. X-Offset
          sub.w     WIN_CUR_WH(a4),d2
          cmp.b     #7,d0
          bne.s     arrowed5
          move.w    WIN_ROOT_YX+2(a4),d1   -- scroll 1 pixel to the left --
          add.w     WIN_CUR_XY(a4),d1
          beq       exec_rts
          subq.w    #1,WIN_ROOT_YX+2(a4)
          subq.w    #1,d1
arrowedD  mulu      #1000,d1
          cmp.l     d2,d1
          bhs.s     arrowedE
          clr.w     d1
          bra.s     arrowedF
arrowedE  divu      d2,d1
arrowedF  moveq.l   #8,d0
          move.w    d1,WIN_HSLIDER_OFF(a4)
          bsr       aes_win_set
          bra       vslidrw
arrowed5  cmp.b     #6,d0
          bne.s     arrowed6
          move.w    WIN_ROOT_YX+2(a4),d1   -- scroll 1 pixel to the right --
          add.w     WIN_CUR_XY(a4),d1
          cmp.w     d2,d1
          bhs       exec_rts
          addq.w    #1,WIN_ROOT_YX+2(a4)
          addq.w    #1,d1
          bra       arrowedD
arrowed6  cmp.b     #4,d0
          bne.s     arrowed7
          clr.w     d1                  -- scroll to left border --
          sub.w     WIN_CUR_XY(a4),d1
          move.w    d1,WIN_ROOT_YX+2(a4)
          clr.w     d1
          clr.w     WIN_HSLIDER_OFF(a4)
          moveq.l   #8,d0
          bsr       aes_win_set
          bra       vslidrw
arrowed7  cmp.b     #5,d0
          bne       exec_rts
          move.w    d2,d1               -- scroll to right border --
          sub.w     WIN_CUR_XY(a4),d1
          move.w    d1,WIN_ROOT_YX+2(a4)
          move.w    #1000,d1
          move.w    #1000,WIN_HSLIDER_OFF(a4)
          moveq.l   #8,d0
          bsr       aes_win_set
          bra       vslidrw
          ;
*-----------------------------------------------------------------------------
* The fuollowing functions handle notification about a request to resize or
* move a window.
*
sized     move.l    EV_MSG_BUF+8(a6),INTIN+4(a6)    --- Change of window size ---
          move.l    EV_MSG_BUF+12(a6),INTIN+8(a6)
          aes       105 6 1 0 0 !(a4) 5   ;wind_set
          aes       108 6 5 0 0 1 $fef  ;wind_calc
          move.l    INTOUT+6(a6),d3
          bra       sizedsub
          ;
moved     move.l    EV_MSG_BUF+8(a6),INTIN+4(a6)    --- Moving window ---
          move.l    EV_MSG_BUF+12(a6),INTIN+8(a6)
          aes       105 6 1 0 0 !(a4) 5  ;wind_set
          aes       108 6 5 0 0 1 $fef   ;wind_calc
          move.l    INTOUT+2(a6),d3
          bra       movedsub
          ;
fulled    move.l    WIN_CUR_XY(a4),d0      --- Maximize window ---
          move.l    WIN_CUR_WH(a4),d1
          cmp.l     maxwin,d0
          bne.s     fulled3
          cmp.l     maxwin+4,d1
          beq.s     fulled1
fulled3   move.l    d0,WIN_PREMAX_XY(a4)      - maximum size -
          move.l    d1,WIN_PREMAX_WH(a4)
          move.l    maxwin,d3
          move.l    maxwin+4,d4
          bra.s     fulled2
fulled1   move.l    WIN_PREMAX_XY(a4),d3      - de-maximize: back to previous window size -
          move.l    WIN_PREMAX_WH(a4),d4
fulled2   move.l    d3,INTIN+4(a6)
          move.l    d4,INTIN+8(a6)
          aes       108 6 5 0 0 0 $fef   ;wind_calc
          move.l    INTOUT+2(a6),INTIN+4(a6)
          move.l    INTOUT+6(a6),INTIN+8(a6)
          aes       105 6 1 0 0 !(a4) 5  ;wind_set
          bsr       movedsub
          move.l    d4,d3
          bra       sizedsub
          ;
*-----------------------------------------------------------------------------
* Handle request to close a window.
*
closed    bsr       wind_chg            --- Close window ---
          beq.s     closed5
          lea       straldel,a0
          moveq.l   #1,d0
          bsr       alertbox            Warn "Really discard...?"
          move.w    INTOUT(a6),d0
          cmp.w     #1,d0
          bne       exec_rts
closed5   move.l    WIN_CUR_XY(a4),d0
          move.l    d0,INTIN+8(a6)
          add.l     #$10001,d0
          move.l    d0,INTIN+0(a6)
          move.l    #$100010,INTIN+4(a6)
          move.l    WIN_CUR_WH(a4),INTIN+12(a6)
          aes       74 8 1 0 0          ;graf_shrinkbox
          aes       102 1 1 0 0 !(a4)   ;wind_close
          aes       103 1 1 0 0 !(a4)   ;wind_delete
          move.l    WIN_IMGBUF_ADDR(a4),-(sp)  ;mfree
          move.w    #$49,-(sp)
          trap      #1
          addq.l    #6,sp
          clr.b     WIN_STATE_FLAGS(a4)
          moveq.l   #MEN_IT_UNDO,d0     disable "undo" menu entry
          bsr       men_idis
          clr.w     UNDO_STATE(a6)
          tst.w     SEL_STATE(a6)       selection ongoing?
          bne.s     closed7
          move.l    UNDO_BUF_ADDR(a6),d0      no; undo buffer refers to current window?
          cmp.l     WIN_IMGBUF_ADDR(a4),d0
          bne.s     closed8
          clr.w     SEL_FLAG_PASTABLE(a6)    yes -> disable paste
          moveq.l   #MEN_IT_SEL_PAST,d0 ;disable "paste" menu entry
          bsr       men_idis
          bra.s     closed8
closed7   clr.b     SEL_STATE(a6)       delete selection frame (SEL_STATE:=$00ff intentional)
          bsr       fram_del
closed8   move.w    #-1,(a4)            reset window handle
          clr.w     d2
          move.b    WIN_PREV_HNDL(a4),d2
          lea       wi_count,a0
          sub.w     #1,(a0)
          ble.s     closed2
          lea       wi1-WIN_STRUCT_SZ,a4  ; loop to search previous active window
          moveq.l   #WIN_STRUCT_CNT-1,d0
closed1   add.w     #WIN_STRUCT_SZ,a4
          cmp.w     WIN_HNDL(a4),d2     match?
          dbeq      d0,closed1
          lea       rec_adr,a0
          move.l    a4,(a0)             -> set as current
          bsr       prep_men            Set state of "Save" menu entry
          move.w    wi_count,d0
          cmp.w     #6,d0
          blo       exec_rts
          move.l    menu_adr,a3         enable accessories
          add.w     #MEN_IT_ACC0*RSC_OBJ_SZ+11,a3
          moveq.l   #5,d0
closed4   bclr.b    #3,(a3)
          add.w     #RSC_OBJ_SZ,a3
          dbra      d0,closed4
          rts
          ;
closed2   moveq.l   #MEN_IT_DISC,d0     all windows closed -> disable menu entries
          bsr       men_idis            disble "discard"
          moveq.l   #MEN_IT_SAV_AS,d0   disble "save as"
          bsr       men_idis
          moveq.l   #MEN_IT_SAVE,d0     disable "save"
          bsr       men_idis
          moveq.l   #MEN_IT_PRINT,d0    disble "print"
          bra       men_idis
          ;
*-----------------------------------------------------------------------------
* Enter fullscreen mode after a click with the right mouse-button.
*
absmod    move.l    rec_adr,a4          ** Switch into full-screen mode **
          move.w    WIN_HNDL(a4),d0
          bmi       evt_multi
          bsr       swap_buf
          bsr       hide_m
          move.w    #-1,-(sp)           resolution unchanged
          move.l    bildbuff,-(sp)      phys. screen := logical screen
          move.l    bildbuff,-(sp)
          move.w    #5,-(sp)            ;XBIOS set_screen
          trap      #14
          add.w     #12,sp
          bsr       show_m
          move.l    a4,-(sp)            save address of window record
          move.l    WIN_IMGBUF_ADDR(a4),a0
          lea       wiabs,a4            switch to dummy window record
          lea       rec_adr,a1
          move.l    a4,(a1)
          move.l    bildbuff,WIN_IMGBUF_ADDR(a4)
          lea       bildbuff,a1
          move.l    a0,(a1)
absmod2   tst.b     MOUSE_RBUT(a6)      busy loop until right mouse button is released
          bne       absmod2
          clr.w     MOUSE_RBUT(a6)
absmod3   tst.w     MOUSE_RBUT(a6)      +++ loop +++
          bne.s     absmod4
          tst.w     MOUSE_LBUT(a6)
          beq       absmod3
          move.l    rec_adr,a4
          bsr       evt_butt
absmod6   tst.b     MOUSE_LBUT+1(a6)    busy loop until left mouse button is released
          bne       absmod6
          clr.w     MOUSE_LBUT(a6)
          bra       absmod3
          ;
absmod4   bsr       hide_m              +++ Leaving full-screen mode +++
          bsr       swap_buf
          move.w    #-1,-(sp)
          move.l    logbase,-(sp)
          move.l    logbase,-(sp)
          move.w    #5,-(sp)            ;XBIOS set_screen
          trap      #14
          add.w     #12,sp
          bsr       show_m
          lea       bildbuff,a1
          move.l    WIN_IMGBUF_ADDR(a4),(a1)
          lea       rec_adr,a0
          move.l    (sp)+,a4
          move.l    a4,(a0)
absmod5   tst.b     MOUSE_RBUT(a6)      busy loop until right mouse button is released
          bne.s     absmod5
          clr.w     MOUSE_RBUT(a6)
          bsr       win_rdw
          bra       evt_multi
*---------------------------------------------------------------------
* Query for full-screen mode
* Result: status.EQ set if yes
*
is_absmode:
          lea       wiabs,a0
          cmp.l     rec_adr,a0
          rts
*--------------------------------------------------------SUB-FUNCTIONS
hide_m    move.l    #$7b0000,CONTRL+0(a6)      hide_cursor
          clr.w     CONTRL+6(a6)
          bra       vdicall
          ;
show_m    move.l    #$7a0000,CONTRL+0(a6)      show_cursor
          move.w    #1,CONTRL+6(a6)
          move.w    #1,INTIN+0(a6)
          bra       vdicall
          ;
aes_win_set:
          aes       105 3 1 0 0 !WIN_HNDL(a4) !d0 !d1  ;wind_set
          rts
          ;
aes_rsrc_gad:
          clr.w     d0                  default type = R_TREE
aes_rsrc_gad_ext:
          aes       112 2 1 0 1 !d0 !d1 ;rsrc_gaddr
          rts
          ;
aes_get_top:                            ;** Return handle of top-level window **
          aes       104 2 5 0 0 !WIN_HNDL(a1) 10  ;wind_get: WF_TOP
          move.w    INTOUT+2(a6),d0     Retrieve handle of the top-most window
          move.l    rec_adr,a0
          cmp.w     WIN_HNDL(a0),d0     compare with handle of active window
          rts
          ;
win_rdw   bsr       aes_get_top         ** Redraw screen **
          beq       vslidrw             redraw top-level window
          lea       EV_MSG_BUF(a6),a0
          move.w    (a1),6(a0)
          move.l    WIN_CUR_XY(a1),8(a0)
          move.l    WIN_CUR_WH(a1),12(a0)
          bra       redraw              use redraw-procedure
          ;
prep_men  move.l    WIN_IMGBUF_ADDR(a4),a0     ** Set State of "Save" menu entry **
          add.w     #32010,a0
          moveq.l   #MEN_IT_SAVE,d0     index of "save" menu entry
          tst.b     (a0)                window title set?
          bne       men_iena            yes -> enable "save"
          bra       men_idis            no -> disable "save"
          ;
*-----------------------------------------------------------------------------
divu1000  move.l    #1000,d0
          ; alternate entry point
divu_d0   cmp.l     d0,d1               ** D1 := D1 / D0 **
          bhs.s     divu_d01
          swap      d1
          bra.s     divu_d02
divu_d01  divu      d0,d1
divu_d02  rts
          ;
*-----------------------------------------------------------------------------
main_rcs_err:
          lea       stralrsc,a0         ** Error loading AES resource file **
          moveq.l   #1,d0
          bsr       alertbox            notify user (most likely RCS file is missing)
          ;fall-through
main_err  clr.w     -(sp)               ** Error initialization -> exit program **
          trap      #1
          bra       main_err
          ;
*-----------------------------------------------------------------------------
* This function is installed as hook in the mouse button interrupt handler
* (i.e. it is called for each button press or release). The function keeps
* track of the state of left and right mouse button.
*
maus_kno  subq.l    #4,sp               ** Mouse button interrupt **
          movem.l   a0/a6,-(sp)
          lea       dsect_a6,a6
          move.w    #1,$9ef0
          btst      #0,d0               ++ left button ++
          beq.s     maus_kn2
          tst.w     MOUSE_LBUT(a6)      button click already registered?
          bne.s     maus_kn5            -> ignore
          move.l    logbase,a0
          tst.b     $54(a0)             any menus active?
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
          move.l    #$1010000,MOUSE_LBUT(a6)
          move.l    MOUSE_CUR_XY(a6),MOUSE_ORIG_XY(a6) ;save mouse coordinates
          bra.s     maus_kn5
maus_kn3  move.l    #$101ffff,MOUSE_LBUT(a6)      ; set flag: mouse pressed during menus
          bra.s     maus_kn5
maus_kn2  clr.b     MOUSE_LBUT+1(a6)
maus_kn5  btst      #1,d0               ++ right mouse button ++
          beq.s     maus_kn4
          tst.w     MOUSE_RBUT(a6)
          bne.s     maus_kn4
          move.w    #-1,MOUSE_RBUT(a6)
          bra.s     maus_kn1
maus_kn4  clr.b     MOUSE_RBUT(a6)
maus_kn1  lea       wiabs,a0            in full-screen mode?
          cmp       rec_adr,a0
          bne.s     maus_kn6
          movem.l   (sp)+,a0/a6         yes -> do not invoke standard handler
          addq.l    #4,sp
          rts
maus_kn6  move.l    MOUSE_VEC_BUT(a6),8(sp) ;place address of standard handler on the stack
          movem.l   (sp)+,a0/a6         restore registers
          rts                           ;jump via RTS so that no register is needed
          ;
*-----------------------------------------------------------------------------
* This function is installed as hook in the mouse movement interrupt handler.
* The function only stores the current X/Y coordinates.
*
maus_mov  subq.l    #8,sp               ** Mouse movement interrupt **
          move.l    a6,(sp)
          lea       dsect_a6,a6
          move.w    d0,MOUSE_CUR_XY+0(a6)   ;X
          move.w    d1,MOUSE_CUR_XY+2(a6)   ;Y
          move.l    MOUSE_VEC_MOV(a6),4(sp) ;place address of standard handler on the stack
          lea       wiabs,a6            in full-screen mode?
          cmp       rec_adr,a6
          bne.s     maus_mo1
          move.l    (sp),a6             yes -> do not invoke standard handler
          addq.l    #8,sp
          rts
maus_mo1  move.l    (sp)+,a6            restore A6
          rts                           ;jump via RTS so that no register is needed
          ;
*-----------------------------------------------------------------------------
save_scr  move.w    wi_count,d0         ** Release screen buffer **
          beq       exec_rts
          tst.b     UNDO_STATE(a6)      drawing changed?
          beq       exec_rts
          move.l    rec_adr,a1
          bclr.b    #3,WIN_STATE_FLAGS(a1)   ;check and clear undo flag
          bne.s     save_sc1
          bset.b    #1,WIN_STATE_FLAGS(a1)   ;not undone -> image modified
save_sc1  clr.w     UNDO_STATE(a6)      buffer free & move done
          clr.b     SEL_TMP_OVERLAY(a6) short-overlay mode cleared
          clr.b     SEL_FLAG_DEL(a6)    do not delete old border
          moveq.l   #MEN_IT_UNDO,d0     disable "undo" menu entry
          bra       men_idis
          ;
*-----------------------------------------------------------------------------
swap_buf  move.l    bildbuff,a1         ** Swap content of buffers **
          move.l    rec_adr,a0
          move.l    WIN_IMGBUF_ADDR(a0),a0
          move.w    #3999,d1
swap_bu1  move.l    (a0),d0
          move.l    (a1),(a0)+
          move.l    d0,(a1)+
          move.l    (a0),d0             unrolled once
          move.l    (a1),(a0)+
          move.l    d0,(a1)+
          dbra      d1,swap_bu1
          rts
          ;
*-----------------------------------------------------------------------------
sizedsub  move.l    d3,WIN_CUR_WH(a4)    ** Set window size **
          move.w    d3,d1               +++ vert. slider +++
          mulu.w    #5,d1
          lsr.w     #1,d1               slider size
          move.w    d1,WIN_VSLIDER_SZ(a4)
          moveq.l   #16,d0
          bsr       aes_win_set         ;wind_set WF_VSLSIZE
          move.w    #400,d0             slider pos
          sub.w     WIN_CUR_XY+6(a4),d0
          move.w    WIN_CUR_XY+2(a4),d1
          add.w     WIN_ROOT_YX(a4),d1
          mulu.w    #1000,d1
          bsr       divu_d0
          move.w    d1,WIN_VSLIDER_OFF(a4)
          moveq.l   #9,d0
          bsr       aes_win_set
          add.w     WIN_CUR_XY+2(a4),d3    offset
          add.w     WIN_ROOT_YX(a4),d3
          sub.w     #400,d3
          bls.s     sized1
          sub.w     d3,WIN_ROOT_YX(a4)
sized1    swap      d3                  +++ hor. slider +++
          move.w    d3,d1
          mulu.w    #25,d1              slider size
          lsr.w     #4,d1
          move.w    d1,WIN_HSLIDER_SZ(a4)
          moveq.l   #15,d0
          bsr       aes_win_set
          move.w    #640,d0             slider pos
          sub.w     WIN_CUR_WH(a4),d0
          move.w    WIN_CUR_XY(a4),d1
          add.w     WIN_ROOT_YX+2(a4),d1
          mulu.w    #1000,d1
          bsr       divu_d0
          move.w    d1,WIN_HSLIDER_OFF(a4)
          moveq.l   #8,d0
          bsr       aes_win_set
          add.w     WIN_CUR_XY(a4),d3      offset
          add.w     WIN_ROOT_YX+2(a4),d3
          sub.w     #640,d3
          bls       exec_rts
          sub.w     d3,WIN_ROOT_YX+2(a4)
          rts
          ;
*-----------------------------------------------------------------------------
movedsub  move.w    WIN_ROOT_YX(a4),d1     ** Set window position **
          add.w     WIN_CUR_XY+2(a4),d1    D1: new Y-offset
          sub.w     d3,d1
          move.w    WIN_ROOT_YX+2(a4),d2   D2: new X-offset
          add.w     WIN_CUR_XY(a4),d2
          move.l    d3,WIN_CUR_XY(a4)
          swap      d3
          sub.w     d3,d2
          swap      d1
          move.w    d2,d1
          move.l    d1,WIN_ROOT_YX(a4)
          rts
          ;
*-----------------------------------------------------------------------------
aescall   move.l    a6,d1
          add.l     #AESPB,d1
          move.l    #$c8,d0
          trap      #2
          rts
          ;
vdicall   move.w    GRHANDLE(a6),CONTRL+12(a6)
          move.l    a6,d1
          add.l     #VDIPB,d1
          moveq.l   #$73,d0
          trap      #2
          rts
          ;
**********************************************************************
**  Function parameters
**  ===================
**    D0:  X/Y-coordinates of the upper-left corner of source
**    D1:  X/Y-coordinates of the lower-right corner of the source
**    D2:  X/Y-coordinates of the upper-left corner of the destination
**    A0:  source base address
**    A1:  target base address
**
**********************************************************************
          ;
copy_blk  movem.l   a4,-(sp)           *** Bit-Block Copy Function (Raster copy) ***
          move.l    #$2800190,d3
          cmp.l     d0,d3               check range of source X1/Y1
          bls       copy_blk_err
          cmp.w     d0,d3
          bls       copy_blk_err
          cmp.l     d1,d3               check range of source X2/Y2
          bls       copy_blk_err
          cmp.w     d1,d3
          bls       copy_blk_err
          lea       blk_data,a3
          lea       rand_tab,a4
          move.w    d1,d3
          sub.w     d0,d3
          bcs       copy_blk_err
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
          bcs       copy_blk_err
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
          bne.s     init3               ++ no move ++
          move.w    #%0100111001110001,d6
          move.w    #-1,d4
          clr.w     d5
          bra       rechts
init3     blo.s     init4               ++ move to the right ++
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
init4     move.w    #%1110000101011000,d6  ++ move to the left ++
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
rechts    lea       rechts,a4
          move.w    d6,ror1-rechts(a4)  ********  Right  ********
          move.w    d6,ror2-rechts(a4)
          move.w    d6,ror3-rechts(a4)  Patch rotation instructions into code
nxt_lin1  move.w    (a0)+,d0            +++ left border +++
ror1      nop                           ATTN: self-modified code
          move.w    d0,d2
          and.w     2(a3),d0            mask left border
          and.w     d4,d0               determine right-side portion
          move.w    (a1),d1
          and.w     6(a3),d1
          or.w      d0,d1               OR into destination
          move.w    d1,(a1)+
          move.w    (a3),d6             no middle section?
          bmi.s     test1
nxt_wrd1  move.w    (a0)+,d0            +++ middle +++
ror2      nop                           ATTN: self-modified code
          move.w    d0,d1
          and.w     d4,d0               determine right-side portion
          and.w     d5,d2
          or.w      d2,d0               +plus left part of previous word
          move.w    d0,(a1)+            store to target bitmap
          move.w    d1,d2
          dbra      d6,nxt_wrd1
rand1     and.w     d5,d2               +++ right border +++
          move.w    (a0),d0
ror3      nop                           ATTN: self-modified code
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
links     lea       links,a4
          move.w    d6,rol1-links(a4)   ********  Left  ********
          move.w    d6,rol2-links(a4)
          move.w    d6,rol3-links(a4)   Patch rotation instructions into code
          move.w    d6,rol4-links(a4)
nxt_lin2  move.w    2(a0),d0            +++ right border +++
rol4      nop                           ATTN: self-modified code
          and.w     d4,d0
          move.w    d0,d1
          move.w    (a0),d0
rol1      nop                           ATTN: self-modified code
          move.w    d0,d2
          and.w     d5,d0               determine left-side portion
          or.w      d1,d0
          and.w     4(a3),d0            mask right border
          move.w    (a1),d1
          and.w     8(a3),d1
          or.w      d0,d1               OR into destination
          move.w    d1,(a1)
          move.w    (a3),d6             no middle section?
          bmi.s     test2
nxt_wrd2  move.w    -(a0),d0            +++ middle +++
rol2      nop                           ATTN: self-modified code
          move.w    d0,d1
          and.w     d5,d0               determine left-side portion...
          and.w     d4,d2
          or.w      d2,d0               +plus right part of previous word
          move.w    d0,-(a1)            store to target bitmap
          move.w    d1,d2
          dbra      d6,nxt_wrd2
rand2     and.w     d4,d2               +++ left border +++
          move.w    -(a0),d0
rol3      nop                           ATTN: self-modified code
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
copy_blk_err:
          move.l    (sp)+,a4
          rts
          ;
*----------------------------------------------------------BITBLK-DATA
rand_tab  dc.w      $ffff,$7fff,$3fff,$1fff,$fff,$7ff,$3ff,$1ff,$ff
          dc.w      $7f,$3f,$1f,$f,7,3,1,0
blk_data  ds.w      10
*-----------------------------------------------------WINDOW-VARIABLES
dsect_a6  ds.l      (DSECT_SZ+3)/4
menu_adr  ds.l      1          Address of menu object tree
logbase   ds.l      1          Address of screen buffer
bildbuff  ds.l      1          Address of general buffer
rec_adr   ds.l      1          Address of current window's record within "wi1", or address of "wiabs" in abs.mode
maxwin    dc.w      1,37,620,342  Window size after maximize
*-----------------------------------------------------WINDOW-VARIABLES
wi_count  dc.w      0          Number of open windows
wi1       dc.w    -1,0,0,0,0,0,0,0,-40,-03,0,03,40,614,337,0,0,959,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-11,0,11,40,606,337,0,0,947,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-19,0,19,40,598,337,0,0,934,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-27,0,27,40,590,337,0,0,922,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-35,0,35,40,582,337,0,0,909,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-43,0,43,40,574,337,0,0,897,887
          dc.w    -1,0,0,0,0,0,0,0,-40,-51,0,51,40,566,337,0,0,884,887
wiabs     dc.w    -1,0,0,0,0,0,0,0,0,0,0,0,0,640,400,-1,-1
*--------------------------------------------------------------STRINGS
rscname   dc.b    'FA.RSC',0
stralrsc  dc.b    '[3][Failed to load resource file|'
          dc.b    '"FA.RSC"][Exit]',0             ; ATTN: keep equal with "rscname"
straldel  dc.b    '[1][You are discarding your|'
          dc.b    'unsaved image!][Ok|Cancel]',0
*---------------------------------------------------------------------
          align 2
          END
