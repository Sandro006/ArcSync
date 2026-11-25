<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.billet.AchatBilletService" %>
<%--
    Fiche d'un billet : details, achat d'origine, controle et annulation.
--%>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String id = cinS(request.getParameter("id"));
    String action = cinS(request.getParameter("action"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;

    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    boolean found = false;
    int statut = 0;
    String numero = "";
    String idAchat = "";

    try {
        c = new UtilDB().GetConn();

        if ("annulerAchat".equals(action) && !id.isEmpty()) {
            ps = c.prepareStatement("SELECT IDMERE FROM CINEMA_BILLET WHERE ID = ?");
            ps.setString(1, id);
            rs = ps.executeQuery();
            if (rs.next()) {
                idAchat = cinS(rs.getString("IDMERE"));
            }
            cinClose(rs, ps, null); rs = null; ps = null;
            if (!idAchat.isEmpty()) {
                AchatBilletService.annuler(userId, idAchat);
                response.sendRedirect(lien
                        + "?but=cinema/billet/billet-liste.jsp&msg="
                        + java.net.URLEncoder.encode(
                                "Achat " + idAchat + " annule (billets annules).", "UTF-8"));
                return;
            }
        }

        ps = c.prepareStatement("SELECT * FROM CINEMA_BILLET_LIB WHERE ID = ?");
        ps.setString(1, id);
        rs = ps.executeQuery();
        if (rs.next()) {
            found = true;
            statut = rs.getInt("STATUT");
            numero = cinS(rs.getString("NUMERO"));
            idAchat = cinS(rs.getString("IDACHATBILLETLIB"));
%>
<div class="content-wrapper">
<section class="content-header">
    <h1>
        <a href="<%=lien%>?but=cinema/billet/billet-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>
        Fiche billet
    </h1>
</section>

<div class="col-md-12">
<% if (!message.isEmpty()) { %><div class="alert alert-success"><%=cinH(message)%></div><% } %>
<% if (erreur != null) { %><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div><% } %>

<div class="cardradius" style="padding:16px">
    <h3><%=cinH(numero)%></h3>
    <table class="table">
        <tr><th style="width:240px">Identifiant</th><td><%=cinH(id)%></td></tr>
        <tr><th>Achat</th>
            <td><a href="<%=lien%>?but=cinema/billet/billet-recu.jsp&idAchat=<%=cinH(idAchat)%>"><%=cinH(idAchat)%></a></td></tr>
        <tr><th>Film</th><td><%=cinH(rs.getString("IDFILMLIB"))%></td></tr>
        <tr><th>Projection</th>
            <td><a href="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=cinH(rs.getString("IDPROJECTIONLIB"))%>"><%=cinH(rs.getString("IDPROJECTIONLIB"))%></a></td></tr>
        <tr><th>Place</th><td><%=cinH(rs.getString("IDPLACELIB"))%></td></tr>
        <tr><th>Cat&eacute;gorie</th><td><%=cinH(rs.getString("IDCATEGORIEPLACELIB"))%></td></tr>
        <tr><th>Prix</th><td><b><%=cinMoney(rs.getDouble("PRIX"))%> Ar</b></td></tr>
        <tr><th>Statut</th><td><%=cinH(rs.getString("STATUTLIB"))%></td></tr>
        <tr><th>&Eacute;tat</th><td><%=cinH(rs.getString("ETATLIB"))%></td></tr>
        <tr><th>Utilis&eacute; le</th><td><%=cinTsFmt(rs.getTimestamp("DATYUTILISATION"))%></td></tr>
    </table>

    <div style="margin-top:8px">
        <% if (statut == 1) { %>
        <a class="btn btn-primary" href="<%=lien%>?but=cinema/billet/billet-controle.jsp&numero=<%=java.net.URLEncoder.encode(numero, "UTF-8")%>">
            Contr&ocirc;ler &agrave; l'entr&eacute;e
        </a>
        <% } %>
        <a class="btn btn-secondary" href="<%=lien%>?but=cinema/billet/billet-recu.jsp&idAchat=<%=cinH(idAchat)%>">Re&ccedil;u de l'achat</a>
        <form action="<%=lien%>?but=cinema/billet/billet-fiche.jsp&id=<%=cinH(id)%>" method="post" style="display:inline"
              onsubmit="return confirm('Annuler tout l\'achat et rembourser les billets ?');">
            <input type="hidden" name="action" value="annulerAchat">
            <button type="submit" class="btn btn-danger">Annuler l'achat</button>
        </form>
    </div>
</div>
</div>
<%
        } else {
%>
<div class="alert alert-warning">Billet introuvable : <%=cinH(id)%></div>
<%
        }
    } catch (Exception e) {
        erreur = e.getMessage();
        e.printStackTrace();
    } finally {
        cinClose(rs, ps, c);
    }

    if (!found && erreur != null) {
%>
<div class="content-wrapper"><div class="col-md-12">
    <div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div>
</div></div>
<%
    }
%>
