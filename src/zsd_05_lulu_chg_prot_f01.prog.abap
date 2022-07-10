*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_ANALYSE_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  DATEN_SELEKTIEREN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM daten_selektieren .
  REFRESH: lt_chg_prot .
* Lesen aller Änderungen   zum Objekt
  SELECT * FROM zsd_04_chg_prot INTO TABLE lt_chg_prot WHERE
     obj_key IN s_objkey AND
     tabname IN s_tabn AND
    fieldname IN s_fname AND
    newval IN s_newv AND
    oldval IN s_oldv AND
    erdat IN s_erdat AND
    ernam  IN s_ernam AND
    erzet IN s_erzet.

  IF sy-dbcnt =  0.
    MESSAGE e012(zsd_05_lulu).
    "Keine protokollierten Änderungen zur Selektion gefunden!
  ENDIF.


ENDFORM.                    " DATEN_SELEKTIEREN
*&---------------------------------------------------------------------*
*&      Form  DATEN_AUSGEBEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM daten_ausgeben .


  DATA lobj_events    TYPE REF TO cl_salv_events_table.
  DATA lw_layout TYPE slis_layout_alv.
  DATA lobj_functions TYPE REF TO cl_salv_functions_list.

  lw_layout-zebra = abap_true.
  lw_layout-colwidth_optimize = abap_true.

  IF NOT  lt_chg_prot[] IS INITIAL.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table   = obj_kehr_auft_alv
                      CHANGING
            t_table        =  lt_chg_prot
               ).
        obj_kehr_auft_alv->get_columns( )->set_optimize( abap_true ).

      CATCH cx_salv_msg .
        WRITE: / text-m01.
    ENDTRY.

    lobj_functions = obj_kehr_auft_alv->get_functions( ).
    lobj_functions->set_all( abap_true ).
    obj_kehr_auft_alv->display( ).
  ELSE.
    WRITE: / text-m02.
  ENDIF.
ENDFORM.                    "DATEN_AUSGEBEN
" DATEN_AUSGEBEN
