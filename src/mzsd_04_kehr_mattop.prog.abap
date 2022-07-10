*&---------------------------------------------------------------------*
*& Include MZSD_04_KEHR_MATTOP                                         *
*&                                                                     *
*&---------------------------------------------------------------------*

PROGRAM  sapmzsd_04_kehr_mat           .

TABLES: makt,                          "Materialkurztexte
        mara,                          "Allgemeine Materialdaten
        zsd_04_kehr_mat.   "Gebühren: Materialen für Kehrichtgrundgebühr

DATA: w_ok       TYPE okcode,
      w_mattext1 TYPE makt-maktx,
      w_mattext2 TYPE makt-maktx,
      w_mattext3 TYPE makt-maktx,
      w_mattext4 TYPE makt-maktx,
      w_mattext5 TYPE makt-maktx,
      w_mattext6 TYPE makt-maktx.
