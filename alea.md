# Gestion des remises — Module Cinéma

> Document de conception de la **gestion des remises** appliquées aux
> réservations.
>
> Règle d'origine (à conserver comme référence métier) :
>
> > Si une réservation contient un nombre de places **supérieur ou égal** au
> > `Nombre_place` de la `Categorie_Reservation`, alors on applique une remise
> > de valeur `Valeur` sur les places de la `Categorie_Remise`, dans la limite
> > de `Nombre_place_remiser` places.

### Décisions retenues

| Sujet | Décision |
| --- | --- |
| Portée | Règle **globale** (toutes les projections) |
| Valeur | **Pourcentage ou montant fixe** (`TYPEVALEUR`) |
| Seuil / places remisées | `NOMBREPLACE` = seuil, `NOMBREPLACEREMISE` = places remisées |
| Cumul | **Une seule** règle par réservation |
| Catégories | `Categorie_Reservation` **≠** `Categorie_Remise` |
| Choix des places | Les **plus chères** d'abord |
| Vente directe | **Non** — uniquement les réservations |
| Historisation | **Oui** (`IDREMISE` + `MONTANTREMISE`) |
| Promotion 20 h | **Supprimée purement et simplement** (non remplacée) |

---

## 1. Objectif

Permettre à un administrateur de **configurer des règles de remise** sans
modifier le code, puis de les appliquer automatiquement au moment de la
**création d'une réservation** (`ReservationService.reserver`).

Exemples de règles visées :

| Règle | Catégorie déclencheuse | Seuil | Effet |
| --- | --- | --- | --- |
| « Famille » | Adulte | 3 | 1 place Enfant à −100 % |
| « Groupe » | Adulte | 5 | 2 places Enfant à −50 % |
| « Soirée » | Standard | 2 | 1 place VIP à −2 000 Ar |

> La catégorie déclencheuse et la catégorie remisée étant **obligatoirement
> différentes**, les promotions « 3 achetées = 1 offerte » sur la *même*
> catégorie ne sont pas exprimables telles quelles. Voir §9.

---

## 2. Règle de gestion

### 2.1 Formulation

Soit une réservation `R` rattachée à une projection `P`, et ses lignes actives
(`CINEMA_RESERVATIONDETAIL`, `ETAT IN (1, 11)`).

```
pour chaque règle de remise active :
    N = nombre de places de R dont la catégorie = Categorie_Reservation
    si N >= Nombre_place :
        la règle est éligible
```

Une règle éligible remise **au plus** `Nombre_place_remiser` places de la
catégorie `Categorie_Remise` présentes dans la réservation. Si la réservation
contient moins de places de cette catégorie, on remise toutes celles présentes
(plafonnement automatique).

### 2.2 Portée : règle globale

Les règles sont **globales** : elles s'appliquent à **toutes les projections**.
Il n'y a donc pas de colonne `IDPROJECTION`.

Une réservation étant rattachée à **une seule** projection
(`CINEMA_RESERVATION.IDPROJECTION`), la règle est évaluée **par réservation**,
donc de fait séance par séance — sans configuration par séance.

### 2.3 Valeur de la remise

`VALEUR` est interprétée selon `TYPEVALEUR` :

| `TYPEVALEUR` | Libellé | Interprétation de `VALEUR` |
| --- | --- | --- |
| `0` | Pourcentage | `VALEUR` ∈ ]0 ; 100], appliqué au prix de la place |
| `1` | Montant fixe | `VALEUR` en Ariary, déduit du prix de la place |

Montant remisé par place :

```
si TYPEVALEUR = 0 :  remise = prix * VALEUR / 100
si TYPEVALEUR = 1 :  remise = VALEUR
remise = min(remise, prix)          -- le prix payé ne peut pas être négatif
prixPaye = prix - remise
```

`VALEUR` est un **prix unitaire** : la remise porte sur chaque place remisée,
pas sur le total de la réservation.

