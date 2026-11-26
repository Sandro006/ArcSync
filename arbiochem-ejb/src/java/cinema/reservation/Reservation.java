package cinema.reservation;

import bean.ClassMAPTable;
import bean.ClassMere;
import cinema.projection.Projection;
import cinema.projection.ProjectionService;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;
import java.sql.Date;
import java.sql.Timestamp;

/**
 * Reservation de places pour une projection.
 */
public class Reservation extends ClassMere {

    private String id;
    private Date daty;
    private String idClient;
    private String idProjection;
    private Timestamp dateExpiration;
    private double montantAcompte;
    private double montantRemise;
    private int statut = ConstanteCinema.STATUT_RESERVATION_EN_ATTENTE;
    private String remarque;
    private int etat = ConstanteCinema.ETAT_CREER;

    public Reservation() throws Exception {
        super.setNomTable("CINEMA_RESERVATION");
        this.setNomClasseFille("cinema.reservation.ReservationDetail");
        this.setLiaisonFille("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CRS", "GETSEQCINEMARESERVATION");
        this.setId(this.makePK(c));
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public String getNomClasseFille() {
        return "cinema.reservation.ReservationDetail";
    }

    @Override
    public String getLiaisonFille() {
        return "idMere";
    }

    public void controlerProjection(Connection c) throws Exception {
        if (idProjection == null || idProjection.trim().isEmpty()) {
            throw new Exception("La projection de la reservation est obligatoire.");
        }
        Projection p = ProjectionService.charger(idProjection, c);
        if (!p.estOuverte()) {
            throw new Exception("La projection n'est pas ouverte a la vente.");
        }
        if (!p.estFuture()) {
            throw new Exception("La projection est deja passee.");
        }
    }

    public void controlerPlaces(Connection c) throws Exception {
        if (getFille() == null || getFille().length == 0) {
            throw new Exception("Au moins une place est obligatoire pour une reservation.");
        }
        String idSalle = CinemaDb.getString(c,
                "SELECT IDSALLE FROM CINEMA_PROJECTION WHERE ID = ?", idProjection);
        if (idSalle == null) {
            throw new Exception("Projection introuvable : " + idProjection);
        }
        for (int i = 0; i < getFille().length; i++) {
            ReservationDetail d = (ReservationDetail) getFille()[i];
            if (d.getIdPlace() == null || d.getIdPlace().trim().isEmpty()) {
                throw new Exception("Chaque ligne de reservation doit reference une place.");
            }
            String categorie = CinemaDb.getString(c,
                    "SELECT IDCATEGORIEPLACE FROM CINEMA_PLACE"
                    + " WHERE ID = ? AND IDMERE = ? AND ETAT = 1",
                    d.getIdPlace(), idSalle);
            if (categorie == null) {
                throw new Exception("Place invalide ou inactive pour cette salle : " + d.getIdPlace());
            }
            if (d.getIdCategoriePlace() == null || d.getIdCategoriePlace().trim().isEmpty()) {
                d.setIdCategoriePlace(categorie);
            }
            // Oracle traite '' comme NULL : "IDORIGINE = ''" devient
            // "IDORIGINE = NULL" (jamais vrai), le NOT (...) vaut alors
            // UNKNOWN et la place existante n'est plus comptee. A la creation
            // (id == null) il ne faut donc pas ajouter du tout l'exclusion.
            String exclusion = (id == null || id.trim().isEmpty())
                    ? "" : " AND NOT (TYPE_OCCUPATION = 'RESERVATION' AND IDORIGINE = ?)";
            String sql = "SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE"
                    + " WHERE IDPROJECTION = ? AND IDPLACE = ?" + exclusion;
            int occupee;
            if (exclusion.isEmpty()) {
                occupee = CinemaDb.getInt(c, sql, idProjection, d.getIdPlace());
            } else {
                occupee = CinemaDb.getInt(c, sql, idProjection, d.getIdPlace(), id);
            }
            if (occupee > 0) {
                throw new Exception("La place " + d.getIdPlace() + " est deja occupee.");
            }
            if (d.getPrix() <= 0 && !aUneRemise(d)) {
                d.setPrix(ProjectionService.getPrixPlace(idProjection, d.getIdPlace(), c));
            }
            d.setEtat(ConstanteCinema.ETAT_CREER);
        }
    }

    public void controlerExpiration() throws Exception {
        if (dateExpiration == null) {
            throw new Exception("La date d'expiration de la reservation est obligatoire.");
        }
        Timestamp base = (daty == null) ? CinemaDb.now() : new Timestamp(daty.getTime());
        if (!dateExpiration.after(base)) {
            throw new Exception("La date d'expiration doit etre posterieure a la date de reservation.");
        }
    }

    public boolean estExpiree() {
        return dateExpiration != null && dateExpiration.before(CinemaDb.now());
    }

    /** Vrai si la ligne a deja recu une remise (prix net eventuellement nul). */
    private boolean aUneRemise(ReservationDetail d) {
        return d.getIdRemise() != null && !d.getIdRemise().trim().isEmpty();
    }

    public boolean estActive() {
        return (etat == ConstanteCinema.ETAT_CREER || etat == ConstanteCinema.ETAT_VALIDER)
                && (statut == ConstanteCinema.STATUT_RESERVATION_EN_ATTENTE
                || statut == ConstanteCinema.STATUT_RESERVATION_CONFIRMEE);
    }

    public double getMontantTotal() {
        if (getFille() == null) {
            return 0;
        }
        double total = 0;
        for (int i = 0; i < getFille().length; i++) {
            ReservationDetail d = (ReservationDetail) getFille()[i];
            if (d.getEtat() != ConstanteCinema.ETAT_ANNULE) {
                total += d.getPrix();
            }
        }
        return total;
    }

    public double getResteAPayer() {
        return getMontantTotal() - montantAcompte;
    }

    public int getNbPlaces() {
        if (getFille() == null) {
            return 0;
        }
        int n = 0;
        for (int i = 0; i < getFille().length; i++) {
            ReservationDetail d = (ReservationDetail) getFille()[i];
            if (d.getEtat() != ConstanteCinema.ETAT_ANNULE) {
                n++;
            }
        }
        return n;
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        if (daty == null) {
            daty = CinemaDb.today();
        }
        this.controlerProjection(c);
        this.controlerExpiration();
        this.controlerPlaces(c);
        return super.createObject(u, c);
    }

    @Override
    public Object validerObject(String u, Connection c) throws Exception {
        this.statut = ConstanteCinema.STATUT_RESERVATION_CONFIRMEE;
        this.etat = ConstanteCinema.ETAT_VALIDER;
        Object o = super.validerObject(u, c);
        CinemaDb.execute(c, "UPDATE CINEMA_RESERVATIONDETAIL SET ETAT = ? WHERE IDMERE = ?",
                Integer.valueOf(ConstanteCinema.ETAT_VALIDER), id);
        return o;
    }

    @Override
    public Object annulerObject(String u, Connection c) throws Exception {
        this.statut = ConstanteCinema.STATUT_RESERVATION_ANNULEE;
        Object o = super.annulerObject(u, c);
        CinemaDb.execute(c, "UPDATE CINEMA_RESERVATIONDETAIL SET ETAT = ? WHERE IDMERE = ?",
                Integer.valueOf(ConstanteCinema.ETAT_ANNULE), id);
        return o;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public String getIdClient() {
        return idClient;
    }

    public void setIdClient(String idClient) {
        this.idClient = idClient;
    }

    public String getIdProjection() {
        return idProjection;
    }

    public void setIdProjection(String idProjection) {
        this.idProjection = idProjection;
    }

    public Timestamp getDateExpiration() {
        return dateExpiration;
    }

    public void setDateExpiration(Timestamp dateExpiration) {
        this.dateExpiration = dateExpiration;
    }

    public double getMontantAcompte() {
        return montantAcompte;
    }

    public void setMontantAcompte(double montantAcompte) {
        this.montantAcompte = montantAcompte;
    }

    public double getMontantRemise() {
        return montantRemise;
    }

    public void setMontantRemise(double montantRemise) {
        this.montantRemise = montantRemise;
    }

    public int getStatut() {
        return statut;
    }

    public void setStatut(int statut) {
        this.statut = statut;
    }

    public String getRemarque() {
        return remarque;
    }

    public void setRemarque(String remarque) {
        this.remarque = remarque;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
