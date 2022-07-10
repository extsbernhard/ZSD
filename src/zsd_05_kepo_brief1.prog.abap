*&---------------------------------------------------------------------*
*& Report  ZSD_05_KEPO_BRIEF1
*&
*& Erstellungsdatum: Januar 2011 IDMZI
*&
*& Druck- und Datenbeschaffungsprogramm zu Nachrichtenart
*&   Z877 ERB Gebührenbrief.
*&   Hier werden alle Druckrelevanten Daten zusammmengetragen
*&   und der Smartform ZSD_05_KEPO_BRIEF1 übergeben.
*&   in der Smartform werden keine zusätzlichen Daten mehr gelesen.
*&---------------------------------------------------------------------*
REPORT  zsd_05_kepo_brief1.

* Tabellen
TABLES: kna1,
        nast,
        vbco3,
        vbrk,
        knvk,
        zsdtkpauft,
        adrct,
        zsdtkpdocpos,
        zsdtkpdocart,
        zsdtkpmarb.
DATA: izsdtkpkepo TYPE zsdtkpkepo,
      ls_vbpa     TYPE vbpa.

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
DATA: formname       TYPE tdsfname.
DATA: formnamesteb   TYPE tdsfname.
DATA: fbausteinname  TYPE rs38l_fnam.
DATA: control_params TYPE ssfctrlop.
DATA: sfcompop       TYPE ssfcompop.

DATA: save_tabix TYPE i.

*&---------------------------------------------------------------------*
*&      Form  entry
*&---------------------------------------------------------------------*
FORM entry USING return_code us_screen.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  DATA: lf_retcode TYPE sy-subrc.
  CLEAR subrc.
  xscreen = us_screen.
  PERFORM processing.
  return_code = subrc.

ENDFORM.                    "entry

*&---------------------------------------------------------------------*
*&      Form  processing
*&---------------------------------------------------------------------*
FORM processing.

* Holen betroffene Daten (Fakturanummet Kundennummer)
  PERFORM hole_grunddaten.

  IF subrc = 0.
* zusammenstellen Printdaten (VKBUR, KND Anrede Name Briefart etc.)
    PERFORM hole_printdaten.
    IF subrc = 0.
      formname = 'ZSD_05_KEPO_BRIEF1'.
      PERFORM holen_fbaustein.

      sfcompop-tdnewid   = 'X'.
      sfcompop-tddataset = 'KEPO'.
      sfcompop-tdsuffix1 = 'BRI1'.
      sfcompop-tdtitle   = 'Kehrichtpolizei Gebührenbrief'.

      PERFORM drucken.
    ENDIF.
  ENDIF.
ENDFORM.                    "processing


*&---------------------------------------------------------------------*
*&      Form  hole_printdaten
*&---------------------------------------------------------------------*
FORM hole_printdaten.
*

* suchen Kunde anhand der Partnerrolle
  SELECT SINGLE * FROM vbpa INTO ls_vbpa
    WHERE vbeln EQ nast-objky
      AND parvw EQ 'AG'.

* suchen Kunde
  IF sy-subrc EQ 0.
    SELECT SINGLE * FROM kna1
      WHERE kunnr EQ ls_vbpa-kunnr.
  ELSE.
    SELECT SINGLE * FROM kna1
      WHERE kunnr EQ nast-parnr.
  ENDIF.

  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.

* suchen Vorname Nachname
  CLEAR knvk.
  SELECT SINGLE * FROM knvk
    WHERE kunnr = kna1-kunnr.
*
* holen Faktur
  SELECT SINGLE * FROM vbrk
    WHERE vbeln = vbco3-vbeln.
  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.

*
* holen Falldaten
  SELECT SINGLE * FROM zsdtkpauft
    WHERE vbeln_f = vbco3-vbeln.
  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.

  SELECT SINGLE * FROM zsdtkpkepo INTO izsdtkpkepo
    WHERE fallnr = zsdtkpauft-fallnr
     AND  gjahr  = zsdtkpauft-gjahr.
  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.

