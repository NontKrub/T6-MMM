import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _dailyReminderTitle = 'Your MMM outfit is ready';
const _dailyReminderBody = 'Open MMM to see today\'s recommendation.';
const _repetitionAlertTitle = 'Try a fresh combination';
const _repetitionAlertBody =
    'You\'ve repeated this combination recently. MMM can suggest an alternative.';

int normalizeReminderMinutes(int value) => value.clamp(0, 23 * 60 + 59);

tz.TZDateTime nextDailyReminderDate({
  required tz.TZDateTime now,
  required int minutes,
}) {
  final normalized = normalizeReminderMinutes(minutes);
  var next = tz.TZDateTime(
    now.location,
    now.year,
    now.month,
    now.day,
    normalized ~/ 60,
    normalized % 60,
  );
  if (!next.isAfter(now)) {
    next = tz.TZDateTime(
      now.location,
      now.year,
      now.month,
      now.day + 1,
      normalized ~/ 60,
      normalized % 60,
    );
  }
  return next;
}

String repetitionNotificationKey(Iterable<String> itemIds) =>
    (itemIds.toSet().toList()..sort()).join('|');

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const dailyReminderEnabledKey = 'mmm_daily_outfit_reminder';
  static const dailyReminderMinutesKey = 'mmm_daily_outfit_reminder_minutes';
  static const dailyReminderId = 1001;
  static const repetitionAlertId = 1002;

  final FlutterLocalNotificationsPlugin _plugin;
  final _repetitionAlertKeys = <String>{};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    if (!_isMobile) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (error) {
      debugPrint('Unable to load device timezone: $error');
    }

    final initialized = await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('mmm_notification_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    if (initialized == false) {
      throw StateError('The notification plugin did not initialize.');
    }
    _initialized = true;
  }

  Future<void> restoreDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(dailyReminderEnabledKey) != true) return;
    final minutes = prefs.getInt(dailyReminderMinutesKey);
    if (minutes == null) return;
    if (!await _ensureInitialized()) return;
    try {
      await _scheduleDailyReminder(normalizeReminderMinutes(minutes));
    } catch (error) {
      debugPrint('Unable to restore daily outfit reminder: $error');
    }
  }

  Future<bool> enableDailyReminder(TimeOfDay time) async {
    if (!await _ensureInitialized()) return false;
    final permission = await requestPermission();
    if (!permission) return false;
    try {
      await _scheduleDailyReminder(time.hour * 60 + time.minute);
      return true;
    } catch (error) {
      debugPrint('Unable to schedule daily outfit reminder: $error');
      return false;
    }
  }

  Future<void> disableDailyReminder() async {
    if (!await _ensureInitialized()) return;
    try {
      await _plugin.cancel(id: dailyReminderId);
    } catch (error) {
      debugPrint('Unable to cancel daily outfit reminder: $error');
    }
  }

  Future<bool> requestPermission() async {
    if (!await _ensureInitialized()) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      }
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    } catch (error) {
      debugPrint('Unable to request notification permission: $error');
      return false;
    }
  }

  Future<void> showRepetitionAlert(Iterable<String> itemIds) async {
    if (!await _ensureInitialized()) return;
    final key = repetitionNotificationKey(itemIds);
    if (!_repetitionAlertKeys.add(key)) return;
    try {
      await _plugin.show(
        id: repetitionAlertId,
        title: _repetitionAlertTitle,
        body: _repetitionAlertBody,
        notificationDetails: _notificationDetails,
        payload: 'repetition:$key',
      );
    } catch (error) {
      _repetitionAlertKeys.remove(key);
      debugPrint('Unable to show repetition alert: $error');
    }
  }

  Future<void> disableRepetitionAlerts() async {
    _repetitionAlertKeys.clear();
    if (!await _ensureInitialized()) return;
    try {
      await _plugin.cancel(id: repetitionAlertId);
    } catch (error) {
      debugPrint('Unable to cancel repetition alert: $error');
    }
  }

  Future<bool> _ensureInitialized() async {
    try {
      await initialize();
      return _isMobile;
    } catch (error) {
      debugPrint('Notifications are unavailable: $error');
      return false;
    }
  }

  Future<void> _scheduleDailyReminder(int minutes) async {
    final now = tz.TZDateTime.now(tz.local);
    await _plugin.cancel(id: dailyReminderId);
    await _plugin.zonedSchedule(
      id: dailyReminderId,
      title: _dailyReminderTitle,
      body: _dailyReminderBody,
      scheduledDate: nextDailyReminderDate(now: now, minutes: minutes),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_outfit',
    );
  }

  NotificationDetails get _notificationDetails => const NotificationDetails(
    android: AndroidNotificationDetails(
      'mmm_outfit_reminders',
      'Outfit reminders',
      channelDescription: 'Daily outfit and repetition reminders from MMM.',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
  );

  bool get _isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

final notificationService = NotificationService();
