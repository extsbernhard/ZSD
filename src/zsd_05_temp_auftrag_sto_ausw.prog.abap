*_____Reportinfos_______________________________________________________
* Dieser Report wertet die stornierten Aufträge der Temporäre
* Verrechnung gemäss Selektion aus.

*     31.07.2012 Report angelegt                       IDSWE, Stadt Bern
*_______________________________________________________________________

REPORT  zsd_05_temp_auftrag_sto_ausw.





*_____Types_____________________________________________________________

TYPE-POOLS: slis. " wird benötigt für ALV-Grid-Ausgabe -> Formatierung





*_____Tabellen__________________________________________________________

TABLES: zsd_05_tverstorn, "Temporäre Verrechnung (stornierte Aufträge)
        usr21.            "Zuordnung Benutzername Adressschlussel





*_____interne Tabellen & Workareas______________________________________

DATA: it_data LIKE STANDARD TABLE OF zsd_05_tverstorn,
      it_out  LIKE STANDARD TABLE OF zsd_05_tverstorn,
      wa_data TYPE zsd_05_tverstorn.





*_____Selektionsbild____________________________________________________

SELECTION-SCREEN: SKIP,
                  BEGIN OF BLOCK bl1 WITH FRAME TITLE text-001,
                  SKIP.


SELECT-OPTIONS:   o_obj FOR zsd_05_tverstorn-objekt,
                  o_vbeln  FOR zsd_05_tverstorn-vbeln_va,
                  o_user   FOR usr21-bname.

SELECTION-SCREEN: SKIP,
                  END OF BLOCK bl1.





*_____Auswertung________________________________________________________

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  SELECT * FROM zsd_05_tverstorn INTO CORRESPONDING
    FIELDS OF TABLE it_data
      WHERE objekt   IN o_obj
      AND   vbeln_va IN o_vbeln
      AND   rsto     IN o_user.



  PERFORM liste_ausgeben.



*_____Forms_____________________________________________________________

FORM liste_ausgeben.

  DATA: lt_fld    TYPE          slis_t_fieldcat_alv.
  DATA: ls_layout TYPE          slis_layout_alv.
  DATA: lt_sort   TYPE TABLE OF slis_sortinfo_alv.

  IF it_data IS INITIAL.
    WRITE: 'Keine Daten für die Selektion vorhanden'.
    EXIT.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
*     I_PROGRAM_NAME               =
*     I_INTERNAL_TABNAME           =
      i_structure_name             = 'ZSD_05_TVERSTORN'
*     I_CLIENT_NEVER_DISPLAY       = 'X'
*     I_INCLNAME                   =
*     I_BYPASSING_BUFFER           =
*     I_BUFFER_ACTIVE              =
    CHANGING
      ct_fieldcat                  = lt_fld
    EXCEPTIONS
      inconsistent_interface       = 1
      program_error                = 2
      OTHERS                       = 3.

*  PERFORM feldkatalog_aufbauen TABLES lt_fld.
  PERFORM sorttabelle_aufbauen TABLES lt_sort.

* Layout ----------
  ls_layout-zebra = 'X'.
  ls_layout-f2code = 'XSEL'.
  ls_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK                = ' '
*     I_BYPASSING_BUFFER               =
*     I_BUFFER_ACTIVE                  = ' '
      i_callback_program               = 'ZSD_05_TEMP_AUFTRAG_STO_AUSW'
*     I_CALLBACK_PF_STATUS_SET         = ' '
*     I_CALLBACK_USER_COMMAND          = ' '
*     I_CALLBACK_TOP_OF_PAGE           = ' '
*     I_CALLBACK_HTML_TOP_OF_PAGE      = ' '
*     I_CALLBACK_HTML_END_OF_LIST      = ' '
      i_structure_name                 = 'ZSD_05_TVERSTORN'
*     I_BACKGROUND_ID                  = ' '
*     I_GRID_TITLE                     =
*     I_GRID_SETTINGS                  =
      is_layout                        = ls_layout
      it_fieldcat                      = lt_fld
*     IT_EXCLUDING                     =
*     IT_SPECIAL_GROUPS                =
      it_sort                          = lt_sort
*     IT_FILTER                        =
*     IS_SEL_HIDE                      =
*     I_DEFAULT                        = 'X'
      i_save                           = 'X'
*     IS_VARIANT                       =
*     IT_EVENTS                        =
*     IT_EVENT_EXIT                    =
*     IS_PRINT                         =
*     IS_REPREP_ID                     =
*     I_SCREEN_START_COLUMN            = 0
*     I_SCREEN_START_LINE              = 0
*     I_SCREEN_END_COLUMN              = 0
*     I_SCREEN_END_LINE                = 0
*     IT_ALV_GRAPHICS                  =
*     IT_ADD_FIELDCAT                  =
*     IT_HYPERLINK                     =
*     I_HTML_HEIGHT_TOP                =
*     I_HTML_HEIGHT_END                =
*     IT_EXCEPT_QINFO                  =
*   IMPORTING
*     E_EXIT_CAUSED_BY_CALLER          =
*     ES_EXIT_CAUSED_BY_USER           =
    TABLES
      t_outtab                         =  it_data.

ENDFORM.                    " liste_ausgeben





*---------------------------------------------------------------------*
*       FORM sorttabelle_aufbauen                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  LT_SORT                                                       *
*---------------------------------------------------------------------*
FORM sorttabelle_aufbauen TABLES lt_sort.

  DATA:  ls_sort   TYPE          slis_sortinfo_alv.

  CLEAR ls_sort.
  ls_sort-fieldname = 'OBJEKT'.
  ls_sort-spos      = 1.
  ls_sort-up        = 'X'.
* ls_sort-subtot    = 'X'.
  APPEND ls_sort TO lt_sort.

  CLEAR ls_sort.
  ls_sort-fieldname = 'PERENDE'.
  ls_sort-spos      = 1.
  ls_sort-up        = 'X'.
* ls_sort-subtot    = 'X'.
  APPEND ls_sort TO lt_sort.

  CLEAR ls_sort.
  ls_sort-fieldname = 'VBELN_VA'.
  ls_sort-spos      = 1.
  ls_sort-up        = 'X'.
*  ls_sort-subtot    = 'X'.
  APPEND ls_sort TO lt_sort.

ENDFORM.                    " sorttabelle_aufbauen
