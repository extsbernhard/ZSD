***INCLUDE MZSD_05_KONTRAKTF01 .
*----------------------------------------------------------------------*
*   INCLUDE TABLECONTROL_FORMS                                         *
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  USER_OK_TC                                               *
*&---------------------------------------------------------------------*
 FORM user_ok_tc USING    p_tc_name TYPE dynfnam
                          p_table_name
                          p_mark_name
                          p_del_able
                 CHANGING p_ok      LIKE sy-ucomm.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
   DATA: l_ok              TYPE sy-ucomm,
         l_offset          TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

* Table control specific operations                                    *
*   evaluate TC name and operations                                    *
   SEARCH p_ok FOR p_tc_name.
   IF sy-subrc <> 0.
     EXIT.
   ENDIF.
   l_offset = strlen( p_tc_name ) + 1.
   l_ok = p_ok+l_offset.
* execute general and TC specific operations                           *
   CASE l_ok.
*
     WHEN 'INSR'.                      "insert row
       IF NOT s_anle IS INITIAL
       OR NOT s_aend IS INITIAL.
         PERFORM fcode_insert_row USING   p_tc_name
                                          p_table_name.
         CLEAR p_ok.
       ELSE.
         MESSAGE s000 WITH text-e09.
       ENDIF.
*
     WHEN 'COPY'.                      "copy row
       IF NOT s_anle IS INITIAL
       OR NOT s_aend IS INITIAL.
         PERFORM fcode_copy_row USING     p_tc_name
                                          p_table_name.
         CLEAR p_ok.
       ELSE.
         MESSAGE s000 WITH text-e09.
       ENDIF.
*
     WHEN 'DELE'.                      "delete row
       IF NOT s_anle IS INITIAL
       OR NOT s_aend IS INITIAL.
         PERFORM fcode_delete_row USING   p_tc_name
                                          p_table_name
                                          p_mark_name
                                          p_del_able.
         CLEAR p_ok.
       ELSE.
         MESSAGE s000 WITH text-e09.
       ENDIF.
*
     WHEN 'DETA'.                      "Detailansicht
       PERFORM fcode_detail_row USING   p_tc_name
                                        p_table_name
                                        p_mark_name .
       CLEAR p_ok.
*
     WHEN 'UPDA'.                      "Tabelleneingabe
       IF NOT s_anle IS INITIAL
       OR NOT s_aend IS INITIAL.
         PERFORM fcode_update_table USING p_tc_name.

         CLEAR p_ok.
       ELSE.
         MESSAGE s000 WITH text-e09.
       ENDIF.

*
     WHEN 'P--' OR                     "top of list
          'P-'  OR                     "previous page
          'P+'  OR                     "next page
          'P++'.                       "bottom of list
       PERFORM compute_scrolling_in_tc USING p_tc_name
                                             l_ok.
       CLEAR p_ok.
*
     WHEN 'MARK'.                      "mark all filled lines
       PERFORM fcode_tc_mark_lines USING p_tc_name
                                         p_table_name
                                         p_mark_name   .
       CLEAR p_ok.
*
     WHEN 'DMRK'.                      "demark all filled lines
       PERFORM fcode_tc_demark_lines USING p_tc_name
                                           p_table_name
                                           p_mark_name .
       CLEAR p_ok.
*
   ENDCASE.

 ENDFORM.                              " USER_OK_TC
*
*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
 FORM fcode_insert_row USING    p_tc_name TYPE dynfnam
                                p_table_name.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
   DATA l_lines_name       LIKE feld-name.
   DATA l_selline          LIKE sy-stepl.
   DATA l_lastline         TYPE i.
   DATA l_line             TYPE i.
   DATA l_iline       TYPE i.
   DATA l_table_name       LIKE feld-name.
   FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
   FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
   FIELD-SYMBOLS <lines>              TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

   ASSIGN (p_tc_name) TO <tc>.

* get the table, which belongs to the tc                               *
   CONCATENATE p_table_name '[]' INTO l_table_name. "table body
   ASSIGN (l_table_name) TO <table>.                "not headerline

* get looplines of TableControl
   CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.
   ASSIGN (l_lines_name) TO <lines>.

* get current line
   GET CURSOR LINE l_selline.
   IF sy-subrc <> 0.                   " append line to table
     l_selline = <tc>-lines + 1.
* set top line and new cursor line                           *
     IF l_selline > <lines>.
       <tc>-top_line = l_selline - <lines> + 1 .
     ELSE.
       <tc>-top_line = 1.
     ENDIF.
   ELSE.                               " insert line into table
     l_selline = <tc>-top_line + l_selline - 1.
     l_lastline = <tc>-top_line + <lines> - 1.
   ENDIF.
* set new cursor line                                        *
   l_line = l_selline - <tc>-top_line + 1.

   CASE p_tc_name.
*
     WHEN 'TC_KONTRPOS'.
*      Insert initial Line
       CLEAR: wa_kontrpos,
              zsd_05_kontrpos.

       MOVE: zsd_05_kontrakt-kontrnr  TO zsd_05_kontrpos-kontrnr,
             zsd_05_kontrakt-kontrart TO zsd_05_kontrpos-kontrart.

       LOOP AT it_kontrpos.
         MOVE it_kontrpos-posnr TO wa_kontrpos-posnr.
       ENDLOOP.

       ADD 10 TO wa_kontrpos-posnr.

       MOVE wa_kontrpos-posnr TO zsd_05_kontrpos-posnr.

       MOVE 'X' TO s_insr.

       g_ts_kontrpos-pressed_tab = c_ts_kontrpos-tab1.

       CALL SCREEN 4000.
*
     WHEN 'TC_KONTRUPOS'.
*      Insert initial Line
       CLEAR wa_kontrupos.
       LOOP AT it_kontrupos.
         MOVE it_kontrupos-uposnr TO wa_kontrupos-uposnr.
       ENDLOOP.
       ADD 10 TO wa_kontrupos-uposnr.
       MOVE: zsd_05_kontrpos-kontrnr  TO wa_kontrupos-kontrnr,
             zsd_05_kontrpos-kontrart TO wa_kontrupos-kontrart,
             zsd_05_kontrpos-posnr    TO wa_kontrupos-posnr,
             'I'                      TO wa_kontrupos-action,
             'X'                      TO wa_kontrupos-delable.

       l_iline = <tc>-lines + 1.

       INSERT wa_kontrupos INTO <table> INDEX l_iline.
       MOVE 'X' TO s_insr1.
   ENDCASE.

   <tc>-lines = <tc>-lines + 1.
* set cursor
   SET CURSOR LINE l_iline.

   LOOP AT SCREEN.
     IF screen-group2 = 'INP'.
       screen-active   = 1.
       screen-input    = 1.
       MODIFY SCREEN.
     ENDIF.
   ENDLOOP.

 ENDFORM.                              " FCODE_INSERT_ROW
*
*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
 FORM fcode_copy_row USING    p_tc_name TYPE dynfnam
                                p_table_name.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
   DATA l_lines_name       LIKE feld-name.
   DATA l_selline          LIKE sy-stepl.
   DATA l_lastline         TYPE i.
   DATA l_line             TYPE i.
   DATA l_iline       TYPE i.
   DATA l_table_name       LIKE feld-name.
   FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
   FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
   FIELD-SYMBOLS <lines>              TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

   ASSIGN (p_tc_name) TO <tc>.

