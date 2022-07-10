*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_ANALYSE
*&
*----------------------------------------------------------------------*
*                                                                      *
*            P R O G R A M M D O K U M E N T A T I O N                 *
*                                                                      *
*----------------------------------------------------------------------*
*               W E R  +  W A N N                                      *
*--------------+-------------------------------+-----------------------*
* Entwickler   | Dominique Schweitzer Firma    | Alsinia GmbH          *
* Tel.Nr.      |                     Natel     | 079 698 00 26         *
* E-Mail       |                                                       *
* Erstelldatum | 27.06.2013          Fertigdat.|                       *
*--------------+-------------------------------+-----------------------*
*               F Ü R   W E N                                          *
*--------------+-------------------------------+-----------------------*
* Amt          | Stadt Bern                    |                       *
* Auftraggeber | Beat Oesch             Tel.Nr.|                       *
* E-Mail       | Beat.Oesch2@bern.ch                                   *
* Proj.Leiter  | Daniel Liener         Tel.Nr.| 031                    *
* E-Mail       | Beat.Oesch2@bern.ch                                   *
*--------------+-------------------------------+-----------------------*
*               W O                                                    *
*--------------+-------------------------------+-----------------------*
* PCM-Nr.      |                     Change-Nr.|                       *
* Proj.Name    | LULU Stadt Bern ERB Proj.Nr.  |
*
*--------------+-------------------------------+-----------------------*
*               W A S                                                  *
*--------------+-------------------------------------------------------*
* Kurz-        | Erstellen einer Berichts,  der zur Analyse der Daten  *
* Beschreibung | Periode 2011 - 2012 dient, um bei den stornierten     *
*              | Kehricht-Verfügungen zu prüfen, ob zu den Objekten    *
*              | im der selben Periode zu einem späteren Zeitpunkt     *
*              | erneut keine neue Faktura erstellt wurde, die den     *
*              | Status 'B' bezahlt hat. Wenn ja, müssen diese in      *
*              | der Verfügung 2013 zur Periode 2011-2012 erneut       *
*              | defintiv fakturiert werden. Separater Prozess.        *
*              | Zusätzlich wird einer neuer Objektkey in die Tabelle  *
*              | ZSD_05_KEHR_AUFT geschrieben, der sich aus den 3      *
*              | KEY-Feldern Stadtteil, Parzellennummer und Objekt     *
*              | zusammensetzt.                                        *
* Funktionen   |                                                       *
*              |                                                       *
* Input        |                                                       *
*              |                                                       *
* Output       |                                                       *
*              |                                                       *
*--------------+-------------------------------------------------------*

*----------------------Aenderungsdokumentation-------------------------
* Edition  SAP-Rel.  Datum        Bearbeiter
*          Beschreibung
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*

REPORT zsd_05_lulu_objkey_build MESSAGE-ID zsd_05_lulu.

INCLUDE zsd_05_lulu_objkey_build_d01.
*INCLUDE zsd_05_lulu_analyse_d01. " Datendeklaration


SELECTION-SCREEN BEGIN OF BLOCK sel_kehr_auft WITH FRAME TITLE
text-t01.

SELECT-OPTIONS s_objkey FOR zsd_05_kehr_auft-obj_key MATCHCODE OBJECT zsdobj .
SELECT-OPTIONS: s_fallnr FOR zsd_05_lulu_head-fallnr,
                s_perbg FOR zsd_05_lulu_head-per_beginn,
                s_pered FOR zsd_05_lulu_head-per_ende.

SELECTION-SCREEN BEGIN OF BLOCK sel_tab WITH FRAME TITLE text-obj.

PARAMETERS: p_head AS CHECKBOX,
            p_hd02 AS CHECKBOX,
            p_objekt AS CHECKBOX,
            p_kehr AS CHECKBOX,
            p_auft AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK sel_tab .


PARAMETERS: p_row TYPE i DEFAULT 500.
SELECTION-SCREEN END OF BLOCK sel_kehr_auft .

SELECTION-SCREEN SKIP.

