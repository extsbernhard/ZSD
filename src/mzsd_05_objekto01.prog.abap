*----------------------------------------------------------------------*
***INCLUDE MZSD_05_PARZELLEO01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_1000  OUTPUT
*&---------------------------------------------------------------------*
*       Dynpro 1000
*----------------------------------------------------------------------*
MODULE status_1000 OUTPUT.
* Rückerstattungs Tabelle
  g_rueckerstattung_copied = ' '.
  REFRESH t_kehrauft.
* Aktivität für Berechtigungsprüfung definieren
  CASE 'X'.
    WHEN s_anle. w_actvt = '01'. "Anlegen
    WHEN s_aend. w_actvt = '02'. "Ändern
    WHEN s_anze. w_actvt = '03'. "Anzeigen
    WHEN OTHERS. w_actvt = '03'. "Anzeigen, wenn X nicht gesetzt ist.
  ENDCASE.
  PERFORM authority-check USING 'ZIDBOGPARV' w_actvt.
  IF sy-subrc NE 0.
    MESSAGE e000 WITH text-e07.
  ENDIF.
* Objekt sperren, wenn im Änderungs- oder Anlege-Modus
  IF NOT zsd_05_objekt IS INITIAL
  AND s_enqueue IS INITIAL
  AND ( NOT s_anle IS INITIAL OR
        NOT s_aend IS INITIAL ).
    CALL FUNCTION 'ENQUEUE_EZSD05_OBJEKT'
      EXPORTING
        mode_zsd_05_objekt = 'E'
        mandt              = sy-mandt
        stadtteil          = zsd_05_objekt-stadtteil
        parzelle           = zsd_05_objekt-parzelle
        objekt             = zsd_05_objekt-objekt
        x_stadtteil        = ' '
        x_parzelle         = ' '
        x_objekt           = ' '
        _scope             = '2'
        _wait              = ' '
        _collect           = ' '
      EXCEPTIONS
        foreign_lock       = 1
        system_failure     = 2
        OTHERS             = 3.
    IF sy-subrc <> 0.
      DATA l_msgv1 LIKE sy-msgv1.
      MOVE sy-msgv1 TO l_msgv1.
      MESSAGE s000 WITH text-e12 l_msgv1 text-e11.
      CLEAR: s_anle,
             s_aend.
      s_anze = 'X'.
    ELSE.
      s_enqueue = 'X'.
    ENDIF.
  ENDIF.
* Funktionen abhängig vom Pflegemodus ausschalten
  REFRESH t_excl_tab.
  MOVE 'DELE' TO w_excl_tab-fcode.
  APPEND w_excl_tab TO t_excl_tab.
* Anlegen
  IF NOT s_anle IS INITIAL.
    MOVE 'ANLE' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
    MOVE 'LIST' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
* Ändern
  ELSEIF NOT s_aend IS INITIAL.
    MOVE 'AEND' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
    MOVE 'LIST' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
* Anzeigen
  ELSEIF NOT s_anze IS INITIAL.
    MOVE 'ANZE' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
    MOVE 'LIST' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
  ENDIF.
* Dynproausgabe vorbereiten
  SET PF-STATUS '1000' EXCLUDING t_excl_tab.
  SET TITLEBAR '100'.
  LOOP AT SCREEN.
    IF screen-group1 = '000'.
      IF s_1000 IS INITIAL.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
    IF screen-group1 = '001'.
      IF s_1000 IS INITIAL.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
    IF screen-group2 = '002'.
      IF NOT s_anze IS INITIAL.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
    IF screen-group2 = '003'.
      IF NOT s_1000 IS INITIAL.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
    IF screen-group3 = '003'.
      CASE screen-name.
        WHEN '%#AUTOTEXT009'.
          IF zsd_05_objekt-eigentuemer IS INITIAL
          AND NOT zsd_05_objekt-addrnumber_eig IS INITIAL.
            screen-active = 1.
            screen-invisible = 0.
          ELSE.
            screen-active = 0.
            screen-invisible = 1.
          ENDIF.
        WHEN '%#AUTOTEXT007'.
*          IF zsd_05_objekt-verwalter IS INITIAL
*          AND NOT zsd_05_objekt-addrnumber_ver IS INITIAL.
*            screen-active = 1.
*            screen-invisible = 0.
*          ELSE.
*            screen-active = 0.
*            screen-invisible = 1.
*          ENDIF.
      ENDCASE.
      MODIFY SCREEN.
    ENDIF.
    IF screen-group4 = '001'.
      IF s_1000 IS INITIAL
      OR NOT s_anle IS INITIAL.
        screen-active = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.
* Cursor auf Objektbezeichnung setzen
  IF NOT s_anle IS INITIAL
  OR NOT s_aend IS INITIAL.
    SET CURSOR FIELD 'ZSD_05_OBJEKT-OBJEKTBEZ'.
  ENDIF.
* Adressen holen
  CLEAR w_kna1e.
  PERFORM read_kna1 USING zsd_05_objekt-eigentuemer w_kna1e.
  PERFORM addr_get  USING zsd_05_objekt-addrnumber_eig w_kna1e.
* Lesen von zugeordneten Objekten ermöglichen
  IF zsd_05_objekt-stadtteil NE w_stadt_parz(1)
  OR zsd_05_objekt-parzelle NE w_stadt_parz+1.
    CLEAR g_tc_object_copied.
    MOVE: zsd_05_objekt-stadtteil TO w_stadt_parz(1),
          zsd_05_objekt-parzelle  TO w_stadt_parz+1.
    CLEAR: zsd_04_kanal,
           zsd_04_kehricht,
           zsd_04_regen,
           zsd_04_boden.
  ENDIF.

