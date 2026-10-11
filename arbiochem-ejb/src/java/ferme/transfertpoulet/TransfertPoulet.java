package ferme.transfertpoulet;

import java.sql.Connection;
import bean.ClassMere;
import bean.ClassMAPTable;
import java.sql.Date;

/**
 *
 * @author Safidy
 */
public class TransfertPoulet extends ClassMere {
    private String id;
    private String remarque,idLot,idReception;
    private Date daty;

    public TransfertPoulet()throws Exception {
        super.setNomTable("TRANSFERTPOULET");
        this.setNomClasseFille("ferme.transfertpoulet.TransfertPouletDetail");
        this.setLiaisonFille("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("TRSP", "GETSEQTRANSFERTPOULET");
        this.setId(this.makePK(c));
    }
    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        controlerCumulReception(c);
        return super.createObject(u, c);
    }

    @Override
    public String getTuppleID() {
        return id;
    }

    /** Le cumul transfere depuis une reception ne doit pas depasser son comptage (theorique 2). */
    public void controlerCumulReception(Connection c) throws Exception {
        if (this.getIdReception() == null || this.getIdReception().isEmpty()) return;
        boolean canClose = false;
        try {
            if (c == null) { c = new utilitaire.UtilDB().GetConn(); canClose = true; }
            java.sql.Statement st = c.createStatement();
            java.sql.ResultSet rs = st.executeQuery(
                "SELECT NVL(SUM(QTERECUS),0) FROM receptionPoussinAeroport WHERE ID='" + this.getIdReception() + "'");
            rs.next();
            double theo = rs.getDouble(1);
            rs.close();
            rs = st.executeQuery(
                "SELECT NVL(SUM(d.QTE),0) FROM transfertPoulet t JOIN transfertPouletDetail d ON d.IDMERE=t.ID WHERE t.IDRECEPTION='" + this.getIdReception() + "'");
            rs.next();
            double deja = rs.getDouble(1);
            rs.close(); st.close();
            double nouveau = 0;
            if (this.getFille() != null)
                for (Object o : (Object[]) this.getFille())
                    nouveau += ((TransfertPouletDetail) o).getQte();
            if (deja + nouveau > theo)
                throw new Exception("Cumul transfere (" + (deja + nouveau) + ") > comptage reception (" + theo + ")");
        } finally {
            if (canClose && c != null) c.close();
        }
    }

    @Override
    public String getAttributIDName() {
        return "id";
    }

    @Override
    public String getNomClasseFille() {
        return "ferme.transfertpoulet.TransfertPouletDetail";
    }

    @Override
    public String getLiaisonFille() {
        return "idMere";
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getRemarque() {
        return remarque;
    }

    public void setRemarque(String remarque) {
        this.remarque = remarque;
    }

    public String getIdLot() {
        return idLot;
    }

    public void setIdLot(String idLot) {
        this.idLot = idLot;
    }

    /** Reception aeroport d'origine (traçabilité arrivage -> voyage). */
    public String getIdReception() {
        return idReception;
    }

    public void setIdReception(String idReception) {
        this.idReception = idReception;
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }
}