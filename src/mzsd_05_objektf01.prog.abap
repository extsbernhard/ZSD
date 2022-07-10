*----------------------------------------------------------------------*
***INCLUDE MZSD_05_PARZELLEF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  read_kna1
*&---------------------------------------------------------------------*
*       Kundenstamm lesen
*----------------------------------------------------------------------*
*      -->F_KUNNR  Kundennummer
*      -->F_KNA1   Kundenstammstruktur
*----------------------------------------------------------------------*
FORM read_kna1 USING    f_kunnr TYPE kna1-kunnr
                        f_kna1  TYPE kna1.

  CHECK NOT f_kunnr IS INITIAL.
  SELECT SINGLE * FROM  kna1
         INTO f_kna1
         WHERE  kunnr  = f_kunnr.

ENDFORM.                                                    " read_kna1
*
*&---------------------------------------------------------------------*
*&      Form  parzelle_vorhanden
*&---------------------------------------------------------------------*
*       Prüfen ob Parzelle vorhanden ist
*----------------------------------------------------------------------*
FORM parzelle_vorhanden.

  DATA: l_stadtteil LIKE zsd_05_objekt-stadtteil,
        l_parzelle  LIKE zsd_05_objekt-parzelle.
  MOVE zsd_05_objekt-stadtteil TO l_stadtteil.
  MOVE zsd_05_objekt-parzelle TO l_parzelle.
  CLEAR zsd_05_objekt.
  SELECT SINGLE * FROM  zsd_05_objekt
         WHERE  stadtteil   = l_stadtteil
         AND    parzelle    = l_parzelle
         AND    objekt      = '0000'.
  MOVE l_stadtteil TO zsd_05_objekt-stadtteil.
  MOVE l_parzelle TO zsd_05_objekt-parzelle.

ENDFORM.                    " parzelle_vorhanden
*
*&---------------------------------------------------------------------*
*&      Form  parzelle_aend
*&---------------------------------------------------------------------*
*       Parzelle ändern
*----------------------------------------------------------------------*
*      -->F_MELDUNG  Meldung ausgeben?
*----------------------------------------------------------------------*
FORM parzelle_aend USING    f_meldung TYPE char1.

  IF NOT f_meldung IS INITIAL.
    CONCATENATE zsd_05_objekt-stadtteil '/'
                zsd_05_objekt-parzelle
                INTO w_parzelle.
    CONCATENATE text-e01 w_parzelle text-e04
                INTO w_textline1 SEPARATED BY space.
    MOVE text-a02 TO w_textline2.
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

ENDFORM.                    " parzelle_aend
*
*&---------------------------------------------------------------------*
*&      Form  parzelle_anle
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->F_MELDUNG  Meldung ausgeben?
*----------------------------------------------------------------------*
FORM parzelle_anle USING    f_meldung TYPE char1.

  IF NOT f_meldung IS INITIAL.
* Wenn nein, dann ev. anlegen
    CONCATENATE zsd_05_objekt-stadtteil '/'
                zsd_05_objekt-parzelle
                INTO w_parzelle.
    CONCATENATE text-e01 w_parzelle text-e02
                INTO w_textline1 SEPARATED BY space.
    MOVE text-a01 TO w_textline2.
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
  s_anle = 'X'.
  CLEAR: s_aend,
         s_anze,
         w_kna1e.

ENDFORM.                    " parzelle_anle
*
*&---------------------------------------------------------------------*
*&      Form  parzelle_dele
*&---------------------------------------------------------------------*
*       Parzelle löschen
*----------------------------------------------------------------------*
FORM parzelle_dele.

* Löschen OK
  s_aend = 'X'.
  s_1000 = 'X'.
  CLEAR: s_anle,
         s_anze.
  IF NOT zsd_05_objekt-stadtteil IS INITIAL
  AND NOT zsd_05_objekt-parzelle IS INITIAL.
* Sind Objekte vorhanden?
    SELECT        * FROM  zsd_05_objekt
           WHERE  stadtteil  = zsd_05_objekt-stadtteil
           AND    parzelle   = zsd_05_objekt-parzelle
           AND    objekt    NE '0000'.

    ENDSELECT.

