*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_ANALYSE_D01
*&---------------------------------------------------------------------*

*--------Tabellendefinitionen -(tables)--------------------------------*
TABLES: zsd_05_kehr_auft, zsd_05_objekt, zsd_05_lulu_head.
*--------C - Counter---------------------------------------------------*
*--------R - Ranges----------------------------------------------------*
*--------S - Schalter--------------------------------------------------*¨
*--------T - interne Tabellen------------------------------------------*
DATA: lt_kehr_auft TYPE TABLE OF zsd_05_kehr_auft.
DATA: lt_zsd_04_kehricht TYPE TABLE OF zsd_04_kehricht.

DATA: lt_lulu_head TYPE TABLE OF zsd_05_lulu_head.
DATA: lt_lulu_hd02 TYPE TABLE OF zsd_05_lulu_hd02.
DATA: lt_kehr_auft_h TYPE TABLE OF zsd_05_kehr_auft.
DATA: lt_objekt TYPE TABLE OF zsd_05_objekt.
*--------V - Value-Felder----------------------------------------------*

*--------W - Work-Felder (Hilfsfelder)---------------------------------*

*--------W - Work-Strukturen-------------------------------------------*
DATA: ls_kehr_auft LIKE LINE OF lt_kehr_auft.
DATA: ls_zsd_04_kehricht LIKE LINE OF lt_zsd_04_kehricht.
DATA: ls_objekt LIKE LINE OF lt_objekt.
DATA: ls_lulu_head TYPE  zsd_05_lulu_head.
DATA: ls_lulu_hd02 TYPE   zsd_05_lulu_hd02.
*--------CON - Konstanten ---------------------------------------------*

*--------Feld-Symbole--------------------------------------------------*

*--------Makros--------------------------------------------------------*
*--------Obj - Objekte-------------------------------------------------*
DATA: obj_kehr_auft_alv TYPE REF TO cl_salv_table.          "#EC NEEDED

*----------------------------------------------------------------------*
