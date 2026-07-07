import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/models.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const windows = WindowsInitializationSettings(
      appName: 'STUPEL',
      appUserModelId: 'com.stupel.desktop.app',
      guid: '6f5e6b1c-6f48-4d8a-9b62-3dc32b6f4d11',
    );
    const initSettings = InitializationSettings(
      android: android,
      windows: windows,
    );
    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  static Future<void> scheduleTaskDeadlineReminders(List<Note> notes) async {
    await init();
    await _plugin.cancelAll();

    for (final note in notes) {
      if (!note.isTask || note.isDone || note.dueDate == null || note.id == null) {
        continue;
      }

      final dueDate = note.dueDate!;
      final oneDayBefore = DateTime(dueDate.year, dueDate.month, dueDate.day)
          .subtract(const Duration(days: 1))
          .add(const Duration(hours: 9));
      final sameDay = DateTime(dueDate.year, dueDate.month, dueDate.day, 8);
      final nearDeadline = DateTime(dueDate.year, dueDate.month, dueDate.day, 18);

      await _schedule(
        id: note.id! * 10 + 1,
        title: 'Pengingat Tugas Besok',
        body: '${note.title} jatuh tempo besok.',
        dateTime: oneDayBefore,
      );
      await _schedule(
        id: note.id! * 10 + 2,
        title: 'Deadline Hari Ini',
        body: '${note.title} jatuh tempo hari ini.',
        dateTime: sameDay,
      );
      await _schedule(
        id: note.id! * 10 + 3,
        title: 'Tugas Mendekati Tenggat',
        body: 'Pastikan ${note.title} selesai tepat waktu.',
        dateTime: nearDeadline,
      );
    }
  }

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (dateTime.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_deadline_channel',
          'Task Deadline',
          channelDescription: 'Notifikasi pengingat deadline tugas',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
