*&---------------------------------------------------------------------*
*&  Include           MZSD_05_LULU_FORMF01
*&---------------------------------------------------------------------*



*&---------------------------------------------------------------------*
*&      Form  ADD_FCODE_EXCLUDE
*&---------------------------------------------------------------------*
*       Funktion zum Exkludieren hinzufügen
*----------------------------------------------------------------------*
FORM add_fcode_exclude USING uv_fcode.

  gs_fcode_excludes = uv_fcode.

  APPEND gs_fcode_excludes TO gt_fcode_excludes.

ENDFORM.                    " ADD_FCODE_EXCLUDE



*&---------------------------------------------------------------------*
*&      Form  FILL_TEXT_VALUES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ZSD_05_LULU_HEAD_EIGEN_VER  text
*      -->P_SY_LANGU  text
*      <--P_GV_EIGEN_VER_VAL  text
*----------------------------------------------------------------------*
FORM fill_text_values  USING    uv_domname
                                uv_val_key
                                uv_langu
                       CHANGING cv_text_value.

  DATA: lv_domname TYPE dd07l-domname,
        lv_val_key TYPE dd07l-domvalue_l,
        ls_dd07v TYPE dd07v.

  lv_domname = uv_domname.
  lv_val_key = uv_val_key.


  CALL FUNCTION 'DD_DOMVALUE_TEXT_GET'
    EXPORTING
      domname  = lv_domname
      value    = lv_val_key
      langu    = uv_langu
    IMPORTING
      dd07v_wa = ls_dd07v.

  cv_text_value = ls_dd07v-ddtext.
ENDFORM.                    " FILL_TEXT_VALUES



*&---------------------------------------------------------------------*
*&      Form  GET_ADDR_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_LULU_HEAD_EIGEN_KUNNR  text
*      <--P_LV_ADRS_PRINT  text
*----------------------------------------------------------------------*
FORM get_addr_data  USING    uv_kunnr
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
*&      Form  GET_OBJ_ADDR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_obj_addr.
  DATA: ls_objekt TYPE zsd_05_objekt.



  CLEAR: gv_obj_addr, ls_objekt.

  SELECT SINGLE * FROM zsd_05_objekt INTO ls_objekt
    WHERE stadtteil = gs_lulu_head-stadtteil
      AND parzelle  = gs_lulu_head-parzelle
      AND objekt    = gs_lulu_head-objekt.



  "Strasse prüfen
  IF NOT ls_objekt-street IS INITIAL.
    gv_obj_addr = ls_objekt-street.
  ENDIF.

  "Hausnummer prüfen
  IF NOT ls_objekt-house_num1 IS INITIAL.
    IF NOT gv_obj_addr IS INITIAL.
      CONCATENATE gv_obj_addr ls_objekt-house_num1 INTO gv_obj_addr SEPARATED BY space.
    ELSE.
      gv_obj_addr = ls_objekt-house_num1.
    ENDIF.
  ENDIF.

  "PLZ prüfen
  IF NOT ls_objekt-post_code1 IS INITIAL.
    IF NOT gv_obj_addr IS INITIAL.
      CONCATENATE gv_obj_addr ls_objekt-post_code1 INTO gv_obj_addr SEPARATED BY `, `.
    ELSE.
      gv_obj_addr = ls_objekt-post_code1.
    ENDIF.
  ENDIF.

  "Ort prüfen
  IF NOT ls_objekt-city1 IS INITIAL.
    IF NOT gv_obj_addr IS INITIAL.
      IF NOT ls_objekt-post_code1 IS INITIAL.
        CONCATENATE gv_obj_addr ls_objekt-city1 INTO gv_obj_addr SEPARATED BY space.
      ELSE.
        CONCATENATE gv_obj_addr ls_objekt-city1 INTO gv_obj_addr SEPARATED BY `, `.
      ENDIF.
    ELSE.
      gv_obj_addr = ls_objekt-post_code1.
    ENDIF.
  ENDIF.

  "Land prüfen
  IF NOT ls_objekt-country IS INITIAL.
    IF NOT gv_obj_addr IS INITIAL.
      CONCATENATE gv_obj_addr ls_objekt-country INTO gv_obj_addr SEPARATED BY `, `.
    ELSE.
      gv_obj_addr = ls_objekt-country.
    ENDIF.
  ENDIF.
