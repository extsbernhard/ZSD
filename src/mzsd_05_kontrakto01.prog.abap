*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KONTRAKTO01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_3000  OUTPUT
*&---------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE status_3000 OUTPUT.

* Funktionen abhängig vom Pflegemodus ausschalten
  REFRESH it_excl_tab.
* Anlegen
  IF NOT s_anle IS INITIAL.
    MOVE 'AEND' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'ANZE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'DELE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'UNDE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
* Ändern
  ELSEIF NOT s_aend IS INITIAL.
    MOVE 'AEND' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    CASE zsd_05_kontrakt-loesch.
      WHEN 'X'.
        MOVE 'DELE' TO wa_excl_tab-fcode.
        APPEND wa_excl_tab TO it_excl_tab.
      WHEN OTHERS.
        MOVE 'UNDE' TO wa_excl_tab-fcode.
        APPEND wa_excl_tab TO it_excl_tab.
    ENDCASE.
* Anzeigen
  ELSEIF NOT s_anze IS INITIAL.
    MOVE 'ANZE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'SAVE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'DELE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'UNDE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
  ENDIF.
* Dynproausgabe vorbereiten
  SET PF-STATUS '3000' EXCLUDING it_excl_tab.

  IF s_anle = 'X'.
    SET TITLEBAR '300'.
  ELSEIF s_aend = 'X'.
    SET TITLEBAR '301'.
  ELSEIF s_anze = 'X'.
    SET TITLEBAR '302'.
  ENDIF.


* Adresse holen
  CLEAR wa_kontrnehm.
  PERFORM chkread_adr.


* Kopfnotiz lesen
  w_ntyp = 'K'.
  w_proc = 'PBO'.
  w_ncode = 'R'.

  PERFORM notiz_bearb USING w_ncode w_ntyp w_proc.


* Zuordnung lesen
  SELECT SINGLE zuordknr FROM zsd_05_kontrzord
     INTO w_zuordknr1
     WHERE kontrart = zsd_05_kontrakt-kontrart
     AND   kontrnr  = zsd_05_kontrakt-kontrnr
     AND   zuordart = 'A'.

  SELECT SINGLE zuordknr FROM zsd_05_kontrzord
     INTO w_zuordknr2
     WHERE kontrart = zsd_05_kontrakt-kontrart
     AND   kontrnr  = zsd_05_kontrakt-kontrnr
     AND   zuordart = 'B'.

  SELECT SINGLE zuordknr FROM zsd_05_kontrzord
     INTO w_zuordknr3
     WHERE kontrart = zsd_05_kontrakt-kontrart
     AND   kontrnr  = zsd_05_kontrakt-kontrnr
     AND   zuordart = 'C'.

ENDMODULE.                 " STATUS_3000  OUTPUT
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRPOS_init       OUTPUT                           *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrpos_init OUTPUT.

* Kontraktpositionen
  IF g_tc_kontrpos_copied IS INITIAL.

    CLEAR   it_kontrpos.
    REFRESH it_kontrpos.

    SELECT * FROM zsd_05_kontrpos
       INTO CORRESPONDING FIELDS OF TABLE it_kontrpos
       WHERE kontrart = zsd_05_kontrakt-kontrart
       AND   kontrnr  = zsd_05_kontrakt-kontrnr
       ORDER BY posnr.


    g_tc_kontrpos_copied = 'X'.
    REFRESH CONTROL 'TC_KONTRPOS' FROM SCREEN 3000.
  ENDIF.

* Kontraktunterpositionen
  IF g_tc_kontrupos_gesamt_copied IS INITIAL.

    CLEAR   it_kontrupos_gesamt.
    REFRESH it_kontrupos_gesamt.

    SELECT * FROM zsd_05_kontrupos
       INTO CORRESPONDING FIELDS OF TABLE it_kontrupos_gesamt
       WHERE kontrart = zsd_05_kontrakt-kontrart
       AND   kontrnr  = zsd_05_kontrakt-kontrnr
       ORDER BY posnr uposnr.


    g_tc_kontrupos_gesamt_copied = 'X'.
    CLEAR g_tc_kontrupos_copied.
