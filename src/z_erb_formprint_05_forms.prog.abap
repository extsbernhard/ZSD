*----------------------------------------------------------------------*
*   INCLUDE RLB_INVOICE_FORM01                                         *
*----------------------------------------------------------------------*
*---------------------------------------------------------------------*
*       FORM GET_DATA                                                 *
*---------------------------------------------------------------------*
*       General provision of data for the form                        *
* W i c h t i g:                                                      *
* bei MwSt-Änderungen muss das Unterprogramm "form get_mwst_satz"     *
* ergänzt werden, da hier aufgrund fehlender Informationen der Prozent*
* satz sehr einfach definiert werden. "EPO20131114                    *
*---------------------------------------------------------------------*
FORM get_data.
*
  DATA: lw_mwst_satz        TYPE zz_mwst_satz
      , lw_return           LIKE syst-subrc
      .

  IF nast-objky+10 NE space.
    nast-objky = nast-objky+16(10).
  ELSE.
    nast-objky = nast-objky.
  ENDIF.

* read print data
*----------------------------------------------------------------------
* lesen Faktura-Kopfdaten gemäss NAST-Objekt-Key = Faktura-Nummer
  SELECT SINGLE * FROM vbrk INTO ws_vbrk
                  WHERE vbeln EQ nast-objky.
  IF NOT sy-subrc > 0.
*----------------------------------------------------------------------
*    wenn erfolgreich lesen der abhängigen Faktura-Positionen
    SELECT       * FROM vbrp INTO CORRESPONDING FIELDS OF TABLE wt_vbrp
                   WHERE vbeln EQ nast-objky.
    IF NOT sy-subrc > 0.
*----------------------------------------------------------------------
*     wenn erfolgreich, aus erster Faktura-Position die Auftragskopf-
*     informationen lesen
      LOOP AT wt_vbrp INTO ws_vbrp TO 1.
*        lesen Auftragskopfdaten ...
        SELECT SINGLE * FROM vbak INTO ws_vbak
                        WHERE vbeln EQ ws_vbrp-aubel.
        IF NOT sy-subrc > 0.
          w_ok = 'J'.
        ELSE.
          w_ok = 'N'.
        ENDIF.
      ENDLOOP. " wt_vbrp into ws_vbrp to 1.
    ENDIF.
  ENDIF.
*----------------------------------------------------------------------
  IF NOT w_ok EQ 'J'.
    MOVE 1 TO sy-subrc.
  ELSE.
    DATA: lw_text_key    TYPE tdname
        , ls_stxh        TYPE stxh
        .
    sy-subrc = 0.
*    bestücken des Textkeys pro Position für "Read_Text"
    CLEAR lw_mwst_satz.
    LOOP AT wt_vbrp INTO ws_vbrp.
      IF lw_mwst_satz IS INITIAL.
        PERFORM get_mwst_satz USING    ws_vbrp-mwskz
                              CHANGING lw_mwst_satz
                                       lw_return.
        IF lw_return EQ 0.
          MOVE lw_mwst_satz TO ws_vbrp-mwst_satz.
        ENDIF.
      ELSE.
        MOVE lw_mwst_satz TO ws_vbrp-mwst_satz.
      ENDIF.
      IF ws_vbrp-txt_key IS INITIAL.
        CONCATENATE ws_vbrp-vbeln ws_vbrp-posnr
               INTO ws_vbrp-txt_key.
        CONDENSE ws_vbrp-txt_key NO-GAPS.
        IF ws_vbrp-txt_key(1) NE '0'.
          CLEAR lw_text_key.
          MOVE: ws_vbrp-txt_key TO lw_text_key+1(15)
              , '0'             TO lw_text_key(1)
              .
          CONDENSE lw_text_key NO-GAPS.
          ws_vbrp-txt_key = lw_text_key.
        ENDIF.
        SELECT SINGLE * FROM stxh INTO ls_stxh
                        WHERE tdobject = c_vbbp
                        AND   tdname   = ws_vbrp-txt_key
                        AND   tdid     = c_0001
                        AND   tdspras  = c_de.
*        Einzelpreis aus Auftrag hinzu lesen ...
        SELECT SINGLE netpr FROM vbap INTO ws_vbrp-netpr
               WHERE  vbeln EQ ws_vbrp-aubel
               AND    posnr EQ ws_vbrp-aupos.
        IF sy-subrc > 0.
          CLEAR ws_vbrp-netpr.
        ENDIF.
        MODIFY wt_vbrp FROM ws_vbrp.
      ENDIF.
    ENDLOOP." at wt_vbrp into ws_vbrp.
  ENDIF.
