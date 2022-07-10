REPORT zsd_01_korrektur_auftrag .


TABLES: vbap.
DATA: t_vbap TYPE vbap OCCURS 0 WITH HEADER LINE.
DATA: w_tdname TYPE tdobname.
SELECT-OPTIONS: s_vbeln FOR vbap-vbeln,
                s_matnr FOR vbap-matnr.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
SELECT        * FROM  vbap
       INTO TABLE t_vbap
       WHERE  vbeln IN s_vbeln
       AND    matnr IN s_matnr.
LOOP AT t_vbap.
  CONCATENATE t_vbap-vbeln t_vbap-posnr INTO w_tdname.
  CALL FUNCTION 'DELETE_TEXT'
       EXPORTING
            client          = sy-mandt
            id              = '0001'
            language        = sy-langu
            name            = w_tdname
            object          = 'VBBP'
            savemode_direct = 'X'
       EXCEPTIONS
            not_found       = 1
            OTHERS          = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDLOOP.