*    REFRESH CONTROL 'TC_KONTRUPOS' FROM SCREEN 4002.
  ENDIF.

ENDMODULE.
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRPOS_get_lines  OUTPUT                           *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrpos_get_lines OUTPUT.

  g_tc_kontrpos_lines = sy-loopc.

ENDMODULE.
*
*&---------------------------------------------------------------------*
*&      Module  STATUS_2000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2000 OUTPUT.

  SET PF-STATUS '2000'.
  SET TITLEBAR '200'.

ENDMODULE.                 " STATUS_2000  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_1000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_1000 OUTPUT.

* Funktionen abhängig vom Pflegemodus ausschalten
  REFRESH it_excl_tab.
  MOVE 'DELE' TO wa_excl_tab-fcode.
  APPEND wa_excl_tab TO it_excl_tab.
* Anlegen
  IF NOT s_anle IS INITIAL.
* Ändern
  ELSEIF NOT s_aend IS INITIAL.
* Anzeigen
  ELSEIF NOT s_anze IS INITIAL.
  ENDIF.
* Dynproausgabe vorbereiten
  SET PF-STATUS '1000' EXCLUDING it_excl_tab.
  SET TITLEBAR '100'.

ENDMODULE.                 " STATUS_1000  OUTPUT
*
*----------------------------------------------------------------------*
*       MODULE TS_KONTRAKT_active_tab_set  OUTPUT                      *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE ts_kontrakt_active_tab_set OUTPUT.

  ts_kontrakt-activetab = g_ts_kontrakt-pressed_tab.
  CASE g_ts_kontrakt-pressed_tab.
    WHEN c_ts_kontrakt-tab1.
      g_ts_kontrakt-subscreen = 3001.
    WHEN c_ts_kontrakt-tab2.
      g_ts_kontrakt-subscreen = 3002.
    WHEN c_ts_kontrakt-tab3.
      g_ts_kontrakt-subscreen = 3003.
    WHEN OTHERS.
*      DO NOTHING
  ENDCASE.

ENDMODULE.
*
*----------------------------------------------------------------------*
*       MODULE TC_KONTRZORD_init      OUTPUT                           *
*----------------------------------------------------------------------*
*       ........                                                       *
*----------------------------------------------------------------------*
MODULE tc_kontrzord_init OUTPUT.

  IF g_tc_kontrzord_copied IS INITIAL.

    CLEAR   it_kontrzord.
    REFRESH it_kontrzord.

    SELECT * FROM zsd_05_kontrzord
       INTO CORRESPONDING FIELDS OF TABLE it_kontrzord
       WHERE zuordart = zsd_05_kontrakt-kontrart
       AND   zuordknr = zsd_05_kontrakt-kontrnr.

    g_tc_kontrzord_copied = 'X'.

    REFRESH CONTROL 'TC_KONTRZORD' FROM SCREEN 3001.
  ENDIF.
ENDMODULE.
*
*---------------------------------------------------------------------*
*       MODULE TC_KONTRZORD_get_lines OUTPUT                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE tc_kontrzord_get_lines OUTPUT.

  g_tc_kontrzord_lines = sy-loopc.

ENDMODULE.
*
*&---------------------------------------------------------------------*
*&      Module  STATUS_4000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_4000 OUTPUT.

* Funktionen abhängig vom Pflegemodus ausschalten
  REFRESH it_excl_tab.
  MOVE 'DELE' TO wa_excl_tab-fcode.
  APPEND wa_excl_tab TO it_excl_tab.
* Anlegen
  IF NOT s_insr IS INITIAL.
    MOVE 'AEND' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'ANZE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
* Ändern
  ELSEIF NOT s_aend IS INITIAL AND s_insr IS INITIAL.
    MOVE 'AEND' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
* Anzeigen
  ELSEIF NOT s_anze IS INITIAL.
    MOVE 'ANZE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'SAVE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
  ENDIF.

