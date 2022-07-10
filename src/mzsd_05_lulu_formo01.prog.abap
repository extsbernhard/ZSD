*&---------------------------------------------------------------------*
*&  Include           MZSD_05_LULU_FORMO01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_1000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_1000 OUTPUT.
  SET PF-STATUS '1000'.
  SET TITLEBAR '100'.

ENDMODULE.                 " STATUS_1000  OUTPUT



*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_FAKT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: UPDATE LINES FOR EQUIVALENT SCROLLBAR
MODULE tc_fakt_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_lulu_fakt LINES tc_fakt-lines.
ENDMODULE.                    "TC_FAKT_CHANGE_TC_ATTR OUTPUT



*&SPWIZARD: OUTPUT MODULE FOR TC 'TC_FAKT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE tc_fakt_get_lines OUTPUT.
  g_tc_fakt_lines = sy-loopc.
ENDMODULE.                    "TC_FAKT_GET_LINES OUTPUT



*&---------------------------------------------------------------------*
*&      Module  STATUS_2000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2000 OUTPUT.
  IF gv_enqu EQ abap_true.
    SET TITLEBAR '201'.

    PERFORM init_fcode_exclude.
    PERFORM add_fcode_exclude USING 'CREA'.
    PERFORM add_fcode_exclude USING 'DISP'.
    PERFORM add_fcode_exclude USING 'SAVE'.
    PERFORM add_fcode_exclude USING 'BACK'.
    PERFORM add_fcode_exclude USING 'UPDA'.

    CLEAR: gv_create, gv_update.
    gv_display = gv_readonly = abap_true.

  ELSEIF gv_create EQ abap_true.
    SET TITLEBAR '202'.

    PERFORM init_fcode_exclude.
    PERFORM add_fcode_exclude USING 'CREA'.
    PERFORM add_fcode_exclude USING 'UPDA'.
    PERFORM add_fcode_exclude USING 'DISP'.
  ELSEIF gv_update EQ abap_true.
    SET TITLEBAR '200'.

    PERFORM init_fcode_exclude.
    PERFORM add_fcode_exclude USING 'CREA'.
    PERFORM add_fcode_exclude USING 'UPDA'.
  ELSEIF gv_display EQ abap_true.
    SET TITLEBAR '201'.

    PERFORM init_fcode_exclude.
    PERFORM add_fcode_exclude USING 'CREA'.
    PERFORM add_fcode_exclude USING 'DISP'.
    PERFORM add_fcode_exclude USING 'SAVE'.
    PERFORM add_fcode_exclude USING 'BACK'.
  ENDIF.

  SET PF-STATUS '2000' EXCLUDING gt_fcode_excludes.

ENDMODULE.                 " STATUS_2000  OUTPUT



*&---------------------------------------------------------------------*
*&      Module  GET_FAKT_DATA  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_fakt_data OUTPUT.
  DATA: ls_lulu_fakt LIKE LINE OF gt_lulu_fakt,
        ls_kehr_auft TYPE zsd_05_kehr_auft,
        ls_vbrk TYPE vbrk,
        lv_vbeln TYPE vbeln_vf.

  LOOP AT gt_lulu_fakt INTO ls_lulu_fakt.
    CLEAR: ls_kehr_auft, ls_vbrk.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = ls_lulu_fakt-vbeln
      IMPORTING
        output = lv_vbeln.


    SELECT SINGLE * FROM zsd_05_kehr_auft INTO ls_kehr_auft
      WHERE faknr EQ lv_vbeln
        AND faknr NE space.

    SELECT SINGLE * FROM vbrk INTO ls_vbrk
      WHERE vbeln EQ lv_vbeln.

    "Mandant füllen
    IF ls_lulu_fakt-mandt IS INITIAL.
      ls_lulu_fakt-mandt = sy-mandt.
    ENDIF.

    "Fallnummer füllen
    IF ls_lulu_fakt-fallnr IS INITIAL.
      ls_lulu_fakt-fallnr = gs_lulu_head-fallnr.
    ENDIF.

    "Fakturadatum füllen
    IF ls_lulu_fakt-fkdat IS INITIAL.
      ls_lulu_fakt-fkdat = ls_kehr_auft-fkdat.
    ENDIF.

    "Währung füllen
    IF ls_lulu_fakt-waerk IS INITIAL.
      ls_lulu_fakt-waerk = ls_vbrk-waerk.
    ENDIF.

    "Bruttobetrag errechnen und füllen
    IF ls_lulu_fakt-brtwr IS INITIAL.
      ls_lulu_fakt-brtwr = ls_vbrk-netwr + ls_vbrk-mwsbk.
    ENDIF.

    "Beginn Verrechnungsperiode füllen
    IF ls_lulu_fakt-verrg_beginn IS INITIAL.
      ls_lulu_fakt-verrg_beginn = ls_kehr_auft-verr_datum.
    ENDIF.

    "Ende Verrechnungsperiode füllen
    IF ls_lulu_fakt-verrg_ende IS INITIAL.
      ls_lulu_fakt-verrg_ende = ls_kehr_auft-verr_datum_schl.
    ENDIF.
    "bezahlt Kennzeichen
    IF ls_lulu_fakt-kennz IS INITIAL.
      ls_lulu_fakt-kennz = ls_kehr_auft-kennz.
    ENDIF.

    MODIFY gt_lulu_fakt FROM ls_lulu_fakt.
    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.                 " GET_FAKT_DATA  OUTPUT



