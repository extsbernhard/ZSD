*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_RUECK_D1
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
TABLES: zsd_04_kehricht             "Kehricht Daten in der Objektverwaltun
      , zsd_05_hinweis
      , kna1                          "Debitoren-Allg.-Daten
      , adrc                          "Zentrale-Adressdaten
      .

*----------------------------------------------------------------------*
DATA:
      t_kehricht TYPE TABLE OF zsd_04_kehricht
    , t_hinweis TYPE TABLE OF zsd_05_hinweis
    , w_printline          TYPE zsd_05_lulu_printline
    , w_hinweis TYPE zsd_05_hinweis
    , w_kna1               TYPE kna1
    , w_adrc               TYPE adrc
    , w_lulu_head          TYPE tabnam
    , w_lulu_fakt          TYPE tabnam
    , w_lines              TYPE i               "Anzahl TabellenEinträge
    .
 data: s_perst TYPE RANGE OF LD_PERST.
 data: s_pered TYPE RANGE OF ld_pered.

 data: w_perst like LINE OF s_perst.
 data: w_pered like LINE OF s_pered.
 data :      gv_obj_addr  TYPE text200,
      gv_obj       TYPE string.
*----------------------------------------------------------------------*

 data: w_rc TYPE sy-subrc.
*----------------------------------------------------------------------*
DATA: c_activ              TYPE c VALUE 'X'
    , c_inactiv            TYPE c VALUE ' '
    , c_fall_head(16)      TYPE c VALUE 'ZSD_05_LULU_HD02'
    , c_fall_fakt(16)      TYPE c VALUE 'ZSD_05_LULU_FK02'
    , c_gesu_head(16)      TYPE c VALUE 'ZSD_05_LULU_HEAD'
    , c_gesu_fakt(16)      TYPE c VALUE 'ZSD_05_LULU_FAKT'
    .

data: lr_util TYPE REF TO ZCL_IM_LULU_UTILS.
*======================================================================*

*======================================================================*
SELECTION-SCREEN BEGIN OF BLOCK b_sel   WITH FRAME TITLE text-002.
SELECT-OPTIONS:
               s_objkey     FOR zsd_04_kehricht-obj_key
              , s_kunnr      for zsd_04_kehricht-kunnr
              .
*----------------------------------------------------------------------*
*   data definition
*----------------------------------------------------------------------*
PARAMETERS: p_rows TYPE i DEFAULT 500.
SELECTION-SCREEN END OF BLOCK b_sel.
*======================================================================*

*======================================================================*
SELECTION-SCREEN BEGIN OF BLOCK b_kun   WITH FRAME TITLE text-003.
PARAMETERS:    p_tstkd     AS CHECKBOX DEFAULT abap_true.
 SELECTION-SCREEN END OF BLOCK b_kun.
*======================================================================*
