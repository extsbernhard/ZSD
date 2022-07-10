*&---------------------------------------------------------------------*
*&  Include           MZSD_05_LULU_FORMI01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1000 INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'CREA'.
      CLEAR: gv_update, gv_display.
      gv_create = abap_true.
      SET PARAMETER ID 'KUN' FIELD space.
      PERFORM get_obj_addr.
      CALL SCREEN 2000.
    WHEN 'UPDA'.
      CLEAR: gv_create, gv_display.
      gv_update = abap_true.
      SET PARAMETER ID 'KUN' FIELD space.
      PERFORM get_obj_addr.
      CALL SCREEN 2000.
    WHEN 'DISP' OR 'ENTE'.
      CLEAR: gv_create, gv_update.
      gv_display = abap_true.
      PERFORM get_obj_addr.
      CALL SCREEN 2000.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_1000  INPUT



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
      LEAVE TO TRANSACTION sy-tcode.
*
    WHEN 'CANC'.
      LEAVE TO TRANSACTION sy-tcode.
*
    WHEN 'EXIT'.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.                 " EXIT_COMMAND_1000  INPUT


*&---------------------------------------------------------------------*
*&      Module  FILL_TEXT_VALUES  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE fill_text_values INPUT.
  "Eigentumsverhältnis
  PERFORM fill_text_values USING    'ZZ_EIGEN_VER'
                                    gs_lulu_head-eigen_ver
                                    sy-langu
                           CHANGING gv_eigen_ver_val.

  "Anschriftsart
  PERFORM fill_text_values USING    'ZZ_ANSCHR_ART'
                                    gs_lulu_head-anschr_art
                                    sy-langu
                           CHANGING gv_anschr_art_val.

  "Nutzungsart
  PERFORM fill_text_values USING    'ZZ_NUTZ_ART'
                                    gs_lulu_head-nutz_art
                                    sy-langu
                           CHANGING gv_nutz_art_val.

  "Rückerstattungsart
  PERFORM fill_text_values USING    'ZZ_RUECKERST_ART'
                                    gs_lulu_head-rueckerst_art
                                    sy-langu
                           CHANGING gv_rueckerst_art_val.

ENDMODULE.                 " FILL_TEXT_VALUES  INPUT



*&---------------------------------------------------------------------*
*&      Module  FILL_ADDR_DATA  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE fill_addr_data INPUT.
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
ENDMODULE.                 " FILL_ADDR_DATA  INPUT



*&SPWIZARD: INPUT MODULE FOR TC 'TC_FAKT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MODIFY TABLE
MODULE tc_fakt_modify INPUT.
  MODIFY gt_lulu_fakt
    FROM gs_lulu_fakt
    INDEX tc_fakt-current_line.
ENDMODULE.                    "TC_FAKT_MODIFY INPUT



*&SPWIZARD: INPUT MODUL FOR TC 'TC_FAKT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: MARK TABLE
MODULE tc_fakt_mark INPUT.
  DATA: g_tc_fakt_wa2 LIKE LINE OF gt_lulu_fakt.
  IF tc_fakt-line_sel_mode = 1
  AND gs_lulu_fakt-flag = 'X'.
    LOOP AT gt_lulu_fakt INTO g_tc_fakt_wa2
      WHERE flag = 'X'.
      g_tc_fakt_wa2-flag = ''.
      MODIFY gt_lulu_fakt
        FROM g_tc_fakt_wa2
        TRANSPORTING flag.
    ENDLOOP.
  ENDIF.
  MODIFY gt_lulu_fakt
    FROM gs_lulu_fakt
    INDEX tc_fakt-current_line
    TRANSPORTING flag.
ENDMODULE.                    "TC_FAKT_MARK INPUT



*&SPWIZARD: INPUT MODULE FOR TC 'TC_FAKT'. DO NOT CHANGE THIS LINE!
*&SPWIZARD: PROCESS USER COMMAND
MODULE tc_fakt_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_FAKT'
                              'GT_LULU_FAKT'
                              'GS_LULU_FAKT'
                              'FLAG'
                              'ACTION'
                              'DELABLE'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.                    "TC_FAKT_USER_COMMAND INPUT



