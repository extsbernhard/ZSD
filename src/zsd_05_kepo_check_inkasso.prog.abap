*---------------------------------------------------------------------*
* Report  ZSD_05_KEPO_CHECK_INKASSO
*
*---------------------------------------------------------------------*
* Verarbeitung der Inkassodaten (Fallverwaltung Kehrichtpolizei)
*
*---------------------------------------------------------------------*

REPORT  zsd_05_kepo_check_inkasso.

*_____Datendefinitionen_____

TABLES: zsdtkpkepo.

DATA: lt_kepo TYPE TABLE OF zsdtkpkepo,
      ls_kepo TYPE          zsdtkpkepo.

DATA: lt_return  TYPE bapiret2_t,
      lt_log_exp TYPE bapiret2_t,
      lt_mail_msg TYPE bapiret2_t,
      ls_mail_msg TYPE bapiret2,

      ld_log TYPE flag.

DATA: go_services TYPE REF TO cl_gui_frontend_services.


"E-Mailobjekte
DATA: ls_doc_data TYPE sodocchgi1,
      lt_obj_cont TYPE STANDARD TABLE OF solisti1,
      ls_obj_cont TYPE solisti1,
      lt_receiv TYPE STANDARD TABLE OF somlreci1,
      ls_receiv TYPE somlreci1,
      ld_receiv TYPE char50.


*_____Konstanten_____
CONSTANTS: c_rec_type TYPE so_escape VALUE 'U'. "Email-/Internet-Adresse
CONSTANTS: c_obj_name TYPE so_obj_nam VALUE 'NOTICE'. "Dokumentenname
CONSTANTS: c_obj_desc TYPE so_obj_des VALUE 'Fallverwaltung Kehrichtpolizei (Inkasso)'. "Beschreibung
CONSTANTS: c_obj_prio TYPE so_obj_pri VALUE '1'. "Dokumentenpriorität
CONSTANTS: c_priority TYPE so_rec_pri VALUE '1'. "Priorität


*_____Selektionsbild_____

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE text-bl1.

SELECT-OPTIONS: so_fnr   FOR zsdtkpkepo-fallnr,
                so_gjahr FOR zsdtkpkepo-gjahr.

SELECTION-SCREEN END OF BLOCK bl1.

SELECTION-SCREEN BEGIN OF BLOCK bl2 WITH FRAME TITLE text-bl2.
PARAMETERS:   p_chkall TYPE flag,
              p_knrold TYPE flag,
              p_test   TYPE flag DEFAULT 'X'.
SELECTION-SCREEN SKIP.
PARAMETERS:   p_mahns TYPE mahns_d DEFAULT 3.
SELECTION-SCREEN SKIP.
*PARAMETERS:   p_log    TYPE flag DEFAULT 'X'.
PARAMETERS:   p_log_fn TYPE text200.
SELECTION-SCREEN SKIP.
SELECT-OPTIONS: so_rec FOR ld_receiv NO INTERVALS.

SELECTION-SCREEN END OF BLOCK bl2.



AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_log_fn .
  PERFORM save_fname CHANGING p_log_fn .



*_____Auswertung_____

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  IF p_chkall EQ 'X'.
    SELECT * FROM zsdtkpkepo INTO TABLE lt_kepo
      WHERE fallnr IN so_fnr
        AND gjahr  IN so_gjahr
        AND fstat  NE '04'. "ist nicht annulliert

  ELSE.
    SELECT * FROM zsdtkpkepo INTO TABLE lt_kepo
      WHERE fallnr IN so_fnr
      AND gjahr  IN so_gjahr
      AND fstat  NE '03'  "ist nicht erledigt
      AND fstat  NE '04'. "ist nicht annulliert
  ENDIF.

  CLEAR: lt_log_exp[], lt_obj_cont[], ld_log.

  IF NOT p_log_fn IS INITIAL.
    ld_log = 'X'.
  ENDIF.

  LOOP AT lt_kepo INTO ls_kepo.

    CLEAR: lt_return[], lt_mail_msg[].

    CALL FUNCTION 'ZSDFBKP_CHECK_INKASSO'
      EXPORTING
        i_fallnr          = ls_kepo-fallnr
        i_gjahr           = ls_kepo-gjahr
        i_ext             = 'X'
        i_test            = p_test
        i_checkall        = p_chkall
        i_check_kunnr_old = p_knrold
        i_check_mahns     = p_mahns
        i_log             = ld_log
      IMPORTING
        et_return         = lt_return
        et_mail_msg       = lt_mail_msg.

    IF NOT lt_return[] IS INITIAL.
      APPEND LINES OF lt_return TO lt_log_exp.
    ENDIF.

    IF NOT lt_mail_msg[] IS INITIAL.
      LOOP AT lt_mail_msg INTO ls_mail_msg.
        CLEAR: ls_obj_cont.
        ls_obj_cont-line = ls_mail_msg-message.
        APPEND ls_obj_cont TO lt_obj_cont.
      ENDLOOP.
    ENDIF.


  ENDLOOP.

  IF NOT p_log_fn IS INITIAL.
    PERFORM save_file USING p_log_fn
                            lt_log_exp.
  ENDIF.


  "E-Mail versenden, wenn Content und Empfänger vorhanden sind
  IF NOT lt_obj_cont[] IS INITIAL AND NOT so_rec[] IS INITIAL.
    ls_doc_data-obj_name = c_obj_name.

    ls_doc_data-obj_descr = c_obj_desc.
    ls_doc_data-obj_langu = sy-langu.
    ls_doc_data-obj_prio  = c_obj_prio.
    ls_doc_data-priority  = c_priority.

    CLEAR: ls_receiv, lt_receiv[].
    LOOP AT so_rec.
      ls_receiv-receiver = so_rec-low.
      ls_receiv-rec_type = c_rec_type.
      APPEND ls_receiv TO lt_receiv.
    ENDLOOP.


    CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1'
      EXPORTING
        document_data                    = ls_doc_data
       document_type                    = 'RAW'
