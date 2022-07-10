*----------------------------------------------------------------------*
* Report  ZSD_05_LULU_MIG_OBJEKT_A1
*
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
* Erstelldatum | 17.10.2013          Fertigdat.|                       *
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
* Kurz-        | Migration Objektverwaltung             *
* Beschreibung |   *
*              |     *
*              |        *
*              |                                                       *
* Funktionen   |  Änderung des Eigentümers mit den Daten des    *
*              |  RG-Empfänger                 *
*              |                                                       *
* Input        |                                   *
*              |   *
*              |
* Output       |                                 *
*              |                                                       *
*--------------+-------------------------------------------------------*

*----------------------Aenderungsdokumentation-------------------------
* Edition  SAP-Rel.  Datum        Bearbeiter
*          Beschreibung
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*

*======================================================================*
 REPORT zsd_05_lulu_mig_objekt MESSAGE-ID zsd.
*======================================================================*
 INCLUDE zsd_05_lulu_mig_objekt_d1. "Datendeklaration

 INCLUDE zsd_05_lulu_mig_objekt_c1.
* INCLUDE zsd_05_lulu_rueck_c1. "Lokale Klasse

* AT SELECTION-SCREEN OUTPUT.
*   s_vfgdt-sign = 'I'.
*   s_vfgdt-option = 'NE'.
*   s_vfgdt-low = '00000000'.
*   s_vfgdt-high = '00000000'.
*   APPEND s_vfgdt.

*ENDIF.
*======================================================================*
 START-OF-SELECTION.
*======================================================================*
   gs_test-amount = p_rows.
   gs_test-repid = sy-repid.

   PERFORM initialize_tables.
*   SELECT * FROM zsd_05_hinweis INTO TABLE t_hinweis.

   SELECT * FROM zsd_04_kehricht
    INTO   TABLE t_kehricht
    UP TO p_rows ROWS
    WHERE   obj_key IN  s_objkey
*                AND eigen_kunnr EQ ''
                AND kunnr IN s_kunnr
                AND kunnr NE ''.


   IF sy-subrc EQ 0.
     DESCRIBE TABLE t_kehricht LINES w_lines.
   ENDIF.
   IF w_lines > 0.

     PERFORM  korr_objektverwaltung TABLES t_kehricht.

     IF p_tstkd = abap_false.
       MODIFY zsd_04_kehricht FROM TABLE t_kehricht.
     ENDIF.
   ELSE.
     MESSAGE e002. "Es wurden keine Daten selektiert.

   ENDIF. "w_lines > 0.

*======================================================================*
 END-OF-SELECTION.
*======================================================================*
   PERFORM daten_anzeigen.

   INCLUDE zsd_05_lulu_mig_objekt_f1.
*   INCLUDE zsd_05_lulu_rueck_f1. "Forminclude

*----------------------------------------------------------------------*
