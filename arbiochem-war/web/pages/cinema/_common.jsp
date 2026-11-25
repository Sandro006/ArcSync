<%@ page import="user.UserEJB" %>
<%@ page import="utilitaire.UtilDB" %>
<%@ page import="utilitaire.Utilitaire" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>
<%--
    Helpers communs aux pages du module Cinema.
    A inclure en tete de chaque page avec <%@ include file="_common.jsp" %>
    (ou ../_common.jsp depuis un sous-dossier).
--%>
<%!
    static String cinS(String v) {
        return v == null ? "" : v;
    }

    static String cinH(String v) {
        if (v == null) return "";
        String s = v;
        s = s.replace("&", "&amp;");
        s = s.replace("<", "&lt;");
        s = s.replace(">", "&gt;");
        s = s.replace("\"", "&quot;");
        s = s.replace("'", "&#39;");
        return s;
    }

    static String cinJs(String v) {
        if (v == null) return "";
        String s = v;
        s = s.replace("\\", "\\\\");
        s = s.replace("'", "\\'");
        s = s.replace("\"", "\\\"");
        s = s.replace("\r", "");
        s = s.replace("\n", "\\n");
        s = s.replace("<", "\\u003c");
        s = s.replace(">", "\\u003e");
        s = s.replace("&", "\\u0026");
        return s;
    }

    static int cinI(String v) {
        if (v == null || v.trim().isEmpty()) return 0;
        try { return Integer.parseInt(v.trim()); } catch (Exception e) { return 0; }
    }

    static double cinD(String v) {
        if (v == null || v.trim().isEmpty()) return 0;
        try { return Double.parseDouble(v.trim().replace(" ", "").replace(",", ".")); }
        catch (Exception e) { return 0; }
    }

    static java.sql.Date cinDate(String v) {
        if (v == null || v.trim().isEmpty()) return null;
        try { return java.sql.Date.valueOf(v.trim()); } catch (Exception e) { return null; }
    }

    static java.sql.Timestamp cinTs(String v) {
        if (v == null || v.trim().isEmpty()) return null;
        try {
            String s = v.trim().replace('T', ' ');
            if (s.length() == 16) s = s + ":00";
            return java.sql.Timestamp.valueOf(s);
        } catch (Exception e) { return null; }
    }

    static String cinDateFmt(java.sql.Date d) {
        if (d == null) return "";
        return new SimpleDateFormat("dd/MM/yyyy").format(d);
    }

    static String cinTsFmt(java.sql.Timestamp t) {
        if (t == null) return "";
        return new SimpleDateFormat("dd/MM/yyyy HH:mm").format(t);
    }

    static String cinMoney(double v) {
        return Utilitaire.formaterAr(v);
    }

    static String cinSelected(String value, String current) {
        return value != null && value.equals(current) ? " selected" : "";
    }

    static String cinChecked(boolean b) {
        return b ? " checked" : "";
    }

    static String cinHeure(java.sql.Timestamp t) {
        if (t == null) return "";
        return new SimpleDateFormat("HH:mm").format(t);
    }

    static void cinClose(ResultSet rs, PreparedStatement ps, Connection c) {
        try { if (rs != null) rs.close(); } catch (Exception ignore) {}
        try { if (ps != null) ps.close(); } catch (Exception ignore) {}
        try { if (c != null) c.close(); } catch (Exception ignore) {}
    }

    /**
     * Condition SQL : la seance (DATY + HEUREDEBUT) n'a pas encore commence.
     * La table interrogee doit exposer les colonnes DATY et HEUREDEBUT.
     */
    static final String cinSqlSeanceFuture =
            " (DATY + (TO_DATE(HEUREDEBUT,'HH24:MI') - TRUNC(TO_DATE(HEUREDEBUT,'HH24:MI')))) >= SYSDATE ";
%>
