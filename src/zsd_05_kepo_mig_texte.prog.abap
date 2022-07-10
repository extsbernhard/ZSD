*&---------------------------------------------------------------------*
*& Report  ZSD_05_KEPO_MIG_TEXTE
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT   zsd_05_kepo_mig_texte.

INCLUDE zsd_05_kepo_mig_texte_top.  " global Data
INCLUDE zsd_05_kepo_mig_texte_f01.  " FORM-Routines



*_____Prüfungen und Eingabehilfen_____

AT SELECTION-SCREEN ON VALUE-REQUEST FOR fn_log .
  PERFORM save_fname CHANGING fn_log.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR fn_texts .
  PERFORM get_fname CHANGING fn_texts.




*_____Auswertung_____

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  PERFORM mig_init.

  PERFORM fill_tab_w_file USING fn_texts
*                              'TY_TEXTS'
                              c_true
                     CHANGING gt_texts.


  LOOP AT gt_kepo INTO gs_kepo.
*    PERFORM loop_init.

    PERFORM prepare_text_data.
    PERFORM save_data.

  ENDLOOP.

  PERFORM mig_end_of.
