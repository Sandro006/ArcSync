package cinema.projection;

/**
 * Vue d'affichage des projections (film, salle, remplissage, recette).
 */
public class ProjectionLib extends Projection {

    private String idFilmLib;
    private String idGenreLib;
    private String idSalleLib;
    private String etatLib;
    private String statutLib;
    private int nbPlacesVendues;
    private int nbPlacesReservees;
    private int nbPlacesDisponibles;
    private double recette;

    public ProjectionLib() throws Exception {
        super();
        super.setNomTable("CINEMA_PROJECTION_LIB");
    }

    public String getIdFilmLib() {
        return idFilmLib;
    }

    public void setIdFilmLib(String idFilmLib) {
        this.idFilmLib = idFilmLib;
    }

    public String getIdGenreLib() {
        return idGenreLib;
    }

    public void setIdGenreLib(String idGenreLib) {
        this.idGenreLib = idGenreLib;
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

    public int getNbPlacesVendues() {
        return nbPlacesVendues;
    }

    public void setNbPlacesVendues(int nbPlacesVendues) {
        this.nbPlacesVendues = nbPlacesVendues;
    }

    public int getNbPlacesReservees() {
        return nbPlacesReservees;
    }

    public void setNbPlacesReservees(int nbPlacesReservees) {
        this.nbPlacesReservees = nbPlacesReservees;
    }

    public int getNbPlacesDisponibles() {
        return nbPlacesDisponibles;
    }

    public void setNbPlacesDisponibles(int nbPlacesDisponibles) {
        this.nbPlacesDisponibles = nbPlacesDisponibles;
    }

    public double getRecette() {
        return recette;
    }

    public void setRecette(double recette) {
        this.recette = recette;
    }
}
