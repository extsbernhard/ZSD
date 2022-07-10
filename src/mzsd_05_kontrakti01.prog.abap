*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KONTRAKTI01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_3000  INPUT
*&---------------------------------------------------------------------*
*       Weiche für Speichern, Löschen, àndern, Anzeigen, inkl. ausprogrammierung
*----------------------------------------------------------------------*
MODULE   user_command_3000 INPUT.

  ok_code = sy-ucomm.
  CASE ok_code.
*
    WHEN 'DELE'.                            "Wenn Löschen
      IF zsd_05_kontrakt-loesch IS INITIAL.
        MOVE 'X' TO zsd_05_kontrakt-loesch.
        MESSAGE s000(zsd_04) WITH text-e23.
      ENDIF.
*
    WHEN 'UNDE'.                            "Wenn unde
      IF NOT zsd_05_kontrakt-loesch IS INITIAL.
        MOVE ' ' TO zsd_05_kontrakt-loesch.
        MESSAGE s000(zsd_04) WITH text-e24.
      ENDIF.
*
    WHEN 'AEND'.                            "Wenn änderungsmodus
      PERFORM akt_backup.        "Schalter sichern
      s_aend = 'X'.
      CLEAR: s_anze,
             s_anle.
      PERFORM set_authority.
      CALL SCREEN 3000.
*
    WHEN 'ANZE'.                            "Wenn anzeigemodus
      PERFORM akt_backup.        "Schalter sichern
      s_anze = 'X'.
      CLEAR: s_aend,
             s_anle.
      PERFORM set_authority.
      CALL SCREEN 3000.
*
    WHEN 'SAVE'.                            "Wenn Speichern

      CLEAR w_count.

      IF s_anle = 'X'.
        MOVE: sy-uname TO zsd_05_kontrakt-rerf,
              sy-datum TO zsd_05_kontrakt-derf,
              sy-uzeit TO zsd_05_kontrakt-terf.

        INSERT INTO zsd_05_kontrakt VALUES zsd_05_kontrakt.
        IF sy-subrc NE 0.
          w_count = w_count + 1.
        ENDIF.
      ELSEIF s_aend = 'X'.
        MOVE: sy-uname TO zsd_05_kontrakt-rbear,
        sy-datum TO zsd_05_kontrakt-dbear,
        sy-uzeit TO zsd_05_kontrakt-tbear.

        UPDATE zsd_05_kontrakt FROM zsd_05_kontrakt.
        IF sy-subrc NE 0.
          w_count = w_count + 1.
        ENDIF.
      ENDIF.


*      IF w_zuordknr1 NE 0. "Rahmenkonzession
      CLEAR zsd_05_kontrzord.
      MOVE: sy-mandt                 TO zsd_05_kontrzord-mandt,
            zsd_05_kontrakt-kontrart TO zsd_05_kontrzord-kontrart,
            zsd_05_kontrakt-kontrnr  TO zsd_05_kontrzord-kontrnr,
            'A'                      TO zsd_05_kontrzord-zuordart,
            w_zuordknr1              TO zsd_05_kontrzord-zuordknr,
            sy-uname                 TO zsd_05_kontrzord-rerf,
            sy-datum                 TO zsd_05_kontrzord-derf,
            sy-uzeit                 TO zsd_05_kontrzord-terf.
*        INSERT INTO zsd_05_kontrzord VALUES zsd_05_kontrzord.
      MODIFY zsd_05_kontrzord FROM zsd_05_kontrzord.
*      ENDIF.
      IF sy-subrc NE 0.
        w_count = w_count + 1.
      ENDIF.





*      IF w_zuordknr2 NE 0. "Objektkonzession
      CLEAR zsd_05_kontrzord.
      MOVE: sy-mandt                 TO zsd_05_kontrzord-mandt,
            zsd_05_kontrakt-kontrart TO zsd_05_kontrzord-kontrart,
            zsd_05_kontrakt-kontrnr  TO zsd_05_kontrzord-kontrnr,
            'B'                      TO zsd_05_kontrzord-zuordart,
            w_zuordknr2              TO zsd_05_kontrzord-zuordknr,
            sy-uname                 TO zsd_05_kontrzord-rerf,
            sy-datum                 TO zsd_05_kontrzord-derf,
            sy-uzeit                 TO zsd_05_kontrzord-terf.
*        INSERT INTO zsd_05_kontrzord VALUES zsd_05_kontrzord.
      MODIFY zsd_05_kontrzord FROM zsd_05_kontrzord.
*      ENDIF.
      IF sy-subrc NE 0.
        w_count = w_count + 1.
      ENDIF.



*      IF w_zuordknr3 NE 0. "Rahmenvertrag
      CLEAR zsd_05_kontrzord.
      MOVE: sy-mandt                 TO zsd_05_kontrzord-mandt,
            zsd_05_kontrakt-kontrart TO zsd_05_kontrzord-kontrart,
            zsd_05_kontrakt-kontrnr  TO zsd_05_kontrzord-kontrnr,
            'C'                      TO zsd_05_kontrzord-zuordart,
            w_zuordknr3              TO zsd_05_kontrzord-zuordknr,
            sy-uname                 TO zsd_05_kontrzord-rerf,
            sy-datum                 TO zsd_05_kontrzord-derf,
            sy-uzeit                 TO zsd_05_kontrzord-terf.
*        INSERT INTO zsd_05_kontrzord VALUES zsd_05_kontrzord.
      MODIFY zsd_05_kontrzord FROM zsd_05_kontrzord.
