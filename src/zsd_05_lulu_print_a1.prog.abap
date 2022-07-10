*----------------------------------------------------------------------*
* Report  ZSD_05_LULU_PRINT_A1
*
*----------------------------------------------------------------------*
*                                                                      *
*            P R O G R A M M D O K U M E N T A T I O N                 *
*                                                                      *
*----------------------------------------------------------------------*
*               W E R  +  W A N N                                      *
*--------------+-------------------------------+-----------------------*
* Entwickler   | Oliver Epking        Firma    | Alsinia GmbH          *
* Tel.Nr.      |                     Natel     | 079 620 07 88         *
* E-Mail       |                                                       *
* Erstelldatum | 27.06.2013          Fertigdat.|                       *
*--------------+-------------------------------+-----------------------*
*               F Ü R   W E N                                          *
*--------------+-------------------------------+-----------------------*
* Amt          | Stadt Bern                    |                       *
* Auftraggeber | Beat Oesch             Tel.Nr.|                       *
* E-Mail       | Beat.Oesch2@bern.ch                                   *
* Proj.Leiter  | Daniel Liener         Tel.Nr.| 031                    *
* E-Mail       | Beat.Oesch2@bern.ch                                   *
*--------------+-------------------------------+-----------------------*
*               W O                                                    *
*--------------+-------------------------------+-----------------------*
* PCM-Nr.      |                     Change-Nr.|                       *
* Proj.Name    | LULU Stadt Bern ERB Proj.Nr.  |
*
*--------------+-------------------------------+-----------------------*
*               W A S                                                  *
*--------------+-------------------------------------------------------*
* Kurz-        | Datensammler für ProForma-Verfügungen des Projekts    *
* Beschreibung | LuLu der ERB. Die Daten werden aus den Gesuchs(2007-  *
*              | 2010) und den Fällen (2011+2012) gelesen und an das   *
*              | noch zu entwickelnde SmartForms-Formular übergeben.   *
*              |                                                       *
* Funktionen   | Aufruf Smartforms-Formular ZSD_05_LULU_PROFORMA       *
*              | für Proforma-Druck                                    *
*              |                                                       *
* Input        | ZSD_05_LULU_HEAD(Gesuche) / ZSD_05_LULU_HD02(Fälle)   *
*              | ZSD_05_LULU_FAKT(Gesuche) / ZSD_05_LULU_FK02(Fälle)   *
*              | ZSD_05_KEHR_AUFZ(Faktura-Positions-Daten) zu FAKT/FK02*
*              | zsd_05_lulu_prof(Proforma-Ausdruck-Zeilen für Wieder- *
*              |                  holdruck)
* Output       | ZSD_05_LULU_PRINTLINE                                 *
*              |                                                       *
*--------------+-------------------------------------------------------*

*----------------------Aenderungsdokumentation-------------------------
* Edition  SAP-Rel.  Datum        Bearbeiter
*          Beschreibung
*----------------------------------------------------------------------*
* <001>    7.31      14.05.2014   Oliver Epking, Alsinia GmbH
*          Prüfen auf Quote ungleich 0% - 0% wird nicht mehr akzeptiert
*          -> Gesuche sind ungeprüft mit 100% Rückerstattung erstellt
*             worden, was zu Problemen geführt hat (Verfügungen)
*          -> die ursprüngliche Vereinbarung für die Masse der Eigen-
*             nutzer muss nun angepasst werden.
*          => Selektion schränkt nun auf die Quote > 50% ein
*----------------------------------------------------------------------*

*======================================================================*
 REPORT ZSD_05_LULU_PRINT_A1.
*======================================================================*

*----------------------------------------------------------------------*
Tables: zsd_05_lulu_head              "Kopfdaten Gesuche 2007-2010
      , zsd_05_lulu_hd02              "Kopfdaten Fälle   2011-2012
      , zsd_05_lulu_fakt              "Fakturadaten zu Gesuche
      , zsd_05_lulu_fk02              "Fakturadaten zu Fälle
      , zsd_05_kehr_aufz              "Fakturapositionsdaten generell
      , kna1                          "Debitoren-Allg.-Daten
      , adrc                          "Zentrale-Adressdaten
      , zsd_05_lulu_prof              "Protokolltab. für Printline
      , zsd_05_t_printl               "Testdruck-Tabelle
      .

*----------------------------------------------------------------------*
Data: t_printline          type TABLE OF zsd_05_lulu_printline
                           with HEADER LINE
    , t_print_prof         type table of zsd_05_lulu_prof
                           with HEADER LINE
    , t_head               type table of zsd_05_lulu_hd02
                           with HEADER LINE
    , t_fakt               type table of zsd_05_lulu_fk02
                           with HEADER LINE
    , t_aufz               type table of zsd_05_kehr_aufz
                           WITH HEADER LINE
    , t_zinstab            type table of zsd_05_lulu_vzi
                           with header line
    , w_printline          type zsd_05_lulu_printline
    , w_lulu_prof          type zsd_05_lulu_prof
    , w_head               type zsd_05_lulu_hd02
    , w_fakt               type zsd_05_lulu_fk02
    , w_aufz               type zsd_05_kehr_aufz
    , w_kna1               type kna1
    , w_adrc               type adrc
    , w_Lulu_head          type tabnam
    , w_LuLu_fakt          type tabnam
    , w_lines              type i               "Anzahl TabellenEinträge
    , w_total_lines        type i
    , w_objektbez          type bezei40
    , w_bemerkung          type text40
    , w_kz_gf              type ZZ_KENNZ_GE_FA
    , w_man                type c               "Kennz. manuell angep.
    , w_sfname             type TDSFNAME value 'ZSD_05_LULU_PROFORMA'
    , w_sf_fuba            type RS38L_FNAM
    , w_ge_fa              type c               "KZ F=Fall, G=Gesuch
    , w_pstart(10)         type c               "Periodenstart
    , w_pende(10)          type c               "Periodenende
    , w_sum_formular       type i               "Zäler Verfügungen gedr.
    .
