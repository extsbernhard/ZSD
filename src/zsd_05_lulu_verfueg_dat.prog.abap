*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_VERFUEG_DAT
*&
*----------------------------------------------------------------------*
*                                                                      *
*            P R O G R A M M D O K U M E N T A T I O N                 *
*                                                                      *
*----------------------------------------------------------------------*
*               W E R  +  W A N N                                      *
*--------------+-------------------------------+-----------------------*
* Entwickler   | Oliver Epking        Firma    | Alsinia GmbH          *
* Tel.Nr.      |                     Natel     | 079 698 00 26         *
* E-Mail       |                                                       *
* Erstelldatum | 19.12.2013          Fertigdat.|                       *
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
* Kurz-        | Massenmutation des KEHR_AUFZ-Daten aus den Verfügungs-*
* Beschreibung | Daten                                                 *
* Funktionen   |                                                       *
*              |                                                       *
* Input        |                                                       *
*              |                                                       *
* Output       |                                                       *
*              |                                                       *
*--------------+-------------------------------------------------------*

*----------------------Aenderungsdokumentation-------------------------
* Edition  SAP-Rel.  Datum        Bearbeiter
*          Beschreibung
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*

REPORT zsd_05_lulu_verfueg_dat MESSAGE-ID zsd_05_lulu.

tables: ZSD_05_T_PRINTL
      , zsd_05_kehr_aufz
      .
data: t_printl               type TABLE OF zsd_05_t_printl
    , w_printl               type zsd_05_t_printl
    , w_lines                type i
    , w_anzahl               type i
    , w_kaufz                type zsd_05_kehr_aufz
    , s_kaufz                type zsd_05_kehr_aufz
    .



SELECTION-SCREEN BEGIN OF BLOCK sel_kehr_auft WITH FRAME TITLE
text-t01.
 SELECT-OPTIONS: s_fallnr FOR zsd_05_t_printl-fallnr.
 SELECT-OPTIONS: s_objkey FOR zsd_05_t_printl-obj_key MATCHCODE OBJECT zsdobj .
 select-options: s_faknr  for zsd_05_t_printl-vbeln.
*PARAMETERS: p_row TYPE i DEFAULT 500.
SELECTION-SCREEN END OF BLOCK sel_kehr_auft .

SELECTION-SCREEN SKIP.

AT SELECTION-SCREEN OUTPUT.

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
* Hier die Selektion für die Änderung des Fallstatus
  select * from zsd_05_t_printl into table t_printl
           where fallnr  in s_fallnr
           and   obj_key in s_objkey
           and   vbeln   in s_faknr.

  clear w_lines.
  if sy-subrc eq 0.
     describe table t_printl lines w_lines.
  endif.

END-OF-SELECTION.

  check w_lines > 0.
  loop at t_printl into w_printl.
   if not w_printl is initial.
    select single * from zsd_05_kehr_aufz into w_kaufz
           where faknr   eq w_printl-vbeln
           and   fakpo   eq w_printl-fakpo.
    if sy-subrc eq 0.
       move w_kaufz to s_kaufz.
       MOVE-CORRESPONDING w_printl to w_kaufz.
       move w_printl-vgubtr        to w_kaufz-VGUBTR_BRU.
       modify zsd_05_kehr_aufz from w_kaufz.
       add 1 to w_anzahl.
    endif.

   endif.
  endloop.

  commit work.

write: / w_anzahl, ' Datensätze wurden upgedatet '.
