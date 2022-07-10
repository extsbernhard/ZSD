*_____Reportinfos_______________________________________________________
* Dieser Report exportiert sämtliche Daten aus der Kontraktverwaltung
* als CSV-Datei, die für die GIS-Schnittstelle verwendet werden.

* Tiefbauamt der Stadt Bern
* Exportprogramm für GIS-Schnittstelle, Kontraktverwaltung
*
* Entwicklung:
* Sascha Weber, Informatikdienste der Stadt Bern, 29.08.2005


REPORT  zsd_05_gis_export01 NO STANDARD PAGE HEADING.





*____Tabellen___________________________________________________________

TABLES: zsd_05_kontrakt,   "Kontrakte
        zsd_05_kontrpos,   "Kontraktposition
        zsd_05_kontrupos,  "Kontraktunterposition
        kna1,              "Kundenstamm (allgemeiner Teil)
        lfa1,              "Lieferantenstamm (allgemeiner Teil)
        adrc.              "Adressen (zentrale Adreßverwaltung)





*____Interne Tabellen, Workareas, Ranges________________________________

DATA: BEGIN OF it_kontrakt OCCURS 0.
        INCLUDE STRUCTURE zsd_05_kontrakt.
DATA: END OF it_kontrakt.

DATA: wa_kontrakt LIKE it_kontrakt.



DATA: BEGIN OF it_kontrpos OCCURS 0.
        INCLUDE STRUCTURE zsd_05_kontrpos.
DATA: END OF it_kontrpos.

DATA: wa_kontrpos LIKE it_kontrpos.



DATA: BEGIN OF it_kontrupos OCCURS 0.
        INCLUDE STRUCTURE zsd_05_kontrupos.
DATA: END OF it_kontrupos.

DATA: wa_kontrupos LIKE it_kontrupos.



*DATA: BEGIN OF it_gis_read OCCURS 0.
*        INCLUDE STRUCTURE zsd_05_csv_gisexport01.
*DATA: END OF it_gis_read.
*
*DATA: wa_gis_read LIKE it_gis_read.



DATA: BEGIN OF it_gis_export OCCURS 0.
        INCLUDE STRUCTURE zsd_05_csv_gisexport01.
DATA: END OF it_gis_export.

DATA: wa_gis_export LIKE it_gis_export.





*_____Variablen und Konstanten__________________________________________

DATA: lv_records   TYPE num6,
      lv_rectype   TYPE num1,


      wa_adrc      TYPE adrc,
      wa_kna1      TYPE kna1,
      wa_lfa1      TYPE lfa1,

      lv_trz(1)    TYPE c VALUE ';',

      lv_file      TYPE rlgrap-filename,

      lv_ftype     TYPE rlgrap-filetype
                        VALUE 'ASC',

      lv_jahr(4)   TYPE c,
      lv_monat(2)  TYPE c,
      lv_tag(2)    TYPE c,
      lv_punkt(1)  TYPE c VALUE '.'.






*_____Inculdes__________________________________________________________

INCLUDE zsd_05_gis_exportf01.





*_____Aufbereitung und Export___________________________________________

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  SELECT * FROM zsd_05_kontrakt INTO
    CORRESPONDING FIELDS OF TABLE it_kontrakt.



  LOOP AT it_kontrakt.
    SELECT * FROM zsd_05_kontrpos INTO
      CORRESPONDING FIELDS OF TABLE it_kontrpos
      WHERE kontrart = it_kontrakt-kontrart
      AND   kontrnr  = it_kontrakt-kontrnr.

    IF sy-subrc = 0.
      CLEAR wa_gis_export.

*   Adresse wird für den aktuellen Kontrakt ermittelt
      IF NOT it_kontrakt-kontrnehmernr IS INITIAL.
        CASE it_kontrakt-code_kontrnehmer.
          WHEN 'K'.
            PERFORM read_kundenadr USING it_kontrakt-kontrnehmernr.
          WHEN 'L'.
            PERFORM read_lieferadr USING it_kontrakt-kontrnehmernr.
        ENDCASE.
      ELSEIF NOT it_kontrakt-adrnr IS INITIAL.
        PERFORM read_adrc USING it_kontrakt-adrnr.
      ENDIF.



      LOOP AT it_kontrpos.
        SELECT * FROM zsd_05_kontrupos INTO
          CORRESPONDING FIELDS OF TABLE it_kontrupos
          WHERE kontrart = it_kontrpos-kontrart
          AND   kontrnr  = it_kontrpos-kontrnr
          AND   posnr    = it_kontrpos-posnr.

        IF sy-subrc = 0.
          LOOP AT it_kontrupos.
