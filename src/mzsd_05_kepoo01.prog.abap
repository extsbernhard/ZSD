*&---------------------------------------------------------------------*
*&  Include           MZSD_05_KEPOO01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_1000  OUTPUT
*&---------------------------------------------------------------------*
*       Status setzen
*----------------------------------------------------------------------*
MODULE status_1000 OUTPUT.
  SET PF-STATUS '1000'.
  SET TITLEBAR '100'.

ENDMODULE.                 " STATUS_1000  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  STATUS_2000  OUTPUT
*&---------------------------------------------------------------------*
*       Status setzen
*----------------------------------------------------------------------*
MODULE status_2000 OUTPUT.
  SET PF-STATUS '2000'.
  SET TITLEBAR '200'.

ENDMODULE.                 " STATUS_2000  OUTPUT



*&SPWIZARD: OUTPUT MODULE FOR TS 'TS_ADMIN'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: SETS ACTIVE TAB
MODULE ts_admin_active_tab_set OUTPUT.
  ts_admin-activetab = g_ts_admin-pressed_tab.
  CASE g_ts_admin-pressed_tab.
    WHEN c_ts_admin-tab1.
      g_ts_admin-subscreen = '3001'.
    WHEN c_ts_admin-tab2.
      g_ts_admin-subscreen = '3002'.
    WHEN c_ts_admin-tab3.
      g_ts_admin-subscreen = '3003'.
    WHEN c_ts_admin-tab4.
      g_ts_admin-subscreen = '3004'.
    WHEN c_ts_admin-tab5.
      g_ts_admin-subscreen = '3005'.
    WHEN c_ts_admin-tab6.
      g_ts_admin-subscreen = '3006'.
    WHEN c_ts_admin-tab7.
      g_ts_admin-subscreen = '3007'.

    WHEN OTHERS.
*&SPWIZARD:      DO NOTHING
  ENDCASE.
ENDMODULE.                    "TS_ADMIN_ACTIVE_TAB_SET OUTPUT


*&---------------------------------------------------------------------*
*&      Module  STATUS_3000  OUTPUT
*&---------------------------------------------------------------------*
*       Status setzen
*----------------------------------------------------------------------*
MODULE status_3000 OUTPUT.
  ok_code = sy-ucomm.

  "Dokumente
  IF gs_auft-manh2_f IS INITIAL.
    PERFORM add_fcode_exclude USING 'PRNTDOCRG1'.
    PERFORM add_fcode_exclude USING 'PDFDOCRG1'.
  ENDIF.

  IF gs_auft-manh3_f IS INITIAL.
    PERFORM add_fcode_exclude USING 'PRNTDOCV1'.
    PERFORM add_fcode_exclude USING 'PDFDOCV1'.
  ENDIF.



  CASE c_true.
    WHEN gd_create.
      PERFORM add_fcode_exclude USING 'AEND'.
      PERFORM add_fcode_exclude USING 'ANZE'.

      SET PF-STATUS '3000' EXCLUDING gt_fcode_excludes.
      SET TITLEBAR '300'.
    WHEN gd_update.
      PERFORM add_fcode_exclude USING 'ANLE'.
      PERFORM add_fcode_exclude USING 'AEND'.
      PERFORM add_fcode_exclude USING 'BACK'.

      SET PF-STATUS '3000' EXCLUDING gt_fcode_excludes.
      SET TITLEBAR '301'.
    WHEN gd_show.
      PERFORM add_fcode_exclude USING 'ANLE'.
      PERFORM add_fcode_exclude USING 'ANZE' .
      PERFORM add_fcode_exclude USING 'SAVE'.
      PERFORM add_fcode_exclude USING 'BACK'.
      PERFORM add_fcode_exclude USING 'DELE'.

      " IDDRI1 - 15.12.2015 ------------------------------------------------------------------
      " Falls ein Fall "Erledigt" oder "Annuliert" ist, wird der "Ändern"-Button in der Statusleiste ausgblendet

      IF  gs_kepo-fstat = 03 OR gs_kepo-fstat = 04 .
        PERFORM add_fcode_exclude USING 'AEND'.
      ENDIF.

      " --------------------------------------------------------------------------------------

      IF gd_readonly EQ c_true.
        PERFORM add_fcode_exclude USING 'AEND'.

        CLEAR: gd_create, gd_update.
        gd_show = c_true.
      ENDIF.

      SET PF-STATUS '3000' EXCLUDING gt_fcode_excludes.

      "Aufruf über anderen Fall vià Batch-Input
      IF sy-binpt EQ c_true.
        SET TITLEBAR '303'.
      ELSE.
        SET TITLEBAR '302'.
      ENDIF.

  ENDCASE.

