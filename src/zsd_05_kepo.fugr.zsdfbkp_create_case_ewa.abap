FUNCTION zsdfbkp_create_case_ewa.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_POBJNR) TYPE  J_OBJNR
*"     REFERENCE(I_FART) TYPE  ZSDEKPFART
*"     REFERENCE(I_FDAT) TYPE  ZSDEKPFDAT
*"     REFERENCE(I_FUZEI) TYPE  ZSDEKPFUZEI
*"     REFERENCE(I_FOBJANZ) TYPE  ZSDEFOBJANZ DEFAULT '1'
*"     REFERENCE(I_KREIS) TYPE  ZSDEKPKREIS
*"     REFERENCE(I_STREET) TYPE  AD_STREET
*"     REFERENCE(I_HOUSE_NUM1) TYPE  AD_HSNM1
*"     REFERENCE(I_POST_CODE1) TYPE  AD_PSTCD1
*"     REFERENCE(I_CITY1) TYPE  AD_CITY1
*"     REFERENCE(I_MARBKP) TYPE  ZSDEMARBID DEFAULT 'DUMMY'
*"     REFERENCE(I_SIGNPERS) TYPE  ZSDEMARBID DEFAULT 'DUMMY'
*"     REFERENCE(I_FUNDNR) TYPE  ZWA_KP_FUNDNR OPTIONAL
*"  EXPORTING
*"     REFERENCE(E_FALLNR) TYPE  ZSDTKPKEPO-FALLNR
*"     REFERENCE(E_GJAHR) TYPE  ZSDTKPKEPO-GJAHR
*"     REFERENCE(E_MSG) TYPE  BAPI_MSG
*"     REFERENCE(E_RC) TYPE  SYSUBRC
*"----------------------------------------------------------------------



  CONSTANTS: c_kepo_msgid TYPE msgid VALUE 'ZSD_05_KEPO',
             c_fstat TYPE zsdekpfstat VALUE '01', "erfasst
             c_nkobj TYPE nrobj VALUE 'ZKEPOFALL', "Nummernkreis-Objekt
             c_nknrr TYPE nrnr  VALUE '01'. "Nummernkreis-Range

  DATA:      gs_kepo TYPE zsdtkpkepo.



  "Geschäftsjahr fortschreiben
  e_gjahr = i_fdat.



  "Neue Fallnummer vergeben
  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = c_nknrr
      object                  = c_nkobj
      quantity                = '1'
      toyear                  = e_gjahr
