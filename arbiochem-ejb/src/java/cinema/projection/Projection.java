package cinema.projection;

import bean.ClassMAPTable;
import bean.ClassMere;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;
import java.sql.Date;
import java.util.HashSet;
import java.util.Set;

/**
 * Seance de cinema : un film dans une salle a une date et une heure donnees.
 */
public class Projection extends ClassMere {

    private String id;
    private Date daty;
    private String heureDebut;
    private String heureFin;
    private String idFilm;
    private String idSalle;
    private double prixBase;
    private int nbPlaces;
    private String format;
    private String version;
    private int statut = ConstanteCinema.STATUT_PROJECTION_PREPAREE;
    private String remarque;
    private int etat = ConstanteCinema.ETAT_CREER;

    public Projection() throws Exception {
        super.setNomTable("CINEMA_PROJECTION");
        this.setNomClasseFille("cinema.projection.ProjectionTarif");
        this.setLiaisonFille("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CPR", "GETSEQCINEMAPROJECTION");
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
        return "cinema.projection.ProjectionTarif";
    }

    @Override
    public String getLiaisonFille() {
        return "idMere";
    }

    public void controlerHoraire() throws Exception {
        if (daty == null) {
            throw new Exception("La date de la projection est obligatoire.");
        }
        int debut = CinemaDb.heureEnMinutes(heureDebut);
        int fin = CinemaDb.heureEnMinutes(heureFin);
        if (debut < 0) {
            throw new Exception("L'heure de debut doit etre au format HH:mm.");
        }
        if (fin < 0) {
            throw new Exception("L'heure de fin doit etre au format HH:mm.");
        }
        if (debut >= fin) {
            throw new Exception("L'heure de debut doit etre anterieure a l'heure de fin.");
        }
    }

    public void controlerSalle(Connection c) throws Exception {
        if (idSalle == null || idSalle.trim().isEmpty()) {
            throw new Exception("La salle de la projection est obligatoire.");
        }
        int exist = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_SALLE WHERE ID = ? AND ETAT = 1", idSalle);
        if (exist == 0) {
            throw new Exception("Salle introuvable ou inactive : " + idSalle);
        }
        int capacite = CinemaDb.getInt(c,
                "SELECT CAPACITE FROM CINEMA_SALLE WHERE ID = ?", idSalle);
        if (nbPlaces <= 0) {
            nbPlaces = capacite;
        }
        if (nbPlaces > capacite) {
            throw new Exception("Le nombre de places ouvertes (" + nbPlaces
                    + ") depasse la capacite de la salle (" + capacite + ").");
        }
        if (daty != null && heureDebut != null && heureFin != null
                && !heureDebut.trim().isEmpty() && !heureFin.trim().isEmpty()) {
            String exclue = (id == null || id.trim().isEmpty()) ? "" : " AND ID <> ?";
            String sql = "SELECT COUNT(*) FROM CINEMA_PROJECTION"
                    + " WHERE IDSALLE = ? AND DATY = ? AND ETAT <> 0"
                    + " AND HEUREDEBUT < ? AND HEUREFIN > ?" + exclue;
            int nb;
            if (exclue.isEmpty()) {
                nb = CinemaDb.getInt(c, sql, idSalle, daty, heureFin, heureDebut);
            } else {
                nb = CinemaDb.getInt(c, sql, idSalle, daty, heureFin, heureDebut, id);
            }
            if (nb > 0) {
                throw new Exception("Une autre projection de cette salle chevauche cet horaire.");
            }
        }
    }

    public void controlerFilm(Connection c) throws Exception {
        if (idFilm == null || idFilm.trim().isEmpty()) {
            throw new Exception("Le film de la projection est obligatoire.");
        }
        int exist = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_FILM WHERE ID = ? AND ETAT = 1", idFilm);
        if (exist == 0) {
            throw new Exception("Film introuvable ou inactif : " + idFilm);
        }
        int duree = CinemaDb.getInt(c,
                "SELECT DUREE FROM CINEMA_FILM WHERE ID = ?", idFilm);
        if (duree <= 0) {
            throw new Exception("La duree du film n'est pas renseignee.");
        }
    }