* get the table, which belongs to the tc                               *
   CONCATENATE p_table_name '[]' INTO l_table_name. "table body
   ASSIGN (l_table_name) TO <table>.                "not headerline

* get looplines of TableControl
   CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.
   ASSIGN (l_lines_name) TO <lines>.

* get current line
   GET CURSOR LINE l_selline.
   IF sy-subrc <> 0.                   " append line to table
     l_selline = <tc>-lines + 1.
* set top line and new cursor line                           *
     IF l_selline > <lines>.
       <tc>-top_line = l_selline - <lines> + 1 .
     ELSE.
       <tc>-top_line = 1.
     ENDIF.
   ELSE.                               " insert line into table
     l_selline = <tc>-top_line + l_selline - 1.
     l_lastline = <tc>-top_line + <lines> - 1.
   ENDIF.
* set new cursor line                                        *
   l_line = l_selline - <tc>-top_line + 1.

   CASE p_tc_name.
*
     WHEN 'TC_KONTRPOS'.
*      Insert copied Line
       CLEAR: wa_kontrpos,
              zsd_05_kontrpos.

       READ TABLE it_kontrpos INDEX l_selline INTO wa_kontrpos.

       MOVE: wa_kontrpos-stadtteil      TO zsd_05_kontrpos-stadtteil,
             wa_kontrpos-parzelle       TO zsd_05_kontrpos-parzelle,
             wa_kontrpos-objekt         TO zsd_05_kontrpos-objekt,
*             wa_kontrpos-matnr          TO zsd_05_kontrpos-matnr,
*             wa_kontrpos-matxt          TO zsd_05_kontrpos-matxt,
*             wa_kontrpos-objlaenge      TO zsd_05_kontrpos-objlaenge,
*             wa_kontrpos-objbreite      TO zsd_05_kontrpos-objbreite,
*             wa_kontrpos-objhoehe       TO zsd_05_kontrpos-objhoehe,
*             wa_kontrpos-menge_pos      TO zsd_05_kontrpos-menge_pos,
*             wa_kontrpos-preis          TO zsd_05_kontrpos-preis,
*             wa_kontrpos-peinh          TO zsd_05_kontrpos-peinh,
             wa_kontrpos-index_key      TO zsd_05_kontrpos-index_key,
             wa_kontrpos-index_basis    TO zsd_05_kontrpos-index_basis,
             wa_kontrpos-index_gjahr    TO zsd_05_kontrpos-index_gjahr,
             wa_kontrpos-index_monat    TO zsd_05_kontrpos-index_monat,
             wa_kontrpos-index_diff     TO zsd_05_kontrpos-index_diff,
             wa_kontrpos-index_diffeinh TO
                                        zsd_05_kontrpos-index_diffeinh,
             wa_kontrpos-verrtyp        TO zsd_05_kontrpos-verrtyp,
             wa_kontrpos-faktperiode    TO zsd_05_kontrpos-faktperiode,
             wa_kontrpos-faktdatab      TO zsd_05_kontrpos-faktdatab,
             wa_kontrpos-faktdatbis     TO zsd_05_kontrpos-faktdatbis,
             wa_kontrpos-verr_code      TO zsd_05_kontrpos-verr_code,
             wa_kontrpos-verr_grund     TO zsd_05_kontrpos-verr_grund.



       MOVE: zsd_05_kontrakt-kontrnr  TO zsd_05_kontrpos-kontrnr,
             zsd_05_kontrakt-kontrart TO zsd_05_kontrpos-kontrart.
       LOOP AT it_kontrpos.
         MOVE it_kontrpos-posnr TO wa_kontrpos-posnr.
       ENDLOOP.
       ADD 10 TO wa_kontrpos-posnr.
       MOVE wa_kontrpos-posnr TO zsd_05_kontrpos-posnr.
       MOVE 'X' TO s_insr.
       g_ts_kontrpos-pressed_tab = c_ts_kontrpos-tab1.
       CALL SCREEN 4000.
*
     WHEN 'TC_KONTRUPOS'.
*      Insert copied Line
   ENDCASE.

   <tc>-lines = <tc>-lines + 1.
* set cursor
   SET CURSOR LINE l_iline.

   LOOP AT SCREEN.
     IF screen-group2 = 'INP'.
       screen-active   = 1.
       screen-input    = 1.
       MODIFY SCREEN.
     ENDIF.
   ENDLOOP.


 ENDFORM.                              " FCODE_COPY_ROW
*
*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
 FORM fcode_delete_row
               USING    p_tc_name           TYPE dynfnam
                        p_table_name
                        p_mark_name
                        p_del_able.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
   DATA l_table_name          LIKE feld-name.

   FIELD-SYMBOLS <tc>         TYPE cxtab_control.
   FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
   FIELD-SYMBOLS <wa>.
   FIELD-SYMBOLS <mark_field>.
   FIELD-SYMBOLS <del_able>.
*-END OF LOCAL DATA----------------------------------------------------*

   ASSIGN (p_tc_name) TO <tc>.

* get the table, which belongs to the tc                               *
   CONCATENATE p_table_name '[]' INTO l_table_name. "table body
   ASSIGN (l_table_name) TO <table>.                "not headerline

* delete marked lines                                                  *
   DESCRIBE TABLE <table> LINES <tc>-lines.

   LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
     ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

*   access to the component 'DELABLE' of the table header              *
     ASSIGN COMPONENT p_del_able  OF STRUCTURE <wa> TO <del_able>.

