<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.projection.ProjectionService" %>
<%--
    Fiche d'une projection : details, tarifs, remplissage, actions de statut.
--%>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();
    String id = cinS(request.getParameter("id"));
    String action = cinS(request.getParameter("action"));

    String message = null;
    String erreur = null;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    if (!action.isEmpty()) {
        try {
            if ("ouvrir".equals(action)) {
                ProjectionService.ouvrirVente(userId, id);
                message = "Vente ouverte pour cette projection.";
            } else if ("cloturer".equals(action)) {
                ProjectionService.cloturerProjection(userId, id);
                message = "Projection clôturée.";
            } else if ("annuler".equals(action)) {
                ProjectionService.annulerProjection(userId, id);
                message = "Projection annulée.";
            }
        } catch (Exception e) {
            erreur = e.getMessage();
            e.printStackTrace();
        }
    }

    boolean found = false;
    String statutLib = "";
    int statut = 0;
    String etatLib = "";
    int etat = 0;
%>
<div class="content-wrapper">
<section class="content-header">
    <h1><a href="<%=lien%>?but=cinema/projection/projection-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>
        Fiche projection</h1>
</section>

<div class="col-md-12">
<% if (message != null) { %><div class="alert alert-success"><%=message%></div><% } %>
<% if (erreur != null) { %><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div><% } %>

<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement("SELECT * FROM CINEMA_PROJECTION_LIB WHERE ID = ?");
        ps.setString(1, id);
        rs = ps.executeQuery();
        if (rs.next()) {
            found = true;
            statut = rs.getInt("STATUT");
            statutLib = cinS(rs.getString("STATUTLIB"));
            etat = rs.getInt("ETAT");
            etatLib = cinS(rs.getString("ETATLIB"));
%>
    <div class="cardradius" style="padding:16px">
        <h3><%=cinH(rs.getString("IDFILMLIB"))%></h3>
        <table class="table">
            <tr><th style="width:220px">Identifiant</th><td><%=cinH(id)%></td></tr>
            <tr><th>Date</th><td><%=cinDateFmt(rs.getDate("DATY"))%></td></tr>
            <tr><th>Horaire</th><td><%=cinH(rs.getString("HEUREDEBUT"))%> - <%=cinH(rs.getString("HEUREFIN"))%></td></tr>
            <tr><th>Salle</th><td><%=cinH(rs.getString("IDSALLELIB"))%></td></tr>
            <tr><th>Genre</th><td><%=cinH(rs.getString("IDGENRELIB"))%></td></tr>
            <tr><th>Format / version</th><td><%=cinH(rs.getString("FORMAT"))%> / <%=cinH(rs.getString("VERSION"))%></td></tr>
            <tr><th>Prix de base</th><td><%=cinMoney(rs.getDouble("PRIXBASE"))%> Ar</td></tr>
            <tr><th>Places ouvertes</th><td><%= rs.getInt("NBPLACES") %></td></tr>
            <tr><th>Vendues</th><td><%= rs.getInt("NBPLACESVENDUES") %></td></tr>
            <tr><th>R&eacute;serv&eacute;es</th><td><%= rs.getInt("NBPLACESRESERVEES") %></td></tr>
            <tr><th>Disponibles</th><td><%= rs.getInt("NBPLACESDISPONIBLES") %></td></tr>
            <tr><th>Recette</th><td><b><%=cinMoney(rs.getDouble("RECETTE"))%> Ar</b></td></tr>
            <tr><th>Statut</th><td><%=cinH(statutLib)%></td></tr>
            <tr><th>&Eacute;tat</th><td><%=cinH(etatLib)%></td></tr>
            <tr><th>Remarque</th><td><%=cinH(rs.getString("REMARQUE"))%></td></tr>
        </table>

        <div style="margin-top:8px">
            <% if (statut == 1 && etat != 0 && etat != 9) { %>
            <form action="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=cinH(id)%>" method="post" style="display:inline">
                <input type="hidden" name="action" value="ouvrir">
                <button type="submit" class="btn btn-primary">Ouvrir la vente</button>
            </form>
            <% } %>
            <% if (statut == 2) { %>
            <a class="btn btn-primary" href="<%=lien%>?but=cinema/billet/billet-vente.jsp&idProjection=<%=cinH(id)%>">Caisse billets</a>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/reservation/reservation-liste.jsp&idProjection=<%=cinH(id)%>">R&eacute;servations</a>
            <form action="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=cinH(id)%>" method="post" style="display:inline"
                  onsubmit="return confirm('Cl&ocirc;turer cette projection ?');">
                <input type="hidden" name="action" value="cloturer">
                <button type="submit" class="btn btn-secondary">Cl&ocirc;turer</button>
            </form>
            <% } %>
            <% if (statut != 0 && etat != 9) { %>
            <form action="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=cinH(id)%>" method="post" style="display:inline"
                  onsubmit="return confirm('Annuler cette projection ?');">
                <input type="hidden" name="action" value="annuler">
                <button type="submit" class="btn btn-danger">Annuler la projection</button>
            </form>
            <% } %>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/projection/projection-saisie.jsp">Nouvelle projection</a>
        </div>
    </div>
<%
        } else {
%>
    <div class="alert alert-warning">Projection introuvable : <%=cinH(id)%></div>
<%
        }
        cinClose(rs, ps, null); rs = null; ps = null;
