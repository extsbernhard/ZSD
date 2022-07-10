*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_REQU_MIG
*&
*&---------------------------------------------------------------------*
*& Migration der Request-Daten von den Basis-Daten ZSD_05_KEHR_AUFT
*& mit den entsprechenden Zusatzdaten der Standard-Tabellen
*&---------------------------------------------------------------------*

INCLUDE zsd_05_lulu_requ_migtop.    " global Data
INCLUDE zsd_05_lulu_requ_migf01.    " FORM-Routines

* INCLUDE ZSD_05_LULU_REQU_MIGO01                 .  " PBO-Modules
* INCLUDE ZSD_05_LULU_REQU_MIGI01                 .  " PAI-Modules




*_____Selektionsbild_____

SELECTION-SCREEN BEGIN OF BLOCK bl0 WITH FRAME TITLE text-bl0.
SELECT-OPTIONS: s_objkey FOR gs_kehr_auft-obj_key.
SELECTION-SCREEN END OF BLOCK bl0.

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE text-bl1.
PARAMETERS: vrgdat   TYPE datum OBLIGATORY,
            vrgdat_s TYPE datum OBLIGATORY.
PARAMETERS: p_test TYPE flag DEFAULT 'X'. "Testlauf
PARAMETERS: p_del TYPE flag.

SELECTION-SCREEN END OF BLOCK bl1.




*_____Auswertung_____


START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's

  IF p_del = abap_true AND p_test = abap_false.

    REFRESH: gt_lulu_head, gt_lulu_fakt.
    DELETE   zsd_05_lulu_hd02 FROM TABLE gt_lulu_head.
    DELETE   zsd_05_lulu_fk02 FROM TABLE gt_lulu_fakt.
  ENDIF.

  SELECT * FROM zsd_05_kehr_auft AS ka1 INNER JOIN vbrk AS v1 ON v1~vbeln = ka1~faknr
    INTO CORRESPONDING FIELDS OF TABLE gt_kehr_auft
    WHERE fksto EQ space
      AND obj_key IN s_objkey
      AND verr_datum      BETWEEN vrgdat AND vrgdat_s
      AND verr_datum_schl BETWEEN vrgdat AND vrgdat_s.
*    ORDER BY stadtteil parzelle objekt kunnr verr_datum verr_datum_schl.


  LOOP AT gt_kehr_auft INTO gs_kehr_auft.
    CONCATENATE gs_kehr_auft-stadtteil gs_kehr_auft-parzelle gs_kehr_auft-objekt gs_kehr_auft-kunnr INTO gs_kehr_auft-fall.
    MODIFY gt_kehr_auft FROM gs_kehr_auft.
  ENDLOOP.

  SORT gt_kehr_auft BY fall verr_datum verr_datum_schl.


  LOOP AT gt_kehr_auft INTO gs_kehr_auft.

    CLEAR: gs_kehr_auft_store.
    gs_kehr_auft_store = gs_kehr_auft.

    AT NEW fall.
      "KOPFDATEN
      CLEAR: gs_lulu_head.

      "Neue Fallnummer vergeben
      PERFORM  get_new_fallnr CHANGING gs_lulu_head-fallnr.

      "Weitere Kopfdaten füllen
      gs_lulu_head-stadtteil   = gs_kehr_auft_store-stadtteil.
      gs_lulu_head-parzelle    = gs_kehr_auft_store-parzelle.
      gs_lulu_head-objekt      = gs_kehr_auft_store-objekt.
      gs_lulu_head-per_beginn  = gs_kehr_auft_store-verr_datum.
      gs_lulu_head-rg_kunnr    = gs_kehr_auft_store-kunnr.
      gs_lulu_head-obj_key    = gs_kehr_auft_store-obj_key. ">001<

    ENDAT.

    SELECT SINGLE * FROM   zsd_05_lulu_help INTO gs_lulu_mig_hlp ">001<
        WHERE        stadtteil   = gs_kehr_auft_store-stadtteil
                 AND parzelle    = gs_kehr_auft_store-parzelle
                 AND objekt      = gs_kehr_auft_store-objekt
                 AND per_beginn  = gs_kehr_auft_store-verr_datum
                 AND kunnr       = gs_kehr_auft_store-kunnr.
