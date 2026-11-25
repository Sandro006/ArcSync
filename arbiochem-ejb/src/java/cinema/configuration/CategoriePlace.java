package cinema.configuration;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * Categorie de place (Standard, VIP, Loge, Enfant...).
 *
 * Le prix par defaut sert de dernier recours quand une projection n'a pas de
 * tarif explicite pour la categorie.
 */
public class CategoriePlace extends ClassMAPTable {

    private String id;
    private String val;
    private String desce;
    private double prixDefaut;
    private int etat = 1;

    public CategoriePlace() {
        super.setNomTable("CINEMA_CATEGORIEPLACE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CCP", "GETSEQCINEMACATEGORIEPLACE");
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
        return val;
    }

    public void controlerPrix() throws Exception {
        if (prixDefaut < 0) {
            throw new Exception("Le prix par defaut d'une categorie de place ne peut pas etre negatif.");
        }
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        this.controlerPrix();
        return super.createObject(u, c);
    }

    @Override
    public int updateObject(String u, Connection c) throws Exception {
        this.controlerPrix();
        return super.updateObject(u, c);
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getVal() {
        return val;
    }

    public void setVal(String val) {
        this.val = val;
    }

    public String getDesce() {
        return desce;
    }

    public void setDesce(String desce) {
        this.desce = desce;
    }

    public double getPrixDefaut() {
        return prixDefaut;
    }

    public void setPrixDefaut(double prixDefaut) throws Exception {
        if (prixDefaut < 0) {
            throw new Exception("Le prix par defaut ne peut pas etre negatif.");
        }
        this.prixDefaut = prixDefaut;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
