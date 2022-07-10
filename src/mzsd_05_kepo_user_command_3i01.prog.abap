*----------------------------------------------------------------------*
***INCLUDE MZSD_05_KEPO_USER_COMMAND_3I01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_3008  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_3008 INPUT.
ok_code = sy-ucomm.

case OK_code.
  when 'VER_CREATE'.
    perform Create_verwarnung.
  when 'VER_SHOW'.
    perform show_verwarnung.
  when 'VER_ENTF'.
    perform entferne_verwarnung.
endcase.
ENDMODULE.                 " USER_COMMAND_3008  INPUT