* offene Fakturen
    IF sy-subrc = 0. ">001<
      gs_lulu_head-status = 'S'. "Sonderbehandlung ">001<
    ENDIF. ">001<

    "FAKTURADATEN
    CLEAR: gs_lulu_fakt.
    gs_lulu_fakt-fallnr = gs_lulu_head-fallnr.
    gs_lulu_fakt-vbeln  = gs_kehr_auft_store-faknr.
    gs_lulu_fakt-fkdat  = gs_kehr_auft_store-fkdat.
    PERFORM get_fakt_data CHANGING gs_lulu_fakt.
    gs_lulu_fakt-verrg_beginn = gs_kehr_auft_store-verr_datum.
    gs_lulu_fakt-verrg_ende   = gs_kehr_auft_store-verr_datum_schl.
    APPEND gs_lulu_fakt TO gt_lulu_fakt.



    AT END OF fall.
      "letztes Schluss-Verrechnungsdatum fortschreiben
      gs_lulu_head-per_ende    = gs_kehr_auft_store-verr_datum_schl.

      "Eigentümer, Vertreter, Angabensperre und Auszahlungsangaben setzen
      IF gs_lulu_head-per_beginn EQ '20110101'.
        SELECT SINGLE * FROM zsd_05_lulu_head INTO gs_lulu_head_form
          WHERE stadtteil EQ gs_lulu_head-stadtteil
            AND parzelle  EQ gs_lulu_head-parzelle
            AND objekt    EQ gs_lulu_head-objekt
            AND rg_kunnr  EQ gs_lulu_head-rg_kunnr
            AND per_ende  EQ '20101231'.

        IF sy-subrc EQ 0.

          gs_lulu_head-angaben_sperre_x = abap_true.
          IF gs_lulu_head-status = ''.  ">001<
            PERFORM set_status USING gs_lulu_head-angaben_sperre_x  ">001<
                                     gs_lulu_head_form-rueckzlg_quote ">001<
                                     gs_lulu_head_form-nutz_art ">001<
                               CHANGING gs_lulu_head-status ">001<
                                 gs_lulu_head_form.">001< scd
            gs_lulu_head_form-obj_key = gs_lulu_head-obj_key. ">001<
          ENDIF.  ">001<

          gs_lulu_head-eigen_kunnr = gs_lulu_head_form-eigen_kunnr.
          gs_lulu_head-vertr_kunnr = gs_lulu_head_form-vertr_kunnr.
          gs_lulu_head-mwst_nr     = gs_lulu_head_form-mwst_nr.
          gs_lulu_head-eigda       = gs_lulu_head_form-eigda.
          gs_lulu_head-vorsteuerx  = gs_lulu_head_form-vorsteuerx.
          gs_lulu_head-name1_ausz  = gs_lulu_head_form-name1_ausz.
          gs_lulu_head-name2_ausz  = gs_lulu_head_form-name2_ausz.
          gs_lulu_head-stras_ausz  = gs_lulu_head_form-stras_ausz.
          gs_lulu_head-ort1_ausz   = gs_lulu_head_form-ort1_ausz.
          gs_lulu_head-pstlz_ausz  = gs_lulu_head_form-pstlz_ausz.
          gs_lulu_head-bankl_ausz  = gs_lulu_head_form-bankl_ausz.
          gs_lulu_head-bankn_ausz  = gs_lulu_head_form-bankn_ausz.
          gs_lulu_head-wrbtr_ausz  = gs_lulu_head_form-wrbtr_ausz.
          gs_lulu_head-esrnr_ausz  = gs_lulu_head_form-esrnr_ausz.
          gs_lulu_head-esrre_ausz  = gs_lulu_head_form-esrre_ausz.
          gs_lulu_head-konto_ausz  = gs_lulu_head_form-konto_ausz.
          gs_lulu_head-sgtxt_ausz  = gs_lulu_head_form-sgtxt_ausz.

        ENDIF.
      ENDIF.



      IF p_test EQ abap_false.
        INSERT zsd_05_lulu_hd02 FROM gs_lulu_head.
        INSERT zsd_05_lulu_fk02 FROM TABLE gt_lulu_fakt.

      ENDIF.
      IF sy-subrc EQ 0.
        CLEAR: gs_lulu_head.
        REFRESH gt_lulu_fakt.
      ENDIF.
      IF gs_lulu_head_form IS NOT INITIAL.
        UPDATE zsd_05_lulu_head FROM gs_lulu_head_form. "Status 'A' ">001<
        CLEAR gs_lulu_head_form.
      ENDIF.
    ENDAT.
  ENDLOOP.

  break weber1.