*   set the internal table index into a variable
     CLEAR w_tabix.
     w_tabix = sy-tabix.

     IF <mark_field> = 'X' AND
        <del_able> = 'X'.

       CASE p_tc_name.
         WHEN 'TC_KONTRPOS'.

           CLEAR wa_kontrpos.

           wa_kontrpos = <wa>.

           DELETE <table> INDEX w_tabix.

           LOOP AT it_kontrupos_gesamt
             WHERE kontrart = wa_kontrpos-kontrart
             AND   kontrnr  = wa_kontrpos-kontrnr
             AND   posnr    = wa_kontrpos-posnr.

             DELETE it_kontrupos_gesamt INDEX sy-tabix.
           ENDLOOP.

           LOOP AT it_kontrupos
             WHERE kontrart = wa_kontrpos-kontrart
             AND   kontrnr  = wa_kontrpos-kontrnr
             AND   posnr    = wa_kontrpos-posnr.

             DELETE it_kontrupos INDEX sy-tabix.
           ENDLOOP.


         WHEN 'TC_KONTRUPOS'.
           CLEAR wa_kontrupos.

           wa_kontrupos = <wa>.

           DELETE <table> INDEX w_tabix.
       ENDCASE.


       IF sy-subrc = 0.
         <tc>-lines = <tc>-lines - 1.
       ENDIF.

     ELSEIF <mark_field> = 'X' AND
        <del_able> NE 'X'.

       CASE p_tc_name.
         WHEN 'TC_KONTRPOS'.

           CLEAR wa_kontrpos.

           wa_kontrpos = <wa>.

           IF wa_kontrpos-loesch NE 'X'.

             CLEAR: w_title, w_answer.

             CONCATENATE text-a04 text-a13 INTO
               w_title SEPARATED BY space.

             CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
                  EXPORTING
                       titel          = w_title
                       textline1      = text-e35
                       textline2      = text-e36
                       cancel_display = ''
                  IMPORTING
                       answer         = w_answer.
             CHECK w_answer = 'J'.

             wa_kontrpos-loesch = 'X'.
             wa_kontrpos-action = 'D'.

             MODIFY <table> INDEX w_tabix FROM wa_kontrpos.

             LOOP AT it_kontrupos_gesamt
               WHERE kontrart = wa_kontrpos-kontrart
               AND   kontrnr  = wa_kontrpos-kontrnr
               AND   posnr    = wa_kontrpos-posnr.

               it_kontrupos_gesamt-loesch = 'X'.
               it_kontrupos_gesamt-action = 'D'.

               MODIFY it_kontrupos_gesamt INDEX sy-tabix.
             ENDLOOP.

             LOOP AT it_kontrupos
               WHERE kontrart = wa_kontrpos-kontrart
               AND   kontrnr  = wa_kontrpos-kontrnr
               AND   posnr    = wa_kontrpos-posnr.

               it_kontrupos-loesch = 'X'.
               it_kontrupos-action = 'D'.

               MODIFY it_kontrupos INDEX sy-tabix.
             ENDLOOP.


             MESSAGE s000(zsd_04) WITH text-e26.

           ELSE.
             MESSAGE s000(zsd_04) WITH text-e29.
           ENDIF.

         WHEN 'TC_KONTRUPOS'.
           CLEAR wa_kontrupos.

           wa_kontrupos = <wa>.

           IF wa_kontrupos-loesch NE 'X'.

             CLEAR: w_title, w_answer.

             CONCATENATE text-a04 text-a13 INTO
               w_title SEPARATED BY space.

             CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
                  EXPORTING
                       titel          = w_title
                       textline1      = text-e37
                       textline2      = ''
                       cancel_display = ''
                  IMPORTING
                       answer         = w_answer.
             CHECK w_answer = 'J'.

             wa_kontrupos-loesch = 'X'.
             wa_kontrupos-action = 'D'.

             MODIFY <table> INDEX w_tabix FROM wa_kontrupos.

*             LOOP AT it_kontrupos_gesamt
*                 WHERE kontrart = wa_kontrupos-kontrart
*                 AND   kontrnr  = wa_kontrupos-kontrnr
*                 AND   posnr    = wa_kontrupos-posnr
*                 AND   uposnr   = wa_kontrupos-uposnr.
*
*               it_kontrupos_gesamt-loesch = 'X'.
*               it_kontrupos_gesamt-action = 'D'.
*
*               MODIFY it_kontrupos_gesamt INDEX sy-tabix.
*             ENDLOOP.

             MESSAGE s000(zsd_04) WITH text-e26.

           ELSE.
             MESSAGE s000(zsd_04) WITH text-e29.
           ENDIF.

       ENDCASE.

*       MESSAGE e000(zsd_04) WITH 'Diese Position kann nicht'
*                                 'mehr gelöscht werden!'.

     ENDIF.
   ENDLOOP.

 ENDFORM.                              " FCODE_DELETE_ROW
*
*&---------------------------------------------------------------------*
*&      Form  fcode_update_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TC_NAME  text
*      -->P_TABLE_NAME  text
*----------------------------------------------------------------------*
 FORM fcode_update_table USING    p_tc_name.

   CASE p_tc_name.
*
     WHEN 'TC_KONTRUPOS'.

       LOOP AT it_kontrupos WHERE action IS initial.
         it_kontrupos-action = 'U'.
         MODIFY it_kontrupos.
       ENDLOOP.

       s_btnkupupd = 'X'.
*
   ENDCASE.

 ENDFORM.                    " fcode_update_table
*
*&---------------------------------------------------------------------*
*&      Form  COMPUTE_SCROLLING_IN_TC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*      -->P_OK       ok code
*----------------------------------------------------------------------*
 FORM compute_scrolling_in_tc USING    p_tc_name
                                       p_ok.
*-BEGIN OF LOCAL DATA--------------------------------------------------*
   DATA l_tc_new_top_line     TYPE i.
   DATA l_tc_name             LIKE feld-name.
   DATA l_tc_lines_name       LIKE feld-name.
   DATA l_tc_field_name       LIKE feld-name.

   FIELD-SYMBOLS <tc>         TYPE cxtab_control.
   FIELD-SYMBOLS <lines>      TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

   ASSIGN (p_tc_name) TO <tc>.
* get looplines of TableControl
   CONCATENATE 'G_' p_tc_name '_LINES' INTO l_tc_lines_name.
   ASSIGN (l_tc_lines_name) TO <lines>.


* is no line filled?                                                   *
   IF <tc>-lines = 0.
*   yes, ...                                                           *
     l_tc_new_top_line = 1.
   ELSE.
*   no, ...                                                            *
     CALL FUNCTION 'SCROLLING_IN_TABLE'
          EXPORTING
               entry_act             = <tc>-top_line
               entry_from            = 1
               entry_to              = <tc>-lines
               last_page_full        = 'X'
               loops                 = <lines>
               ok_code               = p_ok
               overlapping           = 'X'
          IMPORTING
               entry_new             = l_tc_new_top_line
          EXCEPTIONS
*              NO_ENTRY_OR_PAGE_ACT  = 01
*              NO_ENTRY_TO           = 02
*              NO_OK_CODE_OR_PAGE_GO = 03
               OTHERS                = 0.
   ENDIF.

* get actual tc and column                                             *
   GET CURSOR FIELD l_tc_field_name
              AREA  l_tc_name.

   IF syst-subrc = 0.
     IF l_tc_name = p_tc_name.
*     set actual column                                                *
       SET CURSOR FIELD l_tc_field_name LINE 1.
     ENDIF.
   ENDIF.

* set the new top line                                                 *
   <tc>-top_line = l_tc_new_top_line.


 ENDFORM.                              " COMPUTE_SCROLLING_IN_TC
*
*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_MARK_LINES
*&---------------------------------------------------------------------*
*       marks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
 FORM fcode_tc_mark_lines USING p_tc_name
                                p_table_name
                                p_mark_name.
*-BEGIN OF LOCAL DATA--------------------------------------------------*
   DATA l_table_name       LIKE feld-name.

   FIELD-SYMBOLS <tc>         TYPE cxtab_control.
   FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
   FIELD-SYMBOLS <wa>.
   FIELD-SYMBOLS <mark_field>.
*-END OF LOCAL DATA----------------------------------------------------*

   ASSIGN (p_tc_name) TO <tc>.

* get the table, which belongs to the tc                               *
   CONCATENATE p_table_name '[]' INTO l_table_name. "table body
   ASSIGN (l_table_name) TO <table>.                "not headerline

* mark all filled lines                                                *
   LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
     ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

     <mark_field> = 'X'.
   ENDLOOP.
 ENDFORM.                                          "fcode_tc_mark_lines
*
*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_DEMARK_LINES
*&---------------------------------------------------------------------*
*       demarks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
 FORM fcode_tc_demark_lines USING p_tc_name
                                  p_table_name
                                  p_mark_name .
