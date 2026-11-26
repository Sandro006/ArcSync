package cinema.configuration;

import bean.ClassMAPTable;
import java.sql.Connection;

/**
 * Regle de remise appliquee aux reservations.
 *
 * Si une reservation contient au moins {@code nombrePlace} places de la
 * categorie {@code idCategorieReservation}, alors {@code nombrePlaceRemise}
 * places de la categorie {@code idCategorieRemise} sont remisees de
 * {@code valeur} (pourcentage ou montant selon {@code typeValeur}).
 *
 * Les deux categories doivent etre differentes.
 */
public class Remise extends ClassMAPTable {

    /** Type de valeur : pourcentage. */
    public static final int TYPE_POURCENTAGE = 0;
    /** Type de valeur : montant fixe par place. */
    public static final int TYPE_MONTANT = 1;

    private String id;
    private String idCategorieReservation;
    private int nombrePlace;
    private int typeValeur = TYPE_POURCENTAGE;
    private double valeur;
    private String idCategorieRemise;
    private int nombrePlaceRemise;
    private String desce;
    private int etat = 1;

    public Remise() {
        super.setNomTable("CINEMA_REMISE");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CRM", "GETSEQCINEMAREMISE");
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
        if (desce != null && !desce.trim().isEmpty()) {
            return desce;
        }
        return nombrePlace + " place(s) -> " + nombrePlaceRemise + " remise(s)";
    }

    /** Libelle de l'effet de la regle, ex. "-20 %" ou "-5 000 Ar". */
    public String getEffetLibelle() {
        if (typeValeur == TYPE_MONTANT) {
            return "-" + (long) valeur + " Ar";
        }
        return "-" + valeur + " %";
    }

    /**
     * Controles metier communs a la creation et a la modification.
     */
    public void controlerSaisie() throws Exception {
        if (idCategorieReservation == null || idCategorieReservation.trim().isEmpty()) {
            throw new Exception("La categorie de reservation est obligatoire.");
        }
        if (idCategorieRemise == null || idCategorieRemise.trim().isEmpty()) {
            throw new Exception("La categorie remise est obligatoire.");
        }
        if (idCategorieReservation.equals(idCategorieRemise)) {
            throw new Exception("La categorie de reservation et la categorie remise"
                    + " doivent etre differentes.");
        }
        if (nombrePlace < 1) {
            throw new Exception("Le nombre de places declencheur doit etre superieur ou egal a 1.");
        }
        if (nombrePlaceRemise < 1) {
            throw new Exception("Le nombre de places remisees doit etre superieur ou egal a 1.");
        }
        if (typeValeur != TYPE_POURCENTAGE && typeValeur != TYPE_MONTANT) {
            throw new Exception("Type de valeur invalide.");
        }
        if (typeValeur == TYPE_POURCENTAGE && (valeur <= 0 || valeur > 100)) {
            throw new Exception("Le pourcentage de remise doit etre compris entre 0 et 100.");
        }
        if (typeValeur == TYPE_MONTANT && valeur < 0) {
            throw new Exception("Le montant de la remise ne peut pas etre negatif.");
        }
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        this.controlerSaisie();
        return super.createObject(u, c);
    }

    @Override
    public int updateObject(String u, Connection c) throws Exception {
        this.controlerSaisie();
        return super.updateObject(u, c);
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getIdCategorieReservation() {
        return idCategorieReservation;
    }

    public void setIdCategorieReservation(String idCategorieReservation) {
        this.idCategorieReservation = idCategorieReservation;
    }

    public int getNombrePlace() {
        return nombrePlace;
    }

    public void setNombrePlace(int nombrePlace) {
        this.nombrePlace = nombrePlace;
    }

    public int getTypeValeur() {
        return typeValeur;
    }

    public void setTypeValeur(int typeValeur) {
        this.typeValeur = typeValeur;
    }

    public double getValeur() {
        return valeur;
    }

    public void setValeur(double valeur) {
        this.valeur = valeur;
    }

    public String getIdCategorieRemise() {
        return idCategorieRemise;
    }

    public void setIdCategorieRemise(String idCategorieRemise) {
        this.idCategorieRemise = idCategorieRemise;
    }

    public int getNombrePlaceRemise() {
        return nombrePlaceRemise;
    }

    public void setNombrePlaceRemise(int nombrePlaceRemise) {
        this.nombrePlaceRemise = nombrePlaceRemise;
    }

    public String getDesce() {
        return desce;
    }

    public void setDesce(String desce) {
        this.desce = desce;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }
}
