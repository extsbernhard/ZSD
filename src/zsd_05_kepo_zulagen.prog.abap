*---------------------------------------------------------------------*
* Report  ZSD_05_KEPO_ZULAGEN
*
*---------------------------------------------------------------------*
* Aufbereitung der Zulagen für die Kehrichtpolizisten
*
*---------------------------------------------------------------------*

REPORT  zsd_05_kepo_zulagen.

*_____Konstanten_____
CONSTANTS: c_field_separator TYPE c VALUE ';',
           c_field_brackets  TYPE c VALUE '"'.




*_____Datendefinitionen_____

TABLES: zsdtkpmarb.

DATA: lt_kepo TYPE TABLE OF zsdtkpkepo,
      ls_kepo TYPE          zsdtkpkepo,
      lt_marb TYPE TABLE OF zsdtkpmarb,
      ls_marb TYPE          zsdtkpmarb.



DATA: BEGIN OF ls_zulagen_data,
        name   TYPE name_text,
        jahr   TYPE gjahr,
        monat  TYPE month,
        anzahl TYPE i,
        dauer  TYPE i,
      END OF ls_zulagen_data.

DATA: lt_zulagen_data LIKE STANDARD TABLE OF ls_zulagen_data WITH KEY name jahr monat.


DATA: ld_gjahr TYPE gjahr.


DATA: lo_send_request TYPE REF TO cl_bcs,
      lt_msg_body     TYPE bcsy_text,
      lo_document     TYPE REF TO cl_document_bcs,
      lo_recipient    TYPE REF TO cl_cam_address_bcs,
      ld_csv_line     TYPE string,
      ld_csv_data     TYPE string,
      lt_csv_data     TYPE soli_tab,
      ld_csv_falllist TYPE string,
      ld_fall         TYPE string,
      ld_hours        TYPE numc3,
      ld_minutes      TYPE num2,
      ld_dauer        TYPE string,
      ld_dauer_csv    TYPE text6,
      ld_anzahl_csv   TYPE string,

      ld_result       TYPE os_boolean,
      ld_receiv       TYPE ad_smtpadr,
      ld_subject      TYPE so_obj_des,
      ld_time         TYPE text5,
      ld_datum        TYPE text10,
      lx_bcs          TYPE REF TO cx_bcs,
      lx_document_bcs TYPE REF TO cx_document_bcs VALUE IS INITIAL.




*_____Selektionsbild_____

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE text-bl1.
SELECT-OPTIONS: so_marb  FOR ls_kepo-marbkp.
SELECT-OPTIONS: so_gjahr FOR ld_gjahr.
SELECTION-SCREEN END OF BLOCK bl1.

SELECTION-SCREEN BEGIN OF BLOCK bl2 WITH FRAME TITLE text-bl2.
PARAMETERS:     p_bdauer TYPE num2 OBLIGATORY. "Basisdauer in Minuten
SELECT-OPTIONS: so_rec FOR ld_receiv NO INTERVALS OBLIGATORY no-EXTENSION.
SELECTION-SCREEN SKIP.
PARAMETERS: p_flist TYPE flag DEFAULT 'X'. "Fallliste als Info anhängen
PARAMETERS: p_test TYPE flag DEFAULT 'X'. "Testlauf (Datum wird nicht in DB geschrieben)
SELECTION-SCREEN END OF BLOCK bl2.



