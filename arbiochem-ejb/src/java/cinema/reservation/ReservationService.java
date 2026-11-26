package cinema.reservation;

import bean.CGenUtil;
import cinema.billet.AchatBilletService;
import cinema.billet.Billet;
import cinema.projection.Projection;
import cinema.projection.ProjectionService;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import utilitaire.UtilDB;

/**
 * Reservations de places : creation, confirmation, expiration et conversion en
 * billets.
 */
public class ReservationService {

    public static class LigneReservation {
        public String idPlace;
        public String idCategoriePlace;

        public LigneReservation() {
        }

        public LigneReservation(String idPlace, String idCategoriePlace) {
            this.idPlace = idPlace;
            this.idCategoriePlace = idCategoriePlace;
        }
    }

    public static class Resultat {
        public String idReservation;
        public double montantTotal;
        public double montantRemise;
        public double acompte;
        public Timestamp dateExpiration;
        public List<String> idDetails = new ArrayList<String>();

        public Resultat() {
        }
    }

    public static Resultat reserver(String u, String idClient, String idProjection,
            List<LigneReservation> places, double acompte, Timestamp dateExpiration,
            String remarque) throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            Resultat r = reserver(c, u, idClient, idProjection, places, acompte,
                    dateExpiration, remarque);
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

    public static Resultat reserver(Connection c, String u, String idClient,
            String idProjection, List<LigneReservation> places, double acompte,
            Timestamp dateExpiration, String remarque) throws Exception {

        if (places == null || places.isEmpty()) {
            throw new Exception("Au moins une place est obligatoire pour reserver.");
        }
        if (idClient == null || idClient.trim().isEmpty()) {
            throw new Exception("Client obligatoire pour une reservation.");
        }
        if (CinemaDb.getInt(c, "SELECT COUNT(*) FROM CLIENT WHERE ID = ?", idClient) == 0) {
            throw new Exception("Client introuvable : " + idClient);
        }

        Projection p = ProjectionService.charger(idProjection, c);
        if (!p.estOuverte()) {
            throw new Exception("La projection n'est pas ouverte a la vente.");
        }
        if (!p.estFuture()) {
            throw new Exception("La projection est deja passee.");
        }

        Reservation r = new Reservation();
        r.setDaty(CinemaDb.today());
        r.setIdClient(idClient);
        r.setIdProjection(idProjection);
        r.setMontantAcompte(acompte);
        r.setStatut(ConstanteCinema.STATUT_RESERVATION_EN_ATTENTE);
        r.setEtat(ConstanteCinema.ETAT_CREER);
        r.setRemarque(remarque);
        r.setDateExpiration(dateExpiration != null
                ? dateExpiration
                : CinemaDb.addMinutes(CinemaDb.now(), ConstanteCinema.DUREE_RESERVATION_MINUTES));

        ReservationDetail[] details = new ReservationDetail[places.size()];
        for (int i = 0; i < places.size(); i++) {
            LigneReservation lp = places.get(i);
            String categorie = lp.idCategoriePlace;
            if (categorie == null || categorie.trim().isEmpty()) {
                categorie = CinemaDb.getString(c,
                        "SELECT IDCATEGORIEPLACE FROM CINEMA_PLACE WHERE ID = ?", lp.idPlace);
            }
            ReservationDetail d = new ReservationDetail();
            d.setIdPlace(lp.idPlace);
            d.setIdCategoriePlace(categorie);
            d.setPrix(ProjectionService.getPrixPlace(idProjection, lp.idPlace, c));
            d.setEtat(ConstanteCinema.ETAT_CREER);
            details[i] = d;
        }
        r.setFille(details);

        // Regles de remise configurees (CINEMA_REMISE). Une seule regle au plus
        // est appliquee a la reservation.
        double montantRemise = RemiseService.appliquer(details, c);
        r.setMontantRemise(montantRemise);

        Reservation cree = (Reservation) r.createObject(u, c);
        Resultat res = new Resultat();
        res.idReservation = (cree != null && cree.getId() != null) ? cree.getId() : r.getId();
        res.montantTotal = r.getMontantTotal();
        res.acompte = acompte;
        res.montantRemise = montantRemise;
        res.dateExpiration = r.getDateExpiration();
        for (int i = 0; i < details.length; i++) {
            res.idDetails.add(details[i].getId());
        }
        return res;
    }

    public static void confirmer(String u, String idReservation) throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            confirmer(c, u, idReservation);
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

    public static void confirmer(Connection c, String u, String idReservation) throws Exception {
        Reservation r = charger(idReservation, c);
        if (r.getStatut() == ConstanteCinema.STATUT_RESERVATION_ANNULEE
                || r.getStatut() == ConstanteCinema.STATUT_RESERVATION_CONVERTIE) {
            throw new Exception("Cette reservation ne peut plus etre confirmee.");
        }
        if (r.estExpiree()) {
            throw new Exception("Cette reservation est expiree.");
        }
        r.controlerProjection(c);
        r.validerObject(u, c);
    }

    public static void annuler(String u, String idReservation) throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            annuler(c, u, idReservation);
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

    public static void annuler(Connection c, String u, String idReservation) throws Exception {
        Reservation r = charger(idReservation, c);
        r.annulerObject(u, c);
    }

