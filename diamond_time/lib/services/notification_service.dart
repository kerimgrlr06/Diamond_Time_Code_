import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: android);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // ✅ BİLDİRİMLERİ AÇ (ileride schedule edilecek)
  static Future<void> enableAll() async {
    // Şu an boş → ayar açılır açılmaz donma yapmaz
    // Namaz vakti schedule burada olacak
  }

  static Future<void> disableAll() async {
    await _plugin.cancelAll();
  }
}
