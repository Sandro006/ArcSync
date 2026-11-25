<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.configuration.Genre" %>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String action = cinS(request.getParameter("action"));
    String id = cinS(request.getParameter("id"));
    String val = cinS(request.getParameter("val"));
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
            if ("delete".equals(action)) {
                Genre g = (Genre) new Genre().getById(id, "CINEMA_GENRE", c);
                if (g == null || g.getId() == null) throw new Exception("Genre introuvable : " + id);
                g.deleteToTableWithHisto(userId, c);
                message = "Genre supprimé.";
            } else if ("update".equals(action)) {
                if (id.trim().isEmpty()) throw new Exception("Identifiant obligatoire.");
                if (val.trim().isEmpty()) throw new Exception("Le nom du genre est obligatoire.");
                Genre g = new Genre();
                g.setId(id);
                g.setVal(val);
                g.setDesce(desce);
                g.setEtat(etat);
                g.updateObject(userId, c);
                message = "Genre modifié.";
            } else {
                if (val.trim().isEmpty()) throw new Exception("Le nom du genre est obligatoire.");
                Genre g = new Genre();
                g.setVal(val);
                g.setDesce(desce);
                g.setEtat(etat);
                g.createObject(userId, c);
                id = g.getId();
                message = "Genre enregistré.";
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
            PreparedStatement ps = c.prepareStatement("SELECT VAL, DESCE, ETAT FROM CINEMA_GENRE WHERE ID = ?");
            ps.setString(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                val = cinS(rs.getString("VAL"));
                desce = cinS(rs.getString("DESCE"));
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
    <h1><%= id.isEmpty() ? "Nouveau genre" : "Modifier le genre" %></h1>
</section>

<div class="col-md-12">
<% if (message != null) { %>
    <div class="alert alert-success"><%=message%></div>
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/configuration/genre-liste.jsp">Retour &agrave; la liste</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/genre-saisie.jsp">Nouveau genre</a>
<% } else { %>
    <% if (erreur != null) { %><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div><% } %>
    <form action="<%=lien%>?but=cinema/configuration/genre-saisie.jsp" method="post" class="cardradius" style="padding:16px">
        <input type="hidden" name="action" value="<%= id.isEmpty() ? "insert" : "update" %>">
        <input type="hidden" name="id" value="<%=cinH(id)%>">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Nom du genre *</label>
                <input class="form-control" type="text" name="val" value="<%=cinH(val)%>" required></div>
            <div class="form-input"><label class="input-label">&Eacute;tat</label>
                <select class="form-control" name="etat">
                    <option value="1"<%=cinSelected("1", String.valueOf(etat))%>>Actif</option>
                    <option value="0"<%=cinSelected("0", String.valueOf(etat))%>>Inactif</option>
                </select></div>
        </div>
        <div class="form-input" style="width:100%"><label class="input-label">Description</label>
            <input class="form-control" type="text" name="desce" value="<%=cinH(desce)%>"></div>
        <div style="margin-top:12px">
            <button type="submit" class="btn btn-primary">Enregistrer</button>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/configuration/genre-liste.jsp">Annuler</a>
        </div>
    </form>
<% } %>
</div>
</div>
