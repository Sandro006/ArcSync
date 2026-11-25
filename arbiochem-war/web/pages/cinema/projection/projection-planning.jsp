<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Planning journalier par salle.
--%>
<%
    String lien = (String) session.getValue("lien");
    String datyP = cinS(request.getParameter("daty"));
    java.sql.Date daty = cinDate(datyP);
    if (daty == null) daty = new java.sql.Date(System.currentTimeMillis());
    java.sql.Date veille = new java.sql.Date(daty.getTime() - 24L * 60 * 60 * 1000);
    java.sql.Date lendemain = new java.sql.Date(daty.getTime() + 24L * 60 * 60 * 1000);

    String erreur = null;
    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    int totalSeances = 0, totalVendues = 0, totalReservees = 0;
    double totalRecette = 0;
%>
<div class="content-wrapper">
<section class="content-header"><h1>Planning des projections</h1></section>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/projection/projection-planning.jsp" method="get">
        <input type="hidden" name="but" value="cinema/projection/projection-planning.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Date</label>
                <input class="form-control" type="date" name="daty" value="<%=daty.toString()%>"></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary">Afficher</button></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <a class="btn btn-secondary" href="<%=lien%>?but=cinema/projection/projection-planning.jsp&daty=<%=veille.toString()%>">&laquo; Veille</a>
                <a class="btn btn-secondary" href="<%=lien%>?but=cinema/projection/projection-planning.jsp&daty=<%=lendemain.toString()%>">Lendemain &raquo;</a>
            </div>
        </div>
    </form>
</div>

<div class="col-md-12" style="margin-top:12px">
    <a class="btn btn-primary" href="<%=lien%>?but=cinema/projection/projection-saisie.jsp">Pr&eacute;parer une projection</a>
    <a class="btn btn-secondary" href="<%=lien%>?but=cinema/projection/projection-liste.jsp">Liste des projections</a>
</div>

<div class="col-md-12">
<%
    try {
        c = new UtilDB().GetConn();

        ps = c.prepareStatement(
                "SELECT COUNT(*), NVL(SUM(NBPLACESVENDUES),0), NVL(SUM(NBPLACESRESERVEES),0), NVL(SUM(RECETTE),0)"
                + " FROM CINEMA_PROJECTION_LIB WHERE TRUNC(DATY) = TRUNC(?) AND ETAT <> 0");
        ps.setDate(1, daty);
        rs = ps.executeQuery();
        if (rs.next()) {
            totalSeances = rs.getInt(1);
            totalVendues = rs.getInt(2);
            totalReservees = rs.getInt(3);
            totalRecette = rs.getDouble(4);
        }
        cinClose(rs, ps, null); rs = null; ps = null;
%>
    <div class="cardradius" style="padding:16px;margin-top:16px">
        <h3><%=cinDateFmt(daty)%></h3>
        <p><b><%=totalSeances%></b> s&eacute;ance(s) &mdash;
           <b><%=totalVendues%></b> billet(s) vendu(s),
           <b><%=totalReservees%></b> place(s) r&eacute;serv&eacute;e(s) &mdash;
           recette <b><%=cinMoney(totalRecette)%> Ar</b></p>
    </div>
<%
        ps = c.prepareStatement("SELECT ID, NOM, CAPACITE FROM CINEMA_SALLE WHERE ETAT = 1 ORDER BY NOM");
        rs = ps.executeQuery();
        java.util.List<String[]> salles = new java.util.ArrayList<String[]>();
        while (rs.next()) {
            salles.add(new String[]{rs.getString("ID"), rs.getString("NOM"), String.valueOf(rs.getInt("CAPACITE"))});
        }
        cinClose(rs, ps, null); rs = null; ps = null;

        for (int s = 0; s < salles.size(); s++) {
            String sid = salles.get(s)[0];
            String snom = salles.get(s)[1];
            int scap = cinI(salles.get(s)[2]);
%>
    <div class="cardradius" style="padding:16px;margin-top:16px">
        <h4><%=cinH(snom)%> <small>(<%=scap%> places)</small></h4>
        <table class="table table-bordered">
            <tr><th>Heure</th><th>Film</th><th>Format</th><th>Statut</th>
                <th>Vendues</th><th>R&eacute;serv&eacute;es</th><th>Remplissage</th><th>Recette</th><th></th></tr>
<%
            ps = c.prepareStatement(
                    "SELECT * FROM CINEMA_PROJECTION_LIB WHERE IDSALLE = ? AND TRUNC(DATY) = TRUNC(?) AND ETAT <> 0"
                    + " ORDER BY HEUREDEBUT");
            ps.setString(1, sid);
            ps.setDate(2, daty);
            rs = ps.executeQuery();
            boolean any = false;
            while (rs.next()) {
                any = true;
                String idProj = rs.getString("ID");
                int nb = rs.getInt("NBPLACES");
                int vendues = rs.getInt("NBPLACESVENDUES");
                int reservees = rs.getInt("NBPLACESRESERVEES");
                int taux = nb > 0 ? (int) Math.round((vendues + reservees) * 100.0 / nb) : 0;
%>
            <tr>
                <td><%=cinH(rs.getString("HEUREDEBUT"))%> - <%=cinH(rs.getString("HEUREFIN"))%></td>
                <td><a href="<%=lien%>?but=cinema/projection/projection-fiche.jsp&id=<%=idProj%>"><%=cinH(rs.getString("IDFILMLIB"))%></a></td>
                <td><%=cinH(rs.getString("FORMAT"))%> / <%=cinH(rs.getString("VERSION"))%></td>
                <td><%=cinH(rs.getString("STATUTLIB"))%></td>
                <td><%=vendues%></td>
                <td><%=reservees%></td>
                <td><%=taux%> %</td>
                <td><%=cinMoney(rs.getDouble("RECETTE"))%></td>
                <td>
                    <% if (rs.getInt("STATUT") == 2) { %>
                    <a class="btn btn-primary btn-sm" href="<%=lien%>?but=cinema/billet/billet-vente.jsp&idProjection=<%=idProj%>">Caisse</a>
                    <% } %>
                </td>
            </tr>
<%
            }
            if (!any) {
%>
            <tr><td colspan="9">Aucune s&eacute;ance.</td></tr>
<%
            }
            cinClose(rs, ps, null); rs = null; ps = null;
%>
        </table>
    </div>
<%
        }
    } catch (Exception e) {
        erreur = e.getMessage();
        e.printStackTrace();
    } finally {
        cinClose(rs, ps, c);
    }
    if (erreur != null) {
%>
    <div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div>
<%
    }
%>
</div>
</div>
