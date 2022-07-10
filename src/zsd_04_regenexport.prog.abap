
REPORT  zsd_04_regenexport NO STANDARD PAGE HEADING.

*_____Reportinfos_______________________________________________________

* Dieser Report exportiert sämtliche Informationen für die Auftrags-
* erstellung der Regenabwasser-Verrechnung in eine CSV-Datei

* 07.12.2004 Report angelegt                           IDSWE, Stadt Bern
* 08.08.2006 Erweiterung Auslesen Debitorenadresse     IDSWE, Stadt Bern





*_____Tabellen__________________________________________________________

TABLES: zsd_05_objekt,    "Liegenschaftsobjekte
        zsd_04_regen,     "Gebühren: Regenabwasser-Verrechnungs-Info
        zsd_04_regeninfo. "Gebühren: Regenabwasser-Verrechnungs-Info





*____Interne Tabellen, Workareas, Ranges________________________________

DATA: BEGIN OF it_objekt OCCURS 0.
        INCLUDE STRUCTURE zsd_05_objekt.
DATA: END OF it_objekt.

DATA: wa_objekt LIKE it_objekt.



DATA: BEGIN OF it_regen OCCURS 0.
        INCLUDE STRUCTURE zsd_04_regen.
DATA: END OF it_regen.

DATA: wa_regen LIKE it_regen.



DATA: BEGIN OF it_export OCCURS 0.
        INCLUDE STRUCTURE zsd_01_csv_trennzeichen.
DATA:   tzxx    TYPE char1,
        ktrbetr TYPE char30.
DATA: END OF it_export.

DATA: wa_export LIKE it_export.



DATA: it_adrval TYPE addr1_val.



DATA: BEGIN OF it_hinweisre OCCURS 0,
        hinweis TYPE zsd_04_regen-hinweis1,
        hintext TYPE zsd_04_regen-hintext1,
      END OF it_hinweisre.

DATA: wa_hinweisre LIKE it_hinweisre.




*____Variablen und Konstanten___________________________________________

DATA: ls_addr_sel TYPE addr1_sel,
      lv_cpdkd    TYPE ad_addrnum,
      lv_cpdkdkm  TYPE ad_addrnum,
      lv_auart    TYPE auart,
      lv_jahr(4)  TYPE n,
      lv_matnr1   TYPE matnr,
      lv_matbz1   TYPE maktx,
      lv_mattx1   TYPE text72,
      lv_preis1   TYPE p DECIMALS 2,
      lv_leist1   TYPE p,
      lv_matnr2   TYPE matnr,
      lv_matbz2   TYPE maktx,
      lv_mattx2   TYPE text72,
      lv_preis2   TYPE p DECIMALS 2,
      lv_leist2   TYPE p,
      lv_flbas    TYPE p DECIMALS 2,
      lv_negzl1   TYPE string,
      lv_negzl2   TYPE string,
      lv_aktxt1   TYPE text72,
      lv_aktxt2   TYPE string,"text144,
      lv_aktxt3   TYPE text72,
      lv_aktxt4   TYPE text72,
      lv_aktxt5   TYPE text72,

      lv_flmen1   TYPE string,
      lv_flmen2   TYPE string,
      lv_flmen3   TYPE string,
      lv_flmen4   TYPE string,
      lv_flred1   TYPE string,

      lv_przfl1   TYPE string,
      lv_przfl2   TYPE string,
      lv_przfl3   TYPE string,
      lv_przfl4   TYPE string,
      lv_redfl1   TYPE string,
      lv_posmeng  TYPE string,

      lv_redukt1  TYPE string,
      lv_redukt2  TYPE string,

      lv_flein(2) TYPE c,

      lv_lcount   TYPE i,
      lv_count    TYPE i,
      lv_trz(1)   TYPE c,

      lv_bstkd    LIKE wa_export-bstkd,
      lv_cpdvkbur TYPE vkbur,

      lv_msg      TYPE string.



*_____Inculdes__________________________________________________________
INCLUDE z_data.



*_____Selektionsbild____________________________________________________
PARAMETERS:  pa_file TYPE rlgrap-filename
               DEFAULT 'C:\Temp\Autrag_Regenabwasser.csv',
             pa_type TYPE rlgrap-filetype
               DEFAULT 'ASC'.




