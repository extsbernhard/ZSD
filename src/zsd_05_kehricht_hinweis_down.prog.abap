*----------------------------------------------------------------------*
* Report  ZSD_05_KEHRICHT_HINWEIS_DOWN
* Author: Exsigno AG / Raffaele De Simone
*----------------------------------------------------------------------*
* Download von Objekten mit Selektion auf Hinweistypen
*
*----------------------------------------------------------------------*
*
REPORT  zsd_05_kehricht_hinweis_down
            LINE-SIZE  255
            LINE-COUNT 65(0).
*
TYPE-POOLS slis.
TABLES: adrc,
        kna1,
        zsd_04_kehricht.               "Gebühren: Kehrichtgrundgebühr
*
DATA: v_up(4)   TYPE c VALUE 'UP  ',
      v_down(4) TYPE c VALUE 'DOWN',
      v_blank   TYPE c VALUE ' ',
      v_x       TYPE c VALUE 'X'.
DATA t_kehricht TYPE zsd_04_kehricht OCCURS 0 WITH HEADER LINE.
DATA t_output TYPE zsd_05_kehricht_hinweis_down OCCURS 0
     WITH HEADER LINE.
*
SELECT-OPTIONS: s_hinwei FOR zsd_04_kehricht-hinweis1 OBLIGATORY.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.
SELECT-OPTIONS: s_stadtt FOR zsd_04_kehricht-stadtteil,
                s_parzel FOR zsd_04_kehricht-parzelle,
                s_objekt FOR zsd_04_kehricht-objekt.
SELECTION-SCREEN END   OF BLOCK b1.

START-OF-SELECTION.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  SELECT        * FROM  zsd_04_kehricht
         INTO TABLE t_kehricht
         WHERE  stadtteil IN s_stadtt
         AND    parzelle  IN s_parzel
         AND    objekt    IN s_objekt.
*
  LOOP AT t_kehricht.
    IF t_kehricht-hinweis1 IN s_hinwei.
      PERFORM fill_output USING t_kehricht-hinweis1 t_kehricht-hintext1.
    ENDIF.
    IF t_kehricht-hinweis2 IN s_hinwei.
      PERFORM fill_output USING t_kehricht-hinweis2 t_kehricht-hintext2.
    ENDIF.
    IF t_kehricht-hinweis3 IN s_hinwei.
      PERFORM fill_output USING t_kehricht-hinweis3 t_kehricht-hintext3.
    ENDIF.
    IF t_kehricht-hinweis4 IN s_hinwei.
      PERFORM fill_output USING t_kehricht-hinweis4 t_kehricht-hintext4.
    ENDIF.
    IF t_kehricht-hinweis5 IN s_hinwei.
      PERFORM fill_output USING t_kehricht-hinweis5 t_kehricht-hintext5.
    ENDIF.
    IF t_kehricht-hinweis6 IN s_hinwei.
      PERFORM fill_output USING t_kehricht-hinweis6 t_kehricht-hintext6.
    ENDIF.
    IF t_kehricht-hinweis7 IN s_hinwei.
      PERFORM fill_output USING t_kehricht-hinweis7 t_kehricht-hintext7.
    ENDIF.
    IF t_kehricht-hinweis8 IN s_hinwei.
      PERFORM fill_output USING t_kehricht-hinweis8 t_kehricht-hintext8.
    ENDIF.
  ENDLOOP.
*
  DATA t_fieldcat TYPE slis_t_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name         = 'ZSD_05_KEHRICHT_HINWEIS_DOWN'
            i_structure_name       = 'ZSD_05_KEHRICHT_HINWEIS_DOWN'
            i_client_never_display = 'X'
            i_inclname             = 'ZSD_05_KEHRICHT_HINWEIS_DOWN'
       CHANGING
            ct_fieldcat            = t_fieldcat
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*
  DATA w_layout TYPE slis_layout_alv.
  w_layout-no_colhead = v_blank.         " no headings
  w_layout-no_hotspot = v_blank.         " headings not as hotspot
  w_layout-zebra      = v_x.             " striped pattern
  w_layout-no_vline   = v_blank.         " columns separated by space
 w_layout-cell_merge = v_blank.         " not suppress field replication
  w_layout-edit       = v_blank.         " for grid only
  w_layout-edit_mode  = v_blank.         " for grid only
 w_layout-numc_sum   = v_blank.         " totals for NUMC-Fields possib.
  w_layout-no_input   = v_x.             " only display fields
  w_layout-f2code     = v_blank.         "
 w_layout-reprep     = v_blank.         " report report interface active
  w_layout-no_keyfix  = v_blank.         " do not fix keycolumns
  w_layout-expand_all = v_blank.         " Expand all positions
  w_layout-no_author  = v_blank.         " No standard authority check
* PF-status
  w_layout-def_status = v_blank.         " default status  space or 'A'
  w_layout-item_text  = v_blank.         " Text for item button
