import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service de notifications locales
///
/// Utilisé pour programmer des rappels d'entretien.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Canal Android utilisé pour les rappels d'entretien
  static const String _channelId = 'maintenance_reminders';
  static const String _channelName = 'Rappels d\'entretien';
  static const String _channelDescription =
      'Notifications pour les entretiens à effectuer sur votre véhicule';

  /// Initialise le service (à appeler au démarrage de l'app)
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialisation du fuseau horaire
    tz.initializeTimeZones();
    try {
      final location = tz.getLocation('Africa/Algiers');
      tz.setLocalLocation(location);
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur fuseau horaire : $e');
    }

    // Configuration Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);

    // Récupération de l'implémentation Android (syntaxe sur une seule ligne
    // pour éviter l'ambiguïté de parsing avec les generics)
    final AndroidFlutterLocalNotificationsPlugin? androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImpl != null) {
      // Création du canal de notification Android
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      );
      await androidImpl.createNotificationChannel(channel);

      // Demande de permission Android 13+
      try {
        await androidImpl.requestNotificationsPermission();
      } catch (e) {
        if (kDebugMode) debugPrint('Permission notif : $e');
      }
    }

    _initialized = true;
  }

  /// Programme une notification pour une date future
  Future<void> scheduleMaintenanceReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await initialize();

    if (scheduledDate.isBefore(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur programmation notif : $e');
    }
  }
  /// Programme un rappel de mise à jour du kilométrage
  /// Se déclenche tous les 14 jours
  Future<void> scheduleMileageReminder() async {
    await initialize();

    // ID fixe pour le rappel de kilométrage (pour le mettre à jour ou l'annuler)
    const mileageReminderId = 1001;

    // Déclenchement : tous les 14 jours, à partir de maintenant + 14 jours
    final firstTrigger = DateTime.now().add(const Duration(days: 14));

    try {
      await _plugin.zonedSchedule(
        mileageReminderId,
        '📊 Mise à jour du kilométrage',
        'Mettez à jour le kilométrage de votre voiture pour des rappels précis.',
        tz.TZDateTime.from(firstTrigger, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Erreur rappel kilométrage : $e');
    }
  }

  /// Annule le rappel de kilométrage (utile pour le re-programmer)
  Future<void> cancelMileageReminder() async {
    await _plugin.cancel(1001);
  }

  /// Annule une notification programmée
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  /// Annule toutes les notifications programmées
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Affiche une notification immédiate (pour tester)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}