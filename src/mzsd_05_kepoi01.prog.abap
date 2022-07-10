*&---------------------------------------------------------------------*
*&  Include           MZSD_05_KEPOI01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_1000 INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
*
    WHEN 'BACK'.
      LEAVE PROGRAM.
*
    WHEN 'CANC'.
      LEAVE PROGRAM.
*
    WHEN 'EXIT'.
      LEAVE PROGRAM.
  ENDCASE.

ENDMODULE.                 " EXIT_COMMAND_1000  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_2000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_2000 INPUT.
  ok_code = sy-ucomm.

  CASE ok_code.
    WHEN 'ENTE'.
      "Adresse zu Debitor lesen
      PERFORM read_address USING gs_kepo-kunnr
                           CHANGING gs_deb.

      "Adresse zu abw. Rechnungsempfänger lesen
      PERFORM read_address USING gs_kepo-kunnrre
                           CHANGING gs_arg.

    WHEN 'WEIT'.
      "Adresse zu Debitor lesen
      PERFORM read_address USING gs_kepo-kunnr
                           CHANGING gs_deb.

      "Adresse zu abw. Rechnungsempfänger lesen
      PERFORM read_address USING gs_kepo-kunnrre
                           CHANGING gs_arg.

      CALL SCREEN 3000.

    WHEN 'DEBADM_DEB'.
      PERFORM admin_customer USING gs_kepo-kunnr
                                   c_false.

    WHEN 'DEBADM_ARG'.
      PERFORM admin_customer USING gs_kepo-kunnrre
                                   c_false.

*    WHEN 'PICK'.
*      CLEAR: gd_fieldname, gd_fval255.
*      GET CURSOR FIELD gd_fieldname VALUE gd_fval255.
*
*      CHECK NOT gd_fval255 IS INITIAL.
*
*      CASE gd_fieldname.
*        WHEN 'GS_DEBINFO-FALL'.
*          PERFORM show_debinfo_fall USING gd_fval255.
*      ENDCASE.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_2000  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1000 INPUT.
  ok_code = sy-ucomm.

  CASE ok_code.
    WHEN 'ANLE'.
      mode = 'AEND'.
      CLEAR: gd_show, gd_update, gd_delete, gs_kepo-fallnr, gs_kepo-gjahr.
      gd_create = c_true.
      CALL SCREEN 2000.
    WHEN 'ANZE' OR 'ENTE'.
      CLEAR: gd_create, gd_update, gd_delete.
      gd_show = c_true.
      mode = 'ANZE'.
      "-----20110413, IDSWE, Readonly-Unterprogramm-----
      "Prüfen ob Fall erledigt oder annulliert ist, dann Meldung ausgeben (Nur Anzeige möglich!)

      "IDDRI1 - 14.12.2015
      "---- PERFORM read_only auskommentiert, wird für das Anzeigen eines Falles nicht benötigt
      " PERFORM read_only USING c_false.


      CALL SCREEN 3000.
    WHEN 'AEND'.
      mode = 'AEND'.
      CLEAR: gd_create, gd_show, gd_delete.
      gd_update = c_true.

      "-----20110413, IDSWE, Readonly-Unterprogramm-----
      "Prüfen ob Fall erledigt oder annulliert ist, dann Meldung ausgeben (Nur Anzeige möglich!)
      PERFORM read_only USING c_false.


      CALL SCREEN 3000.
    WHEN 'ADM_UPD'. "Fallinfos pflegen
      CLEAR: gd_create, gd_show, gd_delete, gd_readonly.
      gd_update = c_true.

      "-----20110413, IDSWE, Readonly-Unterprogramm-----
      "Prüfen ob Fall erledigt oder annulliert ist, dann Meldung ausgeben (Nur Anzeige möglich!)
      "==> Für das Bearbeiten von Fallinfos wird der Fall geöffnet.
      "    Untenstehendes PERFORM wird hier nicht mehr ausgefüht!
      "PERFORM read_only USING c_false.


      CALL SCREEN 3000.
    WHEN 'DELE'.
      CLEAR: gd_create, gd_show, gd_update, gd_subrc.
      gd_delete = c_true.

      PERFORM cancel_fall USING gs_auft
                       CHANGING gs_kepo
                                gd_subrc.

      IF gd_subrc EQ 0.
        PERFORM save_data USING c_true
                                c_false.
      ENDIF.

    WHEN 'Q_ZC1'. "Zulagenkontrolle auswerten
      CALL SCREEN 3100.


  ENDCASE.

