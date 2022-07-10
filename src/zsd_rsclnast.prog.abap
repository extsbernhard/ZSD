REPORT ZSD_RSCLNAST LINE-SIZE 132.
************************************************************************
* The report RSCLNAST was written to clear up the table NAST. After    *
* some years of production, this table will contain a lot of data      *
* which may not be important anymore.                                  *
************************************************************************
* Anpassungen wurden gemacht, damit verarbeitete Nachrichtensätze nicht*
* gelöscht werden, damit kann man dann ungewollt erzeugte Nachrichten- *
* abrufsätze löschen... Epo20131128                                    *

INCLUDE <CNTN01>.

*-----------------------------------------------------------------------
* database tables
*-----------------------------------------------------------------------
TABLES: NAST.
TABLES: T006, T006A.
*-----------------------------------------------------------------------
* database tables
*-----------------------------------------------------------------------

TYPE-POOLS: SLIS.

CONSTANTS: GC_REPID TYPE SYREPID VALUE SY-REPID, "Current Program Name
           GC_TOP_OF_PAGE TYPE SLIS_ALV_EVENT-FORM VALUE 'TOP_OF_PAGE',
           GC_STRU TYPE  SLIS_TABNAME VALUE 'RSCLNAST_ALV',
           GC_TAB TYPE SLIS_TABNAME  VALUE 'GS_OUTTAB_NAST',
           GC_COM_H TYPE SLIS_LISTHEADER-TYP VALUE 'H', "Commentary type
           GC_COM_S TYPE SLIS_LISTHEADER-TYP VALUE 'S', "Commentary type
           GC_COM_A TYPE SLIS_LISTHEADER-TYP VALUE 'A', "Commentary type
           GC_P_SIMUL TYPE ELEMGENKEY VALUE 'P_SIMUL', " Elementary Key
           GC_5          TYPE N VALUE 5.


DATA: ANTWORT TYPE C,
      L_STARTDATE LIKE SY-DATUM,
      INAST LIKE NAST OCCURS 10000 WITH HEADER LINE.
DATA: L_COUNT TYPE I.

DATA: GT_TOP_OF_PAGE TYPE SLIS_T_LISTHEADER,
      G_SH_TXT TYPE PIFOBJTEXT.


TYPES: BEGIN OF TY_OUTTAB,
       ACTION(12) TYPE C,
       KAPPL LIKE NAST-KAPPL,
       OBJKY LIKE NAST-OBJKY,
       KSCHL LIKE NAST-KSCHL,
       NACHA LIKE NAST-NACHA,
       PARNR LIKE NAST-PARNR,
       PARVW LIKE NAST-PARVW,
       ERDAT LIKE NAST-ERDAT,
       ERUHR LIKE NAST-ERUHR,
       VSZTP LIKE NAST-VSZTP,
       STATUS(12) TYPE C.
TYPES: END OF TY_OUTTAB.

DATA: GT_OUTTAB_NAST TYPE STANDARD TABLE OF TY_OUTTAB. " Internal table
DATA: GS_OUTTAB_NAST TYPE TY_OUTTAB. " structure

DATA: GS_COMMENTARY TYPE SLIS_LISTHEADER,       "Commentary work area
      GT_COMMENTARY TYPE SLIS_T_LISTHEADER, "Commentary table
      G_TYP TYPE SLIS_LISTHEADER-TYP,       "Commentary type
      G_KEY TYPE SLIS_LISTHEADER-KEY,       "Commentary key
      GS_TLINE TYPE TLINE,
      GT_TLINE TYPE TABLE OF TLINE,
      G_TDLINE TYPE TLINE-TDLINE.


*-----------------------------------------------------------------------
* select options
*-----------------------------------------------------------------------
SELECT-OPTIONS: S_KAPPL FOR NAST-KAPPL,
                S_OBJKY FOR NAST-OBJKY,
                S_KSCHL FOR NAST-KSCHL,
                S_NACHA FOR NAST-NACHA,
                s_vstat for nast-vstat."Verarbeitungskennzeichen
