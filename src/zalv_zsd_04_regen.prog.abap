*&---------------------------------------------------------------------*
*& Report ZALV_ZSD_04_REGEN
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zalv_zsd_04_regen.


DATA lt_zsd_04_regen TYPE TABLE OF zsd_04_regen.

SELECT * FROM zsd_04_regen INTO TABLE lt_zsd_04_regen
  WHERE verr_code = 'X'.


*-----------------------------------------------------------------------
* Beginn Datendeklarationen fuer den ALV
*-----------------------------------------------------------------------
* Kopieren Sie diesen Block zu den Datendeklarationen des ABAP-Programms
*-----------------------------------------------------------------------
DATA go_alv TYPE REF TO cl_salv_table.
DATA go_functions TYPE REF TO cl_salv_functions_list.
DATA go_columns TYPE REF TO cl_salv_columns_table.
DATA go_display TYPE REF TO cl_salv_display_settings.
*-----------------------------------------------------------------------
* Ende Datendeklarationen fuer den ALV
*-----------------------------------------------------------------------

*-----------------------------------------------------------------------
* Beginn ALV-Ausgabe
*-----------------------------------------------------------------------
* Kopieren Sie diesen Block an das Endes des Verarbeitungsblocks
* des ABAP-Programms
*-----------------------------------------------------------------------
* Instanz der Klasse cl_salv_table erzeugen
cl_salv_table=>factory(
  IMPORTING r_salv_table = go_alv
  CHANGING t_table = lt_zsd_04_regen ).

* Funktionstasten (Sortieren, Filtern, Excel-Export etc.)
go_functions = go_alv->get_functions( ).
go_functions->set_all( abap_true ).

* optimale Spaltenbreite
go_columns = go_alv->get_columns( ).
go_columns->set_optimize( abap_true ).

* Titel und/oder Streifenmuster
go_display = go_alv->get_display_settings( ).
go_display->set_list_header( value = 'Regenabwasser Export' ).
go_display->set_striped_pattern( abap_true ).

* Liste anzeigen
go_alv->display( ).
