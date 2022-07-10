*&---------------------------------------------------------------------*
*& Include MZSD_05_KONTRAKTTOP                                         *
*&                                                                     *
*&---------------------------------------------------------------------*

PROGRAM  sapmzsd_05_kontrakt MESSAGE-ID zsd_04.

*_____Tables____________________________________________________________

TABLES: zsd_05_kontrakt,  "Kontrakte
        zsd_05_kontrzord, "Kontraktzuordnung
        zsd_05_kontrpos,  "Kontraktposition
        zsd_05_kontrupos, "Kontraktunterposition
        zsd_05_kontridx,  "Kontrakt-Nummernkreise
        zsd_05_kontrverr, "Kontrakt-Verrechnung
        zsd_05_index,     "SAPTAB: Index-Tabelle für Kontraktverwaltung
        kna1,             "Kundenstamm (allgemeiner Teil)
        lfa1,             "Lieferantenstamm (allgemeiner Teil)
        a004,             "Material (Pool-Tabelle)
        konp,             "Konditionen (Position)
        mara,             "Materialstamm
        makt,             "Materialkurztexte
        adrc,             "Adressen (zentrale Adreßverwaltung)
        tvko.             "Org.-Einheit: Verkaufsorganisationen





*_____Typen_____________________________________________________________
TYPES: BEGIN OF tab_excl,
         fcode LIKE rsmpe-func,
       END OF tab_excl.





*_____Ranges____________________________________________________________





*_____Interne Tabelle & Workareas_______________________________________

DATA: it_kontrakt  TYPE zsd_05_kontrakt  OCCURS 0,
      it_adrc      TYPE adrc             OCCURS 0,
      it_kna1      TYPE kna1             OCCURS 0,
      it_lfa1      TYPE lfa1             OCCURS 0,
      it_makt      TYPE makt             OCCURS 0.

DATA: wa_kontrakt  TYPE zsd_05_kontrakt,
      wa_adrc      TYPE adrc,
      wa_kna1      TYPE kna1,
      wa_lfa1      TYPE lfa1,
      wa_makt      TYPE makt,
      wa_a004      TYPE a004,
      wa_konp      TYPE konp.


DATA: BEGIN OF it_kontrpos OCCURS 0.
        INCLUDE STRUCTURE zsd_05_kontrpos.
DATA:   flag    TYPE c,
        action  TYPE c,
        delable TYPE c,
      END OF it_kontrpos.


DATA: BEGIN OF it_kontrupos_gesamt OCCURS 0.
        INCLUDE STRUCTURE zsd_05_kontrupos.
DATA:   flag    TYPE c,
        action  TYPE c,
        delable TYPE c,
      END OF it_kontrupos_gesamt.


DATA: BEGIN OF it_kontrupos OCCURS 0.
        INCLUDE STRUCTURE  zsd_05_kontrupos.
DATA:   flag    TYPE c,
        action  TYPE c,
        delable TYPE c,
      END OF it_kontrupos.


DATA: BEGIN OF it_kontrzord OCCURS 0.
        INCLUDE STRUCTURE zsd_05_kontrzord.
DATA:   flag   TYPE c,
        action TYPE c,
      END OF it_kontrzord.


DATA: wa_kontrpos         LIKE it_kontrpos,
      wa_kontrupos_gesamt LIKE it_kontrupos_gesamt,
      wa_kontrupos        LIKE it_kontrupos,
      wa_kontrzord        LIKE it_kontrzord.


DATA: BEGIN OF it_kontrnehm OCCURS 0,
        kontrnehmnr TYPE zz_kontrnehmernr,
        adrnr       TYPE adrnr,
        name1       TYPE name1_gp,
        name2       TYPE name2_gp,
        stras       TYPE stras_gp,
        land1       TYPE land1_gp,
        pstlz       TYPE pstlz,
        ort01       TYPE ort01_gp,
      END OF it_kontrnehm.


DATA: wa_kontrnehm LIKE it_kontrnehm.


DATA: wa_kontridx  LIKE zsd_05_kontridx.


DATA: it_addr1_dia  TYPE addr1_dia  OCCURS 0 WITH HEADER LINE,
      it_addr1_data TYPE addr1_data OCCURS 0 WITH HEADER LINE.


DATA: it_lines TYPE tline OCCURS 0,
      wa_lines TYPE tline.


DATA: it_excl_tab TYPE STANDARD TABLE OF tab_excl
          WITH NON-UNIQUE DEFAULT KEY
          INITIAL SIZE 10,
      wa_excl_tab TYPE tab_excl.


DATA: it_d023s_s TYPE d023s_s OCCURS 0.


DATA: ls_cp_objekt TYPE zsd_05_objekt.



*_____Hilfsfelder_______________________________________________________

