*----------------------------------------------------------------------*
***INCLUDE ZSD_05_GIS_EXPORTF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  read_kundenadr
*&---------------------------------------------------------------------*
*       Liest die Kundenadresse aus
*----------------------------------------------------------------------*
*      -->IT_KONTRAKT_KONTRNEHMERNR  text
*----------------------------------------------------------------------*
 FORM read_kundenadr USING f_kontrnehmernr.

   CLEAR wa_kna1.

   SELECT SINGLE * FROM kna1 INTO wa_kna1
     WHERE kunnr = f_kontrnehmernr.

   PERFORM read_adrc USING wa_kna1-adrnr.

 ENDFORM.                    " read_kundenadr
*
*&---------------------------------------------------------------------*
*&      Form  read_lieferadr
*&---------------------------------------------------------------------*
*       Liest die Lieferadresse aus
*----------------------------------------------------------------------*
*      -->IT_KONTRAKT_KONTRNEHMERNR  text
*----------------------------------------------------------------------*
 FORM read_lieferadr USING f_kontrnehmernr.

   CLEAR wa_lfa1.

   SELECT SINGLE * FROM lfa1 INTO wa_lfa1
     WHERE lifnr = zsd_05_kontrakt-kontrnehmernr.

   PERFORM read_adrc USING wa_lfa1-adrnr.

 ENDFORM.                    " read_lieferadr
*
*&---------------------------------------------------------------------*
*&      Form  read_adrc
*&---------------------------------------------------------------------*
*       Liest Adresse aus der ADRC aus
*----------------------------------------------------------------------*
*      -->IT_KONTRAKT_ADRNR  text
*----------------------------------------------------------------------*
 FORM read_adrc USING f_adrnr.

   CLEAR wa_adrc.

   SELECT SINGLE * FROM adrc INTO wa_adrc
     WHERE addrnumber = f_adrnr.

   wa_gis_export-name1 = wa_adrc-name1.
   wa_gis_export-name2 = wa_adrc-name2.
   CONCATENATE wa_adrc-street wa_adrc-house_num1
     INTO wa_gis_export-strasse SEPARATED BY space.
   wa_gis_export-land  = wa_adrc-country.
   wa_gis_export-plz   = wa_adrc-post_code1.
   wa_gis_export-ort   = wa_adrc-city1.

 ENDFORM.                    " read_adrc
*
