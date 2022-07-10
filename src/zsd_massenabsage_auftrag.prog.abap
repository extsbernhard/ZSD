*&---------------------------------------------------------------------*
*& Report  ZSD_MASSENABSAGE_AUFTRAG
*&
*&---------------------------------------------------------------------*
REPORT  zsd_massenabsage_auftrag LINE-SIZE 80.
TABLES  zsd_01_tab.

PARAMETERS anzahl TYPE i DEFAULT 5.
PARAMETERS absgrund(2)   DEFAULT 'Z2'.
PARAMETERS mappenn(10)   DEFAULT 'FW'.

* Felder für Mappenerstellung
DATA  BEGIN OF bdcdata OCCURS 0.   "Feldtabelle Batchinput-Dynpros
        INCLUDE STRUCTURE bdcdata.
DATA  END OF bdcdata.
DATA group         TYPE apqi-groupid.
DATA tcode TYPE tstc-tcode.

DATA zaehler TYPE i.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
zaehler = 0.
tcode = 'VA02'.
group = 'MASSLVA02'.

REFRESH bdcdata.

WRITE: / 'Verarbeitete Belege:'.

PERFORM open_group.

SELECT * FROM zsd_01_tab
  WHERE mappe = mappenn
   AND sap_belnr NE ' '.

  zaehler = zaehler + 1.
  IF zaehler > anzahl. EXIT. ENDIF.

  PERFORM bdc_dynpro      USING 'SAPMV45A'           '0102'.
  PERFORM bdc_field       USING 'BDC_CURSOR'         'VBAK-VBELN'.
  PERFORM bdc_field       USING 'BDC_OKCODE'         '/00'.
  PERFORM bdc_field       USING 'VBAK-VBELN'         zsd_01_tab-sap_belnr.

  PERFORM bdc_dynpro      USING 'SAPMV45A'           '4001'.
  PERFORM bdc_field       USING 'BDC_OKCODE'         '=BABS'.
  PERFORM bdc_field       USING 'BDC_SUBSCR'         'SAPMV45A                                4021SUBSCREEN_HEADER'.

  PERFORM bdc_dynpro      USING 'SAPMV45A'           '0250'.
  PERFORM bdc_field       USING 'BDC_OKCODE'         '=SUEB'.
  PERFORM bdc_field       USING 'RV45A-S_ABGRU'      absgrund.

  PERFORM bdc_dynpro      USING 'SAPMV45A'           '4001'.
  PERFORM bdc_field       USING 'BDC_OKCODE'         '=SICH'.
  PERFORM bdc_field       USING 'BDC_SUBSCR'         'SAPMV45A                                4021SUBSCREEN_HEADER'.
  PERFORM bdc_field       USING 'BDC_SUBSCR'         'SAPMV45A                                4701PART-SUB'.
  PERFORM bdc_field       USING 'BDC_CURSOR'         'KUAGV-KUNNR'.
  PERFORM bdc_field       USING 'BDC_SUBSCR'         'SAPMV45A                                4409SUBSCREEN_BODY'.
  PERFORM bdc_field       USING 'BDC_SUBSCR'         'SAPMV45A                                4922SUBSCREEN_TC'.
  PERFORM bdc_field       USING 'BDC_SUBSCR'         'SAPMV45A                                4050SUBSCREEN_BUTTONS'.

  PERFORM bdc_dynpro      USING 'SAPMV45A'           '0101'.
  PERFORM bdc_field       USING 'BDC_OKCODE'         '=OPT1'.

  WRITE: / zsd_01_tab-sap_belnr.
  PERFORM bdc_transaction USING tcode.
ENDSELECT.


PERFORM close_group.

*&---------------------------------------------------------------------*
*&      Form  bdc_dynpro
*&---------------------------------------------------------------------*
FORM bdc_dynpro USING program dynpro.
  CLEAR bdcdata.
  bdcdata-program  = program.
  bdcdata-dynpro   = dynpro.
  bdcdata-dynbegin = 'X'.
  APPEND bdcdata.
ENDFORM.                    "bdc_dynpro

*&---------------------------------------------------------------------*
*&      Form  bdc_field
*&---------------------------------------------------------------------*
FORM bdc_field USING fnam fval.
  CLEAR bdcdata.
  bdcdata-fnam     = fnam.
  bdcdata-fval     = fval.
  APPEND bdcdata.
ENDFORM.                    "bdc_field
*&---------------------------------------------------------------------*
*&      Form  open_group
*&---------------------------------------------------------------------*
FORM open_group.
  CALL FUNCTION 'BDC_OPEN_GROUP'
    EXPORTING
      client = sy-mandt
      group  = group
      user   = sy-uname.
ENDFORM.                    "open_group
*&---------------------------------------------------------------------*
*&      Form  close_group
*&---------------------------------------------------------------------*
FORM close_group.
  CALL FUNCTION 'BDC_CLOSE_GROUP'.
ENDFORM.                    "close_group
*&---------------------------------------------------------------------*
*&      Form  bdc_transaction
*&---------------------------------------------------------------------*
FORM bdc_transaction USING tcode.
  CALL FUNCTION 'BDC_INSERT'
    EXPORTING
      tcode     = tcode
    TABLES
      dynprotab = bdcdata.
  REFRESH bdcdata.
ENDFORM.                    "bdc_transaction