ENDFORM.                    " GET_OBJ_ADDR

*----------------------------------------------------------------------*
*   INCLUDE TABLECONTROL_FORMS                                         *
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  USER_OK_TC                                               *
*&---------------------------------------------------------------------*
FORM user_ok_tc USING    p_tc_name TYPE dynfnam
                         p_table_name
                         p_struc_name
                         p_mark_name
                         p_action
                         p_delable
                CHANGING p_ok      LIKE sy-ucomm.

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA: l_ok              TYPE sy-ucomm,
        l_offset          TYPE i.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

*&SPWIZARD: Table control specific operations                          *
*&SPWIZARD: evaluate TC name and operations                            *
  SEARCH p_ok FOR p_tc_name.
  IF sy-subrc <> 0.
    EXIT.
  ENDIF.
  l_offset = strlen( p_tc_name ) + 1.
  l_ok = p_ok+l_offset.
*&SPWIZARD: execute general and TC specific operations                 *
  CASE l_ok.
    WHEN 'INSR'.                      "insert row
      PERFORM fcode_insert_row USING    p_tc_name
                                        p_table_name
                                        p_struc_name
                                        p_action
                                        p_delable.
      CLEAR p_ok.

    WHEN 'DELE'.                      "delete row
      PERFORM fcode_delete_row USING    p_tc_name
                                        p_table_name
                                        p_mark_name
                                        p_action
                                        p_delable.
      CLEAR p_ok.

    WHEN 'P--' OR                     "top of list
         'P-'  OR                     "previous page
         'P+'  OR                     "next page
         'P++'.                       "bottom of list
      PERFORM compute_scrolling_in_tc USING p_tc_name
                                            l_ok.
      CLEAR p_ok.
*     WHEN 'L--'.                       "total left
*       PERFORM FCODE_TOTAL_LEFT USING P_TC_NAME.
*
*     WHEN 'L-'.                        "column left
*       PERFORM FCODE_COLUMN_LEFT USING P_TC_NAME.
*
*     WHEN 'R+'.                        "column right
*       PERFORM FCODE_COLUMN_RIGHT USING P_TC_NAME.
*
*     WHEN 'R++'.                       "total right
*       PERFORM FCODE_TOTAL_RIGHT USING P_TC_NAME.
*
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

*     WHEN 'SASCEND'   OR
*          'SDESCEND'.                  "sort column
*       PERFORM FCODE_SORT_TC USING P_TC_NAME
*                                   l_ok.

  ENDCASE.

ENDFORM.                              " USER_OK_TC



*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_insert_row USING p_tc_name TYPE dynfnam
                            p_table_name
                            p_struc_name
                            p_action
                            p_delable.

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_lines_name       LIKE feld-name.
  DATA l_selline          LIKE sy-stepl.
  DATA l_lastline         TYPE i.
  DATA l_line             TYPE i.
  DATA l_table_name       LIKE feld-name.
  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <struc>     TYPE any.
  FIELD-SYMBOLS <field_val> TYPE any.
  FIELD-SYMBOLS <lines>              TYPE i.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.                "not headerline

  "Struktur zuweisen
  ASSIGN (p_struc_name) TO <struc>.

*&SPWIZARD: get looplines of TableControl                              *
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.
  ASSIGN (l_lines_name) TO <lines>.

*&SPWIZARD: get current line                                           *
*****   GET CURSOR LINE L_SELLINE.
*****   IF SY-SUBRC <> 0.                   " append line to table
  l_selline = <tc>-lines + 1.
*&SPWIZARD: set top line                                               *
  IF l_selline > <lines>.
    <tc>-top_line = l_selline - <lines> + 1 .
  ELSE.
    <tc>-top_line = 1.
  ENDIF.
*****   ELSE.                               " insert line into table
*****     L_SELLINE = <TC>-TOP_LINE + L_SELLINE - 1.
*****     L_LASTLINE = <TC>-TOP_LINE + <LINES> - 1.
*****   ENDIF.
*&SPWIZARD: set new cursor line                                        *
  l_line = l_selline - <tc>-top_line + 1.


  CASE p_tc_name.
    WHEN 'TC_FAKT'.
      DATA: lr_struc TYPE REF TO data.

      SET PARAMETER ID 'KUN' FIELD gs_lulu_head-rg_kunnr.

