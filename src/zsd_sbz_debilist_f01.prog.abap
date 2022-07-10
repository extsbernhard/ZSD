*&---------------------------------------------------------------------*
*&  Include           ZSD_SBZ_DEBILIST_F01
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
FORM u0010_get_kundendaten.

* data: .
  CASE p_apalle.
    WHEN ' '. "Selektion über alle Debitoren
      SELECT * FROM knvv INTO CORRESPONDING FIELDS OF TABLE t_debi_in
               WHERE kunnr IN s_kunnr
                 AND vkorg IN s_vkorg
                 AND vtweg IN s_vtweg
                 AND kdgrp IN s_kdgrp
                 AND loevm EQ c_leer.
    WHEN 'X'. "Selektion über ALLE Ansprechpartner
      SELECT * FROM knvv INTO CORRESPONDING FIELDS OF TABLE t_debi_in
               FOR ALL ENTRIES IN t_knvk
               WHERE kunnr EQ t_knvk-kunnr
                 AND vkorg IN s_vkorg
                 AND vtweg IN s_vtweg
                 AND kdgrp IN s_kdgrp
                 AND loevm EQ c_leer.
    WHEN OTHERS.
*      do easily nothing
  ENDCASE.
  DESCRIBE TABLE t_debi_in LINES w_lines.
  CHECK w_lines > 0.
  SELECT * FROM kna1 INTO CORRESPONDING FIELDS OF TABLE t_kna1
           FOR ALL ENTRIES IN t_debi_in
           WHERE kunnr EQ t_debi_in-kunnr
             AND brsch IN s_brsch
             AND xcpdk EQ c_leer
             AND loevm EQ c_leer
           " Neue Selection Options IDDRI1 20190314
             AND bran1 IN s_bran1
           .
  LOOP AT t_debi_in INTO s_debi_in.
    READ TABLE t_kna1 WITH KEY kunnr = s_debi_in-kunnr.
    IF sy-subrc EQ 0.
      MOVE: t_kna1-adrnr        TO s_debi_in-adrnr_debi
          , t_kna1-brsch        TO s_debi_in-brsch
          , t_kna1-bran1        TO s_debi_in-bran1
          .
      PERFORM u0015_get_kundenadresse CHANGING s_debi_in.
      MODIFY t_debi_in FROM s_debi_in.
    ELSE.
      CLEAR: s_debi_in-adrnr_debi, s_debi_in-brsch.
      DELETE t_debi_in." from s_debi_in.
    ENDIF.
  ENDLOOP. "at t_debi_in.
ENDFORM." u0010_get_kundendaten.
*----------------------------------------------------------------------*
FORM u0015_get_kundenadresse CHANGING lw_debi_in LIKE s_debi_in.
*
  IF NOT lw_debi_in-adrnr_debi IS INITIAL.
*   Adressnummer des Debitors ist bestückt
    SELECT SINGLE * FROM adrc INTO s_adrc_debi
           WHERE addrnumber EQ lw_debi_in-adrnr_debi.
    IF sy-subrc NE 0.
      CLEAR s_adrc_debi.
    ENDIF.
    SELECT SINGLE * FROM adr6 INTO s_adr6_debi
           WHERE addrnumber EQ lw_debi_in-adrnr_debi
             AND persnumber EQ c_leer.
    IF sy-subrc NE 0.
      CLEAR s_adr6_debi.
    ENDIF.
    IF NOT s_adrc_debi IS INITIAL.
      MOVE: s_adrc_debi-name1       TO lw_debi_in-name1
          , s_adrc_debi-name2       TO lw_debi_in-name2
          , s_adrc_debi-name3       TO lw_debi_in-name3
          , s_adrc_debi-street      TO lw_debi_in-strasse
          , s_adrc_debi-house_num1  TO lw_debi_in-hausnr
          , s_adrc_debi-post_code1  TO lw_debi_in-plz_ort
          , s_adrc_debi-city1       TO lw_debi_in-ort
          , s_adrc_debi-po_box      TO lw_debi_in-postfach
          , s_adrc_debi-post_code2  TO lw_debi_in-plz_pfch
          , s_adrc_debi-po_box_loc  TO lw_debi_in-ort_pfch
          , s_adrc_debi-tel_number  TO lw_debi_in-tel_debi
          , s_adrc_debi-fax_number  TO lw_debi_in-fax_debi
          .
    ENDIF.
    IF NOT s_adr6_debi IS INITIAL.
      MOVE: s_adr6_debi-smtp_addr       TO lw_debi_in-email_debi.
    ENDIF.
  ENDIF.
