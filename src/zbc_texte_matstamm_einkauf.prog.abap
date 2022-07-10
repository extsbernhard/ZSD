REPORT ZBC_TEXTE_MATSTAMM.
"MESSAGE-ID.
"NO STANDARD PAGE HEADING.
"LINE-SIZE  80
"LINE-COUNT 65(0).
*----------------------------------------------------------------------*
* Firma        : SBZ Schul- und Büromaterialzentrale
* Entwickler   : Mummert Consulting AG / H. Stettler
* Beschreibung
* ------------
*
*
*----------------------Aenderungsdokumentation-------------------------
* Edition  SAP-Rel.  Datum        Bearbeiter
*          Beschreibung
*----------------------------------------------------------------------*
* >000<    4.6C      01.06.2004  Mummert Consulting AG / H. Stettler
*          Programmerstellung
*----------------------------------------------------------------------*
*------ Standard-Includes
INCLUDE zbc_in_top.             "Standard TOP-Include für alle Programme
INCLUDE zbc_in_f01.             "Forms                für alle Programme
*------ BDC-Includes
*------ Eigene Includes
*------- Tabellendefinitionen -(tables)---------------------------------
TABLES: MARA.
*------- C - Counter ---------------------------------------------------
*------- R - Ranges ----------------------------------------------------
*------- S - Schalter (Switch) -----------------------------------------
PARAMETERS: p_vtxt  radiobutton group sor,
            p_gtxt  radiobutton group sor,
            p_loe   as checkbox.
*------- T - interne Tabellen ------------------------------------------
DATA: BEGIN OF t_vtxt OCCURS 0,       "Für Vertriebs- und Materialtexte
        altematnr(010) TYPE c,
        bezeichnung(072) TYPE c,
        bezeichnung2(072) TYPE c,
*        bezeichnung3(040) TYPE c,
      END   OF t_vtxt.

DATA: BEGIN OF t_egtxt OCCURS 0,       "Für Einlesen Grunddatentexte
        altematnr(40) TYPE c,
        bezeichnung(1000) TYPE c,
      END   OF t_egtxt.

DATA: BEGIN OF t_gtxt OCCURS 0,       "Für Grunddatentexte
        altematnr(010) TYPE c,
        bezeichnung1(072) TYPE c,
        bezeichnung2(072) TYPE c,
        bezeichnung3(072) TYPE c,
        bezeichnung4(072) TYPE c,
        bezeichnung5(072) TYPE c,
        bezeichnung6(072) TYPE c,
        bezeichnung7(072) TYPE c,
        bezeichnung8(072) TYPE c,
        bezeichnung9(072) TYPE c,
      END   OF t_gtxt.


DATA: t_lines TYPE tline OCCURS 0 WITH HEADER LINE.
*------- V - Value-Felder ----------------------------------------------
*--------W - Work-Felder (Hilfsfelder)----------------------------------
DATA: w_matnr(18)  TYPE n VALUE '000000000000000000'.
DATA: w_matnr_vertrieb(18) TYPE n VALUE '000000000000000000'.
DATA: w_txtz(2) TYPE n.

*--------W - Work-Strukturen -------------------------------------------
DATA: w_header TYPE thead.
*------- Feld-Symbole --------------------------------------------------
*------- Makros --------------------------------------------------------
*------- P = Parameter, O = Select-Options -----------------------------
PARAMETERS: p_input LIKE rlgrap-filename.
*
*
*-----------------------------------------------------------------------
INITIALIZATION.
*-----------------------------------------------------------------------
* Zeitpunkt: Vor Ausgabe des Selektionsdynpros. (Genau einmal)
*
*
*-----------------------------------------------------------------------
AT SELECTION-SCREEN OUTPUT.
*-----------------------------------------------------------------------
* Zeitpunkt: Vor Ausgabe des Selektionsdynpros. (Bei jedem ENTER)
*
*-----------------------------------------------------------------------
AT SELECTION-SCREEN.
*-----------------------------------------------------------------------
* Zeitpunkt: Nach Eingabe auf dem Selektionsdynpro.
*
*-----------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_input.
*-----------------------------------------------------------------------
  CALL FUNCTION 'KD_GET_FILENAME_ON_F4'
       EXPORTING
            static    = 'X'
       CHANGING
            file_name = p_input.

*-----------------------------------------------------------------------
START-OF-SELECTION.
*-----------------------------------------------------------------------
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  PERFORM a_selection_screen_ausgeben USING v_x v_x v_x.
  PERFORM a_write_protokoll_start.
* Vertriebs- und Materiallangtexte
  IF p_vtxt EQ 'X'.
    REFRESH t_vtxt.
    PERFORM a_file_pc_in_itab_stellen
                TABLES
                   t_vtxt
                USING
                   p_input
                   v_dat
                   v_x
                   v_ausgabe_n
                CHANGING
                   w_subrc
                   w_lines.