* Parzelle löschen
    DELETE FROM zsd_05_objekt
                WHERE stadtteil  = zsd_05_objekt-stadtteil
                AND   parzelle   = zsd_05_objekt-parzelle
                AND   objekt     = '0000'.
    IF sy-subrc NE 0.
      MESSAGE e000(zsd_04) WITH text-e01 text-e03.
    ELSE.
      MESSAGE s000(zsd_04) WITH text-e01 text-e05.
      CLEAR: s_aend,
             s_anle,
             s_anze,
             s_1000,
             s_delete,
             zsd_05_objekt.
    ENDIF.
  ELSE.
    MESSAGE w000(zsd_04) WITH text-e01 text-e06.
  ENDIF.

ENDFORM.                    " parzelle_dele
*
*&---------------------------------------------------------------------*
*&      Form  USER_OK_TC                                               *
*&---------------------------------------------------------------------*
FORM user_ok_tc USING    p_tc_name TYPE dynfnam
                         p_table_name
                         p_mark_name
                CHANGING p_ok      LIKE sy-ucomm.
  p_ok = sy-ucomm.
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
    WHEN 'INSR'.                      "insert row
      IF NOT s_anle IS INITIAL
      OR NOT s_aend IS INITIAL.
        PERFORM fcode_insert_row USING    p_tc_name
                                          p_table_name.
        CLEAR p_ok.
      ELSE.
        MESSAGE s000 WITH text-e09.
      ENDIF.
    WHEN 'DETA'.                     "Detailansicht
      PERFORM fcode_detail_row USING    p_tc_name
                                        p_table_name
                                        p_mark_name.
      CLEAR p_ok.

    WHEN 'DELE'.                      "delete row
      PERFORM fcode_delete_row USING    p_tc_name
                                        p_table_name
                                        p_mark_name.
      CLEAR p_ok.

    WHEN 'P--' OR                     "top of list
         'P-'  OR                     "previous page
         'P+'  OR                     "next page
         'P++'.                       "bottom of list
      PERFORM compute_scrolling_in_tc USING p_tc_name
                                            l_ok.
      CLEAR p_ok.
    WHEN 'MARK'.                      "mark all filled lines
      PERFORM fcode_tc_mark_lines USING p_tc_name
                                        p_table_name
                                        p_mark_name   .
      CLEAR p_ok.

    WHEN 'DMRK'.                      "demark all filled lines
      PERFORM fcode_tc_demark_lines USING p_tc_name
                                          p_table_name
                                          p_mark_name .
      CLEAR p_ok.

  ENDCASE.

ENDFORM.                              " USER_OK_TC
*
*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_insert_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name             .

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_lines_name       LIKE feld-name.
  DATA l_selline          LIKE sy-stepl.
  DATA l_lastline         TYPE i.
  DATA l_line             TYPE i.
  DATA l_table_name       LIKE feld-name.
  DATA l_work_area        LIKE feld-name.
  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <lines>              TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.                "not headerline

* get looplines of TableControl
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.
  ASSIGN (l_lines_name) TO <lines>.

* get the work-area, which belongs to the table                        *
  CONCATENATE p_table_name '_WA' INTO l_work_area.
  ASSIGN (l_work_area) TO <wa>.

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
    WHEN 'TC_OBJECT'.
* insert initial line
      CLEAR g_tc_object_wa.
      CLEAR: zsd_04_boden,
             zsd_04_regen,
             zsd_04_kanal,
             zsd_04_kehricht.
      MOVE: zsd_05_objekt-stadtteil TO g_tc_object_wa-stadtteil,
            zsd_05_objekt-parzelle  TO g_tc_object_wa-parzelle,
            zsd_05_objekt-objektbez TO g_tc_object_wa-objektbez,
            zsd_05_objekt-eigentuemer TO g_tc_object_wa-eigentuemer,
          zsd_05_objekt-addrnumber_eig TO g_tc_object_wa-addrnumber_eig,
