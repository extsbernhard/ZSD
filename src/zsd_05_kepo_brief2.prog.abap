*&---------------------------------------------------------------------*
*& Report  ZSD_05_KEPO_BRIEF2
*&
*& Erstellungsdatum: Januar 2011 IDMZI
*&
*& Druck- und Datenbeschaffungsprogramm zur Verfügung und Mahnung
*&   Hier werden alle Druckrelevanten Daten zusammmengetragen
*&   und der Smartform ZSD_05_KEPO_BRIEF2 übergeben.
*&   in der Smartform werden keine zusätzlichen Daten mehr gelesen.
*&---------------------------------------------------------------------*
REPORT  zsd_05_kepo_brief2.

* Tabellen
TABLES: kna1, nast, vbco3, vbrk, zsdtkpauft, adrct, zsdtkpdocpos,
        zsdtkpdocart, zsdtkpmarb, zsdtkpkepo, zsdtkpmatpos, zsdtkpmat, knvk.
DATA: izsdtkpkepo TYPE zsdtkpkepo.

* Grunddatenbesorgung
DATA: BEGIN OF tkomv OCCURS 50.
        INCLUDE STRUCTURE komv.
DATA: END OF tkomv.
DATA: nast_anzal LIKE nast-anzal.  " Number of outputs (Orig. + Cop.)
DATA: xscreen(1) TYPE c.           " Output on printer or screen
DATA: subrc      TYPE sy-subrc.
DATA: z_wiederh  TYPE i.           " Anzahl wiederholter Fall
DATA: wdatum     TYPE sy-datum.    " Wiederholungsdstatum
DATA: z_dokus(2) TYPE n.           " Anzahl Dokumente

* Smartforms Übergabefelder
DATA: BEGIN OF ukopfdaten.
        INCLUDE STRUCTURE zsdtkpsmartform.
DATA: END OF ukopfdaten.

DATA: BEGIN OF udokumente OCCURS 0.
        INCLUDE STRUCTURE zsdtkpsmartform.
DATA: END OF udokumente.

* Smartforms Parameter
DATA: formname                TYPE tdsfname.
DATA: fbausteinname           TYPE rs38l_fnam.
DATA: control_params          TYPE ssfctrlop.
DATA: sfcompop                TYPE ssfcompop.

* Data zu PDF generierung
DATA: v_e_devtype             TYPE rspoptype.
DATA: st_job_output_info      TYPE ssfcrescl.
DATA: st_document_output_info TYPE ssfcrespd.
DATA: st_job_output_options   TYPE ssfcresop.
DATA: lr_idutil               TYPE REF TO zcl_id_util.

DATA: save_tabix TYPE i.
DATA: plzort TYPE string.
DATA: vbeln TYPE zsdtkpauft-vbeln_f.

PARAMETERS: fallnr   TYPE zsdtkpauft-fallnr DEFAULT '2',
            gjahr    TYPE zsdtkpauft-gjahr DEFAULT'2010'.
PARAMETERS: oeffnen  TYPE c AS CHECKBOX.
PARAMETERS: print    AS CHECKBOX DEFAULT 'X'.
PARAMETERS: dir      TYPE string DEFAULT 'c:\temp'.
PARAMETERS: dateinam TYPE string DEFAULT 'Test'.

*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  PERFORM hole_printdaten.
  IF subrc = 0.
    PERFORM drucken.
  ENDIF.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*&      Form  hole_printdaten
*&---------------------------------------------------------------------*
FORM hole_printdaten.
*
* holen Falldaten Kopfdaten
  SELECT SINGLE * FROM zsdtkpkepo
    WHERE fallnr = fallnr
      AND gjahr  = gjahr.
  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.

* Letzten Auftrag suchen
  SELECT MAX( vbeln_f ) FROM zsdtkpauft INTO vbeln
      WHERE fallnr = zsdtkpkepo-fallnr
        AND gjahr  = zsdtkpkepo-gjahr.
  IF sy-subrc NE 0. EXIT. ENDIF.

* holen falldaten auftrag
  SELECT SINGLE * FROM zsdtkpauft
      WHERE vbeln_f = vbeln.
  IF sy-subrc NE 0. EXIT. ENDIF.

*
* suchen Kunde
  SELECT SINGLE * FROM kna1
    WHERE kunnr EQ zsdtkpkepo-kunnr.
  IF sy-subrc NE 0. EXIT. ENDIF.


* suchen vorname nachname
  CLEAR knvk.
  SELECT SINGLE * FROM knvk
    WHERE kunnr = kna1-kunnr.

