*&---------------------------------------------------------------------*
*&  Include           ZSD_05_KEPO_MIG_TEXTE_F01
*&---------------------------------------------------------------------*
DATA: go_services TYPE REF TO cl_gui_frontend_services.

*&---------------------------------------------------------------------*
*&      Form  SAVE_FNAME
*&---------------------------------------------------------------------*
*       Vorbereitung Datei speichern...
*----------------------------------------------------------------------*
FORM save_fname  CHANGING cv_exp_fn.


  DATA: lt_filetable TYPE STANDARD TABLE OF file_table .
  DATA: ls_filetable TYPE                   file_table .

  DATA: lv_rc     TYPE i .
  DATA: lv_action TYPE i,
        lv_fname  TYPE string,
        lv_fpath  TYPE string,
        lv_fullp  TYPE string,
        lv_date   TYPE sy-datum,
        lv_time   TYPE sy-uzeit.


  CREATE OBJECT go_services.


  CLEAR lt_filetable. REFRESH lt_filetable .
  CLEAR lv_action.
  CLEAR lv_fname.

  lv_date = sy-datum.
  lv_time = sy-uzeit.

  CONCATENATE lv_date lv_time 'LOG_KEPO_MIG_TEXTE' sy-uname INTO lv_fname SEPARATED BY '_'.
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

  cv_exp_fn = lv_fullp.

*  CHECK lv_action NE '9' .

  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


ENDFORM.                    " SAVE_FNAME



*&---------------------------------------------------------------------*
*&      Form  SAVE_FILE
*&---------------------------------------------------------------------*
*       Speichern des Dokuments auf dem Client
*----------------------------------------------------------------------*
FORM save_file  USING uv_fname
                      ut_log.

  DATA: lv_fname TYPE string.

  CREATE OBJECT go_services.

  lv_fname = uv_fname.

  go_services->gui_download(
  EXPORTING
*      bin_filesize              =
    filename                  = lv_fname
*      filetype                  = 'ASC'
*      append                    = SPACE
      write_field_separator     = 'X'
*      header                    = '00'
*      trunc_trailing_blanks     = SPACE
*      write_lf                  = 'X'
*      col_select                = SPACE
*      col_select_mask           = SPACE
*      dat_mode                  = SPACE
*      confirm_overwrite         = SPACE
*      no_auth_check             = SPACE
*      codepage                  = SPACE
*      ignore_cerr               = ABAP_TRUE
*      replacement               = '#'
*      write_bom                 = SPACE
*      trunc_trailing_blanks_eol = 'X'
*      wk1_n_format              = SPACE
*      wk1_n_size                = SPACE
*      wk1_t_format              = SPACE
*      wk1_t_size                = SPACE
*      show_transfer_status      = 'X'
*      fieldnames                =
*      write_lf_after_last_line  = 'X'
*    IMPORTING
*      filelength                =
  CHANGING
    data_tab                  = ut_log
*    EXCEPTIONS
*      file_write_error          = 1
*      no_batch                  = 2
*      gui_refuse_filetransfer   = 3
*      invalid_type              = 4
*      no_authority              = 5
*      unknown_error             = 6
*      header_not_allowed        = 7
*      separator_not_allowed     = 8
*      filesize_not_allowed      = 9
*      header_too_long           = 10
*      dp_error_create           = 11
*      dp_error_send             = 12
*      dp_error_write            = 13
*      unknown_dp_error          = 14
*      access_denied             = 15
*      dp_out_of_memory          = 16
*      disk_full                 = 17
*      dp_timeout                = 18
*      file_not_found            = 19
*      dataprovider_exception    = 20
*      control_flush_error       = 21
*      not_supported_by_gui      = 22
*      error_no_gui              = 23
*      others                    = 24
       ).
  IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.




ENDFORM.                    " SAVE_FILE
*&---------------------------------------------------------------------*
*&      Form  GET_FNAME
*&---------------------------------------------------------------------*
*       Datei für den Import auswählen
*----------------------------------------------------------------------*
FORM get_fname  CHANGING cv_imp_fn.

  DATA: lt_filetable TYPE STANDARD TABLE OF file_table .
  DATA: ls_filetable TYPE                   file_table .

  DATA: ld_rc     TYPE i .
  DATA: ld_action TYPE i .

  CREATE OBJECT go_services.

  CLEAR lt_filetable. REFRESH lt_filetable .
  CLEAR ld_rc .
  CLEAR ld_action .


  go_services->file_open_dialog(
    EXPORTING
      window_title            = 'Importfile'
      initial_directory       = c_dir
    CHANGING
      file_table              = lt_filetable
      rc                      = ld_rc
      user_action             = ld_action
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5 ).

  CHECK ld_action NE '9' .

  READ TABLE lt_filetable INTO ls_filetable
                         INDEX 1 .
  CHECK sy-subrc EQ 0 .

  cv_imp_fn = ls_filetable-filename .


