*&---------------------------------------------------------------------*
*& Include MZSD_05_KEPOTOP
*&
*&---------------------------------------------------------------------*

PROGRAM  sapmzsd_05_kehricht.

*_____Tables__________
TABLES: zsdtkpkepo.


*_____Ranges___________



*_____Types__________

TYPES: BEGIN OF ty_editortext,
         line(132) TYPE c,
       END   OF ty_editortext.

"Type für TableControl Kehrichtpolizei Materialpositionen
TYPES: BEGIN OF ty_matpos.

        INCLUDE TYPE zsdtkpmatpos.
TYPES:  flag    TYPE c,
        action  TYPE c,  " Modify (M) = Insert oder Update ; Delete (D) = Löschen
        delable TYPE c,  " X = löschbar ohne DB-Update
       END OF ty_matpos.

"Type für TableControl Kehrichtpolizei Verrechnungs- und Inkassodaten
TYPES: BEGIN OF ty_auft.
        INCLUDE TYPE zsdtkpauft.
TYPES:  flag    TYPE c,
        action  TYPE c,  " Modify (M) = Insert oder Update ; Delete (D) = Löschen
        delable TYPE c,  " X = löschbar ohne DB-Update
       END OF ty_auft.

"Type für TableControl Kehrichtpolizei Dokumentenpositionen
TYPES: BEGIN OF ty_docpos.
        INCLUDE TYPE zsdtkpdocpos.
TYPES:  flag    TYPE c,
        action  TYPE c,  " Modify (M) = Insert oder Update ; Delete (D) = Löschen
        delable TYPE c,  " X = löschbar ohne DB-Update
       END OF ty_docpos.

"Type für TableControl Kehrichtpolizei Infos zu Debitor
TYPES: BEGIN OF ty_debinfo,
        fall      TYPE char13, "Fallnummer/Geschäftsjahr
        fstat     TYPE zsdtkpkepo-fstat,
        fart      TYPE zsdtkpkepo-fart,
        fdat      TYPE zsdtkpkepo-fdat,
        fwdh      TYPE zsdtkpkepo-fwdh,
        psachb    TYPE zsdtkpkepo-psachb,
        kverrgdat TYPE zsdtkpkepo-kverrgdat,
        flag      TYPE c,
       END OF ty_debinfo.



"Type für F4-Hilfe Material je Fallart
TYPES: BEGIN OF ty_matfart,
         fart  TYPE zsdekpfart,
         matnr TYPE matnr,
       END OF ty_matfart.

"Type für F4-Hilfe Material je Fallart
TYPES: BEGIN OF ty_statbez,
         statart TYPE zsdekpstatart,
         bezei   TYPE bezei40,
       END OF ty_statbez.



"Type für Message-Tabelle
TYPES: BEGIN OF ty_msg_tab.
        INCLUDE STRUCTURE bapiret1.
TYPES:   icon TYPE icon_d,
       END OF ty_msg_tab.



*_____Interne Tabellen und Strukturen__________


