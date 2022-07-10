*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_REQU_MIGF01
*&---------------------------------------------------------------------*



*&---------------------------------------------------------------------*
*&      Form  GET_NEW_FALLNR
*&---------------------------------------------------------------------*
*       Neue Fallnummer vergeben
*----------------------------------------------------------------------*
FORM get_new_fallnr CHANGING cd_fallnr.

  CALL FUNCTION 'NUMBER_GET_NEXT'
    EXPORTING
      nr_range_nr             = '02'
      object                  = 'ZKGG'
      quantity                = '1'
*     toyear                  = ud_gjahr
*     IGNORE_BUFFER           = ' '
    IMPORTING
      number                  = cd_fallnr
*     QUANTITY                =
*     RETURNCODE              =
    EXCEPTIONS
      interval_not_found      = 1
      number_range_not_intern = 2
      object_not_found        = 3
      quantity_is_0           = 4
      quantity_is_not_1       = 5
      interval_overflow       = 6
      buffer_overflow         = 7
      OTHERS                  = 8.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " GET_NEW_FALLNR



*&---------------------------------------------------------------------*
*&      Form  GET_FAKT_DATA
*&---------------------------------------------------------------------*
*       Weitere Fakturadaten lesen
*----------------------------------------------------------------------*
FORM get_fakt_data CHANGING cs_lulu_fakt TYPE zsd_05_lulu_fk02.

  DATA: ls_vbrk TYPE vbrk,
        lv_vbeln TYPE vbeln_vf.

  CLEAR: ls_vbrk.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = cs_lulu_fakt-vbeln
    IMPORTING
      output = lv_vbeln.

  SELECT SINGLE * FROM vbrk INTO ls_vbrk
    WHERE vbeln EQ lv_vbeln.

  "Währung füllen
  cs_lulu_fakt-waerk = ls_vbrk-waerk.

  "Bruttobetrag errechnen und füllen
  cs_lulu_fakt-brtwr = ls_vbrk-netwr + ls_vbrk-mwsbk.
ENDFORM.                    " GET_FAKT_DATA
*&---------------------------------------------------------------------*
*&      Form  SET_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GS_LULU_HEAD_STATUS  text
*----------------------------------------------------------------------*
FORM set_status  USING angaben_sperre_x
                     rueckzlg_quote
                     nutz_art
      CHANGING  status TYPE zz_status
                ls_zsd_05_lulu_head STRUCTURE zsd_05_lulu_head.
*Logik?
  IF angaben_sperre_x = abap_true.
*    IF nutz_art = 1. "eigengenutzt
      status = 'A'.
      ls_zsd_05_lulu_head-status = 'A'.
*
*    ELSE.
*      IF rueckzlg_quote = 100 OR rueckzlg_quote = 70.
*        status = 'A'.
*        ls_zsd_05_lulu_head-status = 'A'.
*
*      ENDIF.
*    ENDIF.
  ENDIF.
ENDFORM.                    " SET_STATUS
