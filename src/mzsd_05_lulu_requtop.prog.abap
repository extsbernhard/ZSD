*&---------------------------------------------------------------------*
*& Modulpool        SAPMZSD_05_LULU_REQU
*&
*&---------------------------------------------------------------------*

PROGRAM  sapmzsd_05_lulu_requ.

TYPE-POOLS: abap.

TABLES: zsd_05_lulu_hd02,
         zsd_04_kehr_mat .

TYPES: BEGIN OF ty_lulu_head.
        INCLUDE TYPE zsd_05_lulu_hd02.
TYPES:  flag    TYPE c,
        action  TYPE c,  " Modify (M) = Insert oder Update ; Delete (D) = Löschen
        delable TYPE c,  " X = löschbar ohne DB-Update
       END OF ty_lulu_head.

TYPES: BEGIN OF ty_lulu_fakt.
        INCLUDE TYPE zsd_05_lulu_fk02.
TYPES:  flag    TYPE c,
        action  TYPE c,  " Modify (M) = Insert oder Update ; Delete (D) = Löschen
        delable TYPE c,  " X = löschbar ohne DB-Update
       END OF ty_lulu_fakt.

DATA: gs_lulu_head TYPE ty_lulu_head,
      gt_lulu_head TYPE STANDARD TABLE OF ty_lulu_head,
      gs_lulu_fakt TYPE ty_lulu_fakt,
      gt_lulu_fakt TYPE STANDARD TABLE OF ty_lulu_fakt,
      gt_lulu_fakt_del TYPE STANDARD TABLE OF ty_lulu_fakt.

DATA: gs_kna1 TYPE kna1, "Debitor generell
      gs_adrs_print TYPE adrs_print.


"Interne Tabelle für exkludierende Funktionen
DATA: gt_fcode_excludes TYPE STANDARD TABLE OF sy-ucomm,
      gs_fcode_excludes TYPE sy-ucomm.


DATA: ok_code TYPE sy-ucomm,
      gv_subrc TYPE sy-subrc,

      gv_create        TYPE c,
      gv_create_store  TYPE c,
      gv_update        TYPE c,
      gv_update_store  TYPE c,
      gv_display       TYPE c,
      gv_display_store TYPE c,
      gv_delete        TYPE c,
      gv_delete_store  TYPE c,
      gv_enqu          TYPE c,
      gv_enqu_store    TYPE c,
      gv_readonly      TYPE c,

      gv_fieldname TYPE string,
      gv_strucstr  TYPE dynfnam,
      gv_fldstr    TYPE dynfnam,
      gv_obj_addr  TYPE text200,
      gv_obj       TYPE string.


DATA: gs_et_addr_print TYPE adrs_print,
      gs_vt_addr_print TYPE adrs_print,
      gs_re_addr_print TYPE adrs_print,
      gv_eigen_ver_val TYPE dd07t-ddtext,
      gv_anschr_art_val TYPE dd07t-ddtext,
      gv_rueckerst_art_val TYPE dd07t-ddtext,
      gv_nutz_art_val TYPE dd07t-ddtext.

"Buttons für dynamische Textsteuerung
DATA: btn_eig_mod TYPE string,
      btn_ver_mod TYPE string,
      btn_rem_mod TYPE string,
      btn_trans_rg_eig TYPE string,
      btn_trans_rg_ver TYPE string.


CONSTANTS: c_insert TYPE c VALUE 'I',
           c_update TYPE c VALUE 'U',
           c_modify TYPE c VALUE 'M',
           c_delete TYPE c VALUE 'D',

           c_enqmode TYPE enqmode VALUE 'E', "Sperrmodus

           c_kgd TYPE ktokd VALUE 'ZG00', "Kontengruppe Debitor

           c_nk_obj TYPE nrobj VALUE 'ZKGG', "Nummernkreisobjekt
           c_nk_nrr TYPE nrnr  VALUE '02'.   "Nummernkreisnummer


*&SPWIZARD: DECLARATION OF TABLECONTROL 'TC_FAKT' ITSELF
CONTROLS: tc_fakt TYPE TABLEVIEW USING SCREEN 2000.

*&SPWIZARD: LINES OF TABLECONTROL 'TC_FAKT'
DATA:     g_tc_fakt_lines  LIKE sy-loopc.