ENDFORM.                    " GET_FNAME



*&---------------------------------------------------------------------*
*&      Form  FILL_TAB_W_FILE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_tab_w_file USING uv_imp_fn
*                           uv_tabname
                           uv_septab
                  CHANGING ct_tab.

  DATA: ld_string     TYPE string,
        ld_splitter   TYPE c,
        ld_column     TYPE c LENGTH 8,
        cond_syntax   TYPE string,
        ld_filestring TYPE string.


*  FIELD-SYMBOLS: <fs_tab>   TYPE ANY TABLE,
*                 <fs_struc> TYPE ANY.
*
*  DATA: rt_import TYPE REF TO data,
*        rs_import TYPE REF TO data.
*
*  CREATE DATA rt_import TYPE STANDARD TABLE OF (uv_tabname).
*  ASSIGN rt_import->* TO <fs_tab>.
*
*  CREATE DATA rs_import TYPE (uv_tabname).
*  ASSIGN rs_import->* TO <fs_struc>.



  CREATE OBJECT go_services.

  ld_filestring = uv_imp_fn .
  TRANSLATE ld_filestring TO UPPER CASE .


  go_services->gui_upload(
    EXPORTING
      filename                = ld_filestring
*      filetype                = 'ASC'
      has_field_separator     = uv_septab
*    header_length           = 0
*    read_by_line            = 'X'
*    dat_mode                = SPACE
*    codepage                = SPACE
*    ignore_cerr             = ABAP_TRUE
*    replacement             = '#'
*    virus_scan_profile      =
*    show_transfer_status    = 'X'
*  IMPORTING
*    filelength              =
*    header                  =
    CHANGING
      data_tab                = ct_tab
    EXCEPTIONS
      file_open_error         = 1
      file_read_error         = 2
      no_batch                = 3
      gui_refuse_filetransfer = 4
      invalid_type            = 5
      no_authority            = 6
      unknown_error           = 7
      bad_data_format         = 8
      header_not_allowed      = 9
      separator_not_allowed   = 10
      header_too_long         = 11
      unknown_dp_error        = 12
      access_denied           = 13
      dp_out_of_memory        = 14
      disk_full               = 15
      dp_timeout              = 16
      not_supported_by_gui    = 17
      error_no_gui            = 18
      OTHERS                  = 19 ).

  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

*  ld_splitter = ';'.
*
*  IF uv_septab EQ c_false.
*  ELSE.
*    MOVE <fs_tab>[] TO ct_tab.
*  ENDIF.



ENDFORM.                    " FILL_TAB_W_FILE




*&---------------------------------------------------------------------*
*&      Form  PREPARE_TEXT_DATA
*&---------------------------------------------------------------------*
*       Texte vorbereiten
*----------------------------------------------------------------------*
FORM prepare_text_data.
  DATA: ld_texts_tabix TYPE sy-tabix,
        ld_text_string TYPE string.

  CLEAR: gs_texts, gt_tline[], gs_tline.

  READ TABLE gt_texts INTO gs_texts WITH KEY fallnr_old = gs_kepo-fallnr_old.
  ld_texts_tabix = sy-tabix.

  IF sy-subrc EQ 0.
    "Texte vorbereiten und zu Fallnummer speichern

    "Bemerkung 1
    IF NOT gs_texts-bem1 IS INITIAL.
      CLEAR ld_text_string.

      ld_text_string = gs_texts-bem1.
      PERFORM text2table USING ld_text_string.
    ENDIF.



    "Bemerkung 2
    IF NOT gs_texts-bem2 IS INITIAL.
      CLEAR ld_text_string.

      "Bemerkung 1 nicht leer, dann Leerzeile
      IF NOT gs_texts-bem1 IS INITIAL.
        APPEND INITIAL LINE TO gt_tline.
      ENDIF.

      ld_text_string = gs_texts-bem2.
      PERFORM text2table USING ld_text_string.
    ENDIF.



    "Stichworte Einwände
    IF NOT gs_texts-stwe IS INITIAL.
      CLEAR ld_text_string.

      "Bemerkung 1 oder Bemerkung 2 nicht leer, dann Leerzeile
      IF NOT gs_texts-bem1 IS INITIAL OR NOT gs_texts-bem2 IS INITIAL.
        APPEND INITIAL LINE TO gt_tline.
      ENDIF.


      ld_text_string = gs_texts-stwe.
      PERFORM text2table USING ld_text_string.
    ENDIF.
  ENDIF.


