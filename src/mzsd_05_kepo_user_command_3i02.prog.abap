*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_USER_COMMAND_3I02.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_3009  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_3009 INPUT.
ok_code = sy-ucomm.

case OK_code.
  when 'V_CREATE'.
    perform Create_rechtgeh.
  when 'V_SHOW'.
    perform show_rechtgeh.
  when 'V_ENTF'.
    perform entferne_rechtgeh.
endcase.

ENDMODULE.                 " USER_COMMAND_3009  INPUT
