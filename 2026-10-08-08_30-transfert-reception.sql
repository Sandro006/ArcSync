-- TODO-POUSSINS etape 5 : voyage vers batiments trace depuis la reception
ALTER TABLE TRANSFERTPOULET ADD (IDRECEPTION VARCHAR2(50));
COMMENT ON COLUMN TRANSFERTPOULET.IDRECEPTION IS 'Reception aeroport d origine (FK RECEPTIONPOUSSINAEROPORT.ID)';

-- Java : TransfertPoulet.idReception.
-- JSP : transfertpoulet-saisie accepte ?idLot=&idReception= (pre-remplis readonly),
--       bouton "Voyage vers batiments (BL interne)" sur receptionaeroport-fiche (etat valide).
-- Ce transfert Ferme/Batiment/Parquet depart->arrivee fait office de BL interne.
