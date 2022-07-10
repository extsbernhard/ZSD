*&---------------------------------------------------------------------*
*& Report  ZSD_05_VERFUEGEUNG_PRINT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT zsd_05_verfuegeung_print.
DATA ls_pos_aus TYPE zsd_05_kepo_ver_pos.
DATA lt_pos_aus TYPE TABLE OF zsd_05_kepo_ver_pos.
DATA ls_posdaten TYPE zsdtkpmatpos.
DATA lt_posdaten TYPE TABLE OF zsdtkpmatpos.
DATA ls_pos_aus_head TYPE zsd_05_kepo_ver_pos.
INCLUDE z_sbz_formprint_05_d_declare.
INCLUDE z_sbz_formprint_05_forms.
INCLUDE z_sbz_formprint_05_print_forms.

TABLES: kna1,
        "nast,
        vbrp,
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
DATA mwst TYPE p DECIMALS 1.
DATA ver TYPE TABLE OF zsd_05_kepo_ver.
DATA ls_ver LIKE LINE OF ver.
* Grunddatenbesorgung
DATA: BEGIN OF tkomv OCCURS 50.
        INCLUDE STRUCTURE komv.
      DATA: END OF tkomv.
"DATA: nast_anzal LIKE nast-anzal.  " Number of outputs (Orig. + Cop.)

"DATA: xscreen(1) TYPE c.           " Output on printer or screen
DATA: subrc      TYPE sy-subrc.
DATA: z_wiederh  TYPE i.           " Anzahl wiederholter Fall
DATA: wdatum     TYPE sy-datum.    " Wiederholungsdstatum
DATA: z_dokus(2) TYPE n.           " Anzahl Dokumente

* Smartforms Übergabefelder

"Kopfdaten
*DATA: BEGIN OF ukopfdaten.
*        INCLUDE STRUCTURE zsdtkpsmartform.
*DATA: END OF ukopfdaten.
DATA ukopfdaten LIKE zsdtkpsmartform.
DATA ls_udokumente LIKE zsdtkpsmartform.
DATA lt_udokumente LIKE TABLE OF ls_udokumente.
*DATA: BEGIN OF udokumente OCCURS 0.
*        INCLUDE STRUCTURE zsdtkpsmartform.
*DATA: END OF udokumente.

DATA ls_uposdaten TYPE zsd_05_kepo_ver_pos.
DATA uposdaten LIKE TABLE OF ls_uposdaten.
"Positionsdaten
DATA uposkopf TYPE zsd_05_kepo_ver_pos.
DATA: verdat         TYPE dats,                     "Verwarnungsdatum
      verfdat        TYPE dats,                    "Verfügungsdatum
      kunnr          TYPE kunnr,                     "Kundennummer (Debitor)
      auftragsnummer TYPE zsdtkpauft-vbeln_f, "Auftragsnummer
      fakturanummer  TYPE zsdtkpauft-vbeln_f.
"Fakturanummer

* Smartforms Parameter
DATA: formname       TYPE tdsfname.
DATA: formnamesteb   TYPE tdsfname.
DATA: fbausteinname  TYPE rs38l_fnam.
DATA: control_params TYPE ssfctrlop.
DATA: sfcompop       TYPE ssfcompop.
DATA: ls_print_data_to_read TYPE lbbil_print_data_to_read.
DATA: ls_bil_invoice TYPE lbbil_invoice.
DATA: lf_fm_name            TYPE rs38l_fnam.
DATA: ls_control_param      TYPE ssfctrlop.
DATA: ls_composer_param     TYPE ssfcompop.
DATA: ls_recipient          TYPE swotobjid.
DATA: ls_sender             TYPE swotobjid.
DATA: lf_formname           TYPE tdsfname.
DATA: ls_addr_key           LIKE addr_key.
DATA: ls_dlv-land           LIKE vbrk-land1.
DATA: document_output_info TYPE  ssfcrespd,
      job_output_info      TYPE ssfcrescl,
      job_output_options   TYPE ssfcresop.
DATA: title      TYPE string,
      first_line TYPE string,
      last_line  TYPE string.
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

* determine print data -> Include
  PERFORM set_print_data_to_read USING    lf_formname
                                 CHANGING ls_print_data_to_read
                                 retcode.


* select print data -> Include
  PERFORM get_data USING    ls_print_data_to_read
                   CHANGING ls_addr_key
                            ls_dlv-land
                            ls_bil_invoice
                            retcode.




  "Kontrollparameter (direkt drucken u.s.w.)
  PERFORM set_print_param USING    ls_addr_key
                                   ls_dlv-land
                          CHANGING ls_control_param
                                   ls_composer_param
                                   ls_recipient
                                   ls_sender
                                   retcode.


* Holen betroffene Daten (Fakturanummet Kundennummer)
  PERFORM hole_grunddaten.

  IF subrc = 0.
* zusammenstellen Printdaten (VKBUR, KND Anrede Name Briefart etc.)
    PERFORM hole_printdaten.
    IF subrc = 0.
      formname = 'ZSD_05_KEPO_VERFUEGUNG_S'.
      PERFORM holen_fbaustein.

      sfcompop-tdnewid   = 'X'.
      sfcompop-tddataset = 'KEPO'.
      sfcompop-tdsuffix1 = 'BRI1'.
      sfcompop-tdtitle   = 'Verfügung'.

      PERFORM drucken.
    ENDIF.
  ENDIF.
ENDFORM.                    "processing


