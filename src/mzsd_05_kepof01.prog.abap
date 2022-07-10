*&---------------------------------------------------------------------*
*&  Include           MZSD_05_KEPOF01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  READ_ADDRESS
*&---------------------------------------------------------------------*
*       Liest die Kundenadresse aus
*----------------------------------------------------------------------*
FORM read_address  USING    ud_kunnr
                   CHANGING cs_kdata TYPE kna1.

  CLEAR: gs_kna1, gs_adrc.

  IF NOT ud_kunnr IS INITIAL.

    SELECT SINGLE * FROM kna1 INTO gs_kna1
      WHERE kunnr = ud_kunnr.

    "Vorbelegen der Daten
    MOVE-CORRESPONDING gs_kna1 TO cs_kdata.

    "Akutellste Daten in der ADRC holen
    SELECT SINGLE * FROM adrc INTO gs_adrc
      WHERE addrnumber = gs_kna1-adrnr.

    IF sy-subrc EQ 0.
      cs_kdata-name1 = gs_adrc-name1.
      cs_kdata-name2 = gs_adrc-name2.
      CONCATENATE gs_adrc-street gs_adrc-house_num1
        INTO cs_kdata-stras SEPARATED BY space.
      cs_kdata-land1 = gs_adrc-country.
      cs_kdata-pstlz = gs_adrc-post_code1.
      cs_kdata-ort01 = gs_adrc-city1.
    ELSE.
      CLEAR cs_kdata.
    ENDIF.

  ENDIF.
ENDFORM.                    " READ_ADDRESS


*&---------------------------------------------------------------------*
*&      Form  CREATE_TEXTEDIT
*&---------------------------------------------------------------------*
*       Textcontainer instanzieren
*----------------------------------------------------------------------*
FORM create_textedit .
  gd_repid = sy-repid.

  "Objekt Custom Container instanzieren
  CREATE OBJECT gr_editor_container_fbem
    EXPORTING
*     parent                      =
      container_name              = 'CC_FBEM'
*     style                       =
*     lifetime                    = lifetime_default
*     repid                       =
*     dynnr                       =
*     no_autodef_progid_dynnr     =
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  "Objekt für TextEditor Control instanzieren
  CREATE OBJECT gr_editor_fbem
    EXPORTING
*     max_number_chars       =
*     style  = 0
*     wordwrap_mode          = wordwrap_at_windowborder
*     wordwrap_position      = -1
*     wordwrap_to_linebreak_mode = false
*     filedrop_mode          = dropfile_event_off
      parent = gr_editor_container_fbem
*     lifetime               =
*     name   =
*    EXCEPTIONS
*     error_cntl_create      = 1
*     error_cntl_init        = 2
*     error_cntl_link        = 3
*     error_dp_create        = 4
*     gui_type_not_supported = 5
*     others = 6
    .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " CREATE_TEXTEDIT


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
  DATA: l_ok     TYPE sy-ucomm,
        l_offset TYPE i.
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
  DATA l_lines_name LIKE feld-name.
  DATA l_selline    LIKE sy-stepl.
  DATA l_lastline   TYPE i.
  DATA l_line       TYPE i.
  DATA l_table_name LIKE feld-name.
*  DATA l_struc_name LIKE feld-name.

  FIELD-SYMBOLS <tc>        TYPE cxtab_control.
  FIELD-SYMBOLS <table>     TYPE STANDARD TABLE.
  FIELD-SYMBOLS <struc>     TYPE any.
  FIELD-SYMBOLS <field_val> TYPE any.
  FIELD-SYMBOLS <lines>     TYPE i.
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
  GET CURSOR LINE l_selline.
  IF sy-subrc <> 0.                   " append line to table
    l_selline = <tc>-lines + 1.
*&SPWIZARD: set top line                                               *
    IF l_selline > <lines>.
      <tc>-top_line = l_selline - <lines> + 1 .
    ELSE.
      <tc>-top_line = 1.
    ENDIF.
  ELSE.                               " insert line into table
    l_selline = <tc>-top_line + l_selline - 1.
    l_lastline = <tc>-top_line + <lines> - 1.
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  l_line = l_selline - <tc>-top_line + 1.


  CASE p_tc_name.
    WHEN 'TC_MATPOS' OR 'TC_DOCPOS'.
      DATA: lr_struc TYPE REF TO data.
      DATA: ld_posnr TYPE posnr.

      FIELD-SYMBOLS: <ls_struc>.

      CREATE DATA lr_struc LIKE <struc>.
      ASSIGN lr_struc->* TO <ls_struc>.

      CLEAR: <struc>, <ls_struc>.

      "Fallnummer fortschreiben, wenn vorhanden
      ASSIGN COMPONENT 'FALLNR' OF STRUCTURE <struc> TO <field_val>.
      <field_val> = gs_kepo-fallnr.

      "Geschäftsjahr fortschreiben
      ASSIGN COMPONENT 'GJAHR' OF STRUCTURE <struc> TO <field_val>.
      <field_val> = gs_kepo-gjahr.

      "Eine neue Positionsnummer ermitteln
      READ TABLE <table> INTO <ls_struc> INDEX <tc>-lines.
      IF sy-subrc EQ 0.
        ASSIGN COMPONENT 'POSNR' OF STRUCTURE <ls_struc> TO <field_val>.
        ld_posnr = <field_val> + 10.
      ELSE.
        ld_posnr = 10.
      ENDIF.

      "Positionsnummer fortschreiben
      ASSIGN COMPONENT 'POSNR' OF STRUCTURE <struc> TO <field_val>.
      <field_val> = ld_posnr.

      "Aktion fortschreiben
      ASSIGN COMPONENT p_action OF STRUCTURE <struc> TO <field_val>.
      <field_val> = c_modify.

      "Löschmöglichkeit fortschreiben
      ASSIGN COMPONENT p_delable OF STRUCTURE <struc> TO <field_val>.
      <field_val> = c_true.

      APPEND <struc> TO <table>.
      <tc>-lines = <tc>-lines + 1.

  ENDCASE.


*&SPWIZARD: insert initial line                                        *
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
  DATA l_table_name       LIKE feld-name.

  DATA: ld_tabix TYPE sy-tabix.

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

  "Zugriff auf Löschtabelle für DB-Vorgang vorbereiten
  CLEAR: l_table_name.
  CONCATENATE p_table_name '_DEL[]' INTO l_table_name.
  ASSIGN (l_table_name) TO <table_del>.

*&SPWIZARD: delete marked lines                                        *
  DESCRIBE TABLE <table> LINES <tc>-lines.

  LOOP AT <table> ASSIGNING <wa>.
    CLEAR: ld_tabix.
    ld_tabix = sy-tabix.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    "Kompontentenzugriff für die Positionaktion
    ASSIGN COMPONENT p_action OF STRUCTURE <wa> TO <pos_action>.

    "Kompontentenzugriff für löschbare Positionen
    ASSIGN COMPONENT p_delable OF STRUCTURE <wa> TO <pos_delable>.

    IF <mark_field> = c_true.
      <pos_action> = c_delete.

      "Zu löschende Positionen ermitteln, welche bereits in der DB sind
      IF <pos_delable> = c_false.
        APPEND <wa> TO <table_del>.
      ENDIF.
      DELETE <table> INDEX ld_tabix.
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
        entry_act      = <tc>-top_line
        entry_from     = 1
        entry_to       = <tc>-lines
        last_page_full = c_true
        loops          = <lines>
        ok_code        = p_ok
        overlapping    = c_true
      IMPORTING
        entry_new      = l_tc_new_top_line
      EXCEPTIONS
*       NO_ENTRY_OR_PAGE_ACT  = 01
*       NO_ENTRY_TO    = 02
*       NO_OK_CODE_OR_PAGE_GO = 03
        OTHERS         = 0.
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

    <mark_field> = c_true.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines


*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_DEMARK_LINES
*&---------------------------------------------------------------------*
*       demarks all TableControl lines
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
*&      Form  INIT_ALL
*&---------------------------------------------------------------------*
*       Alles initialisieren
*----------------------------------------------------------------------*
FORM init_all .
  SET PARAMETER ID 'ZKPFNR' FIELD space.
  SET PARAMETER ID 'ZKPGJR' FIELD space.


  CLEAR: gs_kepo, gs_matpos, gt_matpos[], gt_matpos_del[],
         gs_auft, gt_auft[], gt_auft_del[], gs_deb, gs_arg,
         gs_docpos, gt_docpos[], gt_docpos_del[],
         gs_debinfo, gt_debinfo[], gs_kna1,
         gs_adrc, gt_editortext_fbem[], gs_editortext,
         gs_field_prop, gt_field_prop[], gs_msg_tab, gt_msg_tab[],

         ok_code, gd_subrc, gd_tabix, gd_repid, gd_einw1_1, gd_einw1_2,
         gd_einw2_1, gd_einw2_2,gd_einw3_1, gd_einw3_2, gd_mansp,
         gd_manh1, gd_manh2, gd_manh3, gd_fkdat, gd_cnt_err,

         gd_str, gd_hnr, gd_plz, gd_ort,

         gd_test, gd_order_dont_create, gd_invo_dont_create, gd_order_created, gd_invo_created,
         gs_order_header, gs_order_return, gt_order_return[], gs_order_items,
         gt_order_items[], gs_order_matpos, gs_order_partn, gt_order_partn[], gs_order_sched,
         gt_order_sched[], gs_order_cond, gt_order_cond[], gs_order_text, gt_order_text[],

         gs_invo_data , gt_invo_data[], gs_invo_return, gt_invo_return[],
         gs_invo_success, gt_invo_success[], gs_sf_header_data, gs_sf_docs_data, gt_sf_docs_data,

         gd_create, gd_create_store, gd_update, gd_update_store, gd_show, gd_show_store,
         gd_delete, gd_delete_store, gd_enqu, gd_enqu_store, gd_readonly, gd_debinfo_selected,
         gd_dynnr,

         gd_fieldname, gd_strucstr, gd_fldstr, gd_fval255, gs_bdc, gt_bdc[], gs_bdc_opt,

         gr_editor_container_fbem, gr_editor_fbem, gr_services,

         g_tc_matpos_lines.

ENDFORM.                    " INIT_ALL


*&---------------------------------------------------------------------*
*&      Form  ADMIN_CUSTOMER
*&---------------------------------------------------------------------*
*       Debitor pflegen
*       UD_READONLY dient dazu, den Debitor nur anzuzeigen.
*----------------------------------------------------------------------*
FORM admin_customer  USING ud_kunnr
                           ud_readonly.

  CLEAR gs_kna1.
  SELECT SINGLE * FROM kna1 INTO gs_kna1 WHERE kunnr EQ ud_kunnr.

  IF sy-subrc EQ 0.
    SET PARAMETER ID 'KUN' FIELD ud_kunnr.
    IF ud_readonly EQ c_true.
      CALL TRANSACTION 'XD03' AND SKIP FIRST SCREEN.
    ELSE.
      CALL TRANSACTION 'XD02'.
    ENDIF.
  ELSE.
    SET PARAMETER ID 'KGD' FIELD gdc_kgd.
    SET PARAMETER ID 'KUN' FIELD space.
    CALL TRANSACTION 'XD01'.
  ENDIF.
ENDFORM.                    " ADMIN_CUSTOMER


*&---------------------------------------------------------------------*
*&      Form  FALL_EXISTS
*&---------------------------------------------------------------------*
*       Wenn Fall existiert, lesen.
*       Gibt SY-SUBRC zurück.
*       UD_GET_DATA dient dazu, um sämtliche Daten zum Fall zu lesen.
*       -> c_true oder c_false
*----------------------------------------------------------------------*
FORM fall_exists USING ud_fallnr
                       ud_gjahr
                       ud_get_data
              CHANGING cd_subrc.

  DATA: ld_subrc TYPE sy-subrc.

  "Inkasso checken und Fall updaten,
  "ausser bei Aufruf über anderen Fall vià Batch-Input
  IF gdc_check_inkasso EQ c_true AND sy-binpt EQ c_false.
    CALL FUNCTION 'ZSDFBKP_CHECK_INKASSO'
      EXPORTING
        i_fallnr          = ud_fallnr
        i_gjahr           = ud_gjahr
        i_ext             = gdc_check_inkasso_ext
        i_test            = gdc_check_inkasso_test
        i_check_kunnr_old = c_true
        i_check_mahns     = gdc_check_mahns.
  ENDIF.


  "Beginn des Lesens des ausgewählten Falles
  SELECT SINGLE * FROM zsdtkpkepo INTO gs_kepo
  WHERE fallnr EQ ud_fallnr
  AND gjahr  EQ ud_gjahr.

  cd_subrc = sy-subrc.

  IF sy-subrc EQ 0.
    IF ud_get_data EQ c_true.

      "Einwandsverarbeitung setzen (N = angenommen, L = abgelehnt)
      CASE gs_kepo-einw1verarb.
        WHEN 'N'.
          gd_einw1_1 = c_true.
        WHEN 'L'.
          gd_einw1_2 = c_true.
      ENDCASE.

      CASE gs_kepo-einw2verarb.
        WHEN 'N'.
          gd_einw2_1 = c_true.
        WHEN 'L'.
          gd_einw2_2 = c_true.
      ENDCASE.

      CASE gs_kepo-einw3verarb.
        WHEN 'N'.
          gd_einw3_1 = c_true.
        WHEN 'L'.
          gd_einw3_2 = c_true.
      ENDCASE.


      "Adresse zu Debitor lesen
      PERFORM read_address USING gs_kepo-kunnr
                           CHANGING gs_deb.

      "Adresse zu abw. Rechnungsempfänger lesen
      PERFORM read_address USING gs_kepo-kunnrre
                           CHANGING gs_arg.

      "Materialpositionen lesen
      SELECT * FROM zsdtkpmatpos INTO TABLE gt_matpos
        WHERE fallnr EQ ud_fallnr
          AND gjahr  EQ ud_gjahr.

      "Verrechnungsdaten lesen
      PERFORM read_order_data USING ud_fallnr
                                    ud_gjahr.


      "Dokumentenpositionen lesen
      SELECT * FROM zsdtkpdocpos INTO TABLE gt_docpos
        WHERE fallnr EQ ud_fallnr
          AND gjahr  EQ ud_gjahr.

      "Bemerkungstext lesen
      CLEAR gd_subrc.
      PERFORM read_text  TABLES   gt_editortext_fbem
                         USING    gs_kepo-fallnr
                                  gs_kepo-gjahr
                                  gdc_tdobj
                                  gdc_tdid1
                                  gdc_langu
                         CHANGING ld_subrc.

    ENDIF.
  ENDIF.
