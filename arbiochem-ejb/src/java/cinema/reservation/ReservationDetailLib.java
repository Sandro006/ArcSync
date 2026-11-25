package cinema.reservation;

/**
 * Vue d'affichage des lignes de reservation.
 */
public class ReservationDetailLib extends ReservationDetail {

    private String idPlaceLib;
    private String idCategoriePlaceLib;
    private String idBilletLib;
    private String etatLib;

    public ReservationDetailLib() throws Exception {
        super();
        super.setNomTable("CINEMA_RESERVATIONDETAIL_LIB");
    }

    public String getIdPlaceLib() {
        return idPlaceLib;
    }

    public void setIdPlaceLib(String idPlaceLib) {
        this.idPlaceLib = idPlaceLib;
    }

    public String getIdCategoriePlaceLib() {
        return idCategoriePlaceLib;
    }

    public void setIdCategoriePlaceLib(String idCategoriePlaceLib) {
        this.idCategoriePlaceLib = idCategoriePlaceLib;
    }

    public String getIdBilletLib() {
        return idBilletLib;
    }

    public void setIdBilletLib(String idBilletLib) {
        this.idBilletLib = idBilletLib;
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }
}