* Display options
  w_layout-colwidth_optimize = v_x.
  w_layout-no_min_linesize   = v_blank.  " line size = width of the list
  w_layout-min_linesize      = v_blank.  " if initial min_linesize = 80
  w_layout-max_linesize      = v_blank.  " Default 250
  w_layout-window_titlebar   = v_blank.
  w_layout-no_uline_hs       = v_blank.
* Exceptions
  w_layout-lights_fieldname = v_blank.   " fieldname for exception
  w_layout-lights_tabname   = v_blank.   " fieldname for exception
  w_layout-lights_rollname  = v_blank.   " rollname f. exceptiondocu
  w_layout-lights_condense  = v_blank.   " fieldname for exception
* Sums
  w_layout-no_sumchoice        = v_blank." no choice for summing up
  w_layout-no_totalline        = v_blank." no total line
  w_layout-no_subchoice        = v_blank." no choice for subtotals
  w_layout-no_subtotals        = v_blank." no subtotals possible
 w_layout-no_unit_splitting   = v_blank." no sep. tot.lines by inh.units
 w_layout-totals_before_items = v_blank." diplay totals before the items
  w_layout-totals_only         = v_blank." show only totals
w_layout-totals_text         = v_blank." text for 1st col. in total line
 w_layout-subtotals_text      = v_blank." text for 1st col. in subtotals
* Interaction
  w_layout-box_fieldname       = v_blank." fieldname for checkbox
  w_layout-box_tabname         = v_blank." tabname for checkbox
  w_layout-box_rollname        = v_blank." rollname for checkbox
  w_layout-expand_fieldname    = v_blank." fieldname flag 'expand'
  w_layout-hotspot_fieldname   = v_blank." fieldname flag hotspot
  w_layout-confirmation_prompt = v_blank." confirm. prompt when leaving
  w_layout-key_hotspot         = v_blank." keys as hotspot " K_KEYHOT
  w_layout-flexible_key        = v_blank." key columns movable,...
  w_layout-group_buttons       = v_blank." buttons for COL1 - COL5
  w_layout-get_selinfos        = v_blank." read selection screen
 w_layout-group_change_edit   = v_x.    " Settings by user for new group
  w_layout-no_scrolling        = v_blank." no scrolling
* Detailed screen
  w_layout-detail_popup         = v_blank." show detail in popup
  w_layout-detail_initial_lines = v_blank." show also initial lines
  w_layout-detail_titlebar      = v_blank." Titlebar for detail
* Display variants
  w_layout-header_text  = v_blank.       " Text for header button
  w_layout-default_item = v_blank.       " Items as default
* colour
  w_layout-info_fieldname   = v_blank.   " infofield for listoutput
  w_layout-coltab_fieldname = v_blank.   " colors
* others
  w_layout-list_append = v_blank.        " no call screen
 w_layout-xifunckey   = v_blank.        " eXtended interaction(SAPQuery)
 w_layout-xidirect    = v_blank.        " eXtended INTeraction(SAPQuery)
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   EXPORTING
     i_interface_check                 = ' '
     i_buffer_active                   = ' '
     i_callback_program                = 'ZSD_05_KEHRICHT_HINWEIS_DOWN'
     i_callback_pf_status_set          = ' '
     i_callback_user_command           = ' '
     i_callback_top_of_page            = ' '
     i_callback_html_top_of_page       = ' '
     i_callback_html_end_of_list       = ' '
     i_structure_name                  = 'T_OUTPUT'
     i_background_id                   = ' '
*    I_GRID_TITLE                      =
*    I_GRID_SETTINGS                   =
   is_layout                           = w_layout
     it_fieldcat                       = t_fieldcat
*    IT_SORT                           =
     i_default                         = 'X'
     i_save                            = ' '
     i_screen_start_column             = 0
     i_screen_start_line               = 0
     i_screen_end_column               = 0
     i_screen_end_line                 = 0
   TABLES
      t_outtab                        = t_output
   EXCEPTIONS
     program_error                     = 1
     OTHERS                            = 2
            .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  fill_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->F_HINWEIS  Hinweistyp
*      -->F_HINTEXT  Hinweistext
*----------------------------------------------------------------------*
FORM fill_output USING    f_hinweis
                          f_hintext.

  CLEAR t_output.
  MOVE-CORRESPONDING t_kehricht TO t_output.
  MOVE: f_hinweis TO t_output-hinweis,
        f_hintext TO t_output-hintext.
  IF NOT t_output IS INITIAL.
    CLEAR kna1.
    SELECT SINGLE * FROM  kna1
           WHERE  kunnr  = t_output-kunnr.
    SELECT        * FROM  adrc
           WHERE  addrnumber  = kna1-adrnr
           AND    date_from  LE sy-datum
           AND    date_to    GE sy-datum.
      MOVE-CORRESPONDING adrc TO t_output.
    ENDSELECT.
    APPEND t_output.
  ENDIF.

ENDFORM.                    " fill_output
