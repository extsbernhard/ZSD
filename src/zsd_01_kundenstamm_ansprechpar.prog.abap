************************************************************************
* Report: ZSD_01_KUNDENSTAMM_ANSPRECHPAR     Autor: H. Stettler   MC   *
* -------------------------------            ------------------------  *
* Beschreibung                                                         *
* ------------                                                         *
* Lesen Kundenstamm-Ansprechpartner
* Aus Feld Vorname Wert lesen und löschen und Wert in Feld Internet    *
* schreiben Batch Input.
* -------------------------------------------------------------------- *
* Aenderungsverzeichnis:                                               *
* ----------------------                                               *
* Datum      Rel.   Name               Firma                           *
*                   - Beschreibung                                     *
* ---------- ----   -----------------  ------------------------------- *
* 10.06.2004 4.6C   H. Stettler        Mummert Consulting, Zürich      *
*                   - Neuanlage des Reports                            *
************************************************************************
REPORT ZSD_01_KUNDENSTAMM_ANSPRECHPAR.

***********************************************************************
* Definition of tables                                                *
***********************************************************************
TABLES: KNA1, KNVK.


include bdcrecx1.
***********************************************************************
* Definition of parameters ans selection-screen                       *
***********************************************************************
SELECTION-SCREEN BEGIN OF BLOCK 1 WITH FRAME TITLE text-p01.
PARAMETERS: p_ktokd like kna1-ktokd DEFAULT 'ZD66'.
SELECTION-SCREEN END OF BLOCK 1.
SELECTION-SCREEN BEGIN OF BLOCK 2 WITH FRAME TITLE text-p02.
PARAMETERS: P_LOE as checkbox.
SELECTION-SCREEN END OF BLOCK 2.


**********************************************************************
* Definition of internal variables                                    *
***********************************************************************
DATA: C_WRITE     LIKE SY-INDEX,           "geschriebene Datensätze
      C_READ      LIKE SY-INDEX,           "gelesene Datensätze
      C_OK        LIKE SY-INDEX.           "korrekt verarb. Datensätze

*------- SW - Switch --------------------------------------------------*
DATA: SW-HEADER(1) TYPE N VALUE 0.        "Switch Header nicht verarb.

*--------Interne Tabellen----------------------------------------------*
* Tabelle für die Datenübergabe

data: begin of w_kunr occurs 0,
      kunnr like kna1-kunnr,
end of w_kunr.

data: begin of w_ansp occurs 0,
      kunnr like kna1-kunnr,
      namev like knvk-namev,
end of w_ansp.


***********************************************************************
* Start of selection                                                  *
***********************************************************************
START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  SELECT KUNNR FROM KNA1 INTO CORRESPONDING FIELDS OF TABLE W_KUNR
                    WHERE KTOKD EQ P_KTOKD.

  LOOP AT W_KUNR.
    SELECT * FROM KNVK
     WHERE KUNNR EQ W_KUNR-KUNNR.
      IF sy-subrc EQ 0.
        IF KNVK-NAMEV CA '@'.
          MOVE KNVK-NAMEV TO W_ANSP-NAMEV.
          MOVE KNVK-KUNNR TO W_ANSP-KUNNR.
          APPEND W_ANSP.
        ENDIF.
      ENDIF.
    ENDSELECT.
  ENDLOOP.

  IF P_LOE NE 'X'.
    LOOP AT W_ANSP.
      Write: / W_ANSP-NAMEV, W_ANSP-KUNNR.
    ENDLOOP.
  ELSE.
    perform open_group.
    LOOP AT W_ANSP.
      Write: / W_ANSP-NAMEV, W_ANSP-KUNNR.


      perform bdc_dynpro      using 'SAPMF02D' '0101'.
      perform bdc_field       using 'BDC_CURSOR'
                                    'USE_ZAV'.
      perform bdc_field       using 'BDC_OKCODE'
                                    '/00'.
      perform bdc_field       using 'RF02D-KUNNR'
                                    W_ANSP-KUNNR.
      perform bdc_field       using 'RF02D-BUKRS'
                                    '1600'.
      perform bdc_field       using 'RF02D-VKORG'
                                    '1666'.
      perform bdc_field       using 'RF02D-VTWEG'
                                    '66'.
      perform bdc_field       using 'RF02D-SPART'
                                    '66'.
      perform bdc_field       using 'RF02D-D0360'
                                    'X'.
      perform bdc_field       using 'USE_ZAV'
                                    'X'.
      perform bdc_dynpro      using 'SAPMF02D' '0360'.
      perform bdc_field       using 'BDC_CURSOR'
                                    'KNVK-NAME1(01)'.
      perform bdc_field       using 'BDC_OKCODE'
                                    '=LSDP'.
      perform bdc_dynpro      using 'SAPMF02D' '1361'.
      perform bdc_field       using 'BDC_OKCODE'
                                    '=UPDA'.
      perform bdc_field       using 'BDC_CURSOR'
                                    'SZA5_D0700-SMTP_ADDR'.
*    perform bdc_field       using 'ADDR3_DATA-NAME_LAST'
*                                  record-NAME_LAST_008.
      perform bdc_field       using 'ADDR3_DATA-NAME_FIRST'
                                    ' '.
      perform bdc_field       using 'SZA5_D0700-SMTP_ADDR'
                                    W_ANSP-NAMEV.
      perform bdc_transaction using 'XD02'.

    ENDLOOP.
    perform close_group.
  ENDIF.
