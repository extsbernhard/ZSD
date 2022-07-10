*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_SHOW_RECHTGEHF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  SHOW_RECHTGEH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_rechtgeh .
  "  tables zsd_05_gs_rege.
  DATA maxnr TYPE string.
  "Rg_nummer
  gs_rege-ver_nr = maxnr + 1."max+1

  "Geschäftsjahr.
  gs_rege-gjahr = gs_kepo-gjahr.

  "Debitor
  gs_rege-debitor = gs_kepo-kunnr.

  "Rechtliches Gehör Datum
  gs_rege-ver_datum = gs_verwarnung-ver_datum.

  "Angelegt von
  gs_rege-ver_anvo = sy-uname.


  "angelegt am Datum und Zeit
  gs_rege-ver_andat = sy-datum.
  gs_rege-ver_anvo_time = sy-uzeit.

  gs_verwarnung-ver_andat = sy-datum.                 "GUI Angelegt am
  gs_verwarnung-ver_anvo_time = sy-uzeit.             "GUI Angelegt Zeit
  gs_verwarnung-ver_anvo = sy-uname.                  "GUI Sachbearbeiter
  gs_verwarnung-ver_nr = gs_rege-ver_nr.             "GUI Verwarnungsnummer

  "Bemerkung
  gs_rege-bem = gs_verwarnung-bem.

  "------------------------------------------------- ukopfdaten aus säschus Programm

  DATA: ls_vbpa LIKE vbpa.
  DATA kna1 LIKE kna1.
  DATA knvk LIKE knvk.
  DATA ukopfdaten LIKE zsdtkpsmartform.

  DATA sipe TYPE string.
*setze SAchbearbeiter (Unterschrift)



* suchen Kunde

  SELECT SINGLE * FROM kna1 INTO kna1
    WHERE kunnr EQ gs_kepo-kunnr .


  IF sy-subrc NE 0.
    EXIT.
  ENDIF.


* suchen Vorname Nachname
  CLEAR knvk.
  SELECT SINGLE * FROM knvk
    WHERE kunnr = kna1-kunnr.