*&---------------------------------------------------------------------*
*&      Form  hole_printdaten
*&---------------------------------------------------------------------*
FORM hole_printdaten.
**
*
** suchen Kunde anhand der Partnerrolle
*  SELECT SINGLE * FROM vbpa INTO ls_vbpa
*    WHERE vbeln EQ nast-objky
*      AND parvw EQ 'AG'.
*
** suchen Kunde
*  IF sy-subrc EQ 0.
*    SELECT SINGLE * FROM kna1
*      WHERE kunnr EQ ls_vbpa-kunnr.
*  ELSE.
*    SELECT SINGLE * FROM kna1
*      WHERE kunnr EQ nast-parnr.
*  ENDIF.
*
*  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.
*
** suchen Vorname Nachname
*  CLEAR knvk.
*  SELECT SINGLE * FROM knvk
*    WHERE kunnr = kna1-kunnr.
**
** holen Faktur
*  SELECT SINGLE * FROM vbrk
*    WHERE vbeln = vbco3-vbeln.
*  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.
*
**
** holen Falldaten
*  SELECT SINGLE * FROM zsdtkpauft
*    WHERE vbeln_f = vbco3-vbeln.
*  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.
*
*  SELECT SINGLE * FROM zsdtkpkepo INTO izsdtkpkepo
*    WHERE fallnr = zsdtkpauft-fallnr
*     AND  gjahr  = zsdtkpauft-gjahr.
*  IF sy-subrc NE 0. subrc = 4. EXIT. ENDIF.
*
** füllen übergabestrukturen
*  CLEAR ukopfdaten.
*  ukopfdaten-adrnr    = kna1-adrnr.
*  ukopfdaten-fallnr   = zsdtkpauft-fallnr.
*  ukopfdaten-datum    = zsdtkpauft-beldat_f.
*  ukopfdaten-funddat  = izsdtkpkepo-fdat.
*  ukopfdaten-funzeit  = izsdtkpkepo-fuzei.
*  ukopfdaten-kreis    = izsdtkpkepo-kreis.
*  ukopfdaten-fart     = izsdtkpkepo-fart.
*  WRITE izsdtkpkepo-fuzei TO ukopfdaten-funzeit USING EDIT MASK  '__:__'.
*
*  SELECT SINGLE * FROM zsdtkpmarb
*    WHERE marb = izsdtkpkepo-signpers.
*  IF sy-subrc = 0.
*    ukopfdaten-sachb1   = zsdtkpmarb-name.
*    ukopfdaten-sachb2   = zsdtkpmarb-funktion.
*  ELSE.
*    ukopfdaten-sachb1   = '?????'.
*    ukopfdaten-sachb2   = '?????'.
*  ENDIF.
*
*
** Wiederholungsfall ?
*  IF izsdtkpkepo-fwdh NE ' ' .
*    z_wiederh = 0.
*    SELECT COUNT( * ) FROM zsdtkpkepo INTO z_wiederh
*    WHERE fart   EQ izsdtkpkepo-fart
*      AND kunnr  EQ izsdtkpkepo-kunnr
*      AND fallnr NE izsdtkpkepo-fallnr
*      AND fdat   LE izsdtkpkepo-fdat
*      AND fstat  NE '04'. "annulliert
*  ENDIF.
*
*  ukopfdaten-briefart = izsdtkpkepo-fart.
*  ukopfdaten-wiederh  = z_wiederh.
*
*  " Datum im Wiederholungsfall
*  IF z_wiederh > 0.
*    SELECT SINGLE fdat FROM zsdtkpkepo INTO wdatum
*     WHERE fart   EQ izsdtkpkepo-fart
*       AND kunnr  EQ izsdtkpkepo-kunnr
*       AND fallnr NE izsdtkpkepo-fallnr
*       AND fdat   LE izsdtkpkepo-fdat
*       AND fstat  NE '04'  "annulliert
*       AND kverrgnam EQ space. "Keine Verrechnung sind ausgeschlossene Fälle!
*
*    WRITE wdatum TO ukopfdaten-wdatum MM/DD/YYYY.
*  ENDIF.
*
*  IF z_wiederh > 1.
*    ukopfdaten-wtext = 'mehrmals'.
*  ELSE.
*    CONCATENATE 'am' ukopfdaten-wdatum INTO ukopfdaten-wtext SEPARATED BY space.
*  ENDIF.
*
*
**  Texte und Titel
**  Fallart
**   01     Blaue Kehrichtsäcke
**   02     Schwarze Kehrichtsäcke
**   03     Papier / Karton
**   04     Wilde Deponie
**  Kreis
**   A      Kreis A
**   B      Kreis B
**   C      Kreis C Innenstadt
** Texte in Smartforms
**   Fallart     Kreis wiederholt Textname
**   01      <>   C      ja       ZKEPO_1_TEXT_WBGU
**   01       =   C      ja       ZKEPO_1_TEXT_WBGUI
**   03      <>   C      ja       ZKEPO_1_TEXT_WBPU
**   03       =   C      ja       ZKEPO_1_TEXT_WBPUI
**   01      <>   C      nein     ZKEPO_1_TEXT_BGU
**   01       =   C      nein     ZKEPO_1_TEXT_BGUI
**   03      <>   C      nein     ZKEPO_1_TEXT_BPU
**   03       =   C      nein     ZKEPO_1_TEXT_BPUI
**   02  in jedem Fall            ZKEPO_1_TEXT_EWDA
**   04  in jedem Fall            ZKEPO_1_TEXT_EWDA
*
** Bieftitel
*
*    case izsdtkpkepo-fart .
*      when  '01'. "Blauer Sack
*      title   = 'Gebühr für die wiederholte Bereitstellung eines Gebührensacks zur falschen Zeit'.
*      first_line = 'Wiederholte Bereitstellung eines Gebührensacks zur falschen Zeit'.
*      last_line = 'das Schlitzen, sprich die Kontrolle des Abfalls, sowie für den administrativen Aufwand folgende Gebühr verfügt:'.
*
*    when '02'. "Schwarzer Sack
*      title   = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Abfall'.
*      first_line = 'Entsorgung von widerrechtlich deponiertem Abfall'.
*      last_line = 'das Schlitzen, sprich die Kontrolle des Abfalls, sowie für den administrativen Aufwand folgende Gebühr verfügt:'.
*
*    when '03'. " Papier Karton
*      title   = 'Gebühr für die wiederholte Bereitstellung von Papier/Karton zur falschen Zeit'.
*      first_line = 'Wiederholte Bereitstrllung von Papier/Karton zur falschen Zeit'.
*      last_line = 'das Durchsuchen, sprich die Kontrolle des Papier/Karton, sowie für den administrativen Aufwand folgende Gebühr verfügt:'.
*    when '04'.
*      title   = 'Entsorgung von widerrechtlich deponiertem Abfall'.
*      first_line = 'Entsorgung von widerrechtlich deponiertem Abfall'.
*      last_line = 'das Schlitzen, sprich die Kontrolle des Abfalls, sowie für den administrativen Aufwand folgende Gebühr verfügt:'.
*  endcase.
*
*
*
*
*
*  " Fundadresse
*  CONCATENATE izsdtkpkepo-street
*              izsdtkpkepo-house_num1
*         INTO ukopfdaten-funadr SEPARATED BY ' '.
*  CONCATENATE ukopfdaten-funadr ','
*         INTO ukopfdaten-funadr.
*  CONCATENATE ukopfdaten-funadr
**              izsdtkpkepo-post_code1
*              izsdtkpkepo-city1
*         INTO ukopfdaten-funadr SEPARATED BY ' '.
*
*  " Anrede
*  IF kna1-anred = 'Herr'.
*    ukopfdaten-anrede = 'geehrter Herr'.
*    ukopfdaten-nname1 = knvk-name1.
*  ENDIF.
*  IF kna1-anred = 'Frau'.
*    ukopfdaten-anrede = 'geehrte Frau'.
*    ukopfdaten-nname1 = knvk-name1.
*  ENDIF.
*
*  IF kna1-anred = 'Familie'.
*    ukopfdaten-anrede = 'geehrte Familie'.
*    ukopfdaten-nname1 = knvk-name1.
*  ENDIF.
*
*  IF kna1-anred = ' '
*  OR kna1-anred = 'Firma'.
*    ukopfdaten-anrede = 'geehrte Damen und Herren'.
*  ENDIF.
*
*  IF knvk-name1     = ' '
*  AND kna1-anred NE ' '
*  AND kna1-anred NE 'Firma' .
*    ukopfdaten-nname1 = kna1-name1.
*  ENDIF.
*
**Verwarnungsdatum$
*
*select single ver_datum from zsd_05_kepo_ver into verdat
*  WHERE fallnr = izsdtkpkepo-fallnr
*      AND gjahr  = izsdtkpkepo-gjahr.
*
*
*
** Tabelle mit Dokumenten
*
*  REFRESH lt_udokumente.
*  SELECT * FROM zsdtkpdocpos
*    WHERE fallnr = izsdtkpkepo-fallnr
*      AND gjahr  = izsdtkpkepo-gjahr.
*
*    ls_udokumente-dokanz = zsdtkpdocpos-anzahl.
*    ls_udokumente-dokart = zsdtkpdocpos-docart.
*    ls_udokumente-doktxt = zsdtkpdocpos-bezei.
*
*    IF zsdtkpdocpos-bezei = ' '.
*      SELECT bezei FROM zsdtkpdocart INTO zsdtkpdocpos-bezei
*        WHERE docart = zsdtkpdocpos-docart
*          AND spras  = 'DE'.
*        ls_udokumente-doktxt = zsdtkpdocpos-bezei.
*      ENDSELECT.
*    ENDIF.
*    APPEND ls_udokumente to lt_udokumente.
*  ENDSELECT.
*
*  LOOP AT lt_udokumente into ls_udokumente.
*    z_dokus = z_dokus + ls_udokumente-dokanz.
*  ENDLOOP.
*  ls_udokumente-anzdok = z_dokus.
*
*  save_tabix = sy-tabix.
*  CLEAR ukopfdaten-doktxt.
*  LOOP AT lt_udokumente into ls_udokumente.
*    SHIFT ls_udokumente-dokanz LEFT DELETING LEADING '0'.
*    IF ( sy-tabix = 1 AND  sy-tabix = save_tabix )
*    OR sy-tabix = 1.
*      CONCATENATE ls_udokumente-dokanz ls_udokumente-doktxt  INTO ukopfdaten-doktxt SEPARATED BY space.
*    ELSE.
*      IF sy-tabix = save_tabix.
*        CONCATENATE ukopfdaten-doktxt 'und' INTO ukopfdaten-doktxt SEPARATED BY space.
*        CONCATENATE ukopfdaten-doktxt  ls_udokumente-dokanz ' ' ls_udokumente-doktxt  INTO ukopfdaten-doktxt SEPARATED BY space.
*      ELSE.
*        CONCATENATE ukopfdaten-doktxt ', '  INTO ukopfdaten-doktxt.
*        CONCATENATE ukopfdaten-doktxt ls_udokumente-dokanz ' ' ls_udokumente-doktxt  INTO ukopfdaten-doktxt SEPARATED BY space.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.
*
*"Fülle posdaten
*data lt_vbrp type table of vbrp.
*data ls_vbrp like line of lt_vbrp.
*data a type string.
*
*"select * from vbrp into ls_vbrp where vbeln = vbco3-vbeln.
*"  append ls_vbrp to lt_vbrp.
*
*    SELECT * FROM zsdtkpmatpos INTO ls_posdaten WHERE fallnr = izsdtkpkepo-fallnr AND gjahr = izsdtkpkepo-gjahr.
*
*    ls_pos_aus-posnr = ls_posdaten-posnr.
*    ls_pos_aus-bez = ls_posdaten-bezei.
*    ls_pos_aus-menge = ls_posdaten-anzahl.
*
*    "Preispro Definieren Pro position.
*    case ls_posdaten-matnr.
*      when '8500292'.                         "Aufwandgebühr (1.Std.) -                80.-
*         ls_pos_aus-preispro = '80.00'.
*      when '8500381'.                         "Grobsperrgut brennbar / Wilde Deponie - 65.06.-
*         ls_pos_aus-preispro = '65.06'.
*      when '8500383'.                         "Kosten Fahrzeig / Transport Pauschale - 25.-
*         ls_pos_aus-preispro = '25.00'.
*      when '8500384'.                         "Einsatzzeit Fahrzeug (15 Minuten) -     10.-
*         ls_pos_aus-preispro = '10.00'.
*      when '8500385'.                         "Gebühren für beanspr. Personal -        80.-
*         ls_pos_aus-preispro = '80.00'.
*      when '8500400'.                         "Kosten Fahrzeug / Transport Pauschale - 10.-
*         ls_pos_aus-preispro = '100.00'.
*    endcase.
*    ls_pos_aus-leistungsart = ls_posdaten-vrkme.
*    "Berechne preis * Menge
*    ls_pos_aus-wert = ls_pos_aus-preispro * ls_pos_aus-menge.
*    "Berechne Total Exklusiv Mehrwertsteuer
*    "Total exklusiv + wert in Kopfzeile
*    ls_pos_aus_head-total_exkl = ls_pos_aus_head-total_exkl + ls_pos_aus-wert.
*
*
*    APPEND ls_pos_aus TO lt_pos_aus.
**  ls_uposdaten-posnr       = ls_vbrp-posnr.               "Positionsnummer
**  ls_uposdaten-bez         = ls_vbrp-arktx.               "Bezeichnung
**  ls_uposdaten-menge       = ls_vbrp-fkimg.               "Menge
**
** " ls_uposdaten-preispro   = ls_vbrp-netwr / ls_vbrp-fkimg."Preis-Pro
**     case ls_vbrp-matnr.
**      when '8500292'.                         "Aufwandgebühr (1.Std.) -                80.-
**         ls_uposdaten-preispro = '80.00'.
**      when '8500381'.                         "Grobsperrgut brennbar / Wilde Deponie - 65.06.-
**         ls_uposdaten-preispro = '65.06'.
**      when '8500383'.                         "Kosten Fahrzeig / Transport Pauschale - 25.-
**         ls_uposdaten-preispro = '25.00'.
**      when '8500384'.                         "Einsatzzeit Fahrzeug (15 Minuten) -     10.-
**         ls_uposdaten-preispro = '10.00'.
**      when '8500385'.                         "Gebühren für beanspr. Personal -        80.-
**         ls_uposdaten-preispro = '80.00'.
**      when '8500400'.                         "Kosten Fahrzeug / Transport Pauschale - 10.-
**         ls_uposdaten-preispro = '100.00'.
**      when '8500292'.                      "Aufwandgebühr (Einheit 1 Std.)-         80.-
**         ls_uposdaten-preispro = '80.00'.
**    endcase.
**
**  ls_uposdaten-leistungsart = 'LE'.                       "Leistungsart
**  ls_uposdaten-wert = ls_uposdaten-preispro * ls_uposdaten-menge.
**  ls_uposdaten-total_exkl  = ls_uposdaten-total_exkl + ls_uposdaten-wert.               "
**  ls_uposdaten-mwst = ls_vbrp-mwsbp.
**
**
**  "mwst = ls_vbrp-mwsbp / ls_vbrp-netwr * 100.
**
**
**"  add: ls_vbrp-netwr to ls_vbrp-mwsbp.
**   ls_uposdaten-total_inkl = ls_uposdaten-total_exkl + ls_uposdaten-mwst.
**  append ls_uposdaten to uposdaten.
**
*
*
*
*  endselect.
*
*
*  select single * from ZSD_05_KEPO_VER into ls_ver where fallnr = izsdtkpkepo-fallnr.
*    verfdat = ls_ver-VER_DATUM.

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