*----------------------------------------------------------------------*
DATA screen_wa TYPE screen.
*----------------------------------------------------------------------*
Data: c_activ              type c value 'X'
    , c_inactiv            type c value ' '
    , c_leer               type c value ' '
    , c_initial            type dats value '00000000'
    , c_2000               type dats value '20000101'
    , c_4zero(4)           type c value '0000'
    , c_fall_head(16)      type c value 'ZSD_05_LULU_HD02'
    , c_fall_fakt(16)      type c value 'ZSD_05_LULU_FK02'
    , c_gesu_head(16)      type c value 'ZSD_05_LULU_HEAD'
    , c_gesu_fakt(16)      type c value 'ZSD_05_LULU_FAKT'
    , c_bezahlt            type zz_kennz value 'B'
    , c_kz_fall            type c value 'F'
    , c_f_pstart(10)       type c value '01.01.2011'
    , c_f_pende(10)        type c value '31.12.2012'
    , c_kz_gesuch          type c value 'G'
    , c_g_pstart(10)       type c value '01.05.2007'
    , c_g_pende(10)        type c value '31.12.2010'
    , c_info               type c value 'I'
    , c_error              type c value 'E'
    , c_abort              type c value 'A'
    , c_warning            type c value 'W'
*     GRUNDGEBÜHR WOHNUNGEN	                                    5101770
    , c_gr_wohn_alt         type matnr        value '000000000005101770'
*	    GRUNDGEBÜHR GEWERBE 0.5	                                  5101771
    , c_gr_gew0_5_alt       type matnr        value '000000000005101771'
*     GRUNDGEBÜHR GEWERBE 1.0	                                  5101772
    , c_gr_gew1_0_alt       type matnr        value '000000000005101772'
*	    GRUNDGEBÜHR GEWERBE 1.3	                                  5101773
    , c_gr_gew1_3_alt       type matnr        value '000000000005101773'
*	    GRUNDGEBÜHR GEWERBE 2.0                                   5101774
    , c_gr_gew2_0_alt       type matnr        value '000000000005101774'
*	    GRUNDGEBÜHR PAUSCHAL                                      5101775
    , c_gr_pausch_alt       type matnr        value '000000000005101775'
    .
Data: i_rkdat              type dats
    , i_vfdat              type dats
    .
*======================================================================*
*INITIALIZATION.
load-OF-PROGRAM.
*======================================================================*
 i_vfdat = sy-datum + 2.
 i_rkdat = i_vfdat + 40.

SELECTION-SCREEN: BEGIN OF BLOCK bl0 WITH FRAME TITLE text-000.
 PARAMETERS:    p_pridev  TYPE ssfcompop-tddest OBLIGATORY
                                                default 'LP54'.
 PARAMETERS:    p_prnow   TYPE ssfcompop-tdimmed.
 PARAMETERS:    p_dlog    TYPE ssfctrlop-no_dialog DEFAULT abap_true.
SELECTION-SCREEN: end   of Block bl0.
*======================================================================*
SELECTION-SCREEN: BEGIN OF BLOCK bl1 WITH FRAME TITLE text-001.
 PARAMETERS:    p_fall        radiobutton group base
           ,    p_gesuch      radiobutton group base
           ,    p_wiedhd      as checkbox default ' '
           .
 select-options: s_erdat      for zsd_05_lulu_prof-erdat no-DISPLAY
               , s_VFGDT      for zsd_05_lulu_prof-VFGDT
               .
SELECTION-SCREEN: end   of Block bl1.
*======================================================================*
SELECTION-SCREEN: BEGIN OF BLOCK bl2 WITH FRAME TITLE text-002.
 SELECT-OPTIONS: s_status     for zsd_05_lulu_head-status.
*                              OBLIGATORY
 PARAMETERS:     p_vstx        type ZZ_VORSTEUERX.
 SELECT-OPTIONS: s_objkey     for zsd_05_kehr_aufz-obj_key "no-DISPLAY
               , s_fkimg      for zsd_05_kehr_aufz-fkimg_new
                              no-DISPLAY
               , s_loevm      for zsd_05_lulu_head-loevm
                              no-EXTENSION no INTERVALS default ' '
               , s_quote      for zsd_05_lulu_head-RUECKZLG_QUOTE
                              obligatory no-extension
               .
 Select-Options: s_eigda      for zsd_05_lulu_head-eigda.
 Select-Options: s_eigdt      for zsd_05_lulu_hd02-eigda no-DISPLAY.
 PARAMETERS:     p_pausch     type c default ' ' no-display
                              " RADIOBUTTON GROUP pau
           ,     p_opausc     type c default ' ' no-display
                              " RADIOBUTTON GROUP pau
           ,     p_alles      type c default 'X' no-display
                              " RADIOBUTTON GROUP pau default 'X'
           ,     p_quotx      as checkbox default 'X' modif id qu1


           .
SELECTION-SCREEN: end   of Block bl2.
*======================================================================*
SELECTION-SCREEN: BEGIN OF BLOCK bl4 WITH FRAME TITLE text-004.
 Select-Options: s_agsp       for zsd_05_lulu_hd02-angaben_sperre_x.
SELECTION-SCREEN: end   of Block bl4.
*======================================================================*
SELECTION-SCREEN: BEGIN OF BLOCK bl5 WITH FRAME TITLE text-005.
 PARAMETERS:    p_echt        radiobutton group echt.
 Parameters:    p_vfdat       type dats default i_vfdat obligatory.
 Parameters:    p_rkday       type i default 0.
 Parameters:    p_rkdat       type dats default i_rkdat.
 parameters:    p_plfill      type char1 default 'X' no-display.
 PARAMETERS:    p_test        radiobutton group echt.
 parameters:    p_t_rows      type i default 100.
