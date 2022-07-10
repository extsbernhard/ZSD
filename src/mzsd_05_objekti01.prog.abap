*----------------------------------------------------------------------*
***INCLUDE MZSD_05_PARZELLEI01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  exit_command_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_1000 INPUT.
  CASE w_ucomm.
    WHEN 'BACK'.                 "Zurück
      IF NOT s_1000 IS INITIAL.
        CLEAR: s_1000,
               s_anle,
               s_aend,
               s_anze,
               s_enqueue,
               zsd_05_objekt.
        SET SCREEN 1000.
        LEAVE SCREEN.
      ELSE.
        IF NOT s_enqueue IS INITIAL.
          CALL FUNCTION 'DEQUEUE_EZSD05_OBJEKT'
            EXPORTING
              mode_zsd_05_objekt = 'E'
              mandt              = sy-mandt
              stadtteil          = zsd_05_objekt-stadtteil
              parzelle           = zsd_05_objekt-parzelle
              objekt             = zsd_05_objekt-objekt
              x_stadtteil        = ' '
              x_parzelle         = ' '
              x_objekt           = ' '
              _scope             = '3'
              _synchron          = ' '
              _collect           = ' '.
          CLEAR s_enqueue.
        ENDIF.
        REFRESH t_object.
        LEAVE PROGRAM.
      ENDIF.
    WHEN 'CANC'.                 "Abbrechen
      LEAVE PROGRAM.
    WHEN 'EXIT'.                 "Beenden
      LEAVE PROGRAM.
    WHEN 'LIST'.
      REFRESH: t_zsd_05_objekt,
               r_stadtteil,
               r_parzelle.
      IF NOT zsd_05_objekt-stadtteil IS INITIAL.
        MOVE: zsd_05_objekt-stadtteil TO r_stadtteil-low,
              space                   TO r_stadtteil-high,
              'I'                     TO r_stadtteil-sign,
              'EQ'                    TO r_stadtteil-option.
        APPEND r_stadtteil.
      ENDIF.
      SELECT        * FROM  zsd_05_objekt
             INTO TABLE t_zsd_05_objekt
             WHERE  stadtteil IN r_stadtteil
             AND    parzelle  IN r_parzelle.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          i_interface_check           = ' '
          i_buffer_active             = ' '
          i_callback_program          = 'SAPMZSD_05_OBJEKT'
          i_callback_pf_status_set    = ' '
          i_callback_user_command     = ' '
          i_callback_top_of_page      = ' '
          i_callback_html_top_of_page = ' '
          i_callback_html_end_of_list = ' '
          i_structure_name            = 'ZSD_05_OBJEKT'
          i_background_id             = ' '
          i_default                   = 'X'
          i_save                      = ' '
          i_screen_start_column       = 0
          i_screen_start_line         = 0
          i_screen_end_column         = 0
          i_screen_end_line           = 0
        TABLES
          t_outtab                    = t_zsd_05_objekt
        EXCEPTIONS
          program_error               = 1
          OTHERS                      = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
*
*    WHEN 'DLAV'.
*      CLEAR zsd_05_objekt-addrnumber_ver.
*
    WHEN 'DLAE'.
      CLEAR zsd_05_objekt-addrnumber_eig.
*
    WHEN 'ADRE'.                 "Adresse Eigentümer
      PERFORM addr_dialog USING zsd_05_objekt-eigentuemer
                                zsd_05_objekt-addrnumber_eig.
*
*    WHEN 'ADRV'.                 "Adresse Verwalter
*      PERFORM addr_dialog USING zsd_05_objekt-verwalter
*                                zsd_05_objekt-addrnumber_ver.
*
    WHEN OTHERS.
  ENDCASE.

ENDMODULE.                 " exit_command_1000  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1000 INPUT.

  CASE w_ucomm.
    WHEN 'CS'.               "Detailansicht
*      MOVE <wa> TO t_object_wa.
      MOVE: zsd_05_objekt-info1 TO t_object_wa-info1,
            zsd_05_objekt-info2 TO t_object_wa-info2.
      IF t_object_wa-objekt = '0000'.
        MOVE: "zsd_05_objekt-verwalter
              "TO t_object_wa-verwalter,
              "zsd_05_objekt-addrnumber_ver
              "TO t_object_wa-addrnumber_ver,
              zsd_05_objekt-eigentuemer
              TO t_object_wa-eigentuemer,
              zsd_05_objekt-addrnumber_eig
              TO t_object_wa-addrnumber_eig.
      ENDIF.
      CALL SCREEN 2000.
*
    WHEN 'ANLE'.                 "Anlegen
      PERFORM parzelle_vorhanden.
      IF sy-subrc = 0.
        PERFORM parzelle_aend USING 'X'.
        IF s_aend = 'X'.
          s_1000 = 'X'.
        ENDIF.
      ELSE.
        PERFORM parzelle_anle USING ' '.
        s_1000 = 'X'.
      ENDIF.
*
    WHEN 'AEND'.                 "Ändern
      PERFORM parzelle_vorhanden.
      IF sy-subrc NE 0.
        PERFORM parzelle_anle USING 'X'.
        IF s_anle = 'X'.
          s_1000 = 'X'.
        ENDIF.
      ELSE.
        PERFORM parzelle_aend USING ' '.
        s_1000 = 'X'.
      ENDIF.
*
    WHEN 'ANZE'.                 "Anzeigen
      PERFORM parzelle_vorhanden.
      IF sy-subrc = 0.
        s_anze = 'X'.
        CLEAR: s_anle,
               s_aend.
        s_1000 = 'X'.
      ELSE.
        MESSAGE e000(zsd_04) WITH text-e01 text-e02.
      ENDIF.
*
    WHEN 'DELE'.                 "Löschen
      PERFORM parzelle_vorhanden.
      IF sy-subrc NE 0.
        MESSAGE e000(zsd_04) WITH text-e01 text-e02.
      ENDIF.
      PERFORM parzelle_dele.
*
    WHEN 'SAVE'.                 "Sichern
      IF NOT s_aend IS INITIAL.
        MOVE: sy-uname TO zsd_05_objekt-rbear,
              sy-datum TO zsd_05_objekt-dbear,
              sy-uzeit TO zsd_05_objekt-tbear.
        IF NOT zsd_05_objekt-eigentuemer IS INITIAL.
          CLEAR zsd_05_objekt-addrnumber_eig.
        ENDIF.
        UPDATE zsd_05_objekt FROM zsd_05_objekt.
        LOOP AT t_object WHERE objekt = '0000'.
          UPDATE zsd_05_objekt SET ybaujahr   = t_object-ybaujahr
                                   yabbruch   = t_object-yabbruch
                                   yaufbau    = t_object-yaufbau
                                   city1      = t_object-city1
                                   post_code1 = t_object-post_code1
                                   street     = t_object-street
                                   house_num1 = t_object-house_num1
                                   building   = t_object-building
                                   roomnumber = t_object-roomnumber
                                   country    = t_object-country
                                   region     = t_object-region
                             WHERE stadtteil  = t_object-stadtteil
                               AND parzelle   = t_object-parzelle
                               AND objekt     = t_object-objekt.
        ENDLOOP.
        LOOP AT t_object WHERE objekt NE '0000'.
          MODIFY zsd_05_objekt FROM t_object.
        ENDLOOP.
        IF sy-subrc = 0.
          MESSAGE s000(zsd_04) WITH 'Parzelle wurde geändert'.
        ENDIF.
        CLEAR: s_1000,
               s_anle,
               s_aend,
               s_anze,
               zsd_05_objekt,
               w_kna1e.
      ELSEIF NOT s_anle IS INITIAL.
        IF NOT zsd_05_objekt-stadtteil IS INITIAL
        AND NOT zsd_05_objekt-parzelle IS INITIAL.
          SELECT SINGLE * FROM  zsd_05_objekt
                 WHERE  stadtteil   = zsd_05_objekt-stadtteil
                 AND    parzelle    = zsd_05_objekt-parzelle
                 AND    objekt      = '0000'.
          IF sy-subrc = 0.
            MESSAGE e000(zsd_04) WITH text-e01 text-e04.
          ENDIF.
        ENDIF.
        MOVE: sy-uname TO zsd_05_objekt-rerf,
              sy-datum TO zsd_05_objekt-derf,
              sy-uzeit TO zsd_05_objekt-terf.
        INSERT INTO zsd_05_objekt VALUES zsd_05_objekt.
        IF sy-subrc = 0.
          MESSAGE s000(zsd_04) WITH 'Parzelle wurde angelegt'.
        ENDIF.
        MOVE-CORRESPONDING zsd_05_objekt TO t_object_wa.
        CALL SCREEN 2000.
      ENDIF.
*
    WHEN 'ENTE'.                 "Enter
      IF NOT zsd_05_objekt-stadtteil IS INITIAL
      AND NOT zsd_05_objekt-parzelle IS INITIAL
      AND s_1000 IS INITIAL.
        PERFORM parzelle_vorhanden.
        IF sy-subrc = 0.
