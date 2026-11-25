<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Liste des films.
--%>
<%
    String lien = (String) session.getValue("lien");
    String q = cinS(request.getParameter("q"));
    String idGenre = cinS(request.getParameter("idGenre"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>
<div class="content-wrapper">
<section class="content-header"><h1>Films</h1></section>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/film/film-liste.jsp" method="get">
        <input type="hidden" name="but" value="cinema/film/film-liste.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Titre</label>
                <input class="form-control" type="text" name="q" value="<%=cinH(q)%>"></div>
            <div class="form-input"><label class="input-label">Genre</label>
                <select class="form-control" name="idGenre">
                    <option value="">Tous les genres</option>
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement("SELECT ID, VAL FROM CINEMA_GENRE WHERE ETAT = 1 ORDER BY VAL");
        rs = ps.executeQuery();
        while (rs.next()) {
            String gid = rs.getString("ID");
%>
                    <option value="<%=cinH(gid)%>"<%=cinSelected(gid, idGenre)%>><%=cinH(rs.getString("VAL"))%></option>
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
    <a class="btn btn-primary pull-right" href="<%=lien%>?but=cinema/film/film-saisie.jsp">
        <i class="material-symbols-rounded">add</i> Nouveau film
    </a>
</div>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>

<div class="col-md-12 cardradius" style="margin-top:16px">
<%
    try {
        c = new UtilDB().GetConn();
        String sql = "SELECT * FROM CINEMA_FILM_LIB WHERE 1=1";
        if (!q.trim().isEmpty()) sql += " AND UPPER(TITRE) LIKE ?";
        if (!idGenre.trim().isEmpty()) sql += " AND IDGENRE = ?";
        sql += " ORDER BY TITRE";
        ps = c.prepareStatement(sql);
        int index = 1;
        if (!q.trim().isEmpty()) ps.setString(index++, "%" + q.trim().toUpperCase() + "%");
        if (!idGenre.trim().isEmpty()) ps.setString(index++, idGenre);
        rs = ps.executeQuery();
%>
<table class="table table-bordered">
    <tr><th>ID</th><th>Titre</th><th>Genre</th><th>Dur&eacute;e</th><th>Ann&eacute;e</th><th>Classification</th><th>&Eacute;tat</th><th>Action</th></tr>
<%
        boolean any = false;
        while (rs.next()) {
            any = true;
            String id = rs.getString("ID");
            int duree = rs.getInt("DUREE");
%>
    <tr>
        <td><%=cinH(id)%></td>
        <td><a href="<%=lien%>?but=cinema/film/film-fiche.jsp&id=<%=id%>"><%=cinH(rs.getString("TITRE"))%></a></td>
        <td><%=cinH(rs.getString("IDGENRELIB"))%></td>
        <td><%= duree %> min</td>
        <td><%= rs.getInt("ANNEE") %></td>
        <td><%=cinH(rs.getString("CLASSIFICATION"))%></td>
        <td><%=cinH(rs.getString("ETATLIB"))%></td>
        <td>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/film/film-saisie.jsp&id=<%=id%>">Modifier</a>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/projection/projection-saisie.jsp&idFilm=<%=id%>">Programmer</a>
            <form action="<%=lien%>?but=cinema/film/film-saisie.jsp" method="post" style="display:inline"
                  onsubmit="return confirm('Supprimer ce film ?');">
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
    <tr><td colspan="8">Aucun film.</td></tr>
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
