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
  REFRESH: lt_kehr_auft, lt_lulu_head, lt_lulu_fakt, lt_lulu_prot.

  SELECT * FROM zsd_05_lulu_prot INTO TABLE lt_lulu_prot.
  DELETE zsd_05_lulu_prot FROM TABLE lt_lulu_prot.
  SELECT * FROM zsd_05_lulu_head INTO TABLE lt_lulu_head WHERE
          obj_key IN s_objkey
     AND rg_kunnr IN s_kunnr
    AND
    status = ' '.


* Lesen aller Fakturen im selben Zeitraum zum Objekt
  IF sy-dbcnt GT 0.
    SORT lt_lulu_head.

    SELECT * FROM zsd_05_lulu_fakt INTO TABLE lt_lulu_fakt FOR ALL ENTRIES IN lt_lulu_head
      WHERE fallnr = lt_lulu_head-fallnr.


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

  IF NOT  lt_lulu_prot[] IS INITIAL.

    TRY.


        cl_salv_table=>factory(
          IMPORTING
            r_salv_table   = obj_kehr_auft_alv
                      CHANGING
            t_table        =  lt_lulu_prot
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

    LOOP AT lt_lulu_prot INTO ls_lulu_prot.
      MODIFY zsd_05_lulu_prot FROM ls_lulu_prot.
    ENDLOOP.

* Gesuchs-Kopftabelle fortschreinben
    IF p_stat = 'X'.
      LOOP AT lt_lulu_head INTO ls_lulu_head.
        MODIFY zsd_05_lulu_head FROM ls_lulu_head.
      ENDLOOP.
    ENDIF.
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
  SORT lt_lulu_head.
  SORT lt_kehr_auft.

  lv_aenam  = sy-uname.
  lv_aedat = sy-datum.
  lv_aezet = sy-uzeit.
  LOOP AT lt_lulu_head INTO ls_lulu_head.
* 1. Unterschiedliche Rechnungsempfänger Fakturabelege
    PERFORM  set_status_on_kunnr USING  ls_lulu_head-fallnr
                                       ls_lulu_head-stadtteil
                                       ls_lulu_head-parzelle
                                       ls_lulu_head-objekt
                                       ls_lulu_head-rg_kunnr
                                CHANGING ls_lulu_head-status
                                         ls_lulu_prot-grund.
    IF ls_lulu_head-status = 'Q'.

      MODIFY lt_lulu_head FROM ls_lulu_head.
      MOVE-CORRESPONDING ls_lulu_head TO ls_lulu_prot.
      ls_lulu_prot-aenam  = lv_aenam.
      ls_lulu_prot-aedat  = lv_aedat.
      ls_lulu_prot-aezet  = lv_aezet.
      APPEND ls_lulu_prot TO lt_lulu_prot.
      CONTINUE.
    ELSE.

* 2. kleinstes Fakturadatum VERR_DATUM <> Periodenbeginn
      PERFORM  set_status_on_per_beginn USING ls_lulu_head-stadtteil
                                     ls_lulu_head-parzelle
                                     ls_lulu_head-objekt
                                     ls_lulu_head-per_beginn
                              CHANGING ls_lulu_head-status
                                ls_lulu_prot-grund.
      IF ls_lulu_head-status = 'Q'.

        MODIFY lt_lulu_head FROM ls_lulu_head.
        MOVE-CORRESPONDING ls_lulu_head TO ls_lulu_prot.
        ls_lulu_prot-aenam  = lv_aenam.
        ls_lulu_prot-aedat  = lv_aedat.
        ls_lulu_prot-aezet  = lv_aezet.
        APPEND ls_lulu_prot TO lt_lulu_prot.
        CONTINUE.
      ELSE.
* 3. grösstes Fakturadatum VERR_DATUM_schL <> Periodenende
        PERFORM  set_status_on_per_ende USING ls_lulu_head-stadtteil
                                       ls_lulu_head-parzelle
                                       ls_lulu_head-objekt
                                       ls_lulu_head-per_ende
                                CHANGING ls_lulu_head-status
                                  ls_lulu_prot-grund.
        IF ls_lulu_head-status = 'Q'.
          MODIFY lt_lulu_head FROM ls_lulu_head.
          MOVE-CORRESPONDING ls_lulu_head TO ls_lulu_prot.
          ls_lulu_prot-aenam  = lv_aenam.
          ls_lulu_prot-aedat  = lv_aedat.
          ls_lulu_prot-aezet  = lv_aezet.
          APPEND ls_lulu_prot TO lt_lulu_prot.
          CONTINUE.
        ELSE.
* 4. Beträge je nach Nutzungsart
          PERFORM  set_status_on_nutz_art USING ls_lulu_head-stadtteil
                                         ls_lulu_head-parzelle
                                         ls_lulu_head-objekt
                                         ls_lulu_head-nutz_art
                                         ls_lulu_head-rueckerst_art
                                  CHANGING ls_lulu_head-status
                                           ls_lulu_prot-grund.
          IF ls_lulu_head-status <> ' '.
            MODIFY lt_lulu_head FROM ls_lulu_head.
            MOVE-CORRESPONDING ls_lulu_head TO ls_lulu_prot.
            ls_lulu_prot-aenam  = lv_aenam.
            ls_lulu_prot-aedat  = lv_aedat.
            ls_lulu_prot-aezet  = lv_aezet.
            APPEND ls_lulu_prot TO lt_lulu_prot.

            CONTINUE.
          ELSE.

          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.



  ENDLOOP.
ENDFORM.                    " DATEN_AUFBEREITEN
*&---------------------------------------------------------------------*
*&      Form  SET_STATUS_ON_KUNNR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_LULU_HEAD_STADTTEIL  text
*      -->P_LS_LULU_HEAD_PARZELLE  text
*      -->P_LS_LULU_HEAD_OBJEKT  text
*      <--P_LS_LULU_HEAD_STATUS  text
*----------------------------------------------------------------------*
FORM set_status_on_kunnr  USING    lv_fallnr TYPE zsdekpfallnr
                                   lv_stadtteil TYPE zz_stadtteil
                                   lv_parzelle TYPE zz_parz_nr
                                   lv_objekt TYPE zz_parz_teil
                                   lv_kunnr TYPE z_rg_kunnr
                          CHANGING lv_status TYPE zz_status
                                    lv_grund TYPE zz_grund.

  DATA: s_first TYPE c LENGTH 1 VALUE 'X'.

  DATA: lv_faknr TYPE vbeln.
  DATA: lv_vbeln TYPE vbeln_vf.

  REFRESH lt_kehr_auft. CLEAR ls_kehr_auft.

  SELECT * FROM zsd_05_kehr_auft INTO TABLE lt_kehr_auft WHERE
         stadtteil = lv_stadtteil
    AND parzelle = lv_parzelle
    AND objekt = lv_objekt
    AND verr_datum IN s_perst
    AND verr_datum_schl IN s_pered.

  IF sy-dbcnt GT 0.


    LOOP AT lt_lulu_fakt INTO ls_lulu_fakt  WHERE
                                 fallnr = lv_fallnr.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT':"
                  EXPORTING input = ls_lulu_fakt-vbeln
                  IMPORTING output = lv_faknr.

      READ TABLE lt_kehr_auft INTO ls_kehr_auft WITH KEY
                                   stadtteil = lv_stadtteil
                               parzelle  = lv_parzelle
                                objekt    = lv_objekt
                                faknr   =  lv_faknr .

      IF sy-subrc = 0.
        IF  lv_kunnr NE ls_kehr_auft-kunnr.
          lv_status = 'Q'.
          lv_grund = 'RE'.
          EXIT.
        ENDIF.
      ELSE.
* Rechnung gehört nicht zum Objekt
        lv_status = 'Q'.
        lv_grund = 'FR'.
        EXIT.
      ENDIF.

    ENDLOOP.

  ELSE.
* Falsches Objekt
    lv_status = 'Q'.
    lv_grund = 'FO'.
    EXIT.
  ENDIF.

* Mit der Struktur KEHR_AUFT muss weitergearbeitet werden, deshalb alle Fakturen löschen, die nicht
* in der LULU_FAKT sind.
  LOOP AT lt_kehr_auft INTO ls_kehr_auft.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT':"
                EXPORTING input = ls_kehr_auft-faknr
                IMPORTING output = lv_vbeln.

    READ TABLE lt_lulu_fakt INTO ls_lulu_fakt WITH KEY vbeln = lv_vbeln.
    IF sy-subrc <> 0.
      DELETE lt_kehr_auft.
    ENDIF.

  ENDLOOP.



ENDFORM.                    " SET_STATUS_ON_KUNNR
*&---------------------------------------------------------------------*
*&      Form  SET_STATUS_ON_PER_ENDE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_LULU_HEAD_STADTTEIL  text
*      -->P_LS_LULU_HEAD_PARZELLE  text
*      -->P_LS_LULU_HEAD_OBJEKT  text
*      <--P_LS_LULU_HEAD_STATUS  text
*----------------------------------------------------------------------*
FORM set_status_on_per_ende   USING    lv_stadtteil TYPE zz_stadtteil
                                   lv_parzelle TYPE zz_parz_nr
                                   lv_objekt TYPE zz_parz_teil
                                  lv_per_ende TYPE  ld_pered
                          CHANGING lv_status TYPE zz_status
                                   lv_grund TYPE zz_grund.

  DATA: lv_verr_datum_schl TYPE ld_pered.
  LOOP AT lt_kehr_auft INTO ls_kehr_auft WHERE
                              stadtteil = lv_stadtteil
                          AND parzelle  = lv_parzelle
                          AND objekt    = lv_objekt .
    IF  lv_verr_datum_schl IS INITIAL.
      lv_verr_datum_schl = ls_kehr_auft-verr_datum_schl.
    ELSE.
      IF ls_kehr_auft-verr_datum_schl  GT lv_verr_datum_schl.
        lv_verr_datum_schl = ls_kehr_auft-verr_datum_schl.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF lv_verr_datum_schl  NE lv_per_ende.
    lv_status = 'Q'.
    lv_grund = 'PE'.
  ENDIF.

ENDFORM.                    " SET_STATUS_ON_PER_ENDE
*&---------------------------------------------------------------------*
*&      Form  SET_STATUS_ON_PER_BEGINN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_LULU_HEAD_STADTTEIL  text
*      -->P_LS_LULU_HEAD_PARZELLE  text
*      -->P_LS_LULU_HEAD_OBJEKT  text
*      <--P_LS_LULU_HEAD_STATUS  text
*----------------------------------------------------------------------*
FORM set_status_on_per_beginn   USING    lv_stadtteil TYPE zz_stadtteil
                                   lv_parzelle TYPE zz_parz_nr
                                   lv_objekt TYPE zz_parz_teil
                                   lv_per_beginn TYPE  ld_perst
                          CHANGING lv_status TYPE zz_status
                                     lv_grund TYPE zz_grund.

  DATA: lv_verr_datum TYPE ld_perst.

* zuerst das älteste Fakturadatum
  LOOP AT lt_kehr_auft INTO ls_kehr_auft WHERE
                              stadtteil = lv_stadtteil
                          AND parzelle  = lv_parzelle
                          AND objekt    = lv_objekt .

    IF  lv_verr_datum IS INITIAL.
      lv_verr_datum = ls_kehr_auft-verr_datum.
    ELSE.
      IF ls_kehr_auft-verr_datum  LT lv_verr_datum.
        lv_verr_datum = ls_kehr_auft-verr_datum.
      ENDIF.
    ENDIF.

  ENDLOOP.


  IF lv_verr_datum  NE lv_per_beginn.
    lv_status = 'Q'.
    lv_grund = 'PB'.
  ENDIF.
ENDFORM.                    " SET_STATUS_ON_PER_BEGINN
*&---------------------------------------------------------------------*
*&      Form  SET_STATUS_ON_NUTZ_ART
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_LULU_HEAD_STADTTEIL  text
*      -->P_LS_LULU_HEAD_PARZELLE  text
*      -->P_LS_LULU_HEAD_OBJEKT  text
*      -->P_LS_LULU_HEAD_NUTZ_ART  text
*      -->P_LS_LULU_HEAD_RUECKERST_ART  text
*      <--P_LS_LULU_HEAD_STATUS  text
*----------------------------------------------------------------------*
FORM set_status_on_nutz_art  USING  lv_stadtteil TYPE zz_stadtteil
                                    lv_parzelle TYPE zz_parz_nr
                                    lv_objekt TYPE zz_parz_teil
                                    lv_nutz_art TYPE zz_nutz_art
                                    lv_rueckerst_art TYPE zz_rueckerst_art
                           CHANGING lv_status TYPE zz_status
                                    lv_grund TYPE zz_grund.

  DATA: lv_brwtr TYPE amunt.
  CASE lv_nutz_art.

    WHEN '1' OR '3'. "vollständig selbstgenutzt (nicht vermietet) oder
      "andere fremde Nutzung (Nutzniessung, Wohnrecht, etc.)
      LOOP AT lt_kehr_auft INTO ls_kehr_auft WHERE
                                  stadtteil = lv_stadtteil
                              AND parzelle  = lv_parzelle
                              AND objekt    = lv_objekt .

        IF  ls_kehr_auft-brtwr GT p_amunt .
          lv_status = 'Q'.
          lv_grund = 'N1'.
          EXIT.
        ELSEIF ls_kehr_auft-brtwr LE p_amunt .
          lv_status = 'A'.
          lv_grund = 'N1'.
        ENDIF.
      ENDLOOP.

    WHEN '2'. "vollständig oder teilweise vermietet

      CASE lv_rueckerst_art.
        WHEN '1'."Rückerstattung mit Rückzahlungsplan
          lv_status = ' '.
          lv_grund = 'N2'.
        WHEN '2'."Rückerstattung mit Pauschallösung
          lv_status = 'A'.
          lv_grund = 'N2'.
        WHEN OTHERS.
      ENDCASE.



*    WHEN '3'. "andere fremde Nutzung (Nutzniessung, Wohnrecht, etc.)

    WHEN OTHERS.
  ENDCASE.

ENDFORM.                    " SET_STATUS_ON_NUTZ_ART
