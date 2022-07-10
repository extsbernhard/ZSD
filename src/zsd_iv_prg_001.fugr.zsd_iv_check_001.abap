FUNCTION ZSD_IV_CHECK_001.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_DOC_ID) TYPE  SAEARDOID
*"     REFERENCE(I_CONT_REP_ID) TYPE  SAEARCHIVI
*"  EXPORTING
*"     REFERENCE(E_IV_AKTIV) TYPE  ZSD_IV_AKTIV
*"     REFERENCE(E_AR_OBJECT) TYPE  SAEOBJART
*"----------------------------------------------------------------------
constants: c_vbrk               type SAEANWDID    value 'VBRK'
         , c_pdf                type doctyp       value 'PDF'
         , c_inaktiv            type zsd_iv_aktiv value 'N'
         , c_aktiv              type zsd_iv_aktiv value 'J'
         , c_x                  type char1        value 'X'
         .
data:      t_toaom              type table of toaom
         , s_toaom              like LINE OF t_toaom
         , w_toa00              type toa01
         , w_iv_stg001          type zsd_iv_stg001
         , w_vbeln_vf           type vbeln_vf
         , w_ar_object          type saeobjart
         , w_toatab             type TABNAME
         , w_vbrk               type vbrk
         , w_vkorg              type vkorg
         , w_vtweg              type vtweg
         , w_spart              type spart
         , w_taxkd              type taxk1
         , w_bukrs              type bukrs
         .
* ---------- init - Übergabe - Werte --------------------------------- *
        e_iv_aktiv = c_inaktiv.
 clear: e_ar_object.
* ---------- ermitteln Archiv-tabelle über TOAOM --------------------- *
 select * from toaom into table t_toaom
         where archiv_ID  eq i_cont_rep_id
           and sap_object eq c_vbrk
           and doc_type   eq c_pdf.
 check sy-subrc eq 0.
 loop at t_toaom into s_toaom.
  case s_toaom-connection.
   when 'TOA01'.
        select single * from toa01 into w_toa00
                where sap_object eq c_vbrk
                  and archiv_id  eq i_cont_rep_id
                  and arc_doc_id eq i_doc_id
                  and reserve    eq c_pdf.
        if sy-subrc ne 0.
           clear w_toa00.
        else.
           move w_toa00-object_ID(10) to w_vbeln_vf.
           move w_toa00-ar_object     to w_ar_object.
        endif.
   when 'TOA02'.
        select single * from toa02 into w_toa00
                where sap_object eq c_vbrk
                  and archiv_id  eq i_cont_rep_id
                  and arc_doc_id eq i_doc_id
                  and reserve    eq c_pdf.
        if sy-subrc ne 0.
           clear w_toa00.
        else.
           move w_toa00-object_ID(10) to w_vbeln_vf.
           move w_toa00-ar_object     to w_ar_object.
        endif.
   when 'TOA03'.
        select single * from toa03 into w_toa00
                where sap_object eq c_vbrk
                  and archiv_id  eq i_cont_rep_id
                  and arc_doc_id eq i_doc_id
                  and reserve    eq c_pdf.
        if sy-subrc ne 0.
           clear w_toa00.
        else.
           move w_toa00-object_ID(10) to w_vbeln_vf.
           move w_toa00-ar_object     to w_ar_object.
        endif.
   when others.
*       machen wir mal nix ;-)
  endcase." s_toaom-connection.
* ---------- ermitteln Org-Daten aus VBRK wenn Faktura-Nr. vorhanden - *
  if not w_vbeln_vf is initial.
     select single * from vbrk into w_vbrk where vbeln eq w_vbeln_vf.
     if sy-subrc ne 0.
        clear: w_vbrk, w_vbeln_vf, w_ar_object.
     else.
        w_vkorg = w_vbrk-vkorg.
        w_vtweg = w_vbrk-vtweg.
        w_spart = w_vbrk-spart.
        w_bukrs = w_vbrk-bukrs.
        w_taxkd = w_vbrk-taxk1.
* ---------- ermitteln IV-Status aus IV - Steuerungstabelle ---------- *
        select single * from zsd_iv_stg001 into w_iv_stg001
                where bukrs eq w_bukrs
                  and vkorg eq w_vkorg
                  and vtweg eq w_vtweg
                  and spart eq w_spart
                  and taxkd eq w_taxkd
                  and loevm ne c_x.
        if sy-subrc eq 0.
*          Steuerungskennzeichen aus Tabelleneintrag übernehmen ...
           e_iv_aktiv  = w_iv_stg001-iv_aktiv.
        else.
*          kein Tabelleneintrag = inaktiv !!!
           e_iv_aktiv = c_inaktiv.
        endif.
        e_ar_object = w_ar_object.
     endif.
   endif.
 endloop." at t_toaom into s_toaom.





ENDFUNCTION.