ENDFORM.                    " FALL_EXISTS


*&---------------------------------------------------------------------*
*&      Form  GET_NEW_FALLNR
*&---------------------------------------------------------------------*
*       Neue Fallnummer aus Nummernkreis ermitteln
*----------------------------------------------------------------------*
FORM get_new_fallnr  USING    ud_gjahr
                     CHANGING cd_fallnr.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = gdc_nk_nrr
      object                  = gdc_nk_obj
      quantity                = '1'
      toyear                  = ud_gjahr
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
*&      Form  READ_TEXTEDIT
*&---------------------------------------------------------------------*
*       Text aus Editor in Tabelle lesen
*----------------------------------------------------------------------*
FORM read_textedit USING ur_editor
                CHANGING ct_editortext.

  FIELD-SYMBOLS: <fs_editor> TYPE REF TO cl_gui_textedit.

  ASSIGN ur_editor TO <fs_editor>.

  "Text lesen
*  CALL METHOD <fs_editor>->get_text_as_r3table
*    IMPORTING
*      table  = ct_editortext
*    EXCEPTIONS
*      OTHERS = 1.

  CALL METHOD <fs_editor>->get_text_as_stream
    IMPORTING
      text   = ct_editortext
    EXCEPTIONS
      OTHERS = 1.


ENDFORM.                    " READ_TEXTEDIT


*&---------------------------------------------------------------------*
*&      Form  FILL_TEXTEDIT
*&---------------------------------------------------------------------*
*       Text aus Tabelle in Editor lesen
*----------------------------------------------------------------------*
FORM fill_textedit USING ur_editor
                CHANGING ct_editortext.

  FIELD-SYMBOLS: <fs_editor> TYPE REF TO cl_gui_textedit.

  ASSIGN ur_editor TO <fs_editor>.

  "Text aus Tabelle lesen und im TableControl wiedergeben
*  CALL METHOD <fs_editor>->set_text_as_r3table
*    EXPORTING
*      table  = ct_editortext
*    EXCEPTIONS
*      OTHERS = 1.

  CALL METHOD <fs_editor>->set_text_as_stream
    EXPORTING
      text   = ct_editortext
    EXCEPTIONS
      OTHERS = 1.


ENDFORM.                    " FILL_TEXTEDIT


*&---------------------------------------------------------------------*
*&      Form  SAVE_TEXT
*&---------------------------------------------------------------------*
*       Texttabelle als Textobjekt ändern
*----------------------------------------------------------------------*
FORM save_text TABLES   tt_text STRUCTURE gs_editortext
               USING    ud_fallnr
                        ud_gjahr
                        ud_tdobj
                        ud_tdid
                        ud_lang
               CHANGING cd_subrc.

  DATA: lt_tline TYPE STANDARD TABLE OF tline,
        ls_tline TYPE tline,

        ls_thead TYPE thead.


  CLEAR: lt_tline[], ls_tline, ls_thead, gs_editortext.

  LOOP AT tt_text INTO gs_editortext.
    ls_tline-tdline = gs_editortext-line.
    APPEND ls_tline TO lt_tline.
  ENDLOOP.

  CHECK NOT lt_tline[] IS INITIAL.

  ls_thead-tdobject = ud_tdobj.
  ls_thead-tdid     = ud_tdid.
  ls_thead-tdspras  = ud_lang.

  CONCATENATE ud_gjahr ud_fallnr INTO ls_thead-tdname.

  CALL FUNCTION 'SAVE_TEXT'
    EXPORTING
      header          = ls_thead
      savemode_direct = c_true
    TABLES
      lines           = lt_tline
    EXCEPTIONS
      id              = 1
      language        = 2
      name            = 3
      object          = 4
      OTHERS          = 5.

  cd_subrc = sy-subrc.
ENDFORM.                    " SAVE_TEXT


*&---------------------------------------------------------------------*
*&      Form  READ_TEXT
*&---------------------------------------------------------------------*
*       Lesen des Textes (Textobjekt) in Texttabelle
*----------------------------------------------------------------------*
FORM read_text  TABLES   tt_editortext STRUCTURE gs_editortext
                USING    ud_fallnr
                         ud_gjahr
                         ud_tdobj
                         ud_tdid
                         ud_lang

                CHANGING cd_subrc.

  DATA: lt_tline  TYPE STANDARD TABLE OF tline,
        ls_tline  TYPE tline,
        ld_tdname TYPE tdobname.

  CONCATENATE ud_gjahr ud_fallnr INTO ld_tdname.

  CALL FUNCTION 'READ_TEXT'
    EXPORTING
      id                      = ud_tdid
      language                = ud_lang
      name                    = ld_tdname
      object                  = ud_tdobj
    TABLES
      lines                   = lt_tline
    EXCEPTIONS
      id                      = 1
      language                = 2
      name                    = 3
      not_found               = 4
      object                  = 5
      reference_check         = 6
      wrong_access_to_archive = 7
      OTHERS                  = 8.

  cd_subrc = sy-subrc.

  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE 'I'NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CLEAR: ls_tline, gs_editortext, tt_editortext[].
    LOOP AT lt_tline INTO ls_tline.
      gs_editortext-line = ls_tline-tdline.
      APPEND gs_editortext TO tt_editortext.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " READ_TEXT


*&---------------------------------------------------------------------*
*&      Form  FALL_ENQUEUE
*&---------------------------------------------------------------------*
*       Sperreintrag prüfen und setzen
*----------------------------------------------------------------------*
FORM fall_enqueue USING ud_mode
                        ud_mandt
                        ud_fallnr
                        ud_gjahr
               CHANGING cd_subrc.

  DATA: ld_enqusr TYPE sy-msgv1.


  CALL FUNCTION 'ENQUEUE_EZSD_05_KEPO'
    EXPORTING
      mode_zsdtkpkepo   = ud_mode
      mode_zsdtkpauft   = ud_mode
      mode_zsdtkpdocpos = ud_mode
      mode_zsdtkpmatpos = ud_mode
      mandt             = sy-mandt
      fallnr            = ud_fallnr
      gjahr             = ud_gjahr
      _scope            = '2'
      _wait             = c_false
      _collect          = c_false
    EXCEPTIONS
      foreign_lock      = 1
      system_failure    = 2
      OTHERS            = 3.

  cd_subrc = sy-subrc.

  IF sy-subrc <> 0.
    MOVE sy-msgv1 TO ld_enqusr.
    MESSAGE s002(zsd_05_kepo) WITH ud_gjahr ud_fallnr ld_enqusr.
  ENDIF.
ENDFORM.                    " FALL_ENQUEUE


*&---------------------------------------------------------------------*
*&      Form  SET_MAT_DETAILS
*&---------------------------------------------------------------------*
*       Details zu Materialposition setzen
*----------------------------------------------------------------------*
FORM set_mat_details  USING    ud_matnr
                               ud_langu
                      CHANGING cd_vrkme
                               cd_bezei.

  DATA: ld_matnr TYPE matnr,
        ld_vrkme TYPE vrkme,
        ld_bezei TYPE arktx.

  CLEAR: ld_vrkme, ld_bezei.

  MOVE ud_matnr TO ld_matnr.

  SHIFT ld_matnr RIGHT DELETING TRAILING ' '.
  OVERLAY ld_matnr WITH c_matnr_init.

  "Basismengeneinheit zu Material lesen
  SELECT SINGLE meins FROM mara INTO ld_vrkme
    WHERE matnr EQ ld_matnr.

  "Bezeichnung zu Matieral in ZSDTKPMAT lesen
  SELECT SINGLE bezei FROM zsdtkpmat INTO ld_bezei
    WHERE matnr EQ ld_matnr
      AND spras EQ ud_langu.

  IF sy-subrc NE 0 OR ld_bezei IS INITIAL.
    SELECT SINGLE maktx FROM makt INTO ld_bezei
      WHERE matnr EQ ld_matnr
        AND spras EQ ud_langu.
  ENDIF.

  cd_vrkme = ld_vrkme.
  cd_bezei = ld_bezei.
ENDFORM.                    " SET_MAT_DETAILS


*&---------------------------------------------------------------------*
*&      Form  SET_FIELD_PROPERTIES
*&---------------------------------------------------------------------*
*       Setze Feldeigenschaften
*----------------------------------------------------------------------*
FORM set_field_properties .

  DATA: ld_input     TYPE c,
        ld_invisible TYPE c,
        ld_required  TYPE c,
        ld_overwrite TYPE c,
        ld_field     TYPE ddfldname,
        ld_struc     TYPE ddpname,
        ld_dynfnam   TYPE dynfnam.

  FIELD-SYMBOLS: <fld>.


  IF gt_field_prop IS INITIAL.
    SELECT * FROM zsdtkpfldprop INTO TABLE gt_field_prop.
  ENDIF.

  LOOP AT SCREEN.
    CLEAR: ld_input, ld_invisible, ld_required, ld_overwrite,
           ld_field, ld_struc, ld_dynfnam, gs_field_prop.

    SPLIT screen-name AT '-' INTO ld_struc ld_field.

    IF ld_field IS INITIAL.
      ld_field = screen-name.
      CLEAR ld_struc.
    ENDIF.

    READ TABLE gt_field_prop INTO gs_field_prop WITH KEY prog_struc = ld_struc
                                                         prog_field = ld_field.

    IF sy-subrc NE 0.
      CONTINUE.
    ENDIF.

    "Feldeigenschaften vorbelegen
    ld_invisible = screen-invisible.
    ld_input     = screen-input.
    ld_required  = screen-required.


    "Ist das Feld ein Mussfeld
    IF gs_field_prop-required EQ c_true.
      ld_required = c_true_num.
      ld_input    = c_true_num.
*    ELSE.
*      ld_required = c_false_num.
    ENDIF.

    "Ist das Feld eingabefähig
    IF gs_field_prop-editable EQ c_true.
      ld_input = c_true_num.
*    ELSE.
*      ld_input = c_false_num.
    ENDIF.

    "Ist das Feld nur anzeigefähig.
    IF gs_field_prop-readonly EQ c_true.
      ld_input = c_false_num.
    ENDIF.

    "Ist das Feld ausgeblendet
    IF gs_field_prop-invisible EQ c_true.
      ld_invisible = c_true_num.
      ld_input     = c_false_num.
*    ELSE.
*      ld_invisible = c_false_num.
*      ld_input     = c_true_num.
    ENDIF.

    "Wird das Feld stets überschrieben
    IF gs_field_prop-overwrite EQ c_true.
      ld_overwrite = c_true.
    ENDIF.


    "Feldeigenschaften setzen
    screen-invisible = ld_invisible.
    screen-input     = ld_input.
    screen-required  = ld_required.

    MODIFY SCREEN.

    "Vorgabewert setzen
    ASSIGN (screen-name) TO <fld>.
    IF <fld> IS INITIAL.
      MOVE gs_field_prop-value TO <fld>.
    ELSEIF ld_overwrite EQ c_true.
      MOVE gs_field_prop-value TO <fld>.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " SET_FIELD_PROPERTIES


*&---------------------------------------------------------------------*
*&      Form  SET_GLOBAL_DATA_VALUES
*&---------------------------------------------------------------------*
*       Werte globaler Datenvariablen setzen (Customizing)
*       Gecustomizte Vorgabewerte für Programmvariablen
*       (Transaktion SM30 in Tabelle ZSDTKPFLDPROP).
*       Solche Datenvariablen können mit "GDC_" gepflegt werden
*       und die vordefinierten Werte überschreiben.
*       Die Prog-Struktur wird hier mit '&NOVAL' gefüllt!
*
*       Die Felder der GS_-Strukturen können hier auch vorbelegt
*       werden. Z.B: Prog-Struktur = GS_KEPO; Feldname = BUKRS
*----------------------------------------------------------------------*
FORM set_global_data_values.

  FIELD-SYMBOLS: <fld>.

  IF gt_field_prop IS INITIAL.
    SELECT * FROM zsdtkpfldprop INTO TABLE gt_field_prop.
  ENDIF.

  CLEAR: gs_field_prop.

  LOOP AT gt_field_prop INTO gs_field_prop
    WHERE prog_struc EQ c_no_val
      AND prog_field(4) EQ c_gdcfld.
*      AND NOT value IS INITIAL.

    ASSIGN (gs_field_prop-prog_field) TO <fld>.
    MOVE gs_field_prop-value TO <fld>.

  ENDLOOP.
ENDFORM.                    " SET_GLOBAL_DATA_VALUES