*            zsd_05_objekt-verwalter to g_tc_object_wa-verwalter,
*         zsd_05_objekt-addrnumber_ver to g_tc_object_wa-addrnumber_ver,
            zsd_05_objekt-info1 TO g_tc_object_wa-info1,
            zsd_05_objekt-info2 TO g_tc_object_wa-info2,
            zsd_05_objekt-sgrart TO g_tc_object_wa-sgrart,
            zsd_05_objekt-brparzelle TO g_tc_object_wa-brparzelle,
            zsd_05_objekt-brdatum TO g_tc_object_wa-brdatum.
      LOOP AT t_object.
        MOVE t_object-objekt TO g_tc_object_wa-objekt.
      ENDLOOP.
      IF NOT g_tc_object_wa-objekt = 9999.
        ADD 1 TO g_tc_object_wa-objekt.
      ENDIF.
      MOVE-CORRESPONDING g_tc_object_wa TO t_object_wa.
      MOVE 'X' TO s_insr.
      CALL SCREEN 2000.
    WHEN 'TC_REGENINFO'.
* insert initial line
      CLEAR g_tc_regeninfo_wa.
      SORT g_tc_regeninfo_itab BY strasse hausnummer.
      INSERT g_tc_regeninfo_wa INTO <table> INDEX l_selline.

" mzi unicode      MOVE g_tc_regeninfo_wa TO zsd_04_regeninfo+12.
      MOVE-corresponding g_tc_regeninfo_wa TO zsd_04_regeninfo.

      CALL SCREEN 2100 STARTING AT 10 05 ENDING AT 120 30.
  ENDCASE.
  <tc>-lines = <tc>-lines + 1.
  SET CURSOR LINE l_line.

ENDFORM.                              " FCODE_INSERT_ROW
*
*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_delete_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name
                       p_mark_name   .

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

* delete marked lines                                                  *
  DESCRIBE TABLE <table> LINES <tc>-lines.

  LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    IF <mark_field> = 'X'.
      DELETE <table> INDEX syst-tabix.
      IF sy-subrc = 0.
        <tc>-lines = <tc>-lines - 1.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.                              " FCODE_DELETE_ROW
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
*       NO_ENTRY_OR_PAGE_ACT  = 01
*       NO_ENTRY_TO           = 02
*       NO_OK_CODE_OR_PAGE_GO = 03
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
*&      Form  fcode_detail_row
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_TC_NAME  text
*      -->P_P_TABLE_NAME  text
*----------------------------------------------------------------------*
FORM fcode_detail_row USING    p_tc_name     TYPE dynfnam
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

* delete marked lines                                                  *
  DESCRIBE TABLE <table> LINES <tc>-lines.

  LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    IF <mark_field> = 'X'.
      CASE p_tc_name.
        WHEN 'TC_OBJECT'.
          MOVE <wa> TO t_object_wa.
          MOVE: zsd_05_objekt-info1 TO t_object_wa-info1,
                zsd_05_objekt-info2 TO t_object_wa-info2.
          IF t_object_wa-objekt = '0000'.
            MOVE: "zsd_05_objekt-verwalter
                  "to t_object_wa-verwalter,
                  "zsd_05_objekt-addrnumber_ver
                  "to t_object_wa-addrnumber_ver,
                  zsd_05_objekt-eigentuemer
                  TO t_object_wa-eigentuemer,
                  zsd_05_objekt-addrnumber_eig
                  TO t_object_wa-addrnumber_eig.
          ENDIF.
          CALL SCREEN 2000.
        WHEN 'TC_REGENINFO'.

"mzi unicode          MOVE <wa> TO zsd_04_regeninfo+12.
          MOVE-CORRESPONDING <wa> TO zsd_04_regeninfo.

          CALL SCREEN 2100 STARTING AT 5 20.
      ENDCASE.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " fcode_detail_row
*
*&---------------------------------------------------------------------*
*&      Form  read_makt
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->F_MATNR    text
*      -->F_MATTEXT  text
*----------------------------------------------------------------------*
FORM read_makt USING    f_matnr
                        f_mattext.

  CLEAR makt.
  SELECT SINGLE * FROM  makt
         WHERE  matnr  = f_matnr
         AND    spras  = sy-langu.
  IF sy-subrc NE 0.
    MOVE text-e02 TO f_mattext.
  ELSE.
    MOVE makt-maktx TO f_mattext.
  ENDIF.