*
ENDFORM." u0015_get_fk02_data.
*----------------------------------------------------------------------*
FORM u0020_get_ansprechpartner.
*
  "-- IDDRi1 Code ----------------------------------
  DATA lv_attribut TYPE string VALUE 'parh& in s_pakn1'.
  DATA lv_i TYPE n VALUE IS INITIAL.
  DATA lv_c TYPE c1.
  DATA: lt_knvk   LIKE TABLE OF t_knvk,
        ls_knvk   LIKE t_knvk,
        ls_knvk_n LIKE t_knvk.

  DO 5 TIMES.
    ADD 1 TO lv_i.
    lv_c = lv_i.
    REPLACE '&' WITH lv_c INTO lv_attribut.

    "--- IDDRI1 hinzufügen des Selektionsmerkmales pavip (Newsletter) 20180416

    CASE p_apalle.
      WHEN ' '.
        SELECT * FROM knvk APPENDING CORRESPONDING FIELDS OF TABLE lt_knvk
           FOR ALL ENTRIES IN t_debi_in
            WHERE kunnr EQ t_debi_in-kunnr
              AND pafkt IN s_pafkt " Funktion Ansprechpartner
              AND pavip IN s_pavip " Newsletter
              AND abtnr IN s_abtnr " Abteilung
              AND parvo IN s_parvo " Vollmacht
              AND abtpa IN s_abtpa
              AND loevm EQ c_leer
              AND (lv_attribut)
              .

      WHEN 'X'.
        SELECT * FROM knvk APPENDING CORRESPONDING FIELDS OF TABLE lt_knvk
            WHERE kunnr IN s_kunnr
              AND pafkt IN s_pafkt " Funktion Ansprechpartner
              AND pavip IN s_pavip " Newsletter
              AND abtnr IN s_abtnr " Abteilung
              AND parvo IN s_parvo " Vollmacht
              AND abtpa IN s_abtpa
              AND loevm EQ c_leer
              AND (lv_attribut)
              .
    ENDCASE.

    lv_attribut = 'parh& in s_pakn1'.

  ENDDO.

  CLEAR: lv_i, lv_c.
  lv_attribut = 'pakn& in s_pakn1'.

  DO 5 TIMES.
    ADD 1 TO lv_i.
    lv_c = lv_i.
    REPLACE '&' WITH lv_c INTO lv_attribut.

    CASE p_apalle.
      WHEN ' '.
        SELECT * FROM knvk APPENDING CORRESPONDING FIELDS OF TABLE lt_knvk
           FOR ALL ENTRIES IN t_debi_in
            WHERE kunnr EQ t_debi_in-kunnr
              AND pafkt IN s_pafkt " Funktion Ansprechpartner
              AND pavip IN s_pavip " Newsletter
              AND abtnr IN s_abtnr " Abteilung
              AND parvo IN s_parvo " Vollmacht
              AND abtpa IN s_abtpa
              AND loevm EQ c_leer
              AND (lv_attribut)
              .

      WHEN 'X'.
        SELECT * FROM knvk APPENDING CORRESPONDING FIELDS OF TABLE lt_knvk
            WHERE kunnr IN s_kunnr
