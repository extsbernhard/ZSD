*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZSD_01_USRVORSYS................................*
DATA:  BEGIN OF STATUS_ZSD_01_USRVORSYS              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSD_01_USRVORSYS              .
CONTROLS: TCTRL_ZSD_01_USRVORSYS
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZSD_01_USRVORSYS              .
TABLES: ZSD_01_USRVORSYS               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
