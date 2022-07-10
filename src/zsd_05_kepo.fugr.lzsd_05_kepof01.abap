*&---------------------------------------------------------------------*
*       Fall-, Auftrag- und Fakturastatus
*
*       Fallstatus: 01 = erfasst
*                   02 = offen
*                   03 = erledigt
*                   04 = annulliert
*
*       Auftr.stat: 01 = offen
*                   02 = fakturiert
*                   03 = storniert
*                   99 = Fakturawiederholung
*
*       Fakt.stat:  01 = offen
*                   02 = bezahlt
*                   03 = storniert
*                   04 = gemahnt

*       cd_subrc:   0  = Alle mögliche Status gesetzt
*                   4  = Nicht alle mögliche Status gesetzt

*----------------------------------------------------------------------*


*&---------------------------------------------------------------------*
*&      Form  CHECK_INVOICE
*&---------------------------------------------------------------------*
*       Prüft fakturarelevante Vorgänge und passt die Status dem-
*       entsprechend an.
*
*       Die Strukturen Fall-Kopfdaten und -Auftagsdaten, die Status,
*       der SUBRC (um Verarbeitungen zu überspringen) und die Update-
*       info der upzudateten DB-Tabellen werden wieder zurückgegeben.
*       Muss der Auftrags-Datensatz (infolge neuer Key-Vergabe)
*       vorher gelöscht werden, wird das Flag CD_AUFT_DEL_UPD gesetzt.
*----------------------------------------------------------------------*

