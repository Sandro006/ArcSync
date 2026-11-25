<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Liste des billets vendus et recettes filtrees.
--%>
<%
    request.setCharacterEncoding("UTF-8");
    String lien = (String) session.getValue("lien");
    String d1P = cinS(request.getParameter("d1"));
    String d2P = cinS(request.getParameter("d2"));
    String idProjection = cinS(request.getParameter("idProjection"));
    String statutP = cinS(request.getParameter("statut"));
    String numero = cinS(request.getParameter("numero"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;

    java.sql.Date d1 = cinDate(d1P);
    java.sql.Date d2 = cinDate(d2P);

    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
%>
<div class="content-wrapper">
<section class="content-header"><h1>Billets et recettes</h1></section>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/billet/billet-liste.jsp" method="get">
        <input type="hidden" name="but" value="cinema/billet/billet-liste.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Du</label>
                <input class="form-control" type="date" name="d1" value="<%=cinH(d1P)%>"></div>
            <div class="form-input"><label class="input-label">Au</label>
                <input class="form-control" type="date" name="d2" value="<%=cinH(d2P)%>"></div>
            <div class="form-input"><label class="input-label">Projection</label>
                <select class="form-control" name="idProjection">
                    <option value="">Toutes</option>
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement(
                "SELECT * FROM (SELECT ID, IDFILMLIB, IDSALLELIB, DATY, HEUREDEBUT"
                + " FROM CINEMA_PROJECTION_LIB WHERE ETAT <> 0"
                + " ORDER BY DATY DESC, HEUREDEBUT) WHERE ROWNUM <= 200");
        rs = ps.executeQuery();
        while (rs.next()) {
            String pid = rs.getString("ID");
%>
                    <option value="<%=cinH(pid)%>"<%=cinSelected(pid, idProjection)%>><%=cinDateFmt(rs.getDate("DATY"))%>
                        <%=cinH(rs.getString("HEUREDEBUT"))%> &mdash; <%=cinH(rs.getString("IDFILMLIB"))%></option>
<%
        }
        cinClose(rs, ps, null); rs = null; ps = null;
    } catch (Exception e) {
        erreur = e.getMessage();
        e.printStackTrace();
    } finally {
        cinClose(rs, ps, null); rs = null; ps = null;
    }
%>
                </select></div>
            <div class="form-input"><label class="input-label">Num&eacute;ro</label>
                <input class="form-control" type="textbox" name="numero" value="<%=cinH(numero)%>"
                       placeholder="BIL-..."></div>
            <div class="form-input"><label class="input-label">Statut</label>
                <select class="form-control" name="statut">
                    <option value="">Tous</option>
                    <option value="1"<%=cinSelected("1", statutP)%>>Vendu</option>
                    <option value="2"<%=cinSelected("2", statutP)%>>Utilis&eacute;</option>
                    <option value="0"<%=cinSelected("0", statutP)%>>Annul&eacute;</option>
                </select></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary">Filtrer</button></div>
        </div>
    </form>
</div>

<div class="col-md-12" style="margin-top:8px">
    <a class="btn btn-primary pull-right" href="<%=lien%>?but=cinema/billet/billet-vente.jsp">
        <i class="material-symbols-rounded">add</i> Nouvelle vente
    </a>
    <a class="btn btn-secondary pull-right" style="margin-right:8px"
       href="<%=lien%>?but=cinema/billet/billet-controle.jsp">Contr&ocirc;le des entr&eacute;es</a>
</div>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>
<% if (erreur != null) { %><div class="col-md-12"><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div></div><% } %>

<div class="col-md-12 cardradius" style="margin-top:16px">
<%
    try {
        c = (c == null) ? new UtilDB().GetConn() : c;
        String sql = "SELECT b.*, ab.DATY AS DATYACHAT, ab.ID AS IDACHAT"
                + " FROM CINEMA_BILLET_LIB b"
                + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                + " WHERE b.ETAT IN (1,11) AND ab.ETAT IN (1,11)";
        if (d1 != null) sql += " AND ab.DATY >= ?";
        if (d2 != null) sql += " AND ab.DATY <= ?";
        if (!idProjection.trim().isEmpty()) sql += " AND b.IDPROJECTIONLIB = ?";
        if (!statutP.trim().isEmpty()) sql += " AND b.STATUT = ?";
        if (!numero.trim().isEmpty()) sql += " AND UPPER(b.NUMERO) LIKE ?";
        sql += " ORDER BY ab.DATY DESC, b.NUMERO";
        ps = c.prepareStatement(sql);
        int i = 1;
        if (d1 != null) ps.setDate(i++, d1);
        if (d2 != null) ps.setDate(i++, d2);
        if (!idProjection.trim().isEmpty()) ps.setString(i++, idProjection);
        if (!statutP.trim().isEmpty()) ps.setInt(i++, cinI(statutP));
        if (!numero.trim().isEmpty()) ps.setString(i++, "%" + numero.trim().toUpperCase() + "%");
        rs = ps.executeQuery();

        int nb = 0;
        double recette = 0;
%>
<table class="table table-bordered">
    <tr><th>Date vente</th><th>Billet</th><th>Film</th><th>Place</th><th>Cat&eacute;gorie</th>
        <th>Prix</th><th>Statut</th><th>Utilis&eacute; le</th><th>Action</th></tr>
<%
        boolean any = false;
        while (rs.next()) {
            any = true;
            nb++;
            recette += rs.getDouble("PRIX");
            String bid = rs.getString("ID");
            String aid = rs.getString("IDACHAT");
%>
    <tr>
        <td><%=cinDateFmt(rs.getDate("DATYACHAT"))%></td>
        <td><a href="<%=lien%>?but=cinema/billet/billet-fiche.jsp&id=<%=cinH(bid)%>"><%=cinH(rs.getString("NUMERO"))%></a></td>
        <td><%=cinH(rs.getString("IDFILMLIB"))%></td>
        <td><%=cinH(rs.getString("IDPLACELIB"))%></td>
        <td><%=cinH(rs.getString("IDCATEGORIEPLACELIB"))%></td>
        <td><%=cinMoney(rs.getDouble("PRIX"))%></td>
        <td><%=cinH(rs.getString("STATUTLIB"))%></td>
        <td><%=cinTsFmt(rs.getTimestamp("DATYUTILISATION"))%></td>
        <td>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/billet/billet-fiche.jsp&id=<%=cinH(bid)%>">Fiche</a>
            <a class="btn btn-secondary btn-sm" href="<%=lien%>?but=cinema/billet/billet-recu.jsp&idAchat=<%=cinH(aid)%>">Re&ccedil;u</a>
        </td>
    </tr>
<%
        }
        if (!any) {
%>
    <tr><td colspan="9">Aucun billet pour ces crit&egrave;res.</td></tr>
<%
        }
%>
    <tr>
        <th colspan="5" style="text-align:right">Total</th>
        <th><%=cinMoney(recette)%></th>
        <th colspan="3"><%=nb%> billet(s)</th>
    </tr>
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