ENDMODULE.                 " USER_COMMAND_1000  INPUT

*&SPWIZARD: INPUT MODULE FOR TS 'TS_ADMIN'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GETS ACTIVE TAB
MODULE ts_admin_active_tab_get INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN c_ts_admin-tab1.
      g_ts_admin-pressed_tab = c_ts_admin-tab1.
    WHEN c_ts_admin-tab2.
      g_ts_admin-pressed_tab = c_ts_admin-tab2.
    WHEN c_ts_admin-tab3.
      g_ts_admin-pressed_tab = c_ts_admin-tab3.
    WHEN c_ts_admin-tab4.
      g_ts_admin-pressed_tab = c_ts_admin-tab4.
    WHEN c_ts_admin-tab5.
      g_ts_admin-pressed_tab = c_ts_admin-tab5.
    WHEN c_ts_admin-tab6.
      g_ts_admin-pressed_tab = c_ts_admin-tab6.
    WHEN c_ts_admin-tab7.
      g_ts_admin-pressed_tab = c_ts_admin-tab7.
    WHEN c_ts_admin-tab8.
      g_ts_admin-pressed_tab = c_ts_admin-tab8.
    WHEN OTHERS.
*&SPWIZARD:      DO NOTHING
  ENDCASE.
ENDMODULE.                    "TS_ADMIN_ACTIVE_TAB_GET INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_3000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_3000 INPUT.
  ok_code = sy-ucomm.

  CLEAR: gd_cnt_err.

  CASE ok_code.
    WHEN 'WDH'.
      PERFORM check_wiederholung.

    WHEN 'ANLE' OR 'AEND' OR 'ANZE'.
      PERFORM set_mode USING ok_code.
    WHEN 'SAVE'.
      PERFORM save_data USING c_false
                              c_false.

      "Nach dem Sichern ausgeben wenn es sich um einen Wiederholungsfall handlet.
*      if GS_KEPO-FWDH = 'X'.
*      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
*        EXPORTING
**         TITEL              = ' '
*          textline1          = 'Es handelt sich um einen Wiederholungsfall.'
**         TEXTLINE2          = ' '
**         START_COLUMN       = 25
**         START_ROW          = 6
*                .
*      endif.

      "Nach dem Sichern vom Anlege- in den Änderungsmodus wechseln.
      IF gd_create EQ c_true.
        CLEAR: gd_create.
        gd_update = c_true.
      ENDIF.



    WHEN 'DEBADM_DEB'.
      IF gd_create EQ c_true OR gd_update EQ c_true.
        PERFORM admin_customer USING gs_kepo-kunnr
                                     c_false.
      ELSE.
        PERFORM admin_customer USING gs_kepo-kunnr
                             c_true.
      ENDIF.

      "Erneut Adresse lesen, da allenfalls geändert wurde
      WAIT UP TO 1 SECONDS. "WAIT, damit es den aktualisierten Debitor liest
      PERFORM read_address USING gs_kepo-kunnr
                     CHANGING gs_deb.

    WHEN 'DEBADM_OLD'.
      PERFORM admin_customer USING gs_kepo-kunnr_old
                           c_true.


    WHEN 'DEBADM_ARG'.
      IF gd_create EQ c_true OR gd_update EQ c_true.
        PERFORM admin_customer USING gs_kepo-kunnrre
                                     c_false.
      ELSE.
        PERFORM admin_customer USING gs_kepo-kunnrre
                             c_true.
      ENDIF.

      "Erneut Adresse lesen, da allenfalls geändert wurde
      WAIT UP TO 1 SECONDS. "WAIT, damit es den aktualisierten Debitor liest
      PERFORM read_address USING gs_kepo-kunnrre
                     CHANGING gs_arg.


    WHEN 'DELE'.
      CLEAR: gd_create, gd_show, gd_update, gd_subrc.
      gd_delete = c_true.

      PERFORM cancel_fall USING gs_auft
                       CHANGING gs_kepo
                                gd_subrc.

      IF gd_subrc EQ 0.
        PERFORM save_data USING c_true
                                c_false.
      ENDIF.

    WHEN 'PRNTDOCRG1'.
      PERFORM document_output USING ok_code.
    WHEN 'PDFDOCRG1'.
      PERFORM document_output USING ok_code.
    WHEN 'PRNTDOCV1'.
      PERFORM document_output USING ok_code.
    WHEN 'PDFDOCV1'.
      PERFORM document_output USING ok_code.

    WHEN 'EWA_DISP'.
      "Entsorgungsauftrag anzeigen
      DATA: lv_ordernr TYPE eordernr.
      CLEAR: lv_ordernr.

      SELECT SINGLE ordernr FROM ewa_order_object INTO lv_ordernr
        WHERE pobjnr = gs_kepo-ewa_order_obj.

      SET PARAMETER ID 'EORDERNR' FIELD lv_ordernr.
      CALL TRANSACTION 'EWAORDER'.
  ENDCASE.


