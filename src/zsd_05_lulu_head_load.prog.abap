*&---------------------------------------------------------------------*
*& Report  ZSD_05_LULU_PAUSCH_LOAD
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT zsd_05_lulu_head_load.

TABLES: zsd_05_lulu_heak.
.
DATA: t_head        TYPE TABLE OF zsd_05_lulu_head
    ,  t_fakt TYPE TABLE OF zsd_05_lulu_fakt
    , t_hd02 TYPE TABLE OF zsd_05_lulu_hd02
    , t_fk02 TYPE TABLE OF zsd_05_lulu_fk02
    , t_heak       TYPE TABLE OF zsd_05_lulu_heak
    , t_kehr TYPE TABLE OF zsd_04_kehricht
    , t_hinw TYPE TABLE OF zsd_05_hinweis



    , w_heak         TYPE zsd_05_lulu_heak
    , w_head         TYPE zsd_05_lulu_head
    , w_fakt        TYPE zsd_05_lulu_fakt
    , w_hd02         TYPE zsd_05_lulu_hd02
    , w_fk02         TYPE zsd_05_lulu_fk02
    , w_kehr TYPE zsd_04_kehricht
    , w_hinw TYPE zsd_05_hinweis
    , w_netwr_old(15)  TYPE c
    , w_netwr_new(15)  TYPE c
    , w_datum_1(10)      TYPE c
    , w_datum_2(10)      TYPE c
    , w_datum_3(10)      TYPE c
    , w_datum_4(10)      TYPE c
    , w_datum_5(10)      TYPE c
    , w_datum_6(10)      TYPE c
    , w_datum_7(10)      TYPE c
    , w_datum_8(10)      TYPE c
    , c_delim          TYPE c VALUE ';'
    , BEGIN OF t_line OCCURS 0
    ,  line(1024)      TYPE c
    , END OF t_line
    , w_filename_1     LIKE	rlgrap-filename VALUE
                       'c:\temp\lulu_head.csv'
    , w_filename_2     LIKE	rlgrap-filename VALUE
                       ''
    , w_filename       LIKE	rlgrap-filename
.


PARAMETERS: pdelheak TYPE xfeld RADIOBUTTON GROUP rb01 DEFAULT 'X'.
PARAMETERS: pdelhead TYPE xfeld RADIOBUTTON GROUP rb01 .
PARAMETERS: pdelfakt TYPE xfeld RADIOBUTTON GROUP rb01 .
PARAMETERS: pdelhd02 TYPE xfeld RADIOBUTTON GROUP rb01 .
PARAMETERS: pdelfk02 TYPE xfeld RADIOBUTTON GROUP rb01 .
PARAMETERS: pdelhinw TYPE xfeld RADIOBUTTON GROUP rb01 .
PARAMETERS: pdelkehr TYPE xfeld RADIOBUTTON GROUP rb01 .
SKIP.


PARAMETERS: pfheak LIKE	rlgrap-filename DEFAULT
                        'y:\lulu_heak.csv'.
PARAMETERS: pfhead LIKE  rlgrap-filename DEFAULT
                       'y:\lulu_head.csv'.
PARAMETERS: pffakt LIKE  rlgrap-filename DEFAULT
                       'y:\lulu_fakt.csv'.
PARAMETERS: pfhd02 LIKE  rlgrap-filename DEFAULT
                       'y:\lulu_hd02.csv'.
PARAMETERS: pffk02 LIKE  rlgrap-filename DEFAULT
                       'y:\lulu_fk02.csv'.
PARAMETERS: pfhinw LIKE  rlgrap-filename DEFAULT
                       'c:\temp\RE HINDEL.csv'.
PARAMETERS: pfkehr LIKE  rlgrap-filename DEFAULT
                       'c:\temp\KEHR.csv'.

DATA: lv_fallnr TYPE i
      , lv_rueckzlg_quote(35) TYPE c
      , lv_brtwr(35) TYPE c
      , lv_mandt LIKE sy-mandt.


