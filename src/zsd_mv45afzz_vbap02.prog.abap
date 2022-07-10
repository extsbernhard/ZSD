*&---------------------------------------------------------------------*
*&  Include           ZSD_MV45AFZZ_VBAP02
*&---------------------------------------------------------------------*
* Erweiterung für die CO-Ableitung auf Kundenauftragspositions-Ebene
* -------------------------------------------------------------------- *
* erstellt durch Oliver Epking, Alsinia GmbH, 3612 Steffisburg         *
* über das Include, kann der Exit weiterhin bearbeitet werden, ohne    *
* nach jedem Patch/Release einen Zugangsschlüssel lösen zu müssen.     *
* erstellt am: 29.03.2016 im Rahmen Erweiterung Kontierungsableitung   *
* für die ERB (2870, 87) - Auftraggeber: Benjamin Fux und Rolf Studer  *
* ---------------------------------------------------------------------*
*
* Neue Tabelle für die CO-Ableitung:
* Tables: ZSD_MV45_CO_ABL
 Data: t_coabl            type TABLE OF zsd_mv45_co_abl
     , s_coabl            like LINE OF t_coabl
     , c_blank            type c                        value ' '
     , c_blank_vkorg      type vkorg                    value '    '
     , c_blank_vtweg      type vtweg                    value '  '
     , c_activ_x          type c                        value 'X'
     , lw_lines           type i
     , lw_subrc           like syst-subrc
     , lw_param_generell  type c
     .

*----------------------------------------------------------------------*
* Parameter für die generelle Ableitung erst einmal ausgeschalten!!!
  lw_param_generell = c_blank.   "generelle Ableitung - inaktiv
* lw_param_generell = c_activ_x. "generelle Ableitung - aktiv
*----------------------------------------------------------------------*
*       lesen Ableitungstabelle mit VKORG und VTWEG und ohne Löschkennz.
 refresh t_coabl. clear s_coabl.
 select * from zsd_mv45_co_abl into table t_coabl
         where vkorg eq vbak-vkorg
           and vtweg eq vbak-vtweg
           and loevm eq c_blank.
*   Prüfen ob alles i.O. und ob Einträge gefunden wurden.
 if sy-subrc eq 0.
   DESCRIBE TABLE t_coabl lines lw_lines.
 else.
    lw_subrc = sy-subrc.
 endif.

 if lw_lines > 0 and lw_subrc = 0.
* hier geht es nur weiter, wenn etwas korrekt gelesen wurde !!!

  loop at t_coabl into s_coabl.
*    Prüfen auf die 3 Schlüssel, aber nur wenn nicht leer...
*** =============================================================== ***
***     Produkthierarchie                                           ***
*** =============================================================== ***
   if     vbap-prodh eq s_coabl-prodh
      and not s_coabl-prodh is initial.
*       niedrigste Prio, d.h. MATNR übersteuert ggf. die Prod.hierarchie
      if not s_coabl-aufnr is initial.
         vbap-aufnr = s_coabl-aufnr.                 "CO-Innenauftrag
      endif.
      if not s_coabl-kostl is initial.
         vbap-kostl = s_coabl-kostl.                 "CO-Kostenstelle
      endif.
      if not s_coabl-ps_psp_pnr is initial.
         vbap-ps_psp_pnr = s_coabl-ps_psp_pnr.       "CO-PSP-Element
      endif.
*** =============================================================== ***
***     Warengruppe                                                 ***
*** =============================================================== ***
   elseif vbap-matkl eq s_coabl-matkl
      and not s_coabl-matkl is initial.
*       nächst höhere Prio, direkt unter MATNR, übersteuert die Prodhi.
      if not s_coabl-aufnr is initial.
         vbap-aufnr = s_coabl-aufnr.                 "CO-Innenauftrag
      endif.
      if not s_coabl-kostl is initial.
         vbap-kostl = s_coabl-kostl.                 "CO-Kostenstelle
      endif.
      if not s_coabl-ps_psp_pnr is initial.
         vbap-ps_psp_pnr = s_coabl-ps_psp_pnr.       "CO-PSP-Element
      endif.

