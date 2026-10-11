-- TODO-POUSSINS etape 4 : champ sante 1-10 (10=gueri) sur detail reception
ALTER TABLE RECEPTIONPOUSSINAEROPORTDETAIL ADD (SANTE NUMBER(2));
COMMENT ON COLUMN RECEPTIONPOUSSINAEROPORTDETAIL.SANTE IS 'Etat sanitaire 1 (malade) -> 10 (gueri), 0 si non renseigne';

-- Vue detail : exposer SANTE (liste colonnes en dur)
-- CREATE OR REPLACE VIEW RECEPTIONPOUSSINAEDETAIL_LIB AS
-- SELECT rd.ID, rd.IDMERE, rd.IDQUALITEPOUSSIN, rd.IDSEXE, rd.QTE, rd.SANTE,
--        qp.val AS idQualitePoussinLib, s.val AS idSexeLib, mere.idlot AS idlot
-- FROM receptionPoussinAeroportDetail rd ...
-- (applique en base le 08/10/2026, avec IDBL ajoute a RECEPTIONPOUSSINAEROPORT_LIB)

-- Java : ReceptionPoussinAeroportDetail.sante + validation 1-10 (0 tolere).
-- JSP : receptionaeroport-saisie (colonne sante), inc/receptionaeroport-details (colonne sante).
