*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_RUECKZ_F01
*&---------------------------------------------------------------------*

*----------------------------------------------------------------------*
form u0010_get_fall_header_data.
 data: lw_len_fallnr          type i
     , lw_fall_nr             type xblnr
     .
* dann lesen wir mal die Fälle aus ...
  if p_fibel eq c_activ.
*    nur die Einträge lesen wo der FI-Beleg gefüllt ist...
     select * from zsd_05_lulu_hd02
       into CORRESPONDING FIELDS OF TABLE t_worktab
      where aszdt   in s_aszd1
        and rkrdt   in s_rkrd1
        and vfgdt   in s_vfgd1
        and obj_key in s_objkey
        and belnr   ne space.
     check sy-subrc eq 0.
*>>> start insert >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "Epo20140924
*    wenn hier nix gelesen, dann macht das Weitere auch keinen Sinn...
     select * from bsak
       into CORRESPONDING FIELDS OF TABLE t_bsak
            FOR ALL ENTRIES IN t_worktab
      where belnr eq t_worktab-belnr
        and blart eq c_blart_KR
        and lifnr eq p_lifnr
        and xblnr in s_xblnr
        and bukrs eq c_bukrs_erb.
      describe table t_bsak lines w_bsak_lines.
     select * from bsik
       into CORRESPONDING FIELDS OF TABLE t_bsik
            FOR ALL ENTRIES IN t_worktab
      where belnr eq t_worktab-belnr
        and blart eq c_blart_KR
        and lifnr eq p_lifnr
        and xblnr in s_xblnr
        and bukrs eq c_bukrs_erb.
      describe table t_bsik lines w_bsik_lines.
     select * from bkpf
       into CORRESPONDING FIELDS OF TABLE t_bkpf
            FOR ALL ENTRIES IN t_bsak
      where belnr eq t_bsak-belnr
        and gjahr eq t_bsak-gjahr
        and blart eq t_bsak-blart
        and bukrs eq c_bukrs_erb.
     select * from bkpf
       APPENDING CORRESPONDING FIELDS OF TABLE t_bkpf
            FOR ALL ENTRIES IN t_bsik
      where belnr eq t_bsik-belnr
        and gjahr eq t_bsik-gjahr
        and blart eq t_bsik-blart
        and bukrs eq c_bukrs_erb.
      describe table t_bkpf lines w_bkpf_lines.
*    Prüfen ob FI-Beleg auch echt vorhanden => dann BLART <> Space
     if w_bkpf_lines eq 0. "wenn nix FI-Beleg, dann alles löschen ...
        refresh t_worktab.
        clear: t_worktab, s_worktab.
     endif.
     loop at t_worktab into s_worktab.
*     fall-Nummer aufbereiten auf 8stellen ....
      clear lw_len_fallnr.
      write s_worktab-fallnr to lw_fall_nr.
      lw_len_fallnr = strlen( lw_fall_nr ).
      if lw_len_fallnr < 8.
         do.
          concatenate '0' lw_fall_nr into lw_fall_nr.
          condense lw_fall_nr no-gaps.
          if strlen( lw_fall_nr ) = 8.
             exit.
          endif.
         enddo.
      endif.
      read table t_bkpf into s_bkpf
        with key belnr = s_worktab-belnr
                 xblnr = lw_fall_nr
                 bukrs = c_bukrs_erb.
      if sy-subrc ne 0.
         delete t_worktab.
         clear s_worktab.
      else.
         move-CORRESPONDING s_bkpf to s_worktab.
         if w_bsak_lines > 0.
            read table t_bsak into s_bsak
              with key belnr = s_worktab-belnr
                       xblnr = s_worktab-xblnr
                       gjahr = s_worktab-gjahr
                       bukrs = s_worktab-bukrs.
            if sy-subrc eq 0.
               MOVE-CORRESPONDING s_bsak to s_worktab.
            else.
               if p_ausgl eq c_activ. "nur ausgegl. Belege gewünscht
                  delete t_worktab.
                  clear  s_worktab.
               endif.
            endif.
         elseif w_bsik_lines > 0.
            read table t_bsik into s_bsik
              with key belnr = s_worktab-belnr
                       xblnr = s_worktab-xblnr
                       gjahr = s_worktab-gjahr
                       bukrs = s_worktab-bukrs.
            if sy-subrc eq 0.
               MOVE-CORRESPONDING s_bsik to s_worktab.
            endif.
         else.
            sy-subrc = 4.
         endif.
         if not s_worktab is initial.
            modify t_worktab from s_worktab.
         endif.
      endif.
     endloop. "t_worktab...
