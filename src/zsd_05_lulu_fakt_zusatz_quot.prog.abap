*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_FAKT_ZUSATZ
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
* Erstelldatum | 19.02.2014          Fertigdat.|                       *
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
* Kurz-        | Kopie aus ZSD_05_LULU_FAKT_Zusatz zur Neuberechnung   *
* Beschreibung | der Quotenabhängigen Vergütungszinsen, die ursprüng-  *
*              | lich auf 100% gerechnet wurden ...                    *
*              |                                                       *
* Funktionen   |                                                       *
*              |                                                       *
* Input        | ZSD_05_KEHR_AUFZ                                      *
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

REPORT ZSD_05_LULU_FAKT_ZUSATZ_QUOT.
*----------------------------------------------------------------------*

tables: zsd_05_kehr_auft                 "Kehricht-Fakturen zum Objekt
      , zsd_05_kehr_aufz
      , vbrp                             "Faktura-Positions-Daten
      , stxh                             "Text-Header-Tabelle
      , zsd_04_kehricht                  "aktuelle Kehrichtgebühren etc.
      , ZSD_05_LULU_VZI                  "Vergütungszinstabelle
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
data: t_k_auft            type table of zsd_05_kehr_auft
                          with header line
    , t_vbrp              type table of vbrp
                          with header line
    , t_lines             type table of tline
                          with header line
    , t_k_aufz            type table of zsd_05_kehr_aufz
                          with header line
    , t_pausch            type table of zsd_05_lulu_pau
                          with header line
    , t_pausch_leer       type table of zsd_05_lulu_pau
                          with header line
    , t_lulu_vguzi        type table of zsd_05_lulu_vzi
                          with header line
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
    .
*----------------------------------------------------------------------*
select-options:  s_ruquo     for zsd_05_kehr_aufz-ruquo
              ,  s_fkdat     for zsd_05_kehr_aufz-fkdat
              ,  s_faknr     for zsd_05_kehr_aufz-faknr
              ,  s_objky     for zsd_05_kehr_aufz-obj_key
              .
Parameters:      p_ruedt     type zz_ru_bas_dt obligatory
          .
*Parameters:      p_grokd    as checkbox default ' '
*          .
Parameters:      p_echt      RADIOBUTTON GROUP ver
          ,      p_simu      RADIOBUTTON GROUP ver
          .
*======================================================================*
START-OF-SELECTION.
*======================================================================*
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
* neu ab 12.09.2013 - Einlesen des speziellen Vergütungszinses
  select * from ZSD_05_LULU_VZI into table t_lulu_vguzi
           where loevm eq c_leer.
    select * from zsd_05_kehr_aufz into table t_k_aufz
             where ruquo           in s_ruquo
             and   fkdat           in s_fkdat
             and   faknr           in s_faknr
             and   obj_key         in s_objky.
 if sy-subrc ne 0.
    message text-i01 type c_info.
    sy-subrc = 9999. "= nix selektiert !!!!
    exit.
 endif.
 check sy-subrc < 9999. "Nix selektiert, ... sie sind raus !!!
 describe table t_k_aufz lines w_lines.
  clear w_messtxt.
  w_messtxt = text-i10.
  write: w_lines to w_lines_char.
  replace '#LINES#' into w_messtxt with w_lines_char.
  condense w_messtxt.
 message w_messtxt type c_info.
*
*======================================================================*
end-of-SELECTION.
*======================================================================*
 check sy-subrc < 9999. "Nix selektiert, dann auch nix machen !!!
 data: lw_err_mwstz     type ZZ_MWSTZ
     , lw_result        type c
     .
 loop at t_k_aufz into w_kaufz.
*  if p_grokd eq c_aktiv.
*  else.
  if not w_kaufz is initial.
     perform u1010_Zins_rechnen changing w_kaufz
                                         lw_result.
     if lw_result eq 0.
        modify t_k_aufz from w_kaufz.
     else.
        delete t_k_aufz.
     endif.
  endif. "not w_kaufz is initial
*  endif. "p_grokd eq activ
 endloop. "t_k_auft.
