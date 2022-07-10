*----------------------------------------------------------------------*
***INCLUDE Z_DATA .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  set_addr_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_addr_data.

  CALL FUNCTION 'ADDR_GET'
       EXPORTING
            address_selection = ls_addr_sel
            address_group     = 'CA01'
       IMPORTING
            address_value     = it_adrval.


  SELECT SINGLE title_medi FROM tsad3t INTO wa_export-anrede
    WHERE title = it_adrval-title
    AND   langu = it_adrval-langu.
*  wa_export-anrede   = it_adrval-title.      "Feld J

  wa_export-debtxt1  = it_adrval-name1.      "Feld K
  wa_export-debtxt2  = it_adrval-name2.      "Feld L
  wa_export-bedtxt21 = it_adrval-name3.      "Feld M
  IF it_adrval-name3 IS INITIAL.
    wa_export-bedtxt21 = it_adrval-str_suppl1.
  ENDIF.
  wa_export-debtxt3  = it_adrval-street.     "Feld N
  wa_export-debtxt7  = it_adrval-house_num1. "Feld O
  wa_export-debtxt8  = it_adrval-house_num2. "Feld P

  IF NOT it_adrval-po_box_num IS INITIAL.
    wa_export-debtxt4 = 'Postfach'.          "Feld Q
  ELSEIF NOT it_adrval-po_box IS INITIAL.
    wa_export-debtxt4 = it_adrval-po_box.    "Feld Q
  ENDIF.

  IF NOT it_adrval-post_code2 IS INITIAL.
    IF it_adrval-po_box_cty NE 'CH'.
      CONCATENATE it_adrval-po_box_cty it_adrval-post_code2
        INTO wa_export-debtxt5.                 "Feld R
    ELSE.
      wa_export-debtxt5 = it_adrval-post_code2. "Feld R
    ENDIF.

    wa_export-debtxt6 = it_adrval-po_box_loc.   "Feld S
  ELSE.
    IF it_adrval-country NE 'CH'.
      CONCATENATE it_adrval-country it_adrval-post_code1
        INTO wa_export-debtxt5.                 "Feld R
    ELSE.
      wa_export-debtxt5 = it_adrval-post_code1. "Feld R
    ENDIF.

    wa_export-debtxt6 = it_adrval-city1.        "Feld S
  ENDIF.

  CONDENSE wa_export-debtxt5 NO-GAPS.

ENDFORM.                    " set_addr_data