    public void controlerTarifs() throws Exception {
        if (getFille() == null || getFille().length == 0) {
            throw new Exception("Au moins un tarif est obligatoire pour une projection.");
        }
        Set<String> cles = new HashSet<String>();
        for (int i = 0; i < getFille().length; i++) {
            ProjectionTarif t = (ProjectionTarif) getFille()[i];
            t.controlerPrix();
            if (t.getIdCategoriePlace() == null || t.getIdCategoriePlace().trim().isEmpty()) {
                throw new Exception("Chaque tarif doit reference une categorie de place.");
            }
            String rang = t.getRang();
            if (rang == null || rang.trim().isEmpty()) {
                throw new Exception("Chaque tarif doit avoir un rang (ou '*').");
            }
            String cle = t.getIdCategoriePlace() + "|" + rang;
            if (!cles.add(cle)) {
                throw new Exception("Tarif en doublon pour la categorie " + t.getIdCategoriePlace()
                        + " et le rang " + rang + ".");
            }
        }
    }

    public int getNbPlacesVendues(Connection c) throws Exception {
        return CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_BILLET b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " WHERE ab.IDPROJECTION = ? AND ab.ETAT = 11 AND b.ETAT = 11"
                + " AND b.STATUT IN (1,2)", id);
    }

    public int getNbPlacesReservees(Connection c) throws Exception {
        return CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_RESERVATIONDETAIL rd"
                + " JOIN CINEMA_RESERVATION r ON r.ID = rd.IDMERE"
                + " WHERE r.IDPROJECTION = ? AND r.ETAT IN (1,11)"
                + " AND r.STATUT IN (1,2) AND rd.ETAT IN (1,11)", id);
    }

    public int getNbPlacesDisponibles(Connection c) throws Exception {
        int dispo = nbPlaces - getNbPlacesVendues(c) - getNbPlacesReservees(c);
        return dispo < 0 ? 0 : dispo;
    }

    public boolean estOuverte() {
        return etat == ConstanteCinema.ETAT_VALIDER
                && statut == ConstanteCinema.STATUT_PROJECTION_OUVERTE;
    }

    /**
     * Vrai tant que la seance n'a pas commence (date + heure de debut).
     * Une seance du jour dont l'heure de debut est deja passee n'est plus
     * consideree comme future.
     */
    public boolean estFuture() {
        if (daty == null) {
            return false;
        }
        java.sql.Timestamp debut = CinemaDb.debutSeance(daty, heureDebut);
        if (debut == null) {
            // Horaire incomplet : on retombe sur une comparaison par date.
            return !CinemaDb.dateOnly(daty).before(CinemaDb.today());
        }
        return !debut.before(CinemaDb.now());
    }

    public double getRecette(Connection c) throws Exception {
        return CinemaDb.getDouble(c,
                "SELECT NVL(SUM(b.PRIX),0) FROM CINEMA_BILLET b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " WHERE ab.IDPROJECTION = ? AND ab.ETAT = 11 AND b.ETAT = 11"
                + " AND b.STATUT IN (1,2)", id);
    }

    @Override
    public void controler(Connection c) throws Exception {
        super.controler(c);
        this.controlerHoraire();
        this.controlerFilm(c);
        this.controlerSalle(c);
        this.controlerTarifs();
    }

    @Override
    public ClassMAPTable createObject(String u, Connection c) throws Exception {
        this.controlerHoraire();
        this.controlerFilm(c);
        this.controlerSalle(c);
        this.controlerTarifs();
        return super.createObject(u, c);
    }

    @Override
    public Object cloturerObject(String u, Connection c) throws Exception {
        this.statut = ConstanteCinema.STATUT_PROJECTION_CLOTUREE;
        return super.cloturerObject(u, c);
    }

    @Override
    public Object annulerObject(String u, Connection c) throws Exception {
        this.statut = ConstanteCinema.STATUT_PROJECTION_ANNULEE;
        return super.annulerObject(u, c);
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

    public String getHeureDebut() {
        return heureDebut;
    }

    public void setHeureDebut(String heureDebut) {
        this.heureDebut = heureDebut;
    }

    public String getHeureFin() {
        return heureFin;
    }

    public void setHeureFin(String heureFin) {
        this.heureFin = heureFin;
    }

    public String getIdFilm() {
        return idFilm;
    }

    public void setIdFilm(String idFilm) {
        this.idFilm = idFilm;
    }

    public String getIdSalle() {
        return idSalle;
    }

    public void setIdSalle(String idSalle) {
        this.idSalle = idSalle;
    }

    public double getPrixBase() {
        return prixBase;
    }

    public void setPrixBase(double prixBase) {
        this.prixBase = prixBase;
    }

    public int getNbPlaces() {
        return nbPlaces;
    }

    public void setNbPlaces(int nbPlaces) {
        this.nbPlaces = nbPlaces;
    }

    public String getFormat() {
        return format;
    }

    public void setFormat(String format) {
        this.format = format;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public int getStatut() {
        return statut;
    }

    public void setStatut(int statut) {
        this.statut = statut;
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
}
