*&---------------------------------------------------------------------*
*& Include ZSD_05_LULU_REQU_MIGTOP       Report ZSD_05_LULU_REQU_MIG
*&
*&---------------------------------------------------------------------*

REPORT zsd_05_lulu_requ_mig.

TYPE-POOLS: abap.

data: gt_lulu_mig_hlp TYPE TABLE OF ZSD_05_LULU_HELP,
      gs_lulu_mig_hlp TYPE   ZSD_05_LULU_HELP.


DATA: gt_lulu_head TYPE TABLE OF zsd_05_lulu_hd02,
      gs_lulu_head TYPE zsd_05_lulu_hd02,
      gt_lulu_fakt TYPE TABLE OF zsd_05_lulu_fk02,
      gs_lulu_fakt TYPE zsd_05_lulu_fk02,

      gs_lulu_head_form TYPE zsd_05_lulu_head,

      gs_vbrk TYPE vbrk,
      gv_fall TYPE string.


DATA: BEGIN OF gs_kehr_auft.
DATA:   fall TYPE string.
        INCLUDE STRUCTURE zsd_05_kehr_auft.
DATA: END OF gs_kehr_auft,
      gs_kehr_auft_store LIKE gs_kehr_auft,
      gt_kehr_auft LIKE TABLE OF gs_kehr_auft.
