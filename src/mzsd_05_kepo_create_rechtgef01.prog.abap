*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_CREATE_RECHTGEF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  CREATE_RECHTGEH
*&---------------------------------------------------------------------*
*       Erstellt Formular für Rechtliches gehör, entsprechend dem
*       vergehen. Gleichzeitig wird ein Verfügungsentwurf erstellt.
*----------------------------------------------------------------------*
* Änderungsprotokoll
*
* IDTZI, 11.11.2013
* Fehlerhandling eingefügt
* - Fehlende Auftragsnummer
* - Fehlendes Verfügungsdatum
* Code aufgeräumt
* - Datendefinition nach oben
* - Fehlerhandling nach unten
* - Konstanten True und False eingefügt
* IDTZI 27.02.2014
* - Popup zum speichern vor Dokumenterstellung eingefügt
* - Texte T32 und T33 erstellt.
* -
*----------------------------------------------------------------------*

FORM create_rechtgeh .


  "************************** Datendefinition ***************************
  DATA: lv_maxnr       TYPE integer,                  "Laufnummer (Max)
        lv_maxnrs      LIKE TABLE OF lv_maxnr,       "Laufnummer (Sammlung)
        ls_vbpa        LIKE vbpa,                      "
        kna1           LIKE kna1,                         "
        knvk           LIKE knvk,                         "
        ukopfdaten     LIKE zsdtkpsmartform,        "Kopfdaten für Smartforms
        sipe           TYPE string,                       "Signierende Person
        error          TYPE char1,                       "Fehler Flag
        output_options TYPE ssfctrlop,          "Druckoptionen (Smartforms)
        error_text     TYPE string.                 "Fehlertext

*Constants
  DATA: lc_true  TYPE char1,                     "True (X)
        lc_false TYPE char1.                    "False ( )

  lc_true = 'X'.
  lc_false = ''.
  "************************** Abfrage zur Speicherung bevor etwas gemacht wird ***************
  DATA ld_answer TYPE char1.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar              = TEXT-t33
      text_question         = TEXT-t32
      text_button_1         = TEXT-p90 "Ja
      text_button_2         = TEXT-p91 "Nein
      default_button        = '1'
      display_cancel_button = 'X'
    IMPORTING
      answer                = ld_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CASE ld_answer.
    WHEN '1'.
      "    PERFORM save_data USING c_false
      "                           c_false.
    WHEN '2'.
      EXIT.
    WHEN 'A'.
  ENDCASE.

  "************************** Datenselektion, Grunddaten festlegen ***************************
  "Selektiere höchste nummer.
  DATA kv LIKE kepo_ver.
  SELECT * FROM zsd_05_kepo_ver INTO kv ORDER BY ver_nr ASCENDING.
    lv_maxnr = kv-ver_nr.
  ENDSELECT.
  "Rg_nummer
  gs_rege-ver_nr = lv_maxnr + 1."max+1
  "Geschäftsjahr.
  gs_rege-gjahr = gs_kepo-gjahr.
  "Debitor
  gs_rege-debitor = gs_kepo-kunnr.
  "Angelegt von
  gs_rege-ver_anvo = sy-uname.
  "angelegt am Datum und Zeit
  gs_rege-ver_andat = sy-datum.                 "GUI Angelegt am
  gs_rege-ver_anvo_time = sy-uzeit.             "GUI Angelegt Zeit
  gs_rege-ver_anvo = sy-uname.                  "GUI Sachbearbeiter
  gs_rege-ver_nr = gs_rege-ver_nr.             "GUI Verwarnungsnummer
  "Bemerkung
  gs_kepo-bem_rege = gs_rege-bem.

  CASE ld_answer.
    WHEN '1'.
      PERFORM save_data USING c_false
                              c_false.
    WHEN '2'.
      EXIT.
    WHEN 'A'.
  ENDCASE.

  "************************** Formparam. UKOPFDATEN befüllen ***************************
* suchen Kunde

  SELECT SINGLE * FROM kna1 INTO kna1
    WHERE kunnr EQ gs_kepo-kunnr .
  IF sy-subrc NE 0.
    EXIT.  "Exit wenn kein Kunde gefunden.
  ENDIF.

