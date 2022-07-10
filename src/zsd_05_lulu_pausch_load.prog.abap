*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_PAUSCH_LOAD
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZSD_05_LULU_PAUSCH_LOAD.


tables: zsd_05_lulu_pau
      .
data: t_pausch         type table of zsd_05_lulu_pau WITH HEADER LINE
    , w_pausch         type zsd_05_lulu_pau
    , w_NETWR_OLD(15)  type c
    , w_NETWR_NEW(15)  type c
    , w_datum(10)      type c
    , c_delim          type c value ';'
    , begin of t_line occurs 0
    ,  line(1024)      type c
    , end of t_line
    , w_FILENAME_1     LIKE	RLGRAP-FILENAME value
                       'c:\temp\Grosskunde_Kontrolle.csv'
    , w_FILENAME_2     LIKE	RLGRAP-FILENAME value
                       ''
    , w_FILENAME       LIKE	RLGRAP-FILENAME
.

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
concatenate w_filename_1 w_filename_2 into w_filename.
condense w_filename no-gaps.
CALL FUNCTION 'WS_UPLOAD'
 EXPORTING
*   CODEPAGE                      = ' '
   FILENAME                      = w_FILENAME
   FILETYPE                      = 'ASC'
*   HEADLEN                       = ' '
*   LINE_EXIT                     = ' '
*   TRUNCLEN                      = ' '
*   USER_FORM                     = ' '
*   USER_PROG                     = ' '
*   DAT_D_FORMAT                  = ' '
* IMPORTING
*   FILELENGTH                    =
  TABLES
    data_tab                      = t_line
 EXCEPTIONS
   CONVERSION_ERROR              = 1
   FILE_OPEN_ERROR               = 2
   FILE_READ_ERROR               = 3
   INVALID_TYPE                  = 4
   NO_BATCH                      = 5
   UNKNOWN_ERROR                 = 6
   INVALID_TABLE_WIDTH           = 7
   GUI_REFUSE_FILETRANSFER       = 8
   CUSTOMER_ERROR                = 9
   NO_AUTHORITY                  = 10
   OTHERS                        = 11.
IF sy-subrc <> 0.
* Implement suitable error handling here
ENDIF.

break mcepo.

end-of-selection.

loop at t_line.
 if sy-tabix eq 1
 or t_line is initial.
*    exit.
 else.
  clear w_netwr_old.
  clear w_netwr_new.
*
  split t_line at c_delim into
   w_pausch-OBJ_KEY
   w_pausch-STADTTEIL
   w_pausch-PARZELLE
   w_pausch-OBJEKT
   w_pausch-KUNNR_RG
   w_pausch-NAME1
   w_pausch-FAKNR
   w_datum
   w_NETWR_OLD
   w_pausch-BERECHNUNG
   w_pausch-VERR_PERIO
   w_NETWR_NEW
   w_pausch-ABWEICHUNG.
   move sy-mandt    to w_pausch-mandt.
   move: w_datum+6(4) to w_pausch-FKDAT(4)
       , w_datum+3(2) to w_pausch-FKDAT+4(2)
       , w_datum(2)   to w_pausch-FKDAT+6(2).
   move w_netwr_old   to w_pausch-netwr_old.
   move w_netwr_new   to w_pausch-netwr_new.
   append w_pausch    to t_pausch.
 endif.
endloop.

break mcepo.

insert zsd_05_lulu_pau from table t_pausch.

commit work.