*<<< end of insert <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "Epo20140924
**    wenn hier nix gelesen, dann macht das Weitere auch keinen Sinn...
*     select * from bsak
*       into CORRESPONDING FIELDS OF TABLE t_bsak
*            FOR ALL ENTRIES IN t_worktab
*      where belnr eq t_worktab-belnr
*        and cpudt eq t_worktab-aszdt                      "EPO20140917
**        and budat eq t_worktab-aszdt
*        and bukrs eq c_bukrs_erb.
*      DESCRIBE TABLE t_bsak lines w_bsak_lines.
*     select * from bkpf
*       into CORRESPONDING FIELDS OF TABLE t_bkpf
*            FOR ALL ENTRIES IN t_worktab
*      where belnr eq t_worktab-belnr
*        and cpudt eq t_worktab-aszdt                      "EPO20140917
**        and budat eq t_worktab-aszdt
*        and bukrs eq c_bukrs_erb.
*      DESCRIBE TABLE t_bkpf lines w_bkpf_lines.
**    Prüfen ob FI-Beleg auch echt vorhanden => dann BLART <> Space
*     loop at t_worktab into s_worktab.
*      if w_bkpf_lines > 0.
*       read table t_bkpf into s_bkpf
*         with key belnr = s_worktab-belnr
*                  cpudt = s_worktab-aszdt
*                  bukrs = c_bukrs_erb.
*       if sy-subrc ne 0.
*          delete t_worktab.
*          clear s_worktab.
*       else.
*          move-CORRESPONDING s_bkpf to s_worktab.
*        if w_bsak_lines > 0.
*         read table t_bsak into s_bsak
*           with key belnr = s_worktab-belnr
*                    gjahr = s_worktab-gjahr
*                    bukrs = s_worktab-bukrs.
*        else.
*           sy-subrc = 4.
*        endif.
*         if sy-subrc eq 0.
*            MOVE-CORRESPONDING s_bsak to s_worktab.
*         else.
*            if p_ausgl eq c_activ. "nur ausgeglichene Belege gewünscht
*               delete t_worktab.
*               clear  s_worktab.
*            endif.
*         endif.
*       endif.
*       if not s_worktab is initial.
*          modify t_worktab from s_worktab.
*       endif.
*      endif.
*     endloop. "t_worktab...
  else.
*    Also nur Datumseinschränkungen sind wirklich wichtig... schön !!!
     select * from zsd_05_lulu_hd02
       into CORRESPONDING FIELDS OF TABLE t_worktab
      where aszdt in s_aszd1
        and rkrdt in s_rkrd1
        and vfgdt in s_vfgd1
        and obj_key in s_objkey.
*>>> start insert >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "Epo20140924
     check sy-subrc eq 0.
*    wenn hier nix gelesen, dann macht das Weitere auch keinen Sinn...
     select * from bsak
       into CORRESPONDING FIELDS OF TABLE t_bsak
            FOR ALL ENTRIES IN t_worktab
      where belnr eq t_worktab-belnr
        and blart eq c_blart_KR
        and lifnr eq p_lifnr
        and xblnr in s_xblnr
        and bukrs eq c_bukrs_erb.
      describe table t_bsak lines w_bsak_lines.
     select * from bsik
       into CORRESPONDING FIELDS OF TABLE t_bsik
            FOR ALL ENTRIES IN t_worktab
      where belnr eq t_worktab-belnr
        and blart eq c_blart_KR
        and lifnr eq p_lifnr
        and xblnr in s_xblnr
        and bukrs eq c_bukrs_erb.
      describe table t_bsik lines w_bsik_lines.
     select * from bkpf
       into CORRESPONDING FIELDS OF TABLE t_bkpf
            FOR ALL ENTRIES IN t_bsak
      where belnr eq t_bsak-belnr
        and gjahr eq t_bsak-gjahr
        and blart eq t_bsak-blart
        and bukrs eq c_bukrs_erb.
     select * from bkpf
       APPENDING CORRESPONDING FIELDS OF TABLE t_bkpf
            FOR ALL ENTRIES IN t_bsik
      where belnr eq t_bsik-belnr
        and gjahr eq t_bsik-gjahr
        and blart eq t_bsik-blart
        and bukrs eq c_bukrs_erb.
      describe table t_bkpf lines w_bkpf_lines.
     loop at t_worktab into s_worktab.
*     fall-Nummer aufbereiten auf 8stellen ....
      clear lw_len_fallnr.
      write s_worktab-fallnr to lw_fall_nr.
      lw_len_fallnr = strlen( lw_fall_nr ).
      if lw_len_fallnr < 8.
         do.
          concatenate '0' lw_fall_nr into lw_fall_nr.
          condense lw_fall_nr no-gaps.
          if strlen( lw_fall_nr ) = 8.
             exit.
          endif.
         enddo.
      endif.
      read table t_bkpf into s_bkpf
        with key belnr = s_worktab-belnr
                 xblnr = lw_fall_nr
                 bukrs = c_bukrs_erb.
      if sy-subrc ne 0.
         delete t_worktab.
         clear s_worktab.
      else.
         move-CORRESPONDING s_bkpf to s_worktab.
         if w_bsak_lines > 0.
            read table t_bsak into s_bsak
              with key belnr = s_worktab-belnr
                       xblnr = s_worktab-xblnr
                       gjahr = s_worktab-gjahr
                       bukrs = s_worktab-bukrs.
            if sy-subrc eq 0.
               MOVE-CORRESPONDING s_bsak to s_worktab.