DATA: gs_kepo   TYPE zsdtkpkepo, "Kehrichtpolizei Kopfdaten
*      gt_kepo   TYPE STANDARD TABLE OF zsdtkpkepo,
      first_time type char1,
      "Verwarnungen
      gs_rege type zsd_05_kepo_ver,
      gs_verwarnung type zsd_05_kepo_ver,
      kepo_ver like zsd_05_kepo_ver,
      loesch type char1,
      mode type string,
      gs_matpos     TYPE ty_matpos, "Kehrichtpolizei Materialpositionen
      gt_matpos     TYPE STANDARD TABLE OF ty_matpos,
      gt_matpos_del TYPE STANDARD TABLE OF ty_matpos,

      gs_auft     TYPE ty_auft, "Kehrichtpolizei Verrechnungs- und Inkassodaten
      gt_auft     TYPE STANDARD TABLE OF ty_auft,
      gt_auft_del TYPE STANDARD TABLE OF ty_auft,

      gs_docpos     TYPE ty_docpos, "Kehrichtpolizei Dokumentenpositionen
      gt_docpos     TYPE STANDARD TABLE OF ty_docpos,
      gt_docpos_del TYPE STANDARD TABLE OF ty_docpos,

      gs_debinfo      TYPE ty_debinfo, "Info zu Debitor
      gt_debinfo      TYPE STANDARD TABLE OF ty_debinfo,
      gs_debinfo_kepo TYPE zsdtkpkepo, " Hilfstab/struk für Datenselektion
      gt_debinfo_kepo TYPE STANDARD TABLE OF zsdtkpkepo,

      gs_deb TYPE kna1, "Debitor
      gs_arg TYPE kna1, "abw. Rechnungsempfänger

      gs_kna1 TYPE kna1, "Debitor generell
      gs_adrc TYPE adrc, "Adresse

      gs_matfart_f4val TYPE ty_matfart, "Kehrichtpolizei Material je Fallart
      gt_matfart_f4val TYPE STANDARD TABLE OF ty_matfart,

      gs_statbez_f4val TYPE ty_statbez, "Kehrichtpolizei Bezeichnung des Status / Statusart
      gt_statbez_f4val TYPE STANDARD TABLE OF ty_statbez,

      gs_field_prop TYPE zsdtkpfldprop, "Kehrichtpolizei Feldeigenschaften
      gt_field_prop TYPE STANDARD TABLE OF zsdtkpfldprop,

      gs_msg_tab TYPE ty_msg_tab, "Nachrichtausgabe
      gt_msg_tab TYPE STANDARD TABLE OF ty_msg_tab,

      gs_bdc TYPE bdcdata, "Batch-Input Struktur
      gt_bdc TYPE STANDARD TABLE OF bdcdata,
      gs_bdc_opt TYPE ctu_params,

      gs_sf_header_data TYPE zsdtkpsmartform, "Smartforms: Kopfdaten-Übergabe Rechtl. Gehör / Verfügung

      gs_sf_docs_data   TYPE zsdtkpsmartform, "Smartforms: Dokumenten-Übergaben Rechtl. Gehör / Verfügung
      gt_sf_docs_data   TYPE STANDARD TABLE OF zsdtkpsmartform.


*      gs_a004   type a004,          "Material (Pool-Tabelle)
*      gs_konp   type konp,          "Konditionen (Position)
*      gs_mara   type mara,          "Materialstamm
*      gs_makt   type makt,          "Materialkurztexte
*      gs_adrc   type adrc,          "Adressen (zentrale Adreßverwaltung)
*      gs_tvko   type tvko.          "Org.-Einheit: Verkaufsorganisationen



"Interne Tabelle für Texte
DATA: gt_editortext_fbem TYPE STANDARD TABLE OF ty_editortext,
      gs_editortext TYPE ty_editortext.

"Interne Tabelle für exkludierende Funktionen
DATA: gt_fcode_excludes TYPE STANDARD TABLE OF sy-ucomm,
      gs_fcode_excludes TYPE sy-ucomm.


"Verrechnungstabellen, -strukturen, -variablen, etc.
DATA: gd_test   TYPE bapiflag-bapiflag,       "Testlauf

      gd_order_dont_create TYPE c,            "Auftrag nicht erstellen
      gd_order_created     TYPE c,            "Auftrag erstellt
      gd_invo_dont_create TYPE c,             "Faktura nicht erstellen
      gd_invo_created      TYPE c,            "Faktura erstellt

      gs_order_header TYPE bapisdhd1,         "Auftragskopf

      gs_order_return TYPE bapiret2,          "Rückgabemeldungen
      gt_order_return TYPE TABLE OF bapiret2,

      gs_order_items  TYPE bapisditm,         "Positionsdaten
      gt_order_items  TYPE TABLE OF bapisditm,
      gs_order_matpos TYPE ty_matpos,

      gs_order_partn  TYPE bapiparnr,         "Belegpartner
      gt_order_partn  TYPE TABLE OF bapiparnr,

      gs_order_sched  TYPE bapischdl,         "Einteilungsdaten
      gt_order_sched  TYPE TABLE OF bapischdl,

      gs_order_cond   TYPE bapicond,          "Konditionen
      gt_order_cond   TYPE TABLE OF bapicond,

      gs_order_text   TYPE bapisdtext,        "Texte
      gt_order_text   TYPE TABLE OF bapisdtext,

      gs_invo_data  TYPE bapivbrk,            "Fakturakopf
      gt_invo_data    TYPE TABLE OF bapivbrk,

      gs_invo_return  TYPE bapiret1,          "Rückgabemeldungen
      gt_invo_return  TYPE TABLE OF bapiret1,

      gs_invo_success TYPE bapivbrksuccess,   "Erfolgreich verarbeiteter Positionen
      gt_invo_success TYPE TABLE OF bapivbrksuccess.





