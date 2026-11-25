-- =====================================================================
-- Module Cinema - reservations et billets
--   CINEMA_RESERVATION, CINEMA_ACHATBILLET, CINEMA_BILLET,
--   CINEMA_RESERVATIONDETAIL
-- Idempotent : peut etre rejoue sans effet de bord.
--
-- Ordre de creation impose par le cycle de references :
--   RESERVATION -> ACHATBILLET -> BILLET -> RESERVATIONDETAIL
-- puis ALTER TABLE pour la FK IDBILLET -> CINEMA_BILLET.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Reservations
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_RESERVATION';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_RESERVATION (
                ID                  VARCHAR2(100) NOT NULL,
                DATY                DATE DEFAULT SYSDATE,
                IDCLIENT            VARCHAR2(255),
                IDPROJECTION        VARCHAR2(100) NOT NULL,
                DATEEXPIRATION      DATE,
                MONTANTACOMPTE      NUMBER DEFAULT 0,
                STATUT              NUMBER(2) DEFAULT 1,
                REMARQUE            VARCHAR2(500),
                ETAT                NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_RESERVATION PRIMARY KEY (ID),
                CONSTRAINT FK_CINEMA_RESERV_PROJ FOREIGN KEY (IDPROJECTION)
                    REFERENCES CINEMA_PROJECTION (ID),
                CONSTRAINT FK_CINEMA_RESERV_CLIENT FOREIGN KEY (IDCLIENT)
                    REFERENCES CLIENT (ID)
            )';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 2. Achats groupes de billets
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_ACHATBILLET';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_ACHATBILLET (
                ID                  VARCHAR2(100) NOT NULL,
                DATY                DATE DEFAULT SYSDATE,
                IDCLIENT            VARCHAR2(255),
                IDPROJECTION        VARCHAR2(100) NOT NULL,
                IDRESERVATION       VARCHAR2(100),
                MONTANTTOTAL        NUMBER DEFAULT 0,
                MONTANTPAYE         NUMBER DEFAULT 0,
                MONNAIERENDUE       NUMBER DEFAULT 0,
                MODEPAIEMENT        VARCHAR2(255),
                IDVENTE             VARCHAR2(255),
                IDMOUVEMENTCAISSE   VARCHAR2(255),
                REMARQUE            VARCHAR2(500),
                ETAT                NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_ACHATBILLET PRIMARY KEY (ID),
                CONSTRAINT FK_CINEMA_ACHAT_PROJ FOREIGN KEY (IDPROJECTION)
                    REFERENCES CINEMA_PROJECTION (ID),
                CONSTRAINT FK_CINEMA_ACHAT_RESERV FOREIGN KEY (IDRESERVATION)
                    REFERENCES CINEMA_RESERVATION (ID),
                CONSTRAINT FK_CINEMA_ACHAT_CLIENT FOREIGN KEY (IDCLIENT)
                    REFERENCES CLIENT (ID),
                CONSTRAINT FK_CINEMA_ACHAT_MODEP FOREIGN KEY (MODEPAIEMENT)
                    REFERENCES MODEPAIEMENT (ID),
                CONSTRAINT FK_CINEMA_ACHAT_VENTE FOREIGN KEY (IDVENTE)
                    REFERENCES VENTE (ID),
                CONSTRAINT FK_CINEMA_ACHAT_MVTCAISSE FOREIGN KEY (IDMOUVEMENTCAISSE)
                    REFERENCES MOUVEMENTCAISSE (ID)
            )';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 3. Billets individuels
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_BILLET';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_BILLET (
                ID                  VARCHAR2(100) NOT NULL,
                IDMERE              VARCHAR2(100) NOT NULL,
                IDPLACE             VARCHAR2(100) NOT NULL,
                IDCATEGORIEPLACE    VARCHAR2(100),
                PRIX                NUMBER DEFAULT 0,
                NUMERO              VARCHAR2(50) NOT NULL,
                DATYUTILISATION     DATE,
                STATUT              NUMBER(2) DEFAULT 1,
                ETAT                NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_BILLET PRIMARY KEY (ID),
                CONSTRAINT UQ_CINEMA_BILLET_NUM UNIQUE (NUMERO),
                CONSTRAINT UQ_CINEMA_BILLET_PLACE UNIQUE (IDMERE, IDPLACE),
                CONSTRAINT FK_CINEMA_BILLET_ACHAT FOREIGN KEY (IDMERE)
                    REFERENCES CINEMA_ACHATBILLET (ID),
                CONSTRAINT FK_CINEMA_BILLET_PLACE FOREIGN KEY (IDPLACE)
                    REFERENCES CINEMA_PLACE (ID),
                CONSTRAINT FK_CINEMA_BILLET_CAT FOREIGN KEY (IDCATEGORIEPLACE)
                    REFERENCES CINEMA_CATEGORIEPLACE (ID)
            )';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 4. Detail des reservations
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_RESERVATIONDETAIL';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_RESERVATIONDETAIL (
                ID                  VARCHAR2(100) NOT NULL,
                IDMERE              VARCHAR2(100) NOT NULL,
                IDPLACE             VARCHAR2(100) NOT NULL,
                IDCATEGORIEPLACE    VARCHAR2(100),
                PRIX                NUMBER DEFAULT 0,
                IDBILLET            VARCHAR2(100),
                ETAT                NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_RESDETAIL PRIMARY KEY (ID),
                CONSTRAINT UQ_CINEMA_RESDETAIL_PLACE UNIQUE (IDMERE, IDPLACE),
                CONSTRAINT FK_CINEMA_RESDETAIL_MERE FOREIGN KEY (IDMERE)
                    REFERENCES CINEMA_RESERVATION (ID),
                CONSTRAINT FK_CINEMA_RESDETAIL_PLACE FOREIGN KEY (IDPLACE)
                    REFERENCES CINEMA_PLACE (ID),
                CONSTRAINT FK_CINEMA_RESDETAIL_CAT FOREIGN KEY (IDCATEGORIEPLACE)
                    REFERENCES CINEMA_CATEGORIEPLACE (ID)
            )';
    END IF;
END;
/

-- ---------------------------------------------------------------------
-- 5. FK differee IDBILLET -> CINEMA_BILLET
--    (ajoutee apres la creation des deux tables pour eviter le cycle)
-- ---------------------------------------------------------------------
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_constraints
     WHERE constraint_name = 'FK_CINEMA_RESDETAIL_BILLET';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            ALTER TABLE CINEMA_RESERVATIONDETAIL
                ADD CONSTRAINT FK_CINEMA_RESDETAIL_BILLET
                FOREIGN KEY (IDBILLET) REFERENCES CINEMA_BILLET (ID)';
    END IF;
END;
/

COMMIT;
