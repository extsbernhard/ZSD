*----------------------------------------------------------------------*
* Report  ZSD_05_KEHRICHT_AUFTRAG
* Author: Exsigno AG / Raffaele De Simone
*----------------------------------------------------------------------*
* Kundenaufträge anlegen für Verrechnung Kehrichtgrundgebühr
*
* Änderungen:
* 20080424 Zeile 420  Deaktivierung IF Bedingung gemäss MCDSM (IDSWE)
*----------------------------------------------------------------------*
* Änderer: EPO = Oliver Epking, Alsinia GmbH, Steffisburg
* 20131128 Neue Auftragsart Z87G für Kehrichtgrundgebühr hinterlegt in
*          Parameter P_AUART default "Z87G" EpO20131128
*----------------------------------------------------------------------*
* 20131202 Zusätzliche Absicherung dass keine Objekte aus t_fehler     *
*          als Auftrag angelegt werden. "EpO20131202
*----------------------------------------------------------------------*
* 20131219 gemäss Rücksprache mit Frau Giger sind keine Jahresübergrei-*
*          fenden Verrechnungen gewünscht, daher wurde die Berechnung  *
*          nun auf max 12 Monate beschränkt, bzw. bei Jahreswechsel    *
*          wird die Anzahl Monate bis zum Verrechnungs-Ende gerechnet  *
*          Zusätzlich wird neuerdings auch berücksichtigt, wenn Faktura*
*          und Auftrag abgesagt wurden, diese gelten dann korrekt als  *
*          noch nicht verrechnet (Form Check_Vertriebsbelege)          *
*----------------------------------------------------------------------*
*


REPORT  zsd_05_kehricht_auftrag
            LINE-SIZE  255
            LINE-COUNT 65(0).
*
TABLES: a004,                          "Material
        kna1,                          "Kundenstamm (allgemeiner Teil)
        knvv,                          "Kundenstamm Vertriebsdaten
        mara,                          "Allgemeine Materialdaten
        mvke,                          "Verkaufsdaten zum Material
        zsd_05_kehr_auft.        "Gebühren: Kehrichtgrundgebühr Aufträge
*
DATA: BEGIN OF t_fehler OCCURS 0,
        stadtteil        LIKE zsd_04_kehricht-stadtteil,
        parzelle         LIKE zsd_04_kehricht-parzelle,
        objekt           LIKE zsd_04_kehricht-objekt,
        text(160)        TYPE c,
      END   OF t_fehler,
      t_kehricht         TYPE zsd_04_kehricht OCCURS 0,
      t_a004             TYPE a004            OCCURS 0 WITH HEADER LINE,
      t_konp             TYPE konp            OCCURS 0 WITH HEADER LINE,
      t_objekt           TYPE zsd_05_objekt   OCCURS 0,
      t_order_conditions TYPE bapicond        OCCURS 0 WITH HEADER LINE,
      t_order_items      TYPE bapisditm       OCCURS 0 WITH HEADER LINE,
      t_order_partners   TYPE bapiparnr       OCCURS 0 WITH HEADER LINE,
      t_order_schedules  TYPE bapischdl       OCCURS 0 WITH HEADER LINE,
      t_order_text       TYPE bapisdtext      OCCURS 0 WITH HEADER LINE,
      t_return           TYPE bapiret2        OCCURS 0 WITH HEADER LINE,
      w_betrag           TYPE kbetr_kond,
      w_betrag1          TYPE kbetr_kond,
      w_betrag2          TYPE kbetr_kond,
      w_betrag3          TYPE kbetr_kond,
      w_betrag4          TYPE kbetr_kond,
      w_betrag5          TYPE kbetr_kond,
      w_kehricht         TYPE zsd_04_kehricht,
      w_kehrmat          TYPE zsd_04_kehr_mat,
      w_objekt           TYPE zsd_05_objekt,
      w_order_header     TYPE bapisdhd1,
      w_salesdocument    LIKE bapivbeln-vbeln,
      w_street(30)       TYPE c,
      w_vakey            LIKE konh-vakey,
      w_verrdat          TYPE datum,
      w_vbeln_first      TYPE vbeln,
      w_vbeln_last       TYPE vbeln,
      w_verr             LIKE zsd_04_kehricht-verr_datum.
*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-b01.
SELECT-OPTIONS: s_stadtt FOR w_kehricht-stadtteil,
                s_parzel FOR w_kehricht-parzelle,
                s_objekt FOR w_kehricht-objekt,
                s_perio  FOR w_kehricht-verr_perio.
PARAMETER: p_wied AS CHECKBOX DEFAULT ' '.
SELECTION-SCREEN END   OF BLOCK b01.
SELECTION-SCREEN BEGIN OF BLOCK b02 WITH FRAME TITLE text-b02.
PARAMETERS: p_verr  LIKE zsd_04_kehricht-verr_datum OBLIGATORY,
            p_auart TYPE auart DEFAULT 'Z87G' NO-DISPLAY, "EpO20131128
            p_verod TYPE tdobname DEFAULT 'Z_KEHR_AUFT_Z1'.
SELECTION-SCREEN END   OF BLOCK b02.
PARAMETERS: p_fehler AS CHECKBOX DEFAULT 'X',
            p_liste  AS CHECKBOX DEFAULT 'X'.
*
INITIALIZATION.
  IF sy-datum+0(4) GT 2007.
    MOVE sy-datum TO p_verr.
  ELSE.
    MOVE '20070501' TO p_verr.
  ENDIF.
  MOVE '01' TO p_verr+6(2).
*
START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
* Verrechnungsdatum ist immer der 1. des Monats
  IF p_verr+6(2) NE '01'.
    MOVE '01' TO p_verr+6(2).
    DATA msg TYPE bal_s_msg.
    MOVE: 'ZTAB' TO msg-msgid,
          'I'    TO msg-msgty,
          '000'  TO msg-msgno,
          'Datum auf 1. des Monats geändert'
                 TO msg-msgv1.
    CALL FUNCTION 'BAL_MSG_DISPLAY_ABAP'
         EXPORTING
              i_s_msg = msg.
  ENDIF.
