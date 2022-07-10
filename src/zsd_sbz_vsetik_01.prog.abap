REPORT zsd_sbz_vsetik_01 .
************************************************************************
* Report:      ZSD_SBZ_VSETIK_01        Autor: Oliver Epking           *
* ------------------------------             - Mummert Consulting AG - *
* Transaktion:   ZSBZ_vsetik                                           *
* -----------------------                                              *
* Auftraggeber:  Stadt Bern, Projekt NESA                              *
* ---------------------------------------------                        *
* Beschreibung                                                         *
* ------------                                                         *
* Dieser Report stellt die bereitgestellten Daten über den User-Exit   *
* MV50AFZ1 (Tabelle: ZSBZ_SD_VSETIK_0) dem abrufenden Client zur Ver-  *
* fügung.                                                              *
* -------------------------------------------------------------------- *
* Aenderungsverzeichnis:                                               *
* ----------------------                                               *
* Datum      Rel.   Name               Firma                           *
*                   - Beschreibung                                     *
* ---------- ----   -----------------  ------------------------------- *
* 07.06.2004 4.6C   Oliver Epking      Mummert Consulting AG, Zürich   *
*                   - Neuanlage des Reports                            *
* -------------------------------------------------------------------- *
* 10.10.2012 6.0    Sascha Weber       Stadtverwaltung Bern            *
*                   - Erweiterung für Dienstadresse MA Stadt Bern      *
************************************************************************
* im Programm verwendete Daten-Tabellen
TABLES: zsbz_sd_vsetik_0      "Zwischentabelle für VS-Etikettendaten
      , likp                  "Lieferungen Kopf
      , lips                  "Lieferungen Position
      , vbpa                  "Vertriebsbeleg-Partnerdaten
      , adrp                  "zentrale Adressdaten Personal-Nr.
      , adrc                  "zentrale Adressdaten Adress-Nr.
      , adrct                 "zentrale Texte zu Adressdaten
      , vbak                  "Auftrags Kopfdaten
      , knvk                  "Ansprechpartner(Kunden)
      , tsad3t                "Anreden (Texte) (Business Address Services)
      .
* Tabelle für die Datenübergabe
DATA: BEGIN OF w_vsetik OCCURS 0.
        INCLUDE STRUCTURE zsbz_sd_vsetik_0.
DATA: END   OF w_vsetik.
* Tabelle für die Datenübergabe mit Separator
DATA: BEGIN OF w_vsetik_t OCCURS 0
      , mandt(003) TYPE c "ZSBZ_SD_VSETIK_0-MANDT
      , t1    TYPE c
      , vkorg(004) TYPE c "ZSBZ_SD_VSETIK_0-VKORG
      , t2    TYPE c
      , vstel(004) TYPE c "ZSBZ_SD_VSETIK_0-VSTEL
      , t3    TYPE c
      , vgbel(010) TYPE c "ZSBZ_SD_VSETIK_0-VGBEL
      , t4    TYPE c
      , vbeln(010) TYPE c "ZSBZ_SD_VSETIK_0-VBELN
      , t5    TYPE c
      , lfart(004) TYPE c "ZSBZ_SD_VSETIK_0-LFART
      , t6    TYPE c
      , erdat(010) TYPE c "ZSBZ_SD_VSETIK_0-ERDAT
      , t7    TYPE c
      , erzet(008) TYPE c "ZSBZ_SD_VSETIK_0-ERZET
      , t8    TYPE c
      , uname(012) TYPE c "ZSBZ_SD_VSETIK_0-UNAME
      , t9    TYPE c
      , adrnr(012) TYPE c "ZSBZ_SD_VSETIK_0-ADRNR
      , t10   TYPE c
      , title_medi(030) TYPE c "ZSBZ_SD_VSETIK_0-NAME1
      , t11   TYPE c
      , name1(040) TYPE c "ZSBZ_SD_VSETIK_0-NAME1
      , t12   TYPE c
      , name2(040) TYPE c "ZSBZ_SD_VSETIK_0-NAME2
      , t13   TYPE c
      , name3(040) TYPE c "ZSBZ_SD_VSETIK_0-NAME3
      , t14   TYPE c
      , name4(040) TYPE c "ZSBZ_SD_VSETIK_0-NAME4
      , t15   TYPE c
      , name_co(040) TYPE c "ZSBZ_SD_VSETIK_0-NAME4
      , t16   TYPE c
      , street(060) TYPE c "ZSBZ_SD_VSETIK_0-STREET
      , t17   TYPE c
      , house_num1(012) TYPE c "ZSBZ_SD_VSETIK_0-HOUSE_NUM1
      , t18   TYPE c
      , house_num2(010) TYPE c "ZSBZ_SD_VSETIK_0-HOUSE_NUM2
      , t19   TYPE c
      , STR_SUPPL1(040) TYPE c "ZSBZ_SD_VSETIK_0-STREET
      , t20   TYPE c
      , STR_SUPPL2(040) TYPE c "ZSBZ_SD_VSETIK_0-STREET
      , t21   TYPE c
      , STR_SUPPL3(040) TYPE c "ZSBZ_SD_VSETIK_0-STREET
      , t22   TYPE c
      , post_code1(010) TYPE c "ZSBZ_SD_VSETIK_0-POST_CODE1
      , t23   TYPE c
      , city1(040) TYPE c "ZSBZ_SD_VSETIK_0-CITY1
      , t24   TYPE c
      , country(003) TYPE c "ZSBZ_SD_VSETIK_0-COUNTRY
      , t25   TYPE c
      , tel_number(030) TYPE c "ZSBZ_SD_VSETIK_0-TEL_NUMBER
      , t26   TYPE c
      , tel_extens(010) TYPE c "ZSBZ_SD_VSETIK_0-TEL_EXTENS
      , t27   TYPE c
      , fax_number(030) TYPE c "ZSBZ_SD_VSETIK_0-FAX_NUMBER
      , t28   TYPE c
      , fax_extens(010) TYPE c "ZSBZ_SD_VSETIK_0-FAX_EXTENS
      , t29   TYPE c
      , remark(050) TYPE c "ZSBZ_SD_VSETIK_0-REMARK
      , t30   TYPE c
      , anzpk(005) TYPE c "ZSBZ_SD_VSETIK_0-ANZPK
      , t31   TYPE c