ENDFORM.                    " read_makt
*&---------------------------------------------------------------------*
*&      Form  addr_get
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->F_ADDR_NUMBER  text
*      -->F_KNA1E        text
*----------------------------------------------------------------------*
FORM addr_get USING    f_addr_number TYPE adrnr
                       f_kna1 TYPE kna1.

  CHECK: NOT f_addr_number IS INITIAL,
             f_kna1        IS INITIAL.
  DATA l_addr1_sel TYPE addr1_sel.
  DATA l_sadr TYPE sadr.
  MOVE f_addr_number TO l_addr1_sel-addrnumber.
  CALL FUNCTION 'ADDR_GET'
    EXPORTING
      address_selection = l_addr1_sel
      read_sadr_only    = ' '
      read_texts        = ' '
    IMPORTING
      sadr              = l_sadr
    EXCEPTIONS
      parameter_error   = 1
      address_not_exist = 2
      version_not_exist = 3
      internal_error    = 4
      OTHERS            = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  MOVE-CORRESPONDING l_sadr TO f_kna1.

ENDFORM.                    " addr_get
*&---------------------------------------------------------------------*
*&      Form  addr_dialog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->F_KUNNR  text
*----------------------------------------------------------------------*
FORM addr_dialog USING    f_kunnr       TYPE kunnr
                          f_addr_number TYPE adrnr.

  IF f_kunnr IS INITIAL.
    CLEAR: t_addr1_dia,
           t_addr1_data,
           w_ucomm.
    REFRESH: t_addr1_dia,
             t_addr1_data.
    MOVE 'BP  ' TO t_addr1_dia-addr_group.
    IF f_addr_number IS INITIAL.
      MOVE: zsd_05_objekt-stadtteil TO t_addr1_dia-handle+0(1),
            zsd_05_objekt-parzelle  TO t_addr1_dia-handle+1(4),
            zsd_05_objekt-objekt    TO t_addr1_dia-handle+5(4),
            'CREATE' TO t_addr1_dia-maint_mode,
            'CH'     TO t_addr1_dia-country.
    ELSE.
      MOVE: f_addr_number TO t_addr1_dia-addrnumber,
            'CHANGE'      TO t_addr1_dia-maint_mode.
    ENDIF.
    APPEND t_addr1_dia.
    APPEND t_addr1_data.
    CALL FUNCTION 'ADDR_DIALOG'
      EXPORTING
        check_address             = 'X'
        suppress_taxjurcode_check = ' '
      IMPORTING
        ok_code                   = w_ucomm
      TABLES
        number_handle_tab         = t_addr1_dia
        values                    = t_addr1_data
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
    IF w_ucomm = 'CONT'.
      DATA l_addr_ref TYPE addr_ref.
      DATA l_addrnumber TYPE adrc-addrnumber.
      MOVE: 'ZSD_05'                TO l_addr_ref-appl_table,
            'PARTNER'               TO l_addr_ref-appl_field,
            sy-mandt                TO l_addr_ref-appl_key+0(3),
            zsd_05_objekt-stadtteil TO l_addr_ref-appl_key+3(1),
            zsd_05_objekt-parzelle  TO l_addr_ref-appl_key+4(4),
            zsd_05_objekt-objekt    TO l_addr_ref-appl_key+8(4),
            'BP'                    TO l_addr_ref-addr_group.
      IF NOT t_addr1_dia-handle IS INITIAL.
        CALL FUNCTION 'ADDR_NUMBER_GET'
          EXPORTING
            address_handle           = t_addr1_dia-handle
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
        MOVE f_addr_number TO l_addrnumber.
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
      MOVE l_addrnumber TO f_addr_number.
    ENDIF.
  ELSE.
    SET PARAMETER ID 'KUN' FIELD f_kunnr.
    SELECT SINGLE * FROM  tvko
           WHERE  vkorg  = '2850'.
    SET PARAMETER ID 'BUK' FIELD tvko-bukrs.
    CALL TRANSACTION 'XD02' AND SKIP FIRST SCREEN.
  ENDIF.

ENDFORM.                    " addr_dialog
*&---------------------------------------------------------------------*
*&      Form  check_objekt
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_objekt.

* Objektnummer darf nicht bereits vergeben sein beim Hinzufügen
  IF NOT s_insr IS INITIAL.
    LOOP AT t_object WHERE stadtteil = t_object_wa-stadtteil
                     AND   parzelle  = t_object_wa-parzelle
                     AND   objekt    = t_object_wa-objekt.