*  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
*    EXPORTING
*      formname                 = formname
**   VARIANT                  = ' '
**   DIRECT_CALL              = ' '
*   IMPORTING
*     fm_name                   = fbausteinname
** EXCEPTIONS
**   NO_FORM                  = 1
**   NO_FUNCTION_MODULE       = 2
**   OTHERS                   = 3
*            .
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.
ENDFORM.                    "holen_fbaustein

*&---------------------------------------------------------------------*
*&      Form  drucken
*&---------------------------------------------------------------------*
FORM drucken.


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
  auftragsnummer = zsdtkpauft-vbeln_a.
  fakturanummer = zsdtkpauft-vbeln_f.
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
    WHERE marb = izsdtkpkepo-psachb.
  IF sy-subrc = 0.
    ukopfdaten-sachb1   = izsdtkpkepo-psachb.
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

  CASE izsdtkpkepo-fart .
    WHEN  '01'. "Blauer Sack
      title   = 'Gebühr für die wiederholte Bereitstellung eines Gebührensacks zur falschen Zeit'.
      first_line = 'Wiederholte Bereitstellung eines Gebührensacks zur falschen Zeit'.
      last_line = 'das Schlitzen, sprich die Kontrolle des Abfalls, sowie für den administrativen Aufwand folgende Gebühr verfügt:'.

    WHEN '02'. "Schwarzer Sack
      title   = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Abfall'.
      first_line = 'Entsorgung von widerrechtlich deponiertem Abfall'.
      last_line = 'das Schlitzen, sprich die Kontrolle des Abfalls, sowie für den administrativen Aufwand folgende Gebühr verfügt:'.

    WHEN '03'. " Papier Karton
      title   = 'Gebühr für die wiederholte Bereitstellung von Papier/Karton zur falschen Zeit'.
      first_line = 'Wiederholte Bereitstrllung von Papier/Karton zur falschen Zeit'.
      last_line = 'das Durchsuchen, sprich die Kontrolle des Papier/Karton, sowie für den administrativen Aufwand folgende Gebühr verfügt:'.
    WHEN '04'.
      title   = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Abfall'.
      first_line = 'Entsorgung von widerrechtlich deponiertem Abfall'.
      last_line = 'das Schlitzen, sprich die Kontrolle des Abfalls, sowie für den administrativen Aufwand folgende Gebühr verfügt:'.
      " MZi neue Fallarten
    WHEN '05'.  " Schwarzer Sack QES
      title   = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Abfall'.
      first_line = 'Entsorgung von widerrechtlich deponiertem Abfall'.
      last_line = 'das Durchsuchen, sprich die Kontrolle des Ab-falls, die Entsorgung sowie für den administrativen Aufwand folgende Gebühr verfügt:'.
    WHEN '06'.  "Papier / Karton QES
      title   = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Papier/Karton an Sammelstellen für Separatabfälle'.
      first_line = 'Entsorgung von widerrechtlich deponiertem Papier/Karton an Sammelstellen'.
      last_line = 'das Durchsuchen, sprich die Kontrolle des Papier/Karton, sowie für den administrativen Aufwand folgende Gebühr verfügt:'.
    WHEN '07'.  "Papier / Karton Unzeit QES
      title   = 'Gebühr für die Entsorgung von widerrechtlich deponiertem Papier/Karton an Sammelstellen für Separatabfälle ausserhalb der Benutzungszeiten'.
      first_line = 'Entsorgung von widerrechtlich deponiertem Papier/Karton an Sammelstellen für Separatabfälle ausserhalb der Benutzungszeiten'.
      last_line = 'das Durchsuchen, sprich die Kontrolle des Papiers/Karton, die Entsorgung sowie für den administrativen Aufwand folgende Gebühr verfügt:'.
  ENDCASE.





  " Fundadresse
  CONCATENATE izsdtkpkepo-street
              izsdtkpkepo-house_num1
         INTO ukopfdaten-funadr SEPARATED BY ' '.
  CONCATENATE ukopfdaten-funadr ','
         INTO ukopfdaten-funadr.
  CONCATENATE ukopfdaten-funadr
              izsdtkpkepo-post_code1
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