* suchen Vorname Nachname
  CLEAR knvk.
  SELECT SINGLE * FROM knvk
    WHERE kunnr = kna1-kunnr.

* füllen übergabestrukturen
  CLEAR ukopfdaten.
  ukopfdaten-adrnr    = kna1-adrnr.
  ukopfdaten-fallnr   = gs_kepo-fallnr.
  ukopfdaten-datum    = gs_rege-ver_datum.
  ukopfdaten-funddat  = gs_kepo-fdat.
  "  ukopfdaten-funzeit  =
  ukopfdaten-kreis    = gs_kepo-kreis.
  ukopfdaten-fart     = gs_kepo-fart.
  WRITE gs_kepo-fuzei TO ukopfdaten-funzeit USING EDIT MASK  '__:__'.

  ukopfdaten-sachb1 = gs_kepo-signpers.

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

  "************************** Formparam UDOKUMENTE ***************************
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

    "Falls keine Bezeichnung, ziehe sie
    IF zsdtkpdocpos-bezei = ' '.
      SELECT bezei FROM zsdtkpdocart INTO zsdtkpdocpos-bezei
        WHERE docart = zsdtkpdocpos-docart
          AND spras  = 'DE'.
        udokumente-doktxt = zsdtkpdocpos-bezei.
      ENDSELECT.
    ENDIF.
    APPEND udokumente.
  ENDSELECT.

  "************************** Aufbau der Dokumentenliste (Gefundene Dokumente) ***************************
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


  "************************** Positionsdaten inkl. deren Berechnung ***************************
  DATA ls_pos_aus TYPE zsd_05_kepo_ver_pos.
  DATA lt_pos_aus TYPE TABLE OF zsd_05_kepo_ver_pos.
  DATA ls_pos_aus_head TYPE zsd_05_kepo_ver_pos.

  DATA ls_posdaten TYPE zsdtkpmatpos.
  DATA lt_posdaten TYPE TABLE OF zsdtkpmatpos.

  SELECT * FROM zsdtkpmatpos INTO ls_posdaten WHERE fallnr = gs_kepo-fallnr AND gjahr = gs_kepo-gjahr.

    ls_pos_aus-posnr = ls_posdaten-posnr.
    ls_pos_aus-bez = ls_posdaten-bezei.
    ls_pos_aus-menge = ls_posdaten-anzahl.

    "Preispro Definieren Pro position.
    CASE ls_posdaten-matnr.
      WHEN '8500292'.                         "Aufwandgebühr (1.Std.) -                80.-
        ls_pos_aus-preispro = '80.00'.
      WHEN '8500381'.                         "Grobsperrgut brennbar / Wilde Deponie - 65.06.-
        ls_pos_aus-preispro = '60.19'.  "neu ab 09.2016
