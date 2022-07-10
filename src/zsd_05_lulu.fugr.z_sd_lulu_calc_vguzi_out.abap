FUNCTION Z_SD_LULU_CALC_VGUZI_OUT.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_VON_DATUM) TYPE  FKDAT
*"     REFERENCE(I_BIS_DATUM) TYPE  FKDAT
*"     REFERENCE(I_GRUNDBETRAG) TYPE  ZZ_RUBTR
*"     REFERENCE(I_KZ_GE_FA) TYPE  ZZ_KENNZ_GE_FA OPTIONAL
*"     REFERENCE(I_KZ_ZINSZINS) TYPE  CHAR1 DEFAULT 'X'
*"  EXPORTING
*"     REFERENCE(E_TAGE) TYPE  ZZ_VGTAGE
*"     REFERENCE(E_ZINS_SATZ) TYPE  ZZ_VGUSZ
*"     REFERENCE(E_ZINS_BETRAG) TYPE  ZZ_VGUBTR
*"  TABLES
*"      T_ZINSTAB STRUCTURE  ZSD_05_LULU_VZI
*"      T_OUTLIST STRUCTURE  ZSD_05_LULU_ZINSLIST
*"----------------------------------------------------------------------
 data: w_sum_vgtage      type zz_vgtage "Summe aller Vergütungstage
     , w_sum_zinsbetrag  type zz_vgubtr "Summe aller Vergütungszinsbetr.
     , w_sum_rueckbetrag type zz_vgubtr "Kummulierter Rückzahlungsbetrag
     , w_vgtage          type zz_vgtage "Vergütungstage   Jahr
     , w_zinsbetrag      type zz_vgubtr "Vergütungszinsbetrag Jahr
     , w_vgusz           type zz_vgusz  "Vergütungszinssatz
     , w_zizins_kz       type zz_zizins "Zinseszins Ja/Nein
     , w_old_vgusz       type zz_vgusz  "Vergütungszinssatz Vorgänger
     , w_vgusz_gen       type zz_vgusz  "Vergütungszinssatz einheitlich
     , c_9999            type zz_vgusz  value '9.999'
*      Jahresabgrenzungen für die Zinsberechnung mit unterschiedlichen
*      Zinssätzen pro Jahr
     , w_aktuel_jahr(4)    type n          "Jahr zum Vergleich
     , w_end_jahr(4)       type n          "letztes vergleichsjahr
     , w_aktuel_endjahr(8) type n          "Datum letzter des Jahres
     , w_dat_akt_endjhr    type d          "Dautmsfeld zu obigem Feld
     , w_von_datum(8)      type n          "neues von Datum
     , w_dat_von_datum     type d          "Datumsfeld zu obigem Feld
     , c_3112(4)           type c          value '1231'
     , w_anzahl            type n          "Anzahl Schleifendurchläufe
     , w_lines             type i          "Anzahl Tabelleneinträge
     , lw_summe            type wertv8
     .
* Wenn Zinseszins-Rechnung aktiv, dann muss jedes Jahr berechnet werden
* dann wird
  describe table t_zinstab lines w_lines.
  if w_lines eq 0.
     select * from zsd_05_lulu_vzi into table t_zinstab
              where loevm eq ' '.
  endif.
* Ermitteln ob für den Zeitraum ein genereller Zinssatz gilt oder nicht
 loop at t_zinstab where kenz_g_f eq i_kz_ge_fa.
  if w_old_vgusz is initial.
     w_old_vgusz = t_zinstab-vgusz.
  else.
   if w_vgusz_gen eq c_9999. "wenn kein genereller Zinssatz, dann aufhö.
      exit. "loop beenden
   else.
    if w_old_vgusz eq t_zinstab-vgusz.
     if w_vgusz_gen is initial.
        w_vgusz_gen = t_zinstab-vgusz.
        w_zizins_kz = t_zinstab-zi_zins.
     elseif  w_vgusz_gen ne t_zinstab-vgusz
         and w_zizins_kz ne t_zinstab-zi_zins.
        w_vgusz_gen = c_9999."kein genereller Zinssatz
     endif.
    else.
       w_vgusz_gen = c_9999. "kein genereller Zinssatz
    endif.
   endif.
  endif.
 endloop.