ENDMODULE.                 " STATUS_3000  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  STATUS_3005  OUTPUT
*&---------------------------------------------------------------------*
*       Status setzen und Objekt instanzieren
*----------------------------------------------------------------------*
MODULE status_3005 OUTPUT.
*  SET PF-STATUS 'xxxxxxxx'.
*  SET TITLEBAR 'xxx'.


  "TextEdit Control instanzieren
  IF NOT gr_editor_fbem IS BOUND.
    PERFORM create_textedit.
  ENDIF.

  IF NOT gt_editortext_fbem[] IS INITIAL.
    PERFORM fill_textedit USING gr_editor_fbem
                   CHANGING gt_editortext_fbem.
  ENDIF.


ENDMODULE.                 " STATUS_3005  OUTPUT


*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_MATPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE tc_matpos_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_matpos LINES tc_matpos-lines.
ENDMODULE.                    "TC_MATPOS_CHANGE_TC_ATTR OUTPUT


*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_MATPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE tc_matpos_get_lines OUTPUT.
  g_tc_matpos_lines = sy-loopc.
ENDMODULE.                    "TC_MATPOS_GET_LINES OUTPUT


*&---------------------------------------------------------------------*
*&      Module  INIT_ALL  OUTPUT
*&---------------------------------------------------------------------*
*       Alles initialisieren
*----------------------------------------------------------------------*
MODULE init_all OUTPUT.
  PERFORM init_all.

  "Gecustomizte Globale Daten setzen
  PERFORM set_global_data_values.

ENDMODULE.                 " INIT_ALL  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_3004  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung
*----------------------------------------------------------------------*
MODULE screen_modify_3004 OUTPUT.
*  ok_code = sy-ucomm.
*  CASE ok_code.
*    WHEN 'EINW_VERARB'.
  TABLES zsdtkpmarb.

  LOOP AT SCREEN.



    "Eingabeprüfung nur beim Anlegen oder Ändern
    IF gd_create EQ c_true OR
       gd_update EQ c_true.


      IF screen-name = 'GS_AUFT-SIGNPERS_RECHTG' AND NOT gs_auft-manh2_f IS INITIAL.
        screen-required = 1.
      ENDIF.

      "Eingabeprüfung Einwandsverarbeitung 1
      IF gd_einw1_1 EQ c_true.
        IF screen-name = 'GD_EINW1_1'.
          screen-input = 1.
        ENDIF.
        IF screen-name = 'GD_EINW1_2'.
          screen-input = 0.
        ENDIF.
        IF screen-name = 'GS_KEPO-EINW1SNAM' OR screen-name = 'GS_KEPO-EINW1SDAT'.
          screen-required = 1.
        ENDIF.
        "Mussfeld nicht mehr gewünscht, 20110224, IDSWE
*        IF screen-name = 'GS_KEPO-DEBIVERL' OR screen-name = 'GS_KEPO-DEBIVDAT'.
*          screen-required = 1.
*        ENDIF.
      ELSEIF gd_einw1_2 EQ c_true.
        IF screen-name = 'GD_EINW1_2'.
          screen-input = 1.
        ENDIF.
        IF screen-name = 'GD_EINW1_1'.
          screen-input = 0.
        ENDIF.
        IF screen-name = 'GS_KEPO-EINW1SNAM' OR screen-name = 'GS_KEPO-EINW1SDAT'.
          screen-required = 1.
        ENDIF.
      ENDIF.


      "Einwand 2 und 3 Eingabefähigkeit setzen
      IF NOT gs_kepo-einw1dat IS INITIAL.

        "Eingabeprüfung Einwandsverarbeitung 2
        IF gd_einw2_1 EQ c_true.
          IF screen-name = 'GD_EINW2_1'.
            screen-input = 1.
          ENDIF.
          IF screen-name = 'GD_EINW2_2'.
            screen-input = 0.
          ENDIF.
          IF screen-name = 'GS_KEPO-EINW2SNAM' OR screen-name = 'GS_KEPO-EINW2SDAT'.
            screen-required = 1.
          ENDIF.
          "Mussfeld nicht mehr gewünscht, 20110224, IDSWE
*          IF screen-name = 'GS_KEPO-DEBIVERL' OR screen-name = 'GS_KEPO-DEBIVDAT'.
*            screen-required = 1.
*          ENDIF.
        ELSEIF gd_einw2_2 EQ c_true.
          IF screen-name = 'GD_EINW2_2'.
            screen-input = 1.
          ENDIF.
          IF screen-name = 'GD_EINW2_1'.
            screen-input = 0.
          ENDIF.
          IF screen-name = 'GS_KEPO-EINW2SNAM' OR screen-name = 'GS_KEPO-EINW2SDAT'.
            screen-required = 1.
          ENDIF.
        ENDIF.

        IF NOT gs_kepo-einw2dat IS INITIAL.

          "Eingabeprüfung Einwandsverarbeitung 3
          IF gd_einw3_1 EQ c_true.
            IF screen-name = 'GD_EINW3_1'.
              screen-input = 1.
            ENDIF.
            IF screen-name = 'GD_EINW3_2'.
              screen-input = 0.
            ENDIF.
            IF screen-name = 'GS_KEPO-EINW3SNAM' OR screen-name = 'GS_KEPO-EINW3SDAT'.
              screen-required = 1.
            ENDIF.
            "Mussfeld nicht mehr gewünscht, 20110224, IDSWE
