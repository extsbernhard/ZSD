*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZSD_IV_STG001...................................*
DATA:  BEGIN OF STATUS_ZSD_IV_STG001                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSD_IV_STG001                 .
CONTROLS: TCTRL_ZSD_IV_STG001
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *ZSD_IV_STG001                 .
TABLES: ZSD_IV_STG001                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
