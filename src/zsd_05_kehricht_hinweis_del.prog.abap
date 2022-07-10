*----------------------------------------------------------------------*
* Report  ZSD_05_KEHRICHT_HINWEIS_DEL
* Author: Exsigno AG / Raffaele De Simone
*----------------------------------------------------------------------*
* Hinweistypen und -texte auf Objektstamm löschen
*
*----------------------------------------------------------------------*
*
REPORT  zsd_05_kehricht_hinweis_del
            LINE-SIZE  255
            LINE-COUNT 65(0).

INCLUDE zsd_05_kehricht_hinweis_del_c1. "Lokale Klasse

TABLES: zsd_04_kehricht,               "Gebühren: Kehrichtgrundgebühr
     zsd_05_hinweis.
DATA: t_kehricht TYPE zsd_04_kehricht OCCURS 0 WITH HEADER LINE.
data: t_kehr TYPE TABLE OF zsd_04_kehricht.
DATA: t_hinweis TYPE TABLE OF zsd_05_hinweis.
DATA: w_hinweis TYPE zsd_05_hinweis.
DATA: w_ct TYPE i.
*
PARAMETERS: p_hinwei LIKE zsd_04_kehricht-hinweis1 OBLIGATORY.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
SELECT-OPTIONS: s_stadtt FOR zsd_04_kehricht-stadtteil,
                s_parzel FOR zsd_04_kehricht-parzelle,
                s_objekt FOR zsd_04_kehricht-objekt,
                s_objkey FOR zsd_04_kehricht-obj_key.
SELECTION-SCREEN END   OF BLOCK b1.
PARAMETERS: p_mass AS CHECKBOX.
PARAMETERS: p_rows TYPE i DEFAULT 10.

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  IF p_hinwei(2) CS 'VI'.
*  OR p_hinwei(2) CS 'RE'.
    MESSAGE e000(zsd_04) WITH
    'Hinweistypen VI können nicht gelöscht werden!'.
*    'Hinweistypen VI oder RE können nicht gelöscht werden!'.
  ENDIF.

  IF p_mass = 'X'.

    SELECT * FROM zsd_05_hinweis INTO TABLE t_hinweis UP TO p_rows ROWS WHERE hinweis = p_hinwei
           and   stadtteil IN s_stadtt
           AND    parzelle  IN s_parzel
           AND    objekt    IN s_objekt
           AND    obj_key   IN s_objkey.
    IF sy-subrc = 0.
      SELECT        * FROM  zsd_04_kehricht
             INTO TABLE t_kehricht FOR ALL ENTRIES IN t_hinweis
             WHERE  stadtteil = t_hinweis-stadtteil
             AND    parzelle  = t_hinweis-parzelle
             AND    objekt    = t_hinweis-objekt.
    ELSE.
      MESSAGE e000(zsd_04) WITH
      'Keine Daten in Tabelle ZSD_05_HINWEIS!'.
    ENDIF.

  ELSE.
    SELECT        * FROM  zsd_04_kehricht
           INTO TABLE t_kehricht
           WHERE  stadtteil IN s_stadtt
           AND    parzelle  IN s_parzel
           AND    objekt    IN s_objekt
           AND    obj_key   IN s_objkey.
    IF sy-subrc = 0.
      MESSAGE e000(zsd_04) WITH
'Keine Daten selektiert!'.
    ENDIF.
  ENDIF.
*
  LOOP AT t_kehricht.
*    READ TABLE t_hinweis INTO w_hinweis WITH  KEY stadtteil = t_kehricht-stadtteil
*          parzelle = t_kehricht-parzelle
*          objekt   = t_kehricht-objekt.


    CASE p_hinwei.
      WHEN t_kehricht-hinweis1.
*        IF NOT w_hinweis-hinweis = t_kehricht-hinweis1.
        CLEAR: t_kehricht-hinweis1,
               t_kehricht-hintext1.
        MODIFY zsd_04_kehricht FROM t_kehricht.
        IF sy-subrc = 0.
          w_ct = w_ct + 1.
        ENDIF.
      WHEN t_kehricht-hinweis2.
*        IF NOT  w_hinweis-hinweis = t_kehricht-hinweis2.

        CLEAR: t_kehricht-hinweis2,
               t_kehricht-hintext2.
*        ENDIF.
        MODIFY zsd_04_kehricht FROM t_kehricht.
        IF sy-subrc = 0.
          w_ct = w_ct + 1.
        ENDIF.
      WHEN t_kehricht-hinweis3.
*        IF NOT  w_hinweis-hinweis = t_kehricht-hinweis3.
        CLEAR: t_kehricht-hinweis3,
               t_kehricht-hintext3.
*        ENDIF.
        MODIFY zsd_04_kehricht FROM t_kehricht.
        IF sy-subrc = 0.
          w_ct = w_ct + 1.
        ENDIF.
      WHEN t_kehricht-hinweis4.
*        IF NOT  w_hinweis-hinweis = t_kehricht-hinweis4.
        CLEAR: t_kehricht-hinweis4,
               t_kehricht-hintext4.
*        ENDIF.
        MODIFY zsd_04_kehricht FROM t_kehricht.
        IF sy-subrc = 0.
          w_ct = w_ct + 1.
        ENDIF.
      WHEN t_kehricht-hinweis5.
*        IF NOT  w_hinweis-hinweis = t_kehricht-hinweis5.
        CLEAR: t_kehricht-hinweis5,
               t_kehricht-hintext5.
*        ENDIF.
        MODIFY zsd_04_kehricht FROM t_kehricht.
        IF sy-subrc = 0.
          w_ct = w_ct + 1.
        ENDIF.
      WHEN t_kehricht-hinweis6.
*        IF NOT  w_hinweis-hinweis = t_kehricht-hinweis6.
        CLEAR: t_kehricht-hinweis6,
               t_kehricht-hintext6.
*        ENDIF.
        MODIFY zsd_04_kehricht FROM t_kehricht.
        IF sy-subrc = 0.
          w_ct = w_ct + 1.
        ENDIF.
      WHEN t_kehricht-hinweis7.
*        IF NOT  w_hinweis-hinweis = t_kehricht-hinweis7.
        CLEAR: t_kehricht-hinweis7,
               t_kehricht-hintext7.
*        ENDIF.
        MODIFY zsd_04_kehricht FROM t_kehricht.
        IF sy-subrc = 0.
          w_ct = w_ct + 1.
        ENDIF.
      WHEN t_kehricht-hinweis8.
*        IF NOT  w_hinweis-hinweis = t_kehricht-hinweis8.
        CLEAR: t_kehricht-hinweis8,
               t_kehricht-hintext8.
*        ENDIF.
        MODIFY zsd_04_kehricht FROM t_kehricht.
        IF sy-subrc = 0.
          w_ct = w_ct + 1.
        ENDIF.
    ENDCASE.

  ENDLOOP.

  IF w_ct = 0.
    MESSAGE e000(zsd_04) WITH
  'Keine Hinweise gelöscht!'.
  ELSE.
    MESSAGE s000(zsd_04) WITH w_ct 'Hinweise gelöscht'.
    t_kehr[] = t_kehricht[].
  ENDIF.

*======================================================================*
 END-OF-SELECTION.
*======================================================================*
   PERFORM daten_anzeigen.

   INCLUDE zsd_05_kehricht_hinweis_del_f1.