*_____Auswertung________________________________________________________
START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
* VARIABLEN FÜLLEN
  lv_cpdkd    = '880'.
  lv_cpdkdkm  = '881'.
  lv_cpdvkbur = '8810'.

  lv_auart    = 'Z850'.
  lv_jahr     = sy-datum(4).
  lv_matnr1   = '8500031'.

  CONCATENATE 'Regenabwassergebühr für das Jahr' lv_jahr INTO lv_matbz1
         SEPARATED BY space.

  CONCATENATE 'Grundlage ist die Verordnung über den Abwassertarif'
         'der Stadt Bern' INTO lv_mattx1 SEPARATED BY space.

  lv_preis1 = '70'.
  lv_flbas  = '150'.
  lv_matnr2 = '8500031'.
  lv_matbz2 = 'Rabatt begrünte Dachfläche'.
  lv_preis2 = '-14'.

  CONCATENATE 'Versickerungsanlage bei der gebührenpflichtigen'
         'Fläche berücksichtigt.' INTO lv_aktxt2 SEPARATED BY space.

  lv_trz = ';'.
  lv_count = 0.

  lv_flein = 'm2'.



* TITEL 1 FORTSCHREIBEN
  CLEAR wa_export.

  wa_export-vkorg     = 'Auftragsinfo'.
  wa_export-anw       = 'Kundeninfo'.
  wa_export-posmat    = 'Materialinfo'.
  wa_export-aktext1   = 'Auftragskopf'.
  wa_export-afttext1  = 'Auftragsschluss'.

  APPEND wa_export TO it_export.


* TITEL 2 FORTSCHREIBEN
  CLEAR wa_export.

  wa_export-vkorg     = 'VOrg'.
  wa_export-vtweg     = 'Vw'.
  wa_export-spart     = 'Sparte'.
  wa_export-vkbur     = 'VBur'.
  wa_export-auart     = 'Auftr-Art'.
  wa_export-datum     = 'Fakt-Dat.'.
  wa_export-anw       = 'Einw-Nr'.
  wa_export-debno     = 'SAP-Nr'.
  wa_export-chngnr    = 'K-Wechsel'.
  wa_export-anrede    = 'Anrede'.
  wa_export-debtxt1   = 'Name1'.
  wa_export-debtxt2   = 'Name2'.
  wa_export-bedtxt21  = 'Name3'.
  wa_export-debtxt3   = 'Strasse'.
  wa_export-debtxt7   = 'HNr1'.
  wa_export-debtxt8   = 'HNr2'.
  wa_export-debtxt4   = 'Postfach'.
  wa_export-debtxt5   = 'PLZ'.
  wa_export-debtxt6   = 'Ort'.
  wa_export-posmat    = 'Mat-Nr'.
  wa_export-posmatx   = 'Mat-Bezeichnung'.
  wa_export-posmeng   = 'Menge'.
  wa_export-pospreis  = 'Preis'.
  wa_export-postxt1   = 'PTxt1'.
  wa_export-postxt2   = 'PTxt2'.
  wa_export-postxt3   = 'PTxt3'.
  wa_export-aktext1   = 'AK-Text1'.
  wa_export-aktext2   = 'AK-Text2'.
  wa_export-aktext3   = 'AK-Text3'.
  wa_export-aktext4   = 'AK-Text4'.
  wa_export-aktext5   = 'AK-Text5'.
  wa_export-afttext1  = 'AS-Text1'.
  wa_export-afttext2  = 'AS-Text2'.
  wa_export-afttext3  = 'AS-Text3'.
  wa_export-afttext4  = 'AS-Text4'.
  wa_export-afttext5  = 'AS-Text5'.
  wa_export-afttext6  = 'AS-Text6'.
  wa_export-afttext7  = 'AS-Text7'.
  wa_export-bstkd     = 'Index'.
  wa_export-ktrbetr    = 'Ktrbetr'.

  APPEND wa_export TO it_export.


  CLEAR wa_export.


  SELECT * FROM zsd_04_regen INTO TABLE it_regen
    WHERE verr_datum    LE sy-datum
    AND   verr_code     EQ ''
    AND   parz_flaeche3 GT 0.



  LOOP AT it_regen INTO wa_regen.
    CLEAR wa_export.
    CLEAR ls_addr_sel.


*   INFO ZUR VERKAUFSORGANISATION
    wa_export-vkorg = wa_regen-vkorg. "Feld A
    wa_export-vtweg = wa_regen-vtweg. "Feld B
    wa_export-spart = wa_regen-spart. "Feld C
    wa_export-vkbur = wa_regen-vkbur. "Feld D
    wa_export-auart = 'Z850'.         "Feld E
*   Feld F bleibt leer



*   INFO ZUR KUNDENADRESSE

