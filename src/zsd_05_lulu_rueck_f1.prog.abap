*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_RUECK_F1
*&---------------------------------------------------------------------*
*======================================================================*
*                   Unterprogramm-Bibliothek
*======================================================================*
FORM u0001_auth_check.
*
*
ENDFORM. "u0001_auth_check.
*----------------------------------------------------------------------*
FORM u0010_get_fakt_dat USING    lw_head  TYPE zsd_05_lulu_hd02.
*
  REFRESH: t_fakt, t_aufz.
  CLEAR:   t_fakt, t_aufz.
*
  SELECT * FROM (w_lulu_fakt) INTO CORRESPONDING FIELDS OF TABLE t_fakt
           WHERE fallnr EQ lw_head-fallnr.
  IF sy-subrc EQ 0.

  ENDIF.
*
ENDFORM. "u0010_get_fakt_dat using    w_head.
*----------------------------------------------------------------------*
FORM u0100_fill_adress CHANGING lw_printline TYPE zsd_05_lulu_printline.
*   ------------------------- Eigentümer-Adresse ---------------------
*   prüfen und ggf. bestücken Eigentümer-Adress-Nummer
  IF lw_printline-eigen_adrnr IS INITIAL.
    IF lw_printline-eigen_kunnr IS INITIAL.
*    dann lassen wir es auch :-)
    ELSE.
*    Eigentümer-Nummer vorhanden, sollt ja eigentlich auch so sein...
      SELECT SINGLE adrnr FROM kna1 INTO lw_printline-eigen_adrnr
             WHERE kunnr EQ lw_printline-eigen_kunnr.
      IF sy-subrc NE 0.
        CLEAR lw_printline-eigen_adrnr.
      ENDIF.
    ENDIF.
  ENDIF.
*   ------------------------- Vertreter-Adresse ----------------------
*   prüfen und ggf. bestücken Vertreter-Adress-Nummer
  IF lw_printline-vertr_adrnr IS INITIAL.
    IF lw_printline-vertr_kunnr IS INITIAL.
*    dann lassen wir es auch :-)
    ELSE.
*    Vertreter-Nummer vorhanden, dann weiter ...
      SELECT SINGLE adrnr FROM kna1 INTO lw_printline-vertr_adrnr
             WHERE kunnr EQ lw_printline-vertr_kunnr.
      IF sy-subrc NE 0.
        CLEAR lw_printline-vertr_adrnr.
      ENDIF.
    ENDIF.
  ENDIF.
*   ------------------------- abw. Rechnungsempfänger-Adresse -------
*   prüfen und ggf. bestücken abw. Rechnungsempfänger-Adress-Nummer
  IF lw_printline-rg_adrnr IS INITIAL.
    IF lw_printline-rg_kunnr IS INITIAL.
*    dann lassen wir es auch :-)
    ELSE.
*    abw.REmpf-Nummer vorhanden, dann weiter ...
      SELECT SINGLE adrnr FROM kna1 INTO lw_printline-rg_adrnr
             WHERE kunnr EQ lw_printline-rg_kunnr.
      IF sy-subrc NE 0.
        CLEAR lw_printline-rg_adrnr.
      ENDIF.
    ENDIF.
  ENDIF.
*
ENDFORM." u0100_fill_printline using w_head.
*----------------------------------------------------------------------*
FORM u0110_fullfill_printline
           CHANGING lw_printline TYPE zsd_05_lulu_printline.
*
  IF lw_printline-fkimg_new EQ 1.
*   Pauschalbetrag wurde fakturiert ...
    BREAK-POINT.
  ENDIF.
*
ENDFORM." u0110_fullfill_printline changing w_printline.
*&---------------------------------------------------------------------*
*&      Form  DATEN_ANZEIGEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM daten_anzeigen .
*  DATA:go_alv TYPE REF TO cl_salv_table,
*       go_columns TYPE REF TO cl_salv_columns_table,
*       go_column TYPE REF TO cl_salv_column_table.
  TRY .
      IF p_fall EQ c_activ.
        CALL METHOD cl_salv_table=>factory
          IMPORTING
            r_salv_table = gr_table
          CHANGING
            t_table      = t_head.

      ELSEIF p_gesuch EQ c_activ.
        CALL METHOD cl_salv_table=>factory
          IMPORTING
            r_salv_table = gr_table
          CHANGING
            t_table      = t_head_g.
*to change the name of the column in ALV.
*      go_column ?= go_columns->get_column( 'OUN' ).
*      go_column->set_long_text( 'OUn'(010) ).
**to set a field as a hotspot
*      go_column ?= go_columns->get_column( 'EBELN' ).
*      go_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
**to hide a column in ALV
*      go_column ?= go_columns->get_column( 'MEINS' ).
*      go_column->set_visible( ABAP_FALSE ).
      ENDIF.
    CATCH cx_salv_msg.

  ENDTRY.
*... §3 Functions
*... §3.1 activate ALV generic Functions
*... §3.2 include own functions by setting own status
  gr_table->set_screen_status(
    pfstatus      =  'ZSALV_STANDARD'
    report        =  gs_test-repid
    set_functions = gr_table->c_functions_all ).

*... set the columns technical
  DATA: lr_columns TYPE REF TO cl_salv_columns,
        lr_column  TYPE REF TO cl_salv_column_table.

  lr_columns = gr_table->get_columns( ).
  lr_columns->set_optimize( gc_true ).

  PERFORM set_columns_technical USING lr_columns.

*... §4 set hotspot column
  TRY.
      lr_column ?= lr_columns->get_column( 'OBJ_KEY' ).
      lr_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

*... §6 register to the events of cl_salv_table
  DATA: lr_events TYPE REF TO cl_salv_events_table.

  lr_events = gr_table->get_event( ).

  CREATE OBJECT gr_events.

*... §6.1 register to the event USER_COMMAND
  SET HANDLER gr_events->on_user_command FOR lr_events.
