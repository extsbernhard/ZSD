*_____Reportinfos_______________________________________________________
* Dieser Report storniert die Temporär-Verrechnung gemäss Selektion.
* Vor dem Storno wird überprüft, ob der Auftrag selbst abgesagt wurde.
* Wenn dies nicht der Fall ist, kann die Stornierung nicht durchgeführt
* werden.

*     31.07.2012 Report angelegt                       IDSWE, Stadt Bern
*_______________________________________________________________________

REPORT  zsd_05_temp_auftrag_storno.





*_____Tabellen__________________________________________________________

TABLES: zsd_05_temp_verr, "Temporäre Verrechnung
        zsd_05_tverstorn, "Temporäre Verrechnung (stornierte Aufträge)
        vbap.             "Verkaufsbeleg: Positionsdaten





*_____interne Tabellen & Workareas______________________________________

DATA: it_tempverr LIKE STANDARD TABLE OF zsd_05_temp_verr,
      wa_tempverr TYPE zsd_05_temp_verr.


DATA: it_tverstorn LIKE STANDARD TABLE OF zsd_05_tverstorn,
      wa_tverstorn TYPE zsd_05_tverstorn.





*_____Selektionsbild____________________________________________________

SELECTION-SCREEN: SKIP,
                  BEGIN OF BLOCK bl1 WITH FRAME TITLE text-001,
                  SKIP.


PARAMETERS:      p_obj LIKE zsd_05_temp_verr-objekt OBLIGATORY,
                 p_vbeln LIKE zsd_05_temp_verr-vbeln_va OBLIGATORY,
                 p_sgrund LIKE zsd_05_tverstorn-storno_grund OBLIGATORY.


SELECTION-SCREEN: SKIP,
                  END OF BLOCK bl1.





*_____Auswertung________________________________________________________

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  SELECT SINGLE * FROM vbap
    WHERE vbeln = p_vbeln
    AND   abgru = space.

  IF sy-subrc = 0.
    WRITE: 'Der Auftrag', p_vbeln, 'wurde noch nicht abgesagt.'.
  ELSE.
    SELECT * FROM zsd_05_temp_verr INTO TABLE it_tempverr
        WHERE objekt   = p_obj
        AND   vbeln_va = p_vbeln.

    LOOP AT it_tempverr INTO wa_tempverr.

      MOVE-CORRESPONDING wa_tempverr TO wa_tverstorn.

      wa_tverstorn-rsto         = sy-uname.
      wa_tverstorn-dsto         = sy-datum.
      wa_tverstorn-tsto         = sy-uzeit.
      wa_tverstorn-storno_grund = p_sgrund.

      APPEND wa_tverstorn TO it_tverstorn.

    ENDLOOP.

    MODIFY zsd_05_tverstorn FROM TABLE it_tverstorn.
    IF sy-subrc = 0.
      DELETE zsd_05_temp_verr FROM TABLE it_tempverr.
    ENDIF.

    WRITE:  'Die Temporäre Verrechnung wurde erfolgreich storniert.',
          / 'Objektnummer:  ', p_obj,
          / 'Auftragsnummer:', p_vbeln.


  ENDIF.
