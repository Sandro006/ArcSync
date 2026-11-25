-- =====================================================================
-- Module Cinema - donnees de reference
--   - genres cinematographiques
--   - categories de place
--   - salle de demonstration et ses places
--   - article generique CINEMA_BILLET pour les lignes VENTE_DETAILS
--
-- Pas de client comptoir ni de client de demonstration.
-- Les identifiants "DEMO" evitent toute collision avec les sequences
-- metier (prefixes CGR/CCP/CSA/CPL).
-- Idempotent : chaque ligne est inseree si absente.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Genres
-- ---------------------------------------------------------------------
INSERT INTO CINEMA_GENRE (ID, VAL, DESCE, ETAT)
SELECT 'CGRDEMO0001', 'Action', 'Action', 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_GENRE WHERE ID = 'CGRDEMO0001');

INSERT INTO CINEMA_GENRE (ID, VAL, DESCE, ETAT)
SELECT 'CGRDEMO0002', 'Comedie', 'Comedie', 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_GENRE WHERE ID = 'CGRDEMO0002');

INSERT INTO CINEMA_GENRE (ID, VAL, DESCE, ETAT)
SELECT 'CGRDEMO0003', 'Drame', 'Drame', 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_GENRE WHERE ID = 'CGRDEMO0003');

INSERT INTO CINEMA_GENRE (ID, VAL, DESCE, ETAT)
SELECT 'CGRDEMO0004', 'Science-fiction', 'Science-fiction', 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_GENRE WHERE ID = 'CGRDEMO0004');

INSERT INTO CINEMA_GENRE (ID, VAL, DESCE, ETAT)
SELECT 'CGRDEMO0005', 'Animation', 'Animation', 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_GENRE WHERE ID = 'CGRDEMO0005');

INSERT INTO CINEMA_GENRE (ID, VAL, DESCE, ETAT)
SELECT 'CGRDEMO0006', 'Thriller', 'Thriller', 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_GENRE WHERE ID = 'CGRDEMO0006');

INSERT INTO CINEMA_GENRE (ID, VAL, DESCE, ETAT)
SELECT 'CGRDEMO0007', 'Romance', 'Romance', 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_GENRE WHERE ID = 'CGRDEMO0007');

INSERT INTO CINEMA_GENRE (ID, VAL, DESCE, ETAT)
SELECT 'CGRDEMO0008', 'Documentaire', 'Documentaire', 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_GENRE WHERE ID = 'CGRDEMO0008');

-- ---------------------------------------------------------------------
-- 2. Categories de place
-- ---------------------------------------------------------------------
INSERT INTO CINEMA_CATEGORIEPLACE (ID, VAL, DESCE, PRIXDEFAUT, ETAT)
SELECT 'CCPDEMO0001', 'Standard', 'Place standard', 15000, 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_CATEGORIEPLACE WHERE ID = 'CCPDEMO0001');

INSERT INTO CINEMA_CATEGORIEPLACE (ID, VAL, DESCE, PRIXDEFAUT, ETAT)
SELECT 'CCPDEMO0002', 'VIP', 'Place VIP', 30000, 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_CATEGORIEPLACE WHERE ID = 'CCPDEMO0002');

INSERT INTO CINEMA_CATEGORIEPLACE (ID, VAL, DESCE, PRIXDEFAUT, ETAT)
SELECT 'CCPDEMO0003', 'Confort', 'Confort', 20000, 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_CATEGORIEPLACE WHERE ID = 'CCPDEMO0003');

INSERT INTO CINEMA_CATEGORIEPLACE (ID, VAL, DESCE, PRIXDEFAUT, ETAT)
SELECT 'CCPDEMO0004', 'Enfant', 'Tarif enfant', 3000, 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_CATEGORIEPLACE WHERE ID = 'CCPDEMO0004');

-- ---------------------------------------------------------------------
-- 3. Salle de demonstration
-- ---------------------------------------------------------------------
INSERT INTO CINEMA_SALLE (ID, NOM, ADRESSE, CAPACITE, ETAT)
SELECT 'CSADEMO0001', 'Salle 1', 'Salle de demonstration', 100, 1 FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_SALLE WHERE ID = 'CSADEMO0001');

-- ---------------------------------------------------------------------
-- 4. Places de la salle de demonstration
--    10 rangs (A..J) x 10 colonnes = 100 places.
--    Rangs I et J en VIP, les autres en Standard.
-- ---------------------------------------------------------------------
DECLARE
    v_rang      VARCHAR2(1);
    v_numero    VARCHAR2(20);
    v_id        VARCHAR2(100);
    v_categorie VARCHAR2(100);
    v_seq       NUMBER := 0;
    v_exists    NUMBER;
BEGIN
    FOR r IN 1 .. 10 LOOP
        v_rang := CHR(64 + r);
        FOR col IN 1 .. 10 LOOP
            v_seq := v_seq + 1;
            v_numero := v_rang || LPAD(col, 2, '0');
            v_id := 'CPLDEMO' || LPAD(v_seq, 4, '0');
            IF r >= 9 THEN
                v_categorie := 'CCPDEMO0002';
            ELSE
                v_categorie := 'CCPDEMO0001';
            END IF;

            SELECT COUNT(*) INTO v_exists
              FROM CINEMA_PLACE
             WHERE IDMERE = 'CSADEMO0001' AND NUMERO = v_numero;

            IF v_exists = 0 THEN
                INSERT INTO CINEMA_PLACE
                    (ID, IDMERE, NUMERO, RANG, COLONNE, IDCATEGORIEPLACE, ETAT)
                VALUES
                    (v_id, 'CSADEMO0001', v_numero, v_rang, col, v_categorie, 1);
            END IF;
        END LOOP;
    END LOOP;
END;
/

-- ---------------------------------------------------------------------
-- 5. Article generique pour les lignes de vente cinema
--    Modele sur les articles de vente existants (AS_INGREDIENTS).
-- ---------------------------------------------------------------------
INSERT INTO AS_INGREDIENTS
    (ID, LIBELLE, LIBELLEVENTE, CATEGORIEINGREDIENT, IDCATEGORIE, UNITE,
     QUANTITEPARPACK, PV, TVA, ISVENTE, ISACHAT, COMPTE_VENTE, COMPTE_ACHAT,
     COMPTE_STOCK, TYPESTOCK, TYPEPRODUIT, ACTIF, ISPERISHABLE, DURRE, CALORIE,
     SEUIL, DATY)
SELECT 'CINEMA_BILLET', 'BILLET CINEMA', 'BILLET CINEMA', 'CATEG0002',
       'CATEG0002', 'UNT00010', 0, 0, 20, 1, 0, '70700002', '60700000',
       '39700000', 'CUMP', 'TPRD004', 1, 0, 0, 0, 0, SYSDATE
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM AS_INGREDIENTS WHERE ID = 'CINEMA_BILLET');

COMMIT;
