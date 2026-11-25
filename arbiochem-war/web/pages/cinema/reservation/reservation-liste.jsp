<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%@ page import="cinema.reservation.ReservationService" %>
<%--
    Liste des reservations avec filtres client, projection et statut.
--%>
<%
    request.setCharacterEncoding("UTF-8");
    UserEJB u = (UserEJB) session.getValue("u");
    String lien = (String) session.getValue("lien");
    String userId = u == null ? "system" : u.getUser().getTuppleID();

    String idClient = cinS(request.getParameter("idClient"));
    String idProjection = cinS(request.getParameter("idProjection"));
    String statutP = cinS(request.getParameter("statut"));
    String action = cinS(request.getParameter("action"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;

    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

    if ("expirer".equals(action)) {
        try {
            c = new UtilDB().GetConn();
            c.setAutoCommit(false);
            int n = ReservationService.expirerReservations(c);
            c.commit();
            message = n + " reservation(s) expiree(s).";
        } catch (Exception e) {
            erreur = e.getMessage();
            if (c != null) {
                try { c.rollback(); } catch (Exception ignore) {}
            }
            e.printStackTrace();
        } finally {
            if (c != null) {
                try { c.close(); } catch (Exception ignore) {}
            }
            c = null;
        }
    }
%>
<div class="content-wrapper">
<section class="content-header"><h1>R&eacute;servations</h1></section>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/reservation/reservation-liste.jsp" method="get">
        <input type="hidden" name="but" value="cinema/reservation/reservation-liste.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Client</label>
                <input class="form-control" type="textbox" name="idClient" value="<%=cinH(idClient)%>"
                       placeholder="Nom ou identifiant"></div>
            <div class="form-input"><label class="input-label">Projection</label>
                <select class="form-control" name="idProjection">
                    <option value="">Toutes</option>
<%
    try {
        c = new UtilDB().GetConn();
        ps = c.prepareStatement(
                "SELECT * FROM (SELECT ID, IDFILMLIB, IDSALLELIB, DATY, HEUREDEBUT"
                + " FROM CINEMA_PROJECTION_LIB"
                + " WHERE DATY >= TRUNC(SYSDATE) - 7 AND ETAT <> 0"
                + " ORDER BY DATY, HEUREDEBUT) WHERE ROWNUM <= 200");
        rs = ps.executeQuery();
        while (rs.next()) {
            String pid = rs.getString("ID");
%>
                    <option value="<%=cinH(pid)%>"<%=cinSelected(pid, idProjection)%>><%=cinDateFmt(rs.getDate("DATY"))%>
                        <%=cinH(rs.getString("HEUREDEBUT"))%> &mdash; <%=cinH(rs.getString("IDFILMLIB"))%>
                        (<%=cinH(rs.getString("IDSALLELIB"))%>)</option>
<%
        }
        cinClose(rs, ps, c); rs = null; ps = null; c = null;
    } catch (Exception e) {
        erreur = e.getMessage();
        e.printStackTrace();
    } finally {
        cinClose(rs, ps, c); rs = null; ps = null; c = null;
    }
%>
                </select></div>
            <div class="form-input"><label class="input-label">Statut</label>
                <select class="form-control" name="statut">
                    <option value="">Tous</option>
                    <option value="1"<%=cinSelected("1", statutP)%>>En attente</option>
                    <option value="2"<%=cinSelected("2", statutP)%>>Confirm&eacute;e</option>
                    <option value="3"<%=cinSelected("3", statutP)%>>Convertie</option>
                    <option value="4"<%=cinSelected("4", statutP)%>>Expir&eacute;e</option>
                    <option value="0"<%=cinSelected("0", statutP)%>>Annul&eacute;e</option>
                </select></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <button type="submit" class="btn btn-primary">Filtrer</button></div>
        </div>
    </form>
</div>

<div class="col-md-12" style="margin-top:8px">
    <a class="btn btn-primary pull-right" href="<%=lien%>?but=cinema/reservation/reservation-saisie.jsp">
        <i class="material-symbols-rounded">add</i> Nouvelle r&eacute;servation
    </a>
    <a class="btn btn-secondary pull-right" style="margin-right:8px"
       href="<%=lien%>?but=cinema/reservation/reservation-plan.jsp">Plan de salle</a>
    <form action="<%=lien%>?but=cinema/reservation/reservation-liste.jsp" method="post"
          style="display:inline;float:right;margin-right:8px"
          onsubmit="return confirm('Expirer toutes les r&eacute;servations &eacute;chues ?');">
        <input type="hidden" name="action" value="expirer">
        <button type="submit" class="btn btn-warning">Expirer les &eacute;ch&eacute;es</button>
    </form>
</div>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>
<% if (erreur != null) { %><div class="col-md-12"><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div></div><% } %>

<div class="col-md-12 cardradius" style="margin-top:16px">
<%
    try {
        c = new UtilDB().GetConn();
        String sql = "SELECT * FROM CINEMA_RESERVATION_LIB WHERE 1=1";
        if (!idClient.trim().isEmpty()) {
            sql += " AND (UPPER(IDCLIENTLIB) LIKE ? OR UPPER(IDCLIENT) LIKE ?)";
        }
        if (!idProjection.trim().isEmpty()) {
            sql += " AND IDPROJECTION = ?";
        }
        if (!statutP.trim().isEmpty()) {
            sql += " AND STATUT = ?";
        }
        sql += " ORDER BY DATY DESC, ID DESC";
        ps = c.prepareStatement(sql);
        int i = 1;
        if (!idClient.trim().isEmpty()) {
            String like = "%" + idClient.trim().toUpperCase() + "%";
            ps.setString(i++, like);
            ps.setString(i++, like);
        }
        if (!idProjection.trim().isEmpty()) {
            ps.setString(i++, idProjection);
        }
        if (!statutP.trim().isEmpty()) {
            ps.setInt(i++, cinI(statutP));
        }
        rs = ps.executeQuery();
%>
<table class="table table-bordered">
    <tr><th>Date</th><th>Client</th><th>Film</th><th>Salle</th><th>Places</th>
        <th>Total</th><th>Acompte</th><th>Reste</th><th>Expiration</th><th>Statut</th><th>Action</th></tr>
<%
        boolean any = false;
        while (rs.next()) {
            any = true;
            String rid = rs.getString("ID");
            int statut = rs.getInt("STATUT");
%>
    <tr>
        <td><%=cinDateFmt(rs.getDate("DATY"))%></td>
        <td><%=cinH(rs.getString("IDCLIENTLIB"))%></td>
        <td><%=cinH(rs.getString("IDFILMLIB"))%></td>
        <td><%=cinH(rs.getString("IDSALLELIB"))%></td>
        <td><%= rs.getInt("NBPLACESLIB") %></td>
        <td><%=cinMoney(rs.getDouble("MONTANTTOTALLIB"))%></td>
        <td><%=cinMoney(rs.getDouble("MONTANTACOMPTE"))%></td>
        <td><%=cinMoney(rs.getDouble("RESTEAPAYERLIB"))%></td>
        <td><%=cinTsFmt(rs.getTimestamp("DATEEXPIRATION"))%></td>
        <td><%=cinH(rs.getString("STATUTLIB"))%></td>
        <td>
            <a class="btn btn-secondary btn-sm"
               href="<%=lien%>?but=cinema/reservation/reservation-fiche.jsp&id=<%=cinH(rid)%>">Fiche</a>
            <% if (statut == 1 || statut == 2) { %>
            <a class="btn btn-secondary btn-sm"
               href="<%=lien%>?but=cinema/reservation/reservation-plan.jsp&idProjection=<%=cinH(rs.getString("IDPROJECTION"))%>">Plan</a>
            <% } %>
        </td>
    </tr>
<%
        }
        if (!any) {
%>
    <tr><td colspan="11">Aucune r&eacute;servation pour ces crit&egrave;res.</td></tr>
<%
        }
%>
</table>
<%
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
