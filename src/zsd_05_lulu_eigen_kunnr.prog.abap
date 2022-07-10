*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_FALLSTATUS
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
* Kurz-        | Massenmutation des Debitoren Objektverwaltung    *
* Beschreibung | Fakturatabelle            *
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

REPORT zsd_05_lulu_eigen_kunnr MESSAGE-ID zsd_05_lulu.

INCLUDE ZSD_05_LULU_EIGEN_KUNNR_D01.
*INCLUDE zsd_05_lulu_fallstatus_d01. " Datendeklaration


SELECTION-SCREEN BEGIN OF BLOCK sel_kehr_auft WITH FRAME TITLE
text-t01.

SELECT-OPTIONS s_objkey FOR zsd_05_kehr_auft-obj_key MATCHCODE OBJECT zsdobj .
SELECT-OPTIONS s_kunnr FOR  zsd_05_kehr_auft-kunnr.
SELECT-OPTIONS s_verd for zsd_05_kehr_auft-VERR_DATUM.
 SELECT-OPTIONS s_VERDs for zsd_05_kehr_auft-VERR_DATUM_SCHL.
 select-options: s_faknr for zsd_05_kehr_auft-faknr.
*PARAMETERS: p_row TYPE i DEFAULT 500.
SELECTION-SCREEN END OF BLOCK sel_kehr_auft .

SELECTION-SCREEN SKIP.

AT SELECTION-SCREEN OUTPUT.
  refresh: s_verds, s_verd.

  s_verd-sign = 'I'.
  s_verd-option = 'BT'.
  s_verd-low = '20130101'.
  s_verd-high = '20131231'.
  APPEND s_verd TO s_verd.

  s_verds-sign = 'I'.
  s_verds-option = 'BT'.
  s_verds-low = '20130101'.
  s_verds-high = '20131231'.
  APPEND s_verds TO s_verds.

START-OF-SELECTION.

* Hier die Selektion für die Änderung des Fallstatus
  PERFORM daten_selektieren.

END-OF-SELECTION.

* Fallstatus setzen
  PERFORM daten_aufbereiten.

  " Kontrollliste
  PERFORM daten_ausgeben.

INCLUDE ZSD_05_LULU_EIGEN_KUNNR_F01.
*  INCLUDE zsd_05_lulu_fallstatus_f01. " Forminclude