ENDMODULE.                 " USER_COMMAND_3000  INPUT
*&---------------------------------------------------------------------*
*&      Module  SET_GJAHR  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_gjahr INPUT.
  CASE c_true.
    WHEN gd_create.
      gs_kepo-gjahr = gs_kepo-fdat(4).
    WHEN gd_update.
      IF gs_kepo-fdat(4) NE gs_kepo-gjahr.
        MESSAGE e030(zsd_05_kepo) WITH gs_kepo-gjahr.
      ENDIF.
  ENDCASE.
ENDMODULE.                 " SET_GJAHR  INPUT
*&---------------------------------------------------------------------*
*&      Module  GET_EXTPATH  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_extpath INPUT.

  DATA: ld_wtitle   TYPE string,
        ld_initfold TYPE string,
        ld_selfold  TYPE string.

  ld_wtitle = 'Dokumentenablage'.
  ld_initfold = gdc_init_folder.


  IF NOT gr_services IS BOUND.
    CREATE OBJECT gr_services.
  ENDIF.



  gr_services->directory_browse(
    EXPORTING
      window_title         = ld_wtitle
      initial_folder       = ld_initfold
    CHANGING
      selected_folder      = ld_selfold
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4 ).

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  gs_kepo-extpath = ld_selfold.

ENDMODULE.                 " GET_EXTPATH  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_3001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_3001 INPUT.
  ok_code = sy-ucomm.

  DATA: ls_path TYPE string.

  CASE ok_code.
    WHEN 'OPENPATH'.
      IF NOT gr_services IS BOUND.
        CREATE OBJECT gr_services.
      ENDIF.

      ls_path = gs_kepo-extpath.

      CALL METHOD cl_gui_frontend_services=>execute
        EXPORTING
*         document               =
          application            = 'explorer.exe'
          parameter              = ls_path
*         default_directory      = gs_kepo-extpath
*         maximized              =
*         minimized              =
*         synchronous            =
          operation              = 'OPEN'
        EXCEPTIONS
          cntl_error             = 1
          error_no_gui           = 2
          bad_parameter          = 3
          file_not_found         = 4
          path_not_found         = 5
          file_extension_unknown = 6
          error_execute_failed   = 7
          synchronous_failed     = 8
          not_supported_by_gui   = 9
          OTHERS                 = 10.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
  ENDCASE.



ENDMODULE.                 " USER_COMMAND_3001  INPUT
*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_3000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_3000 INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'BACK'.
      IF gd_create EQ c_true.
        CALL SCREEN 2000.
      ELSE.
        PERFORM set_mode USING ok_code.
*        LEAVE TO TRANSACTION sy-tcode.
      ENDIF.
    WHEN 'CANC'.
*      LEAVE PROGRAM.
      PERFORM set_mode USING ok_code.
*      LEAVE TO TRANSACTION sy-tcode.
    WHEN 'EXIT'.
      PERFORM set_mode USING ok_code.
*      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.                 " EXIT_COMMAND_3000  INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TC_MATPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MODIFY TABLE
MODULE tc_matpos_modify INPUT.
  "Marker setzen Position geändert
  gs_matpos-action = c_modify.

  MODIFY gt_matpos
    FROM gs_matpos
    INDEX tc_matpos-current_line.
ENDMODULE.                    "TC_MATPOS_MODIFY INPUT