*      ENDIF.
      IF sy-subrc NE 0.
        w_count = w_count + 1.
      ENDIF.



      CLEAR: w_lcount,
             wa_kontrpos.

      DESCRIBE TABLE it_kontrpos LINES w_lcount.
      IF w_lcount NE 0.
        LOOP AT it_kontrpos INTO wa_kontrpos.

          CASE wa_kontrpos-action.
            WHEN 'I'. "Insert
              MODIFY zsd_05_kontrpos FROM wa_kontrpos.
              IF sy-subrc NE 0.
                w_count = w_count + 1.
              ENDIF.
            WHEN 'U'. "Update
              MODIFY zsd_05_kontrpos FROM wa_kontrpos.
              IF sy-subrc NE 0.
                w_count = w_count + 1.
              ENDIF.
            WHEN 'D'. "Delete (Löschvermerk setzen)
              MODIFY zsd_05_kontrpos FROM wa_kontrpos.
              IF sy-subrc NE 0.
                w_count = w_count + 1.
              ENDIF.
          ENDCASE.
        ENDLOOP.
      ENDIF.



      CLEAR: w_lcount,
             wa_kontrupos_gesamt.

      DESCRIBE TABLE it_kontrupos_gesamt LINES w_lcount.
      IF w_lcount NE 0.
        LOOP AT it_kontrupos_gesamt INTO wa_kontrupos_gesamt.

          CASE wa_kontrupos_gesamt-action.
            WHEN 'I'. "Insert
              MODIFY zsd_05_kontrupos FROM wa_kontrupos_gesamt.
              IF sy-subrc NE 0.
                w_count = w_count + 1.
              ENDIF.
            WHEN 'U'. "Update
              MODIFY zsd_05_kontrupos FROM wa_kontrupos_gesamt.
              IF sy-subrc NE 0.
                w_count = w_count + 1.
              ENDIF.
            WHEN 'D'. "Delete (Löschvermerk setzen)
              MODIFY zsd_05_kontrupos FROM wa_kontrupos_gesamt.
              IF sy-subrc NE 0.
                w_count = w_count + 1.
              ENDIF.
          ENDCASE.
        ENDLOOP.
      ENDIF.


      IF     s_anle = 'X'.
        IF w_count NE 0.
          MESSAGE w000(zsd_04) WITH 'Kontrakt wurde nicht '
                                    'korrekt angelegt'.
        ELSE.
          MESSAGE s000(zsd_04) WITH 'Kontrakt wurde angelegt'.
        ENDIF.
      ELSEIF s_aend = 'X'.
        IF w_count NE 0.
          MESSAGE w000(zsd_04) WITH 'Kontrakt wurde nicht '
                                    'korrekt geändert'.
        ELSE.
          MESSAGE s000(zsd_04) WITH 'Kontrakt wurde geändert'.
        ENDIF.
      ENDIF.

      CLEAR: zsd_05_kontrakt,
             zsd_05_kontrzord,
             zsd_05_kontrpos,
             zsd_05_kontrupos.


      LEAVE TO TRANSACTION sy-tcode.
*
    WHEN 'BTNKN1'.

      w_ntyp = 'K'.
      w_proc = 'PAI'.

      IF s_anle = 'X'.
        w_ncode = 'C'.
      ELSEIF s_aend = 'X'.
        w_ncode = 'U'.
      ELSEIF s_anze = 'X'.
        w_ncode = 'R'.
      ENDIF.

      PERFORM notiz_bearb USING w_ncode w_ntyp w_proc.
*
    WHEN 'BTNDKN1'.

      w_ntyp = 'K'.
      w_proc = 'PAI'.

      IF NOT s_anle IS INITIAL
      OR NOT s_aend IS INITIAL.
        w_ncode = 'D'.
        PERFORM notiz_bearb USING w_ncode w_ntyp w_proc.
      ELSE.
        MESSAGE s000 WITH text-e09.
      ENDIF.
*
    WHEN 'ADRKNEHM'.
      PERFORM addr_dialog USING zsd_05_kontrakt-kontrnehmernr
                                zsd_05_kontrakt-adrnr.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_3000  INPUT
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRPOS_modify     INPUT                            *
*----------------------------------------------------------------------*
*       Modifiziere kotraktpositionen                                  *
*----------------------------------------------------------------------*
MODULE tc_kontrpos_modify INPUT.

  MODIFY it_kontrpos
    INDEX tc_kontrpos-current_line.

ENDMODULE.
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRPOS_mark       INPUT                            *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrpos_mark INPUT.

  IF tc_kontrpos-line_sel_mode = 1.
*  AND wa_kontrpos-flag = 'X'.
    LOOP AT it_kontrpos INTO wa_kontrpos
      WHERE flag = 'X'.
      wa_kontrpos-flag = ''.
      MODIFY it_kontrpos
        FROM wa_kontrpos
        TRANSPORTING flag.
    ENDLOOP.
*    wa_kontrpos-flag = 'X'.
  ENDIF.
  MODIFY it_kontrpos
*    FROM wa_kontrpos
    INDEX tc_kontrpos-current_line
    TRANSPORTING flag.

ENDMODULE.
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRPOS_user_command   INPUT                        *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrpos_user_command INPUT.

  ok_code = sy-ucomm.
  CLEAR: s_insr, w_adrpos.
  PERFORM user_ok_tc USING    'TC_KONTRPOS'
                              'IT_KONTRPOS'
                              'FLAG'
                              'DELABLE'
                     CHANGING ok_code.
  sy-ucomm = ok_code.

