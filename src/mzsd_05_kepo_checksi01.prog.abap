*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_CHECKSI01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  CHECKS  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE checks INPUT.
"IDTZI 07.01.2014
  if gs_kepo-fwdh is initial. "Falls es KEINE Wiederholung ist
    "prüfe ob Unterschrift für Verwarnung gesetzt ist
    if gs_kepo-signpers is initial. "wenn keine person gesetzt
      "gebe meldung aus
      data text type string.
      text = 'Bitte geben Sie eine Unterschriftsberechtigte Person für die Verwarnung an.' .

      message text type 'E' .

      exit.
      endif.
      endif.
ENDMODULE.                 " CHECKS  INPUT