*&SPWIZARD: INPUT MODUL FOR TC 'TC_MATPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MARK TABLE
MODULE tc_matpos_mark INPUT.
  DATA: g_tc_matpos_wa2 LIKE LINE OF gt_matpos.
  IF tc_matpos-line_sel_mode = 1
  AND gs_matpos-flag = c_true.
    LOOP AT gt_matpos INTO g_tc_matpos_wa2
      WHERE flag = c_true.
      g_tc_matpos_wa2-flag = ''.
      MODIFY gt_matpos
        FROM g_tc_matpos_wa2
        TRANSPORTING flag.
    ENDLOOP.
  ENDIF.
  MODIFY gt_matpos
    FROM gs_matpos
    INDEX tc_matpos-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TC_MATPOS_MARK INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TC_MATPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE tc_matpos_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_MATPOS'
                              'GT_MATPOS'
                              'GS_MATPOS'
                              'FLAG'
                              'ACTION'
                              'DELABLE'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TC_MATPOS_USER_COMMAND INPUT

*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_2000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_2000 INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'BACK' OR 'EXIT' OR 'CANC'.
      LEAVE TO TRANSACTION sy-tcode.
  ENDCASE.
ENDMODULE.                 " EXIT_COMMAND_2000  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_3004  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_3004 INPUT.


