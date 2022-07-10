*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_SCREEN_MODIFY_O01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_3008  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE screen_modify_3008 OUTPUT.


PERFORM check_wiederholung.





  "tables zsd_05_kepo_ver.
  "data kepo_ver type LINE OF zsd_05_kepo_ver.
  "Selektiere Verwarnungen zu Fallnummer
  "Wenn kein Löscheintrag gesetzt.
  if gs_kepo-fallnr is initial.
        LOOP AT SCREEN.

      "Create eingabefähig
      IF screen-name = 'BTN_VER_CREATE'.
        screen-input = 0.
      ENDIF.

      "Show eingabefähig
      IF screen-name = 'BTN_VER_SHOW'.
        screen-input = 0.
      ENDIF.

      "Entfernen nicht eingabefähig
      IF screen-name = 'BTN_VER_ENT'.
        screen-input = 0.
      ENDIF.

      MODIFY SCREEN.

    ENDLOOP.
    else.



  IF mode = 'ANZE'.
    "Suche Verwarnung zu Fallnummer
    IF loesch = ''.
      SELECT SINGLE * FROM zsd_05_kepo_ver INTO gs_verwarnung WHERE fallnr = gs_kepo-fallnr AND typ = 'V' AND gjahr = gs_kepo-gjahr AND loesch NE 'X'.
    ENDIF.
    "wenn nichts gefunden und es sich um ein Wiederholungsfall handelt.
    "Suche Verwarnung nach debitor, Typ und löschkennzeichen. (gjahr muss kleiner sein als heute - 2)
    if sy-subrc ne 0 and gs_kepo-fwdh = 'X'.
      data jahrminuszwei type integer.
      jahrminuszwei = gs_kepo-gjahr - 2.
     SELECT SINGLE * FROM zsd_05_kepo_ver INTO gs_verwarnung WHERE debitor = gs_kepo-kunnr AND gjahr > jahrminuszwei and typ = 'V' AND loesch NE 'X'.

  endif.
      gs_verwarnung-bem = gs_kepo-bem_verwarnung.

    LOOP AT SCREEN.

      "Create eingabefähig
      IF screen-name = 'BTN_VER_CREATE'.
        screen-input = 0.
      ENDIF.

      "Show eingabefähig
      IF screen-name = 'BTN_VER_SHOW'.
        screen-input = 0.
      ENDIF.

      "Entfernen nicht eingabefähig
      IF screen-name = 'BTN_VER_ENT'.
        screen-input = 0.
      ENDIF.

      MODIFY SCREEN.

    ENDLOOP.

ELSE.
  IF loesch = ''.
    SELECT SINGLE * FROM zsd_05_kepo_ver INTO gs_verwarnung WHERE fallnr = gs_kepo-fallnr AND typ = 'V' AND gjahr = gs_kepo-gjahr AND loesch NE 'X'.

    if sy-subrc ne 0 and gs_kepo-fwdh = 'X'.
      data jahrminuszwei1 type integer.
      jahrminuszwei1 = gs_kepo-gjahr - 2.
     SELECT SINGLE * FROM zsd_05_kepo_ver INTO gs_verwarnung WHERE debitor = gs_kepo-kunnr AND gjahr > jahrminuszwei1 and typ = 'V' AND loesch NE 'X'.


  endif.
        gs_verwarnung-bem = gs_kepo-bem_verwarnung.
  if sy-subrc = 0.
      "  wurde ein eintrag gefunden?
      LOOP AT SCREEN.
        "Create eingabefähig
        IF screen-name = 'BTN_VER_CREATE'.
          screen-input = 0.
        ENDIF.

        "Show eingabefähig
        IF screen-name = 'BTN_VER_SHOW'.
          screen-input = 1.
        ENDIF.

        "Entfernen nicht eingabefähig
        IF screen-name = 'BTN_VER_ENT'.
          screen-input = 1.
        ENDIF.

        MODIFY SCREEN.
      ENDLOOP.

    ELSE.


      LOOP AT SCREEN.

        "Create eingabefähig
        IF screen-name = 'BTN_VER_CREATE'.
          screen-input = 1.
        ENDIF.

        "Show eingabefähig
        IF screen-name = 'BTN_VER_SHOW'.
          screen-input = 1.
        ENDIF.

        "Entfernen nicht eingabefähig
        IF screen-name = 'BTN_VER_ENT'.
          screen-input = 0.
        ENDIF.

        MODIFY SCREEN.

      ENDLOOP.


    ENDIF.
  ENDIF.
  "Wenn verwarnung gelöscht wurde vor aufruf.
  IF loesch = 'X'.
    LOOP AT SCREEN.

      "Create eingabefähig
      IF screen-name = 'BTN_VER_CREATE'.
        screen-input = 1.
      ENDIF.

      "Show eingabefähig
      IF screen-name = 'BTN_VER_SHOW'.
        screen-input = 1.
      ENDIF.

      "Entfernen nicht eingabefähig
      IF screen-name = 'BTN_VER_ENT'.
        screen-input = 0.
      ENDIF.

      MODIFY SCREEN.

    ENDLOOP.
  ENDIF.
ENDIF.
endif.
ENDMODULE.                 " SCREEN_MODIFY_3008  OUTPUT