*            else.
*               if p_ausgl eq c_activ. "nur ausgegl. Belege gewünscht
*                  delete t_worktab.
*                  clear  s_worktab.
*               endif.
            endif.
         elseif w_bsik_lines > 0.
            read table t_bsik into s_bsik
              with key belnr = s_worktab-belnr
                       xblnr = s_worktab-xblnr
                       gjahr = s_worktab-gjahr
                       bukrs = s_worktab-bukrs.
            if sy-subrc eq 0.
               MOVE-CORRESPONDING s_bsik to s_worktab.
            endif.
*<<< end of insert <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "Epo20140924
*     select * from bkpf
*       into CORRESPONDING FIELDS OF TABLE t_bkpf
*            FOR ALL ENTRIES IN t_worktab
*      where belnr eq t_worktab-belnr
*        and cpudt eq t_worktab-aszdt                      "EPO20140917
**        and budat eq t_worktab-aszdt
*        and bukrs eq c_bukrs_erb.
*      DESCRIBE TABLE t_bkpf lines w_bkpf_lines.
*     select * from bsak
*       into CORRESPONDING FIELDS OF TABLE t_bsak
*            FOR ALL ENTRIES IN t_worktab
*      where belnr eq t_worktab-belnr
*        and cpudt eq t_worktab-aszdt                      "EPO20140917
**        and budat eq t_worktab-aszdt
*        and bukrs eq c_bukrs_erb.
*      DESCRIBE TABLE t_bsak lines w_bsak_lines.
*     loop at t_worktab into s_worktab.
*      if w_bkpf_lines > 0.
*       read table t_bkpf into s_bkpf
*         with key belnr = s_worktab-belnr
*                  cpudt = s_worktab-aszdt
*                  bukrs = c_bukrs_erb.
*       if sy-subrc ne 0.
**         clear: s_worktab-bukrs, s_worktab-blart, s_worktab-gjahr.
*       else.
*        if w_bsak_lines > 0.
*          move-CORRESPONDING s_bkpf to s_worktab.
*          read table t_bsak into s_bsak
*            with key belnr = s_worktab-belnr
*                     cpudt = s_worktab-aszdt
*                     bukrs = c_bukrs_erb..
*           if sy-subrc eq 0.
*              MOVE-CORRESPONDING s_bsak to s_worktab.
*           else.
**             clear: s_worktab-augbl,s_worktab-augdt, s_worktab-lifnr.
*           endif.
*        endif.
        modify t_worktab from s_worktab.
       endif.
      endif.
     endloop. "t_worktab...
*
  endif.
  free t_bsak.
endform." u0010_get_fall_header_data.
*----------------------------------------------------------------------*
form u0015_get_fk02_data.
*
 data: lw_vbeln        type vbeln_vf
     , lw_last_fallnr  type ZSDEKPFALLNR
     .
*
 describe table t_worktab lines w_lines.
 check w_lines > 0.
*
 select * from zsd_05_lulu_fk02
   into CORRESPONDING FIELDS OF TABLE t_worktfak
        for ALL ENTRIES IN t_worktab
   where fallnr eq t_worktab-fallnr.
 check sy-subrc eq 0.
 clear lw_last_fallnr.
 loop at t_worktfak into s_worktfak.
  if strlen( s_worktfak-vbeln ) < 10.
*    dann muss das mit führenden Nullen gefüllt werden !!!
     lw_vbeln = s_worktfak-vbeln.
     do.
      if strlen( lw_vbeln ) eq 10.
         move lw_vbeln to s_worktfak-vbeln.
         exit.
      else.
       concatenate '0' lw_vbeln(9) into lw_vbeln.
       condense lw_vbeln.
      endif.
     enddo.
  endif.
  if s_worktfak-fallnr ne lw_last_fallnr.
     read table t_worktab into s_worktab
       with key fallnr = s_worktfak-fallnr.
      if sy-subrc eq 0.
         move s_worktab-obj_key to s_worktfak-obj_key.
         move s_worktfak-fallnr  to lw_last_fallnr.
      else.
         clear                     s_worktfak-obj_key.
      endif.
  else.
     move s_worktab-obj_key to s_worktfak-obj_key.
  endif.
  modify t_worktfak from s_worktfak.
 endloop.
*
endform." u0015_get_fk02_data.
*----------------------------------------------------------------------*
form u0020_get_gesuch_header_data.
 data: lw_len_fallnr          type i
     , lw_fall_nr             type xblnr
     .
* dann lesen wir mal die Gesuche aus ...
  if p_fibel eq c_activ.
*    nur die Einträge lesen wo der FI-Beleg gefüllt ist...
     select * from zsd_05_lulu_head
       into CORRESPONDING FIELDS OF TABLE t_worktab
      where aszdt   in s_aszd1
        and rkrdt   in s_rkrd1
        and vfgdt   in s_vfgd1
        and obj_key in s_objkey
        and belnr   ne space.
     check sy-subrc eq 0.
