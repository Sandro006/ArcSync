<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.configuration.Salle" %>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String action = cinS(request.getParameter("action"));
    String id = cinS(request.getParameter("id"));
    String nom = cinS(request.getParameter("nom"));
    String adresse = cinS(request.getParameter("adresse"));
    int capacite = cinI(request.getParameter("capacite"));
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
                Salle s = (Salle) new Salle().getById(id, "CINEMA_SALLE", c);
                if (s == null || s.getId() == null) throw new Exception("Salle introuvable : " + id);
                s.deleteToTableWithHisto(userId, c);
                message = "Salle supprimée.";
            } else if ("update".equals(action)) {
                if (id.trim().isEmpty()) throw new Exception("Identifiant obligatoire.");
                if (nom.trim().isEmpty()) throw new Exception("Le nom de la salle est obligatoire.");
                Salle s = new Salle();
                s.setId(id);
                s.setNom(nom);
                s.setAdresse(adresse);
                s.setCapacite(capacite);
                s.setEtat(etat);
                s.updateObject(userId, c);
                message = "Salle modifiée.";
            } else {
                if (nom.trim().isEmpty()) throw new Exception("Le nom de la salle est obligatoire.");
                Salle s = new Salle();
                s.setNom(nom);
                s.setAdresse(adresse);
                s.setCapacite(capacite);
                s.setEtat(etat);
                s.createObject(userId, c);
                id = s.getId();
                message = "Salle enregistrée.";
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
            PreparedStatement ps = c.prepareStatement("SELECT NOM, ADRESSE, CAPACITE, ETAT FROM CINEMA_SALLE WHERE ID = ?");
            ps.setString(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                nom = cinS(rs.getString("NOM"));
                adresse = cinS(rs.getString("ADRESSE"));
                capacite = rs.getInt("CAPACITE");
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
    if (capacite <= 0 && id.isEmpty()) capacite = 100;
%>
<div class="content-wrapper">
<section class="content-header">
    <h1><%= id.isEmpty() ? "Nouvelle salle" : "Modifier la salle" %></h1>
</section>

<div class="col-md-12">
<% if (message != null) { %>
    <div class="alert alert-success"><%=message%></div>
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/configuration/salle-liste.jsp">Retour &agrave; la liste</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/place-liste.jsp&idSalle=<%=cinH(id)%>">G&eacute;rer les places</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/salle-saisie.jsp">Nouvelle salle</a>
<% } else { %>
    <% if (erreur != null) { %><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div><% } %>
    <form action="<%=lien%>?but=cinema/configuration/salle-saisie.jsp" method="post" class="cardradius" style="padding:16px">
        <input type="hidden" name="action" value="<%= id.isEmpty() ? "insert" : "update" %>">
        <input type="hidden" name="id" value="<%=cinH(id)%>">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Nom de la salle *</label>
                <input class="form-control" type="text" name="nom" value="<%=cinH(nom)%>" required></div>
            <div class="form-input"><label class="input-label">Capacit&eacute; *</label>
                <input class="form-control" type="number" min="1" step="1" name="capacite" value="<%= capacite %>" required></div>
            <div class="form-input"><label class="input-label">&Eacute;tat</label>
                <select class="form-control" name="etat">
                    <option value="1"<%=cinSelected("1", String.valueOf(etat))%>>Actif</option>
                    <option value="0"<%=cinSelected("0", String.valueOf(etat))%>>Inactif</option>
                </select></div>
        </div>
        <div class="form-input" style="width:100%"><label class="input-label">Adresse</label>
            <input class="form-control" type="text" name="adresse" value="<%=cinH(adresse)%>"></div>
        <div style="margin-top:12px">
            <button type="submit" class="btn btn-primary">Enregistrer</button>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/salle-liste.jsp">Annuler</a>
        </div>
    </form>
<% } %>
</div>
</div>
