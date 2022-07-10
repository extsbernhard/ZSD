*&---------------------------------------------------------------------*
*&  Include           ZSD_05_KEHRICHT_HINWEIS_DEL_F1
*&---------------------------------------------------------------------*

*======================================================================*
*                   Unterprogramm-Bibliothek
*======================================================================*
FORM u0001_auth_check.
*
*
ENDFORM. "u0001_auth_check.
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
FORM u0100_fill_adress CHANGING lw_printline TYPE zsd_05_lulu_printline.
*   ------------------------- Eigentümer-Adresse ---------------------
*   prüfen und ggf. bestücken Eigentümer-Adress-Nummer
  IF lw_printline-eigen_adrnr IS INITIAL.
    IF lw_printline-eigen_kunnr IS INITIAL.
*    dann lassen wir es auch :-)
    ELSE.
*    Eigentümer-Nummer vorhanden, sollt ja eigentlich auch so sein...
      SELECT SINGLE adrnr FROM kna1 INTO lw_printline-eigen_adrnr
             WHERE kunnr EQ lw_printline-eigen_kunnr.
      IF sy-subrc NE 0.
        CLEAR lw_printline-eigen_adrnr.
      ENDIF.
    ENDIF.
  ENDIF.
*   ------------------------- Vertreter-Adresse ----------------------
*   prüfen und ggf. bestücken Vertreter-Adress-Nummer
  IF lw_printline-vertr_adrnr IS INITIAL.
    IF lw_printline-vertr_kunnr IS INITIAL.
*    dann lassen wir es auch :-)
    ELSE.
*    Vertreter-Nummer vorhanden, dann weiter ...
      SELECT SINGLE adrnr FROM kna1 INTO lw_printline-vertr_adrnr
             WHERE kunnr EQ lw_printline-vertr_kunnr.
      IF sy-subrc NE 0.
        CLEAR lw_printline-vertr_adrnr.
      ENDIF.
    ENDIF.
  ENDIF.
*   ------------------------- abw. Rechnungsempfänger-Adresse -------
*   prüfen und ggf. bestücken abw. Rechnungsempfänger-Adress-Nummer
  IF lw_printline-rg_adrnr IS INITIAL.
    IF lw_printline-rg_kunnr IS INITIAL.
*    dann lassen wir es auch :-)
    ELSE.
*    abw.REmpf-Nummer vorhanden, dann weiter ...
      SELECT SINGLE adrnr FROM kna1 INTO lw_printline-rg_adrnr
             WHERE kunnr EQ lw_printline-rg_kunnr.
      IF sy-subrc NE 0.
        CLEAR lw_printline-rg_adrnr.
      ENDIF.
    ENDIF.
  ENDIF.
*
ENDFORM." u0100_fill_printline using w_head.
*----------------------------------------------------------------------*
FORM u0110_fullfill_printline
           CHANGING lw_printline TYPE zsd_05_lulu_printline.
*
  IF lw_printline-fkimg_new EQ 1.
*   Pauschalbetrag wurde fakturiert ...
    BREAK-POINT.
  ENDIF.
*
ENDFORM." u0110_fullfill_printline changing w_printline.
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
            t_table      = t_kehr.


    CATCH cx_salv_msg.

  ENDTRY.
*... §3 Functions
*... §3.1 activate ALV generic Functions
*... §3.2 include own functions by setting own status
*  gr_table->set_screen_status(
*    pfstatus      =  'ZSALV_STANDARD'
*    report        =  gs_test-repid
*    set_functions = gr_table->c_functions_all ).

*... set the columns technical
  DATA: lr_columns TYPE REF TO cl_salv_columns,
        lr_column  TYPE REF TO cl_salv_column_table.

  lr_columns = gr_table->get_columns( ).
  lr_columns->set_optimize( gc_true ).

  PERFORM set_columns_technical USING lr_columns.

*... §4 set hotspot column
*  TRY.
*      lr_column ?= lr_columns->get_column( 'OBJ_KEY' ).
*      lr_column->set_cell_type( if_salv_c_cell_type=>hotspot ).
*    CATCH cx_salv_not_found.                            "#EC NO_HANDLER
*  ENDTRY.

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