START-OF-SELECTION.
  IF pdelheak = abap_true.
    REFRESH t_head.
    DELETE  FROM zsd_05_lulu_heak  .
    COMMIT WORK.
  ENDIF.
  IF pdelhead = abap_true.
    REFRESH t_head.
    DELETE  FROM zsd_05_lulu_head  .
    COMMIT WORK.
  ENDIF.
  IF pdelfakt = abap_true.
    REFRESH t_fakt.
    DELETE  FROM zsd_05_lulu_fakt  .
    COMMIT WORK.
  ENDIF.

  IF pdelhd02 = abap_true.
    REFRESH t_hd02.
    DELETE  FROM zsd_05_lulu_hd02  .
    COMMIT WORK.
  ENDIF.
  IF pdelfk02 = abap_true.
    REFRESH t_fk02.
    DELETE  FROM zsd_05_lulu_fk02  .
    COMMIT WORK.
  ENDIF.
  IF pdelhinw  = abap_true.
    REFRESH t_hinw .
    DELETE  FROM zsd_05_hinweis  .
    COMMIT WORK.
  ENDIF.
  CASE  'X'.
    WHEN pdelheak.
      w_filename_1 = pfheak.
    WHEN pdelhead.
      w_filename_1 = pfhead.
    WHEN pdelfakt.
      w_filename_1 = pffakt.
    WHEN pdelhd02.
      w_filename_1 = pfhd02.
    WHEN pdelfk02.
      w_filename_1 = pffk02.
    WHEN pdelhinw.
      w_filename_1 = pfhinw.
    WHEN pdelkehr .
      w_filename_1 = pfkehr.
  ENDCASE.


*  CONCATENATE w_filename_1 w_filename_2 INTO w_filename.
*  CONDENSE w_filename NO-GAPS.
  CALL FUNCTION 'WS_UPLOAD'
   EXPORTING
*   CODEPAGE                      = ' '
     filename                      = w_filename_1
     filetype                      = 'ASC'
*   HEADLEN                       = ' '
*   LINE_EXIT                     = ' '
*   TRUNCLEN                      = ' '
*   USER_FORM                     = ' '
*   USER_PROG                     = ' '
*   DAT_D_FORMAT                  = ' '
* IMPORTING
*   FILELENGTH                    =
    TABLES
      data_tab                      = t_line
   EXCEPTIONS
     conversion_error              = 1
     file_open_error               = 2
     file_read_error               = 3
     invalid_type                  = 4
     no_batch                      = 5
     unknown_error                 = 6
     invalid_table_width           = 7
     gui_refuse_filetransfer       = 8
     customer_error                = 9
     no_authority                  = 10
     OTHERS                        = 11.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ENDIF.

  break exschweitzer.

END-OF-SELECTION.


  CASE  'X'.
    WHEN pdelheak.

      LOOP AT t_line.
        IF sy-tabix EQ 1
        OR t_line IS INITIAL.
*    exit.
        ELSE.
          CLEAR w_heak.
*
          SPLIT t_line AT c_delim INTO
          lv_mandt
           w_heak-fallnr
           w_heak-stadtteil
           w_heak-parzelle
           w_heak-objekt
            w_heak-status
*       w_heak-per_beginn
   w_datum_1
*       w_heak-per_ende
  w_datum_2
         w_heak-eigen_ver
         w_heak-eigen_ver_other
         w_heak-anschr_art
         w_heak-vollmacht
         w_heak-eigen_kunnr
         w_heak-vertr_kunnr
         w_heak-nutz_art
         w_heak-rueckerst_art
         w_heak-rg_kunnr
         w_heak-mwst_nr
         w_heak-vorsteuerx
*       w_heak-eigda
  w_datum_3
         w_heak-rueckzlg_pl_x
        w_heak-rueckzlg_quote
        w_heak-rueckzlg_quotex
        w_heak-name1_ausz
        w_heak-name2_ausz
        w_heak-stras_ausz
        w_heak-ort1_ausz
        w_heak-pstlz_ausz
        w_heak-bankl_ausz
        w_heak-bankn_ausz
        w_heak-wrbtr_ausz
        w_heak-esrnr_ausz
        w_heak-esrre_ausz
        w_heak-konto_ausz
        w_heak-sgtxt_ausz
        w_heak-loevm
*      w_heak-vfgdt
  w_datum_4
*      w_heak-rkrdt
  w_datum_5