SELECTION-SCREEN: end   of Block bl5.
*======================================================================*
AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN INTO screen_wa.
   if screen_wa-name = 'S_LOEVM-LOW'.
      screen_wa-input = '0'.
      modify screen from screen_wa.
   endif.
*   if screen_wa-name = 'S_LOEVM-HIGH'.
*      screen_wa-input = '0'.
*      modify screen from screen_wa.
*   endif.
   if screen_wa-name = 'P_QUOTX'.
      screen_wa-input = '0'.
      modify screen from screen_wa.
   endif.
  endloop.
*======================================================================*
INITIALIZATION.
*======================================================================*
 if s_quote is initial.
    move 'BT'     to s_quote-option.        "EQ=ist gleich
    move 'I'      to s_quote-sign.
    move '50.00'  to s_quote-low.
    move '100.00' to s_quote-high.
    append s_quote.
    clear s_quote.
   endif. "


*======================================================================*
AT SELECTION-SCREEN.
   if p_rkday EQ 0.
    if p_rkdat is initial.
     if w_man is initial.
        message text-010 type c_info.
        p_rkdat = p_vfdat + 40.
     endif.
    endif.
   endif.
   if not p_rkdat is initial.
    if p_rkday > 0.
     if w_man is initial.
        message text-011 type c_info.
        clear p_rkday.
     endif.
    endif.
   else.
    if p_rkday > 0.
       p_rkdat = p_vfdat + 30 + p_rkday.
       w_man = c_activ.
    endif.
   endif.

*======================================================================*
 START-OF-SELECTION.
*======================================================================*
   INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
* Vorbereitende Massnahmen :-)
  refresh s_fkimg.
  clear   s_fkimg.
  if not s_eigda is initial.
     move s_eigda[] to s_eigdt[].
  endif.
  if p_pausch eq c_activ.
*    nur Pauschalfakturen selektieren
     move 'EQ'    to s_fkimg-option.        "EQ=ist gleich
     move 'I'     to s_fkimg-sign.
     move 1       to s_fkimg-low.
     clear           s_fkimg-high.
     append s_fkimg.
  elseif p_opausc eq c_activ.
*        keine Pauschalfakturen selektieren
     move 'GT'    to s_fkimg-option.        "GT=Grösser
     move 'I'     to s_fkimg-sign.
     move 1       to s_fkimg-low.
     clear           s_fkimg-high.
     append s_fkimg.
  else.
     refresh s_fkimg.
     clear   s_fkimg.
  endif.
  if p_wiedhd ne c_activ.
   if s_vfgdt is initial.
      move 'EQ'    to s_vfgdt-option.        "EQ=ist gleich
      move 'I'     to s_vfgdt-sign.
      clear           s_vfgdt-low.
      clear           s_vfgdt-high.
      append s_vfgdt.
      move 'LT'         to s_vfgdt-option.   "LT=Kleiner
      move 'I'          to s_vfgdt-sign.
      move '20120101'   to s_vfgdt-low.
      clear                s_vfgdt-high.
      append s_vfgdt.
   endif. "
  endif. "p_echt
*   Auswertungstabellen bestimmen, abhängig ob Fall oder Gesuch gewählt
if p_wiedhd eq c_activ.   " Wiederholdruck von Echtdaten gewünscht !!!
   if     c_activ eq p_fall.
          w_kz_gf = c_kz_fall.
   elseif c_activ eq p_gesuch.
          w_kz_gf = c_kz_gesuch.
   endif.
*
   if c_activ eq p_echt.
      select * from zsd_05_lulu_prof into table t_print_prof
               where kenz_g_f   eq w_kz_gf
               and   obj_key    in s_objkey
               and   erdat      in s_erdat
               and   vorsteuerx eq P_vstx
               and   VFGDT      in s_VFGDT.
   elseif c_activ eq p_test.
      select * from zsd_05_lulu_prof into table t_print_prof
               up to p_t_rows ROWS
               where kenz_g_f   eq w_kz_gf
               and   obj_key    in s_objkey
               and   erdat      in s_erdat
               and   vorsteuerx eq P_vstx
               and   VFGDT      in s_VFGDT.
   endif.
else.
 if p_fall eq c_activ.
    w_lulu_head = c_fall_head.
    w_lulu_fakt = c_fall_fakt.
    w_pstart    = c_f_pstart.
    w_pende     = c_f_pende.
    refresh s_eigda. clear s_eigda.
 elseif p_gesuch eq c_activ.
    w_lulu_head = c_gesu_head.
    w_lulu_fakt = c_gesu_fakt.
    w_pstart    = c_g_pstart.
    w_pende     = c_g_pende.
    refresh s_agsp. clear s_agsp.
 endif.
 if p_vstx eq c_activ. "Kunden die Vorsteuer geltend gemacht haben
    message Text-020 type c_info.
 endif.
* Tabellenwerte sollten nun bestückt sein für die dynam. Auswertung
* Fälle - 2011 und 2012
 if p_fall eq c_activ.
  if p_echt eq c_activ.
     if p_t_rows lt 10000
     and p_t_rows ne 9999.
     select * from (w_lulu_head)
              into CORRESPONDING FIELDS OF TABLE t_head
              up to p_t_rows ROWS
              where status           in s_status
              and   obj_key          in s_objkey
              and   angaben_sperre_x in s_agsp
              and   eigda            in s_eigdt
              and   loevm            in s_loevm
              and   vorsteuerx       eq P_vstx
              and   VFGDT            in s_vfgdt
             .
     else.
     select * from (w_lulu_head)
              into CORRESPONDING FIELDS OF TABLE t_head
              where status           in s_status
              and   obj_key          in s_objkey
              and   angaben_sperre_x in s_agsp
              and   eigda            in s_eigdt
              and   loevm            in s_loevm
              and   vorsteuerx       eq P_vstx
              and   VFGDT            in s_vfgdt
             .
     endif.
   elseif p_test eq c_activ.
        select * from (w_lulu_head)
                 into CORRESPONDING FIELDS OF TABLE t_head
                 up to p_t_rows ROWS
              where status           in s_status
              and   obj_key          in s_objkey
              and   angaben_sperre_x in s_agsp
              and   eigda            in s_eigdt
              and   loevm            in s_loevm
              and   vorsteuerx       eq P_vstx
             .
  endif.
 endif.
