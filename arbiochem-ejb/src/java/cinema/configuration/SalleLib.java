package cinema.configuration;

/**
 * Vue d'affichage des salles.
 */
public class SalleLib extends Salle {

    private String etatLib;
    private int nbPlacesLib;

    public SalleLib() throws Exception {
        super();
        super.setNomTable("CINEMA_SALLE_LIB");
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }

    public int getNbPlacesLib() {
        return nbPlacesLib;
    }

    public void setNbPlacesLib(int nbPlacesLib) {
        this.nbPlacesLib = nbPlacesLib;
    }
}
