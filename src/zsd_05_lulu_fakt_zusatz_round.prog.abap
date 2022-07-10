*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_FAKT_ZUSATZ_round
*&
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
* Kurz-        | Ergänzende Daten zu den Fakturen der Kehricht-Gebühren*
* Beschreibung | in die Zusatztabelle ZSD_05_KEHR_AUFZ integrieren.    *
*              | Dabei werden aus den Faktura-Texten die Quadratmeter  *
*              | und die Einzelgebühr gelesen und bestückt.            *
* Funktionen   |                                                       *
*              |                                                       *
* Input        | ZSD_05_KEHR_AUFT                                      *
*              | VBRP                                                  *
* Output       | ZSD_05_KEHR_AUFZ                                      *
*              |                                                       *
*--------------+-------------------------------------------------------*

*----------------------Aenderungsdokumentation-------------------------
* Edition  SAP-Rel.  Datum        Bearbeiter
*          Beschreibung
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*

REPORT ZSD_05_LULU_FAKT_ZUSATZ_ROUND.
*----------------------------------------------------------------------*

tables: zsd_05_kehr_aufz                 "Kehricht-Fakturen-Zusatzdaten
      , zsd_05_lulu_head                 "Gesuchs-Kopf-Datei(2007-2010)
      , zsd_05_lulu_hd02                 "Fälle-Kopf-Datei  (2011-2012)
      .
*----------------------------------------------------------------------*
data: c_io                  like sy-subrc     value 0
    , c_aktiv               type c            value 'X'
    , c_leer                type c            value ' '
    , c_info                type c            value 'I'
    , c_warn                type c            value 'W'
    , c_error               type c            value 'E'
    , c_abort               type c            value 'A'
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
    , c_800                 type ZZ_MWSTZ     value '8.00'
    , c_770                 type ZZ_MWSTZ     value '7.70'
    , c_760                 type ZZ_MWSTZ     value '7.60'
    , c_300                 type ZZ_VGUSZ     value '3.000'
    , c_120                 type zz_netpr_new value '1.20'
    , c_060                 type zz_netpr_new value '0.60'
    , c_000                 type zz_netpr_new value '0.00'
    , c_2007                type char4        value '2007'
    .
data: t_kehr_aufz            type table of zsd_05_kehr_aufz
                             with header line
    , w_kehraufz             type zsd_05_kehr_aufz
    .
data: ws_head             type zsd_05_lulu_head
    , ws_hd02             type zsd_05_lulu_hd02
    .
data: w_subrc             like sy-subrc
    , w_faknr             type vbeln_vf
    , w_lines             type i              "Zähler für Tab-Einträge
    , w_lines_char(8)     type c              "Zähler Tab-Einträge Char
    , w_length            type i
    , w_tdid              like THEAD-TDID     value '0001'
    , w_tdspras           like THEAD-TDSPRAS  value 'D'
    , w_tdname            like THEAD-TDNAME
    , w_tdobject          like THEAD-TDOBJECT value 'VBBP'
    , w_messtxt(130)      type c              "Message Text
    , w_kauft             type zsd_05_kehr_auft
    , w_vbrp              type vbrp
    , w_kaufz             type zsd_05_kehr_aufz
    , w_fill1(80)         type c
    , w_fill2(80)         type c
    , w_fill3(80)         type c
    , w_tdline(132)       type c
    , w_change_kz         type c
    , w_scha_update       type c
    .
*----------------------------------------------------------------------*
select-options:  s_verr      for zsd_05_kehr_aufz-VERR_DATUM
*                             no-EXTENSION no INTERVALS
              ,  s_datbi     for zsd_05_kehr_aufz-verr_datum_schl
*                             no-EXTENSION no INTERVALS
              ,  s_objky     for zsd_05_kehr_aufz-obj_key
              .
Parameters:      p_overf      RADIOBUTTON GROUP ver
          ,      p_mverf      RADIOBUTTON GROUP ver
          .
