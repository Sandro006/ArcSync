package cinema.projection;

import bean.ClassFille;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;

/**
 * Ligne tarifaire d'une projection : une categorie de place, un rang
 * ('*' = tous les rangs), un prix et un quota optionnel.
 */
public class ProjectionTarif extends ClassFille {

    private String id;
    private String idMere;
    private String idCategoriePlace;
    private String rang = ConstanteCinema.RANG_TOUS;
    private double prix;
    private int quota;
    private int etat = ConstanteCinema.ETAT_CREER;

    public ProjectionTarif() throws Exception {
        super.setNomTable("CINEMA_PROJECTIONTARIF");
        this.setNomClasseMere("cinema.projection.Projection");
        this.setLiaisonMere("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CPRT", "GETSEQCINEMAPROJECTIONTARIF");
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
        return "cinema.projection.Projection";
    }

    @Override
    public String getLiaisonMere() {
        return "idMere";
    }

    public void controlerPrix() throws Exception {
        if (prix < 0) {
            throw new Exception("Le prix d'un tarif ne peut pas etre negatif.");
        }
        if (quota < 0) {
            throw new Exception("Le quota d'un tarif ne peut pas etre negatif.");
        }
    }

    public boolean estActive() {
        return etat != ConstanteCinema.ETAT_ANNULE;
    }

    public boolean estTarifGeneral() {
        return rang == null || rang.trim().isEmpty() || ConstanteCinema.RANG_TOUS.equals(rang);
    }

    public boolean couvreRang(String rangPlace) {
        return estTarifGeneral() || (rang != null && rang.equals(rangPlace));
    }

    /**
     * Quota restant. Un quota a 0 signifie "illimite".
     */
    public int getQuotaRestant(Connection c) throws Exception {
        if (quota == 0) {
            return Integer.MAX_VALUE;
        }
        String filtreRang = estTarifGeneral() ? "" : " AND p.RANG = ?";
        String sql = "SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE o"
                + " JOIN CINEMA_PLACE p ON p.ID = o.IDPLACE"
                + " WHERE o.IDPROJECTION = (SELECT IDMERE FROM CINEMA_PROJECTIONTARIF WHERE ID = ?)"
                + " AND p.IDCATEGORIEPLACE = ?" + filtreRang;
        int utilises;
        if (estTarifGeneral()) {
            utilises = CinemaDb.getInt(c, sql, id, idCategoriePlace);
        } else {
            utilises = CinemaDb.getInt(c, sql, id, idCategoriePlace, rang);
        }
        int reste = quota - utilises;
        return reste < 0 ? 0 : reste;
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

    public String getIdCategoriePlace() {
        return idCategoriePlace;
    }

    public void setIdCategoriePlace(String idCategoriePlace) {
        this.idCategoriePlace = idCategoriePlace;
    }

    public String getRang() {
        return rang;
    }

    public void setRang(String rang) {
        this.rang = (rang == null || rang.trim().isEmpty()) ? ConstanteCinema.RANG_TOUS : rang.trim();
    }

    public double getPrix() {
        return prix;
    }

    public void setPrix(double prix) throws Exception {
        if (prix < 0) {
            throw new Exception("Le prix d'un tarif ne peut pas etre negatif.");
        }
        this.prix = prix;
    }

    public int getQuota() {
        return quota;
    }

    public void setQuota(int quota) {
        this.quota = quota;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