* Gesuche 2007 bis 2010
 if p_gesuch eq c_activ.
  if p_echt eq c_activ.
     if p_t_rows lt 10000
     and p_t_rows ne 9999.
     select * from (w_lulu_head)
              into CORRESPONDING FIELDS OF TABLE t_head
              up to p_t_rows ROWS
              where status           in s_status
              and   obj_key          in s_objkey
              and   eigda            in s_eigda
              and   loevm            in s_loevm
              and   vorsteuerx       eq P_vstx
              and   VFGDT            in s_vfgdt
              and   RUECKZLG_QUOTE   in s_quote.
*              and   RUECKZLG_QUOTEX  eq p_quotx.
     else.
        select * from (w_lulu_head)
                 into CORRESPONDING FIELDS OF TABLE t_head
                 where status           in s_status
                 and   obj_key          in s_objkey
                 and   eigda            in s_eigda
                 and   loevm            in s_loevm
                 and   vorsteuerx       eq P_vstx
                 and   VFGDT            in s_vfgdt
                 and   RUECKZLG_QUOTE   in s_quote.
*                 and   RUECKZLG_QUOTEX  eq p_quotx.
     endif.
  elseif p_test eq c_activ.
        select * from (w_lulu_head)
                 into CORRESPONDING FIELDS OF TABLE t_head
                 up to p_t_rows ROWS
              where status           in s_status
              and   obj_key          in s_objkey
              and   eigda            in s_eigda
              and   loevm            in s_loevm
              and   vorsteuerx       eq P_vstx
              and   VFGDT            in s_vfgdt
              and   RUECKZLG_QUOTE   in s_quote.
*              and   RUECKZLG_QUOTEX  eq p_quotx.
  endif.
 endif.
endif.
*

 if sy-subrc eq 0.
    describe table t_head lines w_lines.
 endif.
 if w_lines > 0.
    loop at t_head into w_head.
     if not w_head is initial.
        perform u0010_get_fakt_dat using   w_head.
*       nun sollte t_fakt und t_aufz bestückt sein ...
        if sy-subrc eq 9.
           write: / 'Fehler Faktura-Daten bei Fall/Gesuch :'
                , w_head-fallnr.
           continue.
        endif.
        check sy-subrc ne 9.
        perform u0020_get_objekt_dat using    w_head
                                     changing w_objektbez
                                              w_bemerkung.
        loop at t_aufz into w_aufz.
         if not w_aufz is initial.
            move-CORRESPONDING w_head to w_printline.
            move: w_objektbez         to w_printline-objektbez
                , w_bemerkung         to w_printline-bemerkung
                .
            Perform u0100_fill_adress changing w_printline.
            read table t_fakt with key vbeln = w_aufz-faknr
                              into w_fakt.
            MOVE-CORRESPONDING w_fakt to w_printline.
            move w_fakt-BRTWR         to w_printline-BRTWR_vbrk.
*            if evtl. noch Verzugszins-Aktualisieren ???
            w_aufz-rue_basis_dt = p_vfdat. "Verfügungsdatum gilt!!!
            if p_gesuch eq c_activ.
               w_ge_fa = 'G'.
            elseif p_fall eq c_activ.
               w_ge_fa = 'F'.
            endif.
 data:      lw_grunbtr               type zz_rubtr."für FuBa notwendig
            clear lw_grunbtr.
            move w_aufz-rubtr_brt    to  lw_grunbtr.
            CALL FUNCTION 'Z_SD_LULU_CALC_VGUZI'
              EXPORTING
                i_von_datum          = w_aufz-fkdat
                i_bis_datum          = w_aufz-rue_basis_dt
                i_grundbetrag        = lw_grunbtr
                I_KZ_GE_FA           = w_ge_fa
                i_kz_zinszins        = c_leer "Steuerung Zinstabelle
              IMPORTING
                E_TAGE               = w_aufz-vgtage
                E_ZINS_SATZ          = w_aufz-vgusz
                E_ZINS_BETRAG        = w_aufz-vgubtr_net
              TABLES
                t_zinstab            = t_zinstab.
             if w_aufz-mwstz > 0.
                w_aufz-vgubtr_bru = w_aufz-vgubtr_net
                                  * ( 1 + ( w_aufz-mwstz / 100 ) ).
             elseif w_aufz-mwstz = 0.
                w_aufz-vgubtr_bru = w_aufz-vgubtr_net.
             endif.
*              w_aufz-vgubtr_bru = w_aufz-vgubtr_net
*                                * ( 1 + ( w_aufz-mwstz / 100 ) ).
            modify t_aufz from w_aufz.
            MOVE-CORRESPONDING w_aufz to w_printline.
*           Faktoren alt und neu bestücken >>>> Start >>>>>>>>>>>>>>>>>
            case w_aufz-matnr.
             when c_gr_wohn_alt.   "Faktor alt =1  neu=1
              move: '1.0'    to  w_printline-faktor_new,
                    '1.0'    to  w_printline-faktor_old.
             when c_gr_gew0_5_alt. "Faktor alt=0.5 neu=0.5
              move: '0.5'    to  w_printline-faktor_new,
                    '0.5'    to  w_printline-faktor_old.
             when c_gr_gew1_0_alt. "Faktor alt=1   neu=1
              move: '1.0'    to  w_printline-faktor_new,
                    '1.0'    to  w_printline-faktor_old.
             when c_gr_gew1_3_alt. "Faktor alt=1.3 neu=1
              move: '1.0'    to  w_printline-faktor_new,
                    '1.3'    to  w_printline-faktor_old.
             when c_gr_gew2_0_alt. "Faktor alt=2   neu=1
              move: '1.0'    to  w_printline-faktor_new,
                    '2.0'    to  w_printline-faktor_old.
             when others.
              clear: w_printline-faktor_new,
                     w_printline-faktor_old.
            endcase. "w_aufz-matnr.