ENDMODULE.                 " STATUS_1000  OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE tc_object_init OUTPUT                                  *
*---------------------------------------------------------------------*
*       Zugeordnete Objekte lesen                                     *
*---------------------------------------------------------------------*
MODULE tc_object_init OUTPUT.

  CHECK NOT s_1000 IS INITIAL.
  IF g_tc_object_copied IS INITIAL.
    SELECT        * FROM zsd_05_objekt
           INTO CORRESPONDING FIELDS OF TABLE t_object
           WHERE  stadtteil = zsd_05_objekt-stadtteil
           AND    parzelle  = zsd_05_objekt-parzelle.


    PERFORM verwend_status.


    g_tc_object_copied = 'X'.
    REFRESH CONTROL 'TC_OBJECT' FROM SCREEN '1000'.
  ENDIF.

ENDMODULE.                    "tc_object_init OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE tc_objekte_move OUTPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_object_move OUTPUT.

  MOVE-CORRESPONDING g_tc_object_wa TO zsd_05_objekt.

ENDMODULE.                    "tc_object_move OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  TC_OBJECT_change_col_attr  OUTPUT
*&---------------------------------------------------------------------*
*       Zugeordnete Objekte im Anzeigemodus nicht änderbar
*----------------------------------------------------------------------*
MODULE tc_object_change_col_attr OUTPUT.

  DESCRIBE TABLE t_object LINES tc_object-lines.
  CHECK tc_object-lines GT 0.
  LOOP AT tc_object-cols INTO g_tc_object-cols_wa.
    IF g_tc_object-cols_wa-screen-group1 = '001'.
      IF s_1000 IS INITIAL.
        MOVE '1' TO g_tc_object-cols_wa-screen-active.
        MODIFY tc_object-cols FROM g_tc_object-cols_wa.
      ENDIF.
    ENDIF.
    IF g_tc_object-cols_wa-screen-group2 = '002'.
      IF s_anze IS INITIAL.
        MOVE '1' TO g_tc_object-cols_wa-screen-input.
        MODIFY tc_object-cols FROM g_tc_object-cols_wa.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " TC_OBJECT_change_col_attr  OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE tc_object_change_tc_attr OUTPUT                        *
*---------------------------------------------------------------------*
*       Zugeordnete Objekte nicht anzeige im Anlegen-Modus            *
*---------------------------------------------------------------------*
MODULE tc_object_change_tc_attr OUTPUT.

  IF s_1000 IS INITIAL
  OR NOT s_anle IS INITIAL.
    MOVE 'X' TO tc_object-invisible.
  ELSE.
    MOVE ' ' TO tc_object-invisible.
  ENDIF.

ENDMODULE.                    "tc_object_change_tc_attr OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE tc_object_get_lines OUTPUT                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_object_get_lines OUTPUT.

  g_tc_object_lines = sy-loopc.

ENDMODULE.                    "tc_object_get_lines OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  status_2000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2000 OUTPUT.

  REFRESH t_excl_tab.
* Anlegen
  IF NOT s_anle IS INITIAL.
    MOVE 'ANLE' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
    MOVE 'DELE' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
    MOVE 'LIST' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
* Ändern
  ELSEIF NOT s_aend IS INITIAL.
    MOVE 'AEND' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
    MOVE 'DELE' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
    MOVE 'LIST' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
* Anzeigen
  ELSEIF NOT s_anze IS INITIAL.
    MOVE 'DELE' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
    MOVE 'ANZE' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
    MOVE 'LIST' TO w_excl_tab-fcode.
    APPEND w_excl_tab TO t_excl_tab.
  ENDIF.
  SET PF-STATUS '2000' EXCLUDING t_excl_tab.
  SET TITLEBAR '200'.
  LOOP AT SCREEN.
    IF screen-group1 = '000'.
      IF ( NOT s_anle IS INITIAL OR
           NOT s_aend IS INITIAL )
      AND NOT s_insr IS INITIAL.
        screen-input = 1.
      ELSE.
        screen-input = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
    IF screen-group1 = '001'.
      IF NOT s_anze IS INITIAL.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