*    wenn hier nix gelesen, dann macht das Weitere auch keinen Sinn...
     select * from bsak
       into CORRESPONDING FIELDS OF TABLE t_bsak
            FOR ALL ENTRIES IN t_worktab
      where belnr eq t_worktab-belnr
*        and cpudt eq t_worktab-aszdt
        and blart eq c_blart_KR                           "Epo20140924
        and lifnr eq p_lifnr                              "Epo20140924
        and xblnr in s_xblnr                              "Epo20140924
*        and budat eq t_worktab-aszdt
        and bukrs eq c_bukrs_erb.
      describe table t_bsak lines w_bsak_lines.
*>>> start insert >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "Epo20140924
     select * from bsik
       into CORRESPONDING FIELDS OF TABLE t_bsik
            FOR ALL ENTRIES IN t_worktab
      where belnr eq t_worktab-belnr
*        and cpudt eq t_worktab-aszdt
        and blart eq c_blart_KR
        and lifnr eq p_lifnr
        and xblnr in s_xblnr
*        and budat eq t_worktab-aszdt
        and bukrs eq c_bukrs_erb.
      describe table t_bsik lines w_bsik_lines.
*<<< end of insert <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "Epo20140924
     select * from bkpf
       into CORRESPONDING FIELDS OF TABLE t_bkpf
            FOR ALL ENTRIES IN t_bsak                      "Epo20140924
      where belnr eq t_bsak-belnr
*        and cpudt eq t_worktab-aszdt                      "EPO20140917
*        and budat eq t_worktab-aszdt                      "Epo20140924
        and gjahr eq t_bsak-gjahr                          "Epo20140924
        and blart eq t_bsak-blart                          "Epo20140924
        and bukrs eq c_bukrs_erb.
*>>> start insert >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "Epo20140924
     select * from bkpf
       APPENDING CORRESPONDING FIELDS OF TABLE t_bkpf
            FOR ALL ENTRIES IN t_bsik
      where belnr eq t_bsik-belnr
        and gjahr eq t_bsik-gjahr
        and blart eq t_bsik-blart
        and bukrs eq c_bukrs_erb.
*<<< end of insert <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "Epo20140924
      describe table t_bkpf lines w_bkpf_lines.
*    Prüfen ob FI-Beleg auch echt vorhanden => dann BLART <> Space
     if w_bkpf_lines eq 0. "wenn nix FI-Beleg, dann alles löschen ...
        refresh t_worktab.
        clear: t_worktab, s_worktab.
     endif.
     loop at t_worktab into s_worktab.
*>>> start insert >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "Epo20140924
*     fall-Nummer aufbereiten auf 8stellen ....
      clear lw_len_fallnr.
      write s_worktab-fallnr to lw_fall_nr.
      lw_len_fallnr = strlen( lw_fall_nr ).
      if lw_len_fallnr < 8.
         do.
          concatenate '0' lw_fall_nr into lw_fall_nr.
          condense lw_fall_nr no-gaps.
          if strlen( lw_fall_nr ) = 8.
             exit.
          endif.
         enddo.
      endif.
*<<< end of insert <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "Epo20140924
      read table t_bkpf into s_bkpf
        with key belnr = s_worktab-belnr
                 xblnr = lw_fall_nr                       "Epo20140924
                 bukrs = c_bukrs_erb.
      if sy-subrc ne 0.
         delete t_worktab.
         clear s_worktab.
      else.
         move-CORRESPONDING s_bkpf to s_worktab.
         if w_bsak_lines > 0.
            read table t_bsak into s_bsak
              with key belnr = s_worktab-belnr
                       xblnr = s_worktab-xblnr            "Epo20140924
                       gjahr = s_worktab-gjahr
                       bukrs = s_worktab-bukrs.
            if sy-subrc eq 0.
               MOVE-CORRESPONDING s_bsak to s_worktab.
            else.
               if p_ausgl eq c_activ. "nur ausgegl. Belege gewünscht
                  delete t_worktab.
                  clear  s_worktab.
               endif.
            endif.
*>>> start insert >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "Epo20140924
         elseif w_bsik_lines > 0.
            read table t_bsik into s_bsik
              with key belnr = s_worktab-belnr
                       xblnr = s_worktab-xblnr
                       gjahr = s_worktab-gjahr
                       bukrs = s_worktab-bukrs.
            if sy-subrc eq 0.
               MOVE-CORRESPONDING s_bsik to s_worktab.
            endif.
*<<< end of insert <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "Epo20140924
         else.
            sy-subrc = 4.
         endif.
         if not s_worktab is initial.
            modify t_worktab from s_worktab.
         endif.
      endif.
     endloop. "t_worktab...
  else.
*    Also nur Datumseinschränkungen sind wirklich wichtig... schön !!!
     select * from zsd_05_lulu_head
       into CORRESPONDING FIELDS OF TABLE t_worktab
      where aszdt in s_aszd1
        and rkrdt in s_rkrd1
        and vfgdt in s_vfgd1
        and obj_key in s_objkey.
*>>> start insert >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "Epo20140924
     check sy-subrc eq 0.
