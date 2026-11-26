package cinema.reservation;

import cinema.configuration.Remise;
import cinema.utils.CinemaDb;
import cinema.utils.ConstanteCinema;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

/**
 * Calcul et application des remises sur une reservation.
 *
 * Les regles sont globales. Une seule regle est appliquee par reservation :
 * celle qui procure le montant total de remise le plus eleve. A montant egal,
 * la regle au seuil le plus eleve l'emporte (ordre de la requete), puis l'ID.
 */
public final class RemiseService {

    private RemiseService() {
    }

    /**
     * Applique la meilleure regle de remise aux lignes fournies et retourne le
     * montant total remise. Les lignes sont modifiees en place : leur prix
     * devient le prix net, et {@code idRemise} / {@code montantRemise} sont
     * renseignes.
     *
     * @param lignes lignes de reservation (prix deja resolus)
     * @param c      connexion ouverte
     * @return montant total remise (0 si aucune regle applicable)
     */
    public static double appliquer(ReservationDetail[] lignes, Connection c) throws Exception {
        if (lignes == null || lignes.length == 0) {
            return 0;
        }

        Remise[] regles = chargerRegles(c);
        if (regles.length == 0) {
            return 0;
        }

        Remise meilleure = null;
        List<Integer> meilleureSelection = null;
        double meilleurTotal = 0;

        for (int r = 0; r < regles.length; r++) {
            Remise regle = regles[r];

            int declencheuses = 0;
            for (int i = 0; i < lignes.length; i++) {
                if (estActive(lignes[i])
                        && memeCategorie(lignes[i], regle.getIdCategorieReservation())) {
                    declencheuses++;
                }
            }
            if (declencheuses < regle.getNombrePlace()) {
                continue;
            }

            // Places remisables, triees par prix decroissant.
            List<Integer> candidates = new ArrayList<Integer>();
            for (int i = 0; i < lignes.length; i++) {
                if (estActive(lignes[i])
                        && memeCategorie(lignes[i], regle.getIdCategorieRemise())) {
                    candidates.add(Integer.valueOf(i));
                }
            }
            trierParPrixDecroissant(candidates, lignes);
            int nb = Math.min(regle.getNombrePlaceRemise(), candidates.size());
            if (nb <= 0) {
                continue;
            }

            List<Integer> selection = new ArrayList<Integer>();
            double total = 0;
            for (int i = 0; i < nb; i++) {
                int index = candidates.get(i).intValue();
                selection.add(Integer.valueOf(index));
                total += calculerRemise(lignes[index].getPrix(), regle);
            }
            total = arrondir(total);

            if (total > meilleurTotal) {
                meilleurTotal = total;
                meilleure = regle;
                meilleureSelection = selection;
            }
        }

        if (meilleure == null || meilleurTotal <= 0) {
            return 0;
        }

        for (int i = 0; i < meilleureSelection.size(); i++) {
            int index = meilleureSelection.get(i).intValue();
            ReservationDetail ligne = lignes[index];
            double remise = calculerRemise(ligne.getPrix(), meilleure);
            ligne.setMontantRemise(remise);
            ligne.setIdRemise(meilleure.getId());
            ligne.setPrix(arrondir(ligne.getPrix() - remise));
        }
        return meilleurTotal;
    }

    /** Charge les regles actives, tries par seuil decroissant puis par ID. */
    public static Remise[] chargerRegles(Connection c) throws Exception {
        List<Remise> liste = new ArrayList<Remise>();
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            ps = c.prepareStatement(
                    "SELECT ID, IDCATEGORIERESERVATION, NOMBREPLACE, TYPEVALEUR, VALEUR,"
                    + " IDCATEGORIEREMISE, NOMBREPLACEREMISE, DESCE, ETAT"
                    + " FROM CINEMA_REMISE WHERE ETAT = 1"
                    + " ORDER BY NOMBREPLACE DESC, ID");
            rs = ps.executeQuery();
            while (rs.next()) {
                Remise r = new Remise();
                r.setId(rs.getString("ID"));
                r.setIdCategorieReservation(rs.getString("IDCATEGORIERESERVATION"));
                r.setNombrePlace(rs.getInt("NOMBREPLACE"));
                r.setTypeValeur(rs.getInt("TYPEVALEUR"));
                r.setValeur(rs.getDouble("VALEUR"));
                r.setIdCategorieRemise(rs.getString("IDCATEGORIEREMISE"));
                r.setNombrePlaceRemise(rs.getInt("NOMBREPLACEREMISE"));
                r.setDesce(rs.getString("DESCE"));
                r.setEtat(rs.getInt("ETAT"));
                liste.add(r);
            }
        } finally {
            CinemaDb.close(rs);
            CinemaDb.close(ps);
        }
        return liste.toArray(new Remise[liste.size()]);
    }

    /** Montant remise unitaire d'une place pour une regle donnee, plafonne au prix. */
    public static double calculerRemise(double prix, Remise regle) {
        if (prix <= 0) {
            return 0;
        }
        double remise;
        if (regle.getTypeValeur() == Remise.TYPE_MONTANT) {
            remise = regle.getValeur();
        } else {
            remise = prix * regle.getValeur() / 100.0;
        }
        if (remise < 0) {
            remise = 0;
        }
        if (remise > prix) {
            remise = prix;
        }
        return arrondir(remise);
    }

    private static void trierParPrixDecroissant(List<Integer> indexes,
            ReservationDetail[] lignes) {
        for (int i = 0; i < indexes.size(); i++) {
            for (int j = i + 1; j < indexes.size(); j++) {
                int a = indexes.get(i).intValue();
                int b = indexes.get(j).intValue();
                if (lignes[b].getPrix() > lignes[a].getPrix()) {
                    indexes.set(i, Integer.valueOf(b));
                    indexes.set(j, Integer.valueOf(a));
                }
            }
        }
    }

    private static boolean estActive(ReservationDetail ligne) {
        return ligne != null && ligne.getEtat() != ConstanteCinema.ETAT_ANNULE;
    }

    private static boolean memeCategorie(ReservationDetail ligne, String categorie) {
        return categorie != null && categorie.equals(ligne.getIdCategoriePlace());
    }

    private static double arrondir(double valeur) {
        return Math.round(valeur * 100.0) / 100.0;
    }
}
