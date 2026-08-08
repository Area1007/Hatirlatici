import 'dart:convert';
import 'dart:io';

import 'ai_reminder_service.dart';
import 'quick_reminder_screen.dart';

import 'core/app_colors.dart';
import 'core/app_spacing.dart';
import 'core/app_text_styles.dart';
import 'core/app_theme.dart';
import 'widgets/app_bottom_nav.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

part 'models.dart';
part 'home_screen.dart';
part 'reminder_list_screen.dart';
part 'reminder_edit_screen.dart';
part 'reminder_detail_screen.dart';
part 'calendar_screen.dart';
part 'stats_screen.dart';
part 'settings_screen.dart';

const String hatirlaticilarKey = 'hatirlaticilar';
const String listelerKey = 'ozel_listeler';
const String defaultListeId = 'default';
const String ayarlarKey = 'uygulama_ayarlari';

const String actionSnooze10 = 'snooze_10';
const String actionSnooze60 = 'snooze_60';
const String actionComplete = 'complete';
const String notificationCategoryId = 'reminder_actions';

final FlutterLocalNotificationsPlugin bildirimPlugin =
    FlutterLocalNotificationsPlugin();

final ValueNotifier<int> veriSurumu = ValueNotifier<int>(0);
final ValueNotifier<AppSettings> appSettingsNotifier =
    ValueNotifier<AppSettings>(const AppSettings());

// Yeni bildirimlerde her hatırlatıcıya 100 slot ayırıyoruz.
int bildirimId(int reminderId, int slot) {
  final int safeBase = reminderId.abs() % 20000000;
  return (safeBase * 100) + slot;
}

String payloadFor(int reminderId) => 'reminder:$reminderId';

int? reminderIdFromPayload(String? payload) {
  if (payload == null || !payload.startsWith('reminder:')) return null;
  return int.tryParse(payload.substring('reminder:'.length));
}

Future<void> _initializePluginForBackground() async {
  appSettingsNotifier.value = await AppSettings.load();

  const AndroidInitializationSettings android =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings darwin = DarwinInitializationSettings(
    notificationCategories: <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        notificationCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(actionSnooze10, '10 dk'),
          DarwinNotificationAction.plain(actionSnooze60, '1 saat'),
          DarwinNotificationAction.plain(actionComplete, 'Tamamlandı'),
        ],
      ),
    ],
  );

  await bildirimPlugin.initialize(
    settings: InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    ),
  );
}

Future<List<Map<String, dynamic>>> _readReminderMaps() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  final String? raw = prefs.getString(hatirlaticilarKey);
  if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

  final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
  return decoded
      .map((dynamic e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

Future<void> _writeReminderMaps(List<Map<String, dynamic>> maps) async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(hatirlaticilarKey, jsonEncode(maps));
}

Future<void> _cancelAllForReminderId(int reminderId) async {
  // Eski sürümde doğrudan reminderId ile kurulmuş bildirimleri de temizler.
  await bildirimPlugin.cancel(id: reminderId);

  // Eski *10 slot düzeni.
  final int oldBase = reminderId.abs() % 200000000;
  for (int slot = 0; slot <= 9; slot++) {
    await bildirimPlugin.cancel(id: (oldBase * 10) + slot);
  }

  // Yeni *100 slot düzeni.
  for (int slot = 0; slot <= 99; slot++) {
    await bildirimPlugin.cancel(id: bildirimId(reminderId, slot));
  }
}

NotificationDetails _actionNotificationDetails() {
  final AppSettings settings = appSettingsNotifier.value;
  final String channelId =
      'hatirlatici_${settings.bildirimSesi ? 'ses' : 'sessiz'}_${settings.titresim ? 'titresim' : 'sabit'}';

  return NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      'Hatırlatıcılar',
      channelDescription: 'Hatırlatıcı bildirimleri',
      importance: Importance.max,
      priority: Priority.high,
      playSound: settings.bildirimSesi,
      enableVibration: settings.titresim,
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(actionSnooze10, '10 dk ertele'),
        AndroidNotificationAction(actionSnooze60, '1 saat ertele'),
        AndroidNotificationAction(actionComplete, 'Tamamlandı'),
      ],
    ),
    iOS: DarwinNotificationDetails(
      categoryIdentifier: notificationCategoryId,
      presentSound: settings.bildirimSesi,
    ),
  );
}

