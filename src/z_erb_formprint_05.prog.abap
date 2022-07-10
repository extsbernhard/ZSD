*----------------------------------------------------------------------*
*      Print of a invoice by SAPscript SMART FORMS                     *
*----------------------------------------------------------------------*

REPORT z_erb_formprint_05.
*----------------------------------------------------------------------*
* W i c h t i g:                                                       *
* bei MwSt-Änderungen muss das Unterprogramm "form get_mwst_satz"      *
* ergänzt werden, da hier aufgrund fehlender Informationen der Prozent *
* satz sehr einfach definiert werden. "EPO20131114                     *
*----------------------------------------------------------------------*
* Erweiterung: 28.11.2013 - wenn eine der Nachrichten Z875/Z876 aus-   *
*              gedruckt wird, wird die andere Nachricht auch auf       *
*              verarbeitet gesetzt, damit die Fakturen nicht doppelt   *
*              gedruckt und versendet werden. EpO20131128              *
* Zusätzlich wurde an diesem Tag auch eine neue Auftragsart Z87G und   *
* eine neue Faktura-Art Z87G für die Fakturierung Kehrichtgrundgebühren*
* customized und ein eigenes Nachrichtenschema zugeordnet. EpO20131128 *
*----------------------------------------------------------------------*
DATA: document_output_info TYPE  ssfcrespd,
      job_output_info      TYPE ssfcrescl,
      job_output_options   TYPE ssfcresop.

* declaration of data
INCLUDE z_erb_formprint_05_d_declare.
* definition of forms

INCLUDE z_erb_formprint_05_forms.
INCLUDE z_erb_formprint_05_print_forms.
*Siehe Hinweis vom 21.06.2004 im INCLUDE z_sbz_formprint_05_print_forms
*---------------------------------------------------------------------*
*       FORM ENTRY
*---------------------------------------------------------------------*
FORM entry USING return_code us_screen.

  DATA: lf_retcode TYPE sy-subrc.
  CLEAR retcode.
  xscreen = us_screen.
  PERFORM processing USING us_screen
                     CHANGING lf_retcode.
  IF lf_retcode NE 0.
    return_code = 1.
  ELSE.
    return_code = 0.
  ENDIF.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM PROCESSING                                               *
*---------------------------------------------------------------------*
FORM processing USING proc_screen
                CHANGING cf_retcode.

  DATA: ls_print_data_to_read TYPE lbbil_print_data_to_read.
  DATA: ls_bil_invoice TYPE lbbil_invoice.
  DATA: lf_fm_name            TYPE rs38l_fnam.
  DATA: ls_control_param      TYPE ssfctrlop.
  DATA: ls_composer_param     TYPE ssfcompop.
  DATA: ls_recipient          TYPE swotobjid.
  DATA: ls_sender             TYPE swotobjid.
  DATA: lf_formname           TYPE tdsfname.
  DATA: ls_addr_key           LIKE addr_key.
  DATA: ls_dlv-land           LIKE vbrk-land1.
  DATA: ls_nast               TYPE nast.

*  DATA: document_output_info TYPE  ssfcrespd,

* SmartForm from customizing table TNAPR
  lf_formname = tnapr-sform.

* determine print data
  PERFORM set_print_data_to_read USING    lf_formname
                                 CHANGING ls_print_data_to_read
                                 cf_retcode.

  IF cf_retcode = 0.
* select print data
    PERFORM get_data.
*   Folgende Strukturen und Tabellen sind nun gefüllt: (sollten sein)
*    - ws_vbrk, ws_vbak, ws_objekt, ws_kehr_auft, ws_re_addr, ws_rg_addr
*    - wt_vbrp
    cf_retcode = sy-subrc. " wenn nicht Null, dann gabs da ein Problem!
  ENDIF.

  IF cf_retcode = 0.
    MOVE ws_re_addr-adrnr TO ls_addr_key-addrnumber.
    MOVE ws_vbrk-land1    TO ls_dlv-land.
    PERFORM set_print_param USING    ls_addr_key
                                     ls_dlv-land
                            CHANGING ls_control_param
                                     ls_composer_param
                                     ls_recipient
                                     ls_sender
                                     cf_retcode.
  ENDIF.

  IF cf_retcode = 0.