*      FIELD-SYMBOLS: <fs_struc>.
*
*      CREATE DATA lr_struc LIKE <struc>.
*      ASSIGN lr_struc->* TO <fs_struc>.

      CLEAR: <struc>. ", <fs_struc>.

      "Fallnummer fortschreiben, wenn vorhanden
      ASSIGN COMPONENT 'FALLNR' OF STRUCTURE <struc> TO <field_val>.
      <field_val> = gs_lulu_head-fallnr.

      "Aktion fortschreiben
      ASSIGN COMPONENT p_action OF STRUCTURE <struc> TO <field_val>.
      <field_val> = c_insert.

      "Löschmöglichkeit fortschreiben
      ASSIGN COMPONENT p_delable OF STRUCTURE <struc> TO <field_val>.
      <field_val> = abap_true.

      APPEND <struc> TO <table>.
      <tc>-lines = <tc>-lines + 1.

  ENDCASE.

******&SPWIZARD: insert initial line                                        *
*****  INSERT INITIAL LINE INTO <table> INDEX l_selline.
*****  <tc>-lines = <tc>-lines + 1.

*&SPWIZARD: set cursor                                                 *
  SET CURSOR LINE l_line.

ENDFORM.                              " FCODE_INSERT_ROW



*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_delete_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name
                       p_mark_name
                       p_action
                       p_delable.

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA lv_tabix TYPE sy-tabix.

  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <table_del>  TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
  FIELD-SYMBOLS <pos_action>.
  FIELD-SYMBOLS <pos_delable>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.                "not headerline


*  "Zugriff auf Löschtabelle für DB-Vorgang vorbereiten
  CLEAR: l_table_name.
  CONCATENATE p_table_name '_DEL[]' INTO l_table_name.
  ASSIGN (l_table_name) TO <table_del>.


*&SPWIZARD: delete marked lines                                        *
  DESCRIBE TABLE <table> LINES <tc>-lines.

  LOOP AT <table> ASSIGNING <wa>.
    CLEAR: lv_tabix.
    lv_tabix = sy-tabix.


*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    "Kompontentenzugriff für die Positionaktion
    ASSIGN COMPONENT p_action OF STRUCTURE <wa> TO <pos_action>.

    "Kompontentenzugriff für löschbare Positionen
    ASSIGN COMPONENT p_delable OF STRUCTURE <wa> TO <pos_delable>.

    IF <mark_field> = abap_true.
      <pos_action> = c_delete.

      "Zu löschende Positionen ermitteln, welche bereits in der DB sind
      IF <pos_delable> = abap_false.
        APPEND <wa> TO <table_del>.
      ENDIF.
      DELETE <table> INDEX lv_tabix.
      IF sy-subrc = 0.
        <tc>-lines = <tc>-lines - 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                              " FCODE_DELETE_ROW



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
*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_tc_new_top_line     TYPE i.
  DATA l_tc_name             LIKE feld-name.
  DATA l_tc_lines_name       LIKE feld-name.
  DATA l_tc_field_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <lines>      TYPE i.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.
*&SPWIZARD: get looplines of TableControl                              *
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_tc_lines_name.
  ASSIGN (l_tc_lines_name) TO <lines>.


*&SPWIZARD: is no line filled?                                         *
  IF <tc>-lines = 0.
*&SPWIZARD: yes, ...                                                   *
    l_tc_new_top_line = 1.
  ELSE.
*&SPWIZARD: no, ...                                                    *
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

*&SPWIZARD: get actual tc and column                                   *
  GET CURSOR FIELD l_tc_field_name
             AREA  l_tc_name.

  IF syst-subrc = 0.
    IF l_tc_name = p_tc_name.
*&SPWIZARD: et actual column                                           *
      SET CURSOR FIELD l_tc_field_name LINE 1.
    ENDIF.
  ENDIF.

*&SPWIZARD: set the new top line                                       *
  <tc>-top_line = l_tc_new_top_line.
ENDFORM.                              " COMPUTE_SCROLLING_IN_TC



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
*&SPWIZARD: EGIN OF LOCAL DATA-----------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.                "not headerline