* füllen übergabestrukturen
  CLEAR ukopfdaten.
  ukopfdaten-adrnr    = kna1-adrnr.
  ukopfdaten-fallnr   = zsdtkpauft-fallnr.
  ukopfdaten-datum    = zsdtkpauft-beldat_f.
  ukopfdaten-funddat  = izsdtkpkepo-fdat.
  ukopfdaten-funzeit  = izsdtkpkepo-fuzei.
  ukopfdaten-kreis    = izsdtkpkepo-kreis.
  ukopfdaten-fart     = izsdtkpkepo-fart.
  WRITE izsdtkpkepo-fuzei TO ukopfdaten-funzeit USING EDIT MASK  '__:__'.

  SELECT SINGLE * FROM zsdtkpmarb
    WHERE marb = izsdtkpkepo-signpers.
  IF sy-subrc = 0.
    ukopfdaten-sachb1   = zsdtkpmarb-name.
    ukopfdaten-sachb2   = zsdtkpmarb-funktion.
  ELSE.
    ukopfdaten-sachb1   = '?????'.
    ukopfdaten-sachb2   = '?????'.
  ENDIF.

* Wiederholungsfall ?
  IF izsdtkpkepo-fwdh NE ' ' .
    z_wiederh = 0.
    SELECT COUNT( * ) FROM zsdtkpkepo INTO z_wiederh
    WHERE fart   EQ izsdtkpkepo-fart
      AND kunnr  EQ izsdtkpkepo-kunnr
      AND fallnr NE izsdtkpkepo-fallnr
      AND fdat   LE izsdtkpkepo-fdat
      AND fstat  NE '04'. "annulliert
  ENDIF.

  ukopfdaten-briefart = izsdtkpkepo-fart.
  ukopfdaten-wiederh  = z_wiederh.

  " Datum im Wiederholungsfall
  IF z_wiederh > 0.
    SELECT SINGLE fdat FROM zsdtkpkepo INTO wdatum
     WHERE fart   EQ izsdtkpkepo-fart
       AND kunnr  EQ izsdtkpkepo-kunnr
       AND fallnr NE izsdtkpkepo-fallnr
       AND fdat   LE izsdtkpkepo-fdat
       AND fstat  NE '04'  "annulliert
       AND kverrgnam EQ space. "Keine Verrechnung sind ausgeschlossene Fälle!

    WRITE wdatum TO ukopfdaten-wdatum MM/DD/YYYY.
  ENDIF.

  IF z_wiederh > 1.
    ukopfdaten-wtext = 'mehrmals'.
  ELSE.
    CONCATENATE 'am' ukopfdaten-wdatum INTO ukopfdaten-wtext SEPARATED BY space.
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
*   Fallart     Kreis wiederholt Textname
*   01      <>   C      ja       ZKEPO_1_TEXT_WBGU
*   01       =   C      ja       ZKEPO_1_TEXT_WBGUI
*   03      <>   C      ja       ZKEPO_1_TEXT_WBPU
*   03       =   C      ja       ZKEPO_1_TEXT_WBPUI
*   01      <>   C      nein     ZKEPO_1_TEXT_BGU
*   01       =   C      nein     ZKEPO_1_TEXT_BGUI
*   03      <>   C      nein     ZKEPO_1_TEXT_BPU
*   03       =   C      nein     ZKEPO_1_TEXT_BPUI
*   02  in jedem Fall            ZKEPO_1_TEXT_EWDA
*   04  in jedem Fall            ZKEPO_1_TEXT_EWDA

