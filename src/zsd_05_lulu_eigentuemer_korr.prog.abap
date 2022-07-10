*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_EIGENTUEMER_KORR
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZSD_05_LULU_EIGENTUEMER_KORR.

tables: ZSD_05_kehr_auft
      .

*>>>>>>>>>>>>>>> S e l e c t i o n   S c r e e n >>>>>>>>>>>>>>>>>>>>>>*

Parameters:    p_Simu      RADIOBUTTON GROUP Echt
          ,    p_Echt      RADIOBUTTON GROUP Echt
          .

SELECT-OPTIONS:  s_faknr for zsd_05_kehr_auft-faknr
              ,  s_fkdat for zsd_05_kehr_auft-fkdat
              ,  s_kunnr for zsd_05_kehr_auft-kunnr
              .
*<<<<<<<<<<<<<<< S e l e c t i o n   S c r e e n <<<<<<<<<<<<<<<<<<<<<<*

* ------------- W o r k i n g    S t o r a g e  (in COBOL) :-) --------*
data:     t_k_auft        type TABLE OF zsd_05_kehr_auft
    ,     w_k_auft        like LINE OF  t_k_auft
    ,     t_kauft_upd     type TABLE OF zsd_05_kehr_auft
    ,     t_kauft_io      type TABLE OF zsd_05_kehr_auft
    ,     w_vbrk          type          vbrk
    ,     w_lines         type i
    ,     w_lines_upd     type i
    ,     w_lines_io      type i
    ,     w_ftext(255)    type c
    ,     w_fvariabel(10) type c
    .
data:     c_warn          type c        value 'W'
    ,     c_error         type c        value 'E'
    ,     c_info          type c        value 'I'
    ,     c_activ         type c        value 'X'
    ,     c_inactiv       type c        value ' '
    .
*=============== S t a r t   o f   S e l e c t i o n ==================*
START-OF-SELECTION.
*=============== S t a r t   o f   S e l e c t i o n ==================*
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  select * from zsd_05_kehr_auft into table t_k_auft
           where faknr in s_faknr
           and   fkdat in s_fkdat
           and   kunnr in s_kunnr.
  if sy-subrc ne 0.
     MESSAGE text-E01 type c_error.
     exit.
  endif.
  DESCRIBE TABLE t_k_auft lines w_lines.
  clear w_ftext.
  move text-I01 to w_ftext.
  write w_lines to w_fvariabel.
  replace '&1' in w_ftext with w_fvariabel.
  condense w_ftext.
  Message w_ftext type c_info .
*=================== E n d   o f   S e l e c t i o n ==================*
end-of-SELECTION.
*=================== E n d   o f   S e l e c t i o n ==================*
 check sy-subrc eq 0.
 data: lw_kunrg        like vbrk-kunrg.
 loop at t_k_auft into w_k_auft.
  clear lw_kunrg.
  perform u0100_get_kunrg_aus_vbrk using    w_k_auft
                                   changing lw_kunrg.

  if not lw_kunrg is initial.
     w_k_auft-kunnr = lw_kunrg.
     if p_echt eq c_activ.
*       Echtverarbeitung wurde gewählt
        modify zsd_05_kehr_auft from w_k_auft.
        append w_k_auft to t_kauft_upd.
     else.
        append w_k_auft to t_kauft_upd.
     endif.
  else.
     append w_k_auft to t_kauft_io.
  endif.

 endloop. "at t_k_auft into w_k_auft.

 describe table t_kauft_io  lines w_lines_io.
 describe table t_kauft_upd lines w_lines_upd.

 if w_lines eq w_lines_io.
*   alles Bestens, nix wurde geändert !!!
    skip 2.
    move text-i09 to w_ftext.
    write w_lines to w_fvariabel.
    replace '&1' with w_fvariabel into w_ftext.
    write: / w_ftext.
    uline.
    write: / sy-datum, '  /  ', sy-uzeit,  '  /  ',
             sy-sysid, '  /  ', sy-host.
 else.
    if     p_echt eq c_activ.
       skip 2.
       write: / text-u01.
       clear w_fvariabel.
       write w_lines_upd to w_fvariabel.
       move text-u02 to w_ftext.
       replace '&1' with w_fvariabel into w_ftext.
       condense w_ftext.
       write: / w_ftext.
       clear w_fvariabel.
       write w_lines_io  to w_fvariabel.
       move text-u03 to w_ftext.
       replace '&1' with w_fvariabel into w_ftext.
       condense w_ftext.
       write: / w_ftext.
       write: / text-u01.
       uline.
       write: / sy-datum, '  /  ', sy-uzeit,  '  /  ',
                sy-sysid, '  /  ', sy-host.
    elseif p_simu eq c_activ.
       skip 2.
       write: / text-s01.
       clear w_fvariabel.
       write w_lines_upd to w_fvariabel.
       move text-s02 to w_ftext.
       replace '&1' with w_fvariabel into w_ftext.
       condense w_ftext.
       write: / w_ftext.
       clear w_fvariabel.
       write w_lines_io  to w_fvariabel.
       move text-s03 to w_ftext.
       replace '&1' with w_fvariabel into w_ftext.
       condense w_ftext.
       write: / w_ftext.
       write: / text-s01.
       uline.
       write: / sy-datum, '  /  ', sy-uzeit,  '  /  ',
                sy-sysid, '  /  ', sy-host.
    endif.
 endif.
*=================== Unterprogramm-Bibliothek =========================*
form u0100_get_kunrg_aus_vbrk using    lw_k_auft type zsd_05_kehr_auft
                              changing lw_kunrg like vbrk-kunrg.

 data: lw_vbeln_vf      like vbrk-vbeln
     , lw_len_faknr     type i
     .

 lw_len_faknr = strlen( lw_k_auft-faknr ).
 if lw_len_faknr < 10.
    lw_vbeln_vf = lw_k_auft-faknr.
    do.
     if strlen( lw_vbeln_vf ) eq 10.
        exit.
     else.
        concatenate '0' lw_vbeln_vf into lw_vbeln_vf.
        condense lw_vbeln_vf.
     endif.
    enddo.
 endif.
 select single * from vbrk into w_vbrk
                 where vbeln eq lw_k_auft-faknr.
 if sy-subrc eq 0.
  if w_vbrk-kunrg eq lw_k_auft-kunnr.
*    alles Bestens, nix ist zu machen ...
     clear lw_kunrg.
  else.
     lw_kunrg = w_vbrk-kunrg.
  endif.
 endif.

endform." u0100_get_kunrg_aus_vbrk using    w_k_auft-faknr
        "                          changing lw_kunrg.
*=================== Unterprogramm-Bibliothek =========================*
* >>>>>>>>>>>>>>>>>>    T h e    E n d        <<<<<<<<<<<<<<<<<<<<<<<<<*
