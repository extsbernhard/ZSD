*&---------------------------------------------------------------------*
*&  Include           ZSD_05_KEPO_MIGRATION_F01
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
        lv_date   TYPE sy-datum.


  CREATE OBJECT go_services.


  CLEAR lt_filetable. REFRESH lt_filetable .
  CLEAR lv_action.
  CLEAR lv_fname.

  lv_date = sy-datum.

  CONCATENATE lv_date 'LOG_KEPO_MIG' sy-uname INTO lv_fname SEPARATED BY '_'.
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
*&      Form  PREPARE_KEPO_DATA
*&---------------------------------------------------------------------*
*       Daten in GT_KEPO ergänzen
*----------------------------------------------------------------------*
FORM prepare_kepo_data.
  DATA: ls_kna1 TYPE kna1,
        i_adrc_struc TYPE adrc_struc,
        e_adrc_struc TYPE adrc_struc,
        ls_addr_str TYPE adrstreett,
        ls_addr_nr  TYPE adrstrpcd,
        ld_house_num TYPE housenum_l.

  CLEAR: gd_msg_text.


  "Bei Testlauf nur interne Nummvergabe, ohne den Nummerkreis zu berücksichtigen
  IF pa_test EQ c_true.
    ADD 1 TO gd_test_fallnr.
    gs_kepo-fallnr = gd_test_fallnr.
  ELSE.

    "Neue Fallnummer vergeben
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING
        nr_range_nr                  = c_nknrr
        object                       = c_nkobj
       quantity                      = '1'
       toyear                        = gs_kepo-gjahr
*       IGNORE_BUFFER                 = ' '
     IMPORTING
       number                        = gs_kepo-fallnr
*       QUANTITY                      =
*       RETURNCODE                    =
     EXCEPTIONS
       interval_not_found            = 1
       number_range_not_intern       = 2
       object_not_found              = 3
       quantity_is_0                 = 4
       quantity_is_not_1             = 5
       interval_overflow             = 6
       buffer_overflow               = 7
       OTHERS                        = 8.

    IF sy-subrc <> 0.
      MESSAGE e900(zsd_05_kepo) WITH gs_kepo-fallnr_old INTO gd_msg_text.
      PERFORM add_msg2log USING sy-msgty
                                gd_msg_text.

      "Datensatz nicht in DB schreiben
      gd_exit = c_true.

    ENDIF.
  ENDIF.



  "Debitor lesen
  CLEAR: ls_kna1.
  IF NOT gs_kepo-kunnr IS INITIAL.
    SELECT SINGLE * FROM kna1 INTO ls_kna1
      WHERE name3 = gs_kepo-kunnr
        AND loevm EQ c_false.

    IF ls_kna1 IS INITIAL.
      MESSAGE e915(zsd_05_kepo) WITH gs_kepo-fallnr_old gs_kepo-kunnr INTO gd_msg_text.
      PERFORM add_msg2log USING sy-msgty
                                gd_msg_text.
    ENDIF.

    "Übergabe auch wenn leer ist, ansonsten ist die alte Kundennummer enthalten
    gs_kepo-kunnr = ls_kna1-kunnr.


    "Fiktive K-Nummern werden bei KUNNR_OLD wieder gelöscht.
    DATA: ld_len TYPE i.

    ld_len = STRLEN( gs_kepo-kunnr_old ).

    IF ld_len LT 6 AND ld_len NE 0.
      CLEAR gs_kepo-kunnr_old.
    ENDIF.
  ENDIF.



  "Adressprüfung, Fortschreibung der PLZ oder Default-Wert setzen
  CLEAR: i_adrc_struc, e_adrc_struc.
  i_adrc_struc-city1 = gs_kepo-city1.
  i_adrc_struc-street = gs_kepo-street.
  i_adrc_struc-house_num1 = gs_kepo-house_num1.
  i_adrc_struc-country = c_ctry.

  CALL FUNCTION 'ADDR_REGIONAL_DATA_CHECK'
    EXPORTING
      x_adrc_struc   = i_adrc_struc
      x_accept_error = c_false
    IMPORTING
      y_adrc_struc   = e_adrc_struc.

  IF e_adrc_struc IS INITIAL.
    ld_house_num = gs_kepo-house_num1.

    IF NOT ld_house_num IS INITIAL.
      SELECT SINGLE apcd~post_code INTO gs_kepo-post_code1
        FROM adrstreett AS astr INNER JOIN adrstrpcd AS apcd
          ON apcd~strt_code = astr~strt_code
        WHERE astr~city_code = c_cityc
          AND astr~street = gs_kepo-street
          AND apcd~housenum_l GE ld_house_num
          AND apcd~housenum_h LE ld_house_num.
    ELSE.
      SELECT SINGLE apcd~post_code INTO gs_kepo-post_code1
        FROM adrstreett AS astr INNER JOIN adrstrpcd AS apcd
          ON apcd~strt_code = astr~strt_code
        WHERE astr~city_code = c_cityc
          AND astr~street = gs_kepo-street.
    ENDIF.

    "Strasse nicht gefunden, Default-PLZ setzen
    IF gs_kepo-post_code1 IS INITIAL.
      gs_kepo-post_code1 = c_pcd.
    ENDIF.

  ELSE.
    gs_kepo-post_code1 = e_adrc_struc-post_code1.
  ENDIF.

  gs_kepo-erdat = sy-datum.
  gs_kepo-erzet = sy-uzeit.

  "Interne Tabelle updaten
  MODIFY gt_kepo FROM gs_kepo INDEX gd_kepo_tabix.

  IF sy-subrc NE 0.
    gd_exit = c_true.
  ENDIF.


