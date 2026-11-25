package cinema.utils;

/**
 * Constantes metier du module Cinema.
 *
 * Les etats standards du framework restent utilises pour ETAT. Les statuts
 * metier fins (reservation en attente, billet utilise, ...) sont stockes dans
 * la colonne STATUT afin de ne pas detourner ETAT.
 */
public final class ConstanteCinema {

    private ConstanteCinema() {
    }

    // Etats standards du framework
    public static final int ETAT_ANNULE = 0;
    public static final int ETAT_CREER = 1;
    public static final int ETAT_CLOTURE = 9;
    public static final int ETAT_REJETE = 10;
    public static final int ETAT_VALIDER = 11;

    // Statuts projection
    public static final int STATUT_PROJECTION_ANNULEE = 0;
    public static final int STATUT_PROJECTION_PREPAREE = 1;
    public static final int STATUT_PROJECTION_OUVERTE = 2;
    public static final int STATUT_PROJECTION_CLOTUREE = 3;

    // Statuts reservation
    public static final int STATUT_RESERVATION_ANNULEE = 0;
    public static final int STATUT_RESERVATION_EN_ATTENTE = 1;
    public static final int STATUT_RESERVATION_CONFIRMEE = 2;
    public static final int STATUT_RESERVATION_CONVERTIE = 3;
    public static final int STATUT_RESERVATION_EXPIREE = 4;

    // Statuts billet
    public static final int STATUT_BILLET_ANNULE = 0;
    public static final int STATUT_BILLET_VENDU = 1;
    public static final int STATUT_BILLET_UTILISE = 2;

    // Parametres metier
    public static final int DUREE_RESERVATION_MINUTES = 30;
    public static final String RANG_TOUS = "*";
    public static final String PREFIXE_NUMERO_BILLET = "BIL";
    public static final String COMPTE_VENTE_BILLET = "70700002";
    public static final String JOURNAL_VENTE = "VENTE";

    /** Magasin utilise pour la facture VENTE generee par la caisse cinema. */
    public static final String IDMAGASIN_DEFAUT = "PNTVNT001";

    /** Code article generique utilise dans VENTE_DETAILS pour les billets. */
    public static final String ARTICLE_BILLET = "CINEMA_BILLET";

    /** Prefixe des numeros de facture cinema. */
    public static final String PREFIXE_FACTURE = "CIN-";

    /** Prefixes des cles generees pour VENTE / VENTE_DETAILS / MOUVEMENTCAISSE. */
    public static final String PREFIXE_VENTE = "VNT";
    public static final String PREFIXE_VENTE_DETAILS = "VTD";
    public static final String PREFIXE_MOUVEMENTCAISSE = "MTC";

    /** Longueur de la partie numerique des cles generees (cf. ClassMAPTable). */
    public static final int LONGUEUR_CLE = 6;

    public static String getStatutProjectionLib(int statut) {
        switch (statut) {
            case STATUT_PROJECTION_PREPAREE:
                return "Preparee";
            case STATUT_PROJECTION_OUVERTE:
                return "Ouverte";
            case STATUT_PROJECTION_CLOTUREE:
                return "Cloturee";
            case STATUT_PROJECTION_ANNULEE:
                return "Annulee";
            default:
                return "Inconnu";
        }
    }

    public static String getStatutReservationLib(int statut) {
        switch (statut) {
            case STATUT_RESERVATION_EN_ATTENTE:
                return "En attente";
            case STATUT_RESERVATION_CONFIRMEE:
                return "Confirmee";
            case STATUT_RESERVATION_CONVERTIE:
                return "Convertie";
            case STATUT_RESERVATION_EXPIREE:
                return "Expiree";
            case STATUT_RESERVATION_ANNULEE:
                return "Annulee";
            default:
                return "Inconnu";
        }
    }

    public static String getStatutBilletLib(int statut) {
        switch (statut) {
            case STATUT_BILLET_VENDU:
                return "Vendu";
            case STATUT_BILLET_UTILISE:
                return "Utilise";
            case STATUT_BILLET_ANNULE:
                return "Annule";
            default:
                return "Inconnu";
        }
    }

    public static String getEtatLib(int etat) {
        switch (etat) {
            case ETAT_ANNULE:
                return "Annule";
            case ETAT_CREER:
                return "Cree";
            case ETAT_CLOTURE:
                return "Cloture";
            case ETAT_REJETE:
                return "Rejete";
            case ETAT_VALIDER:
                return "Valide";
            default:
                return "Etat " + etat;
        }
    }
}