*Verwarnungsdatum$

  SELECT SINGLE ver_datum FROM zsd_05_kepo_ver INTO verdat
    WHERE fallnr = izsdtkpkepo-fallnr
        AND gjahr  = izsdtkpkepo-gjahr
    AND typ = 'V'.
  IF sy-subrc NE 0. "Falls nichts gefunden, suche verwarnung von Vorhergehendem Fall. Einen Fall mit selbem Debitor jünger als zwei Jahre
    DATA jahrminuszwei TYPE integer.
    jahrminuszwei = izsdtkpkepo-gjahr - 2.
    SELECT SINGLE ver_datum FROM zsd_05_kepo_ver INTO verdat
      WHERE debitor = izsdtkpkepo-kunnr
      AND gjahr GT jahrminuszwei.

  ENDIF.
* Tabelle mit Dokumenten

  REFRESH lt_udokumente.
  SELECT * FROM zsdtkpdocpos
    WHERE fallnr = izsdtkpkepo-fallnr
      AND gjahr  = izsdtkpkepo-gjahr.

    ls_udokumente-dokanz = zsdtkpdocpos-anzahl.
    ls_udokumente-dokart = zsdtkpdocpos-docart.
    ls_udokumente-doktxt = zsdtkpdocpos-bezei.

    IF zsdtkpdocpos-bezei = ' '.
      SELECT bezei FROM zsdtkpdocart INTO zsdtkpdocpos-bezei
        WHERE docart = zsdtkpdocpos-docart
          AND spras  = 'DE'.
        ls_udokumente-doktxt = zsdtkpdocpos-bezei.
      ENDSELECT.
    ENDIF.
    APPEND ls_udokumente TO lt_udokumente.
  ENDSELECT.

  LOOP AT lt_udokumente INTO ls_udokumente.
    z_dokus = z_dokus + ls_udokumente-dokanz.
  ENDLOOP.
  ls_udokumente-anzdok = z_dokus.

  save_tabix = sy-tabix.
  CLEAR ukopfdaten-doktxt.
  LOOP AT lt_udokumente INTO ls_udokumente.
    SHIFT ls_udokumente-dokanz LEFT DELETING LEADING '0'.
    IF ( sy-tabix = 1 AND  sy-tabix = save_tabix )
    OR sy-tabix = 1.
      CONCATENATE ls_udokumente-dokanz ls_udokumente-doktxt  INTO ukopfdaten-doktxt SEPARATED BY space.
    ELSE.
      IF sy-tabix = save_tabix.
        CONCATENATE ukopfdaten-doktxt 'und' INTO ukopfdaten-doktxt SEPARATED BY space.
        CONCATENATE ukopfdaten-doktxt  ls_udokumente-dokanz ' ' ls_udokumente-doktxt  INTO ukopfdaten-doktxt SEPARATED BY space.
      ELSE.
        CONCATENATE ukopfdaten-doktxt ', '  INTO ukopfdaten-doktxt.
        CONCATENATE ukopfdaten-doktxt ls_udokumente-dokanz ' ' ls_udokumente-doktxt  INTO ukopfdaten-doktxt SEPARATED BY space.
      ENDIF.
    ENDIF.
  ENDLOOP.

  "Fülle posdaten
  DATA lt_vbrp TYPE TABLE OF vbrp.
  DATA ls_vbrp LIKE LINE OF lt_vbrp.
  DATA a TYPE string.
  REFRESH lt_pos_aus.
  "select * from vbrp into ls_vbrp where vbeln = vbco3-vbeln.
  "  append ls_vbrp to lt_vbrp.

  " MwSt Satz
  DATA is_kond TYPE LINE OF lbbil_invoice-hd_kond.

  SELECT * FROM zsdtkpmatpos INTO ls_posdaten WHERE fallnr = izsdtkpkepo-fallnr AND gjahr = izsdtkpkepo-gjahr..

    ls_pos_aus-posnr = ls_posdaten-posnr.
    ls_pos_aus-bez = ls_posdaten-bezei.
    ls_pos_aus-menge = ls_posdaten-anzahl.

    "Preispro Definieren Pro position.
    CASE ls_posdaten-matnr.
      WHEN '8500292'.                         "Aufwandgebühr (1.Std.) -                80.-
        ls_pos_aus-preispro = '80.00'.
      WHEN '8500381'.                         "Grobsperrgut brennbar / Wilde Deponie - 65.06.-