*
  w_flaeche = zsd_04_kehricht-flaeche_fakt1 +
              zsd_04_kehricht-flaeche_fakt2 +
              zsd_04_kehricht-flaeche_fakt3 +
              zsd_04_kehricht-flaeche_fakt4 +
              zsd_04_kehricht-flaeche_fakt5.
  w_flaechev = zsd_04_kehricht-vflaeche_fakt1 +
               zsd_04_kehricht-vflaeche_fakt2 +
               zsd_04_kehricht-vflaeche_fakt3 +
               zsd_04_kehricht-vflaeche_fakt4 +
               zsd_04_kehricht-vflaeche_fakt5.
  PERFORM betrag_rechnen.
  IF s_insr IS INITIAL.
    IF zsd_04_kehricht IS INITIAL
    OR zsd_04_kehricht-objekt NE t_object_wa-objekt.
      CLEAR zsd_04_kehricht.
      SELECT SINGLE * FROM  zsd_04_kehricht
             WHERE  stadtteil       = t_object_wa-stadtteil
             AND    parzelle        = t_object_wa-parzelle
             AND    objekt          = t_object_wa-objekt.
      w_flaeche = zsd_04_kehricht-flaeche_fakt1 +
                  zsd_04_kehricht-flaeche_fakt2 +
                  zsd_04_kehricht-flaeche_fakt3 +
                  zsd_04_kehricht-flaeche_fakt4 +
                  zsd_04_kehricht-flaeche_fakt5.
      w_flaechev = zsd_04_kehricht-vflaeche_fakt1 +
                   zsd_04_kehricht-vflaeche_fakt2 +
                   zsd_04_kehricht-vflaeche_fakt3 +
                   zsd_04_kehricht-vflaeche_fakt4 +
                   zsd_04_kehricht-vflaeche_fakt5.
      PERFORM betrag_rechnen.
    ENDIF.
    IF zsd_04_regen IS INITIAL
    OR zsd_04_regen-objekt NE t_object_wa-objekt.
      CLEAR zsd_04_regen.
      SELECT SINGLE * FROM  zsd_04_regen
             WHERE  stadtteil       = t_object_wa-stadtteil
             AND    parzelle        = t_object_wa-parzelle
             AND    objekt          = t_object_wa-objekt.
    ENDIF.
    IF zsd_04_kanal IS INITIAL
    OR zsd_04_kanal-objekt NE t_object_wa-objekt.
      CLEAR zsd_04_kanal.
      SELECT SINGLE * FROM  zsd_04_kanal
             WHERE  stadtteil       = t_object_wa-stadtteil
             AND    parzelle        = t_object_wa-parzelle
             AND    objekt          = t_object_wa-objekt.
    ENDIF.
    IF zsd_04_boden IS INITIAL
    OR zsd_04_boden-objekt NE t_object_wa-objekt.
      CLEAR zsd_04_boden.
      SELECT SINGLE * FROM  zsd_04_boden
             WHERE  stadtteil       = t_object_wa-stadtteil
             AND    parzelle        = t_object_wa-parzelle
             AND    objekt          = t_object_wa-objekt.
    ENDIF.
  ENDIF.
  MOVE: '2850' TO zsd_04_kanal-vkorg,
        '89'   TO zsd_04_kanal-vtweg,
        '10'   TO zsd_04_kanal-spart,
        '8900' TO zsd_04_kanal-vkbur.
  MOVE: '2850' TO zsd_04_regen-vkorg,
        '88'   TO zsd_04_regen-vtweg,
        '10'   TO zsd_04_regen-spart,
        '8800' TO zsd_04_regen-vkbur.
  MOVE: '1500' TO zsd_04_boden-vkorg,
        '51'   TO zsd_04_boden-vtweg,
        '10'   TO zsd_04_boden-spart,
        '5180' TO zsd_04_boden-vkbur.
  IF t_object_wa-city1 IS INITIAL.
    MOVE 'Bern' TO t_object_wa-city1.
  ENDIF.
  IF t_object_wa-country IS INITIAL.
    MOVE 'CH' TO t_object_wa-country.
  ENDIF.
  IF t_object_wa-region IS INITIAL.
    MOVE 'BE' TO t_object_wa-region.
  ENDIF.
  CLEAR: w_kna1k,
         w_kna1r,
         w_kna1g,
         w_kna1b.
  IF t_object_wa-objekt NE '0000'.
    CLEAR: w_kna1e.
  ENDIF.
* Adressen
  PERFORM read_kna1 USING: t_object_wa-eigentuemer w_kna1e,
                           zsd_04_kanal-kunnr      w_kna1k,
                           zsd_04_regen-kunnr      w_kna1r,
                           zsd_04_kehricht-kunnr   w_kna1g,
                           zsd_04_boden-kunnr      w_kna1b.
  PERFORM addr_get  USING: t_object_wa-addrnumber_eig w_kna1e,
                           zsd_04_kanal-adrnr         w_kna1k,
                           zsd_04_regen-adrnr         w_kna1r,
                           zsd_04_kehricht-adrnr      w_kna1g,
                           zsd_04_boden-adrnr         w_kna1b.