* determine smartform function module for invoice
    CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
      EXPORTING
        formname           = lf_formname
*       variant            = ' '
*       direct_call        = ' '
      IMPORTING
        fm_name            = lf_fm_name
      EXCEPTIONS
        no_form            = 1
        no_function_module = 2
        OTHERS             = 3.
    IF sy-subrc <> 0.
*   error handling
      cf_retcode = sy-subrc.
      PERFORM protocol_update.
    ENDIF.
  ENDIF.

  IF cf_retcode = 0.
    PERFORM check_repeat.
    IF ls_composer_param-tdcopies EQ 0.
      nast_anzal = 1.
    ELSE.
      nast_anzal = ls_composer_param-tdcopies.
    ENDIF.
    ls_composer_param-tdcopies = 1.


    " MZi 07.2021 QR Rechnung

*    DATA is_glo_qr_sales  TYPE glo_qr_sales.
    DATA is_ref           TYPE string.
    DATA qr_code          TYPE string.
    DATA qr_bill          TYPE string.
    DATA laenge           TYPE i.
    DATA bitmap           TYPE xstring.
    DATA object           TYPE stxbitmaps-tdobject.
    DATA id               TYPE stxbitmaps-tdid.
    DATA btype            TYPE stxbitmaps-tdbtype.
    DATA ibetrag          TYPE string.
    DATA iiban            TYPE string.
    DATA qruebergabe      TYPE zsd_ch_qr_uebergabe.

    " QR und Inhalt aufbauen
    CALL FUNCTION 'Z_SD_00_QR_RECHNUNG'
      EXPORTING
        nast           = nast
        smartf         = abap_true
      CHANGING
        ls_bil_invoice = ls_bil_invoice
        qruebergabe    = qruebergabe.

    " QR qird nach dem Drucken wieder gelöscht

    " MZi 07.2021


    DO nast_anzal TIMES.
* IN CASE OF REPETITION ONLY ONE TIME ARCHIVING
      IF sy-index > 1 AND nast-tdarmod = 3.
        nast_tdarmod = nast-tdarmod.
        nast-tdarmod = 1.
        ls_composer_param-tdarmod = 1.
      ENDIF.
      IF sy-index NE 1 AND repeat IS INITIAL.
        repeat = 'X'.
      ENDIF.
* call smartform invoice

      DATA: i_tsfdara   TYPE tsfdara,
            i_swotobjid TYPE swotobjid.

      IF nast-kschl(1) = 'E'.
        ls_control_param-getotf = 'X'.
      ENDIF.

      " ADu 13.04.2021
      DATA pdf_text TYPE string.
      DATA adrnr    TYPE adrnr.
      DATA adr13    TYPE adr13.

      SELECT SINGLE adrnr FROM tvko INTO adrnr
        WHERE vkorg = ws_vbrk-vkorg.
*       WHERE vkorg = ls_bil_invoice-hd_org-salesorg.
      IF sy-subrc = 0.
        SELECT SINGLE * FROM adr13 INTO adr13
         WHERE addrnumber = adrnr
           AND pager_serv = 'HINW'
           AND pager_nmbr = 'X'.
        IF sy-subrc = 0.
          pdf_text = 'Möchten Sie unsere Rechnungen per E-Mail erhalten? Hier anmelden: www.bern.ch/rechnung'.
        ELSE.
          pdf_text = ' '.
        ENDIF.
      ELSE.
        pdf_text = ' '.
      ENDIF.
      " ADu 13.04.2021

      CALL FUNCTION lf_fm_name
        EXPORTING
          archive_index        = toa_dara
          archive_index_tab    = i_tsfdara
          archive_parameters   = arc_params
          control_parameters   = ls_control_param
          mail_appl_obj        = i_swotobjid
          mail_recipient       = ls_recipient
          mail_sender          = ls_sender
          output_options       = ls_composer_param
          user_settings        = ' '
          is_bil_invoice       = ls_bil_invoice
          is_nast              = nast
