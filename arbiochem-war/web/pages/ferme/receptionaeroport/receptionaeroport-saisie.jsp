<%@page import="bean.CGenUtil"%>
<%@page import="affichage.PageUpdateMultiple"%>
<%@page import="ferme.receptionaeroport.*"%>
<%@page import="faturefournisseur.As_BonDeLivraison"%>
<%@page import="faturefournisseur.As_BonDeLivraison_Fille"%>
<%@page import="user.UserEJB"%>
<%@page import="affichage.PageInsertMultiple"%>
<%@page import="affichage.Liste"%>
<%@page import="bean.TypeObjet"%>
<%@page import="affichage.PageInsert"%>
<%@page import="utilitaire.Utilitaire"%>
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%@ page import="magasin.Magasin" %>
<%@ page import="java.util.Date" %>
<%@ page import="ferme.configuration.QualitePoussin" %>
<%
    try{
    UserEJB u = null;
    u = (UserEJB) session.getValue("u");
    ReceptionPoussinAeroport mere = new ReceptionPoussinAeroport();
    ReceptionPoussinAeroportDetail fille = new ReceptionPoussinAeroportDetail();
    String idLot = request.getParameter("idLot");
    String idBL = request.getParameter("idBL");
    if (idBL == null) idBL = request.getParameter("idBl");
    double qteTheorique = 0;
    As_BonDeLivraison_Fille[] blFilles = new As_BonDeLivraison_Fille[0];
    if (idBL != null && !idBL.isEmpty()) {
        blFilles = (As_BonDeLivraison_Fille[]) CGenUtil.rechercher(
            new As_BonDeLivraison_Fille(), null, null, " AND numbl='" + idBL + "'");
        for (As_BonDeLivraison_Fille b : blFilles) qteTheorique += b.getQuantite();
    }
    int nombreLigne = 10;
    PageInsertMultiple pi = new PageInsertMultiple(mere, fille, request, nombreLigne, u);
    pi.setLien((String) session.getValue("lien"));
    pi.getFormu().getChamp("idLot").setLibelle("Lot");
    pi.getFormu().getChamp("daty").setLibelle("Date");
    pi.getFormu().getChamp("heureDepart").setLibelle("Heure de d&eacute;part");
    pi.getFormu().getChamp("heureDepart").setType("time");
    pi.getFormu().getChamp("heureArrive").setLibelle("Heure d'arriv&eacute;e");
    pi.getFormu().getChamp("heureArrive").setType("time");
    pi.getFormu().getChamp("etat").setVisible(false);
    pi.getFormu().getChamp("nbrCartonMale").setLibelle("Nombre de cartons m&acirc;les");
    pi.getFormu().getChamp("nbrCartonFemelle").setLibelle("Nombre de cartons femelles");
    pi.getFormu().getChamp("qteRecus").setLibelle("Quantit&eacute; re&ccedil;ue (compt&eacute;e)");
    pi.getFormu().getChamp("idBl").setLibelle("BL fournisseur (th&eacute;orique)");
    if (idBL != null && !idBL.isEmpty()) {
        pi.getFormu().getChamp("idBl").setDefaut(idBL);
        pi.getFormu().getChamp("idBl").setAutre("readonly");
        pi.getFormu().getChamp("qteRecus").setDefaut("" + qteTheorique);
    }
    pi.getFormu().getChamp("idLot").setPageAppelComplete("ferme.lot.Lot","id","LOT");
    pi.getFormu().getChamp("idLot").setPageAppelInsert("ferme/lot/lot-saisie.jsp","id;nomlot");


    pi.getFormufle().getChamp("idSexe_0").setLibelle("Sexe");
    pi.getFormufle().getChamp("qte_0").setLibelle("Quantit&eacute;");
    affichage.Champ.setVisible(pi.getFormufle().getChampFille("id"), false);
    affichage.Champ.setVisible(pi.getFormufle().getChampFille("idMere"), false);

    affichage.Liste[] listef = new Liste[2];
    TypeObjet sexe=new TypeObjet();
    sexe.setNomTable("SEXE");
    listef[0]=new Liste("idSexe",sexe,"val","id");
    QualitePoussin qp=new QualitePoussin();
    listef[1]=new Liste("idQualitePoussin",qp,"val","id");
    pi.getFormufle().changerEnChamp(listef);
    pi.getFormufle().getChamp("idSexe_0").setLibelle("Sexe");
    pi.getFormufle().getChamp("idQualitePoussin_0").setLibelle("Qualit&eacute; poussin");

    String classeMere = "ferme.receptionaeroport.ReceptionPoussinAeroport";
    String classeFille = "ferme.receptionaeroport.ReceptionPoussinAeroportDetail";
    String butApresPost = "ferme/receptionaeroport/receptionaeroport-fiche.jsp";
    String colonneMere = "idMere";

    String[] colOrdre = {"id", "idQualitePoussin","idsexe","qte","sante"};
    pi.getFormufle().getChamp("sante_0").setLibelle("Sant&eacute; 1-10 (10=gu&eacute;ri)");
    pi.getFormufle().setColOrdre(colOrdre);


        if (idLot != null && !idLot.isEmpty()){
        pi.getFormu().getChamp("idLot").setDefaut(idLot);
        pi.getFormu().getChamp("idLot").setAutre("readonly");
    }
    // Preremplir les lignes avec les qtes theoriques du BL (l'agent corrige au comptage reel)
    for (int bi = 0; bi < blFilles.length && bi < nombreLigne; bi++) {
        pi.getFormufle().getChamp("qte_" + bi).setDefaut("" + blFilles[bi].getQuantite());
    }
    if (qteTheorique > 0) { %>
    <div class="alert alert-info">BL <b><%= idBL %></b> : quantit&eacute; th&eacute;orique <b><%= qteTheorique %></b> — corrigez avec le comptage r&eacute;el, l'&eacute;cart se calculera en fiche.</div>
    <% }
    pi.preparerDataFormu();
    pi.getFormu().makeHtmlInsertTabIndex();
    pi.getFormufle().makeHtmlInsertTableauIndex();

%>
<div class="content-wrapper">
    <!-- A modifier -->
    <%
        if (request.getParameter("acte")!=null && request.getParameter("acte")!=""){
            out.println("<h1>Modification du reception de poussin &agrave; l'aeroport</h1>");
        }else{
            out.println("<h1>Saisie d'un reception de poussin &agrave; l'aeroport</h1>");
        }
    %>
    <form id="formId" class='container' action="<%=pi.getLien()%>?but=apresMultiple.jsp" method="post" >
        <%
            out.println(pi.getFormu().getHtmlInsert());
        %>
        <div id="butfillejsp">
            <%
                out.println(pi.getFormufle().getHtmlTableauInsert());
            %>
        </div>
        <input name="acte" type="hidden" id="nature" value="insert">
        <input name="bute" type="hidden" id="bute" value="<%= butApresPost %>">
        <input name="classe" type="hidden" id="classe" value="<%= classeMere %>">
        <input name="classefille" type="hidden" id="classefille" value="<%= classeFille %>">
        <input name="nombreLigne" type="hidden" id="nombreLigne" value="<%= nombreLigne %>">
        <input name="colonneMere" type="hidden" id="colonneMere" value="<%= colonneMere %>">
    </form>
</div>
<%
	} catch (Exception e) {
		e.printStackTrace();
%>
    <script language="JavaScript">
        alert('<%=e.getMessage()%>');
        history.back();
    </script>
<% }%>
