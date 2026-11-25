<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.projection.ProjectionService" %>
<%@ page import="cinema.utils.ConstanteCinema" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%--
    Preparation d'une projection : film, salle, horaire, prix de base et
    tarifs par categorie de place.
--%>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String action = cinS(request.getParameter("action"));
    String idFilm = cinS(request.getParameter("idFilm"));
    String idSalle = cinS(request.getParameter("idSalle"));
    String datyP = cinS(request.getParameter("daty"));
    String heureDebut = cinS(request.getParameter("heureDebut"));
    String heureFin = cinS(request.getParameter("heureFin"));
    double prixBase = cinD(request.getParameter("prixBase"));
    String format = cinS(request.getParameter("format"));
    String version = cinS(request.getParameter("version"));
    String remarque = cinS(request.getParameter("remarque"));

    java.sql.Date daty = cinDate(datyP);
    if (daty == null) daty = new java.sql.Date(System.currentTimeMillis());
    if (heureDebut.isEmpty()) heureDebut = "18:00";
    if (heureFin.isEmpty()) heureFin = "20:00";

    String message = null;
    String erreur = null;
    String idCree = null;
    Connection c = null;

    if ("insert".equals(action)) {
        try {
            if (idFilm.trim().isEmpty()) throw new Exception("Le film est obligatoire.");
            if (idSalle.trim().isEmpty()) throw new Exception("La salle est obligatoire.");

            List<ProjectionService.LigneTarif> tarifs = new ArrayList<ProjectionService.LigneTarif>();
            c = new UtilDB().GetConn();
            PreparedStatement ps = c.prepareStatement(
                    "SELECT ID, VAL, PRIXDEFAUT FROM CINEMA_CATEGORIEPLACE WHERE ETAT = 1 ORDER BY VAL");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String idCat = rs.getString("ID");
                double prix = cinD(request.getParameter("prix_" + idCat));
                int quota = cinI(request.getParameter("quota_" + idCat));
                if (prix > 0) {
                    tarifs.add(new ProjectionService.LigneTarif(idCat, ConstanteCinema.RANG_TOUS, prix, quota));
                }
            }
            cinClose(rs, ps, c);
            c = null;

            if (tarifs.isEmpty()) {
                throw new Exception("Renseignez au moins un tarif (prix superieur a 0).");
            }

            ProjectionService.Resultat res = ProjectionService.preparerProjection(userId,
                    idFilm, idSalle, daty, heureDebut, heureFin, prixBase, tarifs,
                    remarque, format, version);
            idCree = res.idProjection;
            message = "Projection préparée.";
        } catch (Exception e) {
            erreur = e.getMessage();
            e.printStackTrace();
        } finally {
            try { if (c != null) c.close(); } catch (Exception ignore) {}
        }
    }
%>
<div class="content-wrapper">
<section class="content-header"><h1>Pr&eacute;parer une projection</h1></section>

