<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Fiche d'une salle : caracteristiques, places et prochaines projections.
--%>
<%
    String lien = (String) session.getValue("lien");
    String id = cinS(request.getParameter("id"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String nom = "", adresse = "", etatLib = "";
    int capacite = 0, nbPlaces = 0;
    boolean found = false;
    java.sql.Date today = new java.sql.Date(System.currentTimeMillis());
%>
<div class="content-wrapper">
<section class="content-header">
    <h1><a href="<%=lien%>?but=cinema/configuration/salle-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>
        Fiche salle</h1>
</section>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>

<div class="col-md-12">
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement("SELECT * FROM CINEMA_SALLE_LIB WHERE ID = ?");
        ps.setString(1, id);
        rs = ps.executeQuery();
        if (rs.next()) {
            found = true;
            nom = cinS(rs.getString("NOM"));
            adresse = cinS(rs.getString("ADRESSE"));
            capacite = rs.getInt("CAPACITE");
            nbPlaces = rs.getInt("NBPLACESLIB");
            etatLib = cinS(rs.getString("ETATLIB"));
        }
        cinClose(rs, ps, null); rs = null; ps = null;
%>
<% if (!found) { %>
    <div class="alert alert-warning">Salle introuvable : <%=cinH(id)%></div>
<% } else { %>
    <div class="cardradius" style="padding:16px">
        <h3><%=cinH(nom)%></h3>
        <table class="table">
            <tr><th style="width:220px">Identifiant</th><td><%=cinH(id)%></td></tr>
            <tr><th>Adresse</th><td><%=cinH(adresse)%></td></tr>
            <tr><th>Capacit&eacute;</th><td><%=capacite%></td></tr>
            <tr><th>Places actives</th><td><%=nbPlaces%></td></tr>
            <tr><th>&Eacute;tat</th><td><%=cinH(etatLib)%></td></tr>
        </table>
        <div>
            <a class="btn btn-primary" href="<%=lien%>?but=cinema/configuration/salle-saisie.jsp&id=<%=cinH(id)%>">Modifier la salle</a>
            <a class="btn btn-primary" href="<%=lien%>?but=cinema/configuration/place-saisie.jsp&idSalle=<%=cinH(id)%>">Ajouter une place</a>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/place-liste.jsp&idSalle=<%=cinH(id)%>">Toutes les places</a>
        </div>
    </div>
<% } %>

<div class="cardradius" style="padding:16px;margin-top:16px">
    <h4>Places</h4>
    <table class="table table-bordered">
        <tr><th>Place</th><th>Rang</th><th>Colonne</th><th>Cat&eacute;gorie</th><th>&Eacute;tat</th><th>Action</th></tr>
<%
        ps = c.prepareStatement(
                "SELECT * FROM CINEMA_PLACE_LIB WHERE IDMERE = ? ORDER BY RANG, COLONNE, NUMERO");
        ps.setString(1, id);
        rs = ps.executeQuery();
        boolean anyPlace = false;
        while (rs.next()) {
            anyPlace = true;
            String idPlace = rs.getString("ID");
%>
        <tr>
            <td><%=cinH(rs.getString("NUMERO"))%></td>
            <td><%=cinH(rs.getString("RANG"))%></td>
            <td><%= rs.getInt("COLONNE") %></td>
            <td><%=cinH(rs.getString("IDCATEGORIEPLACELIB"))%></td>
            <td><%=cinH(rs.getString("ETATLIB"))%></td>
            <td>
                <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/configuration/place-saisie.jsp&id=<%=idPlace%>">Modifier</a>
                <form action="<%=lien%>?but=cinema/configuration/place-saisie.jsp" method="post" style="display:inline"
                      onsubmit="return confirm('Supprimer cette place ?');">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="id" value="<%=idPlace%>">
                    <button type="submit" class="btn btn-danger btn-sm">Supprimer</button>
                </form>
            </td>
        </tr>
<%
        }
        if (!anyPlace) {
%>
        <tr><td colspan="6">Aucune place enregistr&eacute;e.</td></tr>
<%
        }
        cinClose(rs, ps, null); rs = null; ps = null;
%>
    </table>
</div>

<div class="cardradius" style="padding:16px;margin-top:16px">
    <h4>Prochaines projections</h4>
    <table class="table table-bordered">
        <tr><th>Date</th><th>Heure</th><th>Film</th><th>Statut</th><th></th></tr>
<%
        ps = c.prepareStatement(
                "SELECT * FROM CINEMA_PROJECTION_LIB WHERE IDSALLE = ? AND DATY >= ? AND ETAT <> 0"
                + " ORDER BY DATY, HEUREDEBUT");
        ps.setString(1, id);
        ps.setDate(2, today);
        rs = ps.executeQuery();
        boolean anyProj = false;
        while (rs.next()) {
            anyProj = true;
            String idProj = rs.getString("ID");
%>
        <tr>
            <td><%=cinDateFmt(rs.getDate("DATY"))%></td>
            <td><%=cinH(rs.getString("HEUREDEBUT"))%> - <%=cinH(rs.getString("HEUREFIN"))%></td>
            <td><%=cinH(rs.getString("IDFILMLIB"))%></td>
            <td><%=cinH(rs.getString("STATUTLIB"))%></td>
            <td><a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=idProj%>">Fiche</a></td>
        </tr>
<%
        }
        if (!anyProj) {
%>
        <tr><td colspan="5">Aucune projection &agrave; venir.</td></tr>
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
