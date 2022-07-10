*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_RUECK_D1
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
TABLES: zsd_05_lulu_head              "Kopfdaten Gesuche 2007-2010
      , zsd_05_lulu_hd02              "Kopfdaten Fälle   2011-2012
      , zsd_05_lulu_fakt              "Fakturadaten zu Gesuche
      , zsd_05_lulu_fk02              "Fakturadaten zu Fälle
      , zsd_05_kehr_aufz              "Zusatzdaten KEHR_AUFT Fälle und GEsuche
      , kna1                          "Debitoren-Allg.-Daten
      , adrc                          "Zentrale-Adressdaten
      .

*----------------------------------------------------------------------*
DATA: t_printline          TYPE TABLE OF zsd_05_lulu_printline
                           WITH HEADER LINE
    , t_head               TYPE TABLE OF zsd_05_lulu_hd02
    , t_head_g              TYPE TABLE OF zsd_05_lulu_head
    , t_fakt                TYPE TABLE OF zsd_05_lulu_fakt
    , t_fk02               TYPE TABLE OF zsd_05_lulu_fk02
    , t_aufz               TYPE TABLE OF zsd_05_kehr_aufz
    , w_printline          TYPE zsd_05_lulu_printline
    , w_head               TYPE zsd_05_lulu_hd02
    , w_head_g             TYPE zsd_05_lulu_head
    , w_fakt               TYPE zsd_05_lulu_fakt
    , w_fk02               LIKE LINE OF t_fk02
    , w_aufz               TYPE zsd_05_kehr_aufz
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
SELECTION-SCREEN BEGIN OF BLOCK b_bank   WITH FRAME TITLE text-003.
PARAMETERS:    p_tstkb     AS CHECKBOX DEFAULT abap_true.
parameters:    p_korr     as CHECKBOX default abap_false.
SELECTION-SCREEN END OF BLOCK b_bank.
*======================================================================*
SELECTION-SCREEN BEGIN OF BLOCK b_back WITH FRAME TITLE text-006.
PARAMETERS:    p_back     AS CHECKBOX DEFAULT abap_false.
SELECTION-SCREEN END OF BLOCK b_back.
*======================================================================*
*======================================================================*
SELECTION-SCREEN BEGIN OF BLOCK b_case   WITH FRAME TITLE text-001
 .
PARAMETERS:    p_fall        RADIOBUTTON GROUP base
          ,    p_gesuch      RADIOBUTTON GROUP base
          .
skip.
PARAMETERS: p_datum type d DEFAULT sy-datum.
PARAMETERS: p_saknr type saknr DEFAULT '20050876'.

SELECTION-SCREEN END OF BLOCK b_case.
*======================================================================*
SELECTION-SCREEN BEGIN OF BLOCK b_sel   WITH FRAME TITLE text-002.
SELECT-OPTIONS: s_status     FOR zsd_05_lulu_head-status
*                              OBLIGATORY
              , s_fallnr     for zsd_05_lulu_hd02-fallnr
              , s_objkey     FOR zsd_05_lulu_hd02-obj_key
              , s_kunnr      for zsd_05_lulu_hd02-rg_kunnr
              , s_rkrdt      FOR zsd_05_lulu_hd02-rkrdt
              , s_eigda      FOR zsd_05_lulu_hd02-eigda
              , s_vfgdt      for zsd_05_lulu_hd02-vfgdt


              .
*----------------------------------------------------------------------*
*   data definition
*----------------------------------------------------------------------*
*       Batchinputdata of single transaction
DATA:   bdcdata LIKE bdcdata    OCCURS 0 WITH HEADER LINE.
*       messages of call transaction
DATA:   messtab LIKE bdcmsgcoll OCCURS 0 WITH HEADER LINE.
*       error session opened (' ' or 'X')
DATA:   e_group_opened.
*       message texts
TABLES: t100.
PARAMETERS: p_rows TYPE i DEFAULT 500.
SELECTION-SCREEN END OF BLOCK b_sel.

*SELECTION-SCREEN BEGIN OF BLOCK b_kve   WITH FRAME TITLE text-004.
*PARAMETERS:    p_test     AS CHECKBOX DEFAULT abap_true.
*SELECTION-SCREEN END OF BLOCK b_kve.
SELECTION-SCREEN begin OF BLOCK b_bdc  WITH FRAME TITLE text-005.
SELECTION-SCREEN BEGIN OF LINE.
 PARAMETERS session type xfeld DEFAULT 'X' NO-DISPLAY .".  "create session
