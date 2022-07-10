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
  REFRESH: lt_kehr_auft, lt_zsd_04_kehricht.
* Lesen aller Fakturen im selben Zeitraum zum Objekt
  SELECT * FROM zsd_05_kehr_auft INTO TABLE lt_kehr_auft WHERE
     obj_key IN s_objkey AND
     verr_datum IN s_verd AND
    verr_datum_schl IN s_verds AND
    faknr IN s_faknr.

  IF sy-dbcnt GT 0.
    SORT lt_kehr_auft.

    SELECT * FROM zsd_04_kehricht  INTO TABLE lt_zsd_04_kehricht FOR ALL ENTRIES IN lt_kehr_auft WHERE
      stadtteil = lt_kehr_auft-stadtteil AND
      parzelle = lt_kehr_auft-parzelle AND
      objekt   = lt_kehr_auft-objekt.
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

  IF NOT  lt_kehr_auft[] IS INITIAL.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table   = obj_kehr_auft_alv
                      CHANGING
            t_table        =  lt_kehr_auft
               ).
        obj_kehr_auft_alv->get_columns( )->set_optimize( abap_true ).

      CATCH cx_salv_msg .
        WRITE: / text-m01.
    ENDTRY.

    lobj_functions = obj_kehr_auft_alv->get_functions( ).
    lobj_functions->set_all( abap_true ).
    obj_kehr_auft_alv->display( ).
else.
  WRITE: / text-m02.
  ENDIF.
ENDFORM.                    "DATEN_AUSGEBEN
" DATEN_AUSGEBEN
*&---------------------------------------------------------------------*
*&      Form  DELETE_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM delete_status .

  REFRESH lt_lulu_head.

  SELECT * FROM zsd_05_lulu_head INTO TABLE lt_lulu_head WHERE
             obj_key IN s_objkey
       AND eigen_kunnr IN s_kunnr.
  IF sy-dbcnt GT 0.
    LOOP AT lt_lulu_head ASSIGNING  <fs_lulu_head>.
      CLEAR <fs_lulu_head>-status.
    ENDLOOP.
    MODIFY zsd_05_lulu_head FROM TABLE lt_lulu_head.

    IF sy-subrc = 0.
      MESSAGE s001(zsd)."Löschung des Fallstatus der Gesuche erforlgreich.
    ENDIF.
  ENDIF.
ENDFORM.                    " DELETE_STATUS
*&---------------------------------------------------------------------*
*&      Form  DATEN_AUFBEREITEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM daten_aufbereiten .
  SORT lt_zsd_04_kehricht.
  SORT lt_kehr_auft.

  LOOP AT lt_kehr_auft INTO ls_kehr_auft.
    READ TABLE lt_zsd_04_kehricht INTO ls_zsd_04_kehricht WITH KEY stadtteil = ls_kehr_auft-stadtteil
    parzelle = ls_kehr_auft-parzelle
    objekt = ls_kehr_auft-objekt.
    IF sy-subrc = 0.
      MOVE ls_zsd_04_kehricht-eigen_kunnr TO ls_kehr_auft-kunnr.
      MODIFY lt_kehr_auft FROM ls_kehr_auft.
      MODIFY zsd_05_kehr_auft FROM ls_kehr_auft.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " DATEN_AUFBEREITEN