*           Faktoren alt und neu bestücken <<<< Ende  <<<<<<<<<<<<<<<<<
            move w_ge_fa                  to w_printline-kz_ge_fa.
            move w_aufz-vgubtr_bru        to w_printline-vgubtr.
            move: w_aufz-VERR_DATUM       to w_printline-verrg_beginn
                , w_aufz-VERR_DATUM_SCHL  to w_printline-verrg_ende
                .
            Perform u0110_fullfill_printline changing w_printline.
            append w_printline to t_printline.
            clear w_printline.
         endif."not w_aufz is intitial
        endloop."t_aufz into w_aufz.
        clear w_lines.
        describe table t_aufz lines w_lines.
        if w_lines > 0.
           modify zsd_05_kehr_aufz from table t_aufz.
        endif.
     endif."not w_head is initial
    endloop." at t_head into w_head
 endif. "w_lines > 0.
*======================================================================*
 END-OF-SELECTION.
*======================================================================*
 free t_head. free t_fakt. free t_aufz.
 if p_wiedhd eq c_activ.
*   Wiederholdruck wurde gewählt, also Daten in Printline transferieren
    refresh t_printline. clear t_printline.
    loop at t_print_prof into w_lulu_prof.
     clear w_printline.
     MOVE-CORRESPONDING w_lulu_prof to w_printline.
     append w_printline to t_printline.
    endloop.
 endif.
 if p_wiedhd eq c_inactiv.
*   Erst-Echt-Druck wurde gewählt, Protokoll-Datei initialisieren
    refresh t_print_prof.
    clear   t_print_prof.
 endif.
 DESCRIBE TABLE t_printline lines w_lines.
 if w_lines gt 0.
*    loop at t_printline into w_printline.
     clear w_sum_formular.
     Perform u0500_Print_Verfuegung.
*    endloop. "at t_printline
 endif. "w_lines gt 0.
*
 if w_sum_formular > 0.
    Perform u0900_Closing_Message using w_sum_formular.
 else.
    message Text-F99 type c_error.
 endif.
*
*======================================================================*
*                   Unterprogramm-Bibliothek
*======================================================================*
form u0001_auth_check.
*
*
endform. "u0001_auth_check.
*----------------------------------------------------------------------*
form u0010_get_fakt_dat using    lw_head  type zsd_05_lulu_hd02.
*
 data:    w_vbeln_vf(11)    type c.
 refresh: t_fakt, t_aufz.
 clear:   t_fakt, t_aufz.
*
 select * from (w_lulu_fakt) into CORRESPONDING FIELDS OF TABLE t_fakt
          where fallnr eq lw_head-fallnr.
*          and   kennz  eq c_bezahlt.
 if sy-subrc eq 0.
    loop at t_fakt.
     if t_fakt-vbeln(1) ne '0'.
        clear w_vbeln_vf.
        move: '0'       to w_vbeln_vf+0(1)
            , t_fakt-vbeln to w_vbeln_vf+1(10)
            .
        condense w_vbeln_vf no-gaps.
        t_fakt-vbeln = w_vbeln_vf.
        modify t_fakt.
     endif.
    endloop. "t_fakt
    select * from zsd_05_kehr_aufz
             into CORRESPONDING FIELDS OF TABLE t_aufz
             FOR ALL ENTRIES IN t_fakt
             where faknr     eq t_fakt-vbeln
             and   fkimg_new in s_fkimg
             and   kennz     eq c_bezahlt.
    if sy-subrc ne 0.
       sy-subrc = 9.
    else.
       loop at t_aufz.
        if t_fakt-vbeln eq t_aufz-faknr.
           t_aufz-fkdat = t_fakt-fkdat.
           modify t_aufz.
        else.
           read table t_fakt with key vbeln = t_aufz-faknr.
           if sy-subrc eq 0.
              t_aufz-fkdat = t_fakt-fkdat.
              modify t_aufz.
           endif.
        endif.
       endloop. "t_aufz
    endif.
 endif.
*
endform. "u0010_get_fakt_dat using    w_head.
*----------------------------------------------------------------------*
form u0020_get_objekt_dat using    lw_head      type zsd_05_lulu_hd02
                          changing lw_objektbez type bezei40
                                   lw_bemerkung type text40.
*
 select single objektbez bemerkung
   from zsd_05_objekt into (lw_objektbez, lw_bemerkung)
  where stadtteil eq lw_head-stadtteil
    and parzelle  eq lw_head-parzelle
    and objekt    eq lw_head-objekt.
 if  sy-subrc eq 0
 and ( not lw_objektbez is initial
       or not lw_bemerkung is initial ).
 else.
    select single objektbez bemerkung
      from zsd_05_objekt into (lw_objektbez, lw_bemerkung)
     where stadtteil eq lw_head-stadtteil
       and parzelle  eq lw_head-parzelle
       and objekt    eq c_4zero.
    if sy-subrc eq 0.
    else.
       clear: lw_objektbez, lw_bemerkung.
    endif.
 endif.
*
endform. "u0020_get_objekt_dat using    w_head changing etc...
*----------------------------------------------------------------------*
form u0100_fill_adress changing lw_printline type zsd_05_lulu_printline.
*   ------------------------- abw. Rechnungsempfänger-Adresse -------
*   prüfen und ggf. bestücken abw. Rechnungsempfänger-Adress-Nummer
 if lw_printline-rg_adrnr is initial.
  if lw_printline-rg_kunnr is initial.
*    dann lassen wir es auch :-)
  else.