*   Feld G bleibt leer

    IF ( wa_regen-kunnr IS INITIAL AND wa_regen-adrnr IS INITIAL ).
      SELECT SINGLE * FROM zsd_05_objekt INTO wa_objekt
        WHERE stadtteil = wa_regen-stadtteil
        AND   parzelle  = wa_regen-parzelle
        AND   objekt    = wa_regen-objekt.

*      if not wa_objekt-verwalter is initial.
*        wa_export-debno        = wa_objekt-verwalter. "Feld H
*
**       Adresse für Debitor auslesen (08.08.2006, Erweiterung, IDSWE)
*        select single adrnr from kna1 into ls_addr_sel-addrnumber
*          where kunnr = wa_export-debno.
*        perform set_addr_data.
*      else.
*        ls_addr_sel-addrnumber = wa_objekt-addrnumber_ver.
*        if not ls_addr_sel-addrnumber is initial.
*          perform set_addr_data.
*          wa_export-vkbur = lv_cpdvkbur.
*          if wa_regen-hinw_code_ei eq 'KM'. "Feld H, CPD-Kunde
*            wa_export-debno        = lv_cpdkdkm.
*          else.
*            wa_export-debno        = lv_cpdkd.
*          endif.
*        endif.
*      endif.
    ELSE.
      IF NOT wa_regen-kunnr IS INITIAL.
        wa_export-debno        = wa_regen-kunnr. "Feld H

*       Adresse für Debitor auslesen (08.08.2006, Erweiterung, IDSWE)
        SELECT SINGLE adrnr FROM kna1 INTO ls_addr_sel-addrnumber
          WHERE kunnr = wa_export-debno.
        PERFORM set_addr_data.
      ELSE.
        ls_addr_sel-addrnumber = wa_regen-adrnr.
        IF NOT ls_addr_sel-addrnumber IS INITIAL.
          PERFORM set_addr_data.
          wa_export-vkbur = lv_cpdvkbur.
          IF wa_regen-hinw_code_ei EQ 'KM'. "Feld H, CPD-Kunde
            wa_export-debno        = lv_cpdkdkm.
          ELSE.
            wa_export-debno        = lv_cpdkd.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

*   Kundenwechsel
    lv_count = lv_count + 1.
    wa_export-chngnr = lv_count.



*   INFO ZUM MATERIAL
    wa_export-posmat   = lv_matnr1.          "Feld T
    wa_export-posmatx  = lv_matbz1.          "Feld U
    wa_export-posmeng  = CEIL( wa_regen-parz_flaeche3 / lv_flbas ). "F V
    wa_export-pospreis = lv_preis1.          "Feld W
    wa_export-postxt1  = lv_mattx1.          "Feld X
*   Feld Y und Z bleiben leer

*   Kontrollbetrag
    wa_export-ktrbetr  = wa_export-posmeng * wa_export-pospreis.



*   INFO ZUM AUFTRAG

    CONCATENATE 'P' wa_regen-stadtteil '/' wa_regen-parzelle
      INTO wa_export-bstkd.                         "Feld AM zum voraus

    CONCATENATE wa_regen-stadtteil '/' wa_regen-parzelle
     INTO lv_bstkd.

    CONDENSE wa_export-bstkd NO-GAPS.

    MOVE wa_regen-parz_flaeche  TO lv_przfl1.
    MOVE wa_regen-parz_flaeche3 TO lv_przfl3.

    CONCATENATE lv_przfl1 lv_flein INTO lv_flmen1.
    CONCATENATE lv_przfl3 lv_flein INTO lv_flmen3.

    CONDENSE: lv_flmen1 NO-GAPS, lv_flmen3 NO-GAPS.


    lv_posmeng = wa_export-posmeng.
    CONDENSE lv_posmeng.

    CONCATENATE 'Parzelle:' lv_bstkd 'Fläche:'
      lv_flmen1 'Gebührenpflichtig:' lv_flmen3
      '=' lv_posmeng 'LE'
      INTO wa_export-aktext1 SEPARATED BY space.    "Feld AA