### 2.4 Une seule règle par réservation

Même si plusieurs règles sont éligibles, **une seule** est appliquée, donc
**aucun cumul** et **aucune place remisée deux fois**.

Règle retenue : celle qui procure le **montant total de remise le plus
élevé** pour le client. À égalité : seuil `NOMBREPLACE` le plus élevé, puis
`ID` croissant (ordre stable).

```
pour chaque règle éligible :
    simuler la remise sur les places les plus chères de la catégorie remisée
    retenir la règle dont le montant total remisé est maximal
appliquer uniquement cette règle
```

Une règle ne s'applique **qu'une seule fois** par réservation : pas de
répétition par tranche de `Nombre_place` (ex. 6 places ne déclenchent pas
deux fois une règle « 3 → 1 »).

### 2.5 Choix des places remisées

Le prix d'une place dépend de sa catégorie **et de son rang** dans la salle
(`CINEMA_PROJECTIONTARIF`). À l'intérieur d'une même catégorie remisée, les
places peuvent donc avoir des prix différents.

Ordre de sélection : **prix le plus élevé d'abord** (avantage maximal pour le
client, comportement attendu au guichet).

### 2.6 Catégories différentes

Contrainte métier : `IDCATEGORIERESERVATION <> IDCATEGORIEREMISE`.

Cette contrainte est portée à la fois :

* par un `CHECK` en base (voir §3.1) ;
* par une validation applicative dans `Remise.controlerSaisie()` (message clair à
  la saisie).

---

## 3. Modèle de données

### 3.1 Table `CINEMA_REMISE`

Correspondance avec la note d'origine :

| Note | Colonne | Type | Commentaire |
| --- | --- | --- | --- |
| `id` | `ID` | `VARCHAR2(100)` PK | Préfixe `CRM` + séquence |
| `Categorie_Reservation (Place)` | `IDCATEGORIERESERVATION` | `VARCHAR2(100)` NOT NULL | FK `CINEMA_CATEGORIEPLACE` |
| `Nombre_place` | `NOMBREPLACE` | `NUMBER(6)` NOT NULL | Seuil déclencheur (≥ 1) |
| `Valeur(remise)` | `TYPEVALEUR` + `VALEUR` | `NUMBER(1)` + `NUMBER` | 0 = %, 1 = montant |
| `Categorie_Remise (Place)` | `IDCATEGORIEREMISE` | `VARCHAR2(100)` NOT NULL | FK `CINEMA_CATEGORIEPLACE` |
| `Nombre_place_remiser` | `NOMBREPLACEREMISE` | `NUMBER(6)` NOT NULL | Places effectivement remisées (≥ 1) |
| — | `DESCE` | `VARCHAR2(500)` | Libellé / motif affiché |
| — | `ETAT` | `NUMBER(22) DEFAULT 1` | État standard du framework |

DDL idempotent (même style que les autres scripts `cinema-*.sql`) :

