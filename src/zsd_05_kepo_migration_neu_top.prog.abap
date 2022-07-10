*&---------------------------------------------------------------------*
*& Include ZSD_05_KEPO_MIGRATION_TOP                         Report ZSD_05_KEPO_MIGRATION
*&
*&---------------------------------------------------------------------*

*_____Typen_____
TYPES: BEGIN OF ty_texts,
        fallnr_old TYPE zsdtkpkepo-fallnr_old,
        bem1       TYPE text2083,
        bem2       TYPE text2083,
        stwe       TYPE text2083,
       END OF ty_texts.

TYPES: BEGIN OF ty_auft_mod.
        INCLUDE TYPE zsdtkpauft.
TYPES:  fallnr_old TYPE zsdtkpkepo-fallnr_old,
       END OF ty_auft_mod.

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
      gs_auft TYPE zsdtkpauft,
      gt_auft_mod TYPE STANDARD TABLE OF ty_auft_mod,
      gs_auft_mod TYPE ty_auft_mod,
      gt_docs TYPE STANDARD TABLE OF zsdtkpdocpos,
      gs_docs TYPE zsdtkpdocpos,
      gt_texts TYPE STANDARD TABLE OF ty_texts,
      gs_texts TYPE ty_texts,
      gt_matpos TYPE STANDARD TABLE OF zsdtkpmatpos,
      gs_matpos TYPE zsdtkpmatpos,

      gt_tline    TYPE STANDARD TABLE OF tline,
      gs_tline    TYPE tline,

      gd_tdname   TYPE thead-tdname,
      gd_text_string TYPE string,

      gd_test_fallnr TYPE zsdekpfallnr,

      gd_kepo_tabix TYPE sy-tabix,
      gs_t005 TYPE t005,
      gs_t005_mod TYPE t005,

      gs_log TYPE ty_log,
      gt_log TYPE STANDARD TABLE OF ty_log,
      gd_msg_text TYPE string,

      gd_exit TYPE c VALUE c_false.


DATA: BEGIN OF gt_texts_new OCCURS 0,
        fallnr_old TYPE zsdtkpkepo-fallnr_old,
        text       TYPE text2083,
      END OF gt_texts_new,

      gs_texts_new LIKE gt_texts_new.



*_____Selektionsbild_____

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE text-bl1.
PARAMETERS:     fn_kepo  TYPE text200 OBLIGATORY.
PARAMETERS:     fn_docs  TYPE text200 OBLIGATORY.
PARAMETERS:     fn_auft  TYPE text200 OBLIGATORY.
PARAMETERS:     fn_texts TYPE text200 OBLIGATORY.
*PARAMETERS:     p_overw  AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK bl1.

SELECTION-SCREEN BEGIN OF BLOCK bl2 WITH FRAME TITLE text-bl2.
PARAMETERS:   fn_log TYPE text200.
PARAMETERS:   pa_test AS CHECKBOX DEFAULT c_true.
SELECTION-SCREEN END OF BLOCK bl2.
