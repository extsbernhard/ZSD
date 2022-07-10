*&---------------------------------------------------------------------*
*&  Include           ZSD_05_KEHRICHT_HINWEIS_DEL_C1
*&---------------------------------------------------------------------*
constants: gc_true  type sap_bool value 'X',

           begin of gc_s_display,
             list       type i value 1,
             fullscreen type i value 2,
             grid       type i value 3,
           end   of gc_s_display.


types: begin of g_type_s_test,
         amount  type i,
         repid   type syrepid,
         display type i,
         dynamic type sap_bool,
       end of g_type_s_test.


*... §5 Definition is later
class lcl_handle_events definition deferred.

data: gs_test type g_type_s_test.

data: gt_outtab type standard table of zsd_05_lulu_hd02.
data: gs_outtab LIKE LINE OF gt_outtab.

data: gt_fk02 type standard table of zsd_05_lulu_fk02.
data: gs_fk02 LIKE LINE OF gt_fk02.

data: gr_table   type ref to cl_salv_table.

data: gr_container type ref to cl_gui_custom_container.

*... §5 object for handling the events of cl_salv_table
data: gr_events type ref to lcl_handle_events.

data: g_okcode type syucomm.

*---------------------------------------------------------------------*
*       CLASS lcl_handle_events DEFINITION
*---------------------------------------------------------------------*
* §5.1 define a local class for handling events of cl_salv_table
*---------------------------------------------------------------------*
class lcl_handle_events definition.
  public section.
    methods:
      on_user_command for event added_function of cl_salv_events
        importing e_salv_function,

      on_before_salv_function for event before_salv_function of cl_salv_events
        importing e_salv_function,

      on_after_salv_function for event after_salv_function of cl_salv_events
        importing e_salv_function,

      on_double_click for event double_click of cl_salv_events_table
        importing row column,

      on_link_click for event link_click of cl_salv_events_table
        importing row column.
endclass.                    "lcl_handle_events DEFINITION

*---------------------------------------------------------------------*
*       CLASS lcl_handle_events IMPLEMENTATION
*---------------------------------------------------------------------*
* §5.2 implement the events for handling the events of cl_salv_table
*---------------------------------------------------------------------*
class lcl_handle_events implementation.
  method on_user_command.
    perform show_function_info using e_salv_function text-i08.
  endmethod.                    "on_user_command

  method on_before_salv_function.
*    perform show_function_info using e_salv_function text-i09.
  endmethod.                    "on_before_salv_function

  method on_after_salv_function.
*    perform show_function_info using e_salv_function text-i10.
  endmethod.                    "on_after_salv_function

  method on_double_click.
*    perform show_invoice using row column text-i07.
  endmethod.                    "on_double_click

  method on_link_click.
*    perform show_cell_info using row column text-i06.
  endmethod.                    "on_single_click
endclass.                    "lcl_handle_events IMPLEMENTATION
