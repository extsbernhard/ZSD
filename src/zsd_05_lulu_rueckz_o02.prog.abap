*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_RUECKZ_O01
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

*  LOOP AT SCREEN INTO screen_wa.
*   if screen_wa-name = 'S_LOEVM-LOW'.
*      screen_wa-input = '0'.
*      modify screen from screen_wa.
*   endif.
**   if screen_wa-name = 'S_LOEVM-HIGH'.
**      screen_wa-input = '0'.
**      modify screen from screen_wa.
**   endif.
*   if screen_wa-name = 'P_QUOTX'.
*      screen_wa-input = '0'.
*      modify screen from screen_wa.
*   endif.
*  endloop.
*======================================================================*
INITIALIZATION.
*======================================================================*
* if s_quote is initial.
*    move 'BT'     to s_quote-option.        "EQ=ist gleich
*    move 'I'      to s_quote-sign.
*    move '50.00'  to s_quote-low.
*    move '100.00' to s_quote-high.
*    append s_quote.
*    clear s_quote.
* endif. "
 if s_aszdt is initial.
    move 'BT'        to s_aszdt-option.        "EQ=ist gleich
    move 'I'         to s_aszdt-sign.
    move '20130101'  to s_aszdt-low.
    move '20151231'  to s_aszdt-high.
    append s_aszdt.
    clear s_aszdt.
 endif. "


*======================================================================*
AT SELECTION-SCREEN.
*
 if not s_vfgdt is initial.
    refresh s_vfgd1. clear s_vfgd1.                       "Epo20141015
    loop at s_vfgdt.
     MOVE-CORRESPONDING s_vfgdt to s_vfgd1.
     append s_vfgd1.
    endloop.
 endif.
*
 if not s_rkrdt is initial.
    refresh s_rkrd1. clear s_rkrd1.                       "Epo20141015
    loop at s_rkrdt.
     MOVE-CORRESPONDING s_rkrdt to s_rkrd1.
     append s_rkrd1.
    endloop.
 endif.
*
 if not s_aszdt is initial.
    refresh s_aszd1. clear s_aszd1.                       "Epo20141015
    loop at s_aszdt.
     MOVE-CORRESPONDING s_aszdt to s_aszd1.
     append s_aszd1.
    endloop.
 endif.
*
 if     p_fall eq c_activ.
         move c_kz_fall   to w_kz_ge_fa.
 elseif p_gesuch eq c_activ.
         move c_kz_gesuch to w_kz_ge_fa.
 endif.
*
 if     p_summen eq c_activ.
         move c_kz_S      to w_list_kz.
 elseif p_detail eq c_activ.
         move c_kz_D      to w_list_kz.
 endif.
*
 if s_xblnr is initial.
    if p_fall eq 'X'.
       move 'BT'        to s_xblnr-option.        "EQ=ist gleich
       move 'I'         to s_xblnr-sign.
       move '01000000'  to s_xblnr-low.
       move '01017999'  to s_xblnr-high.
       append s_xblnr.
       clear s_xblnr.
    elseif p_gesuch eq 'X'.
       move 'BT'        to s_xblnr-option.        "EQ=ist gleich
       move 'I'         to s_xblnr-sign.
       move '00000001'  to s_xblnr-low.
       move '00009999'  to s_xblnr-high.
       append s_xblnr.
       clear s_xblnr.
    endif.
 endif.
*======================================================================*
 AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vari.
*======================================================================*
 move sy-repid   to w_alv_variant-report.
 CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
  EXPORTING
    IS_VARIANT                = w_alv_variant
*   I_TABNAME_HEADER          =
*   I_TABNAME_ITEM            =
*   IT_DEFAULT_FIELDCAT       =
    I_SAVE                    = c_alv_save
*   I_DISPLAY_VIA_GRID        = ' '
  IMPORTING
*   E_EXIT                    =
    ES_VARIANT                = w_alv_variant
* EXCEPTIONS
*   NOT_FOUND                 = 1
*   PROGRAM_ERROR             = 2
*   OTHERS                    = 3
          .
 IF SY-SUBRC <> 0.
* Implement suitable error handling here
 else.
   p_vari = w_alv_variant-variant.
 ENDIF.
