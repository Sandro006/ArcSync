-- =====================================================================
-- Module Cinema - plan de salle + programme de la semaine 16->22/11/2026
--
-- CONTENU
--   - Categories : Standard 15 000 Ar, Confort 20 000 Ar, VIP 30 000 Ar
--     (la categorie Confort est creee ; les categories existantes
--      Standard et VIP sont remises au bon prix)
--   - 3 salles (Salle A, Salle B, Salle C) de 20 places chacune :
--       rangs A et B -> Standard
--       rang C       -> Confort
--       rang D       -> VIP
--     5 places par rang (A01..A05, B01..B05, C01..C05, D01..D05)
--   - 18 seances du lundi 16/11 au dimanche 22/11/2026
--   - 3 tarifs par seance (Standard / Confort / VIP, rang '*')
--
-- PREREQUIS
--   Les films existent deja :
--     CFI000003 = Les gardiens du Baobab (115 min)
--     CFI000004 = Nuit sur Analamanga     (105 min)
--     CFI000005 = Le petit Lemurien        ( 90 min)
--   Les salles sont creees par le script si elles n'existent pas.
--
-- REMARQUES
--   - Le document source liste "Mercredi 17:00" deux fois pour
--     Le petit Lemurien : le doublon est ignore.
--   - La seance CPR000004 (12/11/2026, Salle A) n'est pas modifiee.
--   - Idempotent : relancer le script ne cree pas de doublon.
--   - Aucun accent dans les libelles SQL (encodage sqlplus Windows).
--
-- UTILISATION
--   sqlplus itu/labs@//localhost:1521/EE.oracle.docker @2026-11-12-11_30-cinema-programme-semaine.sql
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET PAGESIZE 200
SET LINESIZE 200
WHENEVER SQLERROR EXIT ROLLBACK

PROMPT
PROMPT ============================================================
PROMPT  1. CATEGORIES DE PLACE
PROMPT ============================================================

UPDATE CINEMA_CATEGORIEPLACE
   SET VAL = 'Standard', PRIXDEFAUT = 15000
 WHERE ID = 'CCPDEMO0001';

UPDATE CINEMA_CATEGORIEPLACE
   SET VAL = 'VIP', PRIXDEFAUT = 30000
 WHERE ID = 'CCPDEMO0002';

INSERT INTO CINEMA_CATEGORIEPLACE (ID, VAL, DESCE, PRIXDEFAUT, ETAT)
SELECT 'CCP' || LPAD(GETSEQCINEMACATEGORIEPLACE, 6, '0'),
       'Confort', 'Place Confort', 20000, 1
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM CINEMA_CATEGORIEPLACE WHERE VAL = 'Confort');

UPDATE CINEMA_CATEGORIEPLACE
   SET PRIXDEFAUT = 20000
 WHERE VAL = 'Confort';

-- ---------------------------------------------------------------------
-- 2. SALLES A / B / C (creees si absentes, capacite forcee a 20)
-- ---------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  2. SALLES
PROMPT ============================================================

DECLARE
    TYPE t_noms IS TABLE OF VARCHAR2(200) INDEX BY PLS_INTEGER;

    v_noms t_noms;
    v_id   VARCHAR2(100);
BEGIN
    v_noms(1) := 'Salle A';
    v_noms(2) := 'Salle B';
    v_noms(3) := 'Salle C';

    FOR i IN 1 .. v_noms.COUNT LOOP
        BEGIN
            SELECT ID INTO v_id
              FROM CINEMA_SALLE
             WHERE NOM = v_noms(i) AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                SELECT 'CSA' || LPAD(GETSEQCINEMASALLE, 6, '0')
                  INTO v_id
                  FROM DUAL;

                INSERT INTO CINEMA_SALLE (ID, NOM, ADRESSE, CAPACITE, ETAT)
                VALUES (v_id, v_noms(i), 'Cinema', 20, 1);
        END;

        UPDATE CINEMA_SALLE SET CAPACITE = 20 WHERE ID = v_id;

        DBMS_OUTPUT.PUT_LINE('Salle ' || v_noms(i) || ' : ' || v_id);
    END LOOP;
END;
/

-- ---------------------------------------------------------------------
-- 3. PLACES : 4 rangs x 5 places par salle
--    A,B = Standard   C = Confort   D = VIP
-- ---------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  3. PLACES
PROMPT ============================================================