FORM check_invoice  USING    ud_ext
                             ud_test
                             ud_check_kunnr_old
                             ud_check_mahns
                    CHANGING cs_kepo    STRUCTURE zsdtkpkepo
                             cs_auft    STRUCTURE zsdtkpauft
                             cs_auft_fw STRUCTURE zsdtkpauft
                             cd_subrc
                             cd_kepo_upd
                             cd_auft_upd
                             cd_auft_del_upd
                             cd_balanced.

  DATA: ls_bkpf TYPE bkpf,       "Buchhaltung: Belegkopf
        ls_bsid TYPE bsid,       "Buchhaltung: Offene Posten
        ls_bsad TYPE bsad,       "Buchhaltung: Ausgeglichene Posten
        ls_mhnd TYPE mhnd,       "Mahndaten
        ls_knb5 TYPE knb5,       "Kundenstamm Mahndaten
        ls_vbfa TYPE vbfa,       "Vertriebsbelegfluss
        ls_vbrk TYPE vbrk.       "Faktura: Kopfdaten


  DATA: ld_mahns  TYPE mahns_d,             "Mahnstufe
        ld_fname  TYPE fieldname,           "Feldname
        ld_subrc  TYPE sy-subrc.            "Rückgabewert


  FIELD-SYMBOLS:  <fld>.

  CLEAR: ls_bkpf, ls_bsid, ls_bsad, ls_mhnd, ls_knb5, ls_vbfa, ls_vbrk, ld_mahns, ld_fname, ld_subrc.

  clear: cd_balanced.


  "Wurde der Auftrag mittels Standarttransaktion fakturiert?

  "Im Vertriebsbelegfluss prüfen
  SELECT * FROM vbfa INTO ls_vbfa UP TO 1 ROWS
    WHERE vbelv   EQ cs_auft-vbeln_a
      AND vbtyp_n EQ 'M'
    ORDER BY erdat DESCENDING erzet DESCENDING.
  ENDSELECT.

  "Wenn vorhanden, Kopfdaten der Faktura lesen, um Auftragstabelle zu füllen und Status zu setzen.
  IF sy-subrc EQ 0.
    SELECT SINGLE * FROM vbrk INTO ls_vbrk
      WHERE vbeln EQ ls_vbfa-vbeln.

    IF sy-subrc EQ 0.
      IF ls_vbrk-vbeln NE cs_auft-vbeln_f AND NOT cs_auft-vbeln_f IS INITIAL.
        "Fakturawiederholung
        MOVE-CORRESPONDING cs_auft TO cs_auft_fw.

        "Status bei Fakturawiederholung setzen
        cs_auft_fw-statdat_a = ls_vbrk-erdat.
        cs_auft_fw-statzet_a = ls_vbrk-erzet.
        cs_auft_fw-status_a  = '99'. "Fakturawiederholung

        "Fakturaspezifische Felder initialisieren
        CLEAR: cs_auft-vbeln_f, cs_auft-beldat_f, cs_auft-ernam_f, cs_auft-erdat_f,
               cs_auft-erzet_f, cs_auft-netwr_f, cs_auft-waerk_f, cs_auft-stonam_f,
               cs_auft-stodat_f, cs_auft-stozet_f, cs_auft-status_f, cs_auft-statdat_f,
               cs_auft-statzet_f.

        "Daten füllen, für einen neuen Datensatz bei Fakturawiederholung
        cs_kepo-fstat     = '02'. "offen

        cs_auft-statdat_a = ls_vbrk-erdat.
        cs_auft-statzet_a = ls_vbrk-erzet.
        cs_auft-status_a  = '02'. "fakturiert

        cs_auft-vbeln_f   = ls_vbrk-vbeln.
        cs_auft-beldat_f  = ls_vbrk-fkdat.
        cs_auft-ernam_f   = ls_vbrk-ernam.
        cs_auft-erdat_f   = ls_vbrk-erdat.
        cs_auft-erzet_f   = ls_vbrk-erzet.
        cs_auft-netwr_f   = ls_vbrk-netwr.
        cs_auft-waerk_f   = ls_vbrk-waerk.
        cs_auft-status_f  = '01'. "offen
        cs_auft-statdat_f = ls_vbrk-erdat.
        cs_auft-statzet_f = ls_vbrk-erzet.

        cd_kepo_upd = 'X'.
        cd_auft_upd = 'X'.
        cd_subrc    = 0.

      ELSEIF cs_auft-vbeln_f IS INITIAL.
        "Datensatz muss gelöscht werden, und mit den Fakturadaten
        "erneut erstellt werden, da die Belegnummern im Key sind
        cd_auft_del_upd = 'X'.

        "Daten füllen, für einen neuen Datensatz
        cs_kepo-fstat     = '02'. "offen

        cs_auft-statdat_a = ls_vbrk-erdat.
        cs_auft-statzet_a = ls_vbrk-erzet.
        cs_auft-status_a  = '02'. "fakturiert

        cs_auft-vbeln_f   = ls_vbrk-vbeln.
        cs_auft-beldat_f  = ls_vbrk-fkdat.
        cs_auft-ernam_f   = ls_vbrk-ernam.
        cs_auft-erdat_f   = ls_vbrk-erdat.
        cs_auft-erzet_f   = ls_vbrk-erzet.
        cs_auft-netwr_f   = ls_vbrk-netwr.
        cs_auft-waerk_f   = ls_vbrk-waerk.
        cs_auft-status_f  = '01'. "offen
        cs_auft-statdat_f = ls_vbrk-erdat.
        cs_auft-statzet_f = ls_vbrk-erzet.

        cd_kepo_upd = 'X'.
        cd_auft_upd = 'X'.
        cd_subrc    = 0.
      ENDIF.
    ENDIF.
  ENDIF.


  "Wurde der Auftrag überhaupts fakturiert?
  IF cs_auft-vbeln_f IS INITIAL.
    CLEAR: cd_kepo_upd, cd_auft_upd.
    cd_subrc = 4.

  ELSE.
    "Mahnsperre aus Debitor fortschreiben
    SELECT SINGLE * FROM knb5 INTO ls_knb5
      WHERE kunnr EQ cs_kepo-kunnr
        AND bukrs EQ cs_kepo-bukrs.

    IF ls_knb5-mansp NE cs_auft-mansp.
      cs_auft-mansp = ls_knb5-mansp.

      cd_auft_upd = 'X'.
      cd_subrc = 0.
    ENDIF.


    "Mahnungen zu den drei Mahnstufen lesen, und Datum fortschreiben.
    DO ud_check_mahns TIMES.
      ADD 1 TO ld_mahns.
      CLEAR: ld_fname, ls_mhnd.

      CONCATENATE 'CS_AUFT-MANH' ld_mahns '_F' INTO ld_fname.
      ASSIGN (ld_fname) TO <fld>.

      "Nur leere Datumsfelder füllen.
      IF <fld> IS INITIAL.
        "Mahndaten, falls vorhanden lesen
        SELECT SINGLE * FROM mhnd INTO ls_mhnd
          WHERE koart  EQ 'D' "Debitor
            AND bukrs  EQ ls_vbrk-bukrs
            AND kunnr  EQ cs_kepo-kunnr
            AND xblnr  EQ cs_auft-vbeln_f
            AND gjahr  EQ cs_auft-beldat_f(4)
            AND mahnn EQ ld_mahns. "neue Mahnstufe
        "AND mahns EQ ld_mahns. "alte Mahnstufe

        IF sy-subrc EQ 0.
          <fld> = ls_mhnd-laufd.

          "Fakturastatus setzen
          IF cs_auft-status_f EQ '01' OR cs_auft-status_f EQ '04'. "offen oder gemahnt
            cs_auft-status_f = '04'.   "gemahnt
            cs_auft-statdat_f = ls_mhnd-laufd.
            cs_auft-statzet_f = '000000'.
          ENDIF.

          cd_auft_upd = 'X'.
        ELSE.
          "Mahndaten auch zu alter Kundennummer prüfen, wenn nichts gefunden wurde
          IF NOT ud_check_kunnr_old IS INITIAL.
            "Mahndaten, falls vorhanden lesen
            SELECT SINGLE * FROM mhnd INTO ls_mhnd
              WHERE koart  EQ 'D' "Debitor
                AND bukrs  EQ ls_vbrk-bukrs
                AND kunnr  EQ cs_kepo-kunnr_old
                AND xblnr  EQ cs_auft-vbeln_f
                AND gjahr  EQ cs_auft-beldat_f(4)
                AND mahnn EQ ld_mahns. "neue Mahnstufe
            IF sy-subrc EQ 0.
              <fld> = ls_mhnd-laufd.

              "Fakturastatus setzen
              IF cs_auft-status_f EQ '01' OR cs_auft-status_f EQ '04'. "offen oder gemahnt
                cs_auft-status_f = '04'.   "gemahnt
                cs_auft-statdat_f = ls_mhnd-laufd.
                cs_auft-statzet_f = '000000'.
              ENDIF.

              cd_auft_upd = 'X'.
            ENDIF.
          ENDIF.
        ENDIF.

        cd_subrc = 0.
      ENDIF.
    ENDDO.



    "Ist der Posten noch offen (BSID) oder ausgeglichen (BSAD)?
    SELECT SINGLE * FROM bsid INTO ls_bsid
      WHERE bukrs EQ cs_kepo-bukrs
        AND vbeln EQ cs_auft-vbeln_f
        AND gjahr EQ cs_auft-beldat_f(4).

    IF sy-subrc EQ 0.
      "Prüfen und fortschreiben, ob beim offenen Posten eine Mahnsperre gesetzt wurde,
      "sofern nichts schon vom Debitor fortgeschrieben wurde.
      IF cs_auft-mansp IS INITIAL AND NOT ls_bsid-mansp IS INITIAL.
        cs_auft-mansp = ls_bsid-mansp.

        cd_auft_upd = 'X'.
        cd_subrc = 0.
      ENDIF.
    ELSE.
      SELECT SINGLE * FROM bsad INTO ls_bsad
      WHERE bukrs EQ cs_kepo-bukrs
        AND vbeln EQ cs_auft-vbeln_f
        AND gjahr EQ cs_auft-beldat_f(4).

      IF sy-subrc EQ 0.
        "Prüfen, ob storniert oder nicht
        SELECT SINGLE * FROM bkpf INTO ls_bkpf
         WHERE bukrs  = ls_bsad-bukrs
           AND belnr  = ls_bsad-belnr
           AND gjahr  = ls_bsad-gjahr.

        IF ls_bkpf-stblg IS INITIAL.
          "Fakturastatus setzen
          IF cs_auft-status_f NE '02'. "ausgeglichen
            cs_auft-status_f = '02'. "ausgeglichen
            "20110906_0907, IDSWE, Ausgleichsdatum aus BSAD beim Fakturastatus verwenden
            cs_auft-statdat_f = ls_bsad-augdt.
            CLEAR cs_auft-statzet_f.
