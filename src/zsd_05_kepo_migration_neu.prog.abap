*&---------------------------------------------------------------------*
*& Report  ZSD_05_KEPO_MIGRATION
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT   zsd_05_kepo_migration_neu.

INCLUDE zsd_05_kepo_migration_neu_top.
INCLUDE zsd_05_kepo_migration_neu_f01.



*_____Prüfungen und Eingabehilfen_____

AT SELECTION-SCREEN ON VALUE-REQUEST FOR fn_log .
  PERFORM save_fname CHANGING fn_log.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR fn_kepo .
  PERFORM get_fname CHANGING fn_kepo.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR fn_docs .
  PERFORM get_fname CHANGING fn_docs.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR fn_auft .
  PERFORM get_fname CHANGING fn_auft.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR fn_texts .
  PERFORM get_fname CHANGING fn_texts.




*_____Auswertung_____

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  PERFORM mig_init.

  PERFORM fill_tab_w_file USING fn_kepo
*                                'ZSDTKPKEPO'
                                c_true
                       CHANGING gt_kepo.

  PERFORM fill_tab_w_file USING fn_docs
*                              'ZSDTKPDOCPOS'
                              c_true
                     CHANGING gt_docs.

  PERFORM fill_tab_w_file USING fn_auft
*                              'TY_TEXTS'
                              c_true
                     CHANGING gt_auft_mod.

  PERFORM fill_tab_w_file USING fn_texts
*                              'TY_TEXTS'
                              c_true
                     CHANGING gt_texts.


  LOOP AT gt_kepo INTO gs_kepo.
    PERFORM loop_init.

    gd_kepo_tabix = sy-tabix.

    PERFORM prepare_kepo_data.
    PERFORM prepare_docs_data.
    PERFORM prepare_auft_data.
    PERFORM prepare_mats_data.
    PERFORM prepare_text_data.

    PERFORM save_data.

  ENDLOOP.

  PERFORM mig_end_of.