DECLARE
    v_cat_standard VARCHAR2(100) := 'CCPDEMO0001';
    v_cat_vip      VARCHAR2(100) := 'CCPDEMO0002';
    v_cat_confort  VARCHAR2(100);
    v_rang         VARCHAR2(1);
    v_categorie    VARCHAR2(100);
    v_numero       VARCHAR2(20);
    v_place_id     VARCHAR2(100);
    v_exists       NUMBER;
    v_ajoutees     NUMBER := 0;
BEGIN
    SELECT ID INTO v_cat_confort
      FROM CINEMA_CATEGORIEPLACE
     WHERE VAL = 'Confort' AND ROWNUM = 1;

    FOR s IN (SELECT ID, NOM FROM CINEMA_SALLE
               WHERE NOM IN ('Salle A', 'Salle B', 'Salle C')) LOOP

        FOR r IN 1 .. 4 LOOP
            v_rang := CHR(64 + r);

            IF r <= 2 THEN
                v_categorie := v_cat_standard;
            ELSIF r = 3 THEN
                v_categorie := v_cat_confort;
            ELSE
                v_categorie := v_cat_vip;
            END IF;

            FOR col IN 1 .. 5 LOOP
                v_numero := v_rang || LPAD(col, 2, '0');

                SELECT COUNT(*) INTO v_exists
                  FROM CINEMA_PLACE
                 WHERE IDMERE = s.ID AND NUMERO = v_numero;

                IF v_exists = 0 THEN
                    SELECT 'CPL' || LPAD(GETSEQCINEMAPLACE, 6, '0')
                      INTO v_place_id
                      FROM DUAL;

                    INSERT INTO CINEMA_PLACE
                        (ID, IDMERE, NUMERO, RANG, COLONNE,
                         IDCATEGORIEPLACE, ETAT)
                    VALUES
                        (v_place_id, s.ID, v_numero, v_rang, col,
                         v_categorie, 1);

                    v_ajoutees := v_ajoutees + 1;
                ELSE
                    -- place existante : on aligne rang/colonne/categorie
                    UPDATE CINEMA_PLACE
                       SET RANG = v_rang,
                           COLONNE = col,
                           IDCATEGORIEPLACE = v_categorie,
                           ETAT = 1
                     WHERE IDMERE = s.ID AND NUMERO = v_numero;
                END IF;
            END LOOP;
        END LOOP;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Places ajoutees : ' || v_ajoutees);
END;
/

-- ---------------------------------------------------------------------
-- 4. SEANCES 16 -> 22/11/2026 + tarifs
--    L'heure de fin est calculee avec la duree du film.
-- ---------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  4. SEANCES ET TARIFS
PROMPT ============================================================

DECLARE
    v_salle_id    VARCHAR2(100);
    v_capacite    NUMBER;
    v_duree       NUMBER;
    v_heure_fin   VARCHAR2(5);
    v_proj_id     VARCHAR2(100);
    v_exists      NUMBER;
    v_cat_standard VARCHAR2(100) := 'CCPDEMO0001';
    v_cat_vip      VARCHAR2(100) := 'CCPDEMO0002';
    v_cat_confort  VARCHAR2(100);
    v_crees       NUMBER := 0;
