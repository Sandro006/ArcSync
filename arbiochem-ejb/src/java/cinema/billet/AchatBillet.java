package cinema.billet;

import bean.ClassMAPTable;
import bean.ClassMere;
import cinema.projection.Projection;
import cinema.projection.ProjectionService;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;
import java.sql.Date;

/**
 * Achat groupe de billets pour une projection.
 */
public class AchatBillet extends ClassMere {

    private String id;
    private Date daty;
    private String idClient;
    private String idProjection;
    private String idReservation;
    private double montantTotal;
    private double montantPaye;
    private double monnaieRendue;
    private String modepaiement;
    private String idVente;
    private String idMouvementCaisse;
    private String remarque;
    private int etat = ConstanteCinema.ETAT_CREER;
    /**
     * Prix des billets deja figes (conversion d'une reservation, remise
     * incluse). Champ non persiste : il sert uniquement aux controles de
     * creation, un prix net nul etant alors legitime.
     */
    private boolean prixFige;

    public AchatBillet() throws Exception {
        super.setNomTable("CINEMA_ACHATBILLET");
        this.setNomClasseFille("cinema.billet.Billet");
        this.setLiaisonFille("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CAB", "GETSEQCINEMAACHATBILLET");
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
    public String getNomClasseFille() {
        return "cinema.billet.Billet";
    }

    @Override
    public String getLiaisonFille() {
        return "idMere";
    }

    public void controlerProjection(Connection c) throws Exception {
        if (idProjection == null || idProjection.trim().isEmpty()) {
            throw new Exception("La projection de l'achat est obligatoire.");
        }
        Projection p = ProjectionService.charger(idProjection, c);
        if (!p.estOuverte()) {
            throw new Exception("La projection n'est pas ouverte a la vente.");
        }
        if (!p.estFuture()) {
            throw new Exception("La projection est deja passee.");
        }
    }

    public void controlerPlaces(Connection c) throws Exception {
        if (getFille() == null || getFille().length == 0) {
            throw new Exception("Au moins un billet est obligatoire.");
        }
        String idSalle = CinemaDb.getString(c,
                "SELECT IDSALLE FROM CINEMA_PROJECTION WHERE ID = ?", idProjection);
        if (idSalle == null) {
            throw new Exception("Projection introuvable : " + idProjection);
        }
        for (int i = 0; i < getFille().length; i++) {
            Billet b = (Billet) getFille()[i];
            if (b.getIdPlace() == null || b.getIdPlace().trim().isEmpty()) {
                throw new Exception("Chaque billet doit reference une place.");
            }
            String categorie = CinemaDb.getString(c,
                    "SELECT IDCATEGORIEPLACE FROM CINEMA_PLACE"
                    + " WHERE ID = ? AND IDMERE = ? AND ETAT = 1",
                    b.getIdPlace(), idSalle);
            if (categorie == null) {
                throw new Exception("Place invalide ou inactive pour cette salle : " + b.getIdPlace());
            }
            if (b.getIdCategoriePlace() == null || b.getIdCategoriePlace().trim().isEmpty()) {
                b.setIdCategoriePlace(categorie);
            }
            String exclusion = (idReservation == null || idReservation.trim().isEmpty())
                    ? "" : " AND NOT (TYPE_OCCUPATION = 'RESERVATION' AND IDORIGINE = ?)";
            String sql = "SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE"
                    + " WHERE IDPROJECTION = ? AND IDPLACE = ?" + exclusion;
            int occupee;
            if (exclusion.isEmpty()) {
                occupee = CinemaDb.getInt(c, sql, idProjection, b.getIdPlace());
            } else {
                occupee = CinemaDb.getInt(c, sql, idProjection, b.getIdPlace(), idReservation);
            }
            if (occupee > 0) {
                throw new Exception("La place " + b.getIdPlace() + " est deja occupee.");
            }
            if (!prixFige && b.getPrix() <= 0) {
                b.setPrix(ProjectionService.getPrixPlace(idProjection, b.getIdPlace(), c));
            }
            b.setStatut(ConstanteCinema.STATUT_BILLET_VENDU);
            b.setEtat(ConstanteCinema.ETAT_CREER);
        }
    }

    public void controlerPaiement() throws Exception {
        if (montantTotal < 0) {
            throw new Exception("Le montant total ne peut pas etre negatif.");
        }
        if (montantPaye < montantTotal) {
            throw new Exception("Le montant paye (" + montantPaye
                    + ") est inferieur au montant total (" + montantTotal + ").");
        }
    }

    public double getMontantTotalBillets() {
        if (getFille() == null) {
            return 0;
        }
        double total = 0;
        for (int i = 0; i < getFille().length; i++) {
            Billet b = (Billet) getFille()[i];
            if (b.getEtat() != ConstanteCinema.ETAT_ANNULE) {
                total += b.getPrix();
            }
        }
        return total;
    }

    public int getNbBillets() {
        if (getFille() == null) {
            return 0;
        }
        int n = 0;
        for (int i = 0; i < getFille().length; i++) {
            Billet b = (Billet) getFille()[i];
            if (b.getEtat() != ConstanteCinema.ETAT_ANNULE) {
                n++;
            }
        }
        return n;
    }

    public String getNumeroRecu() {
        return "REC-" + (id == null ? "" : id);
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        if (daty == null) {
            daty = CinemaDb.today();
        }
        this.controlerProjection(c);
        this.controlerPlaces(c);
        if (montantTotal <= 0) {
            montantTotal = getMontantTotalBillets();
        }
        this.controlerPaiement();
        return super.createObject(u, c);
    }

    @Override
    public Object validerObject(String u, Connection c) throws Exception {
        Object o = super.validerObject(u, c);
        // ClassFille.validerObject() est un no-op dans le framework : les
        // billets ne passent donc jamais a ETAT=11 via validerObjectFille.
        // Sans cet UPDATE, Billet.estValide() reste faux et le controle a
        // l'entree repond "Billet non valide (etat=1, statut=1)".
        CinemaDb.execute(c, "UPDATE CINEMA_BILLET SET ETAT = ? WHERE IDMERE = ?",
                Integer.valueOf(ConstanteCinema.ETAT_VALIDER), id);
        if (getFille() != null) {
            for (int i = 0; i < getFille().length; i++) {
                ((Billet) getFille()[i]).setEtat(ConstanteCinema.ETAT_VALIDER);
            }
        }
        return o;
    }

    @Override
    public Object annulerObject(String u, Connection c) throws Exception {
        Object o = super.annulerObject(u, c);
        CinemaDb.execute(c, "UPDATE CINEMA_BILLET SET ETAT = ? WHERE IDMERE = ?",
                Integer.valueOf(ConstanteCinema.ETAT_ANNULE), id);
        // La facture et le mouvement de caisse generes a l'achat sont annules
        // avec lui, afin de ne pas laisser une vente valide sans billets.
        String idVente = CinemaDb.getString(c,
                "SELECT IDVENTE FROM CINEMA_ACHATBILLET WHERE ID = ?", id);
        if (idVente != null) {
            CinemaDb.execute(c, "UPDATE VENTE SET ETAT = ? WHERE ID = ?",
                    Integer.valueOf(ConstanteCinema.ETAT_ANNULE), idVente);
        }
        String idMvt = CinemaDb.getString(c,
                "SELECT IDMOUVEMENTCAISSE FROM CINEMA_ACHATBILLET WHERE ID = ?", id);
        if (idMvt != null) {
            CinemaDb.execute(c, "UPDATE MOUVEMENTCAISSE SET ETAT = ? WHERE ID = ?",
                    Integer.valueOf(ConstanteCinema.ETAT_ANNULE), idMvt);
        }
        return o;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public Date getDaty() {
        return daty;
    }

    public void setDaty(Date daty) {
        this.daty = daty;
    }

    public String getIdClient() {
        return idClient;
    }

    public void setIdClient(String idClient) {
        this.idClient = idClient;
    }

    public String getIdProjection() {
        return idProjection;
    }

    public void setIdProjection(String idProjection) {
        this.idProjection = idProjection;
    }

    public String getIdReservation() {
        return idReservation;
    }

    public void setIdReservation(String idReservation) {
        this.idReservation = idReservation;
    }

    public double getMontantTotal() {
        return montantTotal;
    }

    public void setMontantTotal(double montantTotal) {
        this.montantTotal = montantTotal;
    }

    public double getMontantPaye() {
        return montantPaye;
    }

    public void setMontantPaye(double montantPaye) {
        this.montantPaye = montantPaye;
    }

    public double getMonnaieRendue() {
        return monnaieRendue;
    }

    public void setMonnaieRendue(double monnaieRendue) {
        this.monnaieRendue = monnaieRendue;
    }

    public String getModepaiement() {
        return modepaiement;
    }

    public void setModepaiement(String modepaiement) {
        this.modepaiement = modepaiement;
    }

    public String getIdVente() {
        return idVente;
    }

    public void setIdVente(String idVente) {
        this.idVente = idVente;
    }

    public String getIdMouvementCaisse() {
        return idMouvementCaisse;
    }

    public void setIdMouvementCaisse(String idMouvementCaisse) {
        this.idMouvementCaisse = idMouvementCaisse;
    }

    public String getRemarque() {
        return remarque;
    }

    public void setRemarque(String remarque) {
        this.remarque = remarque;
    }

    public int getEtat() {
        return etat;
    }

    public void setEtat(int etat) {
        this.etat = etat;
    }

    public boolean isPrixFige() {
        return prixFige;
    }

    public void setPrixFige(boolean prixFige) {
        this.prixFige = prixFige;
    }
}