* füllen übergabestrukturen
  CLEAR ukopfdaten.
  ukopfdaten-adrnr    = kna1-adrnr.
  ukopfdaten-fallnr   = gs_kepo-fallnr.
  ukopfdaten-datum    = gs_verwarnung-ver_datum.
  ukopfdaten-funddat  = gs_kepo-fdat.
  "  ukopfdaten-funzeit  =
  ukopfdaten-kreis    = gs_kepo-kreis.
  ukopfdaten-fart     = gs_kepo-fart.
  WRITE gs_kepo-fuzei TO ukopfdaten-funzeit USING EDIT MASK  '__:__'.

  ukopfdaten-sachb1 = gs_kepo-signpers.
  "select single name from zsdtkpmarb into ukopfdaten-sachb1 where marb = gs_kepo-signpers.



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

  DATA izsdtkpkepo LIKE zsdtkpkepo.


  SELECT SINGLE * FROM zsdtkpkepo INTO izsdtkpkepo
    WHERE fallnr = gs_kepo-fallnr
     AND  gjahr  =  gs_kepo-gjahr.


  "Fundadresse
  CONCATENATE izsdtkpkepo-street
              izsdtkpkepo-house_num1
         INTO ukopfdaten-funadr SEPARATED BY ' '.
  CONCATENATE ukopfdaten-funadr ','
         INTO ukopfdaten-funadr.
  CONCATENATE ukopfdaten-funadr
              izsdtkpkepo-post_code1
              izsdtkpkepo-city1
         INTO ukopfdaten-funadr SEPARATED BY ' '.
  "---------------------------------------------------
  "Dokumente

  "tables: zsdtkpdocpos.

  "  *Struktur zu Dokumente
  DATA: BEGIN OF udokumente OCCURS 0.
      INCLUDE STRUCTURE zsdtkpsmartform.
  DATA: END OF udokumente.
  "Selektiere Dokumentpositionen nach Jahr und Fallnummer
  SELECT * FROM zsdtkpdocpos
    WHERE fallnr = gs_kepo-fallnr
      AND gjahr  = gs_kepo-gjahr.

    udokumente-dokanz = zsdtkpdocpos-anzahl.
    udokumente-dokart = zsdtkpdocpos-docart.
    udokumente-doktxt = zsdtkpdocpos-bezei.

    "Falls keine Bezeuchnung, ziehe sie
    IF zsdtkpdocpos-bezei = ' '.
      SELECT bezei FROM zsdtkpdocart INTO zsdtkpdocpos-bezei
        WHERE docart = zsdtkpdocpos-docart
          AND spras  = 'DE'.
        udokumente-doktxt = zsdtkpdocpos-bezei.
      ENDSELECT.
    ENDIF.
    APPEND udokumente.
  ENDSELECT.

  DATA save_tabix LIKE sy-tabix.
  DESCRIBE TABLE udokumente LINES save_tabix.
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


  "Positionen inkl berechnung
  DATA ls_pos_aus TYPE zsd_05_kepo_ver_pos.
  DATA lt_pos_aus TYPE TABLE OF zsd_05_kepo_ver_pos.
  DATA ls_pos_aus_head TYPE zsd_05_kepo_ver_pos.

  DATA ls_posdaten TYPE zsdtkpmatpos.
  DATA lt_posdaten TYPE TABLE OF zsdtkpmatpos.

  SELECT * FROM zsdtkpmatpos INTO ls_posdaten WHERE fallnr = gs_kepo-fallnr AND gjahr = gs_kepo-gjahr.

    ls_pos_aus-posnr = ls_posdaten-posnr.
    ls_pos_aus-bez = ls_posdaten-bezei.
    ls_pos_aus-menge = ls_posdaten-anzahl.
    ls_pos_aus-preispro = '80.00'.
    ls_pos_aus-leistungsart = ls_posdaten-vrkme.

    "Berechne preis * Menge
    ls_pos_aus-wert = ls_pos_aus-preispro * ls_pos_aus-menge.
    "Berechne Total Exklusiv Mehrwertsteuer
    "Total exklusiv + wert in Kopfzeile
    ls_pos_aus_head-total_exkl = ls_pos_aus_head-total_exkl + ls_pos_aus-wert . "100 = 0 + 100



    APPEND ls_pos_aus TO lt_pos_aus.

  ENDSELECT.
  "Berechne Mehrwertsteuer
  "Total Exkl. / 100 * 8
  DATA i_mwst TYPE p DECIMALS 2.
  i_mwst = '7.7'.

  ls_pos_aus_head-mwst = ( ls_pos_aus_head-total_exkl / 100 ) * i_mwst. "8.
  "Berechne total inklusive
  ls_pos_aus_head-total_inkl = ls_pos_aus_head-total_exkl + ls_pos_aus_head-mwst.





  "Entscheide welches Formular verwendet wird:
  DATA kreis TYPE string.
  DATA fart TYPE string.
  DATA vfart TYPE string.
  DATA rechtgehform TYPE char30.
  DATA verentform TYPE char30.

  verentform = 'ZSD_05_KEPO_V_'.
  rechtgehform = 'ZSD_05_KEPO_RG_'.

  DATA fm_name TYPE  rs38l_fnam.

  "unterscheide Fallart
  IF gs_kepo-fart = 01. "Blaue Kehrrichtsäcke
    fart = 'B_'.
    vfart = 'B'.
  ELSEIF gs_kepo-fart = 02. "Schwarze Kehrrichtsäcke
    fart = 'S'.
    vfart = 'S'.
  ELSEIF  gs_kepo-fart = 03. "Papier und Karton
    fart = 'PK_'.
    vfart = 'PK'.
    " MZi neue Fallarten
  ELSEIF gs_kepo-fart = 05. "Schwarze Kehrichtsäcke QES
    fart  = 'S'.
    vfart = 'S'.
  ELSEIF gs_kepo-fart = 06. "Papier/Karton QES
    fart  = 'PK_'.
    vfart = 'PK'.
  ELSEIF gs_kepo-fart = 07. "Papier/Karton Unzeit QES
    fart  = 'PK_'.
    vfart = 'PK'.
  ENDIF.

  "Wenn nicht S (Schwarze Säcke) Kein Kreis benötigt.
  IF fart NE 'S'.
    " MZi neue Fallarten kein Kreis nötig
    IF  gs_kepo-fart NE '06'
    AND gs_kepo-fart NE '07'.
      CASE gs_kepo-kreis.
        WHEN 'A' OR 'B'.
          kreis = 'AB'.
        WHEN 'C'.
          kreis = 'C'.
        WHEN OTHERS.
          "nichts
      ENDCASE.

    ENDIF.
  ENDIF.

  " MZi neue Fallarten Formular Kreis C nutzen (in Text Abfrage auf Fallart)
  IF gs_kepo-fart = '06'
  OR gs_kepo-fart = '07'.
    kreis = 'C'.
  ENDIF.


  CONCATENATE verentform vfart INTO verentform.
  CONCATENATE rechtgehform fart kreis INTO rechtgehform.

  DATA output_options TYPE ssfctrlop.
  output_options-no_dialog = 'X'. "Druckpopup unterdrücken.



  IF zsd_05_kp_signp-gposition IS INITIAL.
    DATA signpers_verfuegungsentwurf TYPE char3 .
    SELECT SINGLE id INTO signpers_verfuegungsentwurf FROM zsd_05_kp_sign WHERE fallnr = gs_kepo-fallnr AND gjahr = gs_kepo-gjahr AND typ = '02'.
    IF sy-subrc NE 0.
      signpers_verfuegungsentwurf = '003'. "Walter Matter
    ENDIF.
  ELSE.
    signpers_verfuegungsentwurf = zsd_05_kp_signp-gposition.
  ENDIF.
  IF zsd_05_kp_signp-name IS INITIAL.
    DATA signpers_rechtliches_gehoer TYPE char3 .
    SELECT SINGLE id INTO signpers_rechtliches_gehoer FROM zsd_05_kp_sign WHERE fallnr = gs_kepo-fallnr AND gjahr = gs_kepo-gjahr AND typ = '01'.
    IF sy-subrc NE 0.
      signpers_rechtliches_gehoer = '001'. "Tamara Balsiger
    ENDIF.
  ELSE.
    signpers_rechtliches_gehoer = zsd_05_kp_signp-name.
  ENDIF.


  DATA a TYPE string.
  a =  'Nur für Papier/Karton, Schwarze- und Blaue Kehrrichtsäcke.'.
  " MZi neze Fallarten
