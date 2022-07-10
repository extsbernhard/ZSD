*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_RUECKZ_REP01
*&
*&---------------------------------------------------------------------*
*& Dieser Report wurde auf Anforderung des Finanzinspektorats gegenüber
*& dem ERB erstellt. Die ERB wurde aufgefordert Zeitraumbezogene Aus-
*& Auswertungen dem Finanzinspektorat vorzulegen, wobei die einfachen
*& FI-Debitoren-/Sachkonten-Auswertungen nicht genügten.
*&---------------------------------------------------------------------*
*& Auftragsersteilung durch die ERB (T.Balsiger) erfolgte am Abend des
*& 11.06.2014 - Start der Umsetzung erfolgte am 18.06.2014
*& Autor: Oliver Epking, Fa. Alsinia GmbH, 3612 Steffisburg
*&---------------------------------------------------------------------*

*======================================================================*
* Allgemeine Programm-Includes
*======================================================================*
 INCLUDE ZSD_05_LULU_RUECKZ_TOP                  .    " global Data

 INCLUDE ZSD_05_LULU_RUECKZ_O01                  .  " PBO-Modules
* INCLUDE ZSD_05_LULU_RUECKZ_I01                  .  " PAI-Modules
 INCLUDE ZSD_05_LULU_RUECKZ_F01                  .  " FORM-Routines
*======================================================================*
* Eigentlicher Verarbeitungs-Start
*======================================================================*
*----------------------------------------------------------------------*
 start-of-selection.
*----------------------------------------------------------------------*
   INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
* setzen Laufdatum und Laufzeitpunkt
  g_lauf_datum = sy-datum.
  g_lauf_zeit  = sy-uzeit.
*
 case w_kz_ge_fa.
  when c_kz_fall.
*      t_worktab füllen
       perform u0010_get_fall_header_data.
*      t_worktdet füllen anhand der t_worktab-daten
       perform u0015_get_fk02_data.
  when c_kz_gesuch.
       perform u0020_get_gesuch_header_data.
*      t_worktdet füllen anhand der t_worktab-daten
       perform u0025_get_fakt_data.
  when others.
*      gibts nicht, bzw. darfs nicht geben sonst läuft was schief :-)
 endcase."w_kz_ge_fa
* noch schnell prüfen wer ein Grosskunde ist ...
  free: t_bkpf, t_bsak.
  perform u0040_get_info_grosskunde.
* t_worktdet füllen anhand der t_worktab-daten
  perform u0050_get_detail_kehr_aufz.
  perform u0055_get_detail_fi_belnr.
*
*----------------------------------------------------------------------*
 end-of-selection.
*----------------------------------------------------------------------*
 sort t_worktab by fallnr.
 sort t_worktdet by fallnr belnr faknr fakpo.

 case w_list_kz.
  when 'S'. "Summenliste gewählt
       perform u0100_summenliste_aufbereiten.
  when 'D'. "Detailliste gewählt
       perform u0200_detailliste_aufbereiten.
  when others.
*      gibts ja gar nicht ....
       message text-s99 type c_error.
 endcase."w_list_kz
*
 perform u6000_alv_out.
*