AT SELECTION-SCREEN OUTPUT.
  REFRESH: s_perbg, s_pered .
  s_perbg-sign = 'I'.
  s_perbg-option = 'BT'.
  s_perbg-low = '20110101'.
  s_perbg-high = '20121231'.
  APPEND s_perbg.

  s_pered-sign = 'I'.
  s_pered-option = 'BT'.
  s_pered-low = '20110101'.
  s_pered-high = '20121231'.
  APPEND s_pered.

START-OF-SELECTION.
    IF p_objekt = 'X'.
      SELECT * FROM zsd_05_objekt INTO TABLE lt_objekt
         .
      IF sy-dbcnt GT 0.
        SORT lt_objekt.
        LOOP AT lt_objekt INTO ls_objekt.
          CONCATENATE ls_objekt-stadtteil
          ls_objekt-parzelle
          ls_objekt-objekt INTO
          ls_objekt-obj_key.
          MODIFY lt_objekt FROM ls_objekt.
        ENDLOOP.
        UPDATE zsd_05_objekt FROM   TABLE lt_objekt.
      ENDIF.
    ENDIF.

    IF p_auft = 'X'.
      SELECT * FROM zsd_05_kehr_auft INTO TABLE lt_kehr_auft .
      IF sy-subrc = 0.
        SORT lt_kehr_auft.
        LOOP AT lt_kehr_auft INTO ls_kehr_auft.
          CONCATENATE ls_kehr_auft-stadtteil
          ls_kehr_auft-parzelle
          ls_kehr_auft-objekt INTO
          ls_kehr_auft-obj_key.
          MODIFY lt_kehr_auft FROM ls_kehr_auft.
        ENDLOOP.
        UPDATE zsd_05_kehr_auft FROM   TABLE lt_kehr_auft.
      ENDIF.
    ENDIF.
    IF  p_head = 'X'.
      SELECT * FROM zsd_05_lulu_head INTO TABLE lt_lulu_head  where fallnr in s_fallnr .
      IF sy-subrc = 0.
        SORT lt_lulu_head.
        LOOP AT lt_lulu_head  INTO ls_lulu_head.
          CONCATENATE  ls_lulu_head-stadtteil
           ls_lulu_head-parzelle
           ls_lulu_head-objekt INTO
           ls_lulu_head-obj_key.
          MODIFY lt_lulu_head FROM  ls_lulu_head.
        ENDLOOP.
        UPDATE zsd_05_lulu_head FROM   TABLE lt_lulu_head.
      ENDIF.
    ENDIF.
    IF p_hd02 = 'X'.
      SELECT * FROM zsd_05_lulu_hd02 INTO TABLE lt_lulu_hd02 where fallnr in s_fallnr  .
      IF sy-subrc = 0.
        SORT lt_lulu_hd02.
        LOOP AT lt_lulu_hd02  INTO ls_lulu_hd02.
          CONCATENATE  ls_lulu_hd02-stadtteil
           ls_lulu_hd02-parzelle
           ls_lulu_hd02-objekt INTO
           ls_lulu_hd02-obj_key.
          MODIFY lt_lulu_hd02 FROM  ls_lulu_hd02.
        ENDLOOP.
        UPDATE zsd_05_lulu_hd02 FROM   TABLE lt_lulu_hd02.
      ENDIF.
    ENDIF.

  IF p_kehr = 'X'.
*ZSD_04_Kehricht
    SELECT * FROM zsd_04_kehricht  INTO TABLE lt_zsd_04_kehricht .
    IF sy-subrc = 0.
      SORT lt_zsd_04_kehricht.
      LOOP AT lt_zsd_04_kehricht INTO ls_zsd_04_kehricht.
        CONCATENATE ls_zsd_04_kehricht-stadtteil
        ls_zsd_04_kehricht-parzelle
        ls_zsd_04_kehricht-objekt INTO
        ls_zsd_04_kehricht-obj_key.
        MODIFY lt_zsd_04_kehricht FROM ls_zsd_04_kehricht.
      ENDLOOP.
      UPDATE zsd_04_kehricht FROM   TABLE lt_zsd_04_kehricht.
    ENDIF.
  ENDIF.


END-OF-SELECTION.

  PERFORM daten_ausgeben.




  INCLUDE zsd_05_lulu_objkey_build_f01.
*  INCLUDE zsd_05_lulu_analyse_f01. " Forminclude
