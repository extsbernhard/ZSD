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

REPORT zsd_05_lulu_analyse MESSAGE-ID zsd_05_lulu.

INCLUDE zsd_05_lulu_analyse_d01. " Datendeklaration


SELECTION-SCREEN BEGIN OF BLOCK sel_kehr_auft WITH FRAME TITLE
text-t01.

SELECT-OPTIONS s_objkey FOR zsd_05_kehr_auft-obj_key MATCHCODE OBJECT zsdobj .
SELECT-OPTIONS s_vbeln FOR zsd_05_kehr_auft-vbeln MATCHCODE OBJECT zsdvbeln.

SELECT-OPTIONS: s_vrdata FOR zsd_05_kehr_auft-verr_datum,
                s_vrdate FOR zsd_05_kehr_auft-verr_datum_schl.


PARAMETERS: p_kennz TYPE zsd_05_kehr_auft-kennz DEFAULT 'S'.
PARAMETERS: p_obj AS CHECKBOX.

PARAMETERS: p_row TYPE i DEFAULT 500.
SELECTION-SCREEN END OF BLOCK sel_kehr_auft .

SELECTION-SCREEN SKIP.

AT SELECTION-SCREEN OUTPUT.
  REFRESH: s_vrdata, s_vrdate .
  s_vrdata-sign = 'I'.
  s_vrdata-option = 'BT'.
  s_vrdata-low = '20110101'.
  s_vrdata-high = '20121231'.
  APPEND s_vrdata.

  s_vrdate-sign = 'I'.
  s_vrdate-option = 'BT'.
  s_vrdate-low = '20110101'.
  s_vrdate-high = '20121231'.
  APPEND s_vrdate.

AT SELECTION-SCREEN ON p_obj.
  IF p_obj  IS NOT  INITIAL.
    MESSAGE  w009. "Die Bildung des Schlüssels kann einige Minuten dauern.


  ENDIF.

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  IF p_obj  IS NOT  INITIAL.

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

        SELECT * FROM zsd_05_lulu_head INTO TABLE lt_lulu_head  .
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

        SELECT * FROM zsd_05_lulu_hd02 INTO TABLE lt_lulu_hd02 .
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
*ZSD_04_Kehricht
    SELECT * FROM ZSD_04_Kehricht  INTO TABLE lt_ZSD_04_Kehricht .
    IF sy-subrc = 0.
      SORT lt_ZSD_04_Kehricht.
      LOOP AT lt_ZSD_04_Kehricht INTO ls_ZSD_04_Kehricht.
        CONCATENATE ls_ZSD_04_Kehricht-stadtteil
        ls_ZSD_04_Kehricht-parzelle
        ls_ZSD_04_Kehricht-objekt INTO
        ls_ZSD_04_Kehricht-obj_key.
        MODIFY lt_ZSD_04_Kehricht FROM ls_ZSD_04_Kehricht.
      ENDLOOP.
      UPDATE ZSD_04_Kehricht FROM   TABLE lt_ZSD_04_Kehricht.
    ENDIF.

* Hier die Selektion für die eigentliche Analyse
  PERFORM daten_selektieren.


END-OF-SELECTION.

  PERFORM daten_ausgeben.




  INCLUDE zsd_05_lulu_analyse_f01. " Forminclude