*         is_repeat            = repeat
          vbrk                 = ws_vbrk
          vbak                 = ws_vbak
          zsd_05_objekt        = ws_objekt
          zsd_re_addr          = ws_re_addr
          zsd_rg_addr          = ws_rg_addr
          zsd_05_kehr_auft     = ws_kehr_auft
          vbdre                = ws_vbdre
          pdf_text             = pdf_text
          qruebergabe          = qruebergabe
        IMPORTING
          document_output_info = document_output_info
          job_output_info      = job_output_info
          job_output_options   = job_output_options
        TABLES
          vbrp                 = wt_vbrp
          zsd_05_hinweis       = wt_hinweis
        EXCEPTIONS
          formatting_error     = 1
          internal_error       = 2
          send_error           = 3
          user_canceled        = 4
          OTHERS               = 5.
      IF sy-subrc <> 0.
*     error handling
        cf_retcode = sy-subrc.
        PERFORM protocol_update.
*    get SmartForm protocoll and store it in the NAST protocoll
        PERFORM add_smfrm_prot.
      ELSE.
        IF nast-kschl(1) = 'E'.
          PERFORM send_mail.
        ENDIF.
      ENDIF.
    ENDDO.
*>>>>> Start Erweiterung "EPO20131128 >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
    DATA: lt_nast LIKE nast OCCURS 0 WITH HEADER LINE.
    IF cf_retcode = 0.
      IF ls_control_param-preview    IS INITIAL  "keine Druckansicht !!!
      OR ls_composer_param-tdnoprint IS INITIAL. "keine Druckausgabe !!!
