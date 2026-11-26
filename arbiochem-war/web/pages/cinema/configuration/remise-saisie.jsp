<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.configuration.Remise" %>
<%--
    Saisie d'une regle de remise.

    Une regle est globale : si une reservation contient au moins N places de
    la categorie declencheuse, M places de la categorie remisee sont remisees.
    Les deux categories doivent etre differentes.
--%>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String action = cinS(request.getParameter("action"));
    String id = cinS(request.getParameter("id"));

    String idCategorieReservation = cinS(request.getParameter("idCategorieReservation"));
    int nombrePlace = cinI(request.getParameter("nombrePlace"));
    int typeValeur = request.getParameter("typeValeur") == null
            ? Remise.TYPE_POURCENTAGE : cinI(request.getParameter("typeValeur"));
    double valeur = cinD(request.getParameter("valeur"));
    String idCategorieRemise = cinS(request.getParameter("idCategorieRemise"));
    int nombrePlaceRemise = cinI(request.getParameter("nombrePlaceRemise"));
    String desce = cinS(request.getParameter("desce"));
    String etatP = request.getParameter("etat");
    int etat = etatP == null ? 1 : cinI(etatP);

    String message = null;
    String erreur = null;
    boolean done = false;
    Connection c = null;

    if (!action.isEmpty()) {
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);

            if ("disable".equals(action) || "enable".equals(action)) {
                Remise r = (Remise) new Remise().getById(id, "CINEMA_REMISE", c);
                if (r == null || r.getId() == null) {
                    throw new Exception("R\u00e8gle introuvable : " + id);
                }
                r.setEtat("enable".equals(action) ? 1 : 0);
                r.updateObject(userId, c);
                c.commit();
                String msg = "enable".equals(action)
                        ? "R\u00e8gle activ\u00e9e." : "R\u00e8gle d\u00e9sactiv\u00e9e.";
                response.sendRedirect(lien
                        + "?but=cinema/configuration/remise-liste.jsp&msg="
                        + java.net.URLEncoder.encode(msg, "UTF-8"));
                return;
            }

            if ("update".equals(action)) {
                if (id.trim().isEmpty()) {
                    throw new Exception("Identifiant obligatoire.");
                }
                Remise r = new Remise();
                r.setId(id);
                r.setIdCategorieReservation(idCategorieReservation);
                r.setNombrePlace(nombrePlace);
                r.setTypeValeur(typeValeur);
                r.setValeur(valeur);
                r.setIdCategorieRemise(idCategorieRemise);
                r.setNombrePlaceRemise(nombrePlaceRemise);
                r.setDesce(desce);
                r.setEtat(etat);
                r.updateObject(userId, c);
                message = "R\u00e8gle modifi\u00e9e.";
            } else {
                Remise r = new Remise();
                r.setIdCategorieReservation(idCategorieReservation);
                r.setNombrePlace(nombrePlace);
                r.setTypeValeur(typeValeur);
                r.setValeur(valeur);
                r.setIdCategorieRemise(idCategorieRemise);
                r.setNombrePlaceRemise(nombrePlaceRemise);
                r.setDesce(desce);
                r.setEtat(etat);
                r.createObject(userId, c);
                id = r.getId();
                message = "R\u00e8gle enregistr\u00e9e.";
            }
            c.commit();
            done = true;
            c.setAutoCommit(true);
        } catch (Exception e) {
            erreur = e.getMessage();
            try { if (c != null) c.rollback(); } catch (Exception ignore) {}
            e.printStackTrace();
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignore) {}
            c = null;
        }
    }

    if (!done && !id.isEmpty()) {
        try {
            c = new UtilDB().GetConn();
            PreparedStatement ps = c.prepareStatement(
                    "SELECT IDCATEGORIERESERVATION, NOMBREPLACE, TYPEVALEUR, VALEUR,"
                    + " IDCATEGORIEREMISE, NOMBREPLACEREMISE, DESCE, ETAT"
                    + " FROM CINEMA_REMISE WHERE ID = ?");
            ps.setString(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                idCategorieReservation = cinS(rs.getString("IDCATEGORIERESERVATION"));
                nombrePlace = rs.getInt("NOMBREPLACE");
                typeValeur = rs.getInt("TYPEVALEUR");
                valeur = rs.getDouble("VALEUR");
                idCategorieRemise = cinS(rs.getString("IDCATEGORIEREMISE"));
                nombrePlaceRemise = rs.getInt("NOMBREPLACEREMISE");
                desce = cinS(rs.getString("DESCE"));
                etat = rs.getInt("ETAT");
            }
            cinClose(rs, ps, c);
            c = null;
        } catch (Exception e) {
            if (erreur == null) erreur = e.getMessage();
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignore) {}
            c = null;
        }
    }

    List<String[]> categories = new ArrayList<String[]>();
    try {
        c = new UtilDB().GetConn();
        PreparedStatement ps = c.prepareStatement(
                "SELECT ID, VAL, ETAT FROM CINEMA_CATEGORIEPLACE ORDER BY VAL");
        ResultSet rs = ps.executeQuery();
        while (rs.next()) {
            categories.add(new String[]{
                        cinS(rs.getString("ID")),
                        cinS(rs.getString("VAL")),
                        String.valueOf(rs.getInt("ETAT"))
                    });
        }
        cinClose(rs, ps, c);
        c = null;
    } catch (Exception e) {
        if (erreur == null) erreur = e.getMessage();
    } finally {
        if (c != null) {
            try { c.close(); } catch (Exception ignore) {}
        }
    }