*            IF screen-name = 'GS_KEPO-DEBIVERL' OR screen-name = 'GS_KEPO-DEBIVDAT'.
*              screen-required = 1.
*            ENDIF.
          ELSEIF gd_einw3_2 EQ c_true.
            IF screen-name = 'GD_EINW3_2'.
              screen-input = 1.
            ENDIF.
            IF screen-name = 'GD_EINW3_1'.
              screen-input = 0.
            ENDIF.
            IF screen-name = 'GS_KEPO-EINW3SNAM' OR screen-name = 'GS_KEPO-EINW3SDAT'.
              screen-required = 1.
            ENDIF.
          ENDIF.
        ELSE.
          "Einwandsverarbeitung 3 sperren
          IF screen-group4 EQ 'EW3'.
            screen-input = 0.
          ENDIF.
        ENDIF.
      ELSE.
        "Einwandsverarbeitung 2 und 3 sperren
        IF screen-group4 EQ 'EW2' OR screen-group4 EQ 'EW3'.
          screen-input = 0.
        ENDIF.
      ENDIF.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

ENDMODULE.                 " SCREEN_MODIFY_3004  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung
*----------------------------------------------------------------------*
MODULE screen_modify OUTPUT.
* Screen-Groups:
* SG1: ROY = Offen beim Anlegen, gesperrt beim Anzeigen und Ändern
*      MOD = bei TableControls mit ROY ersetzt
* SG2: UPD = Offen beim Ändern
* SG3: individuelle Steuerungen
* SG4: individuelle Steuerungen
*      EW2 = Einwandsverarbeitung 2
*      EW3 = Einwandsverarbeitung 3
*      OPR = Order protected => Gesperrt nach Auftragserstellung
  "Wenn Schwarzer Sack, Wilde Deponie und alle QES, deaktiviere Reiter verwarnung



" MZi neue Fallarten
*  IF gs_kepo-fart EQ '02' OR gs_kepo-fart EQ '04'.
  IF gs_kepo-fart EQ '02' OR gs_kepo-fart EQ '04' OR gs_kepo-fart EQ '05' OR gs_kepo-fart EQ '06' OR gs_kepo-fart EQ '07'.
    LOOP AT SCREEN.
      IF screen-name = 'TS_ADMIN2_TAB4'.
        screen-invisible = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDLOOP.

  ENDIF.

  LOOP AT SCREEN.
    "Anlegen
    IF gd_create EQ c_true.
      IF screen-group1 = 'ROY'.
        screen-input = 1.
      ENDIF.

      "Ändern
    ELSEIF gd_update EQ c_true.
      IF screen-group1 = 'ROY'.
        screen-input = 0.
      ENDIF.
      IF screen-group2 = 'UPD'.
        screen-input = 1.
      ENDIF.
      IF screen-group4 = 'OPR'.
        "Auftrag wurde erstellt und Status: 01 = offen; 02 = fakturiert
        IF NOT gs_auft-vbeln_a IS INITIAL
           AND ( gs_auft-status_a EQ '01' OR gs_auft-status_a EQ '02' ).
          screen-input = 0.
        ENDIF.
      ENDIF.

      "IDDRI1 - 29.07.2015
      "----- Fallart: 01 - Blaue Kehrichtsäcke, 02 - Schwarze Kehrichtsäcke, 03 - Papier / Karton, 04 - Wilde Deponie
      "----- Fallstatus: 01 - erfasst, 02 - offen, 03 - erledigt, 04 - annulliert
      "----- Aktivierung der Dropdownliste Fallart (GS_KEPO-FART) falls Fallstatus (GS_KEPO-FSTAT) auf "offen" oder "erfasst" ist
" MZi neue Fallarten
*      IF screen-name = 'GS_KEPO-FART' AND ( gs_kepo-fstat = 01 OR gs_kepo-fstat = 02 ).
      IF screen-name = 'GS_KEPO-FART' AND ( gs_kepo-fstat = 01 OR gs_kepo-fstat = 02 OR gs_kepo-fstat = 05 ).
        screen-input = 1.
      ENDIF.

      "Anzeigen
    ELSEIF gd_show EQ c_true.
      IF screen-group1 = 'ROY'.
        screen-input = 0.
      ENDIF.

      "IDDRI1 - 06.02.2017
      "----- Checkbox Fallwiederholung wird hier im Anzeigemodus deaktiviert
      IF screen-name = 'GS_KEPO-FWDH'.
        screen-input = 0.
      ENDIF.

    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.


