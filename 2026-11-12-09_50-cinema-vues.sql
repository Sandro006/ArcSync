-- =====================================================================
-- Module Cinema - vues d'affichage et vue technique de disponibilite
--
-- Chaque vue *_LIB expose toutes les colonnes de la table de base
-- (base.*) plus les colonnes libellees attendues par les classes *Lib.
-- Idempotent : CREATE OR REPLACE VIEW.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Vue technique : places occupees
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_PLACE_OCCUPEE AS
SELECT r.IDPROJECTION, rd.IDPLACE, 'RESERVATION' AS TYPE_OCCUPATION,
       r.ID AS IDORIGINE, r.STATUT
  FROM CINEMA_RESERVATION r
  JOIN CINEMA_RESERVATIONDETAIL rd ON rd.IDMERE = r.ID
 WHERE r.ETAT IN (1, 11)
   AND r.STATUT IN (1, 2)
   AND rd.ETAT IN (1, 11)
UNION ALL
SELECT ab.IDPROJECTION, b.IDPLACE, 'BILLET',
       ab.ID, b.STATUT
  FROM CINEMA_ACHATBILLET ab
  JOIN CINEMA_BILLET b ON b.IDMERE = ab.ID
 WHERE ab.ETAT = 11
   AND b.ETAT = 11
   AND b.STATUT IN (1, 2);

-- ---------------------------------------------------------------------
-- 2. Categories de place
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_CATEGORIEPLACE_LIB AS
SELECT b.*,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB
  FROM CINEMA_CATEGORIEPLACE b;

-- ---------------------------------------------------------------------
-- 3. Films
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_FILM_LIB AS
SELECT b.*,
       g.VAL AS IDGENRELIB,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB
  FROM CINEMA_FILM b
  LEFT JOIN CINEMA_GENRE g ON g.ID = b.IDGENRE;

-- ---------------------------------------------------------------------
-- 4. Salles
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_SALLE_LIB AS
SELECT b.*,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB,
       (SELECT COUNT(*) FROM CINEMA_PLACE p
         WHERE p.IDMERE = b.ID AND p.ETAT = 1) AS NBPLACESLIB
  FROM CINEMA_SALLE b;

-- ---------------------------------------------------------------------
-- 5. Places
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_PLACE_LIB AS
SELECT b.*,
       s.NOM AS SALLELIB,
       c.VAL AS IDCATEGORIEPLACELIB,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB
  FROM CINEMA_PLACE b
  LEFT JOIN CINEMA_SALLE s ON s.ID = b.IDMERE
  LEFT JOIN CINEMA_CATEGORIEPLACE c ON c.ID = b.IDCATEGORIEPLACE;

