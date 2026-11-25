<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.reservation.ReservationService" %>
<%@ page import="cinema.billet.AchatBilletService" %>
<%--
    Fiche d'une reservation : details, confirmation, annulation et conversion
    en billets (facture + mouvement de caisse).
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

    if (!action.isEmpty() && !id.isEmpty()) {
        try {
            if ("confirmer".equals(action)) {
                ReservationService.confirmer(userId, id);
                message = "Réservation confirmée.";
            } else if ("annuler".equals(action)) {
                ReservationService.annuler(userId, id);
                message = "Réservation annulée.";
            } else if ("convertir".equals(action)) {
                String modepaiement = cinS(request.getParameter("modepaiement"));
                String idCaisse = cinS(request.getParameter("idCaisse"));
                AchatBilletService.Resultat r = ReservationService.convertirEnBillet(
                        userId, id, modepaiement.trim().isEmpty() ? null : modepaiement,
                        idCaisse.trim().isEmpty() ? null : idCaisse);
                String msg = "Reservation convertie : achat " + r.idAchat
                        + " (" + r.nbBillets + " billet(s)).";
                response.sendRedirect(lien
                        + "?but=cinema/billet/billet-recu.jsp&idAchat="
                        + java.net.URLEncoder.encode(r.idAchat, "UTF-8")
                        + "&msg=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                return;
            }
        } catch (Exception e) {
            erreur = e.getMessage();
            e.printStackTrace();
        }
    }

    boolean found = false;
    int statut = 0;
    String statutLib = "";
    String idProjection = "";
    String idClient = "";
    double total = 0;
    double acompte = 0;
%>
<div class="content-wrapper">
<section class="content-header">
    <h1>
        <a href="<%=lien%>?but=cinema/reservation/reservation-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>
        Fiche r&eacute;servation
    </h1>
</section>

<div class="col-md-12">
<% if (!message.isEmpty()) { %><div class="alert alert-success"><%=cinH(message)%></div><% } %>
<% if (erreur != null) { %><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div><% } %>
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement("SELECT * FROM CINEMA_RESERVATION_LIB WHERE ID = ?");
        ps.setString(1, id);
        rs = ps.executeQuery();
        if (rs.next()) {
            found = true;
            statut = rs.getInt("STATUT");
            statutLib = cinS(rs.getString("STATUTLIB"));
            idProjection = cinS(rs.getString("IDPROJECTION"));
            idClient = cinS(rs.getString("IDCLIENT"));
            total = rs.getDouble("MONTANTTOTALLIB");
            acompte = rs.getDouble("MONTANTACOMPTE");
%>
    <div class="cardradius" style="padding:16px">
        <h3>
            <%=cinH(rs.getString("IDFILMLIB"))%>
            <small>(<%=cinH(rs.getString("IDSALLELIB"))%>)</small>
        </h3>
        <table class="table">
            <tr><th style="width:240px">Identifiant</th><td><%=cinH(id)%></td></tr>
            <tr><th>Date de r&eacute;servation</th><td><%=cinDateFmt(rs.getDate("DATY"))%></td></tr>
            <tr><th>Client</th><td><%=cinH(rs.getString("IDCLIENTLIB"))%> <small>(<%=cinH(idClient)%>)</small></td></tr>
            <tr><th>Projection</th><td><%=cinH(idProjection)%></td></tr>
            <tr><th>Places</th><td><%= rs.getInt("NBPLACESLIB") %></td></tr>
            <tr><th>Montant total</th><td><b><%=cinMoney(total)%> Ar</b></td></tr>
            <tr><th>Acompte</th><td><%=cinMoney(acompte)%> Ar</td></tr>
            <tr><th>Reste &agrave; payer</th><td><%=cinMoney(rs.getDouble("RESTEAPAYERLIB"))%> Ar</td></tr>
            <tr><th>Expiration</th><td><%=cinTsFmt(rs.getTimestamp("DATEEXPIRATION"))%></td></tr>
            <tr><th>Statut</th><td><%=cinH(statutLib)%></td></tr>
            <tr><th>&Eacute;tat</th><td><%=cinH(rs.getString("ETATLIB"))%></td></tr>
            <tr><th>Remarque</th><td><%=cinH(rs.getString("REMARQUE"))%></td></tr>
        </table>

        <div style="margin-top:8px">
            <% if (statut == 1) { %>
            <form action="<%=lien%>?but=cinema/reservation/reservation-fiche.jsp&id=<%=cinH(id)%>" method="post" style="display:inline">
                <input type="hidden" name="action" value="confirmer">
                <button type="submit" class="btn btn-primary">Confirmer</button>
            </form>
            <% } %>
            <% if (statut == 1 || statut == 2) { %>
            <form action="<%=lien%>?but=cinema/reservation/reservation-fiche.jsp&id=<%=cinH(id)%>" method="post" style="display:inline"
                  onsubmit="return confirm('Annuler cette r&eacute;servation ?');">
                <input type="hidden" name="action" value="annuler">
                <button type="submit" class="btn btn-danger">Annuler</button>
            </form>
            <% } %>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/reservation/reservation-plan.jsp&idProjection=<%=cinH(idProjection)%>">Plan de salle</a>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/reservation/reservation-liste.jsp">Retour &agrave; la liste</a>
        </div>
    </div>
<%
        } else {
%>
    <div class="alert alert-warning">R&eacute;servation introuvable : <%=cinH(id)%></div>
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

<% if (found) { %>
<div class="cardradius" style="padding:16px;margin-top:16px">
    <h4>Places r&eacute;serv&eacute;es</h4>
    <table class="table table-bordered">
        <tr><th>Place</th><th>Cat&eacute;gorie</th><th>Prix</th><th>Billet</th><th>&Eacute;tat</th></tr>
<%
    try {
        ps = c.prepareStatement(
                "SELECT * FROM CINEMA_RESERVATIONDETAIL_LIB WHERE IDMERE = ? ORDER BY ID");
        ps.setString(1, id);
        rs = ps.executeQuery();
        boolean any = false;
        while (rs.next()) {
            any = true;
%>
        <tr>
            <td><%=cinH(rs.getString("IDPLACELIB"))%></td>
            <td><%=cinH(rs.getString("IDCATEGORIEPLACELIB"))%></td>
            <td><%=cinMoney(rs.getDouble("PRIX"))%> Ar</td>
            <td><%=cinH(rs.getString("IDBILLETLIB"))%></td>
            <td><%=cinH(rs.getString("ETATLIB"))%></td>
        </tr>
<%
        }
        if (!any) {
%>
        <tr><td colspan="5">Aucune place.</td></tr>
<%
        }
    } catch (Exception e) {
        erreur = e.getMessage();
        e.printStackTrace();
    } finally {
        cinClose(rs, ps, null); rs = null; ps = null;
    }
%>
    </table>
</div>

<% if (statut == 1 || statut == 2) { %>
<div class="cardradius" style="padding:16px;margin-top:16px">
    <h4>Convertir en billets</h4>
    <p>La conversion encaisse le montant total, g&eacute;n&egrave;re la facture VENTE et le mouvement de caisse.</p>
    <form action="<%=lien%>?but=cinema/reservation/reservation-fiche.jsp&id=<%=cinH(id)%>" method="post">
        <input type="hidden" name="action" value="convertir">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Mode de paiement</label>
                <select class="form-control" name="modepaiement">
                    <option value="">-- Aucun --</option>
<%
    try {
        ps = c.prepareStatement("SELECT ID, VAL FROM MODEPAIEMENT ORDER BY VAL");
        rs = ps.executeQuery();
        while (rs.next()) {
%>
                    <option value="<%=cinH(rs.getString("ID"))%>"><%=cinH(rs.getString("VAL"))%></option>
<%
        }
    } catch (Exception e) {
        erreur = e.getMessage();
    } finally {
        cinClose(rs, ps, null); rs = null; ps = null;
    }
%>
                </select></div>
            <div class="form-input"><label class="input-label">Caisse</label>
                <select class="form-control" name="idCaisse">
                    <option value="">-- Caisse par d&eacute;faut --</option>
<%
    try {
        ps = c.prepareStatement("SELECT ID, VAL FROM CAISSE ORDER BY VAL");
        rs = ps.executeQuery();
        while (rs.next()) {
%>
                    <option value="<%=cinH(rs.getString("ID"))%>"><%=cinH(rs.getString("VAL"))%></option>
<%
        }
    } catch (Exception e) {
        erreur = e.getMessage();
    } finally {
        cinClose(rs, ps, null); rs = null; ps = null;
    }
%>
                </select></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary"
                        onclick="return confirm('Encaisser et convertir en billets ?');">Convertir et encaisser</button></div>
        </div>
    </form>
</div>
<% } %>

<% if (statut == 3) { %>
<%
    String idAchat = null;
    try {
        ps = c.prepareStatement(
                "SELECT ID FROM CINEMA_ACHATBILLET WHERE IDRESERVATION = ? AND ETAT = 11");
        ps.setString(1, id);
        rs = ps.executeQuery();
        if (rs.next()) {
            idAchat = rs.getString("ID");
        }
    } catch (Exception e) {
        erreur = e.getMessage();
    } finally {
        cinClose(rs, ps, null); rs = null; ps = null;
    }
    if (idAchat != null) {
%>
<div class="cardradius" style="padding:16px;margin-top:16px">
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/billet/billet-recu.jsp&idAchat=<%=cinH(idAchat)%>">
        Voir le re&ccedil;u de l'achat <%=cinH(idAchat)%>
    </a>
</div>
<% } %>
<% } %>
<% } %>
<%
    if (erreur != null) {
%>
<div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div>
<%
    }
%>
</div>
<%
    if (c != null) {
        try { c.close(); } catch (Exception ignore) {}
    }
%>
</div>