*        case nast-kschl.
*         when 'Z875'. "Massennachricht über SBZ
*          select single * from nast into ls_nast
*                 where kschl eq 'Z876'
*                 and   vstat ne '1'
*                 and   objky eq nast-objky
*                 and   kappl eq nast-kappl
*                 and   nacha eq nast-nacha
*                 and   parnr eq nast-parnr
*                 and   parvw eq nast-parvw.
*          if sy-subrc eq 0.
*             ls_nast-vstat = '1'. "auf verarbeitet setzen
*             ls_nast-datvr = sy-datum.
*             modify nast from ls_nast.
*          endif.
*         when 'Z876'. "Einzelnachricht lokaler Druck in ERB
*          select single * from nast into ls_nast
*                 where kschl eq 'Z875'
*                 and   vstat ne '1'
*                 and   objky eq nast-objky
*                 and   kappl eq nast-kappl
*                 and   nacha eq nast-nacha
*                 and   parnr eq nast-parnr
*                 and   parvw eq nast-parvw.
*          if sy-subrc eq 0.
*             ls_nast-vstat = '1'. "auf verarbeitet setzen
*             ls_nast-datvr = sy-datum.
*             modify nast from ls_nast.
*          endif.
*
*         when 'Z885'. "Massennachricht über SBZ
*          select single * from nast into ls_nast
*                 where kschl eq 'Z886'
*                 and   vstat ne '1'
*                 and   objky eq nast-objky
*                 and   kappl eq nast-kappl
*                 and   nacha eq nast-nacha
*                 and   parnr eq nast-parnr
*                 and   parvw eq nast-parvw.
*          if sy-subrc eq 0.
*             ls_nast-vstat = '1'. "auf verarbeitet setzen
*             ls_nast-datvr = sy-datum.
*             modify nast from ls_nast.
*          endif.
*         when 'Z886'. "Einzelnachricht lokaler Druck in ERB
*          select single * from nast into ls_nast
*                 where kschl eq 'Z885'
*                 and   vstat ne '1'
*                 and   objky eq nast-objky
*                 and   kappl eq nast-kappl
*                 and   nacha eq nast-nacha
*                 and   parnr eq nast-parnr
*                 and   parvw eq nast-parvw.
*          if sy-subrc eq 0.
*             ls_nast-vstat = '1'. "auf verarbeitet setzen
*             ls_nast-datvr = sy-datum.
*             modify nast from ls_nast.
*          endif.
* NAST Update für Konditionsart Z870 erledigen E870 und Z871
** CR Request CCSAP P. S. 05.08.2020
*        IF nast-kschl EQ 'Z870'.
*          SELECT * FROM nast INTO TABLE lt_nast
*                                    WHERE objky EQ nast-objky
*                                    AND   kschl EQ 'E870'.
*          IF sy-subrc = 0.
*            LOOP AT lt_nast.
*              lt_nast-datvr = nast-erdat.
*              lt_nast-uhrvr = nast-eruhr.
*              lt_nast-usnam = nast-usnam.
*              lt_nast-vstat = '1'.
*              UPDATE nast FROM lt_nast.
*            ENDLOOP.
*          ENDIF.
** NAST Update für Konditionsart Z870 erledigen Z871
*          SELECT * FROM nast INTO TABLE lt_nast
*                                    WHERE objky EQ nast-objky
*                                    AND   kschl EQ 'Z871'.
*          IF sy-subrc = 0.
*            LOOP AT lt_nast.
*              lt_nast-datvr = nast-erdat.
*              lt_nast-uhrvr = nast-eruhr.
*              lt_nast-usnam = nast-usnam.
*              lt_nast-vstat = '1'.
*              UPDATE nast FROM lt_nast.
*            ENDLOOP.
*          ENDIF.
*        ENDIF.
** NAST Update für Konditionsart E870 erledigen Z870 und Z871
** CR Request CCSAP P. S. 05.08.2020
*        IF nast-kschl EQ 'E870'.
*          SELECT * FROM nast INTO TABLE lt_nast
*                                    WHERE objky EQ nast-objky
*                                    AND   kschl EQ 'Z870'.
*          IF sy-subrc = 0.
*            LOOP AT lt_nast.
*              lt_nast-datvr = nast-erdat.
*              lt_nast-uhrvr = nast-eruhr.
*              lt_nast-usnam = nast-usnam.
*              lt_nast-vstat = '1'.
*              UPDATE nast FROM lt_nast.
*            ENDLOOP.
*          ENDIF.
** NAST Update für Konditionsart E870 erledigen Z871
*          SELECT * FROM nast INTO TABLE lt_nast
*                                    WHERE objky EQ nast-objky
*                                    AND   kschl EQ 'Z871'.
*          IF sy-subrc = 0.
*            LOOP AT lt_nast.
*              lt_nast-datvr = nast-erdat.
*              lt_nast-uhrvr = nast-eruhr.
*              lt_nast-usnam = nast-usnam.
*              lt_nast-vstat = '1'.
*              UPDATE nast FROM lt_nast.
*            ENDLOOP.
*          ENDIF.
*        ENDIF.
** NAST Update für Konditionsart Z871 erledigen Z870 und E870
** CR Request CCSAP P. S. 05.08.2020
*        IF nast-kschl EQ 'Z871'.
*          SELECT * FROM nast INTO TABLE lt_nast
*                                    WHERE objky EQ nast-objky
*                                    AND   kschl EQ 'Z870'.
*          IF sy-subrc = 0.
*            LOOP AT lt_nast.
*              lt_nast-datvr = nast-erdat.
*              lt_nast-uhrvr = nast-eruhr.
*              lt_nast-usnam = nast-usnam.
*              lt_nast-vstat = '1'.
*              UPDATE nast FROM lt_nast.
*            ENDLOOP.
*          ENDIF.
** NAST Update für Konditionsart Z871 erledigen E870
*          SELECT * FROM nast INTO TABLE lt_nast
*                                    WHERE objky EQ nast-objky
*                                    AND   kschl EQ 'E870'.
*          IF sy-subrc = 0.
*            LOOP AT lt_nast.
*              lt_nast-datvr = nast-erdat.
*              lt_nast-uhrvr = nast-eruhr.
*              lt_nast-usnam = nast-usnam.
*              lt_nast-vstat = '1'.
*              UPDATE nast FROM lt_nast.
*            ENDLOOP.
*          ENDIF.
*        ENDIF.
* NAST Update für Konditionsart Z875 erledigen E876 und Z876
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'Z875'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E876'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z875 erledigen Z876
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z876'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart E876 erledigen Z875 und Z876
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'E876'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z875'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart E876 erledigen Z876
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z876'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart Z876 erledigen Z875 und E876
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'Z876'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z875'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z876 erledigen E876
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E876'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart Z877 erledigen E878 und Z878
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'Z877'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z877 erledigen Z878
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z877 erledigen ZM77 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM77'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z877 erledigen ZM78 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z877 erledigen ZM80 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z877 erledigen ZM81 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z877 erledigen ZM83 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart E878 erledigen Z877 und Z878
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'E878'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z877'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart E878 erledigen Z878
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart E878 erledigen E881, EM81 und EM83
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'E878'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart E878 erledigen EM81
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart E878 erledigen EM83
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart Z878 erledigen Z877 und E878
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'Z878'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z877'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z878 erledigen E878
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z878 erledigen ZM77 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM77'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z878 erledigen ZM78 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z878 erledigen ZM80 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z878 erledigen ZM81 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z878 erledigen ZM83 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart Z880 erledigen E881 und Z881
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'Z880'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z880 erledigen Z881 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z880 erledigen ZM77 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM77'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z880 erledigen ZM78 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z880 erledigen ZM80 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z880 erledigen ZM81 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z880 erledigen ZM83 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart E881 erledigen Z880 und Z881
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'E881'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z880'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart E881 erledigen Z881
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart E881 erledigen E878, EM81 und EM83
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'E881'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart E881 erledigen EM81
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart E881 erledigen EM83
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart Z881 erledigen Z880 und E881
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'Z881'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z880'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z881 erledigen E881
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z881 erledigen ZM77 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM77'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z881 erledigen ZM78 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z881 erledigen ZM80 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z881 erledigen ZM81 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z881 erledigen ZM83 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart Z885 erledigen E886 und Z886
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'Z885'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E886'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z885 erledigen Z886
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z886'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart E886 erledigen Z885 und Z886
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'E886'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z885'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart E886 erledigen Z886
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z886'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart Z886 erledigen Z885 und E886
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'Z886'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z885'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart Z886 erledigen E886
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E886'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart ZM77 erledigen EM78 und ZM78
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'ZM77'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM77 erledigen ZM78 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM77 erledigen ZM80 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM77 erledigen ZM81 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM77 erledigen ZM83 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM77 erledigen Z880 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z880'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM77 erledigen Z881 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM77 erledigen Z877 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z877'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM77 erledigen Z878 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart EM78 erledigen ZM77 und ZM78
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'EM78'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM77'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart EM78 erledigen ZM78
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart ZM78 erledigen ZM77 und EM78
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'ZM78'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM77'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM78 erledigen EM78
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM78 erledigen Z880 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z880'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM78 erledigen Z881 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM78 erledigen ZM80 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM78 erledigen ZM81 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM78 erledigen ZM83 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM78 erledigen Z877 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z877'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM78 erledigen Z878 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart ZM80 erledigen EM81 und ZM81
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'ZM80'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM80 erledigen ZM81
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM80 erledigen Z880 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z880'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM80 erledigen Z881 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM80 erledigen ZM77 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM77'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM80 erledigen ZM78 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM80 erledigen ZM83 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM80 erledigen Z877 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z877'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM80 erledigen Z878 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart EM81 erledigen ZM80 und ZM81
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'EM81'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart EM81 erledigen ZM81
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart EM81 erledigen E878, E881 und EM83
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'EM81'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart EM81 erledigen E881
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart EM81 erledigen EM83
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart ZM81 erledigen ZM80 und EM81
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'ZM81'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM81 erledigen EM81
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM81 erledigen Z880 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z880'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM81 erledigen Z881 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM81 erledigen ZM77 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM77'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM81 erledigen ZM78 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM81 erledigen ZM83 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM81 erledigen Z877 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z877'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM81 erledigen Z878 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart ZM82 erledigen EM83 und ZM83
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'ZM82'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.

          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.

          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.

          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.

        ENDIF.