SELECTION-SCREEN COMMENT 3(20) text-s07 FOR FIELD session.
*SELECTION-SCREEN POSITION 45.
*PARAMETERS ctu RADIOBUTTON GROUP  ctu.     "call transaction
*SELECTION-SCREEN COMMENT 48(20) text-s08 FOR FIELD ctu.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(20) text-s01 FOR FIELD group.
SELECTION-SCREEN POSITION 25.
PARAMETERS group(12) DEFAULT 'Z_RUECK'.                      "group name of session
SELECTION-SCREEN COMMENT 48(20) text-s05 FOR FIELD ctumode.
SELECTION-SCREEN POSITION 70.
PARAMETERS ctumode LIKE ctu_params-dismode DEFAULT 'N'.
"A: show all dynpros
"E: show dynpro on error only
"N: do not display dynpro
SELECTION-SCREEN END OF LINE.



SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(20) text-s02 FOR FIELD user.
SELECTION-SCREEN POSITION 25.
PARAMETERS: user(12) DEFAULT sy-uname.     "user for session in batch
*SELECTION-SCREEN COMMENT 48(20) text-s06 FOR FIELD cupdate.
*SELECTION-SCREEN POSITION 70.
*PARAMETERS cupdate LIKE ctu_params-updmode DEFAULT 'L'.
"S: synchronously
"A: asynchronously
"L: local
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(20) text-s03 FOR FIELD keep.
SELECTION-SCREEN POSITION 25.
PARAMETERS: keep AS CHECKBOX.       "' ' = delete session if finished
"'X' = keep   session if finished
*SELECTION-SCREEN COMMENT 48(20) text-s09 FOR FIELD e_group.
*SELECTION-SCREEN POSITION 70.
*PARAMETERS e_group(12).             "group name of error-session
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(20) text-s04 FOR FIELD holddate.
SELECTION-SCREEN POSITION 25.
PARAMETERS: holddate LIKE sy-datum.
*SELECTION-SCREEN COMMENT 51(17) text-s02 FOR FIELD e_user.
*SELECTION-SCREEN POSITION 70.
*PARAMETERS: e_user(12) DEFAULT sy-uname.    "user for error-session
SELECTION-SCREEN END OF LINE.

*SELECTION-SCREEN BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 51(17) text-s03 FOR FIELD e_keep.
*SELECTION-SCREEN POSITION 70.
*PARAMETERS: e_keep AS CHECKBOX .     "' ' = delete session if finished
*"'X' = keep   session if finished
*SELECTION-SCREEN END OF LINE.

*SELECTION-SCREEN BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 51(17) text-s04 FOR FIELD e_hdate.
*SELECTION-SCREEN POSITION 70.
*PARAMETERS: e_hdate LIKE sy-datum NO-DISPLAY.
*SELECTION-SCREEN END OF LINE.

*SELECTION-SCREEN SKIP.
*
*SELECTION-SCREEN BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 1(33) text-s10 FOR FIELD nodata.
*PARAMETERS: nodata DEFAULT '/' LOWER CASE.          "nodata
*SELECTION-SCREEN END OF LINE.
*
*SELECTION-SCREEN BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 1(33) text-s11 FOR FIELD smalllog.
*PARAMETERS: smalllog AS CHECKBOX.  "' ' = log all transactions
*"'X' = no transaction logging
*SELECTION-SCREEN END OF LINE.

*SELECTION-SCREEN BEGIN OF LINE.
*  SELECTION-SCREEN COMMENT 1(15) text-s12 FOR FIELD p_esr.
*PARAMETERS: p_esr TYPE xfeld.
*SELECTION-SCREEN END OF LINE.
*SELECTION-SCREEN BEGIN OF LINE.
*  SELECTION-SCREEN COMMENT 1(15) text-s13 FOR FIELD p_iban.
*PARAMETERS:   p_iban TYPE xfeld.
*SELECTION-SCREEN END OF LINE.
*SELECTION-SCREEN BEGIN OF LINE.
*  SELECTION-SCREEN COMMENT 1(15) text-s14 FOR FIELD p_acc.
*PARAMETERS:   p_acc TYPE xfeld.
*SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b_bdc.