* Verrechnungsdatum darf nicht in der Zukunft liegen
  IF p_verr GT sy-datum.
    MESSAGE s000(ztab) WITH
    'Verrechnungsdatum grösser als aktuelles Datum'.
    LEAVE TO TRANSACTION sy-tcode.
  ENDIF.
* Verrechnungsperiodizität muss angegeben werden
  IF p_wied IS INITIAL AND s_perio[] IS INITIAL.
    MESSAGE s000(ztab) WITH
          'Verrechnungsperiodizität nicht angegeben'.
    LEAVE TO TRANSACTION sy-tcode.
  ENDIF.
  PERFORM daten_lesen.
  PERFORM fehler_suchen.
  PERFORM verarbeitung.
*
END-OF-SELECTION.
 data: lw_lines    type i.
  IF NOT p_fehler IS INITIAL.
    describe table t_fehler lines lw_lines.
    If lw_lines <> 0.
     ULINE.
     FORMAT COLOR COL_NEGATIVE.
     WRITE: / 'Keine Verrechnung'.
     SORT t_fehler BY stadtteil parzelle objekt.
     LOOP AT t_fehler.
       CLEAR w_objekt.
       READ TABLE t_objekt INTO w_objekt
                           WITH KEY stadtteil = t_fehler-stadtteil
                                    parzelle  = t_fehler-parzelle
                                    objekt    = t_fehler-objekt
                                    BINARY SEARCH.
       CONCATENATE w_objekt-street
                   w_objekt-house_num1
              INTO w_street
                   SEPARATED BY space.
       WRITE: / t_fehler-stadtteil,
                t_fehler-parzelle,
                t_fehler-objekt,
                w_street,
                w_objekt-post_code1(5),
                w_objekt-city1(15),
                t_fehler-text.
     ENDLOOP.
    else.
     ULINE.
     WRITE: / 'Keine Verrechnung'.
    endif.
  ENDIF.
*
*&---------------------------------------------------------------------*
*&      Form  grund_keine_verrechnung
*&---------------------------------------------------------------------*
*       Mögliche Gründe für keine Verrechnung
*----------------------------------------------------------------------*
FORM grund_keine_verrechnung changing lw_subrc like syst-subrc.
*                            übergeben Sy-subrc für Folgeverarbeitung

  CLEAR t_fehler.
  MOVE-CORRESPONDING w_kehricht TO t_fehler.
* Kundennummer ist nicht vorhanden oder gelöscht
  IF  w_kehricht-adrnr       IS INITIAL
  and w_kehricht-eigen_kunnr is initial.
   if w_kehricht-adrnr    is initial.
      PERFORM check_kunnr USING    w_kehricht-kunnr
                          changing sy-subrc.
      if  w_kehricht-eigen_kunnr is initial
      and sy-subrc > 0.
          MOVE 'Kein Eigentümer für dieses Objekt definiert !'
            TO t_fehler-text.
          APPEND t_fehler.
          lw_subrc = 99.                                  "Epo20131202
      endif.
   endif.
  ENDIF.
* Kennzeichen "Keine Verrechnung"
  IF NOT w_kehricht-verr_code IS INITIAL.
    CONCATENATE w_kehricht-verr_grund
                w_kehricht-verr_parz1
                w_kehricht-verr_parz2
           INTO t_fehler-text
                SEPARATED BY space.
    APPEND t_fehler.
    lw_subrc = 99.                                        "EpO20131202
    EXIT.
  ENDIF.
* Keine Jahresgebühr oder verrechenbare Flächen
  IF w_kehricht-jahresgebuehr = 0
  AND w_kehricht-vflaeche_fakt1 = 0
  AND w_kehricht-vflaeche_fakt2 = 0
  AND w_kehricht-vflaeche_fakt3 = 0.
*>>>>>>>>>>>>>> ab Nov 2013 nicht mehr erforderlich >>>>>>>> Epo20131107
*  AND w_kehricht-vflaeche_fakt4 = 0 ab Nov2013 ungültig    "Epo20131107
*  AND w_kehricht-vflaeche_fakt5 = 0.ab Nov2013 ungültig    "Epo20131107
*<<<<<<<<<<<<<< ab Nov 2013 nicht mehr erforderlich <<<<<<<< Epo20131107
    MOVE 'Keine Jahresgebühr oder verrechenbare Flächen'
      TO t_fehler-text.
    APPEND t_fehler.
    lw_subrc = 99.
    EXIT.
  ENDIF.
* Material nicht vorhanden oder gelöscht
  IF w_kehricht-vflaeche_fakt1 NE 0.
    PERFORM check_material USING w_kehrmat-matnr_1
                           changing lw_subrc.             "Epo20131202
    if lw_subrc eq 99.
       exit.
    endif.
  ENDIF.
  IF w_kehricht-vflaeche_fakt2 NE 0.
    PERFORM check_material USING w_kehrmat-matnr_2
                           changing lw_subrc.             "Epo20131202
    if lw_subrc eq 99.
       exit.
    endif.
  ENDIF.
  IF w_kehricht-vflaeche_fakt3 NE 0.
    PERFORM check_material USING w_kehrmat-matnr_3
                           changing lw_subrc.             "Epo20131202
    if lw_subrc eq 99.
       exit.
    endif.
  ENDIF.
*>>>>>>>>>>>>>> ab Nov 2013 nicht mehr erforderlich >>>>>>>> Epo20131107
**  Todo SCD Anfang  Material 4 und 5 entfallen abe 2013
*  IF w_kehricht-vflaeche_fakt4 NE 0.
*    PERFORM check_material USING w_kehrmat-matnr_4.
*  ENDIF.
*  IF w_kehricht-vflaeche_fakt5 NE 0.
*    PERFORM check_material USING w_kehrmat-matnr_5.
*  ENDIF.
**  Todo SCD Ende
*<<<<<<<<<<<<<< ab Nov 2013 nicht mehr erforderlich <<<<<<<< Epo20131107
  IF w_kehricht-jahresgebuehr NE 0.
    PERFORM check_material USING     w_kehrmat-pausch
                           changing lw_subrc.             "Epo20131202
    if lw_subrc eq 99.
       exit.
    endif.
  ENDIF.