* NAST Update für Konditionsart EM83 erledigen ZM82 und ZM83
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'EM83'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM82'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart EM83 erledigen ZM83
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart EM83 erledigen E878, E881 und EM83
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'EM83'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart EM83 erledigen E881
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'E881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart EM83 erledigen EM81
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.
* NAST Update für Konditionsart ZM83 erledigen ZM82 und EM83
* CR Request CCSAP P. S. 05.08.2020
        IF nast-kschl EQ 'ZM83'.
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM82'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM83 erledigen EM831
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'EM83'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM83 erledigen Z880 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z880'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM83 erledigen Z881 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z881'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM83 erledigen ZM77 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM77'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM83 erledigen ZM78 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM78'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM83 erledigen ZM80 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM80'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM83 erledigen ZM81 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'ZM81'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM83 erledigen Z877 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z877'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
* NAST Update für Konditionsart ZM83 erledigen Z878 STH 24.08.2020
          SELECT * FROM nast INTO TABLE lt_nast
                                    WHERE objky EQ nast-objky
                                    AND   kschl EQ 'Z878'.
          IF sy-subrc = 0.
            LOOP AT lt_nast.
              lt_nast-datvr = nast-erdat.
              lt_nast-uhrvr = nast-eruhr.
              lt_nast-usnam = nast-usnam.
              lt_nast-vstat = '1'.
              UPDATE nast FROM lt_nast.
            ENDLOOP.
          ENDIF.
        ENDIF.

