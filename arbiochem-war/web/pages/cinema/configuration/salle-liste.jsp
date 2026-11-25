<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Liste des salles.
--%>
<%
    String lien = (String) session.getValue("lien");
    String message = cinS(request.getParameter("msg"));
    String erreur = null;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>
<div class="content-wrapper">
<section class="content-header"><h1>Salles</h1></section>

<div class="col-md-12">
    <a class="btn btn-primary pull-right" href="<%=lien%>?but=cinema/configuration/salle-saisie.jsp">
        <i class="material-symbols-rounded">add</i> Nouvelle salle
    </a>
</div>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>

<div class="col-md-12 cardradius" style="margin-top:16px">
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement("SELECT * FROM CINEMA_SALLE_LIB ORDER BY NOM");
        rs = ps.executeQuery();
%>
<table class="table table-bordered">
    <tr><th>ID</th><th>Salle</th><th>Adresse</th><th>Capacit&eacute;</th><th>Places actives</th><th>&Eacute;tat</th><th>Action</th></tr>
<%
        boolean any = false;
        while (rs.next()) {
            any = true;
            String id = rs.getString("ID");
%>
    <tr>
        <td><%=cinH(id)%></td>
        <td><a href="<%=lien%>?but=cinema/configuration/salle-fiche.jsp&id=<%=id%>"><%=cinH(rs.getString("NOM"))%></a></td>
        <td><%=cinH(rs.getString("ADRESSE"))%></td>
        <td><%= rs.getInt("CAPACITE") %></td>
        <td><%= rs.getInt("NBPLACESLIB") %></td>
        <td><%=cinH(rs.getString("ETATLIB"))%></td>
        <td>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/configuration/place-liste.jsp&idSalle=<%=id%>">Places</a>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/configuration/salle-saisie.jsp&id=<%=id%>">Modifier</a>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/configuration/salle-fiche.jsp&id=<%=id%>">Fiche</a>
        </td>
    </tr>
<%
        }
        if (!any) {
%>
    <tr><td colspan="7">Aucune salle.</td></tr>
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

<div class="col-md-12" style="margin-top:12px">
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/genre-liste.jsp">Genres</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/categorieplace-liste.jsp">Cat&eacute;gories de place</a>
</div>
</div>
