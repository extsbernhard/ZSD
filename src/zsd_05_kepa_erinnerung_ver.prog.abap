*---------------------------------------------------------------------*
* Report  ZSD_05_KEPA_INFOGEHOER
*---------------------------------------------------------------------*
* Firma     : Stadtverwaltung Bern Informatikdienste
* Ersteller : 07.04.2016 / David Ricci
*---------------------------------------------------------------------*
* Beschreibung:
* Dieser Report dient dazu ein Benachrichitgungs-Email zu senden,
* wenn die 30 Tage nach Versand des rechtlichen Gehörs überschritten wurden.
* Dazu wird das Programm jeden Tag von einem Job gestartet.
*---------------------------------------------------------------------*
* Änderungen:
* TT.MM.JJJJ  Name / Firma
*
*---------------------------------------------------------------------*
REPORT zsd_05_kepa_info_verfuegung.

* ------ Tabellendefinitionen       (TABLES)
TABLES: zsdtkpkepo.

* ------ Typendefinitionen          (TYPES)
DATA: gt_kopfdaten_kepa  LIKE TABLE OF zsdtkpkepo.
DATA: text               TYPE bcsy_text.
DATA: note               TYPE bcsy_text.
DATA: subject            TYPE so_obj_des.
DATA: send_request       TYPE REF TO cl_bcs.
DATA: document           TYPE REF TO cl_document_bcs.
DATA: sender             TYPE REF TO cl_sapuser_bcs.
DATA: recipient          TYPE REF TO if_recipient_bcs.
DATA: bcs_exception      TYPE REF TO cx_bcs.
DATA: sent_to_all        TYPE os_boolean.
DATA: anz_er             TYPE i.
DATA: wa_date            TYPE sy-datum.

* ------ Konstantendefinitionen     (CONSTANTS)
CONSTANTS: email TYPE so_rec_ext  VALUE 'david.ricci@BERN.CH', " Für Testzwecke eigene Email, Standard -> kepa_admin.erb@BERN.CH
           user  TYPE sy-uname    VALUE 'DDIC'.

*---------------------------------------------------------------------*
* Selektionsbild                    (select-option / Parameters)
*---------------------------------------------------------------------*
PARAMETERS p_check TYPE c AS CHECKBOX DEFAULT ''.

DATA: BEGIN OF lw_rege,
        fallnr  TYPE zsdekpfallnr,
        gjahr   TYPE gjahr,
        verdat  TYPE fkdat,
        debitor TYPE kunnr,
        funddat TYPE zsdekpfdat,
      END OF lw_rege,
      lt_rege LIKE TABLE OF lw_rege.

IF p_check = 'X'.
*--- Zählt vom aktuellen Datum 30 Tage ab und gibt diese Datum zurück.
*    Nach diesem Datum wird im SELECT gefiltert um die passenden Fälle
*    zu bekommen.
*    Fälle bei welchen eine Verfügung versandt wurde werden ignoriert.
*---

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = sy-datum
      days      = 30
      months    = 0
      years     = 0
      signum    = '-'
    IMPORTING
      calc_date = wa_date.

  SELECT zsdtkpkepo~fallnr zsdtkpkepo~gjahr zsd_05_kepo_ver~ver_datum zsd_05_kepo_ver~debitor zsdtkpkepo~fdat
    FROM zsdtkpkepo
    INNER JOIN zsd_05_kepo_ver ON                       " Tabelle für Verwarnungen
        zsdtkpkepo~fallnr = zsd_05_kepo_ver~fallnr AND
        zsdtkpkepo~gjahr = zsd_05_kepo_ver~gjahr
    INTO TABLE lt_rege
    WHERE                                               " Versanddatum ist heute - 30 Tage, Typ 'Rechtliches Gehör'
    ( zsd_05_kepo_ver~ver_datum = wa_date AND zsd_05_kepo_ver~typ = 'R' ) AND
    NOT EXISTS
    ( SELECT vbeln_f FROM zsdtkpauft                    " Es darf nich bereits ein Verfügung bestehen
      WHERE zsdtkpkepo~fallnr = zsdtkpauft~fallnr AND zsdtkpkepo~gjahr = zsdtkpauft~gjahr ).

  IF lt_rege IS NOT INITIAL.
    PERFORM send_info.
  ELSE.
    WRITE 'Kein Versand von Verfügungen nötig.'.
  ENDIF.