*... §6.2 register to the event BEFORE_SALV_FUNCTION
  SET HANDLER gr_events->on_before_salv_function FOR lr_events.
*... §6.3 register to the event AFTER_SALV_FUNCTION
  SET HANDLER gr_events->on_after_salv_function FOR lr_events.
*... §6.4 register to the event DOUBLE_CLICK
  SET HANDLER gr_events->on_double_click FOR lr_events.
*... §6.5 register to the event LINK_CLICK
  SET HANDLER gr_events->on_link_click FOR lr_events.

*... set list title
  DATA: lr_display_settings TYPE REF TO cl_salv_display_settings,
        l_title TYPE lvc_title.

  l_title = text-t02.
  lr_display_settings = gr_table->get_display_settings( ).
  lr_display_settings->set_list_header( l_title ).

*... §7 display the table
  gr_table->display( ).




ENDFORM.                    " DATEN_ANZEIGEN
*&---------------------------------------------------------------------*
*&      Form  SHOW_INVOICE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ROW  text
*      -->P_COLUMN  text
*      -->P_TEXT_I07  text
*----------------------------------------------------------------------*
FORM show_invoice  USING  i_row    TYPE i
                          i_column TYPE lvc_fname
                          i_text   TYPE string.

  DATA: l_row_string TYPE string,
        l_col_string TYPE string,
        l_row        TYPE char128.

  WRITE i_row TO l_row LEFT-JUSTIFIED.


  READ TABLE t_head INTO w_head INDEX i_row.

  SELECT * FROM zsd_05_lulu_fk02 INTO TABLE gt_fk02 WHERE fallnr = w_head-fallnr.




  TRY.
      cl_salv_table=>factory(
        IMPORTING
          r_salv_table = gr_table
        CHANGING
          t_table      = gt_fk02 ).
    CATCH cx_salv_msg.                                  "#EC NO_HANDLER
  ENDTRY.

*... §3 Functions
*... §3.1 activate ALV generic Functions
*... §3.2 include own functions by setting own status
  gr_table->set_screen_status(
    pfstatus      =  'ZSALV_FAKTUREN'
    report        =  gs_test-repid
    set_functions = gr_table->c_functions_all ).

*... set the columns technical
  DATA: lr_columns TYPE REF TO cl_salv_columns,
        lr_column  TYPE REF TO cl_salv_column_table.

  lr_columns = gr_table->get_columns( ).
  lr_columns->set_optimize( gc_true ).

  PERFORM set_columns_technical USING lr_columns.

*... §4 set hotspot column
  TRY.
      lr_column ?= lr_columns->get_column( 'OBJ_KEY' ).
      lr_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

**... §6 register to the events of cl_salv_table
*  data: lr_events type ref to cl_salv_events_table.
*
*  lr_events = gr_table->get_event( ).
*
*  create object gr_events.
*
**... §6.1 register to the event USER_COMMAND
*  set handler gr_events->on_user_command for lr_events.
**... §6.2 register to the event BEFORE_SALV_FUNCTION
*  set handler gr_events->on_before_salv_function for lr_events.
**... §6.3 register to the event AFTER_SALV_FUNCTION
*  set handler gr_events->on_after_salv_function for lr_events.
**... §6.4 register to the event DOUBLE_CLICK
*  set handler gr_events->on_double_click for lr_events.
**... §6.5 register to the event LINK_CLICK
*  set handler gr_events->on_link_click for lr_events.

*... set list title
  DATA: lr_display_settings TYPE REF TO cl_salv_display_settings,
        l_title TYPE lvc_title.

  l_title = text-t03.
  lr_display_settings = gr_table->get_display_settings( ).
  lr_display_settings->set_list_header( l_title ).

*... §7 display the table
  gr_table->display( ).

