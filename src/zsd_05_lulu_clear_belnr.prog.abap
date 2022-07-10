*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_CLEAR_VFGDT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZSD_05_LULU_CLEAR_BELNR.
*
Tables: zsd_05_lulu_head              "Kopfdaten Gesuche 2007-2010
      , zsd_05_lulu_hd02              "Kopfdaten Fälle   2011-2012
      , zsd_05_lulu_fakt              "Fakturadaten zu Gesuche
      , zsd_05_lulu_fk02              "Fakturadaten zu Fälle
      .
Data: w_Lulu_head          type tabnam
    , w_LuLu_fakt          type tabnam
    , w_lines              type i               "Anzahl TabellenEinträge
    , t_head               type table of zsd_05_lulu_head
                           with header line
    , t_hd02               type table of zsd_05_lulu_hd02
                           with header line
    , t_fakt               type table of zsd_05_lulu_fakt
                           with header line
    , t_fk02               type table of zsd_05_lulu_fk02
                           with header line
    .
Data: c_activ              type c value 'X'
    , c_inactiv            type c value ' '
    , c_leer               type c value ' '
    , c_initial            type dats value '00000000'
    , c_4zero(4)           type c value '0000'
    , c_fall_head(16)      type c value 'ZSD_05_LULU_HD02'
    , c_fall_fakt(16)      type c value 'ZSD_05_LULU_FK02'
    , c_gesu_head(16)      type c value 'ZSD_05_LULU_HEAD'
    , c_gesu_fakt(16)      type c value 'ZSD_05_LULU_FAKT'
    , c_bezahlt            type zz_kennz value 'B'
    , c_kz_fall            type c value 'F'
    , c_kz_gesuch          type c value 'G'
    , c_info               type c value 'I'
    , c_error              type c value 'E'
    , c_abort              type c value 'A'
    , c_warning            type c value 'W'
    .

*======================================================================*
SELECTION-SCREEN: BEGIN OF BLOCK bl1 WITH FRAME TITLE text-001.
 PARAMETERS:    p_fall        radiobutton group base
           ,    p_gesuch      radiobutton group base
           .
 SELECT-OPTIONS: s_objkey     for zsd_05_lulu_head-obj_key "no-DISPLAY
               , s_vfgdt      for zsd_05_lulu_head-vfgdt
               .
SELECTION-SCREEN: end   of Block bl1.
*======================================================================*
start-of-selection.
 if p_fall eq c_activ.
    w_lulu_head = c_fall_head.
    w_lulu_fakt = c_fall_fakt.
 elseif p_gesuch eq c_activ.
    w_lulu_head = c_gesu_head.
    w_lulu_fakt = c_gesu_fakt.
 endif.
 move 'NE'    to s_vfgdt-option.        "EQ=ist gleich
 move 'I'     to s_vfgdt-sign.
 clear           s_vfgdt-low.
 clear           s_vfgdt-high.
 append s_vfgdt.
 move 'GT'         to s_vfgdt-option.   "GT=Grösser
 move 'I'          to s_vfgdt-sign.
 move '20000101'   to s_vfgdt-low.
 clear                s_vfgdt-high.
 append s_vfgdt.

 if w_lulu_head eq c_fall_head.
*   Fälle 2011+2012
*    select * from (w_lulu_fakt) into table t_fk02
*             where kennz eq c_bezahlt.
    select * from (w_lulu_head) into table t_hd02
*             for all entries in t_fk02
*             where fallnr  eq t_fk02-fallnr
             Where   vfgdt   in s_vfgdt
             and     obj_key in s_objkey.
    loop at t_hd02.
     clear t_hd02-vfgdt. "löschen Verfügungsdatum
     clear t_hd02-rkrdt. "löschen Rechtkraftsdatum
     modify t_hd02.
    endloop.
    modify zsd_05_lulu_hd02 from table t_hd02.
    commit work.
    describe table t_hd02 lines w_lines.
 elseif w_lulu_head eq c_gesu_head.
*    select * from (w_lulu_fakt) into table t_fakt
*             where kennz eq c_bezahlt.
    select * from (w_lulu_head) into table t_head
*             for all entries in t_fakt
*             where fallnr  eq t_fakt-fallnr
             where vfgdt   in s_vfgdt
             and   obj_key in s_objkey.
    loop at t_head.
     clear t_head-vfgdt. "löschen Verfügungsdatum
*     clear t_head-rkrdt. "löschen Rechtkraftsdatum
     modify t_head.
    endloop.
    modify zsd_05_lulu_head from table t_head.
    commit work.
    describe table t_head lines w_lines.
 endif.
 uline.
 skip 2.
 write: / text-001
      ,   w_lines
      ,   text-002
      .
 skip 2.
 write: / sy-sysid
      ,   sy-datum
      ,   sy-uzeit
      .
 uline.
