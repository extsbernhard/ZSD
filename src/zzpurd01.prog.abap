*&---------------------------------------------------------------------*
*& Report  ZZPURD01
*& (Modification Note 1080954)
*&---------------------------------------------------------------------*
*& Deletes wrong VBFA records.
*& Always run report without UPDATE first
*& Report is in customer's own responsibility: read Note 170183
*&---------------------------------------------------------------------*

REPORT  ZZPURD01.

TABLES: VBFA, EKKN.

SELECT-OPTIONS: S_VBELN FOR  VBFA-VBELN,
                S_EBELN FOR  EKKN-EBELN,
                S_ERDAT FOR  VBFA-ERDAT  DEFAULT ' ' TO SY-DATUM.

CONSTANTS:
  VBTYP_BESTELL TYPE C  VALUE 'V',
  CHARX         TYPE C  VALUE 'X'.

DATA: BEGIN OF DA_VBFA OCCURS 50.
        INCLUDE STRUCTURE VBFA.
DATA: END OF DA_VBFA.

PARAMETERS: UPDATE AS CHECKBOX.

DATA: DEL_FLAG(1),
      DA_COUNTER(10) TYPE N.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
SELECT * FROM VBFA WHERE VBTYP_V IN
                   ('A','B','C','D','E','F','G','H','I','K','L','W')
                   AND VBTYP_N EQ VBTYP_BESTELL
                   AND VBELV IN S_VBELN
                   AND VBELN IN S_EBELN
                   AND ERDAT IN S_ERDAT.
  SELECT * FROM EKKN WHERE EBELN EQ VBFA-VBELN
                       AND EBELP EQ VBFA-POSNN.
    IF EKKN-VBELN NE VBFA-VBELV OR
       EKKN-VBELP NE VBFA-POSNV.
      DEL_FLAG = CHARX.
    ELSE.
      EXIT.
    ENDIF.
  ENDSELECT.
  IF SY-SUBRC NE 0.
    DEL_FLAG = CHARX.
  ENDIF.
  IF DEL_FLAG EQ CHARX.
    MOVE-CORRESPONDING VBFA TO DA_VBFA.
    APPEND DA_VBFA.
    IF UPDATE EQ CHARX.
      DELETE VBFA.
    ENDIF.
    CLEAR DEL_FLAG.
  ENDIF.
ENDSELECT.

FORMAT INTENSIFIED.
WRITE 'Wrong VBFA-records:'.
WRITE: AT  /2(10) 'SalesOrder' COLOR COL_TOTAL   INTENSIFIED,
       AT  13(6)  'Item'       COLOR COL_HEADING INTENSIFIED,
       AT  20(10) 'PurchOrder' COLOR COL_TOTAL   INTENSIFIED,
       AT  31(6)  'Item'       COLOR COL_HEADING INTENSIFIED,
       AT  38(8)  'CreaDate'   COLOR COL_TOTAL   INTENSIFIED,
       AT  47(15) 'Quantity'   COLOR COL_GROUP   INTENSIFIED,
       AT  63(4)  'Unit'       COLOR COL_GROUP   INTENSIFIED,
       AT  68(15) 'Value'      COLOR COL_GROUP   INTENSIFIED,
       AT  84(5)  'Curr'       COLOR COL_GROUP   INTENSIFIED.
FORMAT INTENSIFIED OFF.

LOOP AT DA_VBFA.
  DA_COUNTER = DA_COUNTER + 1.
  WRITE: AT  /2(10) DA_VBFA-VBELV   COLOR COL_KEY,
         AT  13(6)  DA_VBFA-POSNV   COLOR COL_HEADING ,
         AT  20(10) DA_VBFA-VBELN   COLOR COL_KEY     ,
         AT  31(6)  DA_VBFA-POSNN   COLOR COL_HEADING ,
         AT  38(8)  DA_VBFA-ERDAT   COLOR COL_KEY     ,
         AT  47(15) DA_VBFA-RFMNG   COLOR COL_GROUP   ,
         AT  63(3)  DA_VBFA-MEINS   COLOR COL_GROUP   ,
         AT  68(15) DA_VBFA-RFWRT   COLOR COL_GROUP   ,
         AT  84(5)  DA_VBFA-WAERS   COLOR COL_GROUP   .
ENDLOOP.
SKIP.

IF SY-SUBRC NE 0.
  WRITE 'No wrong records were found.'.
ELSE.
  IF UPDATE EQ SPACE.
    WRITE: 'Number of wrong records: ',DA_COUNTER NO-ZERO.
  ELSE.
    WRITE: 'Number of deleted records: ',DA_COUNTER NO-ZERO.
  ENDIF.
ENDIF.
* END OF REPORT ZZPURD01