*            cs_auft-statdat_f = sy-datum.
*            cs_auft-statzet_f = sy-uzeit.
            cd_auft_upd = 'X'.
            cd_balanced = 'X'.
          ENDIF.

          "Fallstatus setzen
          IF cs_kepo-fstat NE '03'. "erledigt
            cs_kepo-fstat = '03'. "erledigt
            cd_kepo_upd = 'X'.
          ENDIF.

          cd_subrc = 0.
        ELSE.
          "Fakturastatus setzen
          IF cs_auft-status_f NE '03'. "storniert
            SELECT SINGLE * FROM bkpf INTO ls_bkpf
               WHERE bukrs  = ls_bkpf-bukrs
                 AND belnr  = ls_bkpf-stblg
                 AND gjahr  = ls_bkpf-stjah.

            cs_auft-stonam_f  = ls_bkpf-usnam.
            cs_auft-stodat_f  = ls_bkpf-cpudt.
            cs_auft-stozet_f  = ls_bkpf-cputm.

            cs_auft-status_f = '03'. "storniert
            "20110906_0907, IDSWE, Ausgleichsdatum aus BSAD beim Fakturastatus verwenden
            cs_auft-statdat_f = ls_bsad-augdt.
            CLEAR cs_auft-statzet_f.
*            cs_auft-statdat_f = sy-datum.
*            cs_auft-statzet_f = sy-uzeit.
            cd_auft_upd = 'X'.
          ENDIF.

          "Auftragsstatus setzen
          IF cs_auft-status_a EQ '02'. "fakturiert
            cs_auft-status_a = '01'. "offen
            "20110906_0907, IDSWE, Ausgleichsdatum aus BSAD beim Fakturastatus verwenden
            cs_auft-statdat_a = ls_bsad-augdt.
            CLEAR cs_auft-statzet_a.