*      , DATUE(001) TYPE C "ZSBZ_SD_VSETIK_0-DATUE
*      , t27   type c
*      , STOKZ(001) TYPE C "ZSBZ_SD_VSETIK_0-STOKZ
*      , t28   type c
*      , UEDAT(010) TYPE C "ZSBZ_SD_VSETIK_0-UEDAT
*      , t29   type c
*      , UEZET(008) TYPE C "ZSBZ_SD_VSETIK_0-UEZET
*      , t30   type c
*      , UENAM(012) TYPE C "ZSBZ_SD_VSETIK_0-UENAM
*      , t31   type c
      ,
      END OF w_vsetik_t.
* Struktur für die Datenübergabe - Feldnamen
DATA: BEGIN OF w_fieldnames OCCURS 0
    ,  name(20) TYPE c
    , END   OF w_fieldnames.

* Datenfelder für die Verarbeitungssteuerung
DATA: w_scha_update    TYPE c."Schalter ob update erforderlich
DATA: i_fnam           TYPE rlgrap-filename.
DATA: s_fnam           TYPE rlgrap-filename.
DATA: w_lines          TYPE i.
DATA: w_ftyp           TYPE rlgrap-filetype.
DATA: w_punkt          TYPE c VALUE '.'.
DATA: w_mode           TYPE c.
DATA: i_mask(100)      TYPE c.
DATA: h_ftyp(8)        TYPE c
    , h_pos            TYPE i
    , lv_adrnr         TYPE adrnr.

*-----------------------------------------------------------------------
SELECT-OPTIONS: s_vkorg   FOR zsbz_sd_vsetik_0-vkorg
                          DEFAULT '1666'
              , s_vstel   FOR zsbz_sd_vsetik_0-vstel
              , s_vbeln   FOR zsbz_sd_vsetik_0-vbeln
              , s_lfart   FOR zsbz_sd_vsetik_0-lfart
                          DEFAULT 'ZLF '
              , s_erdat   FOR zsbz_sd_vsetik_0-erdat
              , s_uname   FOR zsbz_sd_vsetik_0-uname
                          DEFAULT sy-uname
              .
*--------------- Parameter Datenübernahme Kz und Storno Kz -------------
PARAMETERS:     p_datue  TYPE zsbz_sd_vsetik_0-datue
                         DEFAULT ' '
              , p_stokz  TYPE zsbz_sd_vsetik_0-stokz
                         DEFAULT ' '
              .
*--------------- Parameter Adressdaten aktualisieren -------------------
PARAMETERS:     p_aktua  AS CHECKBOX
                         DEFAULT 'X'
              .
*--------------- Parameter Datendownload und Testlauf ------------------
PARAMETERS:     p_dat    RADIOBUTTON GROUP fil1
              , p_wk1    RADIOBUTTON GROUP fil1
              , p_dbf    RADIOBUTTON GROUP fil1
              , p_asc    RADIOBUTTON GROUP fil1
                         DEFAULT 'X'
              , p_head   AS CHECKBOX
                         DEFAULT ' '
              , p_trenn  TYPE c
                         DEFAULT ';'
              , p_appd   AS CHECKBOX
                         DEFAULT 'X'
              , p_fnam   LIKE rlgrap-filename
              , p_test   AS CHECKBOX
              .
*-----------------------------------------------------------------------
INITIALIZATION.
  MOVE  'C:\'               TO i_fnam+00(03).
  MOVE 'Etiketten_Versand\' TO i_fnam+03(18).
  MOVE  'lfeti'             TO i_fnam+21(05).
  MOVE  '_'                 TO i_fnam+26(01).
  MOVE  sy-datum            TO i_fnam+27(08).
  MOVE  '_'                 TO i_fnam+35(01).
  MOVE  sy-uzeit            TO i_fnam+36(06).
  MOVE  '.'                 TO i_fnam+42(01).
  MOVE 'txt'                TO i_fnam+43(03).
  MOVE i_fnam               TO p_fnam.
  MOVE i_fnam               TO s_fnam.
  MOVE '.txt              ' TO p_fnam+26(20).
  MOVE '*.txt'              TO i_mask.
