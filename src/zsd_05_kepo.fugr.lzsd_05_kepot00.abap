*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZSDTKPDOCART....................................*
DATA:  BEGIN OF STATUS_ZSDTKPDOCART                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSDTKPDOCART                  .
CONTROLS: TCTRL_ZSDTKPDOCART
            TYPE TABLEVIEW USING SCREEN '0007'.
*...processing: ZSDTKPFART......................................*
DATA:  BEGIN OF STATUS_ZSDTKPFART                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSDTKPFART                    .
CONTROLS: TCTRL_ZSDTKPFART
            TYPE TABLEVIEW USING SCREEN '0004'.
*...processing: ZSDTKPFLDPROP...................................*
DATA:  BEGIN OF STATUS_ZSDTKPFLDPROP                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSDTKPFLDPROP                 .
CONTROLS: TCTRL_ZSDTKPFLDPROP
            TYPE TABLEVIEW USING SCREEN '0008'.
*...processing: ZSDTKPKREIS.....................................*
DATA:  BEGIN OF STATUS_ZSDTKPKREIS                   .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSDTKPKREIS                   .
CONTROLS: TCTRL_ZSDTKPKREIS
            TYPE TABLEVIEW USING SCREEN '0003'.
*...processing: ZSDTKPMARB......................................*
DATA:  BEGIN OF STATUS_ZSDTKPMARB                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSDTKPMARB                    .
CONTROLS: TCTRL_ZSDTKPMARB
            TYPE TABLEVIEW USING SCREEN '0009'.
*...processing: ZSDTKPMAT.......................................*
DATA:  BEGIN OF STATUS_ZSDTKPMAT                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSDTKPMAT                     .
CONTROLS: TCTRL_ZSDTKPMAT
            TYPE TABLEVIEW USING SCREEN '0006'.
*...processing: ZSDTKPSTATART...................................*
DATA:  BEGIN OF STATUS_ZSDTKPSTATART                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSDTKPSTATART                 .
CONTROLS: TCTRL_ZSDTKPSTATART
            TYPE TABLEVIEW USING SCREEN '0001'.
*...processing: ZSDTKPSTATUS....................................*
DATA:  BEGIN OF STATUS_ZSDTKPSTATUS                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZSDTKPSTATUS                  .
CONTROLS: TCTRL_ZSDTKPSTATUS
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *ZSDTKPDOCART                  .
TABLES: *ZSDTKPFART                    .
TABLES: *ZSDTKPFLDPROP                 .
TABLES: *ZSDTKPKREIS                   .
TABLES: *ZSDTKPMARB                    .
TABLES: *ZSDTKPMAT                     .
TABLES: *ZSDTKPSTATART                 .
TABLES: *ZSDTKPSTATUS                  .
TABLES: ZSDTKPDOCART                   .
TABLES: ZSDTKPFART                     .
TABLES: ZSDTKPFLDPROP                  .
TABLES: ZSDTKPKREIS                    .
TABLES: ZSDTKPMARB                     .
TABLES: ZSDTKPMAT                      .
TABLES: ZSDTKPSTATART                  .
TABLES: ZSDTKPSTATUS                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
