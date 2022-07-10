*&---------------------------------------------------------------------*
*& Report  ZSD_SBZ_DEBILIST_AP01
*&
*&---------------------------------------------------------------------*
*& Dieser Report wurde auf Anforderung der SBZ erstellt, da die Kombi-
*& nationen der Anforderungen sich mit Query nur schlecht und z.G. gar
*& nicht verwirklichen lassen hätten können. Daher wurde entschieden,
*& dass die geforderten Felder in einem Report ausgewertet werden sollen
*&---------------------------------------------------------------------*
*& Auftragsersteilung durch die SBZ Jonathan Vahlé, Leiter Verkauf
*& 17.03.2015 - Auftragserstellung durch Patrick Schär CCSAP Stadt Bern
*& 24.03.2015 - Start Realisierung durch O. Epking Fa. Alsinia GmbH
*& Autor: Oliver Epking, Fa. Alsinia GmbH, 3612 Steffisburg
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*


*======================================================================*
* Allgemeine Programm-Includes
*======================================================================*
INCLUDE ZSD_SBZ_DEBILIST_TOP                      .  " global Data
*
INCLUDE ZSD_SBZ_DEBILIST_O01                      .  " PAI-Modules
*
INCLUDE ZSD_SBZ_DEBILIST_F01.                     .  " FORM-Routines
*======================================================================*
* Eigentlicher Verarbeitungs-Start
*======================================================================*
*----------------------------------------------------------------------*
 start-of-selection.
*----------------------------------------------------------------------*
   INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  clear w_vkz.
* Was für eine Liste wurde gewählt???
  if     p_deball eq c_activ.
           w_vkz = 'deball'.
  elseif p_debohn eq c_activ.
           w_vkz = 'debohn'.
  elseif p_apalle eq c_activ.
           w_vkz = 'apalle'.
  endif.
*
 if w_vkz is initial.
    message text-fs0 type c_error.
    exit.
 endif.
 refresh t_debi_in. clear: t_debi_in, s_debi_in.
 case w_vkz.
  when  c_deball.
*       Alle Debitoren mit Ansprechpartner
        perform u0010_get_kundendaten.
        perform u0020_get_ansprechpartner.
  when  c_debohn.
*       Alle Debitoren ohne Ansprechpartner
        perform u0010_get_kundendaten.
  when  c_apalle.
*       Alle Ansprechpartner mit Kundennummer
        perform u0020_get_ansprechpartner.
  when others.
*      gibts nicht, bzw. darfs nicht geben sonst läuft was schief :-)
 endcase."w_vkz
**
*----------------------------------------------------------------------
*
 end-of-selection.
*----------------------------------------------------------------------
*
 loop at t_debi_in into s_debi_in.
  case w_vkz.
  when  c_deball.
*       Alle Debitoren mit Ansprechpartner
        if s_debi_in-parnr is initial.
           delete t_debi_in."from s_debin_in.
        else.
           MOVE-CORRESPONDING s_debi_in to s_debi_out.
           append s_debi_out to t_debi_out.
        endif.
  when  c_debohn.
*       Alle Debitoren ohne Ansprechpartner
        if not s_debi_in-parnr is initial.
           delete t_debi_in."from s_debi_in.
        else.
           MOVE-CORRESPONDING s_debi_in to s_debi_out.
           append s_debi_out to t_debi_out.
        endif.
  when  c_apalle.
*       Alle Ansprechpartner mit Kundennummer
        if s_debi_in-parnr is initial.
           delete t_debi_in.
        else.
           MOVE-CORRESPONDING s_debi_in to s_ap_out.
           append s_ap_out to t_ap_out.
        endif.
  when others.
*      gibts nicht, bzw. darfs nicht geben sonst läuft was schief :-)
  endcase. "w_vkz.
 endloop. "at t_debi_in into s_debi_in.
* sort t_worktab by fallnr.
* sort t_worktdet by fallnr belnr faknr fakpo.
*
* case w_list_kz.
*  when 'S'. "Summenliste gewählt
*       perform u0100_summenliste_aufbereiten.
*  when 'D'. "Detailliste gewählt
*       perform u0200_detailliste_aufbereiten.
*  when others.
**      gibts ja gar nicht ....
*       message text-s99 type c_error.
* endcase."w_list_kz
**
 perform u6000_alv_out.
**
