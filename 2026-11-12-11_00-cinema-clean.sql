-- =====================================================================
-- Module Cinema - nettoyage des donnees transactionnelles
--
-- CE QUI EST SUPPRIME
--   CINEMA_BILLET, CINEMA_ACHATBILLET,
--   CINEMA_RESERVATION, CINEMA_RESERVATIONDETAIL,
--   les VENTE / VENTE_DETAILS / MOUVEMENTCAISSE generes par les ventes
--   de billets, ainsi que l'historique 'cinema.*'.
--
-- CE QUI EST CONSERVE (configuration)
--   CINEMA_GENRE, CINEMA_CATEGORIEPLACE, CINEMA_FILM, CINEMA_SALLE,
--   CINEMA_PLACE, CINEMA_PROJECTION, CINEMA_PROJECTIONTARIF,
--   les menus et les clients.
--
-- SEQUENCES REMISES A 1
--   SEQ_CINEMA_ACHATBILLET, SEQ_CINEMA_BILLET,
--   SEQ_CINEMA_RESERVATION, SEQ_CINEMA_RESERVATIONDETAIL
--   -> les prochains identifiants repartent de CAB000001, CBI000001,
--      CRS000001, CRSD000001.
--
--   Les sequences de configuration ne sont volontairement PAS remises a
--   zero : des identifiants issus de ces sequences existent deja
--   (CPL000001, CFI000001, CSA000001...) et seraient reutilises, ce qui
--   provoquerait une violation de cle primaire au prochain enregistrement.
--   Pour les remettre a zero, il faudrait d'abord supprimer les
--   referentiels correspondants.
--
-- UTILISATION
--   sqlplus itu/labs@//localhost:1521/EE.oracle.docker @2026-11-12-11_00-cinema-clean.sql
--
-- Le script est idempotent : le relancer sur une base deja nettoyee ne
-- fait rien (hors remise a zero des 4 sequences, sans effet de bord).
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET PAGESIZE 100
SET LINESIZE 160
WHENEVER SQLERROR EXIT ROLLBACK

PROMPT
PROMPT ============================================================
PROMPT  ETAT AVANT NETTOYAGE
PROMPT ============================================================

SELECT (SELECT COUNT(*) FROM CINEMA_BILLET)             AS BILLETS,
       (SELECT COUNT(*) FROM CINEMA_ACHATBILLET)        AS ACHATS,
       (SELECT COUNT(*) FROM CINEMA_RESERVATION)        AS RESERVATIONS,
       (SELECT COUNT(*) FROM CINEMA_RESERVATIONDETAIL)  AS DETAILS,
       (SELECT COUNT(*) FROM HISTORIQUE
         WHERE OBJET LIKE 'cinema.%')                   AS HISTORIQUE_CINEMA
  FROM DUAL;

-- ---------------------------------------------------------------------
-- 0. SAUVEGARDE FACULTATIVE
--    Decommenter ce bloc (et le rejouer) pour archiver les donnees
--    avant suppression. Remplacer la date si besoin.
-- ---------------------------------------------------------------------
-- CREATE TABLE CINEMA_BILLET_BAK_20261112            AS SELECT * FROM CINEMA_BILLET;
-- CREATE TABLE CINEMA_ACHATBILLET_BAK_20261112       AS SELECT * FROM CINEMA_ACHATBILLET;
-- CREATE TABLE CINEMA_RESERVATION_BAK_20261112       AS SELECT * FROM CINEMA_RESERVATION;
-- CREATE TABLE CINEMA_RESERVATIONDETAIL_BAK_20261112 AS SELECT * FROM CINEMA_RESERVATIONDETAIL;

-- =====================================================================
-- 1. PURGE DES TRANSACTIONS
--    L'ordre respecte les cles etrangeres :
--      RESERVATIONDETAIL -> BILLET -> VENTE_DETAILS -> ACHATBILLET
--      -> VENTE / MOUVEMENTCAISSE -> RESERVATION
--    Les identifiants de VENTE et MOUVEMENTCAISSE sont memorises avant
--    la suppression des achats, car ce sont les achats qui les
--    referencent.
-- =====================================================================

PROMPT
PROMPT ============================================================
PROMPT  PURGE EN COURS
PROMPT ============================================================

DECLARE
    TYPE t_ids IS TABLE OF VARCHAR2(100);

    v_ventes t_ids;
    v_mvts   t_ids;