*    wenn hier nix gelesen, dann macht das Weitere auch keinen Sinn...
     select * from bsak
       into CORRESPONDING FIELDS OF TABLE t_bsak
            FOR ALL ENTRIES IN t_worktab
      where belnr eq t_worktab-belnr
        and blart eq c_blart_KR
        and lifnr eq p_lifnr
        and xblnr in s_xblnr
        and bukrs eq c_bukrs_erb.
      describe table t_bsak lines w_bsak_lines.
     select * from bsik
       into CORRESPONDING FIELDS OF TABLE t_bsik
            FOR ALL ENTRIES IN t_worktab
      where belnr eq t_worktab-belnr
        and blart eq c_blart_KR
        and lifnr eq p_lifnr
        and xblnr in s_xblnr
        and bukrs eq c_bukrs_erb.
      describe table t_bsik lines w_bsik_lines.
     select * from bkpf
       into CORRESPONDING FIELDS OF TABLE t_bkpf
            FOR ALL ENTRIES IN t_bsak
      where belnr eq t_bsak-belnr
        and gjahr eq t_bsak-gjahr
        and blart eq t_bsak-blart
        and bukrs eq c_bukrs_erb.
     select * from bkpf
       APPENDING CORRESPONDING FIELDS OF TABLE t_bkpf
            FOR ALL ENTRIES IN t_bsik
      where belnr eq t_bsik-belnr
        and gjahr eq t_bsik-gjahr
        and blart eq t_bsik-blart
        and bukrs eq c_bukrs_erb.
      describe table t_bkpf lines w_bkpf_lines.
     loop at t_worktab into s_worktab.
*     fall-Nummer aufbereiten auf 8stellen ....
      clear lw_len_fallnr.
      write s_worktab-fallnr to lw_fall_nr.
      lw_len_fallnr = strlen( lw_fall_nr ).
      if lw_len_fallnr < 8.
         do.
          concatenate '0' lw_fall_nr into lw_fall_nr.
          condense lw_fall_nr no-gaps.
          if strlen( lw_fall_nr ) = 8.
             exit.
          endif.
         enddo.
      endif.
      read table t_bkpf into s_bkpf
        with key belnr = s_worktab-belnr
                 xblnr = lw_fall_nr
                 bukrs = c_bukrs_erb.
      if sy-subrc ne 0.
         delete t_worktab.
         clear s_worktab.
      else.
         move-CORRESPONDING s_bkpf to s_worktab.
         if w_bsak_lines > 0.
            read table t_bsak into s_bsak
              with key belnr = s_worktab-belnr
                       xblnr = s_worktab-xblnr
                       gjahr = s_worktab-gjahr
                       bukrs = s_worktab-bukrs.
            if sy-subrc eq 0.
               MOVE-CORRESPONDING s_bsak to s_worktab.
*            else.
*               if p_ausgl eq c_activ. "nur ausgegl. Belege gewünscht
*                  delete t_worktab.
*                  clear  s_worktab.
*               endif.
            endif.
         elseif w_bsik_lines > 0.
            read table t_bsik into s_bsik
              with key belnr = s_worktab-belnr
                       xblnr = s_worktab-xblnr
                       gjahr = s_worktab-gjahr
                       bukrs = s_worktab-bukrs.
            if sy-subrc eq 0.
               MOVE-CORRESPONDING s_bsik to s_worktab.
            endif.
*<<< end of insert <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "Epo20140924
*     select * from bkpf
*       into CORRESPONDING FIELDS OF TABLE t_bkpf
*            FOR ALL ENTRIES IN t_worktab
*      where belnr eq t_worktab-belnr
*        and cpudt eq t_worktab-aszdt                      "Epo20140917
**        and budat eq t_worktab-aszdt
*        and bukrs eq c_bukrs_erb.
*      describe table t_bkpf lines w_bkpf_lines.
*     select * from bsak
*       into CORRESPONDING FIELDS OF TABLE t_bsak
*            FOR ALL ENTRIES IN t_worktab
*      where belnr eq t_worktab-belnr
*        and cpudt eq t_worktab-aszdt                      "Epo20140917
**        and budat eq t_worktab-aszdt
*        and bukrs eq c_bukrs_erb.
*      describe table t_bsak lines w_bsak_lines.
*     loop at t_worktab into s_worktab.
*      if w_bkpf_lines > 0.
*       read table t_bkpf into s_bkpf
*         with key belnr = s_worktab-belnr
*                  cpudt = s_worktab-aszdt
*                  bukrs = c_bukrs_erb.
*       if sy-subrc ne 0.
**         clear: s_worktab-bukrs, s_worktab-blart, s_worktab-gjahr.
*       else.
*        if w_bsak_lines > 0.
*          move-CORRESPONDING s_bkpf to s_worktab.
*          read table t_bsak into s_bsak
*            with key belnr = s_worktab-belnr
*                     cpudt = s_worktab-aszdt
*                     bukrs = c_bukrs_erb..
*          if sy-subrc eq 0.
*             MOVE-CORRESPONDING s_bsak to s_worktab.
*          else.
**            clear: s_worktab-augbl,s_worktab-augdt, s_worktab-lifnr.
*          endif.
*        endif.
        modify t_worktab from s_worktab.
       endif.
      endif.
     endloop. "t_worktab...

  endif.