BEGIN
    SELECT ID INTO v_cat_confort
      FROM CINEMA_CATEGORIEPLACE
     WHERE VAL = 'Confort' AND ROWNUM = 1;

    FOR r IN (
        -- Lundi 16/11 : Les gardiens du Baobab (Salle A)
        SELECT 'CFI000003' AS idfilm, 'Salle A' AS salle,
               DATE '2026-11-16' AS daty, '14:00' AS heure FROM DUAL
        UNION ALL SELECT 'CFI000003', 'Salle A', DATE '2026-11-16', '20:00' FROM DUAL
        -- Lundi 16/11 : Nuit sur Analamanga (Salle B)
        UNION ALL SELECT 'CFI000004', 'Salle B', DATE '2026-11-16', '14:00' FROM DUAL
        UNION ALL SELECT 'CFI000004', 'Salle B', DATE '2026-11-16', '17:00' FROM DUAL
        UNION ALL SELECT 'CFI000004', 'Salle B', DATE '2026-11-16', '20:00' FROM DUAL
        -- Mardi 17/11
        UNION ALL SELECT 'CFI000004', 'Salle B', DATE '2026-11-17', '18:00' FROM DUAL
        UNION ALL SELECT 'CFI000005', 'Salle C', DATE '2026-11-17', '14:00' FROM DUAL
        -- Mercredi 18/11 : Le petit Lemurien (doublon 17:00 ignore)
        UNION ALL SELECT 'CFI000005', 'Salle C', DATE '2026-11-18', '14:00' FROM DUAL
        UNION ALL SELECT 'CFI000005', 'Salle C', DATE '2026-11-18', '17:00' FROM DUAL
        -- Jeudi 19/11 : Les gardiens du Baobab (Salle A)
        UNION ALL SELECT 'CFI000003', 'Salle A', DATE '2026-11-19', '14:00' FROM DUAL
        UNION ALL SELECT 'CFI000003', 'Salle A', DATE '2026-11-19', '17:00' FROM DUAL
        UNION ALL SELECT 'CFI000003', 'Salle A', DATE '2026-11-19', '20:00' FROM DUAL
        -- Vendredi 20/11 : Nuit sur Analamanga (Salle B)
        UNION ALL SELECT 'CFI000004', 'Salle B', DATE '2026-11-20', '17:00' FROM DUAL
        UNION ALL SELECT 'CFI000004', 'Salle B', DATE '2026-11-20', '20:00' FROM DUAL
        -- Samedi 21/11 : Le petit Lemurien (Salle C)
        UNION ALL SELECT 'CFI000005', 'Salle C', DATE '2026-11-21', '10:00' FROM DUAL
        UNION ALL SELECT 'CFI000005', 'Salle C', DATE '2026-11-21', '14:00' FROM DUAL
        UNION ALL SELECT 'CFI000005', 'Salle C', DATE '2026-11-21', '17:00' FROM DUAL
        -- Dimanche 22/11 : Les gardiens du Baobab (Salle A)
        UNION ALL SELECT 'CFI000003', 'Salle A', DATE '2026-11-22', '15:00' FROM DUAL
    ) LOOP

        SELECT s.ID, NVL(s.CAPACITE, 20), f.DUREE
          INTO v_salle_id, v_capacite, v_duree
          FROM CINEMA_SALLE s, CINEMA_FILM f
         WHERE s.NOM = r.salle
           AND f.ID = r.idfilm
           AND ROWNUM = 1;

        IF v_duree IS NULL THEN
            RAISE_APPLICATION_ERROR(-20001,
                'Duree manquante pour le film ' || r.idfilm);
        END IF;

        SELECT COUNT(*) INTO v_exists
          FROM CINEMA_PROJECTION
         WHERE IDSALLE = v_salle_id
           AND DATY = r.daty
           AND HEUREDEBUT = r.heure;

        IF v_exists = 0 THEN
            v_heure_fin := TO_CHAR(
                TO_DATE(r.heure, 'HH24:MI') + (v_duree / 1440), 'HH24:MI');

            SELECT 'CPR' || LPAD(GETSEQCINEMAPROJECTION, 6, '0')
              INTO v_proj_id
              FROM DUAL;

            INSERT INTO CINEMA_PROJECTION
                (ID, DATY, HEUREDEBUT, HEUREFIN, IDFILM, IDSALLE,
                 PRIXBASE, NBPLACES, STATUT, ETAT)
            VALUES
                (v_proj_id, r.daty, r.heure, v_heure_fin, r.idfilm, v_salle_id,
                 15000, v_capacite, 2, 11);

            v_crees := v_crees + 1;
        ELSE
            SELECT ID INTO v_proj_id
              FROM CINEMA_PROJECTION
             WHERE IDSALLE = v_salle_id
               AND DATY = r.daty
               AND HEUREDEBUT = r.heure
               AND ROWNUM = 1;
        END IF;

        -- Tarifs de la seance : un prix par categorie, tous rangs
        INSERT INTO CINEMA_PROJECTIONTARIF
            (ID, IDMERE, IDCATEGORIEPLACE, RANG, PRIX, QUOTA, ETAT)
        SELECT 'CPRT' || LPAD(GETSEQCINEMAPROJECTIONTARIF, 6, '0'),
               v_proj_id, v_cat_standard, '*', 15000, 0, 11
          FROM DUAL
         WHERE NOT EXISTS (SELECT 1 FROM CINEMA_PROJECTIONTARIF
                            WHERE IDMERE = v_proj_id
                              AND IDCATEGORIEPLACE = v_cat_standard
                              AND RANG = '*');

        INSERT INTO CINEMA_PROJECTIONTARIF
            (ID, IDMERE, IDCATEGORIEPLACE, RANG, PRIX, QUOTA, ETAT)
        SELECT 'CPRT' || LPAD(GETSEQCINEMAPROJECTIONTARIF, 6, '0'),
               v_proj_id, v_cat_confort, '*', 20000, 0, 11
          FROM DUAL
         WHERE NOT EXISTS (SELECT 1 FROM CINEMA_PROJECTIONTARIF
                            WHERE IDMERE = v_proj_id
                              AND IDCATEGORIEPLACE = v_cat_confort
                              AND RANG = '*');

        INSERT INTO CINEMA_PROJECTIONTARIF
            (ID, IDMERE, IDCATEGORIEPLACE, RANG, PRIX, QUOTA, ETAT)
        SELECT 'CPRT' || LPAD(GETSEQCINEMAPROJECTIONTARIF, 6, '0'),
               v_proj_id, v_cat_vip, '*', 30000, 0, 11
          FROM DUAL
         WHERE NOT EXISTS (SELECT 1 FROM CINEMA_PROJECTIONTARIF
                            WHERE IDMERE = v_proj_id
                              AND IDCATEGORIEPLACE = v_cat_vip
                              AND RANG = '*');
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('Seances creees : ' || v_crees);
END;
/