SELECTION-SCREEN SKIP.
SELECT-OPTIONS: S_PARNR FOR NAST-PARNR,
                S_PARVW FOR NAST-PARVW.
SELECTION-SCREEN SKIP.
SELECT-OPTIONS: S_ERDAT FOR NAST-ERDAT,
                S_ERUHR FOR NAST-ERUHR.
PARAMETERS DELTA(4) TYPE N.
PARAMETERS UNIT LIKE T006-MSEHI.
SELECTION-SCREEN  COMMENT 50(10) U_TEXT FOR FIELD UNIT.
SELECTION-SCREEN SKIP.
SELECT-OPTIONS: S_VSZTP FOR NAST-VSZTP.
SELECTION-SCREEN SKIP.
PARAMETERS NORMAL RADIOBUTTON GROUP RG1.
PARAMETERS PREVIEW RADIOBUTTON GROUP RG1.
PARAMETERS CONF_ALL RADIOBUTTON GROUP RG1.
Parameters verarb radiobutton group RG1.

************************************************************************
*                                                                      *
************************************************************************
INITIALIZATION.
  SELECT SINGLE * FROM T006 WHERE MSEHI = 'TAG'.
  IF SY-SUBRC EQ 0.
    SELECT SINGLE * FROM T006A WHERE SPRAS = SY-LANGU
                              AND MSEHI = T006-MSEHI.
    IF SY-SUBRC EQ 0.
      UNIT = T006-MSEHI.
      U_TEXT = T006A-MSEHT.
    ENDIF.
  ENDIF.

**** selection screen helps
AT SELECTION-SCREEN ON VALUE-REQUEST FOR UNIT.
  PERFORM VALUE_REQUEST_UNIT.

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
* evaluation of startdate
  CLEAR L_STARTDATE.
  IF NOT DELTA IS INITIAL.
    CALL FUNCTION 'START_TIME_DETERMINE'
         EXPORTING
              DURATION                   = DELTA
              UNIT                       = UNIT
*           FACTORY_CALENDAR           =
         IMPORTING
              START_DATE                 = L_STARTDATE
         EXCEPTIONS
              FACTORY_CALENDAR_NOT_FOUND = 1
              DATE_OUT_OF_CALENDAR_RANGE = 2
              DATE_NOT_VALID             = 3
              UNIT_CONVERSION_ERROR      = 4
              SI_UNIT_MISSING            = 5
              PARAMETERS_NOT_VALID       = 6
              OTHERS                     = 7.
    IF SY-SUBRC NE 0.
      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO WITH
                 SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDIF.
* confirm deletion
  IF PREVIEW EQ SPACE.
    IF SY-BATCH NE SPACE OR SY-BINPT NE SPACE.
      ANTWORT = 'J'.
    ELSE.
      CALL FUNCTION 'POPUP_TO_CONFIRM_STEP'
        EXPORTING
          DEFAULTOPTION = 'N'
          TEXTLINE1     = TEXT-002
          TEXTLINE2     = TEXT-003
          TITEL         = TEXT-001
          START_COLUMN  = 25
          START_ROW     = 6
        IMPORTING
          ANSWER        = ANTWORT.
    ENDIF.
  ELSE.
    ANTWORT = 'J'.
  ENDIF.
  IF ANTWORT = 'J'.
* process deletion
    SELECT * FROM NAST INTO TABLE INAST
                       WHERE KAPPL IN S_KAPPL AND
                             OBJKY IN S_OBJKY AND
                             KSCHL IN S_KSCHL AND
                             NACHA IN S_NACHA AND
                             PARNR IN S_PARNR AND
                             PARVW IN S_PARVW AND
                             ERDAT IN S_ERDAT AND
                             ERUHR IN S_ERUHR AND
                             VSZTP IN S_VSZTP and
                             vstat in s_vstat.    "Verarbeitungskennz.
    L_COUNT = 0.
    LOOP AT INAST.
*
      ADD 1 TO L_COUNT.
      IF L_COUNT EQ 1000.
        CLEAR L_COUNT.
        COMMIT WORK.
      ENDIF.
