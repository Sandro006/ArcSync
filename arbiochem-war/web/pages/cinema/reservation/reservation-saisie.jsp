<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.reservation.ReservationService" %>
<%@ page import="cinema.utils.CinemaDb" %>
<%--
    Saisie d'une reservation : projection ouverte, client, plan de salle,
    acompte et date d'expiration.

    Le plan de salle est rendu apres selection de la projection (rechargement
    de la page) car les places dependent de la salle.
--%>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String idProjection = cinS(request.getParameter("idProjection"));
    String clientQ = cinS(request.getParameter("client"));
    String idClient = cinS(request.getParameter("idClient"));
    String action = cinS(request.getParameter("action"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;

    Set<String> cinSelPlaces = new LinkedHashSet<String>();
    String[] placesParams = request.getParameterValues("places");
    if (placesParams != null) {
        for (int i = 0; i < placesParams.length; i++) {
            String[] parts = cinS(placesParams[i]).split(",");
            for (int j = 0; j < parts.length; j++) {
                String v = parts[j].trim();
                if (!v.isEmpty()) {
                    cinSelPlaces.add(v);
                }
            }
        }
    }

    if ("creer".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        String acompteP = cinS(request.getParameter("acompte"));
        String expirationP = cinS(request.getParameter("expiration"));
        String remarque = cinS(request.getParameter("remarque"));
        if (cinSelPlaces.isEmpty()) {
            erreur = "Sélectionnez au moins une place.";
        } else if (idClient.trim().isEmpty()) {
            erreur = "Sélectionnez un client.";
        } else if (idProjection.trim().isEmpty()) {
            erreur = "Sélectionnez une projection.";
        } else {
            try {
                List<ReservationService.LigneReservation> lignes =
                        new ArrayList<ReservationService.LigneReservation>();
                Iterator<String> it = cinSelPlaces.iterator();
                while (it.hasNext()) {
                    lignes.add(new ReservationService.LigneReservation(it.next(), null));
                }
                ReservationService.Resultat r = ReservationService.reserver(userId,
                        idClient, idProjection, lignes, cinD(acompteP),
                        cinTs(expirationP), remarque);
                String msg = "Reservation " + r.idReservation + " creee ("
                        + lignes.size() + " place(s), total " + r.montantTotal + " Ar).";
                response.sendRedirect(lien
                        + "?but=cinema/reservation/reservation-fiche.jsp&id="
                        + java.net.URLEncoder.encode(r.idReservation, "UTF-8")
                        + "&msg=" + java.net.URLEncoder.encode(msg, "UTF-8"));
                return;
            } catch (Exception e) {
                erreur = e.getMessage();
                e.printStackTrace();
            }
        }
    }

    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    String clientNom = "";
    String expirationDefaut = CinemaDb.formatTimestamp(
            CinemaDb.addMinutes(CinemaDb.now(), 30));
%>
<div class="content-wrapper">
<section class="content-header">
    <h1>
        <a href="<%=lien%>?but=cinema/reservation/reservation-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>
        Nouvelle r&eacute;servation
    </h1>
</section>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>
<% if (erreur != null) { %><div class="col-md-12"><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div></div><% } %>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/reservation/reservation-saisie.jsp" method="get">
        <input type="hidden" name="but" value="cinema/reservation/reservation-saisie.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Projection ouverte</label>
                <select class="form-control" name="idProjection" onchange="this.form.submit()">
                    <option value="">-- Choisir une projection --</option>
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement(
                "SELECT * FROM (SELECT ID, IDFILMLIB, IDSALLELIB, DATY, HEUREDEBUT,"
                + " NBPLACESDISPONIBLES FROM CINEMA_PROJECTION_LIB"
                + " WHERE ETAT = 11 AND STATUT = 2 AND " + cinSqlSeanceFuture
                + " ORDER BY DATY, HEUREDEBUT) WHERE ROWNUM <= 100");
        rs = ps.executeQuery();
        while (rs.next()) {
            String pid = rs.getString("ID");
%>
                    <option value="<%=cinH(pid)%>"<%=cinSelected(pid, idProjection)%>><%=cinDateFmt(rs.getDate("DATY"))%>
                        <%=cinH(rs.getString("HEUREDEBUT"))%> &mdash; <%=cinH(rs.getString("IDFILMLIB"))%>
                        (<%=cinH(rs.getString("IDSALLELIB"))%>) &mdash;
                        <%= rs.getInt("NBPLACESDISPONIBLES") %> place(s) libre(s)</option>
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
            <div class="form-input"><label class="input-label">Rechercher un client</label>
                <input class="form-control" type="textbox" name="client" value="<%=cinH(clientQ)%>"
                       placeholder="Nom ou identifiant"></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary">Afficher</button></div>
        </div>
    </form>
</div>

<form action="<%=lien%>?but=cinema/reservation/reservation-saisie.jsp" method="post" id="formReservation">
<input type="hidden" name="action" value="creer">
<input type="hidden" name="idProjection" value="<%=cinH(idProjection)%>">

<div class="col-md-12 cardradius" style="margin-top:12px;padding:12px">
    <div class="input-container">
        <div class="form-input"><label class="input-label">Client</label>
            <select class="form-control" name="idClient">
                <option value="">-- Choisir un client --</option>
<%
    try {
        c = (c == null) ? new UtilDB().GetConn() : c;
        String sql;
        if (clientQ.trim().isEmpty()) {
            sql = "SELECT * FROM (SELECT ID, NOM FROM CLIENT WHERE NOM IS NOT NULL"
                    + " ORDER BY NOM) WHERE ROWNUM <= 50";
        } else {
            sql = "SELECT * FROM (SELECT ID, NOM FROM CLIENT"
                    + " WHERE UPPER(NOM) LIKE ? OR UPPER(ID) LIKE ?"
                    + " ORDER BY NOM) WHERE ROWNUM <= 50";
        }
        ps = c.prepareStatement(sql);
        if (!clientQ.trim().isEmpty()) {
            String like = "%" + clientQ.trim().toUpperCase() + "%";
            ps.setString(1, like);
            ps.setString(2, like);
        }
        rs = ps.executeQuery();
        boolean anyClient = false;
        while (rs.next()) {
            anyClient = true;
            String cid = rs.getString("ID");
            String cnom = cinS(rs.getString("NOM"));
            if (cid.equals(idClient)) {
                clientNom = cnom;
            }
%>
                <option value="<%=cinH(cid)%>"<%=cinSelected(cid, idClient)%>><%=cinH(cid)%> &mdash; <%=cinH(cnom)%></option>
<%
        }
        if (!anyClient) {
%>
                <option value="">Aucun client ne correspond &agrave; la recherche</option>
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
            </select>
            <% if (!clientQ.trim().isEmpty()) { %>
            <small>Filtr&eacute; sur &laquo; <%=cinH(clientQ)%> &raquo; &mdash; <a href="<%=lien%>?but=cinema/reservation/reservation-saisie.jsp&idProjection=<%=cinH(idProjection)%>">tout afficher</a></small>
            <% } %>
        </div>
    </div>
</div>

<div class="col-md-12 cardradius" style="margin-top:12px;padding:12px">
    <h4>Plan de salle</h4>
    <%
        String idPlanProjection = idProjection;
        boolean cinPlanVente = true;
        String cinPlanFieldName = "places";
        if (c == null) {
            try { c = new UtilDB().GetConn(); } catch (Exception e) { erreur = e.getMessage(); }
        }
    %>
    <%@ include file="../_plan-salle.jsp" %>
</div>

<div class="col-md-12 cardradius" style="margin-top:12px;padding:12px">
    <div class="input-container">
        <div class="form-input"><label class="input-label">Acompte (Ar)</label>
            <input class="form-control" type="number" min="0" step="0.01" name="acompte" value="0"></div>
        <div class="form-input"><label class="input-label">Expiration</label>
            <input class="form-control" type="datetime-local" name="expiration" value="<%=expirationDefaut%>"></div>
        <div class="form-input" style="width:100%"><label class="input-label">Remarque</label>
            <input class="form-control" type="textbox" name="remarque" value=""></div>
    </div>
    <div style="margin-top:12px">
        <button type="submit" class="btn btn-primary">Enregistrer la r&eacute;servation</button>
        <a class="btn btn-secondary" href="<%=lien%>?but=cinema/reservation/reservation-liste.jsp">Annuler</a>
    </div>
</div>
</form>
</div>
<%
    if (c != null) {
        try { c.close(); } catch (Exception ignore) {}
    }
%>
