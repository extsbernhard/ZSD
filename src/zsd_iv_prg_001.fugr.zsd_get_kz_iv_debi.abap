FUNCTION ZSD_GET_KZ_IV_DEBI.
*"----------------------------------------------------------------------
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     REFERENCE(I_KUNRG) TYPE  KUNRG
*"     REFERENCE(I_BUKRS) TYPE  BUKRS
*"     REFERENCE(I_VKORG) TYPE  VKORG
*"     REFERENCE(I_VTWEG) TYPE  VTWEG
*"     REFERENCE(I_SPART) TYPE  SPART
*"     REFERENCE(I_ALAND) TYPE  ALAND DEFAULT 'CH'
*"     REFERENCE(I_TATYP) TYPE  TATYP DEFAULT 'MWST'
*"  EXPORTING
*"     REFERENCE(E_TAXKD) TYPE  TAKLD
*"     REFERENCE(E_IV_AKTIV) TYPE  ZSD_IV_AKTIV
*"  EXCEPTIONS
*"      NO_TAX_DEF
*"      CLIENT_DEL
*"      NO_CUST_ORG
*"      WRONG_PARAMS
*"----------------------------------------------------------------------
 data: ls_knvv                    type knvv
     , ls_knvi                    type knvi
     , ls_iv_stg001               type zsd_iv_stg001
     .
 CONSTANTS:
       c_nein                     type char1 value 'N'
     , c_x                        type char1 value 'X'
     .
*-----------------------------------------------------------------------
  if i_kunrg is initial
  or i_bukrs is initial
  or i_vkorg is initial
  or i_vtweg is initial
  or i_spart is initial.
     RAISE wrong_params.
  endif.
  if i_vkorg is initial
  or i_vtweg is initial
  or i_spart is initial.
     RAISE no_cust_org.
  endif.
* lesen Steuerkennzeichen zum Regulierer / Kunden
  select single * from knvi into ls_knvi
         where kunnr eq i_kunrg
           and aland eq i_aland
           and tatyp eq i_tatyp.
  if sy-subrc ne 0.
     raise no_tax_def.
  endif.
* lesen Vertriebsbereichsdaten zum Regulierer / Kunden
  select single * from knvv into ls_knvv
          where kunnr eq i_kunrg
            and vkorg eq i_vkorg
            and vtweg eq i_vtweg
            and spart eq i_spart.
  if not ls_knvv-loevm is initial.
     raise client_del.
  endif.
* bestücken Rückgabe-Felder
  e_taxkd = ls_knvi-taxkd.
  select single * from zsd_iv_stg001 into ls_iv_stg001
          where bukrs eq i_bukrs
            and vkorg eq i_vkorg
            and vtweg eq i_vtweg
            and spart eq i_spart
            and taxkd eq ls_knvi-taxkd
            and loevm ne c_x.
  if sy-subrc eq 0.
     e_iv_aktiv = ls_iv_stg001-iv_aktiv.
  else.
     e_iv_aktiv = c_nein.
  endif.
*
ENDFUNCTION.