*        ls_pos_aus-preispro = '65.06'.
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


    APPEND ls_pos_aus TO lt_pos_aus.

  ENDSELECT.

  ls_pos_aus_head-mwst = ( ls_pos_aus_head-total_exkl / 100 ) * 8.
  "Berechne total inklusive
  ls_pos_aus_head-total_inkl = ls_pos_aus_head-total_exkl + ls_pos_aus_head-mwst.
  "************************** Formularauswahl ***************************
  DATA kreis TYPE string.
  DATA fart TYPE string.
  DATA vfart TYPE string.
  DATA rechtgehform TYPE char30.
  DATA verentform TYPE char30.

  verentform = 'ZSD_05_KEPO_V_'.
  rechtgehform = 'ZSD_05_KEPO_RG_'.

  DATA fm_name TYPE  rs38l_fnam.

  IF gs_kepo-fart = 01. "Blaue Kehrrichtsäcke
    fart = 'B_'.
    vfart = 'B'.
  ELSEIF gs_kepo-fart = 02 OR gs_kepo-fart = 05. "Schwarze Kehrrichtsäcke
    fart = 'S'.
    vfart = 'S'.
  ELSEIF  gs_kepo-fart = 03 OR gs_kepo-fart = 06 OR gs_kepo-fart = 07. "Papier und Karton
    fart = 'PK_'.
    vfart = 'PK'.
  ELSEIF gs_kepo-fart = 04. "Wilde Deponie
    fart = 'WD'.
    vfart = 'WD'.
  ENDIF.

  IF  gs_kepo-fart = 06 OR gs_kepo-fart = 07. "Papier und Karton QES
    kreis = 'C'.
  ELSE.
    "Wenn nicht S (Schwarze Säcke) wird Kreis benötigt.
    IF fart NE 'S' AND fart NE 'WD'.
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

  CONCATENATE verentform vfart INTO verentform.
  CONCATENATE rechtgehform fart kreis INTO rechtgehform.
  DATA signpers_verfuegungsentwurf TYPE char3 .
  DATA signpers_rechtliches_gehoer TYPE char3 .

  "Definiere Signierende Personen
  IF zsd_05_kp_signp-gposition IS INITIAL.    "Wenn keine Person in auswahl
    SELECT SINGLE id INTO signpers_verfuegungsentwurf FROM zsd_05_kp_sign WHERE fallnr = gs_kepo-fallnr AND gjahr = gs_kepo-gjahr AND typ = '02'. "Suche in DB (nehme ID)
    IF sy-subrc NE 0 OR signpers_verfuegungsentwurf IS INITIAL. "falls nicht gefunden oder ID ist initial
      signpers_verfuegungsentwurf = '003'. "Walter Matter "Setze fixe person
    ENDIF.
  ELSE. "Wenn person in auswahl
    signpers_verfuegungsentwurf = zsd_05_kp_signp-gposition. "Setze ausgewählte Person
  ENDIF.

  IF zsd_05_kp_signp-name IS INITIAL."wenn keine Person in auswahl
    SELECT SINGLE id INTO signpers_rechtliches_gehoer FROM zsd_05_kp_sign WHERE fallnr = gs_kepo-fallnr AND gjahr = gs_kepo-gjahr AND typ = '01'. "suche in DB (nehme ID)
    IF sy-subrc NE 0 OR signpers_rechtliches_gehoer IS INITIAL. "Falls nicht gefunden, oder ID ist initial
      signpers_rechtliches_gehoer = '001'. "Tamara Balsiger "Setze fixe Person
    ENDIF.
  ELSE. "Wenn person in auswahl
    signpers_rechtliches_gehoer = zsd_05_kp_signp-name. "setze ausgewählt
  ENDIF.
  DATA a TYPE string.
  "************************** Fehlerprüfungen ***************************
  "************************** IDTZI *************************** 11.11.2013

  IF gs_rege-ver_datum IS INITIAL.                                             "Kein Verfügungsdatum -> Fehler
    a = 'Bitte ein Versendedatum für Rechtliches Gehör angeben.'.
    error = lc_true.
    " elseif gs_auft-vbeln_a is initial.
    "  a = 'Zu diesem Fall besteht kein Auftrag, bitte Auftrag anlegen.'.              "Auftragsnummer fehlt -> Fehler
    " error = lc_true.
  ENDIF.

  "Fehlermeldung ausgeben.
  IF error EQ lc_true.
    MESSAGE e001(zz) WITH a.
  ENDIF.
  "************************** IDTZI ***************************




  "************************** Formularausgabe ***************************
  IF error EQ lc_false."Wenn keine Fehler
    output_options-no_dialog = 'X'. "Druckpopup unterdrücken.

    "Speichere Daten
    PERFORM save_data USING c_false
                            c_false.
    DATA ver_datum TYPE dats.
    IF gs_kepo-fart NE '02' AND gs_kepo-fart NE '04'.
      SELECT SINGLE ver_datum FROM zsd_05_kepo_ver INTO ver_datum WHERE fallnr = gs_kepo-fallnr AND typ = 'V'.

    ENDIF.

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
        verdat             = gs_verwarnung-ver_datum "sy-datum - gs_verwarnung-
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
        verdat             = gs_verwarnung-ver_datum
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
    gs_kepo-fstat = '02'.

  ENDIF.

ENDFORM.                    " CREATE_RECHTGEH