* Wenn ja, dann anzeigen
          s_anze = 'X'.
          s_1000 = 'X'.
          CLEAR: s_anle,
                 s_aend.
        ELSE.
          PERFORM parzelle_anle USING 'X'.
          IF s_anle = 'X'.
            s_1000 = 'X'.
          ENDIF.
        ENDIF.
      ELSE.
*        IF NOT zsd_05_objekt-verwalter IS INITIAL.
*          CLEAR zsd_05_objekt-addrnumber_ver.
*        ENDIF.
        IF NOT zsd_05_objekt-eigentuemer IS INITIAL.
          CLEAR zsd_05_objekt-addrnumber_eig.
        ENDIF.
      ENDIF.
*
    WHEN OTHERS.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_1000  INPUT
*
*---------------------------------------------------------------------*
*       MODULE tc_object_modify INPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_object_modify INPUT.

  MODIFY t_object
    INDEX tc_object-current_line.

ENDMODULE.                    "tc_object_modify INPUT
*
*---------------------------------------------------------------------*
*       MODULE tc_object_mark INPUT                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_object_mark INPUT.

  DATA: g_tc_object_wa2 LIKE LINE OF t_object.
  IF tc_object-line_sel_mode = 1.
    LOOP AT t_object INTO g_tc_object_wa2
      WHERE flag = 'X'.
      g_tc_object_wa2-flag = ''.
      MODIFY t_object
        FROM g_tc_object_wa2
        TRANSPORTING flag.
    ENDLOOP.
  ENDIF.
  MODIFY t_object
    INDEX tc_object-current_line
    TRANSPORTING flag.

ENDMODULE.                    "tc_object_mark INPUT
*
*---------------------------------------------------------------------*
*       MODULE tc_object_user_command INPUT                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_object_user_command INPUT.

  w_ucomm = sy-ucomm.
  CLEAR s_insr.
  PERFORM user_ok_tc USING    'TC_OBJECT'
                              'T_OBJECT'
                              'FLAG'
                     CHANGING w_ucomm.
  sy-ucomm = w_ucomm.

ENDMODULE.                    "tc_object_user_command INPUT
*
*&---------------------------------------------------------------------*
*&      Module  user_command_2000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_2000 INPUT.

  CASE w_ucomm.
    WHEN 'SAVE'.                 "Sichern
* Equipment nachführen
      TABLES equi.
      DATA l_subrc LIKE sy-subrc.
      DATA lt_messtab TYPE bdcmsgcoll OCCURS 0 WITH HEADER LINE.
      DATA l_equnr LIKE equi-equnr.
      CLEAR l_subrc.
      REFRESH lt_messtab.
      CONCATENATE '000000000'
                  t_object_wa-stadtteil
                  t_object_wa-parzelle
                  t_object_wa-objekt
             INTO l_equnr.
      SELECT SINGLE * FROM  equi
             WHERE  equnr  = l_equnr.
      IF sy-subrc NE 0.
        MOVE: sy-uname TO t_object_wa-rerf,
              sy-datum TO t_object_wa-derf,
              sy-uzeit TO t_object_wa-terf.
        CALL FUNCTION 'ZSD_05_OBJEKT_EQUI'
          EXPORTING
            tcode         = 'IE01'
            zsd_05_objekt = t_object_wa
          IMPORTING
            subrc         = l_subrc
          TABLES
            messtab       = lt_messtab.
        IF l_subrc NE 0.
        ENDIF.
        IF NOT s_anle IS INITIAL
        OR NOT s_insr IS INITIAL.
          APPEND t_object.
          MESSAGE s000 WITH text-e13.
        ENDIF.
      ELSE.
        DATA lt_object TYPE zsd_05_objekt.
        CLEAR lt_object.
        MOVE-CORRESPONDING t_object_wa TO lt_object.
        CALL FUNCTION 'ZSD_05_OBJEKT_EQUI'
          EXPORTING
            tcode         = 'IE02'
            zsd_05_objekt = lt_object
          IMPORTING
            subrc         = l_subrc
          TABLES
            messtab       = lt_messtab.
        MESSAGE s000 WITH text-e23.
        MOVE: sy-uname TO t_object_wa-rbear,
              sy-datum TO t_object_wa-dbear,
              sy-uzeit TO t_object_wa-tbear.
      ENDIF.
* Objekt sichern
      MODIFY zsd_05_objekt FROM t_object_wa.
      IF t_object_wa-objekt = '0000'.
        MOVE t_object_wa TO zsd_05_objekt.
      ENDIF.
      IF NOT zsd_04_boden-kunnr IS INITIAL
      OR NOT zsd_04_boden-adrnr IS INITIAL.
        MODIFY zsd_04_boden FROM zsd_04_boden.
      ENDIF.
      IF NOT zsd_04_kanal-kunnr IS INITIAL
      OR NOT zsd_04_kanal-adrnr IS INITIAL.
        MODIFY zsd_04_kanal FROM zsd_04_kanal.
      ENDIF.
      IF NOT zsd_04_kehricht-kunnr IS INITIAL
      or not zsd_04_kehricht-eigen_kunnr IS INITIAL
      OR NOT zsd_04_kehricht-adrnr IS INITIAL.
        zsd_04_kehricht-kunnr = zsd_04_kehricht-eigen_kunnr.  ">IDEDSC 20140124<
        MODIFY zsd_04_kehricht FROM zsd_04_kehricht.
* Historie
        PERFORM protocol_changes USING zsd_04_kehricht
                      w_zsd_04_kehricht.
        REFRESH t_kehrauft.
      ENDIF.
      IF NOT zsd_04_regen-kunnr IS INITIAL
      OR NOT zsd_04_regen-adrnr IS INITIAL.
        MODIFY zsd_04_regen FROM zsd_04_regen.
      ENDIF.
      CLEAR g_tc_regeninfo_copied.
      IF NOT s_anle IS INITIAL
      OR NOT s_aend IS INITIAL.
        CLEAR g_tc_object_copied.
      ENDIF.
      MESSAGE s000 WITH text-e10.
      CLEAR s_anle.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'AEND'.
      CLEAR: s_anze,
             s_anle.
      s_aend = 'X'.
    WHEN 'ANZE'.
      CLEAR: s_aend,
             s_anle.
      s_anze = 'X'.
    WHEN OTHERS.
* Adressen
      CLEAR: w_kna1e,
             w_kna1k,
             w_kna1r,
             w_kna1g,
             w_kna1b.
      PERFORM read_kna1 USING: t_object_wa-eigentuemer w_kna1e,
                               zsd_04_kanal-kunnr      w_kna1k,
                               zsd_04_regen-kunnr      w_kna1r,
                               zsd_04_kehricht-eigen_kunnr   w_kna1g, ">IDEDSC 20140124<
*                               zsd_04_kehricht-kunnr   w_kna1g,
                               zsd_04_boden-kunnr      w_kna1b.
      PERFORM addr_get  USING: t_object_wa-addrnumber_eig w_kna1e,
                               zsd_04_kanal-adrnr         w_kna1k,
                               zsd_04_regen-adrnr         w_kna1r,
                               zsd_04_kehricht-adrnr      w_kna1g,
                               zsd_04_boden-adrnr         w_kna1b.
  ENDCASE.

ENDMODULE.                 " user_command_2000  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  exit_command_2000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_2000 INPUT.

  CASE w_ucomm.
    WHEN 'BACK'.                 "Zurück
      REFRESH t_kehrauft.
      CLEAR g_tc_regeninfo_copied.
      CLEAR s_anle.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'CANC'.                 "Abbrechen
      REFRESH t_kehrauft.
      CLEAR g_tc_regeninfo_copied.
      LEAVE PROGRAM.
    WHEN 'EXIT'.                 "Beenden
      REFRESH t_kehrauft.
      CLEAR g_tc_regeninfo_copied.
      LEAVE PROGRAM.
    WHEN 'ADRE'.                 "Adresse Eigentümer
      PERFORM addr_dialog USING t_object_wa-eigentuemer
                                t_object_wa-addrnumber_eig.
    WHEN 'DLAE'.
      CLEAR t_object_wa-addrnumber_eig.
    WHEN 'ADRK'.                 "Adresse Verwalter Kanalisation
      PERFORM addr_dialog USING zsd_04_kanal-kunnr
                                zsd_04_kanal-adrnr.
    WHEN 'DLAK'.
      CLEAR zsd_04_kanal-adrnr.
    WHEN 'DLAG'.
      CLEAR zsd_04_kehricht-adrnr.
    WHEN 'ADRR'.                 "Adresse Verwalter Regenabwasser
      PERFORM addr_dialog USING zsd_04_regen-kunnr
                                zsd_04_regen-adrnr.
    WHEN 'DLAR'.
      CLEAR zsd_04_regen-adrnr.
    WHEN 'ADRB'.                 "Adresse Verwalter Bew. öff. Boden
      PERFORM addr_dialog USING zsd_04_boden-kunnr
                                zsd_04_boden-adrnr.
    WHEN 'DLAB'.
      CLEAR zsd_04_boden-adrnr.
    WHEN OTHERS.
  ENDCASE.