*** =============================================================== ***
***     Material-Nummer                                             ***
*** =============================================================== ***
   elseif vbap-matnr eq s_coabl-matnr
      and not s_coabl-matnr is initial.
*         höchste Priorität, da höchste Detaillierung übersteuert alles
      if not s_coabl-aufnr is initial.
         vbap-aufnr = s_coabl-aufnr.                 "CO-Innenauftrag
      endif.
      if not s_coabl-kostl is initial.
         vbap-kostl = s_coabl-kostl.                 "CO-Kostenstelle
      endif.
      if not s_coabl-ps_psp_pnr is initial.
         vbap-ps_psp_pnr = s_coabl-ps_psp_pnr.       "CO-PSP-Element
      endif.

   endif.
  endloop." at t_coabl into s_coabl.
 endif."lw_lines > 0 and lw_subrc eq 0.
*======================================================================*
*======================================================================*
*             Generelle Ableitung ohne VKORG und VTWEG                 *
*======================================================================*
*======================================================================*
If lw_param_generell eq c_activ_x.
*       lesen generelle Ableitungstabelle ohne Löschkennz.
 refresh t_coabl. clear s_coabl.
 select * from zsd_mv45_co_abl into table t_coabl
         where vkorg eq c_blank_vkorg
           and vtweg eq c_blank_vtweg
           and loevm eq c_blank.
*   Prüfen ob alles i.O. und ob Einträge gefunden wurden.
 if sy-subrc eq 0.
   DESCRIBE TABLE t_coabl lines lw_lines.
 else.
    lw_subrc = sy-subrc.
 endif.

 if lw_lines > 0 and lw_subrc = 0.
* hier geht es nur weiter, wenn etwas korrekt gelesen wurde !!!

  loop at t_coabl into s_coabl.
*    Prüfen auf die 3 Schlüssel, aber nur wenn nicht leer...
*** =============================================================== ***
***     Produkthierarchie                                           ***
*** =============================================================== ***
   if     vbap-prodh eq s_coabl-prodh
      and not s_coabl-prodh is initial.
*       niedrigste Prio, d.h. MATNR übersteuert ggf. die Prod.hierarchie
      if not s_coabl-aufnr is initial.
         vbap-aufnr = s_coabl-aufnr.                 "CO-Innenauftrag
      endif.
      if not s_coabl-kostl is initial.
         vbap-kostl = s_coabl-kostl.                 "CO-Kostenstelle
      endif.
      if not s_coabl-ps_psp_pnr is initial.
         vbap-ps_psp_pnr = s_coabl-ps_psp_pnr.       "CO-PSP-Element
      endif.
*** =============================================================== ***
***     Warengruppe                                                 ***
*** =============================================================== ***
   elseif vbap-matkl eq s_coabl-matkl
      and not s_coabl-matkl is initial.
*       nächst höhere Prio, direkt unter MATNR, übersteuert die Prodhi.
      if not s_coabl-aufnr is initial.
         vbap-aufnr = s_coabl-aufnr.                 "CO-Innenauftrag
      endif.
      if not s_coabl-kostl is initial.
         vbap-kostl = s_coabl-kostl.                 "CO-Kostenstelle
      endif.
      if not s_coabl-ps_psp_pnr is initial.
         vbap-ps_psp_pnr = s_coabl-ps_psp_pnr.       "CO-PSP-Element
      endif.

*** =============================================================== ***
***     Material-Nummer                                             ***
*** =============================================================== ***
   elseif vbap-matnr eq s_coabl-matnr
      and not s_coabl-matnr is initial.
*         höchste Priorität, da höchste Detaillierung übersteuert alles
      if not s_coabl-aufnr is initial.
         vbap-aufnr = s_coabl-aufnr.                 "CO-Innenauftrag
      endif.
      if not s_coabl-kostl is initial.
         vbap-kostl = s_coabl-kostl.                 "CO-Kostenstelle
      endif.
      if not s_coabl-ps_psp_pnr is initial.
         vbap-ps_psp_pnr = s_coabl-ps_psp_pnr.       "CO-PSP-Element
      endif.

   endif.
  endloop." at t_coabl into s_coabl.
 endif."lw_lines > 0 and lw_subrc eq 0.
endif."lw_param_generell eq c_activ_x.
