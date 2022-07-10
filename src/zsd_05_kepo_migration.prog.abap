*&---------------------------------------------------------------------*
*& Report  ZSD_05_KEPO_MIGRATION
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

report   zsd_05_kepo_migration.

include zsd_05_kepo_migration_top.  " global Data
include zsd_05_kepo_migration_f01.  " FORM-Routines
* INCLUDE ZSD_05_KEPO_MIGRATION_O01               .  " PBO-Modules
* INCLUDE ZSD_05_KEPO_MIGRATION_I01               .  " PAI-Modules



*_____Prüfungen und Eingabehilfen_____

at selection-screen on value-request for fn_log .
  perform save_fname changing fn_log.

at selection-screen on value-request for fn_kepo .
  perform get_fname changing fn_kepo.

at selection-screen on value-request for fn_docs .
  perform get_fname changing fn_docs.

at selection-screen on value-request for fn_auft .
  perform get_fname changing fn_auft.

at selection-screen on value-request for fn_texts .
  perform get_fname changing fn_texts.




*_____Auswertung_____

start-of-selection.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  perform mig_init.

  perform fill_tab_w_file using fn_kepo
*                                'ZSDTKPKEPO'
                                c_true
                       changing gt_kepo.

  perform fill_tab_w_file using fn_docs
*                              'ZSDTKPDOCPOS'
                              c_true
                     changing gt_docs.

  perform fill_tab_w_file using fn_auft
*                              'TY_TEXTS'
                              c_true
                     changing gt_auft_mod.

  perform fill_tab_w_file using fn_texts
*                              'TY_TEXTS'
                              c_true
                     changing gt_texts.


  loop at gt_kepo into gs_kepo.
    perform loop_init.

    gd_kepo_tabix = sy-tabix.

    perform prepare_kepo_data.
    perform prepare_docs_data.
    perform prepare_auft_data.
    perform prepare_mats_data.
    perform prepare_text_data.

    perform save_data.

  endloop.

  perform mig_end_of.