-- ---------------------------------------------------------------------
-- 6. Projections
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_PROJECTION_LIB AS
SELECT b.*,
       f.TITRE AS IDFILMLIB,
       g.VAL AS IDGENRELIB,
       s.NOM AS IDSALLELIB,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB,
       CASE b.STATUT
           WHEN 0 THEN 'Annulee'
           WHEN 1 THEN 'Preparee'
           WHEN 2 THEN 'Ouverte'
           WHEN 3 THEN 'Cloturee'
           ELSE 'Statut ' || b.STATUT
       END AS STATUTLIB,
       (SELECT COUNT(*) FROM CINEMA_BILLET bl
          JOIN CINEMA_ACHATBILLET ab ON ab.ID = bl.IDMERE
         WHERE ab.IDPROJECTION = b.ID AND ab.ETAT = 11 AND bl.ETAT = 11
           AND bl.STATUT IN (1, 2)) AS NBPLACESVENDUES,
       (SELECT COUNT(*) FROM CINEMA_RESERVATIONDETAIL rd
          JOIN CINEMA_RESERVATION r ON r.ID = rd.IDMERE
         WHERE r.IDPROJECTION = b.ID AND r.ETAT IN (1, 11)
           AND r.STATUT IN (1, 2) AND rd.ETAT IN (1, 11)) AS NBPLACESRESERVEES,
       CASE
           WHEN b.NBPLACES
                - (SELECT COUNT(*) FROM CINEMA_BILLET bl
                     JOIN CINEMA_ACHATBILLET ab ON ab.ID = bl.IDMERE
                    WHERE ab.IDPROJECTION = b.ID AND ab.ETAT = 11 AND bl.ETAT = 11
                      AND bl.STATUT IN (1, 2))
                - (SELECT COUNT(*) FROM CINEMA_RESERVATIONDETAIL rd
                     JOIN CINEMA_RESERVATION r ON r.ID = rd.IDMERE
                    WHERE r.IDPROJECTION = b.ID AND r.ETAT IN (1, 11)
                      AND r.STATUT IN (1, 2) AND rd.ETAT IN (1, 11)) < 0
           THEN 0
           ELSE b.NBPLACES
                - (SELECT COUNT(*) FROM CINEMA_BILLET bl
                     JOIN CINEMA_ACHATBILLET ab ON ab.ID = bl.IDMERE
                    WHERE ab.IDPROJECTION = b.ID AND ab.ETAT = 11 AND bl.ETAT = 11
                      AND bl.STATUT IN (1, 2))
                - (SELECT COUNT(*) FROM CINEMA_RESERVATIONDETAIL rd
                     JOIN CINEMA_RESERVATION r ON r.ID = rd.IDMERE
                    WHERE r.IDPROJECTION = b.ID AND r.ETAT IN (1, 11)
                      AND r.STATUT IN (1, 2) AND rd.ETAT IN (1, 11))
       END AS NBPLACESDISPONIBLES,
       NVL((SELECT SUM(bl.PRIX) FROM CINEMA_BILLET bl
              JOIN CINEMA_ACHATBILLET ab ON ab.ID = bl.IDMERE
             WHERE ab.IDPROJECTION = b.ID AND ab.ETAT = 11 AND bl.ETAT = 11
               AND bl.STATUT IN (1, 2)), 0) AS RECETTE
  FROM CINEMA_PROJECTION b
  LEFT JOIN CINEMA_FILM f ON f.ID = b.IDFILM
  LEFT JOIN CINEMA_GENRE g ON g.ID = f.IDGENRE
  LEFT JOIN CINEMA_SALLE s ON s.ID = b.IDSALLE;

-- ---------------------------------------------------------------------
-- 7. Tarifs de projection
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_PROJECTIONTARIF_LIB AS
SELECT b.*,
       c.VAL AS IDCATEGORIEPLACELIB,
       CASE
           WHEN b.RANG = '*' OR b.RANG IS NULL THEN 'Tous les rangs'
           ELSE 'Rang ' || b.RANG
       END AS RANGLIB,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB,
       CASE
           WHEN b.QUOTA = 0 THEN 0
           WHEN b.QUOTA - (SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE o
                             JOIN CINEMA_PLACE p ON p.ID = o.IDPLACE
                            WHERE o.IDPROJECTION = b.IDMERE
                              AND p.IDCATEGORIEPLACE = b.IDCATEGORIEPLACE
                              AND (b.RANG = '*' OR b.RANG IS NULL OR p.RANG = b.RANG)) < 0
           THEN 0
           ELSE b.QUOTA - (SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE o
                             JOIN CINEMA_PLACE p ON p.ID = o.IDPLACE
                            WHERE o.IDPROJECTION = b.IDMERE
                              AND p.IDCATEGORIEPLACE = b.IDCATEGORIEPLACE
                              AND (b.RANG = '*' OR b.RANG IS NULL OR p.RANG = b.RANG))
       END AS QUOTARESTANT
  FROM CINEMA_PROJECTIONTARIF b
  LEFT JOIN CINEMA_CATEGORIEPLACE c ON c.ID = b.IDCATEGORIEPLACE;

