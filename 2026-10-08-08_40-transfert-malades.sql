-- TODO-POUSSINS etape 6 : malades a l'arrivee au parquet
ALTER TABLE TRANSFERTPOULETDETAIL ADD (NBMALADES NUMBER);
COMMENT ON COLUMN TRANSFERTPOULETDETAIL.NBMALADES IS 'Malades constates a l arrivee (<= qte transferee)';

-- Vue lib : exposer NBMALADES (liste colonnes en dur)
-- CREATE OR REPLACE VIEW TRANSFERTPOULETDETAIL_LIB AS SELECT ..., td.NBMALADES, ... (applique 08/10/2026)

-- Java : TransfertPouletDetail.nbMalades + controle malades<=qte au createObject.
-- JSP : transfertpoulet-saisie, champ "Malades a l'arrivee".
-- Separation males/femelles : 1 ligne par sexe+parquet (idSexe + idParquetArrive).
