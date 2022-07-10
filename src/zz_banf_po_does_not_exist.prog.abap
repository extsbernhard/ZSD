*&---------------------------------------------------------------------*
*& Report  ZZ_BANF_PO_DOES_NOT_EXIST
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

REPORT ZZ_BANF_PO_DOES_NOT_EXIST .                     "v_mod_530351

* This report deletes the reference to a purchase order from a purchase
* requisition provided the purchase order cannot be found on the data
* base.

* CAUTION:
* This report cuts the connection between purchase requisition and
* purchase order. Although it is checked beforehand that the PO is
* not present on the database it should be used with great care
* and only for purchase requisitions in which the PO is referenced
* accidentally.
* Before using this report in particular make sure that the missing
* purchase order wasn't archived.

* SELECTION:
* The purchase requisition cannot be selected directly but is found via
* the corresponding sales order. As a precaution the report can only act
* on the corresponding PReqs of a single sales order or a single
* sales order item at one time.

* HOW TO USE:
* - If you want to correct a complete order
*   enter the sales order you want to be corrected
*   (leave the item number empty).
* - If you want to correct a single order item
*   enter sales order and item number you want to be corrected.

* - Run the report once without flagging checkbox 'Correct'.
* - As output you get all schedule lines of the SO/SO-item
*   and all items of the corresponding purchase requisition(s).
*  + Items with no reference to a PO are marked yellow (e.g. PO
*    was not yet created).
*  + Items where a corresponding PO could be found are marked red
*  + Items where the corresponding PO could not be found are marked
*    green. Only for these items the reference can be deleted.
*
* - If you are sure you want to clear fields referring to the PO
*   of ALL PReq items marked green check 'Correct' and start the report.
*
* - Re-run the report with 'Correct' unflagged to check the result.
*   The PReq items of which the reference could be deleted should
*   now be marked yellow because the reference will not be found
*   any longer.

* Definitions
  TYPES: BEGIN OF STR_VBEP,
           VBELN LIKE VBEP-VBELN,
           POSNR LIKE VBEP-POSNR,
           ETENR LIKE VBEP-ETENR,
           WMENG LIKE VBEP-WMENG,
           BMENG LIKE VBEP-BMENG,
           BANFN LIKE VBEP-BANFN,
           BNFPO LIKE VBEP-BNFPO,
         END OF STR_VBEP.

  TYPES: ITAB_VBEP TYPE STANDARD TABLE OF STR_VBEP
         WITH KEY VBELN POSNR ETENR.

  TYPES: BEGIN OF STR_EBAN,
           BANFN LIKE EBAN-BANFN,
           BNFPO LIKE EBAN-BNFPO,
         END OF STR_EBAN.

  TYPES: ITAB_EBAN TYPE SORTED TABLE OF STR_EBAN
         WITH UNIQUE KEY BANFN BNFPO.

  CONSTANTS: MARK VALUE 'X'.

  DATA:  LT_VBEP TYPE ITAB_VBEP,
         LT_EBAN TYPE ITAB_EBAN,
         LS_VBEP TYPE STR_VBEP,
         LS_EBAN TYPE STR_EBAN.

  DATA:  LV_BANFN LIKE EBAN-BANFN,
         LV_DONE VALUE ' '.

  TABLES: VBEP, EBAN.

* Dialog screen
  PARAMETERS: ORD_NR  LIKE VBEP-VBELN,
              ORD_POS LIKE VBEP-POSNR,
              CORRECT AS   CHECKBOX.
  INCLUDE z_abap_benutzt. "Zählt die Aufrufe der ABAP's
  IF ORD_POS IS INITIAL.
    WRITE: / TEXT-001, ORD_NR.
    WRITE: /.

*   Schedule lines from selected order
    SELECT VBELN POSNR ETENR WMENG BMENG BANFN BNFPO
           FROM VBEP
           INTO TABLE LT_VBEP
           WHERE VBELN = ORD_NR.
  ELSE.
    WRITE: / TEXT-001, ORD_NR, '/', ORD_POS.
    WRITE: /.

*   Schedule lines from selected order item
    SELECT VBELN POSNR ETENR WMENG BMENG BANFN BNFPO
           FROM VBEP
           INTO TABLE LT_VBEP
           WHERE VBELN = ORD_NR
             AND POSNR = ORD_POS.
  ENDIF.

  IF SY-SUBRC NE 0.
    WRITE: / TEXT-002.
    EXIT.
  ENDIF.

  WRITE: / TEXT-003.
  WRITE: / TEXT-004.

* Collect items of correspondig PReq(s)
  LOOP AT LT_VBEP INTO LS_VBEP.

    WRITE: / LS_VBEP-VBELN, LS_VBEP-POSNR, LS_VBEP-ETENR, LS_VBEP-WMENG,
             LS_VBEP-BMENG, LS_VBEP-BANFN, LS_VBEP-BNFPO.

    LS_EBAN-BANFN = LS_VBEP-BANFN.
    LS_EBAN-BNFPO = LS_VBEP-BNFPO.

    INSERT LS_EBAN INTO TABLE LT_EBAN.

  ENDLOOP.

  WRITE: /.
  WRITE: / TEXT-005.
  WRITE: / TEXT-006.

* Loop over PReq items
  LOOP AT LT_EBAN INTO LS_EBAN.

    SELECT SINGLE * FROM EBAN WHERE BANFN = LS_EBAN-BANFN
                                AND BNFPO = LS_EBAN-BNFPO.

    IF SY-SUBRC NE 0.
      CONTINUE.
    ENDIF.

    WRITE: / EBAN-BANFN, EBAN-BNFPO, EBAN-EBELN, EBAN-EBELP, EBAN-BSMNG,
             EBAN-BEDAT.

*   Skip entry if reference of PO is not set in PReq item
    IF EBAN-EBELN IS INITIAL OR
       EBAN-EBELP IS INITIAL.
      WRITE: AT /18 TEXT-007 COLOR COL_GROUP.
      WRITE: /.
      CONTINUE.
    ENDIF.

* Determine whether PO item exists
    SELECT BANFN INTO LV_BANFN
           FROM M_MEKKE UP TO 1 ROWS
           WHERE BANFN = EBAN-BANFN
             AND BNFPO = EBAN-BNFPO
             AND EBELN = EBAN-EBELN
             AND EBELP = EBAN-EBELP.
    ENDSELECT.

    IF SY-SUBRC = 0.
      WRITE: AT /18 TEXT-008 COLOR COL_NEGATIVE.
      WRITE: /.
      CONTINUE.
    ENDIF.

    WRITE: AT /18 TEXT-009 COLOR COL_POSITIVE.
    WRITE: /.

*   Modify database if requested
    IF CORRECT EQ MARK.
      CLEAR EBAN-EBELN.
      CLEAR EBAN-EBELP.
      CLEAR EBAN-BSMNG.
      CLEAR EBAN-BEDAT.
      EBAN-STATU = 'N'.
      UPDATE EBAN.
      LV_DONE = MARK.
    ENDIF.

  ENDLOOP.

* Complete output
  WRITE: /.
  WRITE: / TEXT-010.

  IF CORRECT EQ MARK.
    IF LV_DONE EQ MARK.
      WRITE: / TEXT-011 COLOR COL_POSITIVE.
    ELSE.
      WRITE: / TEXT-012 COLOR COL_GROUP.
    ENDIF.
  ELSE.
    WRITE: / TEXT-013 COLOR COL_GROUP.
  ENDIF.                                               "^_mod_530351