* check creating date
      IF NOT L_STARTDATE IS INITIAL.
        CHECK: INAST-ERDAT LT L_STARTDATE.
      ENDIF.
* Storing the values of in the GT_OUTTAB Internal Table
      if verarb = space.
      MOVE : TEXT-010      TO GS_OUTTAB_NAST-ACTION,
             INAST-KAPPL   TO GS_OUTTAB_NAST-KAPPL,
             INAST-OBJKY   TO GS_OUTTAB_NAST-OBJKY,
             INAST-KSCHL   TO GS_OUTTAB_NAST-KSCHL,
             INAST-NACHA   TO GS_OUTTAB_NAST-NACHA,
             INAST-PARNR   TO GS_OUTTAB_NAST-PARNR,
             INAST-PARVW   TO GS_OUTTAB_NAST-PARVW,
             INAST-ERDAT   TO GS_OUTTAB_NAST-ERDAT,
             INAST-ERUHR   TO GS_OUTTAB_NAST-ERUHR,
             INAST-VSZTP   TO GS_OUTTAB_NAST-VSZTP,
             TEXT-011      TO GS_OUTTAB_NAST-STATUS.
      APPEND GS_OUTTAB_NAST TO GT_OUTTAB_NAST.
      else.
      MOVE : TEXT-020      TO GS_OUTTAB_NAST-ACTION,
             INAST-KAPPL   TO GS_OUTTAB_NAST-KAPPL,
             INAST-OBJKY   TO GS_OUTTAB_NAST-OBJKY,
             INAST-KSCHL   TO GS_OUTTAB_NAST-KSCHL,
             INAST-NACHA   TO GS_OUTTAB_NAST-NACHA,
             INAST-PARNR   TO GS_OUTTAB_NAST-PARNR,
             INAST-PARVW   TO GS_OUTTAB_NAST-PARVW,
             INAST-ERDAT   TO GS_OUTTAB_NAST-ERDAT,
             INAST-ERUHR   TO GS_OUTTAB_NAST-ERUHR,
             INAST-VSZTP   TO GS_OUTTAB_NAST-VSZTP,
             TEXT-021      TO GS_OUTTAB_NAST-STATUS.
      APPEND GS_OUTTAB_NAST TO GT_OUTTAB_NAST.
      endif.
      IF PREVIEW = SPACE.
        IF CONF_ALL <> SPACE.
*       stelle frage
          IF SY-BATCH NE SPACE OR SY-BINPT NE SPACE.
            ANTWORT = 'J'.
          ELSE.
            CALL FUNCTION 'POPUP_TO_CONFIRM_WITH_MESSAGE'
              EXPORTING
                DEFAULTOPTION = 'N'
                DIAGNOSETEXT1 = TEXT-004
                DIAGNOSETEXT2 = INAST
                DIAGNOSETEXT3 = TEXT-005
                TEXTLINE1     = TEXT-004
                TEXTLINE2     = TEXT-005
                TITEL         = TEXT-006
                START_COLUMN  = 25
                START_ROW     = 6
              IMPORTING
                ANSWER        = ANTWORT.
          ENDIF.
          IF ANTWORT = 'J'.
            PERFORM CLEANSWEEP USING  INAST.
          ELSEIF ANTWORT = 'A'.
            EXIT.
          ENDIF.
        ELSEif normal <> space.
          PERFORM CLEANSWEEP USING  INAST.
        elseif verarb <> space.
          inast-vstat = '1'.
          modify inast.
          modify nast from inast.
        ENDIF.
      ENDIF.
    ENDLOOP.

    COMMIT WORK.

    IF GT_OUTTAB_NAST[] IS NOT INITIAL.
      PERFORM OUTPUT_ALV.
    ENDIF.

  ENDIF.

*---------------------------------------------------------------------*
*       FORM CLEANSWEEP                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM CLEANSWEEP USING INAST STRUCTURE NAST.
  DATA: TDNAME LIKE THEAD-TDNAME,
        L_MESSAGE TYPE SWC_OBJECT.
  SWC_CONTAINER LT_CONTAINER.
