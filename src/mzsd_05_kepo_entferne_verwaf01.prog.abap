*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_ENTFERNE_VERWAF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  ENTFERNE_VERWARNUNG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM entferne_verwarnung .

gs_verwarnung-loesch = 'X'.
MOVE-CORRESPONDING  gs_verwarnung to kepo_ver.
gs_kepo-fstat = '01'.
clear gs_verwarnung.
loesch = 'X'.


ENDFORM.                    " ENTFERNE_VERWARNUNG