* Grunddatentexte
  ELSEIF p_gtxt EQ 'X'.
    REFRESH t_egtxt.
    PERFORM a_file_pc_in_itab_stellen
              TABLES
                 t_egtxt
              USING
                 p_input
                 v_dat
                 v_x
                 v_ausgabe_n
              CHANGING
                 w_subrc
                 w_lines.
  ENDIF.
* Vertriebs- und Materiallangtexte
  IF p_vtxt EQ 'X'.
    LOOP AT t_vtxt.
*   Tabelle für Texte STXH
*   Vertriebstext
*      REFRESH t_lines.
*      SELECT SINGLE * FROM MARA WHERE MATNR EQ t_vtxt-altematnr.
*      if sy-subrc eq 0.
*        MOVE MARA-MATNR TO w_matnr.
*        CONCATENATE w_matnr '166666' INTO w_header-tdname.
*        MOVE: 'MVKE' TO w_header-tdobject,
*              '0001' TO w_header-tdid,
*              'DE'   TO w_header-tdspras.
*        MOVE '/ ' TO t_lines-tdformat.
*        IF t_vtxt-bezeichnung <> ' '.
*          MOVE t_vtxt-bezeichnung TO t_lines-tdline.
*          APPEND t_lines.
*        ENDIF.
*        IF t_vtxt-bezeichnung2 <> ' '.
*          MOVE t_vtxt-bezeichnung2 TO t_lines-tdline.
*          APPEND t_lines.
*        ENDIF.
**    IF t_work-bezeichnung3 <> ' '.
**      MOVE t_vtxt-bezeichnung3 TO t_lines-tdline.
**      APPEND t_lines.
**    ENDIF.
*        CALL FUNCTION 'SAVE_TEXT'
*             EXPORTING
*                  client          = sy-mandt
*                  header          = w_header
*                  savemode_direct = 'X'
*             TABLES
*                  lines           = t_lines
*             EXCEPTIONS
*                  id              = 1
*                  language        = 2
*                  name            = 3
*                  object          = 4
*                  OTHERS          = 5.
*        IF sy-subrc <> 0.
*          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        ENDIF.

*   Tabelle für Texte STXH
*   Einkaufstext
        REFRESH t_lines.
       MOVE t_vtxt-altematnr TO w_matnr.
        MOVE w_matnr TO w_header-tdname.
        MOVE: 'MATERIAL' TO w_header-tdobject,
              'BEST'     TO w_header-tdid,
              'DE'       TO w_header-tdspras.
        MOVE '/ ' TO t_lines-tdformat.
        IF t_vtxt-bezeichnung <> ' '.
          MOVE t_vtxt-bezeichnung TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
*        IF t_vtxt-bezeichnung2 <> ' '.
*          MOVE t_vtxt-bezeichnung2 TO t_lines-tdline.
*          APPEND t_lines.
*        ENDIF.
*    IF t_work-bezeichnung3 <> ' '.
*      MOVE t_vtxt-bezeichnung3 TO t_lines-tdline.
*      APPEND t_lines.
*    ENDIF.
        CALL FUNCTION 'SAVE_TEXT'
             EXPORTING
                  client          = sy-mandt
                  header          = w_header
                  savemode_direct = 'X'
             TABLES
                  lines           = t_lines
             EXCEPTIONS
                  id              = 1
                  language        = 2
                  name            = 3
                  object          = 4
                  OTHERS          = 5.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
*      ELSE.
*        Write:/ t_vtxt-altematnr, 'nicht angelegt'.
*      ENDIF.
    ENDLOOP.
  ENDIF.

* Grunddatentexte in Zwischentabelle Aufbereitung
  IF p_gtxt EQ 'X'.
    REFRESH t_gtxt. CLEAR t_gtxt.
    LOOP AT t_egtxt.
      IF t_egtxt-altematnr(5) CO '0123456789'.
        IF NOT t_gtxt IS INITIAL.
          APPEND t_gtxt.
          CLEAR t_gtxt.
        ENDIF.
        MOVE t_egtxt-altematnr to t_gtxt-altematnr.
        MOVE t_egtxt-bezeichnung to t_gtxt-bezeichnung1.
        w_txtz = 1.
      ELSE.
        ADD 1 to w_txtz.
        case w_txtz.
          when 2.
            MOVE t_egtxt-altematnr to t_gtxt-bezeichnung2.
          when 3.
            MOVE t_egtxt-altematnr to t_gtxt-bezeichnung3.
          when 4.
            MOVE t_egtxt-altematnr to t_gtxt-bezeichnung4.
          when 5.
            MOVE t_egtxt-altematnr to t_gtxt-bezeichnung5.
          when 6.
            MOVE t_egtxt-altematnr to t_gtxt-bezeichnung6.
          when 7.
            MOVE t_egtxt-altematnr to t_gtxt-bezeichnung7.
          when 8.
            MOVE t_egtxt-altematnr to t_gtxt-bezeichnung8.
          when 9.
            MOVE t_egtxt-altematnr to t_gtxt-bezeichnung9.
        endcase.
      ENDIF.
    ENDLOOP.
    IF NOT t_gtxt IS INITIAL.
      APPEND t_gtxt.
    ENDIF.
  ENDIF.

