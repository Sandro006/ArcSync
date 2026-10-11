-- TODO-POUSSINS etape 1 : souche (race) sur ligne BC fournisseur
-- 1. Colonne de base (nullable : BC non-avicoles OK)
ALTER TABLE AS_BONDECOMMANDE_FILLE ADD (IDSOUCHE VARCHAR2(50));
COMMENT ON COLUMN AS_BONDECOMMANDE_FILLE.IDSOUCHE IS 'Souche / race poussin (FK SOUCHE.ID)';

-- 2. Vue CPL : reprendre l'origine (produitlib/unitelib/montants) + souche
-- ATTENTION : ne pas remplacer par un SELECT simplifie, la chaine
-- RECEPT -> RECEPTGRP -> MERETRAITE en depend (UNITELIB, MONTANTHT/TVA/REMISE).
CREATE OR REPLACE VIEW AS_BONDECOMMANDE_CPL AS
SELECT asbc.ID, asbc.PRODUIT, asbc.IDBC, asbc.QUANTITE, asbc.PU, asbc.MONTANT,
       asbc.TVA, asbc.UNITE,
       au.VAL AS IDUNITE, au.VAL AS UNITELIB,
       asbc.REMISE, asbc.IDDEVISE, asbc.TAUXDECHANGE,
       asing.libelle AS PRODUITLIB,
       asbc.IDSOUCHE, s.VAL AS SOUCHELIB,
       NVL(asbc.QUANTITE,0)*NVL(asbc.PU,0) AS MONTANTHT,
       NVL(asbc.QUANTITE,0)*NVL(asbc.PU,0)*NVL(asbc.TVA,0)/100 AS MONTANTTVA,
       NVL(asbc.QUANTITE,0)*NVL(asbc.PU,0)*NVL(asbc.REMISE,0)/100 AS REMISEMONTANT,
       NVL(asbc.QUANTITE,0)*NVL(asbc.PU,0)*(1+NVL(asbc.TVA,0)/100) AS MONTANTTTC
FROM AS_BONDECOMMANDE_FILLE asbc
LEFT JOIN AS_INGREDIENTS asing ON asbc.PRODUIT = asing.ID
LEFT JOIN as_unite au ON au.ID = asbc.UNITE
LEFT JOIN SOUCHE s ON s.ID = asbc.IDSOUCHE;

-- 3. Vue FILLE_CPL (utilisee par les formulaires de saisie) : + souche
CREATE OR REPLACE VIEW AS_BONDECOMMANDE_FILLE_CPL AS
SELECT asbc.ID, asbc.PRODUIT, asbc.IDBC, asbc.QUANTITE, asbc.PU, asbc.MONTANT,
       asbc.TVA, asbc.UNITE, au.VAL AS IDUNITE,
       asbc.REMISE, asbc.IDDEVISE, asbc.TAUXDECHANGE,
       asing.libelle AS PRODUITLIB,
       asbc.IDSOUCHE, s.VAL AS SOUCHELIB
FROM AS_BONDECOMMANDE_FILLE asbc
LEFT JOIN AS_INGREDIENTS asing ON asbc.PRODUIT = asing.ID
LEFT JOIN as_unite au ON au.ID = asbc.UNITE
LEFT JOIN SOUCHE s ON s.ID = asbc.IDSOUCHE;

-- 4. Recompiler la chaine (ordre : enfants d'abord)
ALTER VIEW AS_BONDECOMMANDE_CPL_RECEPT COMPILE;
ALTER VIEW AS_BONDECOMMANDE_CPL_RECEPTGRP COMPILE;
ALTER VIEW AS_BONDECOMMANDEFILLE_CPL COMPILE;
ALTER VIEW AS_BONDECOMMANDE_MERECPL COMPILE;
ALTER VIEW AS_BONDECOMMANDE_MERETRAITE COMPILE;
-- Verif : SELECT object_name, status FROM user_objects WHERE object_name LIKE 'AS_BONDECOMMANDE%'; -- tout VALID