* Position mit Löschvermerk
  IF NOT zsd_05_kontrpos-loesch IS INITIAL.
    MOVE 'AEND' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'ANZE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
    MOVE 'SAVE' TO wa_excl_tab-fcode.
    APPEND wa_excl_tab TO it_excl_tab.
  ENDIF.


* Dynproausgabe vorbereiten
  SET PF-STATUS '4000' EXCLUDING it_excl_tab.


* Kopfnotiz lesen
  w_ntyp = 'P'.
  w_proc = 'PBO'.
  w_ncode = 'R'.

  PERFORM notiz_bearb USING w_ncode w_ntyp w_proc.


* Set Titlebar
  IF s_insr = 'X'.
    SET TITLEBAR '400'.
  ELSEIF s_aend = 'X' AND s_insr IS INITIAL.
    SET TITLEBAR '401'.
  ELSEIF s_anze = 'X'.
    SET TITLEBAR '402'.
  ENDIF.

* Set Titlebar Position mit Löschvermerk
  IF NOT zsd_05_kontrpos-loesch IS INITIAL.
    SET TITLEBAR '402'.
  ENDIF.


ENDMODULE.                 " status_4000  OUTPUT
*
*---------------------------------------------------------------------*
*       MODULE TS_KONTRPOS_active_tab_set   OUTPUT                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE ts_kontrpos_active_tab_set OUTPUT.

  ts_kontrpos-activetab = g_ts_kontrpos-pressed_tab.
  CASE g_ts_kontrpos-pressed_tab.
    WHEN c_ts_kontrpos-tab1.
      g_ts_kontrpos-subscreen = 4001.
    WHEN c_ts_kontrpos-tab2.
      g_ts_kontrpos-subscreen = 4002.
    WHEN c_ts_kontrpos-tab3.
      g_ts_kontrpos-subscreen = 4003.
    WHEN OTHERS.
*      DO NOTHING

  ENDCASE.

ENDMODULE.
*
*&---------------------------------------------------------------------*
*&      Module  feld_nur_ausgabe  OUTPUT
*&---------------------------------------------------------------------*
*       Feld nach Auswahl der Radiobutton aktivieren/deaktivieren
*----------------------------------------------------------------------*
MODULE feld_nur_ausgabe OUTPUT.

  IF rb_kk1 IS INITIAL AND rb_lk1 IS INITIAL.
    rb_kk1 = 'X'.
  ENDIF.

  LOOP AT SCREEN.
    IF rb_kk1 = 'X'.
      IF screen-name = 'KNA1-KUNNR'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'LFA1-LIFNR'.
        screen-input = 0.
        CLEAR lfa1-lifnr.
        IF lfa1-lifnr IS INITIAL AND kna1-kunnr IS INITIAL
          AND zsd_05_kontrakt-adrnr IS INITIAL.
          CLEAR wa_kontrnehm.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    IF rb_lk1 = 'X'.
      IF screen-name = 'KNA1-KUNNR'.
        screen-input = 0.
        CLEAR kna1-kunnr.
        IF lfa1-lifnr IS INITIAL AND kna1-kunnr IS INITIAL
          AND zsd_05_kontrakt-adrnr IS INITIAL.
          CLEAR wa_kontrnehm.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'LFA1-LIFNR'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " feld_nur_ausgabe  OUTPUT

*
*&---------------------------------------------------------------------*
*&      Module  tc_kontrupos_change_col_attr  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_kontrupos_change_col_attr OUTPUT.

  DESCRIBE TABLE it_kontrupos LINES tc_kontrupos-lines.
  LOOP AT tc_kontrupos-cols INTO g_tc_kontrupos-cols_wa.
    IF g_tc_kontrupos-cols_wa-screen-group2 = 'INP'.
      CASE s_insr1.
        WHEN 'X'.
          MOVE '1' TO g_tc_kontrupos-cols_wa-screen-input.
          MODIFY tc_kontrupos-cols FROM g_tc_kontrupos-cols_wa.
        WHEN space.
          IF s_btnkupupd IS INITIAL.
            MOVE '0' TO g_tc_kontrupos-cols_wa-screen-input.
            MODIFY tc_kontrupos-cols FROM g_tc_kontrupos-cols_wa.
          ENDIF.
      ENDCASE.
    ENDIF.
  ENDLOOP.
  CLEAR s_insr1.