*
* holen Faktur
  SELECT SINGLE * FROM vbrk
    WHERE vbeln = zsdtkpauft-vbeln_f.
  IF sy-subrc NE 0. EXIT. ENDIF.


  SELECT SINGLE * FROM zsdtkpkepo INTO izsdtkpkepo
    WHERE fallnr = zsdtkpauft-fallnr
     AND  gjahr  = zsdtkpauft-gjahr.
  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.

*
* füllen übergabestrukturen
  CLEAR ukopfdaten.
  ukopfdaten-adrnr        = kna1-adrnr.
  ukopfdaten-fallnr       = zsdtkpauft-fallnr.
  ukopfdaten-datum        = sy-datum.
  ukopfdaten-funddat      = izsdtkpkepo-fdat.
  ukopfdaten-funzeit      = izsdtkpkepo-fuzei.
  ukopfdaten-kreis        = izsdtkpkepo-kreis.
  ukopfdaten-fart         = izsdtkpkepo-fart.
  ukopfdaten-faknr        = zsdtkpauft-vbeln_f.
  ukopfdaten-fakdat       = zsdtkpauft-beldat_f.
  ukopfdaten-mahn1        = zsdtkpauft-manh1_f.
  ukopfdaten-mahn2        = zsdtkpauft-manh2_f.
  ukopfdaten-mahn3        = zsdtkpauft-manh3_f.
  ukopfdaten-fakbetr      = vbrk-netwr + vbrk-mwsbk.
  ukopfdaten-fakbetr20    = ukopfdaten-fakbetr + 20.

* Dauer Minuten
  ukopfdaten-vbminuten = 0.
  SELECT * FROM zsdtkpmatpos
   WHERE fallnr = zsdtkpauft-fallnr
     AND gjahr  = zsdtkpauft-gjahr.
    SELECT SINGLE * FROM zsdtkpmat
      WHERE matnr = zsdtkpmatpos-matnr
        AND fart  = izsdtkpkepo-fart.
    IF sy-subrc = 0.
      ukopfdaten-vbminuten = ukopfdaten-vbminuten + ( zsdtkpmat-dauer * zsdtkpmatpos-anzahl ).
    ENDIF.
  ENDSELECT.

  CONCATENATE kna1-pstlz kna1-ort01 INTO plzort SEPARATED BY ' '.
  IF kna1-name2 NE ' '.
    CONCATENATE kna1-name1 kna1-name2 kna1-stras plzort INTO ukopfdaten-debiadresse SEPARATED BY ','.
  ELSE.
    CONCATENATE kna1-name1 kna1-stras plzort            INTO ukopfdaten-debiadresse SEPARATED BY ', '.
  ENDIF.

  ukopfdaten-mwst         = vbrk-mwsbk.
  ukopfdaten-betromwst    = vbrk-netwr.
  ukopfdaten-betrmmwst    = ukopfdaten-fakbetr.

  WRITE izsdtkpkepo-fuzei TO ukopfdaten-funzeit USING EDIT MASK  '__:__'.

  IF zsdtkpauft-manh3_f NE 0.
    SELECT SINGLE * FROM zsdtkpmarb WHERE marb = zsdtkpauft-signpers_verfg.
    IF sy-subrc = 0.
      ukopfdaten-sachb1   = zsdtkpmarb-name.
      ukopfdaten-sachb2   = zsdtkpmarb-funktion.
    ELSE.
      ukopfdaten-sachb1   = '?????'.
      ukopfdaten-sachb2   = '?????'.
    ENDIF.
  ELSE.
    SELECT SINGLE * FROM zsdtkpmarb WHERE marb = zsdtkpauft-signpers_rechtg.
    IF sy-subrc = 0.
      ukopfdaten-sachb1   = zsdtkpmarb-name.
      ukopfdaten-sachb2   = zsdtkpmarb-funktion.
    ELSE.
      ukopfdaten-sachb1   = '?????'.
      ukopfdaten-sachb2   = '?????'.
    ENDIF.
  ENDIF.


*  Texte und Titel
*  Fallart
*   01     Blaue Kehrichtsäcke
*   02     Schwarze Kehrichtsäcke
*   03     Papier / Karton
*   04     Wilde Deponie
*  Kreis
*   A      Kreis A
*   B      Kreis B
*   C      Kreis C Innenstadt

* Texte in Smartforms
*   Fallart     Kreis 2.Mahnung  3.Mahnung  Textname
*   2. Mahnung
*   01           egal   X                   ZKEPO_2_TEXT_MGBKU
*   02           egal   X                   ZKEPO_2_TEXT_MGEDA
*   04           egal   X                   ZKEPO_2_TEXT_MGEDA
*   03           egal   X                   ZKEPO_2_TEXT_MGBPU

