*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZSD_MV45_ZABGRU.................................*
DATA:  BEGIN OF STATUS_ZSD_MV45_ZABGRU               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSD_MV45_ZABGRU               .
CONTROLS: TCTRL_ZSD_MV45_ZABGRU
            TYPE TABLEVIEW USING SCREEN '0102'.
*...processing: ZSD_MV45_ZPSTYV.................................*
DATA:  BEGIN OF STATUS_ZSD_MV45_ZPSTYV               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSD_MV45_ZPSTYV               .
CONTROLS: TCTRL_ZSD_MV45_ZPSTYV
            TYPE TABLEVIEW USING SCREEN '0101'.
*...processing: ZSD_MV45_ZUSCHL.................................*
DATA:  BEGIN OF STATUS_ZSD_MV45_ZUSCHL               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSD_MV45_ZUSCHL               .
CONTROLS: TCTRL_ZSD_MV45_ZUSCHL
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZSD_MV45_ZABGRU               .
TABLES: *ZSD_MV45_ZPSTYV               .
TABLES: *ZSD_MV45_ZUSCHL               .
TABLES: ZSD_MV45_ZABGRU                .
TABLES: ZSD_MV45_ZPSTYV                .
TABLES: ZSD_MV45_ZUSCHL                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