*
 if p_echt eq c_aktiv.
    modify zsd_05_kehr_aufz from table t_k_aufz.
    commit work.
 else.
    loop at t_k_aufz into w_kaufz.
     write: / w_kaufz(80).
    endloop.
 endif.
*
*======================================================================*
*                      Unterprogramm-Bibliothek
*======================================================================*
form u0010_get_vbrp using    lw_faknr        type vbeln_vf
                    changing lw_subrc        like syst-subrc.
 clear   t_vbrp.
 refresh t_vbrp.
*
 select * from vbrp into table t_vbrp
          where vbeln eq lw_faknr.
 if sy-subrc eq 0.
    lw_subrc = sy-subrc.
 else.
    clear   t_vbrp.
    refresh t_vbrp.
    lw_subrc = sy-subrc.
 endif.
*
endform." u0010_get_vbrp using    w_kauft-faknr  changing w_subrc.
*----------------------------------------------------------------------*
form u0020_read_pos_text using    lw_vbeln_vf     type vbeln_vf
                                  lw_posnr_vf     type posnr_vf
                         changing lw_fkimg_new    type fkimg
                                  lw_netpr_old    type netpr
                                  lw_subrc        like syst-subrc.
*
 refresh t_lines.
 clear   t_lines.
*
 concatenate lw_vbeln_vf lw_posnr_vf into w_tdname.
 condense w_tdname.
 select single * from stxh where tdid     eq w_tdid
                           and   tdspras  eq w_tdspras
                           and   tdname   eq w_tdname
                           and   tdobject eq w_tdobject.
 if sy-subrc ne 0.
    lw_subrc = sy-subrc.
 else.
*   Text existiert, also lesen, das Teil ....
    CALL FUNCTION 'READ_TEXT'
     EXPORTING
      ID                            = w_tdid
      LANGUAGE                      = w_tdspras
      NAME                          = w_tdname
      OBJECT                        = w_tdobject
*    IMPORTING
*     OLD_LINE_COUNTER              =
     TABLES
      LINES                         = t_lines
     EXCEPTIONS
      ID                            = 1
      LANGUAGE                      = 2
      NAME                          = 3
      NOT_FOUND                     = 4
      OBJECT                        = 5
      REFERENCE_CHECK               = 6
      WRONG_ACCESS_TO_ARCHIVE       = 7
      OTHERS                        = 8.
    IF SY-SUBRC <> 0.
*      Implement suitable error handling here
       lw_subrc = sy-subrc.
    ENDIF. " zu read_text - sy-subrc
 endif. "sy-subrc zu stxh-select
*
 if sy-subrc eq 0.
    loop at t_lines where tdline+0(1) co '0123456789'.
     lw_subrc = 9.
     clear w_tdline.
     w_tdline = t_lines-tdline.
     if w_tdline na ':'.
        shift w_tdline LEFT DELETING LEADING space.
        split w_tdline at 'm2' into w_fill1 w_fill2.
        split w_fill1 at '.' into w_fill3 w_fill2.
        condense w_fill3 no-gaps.
        lw_fkimg_new = w_fill3.
        clear: w_fill1, w_fill2, w_fill3.
        split w_tdline at 'Fr.' into w_fill1 w_fill2.
        split w_fill2 at '=' into w_fill3 w_fill2.
        condense w_fill3 no-gaps.
        lw_netpr_old = w_fill3.
        clear: w_fill1, w_fill2, w_fill3.
        lw_subrc = 0.
        exit.
     endif.

    endloop. "at t_lines
    loop at t_lines where tdline cs 'Jahresgebühr Fr.'.
     lw_subrc = 9.
     clear w_tdline.
     w_tdline = t_lines-tdline.
     if w_tdline(16) eq 'Jahresgebühr Fr.'.
*       Pauschale Jahresgebühr
        split w_tdline at 'Fr.' into w_fill1 w_fill2.
        condense w_fill2 no-gaps.
        lw_netpr_old = w_fill2.
        lw_fkimg_new = 1.
        clear: w_fill1, w_fill2, w_fill3.
        lw_subrc = 0.
     endif.
    endloop.
 endif.
