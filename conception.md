# Conception — Module Cinéma

> Document de conception fonctionnelle et technique du module **Cinéma** :  
> achat de droits de diffusion, préparation des projections, réservation de places  
> et achat de billets.
> 
> Ce document suit les conventions du projet (`ClassMere`, `ClassFille`,  
> `TypeObjet`, `ETAT`, PK `préfixe + séquence`, vues `*_LIB`, JSP `*-saisie`,  
> `*-liste`, `*-fiche`, SQL `AAAA-MM-JJ-HH_MM-*.sql`).

---

## Sommaire

1.  [Objectif et périmètre](#1-objectif-et-p%C3%A9rim%C3%A8tre)
2.  [Conventions reprises du projet](#2-conventions-reprises-du-projet)
3.  [Acteurs et cas d'utilisation](#3-acteurs-et-cas-dutilisation)
4.  [Processus métier](#4-processus-m%C3%A9tier)
5.  [Modèle de données](#5-mod%C3%A8le-de-donn%C3%A9es)
6.  [Modèle objet Java](#6-mod%C3%A8le-objet-java)
7.  [Couche service](#7-couche-service)
8.  [Pages JSP et menus](#8-pages-jsp-et-menus)
9.  [Fichiers SQL de migration](#9-fichiers-sql-de-migration)
10.  [Règles de gestion](#10-r%C3%A8gles-de-gestion)
11.  [Intégration avec les modules existants](#11-int%C3%A9gration-avec-les-modules-existants)
12.  [Recette](#12-recette)
13.  [Ordre de mise en œuvre](#13-ordre-de-mise-en-%C5%93uvre)

---

## 1\. Objectif et périmètre

Le module **Cinéma** couvre quatre processus principaux :

| Processus | Objet métier | Résultat attendu |
| --- | --- | --- |
| Achat de droit de diffusion | `AchatDroitDiffusion` + détails | Un film est autorisé à être projeté sur une période et un territoire donnés. |
| Préparation d'une projection | `Projection` + `ProjectionTarif` | Une séance est planifiée dans une salle, avec ses tarifs et ses places. |
| Réservation | `Reservation` + `ReservationDetail` | Des places sont bloquées pour un client pendant un délai limité. |
| Achat de billet | `AchatBillet` + `Billet` | Les places sont payées, les billets sont émis et contrôlables à l'entrée. |

**Hors périmètre initial** : gestion des abonnements, fidélité, programmes  
multi-salles centralisés, diffusion numérique (DCP), comptabilité analytique  
détaillée. Ces points pourront être ajoutés sans modifier le modèle de base.

**Hypothèses** :

*   La base est Oracle (même si le framework supporte PostgreSQL).
*   Les clients, devises, modes de paiement, caisses et utilisateurs existent déjà  
    (`CLIENT`, `DEVISE`, `MODEPAIEMENT`, `CAISSE`, `UTILISATEUR`).
*   Le module peut être utilisé sans facturation `VENTE` dans un premier temps ;  
    le raccordement comptable est prévu mais optionnel.
*   Les identifiants sont des `VARCHAR2(100)` générés par `makePK`.
*   Les dates métier sont des `java.sql.Date` ; les heures sont des `String`  
    au format `HH:mm`, conformément aux objets existants du projet.

---

## 2\. Conventions reprises du projet

### 2.1 Héritage des objets

| Classe de base | Usage | Exemple dans le projet |
| --- | --- | --- |
| `bean.TypeObjet` | Référentiel simple (`ID`, `VAL`, `DESCE`) | `ferme.configuration.Souche` |
| `bean.ClassMAPTable` | Objet autonome sans fille | `produits.Ingredients` |
| `bean.ClassMere` | Objet principal avec lignes de détail | `ferme.receptionaeroport.ReceptionPoussinAeroport` |
| `bean.ClassFille` | Ligne de détail d'un objet mère | `ferme.receptionaeroport.ReceptionPoussinAeroportDetail` |

`ClassMere` et `ClassFille` héritent de `ClassEtat`, donc les objets disposent  
déjà de `getEtat()`, `setEtat(int)`, `validerObject`, `annulerObject`,  
`cloturerObject`, `updateEtat`.

### 2.2 Contrat commun des objets

Tout objet `ClassMAPTable` expose ou hérite des signatures suivantes :

```java
public String getId();
public void setId(String id);
public String getNomTable();
public void setNomTable(String nomTable);
public String getTuppleID();
public String getAttributIDName();
public void construirePK(Connection c) throws Exception;
public ClassMAPTable createObject(String u, Connection c) throws Exception;
public int updateObject(String u, Connection c) throws Exception;
public ClassMAPTable getById(String id, String nomTable, Connection c) throws Exception;
public int deleteToTable(Connection c) throws Exception;
public int updateEtat(String u, Connection c, int etat) throws Exception;
public Object validerObject(String u, Connection c) throws Exception;
public Object annulerObject(String u, Connection c) throws Exception;
public Object cloturerObject(String u, Connection c) throws Exception;
```

Tout objet `ClassMere` ajoute :

```java
public String getNomClasseFille();
public void setNomClasseFille(String nomClasseFille) throws Exception;
public String getLiaisonFille();
public void setLiaisonFille(String liaisonFille);
public ClassFille[] getFille();
public void setFille(ClassFille[] filles) throws Exception;
public void setFille(java.util.List<ClassFille> filles) throws Exception;
public void ajouterFille(ClassFille fille) throws Exception;
public void createObjectFille(String u, Connection c) throws Exception;
public void validerObjectFille(String u, Connection c) throws Exception;
```

Tout objet `ClassFille` ajoute :

```java
public String getNomClasseMere();
public void setNomClasseMere(String nomClasseMere) throws Exception;
public String getLiaisonMere();
public void setLiaisonMere(String liaisonMere);
public ClassMere getMere();
public ClassMere findMere(String u, Connection c) throws Exception;
```

### 2.3 Clé primaire

Chaque objet implémente :

```java
@Override
public void construirePK(Connection c) throws Exception {
    this.preparePk("<PREFIXE>", "GETSEQ<OBJET>");
    this.setId(this.makePK(c));
}
```

`makePK` appelle `Utilitaire.getMaxSeq("GETSEQ<OBJET>", c)`, qui exécute  
`SELECT GETSEQ<OBJET> FROM DUAL`. Il faut donc créer, pour chaque objet :

1.  une séquence `SEQ_CINEMA_<OBJET>` ;
2.  une fonction `GETSEQ<OBJET>` qui retourne `SEQ_CINEMA_<OBJET>.NEXTVAL`.

### 2.4 États

Les valeurs standard du framework sont conservées :

| Constante | Valeur | Signification |
| --- | --- | --- |
| `ETAT_ANNULE` | 0 | Annulé |
| `ETAT_CREER` | 1 | Créé / brouillon |
| `ETAT_CLOTURE` | 9 | Clôturé |
| `ETAT_REJETE` | 10 | Rejeté |
| `ETAT_VALIDER` | 11 | Validé / actif |

Pour les statuts métier plus fins (réservation en attente, confirmée, etc.),  
on ajoute une colonne `STATUT` et des constantes dans  
`cinema.utils.ConstanteCinema`. Cela évite de détourner `ETAT` et permet de  
conserver les boutons standards « Valider », « Annuler », « Clôturer ».

### 2.5 Nommage

| Élément | Convention |
| --- | --- |
| Package | `cinema.<domaine>` |
| Table | `CINEMA_<OBJET>` en majuscules |
| Vue | `CINEMA_<OBJET>_LIB` |
| Objet Java | `PascalCase`, même nom que la table sans le préfixe |
| Objet fille | `<Mere>Detail` |
| Objet libellé | `<Objet>Lib` |
| JSP | `cinema/<domaine>/<objet>-saisie.jsp`, `-liste.jsp`, `-fiche.jsp` |
| SQL | `AAAA-MM-JJ-HH_MM-cinema-<sujet>.sql` |

### 2.6 Vues `*_LIB`

Une vue `*_LIB` doit exposer **toutes les colonnes de la table de base**  
(par exemple `p.*`) **plus** les colonnes libellées attendues par la classe  
`*Lib`. Sinon le mapping automatique du framework ne retrouve pas les champs.

---

## 3\. Acteurs et cas d'utilisation

| Acteur | Rôle | Cas d'utilisation |
| --- | --- | --- |
| Administrateur cinéma | `CINEMA_ADMIN` | Configurer genres, distributeurs, salles, places, catégories. |
| Programmateur | `CINEMA_PROGRAMMATEUR` | Acheter les droits, créer les films, préparer les projections. |
| Caissier | `CINEMA_CAISSIER` | Prendre les réservations, vendre les billets, encaisser. |
| Contrôleur | `CINEMA_CONTROLEUR` | Scanner / saisir un billet à l'entrée. |
| Responsable financier | `CINEMA_DAF` | Valider les achats de droits, consulter les recettes. |

**Cas d'utilisation principaux** :

1.  `UC-01` — Acheter un droit de diffusion pour un ou plusieurs films.
2.  `UC-02` — Consulter les droits actifs par film et par date.
3.  `UC-03` — Préparer une projection (film, salle, date, heure, tarifs).
4.  `UC-04` — Ouvrir / clôturer / annuler une projection.
5.  `UC-05` — Réserver une ou plusieurs places.
6.  `UC-06` — Confirmer, annuler ou laisser expirer une réservation.
7.  `UC-07` — Convertir une réservation en billets.
8.  `UC-08` — Vendre des billets au comptoir.
9.  `UC-09` — Contrôler un billet à l'entrée.
10.  `UC-10` — Consulter le planning et la recette d'une projection.

---

## 4\. Processus métier

### 4.1 Achat de droit de diffusion

```
Distributeur
   │
   ▼
[AchatDroitDiffusion]  (en-tête : dates, territoire, devise, montant)
   │
   ├── [AchatDroitDiffusionDetail]  Film 1 : période, quota, montant
   ├── [AchatDroitDiffusionDetail]  Film 2 : période, quota, montant
   └── ...
   │
   ▼
Validation (ETAT = 11) → droit actif
   │
   ▼
La préparation d'une projection vérifie qu'un droit actif couvre
le film, la date et le quota de projections.
```

**Étapes** :

1.  Le programmateur choisit un distributeur, une devise, un taux de change,  
    une période globale, un territoire et un mode de paiement.
2.  Il ajoute une ligne par film : période, nombre maximum de projections,  
    montant et TVA.
3.  Le système contrôle les dates, les doublons de film, les montants et le  
    quota.
4.  L'achat est d'abord créé en brouillon (`ETAT = 1`), puis validé  
    (`ETAT = 11`) par le responsable financier.
5.  Un achat validé ne peut plus être modifié ; il peut être annulé si aucune  
    projection active ne l'utilise.

### 4.2 Préparation d'une projection

```
Film + Droit actif + Salle
   │
   ▼
[Projection]  (date, heure début/fin, format, version, statut = Préparée)
   │
   ├── [ProjectionTarif]  Standard, tous rangs : prix, quota
   ├── [ProjectionTarif]  VIP, rangs A-C       : prix, quota
   ├── [ProjectionTarif]  VIP, autres rangs    : prix, quota
   └── ...
   │
   ▼
Validation (ETAT = 11, STATUT = Ouverte) → vente possible
```

**Contrôles** :

*   le film existe et possède un droit actif à la date de la projection ;
*   la salle existe, est active et n'a pas de chevauchement horaire ;
*   le nombre de places ne dépasse pas la capacité de la salle ;
*   au moins un tarif est défini ;
*   chaque tarif référence une catégorie existante et un rang existant dans la  
    salle (ou `'*'` pour tous les rangs) ;
*   la somme des quotas (hors `0`) ne dépasse pas le nombre de places ;
*   le quota du droit de diffusion n'est pas dépassé.

### 4.3 Réservation

```
Client + Projection ouverte + Places
   │
   ▼
[Reservation]  (statut = En attente, date d'expiration)
   │
   ├── [ReservationDetail]  Place A1, catégorie, prix
   ├── [ReservationDetail]  Place A2, catégorie, prix
   └── ...
   │
   ├── confirmation → statut = Confirmée
   ├── expiration   → statut = Expirée (places libérées)
   ├── annulation   → statut = Annulée (places libérées)
   └── conversion   → statut = Convertie + [AchatBillet]
```

**Règles** :

*   une place ne peut être réservée que si elle est libre pour la projection ;
*   la réservation bloque les places jusqu'à `DATEEXPIRATION` ;
*   une réservation confirmée reste bloquante ;
*   la conversion en billets conserve les mêmes places et crée un `AchatBillet` ;
*   l'annulation ou l'expiration libère immédiatement les places.

### 4.4 Achat de billet

```
Client + Projection ouverte + Places
   │
   ▼
[AchatBillet]  (montant total, montant payé, mode de paiement)
   │
   ├── [Billet]  Place A1, code-barres, statut = Vendu
   ├── [Billet]  Place A2, code-barres, statut = Vendu
   └── ...
   │
   ▼
Paiement → ETAT = 11
   │
   ├── impression du reçu / des billets
   └── contrôle à l'entrée → statut = Utilisé
```

**Contrôles** :

*   la projection est ouverte et non clôturée ;
*   chaque place est libre (hors places de la réservation en cours de conversion) ;
*   le prix est celui du tarif de la projection pour la catégorie de la place ;
*   `MONTANTPAYE >= MONTANTTOTAL` ;
*   un billet annulé ne peut plus être contrôlé ;
*   un billet déjà utilisé ne peut pas être réutilisé.

### 4.5 Contrôle à l'entrée

```
Code-barres / QR
   │
   ▼
Recherche du Billet
   │
   ├── introuvable            → refus
   ├── annulé                 → refus
   ├── déjà utilisé           → refus
   ├── mauvaise projection    → refus
   └── valide                 → statut = Utilisé, DATYUTILISATION = now
```

---

## 5\. Modèle de données

### 5.1 Vue d'ensemble

```
CINEMA_GENRE ◄──── CINEMA_FILM ◄──── CINEMA_ACHATDROITDETAIL ────► CINEMA_ACHATDROIT
                                                                    │
CINEMA_DISTRIBUTEUR ◄──────────────────────────────────────────────┘
                                                                    │
CINEMA_SALLE ◄──── CINEMA_PLACE                                     │
     │                  │                                           │
     └──── CINEMA_PROJECTION ◄──────────────────────────────────────┘
                │
                ├──── CINEMA_PROJECTIONTARIF ◄──── CINEMA_CATEGORIEPLACE
                │
                ├──── CINEMA_RESERVATION ◄──── CLIENT
                │          │
                │          └──── CINEMA_RESERVATIONDETAIL ◄──── CINEMA_PLACE
                │
                └──── CINEMA_ACHATBILLET ◄──── CLIENT
                           │
                           └──── CINEMA_BILLET ◄──── CINEMA_PLACE
```

### 5.2 Tables

#### 5.2.1 `CINEMA_GENRE`

Référentiel des genres cinématographiques (action, comédie, drame, etc.).

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `VAL` | `VARCHAR2(200)` | NOT NULL | Libellé du genre. |
| `DESCE` | `VARCHAR2(500)` |   | Description. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = actif, 0 = inactif. |

#### 5.2.2 `CINEMA_DISTRIBUTEUR`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `NOM` | `VARCHAR2(200)` | NOT NULL | Raison sociale. |
| `CONTACT` | `VARCHAR2(200)` |   | Personne de contact. |
| `TELEPHONE` | `VARCHAR2(50)` |   | Téléphone. |
| `EMAIL` | `VARCHAR2(200)` |   | E-mail. |
| `ADRESSE` | `VARCHAR2(500)` |   | Adresse. |
| `PAYS` | `VARCHAR2(100)` |   | Pays. |
| `DATY` | `DATE` | DEFAULT SYSDATE | Date de création. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = actif, 0 = inactif. |

#### 5.2.3 `CINEMA_CATEGORIEPLACE`

Catégories physiques ou tarifaires des places : Standard, VIP, Loge, Enfant.

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `VAL` | `VARCHAR2(200)` | NOT NULL | Libellé. |
| `DESCE` | `VARCHAR2(500)` |   | Description. |
| `PRIXDEFAUT` | `NUMBER` | DEFAULT 0 | Prix par défaut si la projection n'a pas de tarif explicite. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = actif, 0 = inactif. |

#### 5.2.4 `CINEMA_FILM`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `TITRE` | `VARCHAR2(300)` | NOT NULL | Titre exploitable. |
| `TITREORIGINAL` | `VARCHAR2(300)` |   | Titre original. |
| `IDGENRE` | `VARCHAR2(100)` | FK → `CINEMA_GENRE.ID` | Genre. |
| `DUREE` | `NUMBER(4)` |   | Durée en minutes. |
| `LANGUE` | `VARCHAR2(100)` |   | Langue originale. |
| `ANNEE` | `NUMBER(4)` |   | Année de production. |
| `REALISATEUR` | `VARCHAR2(200)` |   | Réalisateur. |
| `ACTEURS` | `VARCHAR2(1000)` |   | Acteurs principaux. |
| `CLASSIFICATION` | `VARCHAR2(20)` |   | Tous publics, -12, -16, -18. |
| `SYNOPSIS` | `VARCHAR2(4000)` |   | Résumé. |
| `AFFICHE` | `VARCHAR2(500)` |   | Chemin ou nom du fichier d'affiche. |
| `DATY` | `DATE` | DEFAULT SYSDATE | Date de création. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = actif, 0 = inactif. |

#### 5.2.5 `CINEMA_SALLE`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `NOM` | `VARCHAR2(200)` | NOT NULL | Nom de la salle. |
| `ADRESSE` | `VARCHAR2(500)` |   | Adresse / localisation. |
| `CAPACITE` | `NUMBER(4)` |   | Capacité maximale. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = active, 0 = inactive. |

#### 5.2.6 `CINEMA_PLACE`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `IDMERE` | `VARCHAR2(100)` | FK → `CINEMA_SALLE.ID` | Salle. |
| `NUMERO` | `VARCHAR2(20)` | NOT NULL | Numéro affiché (A1, B12…). |
| `RANG` | `VARCHAR2(10)` |   | Rang. |
| `COLONNE` | `NUMBER(4)` |   | Colonne. |
| `IDCATEGORIEPLACE` | `VARCHAR2(100)` | FK → `CINEMA_CATEGORIEPLACE.ID` | Catégorie. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = active, 0 = inactive. |

Contrainte : `UNIQUE (IDMERE, NUMERO)`.

#### 5.2.7 `CINEMA_ACHATDROIT`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `DATY` | `DATE` | DEFAULT SYSDATE | Date de l'achat. |
| `IDDISTRIBUTEUR` | `VARCHAR2(100)` | FK → `CINEMA_DISTRIBUTEUR.ID` | Distributeur. |
| `IDDEVISE` | `VARCHAR2(120)` | FK → `DEVISE.ID` | Devise. |
| `TAUXDEECHANGE` | `NUMBER` | DEFAULT 1 | Taux de conversion. |
| `MONTANTTOTAL` | `NUMBER` | DEFAULT 0 | Montant total HT ou TTC selon paramétrage. |
| `DATEDEBUT` | `DATE` |   | Début de la période globale. |
| `DATEFIN` | `DATE` |   | Fin de la période globale. |
| `TERRITOIRE` | `VARCHAR2(200)` |   | Territoire d'exploitation. |
| `EXCLUSIVITE` | `NUMBER(1)` | DEFAULT 0 | 1 = exclusivité. |
| `MODEPAIEMENT` | `VARCHAR2(255)` | FK → `MODEPAIEMENT.ID` | Mode de paiement. |
| `REFERENCE` | `VARCHAR2(100)` |   | Référence contrat / facture. |
| `REMARQUE` | `VARCHAR2(500)` |   | Remarque. |
| `IDBONDECOMMANDE` | `VARCHAR2(500)` | FK → `AS_BONDECOMMANDE.ID` | Raccordement achat (optionnel). |
| `IDFACTUREFOURNISSEUR` | `VARCHAR2(255)` |   | Raccordement facture fournisseur (optionnel). |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = brouillon, 11 = validé, 9 = clôturé, 0 = annulé. |

#### 5.2.8 `CINEMA_ACHATDROITDETAIL`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `IDMERE` | `VARCHAR2(100)` | FK → `CINEMA_ACHATDROIT.ID` | Achat. |
| `IDFILM` | `VARCHAR2(100)` | FK → `CINEMA_FILM.ID` | Film concerné. |
| `DATEDEBUT` | `DATE` |   | Début du droit pour ce film. |
| `DATEFIN` | `DATE` |   | Fin du droit pour ce film. |
| `NBMAXPROJECTION` | `NUMBER(6)` | DEFAULT 0 | Quota de projections (0 = illimité). |
| `MONTANT` | `NUMBER` | DEFAULT 0 | Montant de la ligne. |
| `TVA` | `NUMBER` | DEFAULT 0 | Taux de TVA. |
| `REMARQUE` | `VARCHAR2(500)` |   | Remarque. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | État de la ligne. |

Contrainte : `UNIQUE (IDMERE, IDFILM, DATEDEBUT)`.

#### 5.2.9 `CINEMA_PROJECTION`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `DATY` | `DATE` | NOT NULL | Date de la séance. |
| `HEUREDEBUT` | `VARCHAR2(5)` | NOT NULL | Heure de début `HH:mm`. |
| `HEUREFIN` | `VARCHAR2(5)` |   | Heure de fin `HH:mm`. |
| `IDFILM` | `VARCHAR2(100)` | FK → `CINEMA_FILM.ID` | Film projeté. |
| `IDSALLE` | `VARCHAR2(100)` | FK → `CINEMA_SALLE.ID` | Salle. |
| `IDACHATDROIT` | `VARCHAR2(100)` | FK → `CINEMA_ACHATDROIT.ID` | Achat de droit utilisé. |
| `IDACHATDROITDETAIL` | `VARCHAR2(100)` | FK → `CINEMA_ACHATDROITDETAIL.ID` | Ligne de droit utilisée. |
| `PRIXBASE` | `NUMBER` | DEFAULT 0 | Prix de repli si aucun tarif `(catégorie, rang)` n'est défini. |
| `NBPLACES` | `NUMBER(4)` |   | Nombre de places ouvertes (snapshot). |
| `FORMAT` | `VARCHAR2(20)` |   | 2D, 3D, IMAX… |
| `VERSION` | `VARCHAR2(20)` |   | VF, VOST… |
| `STATUT` | `NUMBER(2)` | DEFAULT 1 | 1 = préparée, 2 = ouverte, 3 = clôturée, 0 = annulée. |
| `REMARQUE` | `VARCHAR2(500)` |   | Remarque. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = créé, 11 = validé, 9 = clôturé, 0 = annulé. |

#### 5.2.10 `CINEMA_PROJECTIONTARIF`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `IDMERE` | `VARCHAR2(100)` | FK → `CINEMA_PROJECTION.ID` | Projection. |
| `IDCATEGORIEPLACE` | `VARCHAR2(100)` | FK → `CINEMA_CATEGORIEPLACE.ID` | Catégorie de place. |
| `RANG` | `VARCHAR2(10)` | DEFAULT `'*'` NOT NULL | Rang concerné (`'*'` = tous les rangs). |
| `PRIX` | `NUMBER` | DEFAULT 0 | Prix unitaire. |
| `QUOTA` | `NUMBER(6)` | DEFAULT 0 | Quota de places pour cette ligne (0 = pas de quota). |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | État de la ligne. |

Contrainte : `UNIQUE (IDMERE, IDCATEGORIEPLACE, RANG)`.

> La valeur sentinelle `'*'` est utilisée à la place de `NULL` car Oracle  
> considère deux `NULL` comme distincts dans une contrainte `UNIQUE` : on  
> pourrait sinon créer plusieurs lignes « tous rangs » pour la même catégorie.
> 
> Résolution du prix d'une place : ligne `(catégorie, rang)` exacte, puis  
> ligne `(catégorie, '*')`, puis `CINEMA_PROJECTION.PRIXBASE`, puis  
> `CINEMA_CATEGORIEPLACE.PRIXDEFAUT`.

#### 5.2.11 `CINEMA_RESERVATION`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `DATY` | `DATE` | DEFAULT SYSDATE | Date de la réservation. |
| `IDCLIENT` | `VARCHAR2(255)` | FK → `CLIENT.ID` | Client. |
| `IDPROJECTION` | `VARCHAR2(100)` | FK → `CINEMA_PROJECTION.ID` | Projection. |
| `DATEEXPIRATION` | `DATE` |   | Date/heure limite de la réservation. |
| `MONTANTACOMPTE` | `NUMBER` | DEFAULT 0 | Acompte versé. |
| `STATUT` | `NUMBER(2)` | DEFAULT 1 | 1 = en attente, 2 = confirmée, 3 = convertie, 4 = expirée, 0 = annulée. |
| `REMARQUE` | `VARCHAR2(500)` |   | Remarque. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = créée, 11 = validée, 9 = clôturée, 0 = annulée. |

#### 5.2.12 `CINEMA_RESERVATIONDETAIL`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `IDMERE` | `VARCHAR2(100)` | FK → `CINEMA_RESERVATION.ID` | Réservation. |
| `IDPLACE` | `VARCHAR2(100)` | FK → `CINEMA_PLACE.ID` | Place réservée. |
| `IDCATEGORIEPLACE` | `VARCHAR2(100)` | FK → `CINEMA_CATEGORIEPLACE.ID` | Catégorie au moment de la réservation. |
| `PRIX` | `NUMBER` | DEFAULT 0 | Prix unitaire appliqué. |
| `IDBILLET` | `VARCHAR2(100)` | FK → `CINEMA_BILLET.ID` | Billet créé lors de la conversion. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | État de la ligne. |

Contrainte : `UNIQUE (IDMERE, IDPLACE)`.

> La FK `IDBILLET → CINEMA_BILLET.ID` est ajoutée par `ALTER TABLE` **après**  
> la création de `CINEMA_BILLET`, car les deux tables se référencent  
> fonctionnellement (réservation → billet → achat → réservation).

#### 5.2.13 `CINEMA_ACHATBILLET`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `DATY` | `DATE` | DEFAULT SYSDATE | Date de l'achat. |
| `IDCLIENT` | `VARCHAR2(255)` | FK → `CLIENT.ID` | Client. |
| `IDPROJECTION` | `VARCHAR2(100)` | FK → `CINEMA_PROJECTION.ID` | Projection. |
| `IDRESERVATION` | `VARCHAR2(100)` | FK → `CINEMA_RESERVATION.ID` | Réservation d'origine (nullable). |
| `MONTANTTOTAL` | `NUMBER` | DEFAULT 0 | Montant total. |
| `MONTANTPAYE` | `NUMBER` | DEFAULT 0 | Montant reçu. |
| `MONNAIERENDUE` | `NUMBER` | DEFAULT 0 | Monnaie rendue. |
| `MODEPAIEMENT` | `VARCHAR2(255)` | FK → `MODEPAIEMENT.ID` | Mode de paiement. |
| `IDVENTE` | `VARCHAR2(255)` | FK → `VENTE.ID` | Facture de vente (optionnel). |
| `IDMOUVEMENTCAISSE` | `VARCHAR2(255)` | FK → `MOUVEMENTCAISSE.ID` | Mouvement de caisse (optionnel). |
| `REMARQUE` | `VARCHAR2(500)` |   | Remarque. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = créé, 11 = validé, 0 = annulé. |

#### 5.2.14 `CINEMA_BILLET`

| Colonne | Type | Contrainte | Description |
| --- | --- | --- | --- |
| `ID` | `VARCHAR2(100)` | PK | Identifiant. |
| `IDMERE` | `VARCHAR2(100)` | FK → `CINEMA_ACHATBILLET.ID` | Achat. |
| `IDPLACE` | `VARCHAR2(100)` | FK → `CINEMA_PLACE.ID` | Place. |
| `IDCATEGORIEPLACE` | `VARCHAR2(100)` | FK → `CINEMA_CATEGORIEPLACE.ID` | Catégorie. |
| `PRIX` | `NUMBER` | DEFAULT 0 | Prix unitaire. |
| `NUMERO` | `VARCHAR2(50)` |   | Numéro lisible du billet. |
| `CODEBARRE` | `VARCHAR2(100)` | UNIQUE | Code-barres / QR. |
| `DATYUTILISATION` | `DATE` |   | Date/heure de contrôle à l'entrée. |
| `STATUT` | `NUMBER(2)` | DEFAULT 1 | 1 = vendu, 2 = utilisé, 0 = annulé. |
| `ETAT` | `NUMBER(22)` | DEFAULT 1 | 1 = créé, 11 = validé, 0 = annulé. |

Contrainte : `UNIQUE (IDMERE, IDPLACE)`.

### 5.3 Séquences et fonctions PK

| Objet | Préfixe PK | Fonction `GETSEQ…` | Séquence |
| --- | --- | --- | --- |
| `Genre` | `CGR` | `GETSEQCINEMAGENRE` | `SEQ_CINEMA_GENRE` |
| `Distributeur` | `CDI` | `GETSEQCINEMADISTRIBUTEUR` | `SEQ_CINEMA_DISTRIBUTEUR` |
| `CategoriePlace` | `CCP` | `GETSEQCINEMACATEGORIEPLACE` | `SEQ_CINEMA_CATEGORIEPLACE` |
| `Film` | `CFI` | `GETSEQCINEMAFILM` | `SEQ_CINEMA_FILM` |
| `Salle` | `CSA` | `GETSEQCINEMASALLE` | `SEQ_CINEMA_SALLE` |
| `Place` | `CPL` | `GETSEQCINEMAPLACE` | `SEQ_CINEMA_PLACE` |
| `AchatDroitDiffusion` | `CAD` | `GETSEQCINEMAACHATDROIT` | `SEQ_CINEMA_ACHATDROIT` |
| `AchatDroitDiffusionDetail` | `CADF` | `GETSEQCINEMAACHATDROITDETAIL` | `SEQ_CINEMA_ACHATDROITDETAIL` |
| `Projection` | `CPR` | `GETSEQCINEMAPROJECTION` | `SEQ_CINEMA_PROJECTION` |
| `ProjectionTarif` | `CPRT` | `GETSEQCINEMAPROJECTIONTARIF` | `SEQ_CINEMA_PROJECTIONTARIF` |
| `Reservation` | `CRS` | `GETSEQCINEMARESERVATION` | `SEQ_CINEMA_RESERVATION` |
| `ReservationDetail` | `CRSD` | `GETSEQCINEMARESERVATIONDETAIL` | `SEQ_CINEMA_RESERVATIONDETAIL` |
| `AchatBillet` | `CAB` | `GETSEQCINEMAACHATBILLET` | `SEQ_CINEMA_ACHATBILLET` |
| `Billet` | `CBI` | `GETSEQCINEMABILLET` | `SEQ_CINEMA_BILLET` |

Exemple de fonction Oracle :

```
CREATE SEQUENCE SEQ_CINEMA_FILM START WITH 1 INCREMENT BY 1 NOCACHE;

CREATE OR REPLACE FUNCTION GETSEQCINEMAFILM RETURN NUMBER IS
    v NUMBER;
BEGIN
    SELECT SEQ_CINEMA_FILM.NEXTVAL INTO v FROM DUAL;
    RETURN v;
END;
/
```

### 5.4 Vues `*_LIB`

| Vue | Rôle | Colonnes supplémentaires attendues |
| --- | --- | --- |
| `CINEMA_DISTRIBUTEUR_LIB` | Distributeur + état | `ETATLIB` |
| `CINEMA_CATEGORIEPLACE_LIB` | Catégorie + état | `ETATLIB` |
| `CINEMA_FILM_LIB` | Film + genre | `IDGENRELIB`, `ETATLIB`, `NBDROITSACTIFS` |
| `CINEMA_SALLE_LIB` | Salle + places | `ETATLIB`, `NBPLACESLIB` |
| `CINEMA_PLACE_LIB` | Place + salle + catégorie | `SALLELIB`, `IDCATEGORIEPLACELIB`, `ETATLIB` |
| `CINEMA_ACHATDROIT_LIB` | Achat + distributeur + devise | `IDDISTRIBUTEURLIB`, `IDDEVISELIB`, `ETATLIB`, `NBFILMSLIB`, `MONTANTDETAIL` |
| `CINEMA_ACHATDROITDETAIL_LIB` | Détail + film + genre | `IDFILMLIB`, `IDGENRELIB`, `ETATLIB`, `NBPROJECTIONUTILISEES`, `NBPROJECTIONRESTANTES` |
| `CINEMA_PROJECTION_LIB` | Projection + film + salle + droit | `IDFILMLIB`, `IDGENRELIB`, `IDSALLELIB`, `IDACHATDROITLIB`, `ETATLIB`, `STATUTLIB`, `NBPLACESVENDUES`, `NBPLACESRESERVEES`, `NBPLACESDISPONIBLES`, `RECETTE` |
| `CINEMA_PROJECTIONTARIF_LIB` | Tarif + catégorie | `IDCATEGORIEPLACELIB`, `RANGLIB`, `ETATLIB`, `QUOTARESTANT` |
| `CINEMA_RESERVATION_LIB` | Réservation + client + projection | `IDCLIENTLIB`, `IDPROJECTIONLIB`, `IDFILMLIB`, `IDSALLELIB`, `ETATLIB`, `STATUTLIB`, `NBPLACESLIB`, `MONTANTTOTALLIB`, `RESTEAPAYERLIB` |
| `CINEMA_RESERVATIONDETAIL_LIB` | Détail + place + catégorie + billet | `IDPLACELIB`, `IDCATEGORIEPLACELIB`, `IDBILLETLIB`, `ETATLIB` |
| `CINEMA_ACHATBILLET_LIB` | Achat + client + projection | `IDCLIENTLIB`, `IDPROJECTIONLIB`, `IDFILMLIB`, `IDSALLELIB`, `ETATLIB`, `NBBILLETSLIB`, `MONTANTTOTAL` |
| `CINEMA_BILLET_LIB` | Billet + place + achat + projection | `IDPLACELIB`, `IDCATEGORIEPLACELIB`, `IDACHATBILLETLIB`, `IDPROJECTIONLIB`, `IDFILMLIB`, `STATUTLIB`, `ETATLIB` |

**Vue technique de disponibilité** : `CINEMA_PLACE_OCCUPEE`

```
CREATE OR REPLACE VIEW CINEMA_PLACE_OCCUPEE AS
SELECT r.IDPROJECTION, rd.IDPLACE, 'RESERVATION' AS TYPE_OCCUPATION,
       r.ID AS IDORIGINE, r.STATUT
  FROM CINEMA_RESERVATION r
  JOIN CINEMA_RESERVATIONDETAIL rd ON rd.IDMERE = r.ID
 WHERE r.ETAT IN (1, 11)
   AND r.STATUT IN (1, 2)
UNION ALL
SELECT ab.IDPROJECTION, b.IDPLACE, 'BILLET',
       ab.ID, b.STATUT
  FROM CINEMA_ACHATBILLET ab
  JOIN CINEMA_BILLET b ON b.IDMERE = ab.ID
 WHERE ab.ETAT = 11
   AND b.ETAT = 11
   AND b.STATUT IN (1, 2);
```

Cette vue est utilisée par les services pour vérifier qu'une place est libre.  
Une place annulée, expirée ou convertie disparaît automatiquement de la vue  
grâce aux filtres sur `ETAT` et `STATUT`.

### 5.5 Index recommandés

```
CREATE INDEX IDX_CINEMA_FILM_TITRE       ON CINEMA_FILM (TITRE);
CREATE INDEX IDX_CINEMA_PLACE_SALLE      ON CINEMA_PLACE (IDMERE, IDCATEGORIEPLACE);
CREATE INDEX IDX_CINEMA_PROJ_DATE        ON CINEMA_PROJECTION (DATY, IDSALLE);
CREATE INDEX IDX_CINEMA_PROJ_FILM        ON CINEMA_PROJECTION (IDFILM, DATY);
CREATE INDEX IDX_CINEMA_PROJTARIF_RANG   ON CINEMA_PROJECTIONTARIF (IDMERE, RANG);
CREATE INDEX IDX_CINEMA_RESERV_PROJ      ON CINEMA_RESERVATION (IDPROJECTION, STATUT);
CREATE INDEX IDX_CINEMA_RESERV_CLIENT    ON CINEMA_RESERVATION (IDCLIENT, DATY);
CREATE INDEX IDX_CINEMA_ACHATBILLET_PROJ ON CINEMA_ACHATBILLET (IDPROJECTION, ETAT);
CREATE INDEX IDX_CINEMA_BILLET_CODE      ON CINEMA_BILLET (CODEBARRE);
CREATE INDEX IDX_CINEMA_BILLET_PROJ      ON CINEMA_BILLET (IDMERE, IDPLACE);
```

---

## 6\. Modèle objet Java

### 6.1 Arborescence des packages

```
arbiochem-ejb/src/java/cinema/
├── utils/
│   └── ConstanteCinema.java
├── configuration/
│   ├── Genre.java
│   ├── Distributeur.java
│   ├── DistributeurLib.java
│   ├── CategoriePlace.java
│   ├── CategoriePlaceLib.java
│   ├── Salle.java
│   ├── SalleLib.java
│   ├── Place.java
│   └── PlaceLib.java
├── film/
│   ├── Film.java
│   └── FilmLib.java
├── diffusion/
│   ├── AchatDroitDiffusion.java
│   ├── AchatDroitDiffusionLib.java
│   ├── AchatDroitDiffusionDetail.java
│   ├── AchatDroitDiffusionDetailLib.java
│   └── AchatDroitDiffusionService.java
├── projection/
│   ├── Projection.java
│   ├── ProjectionLib.java
│   ├── ProjectionTarif.java
│   ├── ProjectionTarifLib.java
│   └── ProjectionService.java
├── reservation/
│   ├── Reservation.java
│   ├── ReservationLib.java
│   ├── ReservationDetail.java
│   ├── ReservationDetailLib.java
│   └── ReservationService.java
└── billet/
    ├── AchatBillet.java
    ├── AchatBilletLib.java
    ├── Billet.java
    ├── BilletLib.java
    └── AchatBilletService.java
```

### 6.2 Diagramme de classes

```
TypeObjet
   └── Genre

ClassMAPTable
   ├── Distributeur
   ├── CategoriePlace
   └── Film

ClassMere
   ├── Salle       1 ─── * Place
   ├── AchatDroitDiffusion 1 ─── * AchatDroitDiffusionDetail
   ├── Projection  1 ─── * ProjectionTarif
   ├── Reservation 1 ─── * ReservationDetail
   └── AchatBillet 1 ─── * Billet

ClassFille
   ├── Place
   ├── AchatDroitDiffusionDetail
   ├── ProjectionTarif
   ├── ReservationDetail
   └── Billet
```

**Squelette type d'un objet mère** (à reproduire pour chaque classe) :

```java
package cinema.xxx;

import bean.ClassMere;
import java.sql.Connection;

public class Xxx extends ClassMere {
    private String id;
    private int etat;

    public Xxx() throws Exception {
        super.setNomTable("CINEMA_XXX");
        this.setNomClasseFille("cinema.xxx.XxxDetail");
        this.setLiaisonFille("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CXX", "GETSEQCINEMAXXX");
        this.setId(this.makePK(c));
    }

    @Override
    public String getTuppleID() { return id; }
    @Override
    public String getAttributIDName() { return "id"; }
    @Override
    public String getNomClasseFille() { return "cinema.xxx.XxxDetail"; }
    @Override
    public String getLiaisonFille() { return "idMere"; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
```

**Squelette type d'un objet fille** :

```java
package cinema.xxx;

import bean.ClassFille;
import java.sql.Connection;

public class XxxDetail extends ClassFille {
    private String id;
    private String idMere;
    private int etat;

    public XxxDetail() throws Exception {
        super.setNomTable("CINEMA_XXXDETAIL");
        this.setNomClasseMere("cinema.xxx.Xxx");
        this.setLiaisonMere("idMere");
    }

    @Override
    public void construirePK(Connection c) throws Exception {
        this.preparePk("CXXF", "GETSEQCINEMAXXXDETAIL");
        this.setId(this.makePK(c));
    }

    @Override
    public String getTuppleID() { return id; }
    @Override
    public String getAttributIDName() { return "id"; }
    @Override
    public String getNomClasseMere() { return "cinema.xxx.Xxx"; }
    @Override
    public String getLiaisonMere() { return "idMere"; }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getIdMere() { return idMere; }
    public void setIdMere(String idMere) { this.idMere = idMere; }
    public int getEtat() { return etat; }
    public void setEtat(int etat) { this.etat = etat; }
}
```

### 6.3 Constantes métier

#### `cinema.utils.ConstanteCinema`

```java
public final class ConstanteCinema {
    private ConstanteCinema() {}

    // États standards
    public static final int ETAT_ANNULE  = 0;
    public static final int ETAT_CREER   = 1;
    public static final int ETAT_CLOTURE = 9;
    public static final int ETAT_REJETE  = 10;
    public static final int ETAT_VALIDER = 11;

    // Statuts projection
    public static final int STATUT_PROJECTION_ANNULEE  = 0;
    public static final int STATUT_PROJECTION_PREPAREE = 1;
    public static final int STATUT_PROJECTION_OUVERTE  = 2;
    public static final int STATUT_PROJECTION_CLOTUREE = 3;

    // Statuts réservation
    public static final int STATUT_RESERVATION_ANNULEE   = 0;
    public static final int STATUT_RESERVATION_EN_ATTENTE = 1;
    public static final int STATUT_RESERVATION_CONFIRMEE  = 2;
    public static final int STATUT_RESERVATION_CONVERTIE  = 3;
    public static final int STATUT_RESERVATION_EXPIREE    = 4;

    // Statuts billet
    public static final int STATUT_BILLET_ANNULE = 0;
    public static final int STATUT_BILLET_VENDU  = 1;
    public static final int STATUT_BILLET_UTILISE = 2;

    // Paramètres métier
    public static final int    DUREE_RESERVATION_MINUTES = 30;
    public static final String RANG_TOUS                 = "*";
    public static final String PREFIXE_CODE_BARRE        = "CINE";
    public static final String IDCLIENT_COMPTOIR         = "CLI00000001";
    public static final String COMPTE_VENTE_BILLET       = "70700002";
    public static final String JOURNAL_VENTE             = "VENTE";

    public static String getStatutProjectionLib(int statut) {
        switch (statut) {
            case STATUT_PROJECTION_PREPAREE: return "Préparée";
            case STATUT_PROJECTION_OUVERTE:  return "Ouverte";
            case STATUT_PROJECTION_CLOTUREE: return "Clôturée";
            case STATUT_PROJECTION_ANNULEE:  return "Annulée";
            default: return "Inconnu";
        }
    }

    public static String getStatutReservationLib(int statut) {
        switch (statut) {
            case STATUT_RESERVATION_EN_ATTENTE: return "En attente";
            case STATUT_RESERVATION_CONFIRMEE:  return "Confirmée";
            case STATUT_RESERVATION_CONVERTIE:  return "Convertie";
            case STATUT_RESERVATION_EXPIREE:    return "Expirée";
            case STATUT_RESERVATION_ANNULEE:    return "Annulée";
            default: return "Inconnu";
        }
    }

    public static String getStatutBilletLib(int statut) {
        switch (statut) {
            case STATUT_BILLET_VENDU:   return "Vendu";
            case STATUT_BILLET_UTILISE: return "Utilisé";
            case STATUT_BILLET_ANNULE:  return "Annulé";
            default: return "Inconnu";
        }
    }
}
```

### 6.4 Référentiels

#### 6.4.1 `cinema.configuration.Genre`

*   **Table** : `CINEMA_GENRE`
*   **Héritage** : `bean.TypeObjet`

```java
public class Genre extends TypeObjet {
    public Genre();
    public void construirePK(Connection c) throws Exception;
}
```

Champs hérités de `TypeObjet` :

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `val` | `String` | `getVal()` / `setVal(String)` |
| `desce` | `String` | `getDesce()` / `setDesce(String)` |

#### 6.4.2 `cinema.configuration.Distributeur`

*   **Table** : `CINEMA_DISTRIBUTEUR`
*   **Héritage** : `bean.ClassMAPTable`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `nom` | `String` | `getNom()` / `setNom(String)` |
| `contact` | `String` | `getContact()` / `setContact(String)` |
| `telephone` | `String` | `getTelephone()` / `setTelephone(String)` |
| `email` | `String` | `getEmail()` / `setEmail(String)` |
| `adresse` | `String` | `getAdresse()` / `setAdresse(String)` |
| `pays` | `String` | `getPays()` / `setPays(String)` |
| `daty` | `java.sql.Date` | `getDaty()` / `setDaty(java.sql.Date)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public Distributeur();
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public ClassMAPTable createObject(String u, Connection c) throws Exception;
public int updateObject(String u, Connection c) throws Exception;
```

#### 6.4.3 `cinema.configuration.CategoriePlace`

*   **Table** : `CINEMA_CATEGORIEPLACE`
*   **Héritage** : `bean.ClassMAPTable`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `val` | `String` | `getVal()` / `setVal(String)` |
| `desce` | `String` | `getDesce()` / `setDesce(String)` |
| `prixDefaut` | `double` | `getPrixDefaut()` / `setPrixDefaut(double)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public CategoriePlace();
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getLibelle();
public void controlerPrix() throws Exception;
public ClassMAPTable createObject(String u, Connection c) throws Exception;
public int updateObject(String u, Connection c) throws Exception;
```

`setPrixDefaut(double)` refuse une valeur négative.

#### 6.4.4 `cinema.configuration.Salle`

*   **Table** : `CINEMA_SALLE`
*   **Héritage** : `bean.ClassMere`
*   **Fille** : `cinema.configuration.Place`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `nom` | `String` | `getNom()` / `setNom(String)` |
| `adresse` | `String` | `getAdresse()` / `setAdresse(String)` |
| `capacite` | `int` | `getCapacite()` / `setCapacite(int)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public Salle() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseFille();
public String getLiaisonFille();
public ClassMAPTable createObject(String u, Connection c) throws Exception;
public void controlerCapacite() throws Exception;
public int getNbPlaces();
public Place[] getPlacesActives(Connection c) throws Exception;
public Place getPlace(String numero, Connection c) throws Exception;
```

`controlerCapacite()` vérifie que `capacite > 0` et que le nombre de places  
actives ne dépasse pas la capacité.

#### 6.4.5 `cinema.configuration.Place`

*   **Table** : `CINEMA_PLACE`
*   **Héritage** : `bean.ClassFille`
*   **Mère** : `cinema.configuration.Salle`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `idMere` | `String` | `getIdMere()` / `setIdMere(String)` |
| `numero` | `String` | `getNumero()` / `setNumero(String)` |
| `rang` | `String` | `getRang()` / `setRang(String)` |
| `colonne` | `int` | `getColonne()` / `setColonne(int)` |
| `idCategoriePlace` | `String` | `getIdCategoriePlace()` / `setIdCategoriePlace(String)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public Place() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseMere();
public String getLiaisonMere();
public String getLibelle();
public boolean estActive();
```

`getLibelle()` retourne par exemple `"Rang B - Place 12"`.

#### 6.4.6 Classes `*Lib` des référentiels

Ces classes étendent l'objet de base et fixent `setNomTable` sur la vue  
correspondante. Elles n'ajoutent que des champs d'affichage.

`**cinema.configuration.DistributeurLib**`

*   **Table** : `CINEMA_DISTRIBUTEUR_LIB`
*   **Héritage** : `cinema.configuration.Distributeur`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |

```java
public DistributeurLib();
```

`**cinema.configuration.CategoriePlaceLib**`

*   **Table** : `CINEMA_CATEGORIEPLACE_LIB`
*   **Héritage** : `cinema.configuration.CategoriePlace`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |

```java
public CategoriePlaceLib();
```

`**cinema.configuration.SalleLib**`

*   **Table** : `CINEMA_SALLE_LIB`
*   **Héritage** : `cinema.configuration.Salle`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |
| `nbPlaces` | `int` | `getNbPlacesLib()` / `setNbPlacesLib(int)` |

```java
public SalleLib() throws Exception;
```

`**cinema.configuration.PlaceLib**`

*   **Table** : `CINEMA_PLACE_LIB`
*   **Héritage** : `cinema.configuration.Place`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `salleLib` | `String` | `getSalleLib()` / `setSalleLib(String)` |
| `idCategoriePlaceLib` | `String` | `getIdCategoriePlaceLib()` / `setIdCategoriePlaceLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |

```java
public PlaceLib() throws Exception;
```

### 6.5 Film

#### 6.5.1 `cinema.film.Film`

*   **Table** : `CINEMA_FILM`
*   **Héritage** : `bean.ClassMAPTable`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `titre` | `String` | `getTitre()` / `setTitre(String)` |
| `titreOriginal` | `String` | `getTitreOriginal()` / `setTitreOriginal(String)` |
| `idGenre` | `String` | `getIdGenre()` / `setIdGenre(String)` |
| `duree` | `int` | `getDuree()` / `setDuree(int)` |
| `langue` | `String` | `getLangue()` / `setLangue(String)` |
| `annee` | `int` | `getAnnee()` / `setAnnee(int)` |
| `realisateur` | `String` | `getRealisateur()` / `setRealisateur(String)` |
| `acteurs` | `String` | `getActeurs()` / `setActeurs(String)` |
| `classification` | `String` | `getClassification()` / `setClassification(String)` |
| `synopsis` | `String` | `getSynopsis()` / `setSynopsis(String)` |
| `affiche` | `String` | `getAffiche()` / `setAffiche(String)` |
| `daty` | `java.sql.Date` | `getDaty()` / `setDaty(java.sql.Date)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public Film() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getLibelle();
public String getDureeHeureMinute();
public void controlerDuree() throws Exception;
public ClassMAPTable createObject(String u, Connection c) throws Exception;
public int updateObject(String u, Connection c) throws Exception;
public static Film[] rechercher(String motCle, Connection c) throws Exception;
```

*   `getLibelle()` retourne `titre + " (" + annee + ")"`.
*   `getDureeHeureMinute()` retourne par exemple `"1h52"`.
*   `controlerDuree()` refuse `duree <= 0` ou `duree > 600`.
*   `rechercher` utilise `CGenUtil.rechercher` avec un `LIKE` sur `TITRE`.

#### 6.5.2 `cinema.film.FilmLib`

*   **Table** : `CINEMA_FILM_LIB`
*   **Héritage** : `cinema.film.Film`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `idGenreLib` | `String` | `getIdGenreLib()` / `setIdGenreLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |
| `nbDroitsActifs` | `int` | `getNbDroitsActifs()` / `setNbDroitsActifs(int)` |

```java
public FilmLib() throws Exception;
```

### 6.6 Achat de droit de diffusion

#### 6.6.1 `cinema.diffusion.AchatDroitDiffusion`

*   **Table** : `CINEMA_ACHATDROIT`
*   **Héritage** : `bean.ClassMere`
*   **Fille** : `cinema.diffusion.AchatDroitDiffusionDetail`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `daty` | `java.sql.Date` | `getDaty()` / `setDaty(java.sql.Date)` |
| `idDistributeur` | `String` | `getIdDistributeur()` / `setIdDistributeur(String)` |
| `idDevise` | `String` | `getIdDevise()` / `setIdDevise(String)` |
| `tauxDeChange` | `double` | `getTauxDeChange()` / `setTauxDeChange(double)` |
| `montantTotal` | `double` | `getMontantTotal()` / `setMontantTotal(double)` |
| `dateDebut` | `java.sql.Date` | `getDateDebut()` / `setDateDebut(java.sql.Date)` |
| `dateFin` | `java.sql.Date` | `getDateFin()` / `setDateFin(java.sql.Date)` |
| `territoire` | `String` | `getTerritoire()` / `setTerritoire(String)` |
| `exclusivite` | `int` | `getExclusivite()` / `setExclusivite(int)` |
| `modepaiement` | `String` | `getModepaiement()` / `setModepaiement(String)` |
| `reference` | `String` | `getReference()` / `setReference(String)` |
| `remarque` | `String` | `getRemarque()` / `setRemarque(String)` |
| `idBonDeCommande` | `String` | `getIdBonDeCommande()` / `setIdBonDeCommande(String)` |
| `idFactureFournisseur` | `String` | `getIdFactureFournisseur()` / `setIdFactureFournisseur(String)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public AchatDroitDiffusion() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseFille();
public String getLiaisonFille();
public ClassMAPTable createObject(String u, Connection c) throws Exception;
public Object validerObject(String u, Connection c) throws Exception;
public Object annulerObject(String u, Connection c) throws Exception;
public void controlerDates() throws Exception;
public void controlerDetail() throws Exception;
public double getMontantDetails();
public int getNbFilms();
public boolean estActif(java.sql.Date date);
public boolean couvreFilm(String idFilm, java.sql.Date date);
public AchatDroitDiffusionDetail getDetailPourFilm(String idFilm, java.sql.Date date, Connection c) throws Exception;
public int getNbProjectionsUtilisees(Connection c) throws Exception;
```

**Contrôles** :

*   `dateDebut <= dateFin` ;
*   `tauxDeChange > 0` ;
*   `montantTotal >= 0` ;
*   au moins une ligne de détail ;
*   chaque ligne a un film, des dates cohérentes et un montant positif ;
*   pas de doublon `(idFilm, dateDebut)` dans le même achat ;
*   `annulerObject` refuse si des projections actives utilisent ce droit.

#### 6.6.2 `cinema.diffusion.AchatDroitDiffusionDetail`

*   **Table** : `CINEMA_ACHATDROITDETAIL`
*   **Héritage** : `bean.ClassFille`
*   **Mère** : `cinema.diffusion.AchatDroitDiffusion`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `idMere` | `String` | `getIdMere()` / `setIdMere(String)` |
| `idFilm` | `String` | `getIdFilm()` / `setIdFilm(String)` |
| `dateDebut` | `java.sql.Date` | `getDateDebut()` / `setDateDebut(java.sql.Date)` |
| `dateFin` | `java.sql.Date` | `getDateFin()` / `setDateFin(java.sql.Date)` |
| `nbMaxProjection` | `int` | `getNbMaxProjection()` / `setNbMaxProjection(int)` |
| `montant` | `double` | `getMontant()` / `setMontant(double)` |
| `tva` | `double` | `getTva()` / `setTva(double)` |
| `remarque` | `String` | `getRemarque()` / `setRemarque(String)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public AchatDroitDiffusionDetail() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseMere();
public String getLiaisonMere();
public void controlerDates() throws Exception;
public boolean estActif(java.sql.Date date);
public boolean couvre(java.sql.Date date);
public int getNbProjectionsUtilisees(Connection c) throws Exception;
public int getNbProjectionsRestantes(Connection c) throws Exception;
public void controlerQuota(Connection c) throws Exception;
public double getMontantTTC();
```

*   `estActif` : `etat == 11`, `dateDebut <= date <= dateFin`.
*   `getNbProjectionsUtilisees` compte les projections non annulées liées à ce détail.
*   `getNbProjectionsRestantes` : `nbMaxProjection == 0 ? Integer.MAX_VALUE : nbMaxProjection - utilisees`.
*   `controlerQuota` refuse si `nbMaxProjection > 0` et `utilisees >= nbMaxProjection`.

#### 6.6.3 `cinema.diffusion.AchatDroitDiffusionLib`

*   **Table** : `CINEMA_ACHATDROIT_LIB`
*   **Héritage** : `cinema.diffusion.AchatDroitDiffusion`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `idDistributeurLib` | `String` | `getIdDistributeurLib()` / `setIdDistributeurLib(String)` |
| `idDeviseLib` | `String` | `getIdDeviseLib()` / `setIdDeviseLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |
| `nbFilmsLib` | `int` | `getNbFilmsLib()` / `setNbFilmsLib(int)` |
| `montantDetail` | `double` | `getMontantDetail()` / `setMontantDetail(double)` |

```java
public AchatDroitDiffusionLib() throws Exception;
```

#### 6.6.4 `cinema.diffusion.AchatDroitDiffusionDetailLib`

*   **Table** : `CINEMA_ACHATDROITDETAIL_LIB`
*   **Héritage** : `cinema.diffusion.AchatDroitDiffusionDetail`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `idFilmLib` | `String` | `getIdFilmLib()` / `setIdFilmLib(String)` |
| `idGenreLib` | `String` | `getIdGenreLib()` / `setIdGenreLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |
| `nbProjectionUtilisees` | `int` | `getNbProjectionUtilisees()` / `setNbProjectionUtilisees(int)` |
| `nbProjectionRestantes` | `int` | `getNbProjectionRestantes()` / `setNbProjectionRestantes(int)` |

```java
public AchatDroitDiffusionDetailLib() throws Exception;
```

---

### 6.7 Projection

#### 6.7.1 `cinema.projection.Projection`

*   **Table** : `CINEMA_PROJECTION`
*   **Héritage** : `bean.ClassMere`
*   **Fille** : `cinema.projection.ProjectionTarif`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `daty` | `java.sql.Date` | `getDaty()` / `setDaty(java.sql.Date)` |
| `heureDebut` | `String` | `getHeureDebut()` / `setHeureDebut(String)` |
| `heureFin` | `String` | `getHeureFin()` / `setHeureFin(String)` |
| `idFilm` | `String` | `getIdFilm()` / `setIdFilm(String)` |
| `idSalle` | `String` | `getIdSalle()` / `setIdSalle(String)` |
| `idAchatDroit` | `String` | `getIdAchatDroit()` / `setIdAchatDroit(String)` |
| `idAchatDroitDetail` | `String` | `getIdAchatDroitDetail()` / `setIdAchatDroitDetail(String)` |
| `prixBase` | `double` | `getPrixBase()` / `setPrixBase(double)` |
| `nbPlaces` | `int` | `getNbPlaces()` / `setNbPlaces(int)` |
| `format` | `String` | `getFormat()` / `setFormat(String)` |
| `version` | `String` | `getVersion()` / `setVersion(String)` |
| `statut` | `int` | `getStatut()` / `setStatut(int)` |
| `remarque` | `String` | `getRemarque()` / `setRemarque(String)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public Projection() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseFille();
public String getLiaisonFille();
public ClassMAPTable createObject(String u, Connection c) throws Exception;
public Object validerObject(String u, Connection c) throws Exception;
public Object cloturerObject(String u, Connection c) throws Exception;
public Object annulerObject(String u, Connection c) throws Exception;
public void controlerHoraire() throws Exception;
public void controlerSalle(Connection c) throws Exception;
public void controlerDroitDiffusion(Connection c) throws Exception;
public void controlerTarifs() throws Exception;
public int getNbPlacesVendues(Connection c) throws Exception;
public int getNbPlacesReservees(Connection c) throws Exception;
public int getNbPlacesDisponibles(Connection c) throws Exception;
public boolean estOuverte();
public boolean estFuture();
public double getRecette(Connection c) throws Exception;
```

**Contrôles détaillés** :

*   `controlerHoraire()` : `heureDebut` et `heureFin` au format `HH:mm`,  
    `heureDebut < heureFin`, `daty` non nulle.
*   `controlerSalle(c)` :
    *   la salle existe et `etat == 1` ;
    *   `nbPlaces <= salle.capacite` ;
    *   aucune autre projection non annulée de la même salle, le même jour,  
        ne chevauche l'intervalle `[heureDebut, heureFin[`.
*   `controlerDroitDiffusion(c)` :
    *   le film existe et est actif ;
    *   si `idAchatDroitDetail` est null, rechercher un détail actif pour  
        `(idFilm, daty)` ;
    *   le détail doit être actif, couvrir la date, et avoir un quota restant ;
    *   le détail doit appartenir à un achat validé.
*   `controlerTarifs()` :
    *   `getFille()` non vide ;
    *   chaque tarif a une catégorie, un rang (ou `'*'`) et un prix `>= 0` ;
    *   pas de doublon `(idCategoriePlace, rang)` ;
    *   chaque rang référencé existe dans la salle de la projection ;
    *   pour chaque catégorie, la somme des quotas (si > 0) des lignes  
        `RANG = '*'` ne dépasse pas le nombre de places de cette catégorie ;  
        à défaut de ligne générale, la somme des quotas des lignes de rang ne  
        dépasse pas ce nombre.
*   `getNbPlacesVendues(c)` : compte les `Billet` avec `etat == 11` et  
    `statut IN (1,2)` pour cette projection.
*   `getNbPlacesReservees(c)` : compte les `ReservationDetail` des réservations  
    `etat IN (1,11)` et `statut IN (1,2)`.
*   `getNbPlacesDisponibles(c)` : `nbPlaces - vendues - réservées`.
*   `estOuverte()` : `etat == 11 && statut == 2`.
*   `estFuture()` : `daty + heureDebut >= maintenant` (la séance n'a pas encore commencé).
*   `getRecette(c)` : somme des `Billet.prix` vendus non annulés.

#### 6.7.2 `cinema.projection.ProjectionTarif`

*   **Table** : `CINEMA_PROJECTIONTARIF`
*   **Héritage** : `bean.ClassFille`
*   **Mère** : `cinema.projection.Projection`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `idMere` | `String` | `getIdMere()` / `setIdMere(String)` |
| `idCategoriePlace` | `String` | `getIdCategoriePlace()` / `setIdCategoriePlace(String)` |
| `rang` | `String` | `getRang()` / `setRang(String)` |
| `prix` | `double` | `getPrix()` / `setPrix(double)` |
| `quota` | `int` | `getQuota()` / `setQuota(int)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public ProjectionTarif() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseMere();
public String getLiaisonMere();
public void controlerPrix() throws Exception;
public boolean estActive();
public boolean estTarifGeneral();
public boolean couvreRang(String rang);
public int getQuotaRestant(Connection c) throws Exception;
```

*   `controlerPrix()` refuse `prix < 0` et `quota < 0`.
*   `rang` vaut `ConstanteCinema.RANG_TOUS` (`"*"`) pour un tarif valable sur  
    tous les rangs ; le constructeur l'initialise à `RANG_TOUS`, et toute  
    autre valeur doit correspondre à un `Place.rang` de la salle.
*   `estTarifGeneral()` : `rang == null || rang.isEmpty() || "*".equals(rang)`.
*   `couvreRang(rangPlace)` : `estTarifGeneral() || rang.equals(rangPlace)`.
*   `getQuotaRestant(c)` : `quota == 0 ? Integer.MAX_VALUE : quota - places vendues/réservées de cette catégorie et de ce rang` (une place est comptée  
    sur la ligne la plus spécifique qui la couvre).

#### 6.7.3 `cinema.projection.ProjectionLib`

*   **Table** : `CINEMA_PROJECTION_LIB`
*   **Héritage** : `cinema.projection.Projection`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `idFilmLib` | `String` | `getIdFilmLib()` / `setIdFilmLib(String)` |
| `idGenreLib` | `String` | `getIdGenreLib()` / `setIdGenreLib(String)` |
| `idSalleLib` | `String` | `getIdSalleLib()` / `setIdSalleLib(String)` |
| `idAchatDroitLib` | `String` | `getIdAchatDroitLib()` / `setIdAchatDroitLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |
| `statutLib` | `String` | `getStatutLib()` / `setStatutLib(String)` |
| `nbPlacesVendues` | `int` | `getNbPlacesVendues()` / `setNbPlacesVendues(int)` |
| `nbPlacesReservees` | `int` | `getNbPlacesReservees()` / `setNbPlacesReservees(int)` |
| `nbPlacesDisponibles` | `int` | `getNbPlacesDisponibles()` / `setNbPlacesDisponibles(int)` |
| `recette` | `double` | `getRecette()` / `setRecette(double)` |

```java
public ProjectionLib() throws Exception;
```

#### 6.7.4 `cinema.projection.ProjectionTarifLib`

*   **Table** : `CINEMA_PROJECTIONTARIF_LIB`
*   **Héritage** : `cinema.projection.ProjectionTarif`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `idCategoriePlaceLib` | `String` | `getIdCategoriePlaceLib()` / `setIdCategoriePlaceLib(String)` |
| `rangLib` | `String` | `getRangLib()` / `setRangLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |
| `quotaRestant` | `int` | `getQuotaRestant()` / `setQuotaRestant(int)` |

```java
public ProjectionTarifLib() throws Exception;
```

### 6.8 Réservation

#### 6.8.1 `cinema.reservation.Reservation`

*   **Table** : `CINEMA_RESERVATION`
*   **Héritage** : `bean.ClassMere`
*   **Fille** : `cinema.reservation.ReservationDetail`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `daty` | `java.sql.Date` | `getDaty()` / `setDaty(java.sql.Date)` |
| `idClient` | `String` | `getIdClient()` / `setIdClient(String)` |
| `idProjection` | `String` | `getIdProjection()` / `setIdProjection(String)` |
| `dateExpiration` | `java.sql.Date` | `getDateExpiration()` / `setDateExpiration(java.sql.Date)` |
| `montantAcompte` | `double` | `getMontantAcompte()` / `setMontantAcompte(double)` |
| `statut` | `int` | `getStatut()` / `setStatut(int)` |
| `remarque` | `String` | `getRemarque()` / `setRemarque(String)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public Reservation() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseFille();
public String getLiaisonFille();
public ClassMAPTable createObject(String u, Connection c) throws Exception;
public Object validerObject(String u, Connection c) throws Exception;
public Object annulerObject(String u, Connection c) throws Exception;
public void controlerProjection(Connection c) throws Exception;
public void controlerPlaces(Connection c) throws Exception;
public void controlerExpiration() throws Exception;
public boolean estExpiree();
public boolean estActive();
public double getMontantTotal();
public double getResteAPayer();
public int getNbPlaces();
```

**Contrôles** :

*   `controlerProjection(c)` : la projection existe, est ouverte  
    (`etat == 11 && statut == 2`) et est future.
*   `controlerPlaces(c)` :
    *   chaque détail référence une place active de la salle de la projection ;
    *   la place n'apparaît pas dans `CINEMA_PLACE_OCCUPEE` pour cette projection ;
    *   la catégorie de la place correspond au tarif de la projection ;
    *   le prix est repris du tarif `(catégorie, rang)` (ou du tarif général de  
        la catégorie, ou du prix par défaut de la catégorie).
*   `controlerExpiration()` : `dateExpiration` non nulle et postérieure à `daty`.
*   `estExpiree()` : `dateExpiration < now`.
*   `estActive()` : `etat IN (1,11) && statut IN (1,2)`.
*   `getMontantTotal()` : somme des `prix` des détails.
*   `getResteAPayer()` : `montantTotal - montantAcompte`.
*   `getNbPlaces()` : nombre de détails actifs.

#### 6.8.2 `cinema.reservation.ReservationDetail`

*   **Table** : `CINEMA_RESERVATIONDETAIL`
*   **Héritage** : `bean.ClassFille`
*   **Mère** : `cinema.reservation.Reservation`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `idMere` | `String` | `getIdMere()` / `setIdMere(String)` |
| `idPlace` | `String` | `getIdPlace()` / `setIdPlace(String)` |
| `idCategoriePlace` | `String` | `getIdCategoriePlace()` / `setIdCategoriePlace(String)` |
| `prix` | `double` | `getPrix()` / `setPrix(double)` |
| `idBillet` | `String` | `getIdBillet()` / `setIdBillet(String)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public ReservationDetail() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseMere();
public String getLiaisonMere();
public void controlerPlace(Connection c) throws Exception;
public boolean estConverti();
public void marquerConverti(String idBillet) throws Exception;
```

*   `controlerPlace(c)` vérifie que la place existe, est active et appartient à  
    la salle de la projection.
*   `estConverti()` : `idBillet != null && !idBillet.isEmpty()`.
*   `marquerConverti(idBillet)` affecte `idBillet` et passe `etat` à 9.

#### 6.8.3 `cinema.reservation.ReservationLib`

*   **Table** : `CINEMA_RESERVATION_LIB`
*   **Héritage** : `cinema.reservation.Reservation`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `idClientLib` | `String` | `getIdClientLib()` / `setIdClientLib(String)` |
| `idProjectionLib` | `String` | `getIdProjectionLib()` / `setIdProjectionLib(String)` |
| `idFilmLib` | `String` | `getIdFilmLib()` / `setIdFilmLib(String)` |
| `idSalleLib` | `String` | `getIdSalleLib()` / `setIdSalleLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |
| `statutLib` | `String` | `getStatutLib()` / `setStatutLib(String)` |
| `nbPlacesLib` | `int` | `getNbPlacesLib()` / `setNbPlacesLib(int)` |
| `montantTotalLib` | `double` | `getMontantTotalLib()` / `setMontantTotalLib(double)` |
| `resteAPayerLib` | `double` | `getResteAPayerLib()` / `setResteAPayerLib(double)` |

```java
public ReservationLib() throws Exception;
```

> Les champs `montantTotalLib` et `resteAPayerLib` sont suffixés `Lib` pour  
> éviter le conflit avec les méthodes calculées `getMontantTotal()` et  
> `getResteAPayer()` de `Reservation`.

#### 6.8.4 `cinema.reservation.ReservationDetailLib`

*   **Table** : `CINEMA_RESERVATIONDETAIL_LIB`
*   **Héritage** : `cinema.reservation.ReservationDetail`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `idPlaceLib` | `String` | `getIdPlaceLib()` / `setIdPlaceLib(String)` |
| `idCategoriePlaceLib` | `String` | `getIdCategoriePlaceLib()` / `setIdCategoriePlaceLib(String)` |
| `idBilletLib` | `String` | `getIdBilletLib()` / `setIdBilletLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |

```java
public ReservationDetailLib() throws Exception;
```

---

### 6.9 Achat de billets

#### 6.9.1 `cinema.billet.AchatBillet`

*   **Table** : `CINEMA_ACHATBILLET`
*   **Héritage** : `bean.ClassMere`
*   **Fille** : `cinema.billet.Billet`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `daty` | `java.sql.Date` | `getDaty()` / `setDaty(java.sql.Date)` |
| `idClient` | `String` | `getIdClient()` / `setIdClient(String)` |
| `idProjection` | `String` | `getIdProjection()` / `setIdProjection(String)` |
| `idReservation` | `String` | `getIdReservation()` / `setIdReservation(String)` |
| `montantTotal` | `double` | `getMontantTotal()` / `setMontantTotal(double)` |
| `montantPaye` | `double` | `getMontantPaye()` / `setMontantPaye(double)` |
| `monnaieRendue` | `double` | `getMonnaieRendue()` / `setMonnaieRendue(double)` |
| `modepaiement` | `String` | `getModepaiement()` / `setModepaiement(String)` |
| `idVente` | `String` | `getIdVente()` / `setIdVente(String)` |
| `idMouvementCaisse` | `String` | `getIdMouvementCaisse()` / `setIdMouvementCaisse(String)` |
| `remarque` | `String` | `getRemarque()` / `setRemarque(String)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public AchatBillet() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseFille();
public String getLiaisonFille();
public ClassMAPTable createObject(String u, Connection c) throws Exception;
public Object validerObject(String u, Connection c) throws Exception;
public Object annulerObject(String u, Connection c) throws Exception;
public void controlerProjection(Connection c) throws Exception;
public void controlerPlaces(Connection c) throws Exception;
public void controlerPaiement() throws Exception;
public double getMontantTotalBillets();
public int getNbBillets();
public String getNumeroRecu();
```

**Contrôles** :

*   `controlerProjection(c)` : projection ouverte, non clôturée, future.
*   `controlerPlaces(c)` :
    *   chaque billet référence une place active de la salle ;
    *   la place est libre dans `CINEMA_PLACE_OCCUPEE`, sauf si elle appartient  
        à la réservation `idReservation` en cours de conversion ;
    *   le prix est cohérent avec le tarif de la projection pour la catégorie  
        et le rang de la place.
*   `controlerPaiement()` : `montantPaye >= montantTotal`, `montantTotal >= 0`.
*   `getMontantTotalBillets()` : somme des prix des billets.
*   `getNbBillets()` : nombre de billets actifs.
*   `getNumeroRecu()` : numéro lisible du reçu (ex. `REC-<idAchat>`).

#### 6.9.2 `cinema.billet.Billet`

*   **Table** : `CINEMA_BILLET`
*   **Héritage** : `bean.ClassFille`
*   **Mère** : `cinema.billet.AchatBillet`, liaison `idMere`

| Champ | Type | Getter / Setter |
| --- | --- | --- |
| `id` | `String` | `getId()` / `setId(String)` |
| `idMere` | `String` | `getIdMere()` / `setIdMere(String)` |
| `idPlace` | `String` | `getIdPlace()` / `setIdPlace(String)` |
| `idCategoriePlace` | `String` | `getIdCategoriePlace()` / `setIdCategoriePlace(String)` |
| `prix` | `double` | `getPrix()` / `setPrix(double)` |
| `numero` | `String` | `getNumero()` / `setNumero(String)` |
| `codeBarre` | `String` | `getCodeBarre()` / `setCodeBarre(String)` |
| `datyUtilisation` | `java.sql.Date` | `getDatyUtilisation()` / `setDatyUtilisation(java.sql.Date)` |
| `statut` | `int` | `getStatut()` / `setStatut(int)` |
| `etat` | `int` | `getEtat()` / `setEtat(int)` |

```java
public Billet() throws Exception;
public void construirePK(Connection c) throws Exception;
public String getTuppleID();
public String getAttributIDName();
public String getNomClasseMere();
public String getLiaisonMere();
public void controlerPlace(Connection c) throws Exception;
public boolean estValide();
public boolean estUtilise();
public void marquerUtilise(Connection c) throws Exception;
public String getLibellePlace(Connection c) throws Exception;
public String getCodeQr();
```

*   `estValide()` : `etat == 11 && statut == 1`.
*   `estUtilise()` : `statut == 2`.
*   `marquerUtilise(c)` : si `!estValide()` lever une exception ; sinon  
    `statut = 2`, `datyUtilisation = now`, `updateObject`.
*   `getLibellePlace(c)` : retourne `"Salle X - Rang Y - Place Z"`.
*   `getCodeQr()` : retourne le contenu texte encodé dans le QR  
    (par défaut `CODEBARRE`).

#### 6.9.3 `cinema.billet.AchatBilletLib`

*   **Table** : `CINEMA_ACHATBILLET_LIB`
*   **Héritage** : `cinema.billet.AchatBillet`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `idClientLib` | `String` | `getIdClientLib()` / `setIdClientLib(String)` |
| `idProjectionLib` | `String` | `getIdProjectionLib()` / `setIdProjectionLib(String)` |
| `idFilmLib` | `String` | `getIdFilmLib()` / `setIdFilmLib(String)` |
| `idSalleLib` | `String` | `getIdSalleLib()` / `setIdSalleLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |
| `nbBilletsLib` | `int` | `getNbBilletsLib()` / `setNbBilletsLib(int)` |

```java
public AchatBilletLib() throws Exception;
```

#### 6.9.4 `cinema.billet.BilletLib`

*   **Table** : `CINEMA_BILLET_LIB`
*   **Héritage** : `cinema.billet.Billet`

| Champ supplémentaire | Type | Getter / Setter |
| --- | --- | --- |
| `idPlaceLib` | `String` | `getIdPlaceLib()` / `setIdPlaceLib(String)` |
| `idCategoriePlaceLib` | `String` | `getIdCategoriePlaceLib()` / `setIdCategoriePlaceLib(String)` |
| `idAchatBilletLib` | `String` | `getIdAchatBilletLib()` / `setIdAchatBilletLib(String)` |
| `idProjectionLib` | `String` | `getIdProjectionLib()` / `setIdProjectionLib(String)` |
| `idFilmLib` | `String` | `getIdFilmLib()` / `setIdFilmLib(String)` |
| `statutLib` | `String` | `getStatutLib()` / `setStatutLib(String)` |
| `etatLib` | `String` | `getEtatLib()` / `setEtatLib(String)` |

```java
public BilletLib() throws Exception;
```

### 6.10 Récapitulatif des objets et de leurs méthodes propres

| Objet | Méthodes propres à implémenter |
| --- | --- |
| `Genre` | `construirePK` |
| `Distributeur` | `construirePK`, `getTuppleID`, `getAttributIDName` |
| `CategoriePlace` | `construirePK`, `getLibelle`, `controlerPrix` |
| `Salle` | `construirePK`, `controlerCapacite`, `getNbPlaces`, `getPlacesActives`, `getPlace` |
| `Place` | `construirePK`, `getLibelle`, `estActive` |
| `Film` | `construirePK`, `getLibelle`, `getDureeHeureMinute`, `controlerDuree`, `rechercher` |
| `AchatDroitDiffusion` | `construirePK`, `controlerDates`, `controlerDetail`, `getMontantDetails`, `getNbFilms`, `estActif`, `couvreFilm`, `getDetailPourFilm`, `getNbProjectionsUtilisees` |
| `AchatDroitDiffusionDetail` | `construirePK`, `controlerDates`, `estActif`, `couvre`, `getNbProjectionsUtilisees`, `getNbProjectionsRestantes`, `controlerQuota`, `getMontantTTC` |
| `Projection` | `construirePK`, `controlerHoraire`, `controlerSalle`, `controlerDroitDiffusion`, `controlerTarifs`, `getNbPlacesVendues`, `getNbPlacesReservees`, `getNbPlacesDisponibles`, `estOuverte`, `estFuture`, `getRecette` |
| `ProjectionTarif` | `construirePK`, `controlerPrix`, `estActive`, `estTarifGeneral`, `couvreRang`, `getQuotaRestant` |
| `Reservation` | `construirePK`, `controlerProjection`, `controlerPlaces`, `controlerExpiration`, `estExpiree`, `estActive`, `getMontantTotal`, `getResteAPayer`, `getNbPlaces` |
| `ReservationDetail` | `construirePK`, `controlerPlace`, `estConverti`, `marquerConverti` |
| `AchatBillet` | `construirePK`, `controlerProjection`, `controlerPlaces`, `controlerPaiement`, `getMontantTotalBillets`, `getNbBillets`, `getNumeroRecu` |
| `Billet` | `construirePK`, `controlerPlace`, `estValide`, `estUtilise`, `marquerUtilise`, `getLibellePlace`, `getCodeQr` |

---

## 7\. Couche service

Les services suivent le modèle de `ferme.vente.VenteFermeService` :

*   méthodes `static` ;
*   deux surcharges : une avec `Connection` (transaction gérée par l'appelant)  
    et une sans `Connection` (le service ouvre, commit ou rollback, ferme) ;
*   classes internes `Ligne…` pour les entrées et `Resultat` pour les sorties ;
*   validation métier avant `createObject`, puis `validerObject` si nécessaire.

> Les services doivent aussi passer les lignes de détail à `ETAT = 11` lors de  
> la validation de l'en-tête (ou appeler `validerObjectFille`). Les vues  
> `CINEMA_PLACE_OCCUPEE` et `CINEMA_BILLET_LIB` filtrent sur cet état.

### 7.1 `cinema.diffusion.AchatDroitDiffusionService`

```java
public class AchatDroitDiffusionService {

    public static class LigneDroit {
        public String idFilm;
        public java.sql.Date dateDebut;
        public java.sql.Date dateFin;
        public int nbMaxProjection;
        public double montant;
        public double tva;

        public LigneDroit();
        public LigneDroit(String idFilm, java.sql.Date dateDebut,
                          java.sql.Date dateFin, int nbMaxProjection,
                          double montant, double tva);
    }

    public static class Resultat {
        public String idAchat;
        public String reference;
        public double montantTotal;
        public java.util.List<String> idDetails;

        public Resultat();
        public String resume();
    }

    public static Resultat creerBrouillon(
            String u, String idDistributeur, java.sql.Date daty,
            String idDevise, double tauxDeChange, String territoire,
            int exclusivite, String modepaiement, String reference,
            String remarque, java.util.List<LigneDroit> lignes) throws Exception;

    public static Resultat creerBrouillon(
            Connection c, String u, String idDistributeur, java.sql.Date daty,
            String idDevise, double tauxDeChange, String territoire,
            int exclusivite, String modepaiement, String reference,
            String remarque, java.util.List<LigneDroit> lignes) throws Exception;

    public static Resultat acheter(
            String u, String idDistributeur, java.sql.Date daty,
            String idDevise, double tauxDeChange, String territoire,
            int exclusivite, String modepaiement, String reference,
            String remarque, java.util.List<LigneDroit> lignes) throws Exception;

    public static Resultat acheter(
            Connection c, String u, String idDistributeur, java.sql.Date daty,
            String idDevise, double tauxDeChange, String territoire,
            int exclusivite, String modepaiement, String reference,
            String remarque, java.util.List<LigneDroit> lignes) throws Exception;

    public static void annuler(String u, String idAchat) throws Exception;
    public static void annuler(Connection c, String u, String idAchat) throws Exception;

    public static AchatDroitDiffusionDetail getDroitActif(
            String idFilm, java.sql.Date date, Connection c) throws Exception;

    public static AchatDroitDiffusionDetail[] getDroitsActifs(Connection c) throws Exception;

    public static boolean estCouvert(
            String idFilm, java.sql.Date date, Connection c) throws Exception;

    public static double calculerMontantTotal(
            java.util.List<LigneDroit> lignes) throws Exception;

    public static void controlerLignes(
            java.util.List<LigneDroit> lignes) throws Exception;
}
```

**Comportement** :

*   `creerBrouillon` crée l'en-tête (`ETAT = 1`) et les détails.
*   `acheter` appelle `creerBrouillon` puis `validerObject` (`ETAT = 11`).
*   `getDroitActif` recherche le détail actif correspondant au film et à la date,  
    en privilégiant le plus récent.
*   `estCouvert` retourne `true` si un droit actif existe.
*   `annuler` vérifie qu'aucune projection active n'utilise l'achat.

### 7.2 `cinema.projection.ProjectionService`

```java
public class ProjectionService {

    public static class LigneTarif {
        public String idCategoriePlace;
        public String rang;
        public double prix;
        public int quota;

        public LigneTarif();
        public LigneTarif(String idCategoriePlace, double prix, int quota);
        public LigneTarif(String idCategoriePlace, String rang,
                          double prix, int quota);
    }

    public static class Resultat {
        public String idProjection;
        public int nbPlaces;
        public double recette;

        public Resultat();
    }

    public static Resultat preparerProjection(
            String u, String idFilm, String idSalle, java.sql.Date daty,
            String heureDebut, String heureFin, String idAchatDroitDetail,
            double prixBase, java.util.List<LigneTarif> tarifs,
            String remarque) throws Exception;

    public static Resultat preparerProjection(
            Connection c, String u, String idFilm, String idSalle, java.sql.Date daty,
            String heureDebut, String heureFin, String idAchatDroitDetail,
            double prixBase, java.util.List<LigneTarif> tarifs,
            String remarque) throws Exception;

    public static void ouvrirVente(String u, String idProjection) throws Exception;
    public static void ouvrirVente(Connection c, String u, String idProjection) throws Exception;

    public static void cloturerProjection(String u, String idProjection) throws Exception;
    public static void cloturerProjection(Connection c, String u, String idProjection) throws Exception;

    public static void annulerProjection(String u, String idProjection) throws Exception;
    public static void annulerProjection(Connection c, String u, String idProjection) throws Exception;

    public static Projection[] getProjectionsDuJour(
            java.sql.Date daty, Connection c) throws Exception;

    public static Projection[] getProjectionsOuvertes(Connection c) throws Exception;

    public static int getPlacesDisponibles(
            String idProjection, Connection c) throws Exception;

    public static boolean chevauche(
            String idSalle, java.sql.Date daty, String heureDebut, String heureFin,
            String idProjectionExclue, Connection c) throws Exception;

    public static double getPrix(
            String idProjection, String idCategoriePlace, Connection c) throws Exception;

    public static double getPrix(
            String idProjection, String idPlace, Connection c) throws Exception;

    public static ProjectionTarif getTarif(
            String idProjection, String idCategoriePlace, String rang,
            Connection c) throws Exception;
}
```

**Comportement** :

*   `preparerProjection` :
    1.  charge le film, la salle et le droit ;
    2.  vérifie le droit actif et le quota ;
    3.  vérifie l'absence de chevauchement ;
    4.  crée la projection (`ETAT = 1`, `STATUT = 1`) ;
    5.  crée les tarifs (catégorie + rang) ;
    6.  retourne l'identifiant et le nombre de places.
*   `ouvrirVente` passe `ETAT = 11` et `STATUT = 2`.
*   `cloturerProjection` passe `ETAT = 9` et `STATUT = 3` ; refuse si des  
    réservations actives existent encore (ou les expire d'abord).
*   `annulerProjection` passe `ETAT = 0`, `STATUT = 0` ; refuse si des billets  
    ont déjà été vendus (ou exige un remboursement préalable).
*   `getPrix(idProjection, idCategoriePlace, c)` cherche le tarif de la  
    catégorie pour tous les rangs (`RANG = '*'`) ; à défaut, retourne  
    `prixBase`, puis `CategoriePlace.prixDefaut`.
*   `getPrix(idProjection, idPlace, c)` charge la place pour connaître sa  
    catégorie et son rang, puis applique l'ordre de résolution :  
    `(catégorie, rang)` → `(catégorie, '*')` → `prixBase` →  
    `CategoriePlace.prixDefaut`. C'est cette surcharge que doivent utiliser  
    `ReservationService.reserver` et `AchatBilletService.acheter`.
*   `getTarif(idProjection, idCategoriePlace, rang, c)` retourne la ligne la  
    plus spécifique (`rang` exact puis `'*'`), ou `null`.
*   `LigneTarif(idCategoriePlace, prix, quota)` laisse `rang = RANG_TOUS` ;  
    utiliser le constructeur à 4 arguments pour un tarif propre à un rang.

### 7.3 `cinema.reservation.ReservationService`

```java
public class ReservationService {

    public static class LigneReservation {
        public String idPlace;
        public String idCategoriePlace;

        public LigneReservation();
        public LigneReservation(String idPlace, String idCategoriePlace);
    }

    public static class Resultat {
        public String idReservation;
        public double montantTotal;
        public double acompte;
        public java.sql.Date dateExpiration;
        public java.util.List<String> idDetails;

        public Resultat();
    }

    public static Resultat reserver(
            String u, String idClient, String idProjection,
            java.util.List<LigneReservation> places, double acompte,
            java.sql.Date dateExpiration, String remarque) throws Exception;

    public static Resultat reserver(
            Connection c, String u, String idClient, String idProjection,
            java.util.List<LigneReservation> places, double acompte,
            java.sql.Date dateExpiration, String remarque) throws Exception;

    public static void confirmer(String u, String idReservation) throws Exception;
    public static void confirmer(Connection c, String u, String idReservation) throws Exception;

    public static void annuler(String u, String idReservation) throws Exception;
    public static void annuler(Connection c, String u, String idReservation) throws Exception;

    public static int expirerReservations(Connection c) throws Exception;

    public static AchatBilletService.Resultat convertirEnBillet(
            String u, String idReservation, String modepaiement,
            String idCaisse) throws Exception;

    public static AchatBilletService.Resultat convertirEnBillet(
            Connection c, String u, String idReservation, String modepaiement,
            String idCaisse) throws Exception;

    public static boolean placeDisponible(
            String idProjection, String idPlace, Connection c) throws Exception;

    public static Reservation[] getReservationsActives(
            String idClient, Connection c) throws Exception;

    public static Reservation[] getReservationsAExpirer(Connection c) throws Exception;
}
```

**Comportement** :

*   `reserver` :
    1.  vérifie le client et la projection ouverte ;
    2.  vérifie chaque place dans `CINEMA_PLACE_OCCUPEE` ;
    3.  calcule le prix depuis `ProjectionTarif` pour la catégorie et le rang de  
        chaque place ;
    4.  crée la réservation (`ETAT = 1`, `STATUT = 1`) et les détails ;
    5.  si `dateExpiration` est null, applique `now + DUREE_RESERVATION_MINUTES`.
*   `confirmer` passe `ETAT = 11`, `STATUT = 2`.
*   `annuler` passe `ETAT = 0`, `STATUT = 0` et libère les places.
*   `expirerReservations` passe les réservations échues à `STATUT = 4`,  
    `ETAT = 9`, et désactive les détails.
*   `convertirEnBillet` appelle `AchatBilletService.acheter` avec les places de  
    la réservation, puis marque chaque détail `idBillet` et passe la réservation  
    à `STATUT = 3`, `ETAT = 9`.

### 7.4 `cinema.billet.AchatBilletService`

```java
public class AchatBilletService {

    public static class LigneBillet {
        public String idPlace;
        public String idCategoriePlace;
        public double prix;

        public LigneBillet();
        public LigneBillet(String idPlace, String idCategoriePlace, double prix);
    }

    public static class Resultat {
        public String idAchat;
        public String idVente;
        public double montantTotal;
        public int nbBillets;
        public java.util.List<String> idBillets;

        public Resultat();
        public String resume();
    }

    public static Resultat acheter(
            String u, String idClient, String idProjection,
            java.util.List<LigneBillet> billets, String modepaiement,
            String idCaisse, String remarque) throws Exception;

    public static Resultat acheter(
            String u, String idClient, String idProjection, String idReservation,
            java.util.List<LigneBillet> billets, String modepaiement,
            String idCaisse, String remarque) throws Exception;

    public static Resultat acheter(
            Connection c, String u, String idClient, String idProjection,
            String idReservation, java.util.List<LigneBillet> billets,
            String modepaiement, String idCaisse, String remarque) throws Exception;

    public static void annuler(String u, String idAchat) throws Exception;
    public static void annuler(Connection c, String u, String idAchat) throws Exception;

    public static Billet validerEntree(String codeBarre, Connection c) throws Exception;
    public static Billet validerEntree(String codeBarre, String u, Connection c) throws Exception;

    public static Billet[] getBillets(String idAchat, Connection c) throws Exception;

    public static double getRecette(String idProjection, Connection c) throws Exception;

    public static String genererCodeBarre(String idBillet) throws Exception;
    public static String getCodeBarre(String idBillet, Connection c) throws Exception;

    public static void controlerPlace(
            String idProjection, String idPlace, Connection c) throws Exception;
}
```

**Comportement** :

*   `acheter` :
    1.  vérifie la projection ouverte et les places ;
    2.  calcule le montant total à partir du tarif `(catégorie, rang)` de  
        chaque place ;
    3.  crée l'achat (`ETAT = 1`) et les billets (`STATUT = 1`) ;
    4.  contrôle le paiement ;
    5.  crée éventuellement le mouvement de caisse et la facture `VENTE` ;
    6.  valide l'achat (`ETAT = 11`).
*   `annuler` passe l'achat et les billets à `ETAT = 0` ; les places sont  
    libérées automatiquement par la vue `CINEMA_PLACE_OCCUPEE`.
*   `validerEntree` recherche le billet par `CODEBARRE`, vérifie  
    `ETAT = 11 && STATUT = 1`, vérifie la projection et la date, puis appelle  
    `marquerUtilise`.
*   `genererCodeBarre` retourne `PREFIXE_CODE_BARRE + "-" + idBillet`.
*   `getRecette` somme les billets vendus non annulés de la projection.

### 7.5 Service de statistiques (optionnel)

```java
public class CinemaStatService {
    public static class StatProjection {
        public String idProjection;
        public String film;
        public String salle;
        public int nbBillets;
        public double recette;
        public int tauxRemplissage;
    }

    public static double getRecetteJour(java.sql.Date daty, Connection c) throws Exception;
    public static int getNbBilletsJour(java.sql.Date daty, Connection c) throws Exception;
    public static int getTauxRemplissage(String idProjection, Connection c) throws Exception;
    public static StatProjection[] getTopProjections(
            java.sql.Date debut, java.sql.Date fin, int limit, Connection c) throws Exception;
}
```

---

## 8\. Pages JSP et menus

### 8.1 Arborescence des pages

```
arbiochem-war/web/pages/cinema/
├── dashboard.jsp
├── configuration/
│   ├── genre-liste.jsp
│   ├── genre-saisie.jsp
│   ├── distributeur-liste.jsp
│   ├── distributeur-saisie.jsp
│   ├── categorieplace-liste.jsp
│   ├── categorieplace-saisie.jsp
│   ├── salle-liste.jsp
│   ├── salle-saisie.jsp
│   ├── salle-fiche.jsp
│   ├── place-liste.jsp
│   └── place-saisie.jsp
├── film/
│   ├── film-liste.jsp
│   ├── film-saisie.jsp
│   └── film-fiche.jsp
├── diffusion/
│   ├── achatdroit-liste.jsp
│   ├── achatdroit-saisie.jsp
│   └── achatdroit-fiche.jsp
├── projection/
│   ├── projection-liste.jsp
│   ├── projection-saisie.jsp
│   ├── projection-fiche.jsp
│   └── projection-planning.jsp
├── reservation/
│   ├── reservation-liste.jsp
│   ├── reservation-saisie.jsp
│   ├── reservation-fiche.jsp
│   └── reservation-plan.jsp
└── billet/
    ├── billet-vente.jsp
    ├── billet-liste.jsp
    ├── billet-fiche.jsp
    ├── billet-controle.jsp
    └── billet-recu.jsp
```

### 8.2 Rôle des pages

| Page | Rôle |
| --- | --- |
| `*-liste.jsp` | Liste avec recherche, filtres et actions (voir, modifier, annuler). |
| `*-saisie.jsp` | Formulaire de création / modification, avec lignes de détail. Pour une projection, chaque ligne de tarif porte la catégorie, le rang (ou « tous les rangs »), le prix et le quota. |
| `*-fiche.jsp` | Détail complet, boutons Valider / Annuler / Clôturer / Imprimer. |
| `projection-planning.jsp` | Planning jour/semaine par salle, avec taux de remplissage. |
| `reservation-plan.jsp` | Plan de salle interactif pour choisir les places. |
| `billet-vente.jsp` | Écran de caisse : choix projection, places, catégories, paiement. |
| `billet-controle.jsp` | Saisie ou scan du code-barres, résultat du contrôle. |
| `billet-recu.jsp` | Reçu et billets imprimables (un bloc par place). |

### 8.3 Menus `MENUDYNAMIQUE`

```
-- Menu racine Cinéma
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
SELECT 'MENDYN1792000000000001', 'Cinéma', 'film',
       'module.jsp?but=cinema/dashboard.jsp', 20, 1, NULL
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM MENUDYNAMIQUE WHERE ID = 'MENDYN1792000000000001');

-- Films
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
SELECT 'MENDYN1792000000000002', 'Films', 'video',
       'module.jsp?but=cinema/film/film-liste.jsp', 1, 2, 'MENDYN1792000000000001'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM MENUDYNAMIQUE WHERE ID = 'MENDYN1792000000000002');

-- Droits de diffusion
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
SELECT 'MENDYN1792000000000003', 'Droits de diffusion', 'key',
       'module.jsp?but=cinema/diffusion/achatdroit-liste.jsp', 2, 2, 'MENDYN1792000000000001'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM MENUDYNAMIQUE WHERE ID = 'MENDYN1792000000000003');

-- Projections
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
SELECT 'MENDYN1792000000000004', 'Projections', 'calendar',
       'module.jsp?but=cinema/projection/projection-liste.jsp', 3, 2, 'MENDYN1792000000000001'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM MENUDYNAMIQUE WHERE ID = 'MENDYN1792000000000004');

-- Réservations
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
SELECT 'MENDYN1792000000000005', 'Réservations', 'bookmark',
       'module.jsp?but=cinema/reservation/reservation-liste.jsp', 4, 2, 'MENDYN1792000000000001'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM MENUDYNAMIQUE WHERE ID = 'MENDYN1792000000000005');

-- Vente de billets
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
SELECT 'MENDYN1792000000000006', 'Vente de billets', 'shopping-cart',
       'module.jsp?but=cinema/billet/billet-vente.jsp', 5, 2, 'MENDYN1792000000000001'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM MENUDYNAMIQUE WHERE ID = 'MENDYN1792000000000006');

-- Contrôle des billets
INSERT INTO MENUDYNAMIQUE (ID, LIBELLE, ICONE, HREF, RANG, NIVEAU, ID_PERE)
SELECT 'MENDYN1792000000000007', 'Contrôle des billets', 'check',
       'module.jsp?but=cinema/billet/billet-controle.jsp', 6, 2, 'MENDYN1792000000000001'
  FROM DUAL
 WHERE NOT EXISTS (SELECT 1 FROM MENUDYNAMIQUE WHERE ID = 'MENDYN1792000000000007');

COMMIT;
```

> Adapter `ID_PERE` si le projet utilise un menu racine existant. Les menus  
> sont chargés à la connexion : se reconnecter pour les voir.

### 8.4 Rôles et permissions

| Rôle | Pages autorisées |
| --- | --- |
| `CINEMA_ADMIN` | Toutes les pages de configuration et de gestion. |
| `CINEMA_PROGRAMMATEUR` | Films, droits, projections. |
| `CINEMA_CAISSIER` | Réservations, vente de billets, reçus. |
| `CINEMA_CONTROLEUR` | Contrôle des billets uniquement. |
| `CINEMA_DAF` | Validation des droits, consultation des recettes. |

Les permissions sont à déclarer dans les tables de rôles existantes  
(`ROLE`, `USERROLE` ou équivalent) et à vérifier dans les JSP / servlets.

---

## 9\. Fichiers SQL de migration

Les fichiers respectent le hook `control/pre-commit` :  
`^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{2}_[0-9]{2}.*\.sql$`.

| Fichier | Contenu |
| --- | --- |
| `2026-11-12-09_00-cinema-configuration.sql` | Tables `CINEMA_GENRE`, `CINEMA_DISTRIBUTEUR`, `CINEMA_CATEGORIEPLACE`, `CINEMA_SALLE`, `CINEMA_PLACE`. |
| `2026-11-12-09_10-cinema-film-droit.sql` | Tables `CINEMA_FILM`, `CINEMA_ACHATDROIT`, `CINEMA_ACHATDROITDETAIL`. |
| `2026-11-12-09_20-cinema-projection.sql` | Tables `CINEMA_PROJECTION`, `CINEMA_PROJECTIONTARIF`. |
| `2026-11-12-09_30-cinema-reservation-billet.sql` | Tables `CINEMA_RESERVATION`, `CINEMA_RESERVATIONDETAIL`, `CINEMA_ACHATBILLET`, `CINEMA_BILLET`. |
| `2026-11-12-09_40-cinema-sequences.sql` | Séquences et fonctions `GETSEQ…`. |
| `2026-11-12-09_50-cinema-vues.sql` | Toutes les vues `*_LIB` + `CINEMA_PLACE_OCCUPEE`. |
| `2026-11-12-10_00-cinema-index.sql` | Index de performance. |
| `2026-11-12-10_10-cinema-menus.sql` | Entrées `MENUDYNAMIQUE`. |
| `2026-11-12-10_20-cinema-donnees-reference.sql` | Genres, catégories de place, salle de démonstration, client comptoir. |

**Ordre d'application** : configuration → film/droit → projection →  
réservation/billet → séquences → vues → index → menus → données de référence.

> Dans `2026-11-12-09_30-cinema-reservation-billet.sql`, créer les tables dans  
> l'ordre `CINEMA_RESERVATION`, `CINEMA_ACHATBILLET`, `CINEMA_BILLET`,  
> `CINEMA_RESERVATIONDETAIL`, puis ajouter la contrainte  
> `FK_CINEMA_RESDETAIL_BILLET (IDBILLET → CINEMA_BILLET.ID)` par `ALTER TABLE`.  
> Cela évite le cycle de références entre réservation, achat et billet.

> Les tables existantes `CLIENT`, `DEVISE`, `MODEPAIEMENT`, `CAISSE`,  
> `AS_BONDECOMMANDE`, `VENTE`, `MOUVEMENTCAISSE` ne sont pas recréées.

---

## 10\. Règles de gestion

**Droit de diffusion**

*   Un droit est défini par un film, une période et un territoire.
*   `DATEDEBUT <= DATEFIN`.
*   Un achat validé ne peut plus être modifié.
*   Un achat ne peut être annulé si une projection active l'utilise.
*   Le quota `NBMAXPROJECTION = 0` signifie « illimité ».

**Projection**

*   Une projection doit référencer un film, une salle et un droit actif.
*   Deux projections d'une même salle ne peuvent pas se chevaucher.
*   `NBPLACES <= CAPACITE` de la salle.
*   Au moins un tarif est obligatoire.
*   Un tarif est identifié par `(catégorie de place, rang)` ; `RANG = '*'`  
    couvre tous les rangs de la salle.
*   Le prix d'une place est résolu dans cet ordre :  
    `(catégorie, rang)` → `(catégorie, '*')` → `PRIXBASE` →  
    `CATEGORIEPLACE.PRIXDEFAUT`.
*   Le prix appliqué est figé dans `RESERVATIONDETAIL.PRIX` puis dans  
    `BILLET.PRIX` : une modification ultérieure des tarifs ne change pas les  
    ventes déjà enregistrées.
*   Une projection ouverte peut recevoir des réservations et des ventes.
*   Une projection clôturée ou annulée n'accepte plus de réservations ni de  
    ventes.
*   Une projection annulée avec des billets vendus exige un remboursement  
    préalable.

**Réservation**

*   Une place ne peut être réservée que si elle est libre pour la projection.
*   Une réservation bloque les places jusqu'à `DATEEXPIRATION`.
*   Une réservation expirée ou annulée libère les places.
*   Une réservation confirmée reste bloquante.
*   La conversion en billets conserve les places et crée un `AchatBillet`.

**Billet**

*   Une place ne peut être vendue qu'une fois par projection.
*   `MONTANTPAYE >= MONTANTTOTAL`.
*   Un billet vendu est `STATUT = 1`, `ETAT = 11`.
*   Un billet contrôlé passe à `STATUT = 2` et reçoit `DATYUTILISATION`.
*   Un billet annulé (`ETAT = 0`) ou déjà utilisé (`STATUT = 2`) est refusé  
    au contrôle.
*   Le code-barres est unique.

**Caisse et comptabilité**

*   Toute vente encaissée génère un mouvement de caisse.
*   La facturation `VENTE` est optionnelle ; si elle est activée, une facture  
    est créée avec une ligne par catégorie et par rang.
*   Les annulations génèrent un mouvement inverse ou un avoir.

**Sécurité**

*   Seuls les rôles autorisés peuvent valider un achat de droit.
*   Seuls les caissiers peuvent vendre des billets.
*   Seuls les contrôleurs peuvent valider une entrée.

---

## 11\. Intégration avec les modules existants

| Module existant | Utilisation |
| --- | --- |
| `client.Client` / table `CLIENT` | Client de la réservation et de l'achat de billets. |
| `DEVISE` | Devise de l'achat de droit. |
| `MODEPAIEMENT` | Mode de paiement des achats et des billets. |
| `CAISSE` / `MvtCaisse` | Encaissement et journal de caisse. |
| `vente.Vente` / `VenteDetails` | Facturation optionnelle des billets. |
| `faturefournisseur.As_BonDeCommande` | Raccordement optionnel de l'achat de droits. |
| `utilisateur` / rôles | Contrôle d'accès aux écrans. |
| `ferme.vente.VenteFermeService` | Modèle de service transactionnel à reproduire. |

**Points d'attention** :

*   `VenteArbiochem.validerObject` peut effectuer un commit interne : dans ce  
    cas, ne pas l'appeler au milieu d'une transaction cinema sans précaution.
*   Les services doivent toujours proposer une surcharge avec `Connection` pour  
    permettre l'enchaînement réservation → billets dans une seule transaction.
*   Les vues `*_LIB` doivent être recompilées après ajout de colonnes.

---

## 12\. Recette

### 12.1 Jeu de données minimal

1.  Créer un genre « Drame ».
2.  Créer un distributeur « Studio Demo ».
3.  Créer un film « Film Demo » (durée 120 min, genre Drame).
4.  Créer une salle « Salle 1 » (capacité 100) avec 10 places :
    *   rangs A et B : 6 places Standard ;
    *   rangs C et D : 4 places VIP.
5.  Créer les catégories « Standard » (prix 10 000) et « VIP » (prix 20 000).
6.  Créer un client « Client Test ».

### 12.2 Scénarios

| # | Scénario | Résultat attendu |
| --- | --- | --- |
| 1 | Acheter un droit pour « Film Demo » du 01/12/2026 au 31/12/2026, quota 20 | Achat validé, droit actif. |
| 2 | Préparer une projection le 10/12/2026 à 20:00 en Salle 1 | Projection créée, statut Préparée. |
| 3 | Ouvrir la vente | Statut Ouverte, 100 places disponibles. |
| 4 | Réserver 2 places Standard | Réservation En attente, 2 places bloquées. |
| 5 | Réserver à nouveau une des 2 places | Refus : place déjà occupée. |
| 6 | Confirmer la réservation | Statut Confirmée. |
| 7 | Convertir la réservation en billets | Achat validé, 2 billets Vendus. |
| 8 | Vendre 1 place VIP au comptoir | Achat validé, 1 billet Vendus. |
| 9 | Vendre la même place VIP | Refus : place déjà vendue. |
| 10 | Payer moins que le montant total | Refus : paiement insuffisant. |
| 11 | Contrôler un billet valide | Billet Utilisé. |
| 12 | Contrôler à nouveau le même billet | Refus : billet déjà utilisé. |
| 13 | Annuler un achat de billets | Billets annulés, places libérées. |
| 14 | Laisser expirer une réservation | Statut Expirée, places libérées. |
| 15 | Préparer une projection sans droit actif | Refus : droit absent. |
| 16 | Préparer deux projections qui se chevauchent | Refus : chevauchement. |
| 17 | Annuler un droit utilisé par une projection active | Refus. |
| 18 | Définir un tarif Standard rang A = 12 000 et un tarif Standard `*` = 10 000 | Rang A à 12 000, autres rangs Standard à 10 000. |
| 19 | Vendre une place rang A puis une place rang B de la même catégorie | Billets à 12 000 et 10 000, prix figés dans `BILLET.PRIX`. |
| 20 | Créer deux tarifs `(Standard, A)` sur la même projection | Refus : doublon `(catégorie, rang)`. |
| 21 | Modifier un tarif après une vente | Le billet déjà vendu conserve son prix d'origine. |

### 12.3 Vérifications techniques

*   `mvn` / build Ant du projet passe sans erreur.
*   Les JSP se chargent avec `admin/admin123` sur  
    `http://localhost:8080/arbiochem/`.
*   Les vues `*_LIB` retournent les colonnes attendues.
*   Les séquences génèrent des identifiants uniques.
*   Les menus apparaissent après reconnexion.

---

## 13\. Ordre de mise en œuvre

| Étape | Livrable | Dépendances |
| --- | --- | --- |
| 1 | SQL configuration + séquences | Aucune |
| 2 | `Genre`, `Distributeur`, `CategoriePlace`, `Salle`, `Place` + JSP | Étape 1 |
| 3 | `Film` + JSP | Étape 2 |
| 4 | `AchatDroitDiffusion` + détail + service + JSP | Étape 3 |
| 5 | `Projection` + tarifs + service + JSP | Étape 4 |
| 6 | `Reservation` + détail + service + JSP | Étape 5 |
| 7 | `AchatBillet` + `Billet` + service + JSP | Étape 6 |
| 8 | Vues `*_LIB`, `CINEMA_PLACE_OCCUPEE`, index | Étapes 1-7 |
| 9 | Menus, rôles, données de référence | Étape 8 |
| 10 | Recette complète | Étape 9 |

**Recommandation** : implémenter d'abord le couple  
`AchatDroitDiffusion` → `Projection`, puis `Reservation` → `AchatBillet`.  
Cela permet de tester le contrôle des droits et la disponibilité des places  
avant d'ajouter la complexité du paiement et du contrôle à l'entrée.

---

_Fin du document._