* Adressen
  CLEAR: w_kna1e,
         w_kna1k,
         w_kna1r,
         w_kna1g,
         w_kna1b.
  PERFORM read_kna1 USING: t_object_wa-eigentuemer w_kna1e,
                           zsd_04_kanal-kunnr      w_kna1k,
                           zsd_04_regen-kunnr      w_kna1r,
                           zsd_04_kehricht-eigen_kunnr   w_kna1g, ">IDEDSC 20140124<
*                           zsd_04_kehricht-kunnr   w_kna1g,
                           zsd_04_boden-kunnr      w_kna1b.
  PERFORM addr_get  USING: t_object_wa-addrnumber_eig w_kna1e,
                           zsd_04_kanal-adrnr         w_kna1k,
                           zsd_04_regen-adrnr         w_kna1r,
                           zsd_04_kehricht-adrnr      w_kna1g,
                           zsd_04_boden-adrnr         w_kna1b.

ENDMODULE.                 " exit_command_1000  INPUT
*
*---------------------------------------------------------------------*
*       MODULE ts_gebuehren_active_tab_get INPUT                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE ts_gebuehren_active_tab_get INPUT.
  IF  sy-ucomm = 'TC_RUECK_INS'
   OR sy-ucomm = 'TC_RUECK_DEL'
   OR sy-ucomm = 'TC_RUECK_DET'.
    sy-ucomm   = ' '.
  ENDIF.
  w_ucomm = sy-ucomm.
  CASE w_ucomm.
    WHEN c_ts_gebuehren-tab1.
      g_ts_gebuehren-pressed_tab = c_ts_gebuehren-tab1.
    WHEN c_ts_gebuehren-tab2.
      g_ts_gebuehren-pressed_tab = c_ts_gebuehren-tab2.
    WHEN c_ts_gebuehren-tab3.
      g_ts_gebuehren-pressed_tab = c_ts_gebuehren-tab3.
    WHEN c_ts_gebuehren-tab4.
      g_ts_gebuehren-pressed_tab = c_ts_gebuehren-tab4.
    WHEN OTHERS.
  ENDCASE.

ENDMODULE.                    "ts_gebuehren_active_tab_get INPUT
*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_2002  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_2002 INPUT.

  CASE sy-ucomm.
    WHEN 'ADRG'.                 "Adresse Verwalter Kehricht
      PERFORM addr_dialog USING zsd_04_kehricht-kunnr
                                zsd_04_kehricht-adrnr.
    WHEN 'CS'.
      DATA l_field(20) TYPE c.
      DATA l_line TYPE i.
      DATA l_aufnr LIKE zsd_05_kehr_auft-vbeln.
      DATA l_faknr LIKE zsd_05_kehr_auft-faknr.
      DATA l_kunnr LIKE zsd_05_kehr_auft-kunnr.
      GET CURSOR FIELD l_field VALUE l_aufnr.
      CHECK NOT l_aufnr IS INITIAL.
      CASE l_field.
        WHEN 'W_KEHRAUFT-VBELN'.
          SET PARAMETER ID 'AUN' FIELD l_aufnr.
          CALL TRANSACTION 'VA03'. "AND SKIP FIRST SCREEN.
        WHEN 'W_KEHRAUFT-FAKNR'.
          SET PARAMETER ID 'VF' FIELD l_aufnr.
          CALL TRANSACTION 'VF03'. "AND SKIP FIRST SCREEN.
        WHEN 'W_KEHRAUFT-KUNNR'.
          SET PARAMETER ID 'KUN' FIELD l_aufnr.
          CALL TRANSACTION 'FBL5N'. "AND SKIP FIRST SCREEN.
      ENDCASE.
    WHEN 'BINF'.
      CONCATENATE zsd_04_kehr_mat-berpfad
                  zsd_04_kehricht-berechnung
             INTO zsd_04_kehr_mat-berpfad.
      CALL FUNCTION 'GUI_RUN'
        EXPORTING
          command = zsd_04_kehr_mat-berpfad.
    WHEN 'KMAT'.
      CALL TRANSACTION 'ZSD_04_KEHR_MAT'.

    WHEN 'HIST'.
      SET PARAMETER ID 'ZZ_OBJ_KEY' FIELD  zsd_04_kehricht-obj_key.
      CALL TRANSACTION  'ZSD_05_LULU_CHG_PROT'."Historisierung Kehrichtverwaltung
    WHEN 'TEXT'.                 "Textnotiz pflegen
      DATA: w_function,
            w_header   TYPE thead,
            w_header_e TYPE thead,
            w_schab    LIKE ankaz-am_tdnam01,
            t_tline    TYPE tline OCCURS 0.
      MOVE: 'EQUI'   TO w_header-tdobject,
            'INTV'   TO w_header-tdid,
*            'LTXT'   TO w_header-tdid,
            sy-langu TO w_header-tdspras,
            '70'     TO w_header-tdlinesize.
      CONCATENATE '000000000'
                  zsd_04_kehricht-stadtteil
                  zsd_04_kehricht-parzelle
                  zsd_04_kehricht-objekt
             INTO w_header-tdname.
      CALL FUNCTION 'TEXT_EDIT'
        EXPORTING
          i_header     = w_header
          i_schab      = w_schab
*          i_schab_tdid = 'LTXT'
*          i_schab_tdid = '0001'
          i_schab_tdid = 'INTV'
        IMPORTING
          e_function   = w_function
          e_header     = w_header_e
        TABLES
          t_lines      = t_tline.
      IF sy-subrc <> 0.
*         message e020 with 'EDIT_TEXT'.
      ENDIF.
      CALL FUNCTION 'SAVE_TEXT'
        EXPORTING
          client          = sy-mandt
          header          = w_header_e
          insert          = ' '
          savemode_direct = 'X'
        TABLES
          lines           = t_tline.
      IF sy-subrc <> 0.
*         message e020 with 'SAVE_TEXT'.
      ENDIF.
*      CALL FUNCTION 'COMMIT_TEXT'
*       EXPORTING
*         OBJECT                = w_header-tdobject
*         NAME                  = w_header-tdname
*         ID                    = w_header-tdid
*         LANGUAGE              = sy-langu
*         SAVEMODE_DIRECT       = 'X'
*         KEEP                  = 'X'
**         LOCAL_CAT             = ' '
**       IMPORTING
**         COMMIT_COUNT          =
**       TABLES
**         T_OBJECT              =
**         T_NAME                =
**         T_ID                  =
**         T_LANGUAGE            =
*                .
*      IF sy-subrc <> 0.
**         message e020 with 'COMMIT_TEXT'.
*      ENDIF.
    WHEN 'DEBADM_EIG'.
*      IF gv_display EQ abap_true.
      PERFORM admin_customer USING abap_true
                             CHANGING zsd_04_kehricht-eigen_kunnr.
*      ELSE.
*        PERFORM admin_customer USING abap_false
*                         CHANGING gs_lulu_head-eigen_kunnr.
*      ENDIF.

    WHEN 'DEBADM_VER'.
*      IF gv_display EQ abap_true.
      PERFORM admin_customer USING abap_true
                             CHANGING zsd_04_kehricht-vertr_kunnr.
*      ELSE.
*        PERFORM admin_customer USING abap_false
*                         CHANGING gs_lulu_head-vertr_kunnr.
*      ENDIF.

    WHEN 'GET_REM_EIG'.
      IF NOT zsd_04_kehricht-kunnr IS INITIAL.
        zsd_04_kehricht-eigen_kunnr = zsd_04_kehricht-kunnr.
      ENDIF.

    WHEN 'GET_REM_VER'.
      IF NOT zsd_04_kehricht-kunnr IS INITIAL.
        zsd_04_kehricht-vertr_kunnr = zsd_04_kehricht-kunnr.
      ENDIF.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_2002  INPUT
*
*---------------------------------------------------------------------*
*       MODULE ts_objekt_active_tab_get INPUT                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE ts_objekt_active_tab_get INPUT.

  w_ucomm = sy-ucomm.
  CASE w_ucomm.
    WHEN c_ts_objekt-tab1.
      g_ts_objekt-pressed_tab = c_ts_objekt-tab1.
    WHEN c_ts_objekt-tab2.
      g_ts_objekt-pressed_tab = c_ts_objekt-tab2.
    WHEN c_ts_objekt-tab3.
      g_ts_objekt-pressed_tab = c_ts_objekt-tab3.
    WHEN OTHERS.
  ENDCASE.

ENDMODULE.                    "ts_objekt_active_tab_get INPUT
*
*---------------------------------------------------------------------*
*       MODULE TC_REGENINFO_modify INPUT                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_regeninfo_modify INPUT.

  MOVE-CORRESPONDING zsd_04_regeninfo TO g_tc_regeninfo_wa.
  MODIFY g_tc_regeninfo_itab
    FROM g_tc_regeninfo_wa
    INDEX tc_regeninfo-current_line.

