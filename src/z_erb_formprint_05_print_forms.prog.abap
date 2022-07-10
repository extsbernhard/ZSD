*----------------------------------------------------------------------*
*   INCLUDE RLB_PRINT_FORMS                                            *
*----------------------------------------------------------------------*

*---------------------------------------------------------------------*
*       FORM PROTOCOL_UPDATE                                          *
*---------------------------------------------------------------------*
*       The messages are collected for the processing protocol.       *
*---------------------------------------------------------------------*

FORM PROTOCOL_UPDATE.

  CHECK XSCREEN = SPACE.
  CALL FUNCTION 'NAST_PROTOCOL_UPDATE'
       EXPORTING
            MSG_ARBGB = SYST-MSGID
            MSG_NR    = SYST-MSGNO
            MSG_TY    = SYST-MSGTY
            MSG_V1    = SYST-MSGV1
            MSG_V2    = SYST-MSGV2
            MSG_V3    = SYST-MSGV3
            MSG_V4    = SYST-MSGV4
       EXCEPTIONS
            OTHERS    = 1.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ADD_SMFRM_PROT
*&---------------------------------------------------------------------*
FORM ADD_SMFRM_PROT.

  DATA: LT_ERRORTAB             TYPE TSFERROR.
* DATA: LF_MSGNR                TYPE SY-MSGNO.
  FIELD-SYMBOLS: <FS_ERRORTAB>  TYPE LINE OF TSFERROR.

* get smart form protocoll
  CALL FUNCTION 'SSF_READ_ERRORS'
       IMPORTING
            ERRORTAB = LT_ERRORTAB.

* add smartform protocoll to nast protocoll
  LOOP AT LT_ERRORTAB ASSIGNING <FS_ERRORTAB>.
*   CLEAR LF_MSGNR.
*   LF_MSGNR = <FS_ERRORTAB>-ERRNUMBER.
    CALL FUNCTION 'NAST_PROTOCOL_UPDATE'
         EXPORTING
              MSG_ARBGB = <FS_ERRORTAB>-MSGID
*             MSG_NR    = LF_MSGNR
              MSG_NR    = <FS_ERRORTAB>-MSGNO
              MSG_TY    = <FS_ERRORTAB>-MSGTY
              MSG_V1    = <FS_ERRORTAB>-MSGV1
              MSG_V2    = <FS_ERRORTAB>-MSGV2
              MSG_V3    = <FS_ERRORTAB>-MSGV3
              MSG_V4    = <FS_ERRORTAB>-MSGV4
         EXCEPTIONS
              OTHERS    = 1.
  ENDLOOP.

ENDFORM.                               " ADD_SMFRM_PROT

*&---------------------------------------------------------------------*
*&      Form  SET_PRINT_PARAM
*&---------------------------------------------------------------------*
FORM SET_PRINT_PARAM USING    IS_ADDR_KEY LIKE ADDR_KEY
                              IS_DLV-LAND LIKE VBRK-LAND1
                     CHANGING CS_CONTROL_PARAM TYPE SSFCTRLOP
                              CS_COMPOSER_PARAM TYPE SSFCOMPOP
                              CS_RECIPIENT TYPE  SWOTOBJID
                              CS_SENDER TYPE  SWOTOBJID
                              CF_RETCODE TYPE SY-SUBRC.

  DATA: LS_ITCPO     TYPE ITCPO.
  DATA: LF_REPID     TYPE SY-REPID.
  DATA: LF_DEVICE    TYPE TDDEVICE.
  DATA: LS_RECIPIENT TYPE SWOTOBJID.
  DATA: LS_SENDER    TYPE SWOTOBJID.

  LF_REPID = SY-REPID.

*_____Hinweis 21.06.2004________________________________________________

*Im folgenden Funktionsbaustein "WFMC_PREPARE_SMART_FORM" wird das
*Formular vorbereitet. Unter anderem auch das Dezimalformat. In diesem
*wird das Dezimalformat durch den Syntax SET COUNTRY definiert. Durch
*diesen Syntax wird die Tabelle T005X überprüft, wie die Länder-
*einstellungen vorgenommen wurden, und danach übernommen.
*_______________________________________________________________________

  CALL FUNCTION 'WFMC_PREPARE_SMART_FORM'
       EXPORTING
            PI_NAST       = NAST
            PI_COUNTRY    = IS_DLV-LAND
            PI_ADDR_KEY   = IS_ADDR_KEY
            PI_REPID      = LF_REPID
            PI_SCREEN     = XSCREEN
       IMPORTING
            PE_RETURNCODE = CF_RETCODE
            PE_ITCPO      = LS_ITCPO
            PE_DEVICE     = LF_DEVICE
            PE_RECIPIENT  = CS_RECIPIENT
            PE_SENDER     = CS_SENDER.

  IF CF_RETCODE = 0.
    MOVE-CORRESPONDING LS_ITCPO TO CS_COMPOSER_PARAM.
*   CS_CONTROL_PARAM-NO_OPEN
*   CS_CONTROL_PARAM-NO_CLOSE
    CS_CONTROL_PARAM-DEVICE      = LF_DEVICE.
    CS_CONTROL_PARAM-NO_DIALOG   = 'X'.
    CS_CONTROL_PARAM-PREVIEW     = XSCREEN.
    CS_CONTROL_PARAM-GETOTF      = LS_ITCPO-TDGETOTF.
    CS_CONTROL_PARAM-LANGU       = NAST-SPRAS.
*   CS_CONTROL_PARAM-REPLANGU1
*   CS_CONTROL_PARAM-REPLANGU2
*   CS_CONTROL_PARAM-REPLANGU3
*   CS_CONTROL_PARAM-STARTPAGE
  ENDIF.
ENDFORM.                               " SET_PRINT_PARAM
*&---------------------------------------------------------------------*
*&      Form  CHECK_REPEAT
*&---------------------------------------------------------------------*
FORM CHECK_REPEAT .

  CLEAR REPEAT.
  SELECT * INTO *NAST FROM NAST WHERE KAPPL = NAST-KAPPL
                                AND   OBJKY = NAST-OBJKY
                                AND   KSCHL = NAST-KSCHL
                                AND   SPRAS = NAST-SPRAS
                                AND   PARNR = NAST-PARNR
                                AND   PARVW = NAST-PARVW
                                AND   NACHA BETWEEN '1' AND '4'.
    IF *NAST-VSTAT = '1'.
    REPEAT = 'X'.
    ENDIF.
  ENDSELECT.


ENDFORM.                    " CHECK_REPEAT
