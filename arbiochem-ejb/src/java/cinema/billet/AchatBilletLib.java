package cinema.billet;

/**
 * Vue d'affichage des achats de billets.
 */
public class AchatBilletLib extends AchatBillet {

    private String idClientLib;
    private String idProjectionLib;
    private String idFilmLib;
    private String idSalleLib;
    private String etatLib;
    private int nbBilletsLib;

    public AchatBilletLib() throws Exception {
        super();
        super.setNomTable("CINEMA_ACHATBILLET_LIB");
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

    public int getNbBilletsLib() {
        return nbBilletsLib;
    }

    public void setNbBilletsLib(int nbBilletsLib) {
        this.nbBilletsLib = nbBilletsLib;
    }
}