ENDMODULE.
*
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
      PERFORM knummer_freigabe.
      CALL SCREEN 1000.
      CLEAR: wa_kontrnehm.
*
    WHEN 'CANC'.
      PERFORM knummer_freigabe.
      LEAVE PROGRAM.
*
    WHEN 'EXIT'.
      PERFORM knummer_freigabe.
      LEAVE PROGRAM.
  ENDCASE.

ENDMODULE.                 " exit_command_2000  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_2000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_2000 INPUT.

  CLEAR: zsd_05_kontrakt-kontrnehmernr,
         zsd_05_kontrakt-code_kontrnehmer.

  IF NOT kna1-kunnr IS INITIAL AND NOT rb_kk1 IS INITIAL.
    zsd_05_kontrakt-kontrnehmernr    = kna1-kunnr.
    zsd_05_kontrakt-code_kontrnehmer = 'K'. "Kunde
    w_kontrnehmart                  = 'Kunde'.

  ELSEIF NOT lfa1-lifnr IS INITIAL AND NOT rb_lk1 IS INITIAL.
    zsd_05_kontrakt-kontrnehmernr    = lfa1-lifnr.
    zsd_05_kontrakt-code_kontrnehmer = 'L'. "Lieferant
    w_kontrnehmart                  = 'Lieferant'.

  ELSEIF kna1-kunnr IS INITIAL AND
         lfa1-lifnr IS INITIAL.
    zsd_05_kontrakt-kontrnehmernr = ''.

    IF NOT rb_kk1 IS INITIAL AND NOT zsd_05_kontrakt-adrnr IS INITIAL.
      zsd_05_kontrakt-code_kontrnehmer = 'K'. "manuelle Adresse Kunde
      w_kontrnehmart                  = 'Kunde'.

    ELSEIF NOT rb_lk1 IS INITIAL AND
           NOT zsd_05_kontrakt-adrnr IS INITIAL.
      zsd_05_kontrakt-code_kontrnehmer = 'L'. "man. Adresse Lieferant
      w_kontrnehmart                  = 'Lieferant'.
    ENDIF.
  ENDIF.


  ok_code = sy-ucomm.
  CASE ok_code.
*
    WHEN 'WEIT'.      "Fortsetzung Anlegen.
      IF NOT wa_kontrnehm IS INITIAL.
        PERFORM set_authority.
        CALL SCREEN 3000.
      ELSE.
        MESSAGE i000(zsd_04) WITH text-i05 text-i06 text-i07.
      ENDIF.
*
    WHEN 'ENTE'.
*
      CASE zsd_05_kontrakt-code_kontrnehmer.
*
        WHEN 'K'.
          IF NOT zsd_05_kontrakt-kontrnehmernr IS INITIAL.
            PERFORM read_kundenadr USING zsd_05_kontrakt-kontrnehmernr.
          ELSEIF NOT zsd_05_kontrakt-adrnr IS INITIAL.
            PERFORM read_adrc USING zsd_05_kontrakt-adrnr.
          ENDIF.
*
        WHEN 'L'.
          IF NOT zsd_05_kontrakt-kontrnehmernr IS INITIAL.
            PERFORM read_lieferadr USING zsd_05_kontrakt-kontrnehmernr.
          ELSEIF NOT zsd_05_kontrakt-adrnr IS INITIAL.
            PERFORM read_adrc USING zsd_05_kontrakt-adrnr.
          ENDIF.
      ENDCASE.
*
    WHEN 'ADRKNEHM'.
      PERFORM addr_dialog USING zsd_05_kontrakt-kontrnehmernr
                                zsd_05_kontrakt-adrnr.
*
    WHEN 'KART'.
*     Wird für die Radiobutton-Auswahl für im PAI benötigt.



  ENDCASE.

ENDMODULE.                 " USER_COMMAND_2000  INPUT
*
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

ENDMODULE.                 " exit_command_1000  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  check_anzeigen_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_anzeigen_1000 INPUT.

  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'ANZE' OR 'ENTE' OR 'AEND'.
      PERFORM kontrakt_vorhanden.
      IF w_subrc NE 0.
        MESSAGE e000(zsd_04) WITH text-e01 text-e02.
      ENDIF.
  ENDCASE.

ENDMODULE.                 " check_anzeigen  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1000 INPUT.

  ok_code = sy-ucomm.
  CASE ok_code.
*
    WHEN 'ANLE'.                "Anlegen
      PERFORM kontrakt_vorhanden.
      IF w_subrc = 0.
        PERFORM kontrakt_aend USING 'X'.
        IF s_aend = 'X'.
          PERFORM set_authority.
          CALL SCREEN 3000.
        ENDIF.
      ELSE.
        PERFORM kontrakt_anle USING ' '.
        PERFORM set_authority.
        CALL SCREEN 2000.
      ENDIF.
*
    WHEN 'AEND'.                 "Ändern
      PERFORM kontrakt_vorhanden.
      IF w_subrc NE 0.
        PERFORM kontrakt_anle USING 'X'.
        IF s_anle = 'X'.
          PERFORM set_authority.
          CALL SCREEN 2000.
        ENDIF.
      ELSE.
        PERFORM kontrakt_aend USING ' '.
        PERFORM set_authority.
        CALL SCREEN 3000.
      ENDIF.
