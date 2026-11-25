package cinema.configuration;

import bean.ClassFille;
import java.sql.Connection;

/**
 * Place physique d'une salle. Le numero affiche (A1, B12...) est unique dans
 * la salle.
 */
public class Place extends ClassFille {

    private String id;
    private String idMere;
    private String numero;
    private String rang;
    private int colonne;
    private String idCategoriePlace;
    private int etat = 1;

    public Place() throws Exception {
        super.setNomTable("CINEMA_PLACE");
        this.setNomClasseMere("cinema.configuration.Salle");
        this.setLiaisonMere("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CPL", "GETSEQCINEMAPLACE");
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
    public String getNomClasseMere() {
        return "cinema.configuration.Salle";
    }

    @Override
    public String getLiaisonMere() {
        return "idMere";
    }

    public String getLibelle() {
        String r = rang == null ? "" : rang.trim();
        String n = numero == null ? "" : numero.trim();
        if (r.isEmpty()) {
            return "Place " + n;
        }
        return "Rang " + r + " - Place " + n;
    }

    public boolean estActive() {
        return etat == 1;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdMere() {
        return idMere;
    }

    public void setIdMere(String idMere) {
        this.idMere = idMere;
    }

    public String getNumero() {
        return numero;
    }

    public void setNumero(String numero) {
        this.numero = numero;
    }

    public String getRang() {
        return rang;
    }

    public void setRang(String rang) {
        this.rang = rang;
    }

    public int getColonne() {
        return colonne;
    }

    public void setColonne(int colonne) {
        this.colonne = colonne;
    }

    public String getIdCategoriePlace() {
        return idCategoriePlace;
    }

    public void setIdCategoriePlace(String idCategoriePlace) {
        this.idCategoriePlace = idCategoriePlace;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