*   Verfügung
*   01           A                X         ZKEPO_2_TEXT_VGEUA
*   01           B                X         ZKEPO_2_TEXT_VGEUA
*   01           C                X         ZKEPO_2_TEXT_VGEUIA
*   02           egal             X         ZKEPO_2_TEXT_VGEDA
*   03           A                X         ZKEPO_2_TEXT_VGEUP
*   03           B                X         ZKEPO_2_TEXT_VGEUP
*   03           C                X         ZKEPO_2_TEXT_VGEUIP
*

* zu testzwecken
*  ukopfdaten-fart        = '04'.
*  izsdtkpkepo-fart       = '04'.
*  ukopfdaten-kreis       = 'C'.

* Bieftitel

  IF zsdtkpauft-manh3_f NE 0.
    ukopfdaten-brieftitel    = 'Verfügung'.
* Verfügung
    IF izsdtkpkepo-fart         = '01'.          " VGEUA  Kreis C VGEUIA
      ukopfdaten-brieftitel2    = 'Gebühr für die Entsorgung von zur Unzeit bereitgestelltem Abfall'.
    ENDIF.
    IF izsdtkpkepo-fart         = '02'.          " VGEDA
      ukopfdaten-brieftitel2   = 'Gebühr für die Entsorgung von widerechtlich deponiertem Abfall'.
    ENDIF.
    IF izsdtkpkepo-fart         = '03'.          " VGEUP
      ukopfdaten-brieftitel     = 'Gebühr für die Entsorgung von zur Unzeit bereitgestelltem Papier/Karton'.
      IF ukopfdaten-kreis       = 'C'.           " VGEUIP
        ukopfdaten-brieftitel   = 'Gebühr für die Entsorgung von zur Unzeit bereitgestelltem Papier/Karton '.
      ENDIF.
    ENDIF.
    IF izsdtkpkepo-fart         = '04'.          " VGEDA
      ukopfdaten-brieftitel2   = 'Gebühr für die Entsorgung von widerechtlich deponiertem Abfall'.
    ENDIF.
  ELSE.
    IF zsdtkpauft-manh2_f NE 0.
* 2. Mahnung
      IF izsdtkpkepo-fart       = '01'.
        ukopfdaten-brieftitel   = '2. Mahnung/Rechtliches Gehör'.      " MGBKU
        ukopfdaten-brieftitel2  = 'Gebühr für die Bereitstellung eines Kehrichtsacks zur Unzeit'.
      ENDIF.
      IF izsdtkpkepo-fart       =  '02'.
        ukopfdaten-brieftitel   = '2. Mahnung/Rechtliches Gehör'.      " MGEDA
        ukopfdaten-brieftitel2  = 'Gebühr für die Entsorgung von widerechtlich deponiertem Abfall'.
      ENDIF.
      IF izsdtkpkepo-fart       = '03'.
        ukopfdaten-brieftitel   = '2. Mahnung/Rechtliches Gehör'.      " MGBPU
        ukopfdaten-brieftitel2  = 'Gebühr für die Bereitstellung von Papier/Karton zur Unzeit'.
      ENDIF.
      IF izsdtkpkepo-fart       = '04'.
        ukopfdaten-brieftitel   = '2. Mahnung/Rechtliches Gehör'.      " MGEDA
        ukopfdaten-brieftitel2  = 'Gebühr für die Entsorgung von widerechtlich deponiertem Abfall'.
      ENDIF.
    ELSE.
*    weder noch: beenden
      subrc = 4.
      EXIT.
    ENDIF.
  ENDIF.

  " Fundadresse
  CONCATENATE izsdtkpkepo-street izsdtkpkepo-house_num1 INTO ukopfdaten-funadr SEPARATED BY ' '.

  " Anrede
  IF kna1-anred = 'Herr'.
    ukopfdaten-anrede = 'geehrter Herr'.
    ukopfdaten-nname1 = knvk-name1.
*    ukopfdaten-nname1 = kna1-name1.
*    ukopfdaten-nname2 = kna1-name2.
  ENDIF.
  IF kna1-anred = 'Frau'.
    ukopfdaten-anrede = 'geehrte Frau'.
    ukopfdaten-nname1 = knvk-name1.
*    ukopfdaten-nname1 = kna1-name1.
*    ukopfdaten-nname2 = kna1-name2.
  ENDIF.

  IF kna1-anred = 'Familie'.
    ukopfdaten-anrede = 'geehrte Familie'.
    ukopfdaten-nname1 = knvk-name1.
*    ukopfdaten-nname1 = kna1-name1.
*    ukopfdaten-nname2 = kna1-name2.
  ENDIF.

  IF kna1-anred = ' '
  OR kna1-anred = 'Firma'.
    ukopfdaten-anrede = 'geehrte Damen und Herren'.
  ENDIF.

  IF knvk-name1     = ' '
    AND kna1-anred NE ' '
    AND kna1-anred NE 'Firma' .
    ukopfdaten-nname1 = kna1-name1.
  ENDIF.


