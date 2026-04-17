import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service centralisé d'authentification Firebase
///
/// Gère toutes les opérations liées à l'authentification :
/// - Inscription email/password
/// - Connexion email/password
/// - Déconnexion
/// - Réinitialisation de mot de passe
/// - Persistance du choix "Remember me"
/// - Observation de l'état de connexion en temps réel
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Clé utilisée pour stocker la préférence "Remember me" localement
  static const String _rememberMeKey = 'remember_me';

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Stream de l'état de connexion — émet un événement à chaque changement
  /// (connexion, déconnexion, inscription)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utilisateur actuellement connecté (null si déconnecté)
  User? get currentUser => _auth.currentUser;

  // =========================================================================
  // INSCRIPTION
  // =========================================================================

  /// Crée un nouveau compte avec email et mot de passe
  ///
  /// Retourne [null] en cas de succès, ou un [String] avec le message
  /// d'erreur en français en cas d'échec.
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null; // succès
    } on FirebaseAuthException catch (e) {
      return _translateError(e.code);
    } catch (e) {
      return 'Une erreur inattendue est survenue. Réessayez.';
    }
  }

  // =========================================================================
  // CONNEXION
  // =========================================================================

  /// Connecte un utilisateur avec email et mot de passe
  ///
  /// Si [rememberMe] est true, la préférence est sauvegardée localement.
  /// Retourne [null] en cas de succès, sinon un message d'erreur.
  Future<String?> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Sauvegarde du choix "Remember me"
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, rememberMe);

      return null; // succès
    } on FirebaseAuthException catch (e) {
      return _translateError(e.code);
    } catch (e) {
      return 'Une erreur inattendue est survenue. Réessayez.';
    }
  }

  // =========================================================================
  // DÉCONNEXION
  // =========================================================================

  /// Déconnecte l'utilisateur et efface la préférence "Remember me"
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_rememberMeKey);
    await _auth.signOut();
  }

  // =========================================================================
  // MOT DE PASSE OUBLIÉ
  // =========================================================================

  /// Envoie un email de réinitialisation de mot de passe
  ///
  /// Retourne [null] en cas de succès, sinon un message d'erreur.
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null; // succès
    } on FirebaseAuthException catch (e) {
      return _translateError(e.code);
    } catch (e) {
      return 'Une erreur inattendue est survenue. Réessayez.';
    }
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  /// Récupère la valeur de la préférence "Remember me"
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  /// Traduit les codes d'erreur Firebase en français lisible
  String _translateError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'L\'adresse email est invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Aucun compte trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé.';
      case 'operation-not-allowed':
        return 'Cette méthode de connexion est désactivée.';
      case 'weak-password':
        return 'Le mot de passe est trop faible (minimum 6 caractères).';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Pas de connexion internet.';
      default:
        return 'Erreur : $code';
    }
  }
}