*            cs_auft-statdat_a = sy-datum.
*            cs_auft-statzet_a = sy-uzeit.
            cd_auft_upd = 'X'.
          ENDIF.

          "Fallstatus setzen
          IF cs_kepo-fstat NE '02'. "offen
            cs_kepo-fstat = '02'. "offen
            cd_kepo_upd = 'X'.
          ENDIF.

          cd_subrc = 4.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " CHECK_INVOICE


*&---------------------------------------------------------------------*
*&      Form  CHECK_ORDER
*&---------------------------------------------------------------------*
*       Prüft auftragsrelevante Vorgänge und passt die Status dem-
*       entsprechend an.
*
*       Die Strukturen Fall-Kopfdaten und -Auftagsdaten, die Status,
*       der SUBRC (um Verarbeitungen zu überspringen) und die Update-
*       info der upzudateten DB-Tabellen werden wieder zurückgegeben.
*       Muss der Auftrags-Datensatz (infolge neuer Key-Vergabe)
*       vorher gelöscht werden, wird das Flag CD_AUFT_DEL_UPD gesetzt.
*----------------------------------------------------------------------*

FORM check_order USING    ud_ext
                          ud_test
                 CHANGING cs_kepo STRUCTURE zsdtkpkepo
                          cs_auft STRUCTURE zsdtkpauft
                          cd_subrc
                          cd_kepo_upd
                          cd_auft_upd
                          cd_auft_del_upd.


  DATA: ls_vbak TYPE vbak,   "Verkaufsbeleg: Kopfdaten
        ls_vbap TYPE vbap.   "Verkaufsbeleg: Positionsdaten


  IF NOT cs_auft-vbeln_a IS INITIAL.
    "Vertriebsbeleg lesen
    SELECT SINGLE * FROM vbak INTO ls_vbak
      WHERE vbeln EQ cs_auft-vbeln_a.

    IF sy-subrc EQ 0.
      "Wenn Vertriebsbeleg vorhanden, prüfen, ob Positionen ohne Absagegrund bestehen
      SELECT SINGLE * FROM vbap INTO ls_vbap
        WHERE vbeln EQ ls_vbak-vbeln
          AND abgru EQ ''.

      IF sy-subrc EQ 0.
        IF cs_auft-status_a NE '01'. "offen
          cs_auft-status_a = '01'. "offen
          cs_auft-statdat_a = sy-datum.
          cs_auft-statzet_a = sy-uzeit.

          cd_auft_upd = 'X'.
        ENDIF.
      ELSE.
        "Wenn der Vertriebsbeleg keine offenen Positionen mehr enthält, wird der Status auf "storniert" gesetzt.
        "Stornodaten werden auf das aktuelle Tagesdatum gesetzt.

        IF cs_auft-status_a NE '03'. "storniert
          cs_auft-stonam_a = ls_vbak-ernam.
          cs_auft-stodat_a = ls_vbak-aedat.
          cs_auft-stozet_a = '000000'.
          cs_auft-status_a = '03'. "storniert
          cs_auft-statdat_a = sy-datum.
          cs_auft-statzet_a = sy-uzeit.

          cd_auft_upd = 'X'.
        ENDIF.
      ENDIF.

      cd_subrc = 0.
    ELSE.
      "Wenn der Vertriebsbeleg nicht mehr vorhanden ist, wurde er möglicherweise gelöscht.
      "Stornodaten werden auf das aktuelle Tagesdatum gesetzt.

      IF cs_auft-status_a NE '03'. "storniert
        cs_auft-stonam_a = 'DDIC'. "Systemuser
        cs_auft-stodat_a = sy-datum.
        cs_auft-stozet_a = sy-uzeit.
        cs_auft-status_a = '03'. "storniert
        cs_auft-statdat_a = sy-datum.
        cs_auft-statzet_a = sy-uzeit.
        cd_auft_upd = 'X'.
      ENDIF.

      cd_subrc = 0.
    ENDIF.
  ENDIF.