ENDMODULE.                 " status_2000  OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE TS_GEBUEHREN_ACTIVE_TAB_SET OUTPUT                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE ts_gebuehren_active_tab_set OUTPUT.

  IF s_gebuehren IS INITIAL.
    GET PARAMETER ID 'ZZ_GEBUEHREN_FC' FIELD ts_gebuehren-activetab.
    s_gebuehren = 'X'.
    IF ts_gebuehren-activetab IS INITIAL.
      ts_gebuehren-activetab = g_ts_gebuehren-pressed_tab.
    ELSE.
      CONCATENATE 'TS_GEBUEHREN_' ts_gebuehren-activetab
             INTO g_ts_gebuehren-pressed_tab.
    ENDIF.
  ENDIF.
  CASE g_ts_gebuehren-pressed_tab.
    WHEN c_ts_gebuehren-tab1.
      PERFORM authority-check USING 'ZIDBOGKAAN' w_actvt.
      g_ts_gebuehren-subscreen = '2001'.
      ts_gebuehren-activetab = 'TS_GEBUEHREN_FC1'.
      IF sy-subrc NE 0.
        PERFORM authority-check USING 'ZIDBOGKEGR' w_actvt.
        g_ts_gebuehren-subscreen = '2002'.
        ts_gebuehren-activetab = 'TS_GEBUEHREN_FC2'.
        IF sy-subrc NE 0.
          PERFORM authority-check USING 'ZIDBOGREAB' w_actvt.
          g_ts_gebuehren-subscreen = '2003'.
          ts_gebuehren-activetab = 'TS_GEBUEHREN_FC3'.
          IF sy-subrc NE 0.
            PERFORM authority-check USING 'ZIDBOGOFBD' w_actvt.
            g_ts_gebuehren-subscreen = '2004'.
            ts_gebuehren-activetab = 'TS_GEBUEHREN_FC4'.
            IF sy-subrc NE 0.
              CLEAR s_gebuehren.
              CLEAR g_ts_gebuehren-pressed_tab.
              MESSAGE s000 WITH text-e07.
              LEAVE TO TRANSACTION sy-tcode.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    WHEN c_ts_gebuehren-tab2.
      PERFORM authority-check USING 'ZIDBOGKEGR' w_actvt.
      g_ts_gebuehren-subscreen = '2002'.
      ts_gebuehren-activetab = 'TS_GEBUEHREN_FC2'.
      IF sy-subrc NE 0.
        PERFORM authority-check USING 'ZIDBOGKAAN' w_actvt.
        g_ts_gebuehren-subscreen = '2001'.
        ts_gebuehren-activetab = 'TS_GEBUEHREN_FC1'.
        IF sy-subrc NE 0.
          PERFORM authority-check USING 'ZIDBOGREAB' w_actvt.
          g_ts_gebuehren-subscreen = '2003'.
          ts_gebuehren-activetab = 'TS_GEBUEHREN_FC3'.
          IF sy-subrc NE 0.
            PERFORM authority-check USING 'ZIDBOGOFBD' w_actvt.
            g_ts_gebuehren-subscreen = '2004'.
            ts_gebuehren-activetab = 'TS_GEBUEHREN_FC4'.
            IF sy-subrc NE 0.
              CLEAR s_gebuehren.
              CLEAR g_ts_gebuehren-pressed_tab.
              MESSAGE s000 WITH text-e07.
              LEAVE TO TRANSACTION sy-tcode.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    WHEN c_ts_gebuehren-tab3.
      PERFORM authority-check USING 'ZIDBOGREAB' w_actvt.
      g_ts_gebuehren-subscreen = '2003'.
      ts_gebuehren-activetab = 'TS_GEBUEHREN_FC3'.
      IF sy-subrc NE 0.
        PERFORM authority-check USING 'ZIDBOGKAAN' w_actvt.
        g_ts_gebuehren-subscreen = '2001'.
        ts_gebuehren-activetab = 'TS_GEBUEHREN_FC1'.
        IF sy-subrc NE 0.
          PERFORM authority-check USING 'ZIDBOGKEGR' w_actvt.
          g_ts_gebuehren-subscreen = '2002'.
          ts_gebuehren-activetab = 'TS_GEBUEHREN_FC2'.
          IF sy-subrc NE 0.
            PERFORM authority-check USING 'ZIDBOGOFBD' w_actvt.
            g_ts_gebuehren-subscreen = '2004'.
            ts_gebuehren-activetab = 'TS_GEBUEHREN_FC4'.
            IF sy-subrc NE 0.
              CLEAR s_gebuehren.
              CLEAR g_ts_gebuehren-pressed_tab.
              MESSAGE s000 WITH text-e07.
              LEAVE TO TRANSACTION sy-tcode.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    WHEN c_ts_gebuehren-tab4.
      PERFORM authority-check USING 'ZIDBOGOFBD' w_actvt.
      g_ts_gebuehren-subscreen = '2004'.
      ts_gebuehren-activetab = 'TS_GEBUEHREN_FC4'.
      IF sy-subrc NE 0.
        PERFORM authority-check USING 'ZIDBOGKEGR' w_actvt.
        g_ts_gebuehren-subscreen = '2002'.
        ts_gebuehren-activetab = 'TS_GEBUEHREN_FC2'.
        IF sy-subrc NE 0.
          PERFORM authority-check USING 'ZIDBOGREAB' w_actvt.
          g_ts_gebuehren-subscreen = '2003'.
          ts_gebuehren-activetab = 'TS_GEBUEHREN_FC3'.
          IF sy-subrc NE 0.
            PERFORM authority-check USING 'ZIDBOGKAAN' w_actvt.
            g_ts_gebuehren-subscreen = '2001'.
            ts_gebuehren-activetab = 'TS_GEBUEHREN_FC1'.
            IF sy-subrc NE 0.
              CLEAR s_gebuehren.
              CLEAR g_ts_gebuehren-pressed_tab.
              MESSAGE s000 WITH text-e07.
              LEAVE TO TRANSACTION sy-tcode.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    WHEN OTHERS.
  ENDCASE.

ENDMODULE.                    "ts_gebuehren_active_tab_set OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  STATUS_2001  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2001 OUTPUT.

  LOOP AT SCREEN.
    IF screen-group1 = '001'.
      IF NOT s_anze IS INITIAL.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
  IF screen-group3 = '003'.
    IF zsd_04_kanal-kunnr IS INITIAL
    AND NOT zsd_04_kanal-adrnr IS INITIAL.
      screen-active = 1.
      screen-invisible = 0.
    ELSE.
      screen-active = 0.
      screen-invisible = 1.
    ENDIF.
    MODIFY SCREEN.
  ENDIF.
  IF NOT s_anle IS INITIAL
  OR NOT s_aend IS INITIAL.
    IF zsd_04_kanal-vkbur IS INITIAL.
      MOVE: '2850' TO zsd_04_kanal-vkorg,
            '89'   TO zsd_04_kanal-vtweg,
            '10'   TO zsd_04_kanal-spart,
            '8900' TO zsd_04_kanal-vkbur.
    ENDIF.
    IF zsd_04_kanal-bw_ansatz IS INITIAL.
      zsd_04_kanal-bw_ansatz = 280.

      zsd_04_kanal-qm_ansatz = 25.
      zsd_04_kanal-qm_ansatz_red = 20.
    ENDIF.
  ENDIF.

ENDMODULE.                 " STATUS_2001  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  read_material  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_material OUTPUT.

  SELECT SINGLE * FROM  zsd_04_kehr_mat CLIENT SPECIFIED
         WHERE  mandt  = sy-mandt.
  PERFORM read_makt USING: zsd_04_kehr_mat-matnr_1 w_mattext1,
                           zsd_04_kehr_mat-matnr_2 w_mattext2,
                           zsd_04_kehr_mat-matnr_3 w_mattext3,
                           zsd_04_kehr_mat-matnr_4 w_mattext4,
                           zsd_04_kehr_mat-matnr_5 w_mattext5,
                           zsd_04_kehr_mat-pausch  w_mattext6.
  IF zsd_04_kehricht-bez_fakt1 IS INITIAL.
    MOVE w_mattext1 TO zsd_04_kehricht-bez_fakt1.
  ENDIF.
  IF zsd_04_kehricht-bez_fakt2 IS INITIAL.
    MOVE w_mattext2 TO zsd_04_kehricht-bez_fakt2.
  ENDIF.
  IF zsd_04_kehricht-bez_fakt3 IS INITIAL.
    MOVE w_mattext3 TO zsd_04_kehricht-bez_fakt3.
  ENDIF.
  IF zsd_04_kehricht-bez_fakt4 IS INITIAL.
    MOVE w_mattext4 TO zsd_04_kehricht-bez_fakt4.
  ENDIF.
  IF zsd_04_kehricht-bez_fakt5 IS INITIAL.
    MOVE w_mattext5 TO zsd_04_kehricht-bez_fakt5.
  ENDIF.
  IF zsd_04_kehricht-bez_pauschal IS INITIAL.
    MOVE w_mattext6 TO zsd_04_kehricht-bez_pauschal.
  ENDIF.