*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_2000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_2000 INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.

     WHEN 'BINF'.

      CONCATENATE 'K:\Entsorgung_Recycling\Administration\GRUNDGEBUEHR\Verfügungen manuell\'
                   gs_lulu_head-berechnung
             INTO zsd_04_kehr_mat-berpfad.
      CALL FUNCTION 'GUI_RUN'
        EXPORTING
          command = zsd_04_kehr_mat-berpfad.
    WHEN 'PICK'.
      DATA: lv_field(20) TYPE c,
            lv_line TYPE i,
            lv_aufnr LIKE zsd_05_kehr_auft-vbeln,
            lv_faknr LIKE zsd_05_kehr_auft-faknr.


      GET CURSOR FIELD lv_field VALUE lv_faknr.
      CASE lv_field.
        WHEN 'GS_LULU_FAKT-VBELN'.
          CHECK NOT lv_faknr IS INITIAL.
          SET PARAMETER ID 'VF' FIELD lv_faknr.
          CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
      ENDCASE.



    WHEN 'SAVE'.
      CLEAR: gv_subrc.

      "Neue Fallnummer vergeben
      IF gv_create EQ abap_true.
        PERFORM get_new_fallnr CHANGING gs_lulu_head-fallnr.
        PERFORM set_new_fallnr USING    gs_lulu_head-fallnr
                                        'FALLNR'
                               CHANGING gt_lulu_fakt.
      ENDIF.



      "Kopfdaten speichern
      IF NOT gs_lulu_head IS INITIAL.
        CLEAR: gt_lulu_head[].

        CONCATENATE  gs_lulu_head-stadtteil
         gs_lulu_head-parzelle
         gs_lulu_head-objekt INTO
         gs_lulu_head-obj_key.
        APPEND gs_lulu_head TO gt_lulu_head.

        PERFORM save_data2db TABLES   gt_lulu_head
                             USING    'ZSD_05_LULU_HEAD'
                             CHANGING gv_subrc.
      ENDIF.



      "Rechnungsdaten speichern
      IF NOT gt_lulu_fakt IS INITIAL.
        PERFORM save_data2db TABLES   gt_lulu_fakt
                             USING    'ZSD_05_LULU_FAKT'
                             CHANGING gv_subrc.
      ENDIF.
      IF NOT gt_lulu_fakt_del IS INITIAL.
        PERFORM save_data2db TABLES   gt_lulu_fakt_del
                             USING    'ZSD_05_LULU_FAKT'
                             CHANGING gv_subrc.
        IF gv_subrc EQ 0.
          CLEAR gt_lulu_fakt_del[].
        ENDIF.
      ENDIF.



      "Anlegemodus in Änderungsmodus wechseln
      IF gv_create EQ abap_true.
        CLEAR gv_create.
        gv_update = abap_true.

        "Kopfdaten Status setzen
        gs_lulu_head-delable = abap_false.
        gs_lulu_head-action  = abap_false.

        "Fakturadaten Status setzen
        CLEAR: gs_lulu_fakt.
        gs_lulu_fakt-delable = abap_false.
        gs_lulu_fakt-action  = abap_false.
        MODIFY gt_lulu_fakt FROM gs_lulu_fakt TRANSPORTING action delable WHERE vbeln <> 0.

        "Meldung ausgeben
        CLEAR: gv_obj.
        CONCATENATE gs_lulu_head-stadtteil gs_lulu_head-parzelle gs_lulu_head-objekt INTO gv_obj SEPARATED BY '/'.
        MESSAGE s003(zsd_05_lulu) WITH gs_lulu_head-fallnr gv_obj gs_lulu_head-per_beginn gs_lulu_head-per_ende.
      ELSEIF gv_update EQ abap_true.
        "Meldung ausgeben
        CLEAR: gv_obj.
        CONCATENATE gs_lulu_head-stadtteil gs_lulu_head-parzelle gs_lulu_head-objekt INTO gv_obj SEPARATED BY '/'.
        MESSAGE s004(zsd_05_lulu) WITH gs_lulu_head-fallnr gv_obj gs_lulu_head-per_beginn gs_lulu_head-per_ende.
      ENDIF.
    WHEN 'DISP'.
      CLEAR: gv_create, gv_update.
      gv_display = abap_true.

    WHEN 'UPDA'.
      CLEAR: gv_create, gv_display.
      gv_update = abap_true.

    WHEN 'DEBADM_EIG'.
      IF gv_display EQ abap_true.
        PERFORM admin_customer USING abap_true
                               CHANGING gs_lulu_head-eigen_kunnr.
      ELSE.
        PERFORM admin_customer USING abap_false
                         CHANGING gs_lulu_head-eigen_kunnr.
      ENDIF.

    WHEN 'DEBADM_VER'.
      IF gv_display EQ abap_true.
        PERFORM admin_customer USING abap_true
                               CHANGING gs_lulu_head-vertr_kunnr.
      ELSE.
        PERFORM admin_customer USING abap_false
                         CHANGING gs_lulu_head-vertr_kunnr.
      ENDIF.

    WHEN 'DEBADM_REM'.
      PERFORM admin_customer USING abap_true
                              CHANGING gs_lulu_head-rg_kunnr.

    WHEN 'PRINT'.
      PERFORM print_confirm USING gs_lulu_head.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_2000  INPUT



*&---------------------------------------------------------------------*
*&      Module  EXIT_COMMAND_2000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_2000 INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
*
    WHEN 'BACK'.
      LEAVE TO TRANSACTION sy-tcode.
*
    WHEN 'CANC'.
      LEAVE TO TRANSACTION sy-tcode.
*
    WHEN 'EXIT'.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.                 " EXIT_COMMAND_2000  INPUT



*&---------------------------------------------------------------------*
*&      Module  CHECK_OBJ_PERIOD_EXISTS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_obj_period_exists INPUT.
  CLEAR gv_subrc.

  MOVE-CORRESPONDING zsd_05_lulu_head TO gs_lulu_head.

  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'ENTE' OR 'DISP' OR 'UPDA' OR 'DELE'.
      IF NOT gs_lulu_head-stadtteil IS INITIAL AND
         NOT gs_lulu_head-parzelle IS INITIAL AND
