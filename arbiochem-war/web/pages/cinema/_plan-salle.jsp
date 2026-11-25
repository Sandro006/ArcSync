<%--
    Fragment de plan de salle (inclusion statique).

    Variables attendues dans la page appelante :
      Connection c
      String  idPlanProjection
      Set<String> cinSelPlaces
      boolean cinPlanVente        (true = cases a cocher, false = lecture seule)
      String  cinPlanFieldName    (nom des cases a cocher, ex. "places")
--%>
<%
    if (c == null) {
%>
<div class="alert alert-danger">Connexion indisponible : impossible d'afficher le plan de salle.</div>
<%
    } else if (idPlanProjection == null || idPlanProjection.trim().isEmpty()) {
%>
<div class="alert alert-info">S&eacute;lectionnez une projection pour afficher le plan de salle.</div>
<%
    } else {
        PreparedStatement psPlan = null;
        ResultSet rsPlan = null;
        try {
            psPlan = c.prepareStatement(
                    "SELECT p.ID, p.RANG, p.NUMERO, cp.VAL AS CATLIB,"
                    + " NVL((SELECT MAX(pt.PRIX) FROM CINEMA_PROJECTIONTARIF pt"
                    + "        WHERE pt.IDMERE = pr.ID AND pt.IDCATEGORIEPLACE = p.IDCATEGORIEPLACE"
                    + "          AND pt.RANG = p.RANG AND pt.ETAT <> 0),"
                    + "     NVL((SELECT MAX(pt.PRIX) FROM CINEMA_PROJECTIONTARIF pt"
                    + "            WHERE pt.IDMERE = pr.ID AND pt.IDCATEGORIEPLACE = p.IDCATEGORIEPLACE"
                    + "              AND (pt.RANG = '*' OR pt.RANG IS NULL) AND pt.ETAT <> 0),"
                    + "         NVL(pr.PRIXBASE, cp.PRIXDEFAUT))) AS PRIX,"
                    + " (SELECT COUNT(*) FROM CINEMA_PLACE_OCCUPEE o"
                    + "   WHERE o.IDPROJECTION = pr.ID AND o.IDPLACE = p.ID) AS OCC"
                    + " FROM CINEMA_PLACE p"
                    + " JOIN CINEMA_PROJECTION pr ON pr.IDSALLE = p.IDMERE"
                    + " LEFT JOIN CINEMA_CATEGORIEPLACE cp ON cp.ID = p.IDCATEGORIEPLACE"
                    + " WHERE pr.ID = ? AND p.ETAT = 1"
                    + " ORDER BY p.RANG,"
                    + " TO_NUMBER(REGEXP_REPLACE(p.NUMERO, '[^0-9]', '')), p.NUMERO");
            psPlan.setString(1, idPlanProjection);
            rsPlan = psPlan.executeQuery();

            String curRang = null;
            boolean anySeat = false;

            out.print("<div class=\"cin-plan\" style=\"overflow-x:auto\">"
                    + "<table class=\"table table-bordered\" style=\"width:auto\">");
            out.print("<tr><th style=\"width:110px\">&nbsp;</th><td style=\"text-align:center\">"
                    + "<b>&Eacute;CRAN</b></td></tr>");
            while (rsPlan.next()) {
                anySeat = true;
                String pid = rsPlan.getString("ID");
                String rang = cinS(rsPlan.getString("RANG"));
                String numero = cinS(rsPlan.getString("NUMERO"));
                String catlib = cinS(rsPlan.getString("CATLIB"));
                double prix = rsPlan.getDouble("PRIX");
                boolean occ = rsPlan.getInt("OCC") > 0;
                boolean sel = cinSelPlaces != null && cinSelPlaces.contains(pid);

                if (!rang.equals(curRang)) {
                    if (curRang != null) {
                        out.print("</td></tr>");
                    }
                    out.print("<tr><th style=\"width:110px\">"
                            + (rang.trim().isEmpty() ? "&nbsp;" : "Rang " + cinH(rang))
                            + "</th><td>");
                    curRang = rang;
                }

                String titre = catlib + " - " + cinMoney(prix) + " Ar"
                        + (occ ? " - occupee" : "");
                if (cinPlanVente) {
                    out.print("<label class=\"btn btn-xs " + (occ ? "btn-default" : "btn-primary") + "\""
                            + " title=\"" + cinH(titre) + "\""
                            + " style=\"margin:2px;"
                            + (occ ? "opacity:.45;text-decoration:line-through;" : "") + "\">"
                            + "<input type=\"checkbox\" name=\"" + cinH(cinPlanFieldName) + "\""
                            + " value=\"" + cinH(pid) + "\""
                            + " data-prix=\"" + prix + "\""
                            + (occ ? " disabled" : "")
                            + (sel ? " checked" : "")
                            + " onchange=\"cinRecalc()\" style=\"margin-right:4px\">"
                            + cinH(numero) + "</label>");
                } else {
                    out.print("<span class=\"btn btn-xs " + (occ ? "btn-default" : "btn-primary") + "\""
                            + " title=\"" + cinH(titre) + "\""
                            + " style=\"margin:2px;"
                            + (occ ? "opacity:.45;text-decoration:line-through;" : "") + "\">"
                            + cinH(numero) + "</span>");
                }
            }
            if (curRang != null) {
                out.print("</td></tr>");
            }
            out.print("</table></div>");

            if (!anySeat) {
                out.print("<div class=\"alert alert-warning\">"
                        + "Aucune place active pour la salle de cette projection.</div>");
            }
%>
<div style="margin:8px 0;font-size:12px">
    <span class="btn btn-xs btn-primary">Libre</span>
    <span class="btn btn-xs btn-default" style="opacity:.45;text-decoration:line-through;">Occup&eacute;e</span>
</div>
<% if (cinPlanVente) { %>
<div style="margin:8px 0">
    Places s&eacute;lectionn&eacute;es : <b id="cinNb">0</b>
    &mdash; Total : <b id="cinTotal">0</b> Ar
</div>
<script>
    function cinRecalc() {
        var boxes = document.getElementsByName("<%=cinJs(cinPlanFieldName)%>");
        var nb = 0;
        var total = 0;
        if (boxes) {
            for (var i = 0; i < boxes.length; i++) {
                if (boxes[i].checked) {
                    nb++;
                    var p = parseFloat(boxes[i].getAttribute("data-prix"));
                    if (!isNaN(p)) {
                        total += p;
                    }
                }
            }
        }
        var nbEl = document.getElementById("cinNb");
        var totalEl = document.getElementById("cinTotal");
        if (nbEl) {
            nbEl.innerHTML = String(nb);
        }
        if (totalEl) {
            totalEl.innerHTML = total.toFixed(0);
        }
        var payeEl = document.getElementById("cinPaye");
        if (payeEl && payeEl.getAttribute("data-auto") === "1") {
            payeEl.value = total.toFixed(0);
        }
        var monnaieEl = document.getElementById("cinMonnaie");
        if (monnaieEl) {
            var paye = payeEl ? parseFloat(payeEl.value) : NaN;
            if (!isNaN(paye) && paye > total) {
                monnaieEl.innerHTML = (paye - total).toFixed(0);
            } else {
                monnaieEl.innerHTML = "0";
            }
        }
    }
    cinRecalc();
</script>
<% } %>
<%
        } catch (Exception e) {
%>
<div class="alert alert-danger">Erreur plan de salle : <%=cinH(e.getMessage())%></div>
<%
            e.printStackTrace();
        } finally {
            cinClose(rsPlan, psPlan, null);
        }
    }
%>