ENDMODULE.                 " read_material  OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE TS_OBJEKT_ACTIVE_TAB_SET OUTPUT                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE ts_objekt_active_tab_set OUTPUT.

  ts_objekt-activetab = g_ts_objekt-pressed_tab.
  CASE g_ts_objekt-pressed_tab.
    WHEN c_ts_objekt-tab1.
      g_ts_objekt-subscreen = '2007'.
    WHEN c_ts_objekt-tab2.
      g_ts_objekt-subscreen = '2005'.
    WHEN c_ts_objekt-tab3.
      g_ts_objekt-subscreen = '2006'.
    WHEN OTHERS.
  ENDCASE.

ENDMODULE.                    "ts_objekt_active_tab_set OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE TC_REGENINFO_init OUTPUT                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_regeninfo_init OUTPUT.

  IF g_tc_regeninfo_copied IS INITIAL.
    SELECT        * FROM  zsd_04_regeninfo
           INTO CORRESPONDING FIELDS OF TABLE g_tc_regeninfo_itab
           WHERE  stadtteil  = zsd_05_objekt-stadtteil
           AND    parzelle   = zsd_05_objekt-parzelle
           AND    objekt     = zsd_05_objekt-objekt.
    g_tc_regeninfo_copied = 'X'.
    REFRESH CONTROL 'TC_REGENINFO' FROM SCREEN '2003'.
  ENDIF.

ENDMODULE.                    "tc_regeninfo_init OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE TC_REGENINFO_move OUTPUT                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_regeninfo_move OUTPUT.

  MOVE-CORRESPONDING g_tc_regeninfo_wa TO zsd_04_regeninfo.

ENDMODULE.                    "tc_regeninfo_move OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE TC_REGENINFO_get_lines OUTPUT                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_regeninfo_get_lines OUTPUT.

  g_tc_regeninfo_lines = sy-loopc.

ENDMODULE.                    "tc_regeninfo_get_lines OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  TC_REGENINFO_change_col_attr  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_regeninfo_change_col_attr OUTPUT.

  DESCRIBE TABLE g_tc_regeninfo_itab LINES w_lines.
  CHECK w_lines GT 0.
  LOOP AT tc_regeninfo-cols INTO g_tc_regeninfo-cols_wa.
    MOVE '1' TO g_tc_regeninfo-cols_wa-screen-active.
    MOVE '1' TO g_tc_regeninfo-cols_wa-screen-input.
    MODIFY tc_regeninfo-cols FROM g_tc_regeninfo-cols_wa.
  ENDLOOP.

ENDMODULE.                 " TC_REGENINFO_change_col_attr  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  STATUS_2100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2100 OUTPUT.

  SET PF-STATUS '2100'.
  SET TITLEBAR '210'.
  MOVE: zsd_05_objekt-stadtteil TO zsd_04_regeninfo-stadtteil,
        zsd_05_objekt-parzelle  TO zsd_04_regeninfo-parzelle,
        zsd_05_objekt-objekt    TO zsd_04_regeninfo-objekt.

ENDMODULE.                 " STATUS_2100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  status_2002  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2002 OUTPUT.

  PERFORM authority-check USING 'ZIDBOGKEGR' w_actvt.
  LOOP AT SCREEN.
    IF screen-group1 = '001'.
      IF NOT s_anze IS INITIAL.
        screen-input = 0.
*      btn_eig_mod = text-p03.
*      btn_ver_mod = text-p04.
      ELSE.
        screen-input = 1.

      ENDIF.
      MODIFY SCREEN.
    ENDIF.
*
    IF screen-group2 = '002'.
      IF NOT zsd_04_kehricht-berechnung IS INITIAL.
        screen-invisible = 0.
      ELSE.
        screen-invisible = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
*
    IF screen-group3 = '003'.
      IF zsd_04_kehricht-kunnr IS INITIAL
      AND NOT zsd_04_kehricht-adrnr IS INITIAL.
        screen-active = 1.
        screen-invisible = 0.
      ELSE.
        screen-active = 0.
        screen-invisible = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
*
  IF NOT s_anle IS INITIAL
  OR NOT s_aend IS INITIAL.
    IF zsd_04_kehricht-vkbur IS INITIAL.
      MOVE: '2870' TO zsd_04_kehricht-vkorg,
            '87'   TO zsd_04_kehricht-vtweg,
            '10'   TO zsd_04_kehricht-spart,
            '8720' TO zsd_04_kehricht-vkbur.
    ENDIF.
  ENDIF.
