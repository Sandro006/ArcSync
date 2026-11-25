<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Liste des genres cinematographiques.
--%>
<%
    String lien = (String) session.getValue("lien");
    String q = cinS(request.getParameter("q"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>
<div class="content-wrapper">
<section class="content-header"><h1>Genres</h1></section>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/configuration/genre-liste.jsp" method="get">
        <input type="hidden" name="but" value="cinema/configuration/genre-liste.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Recherche</label>
                <input class="form-control" type="text" name="q" value="<%=cinH(q)%>" placeholder="Nom du genre"></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary">Filtrer</button></div>
        </div>
    </form>
</div>

<div class="col-md-12">
    <a class="btn btn-primary pull-right" href="<%=lien%>?but=cinema/configuration/genre-saisie.jsp">
        <i class="material-symbols-rounded">add</i> Nouveau genre
    </a>
</div>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>

<div class="col-md-12 cardradius" style="margin-top:16px">
<%
    try {
        c = new UtilDB().GetConn();
        String sql = "SELECT ID, VAL, DESCE, ETAT FROM CINEMA_GENRE";
        if (!q.trim().isEmpty()) sql += " WHERE UPPER(VAL) LIKE ?";
        sql += " ORDER BY VAL";
        ps = c.prepareStatement(sql);
        if (!q.trim().isEmpty()) ps.setString(1, "%" + q.trim().toUpperCase() + "%");
        rs = ps.executeQuery();
%>
<table class="table table-bordered">
    <tr><th>ID</th><th>Genre</th><th>Description</th><th>&Eacute;tat</th><th>Action</th></tr>
<%
        boolean any = false;
        while (rs.next()) {
            any = true;
            String id = rs.getString("ID");
%>
    <tr>
        <td><%=cinH(id)%></td>
        <td><%=cinH(rs.getString("VAL"))%></td>
        <td><%=cinH(rs.getString("DESCE"))%></td>
        <td><%= rs.getInt("ETAT") == 1 ? "Actif" : "Inactif" %></td>
        <td>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/configuration/genre-saisie.jsp&id=<%=id%>">Modifier</a>
            <form action="<%=lien%>?but=cinema/configuration/genre-saisie.jsp" method="post" style="display:inline"
                  onsubmit="return confirm('Supprimer ce genre ?');">
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
    <tr><td colspan="5">Aucun genre.</td></tr>
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
