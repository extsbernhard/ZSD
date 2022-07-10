*&---------------------------------------------------------------------*
*& Modulpool         ZSD_05_LULU_REQU_MASS_FORM
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*


INCLUDE zsd_05_lulu_requ_form_mass_top.  " global Data
INCLUDE zsd_05_lulu_requ_form_mass_f01.  " FORM-Routines
* INCLUDE ZSD_05_LULU_REQU_FORM_MASS_O01.  " PBO-Modules
* INCLUDE ZSD_05_LULU_REQU_FORM_MASS_I01 . " PAI-Modules


DATA zaehler TYPE i.
DATA sw_grp.
* Epo20131128 - aus Top-Include übernommen da Warnhinweis aus EHP6.0
at SELECTION-SCREEN.
   if pa_mahn   ne c_activ.
    if  pa_echt eq c_activ.
     if pa_test eq c_activ.
        message text-f01 type c_mess_e.
     elseif pa_test eq c_inactiv.
        message text-v01 type c_mess_i.
     endif.
    elseif pa_test eq c_activ.
        message text-t01 type c_mess_i.
    endif.
   endif.
   if  pa_mahn   eq c_activ. "Mahnungen sind gewünscht
    if pa_echt   eq c_activ. "Echtverarbeitung
     if pa_eigda eq c_activ. "Eingangsdatum ist initial
        message text-v02 type c_mess_i.
     else." pa_eigda eq c_activ
        message text-f02 type c_mess_e.
     endif." pa_eigda eq c_activ
    endif." pa_echt eq c_activ.
    if pa_test   eq c_activ. "Testlauf
     if pa_eigda eq c_activ. "Eingangsdatum ist initial
        message text-t02 type c_mess_i.
     else." pa_eigda eq c_activ
        message text-w02 type c_mess_w.
     endif." pa_eigda eq c_activ
    endif." pa_test eq c_activ
   endif." pa_mahn eq c_activ

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  "Kopfdaten ermitteln
  "Im Testlauf max. PA_ROWS-Datensätze
 if pa_mahn  ne abap_true.  "Kein Mahnlauf selektiert !!! "Epo20131128
  IF pa_test EQ abap_true.
    SELECT * FROM zsd_05_lulu_hd02
      INTO CORRESPONDING FIELDS OF TABLE gt_lulu_head
      UP TO pa_rows ROWS
      WHERE angaben_sperre_x EQ space
        AND loevm EQ space
        AND pridt_mass EQ '00000000'.
  ELSE.
    SELECT * FROM zsd_05_lulu_hd02
      INTO CORRESPONDING FIELDS OF TABLE gt_lulu_head
      WHERE angaben_sperre_x EQ space
        AND loevm EQ space
        AND pridt_mass EQ '00000000'.
  ENDIF.
 else." pa_mahn ne abap_true (d.h. ab hier Mahnung)       "Epo20131128
*     >>> Start insert - Mahnungen >>>>>>>>>>>>>>>>>>>>>>>"Epo20131128
  IF pa_test EQ abap_true.
   if pa_eigda eq abap_true.
    SELECT * FROM zsd_05_lulu_hd02
      INTO CORRESPONDING FIELDS OF TABLE gt_lulu_head
      UP TO pa_rows ROWS
      WHERE angaben_sperre_x EQ space
        AND loevm      EQ space
        AND eigda      EQ '00000000'.
*        and pridt_mass ne '00000000'.
   else."pa_eigda eq abap_true (d.h. Eingabe-Datum nicht leer)
*        das wird nur für Tests akzeptiert !!!
    SELECT * FROM zsd_05_lulu_hd02
      INTO CORRESPONDING FIELDS OF TABLE gt_lulu_head
      UP TO pa_rows ROWS
      WHERE angaben_sperre_x EQ space
        AND loevm      EQ space.
*        and pridt_mass ne '00000000'.
   endif."pa_eigda eq abab_true.
  ELSE.
    SELECT * FROM zsd_05_lulu_hd02
      INTO CORRESPONDING FIELDS OF TABLE gt_lulu_head
      WHERE angaben_sperre_x EQ space
        AND loevm      EQ space
        AND eigda      EQ '00000000'.
