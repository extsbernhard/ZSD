*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_F01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  Create_Verwarnung
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_verwarnung .

data ukopfdaten like zsdtkpsmartform.
data falldaten like zsdtkpkepo.
  "Problem, bei Fehlern wird das ganze bild gesperrt.
"Dieses Problem wird hier für den Fall dass die zu signierende Person (Verwarnung)
"nicht gesetzt ist, wird eine fehlermeldung ausgegeben, das bild darf jedoch nicht gesperrt werden.
data flag type char1.
             data text type string.
"IDTZI 07.01.2014
  if gs_kepo-fwdh is initial. "Falls es KEINE Wiederholung ist
    "prüfe ob Unterschrift für Verwarnung gesetzt ist
    clear: text, flag.
    if gs_kepo-signpers is initial. "wenn keine person gesetzt


      text = 'Bitte geben Sie eine Unterschriftsberechtigte Person für die Verwarnung an.' .
      flag = 'X'.
      message text type 'E' .
      elseif gs_kepo-marbkp is initial. "wenn kein Sachbearbeiter Gesetzt

        text = 'Bitte geben Sie ein/e Sachbearbeiter/in an.'.
        flag = 'X'.
        message text type 'E'.
        endif.

        "Falls eine der Fehlermeldung
        if flag = 'X'.
LOOP AT SCREEN.    "Mache nichts, aber lasse felder offen.
        IF screen-group1 = 'ROY'.
        screen-input = 1.
      ENDIF.
      IF screen-group2 = 'UPD'.
        screen-input = 1.
      ENDIF.
      modify screen.
    endloop.
      endif.
      endif.
  tables zsd_05_kepo_ver.

kepo_ver-fallnr = gs_kepo-FALLNR.

  "Suche folgenummer
  data maxnr type integer.
  data maxnrs like table of maxnr.
  select * from zsd_05_kepo_ver into kepo_ver ORDER BY ver_nr ASCENDING.
    maxnr = kepo_ver-ver_nr.
    ENDSELECT.
  "Verwarnungsnummer
  kepo_ver-ver_nr = maxnr + 1."max+1

  "Geschäftsjahr.
  kepo_ver-gjahr = gs_kepo-gjahr.

  "Debitor
  kepo_ver-debitor = gs_kepo-kunnr.

  "Verwarnungsdatum
  kepo_ver-ver_datum = gs_verwarnung-ver_datum.

  "Angelegt von
  kepo_ver-ver_anvo = sy-uname.


  "angelegt am Datum und Zeit
  kepo_ver-ver_andat = sy-datum.
  kepo_ver-ver_anvo_time = sy-UZEIT.

  gs_verwarnung-ver_andat = sy-datum.                 "GUI Angelegt am
  gs_verwarnung-ver_anvo_time = sy-uzeit.             "GUI Angelegt Zeit
  gs_verwarnung-ver_anvo = sy-uname.                  "GUI Sachbearbeiter
  gs_verwarnung-ver_nr = kepo_ver-ver_nr.             "GUI Verwarnungsnummer

  "Bemerkung  -> neu wird bemerkung zum Fall gespeichert und nicht zum Dokument (in diesem Fall die Verwarnung)
  gs_kepo-bem_verwarnung = gs_verwarnung-bem.
  PERFORM save_data USING c_false
                              c_false.

"------------------------------------------------- ukopfdaten aus säschus Programm

data: ls_vbpa like vbpa.
data kna1 like kna1.
data knvk like knvk.


data sipe type string.
*setze SAchbearbeiter (Unterschrift)



* suchen Kunde

    SELECT SINGLE * FROM kna1 into kna1
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
  ukopfdaten-fallnr   = gs_kepo-FALLNR.
  ukopfdaten-datum    = gs_verwarnung-ver_datum.
  ukopfdaten-funddat  = gs_kepo-FDAT.
  ukopfdaten-datum = gs_verwarnung-ver_datum.
"  ukopfdaten-funzeit  =
  ukopfdaten-kreis    = gs_kepo-KREIS.
  ukopfdaten-fart     = gs_kepo-fart.
  WRITE gs_kepo-FUZEI TO ukopfdaten-funzeit USING EDIT MASK  '__:__'.

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

data izsdtkpkepo like zsdtkpkepo.


  SELECT SINGLE * FROM zsdtkpkepo INTO izsdtkpkepo
    WHERE fallnr = gs_kepo-fallnr
     AND  gjahr  =  gs_kepo-gjahr.
"Setze Status auf "ERLEDIGT"
izsdtkpkepo-fstat = '03'.
modify zsdtkpkepo FROM izsdtkpkepo.

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

  tables: zsdtkpdocpos.

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

data save_tabix like sy-tabix.
DESCRIBE TABLE udokumente lines save_tabix.
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









  "Entscheide welches Formular genommen wird:

  data kreis type string.
  data fart type string.
  data formname type char30.
  formname = 'ZSD_05_KEPO_VER_'.
data fm_name type  RS38L_FNAM.

  "unterscheide Fallart
       IF gs_kepo-fart = 01. "Blaue Kehrrichtsäcke
        fart = 'B_'.
       elseif  gs_kepo-fart = 03. "Papier und Karton
        fart = 'PK_'.
      endif.

  "Unterscheide Kreis
  case gs_kepo-kreis.
    when 'A' or 'B'.
       kreis = 'AB'.
    when 'C'.
      kreis = 'C'.
    when others.
      "nichts
   endcase.

"Baue Formularnamen
  CONCATENATE formname fart kreis into formname.





   data a type string.
 a =  'Nur für Papier/Karton und Blaue Kehrrichtsäcke.'.
  if gs_kepo-fart ne 01 and gs_kepo-fart ne 03.
    MESSAGE E001(zz) with a." type 'A'.

    else.

gs_kepo-fstat = '03'.

   call function 'SSF_FUNCTION_MODULE_NAME'
  exporting
    formname                 = formname
*   VARIANT                  = ' '
*   DIRECT_CALL              = ' '
  IMPORTING
    FM_NAME                  = FM_NAME
  EXCEPTIONS
    NO_FORM                  = 1
    NO_FUNCTION_MODULE       = 2
    OTHERS                   = 3.


call function FM_NAME
 EXPORTING
*   ARCHIVE_INDEX              =
*   ARCHIVE_INDEX_TAB          =
*   ARCHIVE_PARAMETERS         =
*   CONTROL_PARAMETERS         =
*   MAIL_APPL_OBJ              =
*   MAIL_RECIPIENT             =
*   MAIL_SENDER                =
*   OUTPUT_OPTIONS             =
*   USER_SETTINGS              = 'X'
    UKOPFDATEN                 =  ukopfdaten
    kp                         = zsdtkpkepo
    Verwarnung                 = gs_verwarnung

* IMPORTING
*   DOCUMENT_OUTPUT_INFO       =
*   JOB_OUTPUT_INFO            =
*   JOB_OUTPUT_OPTIONS         =
  "TABLES

  EXCEPTIONS
    FORMATTING_ERROR           = 1
    INTERNAL_ERROR             = 2
    SEND_ERROR                 = 3
    USER_CANCELED              = 4
    OTHERS                     = 5.

endif.




ENDFORM.                    " Create_Verwarnung
