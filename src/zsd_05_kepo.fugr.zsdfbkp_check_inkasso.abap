FUNCTION zsdfbkp_check_inkasso.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_FALLNR) TYPE  ZSDEKPFALLNR
*"     REFERENCE(I_GJAHR) TYPE  ZGJAHR
*"     REFERENCE(I_EXT) TYPE  FLAG
*"     REFERENCE(I_TEST) TYPE  FLAG DEFAULT 'X'
*"     REFERENCE(I_CHECKALL) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_LOG) TYPE  FLAG DEFAULT 'X'
*"     REFERENCE(I_CHECK_KUNNR_OLD) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_CHECK_MAHNS) TYPE  MAHNS_D DEFAULT 3
*"  EXPORTING
*"     REFERENCE(E_FSTAT) TYPE  ZSDTKPKEPO-FSTAT
*"     REFERENCE(E_STATUS_A) TYPE  ZSDTKPAUFT-STATUS_A
*"     REFERENCE(E_STATUS_F) TYPE  ZSDTKPAUFT-STATUS_F
*"     REFERENCE(ET_RETURN) TYPE  BAPIRET2_T
*"     REFERENCE(ET_MAIL_MSG) TYPE  BAPIRET2_T
*"----------------------------------------------------------------------

*Log-Meldungen:
*060  Die Kopfdaten zum Fall & & wurden korrekt geändert
*061  Die Kopfdaten zum Fall & & wurden nicht korrekt geändert
*062  Die Auftragsdaten & & zum Fall & & wurden korrekt angelegt
*063  Die Auftragsdaten & & zum Fall & & wurden nicht korrekt angelegt
*064  Die Auftragsdaten & & zum Fall & & wurden korrekt geändert
*065  Die Auftragsdaten & & zum Fall & & wurden nicht korrekt geändert
*066  Die Auftragsdaten & & zum Fall & & wurden korrekt gelöscht
*067  Die Auftragsdaten & & zum Fall & & wurden nicht korrekt gelöscht



  CONSTANTS: c_kepo_msgid TYPE msgid VALUE 'ZSD_05_KEPO'.


  DATA: ls_kepo     TYPE zsdtkpkepo, "Kehrichtpolizei Kopfdaten
        ls_auft     TYPE zsdtkpauft, "Kehrichtpolizei Verrechnungsdaten
        ls_auft_del TYPE zsdtkpauft, "Zu löschender Datensatz, infolge Key-Anpassung
        ls_auft_fw  TYPE zsdtkpauft. "Speicherung, des alten Datensatzes, infolge Fakturawiederholung


  DATA: ld_subrc        TYPE sy-subrc,            "Rückgabewert
        ld_kepo_upd     TYPE flag,                "Update ZSDTKPKEPO
        ld_auft_upd     TYPE flag,                "Update ZSDTKPAUFT
        ld_auft_del_upd TYPE flag,                "Delete before Update ZSDTKPAUFT
        ld_balanced     TYPE flag,                "Ausgeglichen

        ld_msgv1 TYPE symsgv,
        ld_msgv2 TYPE symsgv,
        ld_msgv3 TYPE symsgv,
        ld_msgv4 TYPE symsgv.


  CLEAR: ls_kepo, ls_auft, ls_auft_del, ls_auft_fw, ld_subrc,
         ld_kepo_upd, ld_auft_upd, ld_auft_del_upd, ld_balanced,
         ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.

  ld_subrc = 0.

  "Fall fürs Updaten lesen
  IF i_checkall EQ 'X'.
    "Checkt sämtliche Fälle, welche im System erfasst sind.
    "Ausser die annullierten Fälle werden nicht geprüft,
    "da jene explizit vom Benutzenden annulliert wurden.
    "Alle restlichen Fallstatus werden von der Anwendung gesetzt.
    SELECT SINGLE * FROM zsdtkpkepo INTO ls_kepo
      WHERE fallnr EQ i_fallnr
        AND gjahr  EQ i_gjahr
        AND fstat  NE '04'. "ist nicht annulliert

  ELSE.
    SELECT SINGLE * FROM zsdtkpkepo INTO ls_kepo
      WHERE fallnr EQ i_fallnr
        AND gjahr  EQ i_gjahr
        AND fstat  NE '03'  "ist nicht erledigt
        AND fstat  NE '04'. "ist nicht annulliert
  ENDIF.

  IF sy-subrc EQ 0.
    "Verrechnungsdaten fürs Updaten lesen, letzter erstellter Verrg.-Datensatz lesen
    SELECT * FROM zsdtkpauft INTO ls_auft UP TO 1 ROWS
      WHERE fallnr EQ i_fallnr
      AND   gjahr  EQ i_gjahr
      AND   vbeln_a NE space
      ORDER BY vbeln_a DESCENDING
               vbeln_f DESCENDING.
    ENDSELECT.


    IF sy-subrc EQ 0.
      MOVE-CORRESPONDING ls_auft TO ls_auft_del.

      PERFORM check_invoice USING    i_ext
                                     i_test
                                     i_check_kunnr_old
                                     i_check_mahns
                            CHANGING ls_kepo
                                     ls_auft
                                     ls_auft_fw
                                     ld_subrc
                                     ld_kepo_upd
                                     ld_auft_upd
                                     ld_auft_del_upd
                                     ld_balanced.


      IF ld_subrc NE 0.
        PERFORM check_order USING    i_ext
                                     i_test
                            CHANGING ls_kepo
                                     ls_auft
                                     ld_subrc
                                     ld_kepo_upd
                                     ld_auft_upd
                                     ld_auft_del_upd.
      ENDIF.


      "Status für Export fortschreiben
      e_fstat = ls_kepo-fstat.
      e_status_a = ls_auft-status_a.
      e_status_f = ls_auft-status_f.



      CLEAR: ld_subrc.

      "Update DB-Tabellen
      IF i_test EQ space.
        IF ld_kepo_upd EQ 'X'.
          MODIFY zsdtkpkepo FROM ls_kepo.
          ld_subrc = sy-subrc.

          "Logtabelle füllen
          IF i_log EQ 'X'.
            CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
            ld_msgv1 = ls_kepo-fallnr.
            ld_msgv2 = ls_kepo-gjahr.

            IF ld_subrc EQ 0.
              "Erfolgreichen Update der Kopfdaten
              PERFORM msg_handling TABLES et_return
                                    USING 'I'
                                          c_kepo_msgid
                                          '060'
                                          ld_msgv1
                                          ld_msgv2
                                          space
                                          space.

            ELSE.
              "Fehlerhaften Update der Kopfdaten
              PERFORM msg_handling TABLES et_return
                                    USING 'E'
                                          c_kepo_msgid
                                          '061'
                                          ld_msgv1
                                          ld_msgv2
                                          space
                                          space.
            ENDIF.
          ENDIF.
        ENDIF.

        IF ld_auft_upd EQ 'X'.
          "Wurde eine Fakturawiederholung durchgeführt?
          IF NOT ls_auft_fw IS INITIAL.
            MODIFY zsdtkpauft FROM ls_auft_fw.
            ld_subrc = sy-subrc.


            "Logtabelle füllen
            IF i_log EQ 'X'.
              CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
              ld_msgv1 = ls_auft_fw-fallnr.
              ld_msgv2 = ls_auft_fw-gjahr.
              ld_msgv3 = ls_auft_fw-fallnr.
              ld_msgv4 = ls_auft_fw-gjahr.

              IF ld_subrc EQ 0.
                "Erfolgreichen Update des Auftrag-Datensatzes
                PERFORM msg_handling TABLES et_return
                                      USING 'I'
                                            c_kepo_msgid
                                            '064'
                                            ld_msgv1
                                            ld_msgv2
                                            ld_msgv3
                                            ld_msgv4.

              ELSE.
                "Fehlerhaften Update des Auftrag-Datensatzes
                PERFORM msg_handling TABLES et_return
                                      USING 'E'
                                            c_kepo_msgid
                                            '065'
                                            ld_msgv1
                                            ld_msgv2
                                            ld_msgv3
                                            ld_msgv4.
              ENDIF.
            ENDIF.
          ENDIF.

          "Für einen Auftrag wurde die Faktura erstellt
          MODIFY zsdtkpauft FROM ls_auft.
          ld_subrc = sy-subrc.

          CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
          ld_msgv1 = ls_auft-fallnr.
          ld_msgv2 = ls_auft-gjahr.
          ld_msgv3 = ls_auft-fallnr.
          ld_msgv4 = ls_auft-gjahr.

          IF ld_subrc EQ 0.

            "Logtabelle füllen
            IF i_log EQ 'x'.
              "Erfolgreichen Insert eines Auftrag-Datensatzes
              PERFORM msg_handling TABLES et_return
                                    USING 'I'
                                          c_kepo_msgid
                                          '062'
                                          ld_msgv1
                                          ld_msgv2
                                          ld_msgv3
                                          ld_msgv4.
            ENDIF.

            IF ld_auft_del_upd EQ 'X'.
              DELETE zsdtkpauft FROM ls_auft_del.
              ld_subrc = sy-subrc.


              "Logtabelle füllen
              IF i_log EQ 'X'.
                CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.
                ld_msgv1 = ls_auft_del-fallnr.
                ld_msgv2 = ls_auft_del-gjahr.
                ld_msgv3 = ls_auft_del-fallnr.
                ld_msgv4 = ls_auft_del-gjahr.

                IF ld_subrc EQ 0.
                  "Erfolgreiches Löschen eines Auftrag-Datensatzes
                  PERFORM msg_handling TABLES et_return
                                        USING 'I'
                                              c_kepo_msgid
                                              '066'
                                              ld_msgv1
                                              ld_msgv2
                                              ld_msgv3
                                              ld_msgv4.
                ELSE.
                  "Fehlerhaftes Löschen eines Auftrag-Datensatzes
                  PERFORM msg_handling TABLES et_return
                                        USING 'E'
                                              c_kepo_msgid
                                              '067'
                                              ld_msgv1
                                              ld_msgv2
                                              ld_msgv3
                                              ld_msgv4.
                ENDIF.
              ENDIF.
            ENDIF.
          ELSE.
            "Logtabelle füllen
            IF i_log EQ 'X'.
              "Fehlerhaften Insert eines Auftrag-Datensatzes
              PERFORM msg_handling TABLES et_return
                                    USING 'E'
                                          c_kepo_msgid
                                          '063'
                                          ld_msgv1
                                          ld_msgv2
                                          ld_msgv3
                                          ld_msgv4.
            ENDIF.
          ENDIF.
        ENDIF.

        COMMIT WORK AND WAIT.
      ENDIF.

      IF ld_kepo_upd IS INITIAL AND ld_auft_upd IS INITIAL AND i_log EQ 'X'.
        "Keine Änderungen zum Fall vorgenommen
        CLEAR: ld_msgv1, ld_msgv2.
        ld_msgv1 = i_fallnr.
        ld_msgv2 = i_gjahr.

        PERFORM msg_handling TABLES et_return
                              USING 'I'
                                    c_kepo_msgid
                                    '068'
                                    ld_msgv1
                                    ld_msgv2
                                    space
                                    space.
      ENDIF.
    ENDIF.

    IF ld_balanced EQ 'X'.
      "Mailmeldung - Der Fall wurde ausgeglichen
      CLEAR: ld_msgv1, ld_msgv2, ld_msgv3, ld_msgv4.

      CONCATENATE ls_auft-fallnr ls_auft-gjahr INTO ld_msgv1 SEPARATED BY '/'.
      SHIFT ld_msgv1 LEFT DELETING LEADING '0'.

      WRITE ls_auft-statdat_f TO ld_msgv2 DD/MM/YYYY.
      WRITE ls_kepo-fdat TO ld_msgv3 DD/MM/YYYY.

      ld_msgv4 = ls_kepo-kunnr.
      SHIFT ld_msgv4 LEFT DELETING LEADING '0'.


      PERFORM msg_handling TABLES et_mail_msg
                            USING 'I'
                                  c_kepo_msgid
                                  '100'
                                  ld_msgv1
                                  ld_msgv2
                                  ld_msgv3
                                  ld_msgv4.
    ENDIF.

  ELSE.
    "Logtabelle füllen
    IF i_log EQ 'X'.
      CLEAR: ld_msgv1, ld_msgv2.
      ld_msgv1 = i_fallnr.
      ld_msgv2 = i_gjahr.



      "Kein Fall zur Selektion gefunden
      PERFORM msg_handling TABLES et_return
                            USING 'E'
                                  c_kepo_msgid
                                  '001'
                                  ld_msgv1
                                  ld_msgv2
                                  space
                                  space.
    ENDIF.
  ENDIF.

ENDFUNCTION.