endform." u0020_get_gesuch_header_data.
*----------------------------------------------------------------------*
form u0025_get_fakt_data.
*
 data: lw_vbeln        type vbeln_vf
     , lw_last_fallnr  type ZSDEKPFALLNR
     .
*
 describe table t_worktab lines w_lines.
 check w_lines > 0.
*
 select * from zsd_05_lulu_fakt
   into CORRESPONDING FIELDS OF TABLE t_worktfak
        for ALL ENTRIES IN t_worktab
   where fallnr eq t_worktab-fallnr.
 check sy-subrc eq 0.
 clear lw_last_fallnr.
 loop at t_worktfak into s_worktfak.
  if strlen( s_worktfak-vbeln ) < 10.
*    dann muss das mit führenden Nullen gefüllt werden !!!
     lw_vbeln = s_worktfak-vbeln.
     do.
      if strlen( lw_vbeln ) eq 10.
         move lw_vbeln to s_worktfak-vbeln.
         exit.
      else.
       concatenate '0' lw_vbeln(9) into lw_vbeln.
       condense lw_vbeln.
      endif.
     enddo.
  endif.
  if s_worktfak-fallnr ne lw_last_fallnr.
     read table t_worktab into s_worktab
       with key fallnr = s_worktfak-fallnr.
      if sy-subrc eq 0.
         move s_worktab-obj_key to s_worktfak-obj_key.
         move s_worktfak-fallnr  to lw_last_fallnr.
      else.
         clear                     s_worktfak-obj_key.
      endif.
  else.
     move s_worktab-obj_key to s_worktfak-obj_key.
  endif.
  modify t_worktfak from s_worktfak.
 endloop.
*
endform." u0025_get_fakt_data.
*----------------------------------------------------------------------*
form u0040_get_info_grosskunde.
*
 data: lw_pausch      type zsd_05_lulu_pau
     , lw_last_fallnr type ZSDEKPFALLNR
     .
*
 clear lw_last_fallnr.
 loop at t_worktfak into s_worktfak.
  if s_worktfak-fallnr ne lw_last_fallnr.
     select single * from zsd_05_lulu_pau into lw_pausch
            where faknr eq s_worktfak-vbeln.
     if sy-subrc eq 0.
        loop at t_worktab into s_worktab
          where fallnr eq s_worktfak-fallnr.
*          if sy-subrc eq 0.
           move c_activ    to s_worktab-KZ_GROSSKD.
           modify t_worktab from s_worktab.
           lw_last_fallnr = s_worktab-fallnr.
*          endif.
        endloop.
     endif.
  endif.
 endloop.
*
endform." u0040_get_info_grosskunde.
*----------------------------------------------------------------------*
form u0050_get_detail_kehr_aufz.
*
 data: lw_last_fallnr    type ZSDEKPFALLNR
     , lw_rue_bas_dt     type ZZ_RU_BAS_DT
     .
*
 describe table t_worktfak lines w_lines.
*
 check w_lines > 0.
*
 select * from zsd_05_kehr_aufz
   into CORRESPONDING FIELDS OF TABLE t_worktdet
        for ALL ENTRIES IN t_worktfak
   where faknr eq t_worktfak-vbeln.
 check sy-subrc eq 0.
 clear lw_last_fallnr.
 loop at t_worktdet into s_worktdet.
  if s_worktdet-faknr eq s_worktfak-vbeln.
     MOVE s_worktfak-fallnr to s_worktdet-fallnr.
*     modify t_worktdet from s_worktdet.
  else.
     read table t_worktfak into s_worktfak
          with key vbeln = s_worktdet-faknr.
     if sy-subrc eq 0.
        MOVE s_worktfak-fallnr to s_worktdet-fallnr.
*        modify t_worktdet from s_worktdet.
     else.
        clear s_worktfak.
     endif.
  endif.
  lw_rue_bas_dt = s_worktdet-rue_basis_dt.
  if s_worktdet-fallnr ne lw_last_fallnr.
     read table t_worktab into s_worktab
       with key fallnr = s_worktdet-fallnr.
     if sy-subrc eq 0.
        MOVE-CORRESPONDING s_worktab to s_worktdet.
        lw_last_fallnr = s_worktdet-fallnr.
     endif.
  else.
     MOVE-CORRESPONDING s_worktab to s_worktdet.
  endif.
  move lw_rue_bas_dt to s_worktdet-rue_basis_dt.
  modify t_worktdet from s_worktdet.
 endloop.
*
 free t_worktfak.
*
endform." u0050_get_detail_kehr_aufz.
*----------------------------------------------------------------------*
form u0055_get_detail_fi_belnr.
*
 describe table t_worktab lines w_lines.
*
 check w_lines > 0.