*
endform." u0020_read_pos_text using w_vbrp-vbeln w_vbrp-posnr w_subrc.
form u0100_get_new_price changing lw_kaufz type zsd_05_kehr_aufz.
*
 data: lw_kehricht     type zsd_04_kehricht.
 data: lw_stadtteil    type zz_stadtteil
     , lw_parzelle     type zz_parz_nr
     , lw_objekt       type zz_parz_teil
     , lw_verr_von(6)  type n "Abrechnung von JJJJMM zum rechnen
     , lw_verr_bis(6)  type n "Abrechnung bis JJJJMM zum rechnen
     , lw_anteil_verr  type i "verr_bis - verr_von + 1 = Anteil ...
     .
*
 clear: lw_stadtteil, lw_parzelle, lw_objekt.
 move: lw_kaufz-obj_key(1)   to lw_stadtteil
     , lw_kaufz-obj_key+1(4) to lw_parzelle
     , lw_kaufz-obj_key+5(4) to lw_objekt.
     .
* Berechnen anteil Monate für die Berechnung des Nettowerts
  move: lw_kaufz-verr_datum+0(6)      to lw_verr_von
      , lw_kaufz-verr_datum_schl+0(6) to lw_verr_bis
      .
        lw_anteil_verr = lw_verr_bis - lw_verr_von + 1.
*
 case lw_kaufz-fkimg_new. " QM-Wert, wenn 1 dann Pauschal ...
  when 1. "Pauschalbetrag -> lesen neuer Wert in zsd_04_kehricht
       read table t_pausch with key faknr = lw_kaufz-faknr.
       if sy-subrc ne 0. " das wäre also ganz schlecht !!!
          clear t_pausch.
       endif.
       if t_pausch-netwr_old eq lw_kaufz-netwr
       or t_pausch-netwr_old eq lw_kaufz-brtwr.
*         Logik vertagt, bis die irgendwie schlüssig ist ... :-(
*         d.h. alter Preis passt, => übernehmen wir auch den neuen Wert
          move: c_000              to lw_kaufz-netpr_new
              , t_pausch-netwr_new to lw_kaufz-netwr_new.
          perform u1000_wert_fill_in using    lw_kaufz-netpr_new
                                              lw_kaufz-netwr_new
                                              lw_anteil_verr
                                     changing lw_kaufz.
       endif.
  when others. "neue Grundgebühr (1,20CHF oder 0,60 CHF)
*      QM - Wert ist bestückt grösser 1... machen wir es uns leicht :-)
   case lw_kaufz-matnr.
*        Mat.Nr.   Bezeichnung                Alt         Neu
    when c_gr_wohn_alt.
*        5101770   GRUNDGEBÜHR WOHNUNGEN      1,45        1,20
         lw_kaufz-netpr_new = c_120.
         lw_kaufz-netwr_new = lw_kaufz-netpr_new * lw_kaufz-fkimg_new.
         perform u1000_wert_fill_in using    lw_kaufz-netpr_new
                                             lw_kaufz-netwr_new
                                             lw_anteil_verr
                                    changing lw_kaufz.
    when c_gr_gew0_5_alt.
*        5101771   GRUNDGEBÜHR GEWERBE 0.5    0,72        0,60
         lw_kaufz-netpr_new = c_060.
         lw_kaufz-netwr_new = lw_kaufz-netpr_new * lw_kaufz-fkimg_new.
         perform u1000_wert_fill_in using    lw_kaufz-netpr_new
                                             lw_kaufz-netwr_new
                                             lw_anteil_verr
                                    changing lw_kaufz.
    when c_gr_gew1_0_alt.
*        5101772   GRUNDGEBÜHR GEWERBE 1.0    1,45        1,20
         lw_kaufz-netpr_new = c_120.
         lw_kaufz-netwr_new = lw_kaufz-netpr_new * lw_kaufz-fkimg_new.
         perform u1000_wert_fill_in using    lw_kaufz-netpr_new
                                             lw_kaufz-netwr_new
                                             lw_anteil_verr
                                    changing lw_kaufz.
    when c_gr_gew1_3_alt.