%>
<div class="content-wrapper">
<section class="content-header">
    <h1><%= id.isEmpty() ? "Nouvelle r&egrave;gle de remise" : "Modifier la r&egrave;gle de remise" %></h1>
</section>

<div class="col-md-12">
<% if (message != null) { %>
    <div class="alert alert-success"><%=message%></div>
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/configuration/remise-liste.jsp">Retour &agrave; la liste</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/remise-saisie.jsp">Nouvelle r&egrave;gle</a>
<% } else { %>
    <% if (erreur != null) { %><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div><% } %>
    <form action="<%=lien%>?but=cinema/configuration/remise-saisie.jsp" method="post"
          class="cardradius" style="padding:16px">
        <input type="hidden" name="action" value="<%= id.isEmpty() ? "insert" : "update" %>">
        <input type="hidden" name="id" value="<%=cinH(id)%>">

        <div class="input-container">
            <div class="form-input"><label class="input-label">Cat&eacute;gorie d&eacute;clencheuse *</label>
                <select class="form-control" name="idCategorieReservation" required>
                    <option value="">-- Choisir --</option>
<%      for (int i = 0; i < categories.size(); i++) {
            String[] cat = categories.get(i);
%>
                    <option value="<%=cinH(cat[0])%>"<%=cinSelected(cat[0], idCategorieReservation)%>><%=cinH(cat[1])%><%= "1".equals(cat[2]) ? "" : " (inactif)" %></option>
<%      } %>
                </select></div>
            <div class="form-input"><label class="input-label">Nombre de places (seuil) *</label>
                <input class="form-control" type="number" min="1" step="1" name="nombrePlace"
                       value="<%= nombrePlace == 0 ? "" : String.valueOf(nombrePlace) %>" required></div>
        </div>

        <div class="input-container">
            <div class="form-input"><label class="input-label">Type de valeur</label>
                <select class="form-control" name="typeValeur">
                    <option value="0"<%=cinSelected("0", String.valueOf(typeValeur))%>>Pourcentage</option>
                    <option value="1"<%=cinSelected("1", String.valueOf(typeValeur))%>>Montant fixe (Ar)</option>
                </select></div>
            <div class="form-input"><label class="input-label">Valeur de la remise *</label>
                <input class="form-control" type="number" min="0" step="0.01" name="valeur"
                       value="<%= valeur == 0 ? "" : String.valueOf(valeur) %>" required>
                <small>Pourcentage : entre 0 et 100. Montant : d&eacute;duction par place.</small></div>
        </div>

        <div class="input-container">
            <div class="form-input"><label class="input-label">Cat&eacute;gorie remis&eacute;e *</label>
                <select class="form-control" name="idCategorieRemise" required>
                    <option value="">-- Choisir --</option>
<%      for (int i = 0; i < categories.size(); i++) {
            String[] cat = categories.get(i);
%>
                    <option value="<%=cinH(cat[0])%>"<%=cinSelected(cat[0], idCategorieRemise)%>><%=cinH(cat[1])%><%= "1".equals(cat[2]) ? "" : " (inactif)" %></option>
<%      } %>
                </select></div>
            <div class="form-input"><label class="input-label">Nombre de places remis&eacute;es *</label>
                <input class="form-control" type="number" min="1" step="1" name="nombrePlaceRemise"
                       value="<%= nombrePlaceRemise == 0 ? "" : String.valueOf(nombrePlaceRemise) %>" required></div>
        </div>

        <div class="input-container">
            <div class="form-input" style="width:100%"><label class="input-label">Description</label>
                <input class="form-control" type="text" name="desce" value="<%=cinH(desce)%>"
                       placeholder="Ex. : offre famille"></div>
            <div class="form-input"><label class="input-label">&Eacute;tat</label>
                <select class="form-control" name="etat">
                    <option value="1"<%=cinSelected("1", String.valueOf(etat))%>>Actif</option>
                    <option value="0"<%=cinSelected("0", String.valueOf(etat))%>>Inactif</option>
                </select></div>
        </div>

        <p><small>La cat&eacute;gorie d&eacute;clencheuse et la cat&eacute;gorie remis&eacute;e
        doivent &ecirc;tre diff&eacute;rentes.</small></p>

        <div style="margin-top:12px">
            <button type="submit" class="btn btn-primary">Enregistrer</button>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/remise-liste.jsp">Annuler</a>
        </div>
    </form>
<% } %>
</div>
</div>
