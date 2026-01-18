import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  /// ✅ KRİTİK FONKSİYON: 10 Günlük Tüm Bildirimleri Planlar
  /// Uygulamaya girmesen bile bildirimlerin gelmesini sağlayan motor burasıdır.
  static Future<void> scheduleTenDays(
    Coordinates coords,
    CalculationParameters params,
  ) async {
    // Önce çakışma olmaması için eskileri temizle
    await _plugin.cancelAll();

    final prefs = await SharedPreferences.getInstance();
    final bool hatirlatmaAcik = prefs.getBool('bildirim_oncesi_uyari') ?? true;
    final int hatirlatmaDk = prefs.getInt('hatirlatma_dk') ?? 15;

    // Önümüzdeki 10 gün için döngü
    for (int i = 0; i < 10; i++) {
      final date = DateTime.now().add(Duration(days: i));
      final dateComp = DateComponents.from(date);
      final prayerTimes = PrayerTimes(coords, dateComp, params);

      // Her vakit için bildirim kur
      _buildVakit(prayerTimes.fajr, "İmsak", 100 + i, prefs);
      _buildVakit(prayerTimes.dhuhr, "Öğle", 200 + i, prefs);
      _buildVakit(prayerTimes.asr, "İkindi", 300 + i, prefs);
      _buildVakit(prayerTimes.maghrib, "Akşam", 400 + i, prefs);
      _buildVakit(prayerTimes.isha, "Yatsı", 500 + i, prefs);

      // Eğer vakit öncesi hatırlatma açıksa onları da kur
      if (hatirlatmaAcik) {
        _buildVakit(
          prayerTimes.fajr.subtract(Duration(minutes: hatirlatmaDk)),
          "İmsak Vaktine $hatirlatmaDk Dakika Kaldı",
          1100 + i,
          prefs,
          isReminder: true,
        );
        // ... diğer vakitler için de benzer hatırlatmalar eklenebilir
      }
    }
  }

  static Future<void> _buildVakit(
    DateTime time,
    String title,
    int id,
    SharedPreferences prefs, {
    bool isReminder = false,
  }) async {
    // Zamanı geçmiyecek şekilde kontrol et
    if (time.isBefore(DateTime.now())) return;

    // Ayarlardan bu vaktin bildirimi açık mı kontrol et
    final bool isActive =
        prefs.getBool('${title.toLowerCase()}_bildirim') ?? true;
    if (!isActive && !isReminder) return;

    final int sesTipi = prefs.getInt('ses_tipi') ?? 2;

    await _plugin.zonedSchedule(
      id,
      title,
      isReminder ? "Hazırlanmayı Unutmayın" : "Vakit Geldi",
      tz.TZDateTime.from(time, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'namaz_vakti_channel',
          'Namaz Vakitleri',
          importance: Importance.max,
          priority: Priority.high,
          sound: sesTipi == 0
              ? null
              : const RawResourceAndroidNotificationSound('ezan'),
          enableVibration: sesTipi == 1 || sesTipi == 3,
          playSound: sesTipi >= 2,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode
          .exactAllowWhileIdle, // ✅ Doze modunda bile çalışır
    );
  }

  static Future<void> disableAll() async {
    await _plugin.cancelAll();
  }
}