ENDFORM.                    " PREPARE_TEXT_DATA



*&---------------------------------------------------------------------*
*&      Form  SAVE_DATA
*&---------------------------------------------------------------------*
*       Daten speichern
*----------------------------------------------------------------------*
FORM save_data.

  "TEXTE
  IF pa_test NE c_true.
    DATA: ls_thead TYPE thead.

    IF gt_tline[] IS INITIAL.
      MESSAGE s912(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr INTO gd_msg_text.
      PERFORM add_msg2log USING sy-msgty
                                gd_msg_text.
    ELSE.
      ls_thead-tdobject = c_tdobj.
      ls_thead-tdid     = c_tdid.
      ls_thead-tdspras  = c_tdspr.

      CONCATENATE gs_kepo-gjahr gs_kepo-fallnr INTO ls_thead-tdname.

      CALL FUNCTION 'SAVE_TEXT'
        EXPORTING
          header          = ls_thead
          insert          = c_true
          savemode_direct = c_true
        TABLES
          lines           = gt_tline
        EXCEPTIONS
          id              = 1
          language        = 2
          name            = 3
          object          = 4
          OTHERS          = 5.

      IF sy-subrc EQ 0.
        MESSAGE s913(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr INTO gd_msg_text.
        PERFORM add_msg2log USING sy-msgty
                                  gd_msg_text.
      ELSE.
        MESSAGE e914(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr INTO gd_msg_text.
        PERFORM add_msg2log USING sy-msgty
                                  gd_msg_text.
      ENDIF.
    ENDIF.
  ENDIF.


  "Testlauf
  IF pa_test EQ c_true.
*    ROLLBACK WORK.
  ELSE.
    COMMIT WORK.
  ENDIF.

ENDFORM.                    " SAVE_DATA



*&---------------------------------------------------------------------*
*&      Form  TEXT2TABLE
*&---------------------------------------------------------------------*
*       Text in Tabelle fortschreiben
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
FORM text2table  USING ud_text.
  DATA: ld_len TYPE i.

  CLEAR: gs_tline.

  DO.
    IF ud_text IS INITIAL.
      EXIT.
    ENDIF.

    CLEAR gs_tline .

    gs_tline-tdline = ud_text.
    APPEND gs_tline TO gt_tline.

    SHIFT ud_text LEFT BY c_tline_len PLACES.
  ENDDO.
ENDFORM.                    " TEXT2TABLE


*&---------------------------------------------------------------------*
*&      Form  MIG_INIT
*&---------------------------------------------------------------------*
*       Initialization
*----------------------------------------------------------------------*
FORM mig_init.
  CLEAR: gd_test_fallnr, gd_msg_text, gt_log[].

  "Testlauf
  IF pa_test EQ c_true.
    MESSAGE s930(zsd_05_kepo) INTO gd_msg_text.
    PERFORM add_msg2log USING 'I'
                              gd_msg_text.
  ENDIF.


  "Textmemory leeren
  CALL FUNCTION 'FREE_TEXT_MEMORY'
    EXCEPTIONS
      not_found = 1
      OTHERS    = 2.
  IF sy-subrc <> 0.
    CLEAR gd_msg_text.

    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            INTO gd_msg_text.

    PERFORM add_msg2log USING sy-msgid
                           gd_msg_text.
  ENDIF.



  SELECT * FROM zsdtkpkepo INTO TABLE gt_kepo.

ENDFORM.                    " MIG_INIT



*&---------------------------------------------------------------------*
*&      Form  MIG_END_OF
*&---------------------------------------------------------------------*
*       End Of Migration
*----------------------------------------------------------------------*
FORM mig_end_of .

  MESSAGE s929(zsd_05_kepo) INTO gd_msg_text.
  PERFORM add_msg2log USING 'I'
                              gd_msg_text.

  PERFORM save_file USING fn_log
                         gt_log.


ENDFORM.                    " MIG_END_OF




*&---------------------------------------------------------------------*
*&      Form  ADD_MSG2LOG
*&---------------------------------------------------------------------*
*       Meldung in LOG-Tabelle schreiben
*----------------------------------------------------------------------*
FORM add_msg2log  USING ud_mtype
                        ud_mtext.

  CLEAR: gs_log.
  gs_log-mtype = ud_mtype.
  gs_log-mtext = ud_mtext.

  APPEND gs_log TO gt_log.

ENDFORM.                    " ADD_MSG2LOG



*&---------------------------------------------------------------------*
*&      Form  LOOP_INIT
*&---------------------------------------------------------------------*
*       Initialization im Fall-Loop
*----------------------------------------------------------------------*
FORM loop_init .
  CLEAR: gd_exit.
ENDFORM.                    " LOOP_INIT
