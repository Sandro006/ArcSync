-- =====================================================================
-- Module Cinema - films
-- Idempotent : peut etre rejoue sans effet de bord.
-- =====================================================================
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_FILM';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_FILM (
                ID              VARCHAR2(100) NOT NULL,
                TITRE           VARCHAR2(300) NOT NULL,
                TITREORIGINAL   VARCHAR2(300),
                IDGENRE         VARCHAR2(100),
                DUREE           NUMBER(4),
                LANGUE          VARCHAR2(100),
                ANNEE           NUMBER(4),
                REALISATEUR     VARCHAR2(200),
                ACTEURS         VARCHAR2(1000),
                CLASSIFICATION  VARCHAR2(20),
                SYNOPSIS        VARCHAR2(4000),
                AFFICHE         VARCHAR2(500),
                DATY            DATE DEFAULT SYSDATE,
                ETAT            NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_FILM PRIMARY KEY (ID),
                CONSTRAINT FK_CINEMA_FILM_GENRE FOREIGN KEY (IDGENRE)
                    REFERENCES CINEMA_GENRE (ID)
            )';
    END IF;
END;
/

COMMIT;