BEGIN
    SELECT IDVENTE BULK COLLECT INTO v_ventes
      FROM CINEMA_ACHATBILLET
     WHERE IDVENTE IS NOT NULL;

    SELECT IDMOUVEMENTCAISSE BULK COLLECT INTO v_mvts
      FROM CINEMA_ACHATBILLET
     WHERE IDMOUVEMENTCAISSE IS NOT NULL;

    -- 1. Lignes de reservation (FK vers CINEMA_BILLET)
    DELETE FROM CINEMA_RESERVATIONDETAIL;

    -- 2. Billets
    DELETE FROM CINEMA_BILLET;

    -- 3. Lignes de facture des ventes de billets
    DELETE FROM VENTE_DETAILS
     WHERE IDVENTE IN (SELECT IDVENTE FROM CINEMA_ACHATBILLET
                        WHERE IDVENTE IS NOT NULL);

    -- 4. Achats de billets
    DELETE FROM CINEMA_ACHATBILLET;

    -- 5. Factures et mouvements de caisse devenus orphelins
    IF v_ventes.COUNT > 0 THEN
        FORALL i IN 1 .. v_ventes.COUNT
            DELETE FROM VENTE WHERE ID = v_ventes(i);
    END IF;

    IF v_mvts.COUNT > 0 THEN
        FORALL i IN 1 .. v_mvts.COUNT
            DELETE FROM MOUVEMENTCAISSE WHERE ID = v_mvts(i);
    END IF;

    -- 6. Reservations
    DELETE FROM CINEMA_RESERVATION;

    -- 7. Historique genere par le module cinema
    DELETE FROM HISTORIQUE WHERE OBJET LIKE 'cinema.%';

    DBMS_OUTPUT.PUT_LINE('Purge terminee : '
        || SQL%ROWCOUNT || ' lignes sur le dernier DELETE.');
END;
/

COMMIT;

-- =====================================================================
-- 2. REMISE A ZERO DES SEQUENCES TRANSACTIONNELLES
--    Oracle 11g ne connait pas ALTER SEQUENCE ... RESTART : on
--    supprime puis on recree chaque sequence a 1.
-- =====================================================================

PROMPT
PROMPT ============================================================
PROMPT  REMISE A ZERO DES SEQUENCES
PROMPT ============================================================

DECLARE
    TYPE t_names IS TABLE OF VARCHAR2(30);

    v_names t_names := t_names(
        'SEQ_CINEMA_ACHATBILLET',
        'SEQ_CINEMA_BILLET',
        'SEQ_CINEMA_RESERVATION',
        'SEQ_CINEMA_RESERVATIONDETAIL'
    );
BEGIN
    FOR i IN 1 .. v_names.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP SEQUENCE ' || v_names(i);
        EXCEPTION
            WHEN OTHERS THEN
                -- ORA-02289 : sequence inexistante, on la cree plus bas
                IF SQLCODE != -2289 THEN
                    RAISE;
                END IF;
        END;

        EXECUTE IMMEDIATE 'CREATE SEQUENCE ' || v_names(i)
            || ' START WITH 1 INCREMENT BY 1 NOCACHE';

        DBMS_OUTPUT.PUT_LINE('Sequence ' || v_names(i) || ' remise a 1.');
    END LOOP;
END;
/

-- =====================================================================
-- 3. VERIFICATION
-- =====================================================================

PROMPT
PROMPT ============================================================
PROMPT  ETAT APRES NETTOYAGE
PROMPT ============================================================

SELECT (SELECT COUNT(*) FROM CINEMA_BILLET)            AS BILLETS,
       (SELECT COUNT(*) FROM CINEMA_ACHATBILLET)       AS ACHATS,
       (SELECT COUNT(*) FROM CINEMA_RESERVATION)       AS RESERVATIONS,
       (SELECT COUNT(*) FROM CINEMA_RESERVATIONDETAIL) AS DETAILS,
       (SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE)     AS PLACES_OCCUPEES
  FROM DUAL;

SELECT SEQUENCE_NAME, LAST_NUMBER
  FROM USER_SEQUENCES
 WHERE SEQUENCE_NAME IN ('SEQ_CINEMA_ACHATBILLET', 'SEQ_CINEMA_BILLET',
                         'SEQ_CINEMA_RESERVATION',
                         'SEQ_CINEMA_RESERVATIONDETAIL')
 ORDER BY SEQUENCE_NAME;

PROMPT
PROMPT Nettoyage termine.
PROMPT
