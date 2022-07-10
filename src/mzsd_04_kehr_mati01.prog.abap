*----------------------------------------------------------------------*
***INCLUDE MZSD_04_KEHR_MATI01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  exit_command_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE exit_command_1000 INPUT.

  CASE w_ok.
    WHEN 'BACK'.                 "Zurück
      LEAVE TO SCREEN 0.
    WHEN 'CANC'.                 "Abbrechen
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'.                 "Beenden
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
      IF NOT zsd_04_kehr_mat IS INITIAL.
        PERFORM read_makt USING: zsd_04_kehr_mat-matnr_1 w_mattext1,
                                 zsd_04_kehr_mat-matnr_2 w_mattext2,
                                 zsd_04_kehr_mat-matnr_3 w_mattext3,
                                 zsd_04_kehr_mat-matnr_4 w_mattext4,
                                 zsd_04_kehr_mat-matnr_5 w_mattext5,
                                 zsd_04_kehr_mat-pausch  w_mattext6.
      ENDIF.
  ENDCASE.


ENDMODULE.                 " exit_command_1000  INPUT
*&---------------------------------------------------------------------*
*&      Module  user_command_1000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1000 INPUT.

  CASE w_ok.
    WHEN 'SAVE'.                 "Sichern
      UPDATE zsd_04_kehr_mat FROM zsd_04_kehr_mat.
      IF sy-subrc NE 0.
        INSERT INTO zsd_04_kehr_mat VALUES zsd_04_kehr_mat.
      ENDIF.
    WHEN OTHERS.
      IF NOT zsd_04_kehr_mat IS INITIAL.
        PERFORM read_makt USING: zsd_04_kehr_mat-matnr_1 w_mattext1,
                                 zsd_04_kehr_mat-matnr_2 w_mattext2,
                                 zsd_04_kehr_mat-matnr_3 w_mattext3,
                                 zsd_04_kehr_mat-matnr_4 w_mattext4,
                                 zsd_04_kehr_mat-matnr_5 w_mattext5,
                                 zsd_04_kehr_mat-pausch  w_mattext6.
      ENDIF.
  ENDCASE.

ENDMODULE.                 " user_command_1000  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_MATNR1  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_matnr1 INPUT.

  SELECT SINGLE * FROM  mara
         WHERE  matnr  = zsd_04_kehr_mat-matnr_1.
  IF sy-subrc NE 0.
    MESSAGE e000(zsd_04) WITH text-e01.
  ENDIF.

ENDMODULE.                 " CHECK_MATNR1  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_MATNR2  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_matnr2 INPUT.

  SELECT SINGLE * FROM  mara
         WHERE  matnr  = zsd_04_kehr_mat-matnr_2.
  IF sy-subrc NE 0.
    MESSAGE e000(zsd_04) WITH text-e01.
  ENDIF.

ENDMODULE.                 " CHECK_MATNR2  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_MATNR1  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_matnr3 INPUT.

  SELECT SINGLE * FROM  mara
         WHERE  matnr  = zsd_04_kehr_mat-matnr_3.
  IF sy-subrc NE 0.
    MESSAGE e000(zsd_04) WITH text-e01.
  ENDIF.

ENDMODULE.                 " CHECK_MATNR3  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_MATNR1  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_matnr4 INPUT.

  SELECT SINGLE * FROM  mara
         WHERE  matnr  = zsd_04_kehr_mat-matnr_4.
  IF sy-subrc NE 0.
    MESSAGE e000(zsd_04) WITH text-e01.
  ENDIF.

ENDMODULE.                 " CHECK_MATNR4  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_MATNR5  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_matnr5 INPUT.

  SELECT SINGLE * FROM  mara
         WHERE  matnr  = zsd_04_kehr_mat-matnr_5.
  IF sy-subrc NE 0.
    MESSAGE e000(zsd_04) WITH text-e01.
  ENDIF.

ENDMODULE.                 " CHECK_MATNR5  INPUT
*&---------------------------------------------------------------------*
*&      Module  CHECK_MATNR6  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE check_matnr6 INPUT.

  SELECT SINGLE * FROM  mara
         WHERE  matnr  = zsd_04_kehr_mat-pausch.
  IF sy-subrc NE 0.
    MESSAGE e000(zsd_04) WITH text-e01.
  ENDIF.

ENDMODULE.                 " CHECK_MATNR6  INPUT