*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE screen_modify OUTPUT.
* Screen-Groups:
* SG1: ROY = Offen beim Anlegen, gesperrt beim Anzeigen und Ändern
*      MOD = bei TableControls mit ROY ersetzt
* SG2: UPD = Offen beim Ändern
* SG3: individuelle Steuerungen
* SG4: individuelle Steuerungen

  LOOP AT SCREEN.
    "Anlegen
    IF gv_create EQ abap_true.
      IF screen-group1 = 'ROY'.
        screen-input = 1.
      ENDIF.
      btn_eig_mod = text-p01.
      btn_ver_mod = text-p02.

      "Ändern
    ELSEIF gv_update EQ abap_true.
      IF screen-group1 = 'ROY'.
        screen-input = 0.
      ENDIF.
      IF screen-group2 = 'UPD'.
        screen-input = 1.
      ENDIF.
      IF screen-group3 = 'DEP'.
        IF gs_lulu_head-belnr IS INITIAL.
          screen-input = 1.
        ELSE.
          screen-input = 0.
        ENDIF.
      ENDIF.

      IF screen-group3 = 'RPL'.
         IF gs_lulu_head-RUECKERST_ART = '1'.
          screen-input = 1.
        ELSE.
          screen-input = 0.
        ENDIF.
      ENDIF.

      IF screen-group3 = 'STA'.
        IF NOT gs_lulu_head-berechnung IS INITIAL.
          screen-invisible = 0.
        ELSE.
          screen-invisible = 1.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.


      btn_eig_mod = text-p01.
      btn_ver_mod = text-p02.

      "Anzeigen
    ELSEIF gv_display EQ abap_true.
      IF screen-group1 = 'ROY' OR screen-group1 = 'MOD' OR screen-group1 = 'PAG'.
        screen-input = 0.
      ENDIF.
      IF screen-group3 = 'STA'.
        IF NOT gs_lulu_head-berechnung IS INITIAL.
          screen-invisible = 0.
        ELSE.
          screen-invisible = 1.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.
      btn_eig_mod = text-p03.
      btn_ver_mod = text-p04.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.
ENDMODULE.                 " SCREEN_MODIFY  OUTPUT



*&---------------------------------------------------------------------*
*&      Module  FILL_ADDR_DATA  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE fill_addr_data OUTPUT.
  CLEAR: gv_fieldname, gv_strucstr, gv_fldstr.

***  "Aktuelles Eingabefeld ermitteln
***  GET CURSOR FIELD gv_fieldname.


***  CASE gv_fieldname.
***    WHEN 'GS_LULU_HEAD-EIGEN_KUNNR'.
  "Adressdaten ermitteln
  IF NOT gs_lulu_head-eigen_kunnr IS INITIAL.
    PERFORM get_addr_data USING    gs_lulu_head-eigen_kunnr
                          CHANGING gs_adrs_print.

    "Adressdaten in entsprechende Felder füllen
    MOVE-CORRESPONDING gs_adrs_print TO gs_et_addr_print.
  ELSE.
    CLEAR gs_et_addr_print.
  ENDIF.

***    WHEN 'GS_LULU_HEAD-VERTR_KUNNR'.
  "Adressdaten ermitteln
  IF NOT gs_lulu_head-vertr_kunnr IS INITIAL.
    PERFORM get_addr_data USING    gs_lulu_head-vertr_kunnr
                          CHANGING gs_adrs_print.

    "Adressdaten in entsprechende Felder füllen
    MOVE-CORRESPONDING gs_adrs_print TO gs_vt_addr_print.
  ELSE.
    CLEAR gs_vt_addr_print.
  ENDIF.

***    WHEN 'GS_LULU_HEAD-RG_KUNNR'.
  "Adressdaten ermitteln
  IF NOT gs_lulu_head-rg_kunnr IS INITIAL.
    PERFORM get_addr_data USING    gs_lulu_head-rg_kunnr
                          CHANGING gs_adrs_print.

    "Adressdaten in entsprechende Felder füllen
    MOVE-CORRESPONDING gs_adrs_print TO gs_re_addr_print.

    SET PARAMETER ID 'KUN' FIELD gs_lulu_head-rg_kunnr.
  ELSE.
    CLEAR gs_re_addr_print.
  ENDIF.
***  ENDCASE.

ENDMODULE.                 " FILL_ADDR_DATA  OUTPUT



*&---------------------------------------------------------------------*
*&      Module  SET_ENQUEUE  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_enqueue OUTPUT.
  DATA: lv_subrc TYPE sy-subrc.

  "Im Änderungsmodus
  IF gv_update EQ abap_true AND gv_enqu EQ abap_false.
    "Sperreintrag prüfen und allenfalls setzen
    PERFORM fall_enqueue USING c_enqmode
                               sy-mandt
                               gs_lulu_head-fallnr
                      CHANGING lv_subrc.


    IF lv_subrc NE 0.
      "Prüfung gecheckt und Gesuch ist gesperrt
      gv_enqu = abap_true.

      "Wenn bereits verwendet, nur Anzeigen möglich
      CLEAR: gv_update.
      gv_display = abap_true.
    ENDIF.
  ENDIF.

ENDMODULE.                 " SET_ENQUEUE  OUTPUT



*&---------------------------------------------------------------------*
*&      Module  INIT_DATA  OUTPUT
*&---------------------------------------------------------------------*
*       Werte initialisieren
*----------------------------------------------------------------------*
MODULE init_data OUTPUT.
  "Buchhalterische Werte setzen
  SET PARAMETER ID 'BUK' FIELD '2870'.
  SET PARAMETER ID 'VKO' FIELD '2870'.
  SET PARAMETER ID 'VTW' FIELD '87'.
  SET PARAMETER ID 'SPA' FIELD '10'.
ENDMODULE.                 " INIT_DATA  OUTPUT
