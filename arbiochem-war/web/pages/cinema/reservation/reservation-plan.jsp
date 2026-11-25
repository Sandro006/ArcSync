<%@ page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ include file="../_common.jsp" %>
<%--
    Plan de salle d'une projection : places libres / occupees, selection
    multiple puis envoi vers la saisie de reservation.
--%>
<%
    request.setCharacterEncoding("UTF-8");
    String lien = (String) session.getValue("lien");
    String idProjection = cinS(request.getParameter("idProjection"));
    String message = cinS(request.getParameter("msg"));
    String erreur = null;
    String projectionLib = "";

    Connection c = null;
    PreparedStatement ps = null;
    ResultSet rs = null;

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

    int nbTotal = 0;
    int nbOccupees = 0;
    int nbDisponibles = 0;
%>
<div class="content-wrapper">
<section class="content-header">
    <h1>
        <a href="<%=lien%>?but=cinema/reservation/reservation-liste.jsp"><i class="fa fa-arrow-circle-left"></i></a>
        Plan de salle
    </h1>
</section>

<% if (!message.isEmpty()) { %><div class="col-md-12"><div class="alert alert-success"><%=cinH(message)%></div></div><% } %>
<% if (erreur != null) { %><div class="col-md-12"><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div></div><% } %>

<div class="col-md-12 cardradius">
    <form action="<%=lien%>?but=cinema/reservation/reservation-plan.jsp" method="get">
        <input type="hidden" name="but" value="cinema/reservation/reservation-plan.jsp">
        <div class="input-container">
            <div class="form-input"><label class="input-label">Projection</label>
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
                        (<%=cinH(rs.getString("IDSALLELIB"))%>)</option>
<%
        }
        cinClose(rs, ps, null); rs = null; ps = null;
    } catch (Exception e) {
        erreur = e.getMessage();
        e.printStackTrace();
    } finally {
        cinClose(rs, ps, null); rs = null; ps = null;
    }

    if (!idProjection.trim().isEmpty()) {
        try {
            ps = c.prepareStatement("SELECT IDFILMLIB, IDSALLELIB, DATY, HEUREDEBUT"
                    + " FROM CINEMA_PROJECTION_LIB WHERE ID = ?");
            ps.setString(1, idProjection);
            rs = ps.executeQuery();
            if (rs.next()) {
                projectionLib = cinH(rs.getString("IDFILMLIB")) + " ("
                        + cinH(rs.getString("IDSALLELIB")) + ") - "
                        + cinDateFmt(rs.getDate("DATY")) + " "
                        + cinS(rs.getString("HEUREDEBUT"));
            }
            cinClose(rs, ps, null); rs = null; ps = null;

            ps = c.prepareStatement(
                    "SELECT COUNT(*) FROM CINEMA_PLACE p"
                    + " JOIN CINEMA_PROJECTION pr ON pr.IDSALLE = p.IDMERE"
                    + " WHERE pr.ID = ? AND p.ETAT = 1");
            ps.setString(1, idProjection);
            rs = ps.executeQuery();
            if (rs.next()) {
                nbTotal = rs.getInt(1);
            }
            cinClose(rs, ps, null); rs = null; ps = null;

            ps = c.prepareStatement(
                    "SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE WHERE IDPROJECTION = ?");
            ps.setString(1, idProjection);
            rs = ps.executeQuery();
            if (rs.next()) {
                nbOccupees = rs.getInt(1);
            }
            cinClose(rs, ps, null); rs = null; ps = null;

            nbDisponibles = nbTotal - nbOccupees;
            if (nbDisponibles < 0) {
                nbDisponibles = 0;
            }
        } catch (Exception e) {
            erreur = e.getMessage();
            e.printStackTrace();
        } finally {
            cinClose(rs, ps, null); rs = null; ps = null;
        }
    }
%>
                </select></div>
            <div class="form-input"><label class="input-label">&nbsp;</label>
                <a class="btn btn-secondary" href="<%=lien%>?but=cinema/reservation/reservation-saisie.jsp&idProjection=<%=cinH(idProjection)%>">Cr&eacute;er une r&eacute;servation</a></div>
        </div>
    </form>
</div>

<% if (!idProjection.trim().isEmpty()) { %>
<div class="col-md-12" style="margin-top:8px">
    <b><%=projectionLib%></b> &mdash;
    <%=nbTotal%> place(s), <span style="color:#c0392b"><%=nbOccupees%> occup&eacute;e(s)</span>,
    <span style="color:#27ae60"><%=nbDisponibles%> libre(s)</span>
</div>

<form id="planForm" action="<%=lien%>" method="get">
    <input type="hidden" name="but" value="cinema/reservation/reservation-saisie.jsp">
    <input type="hidden" name="idProjection" value="<%=cinH(idProjection)%>">
    <input type="hidden" name="places" id="placesCible" value="">

    <div class="col-md-12 cardradius" style="margin-top:12px;padding:12px">
        <h4>S&eacute;lection des places</h4>
        <%
            String idPlanProjection = idProjection;
            boolean cinPlanVente = true;
            String cinPlanFieldName = "sel";
        %>
        <%@ include file="../_plan-salle.jsp" %>

        <div style="margin-top:12px">
            <button type="button" class="btn btn-primary" onclick="planGo()">
                R&eacute;server la s&eacute;lection
            </button>
            <a class="btn btn-secondary" href="<%=lien%>?but=cinema/reservation/reservation-liste.jsp">Annuler</a>
        </div>
    </div>
</form>

<script>
    function planGo() {
        var boxes = document.getElementsByName("sel");
        var ids = [];
        if (boxes) {
            for (var i = 0; i < boxes.length; i++) {
                if (boxes[i].checked) {
                    ids.push(boxes[i].value);
                }
            }
        }
        if (ids.length === 0) {
            alert("S&eacute;lectionnez au moins une place.");
            return;
        }
        document.getElementById("placesCible").value = ids.join(",");
        document.getElementById("planForm").submit();
    }
</script>
<% } %>
<%
    if (erreur != null) {
%>
<div class="col-md-12"><div class="alert alert-danger">Erreur : <%=cinH(erreur)%></div></div>
<%
    }
%>
</div>
<%
    if (c != null) {
        try { c.close(); } catch (Exception ignore) {}
    }
%>
