package cinema.configuration;

/**
 * Vue d'affichage des places.
 */
public class PlaceLib extends Place {

    private String salleLib;
    private String idCategoriePlaceLib;
    private String etatLib;

    public PlaceLib() throws Exception {
        super();
        super.setNomTable("CINEMA_PLACE_LIB");
    }

    public String getSalleLib() {
        return salleLib;
    }

    public void setSalleLib(String salleLib) {
        this.salleLib = salleLib;
    }

    public String getIdCategoriePlaceLib() {
        return idCategoriePlaceLib;
    }

    public void setIdCategoriePlaceLib(String idCategoriePlaceLib) {
        this.idCategoriePlaceLib = idCategoriePlaceLib;
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }
}