* Grunddatentexte Löschen
  IF p_gtxt EQ 'X' and p_loe EQ 'X'.
    LOOP AT t_gtxt.
      REFRESH t_lines.
      SELECT SINGLE * FROM MARA WHERE BISMT EQ t_gtxt-altematnr.
      if sy-subrc eq 0.
        MOVE MARA-MATNR TO w_matnr.
        MOVE w_matnr TO w_header-tdname.
        MOVE: 'MATERIAL' TO w_header-tdobject,
              'GRUN'     TO w_header-tdid,
              'DE'       TO w_header-tdspras.

        CALL FUNCTION 'DELETE_TEXT'
          EXPORTING
           CLIENT                = SY-MANDT
            ID                    = w_header-tdid
            LANGUAGE              = w_header-tdspras
            NAME                  = w_header-tdname
            OBJECT                = w_header-tdobject
           SAVEMODE_DIRECT       = 'X'
*   TEXTMEMORY_ONLY       = ' '
*   LOCAL_CAT             = ' '
* EXCEPTIONS
*   NOT_FOUND             = 1
*   OTHERS                = 2
                  .
*        IF SY-SUBRC <> 0.
** MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
**         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

* Grunddatentexte anlegen
  IF p_gtxt EQ 'X'.
    LOOP AT t_gtxt.
*   Grunddatentexte
      REFRESH t_lines.
      SELECT SINGLE * FROM MARA WHERE BISMT EQ t_gtxt-altematnr.
      if sy-subrc eq 0.
        MOVE MARA-MATNR TO w_matnr.
        MOVE w_matnr TO w_header-tdname.
        MOVE: 'MATERIAL' TO w_header-tdobject,
              'GRUN'     TO w_header-tdid,
              'DE'       TO w_header-tdspras.
        MOVE '/ ' TO t_lines-tdformat.
        IF t_gtxt-bezeichnung1 <> ' '.
          MOVE t_gtxt-bezeichnung1 TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
        IF t_gtxt-bezeichnung2 <> ' '.
          MOVE t_gtxt-bezeichnung2 TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
        IF t_gtxt-bezeichnung3 <> ' '.
          MOVE t_gtxt-bezeichnung3 TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
        IF t_gtxt-bezeichnung4 <> ' '.
          MOVE t_gtxt-bezeichnung4 TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
        IF t_gtxt-bezeichnung5 <> ' '.
          MOVE t_gtxt-bezeichnung5 TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
        IF t_gtxt-bezeichnung6 <> ' '.
          MOVE t_gtxt-bezeichnung6 TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
        IF t_gtxt-bezeichnung7 <> ' '.
          MOVE t_gtxt-bezeichnung7 TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
        IF t_gtxt-bezeichnung8 <> ' '.
          MOVE t_gtxt-bezeichnung8 TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
        IF t_gtxt-bezeichnung9 <> ' '.
          MOVE t_gtxt-bezeichnung9 TO t_lines-tdline.
          APPEND t_lines.
        ENDIF.
        CALL FUNCTION 'SAVE_TEXT'
             EXPORTING
                  client          = sy-mandt
                  header          = w_header
                  savemode_direct = 'X'
             TABLES
                  lines           = t_lines
             EXCEPTIONS
                  id              = 1
                  language        = 2
                  name            = 3
                  object          = 4
                  OTHERS          = 5.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ELSE.
        Write:/ t_vtxt-altematnr, 'nicht angelegt'.
      ENDIF.
    ENDLOOP.
  ENDIF.

*
*-----------------------------------------------------------------------
END-OF-SELECTION.
  PERFORM a_ausgeben_t_msg.
  PERFORM a_write_protokoll_end.
*
*-----------------------------------------------------------------------
AT LINE-SELECTION.
*-----------------------------------------------------------------------
* Dieser Zeitpunkt wird nach einer Zeilenauswahl prozessiert.
* (Doppelklick oder F2)
*
*-----------------------------------------------------------------------
AT USER-COMMAND.
*-----------------------------------------------------------------------
* Dieser Zeitpunkt wird nach der Eingabe in der OK-Zeile prozessiert.
* Sämtlich Funktionen die im GUI-Status definiert wurden, werden
* hier verarbeitet.
  CASE sy-ucomm.
    WHEN '    '.
  ENDCASE.
*
*-----------------------------------------------------------------------
TOP-OF-PAGE.
*-----------------------------------------------------------------------
* Dieser Zeitpunkt wird bei einer neuen Seite prozessiert wenn
* 'NO STANDARD PAGE HEADING' definiert wurde.
*
*-----------------------------------------------------------------------
END-OF-PAGE.
*-----------------------------------------------------------------------
* Dieser Zeitpunkt wird nach der Ausgabe der letzten Zeile einer Seite
* prozessiert.
*
