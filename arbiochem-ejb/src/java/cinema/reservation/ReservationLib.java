package cinema.reservation;

/**
 * Vue d'affichage des reservations.
 */
public class ReservationLib extends Reservation {

    private String idClientLib;
    private String idProjectionLib;
    private String idFilmLib;
    private String idSalleLib;
    private String etatLib;
    private String statutLib;
    private int nbPlacesLib;
    private double montantTotalLib;
    private double resteAPayerLib;

    public ReservationLib() throws Exception {
        super();
        super.setNomTable("CINEMA_RESERVATION_LIB");
    }

    public String getIdClientLib() {
        return idClientLib;
    }

    public void setIdClientLib(String idClientLib) {
        this.idClientLib = idClientLib;
    }

    public String getIdProjectionLib() {
        return idProjectionLib;
    }

    public void setIdProjectionLib(String idProjectionLib) {
        this.idProjectionLib = idProjectionLib;
    }

    public String getIdFilmLib() {
        return idFilmLib;
    }

    public void setIdFilmLib(String idFilmLib) {
        this.idFilmLib = idFilmLib;
    }

    public String getIdSalleLib() {
        return idSalleLib;
    }

    public void setIdSalleLib(String idSalleLib) {
        this.idSalleLib = idSalleLib;
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }

    public String getStatutLib() {
        return statutLib;
    }

    public void setStatutLib(String statutLib) {
        this.statutLib = statutLib;
    }

    public int getNbPlacesLib() {
        return nbPlacesLib;
    }

    public void setNbPlacesLib(int nbPlacesLib) {
        this.nbPlacesLib = nbPlacesLib;
    }

    public double getMontantTotalLib() {
        return montantTotalLib;
    }

    public void setMontantTotalLib(double montantTotalLib) {
        this.montantTotalLib = montantTotalLib;
    }

    public double getResteAPayerLib() {
        return resteAPayerLib;
    }

    public void setResteAPayerLib(double resteAPayerLib) {
        this.resteAPayerLib = resteAPayerLib;
    }
}
