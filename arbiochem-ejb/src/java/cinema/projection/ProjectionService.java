package cinema.projection;

import bean.CGenUtil;
import cinema.configuration.CategoriePlace;
import cinema.configuration.Salle;
import cinema.film.Film;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;
import java.text.SimpleDateFormat;
import java.util.List;
import utilitaire.UtilDB;

/**
 * Operations metier sur les projections.
 */
public class ProjectionService {

    public static class LigneTarif {
        public String idCategoriePlace;
        public String rang;
        public double prix;
        public int quota;

        public LigneTarif() {
            this.rang = ConstanteCinema.RANG_TOUS;
        }

        public LigneTarif(String idCategoriePlace, double prix, int quota) {
            this.idCategoriePlace = idCategoriePlace;
            this.rang = ConstanteCinema.RANG_TOUS;
            this.prix = prix;
            this.quota = quota;
        }

        public LigneTarif(String idCategoriePlace, String rang, double prix, int quota) {
            this.idCategoriePlace = idCategoriePlace;
            this.rang = (rang == null || rang.trim().isEmpty())
                    ? ConstanteCinema.RANG_TOUS : rang.trim();
            this.prix = prix;
            this.quota = quota;
        }
    }

    public static class Resultat {
        public String idProjection;
        public int nbPlaces;
        public double recette;

        public Resultat() {
        }
    }

    public static Resultat preparerProjection(String u, String idFilm, String idSalle,
            java.sql.Date daty, String heureDebut, String heureFin, double prixBase,
            List<LigneTarif> tarifs, String remarque) throws Exception {
        return preparerProjection(u, idFilm, idSalle, daty, heureDebut, heureFin, prixBase,
                tarifs, remarque, null, null);
    }

