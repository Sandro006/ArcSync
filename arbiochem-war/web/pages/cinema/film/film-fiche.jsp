<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Fiche d'un film et de ses projections.
--%>
<%
    String lien = (String) session.getValue("lien");
    String id = cinS(request.getParameter("id"));
    String erreur = null;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    boolean found = false;
    java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
%>
<div class="content-wrapper">
<section class="content-header">
    <h1><a href="<%=lien%>?but=cinema/film/film-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>
        Fiche film</h1>
</section>

<div class="col-md-12">
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement("SELECT * FROM CINEMA_FILM_LIB WHERE ID = ?");
        ps.setString(1, id);
        rs = ps.executeQuery();
        if (rs.next()) {
            found = true;
%>
    <div class="cardradius" style="padding:16px">
        <div class="row">
            <div class="col-md-8">
                <h3><%=cinH(rs.getString("TITRE"))%></h3>
                <p><i><%=cinH(rs.getString("TITREORIGINAL"))%></i></p>
                <table class="table">
                    <tr><th style="width:200px">Identifiant</th><td><%=cinH(id)%></td></tr>
                    <tr><th>Genre</th><td><%=cinH(rs.getString("IDGENRELIB"))%></td></tr>
                    <tr><th>Dur&eacute;e</th><td><%= rs.getInt("DUREE") %> min</td></tr>
                    <tr><th>Langue</th><td><%=cinH(rs.getString("LANGUE"))%></td></tr>
                    <tr><th>Ann&eacute;e</th><td><%= rs.getInt("ANNEE") %></td></tr>
                    <tr><th>R&eacute;alisateur</th><td><%=cinH(rs.getString("REALISATEUR"))%></td></tr>
                    <tr><th>Acteurs</th><td><%=cinH(rs.getString("ACTEURS"))%></td></tr>
                    <tr><th>Classification</th><td><%=cinH(rs.getString("CLASSIFICATION"))%></td></tr>
                    <tr><th>&Eacute;tat</th><td><%=cinH(rs.getString("ETATLIB"))%></td></tr>
                    <tr><th>Synopsis</th><td><%=cinH(rs.getString("SYNOPSIS"))%></td></tr>
                </table>
                <div>
                    <a class="btn btn-primary" href="<%=lien%>?but=cinema/film/film-saisie.jsp&id=<%=cinH(id)%>">Modifier</a>
                    <a class="btn btn-primary" href="<%=lien%>?but=cinema/projection/projection-saisie.jsp&idFilm=<%=cinH(id)%>">Programmer une projection</a>
                    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/film/film-liste.jsp">Liste des films</a>
                </div>
            </div>
            <div class="col-md-4">
<%
            if (!cinS(rs.getString("AFFICHE")).isEmpty()) {
%>
                <img src="<%=cinH(rs.getString("AFFICHE"))%>" alt="Affiche" style="max-width:100%">
<%
            }
%>
            </div>
        </div>
    </div>
<%
        } else {
%>
    <div class="alert alert-warning">Film introuvable : <%=cinH(id)%></div>
<%
        }
        cinClose(rs, ps, null); rs = null; ps = null;
%>

<div class="cardradius" style="padding:16px;margin-top:16px">
    <h4>Projections de ce film</h4>
    <table class="table table-bordered">
        <tr><th>Date</th><th>Heure</th><th>Salle</th><th>Statut</th><th>Disponibles</th><th>Recette</th><th></th></tr>
<%
        ps = c.prepareStatement(
                "SELECT * FROM CINEMA_PROJECTION_LIB WHERE IDFILM = ? AND ETAT <> 0"
                + " ORDER BY DATY DESC, HEUREDEBUT");
        ps.setString(1, id);
        rs = ps.executeQuery();
        boolean any = false;
        while (rs.next()) {
            any = true;
            String idProj = rs.getString("ID");
%>
        <tr>
            <td><%=cinDateFmt(rs.getDate("DATY"))%></td>
            <td><%=cinH(rs.getString("HEUREDEBUT"))%></td>
            <td><%=cinH(rs.getString("IDSALLELIB"))%></td>
            <td><%=cinH(rs.getString("STATUTLIB"))%></td>
            <td><%= rs.getInt("NBPLACESDISPONIBLES") %></td>
            <td><%=cinMoney(rs.getDouble("RECETTE"))%></td>
            <td><a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=idProj%>">Fiche</a></td>
        </tr>
<%
        }
        if (!any) {
%>
        <tr><td colspan="7">Aucune projection.</td></tr>
<%
        }
%>
    </table>
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
    <div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div>
<%
    }
%>
</div>
</div>