ENDMODULE.                    "tc_regeninfo_modify INPUT
*
*---------------------------------------------------------------------*
*       MODULE TC_REGENINFO_mark INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_regeninfo_mark INPUT.

  IF tc_regeninfo-line_sel_mode = 1
  AND g_tc_regeninfo_wa-flag = 'X'.
    LOOP AT g_tc_regeninfo_itab INTO g_tc_regeninfo_wa WHERE flag = 'X'.
      g_tc_regeninfo_wa-flag = ''.
      MODIFY g_tc_regeninfo_itab
        FROM g_tc_regeninfo_wa
        TRANSPORTING flag.
    ENDLOOP.
    g_tc_regeninfo_wa-flag = 'X'.
  ENDIF.
  MODIFY g_tc_regeninfo_itab
    FROM g_tc_regeninfo_wa
    INDEX tc_regeninfo-current_line
    TRANSPORTING flag.

ENDMODULE.                    "tc_regeninfo_mark INPUT
*
*---------------------------------------------------------------------*
*       MODULE TC_REGENINFO_user_command INPUT                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_regeninfo_user_command INPUT.

  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_REGENINFO'
                              'G_TC_REGENINFO_ITAB'
                              'FLAG'
                     CHANGING ok_code.
  sy-ucomm = ok_code.

ENDMODULE.                    "tc_regeninfo_user_command INPUT
*
*&---------------------------------------------------------------------*
*&      Module  ADDR_REGIONAL_DATA_CHECK  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE addr_regional_data_check INPUT.

  CHECK t_object_wa-no_check_addr IS INITIAL.
  IF NOT s_insr IS INITIAL
  OR NOT s_aend IS INITIAL.
    PERFORM check_objekt.
  ENDIF.
  DATA l_adrc_struc TYPE adrc_struc.
  DATA lt_addr_error TYPE addr_error OCCURS 0 WITH HEADER LINE.
  MOVE-CORRESPONDING t_object_wa TO l_adrc_struc.
  REFRESH lt_addr_error.
  IF NOT l_adrc_struc-street IS INITIAL.
    CALL FUNCTION 'ZSD_05ADDR_REGIONAL_DATA_CHECK'
      EXPORTING
        x_adrc_struc     = l_adrc_struc
        x_dialog_allowed = 'X'
        x_accept_error   = 'X'
      IMPORTING
        y_adrc_struc     = l_adrc_struc
      TABLES
        error_table      = lt_addr_error.
    LOOP AT lt_addr_error.
    ENDLOOP.
    IF sy-subrc NE 0.
      MOVE-CORRESPONDING l_adrc_struc TO t_object_wa.
    ENDIF.
  ENDIF.
  IF t_object_wa-post_code1 IS INITIAL.
    MOVE zsd_05_objekt-post_code1 TO t_object_wa-post_code1.
  ENDIF.
  IF t_object_wa-post_code1 IS INITIAL.
    MESSAGE e000 WITH text-e25.
  ENDIF.

ENDMODULE.                 " ADDR_REGIONAL_DATA_CHECK  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_2100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_2100 INPUT.

  CASE sy-ucomm.
    WHEN 'CANC'.                 "Abbrechen
      LEAVE TO SCREEN 0.
    WHEN 'SAVE'.                 "Enter
      IF zsd_04_regeninfo-uname IS INITIAL.
        MOVE: sy-uname TO zsd_04_regeninfo-uname,
              sy-datum TO zsd_04_regeninfo-udate,
              sy-uzeit TO zsd_04_regeninfo-utime.
      ENDIF.
      MOVE: sy-uname TO zsd_04_regeninfo-cname,
            sy-datum TO zsd_04_regeninfo-cdate,
            sy-uzeit TO zsd_04_regeninfo-ctime.
      INSERT INTO zsd_04_regeninfo VALUES zsd_04_regeninfo.
      IF sy-subrc NE 0.
        UPDATE zsd_04_regeninfo FROM zsd_04_regeninfo.
      ENDIF.
      CLEAR g_tc_regeninfo_copied.
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_2100  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  verr_grund  INPUT
*&---------------------------------------------------------------------*
*       Verrechnungsgrund
*----------------------------------------------------------------------*
MODULE verr_grund_kanal INPUT.

  IF NOT zsd_04_kanal-verr_code IS INITIAL.
    IF zsd_04_kanal-verr_grund IS INITIAL.
      MESSAGE e000 WITH text-e08.
    ENDIF.
  ENDIF.
  IF NOT zsd_04_kanal-verr_code_qm IS INITIAL.
    IF zsd_04_kanal-verr_grund_qm IS INITIAL.
      MESSAGE e000 WITH text-e08.
    ENDIF.
  ENDIF.

ENDMODULE.                 " verr_grund_kanal  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  verr_grund  INPUT
*&---------------------------------------------------------------------*
*       Verrechnungsgrund
*----------------------------------------------------------------------*
MODULE verr_grund_kehricht INPUT.

  IF NOT zsd_04_kehricht-verr_code IS INITIAL.
    IF zsd_04_kehricht-verr_grund IS INITIAL.
      MESSAGE e000 WITH text-e08.
    ENDIF.
  ELSE.
    CLEAR zsd_04_kehricht-verr_grund.
  ENDIF.

ENDMODULE.                 " verr_grund_kehricht  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  verr_grund  INPUT
*&---------------------------------------------------------------------*
*       Verrechnungsgrund
*----------------------------------------------------------------------*
MODULE verr_grund_regen INPUT.

  IF NOT zsd_04_regen-verr_code IS INITIAL.
    IF zsd_04_regen-verr_grund IS INITIAL.
      MESSAGE e000 WITH text-e08.
    ENDIF.
  ENDIF.

ENDMODULE.                 " verr_grund_regen  INPUT
*&---------------------------------------------------------------------*
*&      Module  zsd_04_kanal  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE zsd_04_kanal INPUT.

  MOVE: t_object_wa-stadtteil TO zsd_04_kanal-stadtteil,
        t_object_wa-parzelle  TO zsd_04_kanal-parzelle,
        t_object_wa-objekt    TO zsd_04_kanal-objekt,
        '2850'                TO zsd_04_kanal-vkorg,
        '89'                  TO zsd_04_kanal-vtweg,
        '10'                  TO zsd_04_kanal-spart.
  IF NOT s_anle IS INITIAL
  OR NOT s_insr IS INITIAL.
    MOVE: sy-uname TO zsd_04_kanal-cname,
          sy-datum TO zsd_04_kanal-cdate,
          sy-uzeit TO zsd_04_kanal-ctime.
  ELSEIF NOT s_aend IS INITIAL.
    MOVE: sy-uname TO zsd_04_kanal-uname,
          sy-datum TO zsd_04_kanal-udate,
          sy-uzeit TO zsd_04_kanal-utime.
  ENDIF.

ENDMODULE.                 " zsd_04_kanal  INPUT
*&---------------------------------------------------------------------*
*&      Module  zsd_04_regen  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE zsd_04_regen INPUT.

  MOVE: t_object_wa-stadtteil TO zsd_04_regen-stadtteil,
        t_object_wa-parzelle  TO zsd_04_regen-parzelle,
        t_object_wa-objekt    TO zsd_04_regen-objekt.
  IF NOT s_anle IS INITIAL
  OR NOT s_insr IS INITIAL.
    MOVE: sy-uname TO zsd_04_regen-cname,
          sy-datum TO zsd_04_regen-cdate,
          sy-uzeit TO zsd_04_regen-ctime.
  ELSEIF NOT s_aend IS INITIAL.
    MOVE: sy-uname TO zsd_04_regen-uname,
          sy-datum TO zsd_04_regen-udate,
          sy-uzeit TO zsd_04_regen-utime.
  ENDIF.

ENDMODULE.                 " zsd_04_regen  INPUT
*&---------------------------------------------------------------------*
*&      Module  zsd_04_kehricht  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE zsd_04_kehricht INPUT.

  MOVE: t_object_wa-stadtteil TO zsd_04_kehricht-stadtteil,
        t_object_wa-parzelle  TO zsd_04_kehricht-parzelle,
        t_object_wa-objekt    TO zsd_04_kehricht-objekt.
  CONCATENATE zsd_04_kehricht-stadtteil zsd_04_kehricht-parzelle zsd_04_kehricht-objekt
  into zsd_04_kehricht-obj_key.
  IF NOT s_anle IS INITIAL
  OR NOT s_insr IS INITIAL
  OR NOT s_aend IS INITIAL.
    MOVE: sy-uname TO zsd_04_kehricht-cname,
          sy-datum TO zsd_04_kehricht-cdate,
          sy-uzeit TO zsd_04_kehricht-ctime.
  ELSEIF NOT s_aend IS INITIAL.
    MOVE: sy-uname TO zsd_04_kehricht-uname,
          sy-datum TO zsd_04_kehricht-udate,
          sy-uzeit TO zsd_04_kehricht-utime.
  ENDIF.

