*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_REQU_FORM_MASS_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  PRINT_CONFIRM
*&---------------------------------------------------------------------*
*       Datennachfrage drucken
*----------------------------------------------------------------------*
*      -->P_GS_LULU_HEAD  text
*----------------------------------------------------------------------*
FORM print_confirm TABLES tt_lulu_fakt LIKE gt_lulu_fakt
                   USING  us_lulu_head
                          uv_sfname
                          us_sf_options TYPE ssfcompop
                          us_sf_control_params.

  DATA: ls_lulu_head TYPE zsd_05_lulu_hd02,
        lt_lulu_fakt TYPE TABLE OF zsd_05_lulu_fk02,
        lv_fbnam TYPE rs38l_fnam.

  CLEAR: ls_lulu_head, lt_lulu_fakt[], lv_fbnam.

*  "Daten für Übergabe bereitstellen
*  MOVE-CORRESPONDING us_lulu_head TO ls_lulu_head.
*  MOVE tt_lulu_fakt[] TO lt_lulu_fakt[].

  "Funktionsbaustein lesen
  PERFORM get_fbnam USING    uv_sfname
                    CHANGING lv_fbnam.

  CALL FUNCTION lv_fbnam
    EXPORTING
      lulu_head          = us_lulu_head
      control_parameters = us_sf_control_params
      output_options     = us_sf_options
      user_settings      = abap_false
    TABLES
      lulu_fakt          = tt_lulu_fakt
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.


ENDFORM.                    " PRINT_CONFIRM



*&---------------------------------------------------------------------*
*&      Form  GET_FBNAM
*&---------------------------------------------------------------------*
*       Funktionsbaustein zu Smarform lesen
*----------------------------------------------------------------------*
FORM get_fbnam  USING    uv_sfname
                CHANGING cv_fbnam.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname               = uv_sfname
*   VARIANT                  = ' '
*   DIRECT_CALL              = ' '
   IMPORTING
     fm_name                 = cv_fbnam
* EXCEPTIONS
*   NO_FORM                  = 1
*   NO_FUNCTION_MODULE       = 2
*   OTHERS                   = 3
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    "get_fbnam
*&---------------------------------------------------------------------*
*&      Form  update_fall_druckdatum
*&---------------------------------------------------------------------*
form update_fall_druckdatum using ls_lulu_head type zsd_05_lulu_hd02.
*
 data: lw_hd02      type zsd_05_lulu_hd02.
*
 select single * from zsd_05_lulu_hd02 into lw_hd02
        where fallnr eq ls_lulu_head.
 if sy-subrc eq 0.
    lw_hd02-PRIDT_MASS = sy-datum.
    modify zsd_05_lulu_hd02 from lw_hd02.
 endif.
*
endform." update_fall_druckdatum using gs_lulu_head
