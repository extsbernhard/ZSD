*&---------------------------------------------------------------------*
*& Include ZSD_SBZ_DEBILIST_TOP       Report ZSD_SBZ_DEBILIST_AP01
*&
*&---------------------------------------------------------------------*

REPORT zsd_sbz_debilist_ap01.

*------ Transparent SAP data-tabs and fields --------------------------
TABLES: kna1                            "Debitoren-Stammdaten allgemein
      , knvv                            "Debitoren-Stammdaten Vertrieb
      , knvk                            "Debitoren-Ansprechpartner
      , adrc                            "zentrale Adressdaten allgemein
      , adr6                            "zentrale E-Mailadressen (ADRC)
      .
*------ working data-tabs and fields ----------------------------------
DATA:   t_debi_in         TYPE TABLE OF zsd_sbz_debilist_si1
    ,   s_debi_in         LIKE LINE OF t_debi_in
    ,   t_debi_out        TYPE TABLE OF zsd_sbz_debilist_so1
    ,   s_debi_out        LIKE LINE OF t_debi_out
    ,   t_ap_out          TYPE TABLE OF zsd_sbz_debilist_so2
    ,   s_ap_out          LIKE LINE OF t_ap_out
    ,   BEGIN OF t_kna1   OCCURS 0
    ,    kunnr            TYPE kunnr
    ,    brsch            TYPE brsch
    ,    adrnr            TYPE adrnr
         " Zusätzliche Spalten IDDRI1 20190314
    ,    bran1            TYPE bran1_d
        " Zusätzliche Spalten IDDRI1 20190314
    ,   END   OF t_kna1
*    ,   s_kna1            type line of t_kna1
    ,   BEGIN OF t_knvk   OCCURS 0
    ,    parnr            TYPE parnr
    ,    kunnr            TYPE kunnr
    ,    adrnd            TYPE adrnd
    ,    telf1            TYPE telf1
    ,    pafkt            TYPE pafkt
    ,    parge            TYPE parge
    ,    prsnr            TYPE ad_persnum
    ,    anred            TYPE anred
    ,    abtpa            TYPE abtei_pa
    ,    name1            TYPE abtnr_pa
    ,    namev            TYPE name1_gp
    ,    ort01   	        TYPE ort01_gp
         " Zusätzliche Spalten IDDRI1 20180416
    ,    pavip   	        TYPE pavip
    ,    abtnr   	        TYPE abtnr_pa
    ,    parvo   	        TYPE parvo
         " Zusätzliche Spalten IDDRI1 20180806
    ,    parh1            TYPE paat6
    ,    parh2            TYPE paat6
    ,    parh3            TYPE paat6
    ,    parh4            TYPE paat6
    ,    parh5            TYPE paat6
    ,    pakn1            TYPE paat6
    ,    pakn2            TYPE paat6
    ,    pakn3            TYPE paat6
    ,    pakn4            TYPE paat6
    ,    pakn5            TYPE paat6
    ,   END   OF t_knvk
*    ,   s_knvk            type line of t_knvk
    ,   s_adrc_debi       TYPE adrc
    ,   s_adrc_ap         TYPE adrc
    ,   s_adr6_debi       TYPE adr6
    ,   s_adr2_ap         TYPE adr2
    ,   s_adr3_ap         TYPE adr3
    ,   s_adr6_ap         TYPE adr6
    ,   s_adrp_ap         TYPE adrp
    ,   s_kna1            TYPE kna1
    ,   s_knvv            TYPE knvv
    ,   s_knvk            TYPE knvk
    .
*------ constants -----------------------------------------------------
DATA:   c_activ              TYPE c VALUE 'X'
    ,   c_inactiv            TYPE c VALUE ' '
    ,   c_leer               TYPE c VALUE ' '
    ,   c_kz_s               TYPE c VALUE 'S'
    ,   c_kz_d               TYPE c VALUE 'D'
    ,   c_initial            TYPE dats VALUE '00000000'
    ,   c_initial10          TYPE ad_persnum VALUE '0000000000'
    ,   c_2000               TYPE dats VALUE '20000101'
    ,   c_4zero(4)           TYPE c VALUE '0000'
    ,   c_deblist_in(20)     TYPE c VALUE 'ZSD_SBZ_DEBILIST_SI1'
    ,   c_deblist_out(20)    TYPE c VALUE 'ZSD_SBZ_DEBILIST_SO1'
    ,   c_info               TYPE c VALUE 'I'
    ,   c_error              TYPE c VALUE 'E'
    ,   c_abort              TYPE c VALUE 'A'
    ,   c_warning            TYPE c VALUE 'W'
    ,   c_deball(6)          TYPE c VALUE 'deball'
    ,   c_debohn(6)          TYPE c VALUE 'debohn'
    ,   c_apalle(6)          TYPE c VALUE 'apalle'
    ,   c_alv_save           TYPE c VALUE 'A'
    .