*-BEGIN OF LOCAL DATA--------------------------------------------------*
   DATA l_table_name       LIKE feld-name.

   FIELD-SYMBOLS <tc>         TYPE cxtab_control.
   FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
   FIELD-SYMBOLS <wa>.
   FIELD-SYMBOLS <mark_field>.
*-END OF LOCAL DATA----------------------------------------------------*

   ASSIGN (p_tc_name) TO <tc>.

* get the table, which belongs to the tc                               *
   CONCATENATE p_table_name '[]' INTO l_table_name. "table body
   ASSIGN (l_table_name) TO <table>.                "not headerline

* demark all filled lines                                              *
   LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
     ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

     <mark_field> = space.
   ENDLOOP.
 ENDFORM.                                          "fcode_tc_mark_lines
*
*&---------------------------------------------------------------------*
*&      Form  kontrakt_vorhanden
*&---------------------------------------------------------------------*
*       Prüfen ob Kontrakt vorhanden ist
*----------------------------------------------------------------------*
 FORM kontrakt_vorhanden.

   SELECT SINGLE * FROM  zsd_05_kontrakt
          WHERE  kontrart   = zsd_05_kontrakt-kontrart
          AND    kontrnr    = zsd_05_kontrakt-kontrnr.

   w_subrc = sy-subrc.

   IF sy-subrc = 0.

     IF NOT zsd_05_kontrakt-kontrnehmernr IS INITIAL.
       CASE zsd_05_kontrakt-code_kontrnehmer.
         WHEN 'K'.
           PERFORM read_kundenadr USING zsd_05_kontrakt-kontrnehmernr.
         WHEN 'L'.
           PERFORM read_lieferadr USING zsd_05_kontrakt-kontrnehmernr.
       ENDCASE.
     ELSEIF NOT zsd_05_kontrakt-adrnr IS INITIAL.
       PERFORM read_adrc USING zsd_05_kontrakt-adrnr.
     ENDIF.

     CASE zsd_05_kontrakt-code_kontrnehmer.
       WHEN 'K'.
         w_kontrnehmart = 'Kunde'.
       WHEN 'L'.
         w_kontrnehmart = 'Lieferant'.
     ENDCASE.


   ENDIF.

 ENDFORM.                    " kontrakt_vorhanden
*
*&---------------------------------------------------------------------*
*&      Form  kontrakt_anle
*&---------------------------------------------------------------------*
*       Kontrakt anlegen
*----------------------------------------------------------------------*
*      -->F_MELDUNG  Meldung ausgeben?
*----------------------------------------------------------------------*

 FORM kontrakt_anle USING f_meldung TYPE char1.

   IF NOT f_meldung IS INITIAL.
* Wenn nein, dann ev. anlegen
     CONCATENATE zsd_05_kontrakt-kontrart
                 zsd_05_kontrakt-kontrnr
                 INTO w_kontrakt.
     CONCATENATE text-e01 w_kontrakt text-e02
                 INTO w_textline1 SEPARATED BY space.
     CONCATENATE text-a01 text-a10
                 INTO w_textline2 SEPARATED BY space.
     CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
          EXPORTING
               titel     = text-a00
               textline1 = w_textline1
               textline2 = w_textline2
          IMPORTING
               answer    = w_answer.
     CHECK w_answer = 'J'.

   ENDIF.
* Anlegen OK
***   CLEAR w_kontrnr.
***
***   SELECT MAX( kontrnr ) FROM zsd_05_kontrakt
***     INTO w_kontrnr
***     WHERE kontrart = zsd_05_kontrakt-kontrart.
***
***   zsd_05_kontrakt-kontrnr = w_kontrnr + 1.

   CLEAR: w_kontrnr, wa_kontridx.

   SELECT * FROM zsd_05_kontridx UP TO 1 ROWS
       INTO  wa_kontridx
       WHERE kontrart   = zsd_05_kontrakt-kontrart
       AND   reserviert = space
       ORDER BY PRIMARY KEY.
   ENDSELECT.

   w_kontrnr = wa_kontridx-kontrnr.
   zsd_05_kontrakt-kontrnr = wa_kontridx-kontrnr.

   wa_kontridx-reserviert = 'X'.

   MODIFY zsd_05_kontridx FROM wa_kontridx.


   s_anle = 'X'.
   CLEAR: s_aend,
          s_anze.

 ENDFORM.                    " kontrakt_anle
*
*&---------------------------------------------------------------------*
*&      Form  kontrakt_aend
*&---------------------------------------------------------------------*
*       Kontrakt ändern
*----------------------------------------------------------------------*
*      -->F_MELDUNG  Meldung ausgeben?
*----------------------------------------------------------------------*
 FORM kontrakt_aend USING f_meldung TYPE char1.

   IF NOT f_meldung IS INITIAL.
     CONCATENATE zsd_05_kontrakt-kontrart
                 zsd_05_kontrakt-kontrnr
                 INTO w_kontrakt.
     CONCATENATE text-e01 w_kontrakt text-e04
                 INTO w_textline1 SEPARATED BY space.
     CONCATENATE text-a01 text-a11
                 INTO w_textline2 SEPARATED BY space.
     CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
          EXPORTING
               titel     = text-a00
               textline1 = w_textline1
               textline2 = w_textline2
          IMPORTING
               answer    = w_answer.
     CHECK w_answer = 'J'.
   ENDIF.
* Änderung OK
   s_aend = 'X'.
   CLEAR: s_anle,
          s_anze.

 ENDFORM.                    " kontrakt_aend
*
*&---------------------------------------------------------------------*
*&      Form  kontrakt_dele
*&---------------------------------------------------------------------*
*       Kontrakt löschen
*----------------------------------------------------------------------*
 FORM kontrakt_dele.

   CONCATENATE text-a01 text-a13
              INTO w_textline1 SEPARATED BY space.

   CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
        EXPORTING
             titel          = text-a00
             textline1      = w_textline1
             defaultoption  = 'N'
             cancel_display = ' '
        IMPORTING
             answer         = w_answer.


   CHECK w_answer = 'J'.


* Löschen OK
   s_aend = 'X'.
   CLEAR: s_anle,
          s_anze.


   IF NOT zsd_05_kontrakt-kontrart IS INITIAL
   AND NOT zsd_05_kontrakt-kontrnr IS INITIAL.

*    Kontrakt vorhanden?
     SELECT * FROM  zsd_05_kontrakt
            WHERE  kontrart  = zsd_05_kontrakt-kontrart
            AND    kontrnr   = zsd_05_kontrakt-kontrnr.
     ENDSELECT.
*    Kontrakt löschen
     DELETE FROM zsd_05_kontrakt
            WHERE kontrart  = zsd_05_kontrakt-kontrart
            AND   kontrnr   = zsd_05_kontrakt-kontrnr.
     IF sy-subrc NE 0.
       MESSAGE e000(zsd_04) WITH text-e01 text-e03.
     ELSE.


*      Zuordnungen vorhanden?
       SELECT * FROM zsd_05_kontrzord
              WHERE kontrart = zsd_05_kontrakt-kontrart
              AND   kontrnr  = zsd_05_kontrakt-kontrnr.
       ENDSELECT.
