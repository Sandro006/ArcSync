package cinema.configuration;

/**
 * Vue d'affichage des regles de remise.
 */
public class RemiseLib extends Remise {

    private String idCategorieReservationLib;
    private String idCategorieRemiseLib;
    private String typeValeurLib;
    private String etatLib;

    public RemiseLib() {
        super();
        super.setNomTable("CINEMA_REMISE_LIB");
    }

    public String getIdCategorieReservationLib() {
        return idCategorieReservationLib;
    }

    public void setIdCategorieReservationLib(String idCategorieReservationLib) {
        this.idCategorieReservationLib = idCategorieReservationLib;
    }

    public String getIdCategorieRemiseLib() {
        return idCategorieRemiseLib;
    }

    public void setIdCategorieRemiseLib(String idCategorieRemiseLib) {
        this.idCategorieRemiseLib = idCategorieRemiseLib;
    }

    public String getTypeValeurLib() {
        return typeValeurLib;
    }

    public void setTypeValeurLib(String typeValeurLib) {
        this.typeValeurLib = typeValeurLib;
    }

    public String getEtatLib() {
        return etatLib;
    }

    public void setEtatLib(String etatLib) {
        this.etatLib = etatLib;
    }
}