ENDIF.


FORM send_info.

  TRY.
*     -------- HTML und Text zusammensetzen ------------------------

      DESCRIBE TABLE lt_rege LINES anz_er.

      DATA: fall TYPE string,
            fallnr TYPE string,
            gjahr  TYPE string,
            intro  TYPE string,
            datum  TYPE c LENGTH 10.

      WRITE sy-datum USING EDIT MASK '__.__.____' TO datum.
      CONCATENATE: 'Fälligkeit Verfügungen vom' datum INTO subject SEPARATED BY space.

      IF anz_er = 1.
        intro = 'Folgende Verfügung ist fällig:'.
      ELSE.
        intro = 'Folgende Verfügungen sind fällig:'.
      ENDIF.

      APPEND '<p><span style="font-size:14px;"><span style="font-family:lucida sans unicode,lucida grande,sans-serif;">' TO text.
      APPEND intro TO text.
      APPEND '<br /><br /> ' TO text.

      LOOP AT lt_rege INTO lw_rege.
        WRITE lw_rege-funddat USING EDIT MASK '__.__.____' TO datum.

        SHIFT lw_rege-fallnr LEFT DELETING LEADING '0'.
        SHIFT lw_rege-debitor LEFT DELETING LEADING '0'.

        CONCATENATE lw_rege-fallnr lw_rege-gjahr INTO fallnr SEPARATED BY '-'.

        CONCATENATE 'Fallnummer:'   fallnr '<br />'
                    'Debitor:'      lw_rege-debitor '<br />'
                    'Funddatum: '   datum           '<br />' INTO fall SEPARATED BY space.

        APPEND fall TO text.
        APPEND '_________________________________________</p>' TO text. "<span style="font-size: 14px;">
      ENDLOOP.

      APPEND '<br />Freundliche Grüsse <br /> Kehrichtpatrouille Verfügungserinnerung </span>' TO text.


*     -------- create persistent send request ------------------------
      send_request = cl_bcs=>create_persistent( ).

*     -------- create and set document -------------------------------
      document = cl_document_bcs=>create_document(
                      i_type    = 'htm'
                      i_text    = text
                      i_subject = subject ).

*     add document to send request
      CALL METHOD send_request->set_document( document ).

*     --------- set sender -------------------------------------------
*     note: this is necessary only if you want to set the sender
*           different from actual user (SY-UNAME). Otherwise sender is
*           set automatically with actual user.

      sender = cl_sapuser_bcs=>create( user ). "sy-uname
      CALL METHOD send_request->set_sender
        EXPORTING
          i_sender = sender.

*     --------- add recipient (e-mail address) -----------------------
      recipient = cl_cam_address_bcs=>create_internet_address( 'kepa_admin.erb@BERN.CH' ). " 'david.ricci@bern.ch' für Tests 'kepa_admin.erb@BERN.CH' für Produktion

*     add recipient with its respective attributes to send request
      CALL METHOD send_request->add_recipient
        EXPORTING
          i_recipient = recipient
          i_express   = 'X'.

*     set that you don't need a Return Status E-mail
      DATA: status_mail TYPE bcs_stml.
      status_mail = 'N'.
      CALL METHOD send_request->set_status_attributes
        EXPORTING
          i_requested_status = status_mail
          i_status_mail      = status_mail.

      CALL METHOD send_request->set_send_immediately( 'X' ).

*     ---------- send document ---------------------------------------
      CALL METHOD send_request->send(
        EXPORTING
          i_with_error_screen = 'X'
        RECEIVING
          result              = sent_to_all ).
      IF sent_to_all = 'X'.
        WRITE text-003.
        WRITE 'Email erfolgreich versendet.'.
      ENDIF.

      COMMIT WORK.

* -----------------------------------------------------------
* *                     exception handling
* -----------------------------------------------------------
* * replace this very rudimentary exception handling
* -----------------------------------------------------------
    CATCH cx_bcs INTO bcs_exception.
      WRITE: text-001.
      WRITE: text-002, bcs_exception->error_type.
      EXIT.

  ENDTRY.

ENDFORM.                    "main