ENDFORM.                    " SHOW_INVOICE
*&---------------------------------------------------------------------*
*&      Form  SET_COLUMNS_TECHNICAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LR_COLUMNS  text
*----------------------------------------------------------------------*
FORM set_columns_technical   USING ir_columns TYPE REF TO cl_salv_columns.

  DATA: lr_column TYPE REF TO cl_salv_column.

  TRY.
      lr_column = ir_columns->get_column( 'MANDT' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'FLOAT_FI' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'STRING_F' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'XSTRING' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'INT_FIEL' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'HEX_FIEL' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'DROPDOWN' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'TAB_INDEX' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.
ENDFORM.                    " SET_COLUMNS_TECHNICAL
*&---------------------------------------------------------------------*
*&      Form  SHOW_FUNCTION_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_SALV_FUNCTION  text
*      -->P_TEXT_I08  text
*----------------------------------------------------------------------*
FORM show_function_info  USING      i_function TYPE salv_de_function
                              i_text     TYPE string.

*  data: l_string type string.
*
*  concatenate i_text i_function into l_string separated by space.
*
*  message i000(0k) with l_string.


ENDFORM.                    " SHOW_FUNCTION_INFO
*&---------------------------------------------------------------------*
*&      Form  KORR_BANK_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_T_HEAD  text
*----------------------------------------------------------------------*
FORM korr_bank_data  CHANGING p_t_head .
  DATA: lv_fallnr TYPE c LENGTH 8.

  LOOP AT t_head INTO w_head.
    IF w_head-bankn_ausz(2) = '01'.
      w_head-esrnr_ausz = w_head-bankn_ausz .
      CLEAR w_head-bankn_ausz .
      CLEAR w_head-bankl_ausz.

    ELSEIF w_head-bankn_ausz(2) = 'CH'.
      CLEAR w_head-bankl_ausz.
      CONDENSE w_head-bankn_ausz NO-GAPS.
    ELSE.
      IF w_head-bankl_ausz  = ''.
        w_head-bankl_ausz = '9000'.
      ENDIF.
    ENDIF.
    IF w_head-sgtxt_ausz = ''.
      PERFORM get_obj_addr USING w_head CHANGING w_head-sgtxt_ausz.

      lv_fallnr = w_head-fallnr.
      SHIFT lv_fallnr LEFT DELETING LEADING '0'.

      CONCATENATE lv_fallnr '/' w_head-sgtxt_ausz INTO w_head-sgtxt_ausz SEPARATED BY space.

    ENDIF.
    CONCATENATE  w_head-stadtteil
        w_head-parzelle
        w_head-objekt INTO
        w_head-obj_key.
    MODIFY  t_head FROM w_head.
  ENDLOOP.

  IF p_gesuch EQ c_activ.
    LOOP AT t_head_g INTO w_head_g.
      READ TABLE t_head INTO w_head WITH KEY mandt = w_head_g-mandt fallnr = w_head_g-fallnr .
      IF sy-subrc = 0.
        w_head_g-bankn_ausz = w_head-bankn_ausz.
        w_head_g-bankl_ausz = w_head-bankl_ausz.
        w_head_g-esrnr_ausz = w_head-esrnr_ausz.
        w_head_g-sgtxt_ausz = w_head-sgtxt_ausz.
        w_head_g-obj_key = w_head-obj_key.
        MODIFY  t_head_g FROM w_head_g.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF p_tstkb = abap_false.
* Modify DB
    IF p_fall EQ c_activ.
      MODIFY (w_lulu_head) FROM TABLE t_head.
    ELSEIF p_gesuch EQ c_activ.
      MODIFY (w_lulu_head) FROM TABLE t_head_g.
    ENDIF.
  ENDIF.
ENDFORM.                    " KORR_BANK_DATA
*&---------------------------------------------------------------------*
*&      Form  GET_OBJ_ADDR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_obj_addr  USING w_lulu_head STRUCTURE zsd_05_lulu_hd02 CHANGING lv_sgtxt.
  DATA: ls_objekt TYPE zsd_05_objekt.

  CLEAR: gv_obj_addr, ls_objekt.

  SELECT SINGLE * FROM zsd_05_objekt INTO ls_objekt
    WHERE stadtteil = w_lulu_head-stadtteil
      AND parzelle  = w_lulu_head-parzelle
      AND objekt    = w_lulu_head-objekt.

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

  lv_sgtxt = gv_obj_addr.
ENDFORM.                    " GET_OBJ_ADDR
*&---------------------------------------------------------------------*
*&      Form  GET_FAKTURA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_HEAD  text
*      -->P_T_FK02  text
*      -->P_T_AUSZ  text
*----------------------------------------------------------------------*
FORM get_faktura_f
                    TABLES pt_fk02 STRUCTURE zsd_05_lulu_fk02
                           pt_aufz STRUCTURE zsd_05_kehr_aufz
USING  pw_hd02 TYPE zsd_05_lulu_hd02
      CHANGING pw_rc TYPE sy-subrc.
  CLEAR pw_rc.

  FIELD-SYMBOLS: <fs_fk02> TYPE zsd_05_lulu_fk02.

  SELECT * FROM zsd_05_lulu_fk02 INTO TABLE pt_fk02
    WHERE fallnr = pw_hd02-fallnr.

  IF sy-dbcnt GT 0.

    SORT pt_fk02 BY vbeln.
    LOOP AT pt_fk02 ASSIGNING <fs_fk02>.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = <fs_fk02>-vbeln
        IMPORTING
          output = <fs_fk02>-vbeln.
    ENDLOOP.

    SELECT * FROM zsd_05_kehr_aufz INTO TABLE pt_aufz FOR ALL ENTRIES IN pt_fk02
      WHERE faknr = pt_fk02-vbeln
      AND kennz = 'B'.

* Nullwerte können nicht weiter verarbeitet werden
    LOOP AT pt_aufz INTO w_aufz WHERE rubtr_brt = 0 OR  vgubtr_bru  = 0.
      w_rc = 4.
    ENDLOOP.
  ELSE.
    w_rc = 4.

  ENDIF.

ENDFORM.                    " GET_FAKTURA
*&---------------------------------------------------------------------*
*&      Form  GET_FAKTURA_G
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_HEAD  text
*      -->P_T_FK02  text
*      -->P_T_AUSZ  text
*----------------------------------------------------------------------*
FORM get_faktura_g  TABLES
                           pt_fakt STRUCTURE zsd_05_lulu_fakt
                           pt_aufz STRUCTURE zsd_05_kehr_aufz
                      USING pw_head TYPE zsd_05_lulu_head
                                  CHANGING pw_rc TYPE sy-subrc.
  FIELD-SYMBOLS: <fs_fakt> TYPE zsd_05_lulu_fakt.
  CLEAR pw_rc.
  SELECT * FROM zsd_05_lulu_fakt INTO TABLE pt_fakt
    WHERE fallnr = pw_head-fallnr.

  IF sy-dbcnt GT 0.
*
    LOOP AT pt_fakt ASSIGNING <fs_fakt>.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = <fs_fakt>-vbeln
        IMPORTING
          output = <fs_fakt>-vbeln.
    ENDLOOP.

    SORT pt_fakt BY vbeln.
    SELECT * FROM zsd_05_kehr_aufz INTO TABLE pt_aufz FOR ALL ENTRIES IN pt_fakt
      WHERE faknr = pt_fakt-vbeln
      AND kennz = 'B'.

* Nullwerte können nicht weiter verarbeitet werden
    LOOP AT pt_aufz INTO w_aufz WHERE rubtr_brt = 0 OR  vgubtr_bru  = 0.
      w_rc = 4.
    ENDLOOP.
  ELSE.
    w_rc = 4.
  ENDIF.

ENDFORM.                    " GET_FAKTURA_G
*&---------------------------------------------------------------------*
*&      Form  INITIALIZE_TABLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initialize_tables .
  REFRESH: t_fakt, t_fk02, t_aufz, bdcdata.
ENDFORM.                    " INITIALIZE_TABLES
*&---------------------------------------------------------------------*
*&      Form  BDCDATA_FILL_F
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_FAKT  text
*      -->P_T_AUFZ  text
*      <--P_W_HEAD  text
*----------------------------------------------------------------------*
FORM bdcdata_fill_f  TABLES   pt_fakt STRUCTURE zsd_05_lulu_fk02

                              pt_aufz STRUCTURE zsd_05_kehr_aufz
                     CHANGING pw_head TYPE zsd_05_lulu_hd02.
  DATA: lv_wrbtr TYPE wrbtr.
  DATA: lv_betrag TYPE c LENGTH 20.
  DATA: lv_sgtxt_r TYPE c LENGTH 50.
  DATA: lv_sgtxt_v TYPE c LENGTH 50.
  DATA: lv_datum TYPE c LENGTH 10.
  DATA: lv_ct TYPE i.
  DATA: lv_land TYPE c LENGTH 2.
  DATA: lv_pstlz TYPE pstlz.

  REFRESH bdcdata.

  CLEAR lv_ct.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=PAYM'.
  PERFORM bdc_field       USING 'RF05A-BUSCS'
                                'R'.

  PERFORM bdc_field       USING 'INVFO-ACCNT'
                                '871'. "fix

  WRITE pw_head-vfgdt TO lv_datum DD/MM/YYYY.
  PERFORM bdc_field       USING 'INVFO-BLDAT'
                                lv_datum.
  WRITE p_datum TO lv_datum DD/MM/YYYY.
  PERFORM bdc_field       USING 'INVFO-BUDAT'
                                lv_datum.
  PERFORM bdc_field       USING 'INVFO-XBLNR'
                              pw_head-fallnr.

* tbd Berechnen
  CLEAR lv_wrbtr.
  LOOP AT pt_aufz INTO w_aufz.
    lv_wrbtr = lv_wrbtr + w_aufz-rubtr_brt + w_aufz-vgubtr_bru.
  ENDLOOP.
  WRITE lv_wrbtr TO lv_betrag LEFT-JUSTIFIED.
  pw_head-wrbtr_ausz = lv_betrag.

*  SHIFT lv_wrbtr LEFT DELETING LEADING space.
  PERFORM bdc_field       USING 'INVFO-WRBTR'
                               lv_betrag. "'              140'.

  PERFORM bdc_field       USING 'INVFO-WAERS'
                                'CHF'.
  PERFORM bdc_field       USING 'INVFO-XMWST'
                                'X'. "?
  PERFORM bdc_field       USING 'INVFO-SGTXT'
                                'Rückerstattung K-GG 2011-2012'.

  IF NOT pw_head-esrnr_ausz IS   INITIAL.
*  IF p_esr = 'X'.
    PERFORM bdc_field       USING 'INVFO-ESRNR'
                                  pw_head-esrnr_ausz. "'01-200000-7'.
    PERFORM bdc_field       USING 'INVFO-ESRRE'
                                pw_head-esrre_ausz. " '423684503030000007994'.
*  ENDIF.
  ENDIF.

  PERFORM bdc_dynpro      USING 'SAPLFCPD' '0100'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'BSEC-PSTLZ'.
  IF pw_head-bankn_ausz(2) = 'CH'.
*  IF p_iban = 'X'.
*  okcode bei IBAN
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  'IBAN'.
  ELSE.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=GO'.
  ENDIF.
  PERFORM bdc_field       USING 'BSEC-SPRAS'
                                'DE'.



  PERFORM bdc_field       USING 'BSEC-NAME1'
                                pw_head-name1_ausz. "'Gobatec AG'.
  PERFORM bdc_field       USING 'BSEC-NAME2'
                               pw_head-name2_ausz. "'Gobatec AG'.
  PERFORM bdc_field       USING 'BSEC-STRAS'
                                pw_head-stras_ausz."'Güterstrasse 15'.
*  PERFORM bdc_field       USING 'BSEC-PFACH'
*                                '347'.
  PERFORM bdc_field       USING 'BSEC-ORT01'
                                pw_head-ort1_ausz."'Bern'.

  IF  pw_head-pstlz_ausz(1) CN '0123456789'.
    SPLIT pw_head-pstlz_ausz AT '-' INTO lv_land lv_pstlz.
  ELSE.
    lv_pstlz = pw_head-pstlz_ausz.
    lv_land = 'CH'.
  ENDIF.

  PERFORM bdc_field       USING 'BSEC-PSTLZ'
                                 lv_pstlz.
*                               pw_head-pstlz_ausz.          " '3008'.

  PERFORM bdc_field       USING 'BSEC-LAND1'
                                 lv_land.
*                                'CH'.
  PERFORM bdc_field       USING 'BSEC-BANKS'
                                'CH'.
  IF pw_head-bankn_ausz(2) NE   'CH'.
    PERFORM bdc_field       USING 'BSEC-BANKL'
                                pw_head-bankl_ausz. "'9000'.
    PERFORM bdc_field       USING 'BSEC-BANKN'
                                pw_head-bankn_ausz. "'30-63958-8'.

  ENDIF.
  PERFORM bdc_field       USING 'BSEC-BKREF'
                                pw_head-sgtxt_ausz(20). "'Gobatec AG'.

*  PERFORM bdc_dynpro      USING 'SAPLSPO1' '0600'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=OPT1'.
  IF pw_head-bankn_ausz(2)  = 'CH'.
    PERFORM bdc_dynpro      USING 'SAPLIBMA' '0200'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'IBAN01'.

    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=SWITCH'.

    PERFORM bdc_dynpro      USING 'SAPLIBMA' '0200'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'IBAN00'.

    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=ENTR'.
    PERFORM bdc_field       USING 'IBAN00'
                                 pw_head-bankn_ausz. " 'CH2109000000306387169'.

    PERFORM bdc_dynpro      USING 'SAPLIBMA' '0200'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'IBAN00'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=ENTR'.

    PERFORM bdc_dynpro      USING 'SAPLFCPD' '0100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=GO'.
*    PERFORM bdc_dynpro      USING 'SAPLSPO1' '0600'.
*    PERFORM bdc_field       USING 'BDC_OKCODE'
*                                  '=OPT1'.
    PERFORM bdc_field       USING 'BSEC-BKREF'
                              pw_head-sgtxt_ausz(20). "'Gobatec AG'.
  ENDIF.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '/00'.
* Loop über die Fakturen und KEHR-AUSZ
  LOOP AT pt_aufz INTO w_aufz.
* Sequenz Rückerstattungsbetrag netto
    PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=0005'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'. "?
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'ACGL_ITEM-STATE(01)'.
    PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)'
                                  'X'.


    PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '/00'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'ACGL_ITEM-GSBER(01)'.
    PERFORM bdc_field       USING 'ACGL_ITEM-HKONT(01)'
                                   p_saknr.   "SCD 20140326