* CLEAR PROTOCOL
  IF NOT INAST-CMFPNR IS INITIAL.
    CALL FUNCTION 'NAST_PROTOCOL_DELETE'
      EXPORTING
        NR                    = INAST-CMFPNR
      EXCEPTIONS
        CALLED_WITHOUT_VALUES = 01.
  ENDIF.
* clear mailtexts
  TDNAME = INAST(66).
  IF INAST-NACHA = '7'.
* delete object (where applicable)
    IF INAST-TDNAME NE SPACE.
      SWC_CREATE_OBJECT L_MESSAGE 'MESSAGE' INAST-TDNAME.
      SWC_CALL_METHOD L_MESSAGE 'Delete' LT_CONTAINER.
    ENDIF.
* delete mailtext
    CALL FUNCTION 'DELETE_TEXT'
         EXPORTING
*             CLIENT          = " SY-MANDT
              ID              = 'BEWG'
              LANGUAGE        = SY-LANGU
              NAME            = TDNAME
              OBJECT          = 'OCS'
              SAVEMODE_DIRECT = 'X'
*             TEXTMEMORY_ONLY = " ' '
         EXCEPTIONS
              NOT_FOUND       = 01.
  ENDIF.
* CLEAR TABLE NAST
  MOVE-CORRESPONDING INAST TO NAST.
  DELETE NAST.
ENDFORM.                    "CLEANSWEEP

*---------------------------------------------------------------------*
*       FORM VALUE_REQUEST_UNIT                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM VALUE_REQUEST_UNIT.
  DATA : BEGIN OF HELP_VAL OCCURS 0.
          INCLUDE STRUCTURE HELP_VALUE.
  DATA : END OF HELP_VAL.
  DATA : BEGIN OF VALUES OCCURS 0,
           DATA(40),
         END OF VALUES.
* value_request for unit --> T006-msehi, T006-dimid = 'TIME'
  CLEAR HELP_VAL.
  REFRESH HELP_VAL.
  MOVE 'T006' TO HELP_VAL-TABNAME.
  MOVE 'MSEHI' TO HELP_VAL-FIELDNAME.
  MOVE 'X' TO    HELP_VAL-SELECTFLAG.
  APPEND HELP_VAL.
  MOVE 'T006A' TO HELP_VAL-TABNAME.
  MOVE 'MSEHT' TO HELP_VAL-FIELDNAME.
  CLEAR  HELP_VAL-SELECTFLAG.
  APPEND HELP_VAL.
* we only want time intervals which are at least a day or so
  SELECT * FROM T006 WHERE DIMID EQ 'TIME'   " dimension = time
                     AND NENNR = 1     " greater than second
                     AND EXP10 = 0                          "
                     AND ZAEHL > 3600  " greater than hour
                                ORDER BY PRIMARY KEY.
    MOVE T006-MSEHI TO VALUES.
    APPEND VALUES.
* read the description for this entry  in t006a
    SELECT SINGLE * FROM T006A WHERE SPRAS = SY-LANGU
                              AND MSEHI = T006-MSEHI.
    IF SY-SUBRC EQ 0.
      MOVE T006A-MSEHT TO VALUES.
      APPEND VALUES.
    ENDIF.
  ENDSELECT.
* here comes the popup
  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
       EXPORTING
*           CUCOL                         = 0
*           CUROW                         = 0
*           DISPLAY                       = ' '
            FIELDNAME                     = 'MSEHI'
            TABNAME                       = 'T006'
*           NO_MARKING_OF_CHECKVALUE      = ' '
       TITLE_IN_VALUES_LIST          = TEXT-500    "  'Zeiteinheit'
       TITEL                         = TEXT-501  "'Archivierungsperiode'
            SHOW_ALL_VALUES_AT_FIRST_TIME = 'X'
       IMPORTING
            SELECT_VALUE                  = UNIT
       TABLES
            FIELDS                        = HELP_VAL
            VALUETAB                      = VALUES
       EXCEPTIONS
            FIELD_NOT_IN_DDIC             = 1
            MORE_THEN_ONE_SELECTFIELD     = 2
            NO_SELECTFIELD                = 3
            OTHERS                        = 4.
  IF SY-SUBRC EQ 0.
    SELECT SINGLE * FROM T006A WHERE SPRAS = SY-LANGU
                              AND MSEHI = UNIT.
    IF SY-SUBRC EQ 0.
      U_TEXT =  T006A-MSEHT.
    ENDIF.
  ENDIF.