*-----------------------------------------------------------------------
AT SELECTION-SCREEN OUTPUT.
*-----------------------------------------------------------------------
* Zeitpunkt: Vor Ausgabe des Selektionsdynpros. (Bei jedem ENTER)
*
*-----------------------------------------------------------------------
AT SELECTION-SCREEN.
*-----------------------------------------------------------------------
* Zeitpunkt: Nach Eingabe auf dem Selektionsdynpro.
*
*-----------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_fnam.
*-----------------------------------------------------------------------
  IF p_dbf EQ 'X'.
    MOVE '*.dbf' TO i_mask.
  ELSEIF p_asc EQ 'X'.
    MOVE '*.*'   TO i_mask.
  ELSEIF p_wk1 EQ 'X'.
    MOVE '*.wk1' TO i_mask.
  ELSEIF p_dat EQ 'X'.
    MOVE '*.dat' TO i_mask.
  ELSE.
    MOVE '*.*'   TO i_mask.
  ENDIF.
*
  CALL FUNCTION 'KD_GET_FILENAME_ON_F4'
    EXPORTING
      static    = 'X'
      mask      = i_mask
    CHANGING
      file_name = p_fnam.


*-----------------------------------------------------------------------
START-OF-SELECTION.
*-----------------------------------------------------------------------
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
* Lesen VS-Etiketten-Daten
  SELECT * FROM zsbz_sd_vsetik_0 INTO TABLE w_vsetik
                                 WHERE vkorg IN s_vkorg "Verkaufsorg.
                                 AND   vstel IN s_vstel "Versandstelle
                                 AND   vbeln IN s_vbeln "Lieferungs-Nr.
                                 AND   lfart IN s_lfart "Lieferart
                                 AND   erdat IN s_erdat "Erstellungsdatum
                                 AND   uname IN s_uname "Ersteller
                                 AND   datue EQ p_datue "Datenübern.Kz
                                 AND   stokz EQ p_stokz "Storno-Kz
                                        .
  IF sy-subrc EQ 0.   "Selektion erfolgreich durchgeführt
*  Lieferbelege wurden selektiert
    IF p_aktua EQ 'X'. "Daten vorab aktualisieren
      LOOP AT w_vsetik.
        PERFORM u0100_adr_daten_aktu.
      ENDLOOP.
    ENDIF.
    DESCRIBE TABLE w_vsetik LINES w_lines.
    IF w_lines > 0.
      PERFORM u0005_fieldnames.
      IF p_fnam IS INITIAL.
        MOVE i_fnam TO p_fnam.
      ENDIF.
      w_scha_update = 'X'.

*-------------------------------- Datenübergabe mit TAB-Trennung .dat -
      IF p_dat EQ 'X'.
        MOVE 'DAT'       TO w_ftyp.
        MOVE 'dat'       TO i_fnam+32(03).
        PERFORM u0007_filenames.
        PERFORM u0010_downl_dat_wk1.
      ELSEIF p_wk1 EQ 'X'.
*-------------------------------- Datenübergabe als WK1-Datei -
        MOVE 'WK1'       TO w_ftyp.
        MOVE 'wk1'       TO i_fnam+32(03).
        PERFORM u0007_filenames.
        PERFORM u0010_downl_dat_wk1.
      ELSEIF p_asc EQ 'X'.
*-------------------------------- Datenübergabe mit Trennzeichen .asc -
        MOVE 'ASC'       TO w_ftyp.
        MOVE 'txt'       TO i_fnam+32(03).
        PERFORM u0007_filenames.
        PERFORM u0030_downl_asc.
      ELSEIF p_dbf EQ 'X'.
*-------------------------------- Datenübergabe mit Trennzeichen .dbf -
        MOVE 'DBF'       TO w_ftyp.
        MOVE 'dbf'       TO i_fnam+32(03).
        PERFORM u0007_filenames.
        PERFORM u0040_downl_dbf.
      ENDIF.
    ELSE.
      WRITE: / 'Datendatei ist leer!'.
    ENDIF.
  ELSE.
    WRITE: / 'Es wurden keine Daten ermittelt!'.
  ENDIF.
*-----------------------------------------------------------------------
END-OF-SELECTION.
*-----------------------------------------------------------------------
*
  IF w_scha_update EQ 'X'.
    WRITE: / 'Es wurden ', w_lines, ' Datensätze übergeben'.
    SKIP 1.
    WRITE: / 'Datenübernahme erfolgte in Datei: ', p_fnam.
    IF NOT p_test EQ 'X'.
      LOOP AT w_vsetik.
        CLEAR zsbz_sd_vsetik_0.
        MOVE 'X'      TO w_vsetik-datue.
        MOVE sy-datum TO w_vsetik-uedat.
        MOVE sy-uzeit TO w_vsetik-uezet.
        MOVE sy-uname TO w_vsetik-uenam.
        MODIFY w_vsetik.
        SELECT SINGLE * FROM zsbz_sd_vsetik_0 WHERE vkorg EQ w_vsetik-vkorg
                                              AND   vstel EQ w_vsetik-vstel
                                              AND   vgbel EQ w_vsetik-vgbel
                                              AND   vbeln EQ w_vsetik-vbeln
                                              .
        IF sy-subrc EQ 0.
          MOVE-CORRESPONDING w_vsetik TO zsbz_sd_vsetik_0.
          UPDATE zsbz_sd_vsetik_0.
        ENDIF.
      ENDLOOP.
    ELSE.
      SKIP 2.
      WRITE: / ' A c h t u n g   -   T e s t l a u f, kein Update in SAP'.
      SKIP 2.
    ENDIF.
    SKIP 1.
    WRITE: / 'Daten wurden komplett upgedatet'.
  ENDIF.
