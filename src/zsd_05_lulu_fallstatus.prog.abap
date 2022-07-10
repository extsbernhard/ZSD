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
* Kurz-        | Massenmutation des Fallstatus bei Gesuchen, um sie    *
* Beschreibung | für die Rückerstattung zu kennzeichnen                *
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

REPORT zsd_05_lulu_fallstatus MESSAGE-ID zsd_05_lulu.

INCLUDE zsd_05_lulu_fallstatus_d01. " Datendeklaration


SELECTION-SCREEN BEGIN OF BLOCK sel_kehr_auft WITH FRAME TITLE
text-t01.

SELECT-OPTIONS s_objkey FOR zsd_05_kehr_auft-obj_key MATCHCODE OBJECT zsdobj .
SELECT-OPTIONS s_kunnr FOR  zsd_05_kehr_auft-kunnr.
PARAMETERS: P_AMUNT TYPE AMUNT DEFAULT '2000.00'.

PARAMETERS: p_del AS CHECKBOX.
PARAMETERS: p_stat AS CHECKBOX.
*PARAMETERS: p_row TYPE i DEFAULT 500.
SELECTION-SCREEN END OF BLOCK sel_kehr_auft .

SELECTION-SCREEN SKIP.

AT SELECTION-SCREEN OUTPUT.




START-OF-SELECTION.
  CLEAR: s_perst, s_pered.

  w_perst-sign = 'I'.
  w_perst-option = 'BT'.
  w_perst-low = '20070101'.
  w_perst-high = '20101231'.
  APPEND w_perst TO s_perst.

  w_pered-sign = 'I'.
  w_pered-option = 'BT'.
  w_pered-low = '20070101'.
  w_pered-high = '20101231'.
  APPEND w_pered TO s_pered.

* Fallstatus löschen
  IF p_del = abap_true.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
       titlebar                    = 'Löschen des Fallstatus'
*        DIAGNOSE_OBJECT             = ' '
        text_question               = text-001"Der Fallstatus darf nur einmal initial gelöscht werden! Wollen Sie löschen?
        text_button_1               = 'Ja'(002)
*       icon_button_1               = 'ICON_OKAY'
       text_button_2               = 'Nein'(003)
*       icon_button_2               = 'ICON_BACK'
       default_button              = '1'
*        DISPLAY_CANCEL_BUTTON       = 'X'
*        USERDEFINED_F1_HELP         = ' '
*        START_COLUMN                = 25
*        START_ROW                   = 6
*        POPUP_TYPE                  =
*        IV_QUICKINFO_BUTTON_1       = ' '
*        IV_QUICKINFO_BUTTON_2       = ' '
     IMPORTING
        answer                      = lv_answer
*      TABLES
*        PARAMETER                   =
     EXCEPTIONS
       text_not_found              = 1
       OTHERS                      = 2
              .
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.
    CASE lv_answer.
      WHEN '1'.
        PERFORM delete_status.

      WHEN '2'.
      WHEN 'A'.
      WHEN OTHERS.
    ENDCASE.

  ENDIF.

* Hier die Selektion für die Änderung des Fallstatus
  PERFORM daten_selektieren.

END-OF-SELECTION.

* Fallstatus setzen
  PERFORM daten_aufbereiten.

  " Kontrollliste
  PERFORM daten_ausgeben.

  INCLUDE zsd_05_lulu_fallstatus_f01. " Forminclude