*        5101773   GRUNDGEBÜHR GEWERBE 1.3    1,88        1,20
         lw_kaufz-netpr_new = c_120.
         lw_kaufz-netwr_new = lw_kaufz-netpr_new * lw_kaufz-fkimg_new.
         perform u1000_wert_fill_in using    lw_kaufz-netpr_new
                                             lw_kaufz-netwr_new
                                             lw_anteil_verr
                                    changing lw_kaufz.
    when c_gr_gew2_0_alt.
*	       5101774   GRUNDGEBÜHR GEWERBE 2.0   2,90        1,20
         lw_kaufz-netpr_new = c_120.
         lw_kaufz-netwr_new = lw_kaufz-netpr_new * lw_kaufz-fkimg_new.
         perform u1000_wert_fill_in using    lw_kaufz-netpr_new
                                             lw_kaufz-netwr_new
                                             lw_anteil_verr
                                    changing lw_kaufz.
    when c_gr_pausch_alt.
*	       5101775   GRUNDGEBÜHR PAUSCHAL - eigentlich unwahrscheinlich
         lw_kaufz-netpr_new = c_000.
         lw_kaufz-netwr_new = c_000.
         perform u1000_wert_fill_in using    lw_kaufz-netpr_new
                                             lw_kaufz-netwr_new
                                             lw_anteil_verr
                                    changing lw_kaufz.
    when others.
*        ... das gibts doch gar nicht !!! so was ist verrückt ...

   endcase.
 endcase.
*
endform. "u0100_get_new_price changing w_kaufz.
*----------------------------------------------------------------------*
form u1000_wert_fill_in using    lw_netpr_new type zz_netpr_new
                                 lw_netwr_new type zz_netwr_new
                                 lw_ant_verr  type i
                        changing lw_kaufz     type zsd_05_kehr_aufz.
*
 data: lw_fallnr                              type ZSDEKPFALLNR
     , lw_ruquo                               type ZZ_RUECKZLG_QUOTE
     , lw_kz_g_f                              type zz_KENNZ_GE_FA
     , lw_rubtr                               type zz_rubtr
     , lw_faknr                               type vbeln_vf
     .
*
 case lw_netpr_new.
  when c_000. "Pauschalbetrag-das ist etwas besonderes, erst später ...
*         if lw_ant_verr ne 12.
*         Nettowert anteilig errechnen, wenn nicht 12 Monate ...
*          lw_kaufz-netwr_new = lw_kaufz-netwr_new / 12 * lw_ant_verr.
*         endif.
*        Gemäss Mail 26.09.2013 A.Giger ist Pauschale bereits anteilig
         lw_kaufz-netwr_new = lw_kaufz-netwr_new.
         lw_kaufz-mwsbp_new = lw_kaufz-netwr_new
                              * ( lw_kaufz-mwstz / 100 ).

  when c_120 or c_060. "neuer Standardpreis 1,20 CHF
       if lw_ant_verr ne 12.
*         Nettowert anteilig errechnen, wenn nicht 12 Monate ...
          lw_kaufz-netwr_new = lw_kaufz-netwr_new / 12 * lw_ant_verr.
       endif.
       lw_kaufz-mwsbp_new = lw_kaufz-netwr_new
                            * ( lw_kaufz-mwstz / 100 ).
*
  when others.
*      das lassen wir mal ...
 endcase.
*-------------------- Ermitteln Rückzahlungsbetrag --------------------
 check lw_kaufz-kennz eq 'B'. " nur Rückzahlung, wenn bezahlt !!!
*      ermitteln des unquotierten Rückzahlungsbetrags
       lw_kaufz-rubtr      = lw_kaufz-netwr - lw_netwr_new.
       lw_kaufz-rumwst_btr = lw_kaufz-rubtr * ( lw_kaufz-mwstz / 100 ).
       lw_kaufz-rubtr_brt  = lw_kaufz-rubtr + lw_kaufz-rumwst_btr.