ENDMODULE.                 " zsd_04_kehricht  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  kanal_kunnr  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE kanal_kunnr INPUT.

  DATA l_addr1_sel TYPE addr1_sel.
  DATA l_sadr TYPE sadr.
  IF NOT zsd_04_kanal-kunnr IS INITIAL.
    CLEAR zsd_04_kanal-adrnr.
    SELECT SINGLE * FROM  kna1
           WHERE  kunnr  = zsd_04_kanal-kunnr.
    IF sy-subrc NE 0.
      MESSAGE e000 WITH text-e20.
    ENDIF.
    SELECT SINGLE * FROM  knvv
           WHERE  kunnr  = zsd_04_kanal-kunnr
           AND    vkorg  = zsd_04_kanal-vkorg
           AND    vtweg  = zsd_04_kanal-vtweg
           AND    spart  = zsd_04_kanal-spart.
    IF sy-subrc NE 0.
      MESSAGE e000 WITH text-e18.
    ENDIF.
  ELSEIF NOT zsd_04_kanal-adrnr IS INITIAL.
    MOVE zsd_04_kanal-adrnr TO l_addr1_sel-addrnumber.
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
    IF l_sadr-name1 IS INITIAL.
      MESSAGE e000 WITH text-e16.
    ENDIF.
  ENDIF.
  IF zsd_04_kanal-kunnr IS INITIAL
  AND zsd_04_kanal-adrnr IS INITIAL.
*    message e000 with text-e14.
  ENDIF.

ENDMODULE.                 " kanal_kunnr  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  kehricht_kunnr  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE kehricht_kunnr INPUT.


  IF zsd_04_kehricht-eigen_kunnr IS INITIAL.
        MESSAGE e000 WITH text-e14.
    ENDIF.

  IF NOT zsd_04_kehricht-eigen_kunnr IS INITIAL.
   CLEAR zsd_04_kehricht-adrnr.
    SELECT SINGLE * FROM  kna1
           WHERE  kunnr  = zsd_04_kehricht-eigen_kunnr.
    IF sy-subrc NE 0.
      MESSAGE e000 WITH text-e20.
    ENDIF.
*    SELECT SINGLE * FROM  knvv
*           WHERE  kunnr  = zsd_04_kehricht-kunnr
*           AND    vkorg  = zsd_04_kehricht-vkorg
*           AND    vtweg  = zsd_04_kehricht-vtweg
*           AND    spart  = zsd_04_kehricht-spart.
*    IF sy-subrc NE 0.
*      MESSAGE e000 WITH text-e17.
*    ENDIF.
  ELSEIF NOT zsd_04_kehricht-adrnr IS INITIAL.
*    MOVE zsd_04_kehricht-adrnr TO l_addr1_sel-addrnumber.
*    CALL FUNCTION 'ADDR_GET'
*      EXPORTING
*        address_selection = l_addr1_sel
*        read_sadr_only    = ' '
*        read_texts        = ' '
*      IMPORTING
*        sadr              = l_sadr
*      EXCEPTIONS
*        parameter_error   = 1
*        address_not_exist = 2
*        version_not_exist = 3
*        internal_error    = 4
*        OTHERS            = 5.
*    IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*    ENDIF.
*    IF l_sadr-name1 IS INITIAL.
*      MESSAGE e000 WITH text-e16.
*    ENDIF.
*  ENDIF.
*  IF zsd_04_kehricht-kunnr IS INITIAL
*  AND zsd_04_kehricht-adrnr IS INITIAL.
*    IF NOT w_flaeche IS INITIAL
*    OR NOT zsd_04_kehricht-jahresgebuehr IS INITIAL.
*      MESSAGE e000 WITH text-e14.
*    ENDIF.
  ENDIF.

ENDMODULE.                 " kehricht_kunnr  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  regen_kunnr  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE regen_kunnr INPUT.

  IF NOT zsd_04_regen-kunnr IS INITIAL.
    CLEAR zsd_04_regen-adrnr.
    SELECT SINGLE * FROM  kna1
           WHERE  kunnr  = zsd_04_regen-kunnr.
    IF sy-subrc NE 0.
      MESSAGE e000 WITH text-e20.
    ENDIF.
    SELECT SINGLE * FROM  knvv
           WHERE  kunnr  = zsd_04_regen-kunnr
           AND    vkorg  = zsd_04_regen-vkorg
           AND    vtweg  = zsd_04_regen-vtweg
           AND    spart  = zsd_04_regen-spart.
    IF sy-subrc NE 0.
      MESSAGE e000 WITH text-e19.
    ENDIF.
  ELSEIF NOT zsd_04_regen-adrnr IS INITIAL.
    MOVE zsd_04_regen-adrnr TO l_addr1_sel-addrnumber.
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
    IF l_sadr-name1 IS INITIAL.
      MESSAGE e000 WITH text-e16.
    ENDIF.
  ENDIF.
*  IF zsd_04_regen-kunnr IS INITIAL
*  AND zsd_04_regen-adrnr IS INITIAL.
*    MESSAGE e000 WITH text-e14.
*  ENDIF.

ENDMODULE.                 " regen_kunnr  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  eigentuemer  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE eigentuemer INPUT.

  IF NOT zsd_05_objekt-eigentuemer IS INITIAL.
    CLEAR zsd_05_objekt-addrnumber_eig.
    SELECT SINGLE * FROM  kna1
           WHERE  kunnr  = zsd_05_objekt-eigentuemer.
    IF sy-subrc NE 0.
      MESSAGE e000 WITH text-e20.
    ENDIF.
  ELSEIF NOT zsd_05_objekt-addrnumber_eig IS INITIAL.
    MOVE zsd_05_objekt-addrnumber_eig TO l_addr1_sel-addrnumber.
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
    IF l_sadr-name1 IS INITIAL.
      MESSAGE e000 WITH text-e16.
    ENDIF.
  ENDIF.

ENDMODULE.                 " eigentuemer  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  baurecht  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE baurecht INPUT.

  IF zsd_05_objekt-sgrart = 2
  AND zsd_05_objekt-brparzelle IS INITIAL.
    MESSAGE e000 WITH text-e15.
  ENDIF.

ENDMODULE.                 " baurecht  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  zsd_04_boden  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE zsd_04_boden INPUT.

  MOVE: t_object_wa-stadtteil TO zsd_04_boden-stadtteil,
        t_object_wa-parzelle  TO zsd_04_boden-parzelle,
        t_object_wa-objekt    TO zsd_04_boden-objekt.
  IF NOT s_anle IS INITIAL
  OR NOT s_insr IS INITIAL.
    MOVE: sy-uname TO zsd_04_boden-cname,
          sy-datum TO zsd_04_boden-cdate,
          sy-uzeit TO zsd_04_boden-ctime.
  ELSEIF NOT s_aend IS INITIAL.
    MOVE: sy-uname TO zsd_04_boden-uname,
          sy-datum TO zsd_04_boden-udate,
          sy-uzeit TO zsd_04_boden-utime.
  ENDIF.

ENDMODULE.                 " zsd_04_boden  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  boden_kunnr  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE boden_kunnr INPUT.

  IF NOT zsd_04_boden-kunnr IS INITIAL.
    CLEAR zsd_04_boden-adrnr.
    SELECT SINGLE * FROM  kna1
           WHERE  kunnr  = zsd_04_boden-kunnr.
    IF sy-subrc NE 0.
      MESSAGE e000 WITH text-e20.
    ENDIF.
    SELECT SINGLE * FROM  knvv
           WHERE  kunnr  = zsd_04_boden-kunnr
           AND    vkorg  = zsd_04_boden-vkorg
           AND    vtweg  = zsd_04_boden-vtweg
           AND    spart  = zsd_04_boden-spart.
    IF sy-subrc NE 0.
      MESSAGE e000 WITH text-e21.
    ENDIF.
  ELSEIF NOT zsd_04_boden-adrnr IS INITIAL.
    MOVE zsd_04_boden-adrnr TO l_addr1_sel-addrnumber.
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
    IF l_sadr-name1 IS INITIAL.
      MESSAGE e000 WITH text-e16.
    ENDIF.
  ENDIF.
*  IF zsd_04_boden-kunnr IS INITIAL
*  AND zsd_04_boden-adrnr IS INITIAL.
*    MESSAGE e000 WITH text-e14.
*  ENDIF.

ENDMODULE.                 " boden_kunnr  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  eigentuemer_obj  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE eigentuemer_obj INPUT.

  IF NOT t_object_wa-eigentuemer IS INITIAL.
    SELECT SINGLE * FROM  kna1
           WHERE  kunnr  = t_object_wa-eigentuemer.
    IF sy-subrc NE 0.
      MESSAGE e000 WITH text-e20.
    ENDIF.
  ELSEIF NOT t_object_wa-addrnumber_eig IS INITIAL.
    MOVE t_object_wa-addrnumber_eig TO l_addr1_sel-addrnumber.
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
    IF l_sadr-name1 IS INITIAL.
      MESSAGE e000 WITH text-e16.
    ENDIF.
  ENDIF.