ENDFORM.                    "VALUE_REQUEST_UNIT

*&---------------------------------------------------------------------*
*&      Form  OUTPUT_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM OUTPUT_ALV .

  DATA: LT_FIELDCAT TYPE SLIS_T_FIELDCAT_ALV,
          LT_EVENTTAB TYPE SLIS_T_EVENT,
          LS_FIELDCAT TYPE SLIS_FIELDCAT_ALV,
          LS_LAYOUT   TYPE SLIS_LAYOUT_ALV.


* Build the layout for the ALV
  PERFORM LAYOUT_GET  CHANGING LS_LAYOUT.

* Build the field catalog for the ALV.
  PERFORM FIELDCAT_ALV_MERGE USING GC_TAB
                                   GC_STRU
                             CHANGING  LT_FIELDCAT.

* Build the Event List for the Simple ALV.
  PERFORM EVENTTAB_ALV_BUILD CHANGING LT_EVENTTAB.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
     I_CALLBACK_PROGRAM                = GC_REPID
     IS_LAYOUT                         = LS_LAYOUT
     IT_FIELDCAT                       = LT_FIELDCAT
     IT_EVENTS                         = LT_EVENTTAB
   TABLES
      T_OUTTAB                          =  GT_OUTTAB_NAST
      EXCEPTIONS
     PROGRAM_ERROR                     = 1
     OTHERS                            = 2
            .
  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " OUTPUT_ALV

*&---------------------------------------------------------------------*
*&      Form  FIELDCAT_ALV_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->IV_TAB  text
*      -->IV_STRU  text
*      <--XT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM FIELDCAT_ALV_MERGE  USING    IV_TAB TYPE  SLIS_TABNAME
                                  IV_STRU LIKE  DD02L-TABNAME
                         CHANGING XT_FIELDCAT TYPE SLIS_T_FIELDCAT_ALV.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      I_PROGRAM_NAME         = GC_REPID
*      I_INTERNAL_TABNAME     = IV_TAB
      I_STRUCTURE_NAME       = IV_STRU
    CHANGING
      CT_FIELDCAT            = XT_FIELDCAT
    EXCEPTIONS
      INCONSISTENT_INTERFACE = 1
      PROGRAM_ERROR          = 2
      OTHERS                 = 3.

  IF SY-SUBRC <> 0.
    MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
           WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " FIELDCAT_ALV_BUILD

*&---------------------------------------------------------------------*
*&      Form  EVENTTAB_ALV_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--XT_EVENTTAB  text
*----------------------------------------------------------------------*
FORM EVENTTAB_ALV_BUILD  CHANGING XT_EVENTTAB TYPE SLIS_T_EVENT.

  DATA: LS_EVENTS TYPE SLIS_ALV_EVENT.

  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    EXPORTING
      I_LIST_TYPE = 0
    IMPORTING
      ET_EVENTS   = XT_EVENTTAB.

  READ TABLE XT_EVENTTAB INTO LS_EVENTS WITH KEY NAME =
  SLIS_EV_TOP_OF_PAGE.
  IF SY-SUBRC = 0.
    LS_EVENTS-FORM = GC_TOP_OF_PAGE.
    MODIFY XT_EVENTTAB FROM LS_EVENTS INDEX SY-TABIX TRANSPORTING FORM.
  ENDIF.


ENDFORM.                    " EVENTTAB_ALV_BUILD
*&---------------------------------------------------------------------*
*&      Form  layout_get
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--XS_LAYOUT  text
*----------------------------------------------------------------------*
FORM LAYOUT_GET  CHANGING XS_LAYOUT TYPE SLIS_LAYOUT_ALV.

  CONSTANTS LC_X  TYPE C VALUE 'X'.

  CLEAR XS_LAYOUT.

  XS_LAYOUT-COLWIDTH_OPTIMIZE     = LC_X.
  XS_LAYOUT-ALLOW_SWITCH_TO_LIST  = LC_X.