*             AND pafkt IN s_pafkt
*             AND abtpa IN s_abtpa
*             AND loevm EQ c_leer
              AND pafkt IN s_pafkt " Funktion Ansprechpartner
              AND pavip IN s_pavip " Newsletter
              AND abtnr IN s_abtnr " Abteilung
              AND parvo IN s_parvo " Vollmacht
              AND abtpa IN s_abtpa
              AND loevm EQ c_leer
              AND (lv_attribut)
             .
    ENDCASE.

    lv_attribut = 'pakn& in s_pakn1'.

  ENDDO.

*  DATA lv_anz_var TYPE n.
*  DATA lv_anz_rec TYPE n.
*  DESCRIBE TABLE s_pakn1[]  LINES lv_anz_var.
*
**    ,    parnr            type parnr
**    ,    kunnr            type kunnr
**    ,    adrnd            type adrnd
*
*  SORT lt_knvk BY parnr ASCENDING.
*
*  LOOP AT lt_knvk INTO ls_knvk.
*    ADD 1 TO lv_anz_rec.
*
*    AT END OF parnr.
*      IF lv_anz_rec = lv_anz_var.
*        READ TABLE lt_knvk INTO ls_knvk_n INDEX sy-tabix.
*        APPEND ls_knvk_n TO t_knvk.
*      ENDIF.
*
*      CLEAR lv_anz_rec.
*    ENDAT.
*
*  ENDLOOP.

  SORT lt_knvk BY parnr ASCENDING.

  DELETE ADJACENT DUPLICATES FROM lt_knvk COMPARING parnr.
  APPEND LINES OF lt_knvk TO t_knvk.
  SORT t_knvk BY kunnr parnr.

  DESCRIBE TABLE t_knvk LINES w_lines.
  CHECK w_lines > 0.
  PERFORM u0010_get_kundendaten.
  CLEAR w_old_kunnr.
  CLEAR s_debi_in.
  LOOP AT t_knvk.
    IF s_debi_in-kunnr NE t_knvk-kunnr.
      CLEAR s_debi_in.
      READ TABLE t_debi_in INTO s_debi_in WITH KEY kunnr = t_knvk-kunnr.
      IF sy-subrc NE 0.
        CLEAR s_debi_in.
      ENDIF.
    ENDIF.
    IF NOT s_debi_in IS INITIAL.
      MOVE: t_knvk-name1 TO s_debi_in-name1_ap
          , t_knvk-namev TO s_debi_in-namev_ap
          , t_knvk-ort01 TO s_debi_in-ort01_ap
          , t_knvk-adrnd TO s_debi_in-adrnr_ap
          , t_knvk-telf1 TO s_debi_in-tel_ap
          , t_knvk-abtpa TO s_debi_in-abtpa
          , t_knvk-pafkt TO s_debi_in-pafkt
          , t_knvk-anred TO s_debi_in-anred
          , t_knvk-parge TO s_debi_in-parge
          , t_knvk-prsnr TO s_debi_in-prsnr
          , t_knvk-parnr TO s_debi_in-parnr
          "--- IDDRI1 20180416
          , t_knvk-pavip TO s_debi_in-pavip
          , t_knvk-abtnr TO s_debi_in-abtnr
          , t_knvk-parvo TO s_debi_in-parvo
          "--- IDDRI1 20180806
          , t_knvk-parh1 TO s_debi_in-parh1
          , t_knvk-parh2 TO s_debi_in-parh2
          , t_knvk-parh3 TO s_debi_in-parh3
          , t_knvk-parh4 TO s_debi_in-parh4
          , t_knvk-parh5 TO s_debi_in-parh5
          , t_knvk-pakn1 TO s_debi_in-pakn1
          , t_knvk-pakn2 TO s_debi_in-pakn2
          , t_knvk-pakn3 TO s_debi_in-pakn3
          , t_knvk-pakn4 TO s_debi_in-pakn4
          , t_knvk-pakn5 TO s_debi_in-pakn5
          .
*     if not s_debi_in-adrnr_ap is initial.
      PERFORM u0025_get_anspr_adresse CHANGING s_debi_in.
*     endif.
      IF w_old_kunnr EQ t_knvk-kunnr.