COMMIT;

-- ---------------------------------------------------------------------
-- 5. VERIFICATION
-- ---------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  5. VERIFICATION
PROMPT ============================================================

COL ID FOR A10
COL JOUR FOR A10
COL HEURE FOR A6
COL FIN FOR A6
COL SALLE FOR A8
COL FILM FOR A28
COL CATEGORIE FOR A10
COL PRIX FOR 99990

SELECT s.NOM AS SALLE,
       COUNT(p.ID) AS NB_PLACES,
       SUM(CASE WHEN p.RANG IN ('A', 'B') THEN 1 ELSE 0 END) AS STANDARD,
       SUM(CASE WHEN p.RANG = 'C' THEN 1 ELSE 0 END) AS CONFORT,
       SUM(CASE WHEN p.RANG = 'D' THEN 1 ELSE 0 END) AS VIP
  FROM CINEMA_SALLE s
  LEFT JOIN CINEMA_PLACE p ON p.IDMERE = s.ID AND p.ETAT = 1
 WHERE s.NOM IN ('Salle A', 'Salle B', 'Salle C')
 GROUP BY s.NOM
 ORDER BY s.NOM;

SELECT p.ID,
       TO_CHAR(p.DATY, 'DD/MM/YYYY') AS JOUR,
       p.HEUREDEBUT AS HEURE,
       p.HEUREFIN AS FIN,
       s.NOM AS SALLE,
       f.TITRE AS FILM,
       p.STATUT,
       p.ETAT
  FROM CINEMA_PROJECTION p
  JOIN CINEMA_SALLE s ON s.ID = p.IDSALLE
  JOIN CINEMA_FILM f ON f.ID = p.IDFILM
 WHERE p.DATY BETWEEN DATE '2026-11-16' AND DATE '2026-11-22'
 ORDER BY p.DATY, p.HEUREDEBUT, s.NOM;

SELECT c.VAL AS CATEGORIE, t.RANG, t.PRIX, COUNT(*) AS NB_SEANCES
  FROM CINEMA_PROJECTIONTARIF t
  JOIN CINEMA_CATEGORIEPLACE c ON c.ID = t.IDCATEGORIEPLACE
  JOIN CINEMA_PROJECTION p ON p.ID = t.IDMERE
 WHERE p.DATY BETWEEN DATE '2026-11-16' AND DATE '2026-11-22'
 GROUP BY c.VAL, t.RANG, t.PRIX
 ORDER BY t.PRIX;

PROMPT
PROMPT Script termine.
PROMPT
