*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_CHG_PROT
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
* Erstelldatum | 15.08.2013          Fertigdat.|                       *
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
* Kurz-        | HISTORISIERUNG der Objektverwaltung                   *
* Beschreibung |                                                       *
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

REPORT zsd_05_lulu_chg_prot MESSAGE-ID zsd_05_lulu.

INCLUDE zsd_05_lulu_chg_prot_d01. " Datendeklaration


SELECTION-SCREEN BEGIN OF BLOCK sel_kehr_auft WITH FRAME TITLE
text-t01.

SELECT-OPTIONS s_objkey FOR zsd_04_chg_prot-obj_key MATCHCODE OBJECT zsdobj .
SELECT-OPTIONS s_tabn FOR  zsd_04_chg_prot-tabname.
SELECT-OPTIONS s_fname FOR zsd_04_chg_prot-fieldname.
SELECT-OPTIONS s_newv FOR zsd_04_chg_prot-newval .
SELECT-OPTIONS: s_oldv FOR zsd_04_chg_prot-oldval .
SELECT-OPTIONS: s_ernam FOR zsd_04_chg_prot-ernam .
SELECT-OPTIONS: s_erdat FOR zsd_04_chg_prot-erdat .
SELECT-OPTIONS: s_erzet FOR zsd_04_chg_prot-erzet .
SELECTION-SCREEN END OF BLOCK sel_kehr_auft .

SELECTION-SCREEN SKIP.

AT SELECTION-SCREEN OUTPUT.
  GET PARAMETER ID 'ZZ_OBJ_KEY' FIELD s_objkey-low.
  s_objkey-sign = 'I'.
  s_objkey-option = 'EQ'.
  APPEND s_objkey.

START-OF-SELECTION.

* Hier die Selektion für die Änderung des Fallstatus
  PERFORM daten_selektieren.

END-OF-SELECTION.



  " Kontrollliste
  PERFORM daten_ausgeben.

  INCLUDE zsd_05_lulu_chg_prot_f01. " Forminclude
