package cinema.configuration;

import bean.TypeObjet;
import java.sql.Connection;

/**
 * Genre cinematographique (referentiel simple).
 */
public class Genre extends TypeObjet {

    private int etat = 1;

    public Genre() {
        super.setNomTable("CINEMA_GENRE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        super.setNomTable("CINEMA_GENRE");
        this.preparePk("CGR", "GETSEQCINEMAGENRE");
        this.setId(this.makePK(c));
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }

    public String getLibelle() {
        return getVal();
    }
}
