*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_FALLSTATUS_D01
*&---------------------------------------------------------------------*

*--------Tabellendefinitionen -(tables)--------------------------------*
TABLES:  zsd_04_chg_prot.
*--------C - Counter----------------akt.-----------------------------------*
*--------R - Ranges----------------------------------------------------*
*--------S - Schalter--------------------------------------------------*¨
*--------T - interne Tabellen------------------------------------------*
data: lt_chg_prot TYPE TABLE OF zsd_04_chg_prot.
DATA: lt_objekt TYPE TABLE OF zsd_05_objekt.
*--------V - Value-Felder----------------------------------------------*

*--------W - Work-Felder (Hilfsfelder)---------------------------------*
DATA: lv_answer(1) TYPE c.
DATA: lv_aenam TYPE aenam,
      lv_aedat TYPE aedat,
      lv_aezet TYPE aezet.
*--------W - Work-Strukturen-------------------------------------------*

DATA: ls_objekt LIKE LINE OF lt_objekt.
DATA: ls_lulu_head TYPE  zsd_05_lulu_head.
DATA: ls_lulu_prot TYPE zsd_05_lulu_prot.
DATA: ls_lulu_fakt TYPE  zsd_05_lulu_fakt.
DATA: ls_lulu_hd02 TYPE   zsd_05_lulu_hd02.

DATA: s_perst TYPE RANGE OF ld_perst.
DATA: s_pered TYPE RANGE OF ld_pered.
DATA: w_perst LIKE LINE OF s_perst.
DATA: w_pered LIKE LINE OF s_pered.
*--------CON - Konstanten ---------------------------------------------*

*--------Feld-Symbole--------------------------------------------------*
FIELD-SYMBOLS: <fs_lulu_head> TYPE zsd_05_lulu_head.
*--------Makros--------------------------------------------------------*
*--------Obj - Objekte-------------------------------------------------*
DATA: obj_kehr_auft_alv TYPE REF TO cl_salv_table.          "#EC NEEDED

*----------------------------------------------------------------------*