*      w_heak-aszdt
  w_datum_6
        w_heak-belnr
        w_heak-obj_key.

          CLEAR lv_fallnr.
          MOVE  w_heak-fallnr TO lv_fallnr.
          CLEAR w_heak-fallnr.
          MOVE lv_fallnr TO w_heak-fallnr.


          CLEAR: w_heak-per_beginn, w_heak-per_ende, w_heak-eigda, w_heak-vfgdt, w_heak-rkrdt, w_heak-aszdt.
          CONCATENATE w_datum_1+6(4) w_datum_1+3(2) w_datum_1(2) INTO w_heak-per_beginn.
          CONCATENATE w_datum_2+6(4) w_datum_2+3(2) w_datum_2(2) INTO w_heak-per_ende.
          CONCATENATE w_datum_3+6(4) w_datum_3+3(2) w_datum_3(2) INTO w_heak-eigda.
          CONCATENATE w_datum_4+6(4) w_datum_4+3(2) w_datum_4(2) INTO w_heak-vfgdt.
          CONCATENATE w_datum_5+6(4) w_datum_5+3(2) w_datum_5(2) INTO  w_heak-rkrdt.
          CONCATENATE w_datum_6+6(4) w_datum_6+3(2) w_datum_6(2) INTO w_heak-aszdt.
          CLEAR: w_datum_1, w_datum_2, w_datum_3, w_datum_4, w_datum_5.

          APPEND w_heak    TO t_heak.

        ENDIF.
      ENDLOOP.

      " " break exschweitzer.

      MODIFY zsd_05_lulu_heak FROM TABLE t_heak.

      COMMIT WORK.

* Gesuche Kopf

    WHEN pdelhead.

      LOOP AT t_line.
        IF sy-tabix EQ 1
        OR t_line IS INITIAL.
*    exit.
        ELSE.
          CLEAR w_head.
*
          SPLIT t_line AT c_delim INTO
          lv_mandt
           w_head-fallnr
           w_head-stadtteil
           w_head-parzelle
           w_head-objekt
            w_head-status
 w_datum_1
*         w_head-per_beginn
 w_datum_2
*         w_head-per_ende
         w_head-eigen_ver
         w_head-eigen_ver_other
         w_head-anschr_art
         w_head-vollmacht
         w_head-eigen_kunnr
         w_head-vertr_kunnr
         w_head-nutz_art
         w_head-rueckerst_art
         w_head-rg_kunnr
         w_head-mwst_nr
         w_head-vorsteuerx
 w_datum_3
*         w_head-eigda
         w_head-rueckzlg_pl_x
*      w_head-rueckzlg_quote
       lv_rueckzlg_quote
        w_head-rueckzlg_quotex
        w_head-name1_ausz
        w_head-name2_ausz
        w_head-stras_ausz
        w_head-ort1_ausz
        w_head-pstlz_ausz
        w_head-bankl_ausz
        w_head-bankn_ausz
        w_head-wrbtr_ausz
        w_head-esrnr_ausz
        w_head-esrre_ausz
        w_head-konto_ausz
        w_head-sgtxt_ausz
        w_head-loevm
 w_datum_4
*        w_head-vfgdt
 w_datum_5
*        w_head-rkrdt
 w_datum_6
*        w_head-aszdt
        w_head-belnr
        w_head-obj_key.

          CLEAR lv_fallnr.
          MOVE  w_head-fallnr TO lv_fallnr.
          CLEAR w_head-fallnr.
          MOVE lv_fallnr TO w_head-fallnr.

          CLEAR w_head-rueckzlg_quote.
          MOVE lv_rueckzlg_quote TO w_head-rueckzlg_quote.
          CLEAR lv_rueckzlg_quote.

          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT':"
                      EXPORTING input = w_head-parzelle
                      IMPORTING output = w_head-parzelle,
                      EXPORTING input = w_head-objekt
                      IMPORTING output = w_head-objekt,
                      EXPORTING input = w_head-esrre_ausz
                      IMPORTING output = w_head-esrre_ausz.

          CLEAR: w_head-per_beginn, w_head-per_ende, w_head-eigda, w_head-vfgdt, w_head-rkrdt, w_head-aszdt.
          CONCATENATE w_datum_1+6(4) w_datum_1+3(2) w_datum_1(2) INTO w_head-per_beginn.
          CONCATENATE w_datum_2+6(4) w_datum_2+3(2) w_datum_2(2) INTO w_head-per_ende.
          CONCATENATE w_datum_3+6(4) w_datum_3+3(2) w_datum_3(2) INTO w_head-eigda.
          CONCATENATE w_datum_4+6(4) w_datum_4+3(2) w_datum_4(2) INTO w_head-vfgdt.
          CONCATENATE w_datum_5+6(4) w_datum_5+3(2) w_datum_5(2) INTO w_head-rkrdt.
          CONCATENATE w_datum_6+6(4) w_datum_6+3(2) w_datum_6(2) INTO w_head-aszdt.
          CLEAR: w_datum_1, w_datum_2, w_datum_3, w_datum_4, w_datum_5.

          APPEND w_head    TO t_head.
        ENDIF.
      ENDLOOP.

      "break exschweitzer.

      MODIFY zsd_05_lulu_head FROM TABLE t_head.

      COMMIT WORK.