*         PUT_IN_OUTBOX                    = ' '
       commit_work                      = 'X'
*       IMPORTING
*         SENT_TO_ALL                      =
*         NEW_OBJECT_ID                    =
      TABLES
*         OBJECT_HEADER                     =
       object_content                   = lt_obj_cont
*         CONTENTS_HEX                     =
*         OBJECT_PARA                      =
*         OBJECT_PARB                      =
        receivers                        = lt_receiv
     EXCEPTIONS
       too_many_receivers               = 1
       document_not_sent                = 2
       document_type_not_exist          = 3
       operation_no_authorization       = 4
       parameter_error                  = 5
       x_error                          = 6
       enqueue_error                    = 7
       OTHERS                           = 8
              .
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      "Sendeprozess für Internet-Mail starten
      SUBMIT rsconn01
      WITH mode = 'INT'
      AND RETURN.
    ENDIF.


  ENDIF.



*_____Forms_____

*&---------------------------------------------------------------------*
*&      Form  SAVE_FNAME
*&---------------------------------------------------------------------*
*       Logpfad/-dateiname definieren
*----------------------------------------------------------------------*
FORM save_fname  CHANGING cd_log_fn.


  DATA: lt_filetable TYPE STANDARD TABLE OF file_table .
  DATA: ls_filetable TYPE                   file_table .

  DATA: lv_rc     TYPE i .
  DATA: lv_action TYPE i,
        lv_fname  TYPE string,
        lv_fpath  TYPE string,
        lv_fullp  TYPE string,
        lv_date   TYPE sy-datum.


  "Erstelle Objekt für Frontend-Services
  CREATE OBJECT go_services.


  CLEAR lt_filetable. REFRESH lt_filetable .
  CLEAR lv_action.
  CLEAR lv_fname.

  lv_date = sy-datum.

  CONCATENATE lv_date 'LOG_KEPO_CHECK_INKASSO' sy-uname INTO lv_fname SEPARATED BY '_'.
  MOVE 'C:\TEMP\' TO lv_fpath.

  CONCATENATE lv_fpath lv_fname INTO lv_fullp.


  go_services->file_save_dialog(
    EXPORTING
      window_title         = 'LOG-Datei speichern unter...'
      default_extension    = 'TXT'
      default_file_name    = lv_fullp
*      with_encoding        =
*      file_filter          =
*      initial_directory    =
      prompt_on_overwrite  = 'X'
    CHANGING
      filename             = lv_fname
      path                 = lv_fpath
      fullpath             = lv_fullp
*      user_action          = lv_action
*      file_encoding        =
    EXCEPTIONS
      cntl_error           = 1
      error_no_gui         = 2
      not_supported_by_gui = 3
      OTHERS               = 4 ).

  cd_log_fn = lv_fullp.


  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.                    " SAVE_FNAME


*&---------------------------------------------------------------------*
*&      Form  SAVE_FILE
*&---------------------------------------------------------------------*
*       Datei speichern
*----------------------------------------------------------------------*
FORM save_file USING uv_fname
                     ut_log.

  DATA: lv_fname TYPE string.

  CREATE OBJECT go_services.

  lv_fname = uv_fname.

  go_services->gui_download(
  EXPORTING
    filename                  = lv_fname
      write_field_separator     = 'X'
  CHANGING
    data_tab                  = ut_log
    EXCEPTIONS
      file_write_error          = 1
      no_batch                  = 2
      gui_refuse_filetransfer   = 3
      invalid_type              = 4
      no_authority              = 5
      unknown_error             = 6
      header_not_allowed        = 7
      separator_not_allowed     = 8
      filesize_not_allowed      = 9
      header_too_long           = 10
      dp_error_create           = 11
      dp_error_send             = 12
      dp_error_write            = 13
      unknown_dp_error          = 14
      access_denied             = 15
      dp_out_of_memory          = 16
      disk_full                 = 17
      dp_timeout                = 18
      file_not_found            = 19
      dataprovider_exception    = 20
      control_flush_error       = 21
      not_supported_by_gui      = 22
      error_no_gui              = 23
      OTHERS                    = 24
       ).
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.                    " SAVE_FILE