```sql
DECLARE
    v_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tables
     WHERE table_name = 'CINEMA_REMISE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE '
            CREATE TABLE CINEMA_REMISE (
                ID                      VARCHAR2(100) NOT NULL,
                IDCATEGORIERESERVATION  VARCHAR2(100) NOT NULL,
                NOMBREPLACE             NUMBER(6) NOT NULL,
                TYPEVALEUR              NUMBER(1) DEFAULT 0 NOT NULL,
                VALEUR                  NUMBER DEFAULT 0 NOT NULL,
                IDCATEGORIEREMISE       VARCHAR2(100) NOT NULL,
                NOMBREPLACEREMISE       NUMBER(6) NOT NULL,
                DESCE                   VARCHAR2(500),
                ETAT                    NUMBER(22) DEFAULT 1,
                CONSTRAINT PK_CINEMA_REMISE PRIMARY KEY (ID),
                CONSTRAINT CK_CINEMA_REMISE_TYPE CHECK (TYPEVALEUR IN (0, 1)),
                CONSTRAINT CK_CINEMA_REMISE_SEUIL CHECK (NOMBREPLACE >= 1),
                CONSTRAINT CK_CINEMA_REMISE_NBREM CHECK (NOMBREPLACEREMISE >= 1),
                CONSTRAINT CK_CINEMA_REMISE_VALEUR CHECK (VALEUR >= 0),
                CONSTRAINT CK_CINEMA_REMISE_CAT CHECK
                    (IDCATEGORIERESERVATION <> IDCATEGORIEREMISE),
                CONSTRAINT FK_CINEMA_REMISE_CATRES FOREIGN KEY (IDCATEGORIERESERVATION)
                    REFERENCES CINEMA_CATEGORIEPLACE (ID),
                CONSTRAINT FK_CINEMA_REMISE_CATREM FOREIGN KEY (IDCATEGORIEREMISE)
                    REFERENCES CINEMA_CATEGORIEPLACE (ID)
            )';
    END IF;
END;
/

CREATE INDEX IDX_CINEMA_REMISE_CAT
    ON CINEMA_REMISE (IDCATEGORIERESERVATION, ETAT);
```

Validations applicatives complémentaires (dans `Remise.controlerSaisie()`) :

* `TYPEVALEUR = 0` ⇒ `0 < VALEUR <= 100` ;
* `NOMBREPLACE >= 1` et `NOMBREPLACEREMISE >= 1` ;
* catégories existantes, actives et **différentes**.

### 3.2 Traçabilité

Pour figer la remise réellement accordée (audit, annulation, statistiques),
ajouter deux colonnes à `CINEMA_RESERVATIONDETAIL` :

| Colonne | Type | Rôle |
| --- | --- | --- |
| `IDREMISE` | `VARCHAR2(100)` | Règle appliquée (`NULL` si aucune) |
| `MONTANTREMISE` | `NUMBER DEFAULT 0` | Montant unitaire remisé sur la ligne |

Et un total au niveau en-tête de la réservation :

| Table | Colonne | Rôle |
| --- | --- | --- |
| `CINEMA_RESERVATION` | `MONTANTREMISE` | Somme des remises de la réservation |

*(La vente directe n'appliquant pas de remise, aucune colonne n'est ajoutée à
`CINEMA_ACHATBILLET`.)*

```sql
DECLARE v_exists NUMBER; BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tab_columns
     WHERE table_name = 'CINEMA_RESERVATIONDETAIL' AND column_name = 'IDREMISE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE CINEMA_RESERVATIONDETAIL ADD (IDREMISE VARCHAR2(100))';
    END IF;
END;
/

DECLARE v_exists NUMBER; BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tab_columns
     WHERE table_name = 'CINEMA_RESERVATIONDETAIL' AND column_name = 'MONTANTREMISE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE CINEMA_RESERVATIONDETAIL ADD (MONTANTREMISE NUMBER DEFAULT 0)';
    END IF;
END;
/

DECLARE v_exists NUMBER; BEGIN
    SELECT COUNT(*) INTO v_exists FROM user_tab_columns
     WHERE table_name = 'CINEMA_RESERVATION' AND column_name = 'MONTANTREMISE';
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE 'ALTER TABLE CINEMA_RESERVATION ADD (MONTANTREMISE NUMBER DEFAULT 0)';
    END IF;
END;
/
```

---

## 4. Algorithme

### 4.1 Pseudo-code

