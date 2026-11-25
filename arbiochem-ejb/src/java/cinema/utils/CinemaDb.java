package cinema.utils;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

/**
 * Petits utilitaires JDBC propres au module cinema. Ils evitent de dupliquer
 * les fermetures de ResultSet/PreparedStatement dans les services et les JSP.
 */
public final class CinemaDb {

    private CinemaDb() {
    }

    public static void close(ResultSet rs) {
        try {
            if (rs != null) {
                rs.close();
            }
        } catch (Exception ignore) {
        }
    }

    public static void close(PreparedStatement ps) {
        try {
            if (ps != null) {
                ps.close();
            }
        } catch (Exception ignore) {
        }
    }

    public static int getInt(Connection c, String sql, Object... params) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            ps = c.prepareStatement(sql);
            bind(ps, params);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
            return 0;
        } finally {
            close(rs);
            close(ps);
        }
    }

    public static double getDouble(Connection c, String sql, Object... params) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            ps = c.prepareStatement(sql);
            bind(ps, params);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getDouble(1);
            }
            return 0;
        } finally {
            close(rs);
            close(ps);
        }
    }

    public static String getString(Connection c, String sql, Object... params) throws Exception {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            ps = c.prepareStatement(sql);
            bind(ps, params);
            rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getString(1);
            }
            return null;
        } finally {
            close(rs);
            close(ps);
        }
    }

    public static boolean exists(Connection c, String sql, Object... params) throws Exception {
        return getInt(c, sql, params) > 0;
    }

    public static int execute(Connection c, String sql, Object... params) throws Exception {
        PreparedStatement ps = null;
        try {
            ps = c.prepareStatement(sql);
            bind(ps, params);
            return ps.executeUpdate();
        } finally {
            close(ps);
        }
    }

    private static void bind(PreparedStatement ps, Object... params) throws Exception {
        if (params == null) {
            return;
        }
        for (int i = 0; i < params.length; i++) {
            Object p = params[i];
            if (p == null) {
                // L'ancien driver Oracle (classes12) ne sait pas deduire le type
                // d'un setObject(i, null) : il leve ORA-17004 "Type de colonne
                // non valide". setNull avec un type explicite fonctionne.
                ps.setNull(i + 1, java.sql.Types.VARCHAR);
            } else if (p instanceof java.sql.Date) {
                ps.setDate(i + 1, (java.sql.Date) p);
            } else if (p instanceof Timestamp) {
                ps.setTimestamp(i + 1, (Timestamp) p);
            } else if (p instanceof Integer) {
                ps.setInt(i + 1, ((Integer) p).intValue());
            } else if (p instanceof Double) {
                ps.setDouble(i + 1, ((Double) p).doubleValue());
            } else {
                ps.setString(i + 1, p.toString());
            }
        }
    }

    /**
     * Date du jour sans composante horaire (00:00:00.000).
     *
     * Attention : new java.sql.Date(System.currentTimeMillis()) conserve
     * l'heure courante dans getTime(). Comme java.util.Date.before() compare
     * les millisecondes, cette valeur rendait toute projection du jour
     * "deja passee" des que l'heure courante depassait minuit.
     */
    public static java.sql.Date today() {
        return dateOnly(new Date());
    }

    /** Tronque une date a minuit (00:00:00.000). */
    public static java.sql.Date dateOnly(Date value) {
        if (value == null) {
            return null;
        }
        Calendar cal = Calendar.getInstance();
        cal.setTime(value);
        cal.set(Calendar.HOUR_OF_DAY, 0);
        cal.set(Calendar.MINUTE, 0);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        return new java.sql.Date(cal.getTimeInMillis());
    }

    public static Timestamp now() {
        return new Timestamp(System.currentTimeMillis());
    }

    public static Timestamp addMinutes(Timestamp base, int minutes) {
        if (base == null) {
            base = now();
        }
        Calendar cal = Calendar.getInstance();
        cal.setTimeInMillis(base.getTime());
        cal.add(Calendar.MINUTE, minutes);
        return new Timestamp(cal.getTimeInMillis());
    }

    public static Timestamp parseTimestamp(String value) {
        if (value == null || value.trim().isEmpty()) {
            return null;
        }
        String v = value.trim().replace('T', ' ');
        String[] formats = {"yyyy-MM-dd HH:mm", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"};
        for (int i = 0; i < formats.length; i++) {
            try {
                SimpleDateFormat sdf = new SimpleDateFormat(formats[i]);
                sdf.setLenient(false);
                Date d = sdf.parse(v);
                return new Timestamp(d.getTime());
            } catch (Exception ignore) {
            }
        }
        return null;
    }

    public static String formatTimestamp(Timestamp value) {
        if (value == null) {
            return "";
        }
        return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm").format(new Date(value.getTime()));
    }

    public static String formatDate(java.sql.Date value) {
        if (value == null) {
            return "";
        }
        return new SimpleDateFormat("yyyy-MM-dd").format(new Date(value.getTime()));
    }

    public static String currentHeure() {
        return new SimpleDateFormat("HH:mm").format(new Date());
    }

    /** Retourne le nombre de minutes depuis 00:00, ou -1 si l'heure est invalide. */
    public static int heureEnMinutes(String heure) {
        if (heure == null || !heure.matches("[0-2][0-9]:[0-5][0-9]")) {
            return -1;
        }
        int h = Integer.parseInt(heure.substring(0, 2));
        int m = Integer.parseInt(heure.substring(3, 5));
        if (h > 23) {
            return -1;
        }
        return h * 60 + m;
    }

    /**
     * Debut de seance = date + heure de debut (HH:mm), a la seconde 0.
     * Retourne null si la date ou l'heure est invalide.
     */
    public static Timestamp debutSeance(Date daty, String heureDebut) {
        if (daty == null) {
            return null;
        }
        int minutes = heureEnMinutes(heureDebut);
        if (minutes < 0) {
            return null;
        }
        Calendar cal = Calendar.getInstance();
        cal.setTime(daty);
        cal.set(Calendar.HOUR_OF_DAY, minutes / 60);
        cal.set(Calendar.MINUTE, minutes % 60);
        cal.set(Calendar.SECOND, 0);
        cal.set(Calendar.MILLISECOND, 0);
        return new Timestamp(cal.getTimeInMillis());
    }
}
