<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.film.Film" %>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String action = cinS(request.getParameter("action"));
    String id = cinS(request.getParameter("id"));
    String titre = cinS(request.getParameter("titre"));
    String titreOriginal = cinS(request.getParameter("titreOriginal"));
    String idGenre = cinS(request.getParameter("idGenre"));
    int duree = cinI(request.getParameter("duree"));
    String langue = cinS(request.getParameter("langue"));
    int annee = cinI(request.getParameter("annee"));
    String realisateur = cinS(request.getParameter("realisateur"));
    String acteurs = cinS(request.getParameter("acteurs"));
    String classification = cinS(request.getParameter("classification"));
    String synopsis = cinS(request.getParameter("synopsis"));
    String affiche = cinS(request.getParameter("affiche"));
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
                Film f = (Film) new Film().getById(id, "CINEMA_FILM", c);
                if (f == null || f.getId() == null) throw new Exception("Film introuvable : " + id);
                f.deleteToTableWithHisto(userId, c);
                message = "Film supprimé.";
            } else {
                if (titre.trim().isEmpty()) throw new Exception("Le titre du film est obligatoire.");
                if (duree <= 0) throw new Exception("La durée doit être strictement positive.");
                Film f;
                if ("update".equals(action)) {
                    if (id.trim().isEmpty()) throw new Exception("Identifiant obligatoire.");
                    f = new Film();
                    f.setId(id);
                } else {
                    f = new Film();
                }
                f.setTitre(titre);
                f.setTitreOriginal(titreOriginal);
                f.setIdGenre(idGenre.trim().isEmpty() ? null : idGenre);
                f.setDuree(duree);
                f.setLangue(langue);
                f.setAnnee(annee);
                f.setRealisateur(realisateur);
                f.setActeurs(acteurs);
                f.setClassification(classification);
                f.setSynopsis(synopsis);
                f.setAffiche(affiche);
                f.setEtat(etat);
                if ("update".equals(action)) {
                    f.updateObject(userId, c);
                    message = "Film modifié.";
                } else {
                    f.createObject(userId, c);
                    id = f.getId();
                    message = "Film enregistré.";
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
                    "SELECT * FROM CINEMA_FILM WHERE ID = ?");
            ps.setString(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                titre = cinS(rs.getString("TITRE"));
                titreOriginal = cinS(rs.getString("TITREORIGINAL"));
                idGenre = cinS(rs.getString("IDGENRE"));
                duree = rs.getInt("DUREE");
                langue = cinS(rs.getString("LANGUE"));
                annee = rs.getInt("ANNEE");
                realisateur = cinS(rs.getString("REALISATEUR"));
                acteurs = cinS(rs.getString("ACTEURS"));
                classification = cinS(rs.getString("CLASSIFICATION"));
                synopsis = cinS(rs.getString("SYNOPSIS"));
                affiche = cinS(rs.getString("AFFICHE"));
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
    <h1><%= id.isEmpty() ? "Nouveau film" : "Modifier le film" %></h1>
</section>

<div class="col-md-12">
<% if (message != null) { %>
    <div class="alert alert-success"><%=message%></div>
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/film/film-liste.jsp">Retour à la liste</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/film/film-fiche.jsp&id=<%=cinH(id)%>">Voir la fiche</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/film/film-saisie.jsp">Nouveau film</a>
<% } else { %>
    <% if (erreur != null) { %><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div><% } %>
    <form action="<%=lien%>?but=cinema/film/film-saisie.jsp" method="post" class="cardradius" style="padding:16px">
        <input type="hidden" name="action" value="<%= id.isEmpty() ? "insert" : "update" %>">
        <input type="hidden" name="id" value="<%=cinH(id)%>">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Titre *</label>
                <input class="form-control" type="text" name="titre" value="<%=cinH(titre)%>" required></div>
            <div class="form-input"><label class="input-label">Titre original</label>
                <input class="form-control" type="text" name="titreOriginal" value="<%=cinH(titreOriginal)%>"></div>
            <div class="form-input"><label class="input-label">Genre</label>
                <select class="form-control" name="idGenre">
                    <option value="">-- Aucun --</option>
<%
        try {
            c = new UtilDB().GetConn();
            PreparedStatement ps = c.prepareStatement("SELECT ID, VAL FROM CINEMA_GENRE WHERE ETAT = 1 ORDER BY VAL");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String gid = rs.getString("ID");
%>
                    <option value="<%=cinH(gid)%>"<%=cinSelected(gid, idGenre)%>><%=cinH(rs.getString("VAL"))%></option>
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
            <div class="form-input"><label class="input-label">Durée (minutes) *</label>
                <input class="form-control" type="number" min="1" max="600" name="duree" value="<%=duree%>" required></div>
            <div class="form-input"><label class="input-label">Langue</label>
                <input class="form-control" type="text" name="langue" value="<%=cinH(langue)%>"></div>
            <div class="form-input"><label class="input-label">Année</label>
                <input class="form-control" type="number" min="0" max="2100" name="annee" value="<%=annee%>"></div>
            <div class="form-input"><label class="input-label">Réalisateur</label>
                <input class="form-control" type="text" name="realisateur" value="<%=cinH(realisateur)%>"></div>
            <div class="form-input"><label class="input-label">Classification</label>
                <input class="form-control" type="text" name="classification" value="<%=cinH(classification)%>" placeholder="Tous publics, -12..."></div>
            <div class="form-input"><label class="input-label">Affiche (URL)</label>
                <input class="form-control" type="text" name="affiche" value="<%=cinH(affiche)%>"></div>
            <div class="form-input"><label class="input-label">&Eacute;tat</label>
                <select class="form-control" name="etat">
                    <option value="1"<%=cinSelected("1", String.valueOf(etat))%>>Actif</option>
                    <option value="0"<%=cinSelected("0", String.valueOf(etat))%>>Inactif</option>
                </select></div>
        </div>
        <div class="form-input" style="width:100%"><label class="input-label">Acteurs</label>
            <input class="form-control" type="text" name="acteurs" value="<%=cinH(acteurs)%>"></div>
        <div class="form-input" style="width:100%"><label class="input-label">Synopsis</label>
            <textarea class="form-control" name="synopsis" rows="4"><%=cinH(synopsis)%></textarea></div>
        <div style="margin-top:12px">
            <button type="submit" class="btn btn-primary">Enregistrer</button>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/film/film-liste.jsp">Annuler</a>
        </div>
    </form>
<% } %>
</div>
</div>