*----------------------------------------------------------------------
  IF sy-subrc <> 0.
*  error handling
    PERFORM protocol_update.
  ENDIF.

* get nast partner adress for communication strategy
*----------------------------------------------------------------------
* lesen Regulierer-Adresse
  SELECT SINGLE adrnr FROM kna1 INTO ws_rg_addr-adrnr
         WHERE  kunnr EQ ws_vbrk-kunrg.
  IF sy-subrc NE 0.
    CLEAR ws_rg_addr-adrnr.
  ELSE.
    MOVE ws_vbrk-kunrg TO ws_rg_addr-kunnr.
  ENDIF.
*----------------------------------------------------------------------
* lesen Rechnungsempfänger-Adresse
  SELECT SINGLE adrnr FROM kna1 INTO ws_re_addr-adrnr
         WHERE  kunnr EQ nast-parnr.
  IF sy-subrc NE 0.
    CLEAR ws_re_addr-adrnr.
  ELSE.
    MOVE nast-parnr TO ws_re_addr-kunnr.
  ENDIF.
*----------------------------------------------------------------------
* Lesen Objekt-Daten zur Faktura über den Auftrags-Beleg
  SELECT SINGLE * FROM zsd_05_kehr_auft INTO ws_kehr_auft
         WHERE vbeln EQ ws_vbak-vbeln.
  IF sy-subrc EQ 0.
    SELECT SINGLE * FROM zsd_05_objekt INTO ws_objekt
           WHERE stadtteil EQ ws_kehr_auft-stadtteil
           AND   parzelle  EQ ws_kehr_auft-parzelle
           AND   objekt    EQ ws_kehr_auft-objekt.
    IF sy-subrc > 0.
      CLEAR ws_objekt.
    ENDIF.
    CLEAR   wt_hinweis.
    REFRESH wt_hinweis.
    PERFORM get_hinweis_texte TABLES wt_hinweis USING ws_kehr_auft.
  ELSE.
    CLEAR ws_kehr_auft.
  ENDIF.
*----------------------------------------------------------------------
* füllen VBDRE - Struktur für ESR-Daten
  DATA: lw_fkwrt    LIKE komk-fkwrt.
  CLEAR lw_fkwrt.
  lw_fkwrt = ws_vbrk-netwr + ws_vbrk-mwsbk.
  CALL FUNCTION 'SD_ESR_GET_DATA'
    EXPORTING
      vbdkr_bukrs                   = ws_vbrk-bukrs
      vbdkr_vkorg                   = ws_vbrk-vkorg
      komk_fkwrt                    = lw_fkwrt
      vbdkr_vbeln                   = ws_vbrk-vbeln
      vbdkr_kunrg                   = ws_vbrk-kunrg
      vbdkr_waerk                   = ws_vbrk-waerk
    CHANGING
      ivbdre                        = ws_vbdre
    EXCEPTIONS
      t049e_no_entry                = 1
      t001_no_entry                 = 2
      bnka_no_entry                 = 3
      sadr_no_entry                 = 4
      fkwrt_not_valid               = 5
      esr_digits_to_check_not_valid = 6
      esr_check_method_not_valid    = 7
      OTHERS                        = 8.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.


*----------------------------------------------------------------------

ENDFORM.
*---------------------------------------------------------------------*
*       FORM SET_PRINT_DATA_TO_READ                                   *
*---------------------------------------------------------------------*
*       General provision of data for the form                        *
*---------------------------------------------------------------------*
FORM set_print_data_to_read
         USING    if_formname LIKE tnapr-sform
         CHANGING cs_print_data_to_read TYPE lbbil_print_data_to_read
                  cf_retcode.

  FIELD-SYMBOLS: <fs_print_data_to_read> TYPE xfeld.
  DATA: lt_fieldlist TYPE tsffields.

* set print data requirements
  DO.
    ASSIGN COMPONENT sy-index OF STRUCTURE
                     cs_print_data_to_read TO <fs_print_data_to_read>.
    IF sy-subrc <> 0. EXIT. ENDIF.
    <fs_print_data_to_read> = 'X'.
  ENDDO.

  CALL FUNCTION 'SSF_FIELD_LIST'
    EXPORTING
      formname           = if_formname
