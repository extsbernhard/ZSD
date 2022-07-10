*&---------------------------------------------------------------------*
*& Report  ZSD_05_KEPO_MODIFY_FALLWDH
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT zsd_05_kepo_modify_fallwdh.

DATA: lt_kepo TYPE TABLE OF zsdtkpkepo,
      ls_kepo TYPE zsdtkpkepo,
      lv_rec  TYPE i,
      lv_line TYPE num4.

TYPE-POOLS: abap.



*_____Selektionsbild_____

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE text-bl1.
PARAMETERS: p_test TYPE flag DEFAULT 'X', "Testlauf (Datum wird nicht in DB geschrieben)
            p_debug TYPE flag.
SELECTION-SCREEN END OF BLOCK bl1.



*_____Auswertung_____

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  IF p_debug EQ abap_true.
    BREAK-POINT.
  ENDIF.

  SELECT * FROM zsdtkpkepo INTO TABLE lt_kepo
    WHERE fwdh EQ abap_false
      AND kunnr NE space
      AND ( fstat NE '04' OR kverrgnam EQ space ).



  LOOP AT lt_kepo INTO ls_kepo.
    SELECT COUNT( * ) FROM zsdtkpkepo INTO lv_rec
      WHERE fart   EQ ls_kepo-fart
        AND kunnr  EQ ls_kepo-kunnr
        AND fallnr NE ls_kepo-fallnr
        AND fstat  NE '04' "annulliert
        AND fdat   LE ls_kepo-fdat
        AND kverrgnam EQ space. "Keine Verrechnung sind ausgeschlossene Fälle!

    IF lv_rec GT 0.
      ADD 1 TO lv_line.

      ls_kepo-fwdh = abap_true.

      IF p_test EQ abap_true.
        WRITE: / lv_line, ls_kepo-fallnr, ls_kepo-gjahr.
      ELSE.
        UPDATE zsdtkpkepo FROM ls_kepo.
        IF sy-subrc EQ 0.
          WRITE: / lv_line, ls_kepo-fallnr, ls_kepo-gjahr, 'SUCCESS'.
        ELSE.
          WRITE: / lv_line, ls_kepo-fallnr, ls_kepo-gjahr, 'ERROR'.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDLOOP.