ENDMODULE.                 " USER_COMMAND_3004  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_FALL_EXISTS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_fall_exists INPUT.
  CLEAR gd_subrc.

  gs_kepo-fallnr = zsdtkpkepo-fallnr.
  gs_kepo-gjahr  = zsdtkpkepo-gjahr.

  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'ENTE' OR 'ANZE' OR 'AEND' OR 'DELE' OR 'ADM_UPD'.
      IF NOT gs_kepo-fallnr IS INITIAL AND NOT gs_kepo-gjahr IS INITIAL.
        PERFORM fall_exists USING gs_kepo-fallnr
                                  gs_kepo-gjahr
                                  c_true
                         CHANGING gd_subrc.

        IF gd_subrc NE 0.
          MESSAGE e001(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
        ENDIF.
      ELSE.
        MESSAGE e000(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr.
      ENDIF.
  ENDCASE.


ENDMODULE.                 " CHECK_FALL_EXISTS  INPUT
*&---------------------------------------------------------------------*
*&      Module  SET_EINW1_VAL  INPUT
*&---------------------------------------------------------------------*
*       Einwandsverarbeitung
*----------------------------------------------------------------------*
MODULE set_einw1_val INPUT.
  CASE c_true.
    WHEN gd_einw1_1. "angenommen
      gs_kepo-einw1verarb = 'N'.
*      gs_kepo-einw1sdat = sy-datum.
    WHEN gd_einw1_2. "abgelehnt
      gs_kepo-einw1verarb = 'L'.
*      gs_kepo-einw1sdat = sy-datum.
  ENDCASE.

  IF gd_einw1_1 EQ c_false AND gd_einw1_2 EQ c_false.
    gs_kepo-einw1verarb = space.
    gs_kepo-einw1snam = space.
    gs_kepo-einw1sdat = c_date_init.
  ENDIF.

ENDMODULE.                 " SET_EINW1_VAL  INPUT

*&---------------------------------------------------------------------*
*&      Module  SET_EINW2_VAL  INPUT
*&---------------------------------------------------------------------*
*       Einwandsverarbeitung
*----------------------------------------------------------------------*
MODULE set_einw2_val INPUT.
  CASE c_true.
    WHEN gd_einw2_1. "angenommen
      gs_kepo-einw2verarb = 'N'.
*      gs_kepo-einw2sdat = sy-datum.
    WHEN gd_einw2_2. "abgelehnt
      gs_kepo-einw2verarb = 'L'.
*      gs_kepo-einw2sdat = sy-datum.
  ENDCASE.

  IF gd_einw2_1 EQ c_false AND gd_einw2_2 EQ c_false.
    gs_kepo-einw2verarb = space.
    gs_kepo-einw2snam = space.
    gs_kepo-einw2sdat = c_date_init.
  ENDIF.
ENDMODULE.                 " SET_EINW2_VAL  INPUT

*&---------------------------------------------------------------------*
*&      Module  SET_EINW3_VAL  INPUT
*&---------------------------------------------------------------------*
*       Einwandsverarbeitung
*----------------------------------------------------------------------*
MODULE set_einw3_val INPUT.
  CASE c_true.
    WHEN gd_einw3_1. "angenommen
      gs_kepo-einw3verarb = 'N'.
*      gs_kepo-einw3sdat = sy-datum.
    WHEN gd_einw3_2. "abgelehnt
      gs_kepo-einw3verarb = 'L'.
*      gs_kepo-einw3sdat = sy-datum.
  ENDCASE.

  IF gd_einw3_1 EQ c_false AND gd_einw3_2 EQ c_false.
    gs_kepo-einw3verarb = space.
    gs_kepo-einw3snam = space.
    gs_kepo-einw3sdat = c_date_init.
  ENDIF.
ENDMODULE.                 " SET_EINW3_VAL  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_3005  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_3005 INPUT.
  ok_code = sy-ucomm.

  CASE ok_code.
    WHEN 'SAVE'.
      PERFORM read_textedit USING gr_editor_fbem
                         CHANGING gt_editortext_fbem.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_3005  INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TC_DOCPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MODIFY TABLE
MODULE tc_docpos_modify INPUT.
  "Marker setzen Position geändert
  gs_docpos-action = c_modify.

  MODIFY gt_docpos
    FROM gs_docpos
    INDEX tc_docpos-current_line.
ENDMODULE.                    "TC_DOCPOS_MODIFY INPUT

*&SPWIZARD: INPUT MODUL FOR TC 'TC_DOCPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MARK TABLE
MODULE tc_docpos_mark INPUT.
  DATA: g_tc_docpos_wa2 LIKE LINE OF gt_docpos.
  IF tc_docpos-line_sel_mode = 1
  AND gs_docpos-flag = c_true.
    LOOP AT gt_docpos INTO g_tc_docpos_wa2
      WHERE flag = c_true.
      g_tc_docpos_wa2-flag = ''.
      MODIFY gt_docpos
        FROM g_tc_docpos_wa2
        TRANSPORTING flag.
    ENDLOOP.
  ENDIF.
  MODIFY gt_docpos
    FROM gs_docpos
    INDEX tc_docpos-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TC_DOCPOS_MARK INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TC_DOCPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE tc_docpos_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_DOCPOS'
                              'GT_DOCPOS'
                              'GS_DOCPOS'
                              'FLAG'
                              'ACTION'
                              'DELABLE'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TC_DOCPOS_USER_COMMAND INPUT
*&---------------------------------------------------------------------*
*&      Module  COUNT_DOCUMENTS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE count_documents INPUT.
  CLEAR: gs_kepo-fadranz.

  LOOP AT gt_docpos INTO gs_docpos.
    "Anzahl Fundadresse zusammenzählen
    ADD gs_docpos-anzahl TO gs_kepo-fadranz.
  ENDLOOP.


ENDMODULE.                 " COUNT_DOCUMENTS  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALUES_MAT_FART  INPUT
*&---------------------------------------------------------------------*
*       F4-Auswahl für Material pro Fallart
*----------------------------------------------------------------------*
MODULE values_mat_fart INPUT.
  CLEAR: gt_matfart_f4val[].

  SELECT fart matnr bezei FROM zsdtkpmat
    INTO  CORRESPONDING FIELDS OF TABLE gt_matfart_f4val
    WHERE fart = gs_kepo-fart.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'MATNR'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'MATNR'
      value_org   = 'S'
    TABLES
      value_tab   = gt_matfart_f4val.



ENDMODULE.                 " VALUES_MAT_FART  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALUES_PSTAT  INPUT
*&---------------------------------------------------------------------*
*       F4-Auswahl für Pendenzstatus
*----------------------------------------------------------------------*
MODULE values_pstat INPUT.
  CLEAR: gt_statbez_f4val[].

  SELECT statart bezei FROM zsdtkpstatus
    INTO  CORRESPONDING FIELDS OF TABLE gt_statbez_f4val
    WHERE statart = 'P1'.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'BEZEI'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'PSTAT'
      value_org   = 'S'
    TABLES
      value_tab   = gt_statbez_f4val.


ENDMODULE.                 " VALUES_PSTAT  INPUT
*&---------------------------------------------------------------------*
*&      Module  VALUES_EWSTAT  INPUT
*&---------------------------------------------------------------------*
*       F4-Auswahl für Einwandsgrund
*----------------------------------------------------------------------*
MODULE values_ewstat INPUT.
  CLEAR: gd_fieldname, gd_strucstr, gd_fldstr.

  GET CURSOR FIELD gd_fieldname.

  SPLIT gd_fieldname AT '-' INTO gd_strucstr gd_fldstr.

  SELECT statart bezei FROM zsdtkpstatus
    INTO  CORRESPONDING FIELDS OF TABLE gt_statbez_f4val
    WHERE statart = 'E1'.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield    = 'BEZEI'
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = gd_fldstr
      value_org   = 'S'
    TABLES
      value_tab   = gt_statbez_f4val.


ENDMODULE.                 " VALUES_EWSTAT  INPUT
*&---------------------------------------------------------------------*
*&      Module  SET_CURRENCY  INPUT
*&---------------------------------------------------------------------*
*       Währung setzen
*----------------------------------------------------------------------*
MODULE set_currency INPUT.
  IF NOT gs_kepo-debiverl IS INITIAL.
    gs_kepo-debiwaers = gdc_currency.
  ELSE.
    CLEAR gs_kepo-debiwaers.
  ENDIF.
ENDMODULE.                 " SET_CURRENCY  INPUT
*&---------------------------------------------------------------------*
*&      Module  SET_POS_VALUES  INPUT
*&---------------------------------------------------------------------*
*       Positionswerte setzen
*----------------------------------------------------------------------*
MODULE set_pos_values INPUT.
  CLEAR: gd_fieldname.

  GET CURSOR FIELD gd_fieldname.

  SPLIT gd_fieldname AT '-' INTO gd_strucstr gd_fldstr.

  CASE gd_strucstr.
    WHEN 'GS_MATPOS'.
      PERFORM set_mat_details USING gs_matpos-matnr
                                    gdc_langu
                           CHANGING gs_matpos-vrkme
                                    gs_matpos-bezei.
    WHEN 'GS_DOCPOS'.
      gs_docpos-vrkme = gdc_doc_vrkme.
  ENDCASE.
ENDMODULE.                 " SET_POS_VALUES  INPUT


*&---------------------------------------------------------------------*
*&      Module  SET_FADR  INPUT
*&---------------------------------------------------------------------*
*       Debitoradresse für Fundadresse übernehmen
*----------------------------------------------------------------------*
MODULE set_fadr INPUT.
  ok_code = sy-ucomm.

  IF ok_code EQ 'DEBADR_TRANS'.
    PERFORM transfer_address USING gs_deb
                          CHANGING gs_kepo.
  ENDIF.

ENDMODULE.                 " SET_FADR  INPUT


*&---------------------------------------------------------------------*
*&      Module  CHECK_FSTREET  INPUT
*&---------------------------------------------------------------------*
*       Prüfen, ob Adresse (Strasse) eingegeben wurde.
*       Die Fundadress-Felder sind nur als Sollfeld deklariert,
*       damit die Übernahme der Debitorenadresse funktioniert.
*----------------------------------------------------------------------*
MODULE check_fstreet INPUT.

  "Wertweitergabe infolge FIELD-Anweisung im Dynpro
  IF NOT gd_str IS INITIAL.
    gs_kepo-street = gd_str.
    CLEAR: gd_str.
  ENDIF.


  IF gs_kepo-street IS INITIAL.
    MESSAGE e055(00).
  ENDIF.
ENDMODULE.                 " CHECK_FSTREET  INPUT


*&---------------------------------------------------------------------*
*&      Module  CHECK_FPLZ  INPUT
*&---------------------------------------------------------------------*
*       Prüfen, ob Adresse (PLZ) eingegeben wurde.
*       Die Fundadress-Felder sind nur als Sollfeld deklariert,
*       damit die Übernahme der Debitorenadresse funktioniert.
*----------------------------------------------------------------------*
MODULE check_fplz INPUT.

  "Wertweitergabe infolge FIELD-Anweisung im Dynpro
  IF NOT gd_plz IS INITIAL.
    gs_kepo-post_code1 = gd_plz.
    CLEAR: gd_plz.
  ENDIF.

  IF gs_kepo-post_code1 IS INITIAL.
    MESSAGE e055(00).
  ENDIF.
ENDMODULE.                 " CHECK_FPLZ  INPUT


*&---------------------------------------------------------------------*
*&      Module  CHECK_FCITY  INPUT
*&---------------------------------------------------------------------*
*       Prüfen, ob Adresse (Ort) eingegeben wurde.
*       Die Fundadress-Felder sind nur als Sollfeld deklariert,
*       damit die Übernahme der Debitorenadresse funktioniert.
*----------------------------------------------------------------------*
MODULE check_fcity INPUT.

  "Wertweitergabe infolge FIELD-Anweisung im Dynpro
  IF NOT gd_ort IS INITIAL.
    gs_kepo-city1 = gd_ort.
    CLEAR: gd_ort.
  ENDIF.

  IF gs_kepo-city1 IS INITIAL.
    MESSAGE e055(00).
  ENDIF.
ENDMODULE.                 " CHECK_FCITY  INPUT


*&---------------------------------------------------------------------*
*&      Module  CHECK_FUZEI  INPUT
*&---------------------------------------------------------------------*
*       Die Uhrzeit besitz bereits den Defaultwert '000000'.
*       Die klassische Mussfeldprüfung funktioniert somit nicht,
*       da schon ein Wert eingetragen ist.
*----------------------------------------------------------------------*
MODULE check_fuzei INPUT.
  IF gs_kepo-fuzei IS INITIAL.
    MESSAGE e055(00).
  ENDIF.
ENDMODULE.                 " CHECK_FUZEI  INPUT


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_3003  INPUT
*&---------------------------------------------------------------------*
*       User-Commands für Dynpro 3003
*----------------------------------------------------------------------*
MODULE user_command_3003 INPUT.
  ok_code = sy-ucomm.

  CASE ok_code.
    WHEN 'KVERRG_SET'.
      PERFORM set_kverrg CHANGING gs_kepo.

    WHEN 'AUFT_SIMULATE'.
      PERFORM set_mode USING ok_code.
      PERFORM create_order USING c_true.

    WHEN 'AUFT_CREATE'.
      PERFORM set_mode USING ok_code.
      PERFORM create_order USING c_false.
      PERFORM read_order_data USING gs_kepo-fallnr
                                    gs_kepo-gjahr.

    WHEN 'AUFT_SHOW'.
      SET PARAMETER ID 'AUN' FIELD gs_auft-vbeln_a.
      CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.

    WHEN 'AUFT_STORNO'.
      PERFORM cancel_order.

    WHEN 'FAKT_SIMULATE'.
      PERFORM create_invoice USING c_true.


    WHEN 'FAKT_CREATE'.
      PERFORM create_invoice USING c_false.
      PERFORM read_order_data USING gs_kepo-fallnr
                                    gs_kepo-gjahr.

    WHEN 'FAKT_SHOW'.
      SET PARAMETER ID 'VF' FIELD gs_auft-vbeln_f.
      CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.


    WHEN 'FAKT_STORNO'.
      PERFORM cancel_invoice.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_3003  INPUT


*&---------------------------------------------------------------------*
*&      Module  READ_ADDR  INPUT
*&---------------------------------------------------------------------*
*       Liest Kundenadresse
*----------------------------------------------------------------------*
MODULE read_addr INPUT.
  "Adresse zu Debitor lesen
  PERFORM read_address USING gs_kepo-kunnr
                       CHANGING gs_deb.

  "Adresse zu abw. Rechnungsempfänger lesen
  PERFORM read_address USING gs_kepo-kunnrre
                       CHANGING gs_arg.


ENDMODULE.                 " READ_ADDR  INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'TC_MESSAGES'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE tc_messages_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_MESSAGES'
                              'GT_MSG_TAB'
                              'GS_MSG_TAB'
                              space
                              space
                              space
                     CHANGING ok_code.

  sy-ucomm = ok_code.
ENDMODULE.                    "TC_MESSAGES_USER_COMMAND INPUT


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_4001  INPUT
*&---------------------------------------------------------------------*
*       User-Commands für Dynpro 4001
*----------------------------------------------------------------------*
MODULE user_command_4001 INPUT.
  ok_code = sy-ucomm.

  CASE ok_code.
    WHEN 'CLOSE'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_4001  INPUT


*&---------------------------------------------------------------------*
*&      Module  CHECK_DEBIVERL  INPUT
*&---------------------------------------------------------------------*
*       Prüft Feldkombination Debitorenverlust
*----------------------------------------------------------------------*
MODULE check_debiverl INPUT.
  IF ( NOT gs_kepo-debiverl IS INITIAL AND gs_kepo-debivdat IS INITIAL ) OR
     ( gs_kepo-debiverl IS INITIAL AND NOT gs_kepo-debivdat IS INITIAL ).

    MESSAGE e031(zsd_05_kepo).

  ENDIF.
ENDMODULE.                 " CHECK_DEBIVERL  INPUT


*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_3007  INPUT
*&---------------------------------------------------------------------*
*       User-Commands für Dynpro 3007
*----------------------------------------------------------------------*
MODULE user_command_3007 INPUT.
  ok_code = sy-ucomm.

  CASE ok_code.
    WHEN 'PICK'.
      CLEAR: gd_fieldname, gd_fval255.
      GET CURSOR FIELD gd_fieldname VALUE gd_fval255.

      CHECK NOT gd_fval255 IS INITIAL.

      CASE gd_fieldname.
        WHEN 'GS_DEBINFO-FALL'.
          PERFORM show_debinfo_fall USING gd_fval255.
      ENDCASE.

  ENDCASE.


ENDMODULE.                 " USER_COMMAND_3007  INPUT


*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_3100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_3100 INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO TRANSACTION sy-tcode.
    WHEN 'CANC'.
      LEAVE TO TRANSACTION sy-tcode.
    WHEN 'EXIT'.
      LEAVE TO TRANSACTION sy-tcode.
  ENDCASE.

ENDMODULE.                 " EXIT_COMMAND_3100  INPUT

*&SPWIZARD: INPUT MODULE FOR TS 'TS_ADMIN1'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GETS ACTIVE TAB
MODULE ts_admin1_active_tab_get INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN c_ts_admin1-tab1.
      g_ts_admin1-pressed_tab = c_ts_admin1-tab1.
    WHEN c_ts_admin1-tab2.
      g_ts_admin1-pressed_tab = c_ts_admin1-tab2.
    WHEN c_ts_admin1-tab3.
      g_ts_admin1-pressed_tab = c_ts_admin1-tab3.
    WHEN c_ts_admin1-tab4.
      g_ts_admin1-pressed_tab = c_ts_admin1-tab4.
    WHEN c_ts_admin1-tab5.
      g_ts_admin1-pressed_tab = c_ts_admin1-tab5.
    WHEN c_ts_admin1-tab6.
      g_ts_admin1-pressed_tab = c_ts_admin1-tab6.
    WHEN c_ts_admin1-tab7.
      g_ts_admin1-pressed_tab = c_ts_admin1-tab7.
    WHEN c_ts_admin1-tab8.
      g_ts_admin1-pressed_tab = c_ts_admin1-tab8.
    WHEN OTHERS.
*&SPWIZARD:      DO NOTHING
  ENDCASE.
ENDMODULE.                    "TS_ADMIN1_ACTIVE_TAB_GET INPUT

*&SPWIZARD: INPUT MODULE FOR TS 'TS_ADMIN2'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GETS ACTIVE TAB
MODULE ts_admin2_active_tab_get INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN c_ts_admin2-tab1.
      g_ts_admin2-pressed_tab = c_ts_admin2-tab1.
    WHEN c_ts_admin2-tab2.
      g_ts_admin2-pressed_tab = c_ts_admin2-tab2.
    WHEN c_ts_admin2-tab3.
      g_ts_admin2-pressed_tab = c_ts_admin2-tab3.
    WHEN c_ts_admin2-tab4.
      g_ts_admin2-pressed_tab = c_ts_admin2-tab4.
    WHEN c_ts_admin2-tab5.
      g_ts_admin2-pressed_tab = c_ts_admin2-tab5.
    WHEN c_ts_admin2-tab6.
      g_ts_admin2-pressed_tab = c_ts_admin2-tab6.
    WHEN c_ts_admin2-tab7.
      g_ts_admin2-pressed_tab = c_ts_admin2-tab7.
    WHEN c_ts_admin2-tab8.
      g_ts_admin2-pressed_tab = c_ts_admin2-tab8.
    WHEN c_ts_admin2-tab9.
      g_ts_admin2-pressed_tab = c_ts_admin2-tab9.
    WHEN OTHERS.
*&SPWIZARD:      DO NOTHING
  ENDCASE.
ENDMODULE.                    "TS_ADMIN2_ACTIVE_TAB_GET INPUT