*        and pridt_mass ne '00000000'.
  ENDIF.
*  loop at gt_lulu_head into gs_lulu_head. "Druckdatum nicht gesetzt!
*   if  gs_lulu_head-pridt_mass eq '00000000'  "keine Massennachfrage
*   and gs_lulu_head-pridt_einz eq '00000000'. "keine Einzelnachfrage
*    if pa_echt eq c_activ.
*       message text-f90 type c_mess_i.
*       write: / text-f90
*            ,   text-010
*            ,   gs_lulu_head-fallnr
*            .
*       delete gt_lulu_head.
*    else.
*       message text-f90 type c_mess_i.
*    endif.
*   endif.
*  endloop." at gt_lulu_head.
*     <<< Ende  insert - Mahnungen <<<<<<<<<<<<<<<<<<<<<<<"Epo20131128
 endif." pa_mahn ne abap_true.                            "Epo20131128

  "Splitting von Spoolaufträgen
  DESCRIBE TABLE gt_lulu_head LINES gv_cnt_lines.
  gv_lines = gv_cnt_lines.
  gv_idx_from = 0.
  IF gv_cnt_lines GT pa_spgrp.
    gv_idx_to   = pa_spgrp.
  ELSE.
    gv_idx_to = gv_cnt_lines.
  ENDIF.

  "Loop über Datennachfrage-Fälle
  LOOP AT gt_lulu_head INTO gs_lulu_head.
    CLEAR: gt_lulu_fakt.

    "Zählen der zu verarbeitenden Fälle
    ADD 1 TO gv_cnt_case.
    ADD 1 TO gv_idx_from.


    "Spoolgruppe berechnen
    IF gv_cnt_lines GT pa_spgrp.
      gv_idx_grp = gv_cnt_case MOD pa_spgrp.
    ELSE.
      gv_idx_grp = gv_cnt_case MOD gv_cnt_lines.
    ENDIF.

    "Rechnungen zum Fall selektieren
    SELECT * FROM zsd_05_lulu_fk02 INTO CORRESPONDING FIELDS OF TABLE gt_lulu_fakt
      WHERE fallnr EQ gs_lulu_head-fallnr.

    "Rechnungen zu Fall vorhanden?
    IF sy-subrc EQ 0.
      CLEAR: gs_sf_options-tdnewid, gs_sf_options-tdfinal.

      "Feldwerte beim ersten Durchgang der Spoolgruppe
      IF gv_idx_grp EQ 1.
        ADD 1 TO gv_grp_nr.
        gs_sf_options-tdnewid          = 'X'.
        gs_sf_options-tddest           = pa_print.
        gs_sf_options-tddataset        = 'LULU'.
        gs_sf_options-tdsuffix1        = 'BNM' && gv_grp_nr.
        gs_sf_options-tdtitle          = 'LULU Datennachfrage Massendruck'.
        gs_sf_options-tdimmed          = pa_prnow.
*        gs_sf_control_params-device    = pa_print.
        gs_sf_control_params-no_dialog = pa_dlog.
        gs_sf_control_params-no_open   = ' '.
        gs_sf_control_params-no_close  = 'X'.
      ENDIF.

      "Feldwerte bei der nächsten Fallnummer innerhalb der Spoolgruppe
      AT NEW fallnr.
        "Beim ersten Durchgang nicht durchführen
        IF gv_cnt_case NE 1.
          gs_sf_control_params-no_open   = 'X'.
          gs_sf_control_params-no_close  = 'X'.
        ENDIF.
      ENDAT.

