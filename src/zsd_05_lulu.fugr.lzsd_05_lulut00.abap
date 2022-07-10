*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZSD_04_CHG_CUSTP................................*
TABLES: ZSD_04_CHG_CUSTP, *ZSD_04_CHG_CUSTP. "view work areas
CONTROLS: TCTRL_ZSD_04_CHG_CUSTP
TYPE TABLEVIEW USING SCREEN '0006'.
DATA: BEGIN OF STATUS_ZSD_04_CHG_CUSTP. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZSD_04_CHG_CUSTP.
* Table for entries selected to show on screen
DATA: BEGIN OF ZSD_04_CHG_CUSTP_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZSD_04_CHG_CUSTP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_04_CHG_CUSTP_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZSD_04_CHG_CUSTP_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZSD_04_CHG_CUSTP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_04_CHG_CUSTP_TOTAL.

*...processing: ZSD_05_HINWEISP.................................*
TABLES: ZSD_05_HINWEISP, *ZSD_05_HINWEISP. "view work areas
CONTROLS: TCTRL_ZSD_05_HINWEISP
TYPE TABLEVIEW USING SCREEN '0005'.
DATA: BEGIN OF STATUS_ZSD_05_HINWEISP. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZSD_05_HINWEISP.
* Table for entries selected to show on screen
DATA: BEGIN OF ZSD_05_HINWEISP_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_HINWEISP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_HINWEISP_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZSD_05_HINWEISP_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_HINWEISP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_HINWEISP_TOTAL.

*...processing: ZSD_05_LULU_HD0P................................*
TABLES: ZSD_05_LULU_HD0P, *ZSD_05_LULU_HD0P. "view work areas
CONTROLS: TCTRL_ZSD_05_LULU_HD0P
TYPE TABLEVIEW USING SCREEN '0004'.
DATA: BEGIN OF STATUS_ZSD_05_LULU_HD0P. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZSD_05_LULU_HD0P.
* Table for entries selected to show on screen
DATA: BEGIN OF ZSD_05_LULU_HD0P_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_LULU_HD0P.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_LULU_HD0P_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZSD_05_LULU_HD0P_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_LULU_HD0P.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_LULU_HD0P_TOTAL.

*...processing: ZSD_05_LULU_HEAP................................*
TABLES: ZSD_05_LULU_HEAP, *ZSD_05_LULU_HEAP. "view work areas
CONTROLS: TCTRL_ZSD_05_LULU_HEAP
TYPE TABLEVIEW USING SCREEN '0002'.
DATA: BEGIN OF STATUS_ZSD_05_LULU_HEAP. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZSD_05_LULU_HEAP.
* Table for entries selected to show on screen
DATA: BEGIN OF ZSD_05_LULU_HEAP_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_LULU_HEAP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_LULU_HEAP_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZSD_05_LULU_HEAP_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_LULU_HEAP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_LULU_HEAP_TOTAL.

*...processing: ZSD_05_LULU_HEKP................................*
TABLES: ZSD_05_LULU_HEKP, *ZSD_05_LULU_HEKP. "view work areas
CONTROLS: TCTRL_ZSD_05_LULU_HEKP
TYPE TABLEVIEW USING SCREEN '0003'.
DATA: BEGIN OF STATUS_ZSD_05_LULU_HEKP. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZSD_05_LULU_HEKP.
* Table for entries selected to show on screen
DATA: BEGIN OF ZSD_05_LULU_HEKP_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_LULU_HEKP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_LULU_HEKP_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZSD_05_LULU_HEKP_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_LULU_HEKP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_LULU_HEKP_TOTAL.

*...processing: ZSD_05_LULU_HLPP................................*
TABLES: ZSD_05_LULU_HLPP, *ZSD_05_LULU_HLPP. "view work areas
CONTROLS: TCTRL_ZSD_05_LULU_HLPP
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_ZSD_05_LULU_HLPP. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_ZSD_05_LULU_HLPP.
* Table for entries selected to show on screen
DATA: BEGIN OF ZSD_05_LULU_HLPP_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_LULU_HLPP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_LULU_HLPP_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF ZSD_05_LULU_HLPP_TOTAL OCCURS 0010.
INCLUDE STRUCTURE ZSD_05_LULU_HLPP.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF ZSD_05_LULU_HLPP_TOTAL.

*.........table declarations:.................................*
TABLES: ZSD_04_CHG_CUST                .
TABLES: ZSD_05_HINWEIS                 .
TABLES: ZSD_05_LULU_HD02               .
TABLES: ZSD_05_LULU_HEAD               .
TABLES: ZSD_05_LULU_HEAK               .
TABLES: ZSD_05_LULU_HELP               .