<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Liste des places, filtrable par salle.
--%>
<%
    String lien = (String) session.getValue("lien");
    String idSalle = cinS(request.getParameter("idSalle"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>
<div class="content-wrapper">
<section class="content-header"><h1>Places</h1></section>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/configuration/place-liste.jsp" method="get">
        <input type="hidden" name="but" value="cinema/configuration/place-liste.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Salle</label>
                <select class="form-control" name="idSalle">
                    <option value="">Toutes les salles</option>
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement("SELECT ID, NOM FROM CINEMA_SALLE WHERE ETAT = 1 ORDER BY NOM");
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
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary">Filtrer</button></div>
        </div>
    </form>
</div>

<div class="col-md-12">
    <a class="btn btn-primary pull-right" href="<%=lien%>?but=cinema/configuration/place-saisie.jsp&idSalle=<%=cinH(idSalle)%>">
        <i class="material-symbols-rounded">add</i> Nouvelle place
    </a>
</div>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>

<div class="col-md-12 cardradius" style="margin-top:16px">
<%
    try {
        c = new UtilDB().GetConn();
        String sql = "SELECT * FROM CINEMA_PLACE_LIB";
        if (!idSalle.trim().isEmpty()) sql += " WHERE IDMERE = ?";
        sql += " ORDER BY SALLELIB, RANG, COLONNE, NUMERO";
        ps = c.prepareStatement(sql);
        if (!idSalle.trim().isEmpty()) ps.setString(1, idSalle);
        rs = ps.executeQuery();
%>
<table class="table table-bordered">
    <tr><th>ID</th><th>Salle</th><th>Place</th><th>Rang</th><th>Colonne</th><th>Cat&eacute;gorie</th><th>&Eacute;tat</th><th>Action</th></tr>
<%
        boolean any = false;
        while (rs.next()) {
            any = true;
            String id = rs.getString("ID");
%>
    <tr>
        <td><%=cinH(id)%></td>
        <td><%=cinH(rs.getString("SALLELIB"))%></td>
        <td><%=cinH(rs.getString("NUMERO"))%></td>
        <td><%=cinH(rs.getString("RANG"))%></td>
        <td><%= rs.getInt("COLONNE") %></td>
        <td><%=cinH(rs.getString("IDCATEGORIEPLACELIB"))%></td>
        <td><%=cinH(rs.getString("ETATLIB"))%></td>
        <td>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/configuration/place-saisie.jsp&id=<%=id%>">Modifier</a>
            <form action="<%=lien%>?but=cinema/configuration/place-saisie.jsp" method="post" style="display:inline"
                  onsubmit="return confirm('Supprimer cette place ?');">
                <input type="hidden" name="action" value="delete">
                <input type="hidden" name="id" value="<%=id%>">
                <button type="submit" class="btn btn-danger btn-sm">Supprimer</button>
            </form>
        </td>
    </tr>
<%
        }
        if (!any) {
%>
    <tr><td colspan="8">Aucune place.</td></tr>
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