ENDMODULE.                 " eigentuemer_obj  INPUT
*&---------------------------------------------------------------------*
*&      Module  Abbruch  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE abbruch INPUT.

  IF NOT t_object_wa-yabbruch IS INITIAL.
    IF zsd_04_kanal-parzelle IS INITIAL.
      SELECT SINGLE * FROM  zsd_04_kanal
             WHERE  stadtteil  = t_object_wa-stadtteil
             AND    parzelle   = t_object_wa-parzelle
             AND    objekt     = t_object_wa-objekt.
      CHECK sy-subrc = 0.
    ENDIF.
    MOVE: 'X' TO zsd_04_kanal-verr_code_qm,
          'X' TO zsd_04_kanal-verr_code.
    CONCATENATE zsd_04_kanal-verr_grund
                'Abbruch'
                t_object_wa-yabbruch
           INTO zsd_04_kanal-verr_grund SEPARATED BY space.
    CONCATENATE zsd_04_kanal-verr_grund_qm
                'Abbruch'
                t_object_wa-yabbruch
           INTO zsd_04_kanal-verr_grund_qm SEPARATED BY space.
  ENDIF.

ENDMODULE.                 " Abbruch  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  kehricht-vkbur  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE kehricht-vkbur INPUT.

  SELECT SINGLE * FROM  tvkbz
         WHERE  vkorg  = zsd_04_kehricht-vkorg
         AND    vtweg  = zsd_04_kehricht-vtweg
         AND    spart  = zsd_04_kehricht-spart
         AND    vkbur  = zsd_04_kehricht-vkbur.
  IF sy-subrc NE 0.
    MESSAGE e000 WITH 'Verkaufsbüro nicht zulässig'.
  ENDIF.
  IF zsd_04_kehricht-vkbur = '8700'
  OR zsd_04_kehricht-vkbur = '8710'.
    MESSAGE e000 WITH 'Verkaufsbüro nicht zulässig'.
  ENDIF.

ENDMODULE.                 " kehricht-vkbur  INPUT
*&---------------------------------------------------------------------*
*&      Module  kehricht_verr  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE kehricht_verr INPUT.

  IF zsd_04_kehricht-verr_code IS INITIAL.
    IF w_flaechev NE 0
    OR zsd_04_kehricht-jahresgebuehr NE 0.
      IF zsd_04_kehricht-verr_perio IS INITIAL.
        MESSAGE e000 WITH 'Verr.-Period. darf nicht leer sein!'.
      ENDIF.
      IF zsd_04_kehricht-verr_datum IS INITIAL.
        MESSAGE e000 WITH 'Bitte Datum Verrechnungsstart eingeben'.
      ENDIF.
    ENDIF.
  ENDIF.

ENDMODULE.                 " kehricht_verr  INPUT
*&---------------------------------------------------------------------*
*&      Module  kehricht_berechnung  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE kehricht_berechnung INPUT.

  IF zsd_04_kehricht-jahresgebuehr NE 0.
    IF zsd_04_kehricht-berechnung IS INITIAL.
      MESSAGE e000 WITH 'Bitte Informationen zur Berechnungsdatei füllen'.
    ENDIF.
  ELSE.
    IF NOT zsd_04_kehricht-berechnung IS INITIAL.
      MESSAGE s000 WITH 'Keine Jahresgebühr!'
                   'Informationen zur Berechnungsdatei wurden gelöscht'.
      CLEAR zsd_04_kehricht-berechnung.
    ENDIF.
  ENDIF.

ENDMODULE.                 " kehricht_berechnung  INPUT
*&---------------------------------------------------------------------*
*&      Module  datum  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE datum INPUT.

  IF NOT w_flaeche IS INITIAL
  OR NOT zsd_04_kehricht-jahresgebuehr IS INITIAL.
    IF zsd_04_kehricht-verr_datum+6(2) NE '01'.
      MOVE '01' TO zsd_04_kehricht-verr_datum+6(2).
    ENDIF.
  ENDIF.
  IF NOT zsd_04_kehricht-verr_datum_schl IS INITIAL.
    CALL FUNCTION 'LAST_DAY_OF_MONTHS'
      EXPORTING
        day_in            = zsd_04_kehricht-verr_datum_schl
      IMPORTING
        last_day_of_month = zsd_04_kehricht-verr_datum_schl
      EXCEPTIONS
        day_in_no_date    = 1
        OTHERS            = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ELSE.
    IF sy-datum+0(4) GT 2007.
      zsd_04_kehricht-verr_datum_schl = '99991231'.
    ELSE.
      zsd_04_kehricht-verr_datum_schl = '20071231'.
    ENDIF.
  ENDIF.

ENDMODULE.                 " datum  INPUT
*&---------------------------------------------------------------------*
*&      Module  BEMERKUNGEN  INPUT
*&---------------------------------------------------------------------*
MODULE bemerkungen INPUT.

  MOVE: sy-uname TO t_object_wa-bemerkung_sb,
        sy-datum TO t_object_wa-bemerkung_datum.

ENDMODULE.                 " BEMERKUNGEN  INPUT
*&---------------------------------------------------------------------*
*&      Module  BEMERKUNGEN_CLEAR  INPUT
MODULE bemerkungen_clear INPUT.

  IF t_object_wa-bemerkung IS INITIAL.
    CLEAR: t_object_wa-bemerkung_sb,
           t_object_wa-bemerkung_datum.
  ENDIF.

ENDMODULE.                 " BEMERKUNGEN_CLEAR  INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'RUECKERSTATTUNG'. DO NOT CHANGE THIS LI
*&SPWIZARD: MODIFY TABLE
MODULE rueckerstattung_modify INPUT.
  MOVE-CORRESPONDING zsd_05_kehr_ruec TO g_rueckerstattung_wa.
  MODIFY g_rueckerstattung_itab
    FROM g_rueckerstattung_wa
    INDEX rueckerstattung-current_line.
  LOOP AT SCREEN.
    screen-input = ' '.
  ENDLOOP.
  MODIFY SCREEN.
ENDMODULE.                    "RUECKERSTATTUNG_MODIFY INPUT

*&SPWIZARD: INPUT MODULE FOR TC 'RUECKERSTATTUNG'. DO NOT CHANGE THIS LI
*&SPWIZARD: PROCESS USER COMMAND
MODULE rueckerstattung_user_command INPUT.


  PERFORM user_ok_tc USING    'RUECKERSTATTUNG'
                              'G_RUECKERSTATTUNG_ITAB'
                              'FLAG'
                     CHANGING ok_code.

  LOOP AT g_rueckerstattung_itab INTO g_rueckerstattung_wa.
    IF g_rueckerstattung_wa-flag = 'X'.
      EXIT.
    ENDIF.
  ENDLOOP.

  save_dat_von = 0.
  save_dat_bis = 0.

  CASE sy-ucomm.
    WHEN 'TC_RUECK_INS'.
      CLEAR zsd_05_kehr_ruec.
      zsd_05_kehr_ruec-stadtteil      = zsd_05_objekt-stadtteil.
      zsd_05_kehr_ruec-parzelle       = zsd_05_objekt-parzelle.
      zsd_05_kehr_ruec-objekt         = t_object_wa-objekt.
      zsd_05_kehr_ruec-bearbeitet_von = sy-uname.
      zsd_05_kehr_ruec-bearbeitet_am  = sy-datum.
      zsd_05_kehr_ruec-total_qm       = w_flaechev.
      zsd_05_kehr_ruec-verrbetr       = zsd_04_kehricht-jahresgebuehr.

      CLEAR: zsd_05_kehr_ruec-von_datum, zsd_05_kehr_ruec-bis_datum,zsd_05_kehr_ruec-jahr,
      zsd_05_kehr_ruec-datum_eingang,zsd_05_kehr_ruec-tage,zsd_05_kehr_ruec-monate,
      zsd_05_kehr_ruec-total_monate, zsd_05_kehr_ruec-total_tage,
      zsd_05_kehr_ruec-leerstand_qm,zsd_05_kehr_ruec-rueckbetr,
      zsd_05_kehr_ruec-datum_brief,zsd_05_kehr_ruec-mahnung1,zsd_05_kehr_ruec-mahnung2,
      zsd_05_kehr_ruec-versdatum.

      save_ucomm2 = sy-ucomm.

      CALL SCREEN 3000 STARTING AT 20 5.
      g_rueckerstattung_copied = ' '.
      sy-ucomm = ' '.
      save_ucomm2 = ' '.

    WHEN 'TC_RUECK_DET'.
      SELECT SINGLE * FROM zsd_05_kehr_ruec
      WHERE stadtteil = zsd_05_objekt-stadtteil
        AND parzelle  = zsd_05_objekt-parzelle
        AND objekt    = t_object_wa-objekt
        AND jahr      = g_rueckerstattung_wa-jahr
        AND von_datum = g_rueckerstattung_wa-von_datum
        AND bis_datum = g_rueckerstattung_wa-bis_datum.

      save_dat_von = zsd_05_kehr_ruec-von_datum.
      save_dat_bis = zsd_05_kehr_ruec-bis_datum.
      CALL SCREEN 3000  STARTING AT 15 1.
      g_rueckerstattung_copied = ' '.
      sy-ucomm = ' '.
      save_ucomm2 = ' '.

    WHEN 'TC_RUECK_DEL'.
      DATA: antwort.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = ' Löschen bestätigen'
          text_question         = 'Wollen Sie wirklich löschen?'
          text_button_1         = 'Ja'(001)
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = 'Nein'(002)
          icon_button_2         = 'ICON_CANCEL'
          default_button        = '1'
          display_cancel_button = ''
        IMPORTING
          answer                = antwort.

      IF antwort = '1'.
        DELETE FROM zsd_05_kehr_ruec
        WHERE stadtteil = zsd_05_objekt-stadtteil
          AND parzelle  = zsd_05_objekt-parzelle
          AND objekt    = t_object_wa-objekt
          AND jahr      = g_rueckerstattung_wa-jahr
          AND von_datum = g_rueckerstattung_wa-von_datum
          AND bis_datum = g_rueckerstattung_wa-bis_datum.
        IF sy-subrc NE 0.
          MESSAGE e000 WITH 'Datensatz konnte nicht gelöscht werden'.
        ENDIF.
      ENDIF.

      g_rueckerstattung_copied = ' '.
      sy-ucomm = ' '.

  ENDCASE.