*======================================================================*
START-OF-SELECTION.
*======================================================================*
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  select * from ZSD_05_kehr_aufz into table t_kehr_aufz
           where verr_datum      in s_verr
           and   verr_datum_schl in s_datbi
           and   obj_key         in s_objky
           and   rubtr           >  0.
*
  loop at t_kehr_aufz.
   if t_kehr_aufz-verr_datum < '20110100'.
      select single * from zsd_05_lulu_head into ws_head
                      where obj_key eq t_kehr_aufz-obj_key.
      if sy-subrc eq 0.
         if  ws_head-vfgdt > '20130701'
         and p_overf       eq 'X'.
             delete t_kehr_aufz.
             continue.
         endif.
      else.
             delete t_kehr_aufz.
      endif.
   else.
      select single * from zsd_05_lulu_hd02 into ws_hd02
                      where obj_key eq t_kehr_aufz-obj_key.
      if sy-subrc eq 0.
         if  ws_hd02-vfgdt > '20130701'
         and p_overf       eq 'X'.
             delete t_kehr_aufz.
             continue.
         endif.
      else.
             delete t_kehr_aufz.
      endif.
   endif.
  endloop.
*
*======================================================================*
end-of-SELECTION.
*======================================================================*
 data: lw_new_brutto       like zsd_05_kehr_aufz-netwr_new
     , lw_new_rubtr        like zsd_05_kehr_aufz-netwr_new
     , lw_new_runet        like zsd_05_kehr_aufz-netwr_new
     , lw_new_mwst         like zsd_05_kehr_aufz-netwr_new
     , lw_new_ruqbtr_brt   like zsd_05_kehr_aufz-netwr_new
     , lw_mwst_satz        like zsd_05_kehr_aufz-netwr_new
     , lw_new_ruqmwst_brt  like zsd_05_kehr_aufz-netwr_new
     .

 loop at t_kehr_aufz into w_kehraufz.
  clear w_scha_update.
*    w_kehraufz-rubtr_brt ist immer der Rückzahlungbetrag Brutto
*    für die Rückerstattung unabhängig ob Quote oder nicht.
  if w_kehraufz-ruquo eq 0
  or w_kehraufz-ruquo eq 100.
     lw_new_brutto = w_kehraufz-netwr_new + w_kehraufz-mwsbp_new.
     lw_new_rubtr  = w_kehraufz-brtwr - lw_new_brutto.
     lw_new_mwst   = lw_new_rubtr - w_kehraufz-rubtr.
     lw_new_runet  = lw_new_rubtr - lw_new_mwst.
     if lw_new_mwst eq w_kehraufz-rumwst_btr.
        clear w_scha_update.
     else.
        w_scha_update = 'X'.
        w_kehraufz-rumwst_btr = lw_new_mwst.
        w_kehraufz-rubtr_brt  = lw_new_rubtr.
        w_kehraufz-rubtr      = lw_new_runet.
     endif.
  else.
     lw_new_brutto = w_kehraufz-netwr_new + w_kehraufz-mwsbp_new.
     lw_new_rubtr  = w_kehraufz-brtwr - lw_new_brutto.
     lw_new_mwst   = lw_new_rubtr - w_kehraufz-rubtr.
     lw_new_runet  = lw_new_rubtr - lw_new_mwst.
     lw_new_ruqbtr_brt  = lw_new_rubtr * w_kehraufz-ruquo / 100.
     lw_mwst_satz       = 100 + w_kehraufz-mwstz.
     lw_new_ruqmwst_brt = w_kehraufz-mwstz * lw_new_ruqbtr_brt
                          / lw_mwst_satz.
     w_scha_update = 'X'.
     w_kehraufz-rubtr       = lw_new_runet.
     w_kehraufz-rumwst_btr  = lw_new_mwst.
     w_kehraufz-ruqbtr      = lw_new_ruqbtr_brt - lw_new_ruqmwst_brt.
     w_kehraufz-ruqmwst_btr = lw_new_ruqmwst_brt.
     w_kehraufz-rubtr_brt   = lw_new_ruqbtr_brt.
  endif.