*_____Auswertung_____

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  "Datum und Uhrzeit formatieren
  WRITE sy-uzeit TO ld_time USING EDIT MASK '__:__'.
  WRITE sy-datum TO ld_datum DD/MM/YYYY.



  "Falldaten lesen
  SELECT * FROM zsdtkpkepo INTO TABLE lt_kepo
    WHERE gjahr IN so_gjahr
      AND marbkp IN so_marb
      AND zulagen EQ '00000000'.



  "Mitarbeiter lesen
  SELECT * FROM zsdtkpmarb INTO TABLE lt_marb.


  "Zulagen-Daten aufbereiten
  LOOP AT lt_kepo INTO ls_kepo.
    CLEAR: ls_zulagen_data, ls_marb.



    "Liste betroffener Fälle erstellen
    IF p_flist EQ abap_true.
      IF sy-tabix EQ 1.
        CONCATENATE cl_abap_char_utilities=>cr_lf cl_abap_char_utilities=>cr_lf cl_abap_char_utilities=>cr_lf cl_abap_char_utilities=>cr_lf 'Betroffene Fälle;'
          INTO ld_csv_falllist.
      ENDIF.

      CONCATENATE 'Fallnummer:' ls_kepo-fallnr 'Geschäftsjahr:' ls_kepo-gjahr
        INTO ld_fall SEPARATED BY space.

      SHIFT ld_fall LEFT DELETING LEADING '0'.

      CONCATENATE ld_csv_falllist cl_abap_char_utilities=>cr_lf ld_fall c_field_separator
        INTO ld_csv_falllist.
    ENDIF.


    "Zulagen-Datum für Update setzen, wenn kein Testlauf
    IF p_test EQ abap_false.
      ls_kepo-zulagen = sy-datum.
      MODIFY lt_kepo FROM ls_kepo.
    ENDIF.



    "Name des Mitarbeiters lesen
    READ TABLE lt_marb INTO ls_marb WITH KEY marb = ls_kepo-marbkp.
    ls_zulagen_data-name = ls_marb-name.
    SHIFT ls_zulagen_data-name LEFT DELETING LEADING space.

    ls_zulagen_data-jahr  = ls_kepo-gjahr.
    ls_zulagen_data-monat = ls_kepo-fdat+4(2).
    ls_zulagen_data-anzahl = ls_kepo-fobjanz.
    ls_zulagen_data-dauer = ls_kepo-fobjanz * p_bdauer.



    "In Zulagen-Tabelle verdichten
    COLLECT ls_zulagen_data INTO lt_zulagen_data.

  ENDLOOP.


  "Sortierung nach Name, Jahr und Monat
  SORT lt_zulagen_data BY name jahr monat.



  "Text-Datensatz für CSV erzeugen
  CONCATENATE 'Mitarbeiter' 'Jahr' 'Monat' 'Anz. Fundmaterial' 'Dauer'
    INTO ld_csv_line SEPARATED BY c_field_separator.

  "Text-Zeile für CSV erweitern
  CONCATENATE ld_csv_line c_field_separator
    INTO ld_csv_data.



  "Tabelleninhalt für CSV erzeugen
  LOOP AT lt_zulagen_data INTO ls_zulagen_data.
    CLEAR: ld_dauer, ld_hours, ld_minutes, ld_dauer_csv, ld_anzahl_csv, ld_csv_line.

    "Minuten (Integer) in Zeit umwandeln und im Format fortschreiben (mehr als 24 Stunden möglich)
    ld_hours = TRUNC( ls_zulagen_data-dauer / 60 ).
    ld_minutes = ls_zulagen_data-dauer - ( ld_hours * 60 ).
    CONCATENATE ld_hours ld_minutes INTO ld_dauer.
    WRITE ld_dauer TO ld_dauer_csv USING EDIT MASK '___:__'.

    "Anzahl in String umwandeln
    ld_anzahl_csv = ls_zulagen_data-anzahl.

    "Text-Zeile für CSV erweitern
    CONCATENATE ld_csv_data cl_abap_char_utilities=>cr_lf ld_csv_line
      INTO ld_csv_data.

    "Text-Datensatz für CSV erzeugen
    CONCATENATE ls_zulagen_data-name ls_zulagen_data-jahr ls_zulagen_data-monat ld_anzahl_csv ld_dauer_csv
      INTO ld_csv_line SEPARATED BY c_field_separator.

    "Text-Zeile für CSV erweitern
    CONCATENATE ld_csv_data ld_csv_line c_field_separator
      INTO ld_csv_data.

  ENDLOOP.



  "Betroffene Fälle anhängen
  IF p_flist EQ abap_true.
    CONCATENATE ld_csv_data ld_csv_falllist INTO ld_csv_data.
  ENDIF.



  "Dateninhalt (String) in Soli-Tabelle umwandeln
  lt_csv_data = cl_document_bcs=>string_to_soli( ld_csv_data ).



  "Bodytext erfassen
  APPEND 'Guten Tag' TO lt_msg_body.
  APPEND INITIAL LINE TO lt_msg_body.
  APPEND 'Dies ist eine automatisch generierte E-Mail. Bitte beantworten Sie diese E-Mail nicht.' TO lt_msg_body.
  APPEND INITIAL LINE TO lt_msg_body.
  APPEND 'Als Anlage wurde die aktuelle Entschädigungsliste (Zulagen Kehrichtpolizei) angehängt.' TO lt_msg_body.
  APPEND INITIAL LINE TO lt_msg_body.
  APPEND 'Freundliche Grüsse' TO lt_msg_body.
  APPEND 'Entsorgung + Recycling Stadt Bern' TO lt_msg_body.



  "Mail-Objekt instanzieren
  lo_send_request = cl_bcs=>create_persistent( ).



  "Dokument-Objekt instanzieren und füllen
  CLEAR: ld_subject.
  CONCATENATE 'Zulagen Kehrichtpolizei per' ld_datum ld_time
    INTO ld_subject SEPARATED BY space.

  lo_document = cl_document_bcs=>create_document(
    i_type = 'RAW'
    i_text = lt_msg_body
    i_subject = ld_subject ).

  lo_send_request->set_document( lo_document ).



  "CSV-Datei anhängen
  CLEAR: ld_subject.
  CONCATENATE sy-datum '_' sy-uzeit '_Zulagen_Kehrichtpolizei.csv'
    INTO ld_subject.

  TRY.
      lo_document->add_attachment(
          i_attachment_type    = 'CSV'
          i_attachment_subject = ld_subject
          i_att_content_text   = lt_csv_data ).

    CATCH cx_document_bcs INTO lx_document_bcs.
  ENDTRY.



  "E-Mailempfänger hinzufügen
  LOOP AT so_rec.
    "Objekt instanzieren und E-Mailadresse füllen
    lo_recipient = cl_cam_address_bcs=>create_internet_address( so_rec-low ).

    "Empfänger hinzufügen
    lo_send_request->add_recipient(
      EXPORTING
        i_recipient = lo_recipient
        i_express = 'X' ).
  ENDLOOP.






  "Keine Statusmeldung erzeugen
  lo_send_request->set_status_attributes(
    EXPORTING
       i_requested_status = 'N' ).



  TRY.
      "E-Mail versenden
      lo_send_request->send(
        EXPORTING
          i_with_error_screen = 'X'
        RECEIVING
          result = ld_result ).

      COMMIT WORK AND WAIT.

    CATCH cx_bcs INTO lx_bcs.
  ENDTRY.

  IF ld_result EQ abap_true.
    SUBMIT rsconn01 WITH mode = 'INT' AND RETURN.

    IF p_test EQ abap_false.
      UPDATE zsdtkpkepo FROM TABLE lt_kepo.
    ENDIF.

  ENDIF.