* Tabelle mit Dokumenten

  REFRESH udokumente.
  SELECT * FROM zsdtkpdocpos
    WHERE fallnr = izsdtkpkepo-fallnr
      AND gjahr  = izsdtkpkepo-gjahr.

    udokumente-dokanz = zsdtkpdocpos-anzahl.
    udokumente-dokart = zsdtkpdocpos-docart.
    udokumente-doktxt = zsdtkpdocpos-bezei.

    IF zsdtkpdocpos-bezei = ' '.
      SELECT bezei FROM zsdtkpdocart INTO zsdtkpdocpos-bezei
        WHERE docart = zsdtkpdocpos-docart
          AND spras  = 'DE'.
        udokumente-doktxt = zsdtkpdocpos-bezei.
      ENDSELECT.
    ENDIF.
    APPEND udokumente.
  ENDSELECT.

*  LOOP AT udokumente.
*    z_dokus = z_dokus + udokumente-dokanz.
*  ENDLOOP.
*  udokumente-anzdok = z_dokus.

  save_tabix = sy-tabix.
  CLEAR ukopfdaten-doktxt.
  LOOP AT udokumente.
    SHIFT udokumente-dokanz LEFT DELETING LEADING '0'.
    IF ( sy-tabix = 1 AND  sy-tabix = save_tabix )
    OR sy-tabix = 1.
      CONCATENATE udokumente-dokanz udokumente-doktxt  INTO ukopfdaten-doktxt SEPARATED BY space.
    ELSE.
      IF sy-tabix = save_tabix.
        CONCATENATE ukopfdaten-doktxt 'und' INTO ukopfdaten-doktxt SEPARATED BY space.
        CONCATENATE ukopfdaten-doktxt  udokumente-dokanz ' ' udokumente-doktxt  INTO ukopfdaten-doktxt SEPARATED BY space.
      ELSE.
        CONCATENATE ukopfdaten-doktxt ', '  INTO ukopfdaten-doktxt.
        CONCATENATE ukopfdaten-doktxt udokumente-dokanz ' ' udokumente-doktxt  INTO ukopfdaten-doktxt SEPARATED BY space.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.                    "hole_printdaten

*&---------------------------------------------------------------------*
*&      Form  holen_fbaustein
*&---------------------------------------------------------------------*
FORM holen_fbaustein.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname               = formname
*   VARIANT                  = ' '
*   DIRECT_CALL              = ' '
   IMPORTING
     fm_name                 = fbausteinname
* EXCEPTIONS
*   NO_FORM                  = 1
*   NO_FUNCTION_MODULE       = 2
*   OTHERS                   = 3
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    "holen_fbaustein

*&---------------------------------------------------------------------*
*&      Form  drucken
*&---------------------------------------------------------------------*
FORM drucken.
  formname = 'ZSD_05_KEPO_BRIEF2'.
  PERFORM holen_fbaustein.

  CREATE OBJECT lr_idutil.

  IF print = 'X'.
*     Dokument in Sap Spool

    sfcompop-tdnewid         = 'X'.
    sfcompop-tddataset       = 'KEPO'.
    sfcompop-tdsuffix1       = 'BRI2'.
    sfcompop-tdtitle         = 'Kehrichtpolizei Mahnung'.
    control_params-no_open   = ' '.
    control_params-no_close  = ' '.

    CALL FUNCTION fbausteinname
      EXPORTING
        ukopfdaten         = ukopfdaten
        control_parameters = control_params
        output_options     = sfcompop
      TABLES
        udokumente         = udokumente
      EXCEPTIONS
        formatting_error   = 1
        internal_error     = 2
        send_error         = 3
        user_canceled      = 4
        OTHERS             = 5.
  ELSE.
*     Dokumend als PDF ablegen
    control_params-no_dialog = 'X'.
    control_params-getotf    = 'X'.
    break weber1.
    sfcompop-tdprinter       = v_e_devtype.
    CALL FUNCTION fbausteinname
      EXPORTING
        ukopfdaten           = ukopfdaten
        control_parameters   = control_params
        output_options       = sfcompop
      IMPORTING
        document_output_info = st_document_output_info
        job_output_info      = st_job_output_info
        job_output_options   = st_job_output_options
      TABLES
        udokumente           = udokumente
      EXCEPTIONS
        formatting_error     = 1
        internal_error       = 2
        send_error           = 3
        user_canceled        = 4
        OTHERS               = 5.
*
    lr_idutil->smartforms2pdf(
      EXPORTING
        otfdata    = st_job_output_info-otfdata
        file_open  = oeffnen
        datei_name = dateinam
        initial_directory = dir
         ).
  ENDIF.

ENDFORM.                    "drucken
