package cinema.utils;

import java.sql.Connection;

/**
 * Statistiques simples du module cinema.
 */
public class CinemaStatService {

    public static class StatProjection {
        public String idProjection;
        public String film;
        public String salle;
        public int nbBillets;
        public double recette;
        public int tauxRemplissage;

        public StatProjection() {
        }
    }

    public static double getRecetteJour(java.sql.Date daty, Connection c) throws Exception {
        return CinemaDb.getDouble(c,
                "SELECT NVL(SUM(b.PRIX),0) FROM CINEMA_BILLET b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " WHERE ab.ETAT = 11 AND b.ETAT = 11 AND b.STATUT IN (1,2)"
                + " AND TRUNC(ab.DATY) = TRUNC(?)", daty);
    }

    public static int getNbBilletsJour(java.sql.Date daty, Connection c) throws Exception {
        return CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_BILLET b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " WHERE ab.ETAT = 11 AND b.ETAT = 11 AND b.STATUT IN (1,2)"
                + " AND TRUNC(ab.DATY) = TRUNC(?)", daty);
    }

    public static int getTauxRemplissage(String idProjection, Connection c) throws Exception {
        int nbPlaces = CinemaDb.getInt(c,
                "SELECT NBPLACES FROM CINEMA_PROJECTION WHERE ID = ?", idProjection);
        if (nbPlaces <= 0) {
            return 0;
        }
        int vendus = CinemaDb.getInt(c,
                "SELECT COUNT(*) FROM CINEMA_BILLET b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " WHERE ab.IDPROJECTION = ? AND ab.ETAT = 11 AND b.ETAT = 11"
                + " AND b.STATUT IN (1,2)", idProjection);
        return (int) Math.round(vendus * 100.0 / nbPlaces);
    }

    public static StatProjection[] getTopProjections(java.sql.Date debut,
            java.sql.Date fin, int limit, Connection c) throws Exception {
        if (limit <= 0) {
            limit = 10;
        }
        String sql = "SELECT * FROM ("
                + " SELECT pr.ID AS IDPROJECTION, f.TITRE AS FILM, s.NOM AS SALLE,"
                + " COUNT(b.ID) AS NBB, NVL(SUM(b.PRIX),0) AS RECETTE"
                + " FROM CINEMA_PROJECTION pr"
                + " JOIN CINEMA_FILM f ON f.ID = pr.IDFILM"
                + " JOIN CINEMA_SALLE s ON s.ID = pr.IDSALLE"
                + " LEFT JOIN CINEMA_ACHATBILLET ab ON ab.IDPROJECTION = pr.ID AND ab.ETAT = 11"
                + " LEFT JOIN CINEMA_BILLET b ON b.IDMERE = ab.ID AND b.ETAT = 11 AND b.STATUT IN (1,2)"
                + " WHERE TRUNC(pr.DATY) BETWEEN TRUNC(?) AND TRUNC(?)"
                + " GROUP BY pr.ID, f.TITRE, s.NOM"
                + " ORDER BY RECETTE DESC"
                + ") WHERE ROWNUM <= ?";

        java.sql.PreparedStatement ps = null;
        java.sql.ResultSet rs = null;
        java.util.List<StatProjection> liste = new java.util.ArrayList<StatProjection>();
        try {
            ps = c.prepareStatement(sql);
            ps.setDate(1, debut);
            ps.setDate(2, fin);
            ps.setInt(3, limit);
            rs = ps.executeQuery();
            while (rs.next()) {
                StatProjection s = new StatProjection();
                s.idProjection = rs.getString("IDPROJECTION");
                s.film = rs.getString("FILM");
                s.salle = rs.getString("SALLE");
                s.nbBillets = rs.getInt("NBB");
                s.recette = rs.getDouble("RECETTE");
                s.tauxRemplissage = getTauxRemplissage(s.idProjection, c);
                liste.add(s);
            }
        } finally {
            CinemaDb.close(rs);
            CinemaDb.close(ps);
        }
        return liste.toArray(new StatProjection[liste.size()]);
    }
}