*         Counter für Anzahl Records
            lv_records = lv_records + 1.

*         Satzart wird definiert
            IF sy-tabix = 1.
              wa_gis_export-satzart = 0.
            ELSE.
              wa_gis_export-satzart = 1.
            ENDIF.

*         Weitere Felder werden gefüllt
            wa_gis_export-stadtteil        = it_kontrpos-stadtteil.
            wa_gis_export-parzelle         = it_kontrpos-parzelle.
            wa_gis_export-kontrart         = it_kontrpos-kontrart.
            wa_gis_export-kontrnr          = it_kontrpos-kontrnr.
            wa_gis_export-posnr            = it_kontrpos-posnr.
            wa_gis_export-kontrtyp         = it_kontrakt-kontrtyp.
          wa_gis_export-code_kontrnehmer = it_kontrakt-code_kontrnehmer.
            wa_gis_export-kontrnehmernr    = it_kontrakt-kontrnehmernr.
            wa_gis_export-adrnr            = it_kontrakt-adrnr.

*            wa_gis_export-kasdat           = it_kontrakt-kasdat.
            CLEAR: lv_jahr, lv_monat, lv_tag.
            lv_jahr  = it_kontrakt-kasdat(4).
            lv_monat = it_kontrakt-kasdat+4(2).
            lv_tag   = it_kontrakt-kasdat+6(2).

            CONCATENATE lv_jahr lv_punkt lv_monat lv_punkt lv_tag
              INTO wa_gis_export-kasdat.

            wa_gis_export-matnr            = it_kontrpos-matnr.
            wa_gis_export-matxt            = it_kontrpos-matxt.
            wa_gis_export-objlaenge        = it_kontrpos-objlaenge.
            wa_gis_export-objbreite        = it_kontrpos-objbreite.
            wa_gis_export-objhoehe         = it_kontrpos-objhoehe.
            wa_gis_export-menge_pos        = it_kontrpos-menge_pos.
            wa_gis_export-meins            = it_kontrpos-meins.
            wa_gis_export-preis            = it_kontrpos-preis.
            wa_gis_export-peinh            = it_kontrpos-peinh.
            wa_gis_export-verrtyp          = it_kontrpos-verrtyp.
            wa_gis_export-index_key        = it_kontrpos-index_key.
            wa_gis_export-index_basis      = it_kontrpos-index_basis.
            wa_gis_export-index_gjahr      = it_kontrpos-index_gjahr.
            wa_gis_export-index_monat      = it_kontrpos-index_monat.
            wa_gis_export-index_stand      = it_kontrpos-index_stand.
            wa_gis_export-index_diff       = it_kontrpos-index_diff.
            wa_gis_export-index_diffeinh   = it_kontrpos-index_diffeinh.
           wa_gis_export-index_diffstand  = it_kontrpos-index_diffstand.
            wa_gis_export-faktperiode      = it_kontrpos-faktperiode.

*            wa_gis_export-faktdatab        = it_kontrpos-faktdatab.
            CLEAR: lv_jahr, lv_monat, lv_tag.
            lv_jahr  = it_kontrpos-faktdatab(4).
            lv_monat = it_kontrpos-faktdatab+4(2).
            lv_tag   = it_kontrpos-faktdatab+6(2).

            CONCATENATE lv_jahr lv_punkt lv_monat lv_punkt lv_tag
              INTO wa_gis_export-faktdatab.