ENDFORM.                    " grund_keine_verrechnung
*&---------------------------------------------------------------------*
*&      Form  check_kunnr
*&---------------------------------------------------------------------*
*       Kunden-Nr. prüfen
*----------------------------------------------------------------------*
*      -->F_KUNNR  Kunden-Nr.
*----------------------------------------------------------------------*
FORM check_kunnr USING    f_kunnr   TYPE kunnr
                 changing lw_return like syst-subrc.
  clear lw_return.
  SELECT SINGLE * FROM  kna1
         WHERE  kunnr  = f_kunnr
         AND    loevm  = space.
  IF sy-subrc NE 0.
    CONCATENATE 'Kunden-Nr. nicht vorhanden oder gelöscht:'
                f_kunnr
           INTO t_fehler-text
                SEPARATED BY space.
    APPEND t_fehler.
    lw_return = 9.
    EXIT.
  ELSE.
    SELECT SINGLE * FROM  knvv
           WHERE  kunnr  = f_kunnr
           AND    vkorg  = w_kehricht-vkorg
           AND    vtweg  = w_kehricht-vtweg
           AND    spart  = w_kehricht-spart
           AND    loevm  = space.
    IF sy-subrc NE 0.
      CONCATENATE 'Kunden-Nr. nicht vorhanden oder gelöscht'
                  'im Vertriebsbereich:'
                  f_kunnr
                  w_kehricht-vkorg
                  w_kehricht-vtweg
                  w_kehricht-spart
             INTO t_fehler-text
                  SEPARATED BY space.
      APPEND t_fehler.
      lw_return = 9.
      EXIT.
    ENDIF.
  ENDIF.
if lw_return < 9.
   lw_return = 0.
endif.
ENDFORM.                    " check_kunnr
*&---------------------------------------------------------------------*
*&      Form  check_material
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->F_MATNR  Material
*----------------------------------------------------------------------*
FORM check_material USING    f_matnr   LIKE w_kehrmat-matnr_1
                    changing lw_subrc  like syst-subrc.

  SELECT SINGLE * FROM  mara
         WHERE  matnr  = f_matnr
         AND    lvorm  = space.
  IF sy-subrc NE 0.
    CONCATENATE 'Material nicht vorhanden oder gelöscht'
                f_matnr
           INTO t_fehler-text
                SEPARATED BY space.
    APPEND t_fehler.
    lw_subrc = 99.                                        "EpO20131202
    EXIT.
  ELSE.
    SELECT SINGLE * FROM  mvke
           WHERE  matnr  = f_matnr
           AND    vkorg  = w_kehricht-vkorg
           AND    vtweg  = w_kehricht-vtweg
           AND    lvorm  = space.
    IF sy-subrc NE 0.
      CONCATENATE 'Material nicht vorhanden oder gelöscht'
                  'im Vertriebsbereich:'
                  f_matnr
                  w_kehricht-vkorg
                  w_kehricht-vtweg
             INTO t_fehler-text
                  SEPARATED BY space.
      APPEND t_fehler.
      lw_subrc = 99.                                      "Epo20131202
      EXIT.
    ENDIF.
  ENDIF.

ENDFORM.                    " check_material
*&---------------------------------------------------------------------*
*&      Form  calc_betrag
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->F_FLAECHE   Fläche
*      -->F_MATNR     Material
*      -->F_BEZ       Bezeichnung
*----------------------------------------------------------------------*
FORM calc_betrag USING    f_flaeche LIKE w_kehricht-vflaeche_fakt1
                          f_matnr LIKE w_kehrmat-matnr_1
                          f_bez LIKE w_kehricht-bez_fakt1.

  DATA l_betrag(10) TYPE c.
  DATA l_betrag1 LIKE w_betrag1.
  DATA l_flaeche(10) TYPE c.
  DATA l_text(132) TYPE c.
  DATA l_monate(02) TYPE n.
  data lw_kz_abgesagt type c. "X" = abgesagt; leer = aktiv
  CHECK w_kehricht-jahresgebuehr = 0.
  CHECK f_flaeche NE 0.
  w_verr = p_verr.
*
  LOOP AT t_a004 WHERE vkorg = w_kehricht-vkorg
                 AND   vtweg = w_kehricht-vtweg
                 AND   matnr = f_matnr.
    LOOP AT t_konp WHERE  knumh  = t_a004-knumh
                   AND    kappl  = t_a004-kappl
                   AND    kschl  = t_a004-kschl.
*      w_verrdat = w_kehricht-verr_datum.          "Epo20131219
*      IF w_verrdat LT w_verr.                     "Epo20131219
        w_verrdat = w_verr.
*      ENDIF.                                      "Epo20131219
      w_betrag1 = f_flaeche * t_konp-kbetr / t_konp-kpein.
      CASE w_kehricht-verr_perio.
        WHEN 'J'.
          w_verrdat+0(4) = w_verrdat+0(4) + 1.
          w_verrdat = w_verrdat - 1.
        WHEN 'V'.
          w_verrdat+4(2) = w_verrdat+4(2) + 3.
          IF w_verrdat+4(2) GT 12.
            w_verrdat+4(2) = w_verrdat+4(2) - 12.
            w_verrdat+0(4) = w_verrdat+0(4) + 1.
          ENDIF.
          w_verrdat = w_verrdat - 1.
      ENDCASE.
      CHECK w_verr GE w_kehricht-verr_datum.
* Prüfen ob nicht bereits fakturiert
      DATA l_wied.
      CLEAR l_wied.
      IF p_wied IS INITIAL.
        SELECT        * FROM  zsd_05_kehr_auft
               WHERE  stadtteil        = w_kehricht-stadtteil
               AND    parzelle         = w_kehricht-parzelle
               AND    objekt           = w_kehricht-objekt
               ORDER BY verr_datum.
* Prüfen ob Kundenauftrag abgesagt und Faktura storniert
          clear lw_kz_abgesagt.
          perform check_vertriebsbelege using    zsd_05_kehr_auft
                                        changing lw_kz_abgesagt.
          if lw_kz_abgesagt ne 'X'.
