*&---------------------------------------------------------------------*
*&  Include           ZSD_MV45AFZZ_01
*&---------------------------------------------------------------------*
* include zum User-Exit MV45AFZZ
tables: ZSD_MV45_ZABGRU
      , ZSD_MV45_ZPSTYV
      , ZSD_MV45_ZUSCHL
      .

data: w_sumbetr     type ZSD_BISBETR
    , w_zusbetr     type ZSD_BISBETR
    , w_grpstyv     type pstyv
    , w_lines       type i
    .
data: t_zpstyv      type table of pstyv           with header line
    , t_ZSCHLTYP    type table of zsd_ZSCHLTYP    with header line
    , t_zuschl      type table of zsd_mv45_zuschl with header line
    .
data: begin of t_ztyp_wert occurs 0
    , zschltyp      type zsd_zschltyp
    , zusbetr       type zsd_bisbetr
    , end   of t_ztyp_wert
    .
data: w_ztyp_wert   like t_ztyp_wert.
* ermitteln ob Zuschläge relevant für diesen Auftrag
 refresh t_zuschl. clear t_zuschl.
 select * from zsd_mv45_zuschl into table t_zuschl
                               where vkorg eq vbak-vkorg
                               and   vtweg eq vbak-vtweg
                               and   datab    le sy-datum
                               and   datbi    ge sy-datum
                               and   loevm    eq space.

 if sy-subrc ne 0.
*  keine Zuschläge zur Vkorg und Vtweg gefunden, also nichts beachten
    exit.
 endif.
 loop at t_zuschl.
*    prüfen ob ein definiertes Zuschlagsmaterial im Auftrag vorhanden
  read table xvbap with key matnr = t_zuschl-matnr
                            pstyv = t_zuschl-pstyv.
  if sy-subrc ne 0.
     read table xvbap with key matnr = t_zuschl-matnr
                               pstyv = t_zuschl-pstyv_gratis.
     if sy-subrc ne 0.
        exit.
     else.
*       Material im Auftrag gefunden, also den Zuschlagstyp "behalten"
*       ist bereits eine Gratisposition, aber das kann sich ja ändern
        t_ztyp_wert-zschltyp = t_zuschl-zschltyp.
        t_ztyp_wert-zusbetr  = t_zuschl-kbetr.
        append t_ztyp_wert.
     endif.
  else.
*   Material im Auftrag gefunden, also den Zuschlagstyp "behalten"
*   Position ist noch Zahlungspflichtig, vielleicht ändert sich ja noch
     t_ztyp_wert-zschltyp = t_zuschl-zschltyp.
     t_ztyp_wert-zusbetr  = t_zuschl-kbetr.
     append t_ztyp_wert.
  endif.
 endloop.
 describe table t_ztyp_wert lines w_lines.
 if w_lines eq 0.
    exit.
 endif.
*---------------------------------------------------------------------
* bereinigen allfällige doppelte Einträge ...
 loop at t_ztyp_wert.
  if not w_ztyp_wert is initial.
   if w_ztyp_wert-zschltyp eq t_ztyp_wert-zschltyp.
      delete t_ztyp_wert.
   else.
      w_ztyp_wert = t_ztyp_wert.
   endif.
  else.
     w_ztyp_wert = t_ztyp_wert.
  endif.
 endloop.
* Ende bereinigen allfällige doppelte Einträge
*---------------------------------------------------------------------
* ermitteln der relevanten Positionstypen zur Wertermittlung
 refresh t_zpstyv. clear t_zpstyv.
 loop at t_ztyp_wert.
  refresh t_zpstyv. clear t_zpstyv.
  select pstyv  from zsd_mv45_zpstyv
                appending table t_zpstyv
                where vkorg eq vbak-vkorg
                and   vtweg eq vbak-vtweg
                and   zschltyp eq t_zuschl-zschltyp
                and   datab    le sy-datum
                and   datbi    ge sy-datum
                and   loevm    eq space.
   if sy-subrc eq 0.
      clear w_sumbetr.
      loop at t_zpstyv.
       loop at xvbap where pstyv eq t_zpstyv.
        add xvbap-kzwi2 to w_sumbetr.
       endloop.
      endloop.
      read table t_zuschl with key ZSCHLTYP = t_ztyp_wert-zschltyp.
      if w_sumbetr > t_ztyp_wert-zusbetr.
*        Positionssumme grösser Biswert, dann Positionstyp ändern
         loop at xvbap where matnr eq t_zuschl-matnr.
          xvbap-pstyv = t_zuschl-pstyv_gratis.
          modify xvbap.
*          modify yvbap from xvbap.
          append xvbap to yvbap.
         endloop.
      else.
         loop at xvbap where matnr eq t_zuschl-matnr.
          xvbap-pstyv = t_zuschl-pstyv.
          modify xvbap.
          append xvbap to yvbap.
         endloop.
      endif.
   endif.
 endloop.
*---------------------------------------------------------------------
