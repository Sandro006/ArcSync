-- =====================================================================
-- Module Cinema - projections et tarifs
-- Idempotent : peut etre rejoue sans effet de bord.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Projections
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_PROJECTION';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_PROJECTION (
                ID          VARCHAR2(100) NOT NULL,
                DATY        DATE NOT NULL,
                HEUREDEBUT  VARCHAR2(5) NOT NULL,
                HEUREFIN    VARCHAR2(5) NOT NULL,
                IDFILM      VARCHAR2(100),
                IDSALLE     VARCHAR2(100),
                PRIXBASE    NUMBER DEFAULT 0,
                NBPLACES    NUMBER(4),
                FORMAT      VARCHAR2(20),
                VERSION     VARCHAR2(20),
                STATUT      NUMBER(2) DEFAULT 1,
                REMARQUE    VARCHAR2(500),
                ETAT        NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_PROJECTION PRIMARY KEY (ID),
                CONSTRAINT FK_CINEMA_PROJ_FILM FOREIGN KEY (IDFILM)
                    REFERENCES CINEMA_FILM (ID),
                CONSTRAINT FK_CINEMA_PROJ_SALLE FOREIGN KEY (IDSALLE)
                    REFERENCES CINEMA_SALLE (ID)
            )';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 2. Tarifs par projection
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_PROJECTIONTARIF';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_PROJECTIONTARIF (
                ID                  VARCHAR2(100) NOT NULL,
                IDMERE              VARCHAR2(100) NOT NULL,
                IDCATEGORIEPLACE    VARCHAR2(100) NOT NULL,
                RANG                VARCHAR2(10) DEFAULT ''*'' NOT NULL,
                PRIX                NUMBER DEFAULT 0,
                QUOTA               NUMBER(6) DEFAULT 0,
                ETAT                NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_PROJTARIF PRIMARY KEY (ID),
                CONSTRAINT UQ_CINEMA_PROJTARIF UNIQUE (IDMERE, IDCATEGORIEPLACE, RANG),
                CONSTRAINT FK_CINEMA_PROJTARIF_PROJ FOREIGN KEY (IDMERE)
                    REFERENCES CINEMA_PROJECTION (ID),
                CONSTRAINT FK_CINEMA_PROJTARIF_CAT FOREIGN KEY (IDCATEGORIEPLACE)
                    REFERENCES CINEMA_CATEGORIEPLACE (ID)
            )';
    END IF;
END;
/

COMMIT;