*         when others.
*             dann machen wir nichts.... :-)
*        endcase.
      ENDIF.
    ENDIF.
*<<<<< Ende  Erweiterung "EPO20131128 <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    ls_composer_param-tdcopies = nast_anzal.
    IF NOT nast_tdarmod IS INITIAL.
      nast-tdarmod = nast_tdarmod.
      CLEAR nast_tdarmod.
    ENDIF.
  ENDIF.
* get SmartForm protocoll and store it in the NAST protocoll
* PERFORM ADD_SMFRM_PROT.

ENDFORM.
FORM send_mail.
  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
* Start PDF Mailversand
  DATA: ls_itcpp         TYPE itcpp,
        lt_otfdata       TYPE TABLE OF itcoo,
        lf_bin_file      TYPE xstring,
        lf_length        TYPE sood-objlen,
        lt_lines         TYPE TABLE OF tline,
        lr_send_request  TYPE REF TO cl_bcs,
        lt_text          TYPE bcsy_text,
        lr_document      TYPE REF TO cl_document_bcs,
        lr_sender        TYPE REF TO cl_sapuser_bcs,
        lr_recipient     TYPE REF TO if_recipient_bcs,
        lr_bcs_exception TYPE REF TO cx_bcs,
        lf_sent_to_all   TYPE os_boolean,
        lv_file          TYPE c LENGTH 50,
        lv_size          TYPE sood-objlen,
        lf_id            TYPE thead-tdid,
        lf_language      TYPE thead-tdspras,
        lf_name          TYPE thead-tdname,
        lf_object        TYPE thead-tdobject,
        lt_body_lines    TYPE STANDARD TABLE OF tline,
        lv_email_address TYPE adr6-smtp_addr,
        lf_output_length TYPE i,
        lt_bin_tab       TYPE solix_tab,
        ls_data          TYPE solix.

  CALL FUNCTION 'CONVERT_OTF'
    EXPORTING
      format                = 'PDF'
      max_linewidth         = 132
    IMPORTING
      bin_filesize          = lf_length
      bin_file              = lf_bin_file
    TABLES
      otf                   = job_output_info-otfdata "lt_otfdata
      lines                 = lt_lines
    EXCEPTIONS
      err_max_linewidth     = 1
      err_format            = 2
      err_conv_not_possible = 3
      OTHERS                = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno.
  ELSE.
    DATA : lv_max  TYPE i,
           lv_next TYPE i,
           current TYPE i,
           line    TYPE i.
    lv_max = lf_length.
    current = 0.
    DO.
      lv_next = lv_max - current.
      IF lv_next > 255.
        line = 255.
      ELSE.
        line = lv_next.
      ENDIF.
      ls_data-line = lf_bin_file+current(line).
      APPEND ls_data
          TO lt_bin_tab.
      CLEAR : ls_data.
      current = current + line.
      IF current = lv_max.
        EXIT.
      ENDIF.
    ENDDO.
  ENDIF.

  TRY.