"*-----------------------------------------------------------------------TZI Entfernt, resp. umgebaut, vermute den Fehler hier
    IF ( wa_regen-hinw_code_ve = 'V1' OR wa_regen-hinw_code_ve = 'V2' ).
      wa_export-aktext2 = lv_aktxt2.                "Feld AB
      elseif not wa_regen-rinfo1 is initial and not wa_regen-rinfo2 is initial.
        CONCATENATE wa_regen-rinfo1 wa_regen-rinfo2 into wa_export-aktext2 SEPARATED BY ','.
    ELSEIF NOT wa_regen-rinfo1 IS INITIAL.
      wa_export-aktext2 = wa_regen-rinfo1.          "Feld AB
    ELSEIF NOT wa_regen-rinfo2 IS INITIAL.
      wa_export-aktext2 = wa_regen-rinfo2.          "Feld AB
    ENDIF.
   IF ( wa_regen-hinw_code_ve = 'V1' OR wa_regen-hinw_code_ve = 'V2' ).
      wa_export-aktext2 = lv_aktxt2.                "Feld AB
      else.
 if wa_regen-rinfo2 is not initial.
    wa_regen-rinfo2 = wa_regen-rinfo2.
   endif.
  "
   ENDIF.

    IF ( wa_regen-hinw_code_ve = 'V1' OR wa_regen-hinw_code_ve = 'V2' )
      AND NOT wa_regen-rinfo1 IS INITIAL.
      wa_export-aktext3 = wa_regen-rinfo1.          "Feld AC
    ELSEIF ( wa_regen-hinw_code_ve = 'V1' OR
      wa_regen-hinw_code_ve = 'V2' ) AND wa_regen-rinfo1 IS INITIAL AND
      NOT wa_regen-rinfo2 IS INITIAL.
      wa_export-aktext3 = wa_regen-rinfo2.          "Feld AC
    ENDIF.

    IF ( wa_regen-hinw_code_ve = 'V1' OR wa_regen-hinw_code_ve = 'V2' )
      AND NOT wa_regen-rinfo1 IS INITIAL
      AND NOT wa_regen-rinfo2 IS INITIAL.
      wa_export-aktext4 = wa_regen-rinfo2.          "Feld AD
    ENDIF.
*   Feld AE bleibt leer