*
    WHEN 'ANZE'.                 "Anzeigen
      PERFORM kontrakt_vorhanden.
      IF w_subrc = 0.
        s_anze = 'X'.
        CLEAR: s_anle,
               s_aend.
        PERFORM set_authority.
        CALL SCREEN 3000.
      ENDIF.
*
    WHEN 'ENTE'.                 "Enter
      PERFORM kontrakt_vorhanden.
      IF w_subrc = 0.
        s_anze = 'X'.
        CLEAR: s_anle,
               s_aend.
        PERFORM set_authority.
        CALL SCREEN 3000.
      ENDIF.
*
    WHEN 'DELE'.                 "Löschen
      PERFORM kontrakt_vorhanden.
      IF w_subrc NE 0.
        MESSAGE e000(zsd_04) WITH text-e01 text-e02.
      ELSE.
        PERFORM kontrakt_dele.
      ENDIF.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_1000  INPUT
*
*----------------------------------------------------------------------*
*       MODULE TS_KONTRAKT_active_tab_get    INPUT                     *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE ts_kontrakt_active_tab_get INPUT.

  ok_code = sy-ucomm.
  CASE ok_code.
*
    WHEN c_ts_kontrakt-tab1.
      g_ts_kontrakt-pressed_tab = c_ts_kontrakt-tab1.
*
    WHEN c_ts_kontrakt-tab2.
      g_ts_kontrakt-pressed_tab = c_ts_kontrakt-tab2.
*
    WHEN c_ts_kontrakt-tab3.
      g_ts_kontrakt-pressed_tab = c_ts_kontrakt-tab3.
*
    WHEN OTHERS.
*      DO NOTHING
  ENDCASE.

ENDMODULE.
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRZORD_modify     INPUT                           *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrzord_modify INPUT.

  MODIFY it_kontrzord
    INDEX tc_kontrzord-current_line.

ENDMODULE.
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRZORD_mark      INPUT                            *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrzord_mark INPUT.

  IF tc_kontrzord-line_sel_mode = 1.
*  AND wa_kontrzord-flag = 'X'.
    LOOP AT it_kontrzord INTO wa_kontrzord
      WHERE flag = 'X'.
      wa_kontrzord-flag = ''.
      MODIFY it_kontrzord
        FROM wa_kontrzord
        TRANSPORTING flag.
    ENDLOOP.
*    wa_kontrzord-flag = 'X'.
  ENDIF.
  MODIFY it_kontrzord
*    FROM wa_kontrzord
    INDEX tc_kontrzord-current_line
    TRANSPORTING flag.

ENDMODULE.
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRZORD_user_command    INPUT                      *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrzord_user_command INPUT.

  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_KONTRZORD'
                              'IT_KONTRZORD'
                              'FLAG'
                              ''
                     CHANGING ok_code.
  sy-ucomm = ok_code.

ENDMODULE.
*
*&---------------------------------------------------------------------*
*&      Module  user_command_4000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_4000 INPUT.

  ok_code = sy-ucomm.
  CASE ok_code.
*
    WHEN 'AEND'.               "Aendern
      PERFORM akt_backup.        "Schalter sichern
      s_aend = 'X'.
      CLEAR: s_anze,
             s_anle.
      PERFORM set_authority.
      CALL SCREEN 4000.
*
    WHEN 'ANZE'.                 "Anzeigen
      PERFORM akt_backup.        "Schalter sichern
      s_anze = 'X'.
      CLEAR: s_aend,
             s_anle.
      PERFORM set_authority.
      CALL SCREEN 4000.
*
    WHEN 'SAVE'.                 "Sichern
      CLEAR: wa_kontrpos,
             w_lcount,
             g_tc_kontrupos_copied.

*      DESCRIBE TABLE it_kontrupos_gesamt LINES w_lcount.
*      IF w_lcount NE 0.
*        LOOP AT it_kontrupos_gesamt INTO wa_kontrupos
*          WHERE  posnr = zsd_05_kontrpos-posnr.
*
*          DELETE TABLE it_kontrupos FROM wa_kontrupos.
*        ENDLOOP.
*      ENDIF.

      CLEAR w_lcount.

      DESCRIBE TABLE it_kontrupos LINES w_lcount.
*
      IF w_lcount NE 0.
        LOOP AT it_kontrupos INTO wa_kontrupos.
          IF wa_kontrupos-action = 'I'.
            MOVE : sy-uname TO wa_kontrupos-rerf,
                   sy-datum TO wa_kontrupos-derf,
                   sy-uzeit TO wa_kontrupos-terf.

            READ TABLE it_kontrupos_gesamt WITH KEY
                                     mandt    = wa_kontrupos-mandt
                                     kontrart = wa_kontrupos-kontrart
                                     kontrnr  = wa_kontrupos-kontrnr
                                     posnr    = wa_kontrupos-posnr
                                     uposnr   = wa_kontrupos-uposnr.
            IF sy-subrc NE 0.
              APPEND wa_kontrupos TO it_kontrupos_gesamt.
            ELSE.
              MODIFY it_kontrupos_gesamt FROM wa_kontrupos
                INDEX sy-tabix.
            ENDIF.
