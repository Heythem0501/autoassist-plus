import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../vehicle/vehicle_service.dart';
import 'diagnostic_model.dart';
import 'diagnostic_service.dart';
import 'diagnostic_result_card.dart';

/// Écran Diagnostic — saisie des symptômes + affichage des résultats IA
class DiagnosticScreen extends StatefulWidget {
  const DiagnosticScreen({super.key});

  @override
  State<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends State<DiagnosticScreen> {
  final _symptomsController = TextEditingController();
  final _diagnosticService = DiagnosticService();
  final _vehicleService = VehicleService();

  bool _isAnalyzing = false;
  DiagnosticResult? _result;
  String? _errorMessage;

  /// Exemples affichés pour guider l'utilisateur
  static const List<String> _examples = [
    'Ma voiture fait un bruit bizarre quand j\'accélère.',
    'Fumée noire à l\'échappement au démarrage.',
    'Les freins grincent et la pédale est molle.',
    'Le moteur chauffe anormalement en ville.',
  ];

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  /// Lance le diagnostic via l'API Gemini
  Future<void> _handleDiagnose() async {
    final symptoms = _symptomsController.text.trim();
    if (symptoms.isEmpty) {
      _showSnackBar('Veuillez décrire les symptômes', isError: true);
      return;
    }

    // Récupérer les infos du véhicule
    final vehicle = await _vehicleService.getVehicle();
    if (!mounted) return;

    if (vehicle == null) {
      _showSnackBar(
        'Aucun véhicule enregistré. Rendez-vous dans l\'onglet Profil.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await _diagnosticService.diagnose(
        symptoms: symptoms,
        vehicle: vehicle,
      );
      if (!mounted) return;

      setState(() {
        _result = result;
        _isAnalyzing = false;
      });
    } on DiagnosticException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isAnalyzing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur inattendue. Réessayez.';
        _isAnalyzing = false;
      });
    }
  }

  /// Réinitialise l'écran pour un nouveau diagnostic
  void _resetDiagnosis() {
    setState(() {
      _result = null;
      _errorMessage = null;
      _symptomsController.clear();
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? AppTheme.severityRed : AppTheme.severityGreen,
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
        title: const Text('Diagnostic intelligent'),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Nouveau diagnostic',
              onPressed: _resetDiagnosis,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _result != null
              ? _buildResultView(_result!)
              : _buildInputView(),
        ),
      ),
    );
  }

  // ==========================================================================
  // VUE : SAISIE (avant diagnostic)
  // ==========================================================================

  Widget _buildInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ===== HEADER =====
        _buildHeader(),
        const SizedBox(height: 24),

        // ===== CHAMP DE SAISIE =====
        _buildSymptomsField(),
        const SizedBox(height: 20),

        // ===== BOUTON DIAGNOSTIC =====
        _buildDiagnoseButton(),
        const SizedBox(height: 16),

        // ===== MESSAGE D'ERREUR =====
        if (_errorMessage != null) _buildErrorBox(_errorMessage!),

        const SizedBox(height: 8),

        // ===== EXEMPLES =====
        if (!_isAnalyzing && _errorMessage == null) _buildExamplesSection(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryBlue, AppTheme.primaryBlueDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnostic IA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Décrivez les symptômes en français ou en arabe.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsField() {
    return TextField(
      controller: _symptomsController,
      maxLines: 5,
      maxLength: 500,
      textInputAction: TextInputAction.newline,
      enabled: !_isAnalyzing,
      decoration: const InputDecoration(
        labelText: 'Décrivez les symptômes',
        hintText:
            'Exemple : Ma voiture fait un bruit métallique quand je freine...',
        hintMaxLines: 2,
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 80),
          child: Icon(Icons.edit_note_rounded, color: AppTheme.primaryBlue),
        ),
      ),
    );
  }

  Widget _buildDiagnoseButton() {
    return ElevatedButton.icon(
      onPressed: _isAnalyzing ? null : _handleDiagnose,
      icon: _isAnalyzing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : const Icon(Icons.psychology_rounded),
      label: Text(
        _isAnalyzing ? 'Analyse en cours...' : 'Analyser avec l\'IA',
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.severityRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.severityRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppTheme.severityRed),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.severityRed,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded,
                color: AppTheme.accentOrange, size: 18),
            SizedBox(width: 6),
            Text(
              'Exemples',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._examples.map((example) => _buildExampleChip(example)),
      ],
    );
  }

  Widget _buildExampleChip(String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _isAnalyzing
            ? null
            : () {
                _symptomsController.text = example;
              },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlueLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderGrey),
          ),
          child: Row(
            children: [
              const Icon(Icons.arrow_forward_rounded,
                  color: AppTheme.primaryBlue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  example,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // VUE : RÉSULTATS (après diagnostic)
  // ==========================================================================

  Widget _buildResultView(DiagnosticResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ===== RAPPEL DES SYMPTÔMES =====
        _buildSymptomsRecap(result.symptoms),
        const SizedBox(height: 16),

        // ===== RÉSUMÉ GLOBAL (gravité max) =====
        _buildSeveritySummary(result),
        const SizedBox(height: 20),

        // ===== LISTE DES CAUSES =====
        Text(
          '${result.causes.length} cause${result.causes.length > 1 ? "s" : ""} probable${result.causes.length > 1 ? "s" : ""}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),

        ...List.generate(
          result.causes.length,
          (i) => DiagnosticResultCard(
            cause: result.causes[i],
            rank: i + 1,
          ),
        ),

        const SizedBox(height: 8),

        // ===== RECOMMANDATION =====
        _buildRecommendationCard(result.recommendation),

        const SizedBox(height: 20),

        // ===== BOUTON NOUVEAU DIAGNOSTIC =====
        OutlinedButton.icon(
          onPressed: _resetDiagnosis,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Nouveau diagnostic'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            side: const BorderSide(color: AppTheme.primaryBlue),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSymptomsRecap(String symptoms) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.format_quote_rounded,
                  color: AppTheme.textSecondary, size: 16),
              SizedBox(width: 4),
              Text(
                'Vos symptômes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            symptoms,
            style: const TextStyle(
              fontSize: 13.5,
              color: AppTheme.textPrimary,
              height: 1.4,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeveritySummary(DiagnosticResult result) {
    final severity = result.maxSeverity;
    final color = severity.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(severity.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gravité : ${severity.label}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  severity.shortMessage,
                  style: TextStyle(
                    fontSize: 13,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(String recommendation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.accentOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tips_and_updates_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recommandation',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accentOrange,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  recommendation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}