*
 loop at t_worktab into s_worktab.
  if not s_worktab-belnr is initial.
     refresh t_bseg. clear t_bseg.
     select * from bseg
              APPENDING CORRESPONDING FIELDS OF table t_bseg
      where belnr eq s_worktab-belnr
        and gjahr eq s_worktab-gjahr
        and bukrs eq s_worktab-bukrs
        and bschl eq c_bschl_40.
     if sy-subrc eq 0.
        loop at t_bseg into s_bseg.
         move-CORRESPONDING s_worktab to s_worktdfi.
         MOVE-CORRESPONDING s_bseg    to s_worktdfi.
         if s_worktdfi-saknr is initial
         or s_worktdfi-saknr eq space.
            move s_bseg-hkont         to s_worktdfi-saknr.
         endif.
         append s_worktdfi to t_worktdfi.
        endloop.
     endif.
  endif.
 endloop.
*
endform." u0055_get_detail_fi_belnr.
*----------------------------------------------------------------------*
form u0100_summenliste_aufbereiten.
 data: lw_rubtr_fi    type zz_rubtr_fi
     , lw_vgubtr_fi   type zz_vgubtr_fi
     , lw_rubtr       type zz_rubtr
     , lw_vgubtr      type zz_vgubtr
     , lw_vst_fi      like bseg-dmbtr
     , lw_kst_fi      like bseg-dmbtr
     .
*
 describe table t_worktab lines w_lines.
 check w_lines > 0.
*
 describe table t_worktdet lines w_lines.
 check w_lines > 0.
*
 data: lw_sakto       type hkont.
*
 loop at t_worktab into s_worktab. "Fälle bzw. Gesuche-Kopfdaten
  clear: lw_rubtr_fi, lw_vgubtr_fi, lw_rubtr, lw_vgubtr,
         lw_kst_fi, lw_vst_fi.
  loop at t_worktdfi into s_worktdfi where fallnr eq s_worktab-fallnr.
   clear lw_sakto.
   lw_sakto = s_worktdfi-saknr.
*   if lw_sakto is initial
*   or lw_sakto eq space.
*      lw_sakto = s_worktdfi-hkont.
*   endif.
*   add s_worktdet-rubtr_brt     to lw_rubtr.
*   add s_worktdet-vgubtr_bru    to lw_vgubtr.
   case lw_sakto. "FI-Sachkonto entscheidet über Zins und Rübtr.
    when c_vorsteuerkto or c_vorsteuerkto13.
        add s_worktdfi-dmbtr        to lw_vst_fi.
    when c_kredsteuerkto or c_kredsteuerkto13.
        add s_worktdfi-dmbtr        to lw_kst_fi.
    when c_rueckzahlkto or  c_rueckzahlkto13.
     if     s_worktdfi-sgtxt cs 'Vergütungszins'.
            add s_worktdfi-dmbtr    to lw_vgubtr_fi.
     elseif s_worktdfi-sgtxt cs 'KGG'.
            add s_worktdfi-dmbtr    to lw_rubtr_fi.
     endif.
   endcase.
  endloop.
  loop at t_worktdet into s_worktdet where fallnr eq s_worktab-fallnr.
   add s_worktdet-rubtr_brt     to lw_rubtr.
   add s_worktdet-vgubtr_bru    to lw_vgubtr.
  endloop.
  move: lw_rubtr_fi      to s_worktab-rubtr_fi
      , lw_vgubtr_fi     to s_worktab-vgubtr_fi
      , lw_rubtr         to s_worktab-rubtr
      , lw_vgubtr        to s_worktab-vgubtr
      , lw_vst_fi        to s_worktab-vsttax_fi
      , lw_kst_fi        to s_worktab-ksttax_fi
      .
  s_worktab-rubtr_fi_total = lw_rubtr_fi + lw_vgubtr_fi
                           + lw_vst_fi   + lw_kst_fi.
  s_worktab-rubtr_total    = lw_rubtr    + lw_vgubtr.
  s_worktab-LFDAT	         = g_lauf_datum.
  s_worktab-LFTIM          = g_lauf_zeit.
  s_worktab-rue_basis_dt   = s_worktdet-rue_basis_dt.
  modify t_worktab from s_worktab.
  if not s_worktab is initial.
     move-CORRESPONDING s_worktab to s_sumlist.
     append s_sumlist to t_sumlist.
     clear s_sumlist.
  endif.
 endloop. "at t_worktab into s_worktab.
*
 describe table t_sumlist lines w_lines.
 free: t_worktab, t_worktdet, t_worktdfi.
*
endform." u0100_summenliste_aufbereiten.
*----------------------------------------------------------------------*
form u0200_detailliste_aufbereiten.
*
 data: lw_rubtr_fi    type zz_rubtr_fi
     , lw_vgubtr_fi   type zz_vgubtr_fi
     , lw_rubtr       type zz_rubtr
     , lw_vgubtr      type zz_vgubtr
     , lw_vst_fi      like bseg-dmbtr
     , lw_kst_fi      like bseg-dmbtr
     .
*
 describe table t_worktdet lines w_lines.
 check w_lines > 0.
