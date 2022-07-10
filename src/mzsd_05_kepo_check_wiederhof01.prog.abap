*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_CHECK_WIEDERHOF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  CHECK_WIEDERHOLUNG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_wiederholung .
"Fallnummer = GS_KEPO-Fallnr
"Debitor = gs_kepo-kunnr
"Funddatum = gs_kepo-fdat

  "Pseudocode:

  "Select single from FÄLLE where debitor = debitor und fallnummer darf nicht die selbe sein.
   "if funddatum  > fälle-funddatum + 2jahre
      "Setze X
  "endif.
  "endselect.
  data head type table of zsdtkpkepo.
  data head_line like line of head.
  data dateplustwo type dats.
if gs_kepo-kunnr is not initial.
  select * from zsdtkpkepo into head_line where FART = gs_kepo-FART and kunnr = gs_kepo-kunnr and fallnr ne gs_kepo-fallnr.
 "   if fdat
CALL FUNCTION 'FKK_DTE_ADD_MONTH'
  EXPORTING
    i_datum                     = head_line-fdat
   I_NR_OF_MONTHS_TO_ADD       = 2
*   I_USE_FACCAL                = ' '
*   I_WORKDAY_INDICATOR         = '+'
*   I_USE_SPECIAL_DAY           = ' '
*   I_BASE_DATE                 =
 IMPORTING
   E_RESULT                     = dateplustwo
* EXCEPTIONS
*   NO_DATE                     = 1
*   OTHERS                      = 2
          .
IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.

  if dateplustwo >= gs_kepo-fdat.
    "Wiederholungsfall
    gs_kepo-fwdh = 'X'.
  "  message 'Es handelt sich um einen Wiederholungsfall!' type 'I'.
    endif.

  endselect.
  endif.
ENDFORM.                    " CHECK_WIEDERHOLUNG
