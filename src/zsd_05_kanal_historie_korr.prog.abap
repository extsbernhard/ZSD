*----------------------------------------------------------------------*
* Report  ZSD_05_KANAL_HISTORIE_KORR
* Author: Exsigno AG, R. De Simone
*----------------------------------------------------------------------*
* Historie Kanalisationsanschlussgebühren
* Nachführen QM-Stand im Objektstamm
*----------------------------------------------------------------------*
*
REPORT  zsd_05_kanal_historie_korr
            NO STANDARD PAGE HEADING
            LINE-SIZE 148
            LINE-COUNT 65(0)
            MESSAGE-ID zpm_01.
*
INCLUDE zbc_in_top.             "Standard TOP-Include für alle Programme
INCLUDE zbc_in_f01.             "Forms                für alle Programme
*
TABLES: vbak,                          "Verkaufsbeleg: Kopfdaten
        vbfa,                          "Vertriebsbelegfluß
        zsd_04_kanal,                  "Gebühren: Kanalisationsanschluss
        zsd_05_kanal_qm,"Gebühren: Kanalisationsanschluss Entwässerung K
        zsd_05_kanal_qmp,"Gebühren: Kanalisationsanschluss Entwässerung
        zsd_05_objekt,                 "Parzellenverwaltung: Objekte
        zsd_05_kanalhist.     "Gebühren: Historie Kanalisationsanschluss
*
TYPE-POOLS slis.
*------- T - Interne Tabellen -----------------------------------------*
DATA: BEGIN OF t_w3 OCCURS 0.
        INCLUDE STRUCTURE zsd_05_kanalhist.
DATA:   belnr TYPE belnr_d,
      END   OF t_w3.
DATA: t_qm LIKE LINE OF t_w3 OCCURS 0 WITH HEADER LINE.
DATA: t_hist TYPE zsd_05_kanalhist OCCURS 0 WITH HEADER LINE.
DATA: w_ucomm LIKE sy-ucomm.
DATA: BEGIN OF t_edit OCCURS 0,
        faknr  LIKE zsd_05_kanalhist-faknr,
        ftyp   LIKE zsd_05_kanalhist-ftyp,
        fkdat  LIKE zsd_05_kanalhist-fkdat,
        dmbtr  LIKE zsd_05_kanalhist-dmbtr,
        storno LIKE zsd_05_kanalhist-storno,
        zeile  LIKE zsd_05_kanalhism-zeile,
        text   LIKE zsd_05_kanalhism-text,
        mark   TYPE c,
      END   OF t_edit.
*
*------- W - Workfelder -----------------------------------------------*
CONTROLS: tc_historie TYPE TABLEVIEW USING SCREEN 9100.
DATA:     g_tc_historie_lines  LIKE sy-loopc.
*-----------------------------------------------------------------------
* Selektionsbild
*-----------------------------------------------------------------------
*------- O - Select-Options -------------------------------------------*
*-----------------------------------------------------------------------
AT SELECTION-SCREEN.
*-----------------------------------------------------------------------
*
*-----------------------------------------------------------------------
START-OF-SELECTION.
*-----------------------------------------------------------------------
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  DATA l_kanalkey(20) TYPE c.
  REFRESH t_hist.
  REFRESH t_w3.
  SET PF-STATUS '9000'.
* SAP-Fakturen nach BW
  SELECT        * FROM  zsd_05_kanal_w3
         APPENDING CORRESPONDING FIELDS OF TABLE t_w3.
  LOOP AT t_w3.
    SELECT SINGLE * FROM  zsd_05_kanalhist
           WHERE  stadtteil  = t_w3-stadtteil
           AND    parzelle   = t_w3-parzelle
           AND    objekt     = t_w3-objekt
           AND    faknr      = t_w3-faknr.
    IF sy-subrc NE 0.
      MOVE 'BW' TO t_w3-ftyp.
      MODIFY t_w3.
    ELSE.
      DELETE t_w3.
    ENDIF.
  ENDLOOP.
* SAP-Fakturen nach QM
  SELECT        * FROM  zsd_05_kanal_qm
         APPENDING CORRESPONDING FIELDS OF TABLE t_qm.
  LOOP AT t_qm.
    SELECT SINGLE * FROM  zsd_05_kanalhist
           WHERE  stadtteil  = t_qm-stadtteil
           AND    parzelle   = t_qm-parzelle
           AND    objekt     = t_qm-objekt
           AND    faknr      = t_qm-faknr.
    IF sy-subrc NE 0.
      MOVE 'QM' TO t_qm-ftyp.
      MODIFY t_qm.
    ELSE.
      DELETE t_qm.
    ENDIF.
  ENDLOOP.
  LOOP AT t_qm.
    t_w3 = t_qm.
    APPEND t_w3.
  ENDLOOP.
*
  LOOP AT t_w3.
    CONCATENATE t_w3-stadtteil
                t_w3-parzelle
                t_w3-objekt
           INTO l_kanalkey.
    CONCATENATE l_kanalkey t_w3-belnr
           INTO l_kanalkey SEPARATED BY space.
    MOVE-CORRESPONDING t_w3 TO t_hist.
    SELECT        * FROM  vbak
           WHERE  bstnk  = l_kanalkey.
      SELECT        * FROM  vbfa
             WHERE  vbelv    = vbak-vbeln
             AND    vbtyp_n  = 'M'.
        MOVE: vbfa-vbeln TO t_hist-faknr,
              vbfa-erdat TO t_hist-fkdat,
              vbfa-rfwrt TO t_hist-dmbtr.
        APPEND t_hist.
      ENDSELECT.
    ENDSELECT.
  ENDLOOP.
*
  SORT t_hist BY stadtteil parzelle objekt fkdat faknr.
  LOOP AT t_hist INTO zsd_05_kanalhist.
    INSERT zsd_05_kanalhist.
  ENDLOOP.
