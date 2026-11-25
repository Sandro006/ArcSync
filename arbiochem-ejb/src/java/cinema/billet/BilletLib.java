package cinema.billet;

/**
 * Vue d'affichage des billets.
 */
public class BilletLib extends Billet {

    private String idPlaceLib;
    private String idCategoriePlaceLib;
    private String idAchatBilletLib;
    private String idProjectionLib;
    private String idFilmLib;
    private String statutLib;
    private String etatLib;

    public BilletLib() throws Exception {
        super();
        super.setNomTable("CINEMA_BILLET_LIB");
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

    public String getIdAchatBilletLib() {
        return idAchatBilletLib;
    }

    public void setIdAchatBilletLib(String idAchatBilletLib) {
        this.idAchatBilletLib = idAchatBilletLib;
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

    public String getStatutLib() {
        return statutLib;
    }

    public void setStatutLib(String statutLib) {
        this.statutLib = statutLib;
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }
}