* Berechnen der Verzugs-/Vergütungstage gesamt
 e_tage = ( i_bis_datum + 1 ) - i_von_datum.
* e_tage kann nur zum Rechnen verwendet werden wenn ein einheitlicher
* Zinssatz besteht für den gesamten Zeitraum, sonst muss gesplittet
* gerechnet werden. (wenn w_vgusz_gen = 9999 dann kein genereller Zins)
 if  w_vgusz_gen ne c_9999
 and i_kz_zinszins ne 'X'.
*   d.h. es gilt generell der gleiche Zinssatz und kein Zinseszins
*   einfache Berechnung für Prognose-Werte ....
  if w_zizins_kz eq 'N'
  or ( w_zizins_kz is initial and i_kz_zinszins ne 'X' ).
    w_zinsbetrag = i_grundbetrag *
                    ( w_vgusz_gen / 365 * e_tage ) / 100.
    w_sum_rueckbetrag = i_grundbetrag + w_zinsbetrag.
    w_sum_zinsbetrag  = w_zinsbetrag.
    w_sum_vgtage      = e_tage.
    move: i_von_datum         to t_outlist-p_von_datum
        , i_bis_datum         to t_outlist-p_bis_datum
        , i_grundbetrag       to t_outlist-p_grundbetrag
        , i_kz_ge_fa          to t_outlist-p_ge_fa
        , i_kz_zinszins       to t_outlist-p_zinszins
        , i_grundbetrag       to t_outlist-betrag_1
        , i_von_datum         to t_outlist-von_datum
        , i_bis_datum         to t_outlist-bis_datum
        , w_vgusz_gen         to t_outlist-vgusz
        , e_tage              to t_outlist-vgztage
        , w_zinsbetrag        to t_outlist-zinsbetrag
        , w_sum_rueckbetrag   to t_outlist-betrag_2
        .
    append t_outlist.
    clear t_outlist.
  endif.
 else.
* kein genereller Zinssatz, oder Zinseszins, jetzt muss man es prüfen
  w_aktuel_jahr     = i_von_datum(4).
  w_end_jahr        = i_bis_datum(4).
* >>> Berechnen Anzahl Do-Schleifen - Durchgänge = w_anzahl...
  w_anzahl          = ( w_end_jahr + 1 ) - w_aktuel_jahr.
* <<< Berechnen Anzahl Do-Schleifen - Durchgänge = w_anzahl...
*  w_von_datum       = i_von_datum.
  w_dat_von_datum   = i_von_datum.
  w_sum_rueckbetrag = i_grundbetrag.
* ---------------------------------------------------------------------
  do w_anzahl times.
*  >>>>>>>>>>>>> ermitteln Jahresende-Datum >>>>>>>>>>>>>>
   concatenate w_aktuel_jahr c_3112 into w_aktuel_endjahr.
   condense    w_aktuel_endjahr no-gaps.
   move        w_aktuel_endjahr to w_dat_akt_endjhr.
*  <<<<<<<<<<<<< ermitteln Jahresende-Datum <<<<<<<<<<<<<<
   if w_dat_akt_endjhr <= i_bis_datum.