*
 clear s_worktab.
 loop at t_worktdet into s_worktdet." where fallnr eq s_worktab-fallnr.
  if s_worktab-fallnr ne s_worktdet-fallnr
  or s_worktab        is initial.
     read table t_worktab into s_worktab
          with key fallnr  = s_worktdet-fallnr
                   obj_key = s_worktdet-obj_key.
     if sy-subrc eq 0.
        MOVE-CORRESPONDING s_worktab to s_detlist.
     else.
        clear s_worktab.
     endif.
  else.
     MOVE-CORRESPONDING s_worktab to s_detlist.
     move: s_worktdet-rubtr_brt   to s_detlist-rubtr
         , s_worktdet-vgubtr_bru  to s_detlist-vgubtr
         .
  endif.
  move-CORRESPONDING s_worktdet to s_detlist.
  move: s_worktdet-rubtr_brt   to s_detlist-rubtr
      , s_worktdet-vgubtr_bru  to s_detlist-vgubtr
      .
  if not s_detlist is initial.
*     move-CORRESPONDING s_worktdet to s_detlist.
     s_detlist-LFDAT           = g_lauf_datum.
     s_detlist-LFTIM          = g_lauf_zeit.
     append s_detlist to t_detlist.
     clear s_detlist.
  endif.
 endloop.
 data: lw_sakto       type hkont.
 loop at t_worktdfi into s_worktdfi." where fallnr eq s_worktab-fallnr.
  clear: s_detlist, lw_rubtr_fi, lw_vgubtr_fi, lw_vst_fi, lw_kst_fi.
  if s_worktab-fallnr ne s_worktdfi-fallnr
  or s_worktab        is initial.
     read table t_worktab into s_worktab
          with key fallnr  = s_worktdfi-fallnr
                   obj_key = s_worktdfi-obj_key.
     if sy-subrc eq 0.
        MOVE-CORRESPONDING s_worktab to s_detlist.
     else.
        clear s_worktab.
     endif.
  else.
     MOVE-CORRESPONDING s_worktab to s_detlist.
  endif.
  move-CORRESPONDING s_worktdfi to s_detlist.
  clear lw_sakto.
  lw_sakto = s_worktdfi-saknr.
  case lw_sakto. "FI-Sachkonto entscheidet über Zins und Rübtr.
    when c_vorsteuerkto or c_vorsteuerkto13.
        add s_worktdfi-dmbtr        to lw_vst_fi.
    when c_kredsteuerkto or c_kredsteuerkto13.
        add s_worktdfi-dmbtr        to lw_kst_fi.
    when c_rueckzahlkto or c_rueckzahlkto13..
     if     s_worktdfi-sgtxt cs 'Vergütungszins'.
            add s_worktdfi-dmbtr    to lw_vgubtr_fi.
     elseif s_worktdfi-sgtxt cs 'KGG'.
            add s_worktdfi-dmbtr    to lw_rubtr_fi.
     endif.
  endcase.
  move: lw_rubtr_fi      to s_detlist-rubtr_fi
      , lw_vgubtr_fi     to s_detlist-vgubtr_fi
      .
  add   lw_vst_fi        to s_detlist-taxbtr_fi.
  add   lw_kst_fi        to s_detlist-taxbtr_fi.
*  s_worktab-rubtr_fi_total = lw_rubtr_fi + lw_vgubtr_fi
*                           + lw_vst_fi   + lw_kst_fi.
  if not s_detlist is initial.
*     move-CORRESPONDING s_worktdfi to s_detlist.
     s_detlist-LFDAT           = g_lauf_datum.
     s_detlist-LFTIM          = g_lauf_zeit.
     append s_detlist to t_detlist.
     clear s_detlist.
  endif.
 endloop.
*
 describe table t_detlist lines w_lines.
 free: t_worktab, t_worktdet, t_worktdfi.
*
endform." u0200_detailliste_aufbereiten.
*----------------------------------------------------------------------*
form u6000_alv_out.
 if w_lines eq 0.
    message text-f01 type 'I'.
 else.
  case w_list_kz.
   when 'S'. "Summenliste
*    describe table t_outlist lines w_lines.
*    if w_lines eq 0.
       CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
         I_STRUCTURE_NAME                  = w_alv_struc
*       IMPORTING
*        E_EXIT_CAUSED_BY_CALLER           =
        TABLES
         T_OUTTAB                          = t_sumlist
*       EXCEPTIONS
*       PROGRAM_ERROR                     = 1
*       OTHERS                            = 2
          .
       IF SY-SUBRC <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
       ENDIF.
*    else.
   when 'D'. "Detailliste
       CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
         I_STRUCTURE_NAME                  = w_alv_struc2
*       IMPORTING
*        E_EXIT_CAUSED_BY_CALLER           =
        TABLES
         T_OUTTAB                          = t_detlist
*       EXCEPTIONS
*       PROGRAM_ERROR                     = 1
*       OTHERS                            = 2
          .
       IF SY-SUBRC <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
       ENDIF.
*    endif.
   when others.
*
  endcase. "w_list_kz.
 endif.
endform." u6000_alv_out.
*----------------------------------------------------------------------*