*       d.h. wir hatten schon einen solchen Datensatz.
        IF  p_deb1ap EQ c_activ
        AND p_deball EQ c_activ.
*          nur ein Ansprechpartner gewünscht, d.h. der hier nicht
        ELSEIF p_deb9ap EQ c_activ.
          APPEND s_debi_in TO t_debi_in.
        ENDIF.
      ELSE.
        APPEND s_debi_in TO t_debi_in.
*        modify t_debi_in from s_debi_in.
        w_old_kunnr = t_knvk-kunnr.
      ENDIF.
    ENDIF.
  ENDLOOP. "at t_knvk.
*

  lv_attribut = 'stop'.

ENDFORM." u0020_get_ansprechpartner
*----------------------------------------------------------------------*
FORM u0025_get_anspr_adresse CHANGING lw_debi_in   LIKE s_debi_in.
**
*
  IF NOT lw_debi_in-adrnr_ap IS INITIAL.
*   Adressnummer des Debitors ist bestückt
    SELECT SINGLE * FROM adrc INTO s_adrc_ap
           WHERE addrnumber EQ lw_debi_in-adrnr_ap.
    IF sy-subrc NE 0.
      CLEAR s_adrc_ap.
    ENDIF.
* Selektion neu mit lw_debi_in-adrnr_debi und lw_debi_in-prsnr
* 13.06.2017 H. Stettler
    SELECT SINGLE * FROM adr6 INTO s_adr6_ap
*           where ADDRNUMBER eq lw_debi_in-adrnr_ap.
            WHERE addrnumber EQ lw_debi_in-adrnr_debi
            AND   persnumber EQ lw_debi_in-prsnr.
    IF sy-subrc NE 0.
      CLEAR s_adr6_ap.
    ENDIF.
    IF NOT s_adrc_debi IS INITIAL.
      MOVE: s_adrc_ap-name1       TO lw_debi_in-name1_ap
          , s_adrc_ap-name2       TO lw_debi_in-namev_ap
          , s_adrc_ap-city1       TO lw_debi_in-ort01_ap
          , s_adrc_ap-tel_number  TO lw_debi_in-tel_ap
          , s_adrc_ap-fax_number  TO lw_debi_in-fax_ap
          .
    ENDIF.
    IF NOT s_adr6_debi IS INITIAL.
      MOVE: s_adr6_ap-smtp_addr       TO lw_debi_in-email_ap.
    ENDIF.
  ELSEIF NOT lw_debi_in-prsnr IS INITIAL.
*  lesen Daten des Ansprechpartners über die Personal-Nummer-Adresse
    CLEAR s_adrp_ap.
    SELECT SINGLE * FROM adrp INTO s_adrp_ap
           WHERE persnumber = lw_debi_in-prsnr.
    IF sy-subrc NE 0.
      CLEAR s_adrp_ap.
    ENDIF.
    IF NOT s_adrp_ap IS INITIAL.
      MOVE: s_adrp_ap-name_last   TO lw_debi_in-name1_ap
          , s_adrp_ap-name_first  TO lw_debi_in-namev_ap.
      CLEAR s_adr6_ap.
*     lesen E-Mail-Adresse zum Ansprechpartner und Company-Adresse
      SELECT SINGLE * FROM adr6 INTO s_adr6_ap
             WHERE addrnumber EQ s_adrp_ap-addr_comp
             AND   persnumber EQ s_adrp_ap-persnumber.
      IF sy-subrc NE 0.
        SELECT SINGLE * FROM adr6 INTO s_adr6_ap
               WHERE addrnumber EQ lw_debi_in-adrnr_debi
               AND   persnumber EQ s_adrp_ap-persnumber.
        IF sy-subrc NE 0.
          SELECT SINGLE * FROM adr6 INTO s_adr6_ap
                 WHERE persnumber EQ s_adrp_ap-persnumber.
          IF sy-subrc NE 0.
            CLEAR s_adr6_ap.
          ENDIF.
        ENDIF.
      ENDIF.
      IF NOT s_adr6_ap-smtp_addr IS INITIAL.
        MOVE: s_adr6_ap-smtp_addr       TO lw_debi_in-email_ap.
      ELSE.
        CLEAR: lw_debi_in-email_ap.
      ENDIF.
