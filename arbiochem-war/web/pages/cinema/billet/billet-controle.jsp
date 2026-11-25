<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.billet.AchatBilletService" %>
<%@ page import="cinema.billet.Billet" %>
<%--
    Controle a l'entree : recherche d'un billet par son numero, verification
    puis validation (marquage "utilise").
--%>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String numero = cinS(request.getParameter("numero")).trim();
    String action = cinS(request.getParameter("action"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;

    if ("valider".equals(action) && !numero.isEmpty()) {
        Connection tc = null;
        boolean ok = false;
        try {
            tc = new UtilDB().GetConn();
            tc.setAutoCommit(false);
            Billet b = AchatBilletService.validerEntree(numero, userId, tc);
            String place = b.getLibellePlace(tc);
            tc.commit();
            ok = true;
            message = "Entrée validée : " + b.getNumero() + " — " + place + ".";
        } catch (Exception e) {
            erreur = e.getMessage();
            e.printStackTrace();
        } finally {
            if (tc != null) {
                if (!ok) {
                    try { tc.rollback(); } catch (Exception ignore) {}
                }
                try { tc.close(); } catch (Exception ignore) {}
            }
        }
    }

    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    boolean found = false;
    boolean valide = false;
    boolean projectionOk = false;
    String film = "";
    String place = "";
    String categorie = "";
    String statutLib = "";
    String achat = "";
    String dateUtil = "";
    double prix = 0;
%>
<div class="content-wrapper">
<section class="content-header">
    <h1>
        <a href="<%=lien%>?but=cinema/billet/billet-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>
        Contr&ocirc;le des billets
    </h1>
</section>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/billet/billet-controle.jsp" method="post">
        <div class="input-container">
            <div class="form-input" style="width:60%"><label class="input-label">Num&eacute;ro du billet</label>
                <input class="form-control" type="textbox" name="numero" value="<%=cinH(numero)%>"
                       placeholder="BIL-..." autofocus></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-secondary" name="action" value="verifier">V&eacute;rifier</button></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary" name="action" value="valider"
                        onclick="return confirm('Valider l\'entr&eacute;e de ce billet ?');">Valider l'entr&eacute;e</button></div>
        </div>
    </form>
</div>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>
<% if (erreur != null) { %><div class="col-md-12"><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div></div><% } %>

<%
    if (!numero.isEmpty()) {
        try {
            c = new UtilDB().GetConn();
            ps = c.prepareStatement("SELECT * FROM CINEMA_BILLET_LIB WHERE NUMERO = ?");
            ps.setString(1, numero);
            rs = ps.executeQuery();
            if (rs.next()) {
                found = true;
                valide = rs.getInt("ETAT") == 11 && rs.getInt("STATUT") == 1;
                film = cinS(rs.getString("IDFILMLIB"));
                place = cinS(rs.getString("IDPLACELIB"));
                categorie = cinS(rs.getString("IDCATEGORIEPLACELIB"));
                statutLib = cinS(rs.getString("STATUTLIB"));
                achat = cinS(rs.getString("IDACHATBILLETLIB"));
                dateUtil = cinTsFmt(rs.getTimestamp("DATYUTILISATION"));
                prix = rs.getDouble("PRIX");
                String idB = rs.getString("ID");

                cinClose(rs, ps, null); rs = null; ps = null;

                ps = c.prepareStatement(
                        "SELECT COUNT(*) FROM CINEMA_BILLET b"
                        + " JOIN CINEMA_ACHATBILLET ab ON ab.ID = b.IDMERE"
                        + " JOIN CINEMA_PROJECTION pr ON pr.ID = ab.IDPROJECTION"
                        + " WHERE b.ID = ? AND ab.ETAT = 11 AND pr.ETAT = 11"
                        + " AND pr.STATUT = 2 AND pr.DATY = TRUNC(SYSDATE)");
                ps.setString(1, idB);
                rs = ps.executeQuery();
                if (rs.next()) {
                    projectionOk = rs.getInt(1) > 0;
                }
%>
<div class="col-md-12 cardradius" style="margin-top:12px;padding:16px">
    <h4>Billet <%=cinH(numero)%></h4>
    <table class="table">
        <tr><th style="width:240px">Statut</th>
            <td>
                <b><%=cinH(statutLib)%></b>
                <span class="label <%= valide ? "label-success" : "label-danger" %>">
                    <%= valide ? "Valide" : "Non valide" %>
                </span>
            </td></tr>
        <tr><th>Projection aujourd'hui ouverte</th>
            <td><%= projectionOk ? "Oui" : "Non" %></td></tr>
        <tr><th>Film</th><td><%=cinH(film)%></td></tr>
        <tr><th>Place</th><td><%=cinH(place)%></td></tr>
        <tr><th>Cat&eacute;gorie</th><td><%=cinH(categorie)%></td></tr>
        <tr><th>Prix</th><td><%=cinMoney(prix)%> Ar</td></tr>
        <tr><th>Achat</th>
            <td><a href="<%=lien%>?but=cinema/billet/billet-recu.jsp&idAchat=<%=cinH(achat)%>"><%=cinH(achat)%></a></td></tr>
        <tr><th>Utilis&eacute; le</th><td><%=cinH(dateUtil)%></td></tr>
    </table>
</div>
<%
            } else {
%>
<div class="col-md-12"><div class="alert alert-warning">Billet introuvable : <%=cinH(numero)%></div></div>
<%
            }
        } catch (Exception e) {
            erreur = e.getMessage();
            e.printStackTrace();
        } finally {
            cinClose(rs, ps, c);
        }
    }
%>
</div>