*&---------------------------------------------------------------------*
*&      Form  ADD_FCODE_EXCLUDE
*&---------------------------------------------------------------------*
*       Funktion zum Exkludieren hinzufügen
*----------------------------------------------------------------------*
FORM add_fcode_exclude  USING ud_fcode.

  gs_fcode_excludes = ud_fcode.

  APPEND gs_fcode_excludes TO gt_fcode_excludes.

ENDFORM.                    " ADD_FCODE_EXCLUDE


*&---------------------------------------------------------------------*
*&      Form  INIT_FCODE_EXCLUDE
*&---------------------------------------------------------------------*
*       Initialisieren der gespeicherten Exclude-Funktionen
*----------------------------------------------------------------------*
FORM init_fcode_exclude .
  CLEAR: gs_fcode_excludes, gt_fcode_excludes[].
ENDFORM.                    " INIT_FCODE_EXCLUDE


*&---------------------------------------------------------------------*
*&      Form  SET_MODE
*&---------------------------------------------------------------------*
*       Modus neu setzen
*       UD_OKCODE für OK-Code-Übergabe
*       CD_
*----------------------------------------------------------------------*
FORM set_mode USING ud_okcode.
  DATA: ld_answer TYPE c.

  "IDTZI 07.01.2014
  IF gs_kepo-fwdh IS INITIAL. "Falls es KEINE Wiederholung ist
    "prüfe ob Unterschrift für Verwarnung gesetzt ist
" MZi neue Fallarten
*    if gs_kepo-signpers is initial and gs_kepo-fart ne 02 and gs_kepo-fart ne 04. "wenn keine person gesetzt
    IF gs_kepo-signpers IS INITIAL AND gs_kepo-fart NE 02 AND gs_kepo-fart NE 04 AND gs_kepo-fart NE 05 AND gs_kepo-fart NE 06 AND gs_kepo-fart NE 07. "wenn keine person gesetzt
      "gebe meldung aus
      DATA text TYPE string.
      text = 'Bitte geben Sie eine Unterschriftsberechtigte Person für die Verwarnung an.' .

      MESSAGE text TYPE 'E' .

      EXIT.
    ENDIF.
  ENDIF.



  CASE c_true.
    WHEN gd_create.
      IF ud_okcode EQ 'ANLE'.
        PERFORM save_data USING c_true
                                c_false.
        mode = 'ANLE'.
      ENDIF.
    WHEN gd_update.
      IF ud_okcode EQ 'ANZE'.
        CLEAR: ld_answer.
        mode = 'ANZE'.
        "Daten vor dem Wechseln auf Anzeigemodus noch sichern?
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = TEXT-t20
            text_question         = TEXT-t21
            text_button_1         = TEXT-p90 "Ja
            text_button_2         = TEXT-p91 "Nein
            default_button        = '1'
            display_cancel_button = 'X'
          IMPORTING
            answer                = ld_answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        CASE ld_answer.
          WHEN '1'.
            PERFORM save_data USING c_false
                                    c_false.
            CLEAR: gd_update.
            gd_show = c_true.
          WHEN '2'.
            CLEAR: gd_update.
            gd_show = c_true.
          WHEN 'A'.
        ENDCASE.
      ELSEIF ud_okcode EQ 'AUFT_SIMULATE' OR ud_okcode EQ 'AUFT_CREATE'.
        CLEAR: gd_order_dont_create, ld_answer.

        "Daten vor dem Auftrag simulieren/erstellen noch sichern?
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = TEXT-t24
            text_question         = TEXT-t25
            text_button_1         = TEXT-p90 "Ja
            text_button_2         = TEXT-p91 "Nein
            default_button        = '1'
            display_cancel_button = c_false
          IMPORTING
            answer                = ld_answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        CASE ld_answer.
          WHEN '1'.
            PERFORM save_data USING c_false
                                    c_true.
          WHEN '2'.
            "Auftrag nicht mehr simulieren/anlegen
            gd_order_dont_create = c_true.

        ENDCASE.
      ELSEIF ud_okcode EQ 'EXIT' OR ud_okcode EQ 'CANC'.
        DATA: ld_title TYPE string,
              ld_quest TYPE string.

        CLEAR: ld_answer, ld_title, ld_quest.

        IF ud_okcode EQ 'EXIT'.
          ld_title = TEXT-t26.
          ld_quest = TEXT-t27.
        ELSEIF ud_okcode EQ 'CANC'.
          ld_title = TEXT-t28.
          ld_quest = TEXT-t29.
        ENDIF.

        "Daten vor dem Beenden oder Abbrechen noch sichern?
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = ld_title
            text_question         = ld_quest
            text_button_1         = TEXT-p90 "Ja
            text_button_2         = TEXT-p91 "Nein
            default_button        = '1'
            display_cancel_button = space
          IMPORTING
            answer                = ld_answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        CASE ld_answer.
          WHEN '1'.
            PERFORM save_data USING c_true
                                    c_false.
          WHEN '2'.
            LEAVE TO TRANSACTION sy-tcode.
*          WHEN 'A'.
        ENDCASE.


      ENDIF.

    WHEN gd_show.
      IF ud_okcode EQ 'AEND'.
        mode = 'AEND'.
        CLEAR: gd_show.
        gd_update = c_true.
      ELSEIF ud_okcode EQ 'EXIT' OR ud_okcode EQ 'CANC'.
        LEAVE TO TRANSACTION sy-tcode.
      ENDIF.
  ENDCASE.
ENDFORM.                    " SET_MODE


*&---------------------------------------------------------------------*
*&      Form  SAVE_DATA
*&---------------------------------------------------------------------*
*       Sämtliche Daten sichern
*       UD_START dient dazu, um die Fallverwaltung neu aufzurufen
*       -> Mögliche Werte: C_TRUE oder C_FALSE
*       UD_NO_MESS dient dazu, um die Messages zu unterdrücken
*       -> Mögliche Werte: C_TRUE oder C_FALSE
*----------------------------------------------------------------------*
FORM save_data USING ud_start
                     ud_no_msg.

  CLEAR: gd_cnt_err.






  IF gd_create EQ c_true.
    "Neue Fallnummer vergeben
    PERFORM get_new_fallnr USING gs_kepo-gjahr
                        CHANGING gs_kepo-fallnr.

    "Neue Fallnummer pro Position setzen
    PERFORM set_new_fallnr USING gs_kepo-fallnr
                                 'FALLNR'
                        CHANGING gt_matpos.

    "Neue Fallnummer pro Position setzen
    PERFORM set_new_fallnr USING gs_kepo-fallnr
                                 'FALLNR'
                        CHANGING gt_auft.

    "Neue Fallnummer pro Position setzen
    PERFORM set_new_fallnr USING gs_kepo-fallnr
                                 'FALLNR'
                        CHANGING gt_docpos.

    "Fallwiederholung prüfen und setzen
    " PERFORM set_fallwdh CHANGING gs_kepo.

    "-----20110413, IDSWE, Anpassung Status-----