*                                  '2006876'. "fix
*      SHIFT w_aufz-rubtr LEFT DELETING LEADING space.
    CLEAR lv_betrag.
    WRITE w_aufz-rubtr_brt TO lv_betrag LEFT-JUSTIFIED.
    PERFORM bdc_field       USING 'ACGL_ITEM-WRBTR(01)'
                                  lv_betrag . "'               40'.

* Gesuche 'A0' und 'A1'
    PERFORM bdc_field       USING 'ACGL_ITEM-MWSKZ(01)'
                                  w_aufz-mwskz. "'A0'.
    WRITE sy-datum TO lv_datum DD/MM/YYYY.
    PERFORM bdc_field       USING 'ACGL_ITEM-VALUT(01)'
                                  lv_datum."Buchungsdatun oder RKRDT?
    CLEAR lv_sgtxt_r.
    CONCATENATE pw_head-eigen_kunnr ': ' 'KGG' w_aufz-verr_datum(4) INTO lv_sgtxt_r SEPARATED BY space.
    PERFORM bdc_field       USING 'ACGL_ITEM-SGTXT(01)'
                                 lv_sgtxt_r. "   'Rückerstattung K-GG 2008, Gobatec'. "generieren
    PERFORM bdc_field       USING 'ACGL_ITEM-GSBER(01)'
                                  '870'. "fix

    lv_ct = lv_ct + 1.

    IF  lv_ct MOD 3  = 0.
      PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '=0005'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
      PERFORM bdc_field       USING 'BDC_CURSOR'
                                    'ACGL_ITEM-STATE(01)'.
      PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)'
                                    'X'.

      PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '/00'.
      CLEAR lv_ct.
    ENDIF.