*
  DATA: BEGIN OF lt_hinweise OCCURS 0,
          code TYPE opsgn,
          text TYPE so_text072,
        END  OF lt_hinweise.
  REFRESH lt_hinweise.
  MOVE: zsd_04_kehricht-hinweis1 TO lt_hinweise-code,
        zsd_04_kehricht-hintext1 TO lt_hinweise-text.
  APPEND lt_hinweise.
  MOVE: zsd_04_kehricht-hinweis2 TO lt_hinweise-code,
        zsd_04_kehricht-hintext2 TO lt_hinweise-text.
  APPEND lt_hinweise.
  MOVE: zsd_04_kehricht-hinweis3 TO lt_hinweise-code,
        zsd_04_kehricht-hintext3 TO lt_hinweise-text.
  APPEND lt_hinweise.
  MOVE: zsd_04_kehricht-hinweis4 TO lt_hinweise-code,
        zsd_04_kehricht-hintext4 TO lt_hinweise-text.
  APPEND lt_hinweise.
  MOVE: zsd_04_kehricht-hinweis5 TO lt_hinweise-code,
        zsd_04_kehricht-hintext5 TO lt_hinweise-text.
  APPEND lt_hinweise.
  MOVE: zsd_04_kehricht-hinweis6 TO lt_hinweise-code,
        zsd_04_kehricht-hintext6 TO lt_hinweise-text.
  APPEND lt_hinweise.
  MOVE: zsd_04_kehricht-hinweis7 TO lt_hinweise-code,
        zsd_04_kehricht-hintext7 TO lt_hinweise-text.
  APPEND lt_hinweise.
  MOVE: zsd_04_kehricht-hinweis8 TO lt_hinweise-code,
        zsd_04_kehricht-hintext8 TO lt_hinweise-text.
  APPEND lt_hinweise.
  CLEAR: zsd_04_kehricht-hinweis1,
         zsd_04_kehricht-hintext1,
         zsd_04_kehricht-hinweis2,
         zsd_04_kehricht-hintext2,
         zsd_04_kehricht-hinweis3,
         zsd_04_kehricht-hintext3,
         zsd_04_kehricht-hinweis4,
         zsd_04_kehricht-hintext4,
         zsd_04_kehricht-hinweis5,
         zsd_04_kehricht-hintext5,
         zsd_04_kehricht-hinweis6,
         zsd_04_kehricht-hintext6,
         zsd_04_kehricht-hinweis7,
         zsd_04_kehricht-hintext7,
         zsd_04_kehricht-hinweis8,
         zsd_04_kehricht-hintext8.
  LOOP AT lt_hinweise.
    IF lt_hinweise-code IS INITIAL.
      DELETE lt_hinweise.
    ENDIF.
  ENDLOOP.
  SORT lt_hinweise BY code.
  LOOP AT lt_hinweise.
    CASE sy-tabix.
      WHEN 1.
        MOVE: lt_hinweise-code TO zsd_04_kehricht-hinweis1,
              lt_hinweise-text TO zsd_04_kehricht-hintext1.
      WHEN 2.
        MOVE: lt_hinweise-code TO zsd_04_kehricht-hinweis2,
              lt_hinweise-text TO zsd_04_kehricht-hintext2.
      WHEN 3.
        MOVE: lt_hinweise-code TO zsd_04_kehricht-hinweis3,
              lt_hinweise-text TO zsd_04_kehricht-hintext3.
      WHEN 4.
        MOVE: lt_hinweise-code TO zsd_04_kehricht-hinweis4,
              lt_hinweise-text TO zsd_04_kehricht-hintext4.
      WHEN 5.
        MOVE: lt_hinweise-code TO zsd_04_kehricht-hinweis5,
              lt_hinweise-text TO zsd_04_kehricht-hintext5.
      WHEN 6.
        MOVE: lt_hinweise-code TO zsd_04_kehricht-hinweis6,
              lt_hinweise-text TO zsd_04_kehricht-hintext6.
      WHEN 7.
        MOVE: lt_hinweise-code TO zsd_04_kehricht-hinweis7,
              lt_hinweise-text TO zsd_04_kehricht-hintext7.
      WHEN 8.
        MOVE: lt_hinweise-code TO zsd_04_kehricht-hinweis8,
              lt_hinweise-text TO zsd_04_kehricht-hintext8.
    ENDCASE.
  ENDLOOP.

ENDMODULE.                 " status_2002  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  status_2003  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2003 OUTPUT.

  PERFORM authority-check USING 'ZIDBOGREAB' w_actvt.
  IF sy-subrc NE 0.
    CALL SCREEN 2000.
    MESSAGE s000 WITH text-e07.
  ENDIF.
  LOOP AT SCREEN.
    IF screen-group1 = '001'.
      IF NOT s_anze IS INITIAL.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
  IF screen-group3 = '003'.
    IF zsd_04_regen-kunnr IS INITIAL
    AND NOT zsd_04_regen-adrnr IS INITIAL.
      screen-active = 1.
      screen-invisible = 0.
    ELSE.
      screen-active = 0.
      screen-invisible = 1.
    ENDIF.
    MODIFY SCREEN.
  ENDIF.
  IF NOT s_anle IS INITIAL
  OR NOT s_aend IS INITIAL.
    IF zsd_04_regen-vkbur IS INITIAL.
      MOVE: '2850' TO zsd_04_regen-vkorg,
            '88'   TO zsd_04_regen-vtweg,
            '10'   TO zsd_04_regen-spart,
            '8800' TO zsd_04_regen-vkbur.
    ENDIF.
  ENDIF.

ENDMODULE.                 " status_2003  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  status_2005  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2005 OUTPUT.

  LOOP AT SCREEN.
    IF screen-group1 = '001'.
      IF NOT s_anze IS INITIAL.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " status_2005  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  status_2006  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2006 OUTPUT.

  LOOP AT SCREEN.
    IF screen-group1 = '001'.
      IF NOT s_anze IS INITIAL.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
  IF screen-group3 = '003'.
    CASE screen-name.
      WHEN '%#AUTOTEXT003'.
        IF t_object_wa-eigentuemer IS INITIAL
        AND NOT t_object_wa-addrnumber_eig IS INITIAL.
          screen-active = 1.
          screen-invisible = 0.
        ELSE.
          screen-active = 0.
          screen-invisible = 1.
        ENDIF.
      WHEN '%#AUTOTEXT004'.
*        IF t_object_wa-verwalter IS INITIAL
*        AND NOT t_object_wa-addrnumber_ver IS INITIAL.
*          screen-active = 1.
*          screen-invisible = 0.
*        ELSE.
*          screen-active = 0.
*          screen-invisible = 1.
*        ENDIF.
    ENDCASE.
    MODIFY SCREEN.
  ENDIF.

