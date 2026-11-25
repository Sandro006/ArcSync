package cinema.reservation;

import bean.ClassFille;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;

/**
 * Ligne de reservation : une place et son prix.
 */
public class ReservationDetail extends ClassFille {

    private String id;
    private String idMere;
    private String idPlace;
    private String idCategoriePlace;
    private double prix;
    private String idBillet;
    private int etat = ConstanteCinema.ETAT_CREER;

    public ReservationDetail() throws Exception {
        super.setNomTable("CINEMA_RESERVATIONDETAIL");
        this.setNomClasseMere("cinema.reservation.Reservation");
        this.setLiaisonMere("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CRSD", "GETSEQCINEMARESERVATIONDETAIL");
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
    public String getNomClasseMere() {
        return "cinema.reservation.Reservation";
    }

    @Override
    public String getLiaisonMere() {
        return "idMere";
    }

    /**
     * Verifie que la place existe, est active et appartient bien a la salle de
     * la projection de la reservation.
     */
    public void controlerPlace(Connection c) throws Exception {
        if (idPlace == null || idPlace.trim().isEmpty()) {
            throw new Exception("La place de la ligne de reservation est obligatoire.");
        }
        String idSalle = CinemaDb.getString(c,
                "SELECT pr.IDSALLE FROM CINEMA_RESERVATION r"
                + " JOIN CINEMA_PROJECTION pr ON pr.ID = r.IDPROJECTION"
                + " WHERE r.ID = ?", idMere);
        if (idSalle == null) {
            throw new Exception("Reservation introuvable : " + idMere);
        }
        int ok = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_PLACE WHERE ID = ? AND IDMERE = ? AND ETAT = 1",
                idPlace, idSalle);
        if (ok == 0) {
            throw new Exception("La place " + idPlace + " n'appartient pas a la salle de la projection.");
        }
    }

    public boolean estConverti() {
        return idBillet != null && !idBillet.trim().isEmpty();
    }

    public void marquerConverti(String idBillet) throws Exception {
        this.idBillet = idBillet;
        this.etat = ConstanteCinema.ETAT_CLOTURE;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdMere() {
        return idMere;
    }

    public void setIdMere(String idMere) {
        this.idMere = idMere;
    }

    public String getIdPlace() {
        return idPlace;
    }

    public void setIdPlace(String idPlace) {
        this.idPlace = idPlace;
    }

    public String getIdCategoriePlace() {
        return idCategoriePlace;
    }

    public void setIdCategoriePlace(String idCategoriePlace) {
        this.idCategoriePlace = idCategoriePlace;
    }

    public double getPrix() {
        return prix;
    }

    public void setPrix(double prix) {
        this.prix = prix;
    }

    public String getIdBillet() {
        return idBillet;
    }

    public void setIdBillet(String idBillet) {
        this.idBillet = idBillet;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