*     MESSAGE e000 WITH text-e24.
    ENDLOOP.
    IF sy-subrc NE 0.
      APPEND t_object_wa TO t_object.
    ENDIF.
  ENDIF.
* Jedes Objekt muss eine andere Adresse haben
  LOOP AT t_object WHERE street     = t_object_wa-street
                   AND   house_num1 = t_object_wa-house_num1
                   AND   post_code1 = t_object_wa-post_code1
                   AND   city1      = t_object_wa-city1
                   AND   country    = t_object_wa-country
                   AND   building   = t_object_wa-building
                   AND   roomnumber = t_object_wa-roomnumber
                   AND   objekt    NE t_object_wa-objekt
                   AND   yabbruch   = space.
    MESSAGE e000 WITH text-e22
                      t_object-stadtteil
                      t_object-parzelle
                      t_object-objekt.
  ENDLOOP.

ENDFORM.                    " check_objekt
*&---------------------------------------------------------------------*
*&      Form  AUTHORITY-CHECK
*&---------------------------------------------------------------------*
*       Berechtigungsprüfung
*----------------------------------------------------------------------*
*      -->F_OBJECT   Berechtigungsobjekt
*      -->F_ACTVT    Aktivität
*----------------------------------------------------------------------*
FORM authority-check USING    f_object
                              f_actvt.

  AUTHORITY-CHECK OBJECT f_object
           ID 'ACTVT' FIELD f_actvt.

ENDFORM.                    " AUTHORITY-CHECK
*eject
*&---------------------------------------------------------------------*
*&      Form  verwend_status
*&---------------------------------------------------------------------*
*       In welchen Register wird das Objekt verwendet
*----------------------------------------------------------------------*
FORM verwend_status.

  LOOP AT t_object.
    CLEAR: t_object-bb,
           t_object-ka,
           t_object-ra,
           t_object-kg.
    CLEAR: zsd_04_boden,
           zsd_04_kanal,
           zsd_04_regen,
           zsd_04_kehricht.
    SELECT SINGLE * FROM  zsd_04_boden
           WHERE  stadtteil  = t_object-stadtteil
           AND    parzelle   = t_object-parzelle
           AND    objekt     = t_object-objekt.
    IF sy-subrc = 0.
      t_object-bb = 'X'.
    ENDIF.
    SELECT SINGLE * FROM  zsd_04_kanal
           WHERE  stadtteil  = t_object-stadtteil
           AND    parzelle   = t_object-parzelle
           AND    objekt     = t_object-objekt.
    IF sy-subrc = 0.
      t_object-ka = 'X'.
    ENDIF.
    SELECT SINGLE * FROM  zsd_04_regen
           WHERE  stadtteil  = t_object-stadtteil
           AND    parzelle   = t_object-parzelle
           AND    objekt     = t_object-objekt.
    IF sy-subrc = 0.
      t_object-ra = 'X'.
    ENDIF.
    SELECT SINGLE * FROM  zsd_04_kehricht
           WHERE  stadtteil  = t_object-stadtteil
           AND    parzelle   = t_object-parzelle
           AND    objekt     = t_object-objekt.
    IF sy-subrc = 0.
      w_zsd_04_kehricht = zsd_04_kehricht.
      t_object-kg = 'X'.
    ENDIF.
    MODIFY t_object INDEX sy-tabix.
  ENDLOOP.

ENDFORM.                    " verwend_status
*&---------------------------------------------------------------------*
*&      Form  betrag_rechnen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM betrag_rechnen.

  CLEAR: w_betrag1, w_betrag2, w_betrag3,
         w_betrag4, w_betrag5.
  DATA l_vakey LIKE konh-vakey.
  SELECT SINGLE * FROM  zsd_04_kehr_mat CLIENT SPECIFIED
         WHERE  mandt  = sy-mandt.
* Lesen Preis Material 1
  CONCATENATE zsd_04_kehricht-vkorg
              zsd_04_kehricht-vtweg
              zsd_04_kehr_mat-matnr_1
         INTO l_vakey.
  SELECT        * FROM  konh
         WHERE  kvewe    = 'A'
         AND    kotabnr  = '004'
         AND    kappl    = 'V'
         AND    kschl    = 'PR00'
         AND    vakey    = l_vakey
         AND    datab   LE sy-datum
         AND    datbi   GE sy-datum.
    SELECT        * FROM  konp
           WHERE  knumh  = konh-knumh
           AND    kappl  = konh-kappl
           AND    kschl  = konh-kschl.
      w_betrag1 = zsd_04_kehricht-vflaeche_fakt1
                * konp-kbetr / konp-kpein.
    ENDSELECT.
  ENDSELECT.
