package cinema.configuration;

/**
 * Vue d'affichage des categories de place.
 */
public class CategoriePlaceLib extends CategoriePlace {

    private String etatLib;

    public CategoriePlaceLib() {
        super();
        super.setNomTable("CINEMA_CATEGORIEPLACE_LIB");
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }
}
