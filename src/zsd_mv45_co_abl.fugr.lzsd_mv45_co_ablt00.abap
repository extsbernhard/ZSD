*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZSD_MV45_CO_ABLP................................*
TABLES: ZSD_MV45_CO_ABLP, *ZSD_MV45_CO_ABLP. "view work areas
CONTROLS: TCTRL_ZSD_MV45_CO_ABLP
TYPE TABLEVIEW USING SCREEN '0100'.
DATA: BEGIN OF STATUS_ZSD_MV45_CO_ABLP. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZSD_MV45_CO_ABLP.
* Table for entries selected to show on screen
DATA: BEGIN OF ZSD_MV45_CO_ABLP_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZSD_MV45_CO_ABLP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_MV45_CO_ABLP_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZSD_MV45_CO_ABLP_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZSD_MV45_CO_ABLP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_MV45_CO_ABLP_TOTAL.

*.........table declarations:.................................*
TABLES: ZSD_MV45_CO_ABL                .
