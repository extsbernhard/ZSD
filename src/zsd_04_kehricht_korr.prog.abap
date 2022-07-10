*----------------------------------------------------------------------*
* Report ZSD_04_KEHRICHT_KORR
*----------------------------------------------------------------------*
* Erstellt durch: Exsigno AG, Dübendorf / R. De Simone
*             am: 18. Juli 2007
*----------------------------------------------------------------------*
* Beschreibung:
* Datenübernahme Stammdaten Kehrichgrundgebühr
*----------------------------------------------------------------------*
REPORT zsd_04_kehricht_korr.
*
TABLES: zsd_04_kehricht.               "Gebühren: Kehrichtgrundgebühr
PARAMETERS: p_datum LIKE zsd_04_kehricht-verr_datum_schl.
DATA: t_kehricht TYPE zsd_04_kehricht OCCURS 0 WITH HEADER LINE.
*
START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  SELECT        * FROM  zsd_04_kehricht
         INTO TABLE t_kehricht
         WHERE  verr_datum_schl  = p_datum.
  LOOP AT t_kehricht.
    SELECT SINGLE * FROM  zsd_04_kehricht CLIENT SPECIFIED
           WHERE  mandt      = t_kehricht-mandt
           AND    stadtteil  = t_kehricht-stadtteil
           AND    parzelle   = t_kehricht-parzelle
           AND    objekt     = t_kehricht-objekt.
    zsd_04_kehricht-verr_datum_schl = '99991231'.
    UPDATE zsd_04_kehricht.
  ENDLOOP.
