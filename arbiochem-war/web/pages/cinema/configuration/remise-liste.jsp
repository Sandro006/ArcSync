<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Liste des regles de remise appliquees aux reservations.
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
<section class="content-header"><h1>R&egrave;gles de remise</h1></section>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/configuration/remise-liste.jsp" method="get">
        <input type="hidden" name="but" value="cinema/configuration/remise-liste.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Recherche</label>
                <input class="form-control" type="text" name="q" value="<%=cinH(q)%>"
                       placeholder="Cat&eacute;gorie de place"></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary">Filtrer</button></div>
        </div>
    </form>
</div>

<div class="col-md-12">
    <a class="btn btn-primary pull-right" href="<%=lien%>?but=cinema/configuration/remise-saisie.jsp">
        <i class="material-symbols-rounded">add</i> Nouvelle r&egrave;gle
    </a>
</div>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>

<div class="col-md-12 cardradius" style="margin-top:16px">
<%
    try {
        c = new UtilDB().GetConn();
        String sql = "SELECT r.*, cr.VAL AS CATRES, cm.VAL AS CATREM"
                + " FROM CINEMA_REMISE r"
                + " LEFT JOIN CINEMA_CATEGORIEPLACE cr ON cr.ID = r.IDCATEGORIERESERVATION"
                + " LEFT JOIN CINEMA_CATEGORIEPLACE cm ON cm.ID = r.IDCATEGORIEREMISE";
        if (!q.trim().isEmpty()) {
            sql += " WHERE UPPER(cr.VAL) LIKE ? OR UPPER(cm.VAL) LIKE ?";
        }
        sql += " ORDER BY r.ETAT DESC, cr.VAL, cm.VAL";
        ps = c.prepareStatement(sql);
        if (!q.trim().isEmpty()) {
            String like = "%" + q.trim().toUpperCase() + "%";
            ps.setString(1, like);
            ps.setString(2, like);
        }
        rs = ps.executeQuery();
%>
<table class="table table-bordered">
    <tr>
        <th>Cat&eacute;gorie d&eacute;clencheuse</th>
        <th>Seuil</th>
        <th>Effet</th>
        <th>Cat&eacute;gorie remis&eacute;e</th>
        <th>Places remis&eacute;es</th>
        <th>Description</th>
        <th>&Eacute;tat</th>
        <th>Action</th>
    </tr>
<%
        boolean any = false;
        while (rs.next()) {
            any = true;
            String id = rs.getString("ID");
            int typeValeur = rs.getInt("TYPEVALEUR");
            double valeur = rs.getDouble("VALEUR");
            int etat = rs.getInt("ETAT");
            String effet = typeValeur == 0
                    ? ("-" + valeur + " %")
                    : ("-" + cinMoney(valeur) + " Ar");
%>
    <tr>
        <td><%=cinH(rs.getString("CATRES"))%></td>
        <td><%= rs.getInt("NOMBREPLACE") %></td>
        <td><%=cinH(effet)%></td>
        <td><%=cinH(rs.getString("CATREM"))%></td>
        <td><%= rs.getInt("NOMBREPLACEREMISE") %></td>
        <td><%=cinH(rs.getString("DESCE"))%></td>
        <td><%= etat == 1 ? "Actif" : "Inactif" %></td>
        <td>
            <a class="btn btn-secondary btn-sm"
               href="<%=lien%>?but=cinema/configuration/remise-saisie.jsp&id=<%=id%>">Modifier</a>
            <% if (etat == 1) { %>
            <form action="<%=lien%>?but=cinema/configuration/remise-saisie.jsp" method="post" style="display:inline"
                  onsubmit="return confirm('D&eacute;sactiver cette r&egrave;gle ?');">
                <input type="hidden" name="action" value="disable">
                <input type="hidden" name="id" value="<%=id%>">
                <button type="submit" class="btn btn-danger btn-sm">D&eacute;sactiver</button>
            </form>
            <% } else { %>
            <form action="<%=lien%>?but=cinema/configuration/remise-saisie.jsp" method="post" style="display:inline">
                <input type="hidden" name="action" value="enable">
                <input type="hidden" name="id" value="<%=id%>">
                <button type="submit" class="btn btn-success btn-sm">Activer</button>
            </form>
            <% } %>
        </td>
    </tr>
<%
        }
        if (!any) {
%>
    <tr><td colspan="8">Aucune r&egrave;gle de remise.</td></tr>
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
