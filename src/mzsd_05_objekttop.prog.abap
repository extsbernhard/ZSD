*&---------------------------------------------------------------------*
*& Include MZSD_05_PARZELLETOP                                         *
*&                                                                     *
*&---------------------------------------------------------------------*

PROGRAM  sapmzsd_05_parzelle MESSAGE-ID zsd_04.

TABLES: anla,                          "Anlagenstammsatz-Segment
        bkpf,                          "Belegkopf für Buchhaltung
        bsad,
        bseg,                          "Belegsegment Buchhaltung
        bsid,
        kna1,                          "Kundenstamm (allgemeiner Teil)
        knvv,                          "Kundenstamm Vertriebsdaten
        konh,                          "Konditionen (Kopf)
        konp,                          "Konditionen (Position)
        makt,                          "Materialkurztexte
        tvkbz, "Org.-Einheit: Verkaufsbüros: Zuordnung zu Org.-Einheiten
        tvko,                      "Org.-Einheit: Verkaufsorganisationen
        zsd_04_boden,      "Gebühren: Bewirtschaftung öffentlicher Boden
        zsd_04_kanal,                  "Gebühren: Kanalisationsanschluss
        zsd_04_kehricht,               "Gebühren: Kehrichtgrundgebühr
        zsd_04_kehr_mat,   "Gebühren: Materialen für Kehrichtgrundgebühr
        zsd_04_regen,            "Gebühren: Regenabwasser-Parzellen-Info
        zsd_04_regeninfo,     "Gebühren: Regenabwasser-Verrechnungs-Info
        zsd_05_kehr_auft,        "Gebühren: Kehrichtgrundgebühr Aufträge
        zsd_05_objekt.                 "Liegenschaftsobjekte

* Typen
TYPES: BEGIN OF tab_excl,
         fcode LIKE rsmpe-func,
       END OF tab_excl.
* Ranges
RANGES: r_stadtteil FOR zsd_05_objekt-stadtteil,
        r_parzelle  FOR zsd_05_objekt-parzelle.
* Interne Tabelle & Work-Area
DATA: BEGIN OF t_object OCCURS 0.
        INCLUDE STRUCTURE zsd_05_objekt.
DATA:   bb(2) TYPE c,
        ka(2) TYPE c,
        kg(2) TYPE c,
        ra(2) TYPE c,
        flag TYPE c,
      END   OF t_object.

DATA: anz_tage        TYPE anz_tage. "zsd_05_kehr_ruec-tage.
DATA: anz_tage_jahr   TYPE anz_tage. "zsd_05_kehr_ruec-tage.
DATA: anz_monate      TYPE zsd_05_kehr_ruec-monate.
DATA: sw_fehler(2)    TYPE n.
DATA: save_ucomm      TYPE sy-ucomm.
DATA: save_ucomm2     TYPE sy-ucomm.
DATA: save_dat_von LIKE zsd_05_kehr_ruec-von_datum.
DATA: save_dat_bis LIKE zsd_05_kehr_ruec-von_datum.

DATA: t_zsd_05_objekt TYPE zsd_05_objekt OCCURS 0.
DATA: t_object_wa TYPE zsd_05_objekt.
DATA: t_excl_tab TYPE STANDARD TABLE OF tab_excl
          WITH NON-UNIQUE DEFAULT KEY
          INITIAL SIZE 10,
      w_excl_tab TYPE tab_excl.
* Hilfsfelder
DATA: w_ucomm         TYPE sy-ucomm, "OK-Code
      w_kna1e         TYPE kna1,     "Kundenstammstruktur für Eigentümer
      w_kna1g         TYPE kna1,
      w_kna1k         TYPE kna1,
      w_kna1b         TYPE kna1,
      w_kna1r         TYPE kna1,
      w_answer,
      w_actvt         TYPE activ_auth,
      w_mattext1      TYPE makt-maktx,
      w_mattext2      TYPE makt-maktx,
      w_mattext3      TYPE makt-maktx,
      w_mattext4      TYPE makt-maktx,
      w_mattext5      TYPE makt-maktx,
      w_mattext6      TYPE makt-maktx,
      w_flaeche       TYPE zz_parz_flaeche1,
      w_flaechev      TYPE zz_parz_flaeche1,
      w_betrag        TYPE kbetr_kond,
      w_betrag1       TYPE kbetr_kond,
      w_betrag2       TYPE kbetr_kond,
      w_betrag3       TYPE kbetr_kond,
      w_betrag4       TYPE kbetr_kond,
      w_betrag5       TYPE kbetr_kond,
      w_lines         TYPE i,
      w_parzelle(8)   TYPE c,
      w_stadt_parz(5) TYPE n,
      w_textline1(60) TYPE c,
      w_textline2(60) TYPE c.
* Schalter
DATA: s_1000,
      s_anle,
      s_aend,
      s_anze,
      s_insr,
      s_delete,
      s_gebuehren,
      s_enqueue.
* Declaration of tablecontrol 'TC_OBJECT' itself
CONTROLS: tc_object TYPE TABLEVIEW USING SCREEN 1000.

