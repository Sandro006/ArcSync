package cinema.billet;

import bean.ClassFille;
import bean.ClassMAPTable;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;
import java.sql.Timestamp;

/**
 * Billet individuel. Le numero est unique et sert au controle a l'entree.
 */
public class Billet extends ClassFille {

    private String id;
    private String idMere;
    private String idPlace;
    private String idCategoriePlace;
    private double prix;
    private String numero;
    private Timestamp datyUtilisation;
    private int statut = ConstanteCinema.STATUT_BILLET_VENDU;
    private int etat = ConstanteCinema.ETAT_CREER;

    public Billet() throws Exception {
        super.setNomTable("CINEMA_BILLET");
        this.setNomClasseMere("cinema.billet.AchatBillet");
        this.setLiaisonMere("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CBI", "GETSEQCINEMABILLET");
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
        return "cinema.billet.AchatBillet";
    }

    @Override
    public String getLiaisonMere() {
        return "idMere";
    }

    public void controlerPlace(Connection c) throws Exception {
        if (idPlace == null || idPlace.trim().isEmpty()) {
            throw new Exception("La place du billet est obligatoire.");
        }
        String idSalle = CinemaDb.getString(c,
                "SELECT pr.IDSALLE FROM CINEMA_ACHATBILLET ab"
                + " JOIN CINEMA_PROJECTION pr ON pr.ID = ab.IDPROJECTION"
                + " WHERE ab.ID = ?", idMere);
        if (idSalle == null) {
            throw new Exception("Achat introuvable : " + idMere);
        }
        int ok = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_PLACE WHERE ID = ? AND IDMERE = ? AND ETAT = 1",
                idPlace, idSalle);
        if (ok == 0) {
            throw new Exception("La place " + idPlace + " n'appartient pas a la salle de la projection.");
        }
    }

    public boolean estValide() {
        return etat == ConstanteCinema.ETAT_VALIDER
                && statut == ConstanteCinema.STATUT_BILLET_VENDU;
    }

    public boolean estUtilise() {
        return statut == ConstanteCinema.STATUT_BILLET_UTILISE;
    }

    public void marquerUtilise(Connection c) throws Exception {
        if (!estValide()) {
            throw new Exception("Ce billet n'est pas valide (etat=" + etat
                    + ", statut=" + statut + ").");
        }
        Timestamp now = CinemaDb.now();
        CinemaDb.execute(c,
                "UPDATE CINEMA_BILLET SET STATUT = ?, DATYUTILISATION = ? WHERE ID = ?",
                Integer.valueOf(ConstanteCinema.STATUT_BILLET_UTILISE), now, id);
        this.statut = ConstanteCinema.STATUT_BILLET_UTILISE;
        this.datyUtilisation = now;
    }

    public String getLibellePlace(Connection c) throws Exception {
        String salle = CinemaDb.getString(c,
                "SELECT s.NOM FROM CINEMA_PLACE p"
                + " JOIN CINEMA_SALLE s ON s.ID = p.IDMERE WHERE p.ID = ?", idPlace);
        String rang = CinemaDb.getString(c,
                "SELECT RANG FROM CINEMA_PLACE WHERE ID = ?", idPlace);
        String numeroPlace = CinemaDb.getString(c,
                "SELECT NUMERO FROM CINEMA_PLACE WHERE ID = ?", idPlace);
        return (salle == null ? "" : salle)
                + (rang == null ? "" : " - Rang " + rang)
                + (numeroPlace == null ? "" : " - Place " + numeroPlace);
    }

    public void genererNumero() throws Exception {
        if (numero == null || numero.trim().isEmpty()) {
            numero = ConstanteCinema.PREFIXE_NUMERO_BILLET + "-" + id;
        }
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        if (id == null || id.trim().isEmpty()) {
            this.construirePK(c);
        }
        this.genererNumero();
        return super.createObject(u, c);
    }

    /**
     * Le framework insere les objets filles en lot (ClassMere.createObject ->
     * createObjectFilleBatch) : createObject() n'est alors pas appele, mais
     * bien createObjectBatch(). Sans cette surcharge, NUMERO restait NULL et
     * Oracle levait ORA-01400.
     */
    @Override
    public ClassMAPTable createObjectBatch(String u, java.sql.Statement st) throws Exception {
        if (id == null || id.trim().isEmpty()) {
            this.construirePK(st.getConnection());
        }
        this.genererNumero();
        return super.createObjectBatch(u, st);
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

    public String getIdPlace() {
        return idPlace;
    }

    public void setIdPlace(String idPlace) {
        this.idPlace = idPlace;
    }

    public String getIdCategoriePlace() {
        return idCategoriePlace;
    }

    public void setIdCategoriePlace(String idCategoriePlace) {
        this.idCategoriePlace = idCategoriePlace;
    }

    public double getPrix() {
        return prix;
    }

    public void setPrix(double prix) {
        this.prix = prix;
    }

    public String getNumero() {
        return numero;
    }

    public void setNumero(String numero) {
        this.numero = numero;
    }

    public Timestamp getDatyUtilisation() {
        return datyUtilisation;
    }

    public void setDatyUtilisation(Timestamp datyUtilisation) {
        this.datyUtilisation = datyUtilisation;
    }

    public int getStatut() {
        return statut;
    }

    public void setStatut(int statut) {
        this.statut = statut;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