ENDFORM.                    " PREPARE_KEPO_DATA



*&---------------------------------------------------------------------*
*&      Form  PREPARE_DOCS_DATA
*&---------------------------------------------------------------------*
*       Daten in GT_DOCS ergänzen
*----------------------------------------------------------------------*
FORM prepare_docs_data .
  DATA: ld_docs_tabix TYPE sy-tabix.

  CLEAR: gs_docs,
         ld_docs_tabix.

  READ TABLE gt_docs INTO gs_docs WITH KEY bezei = gs_kepo-fallnr_old.
  ld_docs_tabix = sy-tabix.

  IF sy-subrc EQ 0.

    "Für Migration die alte Fallnummer enthalten => wird wieder entfernt
    CLEAR: gs_docs-bezei.

    gs_docs-fallnr = gs_kepo-fallnr.
    gs_docs-gjahr  = gs_kepo-gjahr.
*    MODIFY gt_docs FROM gs_docs INDEX ld_docs_tabix.
  ENDIF.

*  ENDLOOP.
ENDFORM.                    " PREPARE_DOCS_DATA



*&---------------------------------------------------------------------*
*&      Form  PREPARE_AUFT_DATA
*&---------------------------------------------------------------------*
*       GT_AUFT Daten vorbereiten
*----------------------------------------------------------------------*
FORM prepare_auft_data.
  DATA: ls_vbrk TYPE vbrk,   "Faktura: Kopfdaten
        ls_vbfa TYPE vbfa,   "Vertriebsbelegfluss
        ls_vbak TYPE vbak.   "Verkaufsbeleg: Kopfdaten

  DATA: ld_auft_tabix TYPE sy-tabix,
        ld_vbeln_init TYPE vbeln_vf VALUE '0000000000'.

  CLEAR: gs_auft_mod, gs_auft, gt_auft[], ld_auft_tabix.

  READ TABLE gt_auft_mod INTO gs_auft_mod WITH KEY fallnr_old = gs_kepo-fallnr_old.
  ld_auft_tabix = sy-tabix.

  IF sy-subrc EQ 0.
    "Fakturanummer formatieren
    SHIFT gs_auft_mod-vbeln_f RIGHT DELETING TRAILING ' '.
    OVERLAY gs_auft_mod-vbeln_f WITH ld_vbeln_init.

    "Lesen des Fakturakopfes
    SELECT SINGLE * FROM vbrk INTO ls_vbrk
      WHERE vbeln EQ gs_auft_mod-vbeln_f.

    IF sy-subrc EQ 0.
      "Lesen des Belegflusses fürs Ermitteln des Auftrags; der letzte aktuelle Eintrag
      SELECT * FROM vbfa INTO ls_vbfa UP TO 1 ROWS
        WHERE vbeln   EQ ls_vbrk-vbeln
          AND vbtyp_n EQ 'M'
        ORDER BY erdat DESCENDING erzet DESCENDING.
      ENDSELECT.

      IF sy-subrc EQ 0.
        "Lesen des Auftragkopfes
        SELECT SINGLE * FROM vbak INTO ls_vbak
          WHERE vbeln EQ ls_vbfa-vbelv.

        IF sy-subrc EQ 0.
          MOVE-CORRESPONDING gs_auft_mod TO gs_auft.

          gs_auft-fallnr    = gs_kepo-fallnr.
          gs_auft-gjahr     = gs_kepo-gjahr.
          gs_auft-vbeln_f   = ls_vbrk-vbeln.
          gs_auft-vbeln_a   = ls_vbak-vbeln.
          gs_auft-vkorg     = ls_vbrk-vkorg.
          gs_auft-vtweg     = ls_vbrk-vtweg.
          gs_auft-spart     = ls_vbrk-spart.
          gs_auft-vkbur     = ls_vbak-vkbur.
          gs_auft-beldat_a  = ls_vbak-audat.
          gs_auft-ernam_a   = ls_vbak-ernam.
          gs_auft-erdat_a   = ls_vbak-erdat.
          gs_auft-erzet_a   = ls_vbak-erzet.
          gs_auft-status_a  = '02'. "fakturiert
          gs_auft-statdat_a = ls_vbrk-erdat.
          gs_auft-statzet_a = ls_vbrk-erzet.
          gs_auft-beldat_f  = ls_vbrk-fkdat.
          gs_auft-ernam_f   = ls_vbrk-ernam.
          gs_auft-erdat_f   = ls_vbrk-erdat.
          gs_auft-erzet_f   = ls_vbrk-erzet.
          gs_auft-netwr_f   = ls_vbrk-netwr.
          gs_auft-waerk_f   = ls_vbrk-waerk.
          gs_auft-status_f  = '01'. "offen
          gs_auft-statdat_f = ls_vbrk-erdat.
          gs_auft-statzet_f = ls_vbrk-erzet.

          "Kein Hinzufügen in Tabelle nötig, da nur ein Auftrags-Datensatz in DB geschrieben wird