%>

<div class="cardradius" style="padding:16px;margin-top:16px">
    <h4>Tarifs</h4>
    <table class="table table-bordered">
        <tr><th>Cat&eacute;gorie</th><th>Rang</th><th>Prix</th><th>Quota</th><th>Quota restant</th><th>&Eacute;tat</th></tr>
<%
        ps = c.prepareStatement(
                "SELECT * FROM CINEMA_PROJECTIONTARIF_LIB WHERE IDMERE = ? ORDER BY IDCATEGORIEPLACELIB, RANG");
        ps.setString(1, id);
        rs = ps.executeQuery();
        boolean anyTarif = false;
        while (rs.next()) {
            anyTarif = true;
%>
        <tr>
            <td><%=cinH(rs.getString("IDCATEGORIEPLACELIB"))%></td>
            <td><%=cinH(rs.getString("RANGLIB"))%></td>
            <td><%=cinMoney(rs.getDouble("PRIX"))%> Ar</td>
            <td><%= rs.getInt("QUOTA") %></td>
            <td><%= rs.getInt("QUOTARESTANT") == 0 && rs.getInt("QUOTA") == 0 ? "Illimit&eacute;" : String.valueOf(rs.getInt("QUOTARESTANT")) %></td>
            <td><%=cinH(rs.getString("ETATLIB"))%></td>
        </tr>
<%
        }
        if (!anyTarif) {
%>
        <tr><td colspan="6">Aucun tarif.</td></tr>
<%
        }
%>
    </table>
</div>

<div class="cardradius" style="padding:16px;margin-top:16px">
    <h4>Billets vendus</h4>
    <table class="table table-bordered">
        <tr><th>Billet</th><th>Place</th><th>Cat&eacute;gorie</th><th>Prix</th><th>Statut</th><th>&Eacute;tat</th><th></th></tr>
<%
        ps = c.prepareStatement(
                "SELECT * FROM CINEMA_BILLET_LIB WHERE IDPROJECTIONLIB = ? ORDER BY NUMERO");
        ps.setString(1, id);
        rs = ps.executeQuery();
        boolean anyBillet = false;
        while (rs.next()) {
            anyBillet = true;
            String bid = rs.getString("ID");
%>
        <tr>
            <td><%=cinH(rs.getString("NUMERO"))%></td>
            <td><%=cinH(rs.getString("IDPLACELIB"))%></td>
            <td><%=cinH(rs.getString("IDCATEGORIEPLACELIB"))%></td>
            <td><%=cinMoney(rs.getDouble("PRIX"))%></td>
            <td><%=cinH(rs.getString("STATUTLIB"))%></td>
            <td><%=cinH(rs.getString("ETATLIB"))%></td>
            <td><a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/billet/billet-fiche.jsp&id=<%=bid%>">Fiche</a></td>
        </tr>
<%
        }
        if (!anyBillet) {
%>
        <tr><td colspan="7">Aucun billet.</td></tr>
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
%>
</div>
</div>
