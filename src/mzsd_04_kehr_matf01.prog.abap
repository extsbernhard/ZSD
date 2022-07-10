*----------------------------------------------------------------------*
***INCLUDE MZSD_04_KEHR_MATF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  read_makt
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->F_MATNR    text
*      -->F_MATTEXT  text
*----------------------------------------------------------------------*
FORM read_makt USING    f_matnr
                        f_mattext.

  CLEAR makt.
  SELECT SINGLE * FROM  makt
         WHERE  matnr  = f_matnr
         AND    spras  = sy-langu.
  IF sy-subrc NE 0.
    MOVE text-e02 TO f_mattext.
  ELSE.
    MOVE makt-maktx TO f_mattext.
  ENDIF.

ENDFORM.                    " read_makt