* Sequenz Vergütungszins

    PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=0005'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'ACGL_ITEM-STATE(01)'.
    PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)'
                                  'X'.



    PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '/00'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'ACGL_ITEM-GSBER(01)'.
    PERFORM bdc_field       USING 'ACGL_ITEM-HKONT(01)'
                                   p_saknr.   "SCD 20140326
*                                  '2006876'. "fix

    CLEAR lv_betrag.
    WRITE w_aufz-vgubtr_bru TO lv_betrag LEFT-JUSTIFIED.

    PERFORM bdc_field       USING 'ACGL_ITEM-WRBTR(01)'
                                  lv_betrag. "'               20'.
    PERFORM bdc_field       USING 'ACGL_ITEM-MWSKZ(01)'
                                  w_aufz-vgz_mwskz. "'V2'.
    WRITE sy-datum TO lv_datum DD/MM/YYYY.
    PERFORM bdc_field       USING 'ACGL_ITEM-VALUT(01)'
                                 lv_datum. "Buchungsdatun oder RKRDT?
    CLEAR lv_sgtxt_v.
    CONCATENATE pw_head-eigen_kunnr ': ' 'Vergütungszins' w_aufz-verr_datum(4) INTO lv_sgtxt_v SEPARATED BY space.
    PERFORM bdc_field       USING 'ACGL_ITEM-SGTXT(01)'
                                   lv_sgtxt_v. "  "generieren
    PERFORM bdc_field       USING 'ACGL_ITEM-GSBER(01)'
                                  '870'.

    lv_ct = lv_ct + 1.

    IF  lv_ct MOD 3  = 0.
      PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '=0005'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
      PERFORM bdc_field       USING 'BDC_CURSOR'
                                    'ACGL_ITEM-STATE(01)'.
      PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)'
                                    'X'.

      PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '/00'.
      CLEAR lv_ct.
    ENDIF.

*  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=0005'. "NEUE ZEILE
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'ACGL_ITEM-STATE(01)'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)' "CURSOR auf 1. Zeile setzen
*                                'X'.
*
*
*  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '/00'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'ACGL_ITEM-GSBER(01)'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-HKONT(01)'
*                                '2006876'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-WRBTR(01)'
*                                '               60'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-MWSKZ(01)'
*                                'AA'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-VALUT(01)'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-SGTXT(01)'
*                                'Rückerstattung K-GG 2007, Gobatec'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-GSBER(01)'
*                                '870'.

  ENDLOOP. " KEHR_AUFZ
  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=BP'. "Buchen
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'ACGL_ITEM-HKONT(04)'.
  DATA: opt TYPE ctu_params.

  opt-defsize = 'X'.
  opt-dismode = ctumode.
  opt-nobinpt = 'X'.
  CALL TRANSACTION 'FV60' USING bdcdata OPTIONS FROM opt.
  IF sy-subrc <> 0.
    PERFORM open_group.
    PERFORM bdc_transaction USING 'FV60'.
    PERFORM close_group.
    pw_head-status = 'F'. "Fehler in Batch-Verarbeitung
    CLEAR pw_head-aszdt.
* Implement suitable error handling here
  ELSE.
*perform close_group.
    DATA: docno TYPE belnr_d.
    GET PARAMETER ID 'BLP' FIELD docno.
    pw_head-belnr = docno.
    pw_head-aszdt = sy-datum.

    CLEAR docno.
  ENDIF.
