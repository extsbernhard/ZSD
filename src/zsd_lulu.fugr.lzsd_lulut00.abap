*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZSD_05_LULU_PAU.................................*
DATA:  BEGIN OF STATUS_ZSD_05_LULU_PAU               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSD_05_LULU_PAU               .
CONTROLS: TCTRL_ZSD_05_LULU_PAU
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZSD_05_LULU_PAU               .
TABLES: ZSD_05_LULU_PAU                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
