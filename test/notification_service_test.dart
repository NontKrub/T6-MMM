import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mix_match_mood/core/services/notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as timezone;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    tz.initializeTimeZones();
  });

  test('normalizes reminder minutes to one valid day', () {
    expect(normalizeReminderMinutes(-1), 0);
    expect(normalizeReminderMinutes(8 * 60 + 30), 510);
    expect(normalizeReminderMinutes(24 * 60), 1439);
  });

  test(
    'schedules the next local occurrence, including after today\'s time',
    () {
      final location = timezone.getLocation('America/New_York');
      final before = timezone.TZDateTime(location, 2026, 3, 8, 0, 30);
      final beforeResult = nextDailyReminderDate(now: before, minutes: 90);
      expect(beforeResult.location, location);
      expect(beforeResult.day, 8);
      expect(beforeResult.hour, 1);
      expect(beforeResult.minute, 30);

      final after = timezone.TZDateTime(location, 2026, 3, 8, 2, 0);
      final afterResult = nextDailyReminderDate(now: after, minutes: 90);
      expect(afterResult.day, 9);
      expect(afterResult.hour, 1);
      expect(afterResult.minute, 30);
    },
  );

  test('debounce key is stable for one outfit combination', () {
    expect(repetitionNotificationKey(['shoes', 'top', 'shoes']), 'shoes|top');
    expect(
      repetitionNotificationKey(['top', 'shoes']),
      repetitionNotificationKey(['shoes', 'top']),
    );
  });

  test('notification operations are harmless on unsupported hosts', () async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      final service = NotificationService();

      expect(await service.requestPermission(), isFalse);
      await service.enableDailyReminder(const TimeOfDay(hour: 8, minute: 0));
      await service.disableDailyReminder();
      await service.showRepetitionAlert(['top']);
      await service.disableRepetitionAlerts();
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
  });
}
