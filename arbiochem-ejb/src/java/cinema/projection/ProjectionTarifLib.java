package cinema.projection;

/**
 * Vue d'affichage des tarifs de projection.
 */
public class ProjectionTarifLib extends ProjectionTarif {

    private String idCategoriePlaceLib;
    private String rangLib;
    private String etatLib;
    private int quotaRestant;

    public ProjectionTarifLib() throws Exception {
        super();
        super.setNomTable("CINEMA_PROJECTIONTARIF_LIB");
    }

    public String getIdCategoriePlaceLib() {
        return idCategoriePlaceLib;
    }

    public void setIdCategoriePlaceLib(String idCategoriePlaceLib) {
        this.idCategoriePlaceLib = idCategoriePlaceLib;
    }

    public String getRangLib() {
        return rangLib;
    }

    public void setRangLib(String rangLib) {
        this.rangLib = rangLib;
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }

    public int getQuotaRestant() {
        return quotaRestant;
    }

    public void setQuotaRestant(int quotaRestant) {
        this.quotaRestant = quotaRestant;
    }
}