ENDFORM.                    " BDCDATA_FILL_F
*&---------------------------------------------------------------------*
*&      Form  BDCDATA_FILL_G
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_T_FAKT  text
*      -->P_T_AUFZ  text
*      <--P_W_HEAD_G  text
*----------------------------------------------------------------------*
FORM bdcdata_fill_g  TABLES    pt_fakt STRUCTURE zsd_05_lulu_fakt
                              pt_aufz STRUCTURE zsd_05_kehr_aufz
                     CHANGING pw_head_g TYPE zsd_05_lulu_head.
  DATA: lv_wrbtr TYPE wrbtr.
  DATA: lv_betrag TYPE c LENGTH 20.
  DATA: lv_sgtxt_r TYPE c LENGTH 50.
  DATA: lv_sgtxt_v TYPE c LENGTH 50.
  DATA: lv_datum TYPE c LENGTH 10.
  DATA: lv_ct TYPE i.
  DATA: lv_land TYPE c LENGTH 2.
  DATA: lv_pstlz TYPE pstlz.

  CLEAR lv_ct.

  REFRESH bdcdata.

  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=PAYM'.
  PERFORM bdc_field       USING 'RF05A-BUSCS'
                                'R'.

  PERFORM bdc_field       USING 'INVFO-ACCNT'
                                '871'. "fix

  WRITE pw_head_g-vfgdt TO lv_datum DD/MM/YYYY.
  PERFORM bdc_field       USING 'INVFO-BLDAT'
                                lv_datum.
  WRITE p_datum TO lv_datum DD/MM/YYYY.
  PERFORM bdc_field       USING 'INVFO-BUDAT'
                                lv_datum.
  PERFORM bdc_field       USING 'INVFO-XBLNR'
                                pw_head_g-fallnr.
* tbd Berechnen
  CLEAR lv_wrbtr.
  LOOP AT pt_aufz INTO w_aufz.
    lv_wrbtr = lv_wrbtr + w_aufz-rubtr_brt + w_aufz-vgubtr_bru.
  ENDLOOP.
  WRITE lv_wrbtr TO lv_betrag LEFT-JUSTIFIED.
  pw_head_g-wrbtr_ausz = lv_betrag.

  PERFORM bdc_field       USING 'INVFO-WRBTR'
                               lv_betrag. "'              140'.

  PERFORM bdc_field       USING 'INVFO-WAERS'
                                'CHF'.
  PERFORM bdc_field       USING 'INVFO-XMWST'
                                'X'. "?
  PERFORM bdc_field       USING 'INVFO-SGTXT'
                              'Rückerstattung K-GG 2007-2010'.

  IF NOT pw_head_g-esrnr_ausz IS   INITIAL.
*  IF p_esr = 'X'.
    PERFORM bdc_field       USING 'INVFO-ESRNR'
                                  pw_head_g-esrnr_ausz. "'01-200000-7'.
    PERFORM bdc_field       USING 'INVFO-ESRRE'
                                pw_head_g-esrre_ausz. " '423684503030000007994'.
*  ENDIF.
  ENDIF.

  PERFORM bdc_dynpro      USING 'SAPLFCPD' '0100'.
  PERFORM bdc_field       USING 'BDC_CURSOR'
                                'BSEC-PSTLZ'.
  IF pw_head_g-bankn_ausz(2) = 'CH'.
*  IF p_iban = 'X'.
*  okcode bei IBAN
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  'IBAN'.
  ELSE.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=GO'.
  ENDIF.
  PERFORM bdc_field       USING 'BSEC-SPRAS'
                                'DE'.
  PERFORM bdc_field       USING 'BSEC-NAME1'
                                pw_head_g-name1_ausz. "'Gobatec AG'.
  PERFORM bdc_field       USING 'BSEC-NAME2'
                               pw_head_g-name2_ausz. "'Gobatec AG'.
  PERFORM bdc_field       USING 'BSEC-STRAS'
                                pw_head_g-stras_ausz."'Güterstrasse 15'.
*  PERFORM bdc_field       USING 'BSEC-PFACH'
*                                '347'.
  PERFORM bdc_field       USING 'BSEC-ORT01'
                                pw_head_g-ort1_ausz."'Bern'.

  IF  pw_head_g-pstlz_ausz(1) CN '0123456789'.
    SPLIT pw_head_g-pstlz_ausz AT '-' INTO lv_land lv_pstlz.
  ELSE.
    lv_pstlz = pw_head_g-pstlz_ausz.
    lv_land = 'CH'.
  ENDIF.

  PERFORM bdc_field       USING 'BSEC-PSTLZ'
*                               pw_head_g-pstlz_ausz.        " '3008'.
                                lv_pstlz.
  PERFORM bdc_field       USING 'BSEC-LAND1'
*                                'CH'.
                                lv_land.
  PERFORM bdc_field       USING 'BSEC-BANKS'
                                'CH'.
  IF pw_head_g-bankn_ausz(2) NE   'CH'.
    PERFORM bdc_field       USING 'BSEC-BANKL'
                                pw_head_g-bankl_ausz. "'9000'.
    PERFORM bdc_field       USING 'BSEC-BANKN'
                                pw_head_g-bankn_ausz. "'30-63958-8'.



*  PERFORM bdc_dynpro      USING 'SAPLSPO1' '0600'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=OPT1'.
  ENDIF.
  PERFORM bdc_field       USING 'BSEC-BKREF'
                                pw_head_g-sgtxt_ausz(20). "'Gobatec AG'.

  IF pw_head_g-bankn_ausz(2)  = 'CH'.
    PERFORM bdc_dynpro      USING 'SAPLIBMA' '0200'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'IBAN01'.

    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=SWITCH'.

    PERFORM bdc_dynpro      USING 'SAPLIBMA' '0200'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'IBAN00'.

    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=ENTR'.
    PERFORM bdc_field       USING 'IBAN00'
                                 pw_head_g-bankn_ausz. " 'CH2109000000306387169'.

    PERFORM bdc_dynpro      USING 'SAPLIBMA' '0200'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'IBAN00'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=ENTR'.

    PERFORM bdc_dynpro      USING 'SAPLFCPD' '0100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=GO'.