*    abw.REmpf-Nummer vorhanden, dann weiter ...
     select single adrnr from kna1 into lw_printline-rg_adrnr
            where kunnr eq lw_printline-rg_kunnr.
     if sy-subrc ne 0.
        clear lw_printline-rg_adrnr.
     endif.
  endif.
 endif.
*   ------------------------- Eigentümer-Adresse ---------------------
*   prüfen und ggf. bestücken Eigentümer-Adress-Nummer
 if lw_printline-eigen_adrnr is initial.
  if lw_printline-eigen_kunnr is initial.
*    dann lassen wir es auch :-) => eben nicht, darf nicht sein !!!
     if not lw_printline-rg_kunnr is initial.
        lw_printline-eigen_kunnr = lw_printline-rg_kunnr.
        lw_printline-eigen_adrnr = lw_printline-rg_adrnr.
     else.
*       nu sin ma chancenlos, dann muss halt das Formular krachen ...
     endif.
  else.
*    Eigentümer-Nummer vorhanden, sollt ja eigentlich auch so sein...
     select single adrnr from kna1 into lw_printline-eigen_adrnr
            where kunnr eq lw_printline-eigen_kunnr.
     if sy-subrc ne 0.
        lw_printline-eigen_kunnr = lw_printline-rg_kunnr.
        lw_printline-eigen_adrnr = lw_printline-rg_adrnr.
     endif.
  endif.
 endif.
*   ------------------------- Vertreter-Adresse ----------------------
*   prüfen und ggf. bestücken Vertreter-Adress-Nummer
 if lw_printline-vertr_adrnr is initial.
  if lw_printline-vertr_kunnr is initial.
*    dann lassen wir es auch :-)
  else.
*    Vertreter-Nummer vorhanden, dann weiter ...
     select single adrnr from kna1 into lw_printline-vertr_adrnr
            where kunnr eq lw_printline-vertr_kunnr.
     if sy-subrc ne 0.
        clear lw_printline-vertr_adrnr.
     endif.
  endif.
 endif.
*
endform." u0100_fill_printline using w_head.
*----------------------------------------------------------------------*
form u0110_fullfill_printline
           changing lw_printline type zsd_05_lulu_printline.
*
 lw_printline-vfgdt = p_vfdat.
 if p_rkdat is initial.
  if p_rkday > 0.
     lw_printline-rkrdt = p_vfdat + p_rkday.
  else.
     lw_printline-rkrdt = p_vfdat + 40.
  endif.
 else.
    lw_printline-rkrdt = p_rkdat.
 endif.
 if lw_printline-fkimg_new eq 1.
*   Pauschalbetrag wurde fakturiert ...
*    break-point.
 endif.

*
endform." u0110_fullfill_printline changing w_printline.
*----------------------------------------------------------------------*
form u0500_Print_Verfuegung.
 data: w_line_idx          type i
     , w_spool_grp_nr      type i
     , w_fall_counter      type i
     , w_sf_options        TYPE ssfcompop
     , w_sf_control_params type SSFCTRLOP
     , t_printl1           type table of zsd_05_lulu_printline
                           with header line.
 data: lw_sum_rubtr        type zz_sum_rubtr
     , lw_sum_vgubtr       type zz_sum_vgubtr
     , lw_sum_rueck        type ZZ_SUM_RUECKBTR.

 clear lw_sum_rubtr.
 clear lw_sum_vgubtr.
 clear lw_sum_rueck.
* Sortieren aufsteigend nach Fall-Nummer, dann nach Faktura-Nr. und Pos.
 sort t_printline by fallnr vbeln fakpo.
*
*
 if p_echt eq c_activ.
*   lesen Funktionsbaustein zum Formular ....
    perform u0510_get_SSF_Fuba  USING    w_sfname
                                CHANGING w_sf_fuba.
*   abarbeiten der Druckdaten
    clear w_fall_counter.
    refresh t_printl1. clear t_printl1.
    describe table t_printline lines w_lines.
    w_total_lines = w_lines.
    clear w_lines.
    CLEAR: w_sf_options-tdnewid, w_sf_options-tdfinal.
    loop at t_printline into w_printline.
     w_line_idx = w_line_idx + 1.
*    Feldwerte beim ersten Durchgang der Spoolgruppe
     IF w_line_idx EQ 1.
        ADD 1 TO w_spool_grp_nr.
        w_sf_options-tdnewid          = 'X'.
        w_sf_options-tddest           = p_pridev.
        w_sf_options-tddataset        = Text-t00. "LuLu
        w_sf_options-tdsuffix1        = 'BNM' && w_spool_grp_nr.
        if p_fall eq c_activ.
           w_sf_options-tdtitle       = Text-t01. "Fälle 2011-2012
        elseif p_gesuch eq c_activ.
           w_sf_options-tdtitle       = Text-t02. "Gesuche 2007-2010
        endif.
        w_sf_options-tdimmed          = p_prnow.
*        gs_sf_control_params-device    = pa_print.
        w_sf_control_params-no_dialog = p_dlog.
        w_sf_control_params-no_open   = ' '.
        w_sf_control_params-no_close  = 'X'.
      ENDIF.
      "Feldwerte bei der nächsten Fallnummer innerhalb der Spoolgruppe
      MOVE-CORRESPONDING w_printline to t_printl1.
      lw_sum_rubtr  = lw_sum_rubtr  + t_printl1-rubtr_brt.
      lw_sum_vgubtr = lw_sum_vgubtr + t_printl1-vgubtr.
      lw_sum_rueck  = lw_sum_rubtr  + lw_sum_vgubtr.
      append t_printl1.
      AT NEW fallnr.
        "Beim ersten Durchgang nicht durchführen
        add 1 to w_fall_counter.
        CLEAR: w_sf_options-tdnewid, w_sf_options-tdfinal.
        IF w_fall_counter NE 1.
          w_sf_control_params-no_open   = 'X'.
          w_sf_control_params-no_close  = 'X'.
        ENDIF.
        clear lw_sum_rubtr.
        clear lw_sum_vgubtr.
        clear lw_sum_rueck.
        lw_sum_rubtr  = lw_sum_rubtr  + t_printl1-rubtr_brt.
        lw_sum_vgubtr = lw_sum_vgubtr + t_printl1-vgubtr.
        lw_sum_rueck  = lw_sum_rubtr  + lw_sum_vgubtr.
      ENDAT.
      if w_total_lines eq w_line_idx.