* Bieftitel
  IF z_wiederh > 0.
    IF izsdtkpkepo-fart       = '01'.
      ukopfdaten-brieftitel   = 'Wiederholte Bereitstellung eines Gebührensacks zur Unzeit'.
      IF ukopfdaten-kreis     = 'C'.
        ukopfdaten-brieftitel = 'Wiederholte Bereitstellung eines Gebührensacks zur Unzeit in der Innenstadt'.
      ENDIF.
    ENDIF.
    IF izsdtkpkepo-fart       =  '02'.
      ukopfdaten-brieftitel   = 'Entsorgung von widerrechtlich deponiertem Abfall'.
    ENDIF.
    IF izsdtkpkepo-fart       = '03'.
      ukopfdaten-brieftitel   = 'Wiederholte Bereitstellung von Papier/Karton zur Unzeit'.
      IF ukopfdaten-kreis     = 'C'.
        ukopfdaten-brieftitel = 'Wiederholte Bereitstellung von Papier/Karton zur Unzeit in der Innenstadt'.
      ENDIF.
    ENDIF.
    IF izsdtkpkepo-fart       = '04'.
      ukopfdaten-brieftitel   = 'Entsorgung von widerrechtlich deponiertem Abfall'.
    ENDIF.
  ELSE.
    IF izsdtkpkepo-fart       = '01'.
      ukopfdaten-brieftitel   = 'Bereitstellung eines Gebührensacks zur Unzeit'.
      IF ukopfdaten-kreis     = 'C'.
        ukopfdaten-brieftitel = 'Bereitstellung eines Gebührensacks zur Unzeit in der Innenstadt'.
      ENDIF.
    ENDIF.
    IF izsdtkpkepo-fart       = '02'.
      ukopfdaten-brieftitel   = 'Entsorgung von widerrechtlich deponiertem Abfall'.
    ENDIF.
    IF izsdtkpkepo-fart       = '03'.
      ukopfdaten-brieftitel   = 'Bereitstellung von Papier/Karton zur Unzeit'.
      IF ukopfdaten-kreis     = 'C'.
        ukopfdaten-brieftitel = 'Bereitstellung von Papier/Karton zur Unzeit in der Innenstadt'.
      ENDIF.
    ENDIF.
    IF izsdtkpkepo-fart       = '04'.
      ukopfdaten-brieftitel   = 'Entsorgung von widerrechtlich deponiertem Abfall'.
    ENDIF.

  ENDIF.


  " Fundadresse
  CONCATENATE izsdtkpkepo-street
              izsdtkpkepo-house_num1
         INTO ukopfdaten-funadr SEPARATED BY ' '.
  CONCATENATE ukopfdaten-funadr ','
         INTO ukopfdaten-funadr.
  CONCATENATE ukopfdaten-funadr
*              izsdtkpkepo-post_code1
              izsdtkpkepo-city1
         INTO ukopfdaten-funadr SEPARATED BY ' '.

  " Anrede
  IF kna1-anred = 'Herr'.
    ukopfdaten-anrede = 'geehrter Herr'.
    ukopfdaten-nname1 = knvk-name1.
  ENDIF.
  IF kna1-anred = 'Frau'.
    ukopfdaten-anrede = 'geehrte Frau'.
    ukopfdaten-nname1 = knvk-name1.
  ENDIF.

  IF kna1-anred = 'Familie'.
    ukopfdaten-anrede = 'geehrte Familie'.
    ukopfdaten-nname1 = knvk-name1.
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

  LOOP AT udokumente.
    z_dokus = z_dokus + udokumente-dokanz.
  ENDLOOP.
  udokumente-anzdok = z_dokus.

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
*&      Form  hole_daten
*&---------------------------------------------------------------------*
FORM hole_grunddaten.

  CALL FUNCTION 'RV_PRICE_PRINT_REFRESH'
    TABLES
      tkomv = tkomv.

  CLEAR nast_anzal.      "Clear aux. variable for number of outputs

  IF nast-objky+10(6) NE space.
    vbco3-vbeln = nast-objky+16(10).
  ELSE.
    vbco3-vbeln = nast-objky.
  ENDIF.

  vbco3-mandt = sy-mandt.
  vbco3-spras = nast-spras.
  vbco3-kunde = nast-parnr.
  vbco3-parvw = nast-parvw.

  IF vbco3-vbeln = ' '.
    subrc = 4.
  ENDIF.

ENDFORM.                    "hole_daten

*&---------------------------------------------------------------------*
*&      Form  holen_fbaustein
*&---------------------------------------------------------------------*
FORM holen_fbaustein.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname                 = formname
*   VARIANT                  = ' '
*   DIRECT_CALL              = ' '
   IMPORTING
     fm_name                   = fbausteinname
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
  control_params-no_open   = ' '.
  control_params-no_close  = ' '.
* Aufruf Smartform
  CALL FUNCTION fbausteinname
    EXPORTING
      ukopfdaten         = ukopfdaten
      control_parameters = control_params
      output_options     = sfcompop
    TABLES
      udokumente         = udokumente.

ENDFORM.                    "drucken
