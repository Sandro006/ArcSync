package cinema.billet;

import bean.CGenUtil;
import cinema.projection.Projection;
import cinema.projection.ProjectionService;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import utilitaire.UtilDB;
import utilitaire.Utilitaire;

/**
 * Achat de billets, caisse et controle a l'entree.
 *
 * Chaque achat genere une facture VENTE et un mouvement de caisse dans la
 * meme transaction que les billets.
 */
public class AchatBilletService {

    public static class LigneBillet {
        public String idPlace;
        public String idCategoriePlace;
        public double prix;

        public LigneBillet() {
        }

        public LigneBillet(String idPlace, String idCategoriePlace, double prix) {
            this.idPlace = idPlace;
            this.idCategoriePlace = idCategoriePlace;
            this.prix = prix;
        }
    }

    public static class Resultat {
        public String idAchat;
        public String idVente;
        public String idMouvementCaisse;
        public double montantTotal;
        public double montantPaye;
        public double monnaieRendue;
        public int nbBillets;
        public List<String> idBillets = new ArrayList<String>();

        public Resultat() {
        }

        public String resume() {
            return "Achat " + idAchat + " - " + nbBillets + " billet(s) - "
                    + montantTotal + " Ar";
        }
    }

    // ------------------------------------------------------------------
    // Achat
    // ------------------------------------------------------------------
    public static Resultat acheter(String u, String idClient, String idProjection,
            List<LigneBillet> billets, String modepaiement, String idCaisse,
            String remarque) throws Exception {
        return acheter(u, idClient, idProjection, null, billets, modepaiement,
                idCaisse, remarque, -1);
    }

    public static Resultat acheter(String u, String idClient, String idProjection,
            String idReservation, List<LigneBillet> billets, String modepaiement,
            String idCaisse, String remarque) throws Exception {
        return acheter(u, idClient, idProjection, idReservation, billets, modepaiement,
                idCaisse, remarque, -1);
    }