*
          ELSEIF wa_kontrupos-action = 'U'.
            MOVE : sy-uname TO wa_kontrupos-rbear,
                   sy-datum TO wa_kontrupos-dbear,
                   sy-uzeit TO wa_kontrupos-tbear.

            READ TABLE it_kontrupos_gesamt WITH KEY
                                     mandt    = wa_kontrupos-mandt
                                     kontrart = wa_kontrupos-kontrart
                                     kontrnr  = wa_kontrupos-kontrnr
                                     posnr    = wa_kontrupos-posnr
                                     uposnr   = wa_kontrupos-uposnr.
            IF sy-subrc EQ 0.
              MODIFY it_kontrupos_gesamt FROM wa_kontrupos
                INDEX sy-tabix.
            ENDIF.
*
          ELSEIF wa_kontrupos-action = 'D'.
            MOVE : sy-uname TO wa_kontrupos-rbear,
                   sy-datum TO wa_kontrupos-dbear,
                   sy-uzeit TO wa_kontrupos-tbear.

            READ TABLE it_kontrupos_gesamt WITH KEY
                                     mandt    = wa_kontrupos-mandt
                                     kontrart = wa_kontrupos-kontrart
                                     kontrnr  = wa_kontrupos-kontrnr
                                     posnr    = wa_kontrupos-posnr
                                     uposnr   = wa_kontrupos-uposnr.
            IF sy-subrc EQ 0.
              MODIFY it_kontrupos_gesamt FROM wa_kontrupos
                INDEX sy-tabix.
            ENDIF.
          ENDIF.

        ENDLOOP.
      ENDIF.



      IF NOT s_insr IS INITIAL.

        MOVE: sy-uname TO zsd_05_kontrpos-rerf,
              sy-datum TO zsd_05_kontrpos-derf,
              sy-uzeit TO zsd_05_kontrpos-terf.

        CASE 'X'.
          WHEN rb_pkt1.
            MOVE 'P' TO zsd_05_kontrpos-index_diffeinh.
          WHEN rb_prz1.
            MOVE 'Z' TO zsd_05_kontrpos-index_diffeinh.
          WHEN OTHERS.
        ENDCASE.

        MOVE-CORRESPONDING zsd_05_kontrpos TO wa_kontrpos.

        MOVE: 'I' TO wa_kontrpos-action,
              'X' TO wa_kontrpos-delable.

        APPEND wa_kontrpos TO it_kontrpos.
      ELSE.

        MOVE: sy-uname TO zsd_05_kontrpos-rbear,
              sy-datum TO zsd_05_kontrpos-dbear,
              sy-uzeit TO zsd_05_kontrpos-tbear.

        CASE zsd_05_kontrpos-verrtyp.
          WHEN 'T' OR 'M'.
            CLEAR: zsd_05_kontrpos-index_key,
                   zsd_05_kontrpos-index_basis,
                   zsd_05_kontrpos-index_gjahr,
                   zsd_05_kontrpos-index_monat,
                   zsd_05_kontrpos-index_stand,
                   zsd_05_kontrpos-index_diffstand,
                   zsd_05_kontrpos-index_diff,
                   zsd_05_kontrpos-index_diffeinh.
          WHEN 'K'.
            CASE 'X'.
              WHEN rb_pkt1.
                MOVE 'P' TO zsd_05_kontrpos-index_diffeinh.
              WHEN rb_prz1.
                MOVE 'Z' TO zsd_05_kontrpos-index_diffeinh.
              WHEN OTHERS.
            ENDCASE.
          WHEN OTHERS.
        ENDCASE.

        MOVE-CORRESPONDING zsd_05_kontrpos TO wa_kontrpos.

        MOVE 'U' TO wa_kontrpos-action.

        MODIFY it_kontrpos FROM wa_kontrpos.
      ENDIF.


      SET SCREEN 0.
      LEAVE SCREEN.
*
    WHEN 'BTNPN1'.                 "Positionsnotiz

      w_ntyp = 'P'.
      w_proc = 'PAI'.

      IF s_anle = 'X'.
        w_ncode = 'C'.
      ELSEIF s_aend = 'X'.
        w_ncode = 'U'.
      ELSEIF s_anze = 'X'.
        w_ncode = 'R'.
      ENDIF.

      PERFORM notiz_bearb USING w_ncode w_ntyp w_proc.
*
    WHEN 'BTNDPN1'.                 "Löschen Positionsnotiz

      w_ntyp = 'P'.
      w_proc = 'PAI'.

      IF NOT s_anle IS INITIAL
      OR NOT s_aend IS INITIAL.
        w_ncode = 'D'.
        PERFORM notiz_bearb USING w_ncode w_ntyp w_proc.
      ELSE.
        MESSAGE s000 WITH text-e09.
      ENDIF.
*
    WHEN 'BTNBSP1'.                 "Stadtplan öffnen (Browse Stadtplan)

      CLEAR: w_ofile,
             w_parzei,
             w_parzeo.

      w_parzei = zsd_05_kontrpos-parzelle.
      w_parzeo = w_parzei.


      CONCATENATE 'http://geoforum/TBInternet/default.aspx?'
                  'User=1&Layers=TBI_Region_av_farbig.mwf&Show='
                  zsd_05_kontrpos-stadtteil '/' w_parzeo
             INTO w_ofile.

*     Link wird mit dem Browser geöffnet (Stadtplan)
      CALL FUNCTION 'GUI_RUN'
           EXPORTING
                command    = w_ofile
           IMPORTING
                returncode = w_returncode.
      CASE w_returncode.
        WHEN '31'.
          MESSAGE i000(zsd_04) WITH
            'Die Dateierweiterung ist'
            'keinem Programm zugeordnet.'.
        WHEN '2'.
          MESSAGE i000(zsd_04) WITH
          'Datei oder eine der Komponenten'
          'kann nicht gefunden werden.'.
      ENDCASE.