* Lesen Preis Material 2
  CONCATENATE zsd_04_kehricht-vkorg
              zsd_04_kehricht-vtweg
              zsd_04_kehr_mat-matnr_2
         INTO l_vakey.
  SELECT        * FROM  konh
         WHERE  kvewe    = 'A'
         AND    kotabnr  = '004'
         AND    kappl    = 'V'
         AND    kschl    = 'PR00'
         AND    vakey    = l_vakey
         AND    datab   LE sy-datum
         AND    datbi   GE sy-datum.
    SELECT        * FROM  konp
           WHERE  knumh  = konh-knumh
           AND    kappl  = konh-kappl
           AND    kschl  = konh-kschl.
      w_betrag2 = zsd_04_kehricht-vflaeche_fakt2
                * konp-kbetr / konp-kpein.
    ENDSELECT.
  ENDSELECT.
* Lesen Preis Material 3
  CONCATENATE zsd_04_kehricht-vkorg
              zsd_04_kehricht-vtweg
              zsd_04_kehr_mat-matnr_3
         INTO l_vakey.
  SELECT        * FROM  konh
         WHERE  kvewe    = 'A'
         AND    kotabnr  = '004'
         AND    kappl    = 'V'
         AND    kschl    = 'PR00'
         AND    vakey    = l_vakey
         AND    datab   LE sy-datum
         AND    datbi   GE sy-datum.
    SELECT        * FROM  konp
           WHERE  knumh  = konh-knumh
           AND    kappl  = konh-kappl
           AND    kschl  = konh-kschl.
      w_betrag3 = zsd_04_kehricht-vflaeche_fakt3
                * konp-kbetr / konp-kpein.
    ENDSELECT.
  ENDSELECT.
* Lesen Preis Material 4
  CONCATENATE zsd_04_kehricht-vkorg
              zsd_04_kehricht-vtweg
              zsd_04_kehr_mat-matnr_4
         INTO l_vakey.
  SELECT        * FROM  konh
         WHERE  kvewe    = 'A'
         AND    kotabnr  = '004'
         AND    kappl    = 'V'
         AND    kschl    = 'PR00'
         AND    vakey    = l_vakey
         AND    datab   LE sy-datum
         AND    datbi   GE sy-datum.
    SELECT        * FROM  konp
           WHERE  knumh  = konh-knumh
           AND    kappl  = konh-kappl
           AND    kschl  = konh-kschl.
      w_betrag4 = zsd_04_kehricht-vflaeche_fakt4
                * konp-kbetr / konp-kpein.
    ENDSELECT.
  ENDSELECT.
* Lesen Preis Material 5
  CONCATENATE zsd_04_kehricht-vkorg
              zsd_04_kehricht-vtweg
              zsd_04_kehr_mat-matnr_5
         INTO l_vakey.
  SELECT        * FROM  konh
         WHERE  kvewe    = 'A'
         AND    kotabnr  = '004'
         AND    kappl    = 'V'
         AND    kschl    = 'PR00'
         AND    vakey    = l_vakey
         AND    datab   LE sy-datum
         AND    datbi   GE sy-datum.
    SELECT        * FROM  konp
           WHERE  knumh  = konh-knumh
           AND    kappl  = konh-kappl
           AND    kschl  = konh-kschl.
      w_betrag5 = zsd_04_kehricht-vflaeche_fakt5
                * konp-kbetr / konp-kpein.
    ENDSELECT.
  ENDSELECT.
* Total
  w_betrag = w_betrag1 + w_betrag2 + w_betrag3
           + w_betrag4 + w_betrag5.


