-- TODO-POUSSINS etape 2 : souche propagee BC -> BL (livraisons avion en N fois)
-- 1. Colonne de base BL fille
ALTER TABLE AS_BONDELIVRAISON_FILLE ADD (IDSOUCHE VARCHAR2(50));
COMMENT ON COLUMN AS_BONDELIVRAISON_FILLE.IDSOUCHE IS 'Souche / race poussin recopiee du BC fille (FK SOUCHE.ID)';

-- 2. Vue MF : exposer IDSOUCHE (liste colonnes en dur)
-- (deja applique en base le 08/10/2026)
-- CREATE OR REPLACE VIEW AS_BONDECOMMANDE_MF AS
-- SELECT ..., bcf.IDSOUCHE FROM AS_BONDECOMMANDE_FILLE bcf LEFT JOIN AS_BONDECOMMANDE AB ON AB.ID=bcf.IDBC;

-- 3. Vue LIVRE (reste a livrer) : exposer IDSOUCHE pour le pre-remplissage N fois
-- CREATE OR REPLACE VIEW AS_BONDECOMMANDE_LIVRE AS
-- SELECT ..., bc.IDSOUCHE FROM AS_BONDECOMMANDE_MF bc ...;

-- Java : As_BonDeLivraison_Fille.idSouche+soucheLib,
--        As_BonDeCommande_Fille.createBLFille -> setIdSouche,
--        As_BonDeCommande.genererLivraisonPourPrerempli -> setIdSouche.
-- Le formulaire bondelivraison-saisie.jsp?id=BC affiche le reste (qte_reste) :
-- chaque BL consomme une partie, repetable jusqu'a reste=0.
