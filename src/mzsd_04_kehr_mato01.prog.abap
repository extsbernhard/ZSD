*----------------------------------------------------------------------*
***INCLUDE MZSD_04_KEHR_MATO01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  status_1000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_1000 OUTPUT.

  SET PF-STATUS '1000'.
  SET TITLEBAR '100'.
  IF zsd_04_kehr_mat IS INITIAL.
    SELECT SINGLE * FROM  zsd_04_kehr_mat CLIENT SPECIFIED
           WHERE  mandt  = sy-mandt.
  ENDIF.
  PERFORM read_makt USING: zsd_04_kehr_mat-matnr_1 w_mattext1,
                           zsd_04_kehr_mat-matnr_2 w_mattext2,
                           zsd_04_kehr_mat-matnr_3 w_mattext3,
                           zsd_04_kehr_mat-matnr_4 w_mattext4,
                           zsd_04_kehr_mat-matnr_5 w_mattext5,
                           zsd_04_kehr_mat-pausch  w_mattext6.

ENDMODULE.