*      Zuordnungen löschen
       DELETE FROM zsd_05_kontrzord
              WHERE kontrart = zsd_05_kontrzord-kontrart
              AND   kontrnr  = zsd_05_kontrzord-kontrnr.


*      Zugeordnete vorhanden?
       SELECT * FROM zsd_05_kontrzord
              WHERE zuordart = zsd_05_kontrakt-kontrart
              AND   zuordknr = zsd_05_kontrakt-kontrnr.
       ENDSELECT.
*      Zugeordnete löschen
       DELETE FROM zsd_05_kontrzord
              WHERE zuordart = zsd_05_kontrzord-kontrart
              AND   zuordknr = zsd_05_kontrzord-kontrnr.


*      Positionen vorhanden?
       SELECT * FROM zsd_05_kontrpos
              WHERE kontrart = zsd_05_kontrakt-kontrart
              AND   kontrnr  = zsd_05_kontrakt-kontrnr.
       ENDSELECT.
*      Positionen löschen
       DELETE FROM zsd_05_kontrpos
              WHERE kontrart = zsd_05_kontrpos-kontrart
              AND   kontrnr  = zsd_05_kontrpos-kontrnr.


*      Unterpositionen vorhanden?
       SELECT * FROM zsd_05_kontrupos
              WHERE kontrart = zsd_05_kontrakt-kontrart
              AND   kontrnr  = zsd_05_kontrakt-kontrnr.
       ENDSELECT.
*      Unterpositionen löschen
       DELETE FROM zsd_05_kontrupos
              WHERE kontrart = zsd_05_kontrupos-kontrart
              AND   kontrnr  = zsd_05_kontrupos-kontrnr.


*      Kontraktnotiz löschen
       CONCATENATE zsd_05_kontrakt-kontrart zsd_05_kontrakt-kontrnr
         INTO w_header-tdname.


       CALL FUNCTION 'READ_TEXT'
            EXPORTING
                 client    = sy-mandt
                 id        = w_tdid
                 language  = sy-langu
                 name      = w_header-tdname
                 object    = w_tdobject
*            IMPORTING
*                 header    = w_header_e
            TABLES
                 lines     = it_lines
            EXCEPTIONS
                 not_found = 4.


       IF sy-subrc = 0.
         CALL FUNCTION 'DELETE_TEXT'
              EXPORTING
                   client          = sy-mandt
                   id              = w_tdid
                   language        = sy-langu
                   name            = w_header-tdname
                   object          = w_tdobject
                   savemode_direct = 'X'.
         IF sy-subrc <> 0.
         ENDIF.

         CALL FUNCTION 'FREE_TEXT_MEMORY'
              EXCEPTIONS
                   not_found = 1
                   OTHERS    = 2.
         IF sy-subrc <> 0.
         ENDIF.

         CLEAR w_textinfo.
       ENDIF.


*      Initialisierungen
       MESSAGE s000(zsd_04) WITH text-e01 text-e05.
       CLEAR: s_aend,
              s_anle,
              s_anze,
              s_delete,
              zsd_05_kontrakt,
              zsd_05_kontrzord,
              zsd_05_kontrpos,
              zsd_05_kontrupos.
     ENDIF.
   ELSE.
     MESSAGE w000(zsd_04) WITH text-e01 text-e06.
   ENDIF.

 ENDFORM.                    " kontrakt_dele
*
*&---------------------------------------------------------------------*
*&      Form  fcode_detail_row
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_TC_NAME  text
*      -->P_P_TABLE_NAME  text
*      -->P_P_MARK_NAME  text
*----------------------------------------------------------------------*
 FORM fcode_detail_row USING    p_tc_name
                                p_table_name
                                p_mark_name.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
   DATA l_table_name          LIKE feld-name.

   FIELD-SYMBOLS <tc>         TYPE cxtab_control.
   FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
   FIELD-SYMBOLS <wa>.
   FIELD-SYMBOLS <mark_field>.
*-END OF LOCAL DATA----------------------------------------------------*

   ASSIGN (p_tc_name) TO <tc>.

* get the table, which belongs to the tc                               *
   CONCATENATE p_table_name '[]' INTO l_table_name. "table body
   ASSIGN (l_table_name) TO <table>.                "not headerline

* delete marked lines                                                  *
   DESCRIBE TABLE <table> LINES <tc>-lines.

   LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
     ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

     IF <mark_field> = 'X'.
       CASE p_tc_name.
         WHEN 'TC_KONTRPOS'.
           CLEAR wa_kontrpos.
           MOVE <wa> TO wa_kontrpos.
           CLEAR zsd_05_kontrpos.
           MOVE-CORRESPONDING wa_kontrpos TO zsd_05_kontrpos.

           g_ts_kontrpos-pressed_tab = c_ts_kontrpos-tab1.
           CALL SCREEN 4000.
       ENDCASE.
     ENDIF.
   ENDLOOP.

 ENDFORM.                    " fcode_detail_row
