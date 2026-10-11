-- TODO-POUSSINS etape 3 : reception aeroport liee au BL (theorique vs reel)
ALTER TABLE RECEPTIONPOUSSINAEROPORT ADD (IDBL VARCHAR2(50));
COMMENT ON COLUMN RECEPTIONPOUSSINAEROPORT.IDBL IS 'BL fournisseur d origine (FK AS_BONDELIVRAISON.ID), nullable pour saisies historiques';

-- Si receptionPoussinAeroport_lib est en SELECT * elle expose IDBL toute seule ;
-- sinon ajouter : s.IDBL dans sa definition puis recompiler.
-- Ecart affiche en fiche : qteTheorique (SUM BL filles) - qteRecus (comptage).