ENDMODULE.                 " status_2006  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  status_2007  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2007 OUTPUT.

  LOOP AT SCREEN.
    IF screen-group1 = '001'.
      IF NOT s_anze IS INITIAL.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
  IF screen-group3 = '003'.
    IF zsd_04_boden-kunnr IS INITIAL
    AND NOT zsd_04_boden-adrnr IS INITIAL.
      screen-active = 1.
      screen-invisible = 0.
    ELSE.
      screen-active = 0.
      screen-invisible = 1.
    ENDIF.
    MODIFY SCREEN.
  ENDIF.
  IF NOT s_anle IS INITIAL
  OR NOT s_insr IS INITIAL.
    t_object_wa-no_check_addr = 'X'.
  ENDIF.

ENDMODULE.                 " status_2007  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  status_2004  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2004 OUTPUT.

  PERFORM authority-check USING 'ZIDBOGOFBD' w_actvt.
  IF sy-subrc NE 0.
    CALL SCREEN 2000.
    MESSAGE s000 WITH text-e07.
  ENDIF.
  LOOP AT SCREEN.
    IF screen-group1 = '001'.
      IF NOT s_anze IS INITIAL.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
  IF NOT s_anle IS INITIAL
  OR NOT s_aend IS INITIAL.
    IF zsd_04_boden-vkbur IS INITIAL.
      MOVE: '1500' TO zsd_04_boden-vkorg,
            '51'   TO zsd_04_boden-vtweg,
            '10'   TO zsd_04_boden-spart,
            '5180' TO zsd_04_boden-vkbur.
    ENDIF.
  ENDIF.

ENDMODULE.                 " status_2004  OUTPUT

*---------------------------------------------------------------------*
*       MODULE tc_kehrauft_change_tc_attr OUTPUT                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_kehrauft_change_tc_attr OUTPUT.

  DESCRIBE TABLE t_kehrauft LINES tc_kehrauft-lines.

ENDMODULE.                    "tc_kehrauft_change_tc_attr OUTPUT

*&---------------------------------------------------------------------*
*&      Module  read_kehrauft  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE read_kehrauft OUTPUT.

  TABLES vbfa.
  CHECK t_kehrauft[] IS INITIAL.
  SELECT        * FROM  zsd_05_kehr_auft
         INTO TABLE t_kehrauft
         WHERE  stadtteil  = zsd_04_kehricht-stadtteil
         AND    parzelle   = zsd_04_kehricht-parzelle
         AND    objekt     = zsd_04_kehricht-objekt.
  CHECK t_kehrauft[] IS NOT INITIAL.
  READ TABLE t_kehrauft INTO w_kehrauft INDEX 1.
  SELECT        * FROM  vbfa
         INTO TABLE t_vbfa
         FOR ALL ENTRIES IN t_kehrauft
         WHERE  vbelv    = t_kehrauft-vbeln
         AND    vbtyp_n  = 'M'.
  SORT t_vbfa BY vbelv.
  LOOP AT t_kehrauft INTO w_kehrauft WHERE faknr IS INITIAL.
    CLEAR vbfa.
    READ TABLE t_vbfa INTO vbfa
         WITH KEY vbelv = w_kehrauft-vbeln BINARY SEARCH.
    MOVE: vbfa-vbeln TO w_kehrauft-faknr,
          vbfa-erdat TO w_kehrauft-fkdat.
    MODIFY t_kehrauft FROM w_kehrauft.
    UPDATE zsd_05_kehr_auft FROM w_kehrauft.
  ENDLOOP.
  CLEAR tvko.
  SELECT SINGLE * FROM  tvko CLIENT SPECIFIED
         WHERE  mandt  = sy-mandt
         AND    vkorg  = w_kehrauft-vkorg.
  SELECT        * FROM  bsid
         INTO TABLE t_bsid
         FOR ALL ENTRIES IN t_kehrauft
         WHERE  bukrs  = tvko-bukrs
         AND    vbeln  = t_kehrauft-faknr.
  RANGES r_kunnr FOR bsad-kunnr.
  REFRESH r_kunnr.
  MOVE: 'I' TO r_kunnr-sign,
        'CP' TO r_kunnr-option,
        'G*' TO r_kunnr-low.
  APPEND r_kunnr.
  SELECT        * FROM  bsad
         INTO TABLE t_bsad
         FOR ALL ENTRIES IN t_kehrauft
         WHERE  bukrs  = tvko-bukrs
         AND    kunnr IN r_kunnr
         AND    vbeln  = t_kehrauft-faknr.
  SORT t_bsid BY vbeln.
  SORT t_bsad BY vbeln.
  LOOP AT t_kehrauft INTO w_kehrauft WHERE faknr IS NOT INITIAL.
    CLEAR: w_kehrauft-kennz,
           w_kehrauft-kennz_datum.
* Zuerst bei offenen suchen
    READ TABLE t_bsid INTO bsid
         WITH KEY vbeln = w_kehrauft-faknr BINARY SEARCH.
    IF sy-subrc NE 0.