*     VARIANT            = ' '
    IMPORTING
      fieldlist          = lt_fieldlist
    EXCEPTIONS
      no_form            = 1
      no_function_module = 2
      OTHERS             = 3.
  IF sy-subrc <> 0.
*  error handling
    cf_retcode = sy-subrc.
    PERFORM protocol_update.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  get_addr_key
*&---------------------------------------------------------------------*
FORM get_addr_key USING    it_hd_adr   TYPE lbbil_invoice-hd_adr
                  CHANGING cs_addr_key LIKE addr_key.

  FIELD-SYMBOLS <fs_hd_adr> TYPE LINE OF lbbil_invoice-hd_adr.

  READ TABLE it_hd_adr ASSIGNING <fs_hd_adr>
                       WITH KEY bil_number = nast-objky
                                partn_role = nast-parvw.
  IF sy-subrc = 0.
    cs_addr_key-addrnumber = <fs_hd_adr>-addr_no.
    cs_addr_key-persnumber = <fs_hd_adr>-person_numb.
    cs_addr_key-addr_type  = <fs_hd_adr>-address_type.
  ENDIF.

ENDFORM.                               " get_addr_key

*&---------------------------------------------------------------------*
*&      Form  get_dlv_land
*&---------------------------------------------------------------------*
FORM get_dlv-land USING    it_hd_gen   TYPE lbbil_invoice-hd_gen
                  CHANGING cs_dlv-land LIKE vbrk-land1.

  cs_dlv-land = it_hd_gen-dlv_land.


ENDFORM.                               " get_dlv_land
FORM get_mwst_satz USING    lw_vbrp-mwskz  TYPE mwskz
                   CHANGING lw_mwst_satz   TYPE zz_mwst_satz
                            lw_return LIKE syst-subrc.
  DATA: lw_knumh       LIKE konp-knumh
      , lw_kbetr       LIKE konp-kbetr
      , lw_char12(12)  TYPE c
      , lw_vkomma(10)  TYPE c
      , lw_nkomma(02)  TYPE c
      , lw_length      TYPE i
      , lw_offset      TYPE i
      , lw_mwsatz      TYPE zz_mwst_satz.
*
  lw_return = 9.
*>>> keine MwSt-KZ in den Faktura-Positionen, somit alles für die Katz
* select single knumh from a003 into lw_knumh
*        where kappl = c_tx
*        and   kschl = c_zpst
*        and   aland = c_ch
*        and   mwskz = lw_vbrp-mwskz.
* if sy-subrc ne 0.
*    lw_return = sy-subrc.
*    clear lw_mwst_satz.
*    clear lw_knumh.
*    exit.
* endif.
* if not lw_knumh is initial.
*    select single kbetr from konp into lw_kbetr
*           where  knumh    = lw_knumh
*           and    loevm_ko = c_leer.
*    if sy-subrc ne 0.
*       lw_return = sy-subrc.
*       clear lw_mwst_satz.
*    endif.
* endif.
*<<< keine MwSt-KZ in den Faktura-Positionen, somit alles für die Katz
  CLEAR: lw_char12
       , lw_kbetr.
  IF NOT ws_vbrp-netwr EQ 0.
    lw_kbetr = ws_vbrp-kzwi5 * 100 / ws_vbrp-netwr.
    MOVE lw_kbetr TO lw_char12.
    SPLIT lw_char12 AT '.' INTO
                           lw_vkomma
                           lw_nkomma.
    CONDENSE lw_vkomma NO-GAPS.
    CONDENSE lw_nkomma NO-GAPS.
    CASE lw_vkomma.
      WHEN '7'.
        CASE lw_nkomma(1).
          WHEN '5' OR '6' OR '7'.
            lw_nkomma = '6'. "muss eigentlich 7.6 sein !!!
          WHEN '9' OR '8'.
            lw_nkomma = '0'. "kann nur 8.0 % sein !!!
            lw_vkomma = '8'. "kann nur 8.0 % sein !!!
        ENDCASE."lw_nkomma(1).
      WHEN '8'.
*     bis es neue MwSt-Sätze gibt, kann man es sich hier einfach machen
        lw_nkomma = '0'.
      WHEN OTHERS.
        lw_mwst_satz = 0.
    ENDCASE.
    IF ws_vbrp-fbuda > '20110101'.  "Änderung war nötig   "Epo20140326
