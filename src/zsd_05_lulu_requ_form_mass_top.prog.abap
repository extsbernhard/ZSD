*&---------------------------------------------------------------------*
*& Include ZSD_05_LULU_REQU_FORM_MASS_TOP                    Modulpool        ZSD_05_LULU_REQU_MASS_FORM
*&
*&---------------------------------------------------------------------*

PROGRAM zsd_05_lulu_requ_mass_form.

TYPE-POOLS: abap.

DATA: gt_lulu_head_db type TABLE OF zsd_05_lulu_hd02,
      gt_lulu_head TYPE TABLE OF zsd_05_lulu_hd02,
      gs_lulu_head TYPE zsd_05_lulu_hd02,
      gt_lulu_fakt TYPE TABLE OF zsd_05_lulu_fk02,
      gs_lulu_fakt TYPE zsd_05_lulu_fk02.

DATA: gv_cnt_case TYPE i,
      gv_cnt_while type i,
      gv_cnt_lines TYPE i,
      gv_lines TYPE i,
      gv_idx_from TYPE i,
      gv_idx_to   TYPE i,
      gv_idx_grp  type i,
      gv_grp_nr   type i,
      gv_sfname TYPE tdsfname VALUE 'ZSD_05_LULU_REQU01',
      gv_fbnam TYPE rs38l_fnam,
      gs_sf_control_params TYPE ssfctrlop,
      gs_sf_options	TYPE ssfcompop.

Data: c_mess_i     type c value 'I'
    , c_mess_w     type c value 'W'
    , c_mess_e     type c value 'E'
    , c_activ      type c value 'X'
    , c_inactiv    type c value ' '
    .

*_____SELEKTIONSBILD_____
SELECTION-SCREEN: BEGIN OF BLOCK bl1 WITH FRAME TITLE text-001.
PARAMETERS:       pa_print TYPE ssfcompop-tddest OBLIGATORY.
PARAMETERS:       pa_prnow TYPE ssfcompop-tdimmed.
PARAMETERS:       pa_dlog  TYPE ssfctrlop-no_dialog DEFAULT abap_true.
"SELECTION-SCREEN: SKIP 1.
PARAMETERS:       pa_spgrp TYPE char6 DEFAULT 750. " NO-DISPLAY.
SELECTION-SCREEN: END OF BLOCK bl1.

SELECTION-SCREEN: BEGIN OF BLOCK bl1a WITH FRAME TITLE text-01a.
PARAMETERS:       pa_mahn    as checkbox DEFAULT ' '. "Mahnlauf Ja/Nein
PARAMETERS:       pa_eigda   as checkbox DEFAULT 'X'. "Eingangsdatum soll initial sein
SELECTION-SCREEN: END OF BLOCK bl1a.

SELECTION-SCREEN: BEGIN OF BLOCK bl2 WITH FRAME TITLE text-002.
PARAMETERS:       pa_test   as checkbox DEFAULT 'X'.
PARAMETERS:       pa_rows   TYPE char6 DEFAULT 5.
SELECTION-SCREEN: END OF BLOCK bl2.

SELECTION-SCREEN: BEGIN OF BLOCK bl3 WITH FRAME TITLE text-003.
PARAMETERS:       pa_echt   as checkbox default ' '.
PARAMETERS:       pa_rowe   TYPE char6 DEFAULT 4000 NO-DISPLAY..
SELECTION-SCREEN: END OF BLOCK bl3.