*  IF gs_kepo-fart NE 01 AND gs_kepo-fart NE 03 AND gs_kepo-fart NE 02.
  IF gs_kepo-fart NE 01 AND gs_kepo-fart NE 03 AND gs_kepo-fart NE 02 AND gs_kepo-fart NE 05 AND gs_kepo-fart NE 06 AND gs_kepo-fart NE 07.
    MESSAGE e001(zz) WITH a." type 'A'.

    .
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

  ELSE.
*    "Rechtliches Gehör
    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname           = rechtgehform
      IMPORTING
        fm_name            = fm_name
      EXCEPTIONS
        no_form            = 1
        no_function_module = 2
        OTHERS             = 3.


    CALL FUNCTION fm_name
      EXPORTING
        control_parameters = output_options
        ukopfdaten         = ukopfdaten
        verdat             = sy-datum
        signp              = signpers_rechtliches_gehoer
      EXCEPTIONS
        formatting_error   = 1
        internal_error     = 2
        send_error         = 3
        user_canceled      = 4
        OTHERS             = 5.
    CLEAR fm_name.
    "Verfügungsentwurf
    "Rechtliches Gehör
    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname           = verentform
      IMPORTING
        fm_name            = fm_name
      EXCEPTIONS
        no_form            = 1
        no_function_module = 2
        OTHERS             = 3.


    CALL FUNCTION fm_name
      EXPORTING
        control_parameters = output_options
        ukopfdaten         = ukopfdaten
        verdat             = gs_kepo-erdat
        uposkopf           = ls_pos_aus_head
        verfdat            = gs_rege-ver_datum
        kunnr              = gs_kepo-kunnr
        auftragsnummer     = gs_auft-vbeln_a
        signp              = signpers_verfuegungsentwurf
      TABLES
        uposdaten          = lt_pos_aus
      EXCEPTIONS
        formatting_error   = 1
        internal_error     = 2
        send_error         = 3
        user_canceled      = 4
        OTHERS             = 5.


  ENDIF.

ENDFORM.                    " SHOW_RECHTGEH