    /**
     * Surcharge pratique pour la caisse : montantPaye negatif signifie
     * "paiement exact".
     */
    public static Resultat acheter(String u, String idClient, String idProjection,
            String idReservation, List<LigneBillet> billets, String modepaiement,
            String idCaisse, String remarque, double montantPaye) throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            Resultat r = acheter(c, u, idClient, idProjection, idReservation, billets,
                    modepaiement, idCaisse, remarque, montantPaye);
            c.commit();
            ok = true;
            return r;
        } finally {
            if (c != null) {
                if (!ok) {
                    try { c.rollback(); } catch (Exception ignore) {}
                }
                try { c.close(); } catch (Exception ignore) {}
            }
        }
    }

    public static Resultat acheter(Connection c, String u, String idClient,
            String idProjection, String idReservation, List<LigneBillet> billets,
            String modepaiement, String idCaisse, String remarque) throws Exception {
        return acheter(c, u, idClient, idProjection, idReservation, billets,
                modepaiement, idCaisse, remarque, -1);
    }

    public static Resultat acheter(Connection c, String u, String idClient,
            String idProjection, String idReservation, List<LigneBillet> billets,
            String modepaiement, String idCaisse, String remarque,
            double montantPaye) throws Exception {

        if (billets == null || billets.isEmpty()) {
            throw new Exception("Aucun billet a acheter.");
        }
        verifierClient(c, idClient);

        Projection p = ProjectionService.charger(idProjection, c);
        if (!p.estOuverte()) {
            throw new Exception("La projection n'est pas ouverte a la vente.");
        }
        if (!p.estFuture()) {
            throw new Exception("La projection est deja passee.");
        }

        AchatBillet achat = new AchatBillet();
        achat.setDaty(CinemaDb.today());
        achat.setIdClient(idClient);
        achat.setIdProjection(idProjection);
        achat.setIdReservation(emptyToNull(idReservation));
        achat.setModepaiement(emptyToNull(modepaiement));
        achat.setRemarque(remarque);
        achat.setEtat(ConstanteCinema.ETAT_CREER);

        Billet[] filles = new Billet[billets.size()];
        double total = 0;
        for (int i = 0; i < billets.size(); i++) {
            LigneBillet lb = billets.get(i);
            Billet b = new Billet();
            b.setIdPlace(lb.idPlace);
            String categorie = lb.idCategoriePlace;
            if (categorie == null || categorie.trim().isEmpty()) {
                categorie = CinemaDb.getString(c,
                        "SELECT IDCATEGORIEPLACE FROM CINEMA_PLACE WHERE ID = ?", lb.idPlace);
            }
            b.setIdCategoriePlace(categorie);
            double prix = lb.prix;
            if (prix <= 0) {
                prix = ProjectionService.getPrixPlace(idProjection, lb.idPlace, c);
            }
            b.setPrix(prix);
            b.setStatut(ConstanteCinema.STATUT_BILLET_VENDU);
            b.setEtat(ConstanteCinema.ETAT_CREER);
            filles[i] = b;
            total += prix;
        }
        achat.setFille(filles);
        achat.setMontantTotal(total);
        double paye = (montantPaye < 0) ? total : montantPaye;
        achat.setMontantPaye(paye);
        achat.setMonnaieRendue(paye - total > 0 ? paye - total : 0);

        AchatBillet cree = (AchatBillet) achat.createObject(u, c);
        Resultat res = new Resultat();
        res.idAchat = (cree != null && cree.getId() != null) ? cree.getId() : achat.getId();
        res.montantTotal = total;
        res.montantPaye = paye;
        res.monnaieRendue = achat.getMonnaieRendue();
        res.nbBillets = filles.length;
        for (int i = 0; i < filles.length; i++) {
            res.idBillets.add(filles[i].getId());
        }

        // Facture VENTE + mouvement de caisse
        String idVente = creerVente(c, u, res.idAchat, idClient, modepaiement,
                total, filles.length);
        String idMvt = creerMouvementCaisse(c, u, res.idAchat, idClient, idCaisse,
                modepaiement, total);
        achat.setIdVente(idVente);
        achat.setIdMouvementCaisse(idMvt);
        res.idVente = idVente;
        res.idMouvementCaisse = idMvt;

        // Ecriture explicite des references de caisse sur l'achat : la creation
        // de l'objet a eu lieu avant la generation de la facture.
        CinemaDb.execute(c,
                "UPDATE CINEMA_ACHATBILLET SET IDVENTE = ?, IDMOUVEMENTCAISSE = ?"
                + " WHERE ID = ?", idVente, idMvt, res.idAchat);

        // Validation : achat ETAT=11 et billets ETAT=11
        achat.validerObject(u, c);
        return res;
    }

    public static void annuler(String u, String idAchat) throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            annuler(c, u, idAchat);
            c.commit();
            ok = true;
        } finally {
            if (c != null) {
                if (!ok) {
                    try { c.rollback(); } catch (Exception ignore) {}
                }
                try { c.close(); } catch (Exception ignore) {}
            }
        }
    }

    public static void annuler(Connection c, String u, String idAchat) throws Exception {
        AchatBillet achat = (AchatBillet) new AchatBillet().getById(idAchat,
                "CINEMA_ACHATBILLET", c);
        if (achat == null || achat.getId() == null) {
            throw new Exception("Achat introuvable : " + idAchat);
        }
        achat.annulerObject(u, c);
    }

    // ------------------------------------------------------------------
    // Controle a l'entree
    // ------------------------------------------------------------------
    public static Billet validerEntree(String numero, Connection c) throws Exception {
        return validerEntree(numero, "system", c);
    }

    public static Billet validerEntree(String numero, String u, Connection c) throws Exception {
        if (numero == null || numero.trim().isEmpty()) {
            throw new Exception("Numero de billet obligatoire.");
        }
        String id = CinemaDb.getString(c,
                "SELECT ID FROM CINEMA_BILLET WHERE NUMERO = ?", numero.trim());
        if (id == null) {
            throw new Exception("Billet introuvable : " + numero);
        }
        Billet b = (Billet) new Billet().getById(id, "CINEMA_BILLET", c);
        if (!b.estValide()) {
            if (b.estUtilise()) {
                throw new Exception("Billet deja utilise le " + b.getDatyUtilisation() + ".");
            }
            throw new Exception("Billet non valide (etat=" + b.getEtat()
                    + ", statut=" + b.getStatut() + ").");
        }
        int okProjection = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_BILLET b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " JOIN CINEMA_PROJECTION pr ON pr.ID = ab.IDPROJECTION"
                + " WHERE b.ID = ? AND ab.ETAT = 11 AND pr.ETAT = 11"
                + " AND pr.STATUT = 2 AND pr.DATY = TRUNC(SYSDATE)", id);
        if (okProjection == 0) {
            throw new Exception("La projection de ce billet n'est pas ouverte aujourd'hui.");
        }
        b.marquerUtilise(c);
        return b;
    }

    public static Billet[] getBillets(String idAchat, Connection c) throws Exception {
        Billet critere = new Billet();
        return (Billet[]) CGenUtil.rechercher(critere, null, null, c,
                " AND IDMERE = '" + esc(idAchat) + "' ORDER BY NUMERO");
    }

    public static double getRecette(String idProjection, Connection c) throws Exception {
        return CinemaDb.getDouble(c,
                "SELECT NVL(SUM(b.PRIX),0) FROM CINEMA_BILLET b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " WHERE ab.IDPROJECTION = ? AND ab.ETAT = 11 AND b.ETAT = 11"
                + " AND b.STATUT IN (1,2)", idProjection);
    }

    public static String genererNumero(String idBillet) throws Exception {
        if (idBillet == null || idBillet.trim().isEmpty()) {
            throw new Exception("Identifiant de billet obligatoire.");
        }
        return ConstanteCinema.PREFIXE_NUMERO_BILLET + "-" + idBillet;
    }

    public static String getNumero(String idBillet, Connection c) throws Exception {
        return CinemaDb.getString(c,
                "SELECT NUMERO FROM CINEMA_BILLET WHERE ID = ?", idBillet);
    }

    public static void controlerPlace(String idProjection, String idPlace,
            Connection c) throws Exception {
        String idSalle = CinemaDb.getString(c,
                "SELECT IDSALLE FROM CINEMA_PROJECTION WHERE ID = ?", idProjection);
        if (idSalle == null) {
            throw new Exception("Projection introuvable : " + idProjection);
        }
        int active = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_PLACE WHERE ID = ? AND IDMERE = ? AND ETAT = 1",
                idPlace, idSalle);
        if (active == 0) {
            throw new Exception("Place invalide ou inactive : " + idPlace);
        }
        int occupee = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE"
                + " WHERE IDPROJECTION = ? AND IDPLACE = ?", idProjection, idPlace);
        if (occupee > 0) {
            throw new Exception("La place est deja occupee : " + idPlace);
        }
    }

    // ------------------------------------------------------------------
    // Caisse / facture
    // ------------------------------------------------------------------
    private static String creerVente(Connection c, String u, String idAchat,
            String idClient, String modepaiement, double total, int nbBillets) throws Exception {
        // Memes prefixes que vente.Vente / vente.VenteDetails (preparePk), afin
        // que les liens des pages existantes (startsWith("VNT")) restent valides.
        int seqVente = CinemaDb.getInt(c, "SELECT getSeqVente FROM DUAL");
        if (seqVente <= 0) {
            throw new Exception("Impossible de generer le numero de facture.");
        }
        String idVente = ConstanteCinema.PREFIXE_VENTE
                + Utilitaire.completerInt(ConstanteCinema.LONGUEUR_CLE, seqVente);
        int seqDetail = CinemaDb.getInt(c, "SELECT getSeqVenteDetails FROM DUAL");
        String idDetail = ConstanteCinema.PREFIXE_VENTE_DETAILS
                + Utilitaire.completerInt(ConstanteCinema.LONGUEUR_CLE, seqDetail);
        String idMagasin = resoudreMagasin(c);
        String numero = ConstanteCinema.PREFIXE_FACTURE + idVente;
        String designation = "Vente billets cinema " + idAchat;

        CinemaDb.execute(c,
                "INSERT INTO VENTE (ID, DESIGNATION, IDMAGASIN, DATY, REMARQUE, ETAT,"
                + " IDORIGINE, IDCLIENT, ESTPREVU, REFERENCEFACT, NUMEROFACTURE, IDMODEPAIEMENT)"
                + " VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                idVente, designation, idMagasin, CinemaDb.today(), designation,
                Integer.valueOf(ConstanteCinema.ETAT_VALIDER), idAchat, idClient,
                Integer.valueOf(0), "CINEMA", numero, emptyToNull(modepaiement));

        double pu = nbBillets > 0 ? total / nbBillets : 0;
        CinemaDb.execute(c,
                "INSERT INTO VENTE_DETAILS (ID, IDVENTE, IDPRODUIT, QTE, PU, TVA,"
                + " DESIGNATION, COMPTE, UNITE, MONTANT, IDDEVISE, TAUXDECHANGE)"
                + " VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                idDetail, idVente, ConstanteCinema.ARTICLE_BILLET,
                Double.valueOf(nbBillets), Double.valueOf(pu), Double.valueOf(0),
                designation, ConstanteCinema.COMPTE_VENTE_BILLET, "UNT00010",
                Double.valueOf(total), "AR", Double.valueOf(1));
        return idVente;
    }

    private static String creerMouvementCaisse(Connection c, String u, String idAchat,
            String idClient, String idCaisse, String modepaiement, double total) throws Exception {
        String caisse = emptyToNull(idCaisse);
        if (caisse == null) {
            caisse = CinemaDb.getString(c,
                    "SELECT ID FROM (SELECT ID FROM CAISSE WHERE ETAT = 1 ORDER BY ID) WHERE ROWNUM = 1");
        }
        if (caisse == null) {
            return null;
        }
        int seqMvt = CinemaDb.getInt(c, "SELECT GETSEQMOUVEMENTCAISSE FROM DUAL");
        if (seqMvt <= 0) {
            throw new Exception("Impossible de generer le mouvement de caisse.");
        }
        String idMvt = ConstanteCinema.PREFIXE_MOUVEMENTCAISSE
                + Utilitaire.completerInt(ConstanteCinema.LONGUEUR_CLE, seqMvt);
        CinemaDb.execute(c,
                "INSERT INTO MOUVEMENTCAISSE (ID, DESIGNATION, IDCAISSE, DATY, ETAT,"
                + " IDORIGINE, IDDEVISE, IDTIERS, COMPTE, IDMODEPAIEMENT, DEBIT, CREDIT, HEURE)"
                + " VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)",
                idMvt, "Vente billets cinema " + idAchat, caisse, CinemaDb.today(),
                Integer.valueOf(ConstanteCinema.ETAT_VALIDER), idAchat, "AR", idClient,
                ConstanteCinema.COMPTE_VENTE_BILLET, emptyToNull(modepaiement),
                Double.valueOf(0), Double.valueOf(total), CinemaDb.currentHeure());
        return idMvt;
    }

    private static String resoudreMagasin(Connection c) throws Exception {
        String id = CinemaDb.getString(c,
                "SELECT ID FROM MAGASIN WHERE ID = ?", ConstanteCinema.IDMAGASIN_DEFAUT);
        if (id != null) {
            return id;
        }
        id = CinemaDb.getString(c,
                "SELECT ID FROM (SELECT ID FROM MAGASIN ORDER BY ID) WHERE ROWNUM = 1");
        if (id == null) {
            throw new Exception("Aucun magasin disponible pour enregistrer la facture.");
        }
        return id;
    }

    private static void verifierClient(Connection c, String idClient) throws Exception {
        if (idClient == null || idClient.trim().isEmpty()) {
            return;
        }
        if (CinemaDb.getInt(c, "SELECT COUNT(*) FROM CLIENT WHERE ID = ?", idClient) == 0) {
            throw new Exception("Client introuvable : " + idClient);
        }
    }

    private static String emptyToNull(String v) {
        return (v == null || v.trim().isEmpty()) ? null : v.trim();
    }

    private static String esc(String v) {
        return v == null ? "" : v.replace("'", "''");
    }
}
