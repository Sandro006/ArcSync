package cinema.film;

import bean.CGenUtil;
import bean.ClassMAPTable;
import java.sql.Connection;
import java.sql.Date;

/**
 * Film exploitable par le cinema.
 */
public class Film extends ClassMAPTable {

    private String id;
    private String titre;
    private String titreOriginal;
    private String idGenre;
    private int duree;
    private String langue;
    private int annee;
    private String realisateur;
    private String acteurs;
    private String classification;
    private String synopsis;
    private String affiche;
    private Date daty;
    private int etat = 1;

    public Film() throws Exception {
        super.setNomTable("CINEMA_FILM");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CFI", "GETSEQCINEMAFILM");
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

    public String getLibelle() {
        String t = titre == null ? "" : titre.trim();
        if (annee > 0) {
            return t + " (" + annee + ")";
        }
        return t;
    }

    public String getDureeHeureMinute() {
        if (duree <= 0) {
            return "";
        }
        int h = duree / 60;
        int m = duree % 60;
        return h + "h" + (m < 10 ? "0" + m : "" + m);
    }

    public void controlerDuree() throws Exception {
        if (duree <= 0) {
            throw new Exception("La duree du film doit etre strictement positive.");
        }
        if (duree > 600) {
            throw new Exception("La duree du film ne peut pas depasser 600 minutes.");
        }
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        this.controlerDuree();
        return super.createObject(u, c);
    }

    @Override
    public int updateObject(String u, Connection c) throws Exception {
        this.controlerDuree();
        return super.updateObject(u, c);
    }

    public static Film[] rechercher(String motCle, Connection c) throws Exception {
        String like = motCle == null ? "" : motCle.trim().toUpperCase().replace("'", "''");
        return (Film[]) CGenUtil.rechercher(new Film(), null, null, c,
                " AND UPPER(TITRE) LIKE '%" + like + "%' ORDER BY TITRE");
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTitre() {
        return titre;
    }

    public void setTitre(String titre) {
        this.titre = titre;
    }

    public String getTitreOriginal() {
        return titreOriginal;
    }

    public void setTitreOriginal(String titreOriginal) {
        this.titreOriginal = titreOriginal;
    }

    public String getIdGenre() {
        return idGenre;
    }

    public void setIdGenre(String idGenre) {
        this.idGenre = idGenre;
    }

    public int getDuree() {
        return duree;
    }

    public void setDuree(int duree) {
        this.duree = duree;
    }

    public String getLangue() {
        return langue;
    }

    public void setLangue(String langue) {
        this.langue = langue;
    }

    public int getAnnee() {
        return annee;
    }

    public void setAnnee(int annee) {
        this.annee = annee;
    }

    public String getRealisateur() {
        return realisateur;
    }

    public void setRealisateur(String realisateur) {
        this.realisateur = realisateur;
    }

    public String getActeurs() {
        return acteurs;
    }

    public void setActeurs(String acteurs) {
        this.acteurs = acteurs;
    }

    public String getClassification() {
        return classification;
    }

    public void setClassification(String classification) {
        this.classification = classification;
    }

    public String getSynopsis() {
        return synopsis;
    }

    public void setSynopsis(String synopsis) {
        this.synopsis = synopsis;
    }

    public String getAffiche() {
        return affiche;
    }

    public void setAffiche(String affiche) {
        this.affiche = affiche;
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