*         ls_pos_aus-preispro = '65.06'.
        ls_pos_aus-preispro = '60.19'.    "neu ab 09.2016
      WHEN '8500383'.                         "Kosten Fahrzeig / Transport Pauschale - 25.-
        ls_pos_aus-preispro = '25.00'.
      WHEN '8500384'.                         "Einsatzzeit Fahrzeug (15 Minuten) -     10.-
        ls_pos_aus-preispro = '10.00'.
      WHEN '8500385'.                         "Gebühren für beanspr. Personal -        80.-
        ls_pos_aus-preispro = '80.00'.
      WHEN '8500400'.                         "Kosten Fahrzeug / Transport Pauschale - 10.-
        ls_pos_aus-preispro = '100.00'.
      WHEN '8500550'.                         "Grobsperrgut brennbar Auswärtige / Wilde Deponie
        ls_pos_aus-preispro = '83.33'.
      WHEN '8500551'.                         "Grobsperrgut unbrennbar Einheimische / Wilde Deponie
        ls_pos_aus-preispro = '74.07'.
      WHEN '8500552'.                         "Grobsperrgut unbrennbar Auswärtige / Wilde Deponie
        ls_pos_aus-preispro = '97.22'.
    ENDCASE.
    ls_pos_aus-leistungsart = ls_posdaten-vrkme.
    "Berechne preis * Menge
    ls_pos_aus-wert = ls_pos_aus-preispro * ls_pos_aus-menge.
    "Berechne Total Exklusiv Mehrwertsteuer
    "Total exklusiv + wert in Kopfzeile
    ls_pos_aus_head-total_exkl = ls_pos_aus_head-total_exkl + ls_pos_aus-wert.

    " MwSt Satz
    LOOP AT ls_bil_invoice-hd_kond INTO is_kond.
      ls_pos_aus-mwst = is_kond-kbetr / 10.
    ENDLOOP.
    APPEND ls_pos_aus TO lt_pos_aus.