*    "Fallstatus: erfasst
*    gs_kepo-fstat = '01'.
    "Fallstatus: erledigt - Wenn keine Verrechnung!
    IF gs_kepo-fstat = '03'.

    ELSEIF NOT gs_kepo-kverrgnam IS INITIAL AND NOT gs_kepo-kverrgdat IS INITIAL.
      gs_kepo-fstat = '03'.

      PERFORM read_only USING c_true.
    ELSE.
      "Fallstatus: erfasst
      gs_kepo-fstat = '01'.
    ENDIF.

    "Erfasser eintragen
    gs_kepo-ernam = sy-uname.
    gs_kepo-erdat = sy-datum.
    gs_kepo-erzet = sy-uzeit.
    gs_kepo-bem_rege = gs_rege-bem.
    gs_kepo-bem_verwarnung = gs_verwarnung-bem.
    "Hauptdaten in DBTAB einfügen
    INSERT  zsdtkpkepo FROM gs_kepo.
    IF sy-subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.
    "------------------------------------------------------------------------------------------------------------------------------------
    "verfügung speichern
    DATA buffer1 LIKE gs_rege.

    SELECT * FROM zsd_05_kepo_ver INTO buffer1 WHERE gjahr = gs_kepo-gjahr AND fallnr = gs_kepo-fallnr AND typ = 'R'.

    ENDSELECT.
    gs_rege-typ = 'R'.
    gs_rege-fallnr = gs_kepo-fallnr.
    IF gs_rege-ver_datum IS INITIAL.

    ELSE.
      IF sy-subrc NE 0.
        "Füge neuen Datensatz ein.
        INSERT zsd_05_kepo_ver FROM gs_rege.
        IF sy-subrc NE 0.
          gd_cnt_err = gd_cnt_err + 1.
        ENDIF.

      ELSE.
        "modifiziere vorhandenen Eintrag
        UPDATE zsd_05_kepo_ver FROM gs_rege.
        IF sy-subrc NE 0.
          gd_cnt_err = gd_cnt_err + 1.
        ENDIF.
      ENDIF.
    ENDIF.
    "------------------------------------------------------------------------------------------------------------------------------------
    "Verwarnung Speichern
    IF gs_kepo-fwdh IS INITIAL. "Speicher Verwarnung nur, wenn kein Wiederholungsfall
      DATA buffer LIKE kepo_ver.

      SELECT * FROM zsd_05_kepo_ver INTO buffer WHERE gjahr = gs_kepo-gjahr AND fallnr = gs_kepo-fallnr AND typ = 'V'.

      ENDSELECT.
      kepo_ver-typ = 'V'.
      kepo_ver-fallnr = gs_kepo-fallnr.
      kepo_ver-bem = gs_verwarnung-bem.
      IF kepo_ver-ver_datum IS INITIAL.

      ELSE.

        gs_kepo-fstat = '03'.
        IF sy-subrc NE 0.
          "Füge neuen Datensatz ein.
          INSERT zsd_05_kepo_ver FROM kepo_ver.
          IF sy-subrc NE 0.
            gd_cnt_err = gd_cnt_err + 1.
          ENDIF.

        ELSE.
          "modifiziere vorhandenen Eintrag
          UPDATE zsd_05_kepo_ver FROM kepo_ver.
          IF sy-subrc NE 0.
            gd_cnt_err = gd_cnt_err + 1.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
    "------------------------------------------------------------------------------------------------------------------------------------

    "Materialpositionen in DBTAB einfügen
    INSERT zsdtkpmatpos FROM TABLE gt_matpos.
    IF sy-subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.

    "Dokumentenpositionen in DBTAB einfügen
    INSERT zsdtkpdocpos FROM TABLE gt_docpos.
    IF sy-subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.

    "Bemerkungstext speichern
    CLEAR gd_subrc.
    PERFORM save_text TABLES   gt_editortext_fbem
                      USING    gs_kepo-fallnr
                               gs_kepo-gjahr
                               gdc_tdobj
                               gdc_tdid1
                               gdc_langu
                      CHANGING gd_subrc.
    IF gd_subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.


    IF ud_no_msg NE c_true.
      IF gd_cnt_err EQ 0.
        MESSAGE s010(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
      ELSE.
        MESSAGE w011(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
      ENDIF.
    ENDIF.




  ELSEIF gd_update EQ c_true.
    "Änderer eintragen
    gs_kepo-aenam = sy-uname.
    gs_kepo-aedat = sy-datum.
    gs_kepo-aezet = sy-uzeit.
    gs_kepo-bem_rege = gs_rege-bem.
    gs_kepo-bem_verwarnung = gs_verwarnung-bem.
    "-----20110413, IDSWE, Anpassung Status-----
    "Fallstatus: erledigt - Bei Debitorenverlust oder Keine Verrechnung!
    IF NOT gs_kepo-kverrgnam IS INITIAL AND NOT gs_kepo-kverrgdat IS INITIAL.
      gs_kepo-fstat = '03'.

      PERFORM read_only USING c_true.


    ENDIF.

    "Fallwiederholung prüfen und setzen, wenn Fallstatus auf ERFASST ist
    "  IF gs_kepo-fstat EQ '01'.
    "   PERFORM set_fallwdh CHANGING gs_kepo.
    " ENDIF.


    "Hauptdaten in DBTAB updaten
    MODIFY  zsdtkpkepo FROM gs_kepo.
    IF sy-subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.

    "Bereits erfasste und zu löschende Materialpositionen vorerst aus der DB löschen
    IF NOT gt_matpos_del[] IS INITIAL.
      DELETE zsdtkpmatpos FROM TABLE gt_matpos_del.
      IF sy-subrc EQ 0.
        CLEAR: gt_matpos_del[].
      ELSE.
        gd_cnt_err = gd_cnt_err + 1.
      ENDIF.
    ENDIF.

    "Materialpositionen in DBTAB einfügen / updaten
    MODIFY zsdtkpmatpos FROM TABLE gt_matpos.
    IF sy-subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.

    "Bereits erfasste und zu löschende Dokumentenpositionen vorerst aus der DB löschen
    IF NOT gt_docpos_del[] IS INITIAL.
      DELETE zsdtkpdocpos FROM TABLE gt_docpos_del.
      IF sy-subrc EQ 0.
        CLEAR: gt_docpos_del[].
      ELSE.
        gd_cnt_err = gd_cnt_err + 1.
      ENDIF.
    ENDIF.

    "Dokumentenpositionen in DBTAB einfügen / updaten
    MODIFY zsdtkpdocpos FROM TABLE gt_docpos.
    IF sy-subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.

    "Verrechnungsdaten in DBTAB updaten
    MODIFY  zsdtkpauft FROM gs_auft.
    IF sy-subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.
    "Verfügung speichern

    "DATA buffer1 LIKE gs_rege.

    "Selektiere bereits vorhandene Informationen aus DBtab
    SELECT * FROM zsd_05_kepo_ver INTO buffer1 WHERE gjahr = gs_kepo-gjahr AND fallnr = gs_kepo-fallnr AND typ = 'R'.

    ENDSELECT.
    gs_rege-typ = 'R'.

    gs_rege-fallnr = gs_kepo-fallnr.      "Setze Fallnummer
    IF gs_rege-ver_datum IS INITIAL.      "mache weiteres nur falls Datum gesetzt ist
      "Setze typ R -> [R]echtliches Gehör
    ELSE.
      IF sy-subrc NE 0.                   "Wenn keine Vorhandenen Informationen gefunden (Select oben)
        "Füge neuen Datensatz ein.
        INSERT zsd_05_kepo_ver FROM gs_rege. "Insertiere die Zeile
        IF sy-subrc NE 0.                     "Fehler falls Fehler
          gd_cnt_err = gd_cnt_err + 1.
        ENDIF.

      ELSE.                               "Wenn Vorhandene Infos Gefunden
        "modifiziere vorhandenen Eintrag
        UPDATE zsd_05_kepo_ver FROM gs_rege.  "Update auf Zeile
        IF sy-subrc NE 0.                     "Fehler falls Fehler
          gd_cnt_err = gd_cnt_err + 1.
        ENDIF.
      ENDIF.
    ENDIF.
    COMMIT WORK.
    "Verwarnung Speichern
    CLEAR buffer.
    "Selektiere bereits vorhandene Informationen aus DBtab
    SELECT * FROM zsd_05_kepo_ver INTO buffer WHERE gjahr = gs_kepo-gjahr AND fallnr = gs_kepo-fallnr.

    ENDSELECT.
    kepo_ver-typ = 'V'.
    kepo_ver-fallnr = gs_kepo-fallnr.
    "Wenn zum löschen vorgemerkt
    IF kepo_ver-ver_datum IS INITIAL.

    ELSE.
      IF sy-subrc NE 0.

        "Füge neuen Datensatz ein.

        INSERT zsd_05_kepo_ver FROM kepo_ver.
        IF sy-subrc NE 0.
          gd_cnt_err = gd_cnt_err + 1.
        ENDIF.

      ELSE.
        "      Falls zum löschen vorgemerkt, enferne eintrag.
        IF kepo_ver-loesch = 'X'.
          DELETE FROM zsd_05_kepo_ver WHERE gjahr = gs_kepo-gjahr AND fallnr = gs_kepo-fallnr.
        ELSE.
          "modifiziere vorhandenen Eintrag 12.12.2013 Entferne die Fehlerprüfung, da es OK sein kann wenn kein Update durchgeführt werden kann.
          UPDATE zsd_05_kepo_ver FROM kepo_ver.
          "  IF sy-subrc NE 0.
          "   gd_cnt_err = gd_cnt_err + 1.
          " ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    DATA rg_signpers LIKE zsd_05_kp_sign.
    DATA ve_signpers LIKE zsd_05_kp_sign.
    DATA x TYPE vrm_id.
    DATA y TYPE vrm_values.
*CALL FUNCTION 'VRM_GET_VALUEs'
*  EXPORTING
*    id                 = 'SIGNPERS_RG'
* IMPORTING
*   VALUES             = Y
* EXCEPTIONS
*   ID_NOT_FOUND       = 1
*   OTHERS             = 2
    .
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    "Gewählte unterschrigtsberechtigte speichern.

    "Verfügung

    ve_signpers-fallnr = gs_kepo-fallnr.
    ve_signpers-gjahr = gs_kepo-gjahr.
    ve_signpers-id = zsd_05_kp_signp-name.
    ve_signpers-typ = '02'.

    "Rechtliches Gehör
    rg_signpers-fallnr = gs_kepo-fallnr.
    rg_signpers-gjahr = gs_kepo-gjahr.
    rg_signpers-id = zsd_05_kp_signp-gposition.
    rg_signpers-typ = '01'.

    MODIFY zsd_05_kp_sign FROM ve_signpers.
    MODIFY zsd_05_kp_sign FROM rg_signpers.



    "Bemerkungstext speichern
    CLEAR gd_subrc.
    PERFORM save_text TABLES   gt_editortext_fbem
                      USING    gs_kepo-fallnr
                               gs_kepo-gjahr
                               gdc_tdobj
                               gdc_tdid1
                               gdc_langu
                      CHANGING gd_subrc.
    IF gd_subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.


    IF ud_no_msg NE c_true.
      IF gd_cnt_err EQ 0.
        MESSAGE s012(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
      ELSE.
        MESSAGE w013(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
      ENDIF.
    ENDIF.
    gs_kepo-bem_verwarnung = gs_verwarnung-bem.
    gs_kepo-bem_rege = gs_rege-bem.
  ELSEIF gd_delete EQ c_true.
    "Hauptdaten in DBTAB updaten

    MODIFY  zsdtkpkepo FROM gs_kepo.
    IF sy-subrc NE 0.
      gd_cnt_err = gd_cnt_err + 1.
    ENDIF.

    IF ud_no_msg NE c_true.
      IF gd_cnt_err EQ 0.
        MESSAGE s014(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
      ELSE.
        MESSAGE w015(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
      ENDIF.
    ENDIF.

  ENDIF.


  "Fallverwaltung Kehrichtpolizei neu starten
  IF ud_start EQ c_true.
    COMMIT WORK AND WAIT.

    LEAVE TO TRANSACTION sy-tcode.
  ENDIF.
ENDFORM.                    " SAVE_DATA


*&---------------------------------------------------------------------*
*&      Form  TRANSFER_ADDRESS
*&---------------------------------------------------------------------*
*       Debitorenadresse in Fundadresse übernehmen
*----------------------------------------------------------------------*
FORM transfer_address USING us_deb STRUCTURE gs_deb
                   CHANGING cs_kepo STRUCTURE gs_kepo.

  DATA: ld_answer TYPE c.

  CLEAR: gd_str, gd_hnr, gd_plz, gd_ort.


  IF NOT us_deb IS INITIAL.
    CLEAR: gs_kna1, gs_adrc.

    " Debitor lesen für ADRNR ermitteln
    SELECT SINGLE * FROM kna1 INTO gs_kna1
      WHERE kunnr = cs_kepo-kunnr.


    "Akutellste Daten in der ADRC holen
    SELECT SINGLE * FROM adrc INTO gs_adrc
      WHERE addrnumber = gs_kna1-adrnr.

    "Prüfen, ob schon etwas eingetragen wurde
    IF NOT cs_kepo-street IS INITIAL OR NOT cs_kepo-post_code1 IS INITIAL OR
       NOT cs_kepo-city1 IS INITIAL.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = TEXT-t22
          text_question         = TEXT-t23
          text_button_1         = TEXT-p90 "Ja
          text_button_2         = TEXT-p91 "Nein
          display_cancel_button = c_false
          default_button        = '2'
        IMPORTING
          answer                = ld_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      IF ld_answer EQ '1'.
        cs_kepo-street     = gs_adrc-street.
        cs_kepo-house_num1 = gs_adrc-house_num1.
        cs_kepo-post_code1 = gs_adrc-post_code1.
        cs_kepo-city1      = gs_adrc-city1.
      ENDIF.

    ELSE.
      cs_kepo-street     = gs_adrc-street.
      cs_kepo-house_num1 = gs_adrc-house_num1.
      cs_kepo-post_code1 = gs_adrc-post_code1.
      cs_kepo-city1      = gs_adrc-city1.
    ENDIF.

    "Zwischenspeicherung infolge FIELD-Anweisung im Dynpro
    gd_str = cs_kepo-street.
    gd_hnr = cs_kepo-house_num1.
    gd_plz = cs_kepo-post_code1.
    gd_ort = cs_kepo-city1.

  ENDIF.
ENDFORM.                    " TRANSFER_ADDRESS
*&---------------------------------------------------------------------*
*&      Form  SET_FALLWDH
*&---------------------------------------------------------------------*
*       Fallwiederholung prüfen und setzen
*       Nur im Anlegemodus!
*
*       Änderungen
*       11.06.2013, IDSWE: Nur in Anlegemodus deaktiviert
*       21.08.2013, IDTZI: Anpassung auf die Zweijahres-verjährungs-frist
*----------------------------------------------------------------------*
FORM set_fallwdh CHANGING gs_kepo STRUCTURE gs_kepo.
  DATA: ld_kepo TYPE zsdtkpkepo."local DDDData?
  DATA: ld_rec  TYPE i.
  DATA head TYPE TABLE OF zsdtkpkepo.
  DATA head_line LIKE LINE OF head.
  DATA dateplustwo TYPE dats.
  CLEAR: ld_kepo.


  "Prüfung nur, wenn Kundennummer nicht initial ist
  IF NOT gs_kepo-kunnr IS INITIAL.
*    SELECT COUNT( * ) FROM zsdtkpkepo INTO ld_rec
*      WHERE fart   EQ gs_kepo-fart
*        AND kunnr  EQ gs_kepo-kunnr
*        AND fallnr NE gs_kepo-fallnr
*        AND fstat  NE '04' "annulliert
*        AND fdat   LE gs_kepo-fdat
*        AND kverrgnam EQ space. "Keine Verrechnung sind ausgeschlossene Fälle!



    "Selektiere alle Fälle des Debitors, mit der selben Fallart.
    SELECT * FROM zsdtkpkepo INTO head_line WHERE kunnr = gs_kepo-kunnr AND fart = gs_kepo-fart.

      " Rechne auf den gefundenen Fall 2 Jahre dazu
      CALL FUNCTION 'FKK_DTE_ADD_MONTH'
        EXPORTING
          i_datum               = head_line-fdat
          i_nr_of_months_to_add = 24
        IMPORTING
          e_result              = dateplustwo.


      "wenn das gefundene Datum+2Jahre grösser als aktueller Fall
      "Wiederholungsfall liegt vor.
      DATA a TYPE zsd_05_kepo_ver.
      IF gs_kepo-fdat <= dateplustwo AND head_line-fallnr NE gs_kepo-fallnr.
        "Wiederholungsfall
        IF gs_kepo-fwdh = ''. "Wenn wiederholungsfallkennz. vorher noch nicht gesetzt, Gebe Popup Aus
          CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
            EXPORTING
**         TITEL              = ' '
              textline1 = 'Es handelt sich um einen Wiederholungsfall.'
      "       TEXTLINE2 = ' '
**         START_COLUMN       = 25
**         START_ROW          = 6
            .
*
*
        ENDIF.
        gs_kepo-fwdh = 'X'."c_true'.

        "Verwarnung von Vorgängerfall anzeigen
        SELECT SINGLE * INTO a FROM zsd_05_kepo_ver WHERE debitor = gs_kepo-kunnr AND gjahr = head_line-gjahr.
        gs_verwarnung-ver_datum = a-ver_datum.
        gs_verwarnung-ver_anvo = a-ver_anvo.
        gs_verwarnung-ver_andat = a-ver_andat.
        IF ok_code = 'ENTE'.
        ELSE.
          gs_verwarnung-ver_anvo_time = a-ver_anvo_time.
          gs_verwarnung-bem = gs_kepo-bem_verwarnung.
        ENDIF.

        EXIT.
      ELSE.

        IF gs_verwarnung-ver_datum IS INITIAL.
          "Erstfall
          gs_kepo-fwdh = ''."c_false.
          gs_verwarnung-ver_datum = ''."a-ver_datum.
          gs_verwarnung-ver_anvo = ''."a-ver_anvo.
          gs_verwarnung-ver_andat = ''."a-ver_andat.
          gs_verwarnung-ver_anvo_time = ''."a-ver_anvo_time.
          gs_verwarnung-bem = ''."a-bem'.
        ENDIF.
      ENDIF.
    ENDSELECT.
    IF sy-subrc = '4'.
      gs_kepo-fwdh = ' '. "Wenn nichts gefunden, stelle wieder auf initial
    ENDIF.
  ENDIF.
***  ENDIF.
ENDFORM.                    " SET_FALLWDH


*&---------------------------------------------------------------------*
*&      Form  PREPARE_ORDER
*&---------------------------------------------------------------------*
*       Datenaufbereitung für die Auftragserstellung
*----------------------------------------------------------------------*
FORM prepare_order USING ud_test.
  DATA: ld_line  TYPE bapisdtext-text_line,
        ld_text  TYPE string,
        ld_llen  TYPE i VALUE 132,
        ld_datum TYPE sc_daystr.

  CLEAR: gd_test, gs_order_header, gs_order_return, gt_order_return[],
         gs_order_items, gt_order_items[], gs_order_partn, gt_order_partn[],
         gs_order_sched, gt_order_sched[], gs_order_cond, gt_order_cond[],
         gs_order_text, gt_order_text[], ld_line.

  "Testlauf definieren
  gd_test = ud_test.

  gdc_order_doc_type = 'Z878'.".
  "Auftragskopf füllen
  gs_order_header-doc_type   = gdc_order_doc_type.
  gs_order_header-sales_org  = gs_kepo-vkorg.
  gs_order_header-distr_chan = gs_kepo-vtweg.
  gs_order_header-division   = gs_kepo-spart.
  gs_order_header-sales_off  = gs_kepo-vkbur.


  "Partner mit deren Rolle füllen
  IF NOT gs_kepo-kunnr IS INITIAL. "Auftraggeber
    gs_order_partn-partn_role  = gdc_prol_deb.
    gs_order_partn-partn_numb  = gs_kepo-kunnr.
    APPEND gs_order_partn TO gt_order_partn.
  ENDIF.
  IF NOT gs_kepo-kunnrre IS INITIAL. "Abw. Rechnungsempfänger
    CLEAR: gs_order_partn.
    gs_order_partn-partn_role  = gdc_prol_arg.
    gs_order_partn-partn_numb  = gs_kepo-kunnrre.
    APPEND gs_order_partn TO gt_order_partn.
  ENDIF.


  "Zu verrechnendes Material füllen
  LOOP AT gt_matpos INTO gs_order_matpos.
    CLEAR: gs_order_items, gs_order_sched.

    SHIFT gs_order_matpos-matnr RIGHT DELETING TRAILING ' '.
    OVERLAY gs_order_matpos-matnr WITH c_matnr_init.

    gs_order_items-itm_number = gs_order_matpos-posnr.
    gs_order_items-material   = gs_order_matpos-matnr.
    gs_order_items-target_qty = gs_order_matpos-anzahl.
    gs_order_items-short_text = gs_order_matpos-bezei.
    APPEND gs_order_items TO gt_order_items.

    gs_order_sched-itm_number = gs_order_matpos-posnr.
    gs_order_sched-req_qty    = gs_order_matpos-anzahl.
    APPEND gs_order_sched TO gt_order_sched.

  ENDLOOP.


  "Kopfnotiz füllen (VBBK)
  MOVE '0001' TO gs_order_text-text_id.    "Text-ID
  MOVE 'DE'   TO gs_order_text-langu_iso.  "Sprache nach ISO 639
  MOVE '*'    TO gs_order_text-format_col. "Formatspalte

  CASE gs_kepo-fart.
    WHEN '01'. "Blaue Kehrichtsäcke
      IF gs_kepo-fwdh EQ c_true. "Wiederholungsfall
        MOVE 'Wiederholte Bereitstellung eines Gebührensacks zur Unzeit' TO gs_order_text-text_line.
      ELSE.
        MOVE 'Bereitstellung eines Gebührensacks zur Unzeit' TO gs_order_text-text_line.
      ENDIF.
      APPEND gs_order_text TO gt_order_text.

    WHEN '02'. "Schwarze Kehrichtsäcke
      MOVE 'Entsorgung von widerrechtlich deponiertem Abfall' TO gs_order_text-text_line.
      APPEND gs_order_text TO gt_order_text.

    WHEN '03'. "Papier / Karton
      IF gs_kepo-fwdh EQ c_true. "Wiederholungsfall
        MOVE 'Wiederholte Bereitstellung von Papier/Karton zur Unzeit' TO gs_order_text-text_line.
      ELSE.
        MOVE 'Bereitstellung von Papier/Karton zur Unzeit' TO gs_order_text-text_line.
      ENDIF.
      APPEND gs_order_text TO gt_order_text.

    WHEN '04'. "Wilde Deponie
      MOVE 'Entsorgung einer wilden Deponie' TO gs_order_text-text_line.
      APPEND gs_order_text TO gt_order_text.
" MZi neue Fallarten
    WHEN '05'. " QES Schwarze Kehrichtsäcke
      MOVE 'Entsorgung von widerrechtlich deponiertem Abfall' TO gs_order_text-text_line.
      APPEND gs_order_text TO gt_order_text.
    WHEN '06'. " QES Papier / Karton
      IF gs_kepo-fwdh EQ c_true. "Wiederholungsfall
        MOVE 'Wiederholte Bereitstellung von widerrechtlich deponiertem Papier/Karton an Wertstoffsammelstellen ausserhalb der Benutzungszeiten' TO gs_order_text-text_line.
      ELSE.
        MOVE 'Entsorgung von widerrechtlich deponiertem Papier/Karton an Wertstoffsammelstellen ausserhalb der Benutzungszeiten' TO gs_order_text-text_line.
      ENDIF.
      APPEND gs_order_text TO gt_order_text.
    WHEN '07'. " QES Papier / Karton
      IF gs_kepo-fwdh EQ c_true. "Wiederholungsfall
        MOVE 'Wiederholte Bereitstellung von widerrechtlich deponiertem Papier/Karton an Wertstoffsammelstellen ausserhalb der Benutzungszeiten' TO gs_order_text-text_line.
      ELSE.
        MOVE 'Entsorgung von widerrechtlich deponiertem Papier/Karton an Wertstoffsammelstellen ausserhalb der Benutzungszeiten' TO gs_order_text-text_line.
      ENDIF.
      APPEND gs_order_text TO gt_order_text.

  ENDCASE.

**  "Fallnummer
**  CONCATENATE 'Fallnummer:' gs_kepo-fallnr '/' gs_kepo-gjahr INTO gs_order_text-text_line SEPARATED BY space.
**  APPEND gs_order_text TO gt_order_text.

  "Fundadresse und -datum
  CALL FUNCTION 'ZID_FORMAT_DATE'
    EXPORTING
      iv_date           = gs_kepo-fdat
      iv_year_format    = '4'
      iv_month_format   = 'L'
      iv_day_format     = '2'
    IMPORTING
      ev_date_formatted = ld_datum.

  MOVE 'Fundinfo:' TO gs_order_text-text_line.
  CONCATENATE gs_order_text-text_line gs_kepo-street     INTO gs_order_text-text_line SEPARATED BY space.
  CONCATENATE gs_order_text-text_line gs_kepo-house_num1 INTO gs_order_text-text_line SEPARATED BY space.
  CONCATENATE gs_order_text-text_line gs_kepo-post_code1 INTO gs_order_text-text_line SEPARATED BY ', '.
  CONCATENATE gs_order_text-text_line gs_kepo-city1      INTO gs_order_text-text_line SEPARATED BY space.
  CONCATENATE gs_order_text-text_line 'am' ld_datum      INTO gs_order_text-text_line SEPARATED BY space.
  APPEND gs_order_text TO gt_order_text.


ENDFORM.                    " PREPARE_ORDER


*&---------------------------------------------------------------------*
*&      Form  CREATE_ORDER
*&---------------------------------------------------------------------*
*       Erstellen des Auftrages
*----------------------------------------------------------------------*
FORM create_order  USING ud_test.

  "Prüfen, ob Auftrag erstellt werden kann
  CHECK gd_order_dont_create NE c_true.

  DATA: ld_vbeln TYPE vbeln_va.
  CLEAR: gd_order_created, ld_vbeln.

  "Daten ermitteln
  PERFORM prepare_order USING ud_test.


  CHECK NOT gt_order_items[] IS INITIAL AND
        NOT gt_order_partn[] IS INITIAL.

  CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
    EXPORTING
      order_header_in    = gs_order_header
*     BEHAVE_WHEN_ERROR  =
      testrun            = ud_test
    IMPORTING
      salesdocument      = ld_vbeln
    TABLES
      return             = gt_order_return
      order_items_in     = gt_order_items
      order_partners     = gt_order_partn
      order_schedules_in = gt_order_sched
      order_text         = gt_order_text.
*   ORDER_CONDITIONS_IN           =

  PERFORM fill_msg_tab USING 'GT_ORDER_RETURN'.

  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

  IF NOT ld_vbeln IS INITIAL AND ud_test EQ c_false.
    gd_order_created = c_true.

    PERFORM save_order_data USING c_order
                                  ld_vbeln
                         CHANGING gs_auft.
  ENDIF.

  "Meldungstabelle ausgeben
  CALL SCREEN 4001 STARTING AT 15 5 .


ENDFORM.                    " CREATE_ORDER


*&---------------------------------------------------------------------*
*&      Form  SAVE_ORDER_DATA
*&---------------------------------------------------------------------*
*       Vorbereiten und Speichern der Verrechnungsdaten
*----------------------------------------------------------------------*
FORM save_order_data USING ud_type
                           ud_vbeln
                  CHANGING cs_auft.

  DATA: ls_vbak TYPE vbak,
        ls_vbrk TYPE vbrk.

  CLEAR: ls_vbak, ls_vbrk.

  CASE ud_type.
    WHEN c_order. "Auftrag erstellt
      "Wurde der Auftrag erstellt?
      IF gd_order_created EQ c_true.
        CLEAR: gs_auft.

        "Schleife verlassen, sobald Datensatz
        "aus der Tabelle gelesen werden konnte.
        WHILE ls_vbak IS INITIAL.
          SELECT SINGLE * FROM vbak INTO ls_vbak
            WHERE vbeln EQ ud_vbeln.

        ENDWHILE.

        gs_auft-fallnr    = gs_kepo-fallnr.
        gs_auft-gjahr     = gs_kepo-gjahr.
        gs_auft-vbeln_a   = ls_vbak-vbeln.
        gs_auft-vkorg     = gs_kepo-vkorg.
        gs_auft-vtweg     = gs_kepo-vtweg.
        gs_auft-spart     = gs_kepo-spart.
        gs_auft-vkbur     = gs_kepo-vkbur.
        gs_auft-beldat_a  = ls_vbak-audat.
        gs_auft-ernam_a   = ls_vbak-ernam.
        gs_auft-erdat_a   = ls_vbak-erdat.
        gs_auft-erzet_a   = ls_vbak-erzet.
        gs_auft-status_a  = '01'. "erstellt
        gs_auft-statdat_a = ls_vbak-erdat.
        gs_auft-statzet_a = ls_vbak-erzet.

        "In die Datenbank schreiben.
        INSERT zsdtkpauft FROM gs_auft.


        IF sy-subrc EQ 0.
          "Fallstatusänderung speichern
          IF gs_kepo-fstat EQ '01'. "erfasst
            gs_kepo-fstat = '02'. "offen
            MODIFY zsdtkpkepo FROM gs_kepo.
          ENDIF.

          "Meldung vorbereiten
          CLEAR: gs_msg_tab.

*          MESSAGE s040(zsd_05_kepo) WITH ls_vbak-vbeln INTO gs_msg_tab-message.
*          gs_msg_tab-icon = gd_icon_message_s.
*
*          APPEND gs_msg_tab TO gt_msg_tab.
          MESSAGE s040(zsd_05_kepo) WITH ls_vbak-vbeln.

        ELSE.
          "Meldung vorbereiten
          CLEAR: gs_msg_tab.

*          MESSAGE s041(zsd_05_kepo) WITH ls_vbak-vbeln INTO gs_msg_tab-message.
*          gs_msg_tab-icon = gd_icon_message_e.
*
*          APPEND gs_msg_tab TO gt_msg_tab.
          MESSAGE s041(zsd_05_kepo) WITH ls_vbak-vbeln.


        ENDIF.
      ENDIF.
    WHEN c_invo. "Faktura erstellt
      "Wurde die Faktura erstellt?
      IF gd_invo_created EQ c_true.

        "Schleife verlassen, sobald Datensatz
        "aus der Tabelle gelesen werden konnte.
        WHILE ls_vbrk IS INITIAL.
          SELECT SINGLE * FROM vbrk INTO ls_vbrk
            WHERE vbeln EQ ud_vbeln.
        ENDWHILE.


        "Prüfen, ob bereits eine Faktura erstellt wurde
        IF gs_auft-vbeln_f IS INITIAL.
          "Datensatz muss gelöscht werden, und mit den Fakturadaten
          "erneut erstellt werden, da die Belegnummern im Key sind
          DELETE zsdtkpauft FROM gs_auft.

        ELSE.
          "Status bei Fakturawiederholung setzen und speichern
          gs_auft-statdat_a = ls_vbrk-erdat.
          gs_auft-statzet_a = ls_vbrk-erzet.
          gs_auft-status_a  = '99'. "Fakturawiederholung

          MODIFY zsdtkpauft FROM gs_auft.

          "Fakturaspezifische Felder initialisieren
          CLEAR: gs_auft-vbeln_f, gs_auft-beldat_f, gs_auft-ernam_f, gs_auft-erdat_f,
                 gs_auft-erzet_f, gs_auft-netwr_f, gs_auft-waerk_f, gs_auft-stonam_f,
                 gs_auft-stodat_f, gs_auft-stozet_f, gs_auft-status_f, gs_auft-statdat_f,
                 gs_auft-statzet_f.
        ENDIF.


        "Daten füllen
        gs_auft-vbeln_f   = ls_vbrk-vbeln.
        gs_auft-statdat_a = ls_vbrk-erdat.
        gs_auft-statzet_a = ls_vbrk-erzet.
        gs_auft-status_a  = '02'. "fakturiert
        gs_auft-beldat_f  = ls_vbrk-fkdat.
        gs_auft-ernam_f   = ls_vbrk-ernam.
        gs_auft-erdat_f   = ls_vbrk-erdat.
        gs_auft-erzet_f   = ls_vbrk-erzet.
        gs_auft-netwr_f   = ls_vbrk-netwr.
        gs_auft-waerk_f   = ls_vbrk-waerk.
        gs_auft-status_f  = '01'. "offen
        gs_auft-statdat_f = ls_vbrk-erdat.
        gs_auft-statzet_f = ls_vbrk-erzet.


        "In die Datenbank schreiben.
        INSERT zsdtkpauft FROM gs_auft.

        IF sy-subrc EQ 0.
          MESSAGE s044(zsd_05_kepo) WITH ls_vbrk-vbeln.
        ELSE.
          MESSAGE s045(zsd_05_kepo) WITH ls_vbrk-vbeln.
        ENDIF.
      ENDIF.

    WHEN c_canc1. "Auftrag storniert/abgesagt
      gs_auft-stonam_a  = sy-uname.
      gs_auft-stodat_a  = sy-datum.
      gs_auft-stozet_a  = sy-uzeit.
      gs_auft-status_a  = '03'. "storniert
      gs_auft-statdat_a = sy-datum.
      gs_auft-statzet_a = sy-uzeit.

      MODIFY zsdtkpauft FROM gs_auft.

      IF sy-subrc EQ 0.
        MESSAGE s042(zsd_05_kepo) WITH gs_auft-vbeln_a.
      ELSE.
        MESSAGE s043(zsd_05_kepo) WITH gs_auft-vbeln_a.
      ENDIF.

    WHEN c_canc2. "Faktura storniert
      gs_auft-statdat_a = sy-datum.
      gs_auft-statzet_a = sy-uzeit.
      gs_auft-status_a  = '01'. "offen
      gs_auft-stonam_f  = sy-uname.
      gs_auft-stodat_f  = sy-datum.
      gs_auft-stozet_f  = sy-uzeit.
      gs_auft-status_f  = '03'. "storniert
      gs_auft-statdat_f = sy-datum.
      gs_auft-statzet_f = sy-uzeit.

      MODIFY zsdtkpauft FROM gs_auft.

      IF sy-subrc EQ 0.
        MESSAGE s046(zsd_05_kepo) WITH gs_auft-vbeln_f.
      ELSE.
        MESSAGE s047(zsd_05_kepo) WITH gs_auft-vbeln_f.
      ENDIF.
  ENDCASE.



ENDFORM.                    " SAVE_ORDER_DATA


*&---------------------------------------------------------------------*
*&      Form  READ_ORDER_DATA
*&---------------------------------------------------------------------*
*       Lesen der Verrechnungsdaten
*----------------------------------------------------------------------*
FORM read_order_data USING ud_fallnr
                           ud_gjahr.

  CLEAR: gs_auft.

  SELECT * FROM zsdtkpauft INTO gs_auft UP TO 1 ROWS
  WHERE fallnr EQ ud_fallnr
    AND gjahr  EQ ud_gjahr
    ORDER BY vbeln_a DESCENDING
             vbeln_f DESCENDING.
  ENDSELECT.


ENDFORM.                    " READ_ORDER_DATA


*&---------------------------------------------------------------------*
*&      Form  PREPARE_INVOICE
*&---------------------------------------------------------------------*
*       Datenaufbereitung für die Fakturaerstellung
*----------------------------------------------------------------------*
FORM prepare_invoice USING ud_test.

  DATA: ls_vbak TYPE vbak,
        ls_vbap TYPE vbap,
        lt_vbap TYPE TABLE OF vbap.

  CLEAR: ls_vbak, ls_vbap, lt_vbap[],
         gd_test, gs_invo_data , gt_invo_data[], gs_invo_return,
         gt_invo_return[], gs_invo_success, gt_invo_success[].

  "Testlauf definieren
  gd_test = ud_test.

  SELECT SINGLE * FROM vbak INTO ls_vbak
    WHERE vbeln = gs_auft-vbeln_a.

  IF sy-subrc EQ 0.
    SELECT * FROM vbap INTO TABLE lt_vbap
      WHERE vbeln = gs_auft-vbeln_a
        AND abgru EQ space.

  ENDIF.

  LOOP AT lt_vbap INTO ls_vbap.
    CLEAR: gs_invo_data.

    gdc_invo_doc_type = 'Z878'.
    "Verkaufsorganisation u.s.w. inkl Nachrichtenart
    gs_invo_data-salesorg    = ls_vbak-vkorg.
    gs_invo_data-distr_chan  = ls_vbak-vtweg.
    gs_invo_data-division    = ls_vbak-vtweg.
    gs_invo_data-doc_type    = ls_vbak-auart.
    gs_invo_data-ordbilltyp  = gdc_invo_doc_type.

    gs_invo_data-serv_date = gs_kepo-fdat. "'20160101'.

    "Prüfung, ob gewünschtes Fakturadatum eingegeben wurde
    IF gs_auft-beldat_f IS INITIAL.
      gs_invo_data-bill_date   = sy-datum.
    ELSE.
      gs_invo_data-bill_date   = gs_auft-beldat_f.
    ENDIF.

    "Neue Aufbereitung
    gs_invo_data-ref_doc     = ls_vbak-vbeln.
    gs_invo_data-ref_doc_ca  = 'C'.              "Auftrag
    gs_invo_data-ref_item    = ls_vbap-posnr.


    "Alte Aufbereitung
*    gs_invo_data-sold_to     = gs_kepo-kunnr.
*    IF NOT gs_kepo-kunnrre IS INITIAL.
*      gs_invo_data-bill_to   = gs_kepo-kunnrre.
*    ELSE.
*      gs_invo_data-bill_to   = gs_kepo-kunnr.
*    ENDIF.
*    gs_invo_data-price_date  = sy-datum.        "ls_vbak-audat.
*    gs_invo_data-sales_unit  = ls_vbap-vrkme.
*    gs_invo_data-currency    = ls_vbap-waerk.
*    gs_invo_data-country     = gdc_country.
*    gs_invo_data-short_text  = ls_vbap-arktx.
*    gs_invo_data-ref_doc     = ls_vbak-vbeln.
*    gs_invo_data-ref_doc_ca  = 'C'.             "Auftrag
*    gs_invo_data-doc_number  = ls_vbak-vbeln.
*    gs_invo_data-itm_number  = ls_vbap-posnr.
*    gs_invo_data-item        = ls_vbap-posnr.
*    gs_invo_data-no_matmast  = c_false.
*    gs_invo_data-plant       = ls_vbap-werks.

*    SHIFT ls_vbap-matnr RIGHT DELETING TRAILING ' '.
*    OVERLAY ls_vbap-matnr WITH c_matnr_init.
*    gs_invo_data-material    = ls_vbap-matnr.





    APPEND gs_invo_data TO gt_invo_data.
  ENDLOOP.
ENDFORM.                    " PREPARE_INVOICE


*&---------------------------------------------------------------------*
*&      Form  CREATE_INVOICE
*&---------------------------------------------------------------------*
*       Erstellen der Faktura
*----------------------------------------------------------------------*
FORM create_invoice USING ud_test.

  "Prüfen, ob Faktura erstellt werden kann
  CHECK gd_invo_dont_create NE c_true.


  DATA: ld_vbeln TYPE vbeln_vf.
  CLEAR: gd_invo_created, ld_vbeln.

  "Daten ermitteln
  PERFORM prepare_invoice USING ud_test.


  CALL FUNCTION 'BAPI_BILLINGDOC_CREATEMULTIPLE'
    EXPORTING
*     CREATORDATAIN =
      testrun       = ud_test
*     POSTING       =
    TABLES
      billingdatain = gt_invo_data
*     CONDITIONDATAIN =
*     CCARDDATAIN   =
*     TEXTDATAIN    =
*     ERRORS        =
      return        = gt_invo_return
      success       = gt_invo_success.

  PERFORM fill_msg_tab USING 'GT_INVO_RETURN'.

  IF ud_test EQ c_false AND NOT gt_invo_success[] IS INITIAL.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

    CLEAR: gs_invo_success.
    "Erste Zeile ermitteln, um die notwendigen Fakturadaten zu erhalten
    READ TABLE gt_invo_success INDEX 1 INTO gs_invo_success.

    gd_invo_created = c_true.

    ld_vbeln = gs_invo_success-bill_doc.

    PERFORM save_order_data USING c_invo
                                   ld_vbeln
                          CHANGING gs_auft.


*    MESSAGE s045(zsd_05_kepo) WITH ld-vbeln.

  ENDIF.

  "Meldungstabelle ausgeben
  CALL SCREEN 4001 STARTING AT 15 5 .

ENDFORM.                    " CREATE_INVOICE


*&---------------------------------------------------------------------*
*&      Form  CANCEL_INVOICE
*&---------------------------------------------------------------------*
*       Faktura stornieren
*----------------------------------------------------------------------*
FORM cancel_invoice .

  CLEAR:  gs_invo_return, gt_invo_return[], gs_invo_success, gt_invo_success[].


  CALL FUNCTION 'BAPI_BILLINGDOC_CANCEL1'
    EXPORTING
      billingdocument = gs_auft-vbeln_f
*     TESTRUN         =
*     NO_COMMIT       =
*     BILLINGDATE     =
    TABLES
      return          = gt_invo_return
      success         = gt_invo_success.

  IF NOT gt_invo_success[] IS INITIAL.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.

    "Erste Zeile ermitteln, um die notwendigen Fakturadaten zu erhalten
    READ TABLE gt_invo_success INDEX 1 INTO gs_invo_success.

    PERFORM save_order_data USING c_canc2
                                   gs_auft-vbeln_f
                          CHANGING gs_auft.

  ENDIF.



ENDFORM.                    " CANCEL_INVOICE


*&---------------------------------------------------------------------*
*&      Form  CANCEL_ORDER
*&---------------------------------------------------------------------*
*       Auftrag stornieren (Absagegrund setzen)
*----------------------------------------------------------------------*
FORM cancel_order.

  CALL FUNCTION 'SD_WF_ORDER_REJECT'
    EXPORTING
      reason_for_rejection = 'Z6' "kein Bedarf mehr
      sales_order_doc_no   = gs_auft-vbeln_a.

  PERFORM save_order_data USING c_canc1
                                 gs_auft-vbeln_a
                        CHANGING gs_auft.



ENDFORM.                    " CANCEL_ORDER


*&---------------------------------------------------------------------*
*&      Form  FILL_MSG_TAB
*&---------------------------------------------------------------------*
*       Message-Tabelle füllen
*----------------------------------------------------------------------*
FORM fill_msg_tab USING tabname.

  DATA: ld_icon  TYPE char50,
        ld_struc TYPE char50.


  FIELD-SYMBOLS: <table> TYPE STANDARD TABLE,
                 <struc> TYPE any,
                 <field> TYPE any,
                 <icon>  TYPE any.

  CLEAR: gt_msg_tab[].

  ASSIGN (tabname) TO <table>.

  ld_struc = tabname.

*  SHIFT ld_struc LEFT BY 3 PLACES.
*  CONCATENATE 'GS_' ld_struc INTO ld_struc.
  REPLACE 'GT_' WITH 'GS_' INTO ld_struc.

  ASSIGN (ld_struc) TO <struc>.
  CLEAR <struc>.


  LOOP AT <table> ASSIGNING <struc>.
    CLEAR: gs_msg_tab.

    MOVE-CORRESPONDING <struc> TO gs_msg_tab.


    ASSIGN COMPONENT 'TYPE' OF STRUCTURE <struc> TO <field>.
    IF sy-subrc NE 0.
      ASSIGN COMPONENT 'MSGTY' OF STRUCTURE <struc> TO <field>.
    ENDIF.

    CHECK sy-subrc EQ 0.


    CONCATENATE 'GD_ICON_MESSAGE_' <field> INTO ld_icon.
    ASSIGN (ld_icon) TO <icon>.
    IF sy-subrc EQ 0.
      gs_msg_tab-icon = <icon>.
    ENDIF.

    APPEND gs_msg_tab TO gt_msg_tab.

    UNASSIGN <field>.
    UNASSIGN <icon>.

  ENDLOOP.

ENDFORM.                    " FILL_MSG_TAB


*&---------------------------------------------------------------------*
*&      Form  CANCEL_FALL
*&---------------------------------------------------------------------*
*       Fall annullieren
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM cancel_fall USING us_auft STRUCTURE gs_auft
              CHANGING cs_kepo STRUCTURE gs_kepo
                       cd_subrc.

  DATA: ld_answer TYPE c.
  CLEAR: ld_answer.

  IF us_auft IS INITIAL AND cs_kepo-loesch EQ c_false AND cs_kepo-kverrgdat IS INITIAL.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = TEXT-t30
        text_question         = TEXT-t31
        text_button_1         = TEXT-p90 "Ja
        text_button_2         = TEXT-p91 "Nein
        display_cancel_button = c_false
        default_button        = '2'
      IMPORTING
        answer                = ld_answer
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    IF ld_answer EQ '1'.
      cs_kepo-fstat  = '04'. "annulliert
      cs_kepo-aenam  = sy-uname.
      cs_kepo-aedat  = sy-datum.
      cs_kepo-aezet  = sy-uzeit.
      cs_kepo-loesch = c_true.
      cd_subrc       = 0.
    ELSE.
      cd_subrc       = 4.
    ENDIF.

  ELSEIF NOT us_auft IS INITIAL AND cs_kepo-loesch EQ c_false.
    IF us_auft-status_a EQ '03' AND ( us_auft-status_f IS INITIAL OR us_auft-status_f EQ '03' ).
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = TEXT-t30
          text_question         = TEXT-t31
          text_button_1         = TEXT-p90 "Ja
          text_button_2         = TEXT-p91 "Nein
          display_cancel_button = c_false
          default_button        = '2'
        IMPORTING
          answer                = ld_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      IF ld_answer EQ '1'.

        cs_kepo-fstat  = '04'. "annulliert
        cs_kepo-aenam  = sy-uname.
        cs_kepo-aedat  = sy-datum.
        cs_kepo-aezet  = sy-uzeit.
        cs_kepo-loesch = c_true.
        cd_subrc       = 0.
      ELSE.
        cd_subrc       = 4.
      ENDIF.

    ELSE.
      MESSAGE w017(zsd_05_kepo) WITH cs_kepo-fallnr cs_kepo-gjahr.
      cd_subrc = 4.
    ENDIF.

  ELSEIF cs_kepo-loesch EQ c_true.
    MESSAGE w016(zsd_05_kepo) WITH cs_kepo-fallnr cs_kepo-gjahr.
    cd_subrc = 4.
  ENDIF.

ENDFORM.                    " CANCEL_FALL


*&---------------------------------------------------------------------*
*&      Form  SET_KVERRG
*&---------------------------------------------------------------------*
*       Keine Verrechnung setzen / entfernen
*----------------------------------------------------------------------*
FORM set_kverrg  CHANGING cs_kepo STRUCTURE gs_kepo.
  IF cs_kepo-kverrgdat IS INITIAL.
    cs_kepo-kverrgnam = sy-uname.
    cs_kepo-kverrgdat = sy-datum.
  ELSE.
    CLEAR: cs_kepo-kverrgnam, cs_kepo-kverrgdat, cs_kepo-kverrggrd.
  ENDIF.
ENDFORM.                    " SET_KVERRG



*&---------------------------------------------------------------------*
*&      Form  READ_ONLY
*&---------------------------------------------------------------------*
*       Prüfen ob Fall erledigt oder annulliert ist,
*       dann Meldung ausgeben (Nur Anzeige möglich!)
*----------------------------------------------------------------------*
FORM read_only USING ud_no_msg.

  "---- Test-Änderung

  "erledigt, annulliert oder bei Aufruf über anderen Fall vià Batch-Input
  IF gs_kepo-fstat EQ '03' OR gs_kepo-fstat EQ '04' OR sy-binpt EQ c_true.
    IF ud_no_msg NE c_true.
      CASE gs_kepo-fstat.
        WHEN '03'. "erledigt
          MESSAGE w019(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
        WHEN '04'. "annulliert
          MESSAGE w018(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
        WHEN OTHERS.
          "Aufruf über anderen Fall vià Batch-Input
          IF sy-binpt EQ c_true.
            MESSAGE w020(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
          ENDIF.
      ENDCASE.


    ENDIF.

    CLEAR: gd_update.
    gd_show = c_true.
    gd_readonly = c_true.
  ENDIF.
ENDFORM.                    " READ_ONLY


*&---------------------------------------------------------------------*
*&      Form  READ_DEBINFO
*&---------------------------------------------------------------------*
*       Weitere Fälle zu Debitor lesen
*----------------------------------------------------------------------*
FORM read_debinfo .
  IF gd_debinfo_selected EQ c_false AND
   NOT gs_kepo-kunnr IS INITIAL.
    SELECT * FROM zsdtkpkepo INTO TABLE gt_debinfo_kepo
      WHERE kunnr  EQ gs_kepo-kunnr
        AND ( fallnr NE gs_kepo-fallnr OR gjahr NE gs_kepo-gjahr )
      ORDER BY fdat fuzei fallnr gjahr ASCENDING.

    IF sy-subrc EQ 0.
      gd_debinfo_selected = c_true.
    ENDIF.

    LOOP AT gt_debinfo_kepo INTO gs_debinfo_kepo.
      CLEAR: gs_debinfo.

      "Fallnummer und Geschäftsjahr verbinden.
      CONCATENATE gs_debinfo_kepo-fallnr
                  gs_debinfo_kepo-gjahr
             INTO gs_debinfo-fall
                  SEPARATED BY c_hyphen.

      "restliche Felder füllen
      MOVE-CORRESPONDING gs_debinfo_kepo TO gs_debinfo.

      APPEND gs_debinfo TO gt_debinfo.
    ENDLOOP.

  ENDIF.
ENDFORM.                    " READ_DEBINFO


*&---------------------------------------------------------------------*
*&      Form  SHOW_DEBINFO_FALL
*&---------------------------------------------------------------------*
*       Ausgewählter Fall zu Debitorinfo anzeigen
*----------------------------------------------------------------------*
FORM show_debinfo_fall USING ud_fall.
  DATA: ld_fallnr TYPE zsdekpfallnr,
        ld_gjahr  TYPE zgjahr.

  CLEAR: gs_bdc, gt_bdc[], gs_bdc_opt, ld_fallnr, ld_gjahr.

  SPLIT ud_fall AT c_hyphen INTO ld_fallnr ld_gjahr.

  CLEAR gs_bdc.
  gs_bdc-program  = sy-cprog.
  gs_bdc-dynpro   = '1000'.
  gs_bdc-dynbegin = 'X'.
  APPEND gs_bdc TO gt_bdc.

  CLEAR gs_bdc.
  gs_bdc-fnam = 'BDC_CURSOR'.
  gs_bdc-fval = 'ZSDTKPKEPO-FALLNR'.
  APPEND gs_bdc TO gt_bdc.

  CLEAR gs_bdc.
  gs_bdc-fnam = 'ZSDTKPKEPO-FALLNR'.
  gs_bdc-fval = ld_fallnr.
  APPEND gs_bdc TO gt_bdc.

  CLEAR gs_bdc.
  gs_bdc-fnam = 'ZSDTKPKEPO-GJAHR'.
  gs_bdc-fval = ld_gjahr.
  APPEND gs_bdc TO gt_bdc.

  CLEAR gs_bdc.
  gs_bdc-fnam = 'BDC_OKCODE'.
  gs_bdc-fval = '=ENTE'.
  APPEND gs_bdc TO gt_bdc.

  gs_bdc_opt-dismode = 'E'. "Nur Fehler anzeigen

  CALL TRANSACTION sy-tcode USING gt_bdc OPTIONS FROM gs_bdc_opt.
ENDFORM.                    " SHOW_DEBINFO_FALL


*&---------------------------------------------------------------------*
*&      Form  DOCUMENT_OUTPUT
*&---------------------------------------------------------------------*
*       Dokument ausgeben
*----------------------------------------------------------------------*
FORM document_output  USING ud_ok_code.
  CASE ud_ok_code.
    WHEN 'PRNTDOCRG1'.
      PERFORM get_data_rg1_v1 USING c_sfart_rg1.

      PERFORM process_sf_output USING c_sfart_rg1
                                      c_print
                                      'ZSD_05_KEPO_BRIEF2'.
    WHEN 'PDFDOCRG1'.
      PERFORM get_data_rg1_v1 USING c_sfart_rg1.

      PERFORM process_sf_output USING c_sfart_rg1
                                      c_pdf
                                      'ZSD_05_KEPO_BRIEF2'.
    WHEN 'PRNTDOCV1'.
      PERFORM get_data_rg1_v1 USING c_sfart_v1.

      PERFORM process_sf_output USING c_sfart_v1
                                      c_print
                                      'ZSD_05_KEPO_BRIEF2'.
    WHEN 'PDFDOCV1'.
      PERFORM get_data_rg1_v1 USING c_sfart_v1.

      PERFORM process_sf_output USING c_sfart_v1
                                      c_pdf
                                      'ZSD_05_KEPO_BRIEF2'.
  ENDCASE.

ENDFORM.                    " DOCUMENT_OUTPUT


*&---------------------------------------------------------------------*
*&      Form  GET_DATA_RG1_V1
*&---------------------------------------------------------------------*
*       Druckdaten für rechtliches Gehör oder Verfügung zusammenstellen
*
*  Texte und Titel
*  Fallart
*   01     Blaue Kehrichtsäcke
*   02     Schwarze Kehrichtsäcke
*   03     Papier / Karton
*   04     Wilde Deponie
*  Kreis
*   A      Kreis A
*   B      Kreis B
*   C      Kreis C Innenstadt

* Texte in Smartforms
*   Fallart     Kreis 2.Mahnung  3.Mahnung  Textname
*   2. Mahnung
*   01           egal   X                   ZKEPO_2_TEXT_MGBKU
*   02           egal   X                   ZKEPO_2_TEXT_MGEDA
*   04           egal   X                   ZKEPO_2_TEXT_MGEDA
*   03           egal   X                   ZKEPO_2_TEXT_MGBPU

*   Verfügung
*   01           A                X         ZKEPO_2_TEXT_VGEUA
*   01           B                X         ZKEPO_2_TEXT_VGEUA
*   01           C                X         ZKEPO_2_TEXT_VGEUIA
*   02           egal             X         ZKEPO_2_TEXT_VGEDA
*   03           A                X         ZKEPO_2_TEXT_VGEUP
*   03           B                X         ZKEPO_2_TEXT_VGEUP
*   03           C                X         ZKEPO_2_TEXT_VGEUIP
*
*----------------------------------------------------------------------*
FORM get_data_rg1_v1 USING ud_type.

  DATA: ls_vbrk   TYPE vbrk,
        ls_matpos TYPE ty_matpos,
        ls_mat    TYPE zsdtkpmat,
        ls_marb   TYPE zsdtkpmarb,
        ls_knvk   TYPE knvk,
        ls_docpos TYPE ty_docpos,
        ld_doc(2) TYPE n,
        ld_tabix  TYPE sy-tabix,
        ld_plzort TYPE string.

  CLEAR: ls_vbrk, ls_matpos, ls_mat, ls_marb, ls_knvk, gs_sf_header_data, gs_sf_docs_data, gt_sf_docs_data[],
         ls_docpos, ld_doc, ld_tabix, ld_plzort.


  "Kopfdaten zu Faktura lesen
  SELECT SINGLE * FROM vbrk INTO ls_vbrk
    WHERE vbeln EQ gs_auft-vbeln_f.


  gs_sf_header_data-adrnr      = gs_deb-adrnr.
  gs_sf_header_data-fallnr     = gs_kepo-fallnr.
  gs_sf_header_data-funddat    = gs_kepo-fdat.
  gs_sf_header_data-funzeit    = gs_kepo-fuzei.
  gs_sf_header_data-kreis      = gs_kepo-kreis.
  gs_sf_header_data-fart       = gs_kepo-fart.
  gs_sf_header_data-faknr      = gs_auft-vbeln_f.
  gs_sf_header_data-fakdat     = gs_auft-beldat_f.
  gs_sf_header_data-mahn1      = gs_auft-manh1_f.
  gs_sf_header_data-mahn2      = gs_auft-manh2_f.
  gs_sf_header_data-mahn3      = gs_auft-manh3_f.
  gs_sf_header_data-fakbetr    = ls_vbrk-netwr + ls_vbrk-mwsbk.
  gs_sf_header_data-fakbetr20  = gs_sf_header_data-fakbetr + 20.
  gs_sf_header_data-mwst       = ls_vbrk-mwsbk.
  gs_sf_header_data-betromwst  = ls_vbrk-netwr.
  gs_sf_header_data-betrmmwst  = gs_sf_header_data-fakbetr.

  WRITE gs_kepo-fuzei TO gs_sf_header_data-funzeit USING EDIT MASK  '__:__'.


  "Dauer in Minuten rechnen
  gs_sf_header_data-vbminuten = 0.
  LOOP AT gt_matpos INTO ls_matpos.
    SHIFT ls_matpos-matnr RIGHT DELETING TRAILING ' '.
    OVERLAY ls_matpos-matnr WITH c_matnr_init.

    SELECT SINGLE * FROM zsdtkpmat INTO ls_mat
      WHERE matnr = ls_matpos-matnr
        AND fart  = gs_kepo-fart.
    IF sy-subrc = 0.
      gs_sf_header_data-vbminuten = gs_sf_header_data-vbminuten + ( ls_mat-dauer * ls_matpos-anzahl ).
    ENDIF.
  ENDLOOP.


  "Adresse aufbereiten
  CONCATENATE gs_deb-pstlz gs_deb-ort01 INTO ld_plzort SEPARATED BY ' '.
  IF gs_deb-name2 NE ' '.
    CONCATENATE gs_deb-name1 gs_deb-name2 gs_deb-stras ld_plzort INTO gs_sf_header_data-debiadresse SEPARATED BY ','.
  ELSE.
    CONCATENATE gs_deb-name1 gs_deb-stras ld_plzort INTO gs_sf_header_data-debiadresse SEPARATED BY ', '.
  ENDIF.


  " Fundadresse
  CONCATENATE gs_kepo-street gs_kepo-house_num1 INTO gs_sf_header_data-funadr SEPARATED BY ' '.


  " Ansprechpartner für Vor- und Nachname ermitteln
  SELECT SINGLE * FROM knvk INTO ls_knvk
    WHERE kunnr = gs_deb-kunnr.

  " Anrede
  IF gs_deb-anred = 'Herr'.
    gs_sf_header_data-anrede = 'geehrter Herr'.
    gs_sf_header_data-nname1 = ls_knvk-name1.
*    gs_sf_header_data-nname2 = gs_deb-name2.
  ENDIF.
  IF gs_deb-anred = 'Frau'.
    gs_sf_header_data-anrede = 'geehrte Frau'.
    gs_sf_header_data-nname1 = ls_knvk-name1.
*    gs_sf_header_data-nname2 = gs_deb-name2.
  ENDIF.
  IF gs_deb-anred = 'Familie'.
    gs_sf_header_data-anrede = 'geehrte Familie'.
    gs_sf_header_data-nname1 = ls_knvk-name1.
*    gs_sf_header_data-nname2 = gs_deb-name2.
  ENDIF.
  IF gs_deb-anred = ' '
  OR gs_deb-anred = 'Firma'.
    gs_sf_header_data-anrede = 'geehrte Damen und Herren'.
  ENDIF.
  IF ls_knvk-name1     = ' '
  AND gs_deb-anred NE ' '
  AND gs_deb-anred NE 'Firma' .
    gs_sf_header_data-nname1 = gs_deb-name1.
  ENDIF.


  "Tabelle mit Dokumenten
  LOOP AT gt_docpos INTO ls_docpos.
    CLEAR: gs_sf_docs_data.

    "Anzahl Dokumente ermittlen
    ld_doc = ld_doc + ls_docpos-anzahl.

    gs_sf_docs_data-dokanz = ls_docpos-anzahl.
    gs_sf_docs_data-dokart = ls_docpos-docart.
    gs_sf_docs_data-doktxt = ls_docpos-bezei.

    IF ls_docpos-bezei = ' '.
      SELECT SINGLE bezei FROM zsdtkpdocart INTO ls_docpos-bezei
        WHERE docart = ls_docpos-docart
          AND spras  = 'DE'.
      gs_sf_docs_data-doktxt = ls_docpos-bezei.
***      ENDSELECT.
    ENDIF.
    APPEND gs_sf_docs_data TO gt_sf_docs_data.
  ENDLOOP.


  "Dokumententext zusammenstellen
  ld_tabix = sy-tabix.
  CLEAR: gs_sf_header_data-doktxt, gs_sf_docs_data.

  LOOP AT gt_sf_docs_data INTO gs_sf_docs_data.
    SHIFT gs_sf_docs_data-dokanz LEFT DELETING LEADING '0'.
    IF ( sy-tabix = 1 AND  sy-tabix = ld_tabix )
    OR sy-tabix = 1.
      CONCATENATE gs_sf_docs_data-dokanz gs_sf_docs_data-doktxt INTO gs_sf_header_data-doktxt SEPARATED BY space.
    ELSE.
      IF sy-tabix = ld_tabix.
        CONCATENATE gs_sf_header_data-doktxt 'und' INTO gs_sf_header_data-doktxt SEPARATED BY space.
        CONCATENATE gs_sf_header_data-doktxt gs_sf_docs_data-dokanz ' ' gs_sf_docs_data-doktxt INTO gs_sf_header_data-doktxt SEPARATED BY space.
      ELSE.
        CONCATENATE gs_sf_header_data-doktxt ', '  INTO gs_sf_header_data-doktxt.
        CONCATENATE gs_sf_header_data-doktxt gs_sf_docs_data-dokanz ' ' gs_sf_docs_data-doktxt  INTO gs_sf_header_data-doktxt SEPARATED BY space.
      ENDIF.
    ENDIF.
  ENDLOOP.


  "Dokumententyp abhängige Felder füllen
  CASE ud_type.
    WHEN c_sfart_rg1.
      "Mahn- /Druckdatum typabhängig
      gs_sf_header_data-datum = gs_auft-manh2_f.

      "Daten Sachbearbeiter ermitteln
      SELECT SINGLE * FROM zsdtkpmarb INTO ls_marb
        WHERE marb = gs_auft-signpers_rechtg.

      IF sy-subrc = 0.
        gs_sf_header_data-sachb1   = ls_marb-name.
        gs_sf_header_data-sachb2   = ls_marb-funktion.
      ELSE.
        gs_sf_header_data-sachb1   = '?????'.
        gs_sf_header_data-sachb2   = '?????'.
      ENDIF.

      "Brieftitel definieren
      CASE gs_kepo-fart.
        WHEN '01'. " MGBKU
          gs_sf_header_data-brieftitel   = '2. Mahnung/Rechtliches Gehör'.
          gs_sf_header_data-brieftitel2  = 'Gebühr für die Bereitstellung eines Kehrichtsacks zur Unzeit'.
        WHEN '02'. " MGEDA
          gs_sf_header_data-brieftitel   = '2. Mahnung/Rechtliches Gehör'.
          gs_sf_header_data-brieftitel2  = 'Gebühr für die Entsorgung von widerechtlich deponiertem Abfall'.
        WHEN '03'. " MGBPU
          gs_sf_header_data-brieftitel   = '2. Mahnung/Rechtliches Gehör'.
          gs_sf_header_data-brieftitel2  = 'Gebühr für die Bereitstellung von Papier/Karton zur Unzeit'.
        WHEN '04'. " MGEDA
          gs_sf_header_data-brieftitel   = '2. Mahnung/Rechtliches Gehör'.
          gs_sf_header_data-brieftitel2  = 'Gebühr für die Entsorgung von widerechtlich deponiertem Abfall'.
          " MZi neue Fallarten
        WHEN '05'.
          gs_sf_header_data-brieftitel   = '2. Mahnung/Rechtliches Gehör'.
          gs_sf_header_data-brieftitel2  = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Abfall'.
        WHEN '06'.
          gs_sf_header_data-brieftitel   = '2. Mahnung/Rechtliches Gehör'.
          gs_sf_header_data-brieftitel2  = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Papier/Karton an Wertstoffsammelstellen ausserhalb der Benutzungszeiten '.
        WHEN '07'.
          gs_sf_header_data-brieftitel   = '2. Mahnung/Rechtliches Gehör'.
          gs_sf_header_data-brieftitel2  = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Papier/Karton an Wertstoffsammelstellen ausserhalb der Benutzungszeiten '.

      ENDCASE.


    WHEN c_sfart_v1.
      "Mahn- /Druckdatum typabhängig
      gs_sf_header_data-datum = gs_auft-manh3_f.

      "Daten Sachbearbeiter ermitteln
      SELECT SINGLE * FROM zsdtkpmarb INTO ls_marb
        WHERE marb = gs_auft-signpers_verfg.
      IF sy-subrc = 0.
        gs_sf_header_data-sachb1   = ls_marb-name.
        gs_sf_header_data-sachb2   = ls_marb-funktion.
      ELSE.
        gs_sf_header_data-sachb1   = '?????'.
        gs_sf_header_data-sachb2   = '?????'.
      ENDIF.

      "Brieftitel definieren
      gs_sf_header_data-brieftitel    = 'Verfügung'.
      CASE gs_kepo-fart.
        WHEN '01'. "VGEUA  Kreis C VGEUIA
          gs_sf_header_data-brieftitel2 = 'Gebühr für die Entsorgung von zur Unzeit bereitgestelltem Abfall'.

        WHEN '02'. "VGEDA
          gs_sf_header_data-brieftitel2 = 'Gebühr für die Entsorgung von widerechtlich deponiertem Abfall'.

        WHEN '03'. "VGEUP
          gs_sf_header_data-brieftitel2 = 'Gebühr für die Entsorgung von zur Unzeit bereitgestelltem Papier/Karton'.
          IF gs_sf_header_data-kreis = 'C'. " VGEUIP
            gs_sf_header_data-brieftitel2 = 'Gebühr für die Entsorgung von zur Unzeit bereitgestelltem Papier/Karton '.
          ENDIF.

        WHEN '04'. " VGEDA
          gs_sf_header_data-brieftitel2   = 'Gebühr für die Entsorgung von widerechtlich deponiertem Abfall'.

          " MZi neue Fallarten
        WHEN '05'. "VGEDA
          gs_sf_header_data-brieftitel2 = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Abfall'.
        WHEN '06'. "VGEUP
          gs_sf_header_data-brieftitel2 = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Papier/Karton an Wertstoffsammelstellen ausserhalb der Benutzungszeiten'.
        WHEN '07'. "VGEUP
          gs_sf_header_data-brieftitel2 = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Papier/Karton an Wertstoffsammelstellen ausserhalb der Benutzungszeiten'.

      ENDCASE.
  ENDCASE.
ENDFORM.                    " GET_DATA_RG1_V1


*&---------------------------------------------------------------------*
*&      Form  PROCESS_SF_OUTPUT
*&---------------------------------------------------------------------*
*       Dokument mit Dokumentenart und Ausgabeart ausgeben
*----------------------------------------------------------------------*
FORM process_sf_output USING ud_sfart
                             ud_outart
                             ud_sfname.

  DATA: ld_sfname               TYPE tdsfname,
        ld_fbnam                TYPE rs38l_fnam,
        ls_sf_control_params    TYPE ssfctrlop,
        ls_sf_options	          TYPE ssfcompop,
        ls_job_output_info      TYPE ssfcrescl,
        ls_document_output_info TYPE ssfcrespd,
        ls_job_output_options   TYPE ssfcresop,
        lo_idutil               TYPE REF TO zcl_id_util,
        ld_file                 TYPE string,
        ld_path                 TYPE string,
        ld_extens               TYPE string.


  CLEAR: ld_sfname, ld_fbnam, ls_sf_control_params, ls_sf_options, ls_job_output_info,
         ls_document_output_info, ls_job_output_options, lo_idutil, ld_file, ld_path, ld_extens.

  "Funktionsbaustein lesen
  ld_sfname = ud_sfname.
  PERFORM get_fbnam USING    ld_sfname
                    CHANGING ld_fbnam.


  CASE ud_outart.
    WHEN c_print. "Drucken
      CASE ud_sfart.
        WHEN c_sfart_rg1 OR c_sfart_v1.
          ls_sf_options-tdnewid         = 'X'.
          ls_sf_options-tddataset       = 'KEPO'.
          ls_sf_options-tdsuffix1       = 'BRI2'.
          ls_sf_options-tdtitle         = 'Kehrichtpolizei Mahnung'.
          ls_sf_control_params-no_open   = ' '.
          ls_sf_control_params-no_close  = ' '.

          CALL FUNCTION ld_fbnam
            EXPORTING
              ukopfdaten         = gs_sf_header_data
              control_parameters = ls_sf_control_params
              output_options     = ls_sf_options
            TABLES
              udokumente         = gt_sf_docs_data
            EXCEPTIONS
              formatting_error   = 1
              internal_error     = 2
              send_error         = 3
              user_canceled      = 4
              OTHERS             = 5.
      ENDCASE.
    WHEN c_pdf. "PDF-Ausgabe
      CASE ud_sfart.
        WHEN c_sfart_rg1 OR c_sfart_v1.
          IF NOT lo_idutil IS BOUND.
            CREATE OBJECT lo_idutil.
          ENDIF.

          ld_extens = c_pdf.

          ls_sf_control_params-no_dialog = 'X'.
          ls_sf_control_params-getotf    = 'X'.
*          ls_sf_options-tdprinter       = v_e_devtype. ?????????????

          CALL FUNCTION ld_fbnam
            EXPORTING
              ukopfdaten           = gs_sf_header_data
              control_parameters   = ls_sf_control_params
              output_options       = ls_sf_options
            IMPORTING
              document_output_info = ls_document_output_info
              job_output_info      = ls_job_output_info
              job_output_options   = ls_job_output_options
            TABLES
              udokumente           = gt_sf_docs_data
            EXCEPTIONS
              formatting_error     = 1
              internal_error       = 2
              send_error           = 3
              user_canceled        = 4
              OTHERS               = 5.



          "Dialog Datei speichern
          PERFORM save_file USING    'KEPO_DOC'
                                     c_true
                            CHANGING ld_file
                                     ld_path
                                     ld_extens.


          "Datei speichern und öffnen
          lo_idutil->smartforms2pdf(
            EXPORTING
              otfdata    = ls_job_output_info-otfdata
              file_open  = c_true
              datei_name = ld_file
              initial_directory = ld_path
               ).
      ENDCASE.
  ENDCASE.






ENDFORM.                    " PROCESS_SF_OUTPUT


*&---------------------------------------------------------------------*
*&      Form  GET_FBNAM
*&---------------------------------------------------------------------*
*       Funktionsbaustein zu Smarform lesen
*----------------------------------------------------------------------*
FORM get_fbnam  USING    ud_sfname
                CHANGING cd_fbnam.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname = ud_sfname
*     VARIANT  = ' '
*     DIRECT_CALL              = ' '
    IMPORTING
      fm_name  = cd_fbnam
* EXCEPTIONS
*     NO_FORM  = 1
*     NO_FUNCTION_MODULE       = 2
*     OTHERS   = 3
    .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " GET_FBNAM


*&---------------------------------------------------------------------*
*&      Form  SAVE_FILE
*&---------------------------------------------------------------------*
*       Dialog Datei speichern
*
*       Parameter UD_W_O_DIALOG wird verwendet, um den
*       "Speichern unter"-Dialog auszuschliessen. Ist somit nur
*       für die Aufbereitung des Pfades und Dateinamens nützlich.
*----------------------------------------------------------------------*
FORM save_file USING    ud_art
                        ud_w_o_dialog
               CHANGING cd_file
                        cd_path
                        cd_extens.


  DATA: lt_filetable TYPE STANDARD TABLE OF file_table,
        ls_filetable TYPE file_table,

        ld_rc        TYPE i,
        ld_action    TYPE i,
        ld_fname     TYPE string,
        ld_fpath     TYPE string,
        ld_fullp     TYPE string,
        ld_extens    TYPE string,
        ld_date      TYPE sy-datum,
        ld_uzeit     TYPE sy-uzeit.


  CLEAR: lt_filetable[], ls_filetable, ld_rc, ld_action,
         ld_fname, ld_fpath, ld_fullp, ld_extens, ld_date, ld_uzeit.


  ld_date = sy-datum.
  ld_uzeit = sy-uzeit.

  CONCATENATE ld_date ld_uzeit ud_art sy-uname INTO ld_fname SEPARATED BY '_'.
  MOVE gdc_init_folder TO ld_fpath.

  TRANSLATE ld_fname TO UPPER CASE.
  TRANSLATE ld_fpath TO UPPER CASE.

  CONCATENATE ld_fpath ld_fname INTO ld_fullp SEPARATED BY c_backsl.

  IF ud_w_o_dialog EQ c_false.
    IF NOT gr_services IS BOUND.
      CREATE OBJECT gr_services.
    ENDIF.

    gr_services->file_save_dialog(
      EXPORTING
        window_title         = 'Datei speichern unter...'
        default_extension    = cd_extens
        default_file_name    = ld_fullp
*      with_encoding        =
*      file_filter          =
*      initial_directory    =
        prompt_on_overwrite  = 'X'
      CHANGING
        filename             = ld_fname
        path                 = ld_fpath
        fullpath             = ld_fullp
*      user_action          = ld_action
*      file_encoding        =
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3
        OTHERS               = 4 ).

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.

  cd_file = ld_fullp.
  cd_path = ld_fpath.
ENDFORM.                    " SAVE_FILE