* Überschneidungen in der Fakturaperiode
           IF zsd_05_kehr_auft-verr_datum_schl GT w_verr.
              CLEAR t_fehler.
              MOVE-CORRESPONDING zsd_05_kehr_auft TO t_fehler.
              CONCATENATE 'Überschneidungen in der Fakturaperiode:'
                          zsd_05_kehr_auft-verr_datum_schl
                          w_verr
                     INTO t_fehler-text
                          SEPARATED BY space.
              APPEND t_fehler.
              l_wied = 'X'.
           ENDIF.
          else.
           clear lw_kz_abgesagt.
          endif.
        ENDSELECT.
        IF sy-subrc = 0.
          w_verr = zsd_05_kehr_auft-verr_datum_schl + 1.
        ENDIF.
      ENDIF.
      CHECK l_wied IS INITIAL.
      l_betrag1 = w_betrag1.
      l_betrag = w_betrag1.
      CONDENSE l_betrag.
      ADD 10 TO t_order_items-itm_number.
      MOVE: f_flaeche                TO l_flaeche,
            f_flaeche                TO t_order_items-target_qty,
            f_matnr                  TO t_order_items-material,
            f_bez                    TO t_order_items-short_text,
            t_order_items-itm_number TO t_order_schedules-itm_number,
            f_flaeche                TO t_order_schedules-req_qty.
      CONDENSE l_flaeche.
* Positionstext
      MOVE: t_order_items-itm_number TO t_order_text-itm_number,
            '0001'                   TO t_order_text-text_id,
            sy-langu                 TO t_order_text-langu,
            '*'                      TO t_order_text-format_col.
      MOVE 'Jahresgebühr' TO t_order_text-text_line.
      APPEND t_order_text.
      MOVE t_konp-kbetr TO l_text.
      CONDENSE l_text.
      CONCATENATE l_flaeche 'm2 à Fr.' l_text
                  '=' l_betrag
             INTO t_order_text-text_line SEPARATED BY space.
      APPEND t_order_text.
* Anteilsmässige Verrechnung
      IF w_verr+0(4) = w_verrdat+0(4).
*        Verrechnung unterjährig im gleichen Jahr
        l_monate = w_verrdat+4(2) - w_verr+4(2) + 1.
      ELSE.
*       Verrechnung Jahresübergreifend, nicht mehr gewünscht 19.12.2013
*        l_monate = 12 - w_verr+4(2) + 1 + w_verrdat+4(2).
        l_monate = w_verrdat+4(2)." - w_verr+4(2) + 1.
                                  " -   01 + 1   "macht keinen Sinn :-)
      ENDIF.
      IF w_verrdat GT w_kehricht-verr_datum_schl.
        IF w_verr+0(4) = w_kehricht-verr_datum_schl+0(4).
          l_monate = w_kehricht-verr_datum_schl+4(2) - w_verr+4(2) + 1.
        ELSE.
*         keine Jahresübergreifenden Verrechnungen mehr   "EPO20131219
*          l_monate = 12 - w_verr+4(2) + 1
*                   + w_kehricht-verr_datum_schl+4(2).
          l_monate = w_kehricht-verr_datum_schl+4(2) - w_verr+4(2) + 1.
        ENDIF.
        w_verrdat = w_kehricht-verr_datum_schl.
      ENDIF.
      w_betrag1 = w_betrag1 * l_monate / 12.
      MOVE: 1 TO t_order_items-target_qty,
            1 TO t_order_schedules-req_qty.
      CONCATENATE 'Anteil für' l_monate 'Monate'
             INTO t_order_text-text_line SEPARATED BY space.
      APPEND t_order_text.
      CONCATENATE l_betrag ': 12 x'
                  l_monate '='
             INTO t_order_text-text_line SEPARATED BY space.
      MOVE w_betrag1 TO l_text.
      CONDENSE l_text.
      CONCATENATE t_order_text-text_line l_text
             INTO t_order_text-text_line SEPARATED BY space.
      APPEND t_order_text.
      IF w_kehricht-verr_perio = 'V'.
        MOVE: 1 TO t_order_items-target_qty,
              1 TO t_order_schedules-req_qty.
      ENDIF.
*
      IF NOT p_liste IS INITIAL.
        WRITE: / w_verr,
                 w_verrdat,
                 w_kehricht-stadtteil,
                 w_kehricht-parzelle,
                 w_kehricht-objekt,
                 f_flaeche,
                 '*',
                 t_konp-kbetr,
                 '=',
                 'Fakturabetrag:',
                 w_betrag1.
      ENDIF.
      IF NOT t_order_items IS INITIAL.
        APPEND t_order_items.
      ENDIF.
      IF NOT t_order_schedules IS INITIAL.
        APPEND t_order_schedules.
      ENDIF.
*      IF l_betrag1 NE w_betrag1.
        MOVE: t_order_items-itm_number TO
              t_order_conditions-itm_number,
              t_a004-kschl TO t_order_conditions-cond_type,
              w_betrag1 TO t_order_conditions-cond_value,
              'CHF' TO t_order_conditions-currency.
        APPEND t_order_conditions.
*      ENDIF.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " calc_betrag
*
*&---------------------------------------------------------------------*
*&      Form  write_aufttab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM write_aufttab.

  CLEAR zsd_05_kehr_auft.
  MOVE-CORRESPONDING w_kehricht TO zsd_05_kehr_auft.
  MOVE: w_verr                  TO zsd_05_kehr_auft-verr_datum,
        w_verrdat               TO zsd_05_kehr_auft-verr_datum_schl.
  move w_kehricht-eigen_kunnr   to zsd_05_kehr_auft-kunnr."Epo20131219
  MOVE w_salesdocument          TO zsd_05_kehr_auft-vbeln.
  move: sy-uname                to zsd_05_kehr_auft-cname "Epo20131219
      , sy-datum                to zsd_05_kehr_auft-cdate "Epo20131219
      , sy-uzeit                to zsd_05_kehr_auft-ctime "Epo20131219
      .                                                   "Epo20131219
  INSERT zsd_05_kehr_auft.

