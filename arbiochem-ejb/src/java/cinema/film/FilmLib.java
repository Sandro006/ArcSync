package cinema.film;

/**
 * Vue d'affichage des films.
 */
public class FilmLib extends Film {

    private String idGenreLib;
    private String etatLib;

    public FilmLib() throws Exception {
        super();
        super.setNomTable("CINEMA_FILM_LIB");
    }

    public String getIdGenreLib() {
        return idGenreLib;
    }

    public void setIdGenreLib(String idGenreLib) {
        this.idGenreLib = idGenreLib;
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }
}