*     Sendrequest generieren
      lr_send_request = cl_bcs=>create_persistent( ).

*     Lesen von Text für Mailbody
      lf_id       = 'ST'.
      lf_language = nast-spras.
      lf_name     = 'ZSD_00_RVADIN01_MAILTEXT'.
      lf_object   = 'TEXT'.
      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          id                      = lf_id
          language                = lf_language
          name                    = lf_name
          object                  = lf_object
        TABLES
          lines                   = lt_lines
        EXCEPTIONS
          id                      = 1
          language                = 2
          name                    = 3
          not_found               = 4
          object                  = 5
          reference_check         = 6
          wrong_access_to_archive = 7.
      IF sy-subrc IS INITIAL.
        LOOP AT lt_lines INTO DATA(ls_lines).
          APPEND ls_lines-tdline TO lt_text.
        ENDLOOP.
      ENDIF.

*     Maildokument erstellen
      lr_document = cl_document_bcs=>create_document(
                      i_type    = 'RAW'
                      i_text    = lt_text
                      i_subject = 'PDF-Rechnung der Stadt Bern' ).

*     Attachements anhängen
      lv_file = 'PDF-Rechnung der Stadt Bern.pdf'.
      lv_size = lines( lt_bin_tab ) * 255.
*     Anhängen
      lr_document->add_attachment( i_attachment_type    = 'PDF'
                                   i_attachment_subject = lv_file
                                   i_attachment_size    = lv_size
                                   i_att_content_hex    = lt_bin_tab ).
*     Anlagenliste auslesen
      PERFORM get_gos_files CHANGING lr_document.

*     Maildokument an Sendrequest übergeben
      CALL METHOD lr_send_request->set_document( lr_document ).

*     Absender definieren
      lr_sender = cl_sapuser_bcs=>create( sy-uname ).
      CALL METHOD lr_send_request->set_sender
        EXPORTING
          i_sender = lr_sender.

*     Empfänger hinzufügen
      SELECT SINGLE b~smtp_addr
        FROM kna1 AS a INNER JOIN adr6 AS b
          ON a~adrnr = b~addrnumber
        INTO lv_email_address
       WHERE a~kunnr = nast-parnr.
      " HVo 040722 Abbruch Weiterverarbeitung mit Protokolleintrag wenn E-Mail Adresse nicht gepflegt
      IF sy-subrc NE 0
      OR lv_email_address IS INITIAL.
        DATA: lv_msg_str TYPE SYST_MSGV.

        CONCATENATE 'keine Mailadresse gepflegt für Kunde' nast-parnr
               INTO lv_msg_str
          SEPARATED BY space.
        "CHECK XSCREEN = SPACE.
        CALL FUNCTION 'NAST_PROTOCOL_UPDATE'
          EXPORTING
            msg_arbgb = '00'
            msg_nr    = '001'
            msg_ty    = 'E'
            msg_v1    = lv_msg_str
