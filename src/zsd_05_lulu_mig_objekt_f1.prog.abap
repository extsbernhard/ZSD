*&---------------------------------------------------------------------*
*&  Include           ZSD_05_LULU_RUECK_F1
*&---------------------------------------------------------------------*
*======================================================================*
*                   Unterprogramm-Bibliothek
*======================================================================*

*&---------------------------------------------------------------------*
*&      Form  DATEN_ANZEIGEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM daten_anzeigen .
*  DATA:go_alv TYPE REF TO cl_salv_table,
*       go_columns TYPE REF TO cl_salv_columns_table,
*       go_column TYPE REF TO cl_salv_column_table.
  TRY .

      CALL METHOD cl_salv_table=>factory
        IMPORTING
          r_salv_table = gr_table
        CHANGING
          t_table      = t_kehricht.

    CATCH cx_salv_msg.

  ENDTRY.
*... §3 Functions
*... §3.1 activate ALV generic Functions
*... §3.2 include own functions by setting own status
  gr_table->set_screen_status(
    pfstatus      =  'ZSALV_STANDARD'
    report        =  gs_test-repid
    set_functions = gr_table->c_functions_all ).

*... set the columns technical
  DATA: lr_columns TYPE REF TO cl_salv_columns,
        lr_column  TYPE REF TO cl_salv_column_table.

  lr_columns = gr_table->get_columns( ).
  lr_columns->set_optimize( gc_true ).

  PERFORM set_columns_technical USING lr_columns.

*... §4 set hotspot column
  TRY.
      lr_column ?= lr_columns->get_column( 'OBJ_KEY' ).
      lr_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

*... §6 register to the events of cl_salv_table
  DATA: lr_events TYPE REF TO cl_salv_events_table.

  lr_events = gr_table->get_event( ).

  CREATE OBJECT gr_events.

*... §6.1 register to the event USER_COMMAND
  SET HANDLER gr_events->on_user_command FOR lr_events.
*... §6.2 register to the event BEFORE_SALV_FUNCTION
  SET HANDLER gr_events->on_before_salv_function FOR lr_events.
*... §6.3 register to the event AFTER_SALV_FUNCTION
  SET HANDLER gr_events->on_after_salv_function FOR lr_events.
*... §6.4 register to the event DOUBLE_CLICK
  SET HANDLER gr_events->on_double_click FOR lr_events.
*... §6.5 register to the event LINK_CLICK
  SET HANDLER gr_events->on_link_click FOR lr_events.

*... set list title
  DATA: lr_display_settings TYPE REF TO cl_salv_display_settings,
        l_title TYPE lvc_title.

  l_title = text-t02.
  lr_display_settings = gr_table->get_display_settings( ).
  lr_display_settings->set_list_header( l_title ).

*... §7 display the table
  gr_table->display( ).




ENDFORM.                    " DATEN_ANZEIGEN

*&---------------------------------------------------------------------*
*&      Form  SET_COLUMNS_TECHNICAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LR_COLUMNS  text
*----------------------------------------------------------------------*
FORM set_columns_technical   USING ir_columns TYPE REF TO cl_salv_columns.

  DATA: lr_column TYPE REF TO cl_salv_column.

  TRY.
      lr_column = ir_columns->get_column( 'MANDT' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'FLOAT_FI' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'STRING_F' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'XSTRING' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'INT_FIEL' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'HEX_FIEL' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'DROPDOWN' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.

  TRY.
      lr_column = ir_columns->get_column( 'TAB_INDEX' ).
      lr_column->set_technical( if_salv_c_bool_sap=>true ).
    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
  ENDTRY.
ENDFORM.                    " SET_COLUMNS_TECHNICAL
*&---------------------------------------------------------------------*
*&      Form  SHOW_FUNCTION_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_SALV_FUNCTION  text
*      -->P_TEXT_I08  text
*----------------------------------------------------------------------*
FORM show_function_info  USING      i_function TYPE salv_de_function
                              i_text     TYPE string.

*  data: l_string type string.
*
*  concatenate i_text i_function into l_string separated by space.
*
*  message i000(0k) with l_string.


ENDFORM.                    " SHOW_FUNCTION_INFO
*&---------------------------------------------------------------------*
*&      Form  KORR_BANK_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_T_HEAD  text
*----------------------------------------------------------------------*
FORM korr_objektverwaltung  TABLES p_t_kehricht STRUCTURE zsd_04_kehricht .

  FIELD-SYMBOLS: <fs_kehricht> TYPE zsd_04_kehricht.


  LOOP AT p_t_kehricht ASSIGNING <fs_kehricht>.
    IF   <fs_kehricht>-eigen_kunnr IS INITIAL.
      <fs_kehricht>-eigen_kunnr = <fs_kehricht>-kunnr.
    ENDIF.

*    <fs_kehricht>-flaeche_fakt3 = <fs_kehricht>-flaeche_fakt3 + <fs_kehricht>-flaeche_fakt4 + <fs_kehricht>-flaeche_fakt5.
    <fs_kehricht>-vflaeche_fakt3 = <fs_kehricht>-vflaeche_fakt3 + <fs_kehricht>-vflaeche_fakt4 +  <fs_kehricht>-vflaeche_fakt5.
    clear: <fs_kehricht>-vflaeche_fakt4, <fs_kehricht>-vflaeche_fakt5.
*    READ TABLE t_hinweis INTO w_hinweis WITH KEY mandt = <fs_kehricht>-mandt
*    stadtteil = <fs_kehricht>-stadtteil
*    parzelle = <fs_kehricht>-parzelle
*    objekt = <fs_kehricht>-objekt.
*   Lesen Hinweis 1 - 8 und löschen des Eintrags

  ENDLOOP.

ENDFORM.                    " KORR_BANK_DATA

*&---------------------------------------------------------------------*
*&      Form  INITIALIZE_TABLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initialize_tables .
  REFRESH: t_kehricht, t_hinweis.
ENDFORM.                    " INITIALIZE_TABLES



*----------------------------------------------------------------------*