ENDMODULE.                 " SCREEN_MODIFY  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_3005  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung
*----------------------------------------------------------------------*
MODULE screen_modify_3005 OUTPUT.
  IF gd_show EQ c_true.
    gr_editor_fbem->set_readonly_mode(
      EXPORTING  readonly_mode = c_true_num
      EXCEPTIONS error_cntl_call_method = 1
                 invalid_parameter      = 2
                 OTHERS                 = 3 ).
    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ELSEIF gd_update EQ c_true OR gd_create EQ c_true.
    gr_editor_fbem->set_readonly_mode(
      EXPORTING  readonly_mode = c_false_num
      EXCEPTIONS error_cntl_call_method = 1
                 invalid_parameter      = 2
                 OTHERS                 = 3 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
ENDMODULE.                 " SCREEN_MODIFY_3005  OUTPUT


*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_DOCPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE tc_docpos_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_docpos LINES tc_docpos-lines.
ENDMODULE.                    "TC_DOCPOS_CHANGE_TC_ATTR OUTPUT


*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_DOCPOS'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE tc_docpos_get_lines OUTPUT.
  g_tc_docpos_lines = sy-loopc.
ENDMODULE.                    "TC_DOCPOS_GET_LINES OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SET_ENQUEUE  OUTPUT
*&---------------------------------------------------------------------*
*       Sperreintrag setzen
*----------------------------------------------------------------------*
MODULE set_enqueue OUTPUT.
  DATA: ld_subrc TYPE sy-subrc.

  "Im Änderungsmodus
  IF gd_update EQ c_true AND gd_enqu EQ c_false.
    "Sperreintrag prüfen und allenfalls setzen
    PERFORM fall_enqueue USING gdc_enqmode
                               sy-mandt
                               gs_kepo-fallnr
                               gs_kepo-gjahr
                      CHANGING ld_subrc.

    "Prüfung als gecheckt setzen
    gd_enqu = c_true.

    IF ld_subrc NE 0.
      "Wenn bereits verwendet, nur Anzeigen möglich
      CLEAR: gd_update.
      gd_show = c_true.
    ENDIF.
  ENDIF.
ENDMODULE.                 " SET_ENQUEUE  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  INIT_3000  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung
*----------------------------------------------------------------------*
MODULE init_3000 OUTPUT.
  PERFORM init_fcode_exclude.

  SET PARAMETER ID 'ZKPFNR' FIELD gs_kepo-fallnr.
  SET PARAMETER ID 'ZKPGJR' FIELD gs_kepo-gjahr.

  "Fallwiederholung prüfen und setzen, nur beim Anlegen oder wenn
  "Fallstatus auf ERFASST ist
  IF gs_kepo-fstat IS INITIAL OR gs_kepo-fstat EQ '01'.
    PERFORM set_fallwdh CHANGING gs_kepo.

    IF first_time = ' '.
      IF gs_kepo-fwdh = 'X'.
        CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
          EXPORTING
*           TITEL     = ' '
            textline1 = 'Es handelt sich um einen Wiederholungsfall.'
*           TEXTLINE2 = ' '
*           START_COLUMN = 25
*           START_ROW = 6
          .

      ENDIF.
    ENDIF.
  ENDIF.

*    IF gs_kepo-fstat IS INITIAL .
*    PERFORM set_fallwdh CHANGING gs_kepo.
*
*
*      if GS_KEPO-FWDH = 'X'.
*      CALL FUNCTION 'POPUP_TO_DISPLAY_TEXT'
*        EXPORTING
**         TITEL              = ' '
*          textline1          = 'Es handelt sich um einen Wiederholungsfall.'
**         TEXTLINE2          = ' '
**         START_COLUMN       = 25
**         START_ROW          = 6
*                .
*
*
*  endif.
  "endif.
  " select single fwdh  into gs_kepo-fwdh from zsdtkpkepo where fallnr = gs_kepo-fallnr and gjahr = gs_kepo-gjahr.
  " ENDIF.
ENDMODULE.                 " INIT_3000  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  INIT_3001  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung
*----------------------------------------------------------------------*
MODULE init_3001 OUTPUT.

  IF first_time NE 'X'.
    PERFORM set_field_properties.
    TABLES zsd_05_kp_signp.
    "tables zsdtkpmarb.
    DATA signpers_ve1 TYPE zsd_05_kp_signp.
    DATA signpers_rg1 TYPE zsd_05_kp_signp.
    DATA signed_ve TYPE zsd_05_kp_sign.
    DATA signed_rg TYPE zsd_05_kp_sign.
    DATA marb TYPE zsdtkpmarb.
    DATA: name    TYPE vrm_id,
          list_rg TYPE vrm_values,
          list_ve TYPE vrm_values,
          value   TYPE vrm_value.

    " Dropdown Fallart nach Key aufsteigend sortieren
    name = 'GS_KEPO-FART'.
    data fart type ZSDTKPFART.
    SELECT * FROM ZSDTKPFART INTO fart.
      value-key = fart-fart.
      value-text = fart-bezei.
      APPEND value TO list_ve.
    ENDSELECT   .
    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = name
        values          = list_ve
      EXCEPTIONS
        id_illegal_name = 0
        OTHERS          = 0.
    CLEAR list_ve.

    name = 'GS_KEPO-SIGNPERS'.
    SELECT * FROM zsdtkpmarb INTO marb WHERE authsign = 'X'.
      value-key = marb-marb.
      value-text = marb-name.
      APPEND value TO list_ve.
    ENDSELECT.

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = name
        values          = list_ve
      EXCEPTIONS
        id_illegal_name = 0
        OTHERS          = 0.

    CLEAR list_ve.

    name = 'ZSD_05_KP_SIGNP-NAME'.
    CLEAR signpers_ve1.
    SELECT * FROM zsd_05_kp_signp INTO signpers_ve1 WHERE typ = '01'.
      value-key = signpers_ve1-id.
      value-text = signpers_ve1-name.
      APPEND value TO list_ve.
    ENDSELECT.

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = name
        values          = list_ve
      EXCEPTIONS
        id_illegal_name = 0
        OTHERS          = 0.
    "set default value (falls Fall bereits besteht)
    SELECT SINGLE * FROM zsd_05_kp_sign INTO signed_ve WHERE fallnr = gs_kepo-fallnr AND gjahr = gs_kepo-gjahr AND typ = '01'.

    IF sy-subrc = 0.
      zsd_05_kp_signp-gposition = signed_ve-id.
    ENDIF.
    "clear list.
    CLEAR name.
    CLEAR value.
    "Sachbearbeiter

    "Cleare das feld, da SWE die Dropdowns irgendwo unauffindbar befüllt.
    CLEAR list_ve.
    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = name
        values          = list_ve
      EXCEPTIONS
        id_illegal_name = 0
        OTHERS          = 0.


    name = 'gs_kepo-psachb'.
    "tables zsdtkpmarb.
*data marb like zsdtkpmarb.
    SELECT * FROM zsdtkpmarb INTO marb WHERE sachb = 'X'.
      value-key = marb-marb.
      value-text = marb-name.
      APPEND value TO list_ve.
    ENDSELECT.

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = name
        values          = list_ve
      EXCEPTIONS
        id_illegal_name = 0
        OTHERS          = 0.





    name = 'ZSD_05_KP_SIGNP-GPOSITION'.
    CLEAR signpers_rg1.
    SELECT * FROM zsd_05_kp_signp INTO signpers_rg1 WHERE typ = '02'.
      value-key = signpers_rg1-id.
      value-text = signpers_rg1-name.
      APPEND value TO list_rg.
    ENDSELECT.

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = name
        values          = list_rg
      EXCEPTIONS
        id_illegal_name = 0
        OTHERS          = 0.

    SELECT SINGLE * FROM zsd_05_kp_sign INTO signed_rg WHERE fallnr = gs_kepo-fallnr AND gjahr = gs_kepo-gjahr AND typ = '02'.

    IF sy-subrc = 0.
      zsd_05_kp_signp-name = signed_rg-id.
    ENDIF.

    first_time = 'X'.
  ENDIF.

ENDMODULE.                 " INIT_3001  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_3000  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung explizit für Dynpro 3000
*----------------------------------------------------------------------*
MODULE screen_modify_3000 OUTPUT.

  btn_debadr_transfer = text-p03.

  "Textsteuerung Pushbuttons
  IF gd_create EQ c_true OR gd_update EQ c_true.
    btn_deb_mod = text-p01.
    btn_arg_mod = text-p01.
    btn_debold_show = text-p02. "Nur Anzeigen
  ELSEIF gd_show EQ c_true.
    btn_deb_mod = text-p02.
    btn_arg_mod = text-p02.
    btn_debold_show = text-p02.
  ENDIF.


  LOOP AT SCREEN.

    IF screen-name = 'BTN_DEBOLD_SHOW' AND gs_kepo-kunnr_old IS INITIAL.
      screen-input = 0.
    ENDIF.

    "Blende Tab "Material" aus wenn erstfall und Fallart Papier/Karton oder Blaue säcke
" MZi Neue Fallarten
*    IF screen-name = 'TS_ADMIN1_TAB3' AND gs_kepo-fwdh = '' AND ( gs_kepo-fart = 01 OR gs_kepo-fart = 03 ) .
    IF screen-name = 'TS_ADMIN1_TAB3' AND gs_kepo-fwdh = '' AND ( gs_kepo-fart = 01 OR gs_kepo-fart = 03 OR gs_kepo-fart = 06 OR gs_kepo-fart = 07  ) .
      screen-invisible = 1.
    ENDIF.

    IF screen-name = 'BTN_DEB_MOD' AND gs_kepo-kunnr IS INITIAL.
      screen-input = 0.
    ENDIF.

    IF screen-name = 'BTN_ARG_MOD' AND gs_kepo-kunnrre IS INITIAL.
      screen-input = 0.
    ENDIF.

    IF screen-name = 'BTN_DEBADR_TRANSFER' AND gs_kepo-kunnr IS INITIAL OR
       screen-name = 'BTN_DEBADR_TRANSFER' AND gd_show EQ c_true.
      screen-input = 0.
    ENDIF.

    IF screen-name = 'BTN_EWA_SHOW' AND gs_kepo-ewa_order_obj IS INITIAL.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.                 " SCREEN_MODIFY_3000  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  INIT_3004  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung
*----------------------------------------------------------------------*
MODULE init_3004 OUTPUT.

  PERFORM set_field_properties.
  "data marb type zsdtkpmarb.
  "data name type vrm_id.
  DATA list TYPE vrm_values.
  "data value type vrm_value.
  IF first_time = 'X'.
    name = 'gs_kepo-einw1snam'.  "einwand 1
    CLEAR marb.
    SELECT * FROM zsdtkpmarb INTO marb WHERE inkasso = 'X'.
      value-key = marb-marb.
      value-text = marb-name.
      APPEND value TO list.
    ENDSELECT.

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = name
        values          = list
      EXCEPTIONS
        id_illegal_name = 0
        OTHERS          = 0.

    name = 'gs_kepo-einw2snam'.   "einwand2
    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = name
        values          = list
      EXCEPTIONS
        id_illegal_name = 0
        OTHERS          = 0.

    name = 'gs_kepo-einw3snam'.   "einwand3
    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = name
        values          = list
      EXCEPTIONS
        id_illegal_name = 0
        OTHERS          = 0.
  ENDIF.
ENDMODULE.                 " INIT_3004  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_3003  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung explizit für Dynpro 3003
*----------------------------------------------------------------------*
MODULE screen_modify_3003 OUTPUT.

  LOOP AT SCREEN.
    "Mussfeld nicht mehr gewünscht, 25.02.2011, IDSWE
*    IF screen-name EQ 'GS_KEPO-ANZDAT' AND
*       ( gs_kepo-fart EQ '04' OR gs_kepo-fart EQ '02' OR gs_kepo-fwdh EQ c_true ).
*
*      screen-required = c_true_num.
*    ELSE.
*      screen-required = c_false_num.
*    ENDIF.

    "Berechtigte Personen setzen. Abfüllen von Dropdowns unauffindbar, daher wirds hier nochmals neu gesetzt
    "data marb type zsdtkpmarb.


    "Steuerung Fakturadatum
    IF screen-name = 'GS_AUFT-BELDAT_F'.
      IF NOT gs_auft-vbeln_f IS INITIAL.
        screen-input = 0.
      ENDIF.
    ENDIF.


    "Steuerung keine Verrechung -> Grund
    IF screen-name = 'GS_KEPO-KVERRGGRD'.
      IF gs_kepo-kverrgdat IS INITIAL.
        screen-required = c_false_num.
      ELSE.
        screen-required = c_true_num.
      ENDIF.
    ENDIF.


    "Steuerung keine Verrechung
    IF screen-name = 'BTN_KVERRG_SET' OR screen-name = 'GS_KEPO-KVERRGGRD'.
      IF gd_show EQ c_true OR                "Im Anzeigemodus
        ( NOT gs_auft-vbeln_a IS INITIAL AND "Wenn Auftrag erstellt und noch nicht storniert wurde
          gs_auft-status_a NE '03' ).
        screen-input = 0.
      ENDIF.
    ENDIF.


    "Button Auftrag simulieren, Button Auftrag erstellen
    IF screen-name = 'BTN_AUFT_SI' OR screen-name = 'BTN_AUFT_CR'.
      IF gd_create EQ c_true OR gd_show EQ c_true OR
         NOT gs_kepo-kverrgdat IS INITIAL OR "Keine Verrechnung gesetzt
         gs_auft-status_a EQ '01' OR         "Auftrag offen
         gs_auft-status_a EQ '02'.           "Auftrag fakturiert
        screen-input = 0.
      ENDIF.

      "Wenn kein Debitor gepflegt ist, kann keine Verrechnung erfolgen
      IF gs_kepo-kunnr IS INITIAL.
        screen-input = 0.
      ENDIF.
    ENDIF.


    "Button Auftrag anzeigen
    IF screen-name = 'BTN_AUFT_SH'.
      IF gs_auft-vbeln_a IS INITIAL.
        screen-input = 0.
      ENDIF.

      "Wenn kein Debitor gepflegt ist, kann keine Verrechnung erfolgen
      IF gs_kepo-kunnr IS INITIAL.
        screen-input = 0.
      ENDIF.
    ENDIF.


    "Button Auftrag stornieren
    IF screen-name = 'BTN_AUFT_ST'.
      IF gd_create EQ c_true OR gd_show EQ c_true OR
        gs_auft-vbeln_a IS INITIAL OR "kein Auftrag angelegt
        gs_auft-status_a EQ '02' OR   "Auftrag fakturiert
        gs_auft-status_a EQ '03' OR   "Auftrag storniert
        gs_auft-status_a IS INITIAL.  "Noch kein Auftrag angelegt
        screen-input = 0.
      ENDIF.

      "Wenn kein Debitor gepflegt ist, kann keine Verrechnung erfolgen
      IF gs_kepo-kunnr IS INITIAL.
        screen-input = 0.
      ENDIF.
    ENDIF.


    "Button Faktura simulieren, Button Faktura erstellen
    IF screen-name = 'BTN_FAKT_SI' OR screen-name = 'BTN_FAKT_CR'.
      IF gd_create EQ c_true OR gd_show EQ c_true OR
        gs_auft-vbeln_a IS INITIAL OR "Keinen Auftrag angelegt
        gs_auft-status_a EQ '03' OR   "Auftrag storniert
        gs_auft-status_f EQ '01' OR   "Faktura offen
        gs_auft-status_f EQ '02' OR   "Faktura bezahlt
        gs_auft-status_f EQ '04'.     "Faktura gemahnt
        screen-input = 0.
      ENDIF.

      "Wenn kein Debitor gepflegt ist, kann keine Verrechnung erfolgen
      IF gs_kepo-kunnr IS INITIAL.
        screen-input = 0.
      ENDIF.
    ENDIF.


    "Button Faktura anzeigen
    IF screen-name = 'BTN_FAKT_SH'.
      IF gs_auft-vbeln_f IS INITIAL.
        screen-input = 0.
      ENDIF.

      "Wenn kein Debitor gepflegt ist, kann keine Verrechnung erfolgen
      IF gs_kepo-kunnr IS INITIAL.
        screen-input = 0.
      ENDIF.
    ENDIF.


    "Button Faktura stornieren
    IF screen-name = 'BTN_FAKT_ST'.
      IF gd_create EQ c_true OR gd_show EQ c_true OR
        gs_auft-vbeln_f IS INITIAL OR "keine Faktura angelegt
        gs_auft-status_f EQ '02' OR   "Faktura bezahlt
        gs_auft-status_f EQ '03' OR   "Faktura storniert
        gs_auft-status_f IS INITIAL.  "Noch keine Faktura angelegt.

        screen-input = 0.
      ENDIF.

      "Wenn kein Debitor gepflegt ist, kann keine Verrechnung erfolgen
      IF gs_kepo-kunnr IS INITIAL.
        screen-input = 0.
      ENDIF.
    ENDIF.


    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.                 " SCREEN_MODIFY_3003  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_3002  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung explizit für Dynpro 3002
*----------------------------------------------------------------------*
MODULE screen_modify_3002 OUTPUT.

*  LOOP AT SCREEN.
*    CASE c_true.
*      WHEN gd_show.
*        IF screen-name = 'TC_MATPOS_INSERT' OR
*           screen-name = 'TC_MATPOS_DELETE'.
*          screen-input = 0.
*        ENDIF.
*    ENDCASE.
*  ENDLOOP.
ENDMODULE.                 " SCREEN_MODIFY_3002  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_3006  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung explizit für Dynpro 3006
*----------------------------------------------------------------------*
MODULE screen_modify_3006 OUTPUT.

*  LOOP AT SCREEN.
*    CASE c_true.
*      WHEN gd_show.
*        IF screen-name = 'TC_DOCPOS_INSERT' OR
*         screen-name = 'TC_DOCPOS_DELETE'.
*          screen-input = 0.
*        ENDIF.
*    ENDCASE.
*  ENDLOOP .
ENDMODULE.                 " SCREEN_MODIFY_3006  OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_MESSAGES'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE tc_messages_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_msg_tab LINES tc_messages-lines.
ENDMODULE.                    "TC_MESSAGES_CHANGE_TC_ATTR OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_MESSAGES'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE tc_messages_get_lines OUTPUT.
  g_tc_messages_lines = sy-loopc.
ENDMODULE.                    "TC_MESSAGES_GET_LINES OUTPUT


*&---------------------------------------------------------------------*
*&      Module  STATUS_4001  OUTPUT
*&---------------------------------------------------------------------*
*       Status setzen
*----------------------------------------------------------------------*
MODULE status_4001 OUTPUT.
  SET PF-STATUS '4001'.
  IF gd_test EQ c_true.
    SET TITLEBAR '4011'.
  ELSE.
    SET TITLEBAR '401'.
  ENDIF.
ENDMODULE.                 " STATUS_4001  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_3001  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung explizit für Dynpro 3001
*----------------------------------------------------------------------*
MODULE screen_modify_3001 OUTPUT.
  LOOP AT SCREEN.
    IF screen-name = 'BTN_EXTPATH' AND gs_kepo-extpath IS INITIAL.
      screen-input = 0.
    ENDIF.

    IF screen-name = 'GS_KEPO-MARBKP' AND NOT gs_kepo-zulagen IS INITIAL.
      screen-input = 0.
    ENDIF.
    "IDTZI, 08.01.2014 -- Entfernt, die zu Signierende Person ist nur auszuwählen, wenn es sich nicht um ein Wiederholungsfall handelt.
    "                     im anderen Fall wird eine Pfüfung beim Speichern eingebaut.
*    IF screen-name = 'GS_KEPO-SIGNPERS' AND NOT gs_kepo-kunnr IS INITIAL and gs_kepo-fwdh is INITIAL.
*      screen-required = 1.
*    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

ENDMODULE.                 " SCREEN_MODIFY_3001  OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_DEBINFO'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE tc_debinfo_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_debinfo LINES tc_debinfo-lines.
ENDMODULE.                    "TC_DEBINFO_CHANGE_TC_ATTR OUTPUT


*&---------------------------------------------------------------------*
*&      Module  INIT_3007  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung
*----------------------------------------------------------------------*
MODULE init_3007 OUTPUT.
  PERFORM read_debinfo.
ENDMODULE.                 " INIT_3007  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_2000  OUTPUT
*&---------------------------------------------------------------------*
*       Screen-Vorbereitung explizit für Dynpro 2000
*----------------------------------------------------------------------*
MODULE screen_modify_2000 OUTPUT.
  LOOP AT SCREEN.

    IF screen-name = 'RM_DEBINFO'.
      IF gs_kepo-kunnr IS INITIAL.
        screen-active = 0.
      ELSE.
        screen-active = 1.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.


  "Subscreen für Debitorinfo ein- ausblenden
  CLEAR: gd_dynnr, gd_debinfo_selected, gt_debinfo_kepo[],
         gs_debinfo_kepo, gt_debinfo[], gs_debinfo.

  gd_dynnr = '3999'.

  IF NOT gs_kepo-kunnr IS INITIAL.
    "Info zu Debitor lesen
    PERFORM read_debinfo.

    IF NOT gt_debinfo[] IS INITIAL.
      gd_dynnr = '3007'.
    ENDIF.
  ENDIF.


ENDMODULE.                 " SCREEN_MODIFY_2000  OUTPUT


*&---------------------------------------------------------------------*
*&      Module  STATUS_3100  OUTPUT
*&---------------------------------------------------------------------*
*       Status setzen
*----------------------------------------------------------------------*
MODULE status_3100 OUTPUT.
  SET PF-STATUS '3100'.
  SET TITLEBAR '3100'.

ENDMODULE.                 " STATUS_3100  OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TS 'TS_ADMIN1'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: SETS ACTIVE TAB
MODULE ts_admin1_active_tab_set OUTPUT.
  ts_admin1-activetab = g_ts_admin1-pressed_tab.
  CASE g_ts_admin1-pressed_tab.
    WHEN c_ts_admin1-tab1.
      g_ts_admin1-subscreen = '3001'.
    WHEN c_ts_admin1-tab2.
      g_ts_admin1-subscreen = '3006'.
    WHEN c_ts_admin1-tab3.
      g_ts_admin1-subscreen = '3002'.
    WHEN c_ts_admin1-tab4.
      g_ts_admin1-subscreen = '3008'.
    WHEN c_ts_admin1-tab5.
      g_ts_admin1-subscreen = '3003'.
    WHEN c_ts_admin1-tab6.
      g_ts_admin1-subscreen = '3004'.
    WHEN c_ts_admin1-tab7.
      g_ts_admin1-subscreen = '3007'.
    WHEN c_ts_admin1-tab8.
      g_ts_admin1-subscreen = '3005'.
    WHEN OTHERS.
*&SPWIZARD:      DO NOTHING
  ENDCASE.
ENDMODULE.                    "TS_ADMIN1_ACTIVE_TAB_SET OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TS 'TS_ADMIN2'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: SETS ACTIVE TAB
MODULE ts_admin2_active_tab_set OUTPUT.
  ts_admin2-activetab = g_ts_admin2-pressed_tab.
  CASE g_ts_admin2-pressed_tab.
    WHEN c_ts_admin2-tab1.
      g_ts_admin2-subscreen = '3001'.
    WHEN c_ts_admin2-tab2.
      g_ts_admin2-subscreen = '3006'.
    WHEN c_ts_admin2-tab3.
      g_ts_admin2-subscreen = '3002'.
    WHEN c_ts_admin2-tab4.
      g_ts_admin2-subscreen = '3008'.
    WHEN c_ts_admin2-tab5.
      g_ts_admin2-subscreen = '3009'.
    WHEN c_ts_admin2-tab6.
      g_ts_admin2-subscreen = '3003'.
    WHEN c_ts_admin2-tab7.
      g_ts_admin2-subscreen = '3004'.
    WHEN c_ts_admin2-tab8.
      g_ts_admin2-subscreen = '3007'.
    WHEN c_ts_admin2-tab9.
      g_ts_admin2-subscreen = '3005'.
    WHEN OTHERS.
*&SPWIZARD:      DO NOTHING
  ENDCASE.
ENDMODULE.                    "TS_ADMIN2_ACTIVE_TAB_SET OUTPUT
