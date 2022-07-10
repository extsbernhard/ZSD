*&---------------------------------------------------------------------*
*& Include ZSD_05_KEPO_MIGRATION_TOP                         Report ZSD_05_KEPO_MIGRATION
*&
*&---------------------------------------------------------------------*

*_____Typen_____
types: begin of ty_texts,
        fallnr_old type zsdtkpkepo-fallnr_old,
*        text       TYPE string,
        text       type text2083,
       end of ty_texts.

types: begin of ty_auft_mod.
        include type zsdtkpauft.
types:  fallnr_old type zsdtkpkepo-fallnr_old,
       end of ty_auft_mod.

types: begin of ty_log,
        mtype type msgty,
        mtext type text200,
       end of ty_log.



*_____Datendefinitionen_____
constants: c_true  type c value 'X',
           c_false type c value ' ',
           c_numerics(11) type c value ' 0123456789',
           c_tdid  type thead-tdid value 'Z001',
           c_tdspr type thead-tdspras value 'DE',
           c_tdobj type thead-tdobject value 'ZKEPO',
           c_nkobj type nrobj value 'ZKEPOFALL',
           c_nknrr type nrnr  value '01',
           c_dir type string value 'O:\50_ZA\20_SAP\Kehrichtpolizei\Migration\Importfiles',
           c_ctry type land1 value 'CH',
           c_cityc type city_code value '000000000351',
           c_pcd   type post_code value '3000',
           c_tline_len type i value '132'.


data: gt_kepo type standard table of zsdtkpkepo,
      gs_kepo type zsdtkpkepo,
      gt_auft type standard table of zsdtkpauft,
      gs_auft type zsdtkpauft,
      gt_auft_mod type standard table of ty_auft_mod,
      gs_auft_mod type ty_auft_mod,
      gt_docs type standard table of zsdtkpdocpos,
      gs_docs type zsdtkpdocpos,
      gt_texts type standard table of ty_texts,
      gs_texts type ty_texts,
      gt_matpos type standard table of zsdtkpmatpos,
      gs_matpos type zsdtkpmatpos,

      gt_tline    type standard table of tline,
      gs_tline    type tline,

      gd_tdname   type thead-tdname,
      gd_text_string type string,

      gd_test_fallnr type zsdekpfallnr,

      gd_kepo_tabix type sy-tabix,
      gs_t005 type t005,
      gs_t005_mod type t005,

      gs_log type ty_log,
      gt_log type standard table of ty_log,
      gd_msg_text type string,

      gd_exit type c value c_false.


data: begin of gt_texts_new occurs 0,
        fallnr_old type zsdtkpkepo-fallnr_old,
        text       type text2083,
      end of gt_texts_new,

      gs_texts_new like gt_texts_new.



*_____Selektionsbild_____

selection-screen begin of block bl1 with frame title text-bl1.
parameters:     fn_kepo  type text200 obligatory.
parameters:     fn_docs  type text200 obligatory.
parameters:     fn_auft  type text200 obligatory.
parameters:     fn_texts type text200 obligatory.
*PARAMETERS:     p_overw  AS CHECKBOX.
selection-screen end of block bl1.

selection-screen begin of block bl2 with frame title text-bl2.
parameters:   fn_log type text200.
parameters:   pa_test as checkbox default c_true.
selection-screen end of block bl2.
