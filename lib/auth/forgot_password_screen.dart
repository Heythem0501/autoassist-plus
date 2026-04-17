import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'auth_service.dart';

/// Écran de réinitialisation de mot de passe
///
/// L'utilisateur entre son email et reçoit un lien Firebase
/// pour réinitialiser son mot de passe.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final errorMessage = await _authService.sendPasswordResetEmail(
      _emailController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.severityRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      setState(() => _emailSent = true);
    }
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
          child: _emailSent ? _buildSuccessView() : _buildFormView(),
        ),
      ),
    );
  }

  // =========================================================================
  // VUE : FORMULAIRE (avant envoi)
  // =========================================================================

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icône
          Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueLight,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 56,
              color: AppTheme.primaryBlue,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Mot de passe oublié ?',
            style: Theme.of(context).textTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Entrez votre adresse email ci-dessous, nous vous enverrons un lien pour réinitialiser votre mot de passe.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Champ email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPassword(),
            decoration: const InputDecoration(
              labelText: 'Adresse email',
              hintText: 'exemple@email.com',
              prefixIcon:
                  Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
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

          const SizedBox(height: 24),

          // Bouton envoyer
          ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPassword,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('Envoyer le lien'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VUE : SUCCÈS (après envoi)
  // =========================================================================

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),

        Container(
          width: 120,
          height: 120,
          margin: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.severityGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 80,
            color: AppTheme.severityGreen,
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Email envoyé !',
          style: Theme.of(context).textTheme.headlineLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Nous avons envoyé un lien de réinitialisation à :\n${_emailController.text}',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez votre boîte de réception (et vos spams).',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 48),

        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Retour à la connexion'),
        ),
      ],
    );
  }
}