*  if w_kehraufz-ruqbtr ne 0.
*     lw_new_brutto = w_kehraufz-netwr_new + w_kehraufz-mwsbp_new.
*     lw_new_rubtr  = w_kehraufz-brtwr - lw_new_brutto.
*     lw_new_rubtr  =
*     lw_new_mwst   = lw_new_rubtr - w_kehraufz-netwr_new.
*     if lw_new_mwst eq w_kehraufz-rumwst_btr.
*        clear w_scha_update.
*     else.
*        w_scha_update = 'X'.
*        w_kehraufz-rumwst_btr = lw_new_mwst.
*     endif.
*  endif.
  if w_scha_update eq 'X'.
     modify t_kehr_aufz from w_kehraufz.
     modify zsd_05_kehr_aufz from w_kehraufz.
     clear w_scha_update.
  endif.
 endloop.
*======================================================================*
form runden_ausserkraft.
 data: lw_kompl_wert     type char10
     , lw_wert_dec       type c
     , lw_wert(3)        type p DECIMALS 2
     , lw_len            type i
     .
  write: w_kehraufz-rubtr_brt to lw_kompl_wert.
  condense lw_kompl_wert no-gaps.
  lw_len = strlen( lw_kompl_wert ).
  lw_len = lw_len - 1.
  move lw_kompl_wert+lw_len(1) to lw_wert_dec.
  case lw_wert_dec.
   when '0' or '5'.
*    alles i.O.
     clear w_scha_update.
   when '1' or '2'.
    lw_wert = lw_wert_dec.
    lw_wert = lw_wert / 100.
    w_kehraufz-rubtr_brt = w_kehraufz-rubtr_brt - lw_wert.
    if w_kehraufz-rumwst_btr > 0.
       w_kehraufz-rumwst_btr = w_kehraufz-rumwst_btr - lw_wert.
    endif.
    if w_kehraufz-ruqmwst_btr > 0.
       w_kehraufz-ruqmwst_btr = w_kehraufz-ruqmwst_btr - lw_wert.
    endif.
    w_scha_update = 'X'.
   when '3' or '4'.
    lw_wert = lw_wert_dec.
    lw_wert = 5 - lw_wert.
    lw_wert = lw_wert / 100.
    w_kehraufz-rubtr_brt = w_kehraufz-rubtr_brt + lw_wert.
    if w_kehraufz-rumwst_btr > 0.
       w_kehraufz-rumwst_btr = w_kehraufz-rumwst_btr + lw_wert.
    endif.
    if w_kehraufz-ruqmwst_btr > 0.
       w_kehraufz-ruqmwst_btr = w_kehraufz-ruqmwst_btr + lw_wert.
    endif.
    w_scha_update = 'X'.
   when '6' or '7'.
    lw_wert = lw_wert_dec.
    lw_wert = lw_wert - 5.
    lw_wert = lw_wert / 100.
    w_kehraufz-rubtr_brt = w_kehraufz-rubtr_brt - lw_wert.
    if w_kehraufz-rumwst_btr > 0.
       w_kehraufz-rumwst_btr = w_kehraufz-rumwst_btr - lw_wert.
    endif.
    if w_kehraufz-ruqmwst_btr > 0.
       w_kehraufz-ruqmwst_btr = w_kehraufz-ruqmwst_btr - lw_wert.
    endif.
    w_scha_update = 'X'.
   when '8' or '9'.
    lw_wert = lw_wert_dec.
    lw_wert = 10 - lw_wert.
    lw_wert = lw_wert / 100.
    w_kehraufz-rubtr_brt = w_kehraufz-rubtr_brt + lw_wert.
    if w_kehraufz-rumwst_btr > 0.
       w_kehraufz-rumwst_btr = w_kehraufz-rumwst_btr + lw_wert.
    endif.
    if w_kehraufz-ruqmwst_btr > 0.
       w_kehraufz-ruqmwst_btr = w_kehraufz-ruqmwst_btr + lw_wert.
    endif.
    w_scha_update = 'X'.
   when others.
*       darfs nicht geben....
  endcase.
endform.