ENDMODULE.
*
*&---------------------------------------------------------------------*
*&      Module  init_all  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_all OUTPUT.

  CLEAR:   zsd_05_kontrakt,
           zsd_05_kontrzord,
           zsd_05_kontrpos,
           zsd_05_kontrupos,
           kna1,
           lfa1,
           makt,
           adrc,

           it_kontrakt,
           it_kontrzord,
           it_adrc,
           it_kna1,
           it_lfa1,
           it_makt,

           wa_kontrakt,
           wa_kontrzord,
           wa_adrc,
           wa_kna1,
           wa_lfa1,
           wa_makt,

           it_kontrpos,
           wa_kontrpos,
           it_kontrupos,
           wa_kontrupos,
           it_kontrnehm,
           wa_kontrnehm,

           it_addr1_dia,
           it_addr1_data,

           ok_code,
           w_textinfo,
           w_textinfok,
           w_textinfop,
           w_textline1,
           w_textline2,
           w_answer,
           w_kontrakt,
           w_bezeichn,
           w_kontrnehmart,
           w_returncode,
           w_zuordknr1,
           w_zuordknr2,
           w_zuordknr3,
           rb_kk1,
           rb_lk1,
           rb_pkt1,
           rb_prz1,
           s_anle,
           s_aend,
           s_anze,
           s_insr,
           s_insr1,
           s_btnkupupd,
           s_delete,
           s_enqueue,

           g_tc_kontrpos_copied,
           g_tc_kontrupos_copied,
           g_tc_kontrupos_gesamt_copied,
           g_tc_kontrzord_copied.

ENDMODULE.                 " init_all  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  tc_kontrpos_change_col_attr  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_kontrpos_change_col_attr OUTPUT.

  DESCRIBE TABLE it_kontrpos LINES tc_kontrpos-lines.
  LOOP AT tc_kontrpos-cols INTO g_tc_kontrpos-cols_wa.
    IF g_tc_kontrpos-cols_wa-screen-group2 = 'INP'.
      CASE s_insr.
        WHEN 'X'.
          MOVE '1' TO g_tc_kontrpos-cols_wa-screen-input.
          MODIFY tc_kontrpos-cols FROM g_tc_kontrpos-cols_wa.
        WHEN space.
          MOVE '0' TO g_tc_kontrpos-cols_wa-screen-input.
          MODIFY tc_kontrpos-cols FROM g_tc_kontrpos-cols_wa.
      ENDCASE.
    ENDIF.
  ENDLOOP.
  CLEAR s_insr.

ENDMODULE.                 " tc_kontrpos_change_col_attr  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  screen_modify  OUTPUT
*&---------------------------------------------------------------------*
*       Generelle Bildschirmeingaben setzen
*----------------------------------------------------------------------*
MODULE screen_modify OUTPUT.

  LOOP AT SCREEN.
    IF s_anle = 'X' OR s_aend = 'X'.
      IF screen-group1 = 'ANZ'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
    ELSEIF s_anze = 'X'.
      IF screen-group1 = 'ANZ'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.


ENDMODULE.                 " screen_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  1000_modify  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 1000_modify OUTPUT.

  LOOP AT SCREEN.
    IF     s_anle = 'X'.
    ELSEIF s_aend = 'X'.
    ELSEIF s_anze = 'X'.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " 1000_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  2000_modify  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 2000_modify OUTPUT.

  LOOP AT SCREEN.
    IF     s_anle = 'X'.
    ELSEIF s_aend = 'X'.
    ELSEIF s_anze = 'X'.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " 2000_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  3000_modify  OUTPUT