*  ls_uposdaten-posnr       = ls_vbrp-posnr.               "Positionsnummer
*  ls_uposdaten-bez         = ls_vbrp-arktx.               "Bezeichnung
*  ls_uposdaten-menge       = ls_vbrp-fkimg.               "Menge
*
* " ls_uposdaten-preispro   = ls_vbrp-netwr / ls_vbrp-fkimg."Preis-Pro
*     case ls_vbrp-matnr.
*      when '8500292'.                         "Aufwandgebühr (1.Std.) -                80.-
*         ls_uposdaten-preispro = '80.00'.
*      when '8500381'.                         "Grobsperrgut brennbar / Wilde Deponie - 65.06.-
*         ls_uposdaten-preispro = '65.06'.
*      when '8500383'.                         "Kosten Fahrzeig / Transport Pauschale - 25.-
*         ls_uposdaten-preispro = '25.00'.
*      when '8500384'.                         "Einsatzzeit Fahrzeug (15 Minuten) -     10.-
*         ls_uposdaten-preispro = '10.00'.
*      when '8500385'.                         "Gebühren für beanspr. Personal -        80.-
*         ls_uposdaten-preispro = '80.00'.
*      when '8500400'.                         "Kosten Fahrzeug / Transport Pauschale - 10.-
*         ls_uposdaten-preispro = '100.00'.
*      when '8500292'.                      "Aufwandgebühr (Einheit 1 Std.)-         80.-
*         ls_uposdaten-preispro = '80.00'.
*    endcase.
*
*  ls_uposdaten-leistungsart = 'LE'.                       "Leistungsart
*  ls_uposdaten-wert = ls_uposdaten-preispro * ls_uposdaten-menge.
*  ls_uposdaten-total_exkl  = ls_uposdaten-total_exkl + ls_uposdaten-wert.               "
*  ls_uposdaten-mwst = ls_vbrp-mwsbp.
*
*
*  "mwst = ls_vbrp-mwsbp / ls_vbrp-netwr * 100.
*
*
*"  add: ls_vbrp-netwr to ls_vbrp-mwsbp.
*   ls_uposdaten-total_inkl = ls_uposdaten-total_exkl + ls_uposdaten-mwst.
*  append ls_uposdaten to uposdaten.
*



  ENDSELECT.


  SELECT SINGLE * FROM zsd_05_kepo_ver INTO ls_ver WHERE fallnr = izsdtkpkepo-fallnr.
  verfdat = ls_ver-ver_datum.



  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname = formname