* Dann bei erledigten suchen
      CLEAR bsad.
      READ TABLE t_bsad INTO bsad
           WITH KEY vbeln = w_kehrauft-faknr BINARY SEARCH.
      SELECT SINGLE * FROM  bkpf CLIENT SPECIFIED
             WHERE  mandt  = bsad-mandt
             AND    bukrs  = bsad-bukrs
             AND    belnr  = bsad-belnr
             AND    gjahr  = bsad-gjahr.
      MOVE: 'B '       TO w_kehrauft-kennz,
            bsad-augdt TO w_kehrauft-kennz_datum,
            bsad-dmbtr TO w_kehrauft-brtwr,
            'CHF' TO w_kehrauft-waers.
      IF bkpf-stblg IS NOT INITIAL.    "Storniert
        SELECT SINGLE * FROM  bkpf CLIENT SPECIFIED
               WHERE  mandt  = bkpf-mandt
               AND    bukrs  = bkpf-bukrs
               AND    belnr  = bkpf-stblg
               AND    gjahr  = bkpf-stjah.
        IF sy-subrc = 0.
          MOVE: 'S '       TO w_kehrauft-kennz,
                bkpf-budat TO w_kehrauft-kennz_datum.
        ENDIF.
      ENDIF.
    ELSE.
      SELECT SINGLE * FROM  bkpf CLIENT SPECIFIED
             WHERE  mandt  = bsid-mandt
             AND    bukrs  = bsid-bukrs
             AND    belnr  = bsid-belnr
             AND    gjahr  = bsid-gjahr.
      IF bkpf-stblg IS NOT INITIAL.    "Storniert
        SELECT SINGLE * FROM  bkpf CLIENT SPECIFIED
               WHERE  mandt  = bkpf-mandt
               AND    bukrs  = bkpf-bukrs
               AND    belnr  = bkpf-stblg
               AND    gjahr  = bkpf-stjah.
        IF sy-subrc = 0.
          MOVE: 'S '       TO w_kehrauft-kennz,
                bkpf-budat TO w_kehrauft-kennz_datum.
        ENDIF.
      ELSE.
        IF bsid-mansp IS NOT INITIAL.
          MOVE 'MS' TO w_kehrauft-kennz.
        ELSEIF bsid-manst IS NOT INITIAL.
          MOVE: 'M '       TO w_kehrauft-kennz,
                bsid-madat TO w_kehrauft-kennz_datum.
          MOVE bsid-manst TO w_kehrauft-kennz+1(1).
        ENDIF.
      ENDIF.
      MOVE: bsid-dmbtr TO w_kehrauft-brtwr,
       'CHF' TO w_kehrauft-waers.
    ENDIF.
    MODIFY t_kehrauft FROM w_kehrauft.
    UPDATE zsd_05_kehr_auft FROM w_kehrauft.
  ENDLOOP.
  SORT t_kehrauft BY verr_datum DESCENDING verr_datum_schl DESCENDING.
* Schattentabelle, um Änderungen zu protokollieren
*  refresh t_kehrauft_h.
*t_kehrauft_h[] = t_kehrauft[].
ENDMODULE.                 " read_kehrauft  OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'RUECKERSTATTUNG'. DO NOT CHANGE THIS L
*&SPWIZARD: COPY DDIC-TABLE TO ITAB
MODULE rueckerstattung_init OUTPUT.
  IF g_rueckerstattung_copied IS INITIAL.
*&SPWIZARD: COPY DDIC-TABLE 'ZSD_05_KEHR_RUEC'
*&SPWIZARD: INTO INTERNAL TABLE 'g_RUECKERSTATTUNG_itab'
    SELECT * FROM zsd_05_kehr_ruec
       INTO CORRESPONDING FIELDS
       OF TABLE g_rueckerstattung_itab
            WHERE stadtteil = zsd_05_objekt-stadtteil
              AND parzelle  = zsd_05_objekt-parzelle
              AND objekt    = t_object_wa-objekt.
    SORT g_rueckerstattung_itab BY von_datum DESCENDING.
    g_rueckerstattung_copied = 'X'.
    REFRESH CONTROL 'RUECKERSTATTUNG' FROM SCREEN '2002'.
  ENDIF.
ENDMODULE.                    "RUECKERSTATTUNG_INIT OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'RUECKERSTATTUNG'. DO NOT CHANGE THIS L
*&SPWIZARD: MOVE ITAB TO DYNPRO
MODULE rueckerstattung_move OUTPUT.
  MOVE-CORRESPONDING g_rueckerstattung_wa TO zsd_05_kehr_ruec.
ENDMODULE.                    "RUECKERSTATTUNG_MOVE OUTPUT

*&SPWIZARD: OUTPUT MODULE FOR TC 'RUECKERSTATTUNG'. DO NOT CHANGE THIS L
*&SPWIZARD: GET LINES OF TABLECONTROL
MODULE rueckerstattung_get_lines OUTPUT.
  g_rueckerstattung_lines = sy-loopc.
ENDMODULE.                    "RUECKERSTATTUNG_GET_LINES OUTPUT
*&---------------------------------------------------------------------*
*&      Module  FILL_ADDR_DATA  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE fill_addr_data OUTPUT.
* CLEAR: gv_fieldname, gv_strucstr, gv_fldstr.

  "Adressdaten ermitteln
  IF NOT zsd_04_kehricht-eigen_kunnr IS INITIAL.
    PERFORM get_addr_data USING    zsd_04_kehricht-eigen_kunnr
                          CHANGING gs_adrs_print.

    "Adressdaten in entsprechende Felder füllen
    MOVE-CORRESPONDING gs_adrs_print TO gs_et_addr_print.
  ELSE.
    CLEAR gs_et_addr_print.
  ENDIF.


  "Adressdaten ermitteln
  IF NOT zsd_04_kehricht-vertr_kunnr IS INITIAL.
    PERFORM get_addr_data USING   zsd_04_kehricht-vertr_kunnr
                          CHANGING gs_adrs_print.

    "Adressdaten in entsprechende Felder füllen
    MOVE-CORRESPONDING gs_adrs_print TO gs_vt_addr_print.
  ELSE.
    CLEAR gs_vt_addr_print.
  ENDIF.


  "Adressdaten ermitteln
  IF NOT zsd_04_kehricht-kunnr IS INITIAL.
    PERFORM get_addr_data USING    zsd_04_kehricht-kunnr
                          CHANGING gs_adrs_print.

    "Adressdaten in entsprechende Felder füllen
    MOVE-CORRESPONDING gs_adrs_print TO gs_re_addr_print.

    SET PARAMETER ID 'KUN' FIELD zsd_04_kehricht-kunnr.
  ELSE.
    CLEAR gs_re_addr_print.
  ENDIF.
***  ENDCASE.
ENDMODULE.                 " FILL_ADDR_DATA  OUTPUT
