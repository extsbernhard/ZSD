*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_SCREEN_MODIFY_O02.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  SCREEN_MODIFY_3009  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE screen_modify_3009 OUTPUT.
  "Bemerkung
  gs_rege-bem = gs_kepo-bem_rege.
 if mode = 'ANZE'.
      if loesch = ''.
  select single * from zsd_05_kepo_ver into gs_rege where gjahr = gs_kepo-gjahr and fallnr = gs_kepo-FALLNR and typ = 'R' and gjahr = gs_kepo-gjahr and loesch ne 'X'.
endif.

      LOOP AT SCREEN.

    "Create eingabefähig
    if screen-name = 'BTN_VER_CREATE'.
      screen-input = 0.
    endif.

    "Show eingabefähig
    if screen-name = 'BTN_VER_SHOW'.
      screen-input = 0.
    endif.

    "Entfernen nicht eingabefähig
    if screen-name = 'BTN_VER_ENT'.
      screen-input = 0.
    endif.

    MODIFY SCREEN.

    ENDLOOP.

    else.
  if loesch = ''.
  select single * from zsd_05_kepo_ver into gs_rege where gjahr = gs_kepo-gjahr and fallnr = gs_kepo-FALLNR and typ = 'R' and gjahr = gs_kepo-gjahr and loesch ne 'X'.


if sy-subrc = 0.

"  wurde ein eintrag gefunden?
    LOOP AT SCREEN.
    "Create eingabefähig
    if screen-name = 'BTN_VER_CREATE'.
      screen-input = 0.
    endif.

    "Show eingabefähig
    if screen-name = 'BTN_VER_SHOW'.
      screen-input = 1.
    endif.

    "Entfernen nicht eingabefähig
    if screen-name = 'BTN_VER_ENT'.
      screen-input = 1.
    endif.

    MODIFY SCREEN.
    ENDLOOP.

  else.

  LOOP AT SCREEN.

    "Create eingabefähig
    if screen-name = 'BTN_VER_CREATE'.
      screen-input = 1.
    endif.

    "Show eingabefähig
    if screen-name = 'BTN_VER_SHOW'.
      screen-input = 1.
    endif.

    "Entfernen nicht eingabefähig
    if screen-name = 'BTN_VER_ENT'.
      screen-input = 0.
    endif.

    MODIFY SCREEN.

    ENDLOOP.


     endif.
endif.
     "Wenn verwarnung gelöscht wurde vor aufruf.
     if loesch = 'X'.
  LOOP AT SCREEN.

    "Create eingabefähig
    if screen-name = 'BTN_VER_CREATE'.
      screen-input = 1.
    endif.

    "Show eingabefähig
    if screen-name = 'BTN_VER_SHOW'.
      screen-input = 1.
    endif.

    "Entfernen nicht eingabefähig
    if screen-name = 'BTN_VER_ENT'.
      screen-input = 0.
    endif.

    MODIFY SCREEN.

    ENDLOOP.
endif.
endif.
ENDMODULE.                 " SCREEN_MODIFY_3009  OUTPUT