ENDFORM.                    " write_aufttab
*
*&---------------------------------------------------------------------*
*&      Form  auftrag_anlegen
*&---------------------------------------------------------------------*
*       Kundenaufträge anlegen
*----------------------------------------------------------------------*
FORM auftrag_anlegen.

  MOVE: w_kehricht-vkorg TO w_order_header-sales_org,
        w_kehricht-vtweg TO w_order_header-distr_chan,
        w_kehricht-spart TO w_order_header-division,
        w_kehricht-vkbur TO w_order_header-sales_off,
        p_auart          TO w_order_header-doc_type.
  CLEAR w_objekt.
  READ TABLE t_objekt INTO w_objekt
                      WITH KEY stadtteil = w_kehricht-stadtteil
                               parzelle  = w_kehricht-parzelle
                               objekt    = w_kehricht-objekt
                               BINARY SEARCH.
*>>> neu mit Vertreter und Eigentümer >>>                  "EpO20131107
  perform Partner_Daten_build.

* Kopfzeile
  MOVE: '000000' TO t_order_text-itm_number,
        '0001'   TO t_order_text-text_id,
        sy-langu TO t_order_text-langu,
        '*'      TO t_order_text-format_col.
  DATA: l_datum_verr(10) TYPE c,
        l_datum_dat(10)  TYPE c.
  WRITE w_verr TO l_datum_verr.
  WRITE w_verrdat TO l_datum_dat.
  CONCATENATE 'Kehrichtgrundgebühr für die Periode'
              l_datum_verr
              '-'
              l_datum_dat
         INTO t_order_text-text_line SEPARATED BY space.
  APPEND t_order_text.
  CLEAR t_order_text-text_line.
  CONCATENATE w_kehricht-stadtteil
              w_kehricht-parzelle
              w_kehricht-objekt
         INTO t_order_text-text_line SEPARATED BY '-'.
  IF NOT w_objekt-objektbez IS INITIAL.
    CONCATENATE t_order_text-text_line
                w_objekt-objektbez
          INTO t_order_text-text_line SEPARATED BY space.
  ELSE.
    CONCATENATE t_order_text-text_line
                w_objekt-street
                w_objekt-house_num1
           INTO t_order_text-text_line SEPARATED BY space.
  ENDIF.
  APPEND t_order_text.
  CLEAR t_order_text-text_line.
  CASE 'VI1'.
    WHEN w_kehricht-hinweis1.
      MOVE w_kehricht-hintext1 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis2.
      MOVE w_kehricht-hintext2 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis3.
      MOVE w_kehricht-hintext3 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis4.
      MOVE w_kehricht-hintext4 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis5.
      MOVE w_kehricht-hintext5 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis6.
      MOVE w_kehricht-hintext6 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis7.
      MOVE w_kehricht-hintext7 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis8.
      MOVE w_kehricht-hintext8 TO t_order_text-text_line.
  ENDCASE.
  IF NOT t_order_text-text_line IS INITIAL.
    APPEND t_order_text.
  ENDIF.
  CLEAR t_order_text-text_line.
  CASE 'VI2'.
    WHEN w_kehricht-hinweis1.
      MOVE w_kehricht-hintext1 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis2.
      MOVE w_kehricht-hintext2 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis3.
      MOVE w_kehricht-hintext3 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis4.
      MOVE w_kehricht-hintext4 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis5.
      MOVE w_kehricht-hintext5 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis6.
      MOVE w_kehricht-hintext6 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis7.
      MOVE w_kehricht-hintext7 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis8.
      MOVE w_kehricht-hintext8 TO t_order_text-text_line.
  ENDCASE.
  IF NOT t_order_text-text_line IS INITIAL.
    APPEND t_order_text.
  ENDIF.
* Schlusszeilen
  MOVE: '000000' TO t_order_text-itm_number,
        '0002'   TO t_order_text-text_id,
        sy-langu TO t_order_text-langu,
        '*'      TO t_order_text-format_col.
  CLEAR t_order_text-text_line.
  CASE 'RE1'.
    WHEN w_kehricht-hinweis1.
      MOVE w_kehricht-hintext1 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis2.
      MOVE w_kehricht-hintext2 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis3.
      MOVE w_kehricht-hintext3 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis4.
      MOVE w_kehricht-hintext4 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis5.
      MOVE w_kehricht-hintext5 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis6.
      MOVE w_kehricht-hintext6 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis7.
      MOVE w_kehricht-hintext7 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis8.
      MOVE w_kehricht-hintext8 TO t_order_text-text_line.
  ENDCASE.
  IF NOT t_order_text-text_line IS INITIAL.
    APPEND t_order_text.
  ENDIF.
  CLEAR t_order_text-text_line.
  CASE 'RE2'.
    WHEN w_kehricht-hinweis1.
      MOVE w_kehricht-hintext1 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis2.
      MOVE w_kehricht-hintext2 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis3.
      MOVE w_kehricht-hintext3 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis4.
      MOVE w_kehricht-hintext4 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis5.
      MOVE w_kehricht-hintext5 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis6.
      MOVE w_kehricht-hintext6 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis7.
      MOVE w_kehricht-hintext7 TO t_order_text-text_line.
    WHEN w_kehricht-hinweis8.
      MOVE w_kehricht-hintext8 TO t_order_text-text_line.
  ENDCASE.
  IF NOT t_order_text-text_line IS INITIAL.
    APPEND t_order_text.
  ENDIF.
  CLEAR t_order_text-text_line.
*  IF NOT w_kehricht-berechnung IS INITIAL.
*    CONCATENATE 'Berechnungsinfo:'
*                w_kehricht-berechnung
*           INTO t_order_text-text_line.
*    APPEND t_order_text.
*  ENDIF.
  IF NOT p_verod IS INITIAL.
    DATA t_line TYPE tline OCCURS 0 WITH HEADER LINE.
    CALL FUNCTION 'READ_TEXT'
         EXPORTING
              client                  = sy-mandt
              id                      = 'ST'
              language                = sy-langu
              name                    = p_verod
              object                  = 'TEXT'
         TABLES
              lines                   = t_line
         EXCEPTIONS
              id                      = 1
              language                = 2
              name                    = 3
              not_found               = 4
              object                  = 5
              reference_check         = 6
              wrong_access_to_archive = 7
              OTHERS                  = 8.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    LOOP AT t_line.
      CLEAR t_order_text-text_line.
      MOVE t_line-tdline TO t_order_text-text_line.
      APPEND t_order_text.
    ENDLOOP.
  ENDIF.