*
    WHEN 'BTNBWG1'.                 "Web-GIS öffnen (Browse Web-GIS)

      CLEAR: w_ofile,
             w_parzei,
             w_parzeo.

      w_parzei = zsd_05_kontrpos-parzelle.
      w_parzeo = w_parzei.


      CONCATENATE 'http://geoforum/TBInternet/default.aspx?'
                  'User=1&Layers=TBI_Region_av_farbig.mwf&Show='
                  zsd_05_kontrpos-stadtteil '/' w_parzeo
             INTO w_ofile.

*     Link wird mit dem Browser geöffnet (Web-GIS)
      CALL FUNCTION 'GUI_RUN'
           EXPORTING
                command    = w_ofile
           IMPORTING
                returncode = w_returncode.
      CASE w_returncode.
        WHEN '31'.
          MESSAGE i000(zsd_04) WITH
            'Die Dateierweiterung ist'
            'keinem Programm zugeordnet.'.
        WHEN '2'.
          MESSAGE i000(zsd_04) WITH
          'Datei oder eine der Komponenten'
          'kann nicht gefunden werden.'.
      ENDCASE.
*
  ENDCASE.

ENDMODULE.                 " user_command_4000  INPUT
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRPOS_active_tab_get     INPUT                    *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE ts_kontrpos_active_tab_get INPUT.

  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN c_ts_kontrpos-tab1.
      g_ts_kontrpos-pressed_tab = c_ts_kontrpos-tab1.
    WHEN c_ts_kontrpos-tab2.
      g_ts_kontrpos-pressed_tab = c_ts_kontrpos-tab2.
    WHEN c_ts_kontrpos-tab3.
      g_ts_kontrpos-pressed_tab = c_ts_kontrpos-tab3.
    WHEN OTHERS.
*      DO NOTHING
  ENDCASE.

ENDMODULE.
*
*&---------------------------------------------------------------------*
*&      Module  exit_command_3000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_3000 INPUT.

  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'BACK'.
      PERFORM knummer_freigabe.
      LEAVE TO TRANSACTION sy-tcode.
    WHEN 'CANC'.
      PERFORM knummer_freigabe.
      LEAVE PROGRAM.
    WHEN 'EXIT'.
      PERFORM knummer_freigabe.
      LEAVE PROGRAM.
  ENDCASE.

ENDMODULE.                 " exit_command_3000  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  get_filename  INPUT
*&---------------------------------------------------------------------*
*       Popupfenster mit Dateistruktur für Dateiauswahl
*----------------------------------------------------------------------*
MODULE get_filename INPUT.

  IF s_anze NE 'X'.
    CALL FUNCTION 'WS_FILENAME_GET'
         EXPORTING
              def_filename     = ' '
              def_path         = zsd_05_kontrakt-dateilink
              mask             = '*.*,*.*.'
              mode             = 'O'
              title            = 'Vertrag auswählen'
         IMPORTING
              filename         = zsd_05_kontrakt-dateilink
         EXCEPTIONS
              inv_winsys       = 1
              no_batch         = 2
              selection_cancel = 3
              selection_error  = 4
              OTHERS           = 5.

    IF sy-subrc <> 0.
    ELSE.
      PERFORM split_dateilink.

      IF NOT zsd_05_kontrakt-dateilink IS INITIAL.
        LOOP AT SCREEN.
          IF screen-name = 'BTN_DELLINK'.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.

          IF screen-name = 'BTN_FILEOPEN'.
            screen-input = 1.
            MODIFY SCREEN.
          ENDIF.
        ENDLOOP.
      ENDIF.


    ENDIF.
  ENDIF.

ENDMODULE.                 " get_filename  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0110  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0110 INPUT.

  CLEAR w_returncode.

  ok_code = sy-ucomm.
  CASE ok_code.
*
    WHEN 'OFILE'.
*     Datei wird mit der zugehörigen Anwendung geöffnet
      CALL FUNCTION 'GUI_RUN'
           EXPORTING
                command    = zsd_05_kontrakt-dateilink
           IMPORTING
                returncode = w_returncode.
*
      CASE w_returncode.
        WHEN '31'.
          MESSAGE i000(zsd_04) WITH
            'Die Dateierweiterung ist'
            'keinem Programm zugeordnet.'.
*
        WHEN '2'.
          MESSAGE i000(zsd_04) WITH
          'Datei oder eine der Komponenten'
          'kann nicht gefunden werden.'.
      ENDCASE.
*
    WHEN 'BTNDELL'.
      CONCATENATE text-a03 text-a13
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
        CLEAR: w_dateilink, zsd_05_kontrakt-dateilink.
      ENDIF.
*
    WHEN 'KVERRG'.
*    Änderung der Eingabeeigenschaften: Grund keine Verrechnung
*    Wird im PBO abgearbeitet: MODULE 4001_modify.
  ENDCASE.


ENDMODULE.                 " USER_COMMAND_0110  INPUT

*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRUPOS_modify     INPUT                           *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrupos_modify INPUT.

  MODIFY it_kontrupos
    INDEX tc_kontrupos-current_line.

ENDMODULE.


*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRUPOS_mark       INPUT                           *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrupos_mark INPUT.

  IF tc_kontrupos-line_sel_mode = 1.