*      Feldwerte bei der letzten Fallnummmer innerhalb der Spoolgruppe
      IF gv_idx_grp EQ 0 OR gv_lines EQ 1.
        gs_sf_control_params-no_open   = 'X'.
        gs_sf_control_params-no_close  = ' '.
        gs_sf_options-tdfinal          = 'X'.
      ENDIF.


      IF  zaehler > pa_spgrp.
        zaehler = 0.
        gs_sf_control_params-no_open   = 'X'.
        gs_sf_control_params-no_close  = ' '.
        gs_sf_options-tdfinal          = 'X'.
        sw_grp = '1'.
      ELSE.
        IF sw_grp = '1'.
          sw_grp = ' '.
          gs_sf_control_params-no_open   = ' '.
          gs_sf_control_params-no_close  = 'X'.
        ELSE.
          gs_sf_control_params-no_open   = ' '.
          gs_sf_control_params-no_close  = ' '.
        ENDIF.
      ENDIF.

      "Druck der Datennachfrage
      PERFORM print_confirm TABLES gt_lulu_fakt
                            USING  gs_lulu_head
                                   gv_sfname
                                   gs_sf_options
                                   gs_sf_control_params.
      IF pa_echt EQ c_activ.
         perform update_fall_druckdatum using gs_lulu_head.
      ENDIF.
    ENDIF.



    "Anzahl Fälle reduzieren
    SUBTRACT 1 FROM gv_lines.
  ENDLOOP.































***  "Splitting von Spoolaufträgen
***  DESCRIBE TABLE gt_lulu_head_db LINES gv_cnt_lines.
***  gv_lines = gv_cnt_lines.
***  gv_idx_from = 1.
***  IF gv_cnt_lines GT pa_spgrp.
***    gv_idx_to   = pa_spgrp.
***  ELSE.
***    gv_idx_to = gv_cnt_lines.
***  ENDIF.
***
***
***  WHILE gv_lines GE 0.
***    ADD 1 TO gv_cnt_while.
***
***    CLEAR: gt_lulu_head[].
***    APPEND LINES OF gt_lulu_head_db FROM gv_idx_from TO gv_idx_to TO gt_lulu_head.
***
***
***    "Loop über Datennachfrage-Fälle
***    LOOP AT gt_lulu_head INTO gs_lulu_head.
***      CLEAR: gt_lulu_fakt.
***
***      "Zählen der zu verarbeitenden Fälle
***      ADD 1 TO gv_cnt_case.
***
***      "Rechnungen zum Fall selektieren
***      SELECT * FROM zsd_05_lulu_fk02 INTO CORRESPONDING FIELDS OF TABLE gt_lulu_fakt
***        WHERE fallnr EQ gs_lulu_head-fallnr.
***
***      "Rechnungen zu Fall vorhanden?
***      IF sy-subrc EQ 0.
***
***        gs_sf_options-tdnewid          = 'X'.
***        gs_sf_options-tddataset        = 'LULU'.
***        gs_sf_options-tdsuffix1        = 'BNM' && gv_cnt_while.
***        gs_sf_options-tdtitle          = 'LULU Datennachfrage Massendruck'.
***        gs_sf_options-tdimmed          = pa_prnow.
***        gs_sf_control_params-no_dialog = pa_dlog.
***
***        AT FIRST.
***          gs_sf_control_params-no_open   = ' '.
***          gs_sf_control_params-no_close  = 'X'.
***          "gs_sf_control_params-preview   = 'X'.
***        ENDAT.
***
***        AT NEW fallnr.
***          "Beim ersten Durchgang nicht durchführen
***          IF gv_cnt_case NE 1.
***            gs_sf_control_params-no_open   = 'X'.
***            gs_sf_control_params-no_close  = 'X'.
***          ENDIF.
***        ENDAT.
***
***
***        AT LAST.
***          gs_sf_control_params-no_open   = 'X'.
***          gs_sf_control_params-no_close  = ' '.
***        ENDAT.
***
***
***        "Druck der Datennachfrage
***        COMMIT WORK.
***        PERFORM print_confirm TABLES gt_lulu_fakt
***                              USING  gs_lulu_head
***                                     gv_sfname
***                                     gs_sf_options
***                                     gs_sf_control_params.
***      ENDIF.
***    ENDLOOP.
***
***    "While-Schleifen-Bedingung aktualisieren
***    gv_lines = gv_lines - pa_spgrp.
***    "Index-From anpassen
***    ADD pa_spgrp TO gv_idx_from.
***    "Index-To anpassen
***    ADD pa_spgrp TO gv_idx_to.
***    IF gv_idx_to GT gv_cnt_lines.
***      gv_idx_to = gv_cnt_lines.
***    ENDIF.
***  ENDWHILE.