* Internal table for tablecontrol 'TC_OBJECT'
DATA: g_tc_object_lines  LIKE sy-loopc.
DATA: g_tc_object_wa      TYPE zsd_05_objekt,    "work area
      g_tc_object-cols_wa TYPE cxtab_column,
      g_tc_regeninfo-cols_wa TYPE cxtab_column,
      g_tc_object_copied.             "copy flag
*
DATA: t_addr1_dia  TYPE addr1_dia  OCCURS 0 WITH HEADER LINE,
      t_addr1_data TYPE addr1_data OCCURS 0 WITH HEADER LINE.
* FUNCTION CODES FOR TABSTRIP 'TS_GEBUEHREN'
CONSTANTS: BEGIN OF c_ts_gebuehren,
             tab1 LIKE sy-ucomm VALUE 'TS_GEBUEHREN_FC1',
             tab2 LIKE sy-ucomm VALUE 'TS_GEBUEHREN_FC2',
             tab3 LIKE sy-ucomm VALUE 'TS_GEBUEHREN_FC3',
             tab4 LIKE sy-ucomm VALUE 'TS_GEBUEHREN_FC4',
           END OF c_ts_gebuehren.
* DATA FOR TABSTRIP 'TS_GEBUEHREN'
CONTROLS:  ts_gebuehren TYPE TABSTRIP.
DATA:      BEGIN OF g_ts_gebuehren,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE 'SAPMZSD_05_OBJEKT',
             pressed_tab LIKE sy-ucomm VALUE c_ts_gebuehren-tab1,
           END OF g_ts_gebuehren.
* FUNCTION CODES FOR TABSTRIP 'TS_OBJEKT'
CONSTANTS: BEGIN OF c_ts_objekt,
             tab1 LIKE sy-ucomm VALUE 'TS_OBJEKT_FC1',
             tab2 LIKE sy-ucomm VALUE 'TS_OBJEKT_FC2',
             tab3 LIKE sy-ucomm VALUE 'TS_OBJEKT_FC3',
           END OF c_ts_objekt.
* DATA FOR TABSTRIP 'TS_OBJEKT'
CONTROLS:  ts_objekt TYPE TABSTRIP.
DATA:      BEGIN OF g_ts_objekt,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE 'SAPMZSD_05_OBJEKT',
             pressed_tab LIKE sy-ucomm VALUE c_ts_objekt-tab1,
           END OF g_ts_objekt.
TYPES: BEGIN OF t_tc_regeninfo,
         strasse       LIKE zsd_04_regeninfo-strasse,
         hausnummer    LIKE zsd_04_regeninfo-hausnummer,
         klasse        LIKE zsd_04_regeninfo-klasse,
         parz_flaeche1 LIKE zsd_04_regeninfo-parz_flaeche1,
         parz_flaeche2 LIKE zsd_04_regeninfo-parz_flaeche2,
         parz_flaeche3 LIKE zsd_04_regeninfo-parz_flaeche3,
         reduktion     LIKE zsd_04_regeninfo-reduktion,
         hinw_code_pl  LIKE zsd_04_regeninfo-hinw_code_pl,
         hinw_code_ve  LIKE zsd_04_regeninfo-hinw_code_ve,
         hinw_code_da  LIKE zsd_04_regeninfo-hinw_code_da,
         hinw_code_be  LIKE zsd_04_regeninfo-hinw_code_be,
         hinw_code_ei  LIKE zsd_04_regeninfo-hinw_code_ei,
         hinw_code_zu  LIKE zsd_04_regeninfo-hinw_code_zu,
         hinweis1      LIKE zsd_04_regeninfo-hinweis1,
         hintext1      LIKE zsd_04_regeninfo-hintext1,
         hinweis2      LIKE zsd_04_regeninfo-hinweis2,
         hintext2      LIKE zsd_04_regeninfo-hintext2,
         hinweis3      LIKE zsd_04_regeninfo-hinweis3,
         hintext3      LIKE zsd_04_regeninfo-hintext3,
         hinweis4      LIKE zsd_04_regeninfo-hinweis4,
         hintext4      LIKE zsd_04_regeninfo-hintext4,
         hinweis5      LIKE zsd_04_regeninfo-hinweis5,
         hintext5      LIKE zsd_04_regeninfo-hintext5,
         hinweis6      LIKE zsd_04_regeninfo-hinweis6,
         hintext6      LIKE zsd_04_regeninfo-hintext6,
         hinweis7      LIKE zsd_04_regeninfo-hinweis7,
         hintext7      LIKE zsd_04_regeninfo-hintext7,
         hinweis8      LIKE zsd_04_regeninfo-hinweis8,
         hintext8      LIKE zsd_04_regeninfo-hintext8,
         hinweis9      LIKE zsd_04_regeninfo-hinweis9,
         hintext9      LIKE zsd_04_regeninfo-hintext9,
         hinweis0      LIKE zsd_04_regeninfo-hinweis0,
         hintext0      LIKE zsd_04_regeninfo-hintext0,
         flag,       "flag for mark column
       END OF t_tc_regeninfo.
DATA:     g_tc_regeninfo_itab   TYPE t_tc_regeninfo OCCURS 0,
          g_tc_regeninfo_wa     TYPE t_tc_regeninfo. "work area