*  AND wa_kontrupos-flag = 'X'.
    LOOP AT it_kontrupos INTO wa_kontrupos
      WHERE flag = 'X'.
      wa_kontrupos-flag = ''.
      MODIFY it_kontrupos
        FROM wa_kontrupos
        TRANSPORTING flag.
    ENDLOOP.
*    wa_kontrupos-flag = 'X'.
  ENDIF.
  MODIFY it_kontrupos
*    FROM wa_kontrupos
    INDEX tc_kontrupos-current_line
    TRANSPORTING flag.

ENDMODULE.
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRUPOS_user_command   INPUT                       *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrupos_user_command INPUT.

  ok_code = sy-ucomm.
  CLEAR: s_insr1,
         s_btnkupupd.

  PERFORM user_ok_tc USING    'TC_KONTRUPOS'
                              'IT_KONTRUPOS'
                              'FLAG'
                              'DELABLE'
                     CHANGING ok_code.
  sy-ucomm = ok_code.

ENDMODULE.
*
*&---------------------------------------------------------------------*
*&      Module  exit_command_4000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_4000 INPUT.

  CLEAR g_tc_kontrupos_copied.

  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN 'BACK'.
      LEAVE TO SCREEN 3000.
    WHEN 'CANC'.
      LEAVE TO SCREEN 3000.
    WHEN 'EXIT'.
      PERFORM knummer_freigabe.
      LEAVE PROGRAM.
  ENDCASE.

ENDMODULE.                 " exit_command_4000  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  tc_kontrpos_change_col_attr  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_kontrpos_change_col_attr INPUT.

  DESCRIBE TABLE it_kontrpos LINES tc_kontrpos-lines.
  CHECK tc_kontrpos-lines GT 0.
  LOOP AT tc_kontrpos-cols INTO g_tc_kontrpos-cols_wa.
    IF g_tc_kontrpos-cols_wa-screen-group2 = 'INP'.
      IF s_anze IS INITIAL.
        MOVE '1' TO g_tc_kontrpos-cols_wa-screen-input.
        MODIFY tc_kontrpos-cols FROM g_tc_kontrpos-cols_wa.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " tc_kontrpos_change_col_attr  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  tc_kontrupos_change_col_attr  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_kontrupos_change_col_attr INPUT.

  DESCRIBE TABLE it_kontrupos LINES tc_kontrupos-lines.
  CHECK tc_kontrupos-lines GT 0.
  LOOP AT tc_kontrupos-cols INTO g_tc_kontrupos-cols_wa.
    IF g_tc_kontrupos-cols_wa-screen-group2 = 'INP'.
      IF s_anze IS INITIAL.
        MOVE '1' TO g_tc_kontrupos-cols_wa-screen-input.
        MODIFY tc_kontrupos-cols FROM g_tc_kontrupos-cols_wa.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " tc_kontrupos_change_col_attr  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  verr_grund_kontrpos  INPUT
*&---------------------------------------------------------------------*
*       Grund wenn Keine Verrechnung
*----------------------------------------------------------------------*
MODULE verr_grund_kontrpos INPUT.

  PERFORM verr_grund_input.

  IF NOT zsd_05_kontrpos-verr_code IS INITIAL.
    IF zsd_05_kontrpos-verr_grund IS INITIAL.
      MESSAGE e000 WITH text-e08.
    ENDIF.
  ENDIF.

ENDMODULE.                 " verr_grund_kontrpos  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  berechnung_menge  INPUT
*&---------------------------------------------------------------------*
*       Mengenberechnung
*----------------------------------------------------------------------*
MODULE berechnung_menge INPUT.

  DATA: lv_menge1 TYPE zsd_05_kontrpos-menge_pos,
        lv_menge2 TYPE zsd_05_kontrpos-objlaenge,
        lv_menge3 TYPE zsd_05_kontrpos-objbreite,
        lv_menge4 TYPE zsd_05_kontrpos-objhoehe.

  lv_menge2 = zsd_05_kontrpos-objlaenge.
  lv_menge3 = zsd_05_kontrpos-objbreite.
  lv_menge4 = zsd_05_kontrpos-objhoehe.

  IF NOT lv_menge2 IS INITIAL AND
     NOT lv_menge3 IS INITIAL.
*    IF NOT lv_menge4 IS INITIAL.
*      lv_menge1 = lv_menge2 * lv_menge3 * lv_menge4.
*    ELSE.
    lv_menge1 = lv_menge2 * lv_menge3.
*    ENDIF.
    zsd_05_kontrpos-menge_pos = lv_menge1.
  ENDIF.

ENDMODULE.                 " berechnung_menge  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  read_idxstand  INPUT
*&---------------------------------------------------------------------*
*       Lesen des Indexstandes
*----------------------------------------------------------------------*
MODULE read_idxstand INPUT.

  SELECT SINGLE index_stand FROM zsd_05_index
    INTO zsd_05_kontrpos-index_stand
    WHERE index_key   = zsd_05_kontrpos-index_key
    AND   index_basis = zsd_05_kontrpos-index_basis
    AND   index_gjahr = zsd_05_kontrpos-index_gjahr
    AND   index_monat = zsd_05_kontrpos-index_monat.

ENDMODULE.                 " read_idxstand  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  matnr  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE matnr INPUT.

  CLEAR: makt, mara.
  SELECT SINGLE * FROM  mara
         WHERE   matnr  = zsd_05_kontrpos-matnr.
  SELECT SINGLE * FROM  makt
         WHERE  matnr  = mara-matnr
         AND    spras  = sy-langu.
  IF zsd_05_kontrpos-matxt IS INITIAL.
    MOVE makt-maktx TO zsd_05_kontrpos-matxt.
  ENDIF.
  MOVE mara-meins TO zsd_05_kontrpos-meins.