*          APPEND gs_auft TO gt_auft.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.


ENDFORM.                    " PREPARE_AUFT_DATA



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
    ld_text_string = gs_texts-text.
    PERFORM text2table USING ld_text_string.

  ENDIF.


ENDFORM.                    " PREPARE_TEXT_DATA



*&---------------------------------------------------------------------*
*&      Form  SAVE_DATA
*&---------------------------------------------------------------------*
*       Daten speichern
*----------------------------------------------------------------------*
FORM save_data.
  "Wenn Datensatz nicht fehlerhaft, dann in DB schreiben
  IF gd_exit EQ c_false.



    "ZSDTKPKEPO
    INSERT zsdtkpkepo FROM gs_kepo.

    IF sy-subrc EQ 0.
      MESSAGE s901(zsd_05_kepo) WITH gs_kepo-fallnr_old  gs_kepo-fallnr INTO gd_msg_text.
      PERFORM add_msg2log USING sy-msgty
                                gd_msg_text.
    ELSE.
      MESSAGE e902(zsd_05_kepo) WITH gs_kepo-fallnr_old INTO gd_msg_text.
      PERFORM add_msg2log USING sy-msgty
                                gd_msg_text.

      "Bei Fehler keine Weiterverarbeitung des aktuellen Falles
      gd_exit = c_true.
    ENDIF.



    "Fehler beim Insert der Kopfdaten - Keine Weiterverarbeitung des aktuellen Falles
    IF gd_exit EQ c_false.



      "ZSDTKPDOCPOS
      IF gs_docs IS INITIAL.
        MESSAGE s903(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr INTO gd_msg_text.
        PERFORM add_msg2log USING sy-msgty
                                  gd_msg_text.
      ELSE.
        INSERT zsdtkpdocpos FROM gs_docs.

        IF sy-subrc EQ 0.
          MESSAGE s903(zsd_05_kepo) WITH gs_docs-posnr gs_docs-fallnr gs_docs-gjahr INTO gd_msg_text.
          PERFORM add_msg2log USING sy-msgty
                                    gd_msg_text.
        ELSE.
          MESSAGE e904(zsd_05_kepo) WITH gs_docs-posnr gs_docs-fallnr gs_docs-gjahr INTO gd_msg_text.
          PERFORM add_msg2log USING sy-msgty
                                    gd_msg_text.
        ENDIF.
      ENDIF.



      "ZSDTKPAUFT
      IF gs_auft IS INITIAL.
        MESSAGE s906(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr INTO gd_msg_text.
        PERFORM add_msg2log USING sy-msgty
                                  gd_msg_text.
      ELSE.
        INSERT zsdtkpauft FROM gs_auft.

        IF sy-subrc EQ 0.
          MESSAGE s907(zsd_05_kepo) WITH gs_auft-fallnr gs_auft-gjahr INTO gd_msg_text.
          PERFORM add_msg2log USING sy-msgty
                                    gd_msg_text.
        ELSE.
          MESSAGE e908(zsd_05_kepo) WITH gs_auft-fallnr gs_auft-gjahr INTO gd_msg_text.
          PERFORM add_msg2log USING sy-msgty
                                    gd_msg_text.
        ENDIF.
      ENDIF.



      "ZSDTKPMATPOS
      CLEAR: gs_matpos.

      IF gt_matpos[] IS INITIAL.
        MESSAGE s909(zsd_05_kepo) WITH gs_kepo-fallnr gs_kepo-gjahr INTO gd_msg_text.
        PERFORM add_msg2log USING sy-msgty
                                  gd_msg_text.
      ELSE.
        LOOP AT gt_matpos INTO gs_matpos.

          SHIFT gs_matpos-matnr LEFT DELETING LEADING '0'.

          INSERT zsdtkpmatpos FROM gs_matpos.

          IF sy-subrc EQ 0.
            MESSAGE s910(zsd_05_kepo) WITH gs_matpos-matnr gs_matpos-posnr gs_matpos-fallnr gs_docs-gjahr INTO gd_msg_text.
            PERFORM add_msg2log USING sy-msgty
                                      gd_msg_text.
          ELSE.
            MESSAGE e911(zsd_05_kepo) WITH gs_matpos-matnr gs_matpos-posnr gs_docs-fallnr gs_docs-gjahr INTO gd_msg_text.
            PERFORM add_msg2log USING sy-msgty
                                      gd_msg_text.
          ENDIF.
        ENDLOOP.
      ENDIF.



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
    ENDIF.
  ENDIF.


  "Testlauf
  IF pa_test EQ c_true.
    ROLLBACK WORK.
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

  CLEAR: gt_tline[], gs_tline.

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
  CLEAR: gs_t005, gs_t005_mod, gd_test_fallnr, gd_msg_text, gt_log[].

  "Für Adressprüfung Tabelle T005 Feld XREGS allenfalls anpassen
  SELECT SINGLE * FROM t005 INTO gs_t005
    WHERE land1 = 'CH'.

  IF gs_t005-xregs NE c_true.
    gs_t005_mod = gs_t005.
    gs_t005_mod-xregs = c_true.
    UPDATE t005 FROM gs_t005_mod.
    COMMIT WORK AND WAIT.
  ENDIF.


  "Testlauf
  IF pa_test EQ c_true.
    MESSAGE s930(zsd_05_kepo) INTO gd_msg_text.
    PERFORM add_msg2log USING 'I'
                              gd_msg_text.
  ENDIF.




ENDFORM.                    " MIG_INIT



*&---------------------------------------------------------------------*
*&      Form  MIG_END_OF
*&---------------------------------------------------------------------*
*       End Of Migration
*----------------------------------------------------------------------*
FORM mig_end_of .
  "Tabelle T005 Feld XREGS wieder zurücksetzen
  IF NOT gs_t005_mod IS INITIAL.
    UPDATE t005 FROM gs_t005.
    COMMIT WORK AND WAIT.
  ENDIF.

  MESSAGE s929(zsd_05_kepo) INTO gd_msg_text.
  PERFORM add_msg2log USING 'I'
                              gd_msg_text.

  PERFORM save_file USING fn_log
                         gt_log.


ENDFORM.                    " MIG_END_OF



*&---------------------------------------------------------------------*
*&      Form  PREPARE_MATS_DATA
*&---------------------------------------------------------------------*
*       Materialpositionen je Fall vorbereiten
*----------------------------------------------------------------------*
FORM prepare_mats_data.
  DATA: lt_vbap TYPE STANDARD TABLE OF vbap,
        ls_vbap TYPE vbap.

  CLEAR: lt_vbap[], ls_vbap, gs_matpos, gt_matpos[].

  SELECT * FROM vbap INTO TABLE lt_vbap
    WHERE vbeln EQ gs_auft-vbeln_a
      ORDER BY posnr ASCENDING.

  IF sy-subrc EQ 0.
    LOOP AT lt_vbap INTO ls_vbap.
      gs_matpos-mandt  = gs_kepo-mandt.
      gs_matpos-fallnr = gs_kepo-fallnr.
      gs_matpos-gjahr  = gs_kepo-gjahr.
      gs_matpos-posnr  = ls_vbap-posnr.
      gs_matpos-matnr  = ls_vbap-matnr.
      gs_matpos-anzahl = ls_vbap-kwmeng.
      gs_matpos-vrkme  = ls_vbap-vrkme.
      gs_matpos-bezei  = ls_vbap-arktx.

      APPEND gs_matpos TO gt_matpos.

    ENDLOOP.
  ELSE.
  ENDIF.

ENDFORM.                    " PREPARE_MATS_DATA



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