<div class="col-md-12">
<% if (message != null) { %>
    <div class="alert alert-success"><%=message%> R&eacute;f&eacute;rence : <b><%=cinH(idCree)%></b></div>
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=cinH(idCree)%>">Voir la fiche</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/projection/projection-liste.jsp">Liste des projections</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/projection/projection-saisie.jsp">Nouvelle projection</a>
<% } else { %>
    <% if (erreur != null) { %><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div><% } %>
    <form action="<%=lien%>?but=cinema/projection/projection-saisie.jsp" method="post" id="formProj">
        <input type="hidden" name="action" value="insert">
        <div class="cardradius" style="padding:16px">
            <div class="input-container">
                <div class="form-input"><label class="input-label">Film *</label>
                    <select class="form-control" name="idFilm" id="idFilm" required>
                        <option value="">-- Choisir --</option>
<%
        try {
            c = new UtilDB().GetConn();
            PreparedStatement ps = c.prepareStatement(
                    "SELECT ID, TITRE, DUREE FROM CINEMA_FILM WHERE ETAT = 1 ORDER BY TITRE");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String fid = rs.getString("ID");
%>
                        <option value="<%=cinH(fid)%>"<%=cinSelected(fid, idFilm)%> data-duree="<%=rs.getInt("DUREE")%>"><%=cinH(rs.getString("TITRE"))%></option>
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
                <div class="form-input"><label class="input-label">Salle *</label>
                    <select class="form-control" name="idSalle" required>
                        <option value="">-- Choisir --</option>
<%
        try {
            c = new UtilDB().GetConn();
            PreparedStatement ps = c.prepareStatement(
                    "SELECT ID, NOM, CAPACITE FROM CINEMA_SALLE WHERE ETAT = 1 ORDER BY NOM");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String sid = rs.getString("ID");
%>
                        <option value="<%=cinH(sid)%>"<%=cinSelected(sid, idSalle)%>><%=cinH(rs.getString("NOM"))%> (<%=rs.getInt("CAPACITE")%> places)</option>
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
                <div class="form-input"><label class="input-label">Date *</label>
                    <input class="form-control" type="date" name="daty" value="<%=cinH(daty.toString())%>" required></div>
                <div class="form-input"><label class="input-label">Heure d&eacute;but *</label>
                    <input class="form-control" type="time" name="heureDebut" id="heureDebut" value="<%=cinH(heureDebut)%>" required></div>
                <div class="form-input"><label class="input-label">Heure fin *</label>
                    <input class="form-control" type="time" name="heureFin" id="heureFin" value="<%=cinH(heureFin)%>" required></div>
                <div class="form-input"><label class="input-label">Prix de base (Ar)</label>
                    <input class="form-control" type="number" min="0" step="1" name="prixBase" value="<%=prixBase%>"></div>
                <div class="form-input"><label class="input-label">Format</label>
                    <select class="form-control" name="format">
                        <option value="2D"<%=cinSelected("2D", format)%>>2D</option>
                        <option value="3D"<%=cinSelected("3D", format)%>>3D</option>
                        <option value="IMAX"<%=cinSelected("IMAX", format)%>>IMAX</option>
                    </select></div>
                <div class="form-input"><label class="input-label">Version</label>
                    <select class="form-control" name="version">
                        <option value="VF"<%=cinSelected("VF", version)%>>VF</option>
                        <option value="VO"<%=cinSelected("VO", version)%>>VO</option>
                        <option value="VOST"<%=cinSelected("VOST", version)%>>VOST</option>
                    </select></div>
                <div class="form-input" style="width:100%"><label class="input-label">Remarque</label>
                    <input class="form-control" type="text" name="remarque" value="<%=cinH(remarque)%>"></div>
            </div>
        </div>

        <div class="cardradius" style="padding:16px;margin-top:16px">
            <h4>Tarifs par cat&eacute;gorie</h4>
            <p>Un prix &agrave; 0 exclut la cat&eacute;gorie. Le quota 0 signifie illimit&eacute;.</p>
            <table class="table table-bordered">
                <tr><th>Cat&eacute;gorie</th><th>Prix (Ar)</th><th>Quota</th></tr>
<%
        try {
            c = new UtilDB().GetConn();
            PreparedStatement ps = c.prepareStatement(
                    "SELECT ID, VAL, PRIXDEFAUT FROM CINEMA_CATEGORIEPLACE WHERE ETAT = 1 ORDER BY VAL");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String idCat = rs.getString("ID");
                String pv = request.getParameter("prix_" + idCat);
                String qv = request.getParameter("quota_" + idCat);
                double prix = (pv == null)
                        ? (prixBase > 0 ? prixBase : rs.getDouble("PRIXDEFAUT"))
                        : cinD(pv);
                int quota = (qv == null) ? 0 : cinI(qv);
%>
                <tr>
                    <td><%=cinH(rs.getString("VAL"))%></td>
                    <td><input class="form-control" type="number" min="0" step="1" name="prix_<%=idCat%>" value="<%=prix%>"></td>
                    <td><input class="form-control" type="number" min="0" step="1" name="quota_<%=idCat%>" value="<%=quota%>"></td>
                </tr>
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
            </table>
            <div>
                <button type="submit" class="btn btn-primary">Enregistrer la projection</button>
                <a class="btn btn-secondary" href="<%=lien%>?but=cinema/projection/projection-liste.jsp">Annuler</a>
            </div>
        </div>
    </form>

    <script>
    function majFin() {
        var sel = document.getElementById("idFilm");
        if (!sel || !sel.options[sel.selectedIndex]) return;
        var duree = parseInt(sel.options[sel.selectedIndex].getAttribute("data-duree") || "0", 10);
        var debut = document.getElementById("heureDebut").value;
        if (duree > 0 && debut) {
            var parts = debut.split(":");
            var total = parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10) + duree;
            total = total % (24 * 60);
            var h = Math.floor(total / 60);
            var m = total % 60;
            document.getElementById("heureFin").value = (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m);
        }
    }
    document.getElementById("idFilm").addEventListener("change", majFin);
    document.getElementById("heureDebut").addEventListener("change", majFin);
    </script>
<% } %>
</div>
</div>