ENDMODULE.                    "RUECKERSTATTUNG_USER_COMMAND INPUT

*----------------------------------------------------------------------*
*  MODULE user_command_3000
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
MODULE user_command_3000.

  g_rueckerstattung_copied = ' '.

  CASE sy-ucomm.

    WHEN 'BACK'.                 "Zurück
      sy-ucomm = ' '.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'CANC'.                 "Abbrechen
      sy-ucomm = ' '.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'EXIT'.                 "Beenden
      sy-ucomm = ' '.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'TESTEN'.
      PERFORM check_input.
      IF sw_fehler NE 0.
        sy-ucomm = ' '.
        EXIT.
      ENDIF.
      PERFORM berechnungen.
      IF sw_fehler NE 0.
        sy-ucomm = ' '.
        EXIT.
      ENDIF.
      sy-ucomm = ' '.

    WHEN 'RAUSDA'.
      sy-ucomm = ' '.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'BEENDEN'.
      PERFORM check_input.
      IF sw_fehler NE 0.
        sy-ucomm = ' '.
        EXIT.
      ENDIF.
      PERFORM berechnungen.
      IF sw_fehler NE 0.
        sy-ucomm = ' '.
        EXIT.
      ENDIF.
      MODIFY zsd_05_kehr_ruec FROM zsd_05_kehr_ruec.
      IF sy-subrc NE 0.
        MESSAGE e000 WITH 'Datensatz konnte nicht gesichert werden'.
      ENDIF.
      sy-ucomm = ' '.
      SET SCREEN 0.
      LEAVE SCREEN.

  ENDCASE.
ENDMODULE.                    "user_command_3000



*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_input.

  DATA: wa_rueck TYPE zsd_05_kehr_ruec.
  DATA: v_jahr(4).

  sw_fehler = 0.

  IF zsd_05_kehr_ruec-jahr = ' '.
    MESSAGE i000 WITH 'Bitte Jahr eingeben'.
    sw_fehler = 1.
    EXIT.
  ENDIF.
  IF zsd_05_kehr_ruec-jahr < 1990.
    MESSAGE i000 WITH 'Bitte gültiges Jahr eingeben'.
    sw_fehler = 1.
    EXIT.
  ENDIF.
  IF zsd_05_kehr_ruec-datum_eingang = 0.
    MESSAGE i000 WITH 'Bitte Eingangs-Datum eingeben'.
    sw_fehler = 2.
    EXIT.
  ENDIF.
  IF zsd_05_kehr_ruec-von_datum = 0.
    MESSAGE i000 WITH 'Bitte Von Datum eingeben'.
    sw_fehler = 3.
    EXIT.
  ENDIF.

  IF zsd_05_kehr_ruec-bis_datum = 0.
    MESSAGE i000 WITH 'Bitte Bis Datum eingeben'.
    sw_fehler = 4.
    EXIT.
  ENDIF.

* Datum Prüfungen
  IF zsd_05_kehr_ruec-von_datum > zsd_05_kehr_ruec-bis_datum.
    MESSAGE i000 WITH 'Von Datum grösser Bis Datum'.
    sw_fehler = 5.
    EXIT.
  ENDIF.

  v_jahr = zsd_05_kehr_ruec-von_datum(4).
  IF v_jahr NE zsd_05_kehr_ruec-jahr.
    MESSAGE i000 WITH 'Verrechnung nicht im Kalenderjahr'.
    sw_fehler = 6.
    EXIT.
  ENDIF.

  v_jahr = zsd_05_kehr_ruec-bis_datum(4).
  IF v_jahr NE zsd_05_kehr_ruec-jahr.
    MESSAGE i000 WITH 'Verrechnung nicht im Kalenderjahr'.
    sw_fehler = 6.
    EXIT.
  ENDIF.

  SELECT SINGLE * FROM zsd_05_kehr_ruec INTO wa_rueck
   WHERE stadtteil  = zsd_05_kehr_ruec-stadtteil
     AND parzelle   = zsd_05_kehr_ruec-parzelle
     AND objekt     = zsd_05_kehr_ruec-objekt
     AND jahr       = zsd_05_kehr_ruec-jahr

     AND ( ( von_datum <= zsd_05_kehr_ruec-von_datum AND
             bis_datum >= zsd_05_kehr_ruec-von_datum     )

       OR  ( bis_datum <= zsd_05_kehr_ruec-bis_datum AND
             von_datum >= zsd_05_kehr_ruec-bis_datum     )   ).

  IF sy-subrc = 0.
    " überlappung VON Datum
    IF save_ucomm2 = 'TC_RUECK_INS'.
      MESSAGE e105. "'Zeitraum bereits erfasst'.
      sw_fehler = 7.
      EXIT.
    ENDIF.

    IF ( save_dat_von  NE zsd_05_kehr_ruec-von_datum OR
         save_dat_bis  NE zsd_05_kehr_ruec-bis_datum )
    AND ( save_dat_bis NE 0 AND save_dat_von NE 0 ).
      MESSAGE e105. "'Zeitraum bereits erfasst'.
      sw_fehler = 8.
      EXIT.
    ENDIF.
  ENDIF.

* Eingegebene Fläche mit Total Fläche vergleichen
  IF zsd_05_kehr_ruec-total_qm > w_flaechev
  AND w_flaechev > 0.
    MESSAGE i000 WITH 'Eingegebene Fläche zu gross'.
    sw_fehler = 9.
    EXIT.
  ENDIF.

* Eingegebene Fläche mit Total Fläche vergleichen
  IF zsd_05_kehr_ruec-leerstand_qm > w_flaechev
  AND w_flaechev > 0.
    MESSAGE i000 WITH 'Eingegebener Leerstand zu gross'.
    sw_fehler = 10.
    EXIT.
  ENDIF.

ENDFORM.                    "check_input

*&---------------------------------------------------------------------*
*&      Form  Berechnungen
*&---------------------------------------------------------------------*
FORM berechnungen.

  sw_fehler = 0.
  CLEAR zsd_05_kehr_ruec-rueckbetr.

*----------------------------------------------------------------------*
* Anzahl Tage errechnen

  CALL FUNCTION 'PRICING_DETERMINE_DATES'
    EXPORTING
      date_begin = zsd_05_kehr_ruec-von_datum
      date_end   = zsd_05_kehr_ruec-bis_datum
    IMPORTING
      days       = anz_tage
*     months     =
*     YEARS      =
*     WEEKS      =
    .

  zsd_05_kehr_ruec-total_tage         = anz_tage.

*----------------------------------------------------------------------*
* Anzahl Monate errechnen

  DATA: anz_mon TYPE anz_monate.

  CALL FUNCTION 'PRICING_DETERMINE_DATES'
    EXPORTING
      date_begin = zsd_05_kehr_ruec-von_datum
      date_end   = zsd_05_kehr_ruec-bis_datum
    IMPORTING
*     DAYS       =
      months     = anz_mon