ENDMODULE.                 " matnr  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  peinh  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE peinh INPUT.

  IF zsd_05_kontrpos-peinh IS INITIAL.
    MOVE 1 TO zsd_05_kontrpos-peinh.
  ENDIF.

ENDMODULE.                 " peinh  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  menge_pos  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE menge_pos INPUT.

  IF zsd_05_kontrpos-menge_pos IS INITIAL.
    MOVE 1 TO zsd_05_kontrpos-menge_pos.
  ENDIF.

ENDMODULE.                 " menge_pos  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  check_parzelle  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_parzelle INPUT.

  CLEAR: ls_cp_objekt, lv_adr, lv_ort.

  SELECT SINGLE * FROM zsd_05_objekt INTO ls_cp_objekt
    WHERE stadtteil = zsd_05_kontrpos-stadtteil
    AND   parzelle  = zsd_05_kontrpos-parzelle
    AND   objekt    = zsd_05_kontrpos-objekt.

  IF NOT ls_cp_objekt IS INITIAL.

    IF NOT ls_cp_objekt-street IS INITIAL AND
       NOT ls_cp_objekt-house_num1 IS INITIAL.
      CONCATENATE ls_cp_objekt-street ls_cp_objekt-house_num1
        INTO lv_adr SEPARATED BY space.
    ELSEIF NOT ls_cp_objekt-street IS INITIAL.
      MOVE ls_cp_objekt-street TO lv_adr.
    ENDIF.


    IF NOT ls_cp_objekt-post_code1 IS INITIAL AND
       NOT ls_cp_objekt-city1 IS INITIAL.
     CONCATENATE ls_cp_objekt-post_code1 ls_cp_objekt-city1 INTO lv_ort
                                SEPARATED BY space.
    ELSEIF NOT ls_cp_objekt-city1 IS INITIAL.
      MOVE ls_cp_objekt-city1 TO lv_ort.
    ENDIF.


    IF NOT lv_adr IS INITIAL AND NOT lv_ort IS INITIAL.
      CONCATENATE lv_adr lv_ort INTO w_adrpos SEPARATED BY ', '.
    ELSEIF NOT lv_adr IS INITIAL AND lv_ort IS INITIAL.
      MOVE lv_adr TO w_adrpos.
    ELSEIF lv_adr IS INITIAL AND NOT lv_ort IS INITIAL.
      MOVE lv_ort TO w_adrpos.
    ENDIF.
  ENDIF.
  DATA: lv_stpzobj TYPE string.

  CLEAR: lv_stpzobj.

  IF ls_cp_objekt IS INITIAL.
    CONCATENATE zsd_05_kontrpos-stadtteil zsd_05_kontrpos-parzelle
                zsd_05_kontrpos-objekt INTO lv_stpzobj SEPARATED BY '/'.

    CLEAR w_adrpos.

    MESSAGE e000(zsd_04) WITH 'Das Objekt ' lv_stpzobj
                              'ist nicht vorhanden.'.
  ENDIF.

ENDMODULE.                 " check_parzelle  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  read_preis  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_preis INPUT.

* Preis ermitteln
  IF zsd_05_kontrpos-verrtyp NE 'K'. " Verrgtyp ist nicht Kontraktpreis
    CLEAR wa_a004.
    CLEAR wa_konp.
    CLEAR zsd_05_kontrpos-preis.

    SELECT SINGLE * FROM a004 INTO wa_a004
      WHERE vkorg =  w_vkorg
      AND   vtweg =  w_vtweg
      AND   matnr =  zsd_05_kontrpos-matnr
      AND   datab <= sy-datum
      AND   datbi >= sy-datum.

    SELECT SINGLE * FROM konp INTO wa_konp
      WHERE knumh = wa_a004-knumh
      AND   kschl = w_kschl.

    IF sy-subrc NE 0.
      MESSAGE e000(zsd_04) WITH 'Zum Material' zsd_05_kontrpos-matnr
                                'kein Preis gefunden.'.
    ELSE.
      MOVE wa_konp-kbetr TO zsd_05_kontrpos-preis.
    ENDIF.
  ENDIF.

ENDMODULE.                 " read_preis  INPUT
*
*&---------------------------------------------------------------------*
*&      Module  check_delete  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_delete INPUT.

  CASE ok_code.
    WHEN 'ANZE' OR 'ENTE' OR 'AEND'.
      IF NOT zsd_05_kontrakt-loesch IS INITIAL.
        MESSAGE w000(zsd_04) WITH text-e22.
      ENDIF.
  ENDCASE.

ENDMODULE.                 " check_delete  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_UPOS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_upos INPUT.

  TABLES zsd_05_objekt.
  IF NOT it_kontrupos-stadtteil IS INITIAL.
    SELECT SINGLE * FROM  zsd_05_objekt
           WHERE  stadtteil  = it_kontrupos-stadtteil
           AND    parzelle   = it_kontrupos-parzelle
           AND    objekt     = it_kontrupos-objekt.
    IF sy-subrc NE 0.
      MESSAGE e000(zsd_04) WITH text-e25.
    ENDIF.
  ENDIF.

ENDMODULE.                 " CHECK_UPOS  INPUT