*      ------------------ Quote ermitteln für 2007-2010 ---------------
*      tja, Quote vorhanden ? mhhhh also müssen wir das nachlesen ...
       clear lw_faknr.
       write: lw_kaufz-faknr to lw_faknr.
       clear lw_fallnr.
       clear lw_kz_g_f.
       if lw_kaufz-verr_datum_schl < '20110101'. " dann Gesuche
          lw_kz_g_f = 'G'.
          select single fallnr from zsd_05_lulu_fakt
                 into lw_fallnr
                 where vbeln eq lw_faknr.
*                 where vbeln eq lw_kaufz-faknr.
          if sy-subrc eq 0.
             select single RUECKZLG_QUOTE from zsd_05_lulu_head
                      into lw_ruquo
                    where fallnr eq lw_fallnr.
             if sy-subrc ne 0.
                clear lw_ruquo.
             else.
                lw_kaufz-ruquo = lw_ruquo.
             endif.
          endif.
       endif.
*      ------------------ Quote ermitteln für 2007-2010 ---- Ende -----
       if lw_ruquo > 0 and lw_ruquo < 100. "dann gibt es was zu rechnen
          lw_kaufz-ruqbtr  = lw_kaufz-rubtr * ( lw_ruquo / 100 ).
          lw_kaufz-ruqmwst_btr
                          = lw_kaufz-ruqbtr * ( lw_kaufz-mwstz / 100 ).
          lw_kaufz-rubtr_brt = lw_kaufz-ruqbtr + lw_kaufz-ruqmwst_btr.
       endif.
*-------------------- Verguetungszins - Berechnung --------------------
*      Vergütungszins und Berechnung des Zinses auf Basis Fakturadatum
*                                          und gepl. Rückzahlungsdatum
*       bis zum 12.09.2013 wurde von einem fixen Zinssatz ausgegangen
        if lw_kz_g_f is initial. "d.h. kein Gesuch, da sonst bestückt
           lw_kz_g_f = 'F'.
        endif.
*       lw_kaufz-VGUSZ = c_300."festgelegt wurde, 3% werden gezahlt
*       lw_kaufz-vgtage = lw_kaufz-rue_basis_dt - lw_kaufz-fkdat.
*      -------------------------------------------------------------
*      Zinsbetrag = Rückz.betrag * ( Tageszins * Anzahl Tage) / 100.
*      Tageszins = Jahres-Zinssatz / Anzahl Tage pro Jahr.
       if lw_ruquo > 0 and lw_ruquo < 100.
          lw_rubtr = lw_kaufz-ruqbtr.
*         Verzinsung auf Quotenabhängigen Rückzahlungsbetrag
          CALL FUNCTION 'Z_SD_LULU_CALC_VGUZI'
           EXPORTING
            i_von_datum         = lw_kaufz-fkdat
            i_bis_datum         = lw_kaufz-rue_basis_dt
            i_grundbetrag       = lw_rubtr
            I_KZ_GE_FA          = lw_kz_g_f
            i_kz_zinszins       = c_leer "Steuerung aus Zinstabelle
           IMPORTING
            E_TAGE              = lw_kaufz-vgtage
            E_ZINS_satz         = lw_kaufz-vgusz
            E_ZINS_BETRAG       = lw_kaufz-VGUBTR_NET
           TABLES
            t_zinstab           = t_lulu_vguzi.
*          lw_kaufz-vgubtr_net = lw_kaufz-ruqbtr
*                    * ( lw_kaufz-vgusz / 365 * lw_kaufz-vgtage ) / 100.
       else.
*         Verzinsung auf 100% Rückzahlungsbetrag
          lw_rubtr = lw_kaufz-rubtr.
          CALL FUNCTION 'Z_SD_LULU_CALC_VGUZI'
           EXPORTING
            i_von_datum         = lw_kaufz-fkdat
            i_bis_datum         = lw_kaufz-rue_basis_dt
            i_grundbetrag       = lw_rubtr
            I_KZ_GE_FA          = lw_kz_g_f
            i_kz_zinszins       = c_leer "Steuerung aus Zinstabelle
           IMPORTING
            E_TAGE              = lw_kaufz-vgtage
            E_ZINS_satz         = lw_kaufz-vgusz
            E_ZINS_BETRAG       = lw_kaufz-VGUBTR_NET
           TABLES
            t_zinstab           = t_lulu_vguzi.