*            wa_gis_export-faktdatbis       = it_kontrpos-faktdatbis.
            CLEAR: lv_jahr, lv_monat, lv_tag.
            lv_jahr  = it_kontrpos-faktdatbis(4).
            lv_monat = it_kontrpos-faktdatbis+4(2).
            lv_tag   = it_kontrpos-faktdatbis+6(2).

            CONCATENATE lv_jahr lv_punkt lv_monat lv_punkt lv_tag
              INTO wa_gis_export-faktdatbis.

            wa_gis_export-verr_code        = it_kontrpos-verr_code.
            wa_gis_export-verr_grund       = it_kontrpos-verr_grund.
            wa_gis_export-upos_stadtteil   = it_kontrupos-stadtteil.
            wa_gis_export-upos_parzelle    = it_kontrupos-parzelle.

*         Datensatz in der internen Tabelle einfügen
            APPEND wa_gis_export TO it_gis_export.

          ENDLOOP.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDLOOP.



*Kontrollzeile anfügen
  CLEAR wa_gis_export.
  wa_gis_export-satzart = 9.
  wa_gis_export-verr_grund = 'Anzahl inkl. Kontrollzeile:'.
  wa_gis_export-anzahl  = lv_records + 1.

  APPEND wa_gis_export TO it_gis_export.



*Trennzeichen setzen
  LOOP AT it_gis_export.
   MOVE lv_trz TO it_gis_export-tz01. MOVE lv_trz TO it_gis_export-tz02.
   MOVE lv_trz TO it_gis_export-tz03. MOVE lv_trz TO it_gis_export-tz04.
   MOVE lv_trz TO it_gis_export-tz05. MOVE lv_trz TO it_gis_export-tz06.
   MOVE lv_trz TO it_gis_export-tz07. MOVE lv_trz TO it_gis_export-tz08.
   MOVE lv_trz TO it_gis_export-tz09. MOVE lv_trz TO it_gis_export-tz10.
   MOVE lv_trz TO it_gis_export-tz11. MOVE lv_trz TO it_gis_export-tz12.
   MOVE lv_trz TO it_gis_export-tz13. MOVE lv_trz TO it_gis_export-tz14.
   MOVE lv_trz TO it_gis_export-tz15. MOVE lv_trz TO it_gis_export-tz16.
   MOVE lv_trz TO it_gis_export-tz17. MOVE lv_trz TO it_gis_export-tz18.
   MOVE lv_trz TO it_gis_export-tz19. MOVE lv_trz TO it_gis_export-tz20.
   MOVE lv_trz TO it_gis_export-tz21. MOVE lv_trz TO it_gis_export-tz22.
   MOVE lv_trz TO it_gis_export-tz23. MOVE lv_trz TO it_gis_export-tz24.
   MOVE lv_trz TO it_gis_export-tz25. MOVE lv_trz TO it_gis_export-tz26.
   MOVE lv_trz TO it_gis_export-tz27. MOVE lv_trz TO it_gis_export-tz28.
   MOVE lv_trz TO it_gis_export-tz29. MOVE lv_trz TO it_gis_export-tz30.
   MOVE lv_trz TO it_gis_export-tz31. MOVE lv_trz TO it_gis_export-tz32.
   MOVE lv_trz TO it_gis_export-tz33. MOVE lv_trz TO it_gis_export-tz34.
   MOVE lv_trz TO it_gis_export-tz35. MOVE lv_trz TO it_gis_export-tz36.
   MOVE lv_trz TO it_gis_export-tz37. MOVE lv_trz TO it_gis_export-tz38.
   MOVE lv_trz TO it_gis_export-tz39. MOVE lv_trz TO it_gis_export-tz40.
   MOVE lv_trz TO it_gis_export-tz41. MOVE lv_trz TO it_gis_export-tz42.

    MODIFY it_gis_export.
  ENDLOOP.

  CONCATENATE 'C:\temp\SAP_GIS_' sy-datum '_' sy-uzeit(4) '.csv'
    INTO lv_file.

*Download der internen Tabelle als CSV-Datei
  CALL FUNCTION 'WS_DOWNLOAD'
       EXPORTING
            filename = lv_file
            filetype = lv_ftype
       TABLES
            data_tab = it_gis_export.

  .
*  IF sy-subrc <> 0.
** MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
**         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*  ENDIF.
*