DATA:   w_vkz(6)             TYPE c
    ,   w_old_kunnr          TYPE kunnr
    ,   w_lines              TYPE i
    ,   w_alv_struc          TYPE tabname
                             VALUE 'ZSD_SBZ_DEBILIST_SO1'
    ,   w_alv_struc2         TYPE tabname
                             VALUE 'ZSD_SBZ_DEBILIST_SO2'
    ,   w_alv_variant        TYPE disvariant
    ,   w_alv_layout         TYPE slis_layout_alv
    .
*----------------------------------------------------------------------*
DATA    screen_wa            TYPE screen.
*----------------------------------------------------------------------*
*======================================================================*
*INITIALIZATION.
LOAD-OF-PROGRAM.
*======================================================================*
* i_vfdat = sy-datum + 2.
* i_rkdat = i_vfdat + 40.

*======================================================================*
  SELECTION-SCREEN: BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-001.
  PARAMETERS:    p_deball      RADIOBUTTON GROUP ausw DEFAULT 'X'
            ,    p_debohn      RADIOBUTTON GROUP ausw
            ,    p_apalle      RADIOBUTTON GROUP ausw
            .
* selection-screen: skip 1.
* selection-screen: uline .
  SELECTION-SCREEN: END   OF BLOCK bl1.
*======================================================================*
  SELECTION-SCREEN: BEGIN OF BLOCK bl2 WITH FRAME TITLE TEXT-002.
  SELECT-OPTIONS: s_kunnr    FOR knvv-kunnr.
  SELECT-OPTIONS: s_vkorg    FOR knvv-vkorg MEMORY ID vko.
  SELECT-OPTIONS: s_vtweg    FOR knvv-vtweg MEMORY ID vtw.
  SELECT-OPTIONS: s_kdgrp    FOR knvv-kdgrp MEMORY ID vkd.
  SELECT-OPTIONS: s_brsch    FOR kna1-brsch.
  " Neue Selection Options IDDRI1 20190314
  SELECT-OPTIONS: s_bran1    FOR kna1-bran1.

* selection-screen: skip 1.
* selection-screen: uline .
  SELECTION-SCREEN: END   OF BLOCK bl2.
*======================================================================*
  SELECTION-SCREEN: BEGIN OF BLOCK bl3 WITH FRAME TITLE TEXT-003.
  SELECT-OPTIONS: s_pafkt    FOR knvk-pafkt.
  SELECT-OPTIONS: s_abtpa    FOR knvk-abtpa NO-DISPLAY.
  " Neue Selection Options IDDRI1 20170314
  SELECT-OPTIONS: s_pavip FOR knvk-pavip.
  SELECT-OPTIONS: s_abtnr FOR knvk-abtnr.
  SELECT-OPTIONS: s_parvo FOR knvk-parvo.

  SELECT-OPTIONS: s_pakn1 FOR knvk-pakn1.

* SELECT-OPTIONS: s_PArh1 for KNVK-PArh1.
* SELECT-OPTIONS: s_PArh2 for KNVK-PArh2.
* SELECT-OPTIONS: s_PArh3 for KNVK-PArh3.
* SELECT-OPTIONS: s_PArh4 for KNVK-PArh4.
* SELECT-OPTIONS: s_PArh5 for KNVK-PArh5.
* SELECT-OPTIONS: s_PAkn2 for KNVK-PAkn2.
* SELECT-OPTIONS: s_PAkn3 for KNVK-PAkn3.
* SELECT-OPTIONS: s_PAkn4 for KNVK-PAkn4.
* SELECT-OPTIONS: s_PAkn5 for KNVK-PAkn5.

* selection-screen: skip 1.
* selection-screen: uline .
  SELECTION-SCREEN: END   OF BLOCK bl3.
*======================================================================*
  SELECTION-SCREEN: BEGIN OF BLOCK bl4 WITH FRAME TITLE TEXT-004.
  PARAMETERS:    p_deb1ap    RADIOBUTTON GROUP lis1
            ,    p_deb9ap    RADIOBUTTON GROUP lis1 DEFAULT 'X'
            .
  PARAMETERS:    p_vari      TYPE slis_vari
           .
* selection-screen: skip 1.
* selection-screen: uline .
  SELECTION-SCREEN: END   OF BLOCK bl4.
*======================================================================*
*======================================================================*
