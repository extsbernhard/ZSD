*----------------------------------------------------------------------*
* Report  ZSD_05_LULU_RUECK_A1
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
* Kurz-        | Datensammler für die Rückerstattungen des Projekts    *
* Beschreibung | LuLu der ERB. Die Daten werden aus den Gesuchs(2007-  *
*              | 2010) und den Fällen (2011+2012) gelesen und an die   *
*              | Verbuchung der FI-Belege übergeben.                   *
*              |                                                       *
* Funktionen   | Aufruf FI-Beleg-Erstellung und Update der HD02/Head   *
*              | Felder: FI-Beleg-Nr und Rückerstattungsdatum          *
*              |                                                       *
* Input        | ZSD_05_LULU_HEAD(Gesuche) / ZSD_05_LULU_HD02(Fälle)   *
*              | ZSD_05_LULU_FAKT(Gesuche) / ZSD_05_LULU_FK02(Fälle)   *
*              | ZSD_05_KEHR_AUFZ(Faktura-Positions-Daten) zu FAKT/FK02*
* Output       | ZSD_05_LULU_PRINTLINE                                 *
*              |                                                       *
*--------------+-------------------------------------------------------*

*----------------------Aenderungsdokumentation-------------------------
* Edition  SAP-Rel.  Datum        Bearbeiter
*          Beschreibung
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*

*======================================================================*
 REPORT zsd_05_lulu_rueck_a1 MESSAGE-ID zsd.
*======================================================================*
 INCLUDE zsd_05_lulu_rueck_d1. "Datendeklaration

 INCLUDE zsd_05_lulu_rueck_c1. "Lokale Klasse

 AT SELECTION-SCREEN OUTPUT.

   refresh s_vfgdt.
   s_vfgdt-sign = 'I'.
   s_vfgdt-option = 'NE'.
   s_vfgdt-low = '00000000'.
   s_vfgdt-high = '00000000'.
   APPEND s_vfgdt.
*BREAK exschweitzer.
*ENDIF.
*======================================================================*
 START-OF-SELECTION.
*======================================================================*
   INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
   REFRESH: t_head, t_head_g.

   gs_test-amount = p_rows.
   gs_test-repid = sy-repid.

*   Auswertungstabellen bestimmen, abhängig ob Fall oder Gesuch gewählt
   IF p_fall EQ c_activ.
     CLEAR: s_perst, s_pered.
     w_lulu_head = c_fall_head.
     w_lulu_fakt = c_fall_fakt.

     w_perst-sign = 'I'.
     w_perst-option = 'BT'.
     w_perst-low = '20110101'.
     w_perst-high = '20121231'.
     APPEND w_perst TO s_perst.

     w_pered-sign = 'I'.
     w_pered-option = 'BT'.
     w_pered-low = '20110101'.
     w_pered-high = '20121231'.
     APPEND w_perst TO s_pered.

   ELSEIF p_gesuch EQ c_activ.
     CLEAR: s_perst, s_pered.
     w_lulu_head = c_gesu_head.
     w_lulu_fakt = c_gesu_fakt.
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
     SELECT * FROM (w_lulu_head)
           INTO CORRESPONDING FIELDS OF TABLE t_head_g
           UP TO p_rows ROWS
           WHERE status IN s_status
                AND eigda IN s_eigda
                AND obj_key IN  s_objkey
                AND fallnr IN s_fallnr
                AND eigen_kunnr IN  s_kunnr
                AND rkrdt IN   s_rkrdt
                AND per_beginn IN s_perst
                AND per_ende IN s_pered
                AND vfgdt NE '00000000'
                AND belnr = ''.


   ENDIF.

   SELECT * FROM (w_lulu_head)
    INTO CORRESPONDING FIELDS OF TABLE t_head
    UP TO p_rows ROWS
    WHERE status IN s_status
                AND eigda IN s_eigda
                AND obj_key IN  s_objkey
                AND fallnr IN s_fallnr
                AND eigen_kunnr IN  s_kunnr
                AND rkrdt IN   s_rkrdt
                AND per_beginn IN s_perst
                AND per_ende IN s_pered
                AND vfgdt NE '00000000'
                AND belnr = ''.


   IF sy-subrc EQ 0.
     DESCRIBE TABLE t_head LINES w_lines.
   ENDIF.
   IF w_lines > 0.

     IF p_korr = abap_true.
       PERFORM  korr_bank_data CHANGING t_head.
     ENDIF.



     IF p_back = abap_true.
* Rückerstattung
       IF p_fall EQ c_activ."Fall
* nur Fälle, die noch nicht verarbeitet wurden
         LOOP AT t_head INTO w_head WHERE belnr IS INITIAL .
* Tabellen inititalisieren
           PERFORM initialize_tables.
* Lesen der Fakturen zu dem Fall
           PERFORM get_faktura_f  TABLES t_fk02 t_aufz
                                  USING w_head
                                  CHANGING w_rc.
           IF w_rc = 0.
             PERFORM bdcdata_fill_f TABLES t_fk02 t_aufz CHANGING w_head.
           ELSE.
             w_head-status = 'Z'.
           ENDIF.
           MODIFY  t_head FROM w_head.
           CLEAR: w_rc.
         ENDLOOP." at t_head into w_head
         MODIFY (w_lulu_head) FROM TABLE t_head.
       ELSEIF p_gesuch EQ c_activ."Gesuch


         LOOP AT t_head_g INTO w_head_g WHERE belnr IS INITIAL .
* Tabellen inititalisieren
           PERFORM initialize_tables.
* nur Gesuche, die noch nicht verarbeitet wurden
           PERFORM get_faktura_g TABLES t_fakt t_aufz USING w_head_g
                 CHANGING w_rc.
           IF w_rc = 0.
             PERFORM bdcdata_fill_g TABLES t_fakt t_aufz CHANGING w_head_g.
           ELSE.
             w_head_g-status = 'Z'.
           ENDIF.
           MODIFY t_head_g FROM w_head_g.
           CLEAR: w_rc.
         ENDLOOP.
         MODIFY (w_lulu_head) FROM TABLE t_head_g.
       ENDIF.
     ELSE.
       MESSAGE e002. "Es wurden keine Daten selektiert.

     ENDIF. "w_lines > 0.
   ENDIF.
*======================================================================*
 END-OF-SELECTION.
*======================================================================*
   PERFORM daten_anzeigen.

   INCLUDE zsd_05_lulu_rueck_f1. "Forminclude

*----------------------------------------------------------------------*
