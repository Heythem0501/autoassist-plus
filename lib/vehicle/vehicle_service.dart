import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vehicle_model.dart';

/// Service centralisé pour gérer les véhicules dans Firestore
///
/// Structure de la base de données :
/// users/
///   {userId}/
///     vehicle/
///       info  ← document unique contenant le véhicule de l'utilisateur
class VehicleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Identifiant Firestore du document véhicule ("info" = unique)
  static const String _vehicleDocId = 'info';

  /// Retourne la référence Firestore vers le document véhicule
  /// de l'utilisateur actuellement connecté
  DocumentReference<Map<String, dynamic>>? _getVehicleRef() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('vehicle')
        .doc(_vehicleDocId);
  }

  // ==========================================================================
  // LECTURE
  // ==========================================================================

  /// Récupère le véhicule de l'utilisateur connecté
  ///
  /// Retourne [null] si l'utilisateur n'a pas encore renseigné de véhicule.
  Future<Vehicle?> getVehicle() async {
    try {
      final ref = _getVehicleRef();
      if (ref == null) return null;

      final doc = await ref.get();
      if (!doc.exists || doc.data() == null) return null;

      return Vehicle.fromFirestore(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  /// Vérifie rapidement si l'utilisateur a déjà un véhicule enregistré
  Future<bool> hasVehicle() async {
    try {
      final ref = _getVehicleRef();
      if (ref == null) return false;

      final doc = await ref.get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Flux en temps réel du véhicule (pour les écrans réactifs)
  Stream<Vehicle?> getVehicleStream() {
    final ref = _getVehicleRef();
    if (ref == null) return Stream.value(null);

    return ref.snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Vehicle.fromFirestore(doc.data()!);
    });
  }

  // ==========================================================================
  // ÉCRITURE
  // ==========================================================================

  /// Enregistre ou met à jour le véhicule de l'utilisateur connecté
  ///
  /// Retourne [null] en cas de succès, sinon un message d'erreur.
  Future<String?> saveVehicle(Vehicle vehicle) async {
    try {
      final ref = _getVehicleRef();
      if (ref == null) {
        return 'Vous devez être connecté pour enregistrer un véhicule.';
      }

      await ref.set(vehicle.toFirestore(), SetOptions(merge: true));
      return null;
    } on FirebaseException catch (e) {
      return _translateError(e.code);
    } catch (e) {
      return 'Une erreur inattendue est survenue. Réessayez.';
    }
  }

  /// Met à jour uniquement le kilométrage (champ fréquemment modifié)
  Future<String?> updateMileage(int newMileage) async {
    try {
      final ref = _getVehicleRef();
      if (ref == null) return 'Non connecté.';

      await ref.update({
        'currentMileage': newMileage,
        'updatedAt': Timestamp.now(),
      });
      return null;
    } on FirebaseException catch (e) {
      return _translateError(e.code);
    } catch (e) {
      return 'Erreur lors de la mise à jour.';
    }
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  /// Traduit les codes d'erreur Firestore en français
  String _translateError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Vous n\'avez pas les droits nécessaires.';
      case 'unavailable':
        return 'Service indisponible. Vérifiez votre connexion.';
      case 'not-found':
        return 'Données introuvables.';
      default:
        return 'Erreur Firestore : $code';
    }
  }
}