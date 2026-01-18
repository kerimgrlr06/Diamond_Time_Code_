import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';

// ✅ Arka plan fonksiyonu sınıf dışında en üstte kalmalıdır.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  if (notificationResponse.actionId == 'islem_yap') {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      final parts = payload.split('_');
      final String gunKey = parts[0];
      final String vakit = parts[1];
      final String tip = parts[2];

      SharedPreferences.getInstance().then((prefs) {
        if (tip == 'namaz') {
          prefs.setString('durum_${vakit}_$gunKey', 'Kıldı');
        } else if (tip == 'oruc') {
          prefs.setString('durum_${vakit}_$gunKey', 'Tutuldu');
        }
      });
    }
  }
}

class BildirimServisi {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> baslat() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static Future<void> tumVakitleriSenkronizeEt(
    Coordinates coords,
    CalculationParameters params,
  ) async {
    await tumBildirimleriIptalEt();

    final prefs = await SharedPreferences.getInstance();
    int sesTipi = prefs.getInt('ses_tipi') ?? 2;
    int hatirlatmaDk = prefs.getInt('hatirlatma_dk') ?? 15;

    for (int i = 0; i < 10; i++) {
      DateTime hedefGun = DateTime.now().add(Duration(days: i));
      String gunKey = DateFormat('yyyy-MM-dd').format(hedefGun);

      PrayerTimes vakitler = PrayerTimes(
        coords,
        DateComponents.from(hedefGun),
        params,
      );

      Map<String, DateTime> vakitMap = {
        'Sabah': vakitler.fajr,
        'Öğle': vakitler.dhuhr,
        'İkindi': vakitler.asr,
        'Akşam': vakitler.maghrib,
        'Yatsı': vakitler.isha,
      };

      int vakitIndex = 0;
      for (var entry in vakitMap.entries) {
        int anaId = (i * 100) + vakitIndex;
        int hatirlatmaId = (i * 100) + vakitIndex + 50;
        int onayId = (i * 100) + vakitIndex + 200;

        bool bildirimAcik =
            prefs.getBool('${entry.key.toLowerCase()}_bildirim') ?? true;

        if (bildirimAcik) {
          await _vakitBildirimiKur(anaId, entry.key, entry.value, sesTipi);

          if (hatirlatmaDk > 0) {
            DateTime hZaman = entry.value.subtract(
              Duration(minutes: hatirlatmaDk),
            );
            await _vakitBildirimiKur(
              hatirlatmaId,
              entry.key,
              hZaman,
              sesTipi,
              isHatirlatma: true,
              dk: hatirlatmaDk,
            );
          }

          // ✅ Vakitten 30 dk sonra interaktif onay bildirimi
          DateTime onayZamani = entry.value.add(const Duration(minutes: 30));
          await _interaktifBildirimKur(
            id: onayId,
            baslik: 'İbadet Kontrolü 🕌',
            mesaj: '${entry.key} namazını kıldıysan işaretlemeyi unutma.',
            zaman: onayZamani,
            payload: '${gunKey}_${entry.key}_namaz',
            butonText: 'Kıldım ✅',
          );
        }
        vakitIndex++;
      }

      // ✅ Oruç Takibi (İftardan 30 dk sonra)
      await _interaktifBildirimKur(
        id: (i * 100) + 300,
        baslik: 'Oruç Kontrolü 🌙',
        mesaj: 'Bugünkü kaza orucunu tuttuysan işaretleyebilirsin.',
        zaman: vakitler.maghrib.add(const Duration(minutes: 30)),
        payload: '${gunKey}_Ramazan Orucu_oruc',
        butonText: 'Tuttum ✅',
      );
    }
  }

  static Future<void> _interaktifBildirimKur({
    required int id,
    required String baslik,
    required String mesaj,
    required DateTime zaman,
    required String payload,
    required String butonText,
  }) async {
    if (zaman.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      id,
      baslik,
      mesaj,
      tz.TZDateTime.from(zaman, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'akilli_takip_kanali',
          'Akıllı İbadet Takibi',
          importance: Importance.max,
          priority: Priority.high,
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              'islem_yap',
              butonText,
              showsUserInterface: false,
            ),
            const AndroidNotificationAction(
              'ignore',
              'Daha Sonra',
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> _vakitBildirimiKur(
    int id,
    String vakitAdi,
    DateTime zaman,
    int sesTipi, {
    bool isHatirlatma = false,
    int dk = 0,
  }) async {
    if (zaman.isBefore(DateTime.now())) return;

    String mesaj = isHatirlatma
        ? '$vakitAdi vaktine $dk dakika kaldı.'
        : '$vakitAdi vakti girdi. Namazını kıldın mı?';

    await _plugin.zonedSchedule(
      id,
      'Diamond Time',
      mesaj,
      tz.TZDateTime.from(zaman, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'vakit_kanali_v2',
          'Vakit Bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          playSound: sesTipi == 2,
          enableVibration: sesTipi >= 1,
          vibrationPattern: sesTipi >= 1
              ? Int64List.fromList([0, 500, 200, 500])
              : null,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> tumBildirimleriIptalEt() async =>
      await _plugin.cancelAll();

  static Future<void> pilAyarlariniAc() async {
    if (await Permission.ignoreBatteryOptimizations.request().isGranted) {
      await openAppSettings();
    }
  }
}