*     lesen Tel_Number zum Ansprechpartner und Company-Adresse
      CLEAR s_adr2_ap.
      SELECT SINGLE * FROM adr2 INTO s_adr2_ap
             WHERE addrnumber EQ s_adrp_ap-addr_comp
             AND   persnumber EQ s_adrp_ap-persnumber.
      IF NOT s_adr2_ap-tel_number IS INITIAL.
        MOVE: s_adr2_ap-tel_number  TO lw_debi_in-tel_ap.
      ELSE.
        CLEAR: lw_debi_in-tel_ap.
      ENDIF.
*     lesen Fax_Number zum Ansprechpartner und Company-Adresse
      CLEAR s_adr3_ap.
      SELECT SINGLE * FROM adr3 INTO s_adr3_ap
             WHERE addrnumber EQ s_adrp_ap-addr_comp
             AND   persnumber EQ s_adrp_ap-persnumber.
      IF NOT s_adr3_ap-fax_number IS INITIAL.
        MOVE: s_adr3_ap-fax_number  TO lw_debi_in-fax_ap.
      ELSE.
        CLEAR: lw_debi_in-fax_ap.
      ENDIF.
    ENDIF.
  ELSE.
*   Daten aus KNVK nehmen ... was es da halt so gibt ....
  ENDIF.
**
ENDFORM." u0025_get_fakt_data.
*----------------------------------------------------------------------*
FORM u6000_alv_out.
*
  CASE w_vkz.
    WHEN c_deball OR c_debohn. "Debitorenliste (Debi in linken Spalten)
      DESCRIBE TABLE t_debi_out LINES w_lines.
      IF w_lines EQ 0.
        MESSAGE TEXT-f01 TYPE 'I'.
      ENDIF.
    WHEN c_apalle. "Ansprechpartnerliste (Ansprechp. linke Spalten)
      DESCRIBE TABLE t_ap_out LINES w_lines.
      IF w_lines EQ 0.
        MESSAGE TEXT-f01 TYPE 'I'.
      ENDIF.
    WHEN OTHERS.
      w_lines = 0.
  ENDCASE.
  IF w_alv_variant-report IS INITIAL.
    MOVE sy-repid   TO w_alv_variant-report.
  ENDIF.
  MOVE 'X'        TO w_alv_layout-colwidth_optimize.
  CHECK w_lines > 0.
  CASE w_vkz.
    WHEN c_deball OR c_debohn. "Debitorenliste (Debi in linken Spalten)
*    describe table t_outlist lines w_lines.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          i_structure_name = w_alv_struc
          i_save           = c_alv_save
          is_variant       = w_alv_variant
          is_layout        = w_alv_layout
*       IMPORTING
*         E_EXIT_CAUSED_BY_CALLER           =
        TABLES
          t_outtab         = t_debi_out
*       EXCEPTIONS
*         PROGRAM_ERROR    = 1
*         OTHERS           = 2
        .
      IF sy-subrc <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.
    WHEN c_apalle. "Ansprechpartnerliste (Ansprechp. linke Spalten)
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          i_structure_name = w_alv_struc2
          i_save           = c_alv_save
          is_variant       = w_alv_variant
          is_layout        = w_alv_layout
*       IMPORTING
*         E_EXIT_CAUSED_BY_CALLER           =
        TABLES
          t_outtab         = t_ap_out
*       EXCEPTIONS
*         PROGRAM_ERROR    = 1
*         OTHERS           = 2
        .
      IF sy-subrc <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.
    WHEN OTHERS.
*
  ENDCASE. "w_vkz.
ENDFORM." u6000_alv_out.
*----------------------------------------------------------------------*