*-----------------------------------------------------------------------
*                    Unterprogramm-Bibliothek
*-----------------------------------------------------------------------
FORM u0005_fieldnames.
*
  REFRESH w_fieldnames. CLEAR w_fieldnames.
  MOVE 'Mdt'                    TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'VOrg'                   TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'VStl'                   TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'Aufnr'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'LF-Nr'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'LArt'                   TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'ErDat'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'ErZet'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'UName'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'AdrNr'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'Title_Medi'             TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'Name1'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'Name2'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'Name3'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'Name4'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'NAME_CO'                TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'Street'                 TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'House_NUM1__'           TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'HOUSE_NUM2'             TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'STR_SUPPL1'             TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'STR_SUPPL2'             TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'STR_SUPPL3'             TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'POSTCODE1'              TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'CITY1'                  TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'Cou'                    TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'TEL_NUMBER'             TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'TEL_EXTENS'             TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'FAX_NUMBER'             TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'FAX_EXTENS'             TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'Anspr_P'                TO w_fieldnames-name. APPEND w_fieldnames.
  MOVE 'AnzPk'                  TO w_fieldnames-name. APPEND w_fieldnames.
*move 'DatUe'                to w_fieldnames-name. append w_fieldnames.
*move 'StoKz'                to w_fieldnames-name. append w_fieldnames.
*move 'UeDat'                to w_fieldnames-name. append w_fieldnames.
*move 'UeZet'                to w_fieldnames-name. append w_fieldnames.
*move 'UeNam'                to w_fieldnames-name. append w_fieldnames.
*move 'Mandt'                to w_fieldnames-name. append w_fieldnames.
*move 'Mandt'                to w_fieldnames-name. append w_fieldnames.
*move 'Mandt'                to w_fieldnames-name. append w_fieldnames.
*
ENDFORM. "u0005_fieldnames.
*--------------------------
FORM u0007_filenames.
*
  MOVE  p_fnam TO s_fnam.
  MOVE: '.'    TO h_ftyp(1)
      , w_ftyp TO h_ftyp+1(3).
  IF h_ftyp EQ '.ASC'.
    MOVE '.txt' TO h_ftyp.
  ENDIF.
  SEARCH s_fnam FOR h_ftyp.
  IF sy-subrc EQ 0.
    CLEAR h_pos.
    MOVE sy-fdpos           TO h_pos.
    MOVE  '_'               TO s_fnam+h_pos(01).
    ADD 1 TO h_pos.
    MOVE  sy-datum          TO s_fnam+h_pos(08).
    ADD 8 TO h_pos.
    MOVE  '_'               TO s_fnam+h_pos(01).
    ADD 1 TO h_pos.
    MOVE  sy-uzeit          TO s_fnam+h_pos(06).
    ADD 6 TO h_pos.
    MOVE h_ftyp             TO s_fnam+h_pos(8).
  ELSEIF sy-subrc EQ 4.
    SEARCH s_fnam FOR w_punkt.
    IF sy-subrc EQ 0.
      CLEAR h_pos.
      MOVE sy-fdpos           TO h_pos.
      MOVE s_fnam+h_pos(8)    TO h_ftyp.
      MOVE  '_'               TO s_fnam+h_pos(01).
      ADD 1 TO h_pos.
      MOVE  sy-datum          TO s_fnam+h_pos(08).
      ADD 8 TO h_pos.
      MOVE  '_'               TO s_fnam+h_pos(01).
      ADD 1 TO h_pos.
      MOVE  sy-uzeit          TO s_fnam+h_pos(06).
      ADD 6 TO h_pos.
      MOVE h_ftyp             TO s_fnam+h_pos(8).
    ELSE.
      CONCATENATE s_fnam '_' sy-datum '_' sy-uzeit h_ftyp INTO s_fnam.
      CONCATENATE p_fnam h_ftyp                           INTO p_fnam.
    ENDIF.
  ENDIF.


*
ENDFORM." u0007_filenames.
*--------------------------
FORM u0010_downl_dat_wk1.
*    Datendownload in Dat-Format (Tab-getrennte Textdatei)
  CALL FUNCTION 'WS_DOWNLOAD'
     EXPORTING
        filename                      = p_fnam
        filetype                      = w_ftyp
*           mode                          = 'A'
      TABLES
        data_tab                      = w_vsetik
        fieldnames                    = w_fieldnames
     EXCEPTIONS
        file_open_error               = 1
        file_write_error              = 2
        invalid_filesize              = 3
        invalid_type                  = 4
        no_batch                      = 5
        unknown_error                 = 6
        invalid_table_width           = 7
        gui_refuse_filetransfer       = 8
        customer_error                = 9
        OTHERS                        = 10
             .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*
ENDFORM. "u0010_downl_dat_wk1.
*------------------------
FORM u0030_downl_asc.
  IF   p_appd EQ 'X'.
    MOVE 'A' TO w_mode.
  ELSE.
    CLEAR w_mode.
  ENDIF.
  IF  p_head EQ 'X'.