*   AUTRAGSSCHLUSSZEILEN

    IF wa_regen-hinweis1(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis1.
      wa_hinweisre-hintext = wa_regen-hintext1.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    IF wa_regen-hinweis2(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis2.
      wa_hinweisre-hintext = wa_regen-hintext2.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    IF wa_regen-hinweis3(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis3.
      wa_hinweisre-hintext = wa_regen-hintext3.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    IF wa_regen-hinweis4(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis4.
      wa_hinweisre-hintext = wa_regen-hintext4.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    IF wa_regen-hinweis5(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis5.
      wa_hinweisre-hintext = wa_regen-hintext5.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    IF wa_regen-hinweis6(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis6.
      wa_hinweisre-hintext = wa_regen-hintext6.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    IF wa_regen-hinweis7(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis7.
      wa_hinweisre-hintext = wa_regen-hintext7.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    IF wa_regen-hinweis8(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis8.
      wa_hinweisre-hintext = wa_regen-hintext8.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    IF wa_regen-hinweis9(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis9.
      wa_hinweisre-hintext = wa_regen-hintext9.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    IF wa_regen-hinweis0(2) EQ 'RE'.
      wa_hinweisre-hinweis = wa_regen-hinweis0.
      wa_hinweisre-hintext = wa_regen-hintext0.
      APPEND wa_hinweisre TO it_hinweisre.
    ENDIF.

    SORT it_hinweisre BY hinweis.


    DESCRIBE TABLE it_hinweisre LINES lv_lcount.


    IF lv_lcount = 1.
      CLEAR: wa_hinweisre.
      READ TABLE it_hinweisre INDEX 1 INTO wa_hinweisre.
      IF sy-subrc = 0.
        CONCATENATE 'Eigentümer:' wa_hinweisre-hintext
          INTO wa_export-afttext1 SEPARATED BY space.     "Feld AF
      ENDIF.
    ELSEIF lv_lcount > 1.
      CLEAR wa_hinweisre.
      wa_export-afttext1 = 'Eigentümer-Info:'.            "Feld AF

      CLEAR wa_hinweisre.
      READ TABLE it_hinweisre INDEX 1 INTO wa_hinweisre.
      IF sy-subrc = 0.
        wa_export-afttext2 = wa_hinweisre-hintext.        "Feld AG
      ENDIF.

      CLEAR wa_hinweisre.
      READ TABLE it_hinweisre INDEX 2 INTO wa_hinweisre.
      IF sy-subrc = 0.
        wa_export-afttext3 = wa_hinweisre-hintext.        "Feld AH
      ENDIF.

      CLEAR wa_hinweisre.
      READ TABLE it_hinweisre INDEX 3 INTO wa_hinweisre.
      IF sy-subrc = 0.
        wa_export-afttext4 = wa_hinweisre-hintext.        "Feld AI
      ENDIF.
    ENDIF.

    CLEAR: wa_hinweisre, it_hinweisre.
    REFRESH it_hinweisre.

*   Felder AJ, AK und AL bleiben leer
*   Feld AM wird zu Beginn der Infos zum Auftrag gefüllt

    IF NOT wa_export-debno IS INITIAL.
      APPEND wa_export TO it_export.



*   RABATTZEILE (REDUKTION) PRO MATERIAL
      IF wa_regen-reduktion > 0.
        CLEAR wa_export.

        IF lv_preis2 LT 0.
          lv_negzl1 = lv_preis2 * -1.
          CONCATENATE '-' lv_negzl1 INTO lv_negzl2.
        ELSE.
          lv_negzl2 = lv_preis2.
        ENDIF.

        wa_export-posmat   = lv_matnr2.          "Feld T

        lv_redukt1 = wa_regen-reduktion.

        CONCATENATE lv_redukt1 lv_flein INTO lv_redukt2.
        CONDENSE lv_redukt2 NO-GAPS.

        CONCATENATE lv_matbz2 lv_redukt2 INTO wa_export-posmatx
          SEPARATED BY space.                    "Feld U

        wa_export-posmeng  = CEIL( wa_regen-reduktion / lv_flbas )."Fld V
        wa_export-pospreis = lv_negzl2.          "Feld W
        wa_export-postxt1  = lv_mattx2.          "Feld X

*     Kontrollbetrag
        CLEAR: lv_negzl1, lv_negzl2.

        IF lv_preis2 LT 0.
          lv_negzl1 = wa_export-posmeng * lv_preis2 * -1.
          CONCATENATE '-' lv_negzl1 INTO lv_negzl2.
        ELSE.
          lv_negzl2 = wa_export-posmeng * lv_preis2.
        ENDIF.

        wa_export-ktrbetr  = lv_negzl2.

        APPEND wa_export TO it_export.
      ENDIF.
    ENDIF.


    CLEAR wa_regen.


  ENDLOOP.

  LOOP AT it_export.
    MOVE lv_trz TO it_export-tz01. MOVE lv_trz TO it_export-tz02.
    MOVE lv_trz TO it_export-tz03. MOVE lv_trz TO it_export-tz04.
    MOVE lv_trz TO it_export-tz05. MOVE lv_trz TO it_export-tz06.
    MOVE lv_trz TO it_export-tz07. MOVE lv_trz TO it_export-tz08.
    MOVE lv_trz TO it_export-tz09. MOVE lv_trz TO it_export-tz10.
    MOVE lv_trz TO it_export-tz11. MOVE lv_trz TO it_export-tz12.
    MOVE lv_trz TO it_export-tz13. MOVE lv_trz TO it_export-tz14.
    MOVE lv_trz TO it_export-tz15. MOVE lv_trz TO it_export-tz16.
    MOVE lv_trz TO it_export-tz17. MOVE lv_trz TO it_export-tz18.
    MOVE lv_trz TO it_export-tz19. MOVE lv_trz TO it_export-tz20.
    MOVE lv_trz TO it_export-tz21. MOVE lv_trz TO it_export-tz22.
    MOVE lv_trz TO it_export-tz23. MOVE lv_trz TO it_export-tz24.
    MOVE lv_trz TO it_export-tz25. MOVE lv_trz TO it_export-tz26.
    MOVE lv_trz TO it_export-tz27. MOVE lv_trz TO it_export-tz28.
    MOVE lv_trz TO it_export-tz29. MOVE lv_trz TO it_export-tz30.
    MOVE lv_trz TO it_export-tz31. MOVE lv_trz TO it_export-tz32.
    MOVE lv_trz TO it_export-tz33. MOVE lv_trz TO it_export-tz34.
    MOVE lv_trz TO it_export-tz35. MOVE lv_trz TO it_export-tz36.
    MOVE lv_trz TO it_export-tz37. MOVE lv_trz TO it_export-tz38.
    MOVE lv_trz TO it_export-tzxx.

    MODIFY it_export.
  ENDLOOP.


  CALL FUNCTION 'WS_DOWNLOAD'
    EXPORTING
      filename = pa_file
      filetype = pa_type
    TABLES
      data_tab = it_export.

  .
  IF sy-subrc <> 0.
    lv_msg = 'Der Download war NICHT erfolgreich!'.
    MESSAGE lv_msg TYPE 'I'.
  ELSE.
    IF sy-uname EQ 'BLASER3'.
      lv_msg = 'Bläsu, läck, dr Download isch fertig!'.
    ELSE.
      lv_msg = 'Der Download war erfolgreich!'.
    ENDIF.
    MESSAGE lv_msg TYPE 'I'.
  ENDIF.