DATA:     g_tc_regeninfo_copied.           "copy flag
CONTROLS: tc_regeninfo TYPE TABLEVIEW USING SCREEN 2003.
DATA:     g_tc_regeninfo_lines  LIKE sy-loopc.
DATA:     ok_code LIKE sy-ucomm.
DATA: t_kehrauft TYPE zsd_05_kehr_auft OCCURS 0.
DATA: w_kehrauft TYPE zsd_05_kehr_auft.


DATA: w_zsd_04_kehricht TYPE zsd_04_kehricht.
DATA: t_chg_prot TYPE TABLE OF zsd_04_chg_prot.
DATA: w_zsd_04_chg_prot LIKE LINE OF t_chg_prot.
DATA: t_chg_cust TYPE TABLE OF zsd_04_chg_cust.
DATA: w_chg_cust LIKE LINE OF t_chg_cust.

DATA: t_vbfa TYPE vbfa OCCURS 0.
DATA: t_bseg TYPE bseg OCCURS 0.
DATA: t_bsid TYPE bsid OCCURS 0.
DATA: t_bsad TYPE bsad OCCURS 0.

*&spwizard: declaration of tablecontrol 'TC_KEHRAUFT' itself
CONTROLS: tc_kehrauft TYPE TABLEVIEW USING SCREEN 2002.

***&SPWIZARD: DATA DECLARATION FOR TABLECONTROL 'RUECKERSTATTUNG'
*&SPWIZARD: DEFINITION OF DDIC-TABLE
TABLES:   zsd_05_kehr_ruec.

*&SPWIZARD: TYPE FOR THE DATA OF TABLECONTROL 'RUECKERSTATTUNG'
TYPES: BEGIN OF t_rueckerstattung,
         jahr           LIKE zsd_05_kehr_ruec-jahr,
         datum_eingang  LIKE zsd_05_kehr_ruec-datum_eingang,
         von_datum      LIKE zsd_05_kehr_ruec-von_datum,
         bis_datum      LIKE zsd_05_kehr_ruec-bis_datum,
         tage           LIKE zsd_05_kehr_ruec-tage,
         dauer_monate   LIKE zsd_05_kehr_ruec-monate,
         total_qm       LIKE zsd_05_kehr_ruec-total_qm,
         leerstand_qm   LIKE zsd_05_kehr_ruec-leerstand_qm,
         verrbetr       LIKE zsd_05_kehr_ruec-verrbetr,
         rueckbetr      LIKE zsd_05_kehr_ruec-rueckbetr,
         datum_brief    LIKE zsd_05_kehr_ruec-datum_brief,
         bearbeitet_von LIKE zsd_05_kehr_ruec-bearbeitet_von,
         bearbeitet_am  LIKE zsd_05_kehr_ruec-bearbeitet_am,
         flag           LIKE zsd_05_kehr_ruec-flag,
       END OF t_rueckerstattung.

*&SPWIZARD: INTERNAL TABLE FOR TABLECONTROL 'RUECKERSTATTUNG'
DATA:     g_rueckerstattung_itab   TYPE t_rueckerstattung OCCURS 0,
          g_rueckerstattung_wa     TYPE t_rueckerstattung. "work area
DATA:     g_rueckerstattung_copied.           "copy flag

*&SPWIZARD: DECLARATION OF TABLECONTROL 'RUECKERSTATTUNG' ITSELF
CONTROLS: rueckerstattung TYPE TABLEVIEW USING SCREEN 2002.

*&SPWIZARD: LINES OF TABLECONTROL 'RUECKERSTATTUNG'
DATA:     g_rueckerstattung_lines  LIKE sy-loopc.


DATA: gs_kna1 TYPE kna1, "Debitor generell
      gs_adrs_print TYPE adrs_print.

CONSTANTS: c_insert TYPE c VALUE 'I',
           c_update TYPE c VALUE 'U',
           c_modify TYPE c VALUE 'M',
           c_delete TYPE c VALUE 'D',

           c_enqmode TYPE enqmode VALUE 'E', "Sperrmodus

           c_kgd TYPE ktokd VALUE 'ZG00', "Kontengruppe Debitor

           c_nk_obj TYPE nrobj VALUE 'ZKGG', "Nummernkreisobjekt
           c_nk_nrr TYPE nrnr  VALUE '01'.   "Nummernkreisnummer


DATA: gs_et_addr_print TYPE adrs_print,
      gs_vt_addr_print TYPE adrs_print,
      gs_re_addr_print TYPE adrs_print,
      gv_eigen_ver_val TYPE dd07t-ddtext,
      gv_anschr_art_val TYPE dd07t-ddtext,
      gv_rueckerst_art_val TYPE dd07t-ddtext,
      gv_nutz_art_val TYPE dd07t-ddtext.

"Buttons für dynamische Textsteuerung
DATA: btn_eig_mod TYPE string,
      btn_ver_mod TYPE string,
      btn_rem_mod TYPE string,
      btn_trans_rg_eig TYPE string,
      btn_trans_rg_ver TYPE string.