*&---------------------------------------------------------------------*
*       Bildschirmeingabe Screen 3000 setzen
*----------------------------------------------------------------------*
MODULE 3000_modify OUTPUT.

  CLEAR w_shelp.

  IF w_kontrnehmart = 'Kunde'.
    w_shelp = 'DEBI'.
  ELSEIF w_kontrnehmart = 'Lieferant'.
    w_shelp = 'KRED'.
  ENDIF.

  LOOP AT SCREEN.
    IF w_textinfok IS INITIAL.
      IF screen-name = 'BTN_DELKNOTIZ'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    CASE zsd_05_kontrakt-kontrart.
      WHEN 'A'. "Rahmenvertrag
        IF screen-group2 = 'KZ0'.
          screen-active = 0.
          MODIFY SCREEN.
        ENDIF.
      WHEN 'B'. "Objektkonzession
        IF screen-group3 = 'KZ1'.
          screen-active = 0.
          MODIFY SCREEN.
        ENDIF.
      WHEN 'C'. "Rahmenvertrag
        IF screen-group4 = 'KZ2'.
          screen-active = 0.
          MODIFY SCREEN.
        ENDIF.
    ENDCASE.

    IF     s_anle = 'X'.
    ELSEIF s_aend = 'X'.
    ELSEIF s_anze = 'X'.

      IF screen-name = 'W_ZUORDKNR1'.
        IF w_zuordknr1 IS INITIAL.
          screen-active = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.

      IF screen-name = 'W_ZUORDKNR2'.
        IF w_zuordknr2 IS INITIAL.
          screen-active = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.

      IF screen-name = 'W_ZUORDKNR3'.
        IF w_zuordknr3 IS INITIAL.
          screen-active = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.

      IF w_textinfok IS INITIAL.
        IF screen-name = 'BTN_KNOTIZ'.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " 3000_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  3001_modify  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 3001_modify OUTPUT.

  LOOP AT SCREEN.
    IF     s_anle = 'X'.
    ELSEIF s_aend = 'X'.
    ELSEIF s_anze = 'X'.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " 3001_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  3002_modify  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 3002_modify OUTPUT.

  PERFORM split_dateilink.

  IF zsd_05_kontrakt-dateilink IS INITIAL.
    LOOP AT SCREEN.
      IF screen-name = 'BTN_DELLINK'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.

      IF screen-name = 'BTN_FILEOPEN'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.


  IF     s_anle = 'X'.
  ELSEIF s_aend = 'X'.
  ELSEIF s_anze = 'X'.

    LOOP AT SCREEN.
      IF zsd_05_kontrakt-dateilink IS INITIAL.
        IF screen-name = 'BTN_FILEOPEN'.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.

      IF screen-name = 'BTN_DELLINK'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

  ENDIF.

ENDMODULE.                 " 3002_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  3003_modify  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 3003_modify OUTPUT.

  LOOP AT SCREEN.
    IF     s_anle = 'X'.
    ELSEIF s_aend = 'X'.
    ELSEIF s_anze = 'X'.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " 3003_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  4000_modify  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 4000_modify OUTPUT.

  LOOP AT SCREEN.

    IF screen-name = 'BTN_BWG1'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.


    IF w_textinfop IS INITIAL.
      IF screen-name = 'BTN_DELPNOTIZ'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.


    IF zsd_05_kontrpos-loesch = 'X'.
      IF screen-group1 = 'ANZ'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'BTN_PNOTIZ'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.


    IF     s_anle = 'X'.
    ELSEIF s_aend = 'X'.
    ELSEIF s_anze = 'X'.

      IF w_textinfop IS INITIAL.
        IF screen-name = 'BTN_PNOTIZ'.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.

    ENDIF.
  ENDLOOP.

ENDMODULE.                 " 4000_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  4001_modify  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 4001_modify OUTPUT.

* Indexpunkte - Einheit setzen
  IF zsd_05_kontrpos-index_diffeinh = 'P'.
    CLEAR rb_prz1.
    rb_pkt1 = 'X'.
  ELSEIF zsd_05_kontrpos-index_diffeinh = 'Z'.
    CLEAR rb_pkt1.
    rb_prz1 = 'X'.
  ENDIF.

  IF rb_pkt1 IS INITIAL AND rb_prz1 IS INITIAL.
    rb_pkt1 = 'X'.
  ENDIF.