*
*&---------------------------------------------------------------------*
*&      Form  addr_dialog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->f_kontrnehmernr  text
*      -->f_adrnr  text
*----------------------------------------------------------------------*
 FORM addr_dialog USING    f_kontrnehmernr
                           f_adrnr.

   IF f_kontrnehmernr IS INITIAL.
     CLEAR:   it_addr1_dia,
              it_addr1_data,
              ok_code.
     REFRESH: it_addr1_dia,
              it_addr1_data.
     MOVE 'BP  ' TO it_addr1_dia-addr_group.
     IF f_adrnr IS INITIAL.
       MOVE: zsd_05_kontrakt-kontrart TO it_addr1_dia-handle+0(1),
             zsd_05_kontrakt-kontrnr  TO it_addr1_dia-handle+1(10),
             'CREATE' TO it_addr1_dia-maint_mode,
             'CH'     TO it_addr1_dia-country.
     ELSE.
       MOVE f_adrnr  TO it_addr1_dia-addrnumber.
       CASE 'X'.
         WHEN s_anle.
           MOVE 'CHANGE'  TO it_addr1_dia-maint_mode.
         WHEN s_aend.
           MOVE 'CHANGE'  TO it_addr1_dia-maint_mode.
         WHEN s_anze.
           MOVE 'DISPLAY' TO it_addr1_dia-maint_mode.
       ENDCASE.
     ENDIF.

     APPEND it_addr1_dia.
     APPEND it_addr1_data.


     CALL FUNCTION 'ADDR_DIALOG'
          EXPORTING
               check_address             = 'X'
               suppress_taxjurcode_check = ' '
          IMPORTING
               ok_code                   = ok_code
          TABLES
               number_handle_tab         = it_addr1_dia
               values                    = it_addr1_data
          EXCEPTIONS
               address_not_exist         = 1
               group_not_valid           = 2
               parameter_error           = 3
               internal_error            = 4
               OTHERS                    = 5.
     IF sy-subrc <> 0.
       MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
     ENDIF.
     IF ok_code = 'CONT'.
       DATA l_addr_ref TYPE addr_ref.
       DATA l_addrnumber TYPE adrc-addrnumber.
       MOVE: 'ZSD_05'                 TO l_addr_ref-appl_table,
             'PARTNER'                TO l_addr_ref-appl_field,
             sy-mandt                 TO l_addr_ref-appl_key+0(3),
             zsd_05_kontrakt-kontrart TO l_addr_ref-appl_key+3(1),
             zsd_05_kontrakt-kontrnr  TO l_addr_ref-appl_key+4(10),
             'BP'                     TO l_addr_ref-addr_group.
       IF NOT it_addr1_dia-handle IS INITIAL.
         CALL FUNCTION 'ADDR_NUMBER_GET'
              EXPORTING
                   address_handle           = it_addr1_dia-handle
                   address_reference        = l_addr_ref
                   personal_address         = ' '
                   numberrange_number       = '01'
                   owner                    = 'X'
              IMPORTING
                   address_number           = l_addrnumber
              EXCEPTIONS
                   address_handle_not_exist = 1
                   internal_error           = 2
                   parameter_error          = 3
                   OTHERS                   = 4.
         IF sy-subrc <> 0.
           MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
         ENDIF.
       ELSE.
         MOVE f_adrnr TO l_addrnumber.
       ENDIF.
       CALL FUNCTION 'ADDR_MEMORY_SAVE'
            EXPORTING
                 execute_in_update_task = ' '
            EXCEPTIONS
                 address_number_missing = 1
                 person_number_missing  = 2
                 internal_error         = 3
                 database_error         = 4
                 reference_missing      = 5
                 OTHERS                 = 6.
       IF sy-subrc <> 0.
         MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
       ENDIF.
       CALL FUNCTION 'ADDR_MEMORY_CLEAR'
            EXPORTING
                 force              = ' '
            EXCEPTIONS
                 unsaved_data_exist = 1
                 internal_error     = 2
                 OTHERS             = 3.
       IF sy-subrc <> 0.
         MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
       ENDIF.
       MOVE l_addrnumber TO f_adrnr.
       MOVE l_addrnumber TO zsd_05_kontrakt-adrnr.
     ENDIF.

   ELSE.

     IF zsd_05_kontrakt-code_kontrnehmer = 'K' OR
        rb_kk1 = 'X'.
       SET PARAMETER ID 'KUN' FIELD f_kontrnehmernr.
       SELECT SINGLE * FROM tvko
         WHERE vkorg = w_vkorg.
       SET PARAMETER ID 'BUK' FIELD tvko-bukrs.
       CASE 'X'.
         WHEN s_aend OR s_anle.
           CALL TRANSACTION 'VD02' AND SKIP FIRST SCREEN.
         WHEN s_anze.
           CALL TRANSACTION 'VD03' AND SKIP FIRST SCREEN.
           PERFORM read_kundenadr USING f_kontrnehmernr.
       ENDCASE.
     ELSEIF zsd_05_kontrakt-code_kontrnehmer = 'L' OR
       rb_lk1 = 'X'.
       SET PARAMETER ID 'LIF' FIELD f_kontrnehmernr.
       SELECT SINGLE * FROM tvko
         WHERE vkorg = w_vkorg.
       SET PARAMETER ID 'BUK' FIELD tvko-bukrs.
       CASE 'X'.
         WHEN s_aend OR s_anle.
           CALL TRANSACTION 'XK02' AND SKIP FIRST SCREEN.
         WHEN s_anze.
           CALL TRANSACTION 'XK03' AND SKIP FIRST SCREEN.
           PERFORM read_lieferadr USING f_kontrnehmernr.
       ENDCASE.
     ENDIF.
   ENDIF.

   COMMIT WORK.

   PERFORM chkread_adr.

 ENDFORM.                    " addr_dialog
*
*&---------------------------------------------------------------------*
*&      Form  read_kundenadr
*&---------------------------------------------------------------------*
*       Liest die Kundenadresse aus
*----------------------------------------------------------------------*
*      -->P_ZSD_05_KONTRAKT_KONTRNEHMERNR  text
*----------------------------------------------------------------------*
 FORM read_kundenadr USING f_kontrnehmernr.

   CLEAR wa_kna1.

   SELECT SINGLE * FROM kna1 INTO wa_kna1
     WHERE kunnr = f_kontrnehmernr.

   PERFORM read_adrc USING wa_kna1-adrnr.

 ENDFORM.                    " read_kundenadr
*
*&---------------------------------------------------------------------*
*&      Form  read_lieferadr
*&---------------------------------------------------------------------*
*       Liest die Lieferadresse aus
*----------------------------------------------------------------------*
*      -->P_ZSD_05_KONTRAKT_KONTRNEHMERNR  text
*----------------------------------------------------------------------*
 FORM read_lieferadr USING f_kontrnehmernr.

   CLEAR wa_lfa1.

   SELECT SINGLE * FROM lfa1 INTO wa_lfa1
     WHERE lifnr = zsd_05_kontrakt-kontrnehmernr.

   PERFORM read_adrc USING wa_lfa1-adrnr.

 ENDFORM.                    " read_lieferadr
*
*&---------------------------------------------------------------------*
*&      Form  read_adrcadr
*&---------------------------------------------------------------------*
*       Liest Adresse aus der ADRC aus
*----------------------------------------------------------------------*
*      -->P_ZSD_05_KONTRAKT_ADRNR  text
*----------------------------------------------------------------------*
 FORM read_adrc USING f_adrnr.

   CLEAR wa_adrc.

   SELECT SINGLE * FROM adrc INTO wa_adrc
     WHERE addrnumber = f_adrnr.

   wa_kontrnehm-name1 = wa_adrc-name1.
   wa_kontrnehm-name2 = wa_adrc-name2.
   CONCATENATE wa_adrc-street wa_adrc-house_num1
     INTO wa_kontrnehm-stras SEPARATED BY space.
   wa_kontrnehm-land1 = wa_adrc-country.
   wa_kontrnehm-pstlz = wa_adrc-post_code1.
   wa_kontrnehm-ort01 = wa_adrc-city1.

 ENDFORM.                    " read_adrc
*
*&---------------------------------------------------------------------*
*&      Form  chkread_adr
*&---------------------------------------------------------------------*
*       Liest die entsprechende Adresse mit Prüfung
*----------------------------------------------------------------------*
 FORM chkread_adr.


   CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
             input  = zsd_05_kontrakt-kontrnehmernr
        IMPORTING
             output = zsd_05_kontrakt-kontrnehmernr.


   IF NOT zsd_05_kontrakt-kontrnehmernr IS INITIAL.
     CASE zsd_05_kontrakt-code_kontrnehmer.
       WHEN 'K'.
         PERFORM read_kundenadr USING zsd_05_kontrakt-kontrnehmernr.
       WHEN 'L'.
         PERFORM read_lieferadr USING zsd_05_kontrakt-kontrnehmernr.
     ENDCASE.
   ELSEIF NOT zsd_05_kontrakt-adrnr IS INITIAL.
     PERFORM read_adrc USING zsd_05_kontrakt-adrnr.
   ENDIF.

 ENDFORM.                    " chkread_adr