```
Entrées : idReservation, lignes[] (place, catégorie, prix)
Sortie  : pour chaque ligne : montantRemise, idRemise

1. Charger les règles actives : ETAT = 1
2. Pour chaque règle :
     N = nb de lignes actives de catégorie IDCATEGORIERESERVATION
     si N < NOMBREPLACE : règle non éligible
     sinon :
         candidates = lignes de catégorie IDCATEGORIEREMISE,
                      triées par prix décroissant
         nb = min(NOMBREPLACEREMISE, taille(candidates))
         total = somme des remises calculées sur les nb premières candidates
3. Retenir la règle éligible dont `total` est maximal
   (égalité : NOMBREPLACE desc, puis ID)
4. Appliquer cette règle uniquement :
     pour les nb candidates retenues :
         ligne.montantRemise = calculerRemise(prix, TYPEVALEUR, VALEUR)
         ligne.idRemise      = regle.ID
5. prixPaye = prix - montantRemise pour chaque ligne.
```

### 4.2 Comptage du déclencheur

```sql
SELECT COUNT(*)
  FROM CINEMA_RESERVATIONDETAIL
 WHERE IDMERE = :idReservation
   AND ETAT IN (1, 11)
   AND IDCATEGORIEPLACE = :idCategorieReservation
```

> Le comptage inclut **toutes** les places de la catégorie déclencheuse.
> Comme la catégorie remisée est toujours différente, aucun chevauchement
> n'est possible.

### 4.3 Exemples chiffrés

**Exemple 1 — Famille**

* Règle : Adulte / seuil 3 / 100 % / Enfant / 1 place.
* Réservation : 3 Adultes (15 000 Ar) + 1 Enfant (8 000 Ar).
* Résultat : 3 × 15 000 + 1 × 0 = **45 000 Ar** (remise 8 000 Ar).

**Exemple 2 — Non éligible**

* Même règle, réservation : 2 Adultes + 1 Enfant.
* Résultat : `2 < 3` ⇒ aucune remise.

**Exemple 3 — Plafonnement**

* Règle : Standard / seuil 2 / −50 % / VIP / 3 places.
* Réservation : 2 Standard + 1 VIP à 20 000 Ar.
* Résultat : la règle est éligible mais une seule place VIP existe ⇒
  1 place VIP à 10 000 Ar (remise 10 000 Ar), pas 3.

**Exemple 4 — Deux règles éligibles, une seule appliquée**

* Règle A : Adulte / seuil 2 / 20 % / Enfant / 1 place → remise 1 600 Ar
  sur un Enfant à 8 000 Ar.
* Règle B : Adulte / seuil 3 / 100 % / Enfant / 1 place → remise 8 000 Ar.
* Réservation : 3 Adultes + 1 Enfant.
* Résultat : les deux règles sont éligibles, on retient **B** (plus
  avantageuse) : Enfant offert.

**Exemple 5 — Montant fixe supérieur au prix**

* Règle : Standard / seuil 1 / 5 000 Ar / Enfant / 1 place.
* Enfant à 3 000 Ar ⇒ remise plafonnée à 3 000 Ar, prix payé = 0.

---

## 5. Interface de configuration

### 5.1 Menu

Ajouter une entrée de niveau 2 sous le menu **Cinéma** :

```sql
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
SELECT 'MENDYN1792000000000011', 'Remises', 'percent',
       'module.jsp?but=cinema/configuration/remise-liste.jsp', 9, 2,
       'MENDYN1792000000000001'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM MENUDYNAMIQUE WHERE ID = 'MENDYN1792000000000011');
```

Ajouter aussi la ligne `USERMENU` correspondante (sinon le menu reste
invisible, cf. commentaire du script `2026-11-12-10_10-cinema-menus.sql`).

### 5.2 Pages JSP

Conventions du module : `*-liste.jsp`, `*-saisie.jsp`, `*-fiche.jsp`.

| Page | Contenu |
| --- | --- |
| `cinema/configuration/remise-liste.jsp` | Liste des règles : catégorie déclencheuse, seuil, effet, catégorie remisée, places remisées, état, actions Modifier / Annuler |
| `cinema/configuration/remise-saisie.jsp` | Formulaire de création / modification |
| `cinema/configuration/remise-fiche.jsp` | (optionnel) consultation en lecture seule |