*    or ws_vbrp-prsdt > '20130101'. deaktiviert für alte Fakturen, Epo
*      Faktura neueren Datums
      IF lw_vkomma CN '08'.
        lw_nkomma = '0'. "kann nur 8.0 % sein !!!
        lw_vkomma = '8'. "kann nur 8.0 % sein !!!
      ENDIF.
    ELSEIF ws_vbrp-fbuda < '20110101'.
      lw_nkomma = '6'. "kann nur 8.0 % sein !!!
      lw_vkomma = '7'. "kann nur 8.0 % sein !!!
    ENDIF.
    IF ws_vbrp-fbuda >= '20180101'.
      lw_nkomma = '7'. "kann nur 7.7 % sein !!!
      lw_vkomma = '7'. "kann nur 7.7 % sein !!!
    ENDIF.

    CONCATENATE lw_vkomma '.' lw_nkomma(1) INTO lw_char12.
    CONDENSE lw_char12 NO-GAPS.
    MOVE lw_char12 TO lw_kbetr.
    MOVE lw_char12 TO lw_mwst_satz.
    lw_return    = 0.
  ELSE.
    lw_mwst_satz = 0.
    lw_return    = 0.
  ENDIF.
  CLEAR lw_return.
*
ENDFORM." get_mwst_satz using ws_vbrp-mwskz, changing lw_mwst_satz
*                                                    lw_return.
*
FORM get_hinweis_texte TABLES wt_hinweis
                       USING  ws_kehr_auft TYPE zsd_05_kehr_auft.
*
  DATA: lw_text_vh             TYPE x.
*
  PERFORM fill_s_hwtxt.
*
  SELECT SINGLE * FROM zsd_04_kehricht INTO ws_kehricht
                  WHERE stadtteil   EQ ws_kehr_auft-stadtteil
                  AND   parzelle    EQ ws_kehr_auft-parzelle
                  AND   objekt      EQ ws_kehr_auft-objekt.
  IF sy-subrc > 0.
    EXIT.
  ENDIF.
*   Alter Hinweistext 1 aus ZSD_04_Kehricht
  IF ws_kehricht-hinweis1 IN s_hwtxt.
    CLEAR ws_hinweis.
    MOVE-CORRESPONDING ws_kehricht TO ws_hinweis.
    MOVE ws_kehricht-hinweis1      TO ws_hinweis-hinweis.
    MOVE ws_kehricht-hintext1      TO ws_hinweis-hintext.
    APPEND ws_hinweis              TO wt_hinweis.
  ENDIF.
*   Alter Hinweistext 2 aus ZSD_04_Kehricht
  IF ws_kehricht-hinweis2 IN s_hwtxt.
    CLEAR ws_hinweis.
    MOVE-CORRESPONDING ws_kehricht TO ws_hinweis.
    MOVE ws_kehricht-hinweis2      TO ws_hinweis-hinweis.
    MOVE ws_kehricht-hintext2      TO ws_hinweis-hintext.
    APPEND ws_hinweis              TO wt_hinweis.
  ENDIF.
*   Alter Hinweistext 3 aus ZSD_04_Kehricht
  IF ws_kehricht-hinweis3 IN s_hwtxt.
    CLEAR ws_hinweis.
    MOVE-CORRESPONDING ws_kehricht TO ws_hinweis.
    MOVE ws_kehricht-hinweis3      TO ws_hinweis-hinweis.
    MOVE ws_kehricht-hintext3      TO ws_hinweis-hintext.
    APPEND ws_hinweis              TO wt_hinweis.
  ENDIF.
*   Alter Hinweistext 4 aus ZSD_04_Kehricht
  IF ws_kehricht-hinweis4 IN s_hwtxt.
    CLEAR ws_hinweis.
    MOVE-CORRESPONDING ws_kehricht TO ws_hinweis.
    MOVE ws_kehricht-hinweis4      TO ws_hinweis-hinweis.
    MOVE ws_kehricht-hintext4      TO ws_hinweis-hintext.
    APPEND ws_hinweis              TO wt_hinweis.
  ENDIF.
*   Alter Hinweistext 5 aus ZSD_04_Kehricht
  IF ws_kehricht-hinweis5 IN s_hwtxt.
    CLEAR ws_hinweis.
    MOVE-CORRESPONDING ws_kehricht TO ws_hinweis.
    MOVE ws_kehricht-hinweis5      TO ws_hinweis-hinweis.
    MOVE ws_kehricht-hintext5      TO ws_hinweis-hintext.
    APPEND ws_hinweis              TO wt_hinweis.
  ENDIF.