*_____Variablen, Hilfsfelder, Schalter, etc.__________
"Konstanten
CONSTANTS: c_prog TYPE sy-repid VALUE 'SAPMZSD_05_KEPO',

           c_marked    TYPE c VALUE 'X',

           c_true      TYPE c VALUE 'X',
           c_false     TYPE c VALUE '',
           c_true_num  TYPE i VALUE 1,
           c_false_num TYPE i VALUE 0,

           c_insert TYPE c VALUE 'I',
           c_update TYPE c VALUE 'U',
           c_modify TYPE c VALUE 'M',
           c_delete TYPE c VALUE 'D',

           c_order(1) TYPE c VALUE 'O', "Kundenauftrag
           c_invo(1)  TYPE c VALUE 'I', "Fakturierung
           c_canc1(2) TYPE c VALUE 'CO', "Storno Kundenauftrag
           c_canc2(2) TYPE c VALUE 'CI', "Storno Fakturierung

           c_fallnr_init TYPE zsdekpfallnr VALUE '00000000', "Fallnummer Initialwert
           c_matnr_init  TYPE matnr VALUE '000000000000000000', "Materialnummer Initialwert
           c_date_init TYPE datum VALUE '00000000', "Datum Initialwert

           c_hyphen TYPE c VALUE '-', "Bindestrich
           c_backsl TYPE c VALUE '\', "Backslash

           c_sfart_rg1 TYPE string VALUE 'RG1', "Smartforms-Dokumentenart: Rechtliches Gehör
           c_sfart_v1 TYPE string VALUE 'V1', "Smartforms-Dokumentenart: Verfügung

           c_print TYPE string VALUE 'print', "Ausgabeart: Drucken
           c_pdf   TYPE string VALUE 'pdf',   "Ausgabeart: PDF

          "Für Customizingtabelle
           c_no_val TYPE char6 VALUE '&NOVAL', "Kein Wert gepflegt
           c_gdcfld TYPE char4 VALUE 'GDC_'.  "Präfix einer Programmvariable


"Gecustomizte Vorgabewerte für Programmvariablen (Transaktion SM30 in Tabelle ZSDTKPFLDPROP).
"Solche Datenvariablen können mit "GDC_" gepflegt werden und die untenstehende Werte überschreiben.
"Die Prog-Struktur wird mit '&NOVAL' gefüllt!

DATA: gdc_nk_obj TYPE nrobj VALUE 'ZKEPOFALL', "Nummernkreisobjekt
      gdc_nk_nrr TYPE nrnr  VALUE '01', "Nummernkreisnummer

      gdc_tdobj TYPE tdobject VALUE 'ZKEPO', "Textobjekt
      gdc_tdid1 TYPE tdid     VALUE 'Z001', "Text-ID

      gdc_langu   TYPE sy-langu VALUE 'DE', "Sprache
      gdc_country TYPE land1    VALUE 'CH',  "Land

      gdc_kgd TYPE ktokd      VALUE 'ZP00', "Kontengruppe Debitor

      gdc_currency  TYPE waerk VALUE 'CHF', "Währung
      gdc_doc_vrkme TYPE vrkme VALUE 'ST', "Defaultwert für Mengeneinheit (Dokumente)

      gdc_enqmode TYPE enqmode VALUE 'E', "Sperrmodus

      gdc_order_doc_type TYPE auart value 'Z878', "Auftragsart
      gdc_invo_doc_type  TYPE fkart Value 'Z878', "Fakturaart
      gdc_prol_deb TYPE parvw VALUE 'AG', "Partnerrolle Auftraggeber
      gdc_prol_arg TYPE parvw VALUE 'RE', "Partnerrolle Rechnungsempfänger

      gdc_check_inkasso TYPE flag VALUE '',      "Inkassodaten beim Aufruf eines Falles prüfen
      gdc_check_inkasso_test TYPE flag VALUE '', "Inkassodaten in DB schreiben, oder nicht
      gdc_check_inkasso_ext TYPE flag VALUE '',  "Inkassodaten als externen Aufruf verarbeiten
      gdc_check_mahns TYPE mahns_d VALUE 1,      "Inkassodaten: Anzahl Mahnstufen prüfen

      gdc_init_folder TYPE string VALUE 'C:\temp'. "Ablagepfad