Champs du formulaire :

| Champ | Contrôle |
| --- | --- |
| Catégorie de réservation | Liste `CINEMA_CATEGORIEPLACE` actives |
| Nombre de places (seuil) | Entier ≥ 1 |
| Type de valeur | Pourcentage / Montant fixe |
| Valeur | % : 0 < valeur ≤ 100 ; montant : ≥ 0 |
| Catégorie remisée | Liste `CINEMA_CATEGORIEPLACE` actives, **différente** de la catégorie de réservation |
| Nombre de places remisées | Entier ≥ 1 |
| Description | Texte libre (motif affiché au guichet) |
| État | Actif / Inactif |

### 5.3 Affichage au guichet

* `reservation-fiche.jsp` : afficher, pour chaque ligne remisée, le prix
  initial barré et le prix payé, plus la ligne
  « Remise — <description> : −X Ar ».
* Pied de la fiche : `Total`, `Remise`, `Net à payer`.

---

## 6. Intégration au code existant

| Élément | Fichier | Nature |
| --- | --- | --- |
| `cinema.configuration.Remise` | `arbiochem-ejb/.../cinema/configuration/Remise.java` | `extends ClassMAPTable` ; PK `CRM` via `GETSEQCINEMAREMISE` |
| `cinema.configuration.RemiseLib` | idem | Vue `CINEMA_REMISE_LIB` + libellés catégories |
| `cinema.reservation.RemiseService` | `.../cinema/reservation/RemiseService.java` | `appliquer(ReservationDetail[] lignes, Connection c)` — cœur du calcul |
| `ReservationService.reserver` | `.../cinema/reservation/ReservationService.java` | Appeler `RemiseService` après le calcul des prix, avant `createObject` |

Points d'attention :

1. **Vente directe exclue** : `AchatBilletService.acheter` n'applique aucune
   remise. Une réservation convertie en billets conserve simplement le prix
   remisé déjà figé (`ReservationService.convertirEnBillet`).
2. **Promotion 20 h supprimée** : le bloc codé en dur dans
   `ReservationService.reserver` (et son bug `lp.idPlace` hors boucle) est
   retiré. Toute remise passe désormais par `CINEMA_REMISE`. Voir §9 pour la
   limite de cette substitution.
3. La remise doit être calculée **une seule fois**, au moment de la création
   de la réservation, puis **figée** dans `CINEMA_RESERVATIONDETAIL`
   (`MONTANTREMISE`, `IDREMISE`). Ne jamais recalculer à l'affichage ni à la
   conversion en billet.
4. `ProjectionService.getPrixPlace` dépend du **rang** : deux places de même
   catégorie peuvent avoir des prix différents (cf. §2.5).

---

## 7. Script de migration

Nom proposé, conforme à la convention `AAAA-MM-JJ-HH_MM-*.sql` :

```
2026-11-19-09_00-cinema-remise.sql
```

Contenu, dans l'ordre :

1. `CREATE TABLE CINEMA_REMISE` (+ index) ;
2. `ALTER TABLE CINEMA_RESERVATIONDETAIL` (`IDREMISE`, `MONTANTREMISE`) ;
3. `ALTER TABLE CINEMA_RESERVATION` (`MONTANTREMISE`) ;
4. création de la séquence `GETSEQCINEMAREMISE` ;
5. vue `CINEMA_REMISE_LIB` ;
6. menus + droits `USERMENU` ;
7. `COMMIT`.

Le script doit rester **idempotent** (test d'existence avant chaque
création), comme `2026-11-12-09_*.sql`.

---

## 8. Recette