*    PERFORM bdc_dynpro      USING 'SAPLSPO1' '0600'.
*    PERFORM bdc_field       USING 'BDC_OKCODE'
*                                  '=OPT1'.
    PERFORM bdc_field       USING 'BSEC-BKREF'
                              pw_head_g-sgtxt_ausz(20). "'Gobatec AG'.
  ENDIF.
  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '/00'.
* Loop über die Fakturen und KEHR-AUSZ
  LOOP AT pt_aufz INTO w_aufz.
* Sequenz Rückerstattungsbetrag netto
    PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=0005'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'. "?
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'ACGL_ITEM-STATE(01)'.
    PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)'
                                  'X'.


    PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '/00'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'ACGL_ITEM-GSBER(01)'.
    PERFORM bdc_field       USING 'ACGL_ITEM-HKONT(01)'
                                  p_saknr. "SCD 20140326
*                                  '2006876'. "fix
    clear lv_betrag.
    WRITE w_aufz-rubtr_brt TO lv_betrag LEFT-JUSTIFIED.
    PERFORM bdc_field       USING 'ACGL_ITEM-WRBTR(01)'
                                  lv_betrag. "'               40'.

* Gesuche 'A0' und 'A1'
    PERFORM bdc_field       USING 'ACGL_ITEM-MWSKZ(01)'
                                  w_aufz-mwskz. "'A0'.
    WRITE sy-datum TO lv_datum DD/MM/YYYY.
    PERFORM bdc_field       USING 'ACGL_ITEM-VALUT(01)'
                                  lv_datum."Buchungsdatun oder RKRDT?
    CLEAR lv_sgtxt_r.
    CONCATENATE pw_head_g-eigen_kunnr ': ' 'KGG' w_aufz-verr_datum(4) INTO lv_sgtxt_r SEPARATED BY space.
    PERFORM bdc_field       USING 'ACGL_ITEM-SGTXT(01)'
                                 lv_sgtxt_r. "   'Rückerstattung K-GG 2008, Gobatec'. "generieren
    PERFORM bdc_field       USING 'ACGL_ITEM-GSBER(01)'
                                  '870'. "fix

    lv_ct = lv_ct + 1.

    IF  lv_ct MOD 3  = 0.
      PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '=0005'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
      PERFORM bdc_field       USING 'BDC_CURSOR'
                                    'ACGL_ITEM-STATE(01)'.
      PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)'
                                    'X'.

      PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '/00'.
      CLEAR lv_ct.
    ENDIF.




* Sequenz Vergütungszins

    PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '=0005'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'ACGL_ITEM-STATE(01)'.
    PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)'
                                  'X'.



    PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
    PERFORM bdc_field       USING 'BDC_OKCODE'
                                  '/00'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
    PERFORM bdc_field       USING 'BDC_CURSOR'
                                  'ACGL_ITEM-GSBER(01)'.
    PERFORM bdc_field       USING 'ACGL_ITEM-HKONT(01)'
                                   p_saknr.   "SCD 20140326
*                                  '2006876'. "fix
    CLEAR lv_betrag.
    WRITE w_aufz-vgubtr_bru TO lv_betrag LEFT-JUSTIFIED.
    PERFORM bdc_field       USING 'ACGL_ITEM-WRBTR(01)'
                                  lv_betrag. "'               20'.
    PERFORM bdc_field       USING 'ACGL_ITEM-MWSKZ(01)'
                                  w_aufz-vgz_mwskz. "'V2'.
    WRITE sy-datum TO lv_datum DD/MM/YYYY.
    PERFORM bdc_field       USING 'ACGL_ITEM-VALUT(01)'
                                  lv_datum. "Buchungsdatun oder RKRDT?
    CLEAR lv_sgtxt_v.
    CONCATENATE pw_head_g-eigen_kunnr ': ' 'Vergütungszins' w_aufz-verr_datum(4) INTO lv_sgtxt_v SEPARATED BY space.
    PERFORM bdc_field       USING 'ACGL_ITEM-SGTXT(01)'
                                   lv_sgtxt_v. "  "generieren
    PERFORM bdc_field       USING 'ACGL_ITEM-GSBER(01)'
                                  '870'.

    lv_ct = lv_ct + 1.
    IF  lv_ct MOD 3  = 0.
      PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '=0005'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
      PERFORM bdc_field       USING 'BDC_CURSOR'
                                    'ACGL_ITEM-STATE(01)'.
      PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)'
                                    'X'.

      PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
      PERFORM bdc_field       USING 'BDC_OKCODE'
                                    '/00'.
      CLEAR lv_ct  .
    ENDIF.
*  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '=0005'. "NEUE ZEILE
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'ACGL_ITEM-STATE(01)'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-MARKSP(01)' "CURSOR auf 1. Zeile setzen
*                                'X'.
*
*
*  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
*  PERFORM bdc_field       USING 'BDC_OKCODE'
*                                '/00'.
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'ACGL_ITEM-GSBER(01)'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-HKONT(01)'
*                                '2006876'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-WRBTR(01)'
*                                '               60'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-MWSKZ(01)'
*                                'AA'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-VALUT(01)'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-SGTXT(01)'
*                                'Rückerstattung K-GG 2007, Gobatec'.
*  PERFORM bdc_field       USING 'ACGL_ITEM-GSBER(01)'
*                                '870'.

  ENDLOOP. " KEHR_AUFZ
  PERFORM bdc_dynpro      USING 'SAPMF05A' '1100'.
  PERFORM bdc_field       USING 'BDC_OKCODE'
                                '=BP'. "Buchen