"Weitere Variablen
DATA: ok_code  TYPE sy-ucomm,
      gd_subrc TYPE sy-subrc,
      gd_tabix TYPE sy-tabix,
      gd_repid TYPE sy-repid,
      gd_dynnr TYPE sy-dynnr,

      gd_cnt_err TYPE i,

      gd_create       TYPE c,
      gd_create_store TYPE c,
      gd_update       TYPE c,
      gd_update_store TYPE c,
      gd_show         TYPE c,
      gd_show_store   TYPE c,
      gd_delete       TYPE c,
      gd_delete_store TYPE c,
      gd_enqu         TYPE c,
      gd_enqu_store   TYPE c,
      gd_readonly     TYPE c,

      gd_einw1_1 TYPE c,
      gd_einw1_2 TYPE c,
      gd_einw2_1 TYPE c,
      gd_einw2_2 TYPE c,
      gd_einw3_1 TYPE c,
      gd_einw3_2 TYPE c,

      gd_mansp TYPE mansp,
      gd_manh1 TYPE datum,
      gd_manh2 TYPE datum,
      gd_manh3 TYPE datum,

      gd_fkdat TYPE fkdat,

      gd_debinfo_selected TYPE c,

      gd_fieldname TYPE string,
      gd_strucstr  TYPE dynfnam,
      gd_fldstr    TYPE dynfnam,
      gd_fval255   TYPE text255,

      gd_str TYPE adrc-street,
      gd_hnr TYPE adrc-house_num1,
      gd_plz TYPE adrc-post_code1,
      gd_ort TYPE adrc-city1,

      gd_q_zc1_set_date TYPE c,
      gd_q_zc1_sel_all TYPE c,

      gd_icon_message_s TYPE icon_d VALUE '@5B@',
      gd_icon_message_i TYPE icon_d VALUE '@19@',
      gd_icon_message_w TYPE icon_d VALUE '@5D@',
      gd_icon_message_e TYPE icon_d VALUE '@5C@',
      gd_icon_message_a TYPE icon_d VALUE '@5C@'.


"Buttons für dynamische Textsteuerung
DATA: btn_deb_mod TYPE string,
      btn_arg_mod TYPE string,
      btn_debold_show TYPE string,
      btn_debadr_transfer TYPE string.





"Data für Texteditor
DATA: gr_editor_container_fbem TYPE REF TO cl_gui_custom_container,
      gr_editor_fbem           TYPE REF TO cl_gui_textedit.


"Data für Frontend Services
DATA: gr_services TYPE REF TO cl_gui_frontend_services.





*_____Wizard generated__________

*&SPWIZARD: FUNCTION CODES FOR TABSTRIP 'TS_ADMIN'
CONSTANTS: BEGIN OF c_ts_admin,
             tab1 LIKE sy-ucomm VALUE 'TS_ADMIN_FC1',
             tab2 LIKE sy-ucomm VALUE 'TS_ADMIN_FC2',
             tab3 LIKE sy-ucomm VALUE 'TS_ADMIN_FC3',
             tab4 LIKE sy-ucomm VALUE 'TS_ADMIN_FC4',
             tab5 LIKE sy-ucomm VALUE 'TS_ADMIN_FC5',
             tab6 LIKE sy-ucomm VALUE 'TS_ADMIN_FC6',
             tab7 LIKE sy-ucomm VALUE 'TS_ADMIN_FC7',
             tab8 LIKE sy-ucomm VALUE 'TS_ADMIN_FC8',
           END OF c_ts_admin.
*&SPWIZARD: DATA FOR TABSTRIP 'TS_ADMIN'
CONTROLS:  ts_admin TYPE TABSTRIP.
DATA:      BEGIN OF g_ts_admin,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE 'SAPMZSD_05_KEPO',
             pressed_tab LIKE sy-ucomm VALUE c_ts_admin-tab1,
           END OF g_ts_admin.