*&SPWIZARD: mark all filled lines                                      *
  LOOP AT <table> ASSIGNING <wa>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    <mark_field> = 'X'.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines



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
*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>.

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.                "not headerline

*&SPWIZARD: demark all filled lines                                    *
  LOOP AT <table> ASSIGNING <wa>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    <mark_field> = space.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines



*&---------------------------------------------------------------------*
*&      Form  SAVE_DATA2DB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0371   text
*      -->P_GT_LULU_HEAD  text
*      <--P_GV_SUBRC  text
*----------------------------------------------------------------------*
FORM save_data2db TABLES   it_table TYPE table
                  USING    iv_ddtable
                  CHANGING cv_subrc.

  DATA: dref_struc TYPE REF TO data,
        dref_struc_db TYPE REF TO data,
        ls_return TYPE bapiret1.

  FIELD-SYMBOLS: <fs_struc> TYPE any,
                 <fs_struc_db> TYPE any,
                 <fs_action_val> TYPE any,
                 <fs_delable_val> TYPE any.


  "Datenobjekte erzeugen
  CREATE DATA dref_struc LIKE LINE OF it_table.
  ASSIGN dref_struc->* TO <fs_struc>.

  CREATE DATA dref_struc_db TYPE (iv_ddtable).
  ASSIGN dref_struc_db->* TO <fs_struc_db>.


  "Verarbeitung der Tabelleneinträge
  LOOP AT it_table ASSIGNING <fs_struc>.
    MOVE-CORRESPONDING <fs_struc> TO <fs_struc_db>.

    ASSIGN COMPONENT 'ACTION' OF STRUCTURE <fs_struc> TO <fs_action_val>.
    ASSIGN COMPONENT 'DELABLE' OF STRUCTURE <fs_struc> TO <fs_delable_val>.

    CASE <fs_action_val>.
      WHEN 'I' OR 'U' OR space. "Insert, Update oder leer
        MODIFY (iv_ddtable) FROM <fs_struc_db>.
        IF sy-subrc NE 0.
          cv_subrc = sy-subrc.
        ENDIF.
      WHEN 'D'. "Delete
        IF <fs_delable_val> EQ abap_false.
          DELETE (iv_ddtable) FROM <fs_struc_db>.
          IF sy-subrc NE 0.
            cv_subrc = sy-subrc.
          ENDIF.
        ENDIF.
    ENDCASE.
  ENDLOOP.
ENDFORM.                    " SAVE_DATA2DB



*&---------------------------------------------------------------------*
*&      Form  OBJ_PERIOD_EXISTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_LULU_HEAD_STADTTEIL  text
*      -->P_GS_LULU_HEAD_PARZELLE  text
*      -->P_GS_LULU_HEAD_OBJEKT  text
*      -->P_GS_LULU_HEAD_PER_BEGINN  text
*      -->P_GS_LULU_HEAD_PER_ENDE  text
*      -->P_ABAP_TRUE  text
*      <--P_GV_SUBRC  text
*----------------------------------------------------------------------*
FORM obj_period_exists  USING    uv_fallnr
                                 uv_stadtteil
                                 uv_parzelle
                                 uv_objekt
                                 uv_per_beginn
                                 uv_per_ende
                                 uv_get_data
                        CHANGING cv_subrc.



  "Ist bereits ein Gesuch innerhalb der gewünschten Periode erfasst worden?
  IF NOT uv_fallnr IS INITIAL.
    SELECT SINGLE * FROM zsd_05_lulu_head INTO gs_lulu_head
      WHERE fallnr  EQ uv_fallnr.

    cv_subrc = sy-subrc.