*           msg_v2    = CONV syst_msgv( )
*           MSG_V3    = SYST-MSGV3
*           MSG_V4    = SYST-MSGV4
          EXCEPTIONS
            OTHERS    = 1.

        MESSAGE ID '00' TYPE 'E' NUMBER '001' WITH lv_msg_str.

        EXIT.
      ENDIF.

      lr_recipient = cl_cam_address_bcs=>create_internet_address( lv_email_address ).
      CALL METHOD lr_send_request->add_recipient
        EXPORTING
          i_recipient = lr_recipient
          i_express   = 'X'.

*     Email versenden
      CALL METHOD lr_send_request->send(
        EXPORTING
          i_with_error_screen = 'X'
        RECEIVING
          result              = lf_sent_to_all ).

    CATCH cx_document_bcs.
  ENDTRY.


  """"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_GOS_FILES
*&---------------------------------------------------------------------*
*       Lesen von Anlagenliste
*----------------------------------------------------------------------*
FORM get_gos_files CHANGING lr_document TYPE REF TO cl_document_bcs.
* Datendeklaration
  DATA: lv_vbelv         TYPE vbeln.
  DATA: ls_object        TYPE sibflporb,
        ls_gos_obj       TYPE gos_s_obj,
        lt_atta          TYPE gos_t_atta,
        ls_return        TYPE bapireturn1,
        ls_attcont       TYPE gos_s_attcont,
        ls_atta_key      TYPE gos_s_attkey,
        lv_xstring       TYPE xstring,
        lv_filename      TYPE c LENGTH 50,
        lv_att_type      TYPE soodk-objtp,
        lf_output_length TYPE i,
        lt_bin_tab       TYPE solix_tab.
  DATA: lr_gos TYPE REF TO cl_gos_api.
************************************************************************
* Vorgänger lesen (weil zum jetzigen Zeitpunkt kein GOS gefüllt in Rechnung)
  SELECT SINGLE aubel
    FROM vbrp
    INTO lv_vbelv
   WHERE vbeln = nast-objky.
  IF sy-subrc IS NOT INITIAL.
    EXIT.
  ENDIF.

  TRY.
*     Werte übergeben
      ls_object-instid = nast-objky. "lv_vbelv.
      ls_object-typeid = 'VBRK'.
      ls_object-catid  = 'BO'.

*     Lesen Anlageliste
      CALL METHOD cl_gos_api=>create_instance(
        EXPORTING
          is_object   = ls_object
        RECEIVING
          ro_instance = lr_gos ).
      lt_atta = lr_gos->get_atta_list( ).

*     Attachement vorhanden
      IF lt_atta IS NOT INITIAL.
        LOOP AT lt_atta INTO DATA(ls_atta).
          CLEAR: ls_return, ls_attcont, ls_atta_key.

*         Lesen von Inhalt
          MOVE-CORRESPONDING ls_atta TO ls_atta_key.
          ls_attcont = lr_gos->get_al_item( is_atta_key = ls_atta_key ).

*         Inhalt vorhanden
          IF ls_attcont-content_x IS NOT INITIAL.
            CLEAR: lt_bin_tab[].
            MOVE ls_attcont-content_x TO lv_xstring.
*           Umwandeln
            CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
              EXPORTING
                buffer        = lv_xstring
              IMPORTING
                output_length = lf_output_length
              TABLES
                binary_tab    = lt_bin_tab.

            DATA size TYPE sood-objlen.
            size = lf_output_length.

*           Attachement hinzufügen
            IF lt_bin_tab[] IS NOT INITIAL.
              lv_filename = ls_atta-filename.
              lv_att_type = ls_atta-tech_type.
              TRANSLATE lv_att_type TO UPPER CASE.
              lr_document->add_attachment( i_attachment_type    = 'BIN' "lv_att_type
                                           i_attachment_subject = lv_filename
                                           i_attachment_size    = size
                                           i_att_content_hex    = lt_bin_tab ).

            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.

*   Fehlerbehandlung
    CATCH cx_obl_parameter_error cx_obl_internal_error cx_obl_model_error.

  ENDTRY.
ENDFORM.
*