*  Gesuche Fakturen

    WHEN pdelfakt.

      LOOP AT t_line.
        IF sy-tabix EQ 1
        OR t_line IS INITIAL.
*    exit.
        ELSE.
          CLEAR w_fakt.

          SPLIT t_line AT c_delim INTO
          lv_mandt
           w_fakt-fallnr
           w_fakt-vbeln
 w_datum_1
*           w_fakt-fkdat
           w_fakt-waerk
           lv_brtwr
*          w_fakt-brtwr
         w_fakt-kennz
         w_fakt-fkkopiex.



          CLEAR lv_fallnr.
          MOVE  w_fakt-fallnr TO lv_fallnr.
          CLEAR w_fakt-fallnr.
          MOVE lv_fallnr TO w_fakt-fallnr.

          CLEAR w_fakt-brtwr.
          REPLACE ALL OCCURRENCES OF ','  IN lv_brtwr WITH ''.
          MOVE lv_brtwr TO w_fakt-brtwr.
          CLEAR lv_brtwr.

          CLEAR: w_fakt-fkdat.
          CONCATENATE w_datum_1+6(4) w_datum_1+3(2) w_datum_1(2) INTO w_fakt-fkdat.
          CLEAR: w_datum_1.

          APPEND w_fakt    TO t_fakt.
        ENDIF.
      ENDLOOP.

      " " break exschweitzer.

      MODIFY zsd_05_lulu_fakt FROM TABLE t_fakt.

      COMMIT WORK.

    WHEN pdelhd02.

* Fall Kopf
      LOOP AT t_line.
        IF sy-tabix EQ 1
        OR t_line IS INITIAL.
*    exit.
        ELSE.
          CLEAR w_hd02.

          SPLIT t_line AT c_delim INTO
          lv_mandt
           w_hd02-fallnr
           w_hd02-stadtteil
           w_hd02-parzelle
           w_hd02-objekt
            w_hd02-status
 w_datum_1
*         w_hd02-per_beginn
 w_datum_2
*         w_hd02-per_ende
         w_hd02-vollmacht
         w_hd02-eigen_kunnr
         w_hd02-vertr_kunnr
         w_hd02-rg_kunnr
         w_hd02-mwst_nr
         w_hd02-vorsteuerx
 w_datum_3
*         w_hd02-eigda
        w_hd02-name1_ausz
        w_hd02-name2_ausz
        w_hd02-stras_ausz
        w_hd02-ort1_ausz
        w_hd02-pstlz_ausz
        w_hd02-bankl_ausz
        w_hd02-bankn_ausz
        w_hd02-wrbtr_ausz
        w_hd02-esrnr_ausz
        w_hd02-esrre_ausz
        w_hd02-konto_ausz
        w_hd02-sgtxt_ausz
        w_hd02-angaben_sperre_x
        w_hd02-loevm
 w_datum_7
*       w_hd02-pridt_einz
 w_datum_8
*       w_hd02-pridt_mass
 w_datum_4
*        w_hd02-vfgdt
 w_datum_5
*        w_hd02-rkrdt
 w_datum_6
