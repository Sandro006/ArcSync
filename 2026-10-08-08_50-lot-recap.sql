-- TODO-POUSSINS etape 7 : totalisation theorique 2 -> actuels par lot
CREATE OR REPLACE VIEW LOT_POUSSIN_RECAP AS
SELECT l.ID AS IDLOT,
       NVL((SELECT SUM(r.QTERECUS) FROM receptionPoussinAeroport r WHERE r.IDLOT = l.ID),0) AS QTE_THEORIQUE2,
       NVL((SELECT SUM(d.QTE) FROM transfertPoulet t JOIN transfertPouletDetail d ON d.IDMERE = t.ID WHERE t.IDLOT = l.ID),0) AS QTE_ARRIVEE,
       NVL((SELECT SUM(d.NBMALADES) FROM transfertPoulet t JOIN transfertPouletDetail d ON d.IDMERE = t.ID WHERE t.IDLOT = l.ID),0) AS NB_MALADES,
       NVL((SELECT SUM(r.QTERECUS) FROM receptionPoussinAeroport r WHERE r.IDLOT = l.ID),0)
       - NVL((SELECT SUM(d.QTE) FROM transfertPoulet t JOIN transfertPouletDetail d ON d.IDMERE = t.ID WHERE t.IDLOT = l.ID),0) AS ECART
FROM LOT l;

-- TRANSFERTPOULET_LIB : exposer IDRECEPTION (liste colonnes en dur)
-- (applique en base le 08/10/2026)

-- Java : TransfertPoulet.createObject -> controlerCumulReception
--        (cumul transfere depuis une reception <= son qteRecus).
-- JSP : lot-fiche.jsp, bandeau recap via LOT_POUSSIN_RECAP.