*  PERFORM bdc_field       USING 'INVFO-ZFBDT'
*                                '26.09.2013'.
*  PERFORM bdc_field       USING 'INVFO-ZTERM'
*                                'ZB05'.
*  PERFORM bdc_field       USING 'INVFO-ZBD1T'
*                                '30'.
*  PERFORM bdc_field       USING 'BDC_CURSOR'
*                                'ACGL_ITEM-HKONT(04)'.
  DATA: opt TYPE ctu_params.

  opt-defsize = 'X'.
  opt-dismode = ctumode.
  opt-nobinpt = 'X'.
  CALL TRANSACTION 'FV60' USING bdcdata OPTIONS FROM opt.
  IF sy-subrc <> 0.
    PERFORM open_group.
    PERFORM bdc_transaction USING 'FV60'.
    PERFORM close_group.
    pw_head_g-status = 'F'. "Fehler in Batch-Verarbeitung
    CLEAR   pw_head_g-aszdt.
* Implement suitable error handling here
  ELSE.
*perform close_group.
    DATA: docno TYPE belnr_d.
    GET PARAMETER ID 'BLP' FIELD docno.
    pw_head_g-belnr = docno.
    pw_head_g-aszdt = sy-datum.

    CLEAR docno.
  ENDIF.





ENDFORM.                    " BDCDATA_FILL_G


*----------------------------------------------------------------------*
*   close dataset                                                      *
*----------------------------------------------------------------------*
FORM close_dataset USING p_dataset.
  CLOSE DATASET p_dataset.
ENDFORM.                    "CLOSE_DATASET

*----------------------------------------------------------------------*
*   create batchinput session                                          *
*   (not for call transaction using...)                                *
*----------------------------------------------------------------------*
FORM open_group.
  IF session = 'X'.
    SKIP.
    WRITE: /(20) 'Create group'(i01), group.
    SKIP.
*   open batchinput group
    CALL FUNCTION 'BDC_OPEN_GROUP'
      EXPORTING
        client   = sy-mandt
        group    = group
        user     = user
        keep     = keep
        holddate = holddate.
    WRITE: /(30) 'BDC_OPEN_GROUP'(i02),
            (12) 'returncode:'(i05),
                 sy-subrc.
  ENDIF.
ENDFORM.                    "OPEN_GROUP

*----------------------------------------------------------------------*
*   end batchinput session                                             *
*   (call transaction using...: error session)                         *
*----------------------------------------------------------------------*
FORM close_group.
  IF session = 'X'.
*   close batchinput group
    CALL FUNCTION 'BDC_CLOSE_GROUP'.
    WRITE: /(30) 'BDC_CLOSE_GROUP'(i04),
            (12) 'returncode:'(i05),
                 sy-subrc.
  ELSE.
    IF e_group_opened = 'X'.
      CALL FUNCTION 'BDC_CLOSE_GROUP'.
      WRITE: /.
      WRITE: /(30) 'Fehlermappe wurde erzeugt'(i06).
      e_group_opened = ' '.
    ENDIF.
  ENDIF.
ENDFORM.                    "CLOSE_GROUP

*----------------------------------------------------------------------*
*        Start new transaction according to parameters                 *
*----------------------------------------------------------------------*
FORM bdc_transaction USING tcode.
  DATA: l_mstring(480).
  DATA: l_subrc LIKE sy-subrc.
* batch input session
  IF session = 'X'.
    CALL FUNCTION 'BDC_INSERT'
      EXPORTING
        tcode     = tcode
      TABLES
        dynprotab = bdcdata.
*    IF smalllog <> 'X'.
*      WRITE: / 'BDC_INSERT'(i03),
*               tcode,
*               'returncode:'(i05),
*               sy-subrc,
*               'RECORD:',
*               sy-index.
*    ENDIF.
* call transaction using
  ELSE.
*    REFRESH messtab.
*    CALL TRANSACTION tcode USING bdcdata
*                     MODE   ctumode
*                     UPDATE cupdate
*                     MESSAGES INTO messtab.
*    l_subrc = sy-subrc.
*    IF smalllog <> 'X'.
*      WRITE: / 'CALL_TRANSACTION',
*               tcode,
*               'returncode:'(i05),
*               l_subrc,
*               'RECORD:',
*               sy-index.
*      LOOP AT messtab.
*        MESSAGE ID     messtab-msgid
*                TYPE   messtab-msgtyp
*                NUMBER messtab-msgnr
*                INTO l_mstring
*                WITH messtab-msgv1
*                     messtab-msgv2
*                     messtab-msgv3
*                     messtab-msgv4.
*        WRITE: / messtab-msgtyp, l_mstring(250).
*      ENDLOOP.
*      SKIP.
  ENDIF.
** Erzeugen fehlermappe ************************************************
*    IF l_subrc <> 0 AND e_group <> space.
*      IF e_group_opened = ' '.
*        CALL FUNCTION 'BDC_OPEN_GROUP'
*          EXPORTING
*            client   = sy-mandt
*            group    = e_group
*            user     = e_user
*            keep     = e_keep
*            holddate = e_hdate.
*        e_group_opened = 'X'.
*      ENDIF.
*      CALL FUNCTION 'BDC_INSERT'
*        EXPORTING
*          tcode     = tcode
*        TABLES
*          dynprotab = bdcdata.
*    ENDIF.
*  ENDIF.
  REFRESH bdcdata.
ENDFORM.                    "BDC_TRANSACTION

*----------------------------------------------------------------------*
*        Start new screen                                              *
*----------------------------------------------------------------------*
FORM bdc_dynpro USING program dynpro.
  CLEAR bdcdata.
  bdcdata-program  = program.
  bdcdata-dynpro   = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.                    "BDC_DYNPRO

*----------------------------------------------------------------------*
*        Insert field                                                  *
*----------------------------------------------------------------------*
FORM bdc_field USING fnam fval.
*  IF fval <> nodata.
  CLEAR bdcdata.
  bdcdata-fnam = fnam.
  bdcdata-fval = fval.
  APPEND bdcdata.
*  ENDIF.
ENDFORM.                    "BDC_FIELD
