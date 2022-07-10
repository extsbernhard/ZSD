*&---------------------------------------------------------------------*
*& Include ZSD_05_LULU_RUECKZ_TOP       Report ZSD_05_LULU_RUECKZ_REP01
*&
*&---------------------------------------------------------------------*

REPORT ZSD_05_LULU_RUECKZ_REP01.

* Allg. Info für den weniger gut Informierten ...
* Es handelt sich um die Rückerstattung von Kehrichtgrundgebühren
* Gesuche sind für den Abrechnungszeitraum 2007-2010 (Antrag manuell)
* Fälle betreffeb deb Abrechnungszeitraum 2011-2012 (alle Betroffenen)

Tables: ZSD_05_Lulu_head               "Kopftabelle zu den Gesuchen
      , zsd_05_lulu_fakt               "zugeordnete Fakturen zu Gesuchen
      , zsd_05_lulu_hd02               "Kopftabelle zu den Fällen
      , zsd_05_lulu_fk02               "zugeordnete Fakturen zu Fällen
      , bkpf                           "Fi-Beleg-Kopfdatei
      , bsak                           "FI-kreditoren-ausgeglichen
      , bseg                           "Fi-Beleg-Buchungszeilen
      , bsec                           "Fi-Beleg-CPD-Adressdaten
      , ZSD_05_OBJEKT                  "Objekt-Daten
      , zsd_05_kehr_aufz               "Tabelle mit Faktura u. Zinsdaten
      .
*------ working data-tabs and fields ----------------------------------
data:   t_fakt            type table of zsd_05_lulu_fakt
    ,   s_fakt            like line of t_fakt
    ,   t_aufz            type table of zsd_05_kehr_aufz
    ,   s_aufz            like line of t_aufz
    ,   t_outlist         type table of ZSD_05_LULU_ZINSLIST
    ,   s_outlist         like line of t_outlist
    ,   t_worktab         type table of zsd_05_lulu_rueckz_in
    ,   s_worktab         like line of t_worktab
    ,   t_worktdet        type table of zsd_05_lulu_rueckz_in2
*                          initial size 1000000
    ,   s_worktdet        like line of t_worktdet
    ,   t_worktdfi        type table of zsd_05_lulu_rueckz_in2
*                          initial size 1000000
    ,   s_worktdfi        like line of t_worktdfi
    ,   begin of t_bkpf     occurs 0
    ,    belnr            type belnr_d
    ,    bukrs            type bukrs
    ,    budat            type budat
    ,    cpudt            type cpudt                      "Epo20140917
    ,    gjahr            type gjahr
    ,    blart            type blart
    ,    stblg            type stblg
    ,    xblnr            type xblnr
    ,   end   of t_bkpf
    ,   s_bkpf            like line of t_bkpf
    ,   begin of t_bsak     occurs 0
    ,    belnr            type belnr_d
    ,    bukrs            type bukrs
    ,    budat            type budat
    ,    cpudt            type cpudt                      "Epo20140917
    ,    gjahr            type gjahr
    ,    blart            type blart
    ,    AUGDT            type augdt
    ,    AUGBL            type augbl
    ,    dmbtr            type dmbtr
    ,    zuonr            type dzuonr
    ,    lifnr            type lifnr
    ,    xblnr            type xblnr
    ,   end   of t_bsak
    ,   s_bsak            like line of t_bsak
    ,   begin of t_bsik     occurs 0
    ,    belnr            type belnr_d
    ,    bukrs            type bukrs
    ,    budat            type budat
    ,    cpudt            type cpudt                      "Epo20140917
    ,    gjahr            type gjahr
    ,    blart            type blart
    ,    AUGDT            type augdt
    ,    AUGBL            type augbl
    ,    dmbtr            type dmbtr
    ,    zuonr            type dzuonr
    ,    lifnr            type lifnr
    ,    xblnr            type xblnr
    ,   end   of t_bsik
    ,   s_bsik            like line of t_bsik
    ,   begin of t_worktfak occurs 0
    ,    fallnr           type ZSDEKPFALLNR
    ,    vbeln            type vbeln_vf
    ,    obj_key          type ZZ_OBJ_KEY
    ,   end   of t_worktfak
    ,   s_worktfak        like line of t_worktfak
*    ,   t_bseg            type table of bseg
    ,   begin of t_bseg     occurs 0
    ,    belnr            type belnr_d
    ,    bukrs            type bukrs
    ,    gjahr            type gjahr
    ,    buzei            type buzei
    ,    bschl            type bschl
    ,    koart            type koart
    ,    dmbtr            type dmbtr
    ,    sgtxt            type sgtxt
    ,    saknr            type saknr
    ,    hkont            type hkont
    ,    mwskz            type mwskz
    ,   end   of t_bseg
,   s_bseg            like line of t_bseg
    ,   w_lines           type i
    ,   w_bkpf_lines      type i
    ,   w_bsak_lines      type i
    ,   w_bsik_lines      type i
    ,   w_alv_struc       type TABNAME
                          value 'ZSD_05_LULU_RUECKZ_OUT_SUM'
    ,   t_sumlist         type table of zsd_05_lulu_rueckz_out_sum
    ,   s_sumlist         like line of t_sumlist
    ,   w_alv_struc2      type TABNAME
                          value 'ZSD_05_LULU_RUECKZ_OUT_DET'
    ,   t_detlist         type table of zsd_05_lulu_rueckz_out_det
    ,   s_detlist         like line of t_detlist
    ,   w_kz_ge_fa        type char1    "F=Fall, G=Gesuch
    ,   w_list_kz         type char1    "S=Summenliste, D=Detailliste
    ,   w_alv_variant     type disvariant                 "Epo20141015
    ,   w_alv_layout      type SLIS_LAYOUT_ALV            "Epo20141015
    .