DATA: ok_code           LIKE sy-ucomm,
      w_subrc           LIKE sy-subrc,
      w_tabix           like sy-tabix,

      w_actvt           TYPE activ_auth,
      w_actdel          type activ_auth,
      w_obj             TYPE string,

      w_textinfo(70)    TYPE c,
      w_textinfok(70)   TYPE c,
      w_textinfop(70)   TYPE c,
      w_textline1(60)   TYPE c,
      w_textline2(60)   TYPE c,
      w_title(60)       type c,
      w_answer                ,
      w_kontrakt(11)    TYPE c,
      w_bezeichn        TYPE bez40,
      w_kontrnehmart    TYPE text10,
      w_returncode      TYPE i,

      w_dateilink(95)   TYPE c,

      w_kontrnr         TYPE zsd_05_kontrakt-kontrnr,

      w_zuordknr1       TYPE zsd_05_kontrzord-zuordknr,
      w_zuordknr2       TYPE zsd_05_kontrzord-zuordknr,
      w_zuordknr3       TYPE zsd_05_kontrzord-zuordknr,

      rb_kk1 VALUE 'X',
      rb_lk1,

      rb_pkt1, " VALUE 'X',
      rb_prz1,

      w_betr            TYPE kbetr,

      btn_adr           TYPE string,

      w_shelp           TYPE shlpname,

      w_vkorg           TYPE vkorg VALUE '1500',
      w_vtweg           TYPE vtweg VALUE '51',

      w_kschl           TYPE kschl VALUE 'PR00',

      w_header          TYPE thead,
      w_schab           LIKE ankaz-am_tdnam01,
      w_tdid            LIKE thead-tdid VALUE '0001',
      w_tdobject        LIKE thead-tdobject,
      w_tdlinesize      LIKE thead-tdlinesize VALUE '70',
      w_tdlsizechk      TYPE string,
      w_function,
      w_header_e        TYPE thead,

      w_ncode,          "Notizcode
*                        C = Anlegen, U = Ändern, R = Lesen, D = Löschen
      w_ntyp,           "Notiztyp
*                        K = Kopf, P = Position
      w_proc(3)         TYPE c,    "Process
*                        PBO=Proc. Before Output, PAI=Proc. After Input

      w_lcount          TYPE i,
      w_count           TYPE i,
      w_len             TYPE i,

      w_ofile           TYPE char200,
      w_parzei          TYPE i,
      w_parzeo          TYPE string,

      w_adrpos(56)      TYPE c.







*_____Schalter__________________________________________________________

DATA: s_anle,      w_anle,
      s_aend,      w_aend,
      s_anze,      w_anze,
      s_insr,      w_insr,
      s_insr1,     w_insr1,
      s_dele,      w_dele,
      s_btnkupupd, w_btnkupupd,
      s_delete,    w_delete,
      s_enqueue,   w_enqueue.





*_____Wizard generated__________________________________________________

*Internal table for tablecontrol 'TC_KONTRPOS'
DATA:     g_tc_kontrpos_copied.           "copy flag

*Declaration of tablecontrol 'TC_KONTRPOS' itself
CONTROLS: tc_kontrpos TYPE TABLEVIEW USING SCREEN 3000.

*Lines of tablecontrol 'TC_KONTRPOS'
DATA:     g_tc_kontrpos_lines  LIKE sy-loopc,
          g_tc_kontrpos-cols_wa TYPE cxtab_column.
*FUNCTION codes for tabstrip 'TS_KONTRAKT'
CONSTANTS: BEGIN OF c_ts_kontrakt,
            tab1 LIKE sy-ucomm VALUE 'TS_KONTRAKT_FC1',
            tab2 LIKE sy-ucomm VALUE 'TS_KONTRAKT_FC2',
            tab3 LIKE sy-ucomm VALUE 'TS_KONTRAKT_FC3',
          END OF c_ts_kontrakt.
* DATA FOR TABSTRIP 'TS_KONTRAKT'
CONTROLS:  ts_kontrakt TYPE TABSTRIP.
DATA:      BEGIN OF g_ts_kontrakt,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE 'SAPMZSD_05_KONTRAKT',
             pressed_tab LIKE sy-ucomm VALUE c_ts_kontrakt-tab2,
           END OF g_ts_kontrakt.

*Internal table for tablecontrol 'TC_KONTRZORD'
DATA:     g_tc_kontrzord_copied.           "copy flag

*Declaration of tablecontrol 'TC_KONTRZORD' itself
CONTROLS: tc_kontrzord TYPE TABLEVIEW USING SCREEN 3001.

*Lines of tablecontrol 'TC_KONTRZORD'
DATA:     g_tc_kontrzord_lines  LIKE sy-loopc.

* FUNCTION CODES FOR TABSTRIP 'TS_KONTRPOS'
CONSTANTS: BEGIN OF c_ts_kontrpos,
             tab1 LIKE sy-ucomm VALUE 'TS_KONTRPOS_FC1',
             tab2 LIKE sy-ucomm VALUE 'TS_KONTRPOS_FC2',
             tab3 LIKE sy-ucomm VALUE 'TS_KONTRPOS_FC3',
           END OF c_ts_kontrpos.
* DATA FOR TABSTRIP 'TS_KONTRPOS'
CONTROLS:  ts_kontrpos TYPE TABSTRIP.
DATA:      BEGIN OF g_ts_kontrpos,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE 'SAPMZSD_05_KONTRAKT',
             pressed_tab LIKE sy-ucomm VALUE c_ts_kontrpos-tab1,
           END OF g_ts_kontrpos.

*Internal table for tablecontrol 'TC_KONTRUPOS'
DATA:     g_tc_kontrupos_copied.           "copy flag
DATA:     g_tc_kontrupos_gesamt_copied.    "copy flag


*Declaration of tablecontrol 'TC_KONTRUPOS' itself
CONTROLS: tc_kontrupos TYPE TABLEVIEW USING SCREEN 4002.

*Lines of tablecontrol 'TC_KONTRUPOS'
DATA:     g_tc_kontrupos_lines  LIKE sy-loopc,
          g_tc_kontrupos-cols_wa TYPE cxtab_column.