*&SPWIZARD: DECLARATION OF TABLECONTROL 'TC_MATPOS' ITSELF
CONTROLS: tc_matpos TYPE TABLEVIEW USING SCREEN 3002.
*&SPWIZARD: LINES OF TABLECONTROL 'TC_MATPOS'
DATA:     g_tc_matpos_lines  LIKE sy-loopc.


*&SPWIZARD: DECLARATION OF TABLECONTROL 'TC_DOCPOS' ITSELF
CONTROLS: tc_docpos TYPE TABLEVIEW USING SCREEN 3006.
*&SPWIZARD: LINES OF TABLECONTROL 'TC_DOCPOS'
DATA:     g_tc_docpos_lines  LIKE sy-loopc.


*&SPWIZARD: DECLARATION OF TABLECONTROL 'TC_MESSAGES' ITSELF
CONTROLS: tc_messages TYPE TABLEVIEW USING SCREEN 4001.
*&SPWIZARD: LINES OF TABLECONTROL 'TC_MESSAGES'
DATA:     g_tc_messages_lines  LIKE sy-loopc.

*&SPWIZARD: DECLARATION OF TABLECONTROL 'TC_DEBINFO' ITSELF
CONTROLS: tc_debinfo TYPE TABLEVIEW USING SCREEN 3007.

*&SPWIZARD: FUNCTION CODES FOR TABSTRIP 'TS_ADMIN1'
CONSTANTS: BEGIN OF c_ts_admin1,
             tab1 LIKE sy-ucomm VALUE 'TS_ADMIN1_FC1',
             tab2 LIKE sy-ucomm VALUE 'TS_ADMIN1_FC2',
             tab3 LIKE sy-ucomm VALUE 'TS_ADMIN1_FC3',
             tab4 LIKE sy-ucomm VALUE 'TS_ADMIN1_FC4',
             tab5 LIKE sy-ucomm VALUE 'TS_ADMIN1_FC5',
             tab6 LIKE sy-ucomm VALUE 'TS_ADMIN1_FC6',
             tab7 LIKE sy-ucomm VALUE 'TS_ADMIN1_FC7',
             tab8 LIKE sy-ucomm VALUE 'TS_ADMIN1_FC8',
           END OF c_ts_admin1.
*&SPWIZARD: DATA FOR TABSTRIP 'TS_ADMIN1'
CONTROLS:  ts_admin1 TYPE TABSTRIP.
DATA:      BEGIN OF g_ts_admin1,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE 'SAPMZSD_05_KEPO',
             pressed_tab LIKE sy-ucomm VALUE c_ts_admin1-tab1,
           END OF g_ts_admin1.

*&SPWIZARD: FUNCTION CODES FOR TABSTRIP 'TS_ADMIN2'
CONSTANTS: BEGIN OF C_TS_ADMIN2,
             TAB1 LIKE SY-UCOMM VALUE 'TS_ADMIN2_FC1',
             TAB2 LIKE SY-UCOMM VALUE 'TS_ADMIN2_FC2',
             TAB3 LIKE SY-UCOMM VALUE 'TS_ADMIN2_FC3',
             TAB4 LIKE SY-UCOMM VALUE 'TS_ADMIN2_FC4',
             TAB5 LIKE SY-UCOMM VALUE 'TS_ADMIN2_FC5',
             TAB6 LIKE SY-UCOMM VALUE 'TS_ADMIN2_FC6',
             TAB7 LIKE SY-UCOMM VALUE 'TS_ADMIN2_FC7',
             TAB8 LIKE SY-UCOMM VALUE 'TS_ADMIN2_FC8',
             TAB9 LIKE SY-UCOMM VALUE 'TS_ADMIN2_FC9',
           END OF C_TS_ADMIN2.
*&SPWIZARD: DATA FOR TABSTRIP 'TS_ADMIN2'
CONTROLS:  TS_ADMIN2 TYPE TABSTRIP.
DATA:      BEGIN OF G_TS_ADMIN2,
             SUBSCREEN   LIKE SY-DYNNR,
             PROG        LIKE SY-REPID VALUE 'SAPMZSD_05_KEPO',
             PRESSED_TAB LIKE SY-UCOMM VALUE C_TS_ADMIN2-TAB1,
           END OF G_TS_ADMIN2.