Future<void> _backgroundCompleteReminder(int reminderId) async {
  final List<Map<String, dynamic>> maps = await _readReminderMaps();
  bool changed = false;

  for (final Map<String, dynamic> item in maps) {
    if (item['id'] == reminderId) {
      item['tamamlandi'] = true;
      item['tamamlanmaTarihi'] = DateTime.now().toIso8601String();
      changed = true;
      break;
    }
  }

  if (changed) await _writeReminderMaps(maps);
  await _cancelAllForReminderId(reminderId);
}

Future<void> _backgroundSnoozeReminder(
  int reminderId,
  Duration duration,
  int slot,
) async {
  final List<Map<String, dynamic>> maps = await _readReminderMaps();
  Map<String, dynamic>? item;

  for (final Map<String, dynamic> candidate in maps) {
    if (candidate['id'] == reminderId) {
      item = candidate;
      break;
    }
  }

  if (item == null || (item['tamamlandi'] ?? false) == true) return;

  tz.initializeTimeZones();
  final tz.TZDateTime snoozeTime = tz.TZDateTime.now(tz.UTC).add(duration);

  await bildirimPlugin.zonedSchedule(
    id: bildirimId(reminderId, slot),
    title: item['baslik'] as String? ?? 'Hatırlatıcı',
    body: ((item['aciklama'] as String?) ?? '').trim().isEmpty
        ? 'Hatırlatma zamanı geldi.'
        : item['aciklama'] as String,
    scheduledDate: snoozeTime,
    notificationDetails: _actionNotificationDetails(),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    payload: payloadFor(reminderId),
  );
}

Future<void> _handleNotificationAction(NotificationResponse response) async {
  final int? reminderId = reminderIdFromPayload(response.payload);
  if (reminderId == null) return;

  if (response.actionId == actionComplete) {
    await _backgroundCompleteReminder(reminderId);
  } else if (response.actionId == actionSnooze10) {
    await _backgroundSnoozeReminder(
      reminderId,
      const Duration(minutes: 10),
      90,
    );
  } else if (response.actionId == actionSnooze60) {
    await _backgroundSnoozeReminder(
      reminderId,
      const Duration(hours: 1),
      91,
    );
  }
}

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializePluginForBackground();
  await _handleNotificationAction(response);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  appSettingsNotifier.value = await AppSettings.load();
  tz.initializeTimeZones();

  try {
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
  } catch (e) {
    debugPrint('ZAMAN DİLİ HATASI: $e');
    tz.setLocalLocation(tz.UTC);
  }

  const AndroidInitializationSettings android =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final DarwinInitializationSettings darwin = DarwinInitializationSettings(
    notificationCategories: <DarwinNotificationCategory>[
      DarwinNotificationCategory(
        notificationCategoryId,
        actions: <DarwinNotificationAction>[
          DarwinNotificationAction.plain(actionSnooze10, '10 dk'),
          DarwinNotificationAction.plain(actionSnooze60, '1 saat'),
          DarwinNotificationAction.plain(actionComplete, 'Tamamlandı'),
        ],
      ),
    ],
  );

  await bildirimPlugin.initialize(
    settings: InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    ),
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      await _handleNotificationAction(response);
      veriSurumu.value++;
    },
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  final AndroidFlutterLocalNotificationsPlugin? androidPlugin = bildirimPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.requestNotificationsPermission();
  await androidPlugin?.requestExactAlarmsPermission();

  runApp(const HatirlaticiApp());
}

class HatirlaticiApp extends StatelessWidget {
  const HatirlaticiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (
        BuildContext context,
        AppSettings settings,
        Widget? child,
      ) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hatırlatıcı',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          home: const AnaSayfa(),
        );
      },
    );
  }
}

/// Varsayılan MaterialPageRoute geçişinden daha kısa animasyon kullanır.
/// Sayfaların çalışma mantığını değiştirmez; yalnızca geçiş hissini hızlandırır.
class FastPageRoute<T> extends MaterialPageRoute<T> {
  FastPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 100);
}
