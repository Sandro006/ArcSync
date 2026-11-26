-- =====================================================================
-- Module Cinema - gestion des remises
--   CINEMA_REMISE + colonnes de tracabilite sur les reservations.
-- Idempotent : peut etre rejoue sans effet de bord.
--
-- Regle : si une reservation contient au moins NOMBREPLACE places de la
-- categorie IDCATEGORIERESERVATION, on remise NOMBREPLACEREMISE places de
-- la categorie IDCATEGORIEREMISE. Les deux categories doivent etre
-- differentes. Une seule regle est appliquee par reservation.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Table des regles de remise
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_REMISE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_REMISE (
                ID                      VARCHAR2(100) NOT NULL,
                IDCATEGORIERESERVATION  VARCHAR2(100) NOT NULL,
                NOMBREPLACE             NUMBER(6) NOT NULL,
                TYPEVALEUR              NUMBER(1) DEFAULT 0 NOT NULL,
                VALEUR                  NUMBER DEFAULT 0 NOT NULL,
                IDCATEGORIEREMISE       VARCHAR2(100) NOT NULL,
                NOMBREPLACEREMISE       NUMBER(6) NOT NULL,
                DESCE                   VARCHAR2(500),
                ETAT                    NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_REMISE PRIMARY KEY (ID),
                CONSTRAINT CK_CINEMA_REMISE_TYPE CHECK (TYPEVALEUR IN (0, 1)),
                CONSTRAINT CK_CINEMA_REMISE_SEUIL CHECK (NOMBREPLACE >= 1),
                CONSTRAINT CK_CINEMA_REMISE_NBREM CHECK (NOMBREPLACEREMISE >= 1),
                CONSTRAINT CK_CINEMA_REMISE_VALEUR CHECK (VALEUR >= 0),
                CONSTRAINT CK_CINEMA_REMISE_CAT CHECK
                    (IDCATEGORIERESERVATION <> IDCATEGORIEREMISE),
                CONSTRAINT FK_CINEMA_REMISE_CATRES FOREIGN KEY (IDCATEGORIERESERVATION)
                    REFERENCES CINEMA_CATEGORIEPLACE (ID),
                CONSTRAINT FK_CINEMA_REMISE_CATREM FOREIGN KEY (IDCATEGORIEREMISE)
                    REFERENCES CINEMA_CATEGORIEPLACE (ID)
            )';
    END IF;
END;
/

DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_indexes
     WHERE index_name = 'IDX_CINEMA_REMISE_CAT';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE INDEX IDX_CINEMA_REMISE_CAT
                ON CINEMA_REMISE (IDCATEGORIERESERVATION, ETAT)';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 2. Tracabilite sur le detail des reservations
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tab_columns
     WHERE table_name = 'CINEMA_RESERVATIONDETAIL'
       AND column_name = 'IDREMISE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE CINEMA_RESERVATIONDETAIL ADD (IDREMISE VARCHAR2(100))';
    END IF;
END;
/

DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tab_columns
     WHERE table_name = 'CINEMA_RESERVATIONDETAIL'
       AND column_name = 'MONTANTREMISE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE CINEMA_RESERVATIONDETAIL ADD (MONTANTREMISE NUMBER DEFAULT 0)';
    END IF;
END;
/

DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tab_columns
     WHERE table_name = 'CINEMA_RESERVATION'
       AND column_name = 'MONTANTREMISE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE
            'ALTER TABLE CINEMA_RESERVATION ADD (MONTANTREMISE NUMBER DEFAULT 0)';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 3. Sequence et fonction de cle primaire
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_sequences
     WHERE sequence_name = 'SEQ_CINEMA_REMISE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE
            'CREATE SEQUENCE SEQ_CINEMA_REMISE START WITH 1 INCREMENT BY 1 NOCACHE';
    END IF;
END;
/

CREATE OR REPLACE FUNCTION GETSEQCINEMAREMISE RETURN NUMBER IS
    v NUMBER;
BEGIN
    SELECT SEQ_CINEMA_REMISE.NEXTVAL INTO v FROM DUAL;
    RETURN v;
END;
/

-- ---------------------------------------------------------------------
-- 4. Vue d'affichage
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW CINEMA_REMISE_LIB AS
SELECT b.*,
       cr.VAL AS IDCATEGORIERESERVATIONLIB,
       cm.VAL AS IDCATEGORIEREMISELIB,
       CASE b.TYPEVALEUR
           WHEN 0 THEN 'Pourcentage'
           WHEN 1 THEN 'Montant fixe'
           ELSE 'Type ' || b.TYPEVALEUR
       END AS TYPEVALEURLIB,
       CASE b.ETAT
           WHEN 0 THEN 'Annule'
           WHEN 1 THEN 'Cree'
           WHEN 9 THEN 'Cloture'
           WHEN 10 THEN 'Rejete'
           WHEN 11 THEN 'Valide'
           ELSE 'Etat ' || b.ETAT
       END AS ETATLIB
  FROM CINEMA_REMISE b
  LEFT JOIN CINEMA_CATEGORIEPLACE cr ON cr.ID = b.IDCATEGORIERESERVATION
  LEFT JOIN CINEMA_CATEGORIEPLACE cm ON cm.ID = b.IDCATEGORIEREMISE;

-- ---------------------------------------------------------------------
-- 5. Menu et droits d'acces
-- ---------------------------------------------------------------------
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
SELECT 'MENDYN1792000000000011', 'Remises', 'percent',
       'module.jsp?but=cinema/configuration/remise-liste.jsp', 9, 2,
       'MENDYN1792000000000001'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM MENUDYNAMIQUE WHERE ID = 'MENDYN1792000000000011');

INSERT INTO USERMENU (ID, REFUSER, IDMENU, IDROLE, CODESERVICE, CODEDIR, INTERDIT)
SELECT 'UMCIN0011', '*', 'MENDYN1792000000000011', NULL, NULL, NULL, 0
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM USERMENU WHERE ID = 'UMCIN0011');

COMMIT;