*
  CHECK NOT t_order_items[] IS INITIAL.
  CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
       EXPORTING
            order_header_in     = w_order_header
            behave_when_error   = 'P'
       IMPORTING
            salesdocument       = w_salesdocument
       TABLES
            return              = t_return
            order_items_in      = t_order_items
            order_partners      = t_order_partners
            order_schedules_in  = t_order_schedules
            order_conditions_in = t_order_conditions
            order_text          = t_order_text.
*
  IF NOT w_salesdocument IS INITIAL.
    PERFORM write_aufttab.
  ENDIF.
  CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'.
  IF w_vbeln_first IS INITIAL.
    w_vbeln_first = w_salesdocument.
  ENDIF.
  w_vbeln_last = w_salesdocument.

ENDFORM.                    " auftrag_anlegen
*
*&---------------------------------------------------------------------*
*&      Form  calc_grundgebuehr
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->F_PERIO     Periodizität
*----------------------------------------------------------------------*
FORM calc_grundgebuehr USING    f_perio.

  DATA l_betrag(10) TYPE c.
  DATA l_monate(02) TYPE n.
  DATA l_text(132) TYPE c.
  w_verr = p_verr.
*  w_verrdat = w_kehricht-verr_datum.                     "Epo20131219

*  IF w_verrdat LT w_verr.                                "Epo20131219
    w_verrdat = w_verr.
*  ENDIF.                                                 "Epo20131219
  w_betrag1 = w_kehricht-jahresgebuehr.
  CASE f_perio.
    WHEN 'J'.
      w_verrdat+0(4) = w_verr+0(4).
      MOVE '1231' TO w_verrdat+4(4).
    WHEN 'V'.
      w_verrdat+4(2) = w_verrdat+4(2) + 3.
      IF w_verrdat+4(2) GT 12.
        w_verrdat+4(2) = w_verrdat+4(2) - 12.
        w_verrdat+0(4) = w_verrdat+0(4) + 1.
      ENDIF.
      w_verrdat = w_verrdat - 1.
  ENDCASE.
*
  CHECK w_verr GE w_kehricht-verr_datum.                  "Achtung!!!
* Prüfen ob nicht bereits fakturiert
  DATA l_wied.
  CLEAR l_wied.
  IF p_wied IS INITIAL.
    SELECT        * FROM  zsd_05_kehr_auft
           WHERE  stadtteil        = w_kehricht-stadtteil
           AND    parzelle         = w_kehricht-parzelle
           AND    objekt           = w_kehricht-objekt
           ORDER BY verr_datum.
* Überschneidungen in der Fakturaperiode
      IF zsd_05_kehr_auft-verr_datum_schl GT w_verr.
        CLEAR t_fehler.
        MOVE-CORRESPONDING zsd_05_kehr_auft TO t_fehler.
        CONCATENATE 'Überschneidungen in der Fakturaperiode:'
                    zsd_05_kehr_auft-verr_datum_schl
                    w_verr
               INTO t_fehler-text
                    SEPARATED BY space.
        APPEND t_fehler.
        l_wied = 'X'.
      ENDIF.
    ENDSELECT.
    IF sy-subrc = 0.
*      w_verr = zsd_05_kehr_auft-verr_datum_schl + 1.     "Epo20131219
*      w_verr soll immer gemäss gesetztem Parameter bestehen bleiben!!!
    ENDIF.
  ENDIF.
  CHECK l_wied IS INITIAL.
  l_betrag = w_kehricht-jahresgebuehr.
  CONDENSE l_betrag.
  ADD 10 TO t_order_items-itm_number.
  MOVE: w_kehrmat-pausch         TO t_order_items-material,
        1                        TO t_order_items-target_qty,
        w_kehricht-bez_pauschal  TO t_order_items-short_text,
        t_order_items-itm_number TO t_order_schedules-itm_number,
        1                        TO t_order_schedules-req_qty.
* Positionszeile
  MOVE: t_order_items-itm_number TO t_order_text-itm_number,
        '0001'                   TO t_order_text-text_id,
        sy-langu                 TO t_order_text-langu,
        '*'                      TO t_order_text-format_col.
  CONCATENATE 'Jahresgebühr Fr.' l_betrag
              INTO t_order_text-text_line SEPARATED BY space.
  APPEND t_order_text.
* Anteilsmässige Verrechnung
  IF w_verr+0(4) = w_verrdat+0(4).
    l_monate = w_verrdat+4(2) - w_verr+4(2) + 1.
  ELSE.
*   keine Jahresübergreifende Faktura mehr gewünscht      "Epo20131219
*    l_monate = 12 - w_verr+4(2) + 1 + w_verrdat+4(2).    "Epo20131219
    l_monate = w_verrdat+4(2).                            "Epo20131219
  ENDIF.
  IF w_verrdat GT w_kehricht-verr_datum_schl.
    IF w_verr+0(4) = w_kehricht-verr_datum_schl+0(4).
      l_monate = w_kehricht-verr_datum_schl+4(2) - w_verr+4(2) + 1.
*    ELSE.                                                "Epo20131219
*      l_monate = 12 - w_verr+4(2) + 1                    "Epo20131219
*               + w_kehricht-verr_datum_schl+4(2).        "Epo20131219
      l_monate = w_kehricht-verr_datum_schl+4(2).
    ENDIF.
    w_verrdat = w_kehricht-verr_datum_schl.
  ENDIF.
  w_betrag1 = w_kehricht-jahresgebuehr
            * l_monate / 12.
  IF w_betrag1 NE w_kehricht-jahresgebuehr.
    CONCATENATE 'Anteil für' l_monate 'Monate'
           INTO t_order_text-text_line SEPARATED BY space.
    APPEND t_order_text.
    CONCATENATE l_betrag ': 12 x'
                l_monate '='
           INTO t_order_text-text_line SEPARATED BY space.
    MOVE w_betrag1 TO l_text.
    CONDENSE l_text.
    CONCATENATE t_order_text-text_line l_text
           INTO t_order_text-text_line SEPARATED BY space.
    APPEND t_order_text.
  ENDIF.
  IF NOT p_liste IS INITIAL.
    WRITE: / w_verr,
             w_verrdat,
             w_kehricht-stadtteil,
             w_kehricht-parzelle,
             w_kehricht-objekt,
             '       1    ',
             '*',
             (16) w_kehricht-jahresgebuehr,
             '=',
             'Fakturabetrag:',
             w_betrag1.
  ENDIF.
  IF NOT t_order_items IS INITIAL.
    APPEND t_order_items.
  ENDIF.
  IF NOT t_order_schedules IS INITIAL.
    APPEND t_order_schedules.
  ENDIF.
  MOVE: t_order_items-itm_number TO t_order_conditions-itm_number,
        'PR00'                   TO t_order_conditions-cond_type,
        w_betrag1                TO t_order_conditions-cond_value,
        'CHF'                    TO t_order_conditions-currency.
  APPEND t_order_conditions.