*   Datenübernahme mit Trennzeichen im ASCII-Format
    CLEAR w_vsetik_t. REFRESH w_vsetik_t.
*   Feldnamen übergeben in 1. Zeile
    MOVE p_trenn TO w_vsetik_t-t1.  MOVE p_trenn TO w_vsetik_t-t2.
    MOVE p_trenn TO w_vsetik_t-t3.  MOVE p_trenn TO w_vsetik_t-t4.
    MOVE p_trenn TO w_vsetik_t-t5.  MOVE p_trenn TO w_vsetik_t-t6.
    MOVE p_trenn TO w_vsetik_t-t7.  MOVE p_trenn TO w_vsetik_t-t8.
    MOVE p_trenn TO w_vsetik_t-t9.  MOVE p_trenn TO w_vsetik_t-t10.
    MOVE p_trenn TO w_vsetik_t-t11. MOVE p_trenn TO w_vsetik_t-t12.
    MOVE p_trenn TO w_vsetik_t-t13. MOVE p_trenn TO w_vsetik_t-t14.
    MOVE p_trenn TO w_vsetik_t-t15. MOVE p_trenn TO w_vsetik_t-t16.
    MOVE p_trenn TO w_vsetik_t-t17. MOVE p_trenn TO w_vsetik_t-t18.
    MOVE p_trenn TO w_vsetik_t-t19. MOVE p_trenn TO w_vsetik_t-t20.
    MOVE p_trenn TO w_vsetik_t-t21. MOVE p_trenn TO w_vsetik_t-t22.
    MOVE p_trenn TO w_vsetik_t-t23. MOVE p_trenn TO w_vsetik_t-t24.
    MOVE p_trenn TO w_vsetik_t-t25. MOVE p_trenn TO w_vsetik_t-t26.
    MOVE p_trenn TO w_vsetik_t-t27. move p_trenn to w_vsetik_t-t28.
    move p_trenn to w_vsetik_t-t29. move p_trenn to w_vsetik_t-t30.
    move p_trenn to w_vsetik_t-t31.

    MOVE 'Mdt'                    TO w_vsetik_t-mandt.
    MOVE 'VOrg'                   TO w_vsetik_t-vkorg.
    MOVE 'VStl'                   TO w_vsetik_t-vstel.
    MOVE 'Aufnr_____'            TO w_vsetik_t-vgbel.
    MOVE 'LF_Nr_____'             TO w_vsetik_t-vbeln.
    MOVE 'LArt'                   TO w_vsetik_t-lfart.
    MOVE 'ErDat_____'             TO w_vsetik_t-erdat.
    MOVE 'ErZet___'               TO w_vsetik_t-erzet.
    MOVE 'UName_______'           TO w_vsetik_t-uname.
    MOVE 'AdrNr_______'           TO w_vsetik_t-adrnr.
    MOVE 'Anrede________________________'
      TO                             w_vsetik_t-title_medi.
    MOVE 'Name1___________________________________'
      TO                             w_vsetik_t-name1.
    MOVE 'Name2___________________________________'
      TO                             w_vsetik_t-name2.
    MOVE 'Name3___________________________________'
      TO                             w_vsetik_t-name3.
    MOVE 'Name4___________________________________'
      TO                             w_vsetik_t-name4.
    MOVE 'Name_CO__________________________________'
      TO                             w_vsetik_t-name_co.
    MOVE 'Street______________________________________________________'
      TO                             w_vsetik_t-street.
    MOVE 'House_NUM1__'           TO w_vsetik_t-house_num1.
    MOVE 'HOUSE_NUM2'             TO w_vsetik_t-house_num2.
    MOVE 'STR_SUPPL1______________________________'
                                  TO w_vsetik_t-STR_SUPPL1.
    MOVE 'STR_SUPPL2______________________________'
                                  TO w_vsetik_t-STR_SUPPL2.
    MOVE 'STR_SUPPL3______________________________'
                                  TO w_vsetik_t-STR_SUPPL3.
    MOVE 'POSTCODE1_'             TO w_vsetik_t-post_code1.
    MOVE 'CITY1___________________________________'
      TO                             w_vsetik_t-city1.
    MOVE 'Cou'                    TO w_vsetik_t-country.
    MOVE 'TEL_NUMBER____________________'
      TO                             w_vsetik_t-tel_number.
    MOVE 'TEL_EXTENS'             TO w_vsetik_t-tel_extens.
    MOVE 'FAX_NUMBER____________________'
      TO                             w_vsetik_t-fax_number.
    MOVE 'FAX_EXTENS'             TO w_vsetik_t-fax_extens.
    MOVE 'Anspr_P_____________________________________________________'
      TO                             w_vsetik_t-remark.
    MOVE 'AnzPk'                  TO w_vsetik_t-anzpk.
*    move 'D'                      to w_vsetik_t-datue.
*    move 'S'                      to w_vsetik_t-stokz.
*    move 'UeDat_____'             to w_vsetik_t-uedat.
*    move 'UeZet___'               to w_vsetik_t-uezet.
*    move 'UeNam_______'           to w_vsetik_t-uenam.
    APPEND w_vsetik_t.
  ENDIF.
  LOOP AT w_vsetik.
