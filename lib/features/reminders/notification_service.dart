import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../models.dart';
import '../../repository.dart';
import 'reminders.dart';

/// Wraps flutter_local_notifications: init, permission, and (re)scheduling
/// birthday/anniversary reminders at 9am local on the day.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'heirloom_reminders',
    'Family reminders',
    channelDescription: 'Birthday and anniversary reminders',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _ready = true;
  }

  /// Asks the OS for notification permission (Android 13+, iOS).
  Future<bool> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iOS = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final a = await android?.requestNotificationsPermission() ?? true;
    final i = await iOS?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    return a || i;
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// Clears and reschedules all reminders from current data.
  Future<void> rescheduleFrom(
    FamilyRepository repo,
    DateTime now, {
    required bool enabled,
  }) async {
    await init();
    await _plugin.cancelAll();
    if (!enabled) return;

    final people = await repo.allPeople();
    final events = <LifeEvent>[];
    for (final p in people) {
      events.addAll(await repo.eventsOf(p.id));
    }

    final reminders =
        upcomingReminders(people: people, events: events, from: now);

    for (final r in reminders) {
      // Fire at 9am local on the day of the occurrence.
      final at = tz.TZDateTime.local(
          r.when.year, r.when.month, r.when.day, 9);
      if (at.isBefore(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        r.id,
        r.title,
        r.body,
        at,
        const NotificationDetails(android: _channel, iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    }
  }
}