*     VARIANT  = ' '
*     DIRECT_CALL              = ' '
    IMPORTING
      fm_name  = fbausteinname
* EXCEPTIONS
*     NO_FORM  = 1
*     NO_FUNCTION_MODULE       = 2
*     OTHERS   = 3
    .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  "Definiere Signierende Personen
  DATA signpers_verfuegung TYPE char3 .
  SELECT SINGLE id INTO signpers_verfuegung FROM zsd_05_kp_sign WHERE fallnr = izsdtkpkepo-fallnr AND gjahr = izsdtkpkepo-gjahr AND typ = '01'.
  IF sy-subrc = 0 AND signpers_verfuegung IS NOT INITIAL. "wenn gefunden
  ELSE. "wenn nicht gefunden
    signpers_verfuegung = '003'.
  ENDIF.


*----------------------------
  DATA pdf_text TYPE string.
  DATA adrnr    TYPE adrnr.
  DATA adr13    TYPE adr13.

  SELECT SINGLE adrnr FROM tvko INTO adrnr
    WHERE vkorg = ls_bil_invoice-hd_org-salesorg.
*       WHERE vkorg = ls_bil_invoice-hd_org-salesorg.
  IF sy-subrc = 0.
    SELECT SINGLE * FROM adr13 INTO adr13
     WHERE addrnumber = adrnr
       AND pager_serv = 'HINW'
       AND pager_nmbr = 'X'.
    IF sy-subrc = 0.
      pdf_text = 'Möchten Sie unsere Rechnungen per E-Mail erhalten? Hier anmelden: www.bern.ch/rechnung'.
    ELSE.
      pdf_text = ' '.
    ENDIF.
  ELSE.
    pdf_text = ' '.
  ENDIF.

  " MZi 07.2022 QR Rechnung

  DATA is_glo_qr_sales  TYPE glo_qr_sales.
  DATA is_ref           TYPE string.
  DATA qr_code          TYPE string.
  DATA qr_bill          TYPE string.
  DATA laenge           TYPE i.
  DATA bitmap           TYPE xstring.
  DATA object           TYPE stxbitmaps-tdobject.
  DATA id               TYPE stxbitmaps-tdid.
  DATA btype            TYPE stxbitmaps-tdbtype.
  DATA ibetrag          TYPE string.
  DATA iiban            TYPE string.
  DATA qruebergabe      TYPE zsd_ch_qr_uebergabe.
  " QR und Inhalt aufbauen
  CALL FUNCTION 'Z_SD_00_QR_RECHNUNG'
    EXPORTING
      nast           = nast
*     empf_iban      = is_glo_qr_sales-qriban
*     debi_iban      = ' '
*     rechnungsinfo  = ' ' "'//S1/01/20170309/11/10201409/20/14000000/22/36958/30/CH106017086/40/1020/41/3010'
*     sapscr         = sapscr
*     adobef         = adobef
      smartf         = abap_true
*     g_bds_name     = g_bds_name1
*      IMPORTING
*     qr_code        = qr_code
*     laenge         = laenge
*     qr_bill        = qr_bill
*     bitmap         = bitmap
*     object         = object
*     id             = id
*     btype          = btype
*      dadrnr         = ukopfdaten-adrnr
    CHANGING
      ls_bil_invoice = ls_bil_invoice
      qruebergabe    = qruebergabe.

  " QR qird nach dem Drucken wieder gelöscht

  " MZi 07.2022

  "   DATA: ls_bil_invoice TYPE lbbil_invoice.
  "data a type kunnr.
  "a = 1000385.
  control_params-no_open   = ' '.
  control_params-no_close  = ' '.

* Aufruf Smartform
  CALL FUNCTION fbausteinname
    EXPORTING
      ukopfdaten         = ukopfdaten
      control_parameters = control_params
      output_options     = sfcompop
      verdat             = verdat
      verfdat            = vbrk-fkdat
      kunnr              = izsdtkpkepo-kunnr "a"1000385"vbrk-kidno"kunnr
      uposkopf           = ls_pos_aus_head
      auftragsnummer     = auftragsnummer
      fakturanummer      = fakturanummer
      is_bil_invoice     = ls_bil_invoice
      title              = title
      first_line         = first_line
      last_line          = last_line
      signp              = signpers_verfuegung
      pdf_text           = pdf_text
      qruebergabe        = qruebergabe
      is_nast            = nast
    TABLES
      udokumente         = lt_udokumente
      uposdaten          = lt_pos_aus.

  "MZi 07.2022 QR Rechnung (QR Code nach Druck löschen)
  CALL FUNCTION 'SAPSCRIPT_DELETE_GRAPHIC_BDS'
    EXPORTING
      i_object       = 'GRAPHICS'
      i_name         = qruebergabe-qr_name
      i_id           = 'BMAP'
      i_btype        = 'BMON'
      dialog         = abap_false
    EXCEPTIONS
      enqueue_failed = 1
      delete_failed  = 2
      not_found      = 3
      canceled       = 4
      OTHERS         = 5.

  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  " MZi 07.2022

