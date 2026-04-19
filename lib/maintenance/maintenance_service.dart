import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'maintenance_model.dart';

/// Service de gestion des entretiens dans Firestore
///
/// Structure :
///   users/{uid}/maintenance/{recordId}
class MaintenanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Référence à la collection des entretiens de l'utilisateur connecté
  CollectionReference<Map<String, dynamic>>? _getCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('maintenance');
  }

  /// Stream des entretiens (triés par date décroissante)
  Stream<List<MaintenanceRecord>> getRecordsStream() {
    final col = _getCollection();
    if (col == null) return Stream.value([]);

    return col
        .orderBy('performedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MaintenanceRecord.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Récupère les entretiens une seule fois (pour le dashboard)
  Future<List<MaintenanceRecord>> getRecordsOnce() async {
    final col = _getCollection();
    if (col == null) return [];

    final snap =
        await col.orderBy('performedAt', descending: true).get();
    return snap.docs
        .map((doc) => MaintenanceRecord.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  /// Ajoute un nouvel entretien
  Future<String?> addRecord(MaintenanceRecord record) async {
    try {
      final col = _getCollection();
      if (col == null) return 'Non connecté.';
      await col.add(record.toFirestore());
      return null;
    } on FirebaseException catch (e) {
      return _translateError(e.code);
    } catch (e) {
      return 'Erreur lors de l\'enregistrement.';
    }
  }

  /// Supprime un entretien
  Future<String?> deleteRecord(String recordId) async {
    try {
      final col = _getCollection();
      if (col == null) return 'Non connecté.';
      await col.doc(recordId).delete();
      return null;
    } on FirebaseException catch (e) {
      return _translateError(e.code);
    } catch (e) {
      return 'Erreur lors de la suppression.';
    }
  }

  /// Pour chaque type d'entretien, retourne le dernier enregistrement
  /// (ou null si jamais fait)
  Future<Map<String, MaintenanceRecord?>> getLatestByType() async {
    final records = await getRecordsOnce();
    final latest = <String, MaintenanceRecord?>{};

    for (final record in records) {
      // records sont déjà triés par date descendante → le premier = le plus récent
      if (!latest.containsKey(record.typeId)) {
        latest[record.typeId] = record;
      }
    }
    return latest;
  }

  String _translateError(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Vous n\'avez pas les droits nécessaires.';
      case 'unavailable':
        return 'Service indisponible. Vérifiez votre connexion.';
      default:
        return 'Erreur Firestore : $code';
    }
  }
}