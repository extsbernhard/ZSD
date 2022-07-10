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
  REFRESH: lt_kehr_auft.

  SELECT * FROM zsd_05_kehr_auft INTO TABLE lt_kehr_auft WHERE
          obj_key IN s_objkey
    AND vbeln IN s_vbeln
    AND verr_datum IN s_vrdata
    AND verr_datum_schl IN s_vrdate
    AND kennz = p_kennz.

* Lesen aller Fakturen im selben Zeitraum zum Objekt
  IF sy-dbcnt GT 0.
    SORT lt_kehr_auft.

    SELECT * FROM zsd_05_kehr_auft INTO TABLE lt_kehr_auft_h FOR ALL ENTRIES IN
               lt_kehr_auft     WHERE
             obj_key = lt_kehr_auft-obj_key
*       AND vbeln = lt_kehr_auft-vbeln
       AND verr_datum = lt_kehr_auft-verr_datum
       AND verr_datum_schl = lt_kehr_auft-verr_datum_schl
       AND kennz NE lt_kehr_auft-kennz.
  ENDIF.

  APPEND LINES OF lt_kehr_auft_h to lt_kehr_auft.
  sort lt_kehr_auft.


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

  IF NOT lt_kehr_auft[] IS INITIAL.

    TRY.


        cl_salv_table=>factory(
          IMPORTING
            r_salv_table   = obj_kehr_auft_alv
                      CHANGING
            t_table        = lt_kehr_auft
               ).
        obj_kehr_auft_alv->get_columns( )->set_optimize( abap_true ).

      CATCH cx_salv_msg .
        WRITE: / text-m01.
    ENDTRY.

*    lobj_events = obj_cats_tabelle->get_event( ).
*
*    SET HANDLER
*      lcl_events=>on_added_function
*      FOR lobj_events.
*
*
*    obj_cats_tabelle->set_screen_status(
*      EXPORTING
*        report        = 'ZSD_05_LULU_ANALYSE'
*        pfstatus      = 'stst'
*        set_functions = obj_kehr_auft_ALv->c_functions_all
*    ).


    lobj_functions = obj_kehr_auft_alv->get_functions( ).
    lobj_functions->set_all( abap_true ).
    obj_kehr_auft_alv->display( ).
  ENDIF.
ENDFORM.                    "DATEN_AUSGEBEN
" DATEN_AUSGEBEN