*------ constants -----------------------------------------------------
Data:   c_activ              type c value 'X'
    ,   c_inactiv            type c value ' '
    ,   c_leer               type c value ' '
    ,   c_kz_S               type c value 'S'
    ,   c_kz_D               type c value 'D'
    ,   c_initial            type dats value '00000000'
    ,   c_2000               type dats value '20000101'
    ,   c_4zero(4)           type c value '0000'
    ,   c_fall_head(16)      type c value 'ZSD_05_LULU_HD02'
    ,   c_fall_fakt(16)      type c value 'ZSD_05_LULU_FK02'
    ,   c_gesu_head(16)      type c value 'ZSD_05_LULU_HEAD'
    ,   c_gesu_fakt(16)      type c value 'ZSD_05_LULU_FAKT'
    ,   c_bezahlt            type zz_kennz value 'B'
    ,   c_kz_fall            type c value 'F'
    ,   c_f_pstart(10)       type c value '01.01.2011'
    ,   c_f_pende(10)        type c value '31.12.2012'
    ,   c_kz_gesuch          type c value 'G'
    ,   c_g_pstart(10)       type c value '01.05.2007'
    ,   c_g_pende(10)        type c value '31.12.2010'
    ,   c_info               type c value 'I'
    ,   c_error              type c value 'E'
    ,   c_abort              type c value 'A'
    ,   c_warning            type c value 'W'
    ,   c_check_dat          type fkdat    value '20101231'
    ,   c_bukrs_erb          type bukrs    value '2870'
    ,   c_blart_KR           type blart    value 'KR'
    ,   c_bschl_40           type bschl    value '40'
    ,   c_rueckzahlkto       type saknr    value '0020050876'
    ,   c_vorsteuerkto       type saknr    value '0010192001'
    ,   c_kredsteuerkto      type saknr    value '0020022000'
    ,   c_rueckzahlkto13     type saknr    value '0002006876'
    ,   c_vorsteuerkto13     type saknr    value '0001019001'
    ,   c_kredsteuerkto13    type saknr    value '0002000040'
    ,   c_alv_save           type c        value 'A'      "Epo20141015
    .

Data:   g_lauf_datum         type zz_laufdat
    ,   g_lauf_zeit          type zz_lauftim
    .
*======================================================================*
*INITIALIZATION.
load-OF-PROGRAM.
*======================================================================*
* i_vfdat = sy-datum + 2.
* i_rkdat = i_vfdat + 40.

*======================================================================*
SELECTION-SCREEN: BEGIN OF BLOCK bl1 WITH FRAME TITLE text-001.
 PARAMETERS:    p_fall        radiobutton group base
           ,    p_gesuch      radiobutton group base
           .
 Select-Options: s_aszdt    for zsd_05_lulu_head-aszdt." obligatory.
 Select-Options: s_aszd1    for zsd_05_lulu_hd02-aszdt no-DISPLAY.
 Select-Options: s_vfgdt    for zsd_05_lulu_head-vfgdt.
 Select-Options: s_vfgd1    for zsd_05_lulu_hd02-vfgdt no-DISPLAY.
 Select-Options: s_rkrdt    for zsd_05_lulu_head-rkrdt.
 Select-Options: s_rkrd1    for zsd_05_lulu_hd02-rkrdt no-DISPLAY.
 Select-Options: s_xblnr    for bsak-xblnr             no-display.
SELECTION-SCREEN: end   of Block bl1.
*======================================================================*
SELECTION-SCREEN: BEGIN OF BLOCK bl2 WITH FRAME TITLE text-002.
 SELECT-OPTIONS: s_objkey     for zsd_05_kehr_aufz-obj_key "no-DISPLAY
               .
 Parameters:    p_fibel     RADIOBUTTON GROUP strg default 'X'.
 Parameters:    p_ausgl     RADIOBUTTON GROUP strg.
 Parameters:    p_nofib     RADIOBUTTON GROUP strg.       "Epo20141015
 Parameters:    p_novfg     RADIOBUTTON GROUP strg.       "Epo20141015
 Parameters:    p_lifnr     type lifnr default '0000000871' NO-DISPLAY.
* selection-screen: skip 1.
* selection-screen: uline .
SELECTION-SCREEN: end   of Block bl2.
SELECTION-SCREEN: BEGIN OF BLOCK bl3 WITH FRAME TITLE text-003.
 Parameters:    p_summen    radiobutton group lis1
           ,    p_detail    radiobutton group lis1
           .
 parameters:    p_vari      type slis_vari
          .
SELECTION-SCREEN: end   of Block bl3.
*======================================================================*
*SELECTION-SCREEN: BEGIN OF BLOCK bl4 WITH FRAME TITLE text-004.
* Select-Options: s_agsp       for zsd_05_lulu_hd02-angaben_sperre_x.
*SELECTION-SCREEN: end   of Block bl4.
*======================================================================*
SELECTION-SCREEN: BEGIN OF BLOCK bl5 WITH FRAME TITLE text-005.
 parameters:    p_t_rows      type i default 100.
SELECTION-SCREEN: end   of Block bl5.
*======================================================================*
