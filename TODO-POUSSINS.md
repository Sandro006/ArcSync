# TODO Poussins — Arrivage → Compartiments

Contexte : `TODO.md` + réponses validées :

- Race = **Souche existante** (`ferme/configuration/souche`)
- Théorique 1 = **Qté BL fille**
- Santé = **nouveau champ 1-10 (10=guéri)** pour morts/malades
- Compartiment = **Parquet existant** (`BatimentDetail.idParquet`)

## 1. BC fournisseur poussin [HIGH]

- [ ]  Formulaire `pages/bondecommande/bondecommande-saisie.jsp` : ajouter `idSouche` (liste souche), `qte`, infos diverses
- [ ]  EJB `faturefournisseur/As_BonDeCommande.java` + `As_BonDeCommande_Fille.java` (produit poussin + souche)
- [ ]  SQL `AAAA-MM-JJ-HH_MM-bc-souche.sql` (colonne `idsouche` / liaison lot)

- Fait si : BC avec souche + qté visible en `bondecommande-liste/fiche`.

## 2. Livraisons avion en N fois [HIGH]

- [ ]  Réutiliser `As_BonDeCommande.genererLivraisonPourPrerempli()` + vue `as_bondecommande_livre`
- [ ]  JSP `bondelivraison-saisie.jsp` pré-remplie depuis `idbc`, N BL partiels autorisés

- Fait si : 1 BC → N BL, reste à 0 au dernier.

## 3. Réception aéroport : réel vs théorique 1 [HIGH]

- [ ]  `ferme.receptionaeroport.ReceptionPoussinAeroport(+Detail)` + `receptionaeroport-saisie.jsp`
- [ ]  Saisir `qteRecus, nbrCartonMale/Femelle` par arrivée, lié `idLot + idBL`
- [ ]  Écart `théorique (Qté BL fille) − réel (Σ qte détail)` en fiche/liste (garder `checkQteFille()`)

- Fait si : chaque arrivée affiche `théorique / réel / écart`.

## 4. Champ santé 1-10 (10=guéri) [HIGH]

- [ ]  Nouveau champ `sante` NUMBER 1-10 sur `ReceptionPoussinAeroportDetail` + `TriageQualitePoussinDetail`
- [ ]  MAJ `*_Lib`, vues, JSP saisie (select 1-10)
- [ ]  SQL migration dédiée

- Fait si : morts/malades/guéris saisissables par ligne d'arrivée.

## 5. BL voyage vers bâtiments [MED]

- [ ]  `ferme.transfertpoulet.TransfertPoulet(+Detail)` : `Ferme/Batiment/Parquet départ → arrivée + qte + sexe + controleur/chauffeur/vehicule`

- Fait si : 1 transfert créé depuis 1 réception, traçable par `idLot`.

## 6. Arrivée bâtiment : séparation sexe/parquet [MED]

- [ ]  `transfertpoulet-saisie.jsp` / `triagebatimentparquet-saisie.jsp` : `idParquet + qte + idSexe + nb malades (sante<10)`
- [ ]  Garder contrôle capacité `Batiment.checkValeurEntierFille()`

- Fait si : mâles/femelles dans parquets distincts, malades comptés.

## 7. Totalisation théorique 2 → actuels [MED]

- [ ]  Vue/calcul `théorique 2 (Σ avant voyage) vs Σ parquets + morts/malades`
- [ ]  Réactiver contrôle `TriageBatimentParquet.createObject` (somme détails = dispo)

- Fait si : fiche lot affiche `théorique2 / actuels / morts / malades`.

## 8. Migration + recette [LOW]

- [ ]  1 SQL par étape au format hook `AAAA-MM-JJ-HH_MM-*.sql` (`control/pre-commit`)
- [ ]  Recette `admin/admin123` sur `http://localhost:8080/arbiochem/` (base `itu`, `societe` non vide)

Ordre conseillé : 1 → 2 → 3 → 4, puis 5 → 6 → 7.
