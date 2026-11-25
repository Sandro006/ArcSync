<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.billet.AchatBilletService" %>
<%--
    Caisse cinema : selection des places, mode de paiement, caisse et montant
    paye. Chaque achat genere une facture VENTE et un mouvement de caisse.
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

    if ("acheter".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
        String modepaiement = cinS(request.getParameter("modepaiement"));
        String idCaisse = cinS(request.getParameter("idCaisse"));
        String payeP = cinS(request.getParameter("montantPaye"));
        String remarque = cinS(request.getParameter("remarque"));
        if (cinSelPlaces.isEmpty()) {
            erreur = "Sélectionnez au moins une place.";
        } else if (idProjection.trim().isEmpty()) {
            erreur = "Sélectionnez une projection.";
        } else {
            try {
                List<AchatBilletService.LigneBillet> lignes =
                        new ArrayList<AchatBilletService.LigneBillet>();
                Iterator<String> it = cinSelPlaces.iterator();
                while (it.hasNext()) {
                    lignes.add(new AchatBilletService.LigneBillet(it.next(), null, 0));
                }
                double paye = payeP.trim().isEmpty() ? -1 : cinD(payeP);
                AchatBilletService.Resultat r = AchatBilletService.acheter(userId,
                        idClient.trim().isEmpty() ? null : idClient, idProjection, null,
                        lignes, modepaiement.trim().isEmpty() ? null : modepaiement,
                        idCaisse.trim().isEmpty() ? null : idCaisse, remarque, paye);
                String msg = "Achat " + r.idAchat + " enregistre : "
                        + r.nbBillets + " billet(s), " + r.montantTotal + " Ar.";
                response.sendRedirect(lien
                        + "?but=cinema/billet/billet-recu.jsp&idAchat="
                        + java.net.URLEncoder.encode(r.idAchat, "UTF-8")
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
%>
<div class="content-wrapper">
<section class="content-header">
    <h1>Caisse &mdash; vente de billets</h1>
</section>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>
<% if (erreur != null) { %><div class="col-md-12"><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div></div><% } %>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/billet/billet-vente.jsp" method="get">
        <input type="hidden" name="but" value="cinema/billet/billet-vente.jsp">
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
                        <%= rs.getInt("NBPLACESDISPONIBLES") %> libre(s)</option>
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
            <div class="form-input"><label class="input-label">Rechercher un client (optionnel)</label>
                <input class="form-control" type="textbox" name="client" value="<%=cinH(clientQ)%>"
                       placeholder="Nom ou identifiant"></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary">Afficher</button></div>
        </div>
    </form>
</div>

<form action="<%=lien%>?but=cinema/billet/billet-vente.jsp" method="post" id="formVente">
<input type="hidden" name="action" value="acheter">
<input type="hidden" name="idProjection" value="<%=cinH(idProjection)%>">

<div class="col-md-12 cardradius" style="margin-top:12px;padding:12px">
    <div class="input-container">
        <div class="form-input"><label class="input-label">Client (facultatif)</label>
            <select class="form-control" name="idClient">
                <option value=""<%=cinSelected("", idClient)%>>Sans client (comptoir)</option>
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
        while (rs.next()) {
            String cid = rs.getString("ID");
%>
                <option value="<%=cinH(cid)%>"<%=cinSelected(cid, idClient)%>><%=cinH(cid)%> &mdash; <%=cinH(rs.getString("NOM"))%></option>
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
        e.printStackTrace();
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
        e.printStackTrace();
    } finally {
        cinClose(rs, ps, null); rs = null; ps = null;
    }
%>
            </select></div>
        <div class="form-input"><label class="input-label">Montant pay&eacute; (Ar)</label>
            <input class="form-control" type="number" min="0" step="1" id="cinPaye"
                   name="montantPaye" value="" placeholder="Vide = paiement exact"
                   oninput="cinRecalc()"></div>
        <div class="form-input"><label class="input-label">Monnaie &agrave; rendre</label>
            <div class="form-control" style="border:none"><b id="cinMonnaie">0</b> Ar</div></div>
        <div class="form-input" style="width:100%"><label class="input-label">Remarque</label>
            <input class="form-control" type="textbox" name="remarque" value="Vente billets cin&eacute;ma"></div>
    </div>
    <div style="margin-top:12px">
        <button type="submit" class="btn btn-primary">Encaisser</button>
        <a class="btn btn-secondary" href="<%=lien%>?but=cinema/billet/billet-liste.jsp">Voir les ventes</a>
    </div>
</div>
</form>
</div>
<script>
    if (typeof cinRecalc === "function") {
        cinRecalc();
    }
</script>
<%
    if (c != null) {
        try { c.close(); } catch (Exception ignore) {}
    }
%>