*
*&---------------------------------------------------------------------*
*&      Form  notiz_bearb
*&---------------------------------------------------------------------*
*       Bearbeitungsvorgänge Kontraktnotiz
*----------------------------------------------------------------------*
*      -->f_ncode f_ntyp
*----------------------------------------------------------------------*
 FORM notiz_bearb USING f_ncode f_ntyp f_proc.

   CLEAR: w_header,
          w_header_e,
          w_textinfo,
          w_textinfok,
          w_textinfop,
          w_lcount,
          wa_lines,
          w_textline1,
          w_textline2,
          w_answer,
          w_tdlsizechk,
          w_tdobject,
          w_header-tdname.

   CLEAR it_lines. REFRESH it_lines.



   CASE f_ntyp.
     WHEN 'K'.                               "Kopfnotiz
       MOVE 'VBBK' TO w_tdobject.

       CONCATENATE zsd_05_kontrakt-kontrart
                   zsd_05_kontrakt-kontrnr
         INTO w_header-tdname.
     WHEN 'P'.                               "Postionsnotiz
       MOVE 'VBBP' TO w_tdobject.

       CONCATENATE zsd_05_kontrakt-kontrart
                   zsd_05_kontrakt-kontrnr
                   zsd_05_kontrpos-posnr
         INTO w_header-tdname.
   ENDCASE.



   MOVE: w_tdobject   TO w_header-tdobject,
         w_tdid       TO w_header-tdid,
         sy-langu     TO w_header-tdspras,
         w_tdlinesize TO w_header-tdlinesize.



   CASE f_ncode.
*
     WHEN 'C' OR 'U'.

       CALL FUNCTION 'TEXT_EDIT'
            EXPORTING
                 i_header     = w_header
                 i_schab      = w_schab
                 i_schab_tdid = w_tdid
            IMPORTING
                 e_function   = w_function
                 e_header     = w_header_e
            TABLES
                 t_lines      = it_lines.

       DESCRIBE TABLE it_lines LINES w_lcount.

*      Prüfung, ob mehr als eine Zeile in der Tabelle ist.
       IF w_lcount GT 1.
         READ TABLE it_lines INTO wa_lines INDEX 1.
         CONCATENATE wa_lines-tdline(67) '...' INTO w_textinfo.
       ELSE.
         READ TABLE it_lines INTO wa_lines INDEX 1.

         MOVE wa_lines-tdline+70(10) TO w_tdlsizechk.

*        Prüfung, ob aktuelle Zeile länger als 70 Zeichen ist.
         IF NOT w_tdlsizechk IS INITIAL.
           CONCATENATE wa_lines-tdline(67) '...' INTO w_textinfo.
         ELSE.
           MOVE wa_lines-tdline(70) TO w_textinfo.
         ENDIF.
       ENDIF.




       CASE f_ntyp.
         WHEN 'K'.                               "Kopfnotiz
           MOVE w_textinfo TO w_textinfok.
           MOVE 'X' TO zsd_05_kontrakt-kontrnotiz.
*
         WHEN 'P'.                               "Postionsnotiz
           MOVE w_textinfo TO w_textinfop.
           MOVE 'X' TO zsd_05_kontrpos-kposnotiz.
       ENDCASE.




       CALL FUNCTION 'SAVE_TEXT'
            EXPORTING
                 client          = sy-mandt
                 header          = w_header_e
                 insert          = ' '
                 savemode_direct = 'X'
            TABLES
                 lines           = it_lines.

       IF sy-subrc <> 0.
       ENDIF.
*
     WHEN 'R'.
       CALL FUNCTION 'READ_TEXT'
            EXPORTING
                 client    = sy-mandt
                 id        = w_tdid
                 language  = sy-langu
                 name      = w_header-tdname
                 object    = w_tdobject
            IMPORTING
                 header    = w_header_e
            TABLES
                 lines     = it_lines
            EXCEPTIONS
                 not_found = 4.

       IF f_proc EQ 'PAI' AND
          sy-subrc NE 4.

         CALL FUNCTION 'EDIT_TEXT'
              EXPORTING
                   display = 'X'
                   header  = w_header
              TABLES
                   lines   = it_lines.
         IF sy-subrc <> 0.
         ENDIF.
       ENDIF.

       DESCRIBE TABLE it_lines LINES w_lcount.

*        Prüfung, ob mehr als eine Zeile in der Tabelle ist.
       IF w_lcount GT 1.
         READ TABLE it_lines INTO wa_lines INDEX 1.
         CONCATENATE wa_lines-tdline(67) '...' INTO w_textinfo.
       ELSEIF w_lcount EQ 1.
         READ TABLE it_lines INTO wa_lines INDEX 1.

         MOVE wa_lines-tdline+70(10) TO w_tdlsizechk.

*          Prüfung, ob aktuelle Zeile länger als 70 Zeichen ist.
         IF NOT w_tdlsizechk IS INITIAL.
           CONCATENATE wa_lines-tdline(67) '...' INTO w_textinfo.
         ELSE.
           MOVE wa_lines-tdline(70) TO w_textinfo.
         ENDIF.
       ENDIF.

       CASE f_ntyp.
         WHEN 'K'.                               "Kopfnotiz
           MOVE w_textinfo TO w_textinfok.
         WHEN 'P'.                               "Postionsnotiz
           MOVE w_textinfo TO w_textinfop.
       ENDCASE.


*
     WHEN 'D'.
       CONCATENATE text-a02 text-a13
                   INTO w_textline1 SEPARATED BY space.

       CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
            EXPORTING
                 titel          = text-a00
                 textline1      = w_textline1
                 defaultoption  = 'N'
                 cancel_display = ' '
            IMPORTING
                 answer         = w_answer.

       IF w_answer = 'J'.

         CALL FUNCTION 'DELETE_TEXT'
              EXPORTING
                   client          = sy-mandt
                   id              = w_tdid
                   language        = sy-langu
                   name            = w_header-tdname
                   object          = w_tdobject
                   savemode_direct = 'X'.
         IF sy-subrc <> 0.
         ENDIF.

         CALL FUNCTION 'FREE_TEXT_MEMORY'
              EXCEPTIONS
                   not_found = 1
                   OTHERS    = 2.
         IF sy-subrc <> 0.
         ENDIF.


         CASE f_ntyp.
           WHEN 'K'.                               "Kopfnotiz
             CLEAR w_textinfok.
             CLEAR zsd_05_kontrakt-kontrnotiz.
           WHEN 'P'.                               "Postionsnotiz
             CLEAR w_textinfop.
             CLEAR zsd_05_kontrpos-kposnotiz.
         ENDCASE.

       ENDIF.
*
   ENDCASE.
 ENDFORM.                    " knotiz_bearb
*
*&---------------------------------------------------------------------*
*&      Form  verr_grund_input
*&---------------------------------------------------------------------*
*       Steuerung Eingabe: Grund keine Verrechnung
*----------------------------------------------------------------------*
 FORM verr_grund_input.

   IF NOT zsd_05_kontrpos-verr_code IS INITIAL.
     LOOP AT SCREEN.
       IF screen-name = 'ZSD_05_KONTRPOS-VERR_GRUND'.
         screen-input    = 1.
         MODIFY SCREEN.
       ENDIF.
     ENDLOOP.
   ELSE.
     CLEAR zsd_05_kontrpos-verr_grund.
     LOOP AT SCREEN.
       IF screen-name = 'ZSD_05_KONTRPOS-VERR_GRUND'.
         screen-input    = 0.
         MODIFY SCREEN.
       ENDIF.
     ENDLOOP.
   ENDIF.

 ENDFORM.                    " verr_grund_input