* Steuerung Eingabe: Grund keine Verrechnung
* Steuerung Eingabe: Indexfelder
  IF NOT s_anle IS INITIAL OR
     NOT s_aend IS INITIAL.
    PERFORM verr_grund_input.
    PERFORM verrtyp_input.
  ENDIF.




* Eingabebereitschaft der Felder nach erster Fakturierung
  SELECT SINGLE * FROM zsd_05_kontrverr
    WHERE kontrart = zsd_05_kontrpos-kontrart
    AND   kontrnr  = zsd_05_kontrpos-kontrnr
    AND   posnr    = zsd_05_kontrpos-posnr.

  IF sy-subrc EQ 0.
    LOOP AT SCREEN.
      IF screen-name = 'ZSD_05_KONTRPOS-INDEX_KEY'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'ZSD_05_KONTRPOS-INDEX_BASIS'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'ZSD_05_KONTRPOS-INDEX_GJAHR'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'ZSD_05_KONTRPOS-INDEX_MONAT'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'ZSD_05_KONTRPOS-INDEX_STAND'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'ZSD_05_KONTRPOS-INDEX_DIFFSTAND'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'RB_PKT1'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'RB_PRZ1'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'ZSD_05_KONTRPOS-VERRTYP'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
      IF screen-name = 'ZSD_05_KONTRPOS-FAKTDATAB'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.



** Preis ermitteln
*  IF zsd_05_kontrpos-verrtyp NE 'K'. " Verrgtyp ist nicht Kontraktpreis
*    CLEAR wa_a004.
*    CLEAR wa_konp.
*    CLEAR zsd_05_kontrpos-preis.
*
*    SELECT SINGLE * FROM a004 INTO wa_a004
*      WHERE vkorg =  w_vkorg
*      AND   vtweg =  w_vtweg
*      AND   matnr =  zsd_05_kontrpos-matnr
*      AND   datab <= sy-datum
*      AND   datbi >= sy-datum.
*
*    SELECT SINGLE * FROM konp INTO wa_konp
*      WHERE knumh = wa_a004-knumh
*      AND   kschl = w_kschl.
*
*    IF sy-subrc NE 0.
*      MESSAGE w000(zsd_04) WITH 'Zum Material' zsd_05_kontrpos-matnr
*                                'kein Preis gefunden.'.
*    ELSE.
*      MOVE wa_konp-kbetr TO zsd_05_kontrpos-preis.
*    ENDIF.
*  ENDIF.



* Betragsberechnung
  CLEAR w_betr.

  IF zsd_05_kontrpos-verr_code IS INITIAL.
    w_betr = zsd_05_kontrpos-menge_pos * zsd_05_kontrpos-preis /
             zsd_05_kontrpos-peinh.
  ENDIF.

  LOOP AT SCREEN.

    IF zsd_05_kontrpos-loesch = 'X'.
      IF screen-group1 = 'ANZ'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.


    IF     s_anle = 'X'.
    ELSEIF s_aend = 'X'.
    ELSEIF s_anze = 'X'.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " 4001_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  4002_modify  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 4002_modify OUTPUT.

  LOOP AT SCREEN.

    IF zsd_05_kontrpos-loesch = 'X'.
      IF screen-group1 = 'ANZ'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

*    IF     s_anle = 'X'.
*    ELSEIF s_aend = 'X'.
*    ELSEIF s_anze = 'X'.
*    ENDIF.

  ENDLOOP.

ENDMODULE.                 " 4002_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  4003_modify  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 4003_modify OUTPUT.

  LOOP AT SCREEN.
    IF     s_anle = 'X'.
    ELSEIF s_aend = 'X'.
    ELSEIF s_anze = 'X'.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " 4003_modify  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  tc_kontrupos_get_lines  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_kontrupos_get_lines OUTPUT.

  g_tc_kontrupos_lines = sy-loopc.