*       Einlesen selektierte Daten
    CLEAR w_vsetik_t.
*       Gewünschtes Trennzeichen bestücken (Neue Struktur)
    MOVE p_trenn TO w_vsetik_t-t1.  MOVE p_trenn TO w_vsetik_t-t2.
    MOVE p_trenn TO w_vsetik_t-t3.  MOVE p_trenn TO w_vsetik_t-t4.
    MOVE p_trenn TO w_vsetik_t-t5.  MOVE p_trenn TO w_vsetik_t-t6.
    MOVE p_trenn TO w_vsetik_t-t7.  MOVE p_trenn TO w_vsetik_t-t8.
    MOVE p_trenn TO w_vsetik_t-t9.  MOVE p_trenn TO w_vsetik_t-t10.
    MOVE p_trenn TO w_vsetik_t-t11. MOVE p_trenn TO w_vsetik_t-t12.
    MOVE p_trenn TO w_vsetik_t-t13. MOVE p_trenn TO w_vsetik_t-t14.
    MOVE p_trenn TO w_vsetik_t-t15. MOVE p_trenn TO w_vsetik_t-t16.
    MOVE p_trenn TO w_vsetik_t-t17. MOVE p_trenn TO w_vsetik_t-t18.
    MOVE p_trenn TO w_vsetik_t-t19. MOVE p_trenn TO w_vsetik_t-t20.
    MOVE p_trenn TO w_vsetik_t-t21. MOVE p_trenn TO w_vsetik_t-t22.
    MOVE p_trenn TO w_vsetik_t-t23. MOVE p_trenn TO w_vsetik_t-t24.
    MOVE p_trenn TO w_vsetik_t-t25. MOVE p_trenn TO w_vsetik_t-t26.
    MOVE p_trenn TO w_vsetik_t-t27. move p_trenn to w_vsetik_t-t28.
    move p_trenn to w_vsetik_t-t29. move p_trenn to w_vsetik_t-t30.
    move p_trenn to w_vsetik_t-t31.

*       Selektionsdaten übertragen in neue Struktur
    WRITE: w_vsetik-mandt           TO w_vsetik_t-mandt
         , w_vsetik-vkorg           TO w_vsetik_t-vkorg
         , w_vsetik-vstel           TO w_vsetik_t-vstel
         , w_vsetik-vgbel           TO w_vsetik_t-vgbel
         , w_vsetik-vbeln           TO w_vsetik_t-vbeln
         , w_vsetik-lfart           TO w_vsetik_t-lfart
         , w_vsetik-erdat           TO w_vsetik_t-erdat
         , w_vsetik-erzet           TO w_vsetik_t-erzet
         , w_vsetik-uname           TO w_vsetik_t-uname
         , w_vsetik-adrnr           TO w_vsetik_t-adrnr
         , w_vsetik-title_medi      TO w_vsetik_t-title_medi
         , w_vsetik-name1           TO w_vsetik_t-name1
         , w_vsetik-name2           TO w_vsetik_t-name2
         , w_vsetik-name3           TO w_vsetik_t-name3
         , w_vsetik-name4           TO w_vsetik_t-name4
         , w_vsetik-name_co         to w_vsetik_t-name_co
         , w_vsetik-street          TO w_vsetik_t-street
*             , w_vsetik-HOUSE_NUM1      to w_vsetik_t-HOUSE_NUM1
         , w_vsetik-house_num2      TO w_vsetik_t-house_num2
*             , w_vsetik-POST_CODE1      to w_vsetik_t-POST_CODE1
         , w_vsetik-STR_SUPPL1      TO w_vsetik_t-STR_SUPPL1
         , w_vsetik-STR_SUPPL2      TO w_vsetik_t-STR_SUPPL2
         , w_vsetik-STR_SUPPL3      TO w_vsetik_t-STR_SUPPL3
         , w_vsetik-city1           TO w_vsetik_t-city1
         , w_vsetik-country         TO w_vsetik_t-country
         , w_vsetik-tel_number      TO w_vsetik_t-tel_number
         , w_vsetik-tel_extens      TO w_vsetik_t-tel_extens
         , w_vsetik-fax_number      TO w_vsetik_t-fax_number
         , w_vsetik-fax_extens      TO w_vsetik_t-fax_extens
         , w_vsetik-remark          TO w_vsetik_t-remark
         , w_vsetik-anzpk           TO w_vsetik_t-anzpk
*             , w_vsetik-DATUE           to w_vsetik_t-DATUE
*             , w_vsetik-STOKZ           to w_vsetik_t-STOKZ
*             , w_vsetik-UEDAT           to w_vsetik_t-UEDAT
*             , w_vsetik-UEZET           to w_vsetik_t-UEZET
*             , w_vsetik-UENAM           to w_vsetik_t-UENAM
         .

    CONCATENATE '"' w_vsetik-post_code1 '"' INTO w_vsetik_t-post_code1.

    CONCATENATE '"' w_vsetik-house_num1 '"'
           INTO w_vsetik_t-house_num1.
*       move-corresponding w_vsetik to w_vsetik_t.
*       Neue Struktur mit Daten sichern
    APPEND w_vsetik_t.
*       auf zum nächsten Datensatz.
  ENDLOOP.