*     IGNORE_BUFFER           = ' '
    IMPORTING
      number                  = e_fallnr
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
    "Fehler bei der Nummernvergabe ausgeben
    e_rc = sy-subrc.
    MESSAGE e110(zsd_05_kepo) INTO e_msg.
  ELSE.
    "Struktur füllen
    gs_kepo-fallnr        = e_fallnr.
    gs_kepo-gjahr         = e_gjahr.
    gs_kepo-fstat         = c_fstat.
    gs_kepo-fart          = i_fart.
    gs_kepo-fdat          = i_fdat.
    gs_kepo-fuzei         = i_fuzei.
    gs_kepo-fobjanz       = i_fobjanz.
    gs_kepo-kreis         = i_kreis.
    gs_kepo-street        = i_street.
    gs_kepo-house_num1    = i_house_num1.
    gs_kepo-post_code1    = i_post_code1.
    gs_kepo-city1         = i_city1.
    gs_kepo-marbkp        = i_marbkp.
    gs_kepo-signpers      = i_signpers.
    gs_kepo-ewa_order_obj = i_pobjnr.
    gs_kepo-fundnr        = i_fundnr.

    "Fall in DB schreiben
    INSERT zsdtkpkepo FROM gs_kepo.

    "Meldung ausgeben
    IF sy-subrc EQ 0.
      e_rc = sy-subrc.
      MESSAGE s010(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr INTO e_msg.
    ELSE.
      e_rc = sy-subrc.
      MESSAGE e011(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr INTO e_msg.
    ENDIF.
  ENDIF.




































*  DATA: ls_kepo     TYPE zsdtkpkepo, "Kehrichtpolizei Kopfdaten
*        ls_auft     TYPE zsdtkpauft, "Kehrichtpolizei Verrechnungsdaten
*        ls_auft_del TYPE zsdtkpauft, "Zu löschender Datensatz, infolge Key-Anpassung
*        ls_auft_fw  TYPE zsdtkpauft. "Speicherung, des alten Datensatzes, infolge Fakturawiederholung
*
*
*  DATA: ld_subrc        TYPE sy-subrc,            "Rückgabewert
*        ld_kepo_upd     TYPE flag,                "Update ZSDTKPKEPO
*        ld_auft_upd     TYPE flag,                "Update ZSDTKPAUFT
*        ld_auft_del_upd TYPE flag,                "Delete before Update ZSDTKPAUFT
*        ld_balanced     TYPE flag,                "Ausgeglichen
*
*        ld_msgv1 TYPE symsgv,
*        ld_msgv2 TYPE symsgv,
*        ld_msgv3 TYPE symsgv,
*        ld_msgv4 TYPE symsgv.
*
*
*  CLEAR: ls_kepo, ls_auft, ls_auft_del, ls_auft_fw, ld_subrc,
*         ld_kepo_upd, ld_auft_upd, ld_auft_del_upd, ld_balanced,
*         ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
*
*  ld_subrc = 0.
*
*  "Fall fürs Updaten lesen
*  IF i_checkall EQ 'X'.
*    "Checkt sämtliche Fälle, welche im System erfasst sind.
*    "Ausser die annullierten Fälle werden nicht geprüft,
*    "da jene explizit vom Benutzenden annulliert wurden.
*    "Alle restlichen Fallstatus werden von der Anwendung gesetzt.
*    SELECT SINGLE * FROM zsdtkpkepo INTO ls_kepo
*      WHERE fallnr EQ i_fallnr
*        AND gjahr  EQ i_gjahr
*        AND fstat  NE '04'. "ist nicht annulliert
*
*  ELSE.
*    SELECT SINGLE * FROM zsdtkpkepo INTO ls_kepo
*      WHERE fallnr EQ i_fallnr
*        AND gjahr  EQ i_gjahr
*        AND fstat  NE '03'  "ist nicht erledigt
*        AND fstat  NE '04'. "ist nicht annulliert
*  ENDIF.
*
*  IF sy-subrc EQ 0.
*    "Verrechnungsdaten fürs Updaten lesen, letzter erstellter Verrg.-Datensatz lesen
*    SELECT * FROM zsdtkpauft INTO ls_auft UP TO 1 ROWS
*      WHERE fallnr EQ i_fallnr
*      AND   gjahr  EQ i_gjahr
*      AND   vbeln_a NE space
*      ORDER BY vbeln_a DESCENDING
*               vbeln_f DESCENDING.
*    ENDSELECT.
*
*
*    IF sy-subrc EQ 0.
*      MOVE-CORRESPONDING ls_auft TO ls_auft_del.
*
*      PERFORM check_invoice USING    i_ext
*                                     i_test
*                                     i_check_kunnr_old
*                                     i_check_mahns
*                            CHANGING ls_kepo
*                                     ls_auft
*                                     ls_auft_fw
*                                     ld_subrc
*                                     ld_kepo_upd
*                                     ld_auft_upd
*                                     ld_auft_del_upd
*                                     ld_balanced.
*
*
*      IF ld_subrc NE 0.
*        PERFORM check_order USING    i_ext
*                                     i_test
*                            CHANGING ls_kepo
*                                     ls_auft
*                                     ld_subrc
*                                     ld_kepo_upd
*                                     ld_auft_upd
*                                     ld_auft_del_upd.
*      ENDIF.
*
*
*      "Status für Export fortschreiben
*      e_fstat = ls_kepo-fstat.
*      e_status_a = ls_auft-status_a.
*      e_status_f = ls_auft-status_f.
*
*
*
*      CLEAR: ld_subrc.
*
*      "Update DB-Tabellen
*      IF i_test EQ space.
*        IF ld_kepo_upd EQ 'X'.
*          MODIFY zsdtkpkepo FROM ls_kepo.
*          ld_subrc = sy-subrc.
*
*          "Logtabelle füllen
*          IF i_log EQ 'X'.
*            CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
*            ld_msgv1 = ls_kepo-fallnr.
*            ld_msgv2 = ls_kepo-gjahr.
*
*            IF ld_subrc EQ 0.
*              "Erfolgreichen Update der Kopfdaten
*              PERFORM msg_handling TABLES et_return
*                                    USING 'I'
*                                          c_kepo_msgid
*                                          '060'
*                                          ld_msgv1
*                                          ld_msgv2
*                                          space
*                                          space.
*
*            ELSE.
*              "Fehlerhaften Update der Kopfdaten
*              PERFORM msg_handling TABLES et_return
*                                    USING 'E'
*                                          c_kepo_msgid
*                                          '061'
*                                          ld_msgv1
*                                          ld_msgv2
*                                          space
*                                          space.
*            ENDIF.
*          ENDIF.
*        ENDIF.
*
*        IF ld_auft_upd EQ 'X'.
*          "Wurde eine Fakturawiederholung durchgeführt?
*          IF NOT ls_auft_fw IS INITIAL.
*            MODIFY zsdtkpauft FROM ls_auft_fw.
*            ld_subrc = sy-subrc.
*
*
*            "Logtabelle füllen
*            IF i_log EQ 'X'.
*              CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
*              ld_msgv1 = ls_auft_fw-fallnr.
*              ld_msgv2 = ls_auft_fw-gjahr.
*              ld_msgv3 = ls_auft_fw-fallnr.
*              ld_msgv4 = ls_auft_fw-gjahr.
*
*              IF ld_subrc EQ 0.
*                "Erfolgreichen Update des Auftrag-Datensatzes
*                PERFORM msg_handling TABLES et_return
*                                      USING 'I'
*                                            c_kepo_msgid
*                                            '064'
*                                            ld_msgv1
*                                            ld_msgv2
*                                            ld_msgv3
*                                            ld_msgv4.
*
*              ELSE.
*                "Fehlerhaften Update des Auftrag-Datensatzes
*                PERFORM msg_handling TABLES et_return
*                                      USING 'E'
*                                            c_kepo_msgid
*                                            '065'
*                                            ld_msgv1
*                                            ld_msgv2
*                                            ld_msgv3
*                                            ld_msgv4.
*              ENDIF.
*            ENDIF.
*          ENDIF.
*
*          "Für einen Auftrag wurde die Faktura erstellt
*          MODIFY zsdtkpauft FROM ls_auft.
*          ld_subrc = sy-subrc.
*
*          CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
*          ld_msgv1 = ls_auft-fallnr.
*          ld_msgv2 = ls_auft-gjahr.
*          ld_msgv3 = ls_auft-fallnr.
*          ld_msgv4 = ls_auft-gjahr.
*
*          IF ld_subrc EQ 0.
*
*            "Logtabelle füllen
*            IF i_log EQ 'x'.
*              "Erfolgreichen Insert eines Auftrag-Datensatzes
*              PERFORM msg_handling TABLES et_return
*                                    USING 'I'
*                                          c_kepo_msgid
*                                          '062'
*                                          ld_msgv1
*                                          ld_msgv2
*                                          ld_msgv3
*                                          ld_msgv4.
*            ENDIF.
*
*            IF ld_auft_del_upd EQ 'X'.
*              DELETE zsdtkpauft FROM ls_auft_del.
*              ld_subrc = sy-subrc.
*
*
*              "Logtabelle füllen
*              IF i_log EQ 'X'.
*                CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
*                ld_msgv1 = ls_auft_del-fallnr.
*                ld_msgv2 = ls_auft_del-gjahr.
*                ld_msgv3 = ls_auft_del-fallnr.
*                ld_msgv4 = ls_auft_del-gjahr.
*
*                IF ld_subrc EQ 0.
*                  "Erfolgreiches Löschen eines Auftrag-Datensatzes
*                  PERFORM msg_handling TABLES et_return
*                                        USING 'I'
*                                              c_kepo_msgid
*                                              '066'
*                                              ld_msgv1
*                                              ld_msgv2
*                                              ld_msgv3
*                                              ld_msgv4.
*                ELSE.
*                  "Fehlerhaftes Löschen eines Auftrag-Datensatzes
*                  PERFORM msg_handling TABLES et_return
*                                        USING 'E'
*                                              c_kepo_msgid
*                                              '067'
*                                              ld_msgv1
*                                              ld_msgv2
*                                              ld_msgv3
*                                              ld_msgv4.
*                ENDIF.
*              ENDIF.
*            ENDIF.
*          ELSE.
*            "Logtabelle füllen
*            IF i_log EQ 'X'.
*              "Fehlerhaften Insert eines Auftrag-Datensatzes
*              PERFORM msg_handling TABLES et_return
*                                    USING 'E'
*                                          c_kepo_msgid
*                                          '063'
*                                          ld_msgv1
*                                          ld_msgv2
*                                          ld_msgv3
*                                          ld_msgv4.
*            ENDIF.
*          ENDIF.
*        ENDIF.
*
*        COMMIT WORK AND WAIT.
*      ENDIF.
*
*      IF ld_kepo_upd IS INITIAL AND ld_auft_upd IS INITIAL AND i_log EQ 'X'.
*        "Keine Änderungen zum Fall vorgenommen
*        CLEAR: ld_msgv1, ld_msgv2.
*        ld_msgv1 = i_fallnr.
*        ld_msgv2 = i_gjahr.
*
*        PERFORM msg_handling TABLES et_return
*                              USING 'I'
*                                    c_kepo_msgid
*                                    '068'
*                                    ld_msgv1
*                                    ld_msgv2
*                                    space
*                                    space.
*      ENDIF.
*    ENDIF.
*
*    IF ld_balanced EQ 'X'.
*      "Mailmeldung - Der Fall wurde ausgeglichen
*      CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
*
*      CONCATENATE ls_auft-fallnr ls_auft-gjahr INTO ld_msgv1 SEPARATED BY '/'.
*      SHIFT ld_msgv1 LEFT DELETING LEADING '0'.
*
*      WRITE ls_auft-statdat_f TO ld_msgv2 DD/MM/YYYY.
*      WRITE ls_kepo-fdat TO ld_msgv3 DD/MM/YYYY.
*
*      ld_msgv4 = ls_kepo-kunnr.
*      SHIFT ld_msgv4 LEFT DELETING LEADING '0'.
*
*
*      PERFORM msg_handling TABLES et_mail_msg
*                            USING 'I'
*                                  c_kepo_msgid
*                                  '100'
*                                  ld_msgv1
*                                  ld_msgv2
*                                  ld_msgv3
*                                  ld_msgv4.
*    ENDIF.
*
*  ELSE.
*    "Logtabelle füllen
*    IF i_log EQ 'X'.
*      CLEAR: ld_msgv1, ld_msgv2.
*      ld_msgv1 = i_fallnr.
*      ld_msgv2 = i_gjahr.
*
*
*
*      "Kein Fall zur Selektion gefunden
*      PERFORM msg_handling TABLES et_return
*                            USING 'E'
*                                  c_kepo_msgid
*                                  '001'
*                                  ld_msgv1
*                                  ld_msgv2
*                                  space
*                                  space.
*    ENDIF.
*  ENDIF.

ENDFUNCTION.