*        w_hd02-aszdt
        w_hd02-belnr
        w_hd02-obj_key.

          CLEAR lv_fallnr.
          MOVE  w_hd02-fallnr TO lv_fallnr.
          CLEAR w_hd02-fallnr.
          MOVE lv_fallnr TO w_hd02-fallnr.

          CLEAR: w_hd02-per_beginn, w_hd02-per_ende, w_hd02-eigda, w_hd02-vfgdt, w_hd02-rkrdt, w_hd02-aszdt.
          CONCATENATE w_datum_1+6(4) w_datum_1+3(2) w_datum_1(2) INTO w_hd02-per_beginn.
          CONCATENATE w_datum_2+6(4) w_datum_2+3(2) w_datum_2(2) INTO w_hd02-per_ende.
          CONCATENATE w_datum_3+6(4) w_datum_3+3(2) w_datum_3(2) INTO w_hd02-eigda.
          CONCATENATE w_datum_4+6(4) w_datum_4+3(2) w_datum_4(2) INTO w_hd02-vfgdt.
          CONCATENATE w_datum_5+6(4) w_datum_5+3(2) w_datum_5(2) INTO w_hd02-rkrdt.
          CONCATENATE w_datum_6+6(4) w_datum_6+3(2) w_datum_6(2) INTO w_hd02-aszdt.
          CONCATENATE w_datum_7+6(4) w_datum_7+3(2) w_datum_7(2) INTO w_hd02-pridt_einz.
          CONCATENATE w_datum_8+6(4) w_datum_8+3(2) w_datum_8(2) INTO w_hd02-pridt_mass.

          CLEAR: w_datum_1, w_datum_2, w_datum_3, w_datum_4, w_datum_5,w_datum_6, w_datum_7, w_datum_8.

          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT':"
            EXPORTING input = w_hd02-parzelle
            IMPORTING output = w_hd02-parzelle,
            EXPORTING input = w_hd02-objekt
            IMPORTING output = w_hd02-objekt,
            EXPORTING input = w_head-esrre_ausz
            IMPORTING output = w_head-esrre_ausz.

          APPEND w_hd02    TO t_hd02.
        ENDIF.
      ENDLOOP.

      " " break exschweitzer.

      MODIFY zsd_05_lulu_hd02 FROM TABLE t_hd02.

      COMMIT WORK.

*  Fälle Fakturen
    WHEN pdelfk02.

      LOOP AT t_line.
        IF sy-tabix EQ 1
        OR t_line IS INITIAL.
*    exit.
        ELSE.
          CLEAR w_fk02.

          SPLIT t_line AT c_delim INTO
          lv_mandt
           w_fk02-fallnr
           w_fk02-vbeln
*           w_fk02-fkdat
 w_datum_1
           w_fk02-waerk
           lv_brtwr
*          w_fk02-brtwr
 w_datum_2
* verrg_beginn
 w_datum_3
* verrg_ende
         w_fk02-kennz
         w_fk02-fkkopiex.

          CLEAR lv_fallnr.
          MOVE  w_fk02-fallnr TO lv_fallnr.
          CLEAR w_fk02-fallnr.
          MOVE lv_fallnr TO w_fk02-fallnr.

          CLEAR w_fk02-brtwr.
          REPLACE ALL OCCURRENCES OF ','  IN lv_brtwr WITH ''.
          MOVE lv_brtwr TO w_fk02-brtwr.
          CLEAR lv_brtwr.

          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT' "
                EXPORTING input = w_fk02-vbeln
                IMPORTING output = w_fk02-vbeln.

          CLEAR: w_fk02-fkdat, w_fk02-verrg_beginn, w_fk02-verrg_ende.
          CONCATENATE w_datum_1+6(4) w_datum_1+3(2) w_datum_1(2) INTO w_fk02-fkdat.
          CONCATENATE w_datum_2+6(4) w_datum_2+3(2) w_datum_2(2) INTO w_fk02-verrg_beginn.
          CONCATENATE w_datum_3+6(4) w_datum_3+3(2) w_datum_3(2) INTO w_fk02-verrg_ende.
          CLEAR: w_datum_1, w_datum_2, w_datum_3.

          APPEND w_fk02    TO t_fk02.
        ENDIF.
      ENDLOOP.

      " " break exschweitzer.

      MODIFY zsd_05_lulu_fk02 FROM TABLE t_fk02.

      COMMIT WORK.

    WHEN pdelhinw.
      LOOP AT t_line.
        IF sy-tabix EQ 1
        OR t_line IS INITIAL.
*    exit.
        ELSE.
          CLEAR w_hinw.