*     aktuelles Jahr wird bis zum Ende berechnet.>>>>>>>>>>>>>>>>>>>>>>
      w_vgtage = ( w_dat_akt_endjhr + 1 ) - w_dat_von_datum.
      if w_vgtage > 365. " SAP erkennt das Schaltjahr, ignorieren !!!
         w_vgtage = 365. " Zinssatz wird auch nur durch 365 geteilt
      endif.
      read table t_zinstab with key kenz_g_f = i_kz_ge_fa
                                    jahr     = w_aktuel_jahr.
      if sy-subrc eq 0.
         w_zinsbetrag = w_sum_rueckbetrag *
                        ( t_zinstab-vgusz / 365 * w_vgtage ) / 100.
         clear lw_summe.
         lw_summe = w_sum_rueckbetrag + w_zinsbetrag.
         move: i_von_datum         to t_outlist-p_von_datum
             , i_bis_datum         to t_outlist-p_bis_datum
             , i_grundbetrag       to t_outlist-p_grundbetrag
             , i_kz_ge_fa          to t_outlist-p_ge_fa
             , i_kz_zinszins       to t_outlist-p_zinszins
             , w_sum_rueckbetrag   to t_outlist-betrag_1
             , w_dat_von_datum     to t_outlist-von_datum
             , w_dat_akt_endjhr    to t_outlist-bis_datum
             , t_zinstab-vgusz     to t_outlist-vgusz
             , w_vgtage            to t_outlist-vgztage
             , w_zinsbetrag        to t_outlist-zinsbetrag
             , lw_summe            to t_outlist-betrag_2
             .
         append t_outlist.
         clear t_outlist.
      else.
         clear w_zinsbetrag.
      endif.
*     aktuelles Jahr wird bis zum Ende berechnet.<<<<<<<<<<<<<<<<<<<<<<
   else.
*     --------------- erstes Jahr nicht komplett ----------------------
*     dieses Jahr ist nicht voll zu berechnen (das ist leicht (-: )
      w_vgtage = ( i_bis_datum + 1 ) - w_dat_von_datum.
      read table t_zinstab with key kenz_g_f = i_kz_ge_fa
                                    jahr     = w_aktuel_jahr.
      if sy-subrc eq 0.
         w_zinsbetrag = w_sum_rueckbetrag *
                         ( t_zinstab-vgusz / 365 * w_vgtage ) / 100.
         clear lw_summe.
         lw_summe = w_sum_rueckbetrag + w_zinsbetrag.
         move: i_von_datum         to t_outlist-p_von_datum
             , i_bis_datum         to t_outlist-p_bis_datum
             , i_grundbetrag       to t_outlist-p_grundbetrag
             , i_kz_ge_fa          to t_outlist-p_ge_fa
             , i_kz_zinszins       to t_outlist-p_zinszins
             , w_sum_rueckbetrag   to t_outlist-betrag_1
             , w_dat_von_datum     to t_outlist-von_datum
             , i_bis_datum         to t_outlist-bis_datum
             , t_zinstab-vgusz     to t_outlist-vgusz
             , w_vgtage            to t_outlist-vgztage
             , w_zinsbetrag        to t_outlist-zinsbetrag
             , lw_summe            to t_outlist-betrag_2
             .
         append t_outlist.
         clear t_outlist.
      else.
         clear w_zinsbetrag.
      endif.
*     --------------- erstes Jahr nicht komplett ----------------------
   endif.
   w_sum_vgtage     = w_sum_vgtage + w_vgtage.
   w_sum_zinsbetrag = w_sum_zinsbetrag + w_zinsbetrag.
   if i_kz_zinszins eq 'X'  "bei Zinseszinsberechnung erhöhter Betrag
   or t_zinstab-zi_zins eq 'J'.
      w_sum_rueckbetrag = w_sum_rueckbetrag + w_zinsbetrag.
   endif.
   w_dat_von_datum = w_dat_akt_endjhr + 1. "setzen neues Von-Datum
   add 1 to w_aktuel_jahr. "bereit machen für das nächste Jahr
   clear w_vgtage.
   clear w_zinsbetrag.
  enddo.
* ---------------------------------------------------------------------
 endif.
 e_zins_betrag  = w_sum_zinsbetrag.
 e_tage         = w_sum_vgtage.
* e_rueck_betrag = w_sum_rueckbetrag. den brauchts nur für die Zinsen
 e_zins_satz    = w_vgusz_gen.



ENDFUNCTION.