*  ENDIF.
*
*  IF cv_subrc NE 0.
  ELSE.
    SELECT SINGLE * FROM zsd_05_lulu_head INTO gs_lulu_head
      WHERE stadtteil  EQ uv_stadtteil
        AND parzelle   EQ uv_parzelle
        AND objekt     EQ uv_objekt
        AND per_beginn BETWEEN uv_per_beginn AND uv_per_ende
        AND loevm      EQ space
         OR stadtteil  EQ uv_stadtteil
        AND parzelle   EQ uv_parzelle
        AND objekt     EQ uv_objekt
        AND per_ende   BETWEEN uv_per_beginn AND uv_per_ende
        AND loevm      EQ space.

    cv_subrc = sy-subrc.
  ENDIF.



  "Parameter-IDs setzen
  SET PARAMETER ID 'ZZ_STADTTEIL' FIELD gs_lulu_head-stadtteil.
  SET PARAMETER ID 'ZZ_PARZELLEN_NR' FIELD gs_lulu_head-parzelle.
  SET PARAMETER ID 'ZZ_PARZELLEN_TEIL' FIELD gs_lulu_head-objekt.



  IF cv_subrc EQ 0.
    IF uv_get_data EQ abap_true.
      "Adressdaten des Eigentümers ermitteln
      IF NOT gs_lulu_head-eigen_kunnr IS INITIAL.
        PERFORM get_addr_data USING    gs_lulu_head-eigen_kunnr
                              CHANGING gs_adrs_print.

        "Adressdaten in entsprechende Felder füllen
        MOVE-CORRESPONDING gs_adrs_print TO gs_et_addr_print.
      ENDIF.

      "Adressdaten des Vertreters ermitteln
      IF gs_lulu_head-vertr_kunnr IS INITIAL.
        PERFORM get_addr_data USING    gs_lulu_head-vertr_kunnr
                              CHANGING gs_adrs_print.

        "Adressdaten in entsprechende Felder füllen
        MOVE-CORRESPONDING gs_adrs_print TO gs_vt_addr_print.
      ENDIF.

      "Adressdaten des Rechnungsempfängers ermitteln
      IF NOT gs_lulu_head-rg_kunnr IS INITIAL.
        PERFORM get_addr_data USING    gs_lulu_head-rg_kunnr
                              CHANGING gs_adrs_print.

        "Adressdaten in entsprechende Felder füllen
        MOVE-CORRESPONDING gs_adrs_print TO gs_re_addr_print.

        SET PARAMETER ID 'KUN' FIELD gs_lulu_head-rg_kunnr.
      ELSE.
        SET PARAMETER ID 'KUN' FIELD space.
      ENDIF.

      SELECT * FROM zsd_05_lulu_fakt INTO CORRESPONDING FIELDS OF TABLE gt_lulu_fakt
        WHERE fallnr EQ gs_lulu_head-fallnr.
    ENDIF.
  ENDIF.
ENDFORM.                    " OBJ_PERIOD_EXISTS


*&---------------------------------------------------------------------*
*&      Form  INIT_FCODE_EXCLUDE
*&---------------------------------------------------------------------*
*       Initialisieren der gespeicherten Exclude-Funktionen
*----------------------------------------------------------------------*
FORM init_fcode_exclude .
  CLEAR: gs_fcode_excludes, gt_fcode_excludes[].
ENDFORM.                    " INIT_FCODE_EXCLUDE



*&---------------------------------------------------------------------*
*&      Form  GET_NEW_FALLNR
*&---------------------------------------------------------------------*
*       Neue Fallnummer aus Nummernkreis ermitteln
*----------------------------------------------------------------------*
FORM get_new_fallnr CHANGING cd_fallnr.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = c_nk_nrr
      object                  = c_nk_obj
      quantity                = '1'
*     toyear                  = ud_gjahr
*     IGNORE_BUFFER           = ' '
    IMPORTING
      number                  = cd_fallnr
*     QUANTITY                =
*     RETURNCODE              =
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " GET_NEW_FALLNR



*&---------------------------------------------------------------------*
*&      Form  SET_NEW_FALLNR
*&---------------------------------------------------------------------*
*       Neue Fallnummer setzen
*----------------------------------------------------------------------*
FORM set_new_fallnr USING    ud_fallnr
                             ud_fieldname
                    CHANGING ct_table TYPE STANDARD TABLE.

  DATA: lr_struc TYPE REF TO data.

  FIELD-SYMBOLS: <lfs_struc>,
                 <lfs_field>.

  CREATE DATA lr_struc LIKE LINE OF ct_table.
  ASSIGN lr_struc->* TO <lfs_struc>.

  LOOP AT ct_table INTO <lfs_struc>.
    ASSIGN COMPONENT ud_fieldname OF STRUCTURE <lfs_struc> TO <lfs_field>.
    <lfs_field> = ud_fallnr.

    MODIFY ct_table FROM <lfs_struc>.

  ENDLOOP.