*        letzter Eintrag erreicht ...
         w_sf_control_params-no_open   = 'X'.
         w_sf_control_params-no_close  = ' '.
         w_sf_options-tdfinal          = 'X'.
      endif.
      at end of fallnr.
*        ausgeben der Pro-Forma-Verfügungsdaten als Formulardruck
*        Summenwerte für Titelseite Pro-Forma-Verfügung übergeben
         loop at t_printl1.
          move: lw_sum_rubtr  to t_printl1-sum_rubtr
              , lw_sum_vgubtr to t_printl1-sum_vgubtr
              , lw_sum_rueck  to t_printl1-sum_rueck
              .
          modify t_printl1.
          if p_plfill eq c_activ.
*           Test-DB für Testdrucke Pro-Forma-Formular füllen
            move-CORRESPONDING t_printl1 to zsd_05_t_printl.
            modify zsd_05_t_printl.
            clear: zsd_05_t_printl.
          endif.
          if p_echt eq c_activ.
*            Echtverarbeitung, d.h. Ausgeben der Dokumente
             if p_wiedhd eq c_inactiv.
*               nur wenn kein Wiederholdruck !!!
                clear w_lulu_prof.
                MOVE-CORRESPONDING t_printl1  to w_lulu_prof.
                move:  sy-datum               to w_lulu_prof-erdat
                    ,  sy-uzeit               to w_lulu_prof-erzet
                    ,  t_printl1-KZ_GE_FA     to w_lulu_prof-kenz_G_F
                    .
                append w_lulu_prof to t_print_prof.
*               nur wenn kein Wiederholdruck gewählt !!!!!!!!!!!!!!!!!!!
             endif.
          endif.
         endloop.
         if w_fall_counter eq 1.
            w_sf_options-tdnewid          = 'X'.
            w_sf_options-tddest           = p_pridev.
            w_sf_options-tddataset        = Text-t00. "LuLu
            w_sf_options-tdsuffix1        = 'BNM' && w_spool_grp_nr.
            if p_fall eq c_activ.
               w_sf_options-tdtitle       = Text-t01. "Fälle 2011-2012
            elseif p_gesuch eq c_activ.
               w_sf_options-tdtitle       = Text-t02. "Gesuche 2007-2010
            endif.
            w_sf_options-tdimmed          = p_prnow.
*            gs_sf_control_params-device    = pa_print.
            w_sf_control_params-no_dialog = p_dlog.
            w_sf_control_params-no_open   = ' '.
            w_sf_control_params-no_close  = 'X'.
            CLEAR: w_sf_options-tdnewid, w_sf_options-tdfinal.
            if w_total_lines eq w_line_idx.
*              letzter Eintrag erreicht ...
                w_sf_control_params-no_close  = ' '.
                w_sf_options-tdfinal          = 'X'.
            endif.
         endif.
         PERFORM u0520_print_proforma   TABLES t_printl1
                                        USING  w_sfname
                                               w_sf_fuba
                                               w_sf_options
                                               w_sf_control_params.

         if  c_inactiv eq p_wiedhd
         and c_activ   eq p_echt.
*            kein Wiederholdruck und Echtverarbeitung wurde gewählt .
*            d.h. -> Protokoll-Datei fortschreiben wenn was drin steht.
             DESCRIBE TABLE t_print_prof lines w_lines.
             if w_lines > 0.
*               Es sind Einträge vorhanden, also DB schreiben
                 modify zsd_05_lulu_prof from table t_print_prof.
*                ein Commit Work in Ehren kann keiner verwehren :-)
                 commit work.
*                besser eins zuviel, als eins zuwenig ... :-)
             endif.
         endif.
         refresh t_printl1. clear t_printl1.
         refresh t_print_prof. clear t_print_prof.
      endat."end of fallnr
    endloop. "at t_printline into w_printline.
    describe table t_printl1 lines w_lines.
    if w_lines > 0.
       if w_fall_counter eq 1.
          w_sf_options-tdnewid          = 'X'.
          w_sf_options-tddest           = p_pridev.
          w_sf_options-tddataset        = Text-t00. "LuLu
          w_sf_options-tdsuffix1        = 'BNM' && w_spool_grp_nr.
          if p_fall eq c_activ.
             w_sf_options-tdtitle       = Text-t01. "Fälle 2011-2012
          elseif p_gesuch eq c_activ.
             w_sf_options-tdtitle       = Text-t02. "Gesuche 2007-2010
          endif.
          w_sf_options-tdimmed          = p_prnow.
*          gs_sf_control_params-device    = pa_print.
          w_sf_control_params-no_dialog = p_dlog.
          w_sf_control_params-no_open   = ' '.
          w_sf_control_params-no_close  = 'X'.
          CLEAR: w_sf_options-tdnewid, w_sf_options-tdfinal.
          w_sf_options-tdfinal          = 'X'.
       endif.
       PERFORM u0520_print_proforma   TABLES t_printl1
                                      USING  w_sfname
                                             w_sf_fuba
                                             w_sf_options
                                             w_sf_control_params.
       if  c_inactiv eq p_wiedhd
       and c_activ   eq p_echt.
*          kein Wiederholdruck und Echtverarbeitung wurde gewählt .
*           d.h. -> Protokoll-Datei fortschreiben wenn was drin steht.
           DESCRIBE TABLE t_print_prof lines w_lines.
           if w_lines > 0.
*             Es sind Einträge vorhanden, also DB schreiben
               modify zsd_05_lulu_prof from table t_print_prof.
