import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../vehicle/vehicle_model.dart';
import 'diagnostic_model.dart';

/// Service d'appel à l'API Gemini pour le diagnostic automobile
class DiagnosticService {
  static const String _model = 'gemini-2.5-flash-lite';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const int _timeoutSeconds = 30;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DiagnosticResult> diagnose({
    required String symptoms,
    required Vehicle vehicle,
  }) async {
    final trimmed = symptoms.trim();
    if (trimmed.length < 10) {
      throw DiagnosticException(
        'Veuillez décrire les symptômes en au moins 10 caractères.',
      );
    }

    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw DiagnosticException(
        'Clé API Gemini non configurée. Vérifiez le fichier .env.',
      );
    }

    final prompt = _buildPrompt(symptoms: trimmed, vehicle: vehicle);
    final url = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 2048,
        'responseMimeType': 'application/json',
      },
      'safetySettings': [
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
        {
          'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
          'threshold': 'BLOCK_NONE'
        },
        {
          'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
          'threshold': 'BLOCK_NONE'
        },
      ],
    });

    http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: _timeoutSeconds));
    } catch (e) {
      throw DiagnosticException(
        'Impossible de joindre le service. Vérifiez votre connexion internet.',
      );
    }

    if (response.statusCode != 200) {
      throw DiagnosticException(_parseHttpError(response));
    }

    late Map<String, dynamic> geminiJson;
    try {
      final fullResponse =
          jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = fullResponse['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const FormatException('Réponse vide de Gemini');
      }
      final content =
          candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw const FormatException('Contenu vide dans la réponse');
      }
      final text = parts[0]['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw const FormatException('Texte vide dans la réponse');
      }
      geminiJson = jsonDecode(text) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw DiagnosticException(
        'L\'IA a retourné une réponse invalide. Réessayez.\n(${e.message})',
      );
    } catch (e) {
      throw DiagnosticException(
        'Impossible d\'analyser la réponse de l\'IA. Réessayez.',
      );
    }

    final result = DiagnosticResult.fromGeminiJson(
      json: geminiJson,
      symptoms: trimmed,
    );

    if (result.causes.isEmpty) {
      throw DiagnosticException(
        'L\'IA n\'a pas pu identifier de cause. Soyez plus précis dans votre description.',
      );
    }

    _saveToFirestore(result);
    return result;
  }

  /// Construit le prompt envoyé à Gemini
  /// La réponse est TOUJOURS en français, peu importe la langue de saisie.
  String _buildPrompt({
    required String symptoms,
    required Vehicle vehicle,
  }) {
    return '''
Tu es un expert automobile chevronné. L'utilisateur décrit les symptômes de sa voiture en français ou en arabe. Tu dois identifier les causes probables.

Informations sur le véhicule :
- Marque : ${vehicle.brand}
- Modèle : ${vehicle.model}
- Année : ${vehicle.year}
- Carburant : ${vehicle.fuelType.label}
- Kilométrage : ${vehicle.currentMileage} km

Symptômes décrits par l'utilisateur :
"""
$symptoms
"""

Retourne UNIQUEMENT un objet JSON valide avec cette structure exacte (pas de markdown, pas de commentaires) :
{
  "causes": [
    {
      "cause": "Nom de la cause en français",
      "probabilite": 70,
      "gravite": "rouge"
    },
    {
      "cause": "Autre cause en français",
      "probabilite": 20,
      "gravite": "orange"
    },
    {
      "cause": "Troisième cause en français",
      "probabilite": 10,
      "gravite": "vert"
    }
  ],
  "recommandation": "Conseil en français de 1 à 2 phrases."
}

Règles strictes :
1. Entre 2 et 5 causes possibles, triées par probabilité décroissante.
2. Les probabilités doivent totaliser 100.
3. "gravite" doit être exactement "vert", "orange", ou "rouge".
4. "cause" : description courte (3-8 mots) en FRANÇAIS (même si l'utilisateur écrit en arabe).
5. "recommandation" : conseil pratique en FRANÇAIS adapté à la gravité maximale.
6. Tiens compte de l'âge, du kilométrage et du type de carburant du véhicule.
7. Réponds UNIQUEMENT en JSON valide, sans texte avant ou après.
''';
  }

  void _saveToFirestore(DiagnosticResult result) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    _firestore
        .collection('users')
        .doc(userId)
        .collection('diagnostics')
        .add(result.toFirestore())
        .catchError((e) {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('diagnostics')
          .doc('error');
    });
  }

  Stream<List<DiagnosticResult>> getHistoryStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('diagnostics')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final causes = (data['causes'] as List<dynamic>?)
                ?.map((c) =>
                    DiagnosticCause.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [];

        return DiagnosticResult(
          symptoms: data['symptoms'] as String? ?? '',
          causes: causes,
          recommendation: data['recommendation'] as String? ?? '',
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  String _parseHttpError(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      final message = error?['message'] as String? ?? '';

      if (response.statusCode == 400) {
        return 'Requête invalide. Essayez de reformuler vos symptômes.';
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return 'Clé API Gemini invalide ou expirée.';
      } else if (response.statusCode == 429) {
        return 'Quota Gemini dépassé. Réessayez dans quelques minutes.';
      } else if (response.statusCode >= 500) {
        return 'Service Gemini indisponible. Réessayez plus tard.';
      }
      return 'Erreur API (${response.statusCode}): $message';
    } catch (_) {
      return 'Erreur inconnue (code ${response.statusCode}).';
    }
  }
}

class DiagnosticException implements Exception {
  final String message;
  DiagnosticException(this.message);

  @override
  String toString() => message;
}