ENDFORM.                    " betrag_rechnen
*&      Form  ADMIN_CUSTOMER
*&---------------------------------------------------------------------*
*       Debitor pflegen
*       UD_READONLY dient dazu, den Debitor nur anzuzeigen.
*----------------------------------------------------------------------*
FORM admin_customer  USING    uv_readonly
                     CHANGING cv_kunnr.

  CLEAR gs_kna1.
  SELECT SINGLE * FROM kna1 INTO gs_kna1 WHERE kunnr EQ cv_kunnr.

  IF sy-subrc EQ 0.
    SET PARAMETER ID 'KUN' FIELD cv_kunnr.
    IF uv_readonly EQ abap_true.
      CALL TRANSACTION 'XD03' AND SKIP FIRST SCREEN.
    ELSE.
      CALL TRANSACTION 'XD02'.
    ENDIF.
  ELSE.
    IF uv_readonly EQ abap_false.
      SET PARAMETER ID 'KGD' FIELD c_kgd.
      SET PARAMETER ID 'KUN' FIELD space.
      CALL TRANSACTION 'XD01'.
      GET PARAMETER ID 'KUN' FIELD cv_kunnr.
    ENDIF.
  ENDIF.
ENDFORM.                    " ADMIN_CUSTOMER
*&---------------------------------------------------------------------*
*&      Form  GET_ADDR_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ZSD_04_KEHRICHT_EIGEN_KUNNR  text
*      <--P_GS_ADRS_PRINT  text
*----------------------------------------------------------------------*
FORM get_addr_data  USING        uv_kunnr
                    CHANGING cs_adrs_print.

  DATA: lv_kunnr TYPE kunnr,
        lv_adrnr TYPE adrnr.



  CLEAR: lv_kunnr, lv_adrnr, cs_adrs_print.


  COMMIT WORK.


  "Adressnummer anhand der Kundennummer ermitteln
  SELECT SINGLE adrnr FROM kna1 INTO lv_adrnr
    WHERE kunnr = uv_kunnr.

  IF sy-subrc EQ 0.
    CALL FUNCTION 'ADDRESS_INTO_PRINTFORM'
      EXPORTING
        address_type      = '1'
        address_number    = lv_adrnr
        number_of_lines   = 5
      IMPORTING
        address_printform = cs_adrs_print.
  ENDIF.

ENDFORM.                    " GET_ADDR_DATA
*&---------------------------------------------------------------------*
*&      Form  PROTOCOL_CHANGES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ZSD_04_KEHRICHT  text
*      -->P_W_ZSD_04_KEHRICHT  text
*----------------------------------------------------------------------*
FORM protocol_changes  USING    chg_kehricht STRUCTURE zsd_04_kehricht
                                org_kehricht STRUCTURE zsd_04_kehricht.

  FIELD-SYMBOLS: <zsd_04_old> TYPE  zsd_04_kehricht,
                 <zsd_04_new> TYPE  zsd_04_kehricht.
  FIELD-SYMBOLS: <comp_old> TYPE  any,
                  <comp_new> TYPE  any.
  ASSIGN org_kehricht TO <zsd_04_old>.
  ASSIGN chg_kehricht TO <zsd_04_new>.

  DATA: s_prot TYPE xfeld.

  SELECT * FROM zsd_04_chg_cust INTO TABLE t_chg_cust WHERE aktiv = abap_true AND tabname = 'ZSD_04_KEHRICHT'.

  w_zsd_04_chg_prot-obj_key = zsd_04_kehricht-obj_key.
  w_zsd_04_chg_prot-erdat = sy-datum.
  w_zsd_04_chg_prot-erzet = sy-uzeit.


  w_zsd_04_chg_prot-ernam = sy-uname.

  LOOP AT t_chg_cust INTO w_chg_cust.
    ASSIGN COMPONENT w_chg_cust-fieldname OF STRUCTURE <zsd_04_old> TO <comp_old>.
    ASSIGN COMPONENT w_chg_cust-fieldname  OF STRUCTURE <zsd_04_new> TO <comp_new>.
    IF <comp_old> <> <comp_new>.
      w_zsd_04_chg_prot-tabname  = w_chg_cust-tabname.
      w_zsd_04_chg_prot-fieldname = w_chg_cust-fieldname.
      w_zsd_04_chg_prot-newval = <comp_new>.
      w_zsd_04_chg_prot-oldval = <comp_old>.
      MODIFY zsd_04_chg_prot FROM w_zsd_04_chg_prot.

    ENDIF.
  ENDLOOP.







ENDFORM.                    " PROTOCOL_CHANGES