*          lw_kaufz-vgubtr_net = lw_kaufz-rubtr
*                    * ( lw_kaufz-vgusz / 365 * lw_kaufz-vgtage ) / 100.
       endif.
*      Rückerstattungsbetrag Brutto ist bereits Quotenabhängig gefüllt!
       lw_rubtr = lw_kaufz-rubtr_brt.
       CALL FUNCTION 'Z_SD_LULU_CALC_VGUZI'
         EXPORTING
           i_von_datum         = lw_kaufz-fkdat
           i_bis_datum         = lw_kaufz-rue_basis_dt
           i_grundbetrag       = lw_rubtr
           I_KZ_GE_FA          = lw_kz_g_f
           i_kz_zinszins       = c_leer "Steuerung aus Zinstabelle
         IMPORTING
           E_TAGE              = lw_kaufz-vgtage
           E_ZINS_satz         = lw_kaufz-vgusz
           E_ZINS_BETRAG       = lw_kaufz-VGUBTR_NET
         TABLES
           t_zinstab           = t_lulu_vguzi.
*       lw_kaufz-vgubtr_bru = lw_kaufz-rubtr_brt
*                    * ( lw_kaufz-vgusz / 365 * lw_kaufz-vgtage ) / 100.
*----------------------------------------------------------------------
*
*  if lw_kaufz-mwstz eq 0.
*     lw_kaufz-mwstz = '7.6'.
*  endif.
  if lw_kaufz-ruqbtr > 0.
     lw_kaufz-RUMWST_BTR  = lw_kaufz-ruqbtr * ( lw_kaufz-mwstz / 100 ).
     lw_kaufz-rubtr_brt   = lw_kaufz-ruqbtr + lw_kaufz-rumwst_btr.
  else.
     lw_kaufz-RUMWST_BTR  = lw_kaufz-rubtr * ( lw_kaufz-mwstz / 100 ).
     lw_kaufz-rubtr_brt   = lw_kaufz-rubtr + lw_kaufz-rumwst_btr.
  endif.
  lw_kaufz-VGUBTR_BRU  =
                 lw_kaufz-vgubtr_net * ( 1 + ( lw_kaufz-mwstz / 100 ) ).
endform." u1000_wert_fill_in using lw_netpr_new, lw_netwr_new.
form u1010_Zins_rechnen changing lw_kaufz   type zsd_05_kehr_aufz
                                 lw_result  type char1.
*
 data: lw_kz_g_f                            type c value 'G'
     , lw_grubtr                            type zz_rubtr
     .
*      Vergütungszins und Berechnung des Zinses auf Basis Fakturadatum
*                                          und gepl. Rückzahlungsdatum
*       bis zum 12.09.2013 wurde von einem fixen Zinssatz ausgegangen
        if  lw_kaufz-ruquo > 0
        and lw_kaufz-ruquo < 100.
*           Quoten nur bei Gesuchen !!!!!!!!!!!!!!!!
            lw_kz_g_f = 'G'.
        else.
*           ohne Quoten, dann sind es Fälle !!!!!!!!!!!!!
            lw_kz_g_f = 'F'.
        endif.
*       lw_kaufz-VGUSZ = c_300."festgelegt wurde, 3% werden gezahlt
*       lw_kaufz-vgtage = lw_kaufz-rue_basis_dt - lw_kaufz-fkdat.
*      -------------------------------------------------------------
*      Zinsbetrag = Rückz.betrag * ( Tageszins * Anzahl Tage) / 100.
*      Tageszins = Jahres-Zinssatz / Anzahl Tage pro Jahr.
       if lw_kaufz-ruquo > 0 and lw_kaufz-ruquo < 100.
          lw_grubtr = lw_kaufz-ruqbtr.
          lw_kaufz-rue_basis_dt = p_ruedt.
