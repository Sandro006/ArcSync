package ferme.receptionaeroport;

import java.sql.Connection;
import bean.ClassFille;

/**
 *
 * @author Safidy
 */
public class ReceptionPoussinAeroportDetail extends ClassFille {
    private String id,idMere,idQualitePoussin,idSexe;
    private double qte;
    private int sante;

    public ReceptionPoussinAeroportDetail()throws Exception {
        super.setNomTable("receptionPoussinAeroportDetail");
        this.setNomClasseMere("ferme.receptionaeroport.ReceptionPoussinAeroport");
        this.setLiaisonMere("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("RPAF", "GETSEQRECEPTIONPOUSSINAEDETAIL");
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
        return "ferme.receptionaeroport.ReceptionPoussinAeroport";
    }

    @Override
    public String getLiaisonMere() {
        return "idMere";
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

    public String getIdQualitePoussin() {
        return idQualitePoussin;
    }

    public void setIdQualitePoussin(String idQualitePoussin) {
        this.idQualitePoussin = idQualitePoussin;
    }

    public String getIdSexe() {
        return idSexe;
    }

    public void setIdSexe(String idSexe) {
        this.idSexe = idSexe;
    }

    public double getQte() {
        return qte;
    }

    public void setQte(double qte) {
        this.qte = qte;
    }

    /** Etat sanitaire du lot : 1 (malade) -> 10 (gueri). 0 = non renseigne. */
    public int getSante() {
        return sante;
    }

    public void setSante(int sante) throws Exception {
        if (sante != 0 && (sante < 1 || sante > 10)) {
            throw new Exception("Sante invalide : valeur 1 (malade) a 10 (gueri), 0 si non renseigne");
        }
        this.sante = sante;
    }
}
