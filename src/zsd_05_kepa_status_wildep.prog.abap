*---------------------------------------------------------------------*
* Report  Z_KEPA_WIDE
*---------------------------------------------------------------------*
* Firma     : Stadtverwaltung Bern Informatikdienste
* Ersteller : 07.10.2015 / David Ricci
*---------------------------------------------------------------------*
* Beschreibung:
* Dieser Report dient dazu KEPA-Fälle welche der Fallart 'Wilde Deponie'
* zugeordnet sind und mindestens drei Monate alt sind, geschlossen
* werden. Dazu wird das Programm durch ein Job regelmässig ausgeführt.
*---------------------------------------------------------------------*
* Änderungen:
* TT.MM.JJJJ  Name / Firma
*
*---------------------------------------------------------------------*
REPORT zsd_05_kepa_status_wildep LINE-SIZE 132.

* ------ Tabellendefinitionen       (TABLES)
TABLES: zsdtkpkepo.

* ------ Typendefinitionen          (TYPES)
DATA: gt_kopfdaten_kepa LIKE TABLE OF zsdtkpkepo.

* ------ Feldsymbole                (FIELD-SYMBOLS)
FIELD-SYMBOLS: <gf_kopfdaten_kepa> LIKE zsdtkpkepo.


*---------------------------------------------------------------------*
* Selektionsbild                    (select-option / Parameters)
*---------------------------------------------------------------------*

PARAMETERS p_update TYPE c AS CHECKBOX DEFAULT ''.

*---------------------------------------------------------------------*
*INITIALIZATION
*---------------------------------------------------------------------*

" Fallart: 01 - Blaue Kehrichtsäcke        Fallstatus: 01 - erfasst
"          02 - Schwarze Kehrichtsäcke                 02 - offen
"          03 - Papier / Karton                        03 - erledigt
"          04 - Wilde Deponie                          04 - annulliert
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
IF p_update = 'X'.

  SELECT * FROM zsdtkpkepo INTO TABLE gt_kopfdaten_kepa.

  DATA: anz_faelle  TYPE i,
        anz_aend    TYPE i,
        date_diff   TYPE p.

  LOOP AT gt_kopfdaten_kepa ASSIGNING <gf_kopfdaten_kepa>.

    anz_faelle = anz_faelle + 1.

    CALL FUNCTION 'SD_DATETIME_DIFFERENCE'
      EXPORTING
        date1            = <gf_kopfdaten_kepa>-fdat
        time1            = sy-uzeit
        date2            = sy-datum
        time2            = sy-uzeit
      IMPORTING
        datediff         = date_diff
      EXCEPTIONS
        invalid_datetime = 1
*       OTHERS           =  2
      .
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.

    IF <gf_kopfdaten_kepa>-fart = 04 AND date_diff > 90 AND <gf_kopfdaten_kepa>-fstat <> 03  .
      <gf_kopfdaten_kepa>-fstat = '03'.
      anz_aend = anz_aend + 1.
    ENDIF.

  ENDLOOP.

  IF anz_aend > 0.

    CALL FUNCTION 'ENQUEUE_EZSD_05_KEPO'
     EXPORTING
       mode_zsdtkpkepo         = 'E'
       mandt                   = sy-mandt
       _scope                  = '2'
*   EXCEPTIONS
*     FOREIGN_LOCK            = 1
*     SYSTEM_FAILURE          = 2
*     OTHERS                  = 3
              .
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ENDIF.


    UPDATE zsdtkpkepo FROM TABLE gt_kopfdaten_kepa.

    CALL FUNCTION 'DEQUEUE_EZSD_05_KEPO'
      EXPORTING
        mode_zsdtkpkepo = 'E'
        mandt           = sy-mandt
        _scope          = '3'
      .

  ENDIF.

  WRITE: anz_faelle, 'Fälle wurden abgearbeitet.'.
  WRITE: anz_aend, 'Fälle wurden angepasst.'.

ENDIF.