*         Verzinsung auf Quotenabhängigen Rückzahlungsbetrag
          CALL FUNCTION 'Z_SD_LULU_CALC_VGUZI'
           EXPORTING
            i_von_datum         = lw_kaufz-fkdat
            i_bis_datum         = lw_kaufz-rue_basis_dt
            i_grundbetrag       = lw_grubtr
            I_KZ_GE_FA          = lw_kz_g_f
            i_kz_zinszins       = c_leer "Steuerung aus Zinstabelle
           IMPORTING
            E_TAGE              = lw_kaufz-vgtage
            E_ZINS_satz         = lw_kaufz-vgusz
            E_ZINS_BETRAG       = lw_kaufz-VGUBTR_NET
           TABLES
            t_zinstab           = t_lulu_vguzi.
*          lw_kaufz-vgubtr_net = lw_kaufz-ruqbtr
*                    * ( lw_kaufz-vgusz / 365 * lw_kaufz-vgtage ) / 100.
       else.
*         Verzinsung auf 100% Rückzahlungsbetrag
          lw_grubtr = lw_kaufz-rubtr.
          lw_kaufz-rue_basis_dt = p_ruedt.
          CALL FUNCTION 'Z_SD_LULU_CALC_VGUZI'
           EXPORTING
            i_von_datum         = lw_kaufz-fkdat
            i_bis_datum         = lw_kaufz-rue_basis_dt
            i_grundbetrag       = lw_grubtr
            I_KZ_GE_FA          = lw_kz_g_f
            i_kz_zinszins       = c_leer "Steuerung aus Zinstabelle
           IMPORTING
            E_TAGE              = lw_kaufz-vgtage
            E_ZINS_satz         = lw_kaufz-vgusz
            E_ZINS_BETRAG       = lw_kaufz-VGUBTR_NET
           TABLES
            t_zinstab           = t_lulu_vguzi.
*          lw_kaufz-vgubtr_net = lw_kaufz-rubtr
*                    * ( lw_kaufz-vgusz / 365 * lw_kaufz-vgtage ) / 100.
       endif.
*      Rückerstattungsbetrag Brutto ist bereits Quotenabhängig gefüllt!
       lw_grubtr = lw_kaufz-rubtr_brt.
       lw_kaufz-rue_basis_dt = p_ruedt.
       CALL FUNCTION 'Z_SD_LULU_CALC_VGUZI'
         EXPORTING
           i_von_datum         = lw_kaufz-fkdat
           i_bis_datum         = lw_kaufz-rue_basis_dt
           i_grundbetrag       = lw_grubtr
           I_KZ_GE_FA          = lw_kz_g_f
           i_kz_zinszins       = c_leer "Steuerung aus Zinstabelle
         IMPORTING
           E_TAGE              = lw_kaufz-vgtage
           E_ZINS_satz         = lw_kaufz-vgusz
           E_ZINS_BETRAG       = lw_kaufz-VGUBTR_NET
         TABLES
           t_zinstab           = t_lulu_vguzi.
*       lw_kaufz-vgubtr_bru = lw_kaufz-rubtr_brt
*                    * ( lw_kaufz-vgusz / 365 * lw_kaufz-vgtage ) / 100.
*----------------------------------------------------------------------
*
  if lw_kaufz-ruqbtr > 0.
     lw_kaufz-RUMWST_BTR  = lw_kaufz-ruqbtr * ( lw_kaufz-mwstz / 100 ).
     lw_kaufz-rubtr_brt   = lw_kaufz-ruqbtr + lw_kaufz-rumwst_btr.
  else.
     lw_kaufz-RUMWST_BTR  = lw_kaufz-rubtr * ( lw_kaufz-mwstz / 100 ).
     lw_kaufz-rubtr_brt   = lw_kaufz-rubtr + lw_kaufz-rumwst_btr.
  endif.
  lw_kaufz-VGUBTR_BRU  =
                 lw_kaufz-vgubtr_net * ( 1 + ( lw_kaufz-mwstz / 100 ) ).
*
 if lw_kaufz-vgubtr_bru eq 0.
    lw_result = 9."keine Änderung !!!
 else.
    lw_result = 0.
 endif.
endform." u1010_Zins_rechnen changing lw_kaufz   type zsd_05_kehr_aufz.
