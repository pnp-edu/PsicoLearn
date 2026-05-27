import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../di/service_locator.dart';
import '../../../features/personality_test/domain/services/personality_test_service.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      if (kIsWeb) {
        debugPrint('Notificaciones no soportadas en la web.');
        return;
      }
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint('Notificaciones no soportadas en esta plataforma de escritorio.');
        return;
      }

      tz_data.initializeTimeZones();
      
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notifications.initialize(initSettings);

      // Solicitar permisos para Android 13+ (API 33+)
      if (Platform.isAndroid) {
        final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          await androidPlugin.requestNotificationsPermission();
          await androidPlugin.requestExactAlarmsPermission();
        }
      }

      // Solicitar permisos para iOS
      if (Platform.isIOS) {
        final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin != null) {
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      }
      
      // Programar recordatorio táctico automáticamente
      await scheduleTacticalReminder();
    } catch (e) {
      debugPrint('Error en init de notificaciones: $e');
    }
  }

  Future<void> scheduleTacticalReminder() async {
    try {
      if (kIsWeb) return;
      if (!Platform.isAndroid && !Platform.isIOS) return;

      final service = sl<PersonalityTestService>();
      final result = await service.getDiagnosisResult();
      final scores = result.scoresPorDimension;
      
      String message = 'Aspirante, tu entrenamiento psicométrico te espera. ¡No bajes la guardia!';
      String title = 'ENTRENAMIENTO CRÍTICO';

      if (scores.isNotEmpty) {
        // Buscar la dimensión más baja
        final lowest = scores.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
        final dim = lowest.first.key;
        final score = (lowest.first.value * 100).toInt();
        
        if (score < 30) {
          title = 'ALERTA DE PERFIL';
          message = 'Tu $dim está en modo CRÍTICO al $score%. ¡Mejora tu perfil para ese bendito examen!';
        } else {
          message = 'Tu $dim requiere refuerzo inmediato. Nivel actual: $score%. ¡Entrena ahora!';
        }
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'tactical_reminders',
        'Recordatorios Tácticos',
        channelDescription: 'Notificaciones para entrenamiento psicométrico',
        importance: Importance.max,
        priority: Priority.high,
        color: const Color(0xFF00E5FF),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        ledColor: const Color(0xFF00E5FF),
        ledOnMs: 1000,
        ledOffMs: 500,
      );

      final NotificationDetails details = NotificationDetails(android: androidDetails);

      // Programar para mañana a las 10 AM con seguridad de zona horaria
      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, 10);
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        0,
        title,
        message,
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error al programar notificación: $e');
    }
  }

  Future<void> showInstantFeedback(String title, String body) async {
    try {
      if (kIsWeb) return;
      if (!Platform.isAndroid && !Platform.isIOS) return;

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'instant_feedback',
        'Feedback Instantáneo',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 200, 100, 200]),
      );
      final NotificationDetails details = NotificationDetails(android: androidDetails);
      await _notifications.show(1, title, body, details);
    } catch (e) {
    }
  }

  Future<void> triggerTestNotification() async {
    await showInstantFeedback(
      'ALERTA DE PERFIL',
      'Tu Ética e Integridad está en modo CRÍTICO al 13%. ¡Mejora tu perfil para ese bendito examen!',
    );
  }
}
