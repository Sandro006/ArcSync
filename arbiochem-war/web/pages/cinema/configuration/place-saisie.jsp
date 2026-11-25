<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.configuration.Place" %>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String action = cinS(request.getParameter("action"));
    String id = cinS(request.getParameter("id"));
    String idMere = cinS(request.getParameter("idMere"));
    if (idMere.isEmpty()) idMere = cinS(request.getParameter("idSalle"));
    String numero = cinS(request.getParameter("numero"));
    String rang = cinS(request.getParameter("rang"));
    int colonne = cinI(request.getParameter("colonne"));
    String idCategoriePlace = cinS(request.getParameter("idCategoriePlace"));
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
            if ("delete".equals(action)) {
                Place p = (Place) new Place().getById(id, "CINEMA_PLACE", c);
                if (p == null || p.getId() == null) throw new Exception("Place introuvable : " + id);
                idMere = p.getIdMere();
                p.deleteToTableWithHisto(userId, c);
                message = "Place supprimée.";
            } else {
                if (idMere.trim().isEmpty()) throw new Exception("La salle est obligatoire.");
                if (numero.trim().isEmpty()) throw new Exception("Le numéro de place est obligatoire.");
                if ("update".equals(action)) {
                    if (id.trim().isEmpty()) throw new Exception("Identifiant obligatoire.");
                    Place p = new Place();
                    p.setId(id);
                    p.setIdMere(idMere);
                    p.setNumero(numero);
                    p.setRang(rang);
                    p.setColonne(colonne);
                    p.setIdCategoriePlace(idCategoriePlace.trim().isEmpty() ? null : idCategoriePlace);
                    p.setEtat(etat);
                    p.updateObject(userId, c);
                    message = "Place modifiée.";
                } else {
                    Place p = new Place();
                    p.setIdMere(idMere);
                    p.setNumero(numero);
                    p.setRang(rang);
                    p.setColonne(colonne);
                    p.setIdCategoriePlace(idCategoriePlace.trim().isEmpty() ? null : idCategoriePlace);
                    p.setEtat(etat);
                    p.createObject(userId, c);
                    id = p.getId();
                    message = "Place enregistrée.";
                }
            }
            c.commit();
            done = true;
        } catch (Exception e) {
            erreur = e.getMessage();
            try { if (c != null) c.rollback(); } catch (Exception ignore) {}
            e.printStackTrace();
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignore) {}
        }
    }

    if (!done && !id.isEmpty()) {
        try {
            c = new UtilDB().GetConn();
            PreparedStatement ps = c.prepareStatement(
                    "SELECT IDMERE, NUMERO, RANG, COLONNE, IDCATEGORIEPLACE, ETAT FROM CINEMA_PLACE WHERE ID = ?");
            ps.setString(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                idMere = cinS(rs.getString("IDMERE"));
                numero = cinS(rs.getString("NUMERO"));
                rang = cinS(rs.getString("RANG"));
                colonne = rs.getInt("COLONNE");
                idCategoriePlace = cinS(rs.getString("IDCATEGORIEPLACE"));
                etat = rs.getInt("ETAT");
            }
            cinClose(rs, ps, c);
            c = null;
        } catch (Exception e) {
            if (erreur == null) erreur = e.getMessage();
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignore) {}
        }
    }
%>
<div class="content-wrapper">
<section class="content-header">
    <h1><%= id.isEmpty() ? "Nouvelle place" : "Modifier la place" %></h1>
</section>

<div class="col-md-12">
<% if (message != null) { %>
    <div class="alert alert-success"><%=message%></div>
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/configuration/place-liste.jsp&idSalle=<%=cinH(idMere)%>">Retour aux places</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/place-saisie.jsp&idSalle=<%=cinH(idMere)%>">Nouvelle place</a>
<% } else { %>
    <% if (erreur != null) { %><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div><% } %>
    <form action="<%=lien%>?but=cinema/configuration/place-saisie.jsp" method="post" class="cardradius" style="padding:16px">
        <input type="hidden" name="action" value="<%= id.isEmpty() ? "insert" : "update" %>">
        <input type="hidden" name="id" value="<%=cinH(id)%>">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Salle *</label>
                <select class="form-control" name="idMere" required>
                    <option value="">-- Choisir --</option>
<%
        try {
            c = new UtilDB().GetConn();
            PreparedStatement ps = c.prepareStatement("SELECT ID, NOM FROM CINEMA_SALLE WHERE ETAT = 1 ORDER BY NOM");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String sid = rs.getString("ID");
%>
                    <option value="<%=cinH(sid)%>"<%=cinSelected(sid, idMere)%>><%=cinH(rs.getString("NOM"))%></option>
<%
            }
            cinClose(rs, ps, c);
            c = null;
        } catch (Exception e) {
            if (erreur == null) erreur = e.getMessage();
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignore) {}
        }
%>
                </select></div>
            <div class="form-input"><label class="input-label">Numéro *</label>
                <input class="form-control" type="text" name="numero" value="<%=cinH(numero)%>" placeholder="A01" required></div>
            <div class="form-input"><label class="input-label">Rang</label>
                <input class="form-control" type="text" name="rang" value="<%=cinH(rang)%>" placeholder="A"></div>
            <div class="form-input"><label class="input-label">Colonne</label>
                <input class="form-control" type="number" min="0" step="1" name="colonne" value="<%=colonne%>"></div>
            <div class="form-input"><label class="input-label">Catégorie</label>
                <select class="form-control" name="idCategoriePlace">
                    <option value="">-- Aucune --</option>
<%
        try {
            c = new UtilDB().GetConn();
            PreparedStatement ps = c.prepareStatement("SELECT ID, VAL FROM CINEMA_CATEGORIEPLACE WHERE ETAT = 1 ORDER BY VAL");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String cid = rs.getString("ID");
%>
                    <option value="<%=cinH(cid)%>"<%=cinSelected(cid, idCategoriePlace)%>><%=cinH(rs.getString("VAL"))%></option>
<%
            }
            cinClose(rs, ps, c);
            c = null;
        } catch (Exception e) {
            if (erreur == null) erreur = e.getMessage();
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignore) {}
        }
%>
                </select></div>
            <div class="form-input"><label class="input-label">&Eacute;tat</label>
                <select class="form-control" name="etat">
                    <option value="1"<%=cinSelected("1", String.valueOf(etat))%>>Active</option>
                    <option value="0"<%=cinSelected("0", String.valueOf(etat))%>>Inactive</option>
                </select></div>
        </div>
        <div style="margin-top:12px">
            <button type="submit" class="btn btn-primary">Enregistrer</button>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/place-liste.jsp&idSalle=<%=cinH(idMere)%>">Annuler</a>
        </div>
    </form>
<% } %>
</div>
</div>