ENDFORM.                    " layout_get

*---------------------------------------------------------------------*
*       FORM TOP_OF_PAGE                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM TOP_OF_PAGE.                                           "#EC CALLED

  REFRESH: GT_TOP_OF_PAGE.

* Subroutine to build heading
  PERFORM HEADER_BUILD USING GT_TOP_OF_PAGE.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            IT_LIST_COMMENTARY = GT_TOP_OF_PAGE.
ENDFORM.                    "TOP_OF_PAGE


*&---------------------------------------------------------------------*
*&      Form  HEADER_BUILD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->XT_TOP_OF_PAGE  text
*----------------------------------------------------------------------*
FORM HEADER_BUILD  USING  XT_TOP_OF_PAGE TYPE SLIS_T_LISTHEADER.

  CLEAR : GS_COMMENTARY, G_KEY, G_TDLINE.  "New code

  Refresh: GT_COMMENTARY.
  MOVE SY-TITLE TO G_TDLINE.
  PERFORM APPEND_COMMENTARY USING GC_COM_H G_KEY G_TDLINE.

  APPEND lines of GT_COMMENTARY TO XT_TOP_OF_PAGE.


  IF PREVIEW = 'X'.
    CALL FUNCTION 'PAK_GET_SHORTTEXT_DTEL'
      EXPORTING
        I_ELEM_KEY   = GC_P_SIMUL
        I_LANGUAGE   = SY-LANGU
      IMPORTING
        E_SHORT_TEXT = G_SH_TXT.

    GS_COMMENTARY-TYP  = GC_COM_S.
    GS_COMMENTARY-INFO = G_SH_TXT.
    APPEND GS_COMMENTARY TO XT_TOP_OF_PAGE.
    CLEAR: GS_COMMENTARY.
  ENDIF.


ENDFORM.                    " HEADER_BUILD

*&---------------------------------------------------------------------*
*&      Form  append_commentary
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->I_TYP     Commentary type
*      -->I_KEY     Commentary key
*      -->I_TDLINE  Commenatry line
*----------------------------------------------------------------------*
FORM APPEND_COMMENTARY  USING I_TYP TYPE SLIS_LISTHEADER-TYP
                              I_KEY TYPE SLIS_LISTHEADER-KEY
                              I_TDLINE TYPE TLINE-TDLINE.

* Check string length and wrap if necessary
  IF STRLEN( I_TDLINE ) > 60.
    CLEAR: GS_TLINE, GT_TLINE.
    GS_TLINE-TDLINE = I_TDLINE.
    APPEND GS_TLINE TO GT_TLINE.
*   Wrap the 'info' line into separate lines
    CALL FUNCTION 'FORMAT_TEXTLINES'
      EXPORTING
        FORMATWIDTH = 60
        LINEWIDTH   = 132
        STARTLINE   = 1
      TABLES
        LINES       = GT_TLINE
      EXCEPTIONS
        OTHERS      = 0.
*   Get back string parts and append to commentary table
    LOOP AT GT_TLINE INTO GS_TLINE.
      CLEAR GS_COMMENTARY.
      IF SY-TABIX = 1.
        GS_COMMENTARY-KEY = I_KEY.
      ENDIF.
      GS_COMMENTARY-TYP = I_TYP.
      GS_COMMENTARY-INFO = GS_TLINE-TDLINE.
      APPEND GS_COMMENTARY TO GT_COMMENTARY.
    ENDLOOP.
  ELSE.   "String length less than 60
    CLEAR GS_COMMENTARY.
    GS_COMMENTARY-TYP = I_TYP.
    GS_COMMENTARY-KEY = I_KEY.
    GS_COMMENTARY-INFO = I_TDLINE.
    APPEND GS_COMMENTARY TO GT_COMMENTARY.
  ENDIF.

ENDFORM.                    " append_commentary