ENDFORM.                    " SET_NEW_FALLNR



*&---------------------------------------------------------------------*
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
*&      Form  PRINT_CONFIRM
*&---------------------------------------------------------------------*
*       Empfängsbestätigung drucken
*----------------------------------------------------------------------*
*      -->P_GS_LULU_HEAD  text
*----------------------------------------------------------------------*
FORM print_confirm USING us_lulu_head.

  DATA: lv_sfname TYPE tdsfname,
        lv_fbnam TYPE rs38l_fnam,
        ls_sf_control_params TYPE ssfctrlop,
        ls_sf_options	TYPE ssfcompop,
        ls_job_output_info TYPE ssfcrescl,
        ls_document_output_info TYPE ssfcrespd,
        ls_job_output_options TYPE ssfcresop,
        lo_idutil TYPE REF TO zcl_id_util,
        lv_file TYPE string,
        lv_path TYPE string,
        lv_extens TYPE string,
        ls_lulu_head TYPE zsd_05_lulu_head.


  CLEAR: lv_sfname, lv_fbnam, ls_sf_control_params, ls_sf_options, ls_job_output_info, ls_lulu_head,
         ls_document_output_info, ls_job_output_options, lo_idutil, lv_file, lv_path, lv_extens.


  "Daten für Übergabe bereitstellen
  MOVE-CORRESPONDING us_lulu_head TO ls_lulu_head.

  "Funktionsbaustein lesen
  lv_sfname = 'ZSD_05_LULU_EMPF_BEST01'.
  PERFORM get_fbnam USING    lv_sfname
                    CHANGING lv_fbnam.


  ls_sf_options-tdnewid         = 'X'.
  ls_sf_options-tddataset       = 'LULU'.
  ls_sf_options-tdsuffix1       = 'EMBE'.
  ls_sf_options-tdtitle         = 'LULU Empfangsbestätigung'.
  ls_sf_control_params-no_open   = ' '.
  ls_sf_control_params-no_close  = ' '.

  CALL FUNCTION lv_fbnam
    EXPORTING
      lulu_head          = ls_lulu_head
      control_parameters = ls_sf_control_params
      output_options     = ls_sf_options
*    TABLES
*      definierte_Tabelle = table_data
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.


ENDFORM.                    " PRINT_CONFIRM



*&---------------------------------------------------------------------*
*&      Form  GET_FBNAM
*&---------------------------------------------------------------------*
*       Funktionsbaustein zu Smarform lesen
*----------------------------------------------------------------------*
FORM get_fbnam  USING    uv_sfname
                CHANGING cv_fbnam.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname               = uv_sfname
*   VARIANT                  = ' '
*   DIRECT_CALL              = ' '
   IMPORTING
     fm_name                 = cv_fbnam
* EXCEPTIONS
*   NO_FORM                  = 1
*   NO_FUNCTION_MODULE       = 2
*   OTHERS                   = 3
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " GET_FBNAM



*&---------------------------------------------------------------------*
*&      Form  FALL_ENQUEUE
*&---------------------------------------------------------------------*
*       Sperreintrag prüfen und setzen
*----------------------------------------------------------------------*
FORM fall_enqueue USING uv_mode
                        uv_mandt
                        uv_fallnr
               CHANGING cv_subrc.

  DATA: lv_enqusr TYPE sy-msgv1.

  CALL FUNCTION 'ENQUEUE_EZSD_05_LULUFORM'
    EXPORTING
      mode_zsd_05_lulu_head = uv_mode
      mode_zsd_05_lulu_fakt = uv_mode
      mandt                 = sy-mandt
      fallnr                = uv_fallnr
*     VBELN                 = VBELN
      _scope                = '2'
      _wait                 = abap_false
      _collect              = abap_false
    EXCEPTIONS
      foreign_lock          = 1
      system_failure        = 2
      OTHERS                = 3.

  cv_subrc = sy-subrc.

  IF sy-subrc <> 0.
    MOVE sy-msgv1 TO lv_enqusr.
    MESSAGE s007(zsd_05_lulu) WITH uv_fallnr lv_enqusr.
  ENDIF.
ENDFORM.                    " FALL_ENQUEUE
