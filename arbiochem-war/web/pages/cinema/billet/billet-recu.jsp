<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Recu d'un achat de billets : totaux, caisse et liste des billets.
--%>
<%
    request.setCharacterEncoding("UTF-8");
    String lien = (String) session.getValue("lien");
    String idAchat = cinS(request.getParameter("idAchat"));
    String idBillet = cinS(request.getParameter("id"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;

    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    boolean found = false;
    String achatProjection = "";
%>
<div class="content-wrapper">
<section class="content-header">
    <h1>
        <a href="<%=lien%>?but=cinema/billet/billet-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>
        Re&ccedil;u de vente
    </h1>
</section>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>

<%
    try {
        c = new UtilDB().GetConn();

        if (idAchat.trim().isEmpty() && !idBillet.trim().isEmpty()) {
            ps = c.prepareStatement("SELECT IDMERE FROM CINEMA_BILLET WHERE ID = ?");
            ps.setString(1, idBillet);
            rs = ps.executeQuery();
            if (rs.next()) {
                idAchat = cinS(rs.getString("IDMERE"));
            }
            cinClose(rs, ps, null); rs = null; ps = null;
        }

        if (!idAchat.trim().isEmpty()) {
            ps = c.prepareStatement("SELECT * FROM CINEMA_ACHATBILLET_LIB WHERE ID = ?");
            ps.setString(1, idAchat);
            rs = ps.executeQuery();
            if (rs.next()) {
                found = true;
                achatProjection = cinS(rs.getString("IDPROJECTION"));
%>
    <div class="cardradius" id="recu" style="padding:18px;max-width:760px;margin:0 auto">
        <h3 class="text-center">CIN&Eacute;MA &mdash; RE&Ccedil;U</h3>
        <p class="text-center">
            Achat <b><%=cinH(idAchat)%></b> &mdash; <%=cinDateFmt(rs.getDate("DATY"))%>
        </p>
        <table class="table">
            <tr><th style="width:220px">Client</th>
                <td><%=cinH(rs.getString("IDCLIENTLIB"))%>
                    <% if (rs.getString("IDCLIENT") != null) { %>
                    <small>(<%=cinH(rs.getString("IDCLIENT"))%>)</small>
                    <% } %></td></tr>
            <tr><th>Film</th><td><%=cinH(rs.getString("IDFILMLIB"))%></td></tr>
            <tr><th>Salle</th><td><%=cinH(rs.getString("IDSALLELIB"))%></td></tr>
            <tr><th>Projection</th><td><%=cinH(rs.getString("IDPROJECTION"))%></td></tr>
            <tr><th>Nombre de billets</th><td><%= rs.getInt("NBBILLETSLIB") %></td></tr>
            <tr><th>Mode de paiement</th>
                <td><%=cinH(rs.getString("MODEPAIEMENTLIB") != null
                        ? rs.getString("MODEPAIEMENTLIB") : rs.getString("MODEPAIEMENT"))%></td></tr>
            <tr><th>Total</th><td><b><%=cinMoney(rs.getDouble("MONTANTTOTAL"))%> Ar</b></td></tr>
            <tr><th>Montant pay&eacute;</th><td><%=cinMoney(rs.getDouble("MONTANTPAYE"))%> Ar</td></tr>
            <tr><th>Monnaie rendue</th><td><%=cinMoney(rs.getDouble("MONNAIERENDUE"))%> Ar</td></tr>
            <tr><th>Facture VENTE</th><td><%=cinH(rs.getString("IDVENTE"))%></td></tr>
            <tr><th>Mouvement caisse</th><td><%=cinH(rs.getString("IDMOUVEMENTCAISSE"))%></td></tr>
            <tr><th>&Eacute;tat</th><td><%=cinH(rs.getString("ETATLIB"))%></td></tr>
            <tr><th>Remarque</th><td><%=cinH(rs.getString("REMARQUE"))%></td></tr>
        </table>

        <h4>Billets</h4>
        <table class="table table-bordered">
            <tr><th>Num&eacute;ro</th><th>Place</th><th>Cat&eacute;gorie</th><th>Prix</th><th>Statut</th></tr>
<%
                cinClose(rs, ps, null); rs = null; ps = null;

                ps = c.prepareStatement(
                        "SELECT * FROM CINEMA_BILLET_LIB WHERE IDMERE = ? ORDER BY NUMERO");
                ps.setString(1, idAchat);
                rs = ps.executeQuery();
                boolean any = false;
                while (rs.next()) {
                    any = true;
                    String bid = rs.getString("ID");
%>
            <tr>
                <td><a href="<%=lien%>?but=cinema/billet/billet-fiche.jsp&id=<%=cinH(bid)%>"><%=cinH(rs.getString("NUMERO"))%></a></td>
                <td><%=cinH(rs.getString("IDPLACELIB"))%></td>
                <td><%=cinH(rs.getString("IDCATEGORIEPLACELIB"))%></td>
                <td><%=cinMoney(rs.getDouble("PRIX"))%> Ar</td>
                <td><%=cinH(rs.getString("STATUTLIB"))%></td>
            </tr>
<%
                }
                if (!any) {
%>
            <tr><td colspan="5">Aucun billet.</td></tr>
<%
                }
                cinClose(rs, ps, null); rs = null; ps = null;
%>
        </table>

        <div style="margin-top:12px" class="no-print">
            <button type="button" class="btn btn-primary" onclick="window.print()">Imprimer</button>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/billet/billet-vente.jsp&idProjection=<%=cinH(achatProjection)%>">Nouvelle vente</a>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/billet/billet-liste.jsp">Liste des billets</a>
        </div>
    </div>
<%
            } else {
%>
    <div class="alert alert-warning">Achat introuvable : <%=cinH(idAchat)%></div>
<%
            }
        } else {
%>
    <div class="alert alert-warning">Aucun achat indiqu&eacute;.</div>
<%
        }
    } catch (Exception e) {
        erreur = e.getMessage();
        e.printStackTrace();
    } finally {
        cinClose(rs, ps, c);
    }
    if (erreur != null) {
%>
<div class="col-md-12"><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div></div>
<%
    }
%>
</div>
<style>
    @media print {
        .no-print, .content-header, .main-header, .main-sidebar, .main-footer { display: none !important; }
        #recu { box-shadow: none; border: none; }
    }
</style>
