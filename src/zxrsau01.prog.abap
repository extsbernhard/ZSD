*&---------------------------------------------------------------------*
*&  Include           ZXRSAU01
*&---------------------------------------------------------------------*
DATA: it_zoxd110009 TYPE TABLE OF zoxd110009,
      it_zsd_05_kepo_ver TYPE TABLE OF zsd_05_kepo_ver.

DATA: wa_zoxd110009 TYPE zoxd110009,
      wa_zsd_05_kepo_ver TYPE zsd_05_kepo_ver.



CASE i_datasource.
  WHEN 'ZDS_WR_ZSDTKPKEPO'.
    SELECT * INTO TABLE it_zsd_05_kepo_ver
      FROM zsd_05_kepo_ver
      WHERE typ = 'R'
      OR    typ = 'V'.

    LOOP AT c_t_data INTO wa_zoxd110009.
      READ TABLE it_zsd_05_kepo_ver INTO wa_zsd_05_kepo_ver
       WITH KEY fallnr  = wa_zoxd110009-fallnr
          gjahr = wa_zoxd110009-gjahr.
      IF sy-subrc = 0.
        wa_zoxd110009-datum = wa_zsd_05_kepo_ver-ver_datum.
        wa_zoxd110009-name  = wa_zsd_05_kepo_ver-ver_anvo.
        wa_zoxd110009-typ   = wa_zsd_05_kepo_ver-typ.
        MODIFY c_t_data FROM wa_zoxd110009.
      ENDIF.
    ENDLOOP.

ENDCASE.

********************************************************************************
* 2LIS_18 Extraktoren Erweiterungen   EXHANDWERK 03.04.2019
********************************************************************************

Tables: AUFK.
DATA:   wa_hdr TYPE mc18i30hdr,
        L_TABIX like SY-TABIX.

CASE i_datasource.
  WHEN '2LIS_18_I3HDR'.
   LOOP AT c_t_data INTO wa_hdr.
   L_TABIX = SY-TABIX.
   clear AUFK.
   SHIFT AUFK-AUFNR LEFT DELETING LEADING '0'.
   SELECT Single * from AUFK where AUFNR = wa_hdr-AUFNR.
*   SELECT Single * from AUFK where AUFNR = '000000423681'.
      IF sy-subrc = 0.
        wa_hdr-zz_signal_code = AUFK-ZZ_SIGNAL_CODE.
        wa_hdr-zz_gb = AUFK-ZZ_GB.
        wa_hdr-zzequnr = AUFK-ZZEQUNR.
      MODIFY c_t_data FROM wa_hdr INDEX L_TABIX.
      ENDIF.
    ENDLOOP.
ENDCASE.


********************************************************************************
* 2LIS_18_I3OPR Extraktoren Erweiterungen   EXHANDWERK 17.07.2019
********************************************************************************

Tables: AFVU.
DATA:   wa_opr TYPE MC18I30OPR.

CASE i_datasource.
  WHEN '2LIS_18_I3OPER'.
   LOOP AT c_t_data INTO wa_opr.
   L_TABIX = SY-TABIX.
   clear AFVU.
   SELECT Single * from AFVU where AUFPL = wa_opr-AUFPL and APLZL = wa_opr-APLZL.
      IF sy-subrc = 0.
        wa_opr-ZZUSE04 = AFVU-USE04.
        wa_opr-ZZUSR04 = AFVU-USR04.
        wa_opr-ZZUSE05 = AFVU-USE05.
        wa_opr-ZZUSR05 = AFVU-USR05.
      MODIFY c_t_data FROM wa_opr INDEX L_TABIX.
      ENDIF.
    ENDLOOP.
ENDCASE.




********************************************************************************
* ZDS_CS_AFRU  CS Auftragsrückmeldung   EXHANDWERK 16.07.2019
********************************************************************************

* Arbeitsplatz ist in Tabelle AFRU nur als Objekt-ID vorhanden, deshalb die Anreicherung über die Tabelle CRHD

TABLES: crhd.
TABLES: AFRU.

DATA: l_s_ZOXD110157 like ZOXD110157.
*DATA: l_s_AFRU like ZOXD110157.

CASE i_datasource.
  WHEN 'ZDS_CS_AFRU'.

LOOP AT c_t_data INTO l_s_ZOXD110157.
  l_tabix = sy-tabix.
  clear AFRU.
  clear CRHD.

SELECT SINGLE * FROM crhd
  WHERE objid = L_S_ZOXD110157-ARBID.

SELECT Single * from AFVU
  WHERE AUFPL = L_S_ZOXD110157-AUFPL and APLZL = L_S_ZOXD110157-APLZL.

  IF sy-subrc = 0.
     L_S_ZOXD110157-ZZARBPL = crhd-ARBPL.
     L_S_ZOXD110157-ZZUSE04 = AFVU-USE04.
     L_S_ZOXD110157-ZZUSR04 = AFVU-USR04.
     L_S_ZOXD110157-ZZUSE05 = AFVU-USE05.
     L_S_ZOXD110157-ZZUSR05 = AFVU-USR05.
     MODIFY c_t_data FROM L_S_ZOXD110157 INDEX l_tabix.
  ENDIF.

ENDLOOP.

ENDCASE.