*"Aus SBZ Programm, funktion muss noch gecheckt werden.
*INCLUDE z_sbz_formprint_05_d_declare.
*INCLUDE z_sbz_formprint_05_forms.
*INCLUDE z_sbz_formprint_05_print_forms.
*
**---------------------------------------------------------------------*
**       FORM ENTRY
*"       Standard, schaut überall gleich aus wo ich bis jetzt geguckt habe.
**---------------------------------------------------------------------*
*FORM entry USING return_code us_screen.
*
*  DATA: lf_retcode TYPE sy-subrc.
*  CLEAR retcode.
*  xscreen = us_screen.
*  PERFORM processing USING us_screen
*                     CHANGING lf_retcode.
*  IF lf_retcode NE 0.
*    return_code = 1.
*  ELSE.
*    return_code = 0.
*  ENDIF.
*
*ENDFORM.                    "entry
*
**---------------------------------------------------------------------*
**       FORM PROCESSING                                               *
**---------------------------------------------------------------------*
*FORM processing USING proc_screen
*                CHANGING cf_retcode.
*
*  DATA: ls_print_data_to_read TYPE lbbil_print_data_to_read.
*  DATA: ls_bil_invoice TYPE lbbil_invoice.
*  DATA: lf_fm_name            TYPE rs38l_fnam.
*  DATA: ls_control_param      TYPE ssfctrlop.
*  DATA: ls_composer_param     TYPE ssfcompop.
*  DATA: ls_recipient          TYPE swotobjid.
*  DATA: ls_sender             TYPE swotobjid.
*  DATA: lf_formname           TYPE tdsfname.
*  DATA: ls_addr_key           LIKE addr_key.
*  DATA: ls_dlv-land           LIKE vbrk-land1.
*
**  DATA: document_output_info TYPE  ssfcrespd,
**      job_output_info TYPE ssfcrescl,
**      job_output_options TYPE ssfcresop.
*
*
** SmartForm from customizing table TNAPR
*  lf_formname = 'ZSD_05_KEPO_VERFUEGUNG_S'.
*
** determine print data -> Include
*  PERFORM set_print_data_to_read USING    lf_formname
*                                 CHANGING ls_print_data_to_read
*                                 cf_retcode.
*
*  IF cf_retcode = 0.
** select print data -> Include
*    PERFORM get_data USING    ls_print_data_to_read
*                     CHANGING ls_addr_key
*                              ls_dlv-land
*                              ls_bil_invoice
*                              cf_retcode.
*  ENDIF.
*
*  IF cf_retcode = 0.
*    "Kontrollparameter (direkt drucken u.s.w.)
*    PERFORM set_print_param USING    ls_addr_key
*                                     ls_dlv-land
*                            CHANGING ls_control_param
*                                     ls_composer_param
*                                     ls_recipient
*                                     ls_sender
*                                     cf_retcode.
*  ENDIF.
*
*  IF cf_retcode = 0.
*    "Hole Formularbaustein
*    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
*      EXPORTING
*        formname           = lf_formname
*      IMPORTING
*        fm_name            = lf_fm_name
*      EXCEPTIONS
*        no_form            = 1
*        no_function_module = 2
*        OTHERS             = 3.
*    IF sy-subrc <> 0.
*      cf_retcode = sy-subrc.
*      "Protokollaufruf -> aus Include
*      PERFORM protocol_update.
*    ENDIF.
*  ENDIF.
*
*  IF cf_retcode = 0.
*    "Prüfe ob Archivierung bereits beesteht -> aus Include
*    PERFORM check_repeat.
*    IF ls_composer_param-tdcopies EQ 0.
*      nast_anzal = 1.
*    ELSE.
*      nast_anzal = ls_composer_param-tdcopies.
*    ENDIF.
*    ls_composer_param-tdcopies = 1.
*    DO nast_anzal TIMES.
** IN CASE OF REPETITION ONLY ONE TIME ARCHIVING
*      IF sy-index > 1 AND nast-tdarmod = 3.
*        nast_tdarmod = nast-tdarmod.
*        nast-tdarmod = 1.
*        ls_composer_param-tdarmod = 1.
*      ENDIF.
*      IF sy-index NE 1 AND repeat IS INITIAL.
*        repeat = 'X'.
*      ENDIF.
** call smartform invoice
*
*
*      CALL FUNCTION lf_fm_name
*        EXPORTING
*          archive_index      = toa_dara
*          archive_parameters = arc_params
*          control_parameters = ls_control_param
*          mail_recipient     = ls_recipient
*          mail_sender        = ls_sender
*          output_options     = ls_composer_param
*          user_settings      = ' '
*          is_bil_invoice     = ls_bil_invoice
*          is_nast            = nast
*          is_repeat          = repeat
*        EXCEPTIONS
*          formatting_error   = 1
*          internal_error     = 2
*          send_error         = 3
*          user_canceled      = 4
*          OTHERS             = 5.
*      IF sy-subrc <> 0.
**     error handling
*        cf_retcode = sy-subrc.
*        PERFORM protocol_update.
**    get SmartForm protocoll and store it in the NAST protocoll
*        PERFORM add_smfrm_prot.
*      ENDIF.
*    ENDDO.
*    ls_composer_param-tdcopies = nast_anzal.
*    IF NOT nast_tdarmod IS INITIAL.
*      nast-tdarmod = nast_tdarmod.
*      CLEAR nast_tdarmod.
*    ENDIF.
*  ENDIF.
** get SmartForm protocoll and store it in the NAST protocoll
** PERFORM ADD_SMFRM_PROT.
*
ENDFORM.                    "processing