ENDFORM.                    " CHECK_ORDER


*&---------------------------------------------------------------------*
*&      Form  MSG_HANDLING
*&---------------------------------------------------------------------*
*       Meldungstabelle füllen
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM msg_handling TABLES tt_return STRUCTURE bapiret2
                   USING ud_type   TYPE bapi_mtype
                         ud_msgid  TYPE symsgid
                         ud_number TYPE symsgno
                         ud_par1   TYPE symsgv
                         ud_par2   TYPE symsgv
                         ud_par3   TYPE symsgv
                         ud_par4   TYPE symsgv.

  DATA: ls_return TYPE bapiret2.

  CLEAR ls_return.

  CALL FUNCTION 'BALW_BAPIRETURN_GET2'
    EXPORTING
      type             = ud_type
      cl               = ud_msgid
      number           = ud_number
      par1             = ud_par1
      par2             = ud_par2
      par3             = ud_par3
      par4             = ud_par4
*     LOG_NO           = ' '
*     LOG_MSG_NO       = ' '
*     PARAMETER        = ' '
*     ROW              = 0
*     FIELD            = ' '
    IMPORTING
      return           = ls_return.

  "Meldung in Tabelle anfügen
  APPEND ls_return TO tt_return.
ENDFORM.                    " MSG_HANDLING
