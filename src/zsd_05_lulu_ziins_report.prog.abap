*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_ZIINS_REPORT
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

*======================================================================*
REPORT ZSD_05_LULU_ZIINS_REPORT.
*======================================================================*

*======================================================================*
tables:   zsd_05_lulu_head           "Gesuche-Kopftabelle
      ,   zsd_05_lulu_fakt           "Gesuche-Fakturazuordnungstabelle
      ,   zsd_05_kehr_aufz           "Tabelle mit Faktura und Zinsdaten
      .

data:     t_fakt            type table of zsd_05_lulu_fakt
    ,     s_fakt            like line of t_fakt
    ,     t_aufz            type table of zsd_05_kehr_aufz
    ,     s_aufz            like line of t_aufz
    ,     t_outlist         type table of ZSD_05_LULU_ZINSLIST
    ,     s_outlist         like line of t_outlist
    ,     lt_outlist        like table of ZSD_05_LULU_ZINSLIST
    ,     ls_outlist        like line of lt_outlist
    ,     lt_zinstab        type table of ZSD_05_LULU_VZI
    ,     w_lines           type i
    ,     w_alv_struc       type TABNAME  value 'ZSD_05_KEHR_AUFZ'
    ,     w_alv_struc2      type TABNAME  value 'ZSD_05_LULU_ZINSLIST'
    ,     lw_kz_ge_fa       type char1
    ,     lw_rubtr_brt      type zz_rubtr
    ,     c_check_dat       type fkdat    value '20101231'.
    .

*======================================================================*
parameters: p_fallnr           type zsd_05_lulu_head-fallnr
          , p_objkey           type zsd_05_kehr_aufz-obj_key
                               MATCHCODE OBJECT ZSDOBJ
          , p_faknr            type zsd_05_kehr_aufz-faknr
                               MATCHCODE OBJECT ZSDH_05_KEHR_AUFT_LULU
          .

*======================================================================*
start-OF-SELECTION.
*======================================================================*
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's

 if not p_fallnr is initial.
*   Verarbeitung über Fall-Nummer aus den Gesuchen !!!
    select * from zsd_05_lulu_fakt into table t_fakt
             where fallnr eq p_fallnr.
    if sy-subrc eq 0.
       loop at t_fakt into s_fakt.
        if strlen( s_fakt-vbeln ) eq 9.
           move: s_fakt-vbeln(9) to s_fakt-vbeln+1(9)
               , '0'             to s_fakt-vbeln+0(1).
           modify t_fakt from s_fakt.
        endif.
       endloop. "t_fakt into s_fakt.
       select * from zsd_05_kehr_aufz into table t_aufz
                FOR ALL ENTRIES IN t_fakt
                where faknr eq t_fakt-vbeln.
    endif.
 elseif not p_objkey is initial.
*   Verarbeitung über Objekt-Key, d.h. alle Fakturen auflisten !!!
    select * from zsd_05_kehr_aufz into table t_aufz
             where obj_key eq p_objkey.
 elseif not p_faknr is initial.
*   Verarbeitung nur über eine einzelne Faktura auflisten !!!
    select * from zsd_05_kehr_aufz into table t_aufz
             where faknr eq p_faknr.

    refresh t_outlist. clear t_outlist.
    loop at t_aufz into s_aufz.
     if s_aufz-verr_datum_schl <= c_check_dat.
        lw_kz_ge_fa = 'G'.
     else.
        lw_kz_ge_fa = 'F'.
     endif.
     refresh lt_outlist. clear lt_outlist.
     clear lw_rubtr_brt.
     lw_rubtr_brt = s_aufz-rubtr_brt.
     CALL FUNCTION 'Z_SD_LULU_CALC_VGUZI_OUT'
       EXPORTING
         i_von_datum         = s_aufz-fkdat
         i_bis_datum         = s_aufz-RUE_BASIS_DT
         i_grundbetrag       = lw_rubtr_brt
         I_KZ_GE_FA          = lw_kz_ge_fa
*        I_KZ_ZINSZINS       = 'X'
*      IMPORTING
*        E_TAGE              =
*        E_ZINS_SATZ         =
*        E_ZINS_BETRAG       =
       TABLES
         t_zinstab           = lt_zinstab
         t_outlist           = lt_outlist
               .
     loop at lt_outlist into ls_outlist.
      move: s_aufz-faknr    to ls_outlist-faknr
          , s_aufz-fakpo    to ls_outlist-posnr.
      append ls_outlist to t_outlist.
      modify lt_outlist from ls_outlist.
     endloop. "at lt_outlist.
    endloop.
 else.
*   welch ein Schwachsinn, nix angegeben ... eine nette Meldung halt !!!
    sy-subrc = 12.
    message text-f00 type 'E'.
 endif.

*======================================================================*
end-of-SELECTION.
*======================================================================*
 if sy-subrc eq 12. "nix ausgewählt, wie bl....
    stop.
 endif.
 describe table t_aufz lines w_lines.
 if w_lines eq 0.
    message text-f01 type 'I'.
 else.
    describe table t_outlist lines w_lines.
    if w_lines eq 0.
       CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
         I_STRUCTURE_NAME                  = w_alv_struc
*       IMPORTING
*        E_EXIT_CAUSED_BY_CALLER           =
        TABLES
         T_OUTTAB                          = t_aufz
*       EXCEPTIONS
*       PROGRAM_ERROR                     = 1
*       OTHERS                            = 2
          .
       IF SY-SUBRC <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
       ENDIF.
    else.
       CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
         I_STRUCTURE_NAME                  = w_alv_struc2
*       IMPORTING
*        E_EXIT_CAUSED_BY_CALLER           =
        TABLES
         T_OUTTAB                          = t_outlist
*       EXCEPTIONS
*       PROGRAM_ERROR                     = 1
*       OTHERS                            = 2
          .
       IF SY-SUBRC <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
       ENDIF.
    endif.
 endif.
