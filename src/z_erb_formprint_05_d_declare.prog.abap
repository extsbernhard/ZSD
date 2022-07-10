*----------------------------------------------------------------------*
*   INCLUDE RLB_INVOICE_DATA_DECLARE                                   *
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
*   INCLUDE RLB_INVOICE_DATA_DECLARE                                   *
*----------------------------------------------------------------------*

INCLUDE RVADTABL.

DATA:   RETCODE   LIKE SY-SUBRC.       "Returncode
DATA:   XSCREEN(1) TYPE C.             "Output on printer or screen
DATA:   REPEAT(1) TYPE C.
DATA: NAST_ANZAL LIKE NAST-ANZAL.      "Number of outputs (Orig. + Cop.)
DATA: NAST_TDARMOD LIKE NAST-TDARMOD.  "Archiving only one time

* current language for read buffered.
DATA: GF_LANGUAGE LIKE SY-LANGU.
*>>>>>>>>>>>>>>>>>>>>>>>>> Eigene ERB-Felder >>>>>>>>>>>>>>>>>>>>>>>>>>
data: s_hwtxt           type range of zsd_04_kehricht-hinweis1
    , ls_hwtxt          like line of s_hwtxt
    .
*     interne Tabellen
data: wt_vbrp           type table of ZSD_05_VBRP_ERB
                        with HEADER LINE
    , wt_hinweis        type table of zsd_05_hinweis
    , ws_hinweis        like line of wt_hinweis
    .
*     interne Strukturen
data: ws_vbrk           type vbrk      "Faktura-Kopf-Daten
    , ws_vbak           type vbak      "Auftrags-Kopf-Daten
    , ws_vbdre          type vbdre     "ESR-Daten
    , ws_vbrp           type ZSD_05_VBRP_ERB "Faktura-Pos-Daten-Struktur
    , ws_kna1           type kna1      "Kunden-Allgemeine Daten
    , ws_kehr_auft      type zsd_05_kehr_auft "Auftrag zu Objekt
    , ws_objekt         type zsd_05_objekt    "Objekt-Daten
    , ws_re_addr        type ZSD_05_ADDR_ERB
    , ws_rg_addr        type ZSD_05_ADDR_ERB
    , ws_kehricht       type zsd_04_kehricht
    .
*     interne Schalter-Felder
data: w_ok              type c         "Schalter für weiter oder nicht
    , w_lines           type i         "Zähler für Tabelleneinträge
    .
*     interne Konstante
data: c_null            type i value 0   "Konstante mit Wert 0
    , c_leer            type c value ''  "Konstante mit Leer
    , c_info            type c value 'I' "Konstante mit I für Info
    , c_warn            type c value 'W' "Konstante mit W für Warning
    , c_error           type c value 'E' "Konstante mit E für Error
    , c_abort           type c value 'A' "Konstante mit A für Abbruch
    , c_tx              type kappl    value 'TX'
    , c_zpst            type kschl    value 'ZPST'
    , c_ch              type aland    value 'CH'
    , c_0001            type tdid     value '0001'
    , c_vbbp            type tdobject value 'VBBP'
    , c_de              type tdspras  value 'D'
    .
