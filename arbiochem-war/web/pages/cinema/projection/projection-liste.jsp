<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Liste des projections.
--%>
<%
    String lien = (String) session.getValue("lien");
    String d1P = cinS(request.getParameter("d1"));
    String d2P = cinS(request.getParameter("d2"));
    String idSalle = cinS(request.getParameter("idSalle"));
    String statutP = cinS(request.getParameter("statut"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    java.sql.Date d1 = cinDate(d1P);
    java.sql.Date d2 = cinDate(d2P);
%>
<div class="content-wrapper">
<section class="content-header"><h1>Projections</h1></section>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/projection/projection-liste.jsp" method="get">
        <input type="hidden" name="but" value="cinema/projection/projection-liste.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Du</label>
                <input class="form-control" type="date" name="d1" value="<%=cinH(d1P)%>"></div>
            <div class="form-input"><label class="input-label">Au</label>
                <input class="form-control" type="date" name="d2" value="<%=cinH(d2P)%>"></div>
            <div class="form-input"><label class="input-label">Salle</label>
                <select class="form-control" name="idSalle">
                    <option value="">Toutes</option>
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement("SELECT ID, NOM FROM CINEMA_SALLE ORDER BY NOM");
        rs = ps.executeQuery();
        while (rs.next()) {
            String sid = rs.getString("ID");
%>
                    <option value="<%=cinH(sid)%>"<%=cinSelected(sid, idSalle)%>><%=cinH(rs.getString("NOM"))%></option>
<%
        }
        cinClose(rs, ps, c); rs = null; ps = null; c = null;
    } catch (Exception e) {
        erreur = e.getMessage();
    } finally {
        cinClose(rs, ps, c); rs = null; ps = null; c = null;
    }
%>
                </select></div>
            <div class="form-input"><label class="input-label">Statut</label>
                <select class="form-control" name="statut">
                    <option value="">Tous</option>
                    <option value="1"<%=cinSelected("1", statutP)%>>Pr&eacute;par&eacute;e</option>
                    <option value="2"<%=cinSelected("2", statutP)%>>Ouverte</option>
                    <option value="3"<%=cinSelected("3", statutP)%>>Cl&ocirc;tur&eacute;e</option>
                    <option value="0"<%=cinSelected("0", statutP)%>>Annul&eacute;e</option>
                </select></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary">Filtrer</button></div>
        </div>
    </form>
</div>

<div class="col-md-12">
    <a class="btn btn-primary pull-right" href="<%=lien%>?but=cinema/projection/projection-saisie.jsp">
        <i class="material-symbols-rounded">add</i> Nouvelle projection
    </a>
    <a class="btn btn-secondary pull-right" style="margin-right:8px" href="<%=lien%>?but=cinema/projection/projection-planning.jsp">Planning</a>
</div>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>

<div class="col-md-12 cardradius" style="margin-top:16px">
<%
    try {
        c = new UtilDB().GetConn();
        String sql = "SELECT * FROM CINEMA_PROJECTION_LIB WHERE 1=1";
        if (d1 != null) sql += " AND DATY >= ?";
        if (d2 != null) sql += " AND DATY <= ?";
        if (!idSalle.trim().isEmpty()) sql += " AND IDSALLE = ?";
        if (!statutP.trim().isEmpty()) sql += " AND STATUT = ?";
        sql += " ORDER BY DATY, HEUREDEBUT, IDSALLE";
        ps = c.prepareStatement(sql);
        int i = 1;
        if (d1 != null) ps.setDate(i++, d1);
        if (d2 != null) ps.setDate(i++, d2);
        if (!idSalle.trim().isEmpty()) ps.setString(i++, idSalle);
        if (!statutP.trim().isEmpty()) ps.setInt(i++, cinI(statutP));
        rs = ps.executeQuery();
%>
<table class="table table-bordered">
    <tr><th>Date</th><th>Heure</th><th>Film</th><th>Salle</th><th>Statut</th>
        <th>Vendues</th><th>R&eacute;serv&eacute;es</th><th>Dispo.</th><th>Recette</th><th>Action</th></tr>
<%
        boolean any = false;
        while (rs.next()) {
            any = true;
            String id = rs.getString("ID");
            int statut = rs.getInt("STATUT");
%>
    <tr>
        <td><%=cinDateFmt(rs.getDate("DATY"))%></td>
        <td><%=cinH(rs.getString("HEUREDEBUT"))%> - <%=cinH(rs.getString("HEUREFIN"))%></td>
        <td><a href="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=id%>"><%=cinH(rs.getString("IDFILMLIB"))%></a></td>
        <td><%=cinH(rs.getString("IDSALLELIB"))%></td>
        <td><%=cinH(rs.getString("STATUTLIB"))%></td>
        <td><%= rs.getInt("NBPLACESVENDUES") %></td>
        <td><%= rs.getInt("NBPLACESRESERVEES") %></td>
        <td><%= rs.getInt("NBPLACESDISPONIBLES") %></td>
        <td><%=cinMoney(rs.getDouble("RECETTE"))%></td>
        <td>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=id%>">Fiche</a>
            <% if (statut == 2) { %>
            <a class="btn btn-primary btn-sm" href="<%=lien%>?but=cinema/billet/billet-vente.jsp&idProjection=<%=id%>">Caisse</a>
            <% } %>
        </td>
    </tr>
<%
        }
        if (!any) {
%>
    <tr><td colspan="10">Aucune projection pour ces crit&egrave;res.</td></tr>
<%
        }
%>
</table>
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