    public static Resultat preparerProjection(String u, String idFilm, String idSalle,
            java.sql.Date daty, String heureDebut, String heureFin, double prixBase,
            List<LigneTarif> tarifs, String remarque, String format, String version)
            throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            Resultat r = preparerProjection(c, u, idFilm, idSalle, daty, heureDebut, heureFin,
                    prixBase, tarifs, remarque, format, version);
            c.commit();
            ok = true;
            return r;
        } finally {
            if (c != null) {
                if (!ok) {
                    try { c.rollback(); } catch (Exception ignore) {}
                }
                try { c.close(); } catch (Exception ignore) {}
            }
        }
    }

    public static Resultat preparerProjection(Connection c, String u, String idFilm,
            String idSalle, java.sql.Date daty, String heureDebut, String heureFin,
            double prixBase, List<LigneTarif> tarifs, String remarque) throws Exception {
        return preparerProjection(c, u, idFilm, idSalle, daty, heureDebut, heureFin,
                prixBase, tarifs, remarque, null, null);
    }

    public static Resultat preparerProjection(Connection c, String u, String idFilm,
            String idSalle, java.sql.Date daty, String heureDebut, String heureFin,
            double prixBase, List<LigneTarif> tarifs, String remarque, String format,
            String version) throws Exception {

        Film film = (Film) new Film().getById(idFilm, "CINEMA_FILM", c);
        if (film == null || film.getId() == null) {
            throw new Exception("Film introuvable : " + idFilm);
        }
        if (film.getEtat() != 1) {
            throw new Exception("Le film est inactif : " + film.getTitre());
        }
        film.controlerDuree();

        Salle salle = (Salle) new Salle().getById(idSalle, "CINEMA_SALLE", c);
        if (salle == null || salle.getId() == null) {
            throw new Exception("Salle introuvable : " + idSalle);
        }
        if (salle.getEtat() != 1) {
            throw new Exception("La salle est inactive : " + salle.getNom());
        }

        if (daty == null) {
            throw new Exception("La date de la projection est obligatoire.");
        }
        int minutesDebut = CinemaDb.heureEnMinutes(heureDebut);
        int minutesFin = CinemaDb.heureEnMinutes(heureFin);
        if (minutesDebut < 0 || minutesFin < 0) {
            throw new Exception("Heures invalides : le format attendu est HH:mm.");
        }
        if (minutesFin <= minutesDebut) {
            throw new Exception("L'heure de fin doit etre posterieure a l'heure de debut.");
        }
        if (chevauche(idSalle, daty, heureDebut, heureFin, null, c)) {
            throw new Exception("Cette salle a deja une projection sur ce creneau.");
        }

        int capacite = salle.getCapacite();
        if (capacite <= 0) {
            capacite = CinemaDb.getInt(c,
                    "SELECT COUNT(*) FROM CINEMA_PLACE WHERE IDMERE = ? AND ETAT = 1", idSalle);
        }
        if (capacite <= 0) {
            throw new Exception("Aucune place active dans cette salle.");
        }

        Projection p = new Projection();
        p.setDaty(daty);
        p.setHeureDebut(heureDebut);
        p.setHeureFin(heureFin);
        p.setIdFilm(idFilm);
        p.setIdSalle(idSalle);
        p.setPrixBase(prixBase);
        p.setNbPlaces(capacite);
        p.setFormat(emptyToNull(format));
        p.setVersion(emptyToNull(version));
        p.setStatut(ConstanteCinema.STATUT_PROJECTION_PREPAREE);
        p.setEtat(ConstanteCinema.ETAT_CREER);
        p.setRemarque(remarque);

        if (tarifs == null || tarifs.isEmpty()) {
            throw new Exception("Au moins un tarif est obligatoire.");
        }
        ProjectionTarif[] filles = new ProjectionTarif[tarifs.size()];
        for (int i = 0; i < tarifs.size(); i++) {
            LigneTarif lt = tarifs.get(i);
            ProjectionTarif t = new ProjectionTarif();
            t.setIdCategoriePlace(lt.idCategoriePlace);
            t.setRang(lt.rang);
            t.setPrix(lt.prix);
            t.setQuota(lt.quota);
            t.setEtat(ConstanteCinema.ETAT_CREER);
            filles[i] = t;
        }
        p.setFille(filles);

        Projection cree = (Projection) p.createObject(u, c);
        Resultat res = new Resultat();
        res.idProjection = (cree != null && cree.getId() != null) ? cree.getId() : p.getId();
        res.nbPlaces = p.getNbPlaces();
        res.recette = 0;
        return res;
    }

    public static void ouvrirVente(String u, String idProjection) throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            ouvrirVente(c, u, idProjection);
            c.commit();
            ok = true;
        } finally {
            if (c != null) {
                if (!ok) {
                    try { c.rollback(); } catch (Exception ignore) {}
                }
                try { c.close(); } catch (Exception ignore) {}
            }
        }
    }

    public static void ouvrirVente(Connection c, String u, String idProjection) throws Exception {
        Projection p = charger(idProjection, c);
        if (p.getEtat() == ConstanteCinema.ETAT_ANNULE) {
            throw new Exception("Une projection annulee ne peut pas etre ouverte.");
        }
        if (p.getEtat() == ConstanteCinema.ETAT_CLOTURE) {
            throw new Exception("Une projection cloturee ne peut pas etre reouverte.");
        }
        p.setStatut(ConstanteCinema.STATUT_PROJECTION_OUVERTE);
        p.validerObject(u, c);
        CinemaDb.execute(c, "UPDATE CINEMA_PROJECTIONTARIF SET ETAT = ? WHERE IDMERE = ?",
                Integer.valueOf(ConstanteCinema.ETAT_VALIDER), idProjection);
    }

    public static void cloturerProjection(String u, String idProjection) throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            cloturerProjection(c, u, idProjection);
            c.commit();
            ok = true;
        } finally {
            if (c != null) {
                if (!ok) {
                    try { c.rollback(); } catch (Exception ignore) {}
                }
                try { c.close(); } catch (Exception ignore) {}
            }
        }
    }

    public static void cloturerProjection(Connection c, String u, String idProjection) throws Exception {
        int actives = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_RESERVATION WHERE IDPROJECTION = ?"
                + " AND ETAT IN (1,11) AND STATUT IN (1,2)", idProjection);
        if (actives > 0) {
            throw new Exception("Impossible de cloturer : " + actives
                    + " reservation(s) encore active(s).");
        }
        Projection p = charger(idProjection, c);
        p.setStatut(ConstanteCinema.STATUT_PROJECTION_CLOTUREE);
        p.cloturerObject(u, c);
    }

    public static void annulerProjection(String u, String idProjection) throws Exception {
        Connection c = null;
        boolean ok = false;
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            annulerProjection(c, u, idProjection);
            c.commit();
            ok = true;
        } finally {
            if (c != null) {
                if (!ok) {
                    try { c.rollback(); } catch (Exception ignore) {}
                }
                try { c.close(); } catch (Exception ignore) {}
            }
        }
    }

    public static void annulerProjection(Connection c, String u, String idProjection) throws Exception {
        int vendus = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_BILLET b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " WHERE ab.IDPROJECTION = ? AND ab.ETAT = 11 AND b.ETAT = 11"
                + " AND b.STATUT IN (1,2)", idProjection);
        if (vendus > 0) {
            throw new Exception("Impossible d'annuler : " + vendus
                    + " billet(s) deja vendu(s). Remboursez-les d'abord.");
        }
        Projection p = charger(idProjection, c);
        p.setStatut(ConstanteCinema.STATUT_PROJECTION_ANNULEE);
        p.annulerObject(u, c);
    }

    public static Projection[] getProjectionsDuJour(java.sql.Date daty, Connection c) throws Exception {
        if (daty == null) {
            daty = CinemaDb.today();
        }
        String d = new SimpleDateFormat("yyyy-MM-dd").format(daty);
        return (Projection[]) CGenUtil.rechercher(new ProjectionLib(), null, null, c,
                " AND DATY = TO_DATE('" + d + "','YYYY-MM-DD') ORDER BY HEUREDEBUT");
    }

    public static Projection[] getProjectionsOuvertes(Connection c) throws Exception {
        return (Projection[]) CGenUtil.rechercher(new ProjectionLib(), null, null, c,
                " AND ETAT = 11 AND STATUT = 2"
                + " AND (DATY + (TO_DATE(HEUREDEBUT,'HH24:MI')"
                + " - TRUNC(TO_DATE(HEUREDEBUT,'HH24:MI')))) >= SYSDATE"
                + " ORDER BY DATY, HEUREDEBUT");
    }

    public static int getPlacesDisponibles(String idProjection, Connection c) throws Exception {
        return charger(idProjection, c).getNbPlacesDisponibles(c);
    }

    public static boolean chevauche(String idSalle, java.sql.Date daty, String heureDebut,
            String heureFin, String idProjectionExclue, Connection c) throws Exception {
        String exclue = (idProjectionExclue == null || idProjectionExclue.trim().isEmpty())
                ? "" : " AND ID <> ?";
        String sql = "SELECT COUNT(*) FROM CINEMA_PROJECTION"
                + " WHERE IDSALLE = ? AND DATY = ? AND ETAT <> 0"
                + " AND HEUREDEBUT < ? AND HEUREFIN > ?" + exclue;
        if (exclue.isEmpty()) {
            return CinemaDb.getInt(c, sql, idSalle, daty, heureFin, heureDebut) > 0;
        }
        return CinemaDb.getInt(c, sql, idSalle, daty, heureFin, heureDebut,
                idProjectionExclue) > 0;
    }

    /**
     * Prix resolu pour une place ou, a defaut, pour une categorie.
     *
     * Les deux notions sont des identifiants textuels : on detecte d'abord si
     * la reference correspond a une place, sinon on la traite comme une
     * categorie de place.
     */
    public static double getPrix(String idProjection, String idReference,
            Connection c) throws Exception {
        boolean estPlace = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_PLACE WHERE ID = ?", idReference) > 0;
        if (estPlace) {
            return getPrixPlace(idProjection, idReference, c);
        }
        return getPrixCategorie(idProjection, idReference, c);
    }

    public static double getPrixCategorie(String idProjection, String idCategoriePlace,
            Connection c) throws Exception {
        ProjectionTarif t = getTarif(idProjection, idCategoriePlace,
                ConstanteCinema.RANG_TOUS, c);
        if (t != null) {
            return t.getPrix();
        }
        double base = CinemaDb.getDouble(c,
                "SELECT PRIXBASE FROM CINEMA_PROJECTION WHERE ID = ?", idProjection);
        if (base > 0) {
            return base;
        }
        return CinemaDb.getDouble(c,
                "SELECT PRIXDEFAUT FROM CINEMA_CATEGORIEPLACE WHERE ID = ?", idCategoriePlace);
    }

    public static double getPrixPlace(String idProjection, String idPlace, Connection c) throws Exception {
        String categorie = CinemaDb.getString(c,
                "SELECT IDCATEGORIEPLACE FROM CINEMA_PLACE WHERE ID = ?", idPlace);
        String rang = CinemaDb.getString(c,
                "SELECT RANG FROM CINEMA_PLACE WHERE ID = ?", idPlace);
        if (categorie == null) {
            throw new Exception("Place introuvable : " + idPlace);
        }
        ProjectionTarif t = getTarif(idProjection, categorie, rang, c);
        if (t != null) {
            return t.getPrix();
        }
        t = getTarif(idProjection, categorie, ConstanteCinema.RANG_TOUS, c);
        if (t != null) {
            return t.getPrix();
        }
        double base = CinemaDb.getDouble(c,
                "SELECT PRIXBASE FROM CINEMA_PROJECTION WHERE ID = ?", idProjection);
        if (base > 0) {
            return base;
        }
        return CinemaDb.getDouble(c,
                "SELECT PRIXDEFAUT FROM CINEMA_CATEGORIEPLACE WHERE ID = ?", categorie);
    }

    public static ProjectionTarif getTarif(String idProjection, String idCategoriePlace,
            String rang, Connection c) throws Exception {
        String r = (rang == null || rang.trim().isEmpty())
                ? ConstanteCinema.RANG_TOUS : rang.trim();
        ProjectionTarif critere = new ProjectionTarif();
        ProjectionTarif[] tarifs = (ProjectionTarif[]) CGenUtil.rechercher(critere, null, null, c,
                " AND IDMERE = '" + esc(idProjection) + "'"
                + " AND IDCATEGORIEPLACE = '" + esc(idCategoriePlace) + "'"
                + " AND RANG = '" + esc(r) + "' AND ETAT <> 0");
        return tarifs.length > 0 ? tarifs[0] : null;
    }

    public static Projection charger(String idProjection, Connection c) throws Exception {
        Projection p = (Projection) new Projection().getById(idProjection, "CINEMA_PROJECTION", c);
        if (p == null || p.getId() == null) {
            throw new Exception("Projection introuvable : " + idProjection);
        }
        return p;
    }

    private static String esc(String v) {
        return v == null ? "" : v.replace("'", "''");
    }

    private static String emptyToNull(String v) {
        return (v == null || v.trim().isEmpty()) ? null : v.trim();
    }
}
