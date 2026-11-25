-- =====================================================================
-- Module Cinema - index de performance
-- Idempotent : chaque index est cree s'il n'existe pas deja.
-- Un index deja couvert par une contrainte (ORA-01408) est ignore.
-- =====================================================================

DECLARE
    PROCEDURE creer_index(p_nom VARCHAR2, p_sql VARCHAR2) IS
        v_exists NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_exists
          FROM user_indexes
         WHERE index_name = p_nom;

        IF v_exists = 0 THEN
            BEGIN
                EXECUTE IMMEDIATE p_sql;
            EXCEPTION
                WHEN OTHERS THEN
                    -- ORA-01408 : liste de colonnes deja indexee
                    -- (index unique cree par une contrainte).
                    IF SQLCODE != -1408 THEN
                        RAISE;
                    END IF;
            END;
        END IF;
    END;
BEGIN
    creer_index('IDX_CINEMA_FILM_TITRE',
        'CREATE INDEX IDX_CINEMA_FILM_TITRE ON CINEMA_FILM (TITRE)');

    creer_index('IDX_CINEMA_PLACE_SALLE',
        'CREATE INDEX IDX_CINEMA_PLACE_SALLE ON CINEMA_PLACE (IDMERE, IDCATEGORIEPLACE)');

    creer_index('IDX_CINEMA_PROJ_DATE',
        'CREATE INDEX IDX_CINEMA_PROJ_DATE ON CINEMA_PROJECTION (DATY, IDSALLE)');

    creer_index('IDX_CINEMA_PROJ_FILM',
        'CREATE INDEX IDX_CINEMA_PROJ_FILM ON CINEMA_PROJECTION (IDFILM, DATY)');

    creer_index('IDX_CINEMA_PROJTARIF_RANG',
        'CREATE INDEX IDX_CINEMA_PROJTARIF_RANG ON CINEMA_PROJECTIONTARIF (IDMERE, RANG)');

    creer_index('IDX_CINEMA_RESERV_PROJ',
        'CREATE INDEX IDX_CINEMA_RESERV_PROJ ON CINEMA_RESERVATION (IDPROJECTION, STATUT)');

    creer_index('IDX_CINEMA_RESERV_CLIENT',
        'CREATE INDEX IDX_CINEMA_RESERV_CLIENT ON CINEMA_RESERVATION (IDCLIENT, DATY)');

    creer_index('IDX_CINEMA_ACHAT_PROJ',
        'CREATE INDEX IDX_CINEMA_ACHAT_PROJ ON CINEMA_ACHATBILLET (IDPROJECTION, ETAT)');

    creer_index('IDX_CINEMA_BILLET_NUMERO',
        'CREATE INDEX IDX_CINEMA_BILLET_NUMERO ON CINEMA_BILLET (NUMERO)');

    creer_index('IDX_CINEMA_BILLET_PROJ',
        'CREATE INDEX IDX_CINEMA_BILLET_PROJ ON CINEMA_BILLET (IDMERE, IDPLACE)');

    creer_index('IDX_CINEMA_RESDETAIL_MERE',
        'CREATE INDEX IDX_CINEMA_RESDETAIL_MERE ON CINEMA_RESERVATIONDETAIL (IDMERE, ETAT)');
END;
/

COMMIT;
