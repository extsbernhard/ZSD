*&---------------------------------------------------------------------*
*&  Include           ZSD_05_KEPO_MIG_TEXTE_TOP
*&---------------------------------------------------------------------*


*_____Typen_____
TYPES: BEGIN OF ty_texts,
        fallnr_old TYPE zsdtkpkepo-fallnr_old,
*        text       TYPE string,
        text       TYPE text2083,
       END OF ty_texts.

TYPES: BEGIN OF ty_log,
        mtype TYPE msgty,
        mtext TYPE text200,
       END OF ty_log.



*_____Datendefinitionen_____
CONSTANTS: c_true  TYPE c VALUE 'X',
           c_false TYPE c VALUE ' ',
           c_numerics(11) TYPE c VALUE ' 0123456789',
           c_tdid  TYPE thead-tdid VALUE 'Z001',
           c_tdspr TYPE thead-tdspras VALUE 'DE',
           c_tdobj TYPE thead-tdobject VALUE 'ZKEPO',
           c_nkobj TYPE nrobj VALUE 'ZKEPOFALL',
           c_nknrr TYPE nrnr  VALUE '01',
           c_dir TYPE string VALUE 'O:\50_ZA\20_SAP\Kehrichtpolizei\Migration\Importfiles',
           c_ctry TYPE land1 VALUE 'CH',
           c_cityc TYPE city_code VALUE '000000000351',
           c_pcd   TYPE post_code VALUE '3000',
           c_tline_len TYPE i VALUE '132'.


DATA: gt_kepo TYPE STANDARD TABLE OF zsdtkpkepo,
      gs_kepo TYPE zsdtkpkepo,
      gt_auft TYPE STANDARD TABLE OF zsdtkpauft,
      gt_texts TYPE STANDARD TABLE OF ty_texts,
      gs_texts TYPE ty_texts,

      gt_tline    TYPE STANDARD TABLE OF tline,
      gs_tline    TYPE tline,

      gd_tdname   TYPE thead-tdname,
      gd_text_string TYPE string,

      gd_test_fallnr TYPE zsdekpfallnr,

      gd_kepo_tabix TYPE sy-tabix,

      gs_log TYPE ty_log,
      gt_log TYPE STANDARD TABLE OF ty_log,
      gd_msg_text TYPE string,

      gd_exit TYPE c VALUE c_false.


*_____Selektionsbild_____

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE text-bl1.
PARAMETERS:     fn_texts TYPE text200 OBLIGATORY.
*PARAMETERS:     p_overw  AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK bl1.

SELECTION-SCREEN BEGIN OF BLOCK bl2 WITH FRAME TITLE text-bl2.
PARAMETERS:   fn_log TYPE text200.
PARAMETERS:   pa_test AS CHECKBOX DEFAULT c_true.
SELECTION-SCREEN END OF BLOCK bl2.