*   Alter Hinweistext 6 aus ZSD_04_Kehricht
  IF ws_kehricht-hinweis6 IN s_hwtxt.
    CLEAR ws_hinweis.
    MOVE-CORRESPONDING ws_kehricht TO ws_hinweis.
    MOVE ws_kehricht-hinweis6      TO ws_hinweis-hinweis.
    MOVE ws_kehricht-hintext6      TO ws_hinweis-hintext.
    APPEND ws_hinweis              TO wt_hinweis.
  ENDIF.
*   Alter Hinweistext 7 aus ZSD_04_Kehricht
  IF ws_kehricht-hinweis7 IN s_hwtxt.
    CLEAR ws_hinweis.
    MOVE-CORRESPONDING ws_kehricht TO ws_hinweis.
    MOVE ws_kehricht-hinweis7      TO ws_hinweis-hinweis.
    MOVE ws_kehricht-hintext7      TO ws_hinweis-hintext.
    APPEND ws_hinweis              TO wt_hinweis.
  ENDIF.
*   Alter Hinweistext 8 aus ZSD_04_Kehricht
  IF ws_kehricht-hinweis8 IN s_hwtxt.
    CLEAR ws_hinweis.
    MOVE-CORRESPONDING ws_kehricht TO ws_hinweis.
    MOVE ws_kehricht-hinweis8      TO ws_hinweis-hinweis.
    MOVE ws_kehricht-hintext8      TO ws_hinweis-hintext.
    APPEND ws_hinweis              TO wt_hinweis.
  ENDIF.
* nachschauen, ob Hinweise gefundne wurde ...
  DESCRIBE TABLE wt_hinweis LINES w_lines.
  IF w_lines > 0.
    EXIT.
  ELSE.
    PERFORM get_ext_hinweise TABLES wt_hinweis
                             USING  ws_kehr_auft.
  ENDIF.
*
ENDFORM." get_hinweis_texte tables wt_hinweis using ws_kehr_auft.
*
FORM fill_s_hwtxt.
  IF s_hwtxt IS INITIAL.
    CLEAR ls_hwtxt.
    MOVE 'CP'    TO ls_hwtxt-option.
    MOVE 'I'     TO ls_hwtxt-sign.
    MOVE 'RE*'   TO ls_hwtxt-low.
    CLEAR           ls_hwtxt-high.
    APPEND ls_hwtxt TO s_hwtxt .
*     clear ls_hwtxt.
*     move 'CP'    to s_hwtxt-option.
*     move 'I'     to s_hwtxt-sign.
*     move 'RE2'   to s_hwtxt-low.
*     clear           s_hwtxt-high.
*     append s_hwtxt.
    CLEAR ls_hwtxt.
    MOVE 'CP'    TO ls_hwtxt-option.
    MOVE 'I'     TO ls_hwtxt-sign.
    MOVE 'VI*'   TO ls_hwtxt-low.
    CLEAR           ls_hwtxt-high.
    APPEND ls_hwtxt TO s_hwtxt.
*     clear ls_hwtxt.
*     move 'CP'    to s_hwtxt-option.
*     move 'I'     to s_hwtxt-sign.
*     move 'VI2'   to s_hwtxt-low.
*     clear           s_hwtxt-high.
*     append s_hwtxt.

  ENDIF.
ENDFORM." fill_s_hwtxt.
*
FORM get_ext_hinweise TABLES wt_hinweis
                      USING  ws_kehrauft    TYPE zsd_05_kehr_auft.
*
  SELECT * FROM zsd_05_hinweis
           INTO CORRESPONDING FIELDS OF TABLE wt_hinweis
                  WHERE stadtteil   EQ ws_kehrauft-stadtteil
                  AND   parzelle    EQ ws_kehrauft-parzelle
                  AND   objekt      EQ ws_kehrauft-objekt.
  IF sy-subrc EQ 0.
    DESCRIBE TABLE wt_hinweis LINES w_lines.
  ELSE.
    REFRESH wt_hinweis.
    CLEAR   wt_hinweis.
    CLEAR   ws_hinweis.
  ENDIF.
*
ENDFORM." get_ext_hinweise tables wt_hinweis using  ws_kehrauft.
