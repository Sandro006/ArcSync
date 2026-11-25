<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="_common.jsp" %>
<%--
    Tableau de bord du module Cinema.
--%>
<%
    String lien = (String) session.getValue("lien");
    String erreur = null;
    int nbFilms = 0, nbSalles = 0, nbSeancesJour = 0, nbBilletsJour = 0, nbReservations = 0;
    double recetteJour = 0;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
    try {
        c = new UtilDB().GetConn();

        ps = c.prepareStatement("SELECT COUNT(*) FROM CINEMA_FILM WHERE ETAT = 1");
        rs = ps.executeQuery();
        if (rs.next()) nbFilms = rs.getInt(1);
        cinClose(rs, ps, null); rs = null; ps = null;

        ps = c.prepareStatement("SELECT COUNT(*) FROM CINEMA_SALLE WHERE ETAT = 1");
        rs = ps.executeQuery();
        if (rs.next()) nbSalles = rs.getInt(1);
        cinClose(rs, ps, null); rs = null; ps = null;

        ps = c.prepareStatement("SELECT COUNT(*) FROM CINEMA_PROJECTION WHERE ETAT <> 0 AND TRUNC(DATY) = TRUNC(?)");
        ps.setDate(1, today);
        rs = ps.executeQuery();
        if (rs.next()) nbSeancesJour = rs.getInt(1);
        cinClose(rs, ps, null); rs = null; ps = null;

        ps = c.prepareStatement(
                "SELECT COUNT(*), NVL(SUM(b.PRIX),0) FROM CINEMA_BILLET b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " WHERE ab.ETAT = 11 AND b.ETAT = 11 AND b.STATUT IN (1,2)"
                + " AND TRUNC(ab.DATY) = TRUNC(?)");
        ps.setDate(1, today);
        rs = ps.executeQuery();
        if (rs.next()) { nbBilletsJour = rs.getInt(1); recetteJour = rs.getDouble(2); }
        cinClose(rs, ps, null); rs = null; ps = null;

        ps = c.prepareStatement("SELECT COUNT(*) FROM CINEMA_RESERVATION WHERE ETAT IN (1,11) AND STATUT IN (1,2)");
        rs = ps.executeQuery();
        if (rs.next()) nbReservations = rs.getInt(1);
        cinClose(rs, ps, null); rs = null; ps = null;
%>
<div class="content-wrapper">
<section class="content-header">
    <h1>Cin&eacute;ma</h1>
    <p>Pr&eacute;paration des projections, r&eacute;servations et vente / contr&ocirc;le des billets.</p>
</section>

<div class="col-md-12">
    <div class="row">
        <div class="col-md-3">
            <div class="cardradius" style="padding:16px">
                <h4>Projections aujourd'hui</h4>
                <div style="font-size:28px;font-weight:bold"><%= nbSeancesJour %></div>
                <a class="btn btn-primary btn-sm" href="<%=lien%>?but=cinema/projection/projection-liste.jsp">Voir les projections</a>
            </div>
        </div>
        <div class="col-md-3">
            <div class="cardradius" style="padding:16px">
                <h4>Billets vendus aujourd'hui</h4>
                <div style="font-size:28px;font-weight:bold"><%= nbBilletsJour %></div>
                <div>Recette : <b><%= cinMoney(recetteJour) %> Ar</b></div>
                <a class="btn btn-primary btn-sm" href="<%=lien%>?but=cinema/billet/billet-vente.jsp">Vendre des billets</a>
            </div>
        </div>
        <div class="col-md-3">
            <div class="cardradius" style="padding:16px">
                <h4>R&eacute;servations actives</h4>
                <div style="font-size:28px;font-weight:bold"><%= nbReservations %></div>
                <a class="btn btn-primary btn-sm" href="<%=lien%>?but=cinema/reservation/reservation-liste.jsp">Voir les r&eacute;servations</a>
            </div>
        </div>
        <div class="col-md-3">
            <div class="cardradius" style="padding:16px">
                <h4>Parc</h4>
                <div><b><%= nbFilms %></b> film(s) actif(s)</div>
                <div><b><%= nbSalles %></b> salle(s) active(s)</div>
                <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/configuration/salle-liste.jsp">Configuration</a>
            </div>
        </div>
    </div>
</div>

<div class="col-md-12 cardradius" style="margin-top:16px;padding:16px">
    <h4>S&eacute;ances du jour</h4>
    <table class="table table-bordered">
        <tr>
            <th>Heure</th><th>Film</th><th>Salle</th><th>Statut</th>
            <th>Places vendues</th><th>R&eacute;serv&eacute;es</th><th>Disponibles</th><th>Recette</th><th></th>
        </tr>
        <%
            ps = c.prepareStatement(
                    "SELECT * FROM CINEMA_PROJECTION_LIB"
                    + " WHERE TRUNC(DATY) = TRUNC(?) AND ETAT <> 0"
                    + " ORDER BY HEUREDEBUT");
            ps.setDate(1, today);
            rs = ps.executeQuery();
            boolean any = false;
            while (rs.next()) {
                any = true;
                String id = rs.getString("ID");
        %>
        <tr>
            <td><%= cinH(rs.getString("HEUREDEBUT")) %> - <%= cinH(rs.getString("HEUREFIN")) %></td>
            <td><%= cinH(rs.getString("IDFILMLIB")) %></td>
            <td><%= cinH(rs.getString("IDSALLELIB")) %></td>
            <td><%= cinH(rs.getString("STATUTLIB")) %></td>
            <td><%= rs.getInt("NBPLACESVENDUES") %></td>
            <td><%= rs.getInt("NBPLACESRESERVEES") %></td>
            <td><%= rs.getInt("NBPLACESDISPONIBLES") %></td>
            <td><%= cinMoney(rs.getDouble("RECETTE")) %></td>
            <td><a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=id%>">Fiche</a></td>
        </tr>
        <%
            }
            if (!any) {
        %>
        <tr><td colspan="9">Aucune s&eacute;ance aujourd'hui.</td></tr>
        <%
            }
        %>
    </table>
</div>

<div class="col-md-12" style="margin-top:12px">
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/projection/projection-saisie.jsp">Pr&eacute;parer une projection</a>
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/film/film-saisie.jsp">Ajouter un film</a>
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/billet/billet-vente.jsp">Caisse billets</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/billet/billet-controle.jsp">Contr&ocirc;le &agrave; l'entr&eacute;e</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/projection/projection-planning.jsp">Planning</a>
</div>
<%
    } catch (Exception e) {
        erreur = e.getMessage();
        e.printStackTrace();
    } finally {
        cinClose(rs, ps, c);
    }
    if (erreur != null) {
%>
<div class="col-md-12"><div class="alert alert-danger">Erreur : <%= cinH(erreur) %></div></div>
<%
    }
%>
</div>