*      -> So jetzt nix wie runter schreiben auf den Client
  CALL FUNCTION 'WS_DOWNLOAD'
    EXPORTING
      filename                = p_fnam
      filetype                = w_ftyp
      mode                    = w_mode
    TABLES
      data_tab                = w_vsetik_t
      fieldnames              = w_fieldnames
    EXCEPTIONS
      file_open_error         = 1
      file_write_error        = 2
      invalid_filesize        = 3
      invalid_type            = 4
      no_batch                = 5
      unknown_error           = 6
      invalid_table_width     = 7
      gui_refuse_filetransfer = 8
      customer_error          = 9
      OTHERS                  = 10.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*
ENDFORM. "u0030_downl_asc.
*------------------------
FORM u0040_downl_dbf.
  CALL FUNCTION 'WS_DOWNLOAD'
     EXPORTING
        filename                      = s_fnam
        filetype                      = w_ftyp
*           codepage                      = 'IBM'
        mode                          = ' '
      TABLES
        data_tab                      = w_vsetik
        fieldnames                    = w_fieldnames
     EXCEPTIONS
        file_open_error               = 1
        file_write_error              = 2
        invalid_filesize              = 3
        invalid_type                  = 4
        no_batch                      = 5
        unknown_error                 = 6
        invalid_table_width           = 7
        gui_refuse_filetransfer       = 8
        customer_error                = 9
        OTHERS                        = 10
             .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*    Datendownload in DBASE-Format (DBASE-Tabelle) append-mode
  CALL FUNCTION 'WS_DOWNLOAD'
    EXPORTING
      filename                = p_fnam
      filetype                = w_ftyp
      codepage                = 'IBM'
      mode                    = 'A'
    TABLES
      data_tab                = w_vsetik
      fieldnames              = w_fieldnames
    EXCEPTIONS
      file_open_error         = 1
      file_write_error        = 2
      invalid_filesize        = 3
      invalid_type            = 4
      no_batch                = 5
      unknown_error           = 6
      invalid_table_width     = 7
      gui_refuse_filetransfer = 8
      customer_error          = 9
      OTHERS                  = 10.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

*
ENDFORM. "u0040_downl_dbf.
*-------------------------
FORM u0100_adr_daten_aktu.
* prüfen auf Ansprechpartner -> 1. Prio          für Feld Remark
  CLEAR vbpa. CLEAR w_vsetik-remark.
  SELECT SINGLE * FROM vbpa WHERE vbeln EQ w_vsetik-vbeln
                            AND   posnr EQ '000000'
                            AND   parvw EQ 'ZL'.
  IF sy-subrc EQ 0.
*  Partner-Daten für ZL gefunden-Lesen Adressdaten "zust.AP Lieferg"
    IF vbpa-adrda EQ 'E'
*  or vbpa-adrda eq 'D'
    OR vbpa-adrda EQ 'B'.
      CLEAR adrc.
      SELECT SINGLE * FROM adrc  WHERE addrnumber EQ vbpa-adrnr.
      IF  sy-subrc EQ 0
      AND adrc-name2 NE zsbz_sd_vsetik_0-remark.
        MOVE adrc-name2  TO w_vsetik-remark.
        MOVE 'X'         TO w_scha_update.
      ENDIF.
    ELSE.
      CLEAR knvk.
      SELECT SINGLE * FROM knvk  WHERE parnr EQ vbpa-parnr.
      IF sy-subrc EQ 0.
        CLEAR adrp.
        SELECT SINGLE * FROM adrp  WHERE  persnumber EQ knvk-prsnr.
        IF sy-subrc EQ 0.
          MOVE adrp-name_text  TO w_vsetik-remark.
          MOVE 'X'             TO w_scha_update.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
* prüfen auf "Ihre Referenz" -> 2. Prio
  IF w_vsetik-remark IS INITIAL.
    CLEAR vbak.
    SELECT SINGLE * FROM vbak WHERE vbeln EQ w_vsetik-vgbel.
    IF  NOT vbak-bname IS INITIAL
    AND vbak-bname     NE w_vsetik-remark.
      MOVE vbak-bname   TO w_vsetik-remark.
      MOVE 'X'          TO w_scha_update.
    ENDIF.
  ENDIF.


*
*clear vbpa.
*select single * from vbpa where vbeln eq w_vsetik-vbeln
*                          and   posnr eq '000000'
*                          and   parvw eq 'AP'.
*if sy-subrc eq 0.
**  Partner-Daten für WE gefunden - Lesen Adressdaten
*   select single * from adrc  where ADDRNUMBER eq vbpa-adrnr.
*   if  sy-subrc eq 0
*   and adrc-name1 ne w_vsetik-remark.
*       move adrc-name1  to w_vsetik-remark.
*       move 'X'         to w_scha_update.
*   endif.
*endif.
** prüfen auf "Ihre Referenz" -> 2. Prio
*if w_vsetik-remark is initial.
*   clear vbak.
*   select single * from vbak where vbeln eq w_vsetik-vgbel.
*     if  not vbak-bname is initial
*     and vbak-bname     ne w_vsetik-remark.
*         move vbak-bname   to w_vsetik-remark.
*         move 'X'          to w_scha_update.
*     endif.
*endif.
*    Restliche Daten werden überprüft....
*    Adressdaten neu ermitteln

  "Dienstadresse als abweichende Lieferadresse beziehen
  CLEAR: vbpa, adrc, tsad3t, adrct, lv_adrnr.
  SELECT SINGLE kv1~adrnd FROM vbpa AS vp1 INNER JOIN knvk AS kv1 ON kv1~parnr = vp1~parnr INTO lv_adrnr
    WHERE vbeln EQ w_vsetik-vbeln
     AND  posnr EQ '000000'
     AND  parvw EQ 'ZL'
     AND  adrnd NE space.


  IF lv_adrnr IS INITIAL.
    SELECT SINGLE * FROM vbpa WHERE vbeln EQ w_vsetik-vbeln
                              AND   posnr EQ '000000'
                              AND   parvw EQ 'WE'.
    lv_adrnr = vbpa-adrnr.
  ENDIF.


  IF NOT lv_adrnr IS INITIAL.