ENDMODULE.                 " tc_kontrupos_get_lines  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  tc_kontrupos_init  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_kontrupos_init OUTPUT.

  IF g_tc_kontrupos_copied IS INITIAL.
    CLEAR   it_kontrupos.
    REFRESH it_kontrupos.

    LOOP AT it_kontrupos_gesamt INTO wa_kontrupos_gesamt
      WHERE   posnr    = zsd_05_kontrpos-posnr.

      IF sy-subrc = 0.
        APPEND wa_kontrupos_gesamt TO it_kontrupos.
      ENDIF.
    ENDLOOP.

    SORT it_kontrupos BY posnr uposnr.

    g_tc_kontrupos_copied = 'X'.
    REFRESH CONTROL 'TC_KONTRUPOS' FROM SCREEN 4002.
  ENDIF.

ENDMODULE.                 " tc_kontrupos_init  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  berechnung_kontrbetr  OUTPUT
*&---------------------------------------------------------------------*
*       Berechnung Kontraktbetrag
*----------------------------------------------------------------------*
MODULE berechnung_kontrbetr OUTPUT.

  DATA: lv_kontrbetr TYPE kbetr,
        lv_zahlcal   TYPE p DECIMALS 3, "Drei Nachkommastellen!!!
        lv_zahlout   TYPE p DECIMALS 2. "Zwei Nachkommastellen!!!


  CLEAR: lv_kontrbetr,
         lv_zahlcal,
         lv_zahlout,
         zsd_05_kontrakt-kontrbetr.


  LOOP AT it_kontrpos.
    IF it_kontrpos-verr_code IS INITIAL.
      lv_kontrbetr = it_kontrpos-menge_pos * it_kontrpos-preis /
                     it_kontrpos-peinh.

      ADD lv_kontrbetr TO lv_zahlcal.
    ENDIF.
  ENDLOOP.


  lv_zahlout = lv_zahlcal / 5.
  lv_zahlout = lv_zahlout * 5.


  zsd_05_kontrakt-kontrbetr = lv_zahlout.

ENDMODULE.                 " berechnung_kontrbetr  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  check_enqueue  OUTPUT
*&---------------------------------------------------------------------*
*       Objekt sperren?
*----------------------------------------------------------------------*
MODULE check_enqueue OUTPUT.

* Objekt sperren, wenn im Änderungs- oder Anlege-Modus
  IF NOT zsd_05_kontrakt IS INITIAL
  AND s_enqueue IS INITIAL
  AND ( NOT s_anle IS INITIAL OR
        NOT s_aend IS INITIAL ).

    CALL FUNCTION 'ENQUEUE_EZSD05_KONTRAKT'
         EXPORTING
              mode_zsd_05_kontrakt = 'E'
              mandt                = sy-mandt
              kontrart             = zsd_05_kontrakt-kontrart
              kontrnr              = zsd_05_kontrakt-kontrnr
              x_kontrart           = ' '
              x_kontrnr            = ' '
              _scope               = '2'
              _wait                = ' '
              _collect             = ' '
         EXCEPTIONS
              foreign_lock         = 1
              system_failure       = 2
              OTHERS               = 3.
    IF sy-subrc <> 0.
      DATA l_msgv1 LIKE sy-msgv1.
      MOVE sy-msgv1 TO l_msgv1.
      MESSAGE s000 WITH text-e10 l_msgv1 text-e11.
      CLEAR: s_anle,
             s_aend.
      s_anze = 'X'.
    ELSE.
      s_enqueue = 'X'.
    ENDIF.
  ENDIF.

ENDMODULE.                 " check_enqueue  OUTPUT
*
*&---------------------------------------------------------------------*
*&      Module  parzelle  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE parzelle OUTPUT.

  DATA: lv_adr       TYPE string,
        lv_ort       TYPE string.
  CLEAR: ls_cp_objekt, lv_adr, lv_ort, w_adrpos.

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

ENDMODULE.                 " parzelle  OUTPUT