    public static int expirerReservations(Connection c) throws Exception {
        List<String> ids = new ArrayList<String>();
        java.sql.PreparedStatement ps = null;
        java.sql.ResultSet rs = null;
        try {
            ps = c.prepareStatement(
                    "SELECT ID FROM CINEMA_RESERVATION"
                    + " WHERE ETAT IN (1,11) AND STATUT IN (1,2)"
                    + " AND DATEEXPIRATION IS NOT NULL AND DATEEXPIRATION < SYSDATE");
            rs = ps.executeQuery();
            while (rs.next()) {
                ids.add(rs.getString(1));
            }
        } finally {
            CinemaDb.close(rs);
            CinemaDb.close(ps);
        }
        for (int i = 0; i < ids.size(); i++) {
            String id = ids.get(i);
            CinemaDb.execute(c,
                    "UPDATE CINEMA_RESERVATION SET STATUT = ?, ETAT = ? WHERE ID = ?",
                    Integer.valueOf(ConstanteCinema.STATUT_RESERVATION_EXPIREE),
                    Integer.valueOf(ConstanteCinema.ETAT_CLOTURE), id);
            CinemaDb.execute(c,
                    "UPDATE CINEMA_RESERVATIONDETAIL SET ETAT = ? WHERE IDMERE = ?",
                    Integer.valueOf(ConstanteCinema.ETAT_ANNULE), id);
        }
        return ids.size();
    }

    public static AchatBilletService.Resultat convertirEnBillet(String u,
            String idReservation, String modepaiement, String idCaisse) throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            AchatBilletService.Resultat r = convertirEnBillet(c, u, idReservation,
                    modepaiement, idCaisse);
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

    public static AchatBilletService.Resultat convertirEnBillet(Connection c, String u,
            String idReservation, String modepaiement, String idCaisse) throws Exception {
        Reservation r = charger(idReservation, c);
        if (!r.estActive()) {
            throw new Exception("Cette reservation n'est pas active.");
        }
        if (r.estExpiree()) {
            throw new Exception("Cette reservation est expiree.");
        }
        ReservationDetail critere = new ReservationDetail();
        ReservationDetail[] details = (ReservationDetail[]) CGenUtil.rechercher(critere,
                null, null, c, " AND IDMERE = '" + esc(idReservation) + "'"
                + " AND ETAT IN (1,11) ORDER BY ID");
        if (details.length == 0) {
            throw new Exception("Aucune place active dans cette reservation.");
        }

        List<AchatBilletService.LigneBillet> lignes =
                new ArrayList<AchatBilletService.LigneBillet>();
        for (int i = 0; i < details.length; i++) {
            // Prix deja fige a la creation (remise eventuelle incluse) : ne pas
            // le recalculer, meme s'il vaut 0 apres une remise de 100 %.
            lignes.add(new AchatBilletService.LigneBillet(details[i].getIdPlace(),
                    details[i].getIdCategoriePlace(), details[i].getPrix(), true));
        }

        AchatBilletService.Resultat achat = AchatBilletService.acheter(c, u,
                r.getIdClient(), r.getIdProjection(), idReservation, lignes,
                modepaiement, idCaisse, "Conversion reservation " + idReservation);

        Billet[] billets = AchatBilletService.getBillets(achat.idAchat, c);
        for (int i = 0; i < details.length; i++) {
            String idBillet = null;
            for (int j = 0; j < billets.length; j++) {
                if (details[i].getIdPlace().equals(billets[j].getIdPlace())) {
                    idBillet = billets[j].getId();
                    break;
                }
            }
            if (idBillet != null) {
                CinemaDb.execute(c,
                        "UPDATE CINEMA_RESERVATIONDETAIL SET IDBILLET = ?, ETAT = ? WHERE ID = ?",
                        idBillet, Integer.valueOf(ConstanteCinema.ETAT_CLOTURE),
                        details[i].getId());
            }
        }
        CinemaDb.execute(c,
                "UPDATE CINEMA_RESERVATION SET STATUT = ?, ETAT = ? WHERE ID = ?",
                Integer.valueOf(ConstanteCinema.STATUT_RESERVATION_CONVERTIE),
                Integer.valueOf(ConstanteCinema.ETAT_CLOTURE), idReservation);
        return achat;
    }

    public static boolean placeDisponible(String idProjection, String idPlace,
            Connection c) throws Exception {
        return CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE"
                + " WHERE IDPROJECTION = ? AND IDPLACE = ?", idProjection, idPlace) == 0;
    }

    public static Reservation[] getReservationsActives(String idClient,
            Connection c) throws Exception {
        Reservation critere = new Reservation();
        return (Reservation[]) CGenUtil.rechercher(critere, null, null, c,
                " AND IDCLIENT = '" + esc(idClient) + "'"
                + " AND ETAT IN (1,11) AND STATUT IN (1,2) ORDER BY DATY DESC");
    }

    public static Reservation[] getReservationsAExpirer(Connection c) throws Exception {
        Reservation critere = new Reservation();
        return (Reservation[]) CGenUtil.rechercher(critere, null, null, c,
                " AND ETAT IN (1,11) AND STATUT IN (1,2)"
                + " AND DATEEXPIRATION IS NOT NULL AND DATEEXPIRATION < SYSDATE"
                + " ORDER BY DATEEXPIRATION");
    }

    public static Reservation charger(String idReservation, Connection c) throws Exception {
        Reservation r = (Reservation) new Reservation().getById(idReservation,
                "CINEMA_RESERVATION", c);
        if (r == null || r.getId() == null) {
            throw new Exception("Reservation introuvable : " + idReservation);
        }
        return r;
    }

    private static String esc(String v) {
        return v == null ? "" : v.replace("'", "''");
    }
}
