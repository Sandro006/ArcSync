package cinema.configuration;

import bean.CGenUtil;
import bean.ClassMAPTable;
import bean.ClassMere;
import java.sql.Connection;

/**
 * Salle de cinema. Une salle contient des places (objet fille).
 */
public class Salle extends ClassMere {

    private String id;
    private String nom;
    private String adresse;
    private int capacite;
    private int etat = 1;

    public Salle() throws Exception {
        super.setNomTable("CINEMA_SALLE");
        this.setNomClasseFille("cinema.configuration.Place");
        this.setLiaisonFille("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CSA", "GETSEQCINEMASALLE");
        this.setId(this.makePK(c));
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public String getNomClasseFille() {
        return "cinema.configuration.Place";
    }

    @Override
    public String getLiaisonFille() {
        return "idMere";
    }

    /** Nombre de places actuellement chargees dans l'objet (0 si non charge). */
    public int getNbPlaces() {
        if (getFille() == null) {
            return 0;
        }
        return getFille().length;
    }

    /**
     * Verifie que la capacite est positive et que les places actives ne la
     * depassent pas.
     */
    public void controlerCapacite() throws Exception {
        if (capacite <= 0) {
            throw new Exception("La capacite de la salle doit etre strictement positive.");
        }
        if (getFille() != null) {
            int actives = 0;
            for (int i = 0; i < getFille().length; i++) {
                Place p = (Place) getFille()[i];
                if (p.estActive()) {
                    actives++;
                }
            }
            if (actives > capacite) {
                throw new Exception("Le nombre de places actives (" + actives
                        + ") depasse la capacite de la salle (" + capacite + ").");
            }
        }
    }

    public Place[] getPlacesActives(Connection c) throws Exception {
        Place critere = new Place();
        critere.setIdMere(this.getId());
        return (Place[]) CGenUtil.rechercher(critere, null, null, c,
                " AND IDMERE = '" + this.getId() + "' AND ETAT = 1 ORDER BY RANG, COLONNE, NUMERO");
    }

    public Place getPlace(String numero, Connection c) throws Exception {
        if (numero == null || numero.trim().isEmpty()) {
            return null;
        }
        Place critere = new Place();
        critere.setIdMere(this.getId());
        Place[] places = (Place[]) CGenUtil.rechercher(critere, null, null, c,
                " AND IDMERE = '" + this.getId() + "' AND NUMERO = '" + numero.replace("'", "''") + "'");
        return places.length > 0 ? places[0] : null;
    }

    @Override
    public void controler(Connection c) throws Exception {
        super.controler(c);
        this.controlerCapacite();
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        this.controlerCapacite();
        return super.createObject(u, c);
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getNom() {
        return nom;
    }

    public void setNom(String nom) {
        this.nom = nom;
    }

    public String getAdresse() {
        return adresse;
    }

    public void setAdresse(String adresse) {
        this.adresse = adresse;
    }

    public int getCapacite() {
        return capacite;
    }

    public void setCapacite(int capacite) {
        this.capacite = capacite;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