*
*&---------------------------------------------------------------------*
*&      Form  AUTHORITY-CHECK
*&---------------------------------------------------------------------*
*       Berechtigungsprüfung
*----------------------------------------------------------------------*
*      -->F_OBJECT   Berechtigungsobjekt
*      -->F_ACTVT    Aktivität
*----------------------------------------------------------------------*
 FORM authority-check USING    f_object
                               f_actvt
                               f_obj.

   AUTHORITY-CHECK OBJECT f_object
            ID 'ACTVT' FIELD f_actvt.
   IF sy-subrc NE 0.

*    Schalter zurücksetzen, wenn keine Berechtigung
     PERFORM akt_restore.

     IF     f_actvt EQ 1.
       MESSAGE e001 WITH f_obj.
     ELSEIF f_actvt EQ 2.
       MESSAGE e002 WITH f_obj.
     ELSEIF f_actvt EQ 3.
       MESSAGE e003 WITH f_obj.
     ELSEIF f_actvt EQ 6.
       MESSAGE e006 WITH f_obj.
     ELSE.
       MESSAGE e000 WITH text-e07.
     ENDIF.

   ENDIF.

 ENDFORM.                    " AUTHORITY-CHECK
*
*&---------------------------------------------------------------------*
*&      Form  verrtyp_input
*&---------------------------------------------------------------------*
*       Steuerung Eingabe: Indexfelder
*----------------------------------------------------------------------*
 FORM verrtyp_input.

   IF zsd_05_kontrpos-verrtyp EQ 'T' OR
      zsd_05_kontrpos-verrtyp EQ ''  OR
      ( zsd_05_kontrpos-verrtyp EQ 'K' AND
        zsd_05_kontrpos-faktperiode EQ '0' ).
     LOOP AT SCREEN.
       IF     screen-name = 'ZSD_05_KONTRPOS-INDEX_KEY'.
         screen-input    = 0.
         screen-required = 0.
         CLEAR zsd_05_kontrpos-index_key.
       ELSEIF screen-name = 'ZSD_05_KONTRPOS-INDEX_BASIS'.
         screen-input    = 0.
         screen-required = 0.
         CLEAR zsd_05_kontrpos-index_basis.
       ELSEIF screen-name = 'ZSD_05_KONTRPOS-INDEX_GJAHR'.
         screen-input    = 0.
         screen-required = 0.
         CLEAR zsd_05_kontrpos-index_gjahr.
       ELSEIF screen-name = 'ZSD_05_KONTRPOS-INDEX_MONAT'.
         screen-input    = 0.
         screen-required = 0.
         CLEAR zsd_05_kontrpos-index_monat.
       ELSEIF screen-name = 'ZSD_05_KONTRPOS-INDEX_STAND'.
*         screen-input    = 0.
*         screen-required = 0.
         CLEAR zsd_05_kontrpos-index_stand.
       ELSEIF screen-name = 'ZSD_05_KONTRPOS-INDEX_DIFFSTAND'.
*         screen-input    = 0.
*         screen-required = 0.
         CLEAR zsd_05_kontrpos-index_diffstand.
       ELSEIF screen-name = 'ZSD_05_KONTRPOS-INDEX_DIFF'.
         screen-input    = 0.
         CLEAR zsd_05_kontrpos-index_diff.
       ELSEIF screen-name = 'ZSD_05_KONTRPOS-PREIS'.
         IF zsd_05_kontrpos-verrtyp NE 'K'.
           screen-input   = 0.
           screen-required = 0.
         ENDIF.
       ELSEIF screen-name = 'RB_PKT1'.
         screen-input    = 0.
       ELSEIF screen-name = 'RB_PRZ1'.
         screen-input    = 0.
       ENDIF.
       MODIFY SCREEN.
     ENDLOOP.
   ENDIF.

 ENDFORM.                    " verrtyp_input
*
*&---------------------------------------------------------------------*
*&      Form  set_authority
*&---------------------------------------------------------------------*
*       Setzen der Berechtigungen
*----------------------------------------------------------------------*
 FORM set_authority.

* Aktivität für Berechtigungsprüfung definieren
   CASE 'X'.
     WHEN s_anle. w_actvt = '01'. "Anlegen
     WHEN s_aend. w_actvt = '02'. "Ändern
     WHEN s_anze. w_actvt = '03'. "Anzeigen
   ENDCASE.
   PERFORM authority-check USING 'ZIDBOKOFBD' w_actvt text-a01.

 ENDFORM.                    " set_authority
*
*&---------------------------------------------------------------------*
*&      Form  set_authdele
*&---------------------------------------------------------------------*
*       Setzen der Berechtigungen fürs Löschen
*----------------------------------------------------------------------*
 FORM set_authdele USING f_delobj.

* Aktivität für Berechtigungsprüfung definieren
   CASE 'X'.
     WHEN s_dele. w_actdel = '06'. "Löschen
   ENDCASE.
   PERFORM authority-check USING 'ZIDBOKOFBD' w_actdel f_delobj.

 ENDFORM.                    " set_authdele
*
*&---------------------------------------------------------------------*
*&      Form  akt_backup
*&---------------------------------------------------------------------*
*       Aktivitäten  Anlegen / Ändern / Anezgein sichern
*----------------------------------------------------------------------*
 FORM akt_backup.

   w_anle = s_anle.
   w_aend = s_aend.
   w_anze = s_anze.
   w_dele = s_dele.

 ENDFORM.                    " akt_backup
*
*&---------------------------------------------------------------------*
*&      Form  akt_restore
*&---------------------------------------------------------------------*
*       Aktivitäten  Anlegen / Ändern / Anezgein wiederherstellen
*----------------------------------------------------------------------*
 FORM akt_restore.

   s_anle = w_anle.
   s_aend = w_aend.
   s_anze = w_anze.
   s_dele = w_dele.

 ENDFORM.                    " akt_restore
*
*&---------------------------------------------------------------------*
*&      Form  knummer_freigabe
*&---------------------------------------------------------------------*
*       Gibt die reservierte Kontraktnummer der Nummernkreise frei.
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
 FORM knummer_freigabe.

   IF s_anle = 'X' AND wa_kontridx-reserviert = 'X'.
     wa_kontridx-reserviert = space.
     MODIFY zsd_05_kontridx FROM wa_kontridx.
   ENDIF.

 ENDFORM.                    " knummer_freigabe
*
*&---------------------------------------------------------------------*
*&      Form  split_dateilink
*&---------------------------------------------------------------------*
*       Gibt auf dem Bildschirm nur den Dateinamen aus.
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
 FORM split_dateilink.

   IF NOT zsd_05_kontrakt-dateilink IS INITIAL.
     DATA: BEGIN OF it_link OCCURS 0,
           val TYPE char90,
         END OF it_link.

     SPLIT zsd_05_kontrakt-dateilink AT '\' INTO TABLE it_link.

     CLEAR w_lcount.
     DESCRIBE TABLE it_link LINES w_lcount.

     READ TABLE it_link INTO w_dateilink INDEX w_lcount.
   ENDIF.

 ENDFORM.                    " split_dateilink
*
