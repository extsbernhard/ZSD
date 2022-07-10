class ZCL_IM_LULU_UTILS definition
  public
  final
  create public .

public section.

  constants C_TC_FV60 type TCODE value 'FV60'. "#EC NOTEXT
  class-data IT_BKPF type ZSD_T_BKPF .
  class-data IT_BSEG type ZSD_T_BSEG .
  class-data IT_BSEC type ZSD_T_BSEC .
  class-data IT_BSET type ZSD_T_BSET .
  class-data IT_BSEZ type ZSD_T_BSEZ .
protected section.
private section.

  methods POST_PRELIMANRY
    importing
      !IT_HEAD type ZSD_T_HEAD optional
      !IT_FAKT type ZSD_T_FAKT optional
      !IT_HD02 type ZSD_T_HD02 optional
      !IT_FK02 type ZSD_T_FK02 optional
      !I_FALL type BOOLEAN default 'X'
    exporting
      !E_BELNR type BELNR_D .
  methods CALL_TRANSACTION
    importing
      !I_TCODE type TCODE default 'FV60'
      !IT_BKPF type ZSD_T_BKPF optional
      !IT_BSEG type ZSD_T_BSEG optional
      !IT_BSEC type ZSD_T_BSEC optional
    exporting
      !E_BELNR type BELNR_D
      !E_MAPPE type APQ_GRPN .
ENDCLASS.



CLASS ZCL_IM_LULU_UTILS IMPLEMENTATION.


method CALL_TRANSACTION.




endmethod.


METHOD post_prelimanry.

  DATA: ls_bkpf LIKE LINE OF it_bkpf.
  DATA: ls_bseg LIKE LINE OF it_bseg.
  DATA: ls_bsec LIKE LINE OF it_bsec.

  DATA: ls_head LIKE LINE OF it_head.
  DATA: ls_fakt LIKE LINE OF it_fakt.
  DATA: ls_hd02 LIKE LINE OF it_hd02.
  DATA: ls_fk02 LIKE LINE OF it_fk02.

  IF i_fall = abap_true. "Gesuch
    LOOP AT it_head INTO ls_head.
      MOVE-CORRESPONDING ls_head TO ls_bkpf.

      APPEND ls_bkpf TO it_bkpf.
    ENDLOOP.


    LOOP AT it_fakt INTO ls_fakt.
* Füllen der BSEG und BSEC
      MOVE-CORRESPONDING ls_fakt TO ls_bseg.
      APPEND ls_bseg  TO it_bseg.

      IF sy-tabix = 1.
        MOVE-CORRESPONDING ls_fakt TO ls_bsec.
        APPEND ls_bsec TO it_bsec.
      ENDIF.
    ENDLOOP.



  ELSE. "Fall
    LOOP AT it_hd02 INTO ls_hd02.
      MOVE-CORRESPONDING ls_hd02 TO ls_bkpf.

      APPEND ls_bkpf TO it_bkpf.
    ENDLOOP.


    LOOP AT it_fk02 INTO ls_fk02.
* Füllen der BSEG und BSEC
      MOVE-CORRESPONDING ls_fk02 TO ls_bseg.
      APPEND ls_bseg  TO it_bseg.

      IF sy-tabix = 1.
        MOVE-CORRESPONDING ls_fk02 TO ls_bsec.
        APPEND ls_bsec TO it_bsec.
      ENDIF.
    ENDLOOP.

  ENDIF.





*  CALL FUNCTION 'PRELIMINARY_POSTING_FB01'
*    EXPORTING
*      i_tcode       = me->c_tc_fv60
*      i_tcode_int   = me->c_tc_fv60
*    TABLES
*      t_bkpf        = it_bkpf
*      t_bseg        = it_bseg
*      t_bsec        = it_bsec
*      t_bset        = it_bset
*      t_bsez        = it_bsez
*    EXCEPTIONS
*      error_message = 1.
*
*  IF sy-subrc = '0'.
*    CLEAR e_belnr.
*
*    GET PARAMETER ID 'BLP' FIELD e_belnr.
*
*    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
*      EXPORTING
*        wait = 'X'.
*  ENDIF.

ENDMETHOD.
ENDCLASS.