*         NOT gs_lulu_head-objekt IS INITIAL AND
         NOT gs_lulu_head-per_beginn IS INITIAL AND
         NOT gs_lulu_head-per_ende IS INITIAL OR
         NOT gs_lulu_head-fallnr IS INITIAL.
        PERFORM obj_period_exists USING gs_lulu_head-fallnr
                                        gs_lulu_head-stadtteil
                                        gs_lulu_head-parzelle
                                        gs_lulu_head-objekt
                                        gs_lulu_head-per_beginn
                                        gs_lulu_head-per_ende
                                        abap_true
                               CHANGING gv_subrc.

        IF gv_subrc NE 0.
          IF NOT gs_lulu_head-fallnr IS INITIAL.
            MESSAGE e005(zsd_05_lulu) WITH gs_lulu_head-fallnr.
          ELSE.
            CLEAR: gv_obj.
            CONCATENATE gs_lulu_head-stadtteil gs_lulu_head-parzelle gs_lulu_head-objekt INTO gv_obj SEPARATED BY '/'.
            MESSAGE e001(zsd_05_lulu) WITH gv_obj gs_lulu_head-per_beginn gs_lulu_head-per_ende.
          ENDIF.
        ENDIF.
      ELSE.
        MESSAGE e000(zsd_05_lulu).
      ENDIF.


    WHEN 'CREA'.
      IF NOT gs_lulu_head-stadtteil IS INITIAL AND
         NOT gs_lulu_head-parzelle IS INITIAL AND
*         NOT gs_lulu_head-objekt IS INITIAL AND
         NOT gs_lulu_head-per_beginn IS INITIAL AND
         NOT gs_lulu_head-per_ende IS INITIAL.

        IF NOT zsd_05_lulu_head-per_beginn BETWEEN '20070501' AND '20101231' OR
         not ZSD_05_LULU_HEAD-PER_ENDE BETWEEN '20070501' AND '20101231'.
          MESSAGE e008(zsd_05_lulu).
        ELSE.


          PERFORM obj_period_exists USING ''
                                          gs_lulu_head-stadtteil
                                          gs_lulu_head-parzelle
                                          gs_lulu_head-objekt
                                          gs_lulu_head-per_beginn
                                          gs_lulu_head-per_ende
                                          abap_true
                                 CHANGING gv_subrc.

          IF gv_subrc EQ 0.
            CLEAR: gv_obj.
            CONCATENATE gs_lulu_head-stadtteil gs_lulu_head-parzelle gs_lulu_head-objekt INTO gv_obj SEPARATED BY '/'.
            MESSAGE e002(zsd_05_lulu) WITH gv_obj gs_lulu_head-per_beginn gs_lulu_head-per_ende.
          ELSE.
            gs_lulu_head-action  = c_insert.
            gs_lulu_head-delable = abap_true.
          ENDIF.
        ENDIF.
      ELSE.
        MESSAGE e006(zsd_05_lulu).
      ENDIF.

  ENDCASE.

ENDMODULE.                 " CHECK_OBJ_PERIOD_EXISTS  INPUT



*&---------------------------------------------------------------------*
*&      Module  SET_FIELD_VALUES  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE set_field_values INPUT.
  "Quotenwert setzen
  IF gs_lulu_head-nutz_art EQ 1. "vollständig selbstgenutzt
    gs_lulu_head-rueckzlg_quote = 100.
  ELSEIF gs_lulu_head-rueckerst_art EQ 2. "Rückerstattung mit Pauschallösung
    gs_lulu_head-rueckzlg_quote = 70.
  ELSE.
*    gs_lulu_head-rueckzlg_quote = 0.
  ENDIF.

ENDMODULE.                 " SET_FIELD_VALUES  INPUT
*&---------------------------------------------------------------------*
*&      Module  EXIT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit INPUT.
data: okcode type sy-ucomm.
okcode = OK_CODE.
clear ok_code.
CASE okcode.
  WHEN 'BACK'.
    SET SCREEN '1000'.
  WHEN 'CANC'.
    SET SCREEN '1000'.
  when 'EXIT'.
    LEAVE PROGRAM.
  WHEN OTHERS.
ENDCASE.
ENDMODULE.                 " EXIT  INPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_BERECHNUNG  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_berechnung INPUT.
  IF gs_lulu_head-status = 'V'.
    IF gs_lulu_head-berechnung IS INITIAL.
      MESSAGE e010(zsd_05_lulu) WITH 'Bitte Informationen zur Berechnungsdatei füllen'.
    ENDIF.
  ELSE.
    IF NOT gs_lulu_head-berechnung IS INITIAL.
      MESSAGE s010(zsd_05_lulu) WITH 'Status V nicht gesetzt!'
                   'Informationen zur Berechnungsdatei wurden gelöscht'.
      CLEAR gs_lulu_head-berechnung.
    ENDIF.
  ENDIF.
ENDMODULE.                 " STATUS_BERECHNUNG  INPUT