*
          SPLIT t_line AT c_delim INTO
*          lv_mandt
          w_hinw-stadtteil
          w_hinw-parzelle
          w_hinw-objekt
          w_hinw-hinweis
          w_hinw-hintext.
          IF  w_hinw-objekt = ''.
            MOVE '0000' TO    w_hinw-objekt.
          ENDIF.

          APPEND w_hinw    TO t_hinw.
        ENDIF.
      ENDLOOP.
      LOOP AT t_hinw INTO w_hinw.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT':"
            EXPORTING input = w_hinw-parzelle
            IMPORTING output = w_hinw-parzelle,
            EXPORTING input = w_hinw-objekt
            IMPORTING output = w_hinw-objekt
.
        CONCATENATE w_hinw-stadtteil w_hinw-parzelle w_hinw-objekt INTO w_hinw-obj_key.
        MODIFY t_hinw FROM w_hinw.

      ENDLOOP.
      DELETE ADJACENT DUPLICATES FROM t_hinw.
      MODIFY zsd_05_hinweis FROM TABLE t_hinw.
      COMMIT WORK.
    WHEN pdelkehr.
      LOOP AT t_line.
        IF sy-tabix EQ 1
        OR t_line IS INITIAL.
*    exit.
        ELSE.
          CLEAR w_kehr.
*
          SPLIT t_line AT c_delim INTO
          lv_mandt
w_kehr-stadtteil
w_kehr-parzelle
w_kehr-objekt
w_kehr-eigen_kunnr
w_kehr-vertr_kunnr
w_kehr-eigen_ver
w_kehr-eigen_ver_other
w_kehr-anschr_art
w_kehr-vollmacht
w_kehr-kunnr
w_kehr-adrnr
w_kehr-vkorg
w_kehr-vtweg
w_kehr-spart
w_kehr-vkbur
*w_kehr-flaeche_bebaut
w_kehr-verr_parz1
w_kehr-verr_parz2
*w_kehr-flaeche_fakt1
*w_kehr-flaeche_fakt2
*w_kehr-flaeche_fakt3
*w_kehr-flaeche_fakt4
*w_kehr-flaeche_fakt5
*w_kehr-jahresgebuehr
*w_kehr-vflaeche_fakt1
*w_kehr-vflaeche_fakt2
*w_kehr-vflaeche_fakt3
*w_kehr-vflaeche_fakt4
*w_kehr-vflaeche_fakt5
w_kehr-berechnung
w_kehr-bez_fakt1
w_kehr-bez_fakt2
w_kehr-bez_fakt3
w_kehr-bez_fakt4
w_kehr-bez_fakt5
w_kehr-bez_pauschal
w_kehr-verr_perio
w_kehr-verr_datum
w_kehr-verr_datum_schl
w_kehr-verr_code
w_kehr-verr_grund
w_kehr-hinweis1
w_kehr-hintext1
w_kehr-hinweis2
w_kehr-hintext2
w_kehr-hinweis3
w_kehr-hintext3
w_kehr-hinweis4
w_kehr-hintext4
w_kehr-hinweis5
w_kehr-hintext5
w_kehr-hinweis6
w_kehr-hintext6
w_kehr-hinweis7
w_kehr-hintext7
w_kehr-hinweis8
w_kehr-hintext8
w_kehr-cname
w_kehr-cdate
w_kehr-ctime
w_kehr-uname
w_kehr-udate
w_kehr-utime
w_kehr-obj_key.






          IF  w_kehr-objekt = ''.
            MOVE '0000' TO    w_kehr-objekt.
          ENDIF.

          APPEND w_kehr    TO t_kehr.
        ENDIF.
      ENDLOOP.
      LOOP AT t_kehr INTO w_kehr.
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT':"
            EXPORTING input = w_kehr-parzelle
            IMPORTING output = w_kehr-parzelle,
            EXPORTING input = w_kehr-objekt
            IMPORTING output = w_kehr-objekt
.
        CONCATENATE w_kehr-stadtteil w_kehr-parzelle w_kehr-objekt INTO w_kehr-obj_key.
        MODIFY t_kehr FROM w_kehr.

      ENDLOOP.

*      MODIFY zsd_04_kehrricht FROM TABLE t_kehr.
      COMMIT WORK.
  ENDCASE.
