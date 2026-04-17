import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'auth_service.dart';

/// Écran d'inscription
///
/// Permet à un nouvel utilisateur de créer un compte avec :
/// - Email
/// - Mot de passe (minimum 6 caractères)
/// - Confirmation du mot de passe
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Gère la tentative d'inscription
  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      _showErrorSnackBar('Vous devez accepter les conditions d\'utilisation');
      return;
    }

    setState(() => _isLoading = true);

    final errorMessage = await _authService.signUp(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (errorMessage != null) {
      _showErrorSnackBar(errorMessage);
    } else {
      // Inscription réussie — le AuthWrapper redirige automatiquement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Compte créé avec succès !'),
          backgroundColor: AppTheme.severityGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.severityRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ======== TITRE ========
                Text(
                  'Créer un compte',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Rejoignez AutoAssist+ dès maintenant',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),

                const SizedBox(height: 32),

                // ======== CHAMP EMAIL ========
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Adresse email',
                    hintText: 'exemple@email.com',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppTheme.primaryBlue),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez entrer votre email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Adresse email invalide';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ======== CHAMP MOT DE PASSE ========
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    hintText: 'Au moins 6 caractères',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(
                            () => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un mot de passe';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit contenir au moins 6 caractères';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ======== CHAMP CONFIRMATION MOT DE PASSE ========
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignup(),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    hintText: 'Retapez votre mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.primaryBlue),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppTheme.textSecondary,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword =
                            !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ======== CASE CONDITIONS ========
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptTerms,
                        activeColor: AppTheme.primaryBlue,
                        onChanged: (value) {
                          setState(() => _acceptTerms = value ?? false);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ======== BOUTON INSCRIPTION ========
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Créer mon compte'),
                ),

                const SizedBox(height: 24),

                // ======== LIEN CONNEXION ========
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Déjà inscrit ? ',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: AppTheme.accentOrange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}