*              ein Commit Work in Ehren kann keiner verwehren :-)
               commit work.
*              besser eins zuviel, als eins zuwenig ... :-)
           endif.
       endif.
       refresh t_printl1. clear t_printl1.
       refresh t_print_prof. clear t_print_prof.
    endif.
 endif.
*
endform." u0500_Print_Verfuegung.
*&---------------------------------------------------------------------*
*&      Form  u0510_get_ssf_fuba
*&---------------------------------------------------------------------*
*       Funktionsbaustein zu Smarform lesen
*----------------------------------------------------------------------*
FORM u0510_get_SSF_Fuba  USING    lw_sfname  type TDSFNAME
                         CHANGING lw_sf_fuba type RS38L_FNAM.

  CALL FUNCTION 'SSF_FUNCTION_MODULE_NAME'
    EXPORTING
      formname               = lw_sfname
*   VARIANT                  = ' '
*   DIRECT_CALL              = ' '
   IMPORTING
     fm_name                 = lw_sf_fuba
* EXCEPTIONS
*   NO_FORM                  = 1
*   NO_FUNCTION_MODULE       = 2
*   OTHERS                   = 3
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM. " u0510_get_SSF_Fuba  USING lw_sfname CHANGING lw_sf_fuba.
*&---------------------------------------------------------------------*
*&      Form  u0520_print_proforma
*&---------------------------------------------------------------------*
*       Pro-Forma-Verfügung - Drucken
*----------------------------------------------------------------------*
*      -->P_GS_LULU_HEAD  text
*----------------------------------------------------------------------*
FORM u0520_print_proforma
                 TABLES lt_printl1
                 USING  lw_sfname            type TDSFNAME
                        lw_sf_fuba           type RS38L_FNAM
                        lw_sf_options        TYPE ssfcompop
                        lw_sf_control_params type SSFCTRLOP.

  if lw_sf_fuba is initial.
     "Funktionsbaustein zum Smartforms-Formular lesen
     PERFORM u0510_get_ssf_fuba USING    lw_sfname
                                CHANGING lw_sf_fuba.
  endif.

  CALL FUNCTION lw_sf_fuba
    EXPORTING
      control_parameters = lw_sf_control_params
      output_options     = lw_sf_options
      user_settings      = abap_false
    TABLES
      PRINTLINE_BODY     = lt_printl1
      printline_body2    = lt_printl1
    EXCEPTIONS
      formatting_error   = 1
      internal_error     = 2
      send_error         = 3
      user_canceled      = 4
      OTHERS             = 5.

   if sy-subrc eq 0.
      add 1  to w_sum_formular.
      if p_echt eq c_activ.
         Perform u0600_update_vfdat tables lt_printl1.
      endif.
   endif.
*
ENDFORM.                    " PRINT_CONFIRM
*----------------------------------------------------------------------*
form u0600_update_vfdat tables lt_printl1.
*
 data: ls_head       type zsd_05_lulu_head
     , ls_hd02       type zsd_05_lulu_hd02
     , lw_printl1    type zsd_05_lulu_printline
     .
*
 loop at lt_printl1 into lw_printl1.
  if p_fall eq c_activ.
     select single * from zsd_05_lulu_hd02 into ls_hd02
            where  fallnr eq lw_printl1-fallnr.
     ls_hd02-vfgdt = lw_printl1-vfgdt.
     ls_hd02-rkrdt = lw_printl1-rkrdt.
     modify zsd_05_lulu_hd02 from ls_hd02.
  elseif p_gesuch eq c_activ.
     select single * from zsd_05_lulu_head into ls_head
            where  fallnr eq lw_printl1-fallnr.
     ls_head-vfgdt = lw_printl1-vfgdt.
     ls_head-rkrdt = lw_printl1-rkrdt.
     modify zsd_05_lulu_head from ls_head.
  endif.
  exit.
 endloop.
 commit work.
*
endform." u0600_update_vfdat tables lt_printl1.
*----------------------------------------------------------------------*
form u0900_Closing_Message using w_sum_formular  type i.
*
 data: lw_line(120)        type c
     , lw_anz_form(10)     type c
     .
*
* Header
uline.
clear lw_line.
lw_line = text-h01.
write: / lw_line CENTERED.
Uline.
skip 2.
* Detail-Daten
clear lw_line.
concatenate text-d01 text-d02 into lw_line.
write w_sum_formular to lw_anz_form.
replace '&w_sum_formular&' with lw_anz_form into lw_line.
write: / lw_line CENTERED.
skip 1.
clear lw_line.
lw_line = text-d03.
replace '&w_pstart&' with w_pstart into lw_line.
replace '&w_pende&'  with w_pende  into lw_line.
write: / lw_line CENTERED.
skip 1.
clear lw_line.
lw_line = text-d10.
write: / lw_line CENTERED.
skip 1.
clear lw_line.
concatenate text-d15 text-d16 into lw_line.
clear lw_anz_form.
write p_vfdat to lw_anz_form.
replace '&p_vfgdt&' with lw_anz_form into lw_line.
clear lw_anz_form.
write p_rkdat to lw_anz_form.
replace '&p_rkrdt&' with lw_anz_form into lw_line.
write: / lw_line CENTERED.
skip 1.
clear lw_line.
lw_line = text-d20.
write: / lw_line CENTERED.
skip 1.
clear lw_line.
lw_line = text-d30.
write: / lw_line CENTERED.
* Footer
skip 2.
uline.
clear lw_line.
lw_line = text-e01.
replace '&sy-sysid&' with sy-sysid into lw_line.
clear lw_anz_form.
write sy-datum to lw_anz_form.
replace '&sy-datum&' with lw_anz_form into lw_line.
clear lw_anz_form.
write sy-uzeit to lw_anz_form.
replace '&sy-uzeit&' with lw_anz_form into lw_line.
write: / lw_line CENTERED.
uline.
* The end *
*
endform." u0900_Closing_Message using w_sum_formular.
