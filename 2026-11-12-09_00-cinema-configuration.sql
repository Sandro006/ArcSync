-- =====================================================================
-- Module Cinema - configuration
--   CINEMA_GENRE, CINEMA_CATEGORIEPLACE, CINEMA_SALLE, CINEMA_PLACE
-- Idempotent : peut etre rejoue sans effet de bord.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Genres
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_GENRE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_GENRE (
                ID      VARCHAR2(100) NOT NULL,
                VAL     VARCHAR2(200) NOT NULL,
                DESCE   VARCHAR2(500),
                ETAT    NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_GENRE PRIMARY KEY (ID)
            )';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 2. Categories de place
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_CATEGORIEPLACE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_CATEGORIEPLACE (
                ID          VARCHAR2(100) NOT NULL,
                VAL         VARCHAR2(200) NOT NULL,
                DESCE       VARCHAR2(500),
                PRIXDEFAUT  NUMBER DEFAULT 0,
                ETAT        NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_CATEGORIEPLACE PRIMARY KEY (ID)
            )';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 3. Salles
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_SALLE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_SALLE (
                ID          VARCHAR2(100) NOT NULL,
                NOM         VARCHAR2(200) NOT NULL,
                ADRESSE     VARCHAR2(500),
                CAPACITE    NUMBER(4),
                ETAT        NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_SALLE PRIMARY KEY (ID)
            )';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 4. Places
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_PLACE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_PLACE (
                ID                  VARCHAR2(100) NOT NULL,
                IDMERE              VARCHAR2(100) NOT NULL,
                NUMERO              VARCHAR2(20) NOT NULL,
                RANG                VARCHAR2(10),
                COLONNE             NUMBER(4),
                IDCATEGORIEPLACE    VARCHAR2(100),
                ETAT                NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_PLACE PRIMARY KEY (ID),
                CONSTRAINT UQ_CINEMA_PLACE_NUM UNIQUE (IDMERE, NUMERO),
                CONSTRAINT FK_CINEMA_PLACE_SALLE FOREIGN KEY (IDMERE)
                    REFERENCES CINEMA_SALLE (ID),
                CONSTRAINT FK_CINEMA_PLACE_CAT FOREIGN KEY (IDCATEGORIEPLACE)
                    REFERENCES CINEMA_CATEGORIEPLACE (ID)
            )';
    END IF;
END;
/

COMMIT;