*
ENDFORM.                    " calc_grundgebuehr
*
*&---------------------------------------------------------------------*
*&      Form  daten_lesen
*&---------------------------------------------------------------------*
*       Zu verarbeitenden Daten lesen
*----------------------------------------------------------------------*
FORM daten_lesen.

  SELECT SINGLE * FROM  zsd_04_kehr_mat CLIENT SPECIFIED
         INTO   w_kehrmat
         WHERE  mandt  = sy-mandt.
*             and begda lt sy-datum   "LULU SCD 20130808  "Epo20131107
*             and endda = '99991231'. "LULU SCD 20130808  "Epo20131107
  SELECT        * FROM  zsd_04_kehricht
         INTO TABLE t_kehricht
         WHERE  stadtteil       IN s_stadtt
         AND    parzelle        IN s_parzel
         AND    objekt          IN s_objekt
         AND    verr_perio      IN s_perio
         AND    verr_datum      LE p_verr
         AND    verr_datum_schl GE p_verr
         and    verr_code       eq space.                 "Epo20131202
  SORT t_kehricht BY stadtteil parzelle objekt.
* Bei Wiederholung darf nur 1 Objekt selektiert werden
  IF NOT p_wied IS INITIAL.
    IF sy-dbcnt NE 1.
      MOVE: 'ZTAB' TO msg-msgid,
            'A'    TO msg-msgty,
            '000'  TO msg-msgno,
            'Bei Auftragswiederholung nur 1 Objekt wählbar'
                   TO msg-msgv1.
      CALL FUNCTION 'BAL_MSG_DISPLAY_ABAP'
           EXPORTING
                i_s_msg = msg.
      LEAVE TO TRANSACTION sy-tcode.
    ENDIF.
  ENDIF.
  SELECT        * FROM  zsd_05_objekt
         INTO TABLE t_objekt
         FOR ALL ENTRIES IN t_kehricht
         WHERE  stadtteil  = t_kehricht-stadtteil
         AND    parzelle   = t_kehricht-parzelle
         AND    objekt     = t_kehricht-objekt.
  SORT t_objekt BY stadtteil parzelle objekt.
  SELECT        * FROM  a004
       INTO TABLE t_a004
       WHERE  kappl    = 'V'
       AND    kschl    = 'PR00'
       AND    datab   LE sy-datum
       AND    datbi   GE sy-datum.
  SORT t_a004 BY knumh kappl kschl.
  SELECT        * FROM  konp
         INTO TABLE t_konp
         FOR ALL ENTRIES IN t_a004
         WHERE  knumh  = t_a004-knumh
         AND    kappl  = t_a004-kappl
         AND    kschl  = t_a004-kschl.
  SORT t_konp BY knumh kopos.

ENDFORM.                    " daten_lesen
*
*&---------------------------------------------------------------------*
*&      Form  fehler_suchen
*&---------------------------------------------------------------------*
*       Mögliche Fehler suchen
*----------------------------------------------------------------------*
FORM fehler_suchen.

  LOOP AT t_kehricht INTO w_kehricht.
    clear sy-subrc.                                       "EpO20131203
    PERFORM grund_keine_verrechnung changing sy-subrc.
*                                   changing sy-Subrc     "EpO20131202
*>>> Start >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> "EpO20131202
     if sy-subrc eq 99. "d.h. Fehler wurde ermittelt
        delete t_kehricht from w_kehricht.
     endif.
*<<< Ende  <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< "EpO20131202
  ENDLOOP.
  SORT t_fehler BY stadtteil parzelle objekt.

ENDFORM.                    " fehler_suchen
*
*&---------------------------------------------------------------------*
*&      Form  verarbeitung
*&---------------------------------------------------------------------*
*       Daten verarbeiten
*----------------------------------------------------------------------*
FORM verarbeitung.

  FORMAT COLOR COL_POSITIVE.
  LOOP AT t_kehricht INTO w_kehricht.
    READ TABLE t_fehler WITH KEY stadtteil = w_kehricht-stadtteil
                                 parzelle  = w_kehricht-parzelle
                                 objekt    = w_kehricht-objekt.
*                                 BINARY SEARCH.
* Objekt darf nicht in Fehlertabelle vorhanden sein
    CHECK sy-subrc NE 0.
    CLEAR: w_order_header,
           w_salesdocument.
    REFRESH: t_return,
             t_order_items,
             t_order_partners,
             t_order_schedules,
             t_order_conditions,
             t_order_text.
    CLEAR: t_return,
           t_order_items,
           t_order_partners,
           t_order_schedules,
           t_order_conditions,
           t_order_text.
    PERFORM calc_betrag USING w_kehricht-vflaeche_fakt1
                              w_kehrmat-matnr_1
                              w_kehricht-bez_fakt1.
    PERFORM calc_betrag USING w_kehricht-vflaeche_fakt2
                              w_kehrmat-matnr_2
                              w_kehricht-bez_fakt2.
    PERFORM calc_betrag USING w_kehricht-vflaeche_fakt3
                              w_kehrmat-matnr_3
                              w_kehricht-bez_fakt3.