| # | Scénario | Attendu |
| --- | --- | --- |
| 1 | Règle 3 Adulte → 1 Enfant −100 %, réservation 3 Adultes + 1 Enfant | Enfant offert |
| 2 | Même règle, réservation 2 Adultes + 1 Enfant | Aucune remise |
| 3 | Règle 2 Standard → 3 VIP −50 %, réservation 2 Standard + 1 VIP | 1 VIP remisée, plafonnée |
| 4 | Deux règles éligibles | Une seule appliquée : la plus avantageuse |
| 5 | Saisie d'une règle avec catégorie déclencheuse = catégorie remisée | Refusée (message + contrainte) |
| 6 | Règle inactive (`ETAT = 0`) | Ignorée |
| 7 | Montant fixe supérieur au prix de la place | Prix payé = 0, jamais négatif |
| 8 | Vente directe sans réservation | Aucune remise |
| 9 | Réservation convertie en billets | Le prix remisé figé est conservé |
| 10 | Réservation annulée puis recréée | Remise recalculée à la création |
| 11 | Plusieurs places de la catégorie remisée à des prix différents | Les plus chères sont remisées |
| 12 | Séance à 20 h ou plus | Plus de remise automatique de 50 % |

---

## 9. Décisions validées et limite connue

Décisions confirmées avec le métier :

1. **Même catégorie interdite** : `Categorie_Reservation` doit être
   différente de `Categorie_Remise`. La contrainte est conservée.
2. **Une seule application** par réservation, même si le seuil est atteint
   plusieurs fois.
3. **Promotion 20 h supprimée purement et simplement** : le code en dur est
   retiré de `ReservationService` et n'est **pas** remplacé. Toute remise
   passe par les règles configurées ; les séances de 20 h ou plus ne
   bénéficient plus d'aucune réduction automatique.

**Conséquence assumée** : la contrainte « catégories différentes » rend de
toute façon impossible l'expression d'une règle « −50 % sur toutes les places
à partir de 20 h ». Ce comportement disparaît donc du module ; s'il devait
revenir un jour, il faudrait passer par le prix de base de la projection ou
faire évoluer le modèle.

---

## 10. État d'implémentation

| Élément | Fichier |
| --- | --- |
| Migration (table, colonnes, séquence, vue, menu, droits) | `2026-11-19-09_00-cinema-remise.sql` |
| Entité règle de remise | `arbiochem-ejb/src/java/cinema/configuration/Remise.java` |
| Vue d'affichage | `arbiochem-ejb/src/java/cinema/configuration/RemiseLib.java` |
| Calcul et application | `arbiochem-ejb/src/java/cinema/reservation/RemiseService.java` |
| Branchement réservation | `cinema/reservation/ReservationService.java` (`reserver`, `convertirEnBillet`) |
| Traçabilité ligne / en-tête | `cinema/reservation/ReservationDetail.java`, `cinema/reservation/Reservation.java` |
| Prix figé à la conversion | `cinema/billet/AchatBilletService.java`, `cinema/billet/AchatBillet.java` (`prixFige`) |
| Liste des règles | `arbiochem-war/web/pages/cinema/configuration/remise-liste.jsp` |
| Saisie / modification | `arbiochem-war/web/pages/cinema/configuration/remise-saisie.jsp` |
| Affichage guichet | `arbiochem-war/web/pages/cinema/reservation/reservation-fiche.jsp` |

Points d'implémentation notables :

1. `RemiseService.appliquer(...)` est appelé **avant** `createObject` : le prix
   net calculé est ensuite figé par la persistance (`PRIX`, `MONTANTREMISE`,
   `IDREMISE`).
2. `Reservation.controlerPlaces` ne réécrit plus le prix d'une ligne déjà
   remisée : une place offerte (`prix = 0`, `IDREMISE` renseigné) est
   conservée telle quelle.
3. À la conversion en billets, le prix de la réservation est marqué **figé**
   (`prixFige`) pour que `AchatBilletService` ne le recalcule pas : sans cela,
   une place à −100 % serait facturée au tarif plein.
4. La promotion 20 h a bien été retirée de `ReservationService` (bloc et
   méthode `PromotionaPartir20h`).