*  Partner-Daten für WE gefunden - Lesen Adressdaten
    SELECT SINGLE * FROM adrc  WHERE addrnumber EQ lv_adrnr.

    SELECT SINGLE * FROM adrct WHERE addrnumber EQ lv_adrnr
                               AND   langu      EQ 'DE'.

    "Anredetext lesen
    SELECT SINGLE * FROM tsad3t WHERE title EQ adrc-title
                                  AND langu EQ adrc-langu.

  ENDIF.
*-----------
  IF w_vsetik-adrnr NE lv_adrnr.
*  Partneradresse wurde geändert
    MOVE 'X'             TO w_scha_update.
    MOVE lv_adrnr      TO w_vsetik-adrnr.
    MOVE-CORRESPONDING adrc  TO w_vsetik.
    IF w_vsetik-remark IS INITIAL.                          "-> 3. Prio
      MOVE-CORRESPONDING adrct TO w_vsetik.
    ENDIF.
    MODIFY w_vsetik.
  ELSE.
*  Adressdaten einzeln prüfen.
    IF w_vsetik-title_medi NE tsad3t-title_medi.
      MOVE 'X'             TO w_scha_update.
      MOVE tsad3t-title_medi TO w_vsetik-title_medi.
    ENDIF.
    IF w_vsetik-name1 NE adrc-name1.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-name1      TO w_vsetik-name1.
    ENDIF.
    IF w_vsetik-name2 NE adrc-name2.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-name2      TO w_vsetik-name2.
    ENDIF.
    IF w_vsetik-name3 NE adrc-name3.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-name3      TO w_vsetik-name3.
    ENDIF.
    IF w_vsetik-name4 NE adrc-name4.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-name4      TO w_vsetik-name4.
    ENDIF.
    IF w_vsetik-name_co NE adrc-name_co.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-name_co    TO w_vsetik-name_co.
    ENDIF.
    IF w_vsetik-street NE adrc-street.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-street     TO w_vsetik-street.
    ENDIF.
    IF w_vsetik-house_num1 NE adrc-house_num1.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-house_num1 TO w_vsetik-house_num1.
    ENDIF.
    IF w_vsetik-house_num2 NE adrc-house_num2.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-house_num2 TO w_vsetik-house_num2.
    ENDIF.
    IF w_vsetik-STR_SUPPL1 NE adrc-STR_SUPPL1.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-STR_SUPPL1 TO w_vsetik-STR_SUPPL1.
    ENDIF.
    IF w_vsetik-STR_SUPPL2 NE adrc-STR_SUPPL2.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-STR_SUPPL2 TO w_vsetik-STR_SUPPL2.
    ENDIF.
    IF w_vsetik-STR_SUPPL3 NE adrc-STR_SUPPL3.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-STR_SUPPL3 TO w_vsetik-STR_SUPPL3.
    ENDIF.
    IF w_vsetik-post_code1 NE adrc-post_code1.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-post_code1 TO w_vsetik-post_code1.
    ENDIF.
    IF w_vsetik-city1 NE adrc-city1.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-city1      TO w_vsetik-city1.
    ENDIF.
    IF w_vsetik-country NE adrc-country.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-country    TO w_vsetik-country.
    ENDIF.
    IF w_vsetik-remark IS INITIAL. " -> 3. Prio
      MOVE 'X'             TO w_scha_update.
      MOVE adrct-remark    TO w_vsetik-remark.
    ENDIF.
    IF w_vsetik-tel_number NE adrc-tel_number.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-tel_number TO w_vsetik-tel_number.
    ENDIF.
    IF w_vsetik-tel_extens NE adrc-tel_extens.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-tel_extens TO w_vsetik-tel_extens.
    ENDIF.
    IF w_vsetik-fax_number NE adrc-fax_number.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-fax_number TO w_vsetik-fax_number.
    ENDIF.
    IF w_vsetik-fax_extens NE adrc-fax_extens.
      MOVE 'X'             TO w_scha_update.
      MOVE adrc-fax_extens TO w_vsetik-fax_extens.
    ENDIF.
    IF w_vsetik-anzpk NE likp-anzpk.
      MOVE 'X'             TO w_scha_update.
      MOVE likp-anzpk      TO w_vsetik-anzpk.
    ENDIF.
    MODIFY w_vsetik.
  ENDIF.
*-----------
ENDFORM." u0100_adr_daten_aktu.
*----------------------------