*  Todo SCD Anfang      Material 4 und 5 entfallen ab 2013
*    PERFORM calc_betrag USING w_kehricht-vflaeche_fakt4
*                              w_kehrmat-matnr_4
*                              w_kehricht-bez_fakt4.
*    PERFORM calc_betrag USING w_kehricht-vflaeche_fakt5
*                              w_kehrmat-matnr_5
*                              w_kehricht-bez_fakt5.
*  Todo SCD Ende

    IF w_kehricht-jahresgebuehr NE 0.
      PERFORM calc_grundgebuehr USING w_kehricht-verr_perio.
    ENDIF.
    PERFORM auftrag_anlegen.
  ENDLOOP.
  WRITE: / 'Erzeugte Kundenaufträge:',
           w_vbeln_first, '-',
           w_vbeln_last.

ENDFORM.                    " verarbeitung
*----------------------------------------------------------------------
form Partner_Daten_build.
*>>> Neue Partnerfindung ab Nov.2013 mit Eigentümer und Vertreter >>>
*    Zur Sicherheit wurde die Alte Logik noch integriert !!!
*>>> Eigentümer ist immer der Regulierer => auch Auftraggeber     >>>
*>>> Wenn Eigentümer nicht bestück wird die alte Version verwendet>>>
*>>> Wenn ein Vertreter definiert ist, berkommt er die Rechnung   >>>
*>>>-------------------------------------------------------------->>>
  DATA l_addr1_sel TYPE addr1_sel.
  DATA l_sadr TYPE sadr.
* Bestücken Auftraggeber und Regulierer - Daten
  if not w_kehricht-eigen_kunnr is initial.
      MOVE: 'AG'                   TO t_order_partners-partn_role,
            w_kehricht-eigen_kunnr TO t_order_partners-partn_numb.
      APPEND t_order_partners.
      MOVE: 'RG'                   TO t_order_partners-partn_role,
            w_kehricht-eigen_kunnr TO t_order_partners-partn_numb.
      APPEND t_order_partners.
  elseif not w_kehricht-kunnr is initial.
*>>> ab hier alt !!!! >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
*  IF NOT w_kehricht-kunnr IS INITIAL.                      "Epo20131107
    MOVE: 'AG'             TO t_order_partners-partn_role,
          w_kehricht-kunnr TO t_order_partners-partn_numb.
    APPEND t_order_partners.
  ELSE.
    IF NOT w_kehricht-adrnr IS INITIAL.
      MOVE: 'AG'         TO t_order_partners-partn_role,
            '0000000870' TO t_order_partners-partn_numb.
      MOVE w_kehricht-adrnr TO l_addr1_sel-addrnumber.
      CALL FUNCTION 'ADDR_GET'
           EXPORTING
                address_selection = l_addr1_sel
                read_sadr_only    = ' '
                read_texts        = ' '
           IMPORTING
                sadr              = l_sadr
           EXCEPTIONS
                parameter_error   = 1
                address_not_exist = 2
                version_not_exist = 3
                internal_error    = 4
                OTHERS            = 5.
      IF sy-subrc = 0.
        MOVE: l_sadr-anred TO t_order_partners-title,
              l_sadr-name1 TO t_order_partners-name,
              l_sadr-name2 TO t_order_partners-name_2,
              l_sadr-name3 TO t_order_partners-name_3,
              l_sadr-name4 TO t_order_partners-name_4,
              l_sadr-pfach TO t_order_partners-po_box,
              l_sadr-pstlz TO t_order_partners-postl_code,
              l_sadr-land1 TO t_order_partners-country,
              l_sadr-ort01 TO t_order_partners-city.
        CONCATENATE l_sadr-stras l_sadr-hausn
               INTO t_order_partners-street SEPARATED BY space.
        APPEND t_order_partners.
      ENDIF.
    ENDIF.
  ENDIF.
*<<< bis hier hin alles alt ... <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
  if not w_kehricht-vertr_kunnr is initial.
      MOVE: 'RE'                   TO t_order_partners-partn_role,
            w_kehricht-vertr_kunnr TO t_order_partners-partn_numb.
      APPEND t_order_partners.
  endif.
*  IF NOT t_order_partners IS INITIAL.
*    APPEND t_order_partners.
*  ENDIF.
endform." Partner_Daten_build.
*----------------------------------------------------------------------*
form check_vertriebsbelege using zsd_05_kehr_auft type zsd_05_kehr_auft
                        changing lw_kz_abgesagt   type char1.
 data: lw_keine_faktura type c
     , l_key_vbeln      type vbeln
     , lw_vbeln         type vbeln
     , ls_vbrk          type vbrk
     , ls_vbuk          type vbuk
     , lw_length        type i
     .
 if not zsd_05_kehr_auft-faknr is initial.
    clear l_key_vbeln.
    move zsd_05_kehr_auft-faknr to l_key_vbeln.
    do.
      lw_length = strlen( l_key_vbeln ).
      if lw_length eq 10.
         exit.
      else.
        move: '0'             to lw_vbeln+0(1)
            , l_key_vbeln(9)  to lw_vbeln+1(9).
        move: lw_vbeln        to l_key_vbeln.
      endif.
    enddo.
    select single * from vbrk into ls_vbrk
                              where vbeln eq l_key_vbeln
                              and   FKSTO eq space.
    if sy-subrc ne 0.
       lw_keine_faktura = 'X'.
    endif.
 else.
    lw_keine_faktura = 'X'.
 endif.
 if lw_keine_faktura eq 'X'. "Faktura noch nicht erstellt oder storniert
    clear l_key_vbeln.
    move zsd_05_kehr_auft-vbeln to l_key_vbeln.
    do.
      lw_length = strlen( l_key_vbeln ).
      if lw_length eq 10.
         exit.
      else.
        move: '0'             to lw_vbeln+0(1)
            , l_key_vbeln(9)  to lw_vbeln+1(9).
        move: lw_vbeln        to l_key_vbeln.
      endif.
    enddo.
    select single * from vbuk into ls_vbuk
                              where vbeln eq l_key_vbeln
                              and   ABSTK eq 'C'.
    if sy-subrc eq 0. "d.h. Auftrag ist komplett abgesagt
       lw_kz_abgesagt = 'X'.
    else.
       clear lw_kz_abgesagt.
    endif.
 endif.
*
endform." check_vertriebsbelege using ...