*     YEARS      =
*     WEEKS      =
    .

  anz_monate = anz_mon.

  zsd_05_kehr_ruec-monate = anz_monate.

  DATA: anz_v_monate TYPE zsd_05_kehr_ruec-monate.
  DATA: wa_ruec      TYPE zsd_05_kehr_ruec.
  DATA: lb_datum     TYPE sy-datum.

  " letzte Rückerstattungsperiode ohne Verrechnung suchen
  " und Vormonate einbeziehen
  lb_datum = zsd_05_kehr_ruec-von_datum - 1.
  CLEAR wa_ruec.
  SELECT SINGLE * FROM zsd_05_kehr_ruec INTO wa_ruec
   WHERE stadtteil = zsd_05_kehr_ruec-stadtteil
     AND parzelle  = zsd_05_kehr_ruec-parzelle
     AND objekt    = zsd_05_kehr_ruec-objekt
*     AND rueckbetr = 0
     AND bis_datum = lb_datum.

  " Anzahl Monate inkl. Vorperiode
  anz_v_monate = wa_ruec-monate + anz_monate.
  zsd_05_kehr_ruec-total_monate = anz_v_monate.
  zsd_05_kehr_ruec-total_tage   = zsd_05_kehr_ruec-total_tage + wa_ruec-total_tage.
*----------------------------------------------------------------------*
* Anzahl Tage Kalenderjahr errechnen
  DATA: jahr_von(8).
  DATA: jahr_bis(8).
  DATA: j_von TYPE sy-datum.
  DATA: j_bis TYPE sy-datum.

  CONCATENATE zsd_05_kehr_ruec-jahr '01' '01' INTO jahr_von.
  CONCATENATE zsd_05_kehr_ruec-jahr '12' '31' INTO jahr_bis.

  j_von = jahr_von.
  j_bis = jahr_bis.

  CALL FUNCTION 'PRICING_DETERMINE_DATES'
    EXPORTING
      date_begin = j_von
      date_end   = j_bis
    IMPORTING
      days       = anz_tage_jahr
*     months     = anz_mon
*     YEARS      =
*     WEEKS      =
    .

*----------------------------------------------------------------------*
* Fehlende Eingaben ergänzen

  IF zsd_05_kehr_ruec-total_qm = 0.
    " keine Total-Fläche eingegeben: heranziehen aus Kopfdaten
    IF w_flaechev = 0.
      MESSAGE e103. " 'Keine Total Fläche zum Verrechnen gefunden'.
      EXIT.
    ELSE.
      zsd_05_kehr_ruec-total_qm = w_flaechev.
    ENDIF.
  ENDIF.

  IF zsd_05_kehr_ruec-verrbetr = 0.
    " kein Verrechneter Betrag eingegeben: heranziehen Jahresgebühr
    IF zsd_04_kehricht-jahresgebuehr = 0.

      LOOP AT SCREEN.
        screen-input = '1'.
        MODIFY SCREEN.
      ENDLOOP.
      sw_fehler = 'X'.
      MESSAGE i102. " 'Keine Jahresgebühr zum Verrechnen gefunden'.

      EXIT.
    ELSE.
      zsd_05_kehr_ruec-verrbetr = zsd_04_kehricht-jahresgebuehr.
    ENDIF.
  ENDIF.

*----------------------------------------------------------------------*
* Rückerstattung berechnen

  " Leerstand muss > 50% des Totalen Fläche sein
  DATA: prozent_leerstand_p1(6)    TYPE p DECIMALS 2.
  DATA: prozent_leerstand_p2(6)    TYPE p DECIMALS 2.
  DATA: a_prozent_leerstand_p1(6)  TYPE p DECIMALS 2.
  DATA: a_prozent_leerstand_p2(6)  TYPE p DECIMALS 2.
  DATA: tot_tage_leerstand(3)      TYPE n.
  DATA: anz_tage_p1             TYPE anz_tage. "n.
  DATA: anz_tage_p2             TYPE anz_tage. "n.
  DATA: disp_prozent(2)            TYPE n.
  DATA: meldung(40).

  " Prozent Leerstand pro Periode
  prozent_leerstand_p1 = ( 100 * wa_ruec-leerstand_qm )          / wa_ruec-total_qm.
  prozent_leerstand_p2 = ( 100 * zsd_05_kehr_ruec-leerstand_qm ) / zsd_05_kehr_ruec-total_qm.

  " Anzahl Tage beide Perioden
  IF wa_ruec-von_datum NE 0.
    CALL FUNCTION 'PRICING_DETERMINE_DATES'
      EXPORTING
        date_begin = wa_ruec-von_datum
        date_end   = wa_ruec-bis_datum
      IMPORTING
        days       = anz_tage_p1
*       months     =
*       YEARS      =
*       WEEKS      =
      .
  ENDIF.

  CALL FUNCTION 'PRICING_DETERMINE_DATES'
    EXPORTING
      date_begin = zsd_05_kehr_ruec-von_datum
      date_end   = zsd_05_kehr_ruec-bis_datum
    IMPORTING
      days       = anz_tage_p2
*     months     =
*     YEARS      =
*     WEEKS      =
    .

  tot_tage_leerstand = anz_tage_p1 + anz_tage_p2.

  " Anteil Prozent pro Periode
  a_prozent_leerstand_p1 = ( prozent_leerstand_p1 * anz_tage_p1 ) / tot_tage_leerstand.
  a_prozent_leerstand_p2 = ( prozent_leerstand_p2 * anz_tage_p2 ) / tot_tage_leerstand.

  " Durchschnittliche Prozent beider Perioden
  IF prozent_leerstand_p1 NE 100
  OR prozent_leerstand_p2 NE 100.
    zsd_05_kehr_ruec-proz_leerstand = ( a_prozent_leerstand_p1 + a_prozent_leerstand_p2 ). " / 2.
  ELSE.
    zsd_05_kehr_ruec-proz_leerstand = prozent_leerstand_p2.
  ENDIF.

  IF zsd_05_kehr_ruec-proz_leerstand <= '50.00'.
    disp_prozent = zsd_05_kehr_ruec-proz_leerstand.
    MESSAGE i101 WITH disp_prozent.
    EXIT.
  ENDIF.

  " es werden nur die Tage über 6 Monate rückerstattet
  DATA: verrdatum  LIKE zsd_05_kehr_ruec-bis_datum.
  " Startdatum bestimmen

  IF anz_v_monate > 6.   " Monate nicht verrechnet plus neue Monate
    " Startdatum + 6 Monate finden

    IF wa_ruec-von_datum = 0 . " Wenn keine Vorperiode gefunden wurde
      wa_ruec-von_datum = zsd_05_kehr_ruec-von_datum.
    ENDIF.

    CALL FUNCTION 'END_TIME_DETERMINE'
      EXPORTING
        duration   = 6                  " 6
        unit       = 'MON'              " Monate
      IMPORTING
        end_date   = verrdatum          " Resultat
      CHANGING
        start_date = wa_ruec-von_datum. " Startdatum letzte Periode

    " Es werden nur Tage im aktuellen Geschäftsjahr vergütet
    IF verrdatum(4) < zsd_05_kehr_ruec-jahr.
      CONCATENATE zsd_05_kehr_ruec-jahr '0101' INTO verrdatum.
    ENDIF.

    IF  verrdatum < zsd_05_kehr_ruec-bis_datum.
      " Anzahl Tage ab neuem Verrechungsbeginn
      CALL FUNCTION 'PRICING_DETERMINE_DATES'
        EXPORTING
          date_begin = verrdatum
          date_end   = zsd_05_kehr_ruec-bis_datum
        IMPORTING
          days       = anz_tage
*         months     =
*         YEARS      =
*         WEEKS      =
        .

      zsd_05_kehr_ruec-tage         = anz_tage.

      zsd_05_kehr_ruec-rueckbetr =
       ( zsd_05_kehr_ruec-verrbetr / anz_tage_jahr ) * zsd_05_kehr_ruec-tage.
      zsd_05_kehr_ruec-rueckbetr = ( ( zsd_05_kehr_ruec-rueckbetr / 100 ) * zsd_05_kehr_ruec-proz_leerstand ).
    ELSE.
      MESSAGE i104. " 'Leerstand kleiner 6 Monate: Keine Vergütung berechnet'.
    ENDIF.
  ELSE.
    MESSAGE i104. " 'Leerstand kleiner 6 Monate: Keine Vergütung berechnet'.
  ENDIF.

ENDFORM.                    "Berechungen
" TAGE  INPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_3000  OUTPUT
*&---------------------------------------------------------------------*

MODULE status_3000 OUTPUT.
  save_ucomm = ' '.

  SET PF-STATUS '3001'.
  SET TITLEBAR '300'.
  LOOP AT SCREEN.
    IF sy-ucomm = 'TC_RUECK_DET'
    OR save_ucomm2 = 'TC_RUECK_DET'.
      save_ucomm2 = 'TC_RUECK_DET'.
      IF screen-group1 = '300'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
      IF screen-group2 = '301'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    IF sy-ucomm = 'TC_RUECK_DEL'.
      IF screen-group1 = '300'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    IF sy-ucomm = 'TC_RUECK_INS'.
      screen-input = 1.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.
ENDMODULE.                 " STATUS_3000  OUTPUT