-- ---------------------------------------------------------------------
-- 8. Reservations
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_RESERVATION_LIB AS
SELECT b.*,
       cl.NOM AS IDCLIENTLIB,
       pr.ID AS IDPROJECTIONLIB,
       f.TITRE AS IDFILMLIB,
       s.NOM AS IDSALLELIB,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB,
       CASE b.STATUT
           WHEN 0 THEN 'Annulee'
           WHEN 1 THEN 'En attente'
           WHEN 2 THEN 'Confirmee'
           WHEN 3 THEN 'Convertie'
           WHEN 4 THEN 'Expiree'
           ELSE 'Statut ' || b.STATUT
       END AS STATUTLIB,
       (SELECT COUNT(*) FROM CINEMA_RESERVATIONDETAIL rd
         WHERE rd.IDMERE = b.ID AND rd.ETAT IN (1, 11)) AS NBPLACESLIB,
       NVL((SELECT SUM(rd.PRIX) FROM CINEMA_RESERVATIONDETAIL rd
             WHERE rd.IDMERE = b.ID AND rd.ETAT IN (1, 11)), 0) AS MONTANTTOTALLIB,
       NVL((SELECT SUM(rd.PRIX) FROM CINEMA_RESERVATIONDETAIL rd
             WHERE rd.IDMERE = b.ID AND rd.ETAT IN (1, 11)), 0)
           - NVL(b.MONTANTACOMPTE, 0) AS RESTEAPAYERLIB
  FROM CINEMA_RESERVATION b
  LEFT JOIN CLIENT cl ON cl.ID = b.IDCLIENT
  LEFT JOIN CINEMA_PROJECTION pr ON pr.ID = b.IDPROJECTION
  LEFT JOIN CINEMA_FILM f ON f.ID = pr.IDFILM
  LEFT JOIN CINEMA_SALLE s ON s.ID = pr.IDSALLE;

-- ---------------------------------------------------------------------
-- 9. Detail des reservations
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_RESERVATIONDETAIL_LIB AS
SELECT b.*,
       CASE
           WHEN p.RANG IS NULL OR p.RANG = '' THEN 'Place ' || p.NUMERO
           ELSE 'Rang ' || p.RANG || ' - Place ' || p.NUMERO
       END AS IDPLACELIB,
       c.VAL AS IDCATEGORIEPLACELIB,
       bl.NUMERO AS IDBILLETLIB,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB
  FROM CINEMA_RESERVATIONDETAIL b
  LEFT JOIN CINEMA_PLACE p ON p.ID = b.IDPLACE
  LEFT JOIN CINEMA_CATEGORIEPLACE c ON c.ID = b.IDCATEGORIEPLACE
  LEFT JOIN CINEMA_BILLET bl ON bl.ID = b.IDBILLET;

-- ---------------------------------------------------------------------
-- 10. Achats de billets
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_ACHATBILLET_LIB AS
SELECT b.*,
       cl.NOM AS IDCLIENTLIB,
       pr.ID AS IDPROJECTIONLIB,
       f.TITRE AS IDFILMLIB,
       s.NOM AS IDSALLELIB,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB,
       (SELECT COUNT(*) FROM CINEMA_BILLET bl
         WHERE bl.IDMERE = b.ID AND bl.ETAT IN (1, 11)) AS NBBILLETSLIB,
       mp.VAL AS MODEPAIEMENTLIB
  FROM CINEMA_ACHATBILLET b
  LEFT JOIN CLIENT cl ON cl.ID = b.IDCLIENT
  LEFT JOIN MODEPAIEMENT mp ON mp.ID = b.MODEPAIEMENT
  LEFT JOIN CINEMA_PROJECTION pr ON pr.ID = b.IDPROJECTION
  LEFT JOIN CINEMA_FILM f ON f.ID = pr.IDFILM
  LEFT JOIN CINEMA_SALLE s ON s.ID = pr.IDSALLE;

-- ---------------------------------------------------------------------
-- 11. Billets
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_BILLET_LIB AS
SELECT b.*,
       CASE
           WHEN p.RANG IS NULL OR p.RANG = '' THEN 'Place ' || p.NUMERO
           ELSE 'Rang ' || p.RANG || ' - Place ' || p.NUMERO
       END AS IDPLACELIB,
       c.VAL AS IDCATEGORIEPLACELIB,
       b.IDMERE AS IDACHATBILLETLIB,
       ab.IDPROJECTION AS IDPROJECTIONLIB,
       f.TITRE AS IDFILMLIB,
       CASE b.STATUT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Vendu'
           WHEN 2 THEN 'Utilise'
           ELSE 'Statut ' || b.STATUT
       END AS STATUTLIB,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB
  FROM CINEMA_BILLET b
  LEFT JOIN CINEMA_PLACE p ON p.ID = b.IDPLACE
  LEFT JOIN CINEMA_CATEGORIEPLACE c ON c.ID = b.IDCATEGORIEPLACE
  LEFT JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE
  LEFT JOIN CINEMA_PROJECTION pr ON pr.ID = ab.IDPROJECTION
  LEFT JOIN CINEMA_FILM f ON f.ID = pr.IDFILM;

COMMIT;
