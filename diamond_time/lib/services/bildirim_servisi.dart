import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';

class BildirimServisi {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // 🔔 Servisi Başlat
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

    await _plugin.initialize(settings);
  }

  // ✅ ANA METOD: Tüm vakitleri kurar
  static Future<void> tumVakitleriSenkronizeEt(PrayerTimes vakitler) async {
    await tumBildirimleriIptalEt(); // Önce eskileri temizle

    final prefs = await SharedPreferences.getInstance();

    // 0: Sessiz, 1: Sadece Titreşim, 2: Ses + Titreşim (Varsayılan)
    int sesTipi = prefs.getInt('ses_tipi') ?? 2;
    int hatirlatmaDk = prefs.getInt('hatirlatma_dk') ?? 15;

    Map<String, DateTime> vakitMap = {
      'imsak': vakitler.fajr,
      'ogle': vakitler.dhuhr,
      'ikindi': vakitler.asr,
      'aksam': vakitler.maghrib,
      'yatsi': vakitler.isha,
    };

    int idSayac = 0;
    for (var entry in vakitMap.entries) {
      String key = entry.key;
      DateTime zaman = entry.value;

      bool bildirimAcik = prefs.getBool('${key}_bildirim') ?? true;

      if (bildirimAcik) {
        // 1️⃣ Ana Vakit Bildirimi
        await _vakitBildirimiKur(
          idSayac,
          '${key[0].toUpperCase()}${key.substring(1)}',
          zaman,
          sesTipi,
        );

        // 2️⃣ Hatırlatma Bildirimi
        if (hatirlatmaDk > 0) {
          DateTime hatirlatmaZamani = zaman.subtract(
            Duration(minutes: hatirlatmaDk),
          );
          await _vakitBildirimiKur(
            idSayac + 100,
            '${key[0].toUpperCase()}${key.substring(1)} Yaklaşıyor',
            hatirlatmaZamani,
            sesTipi,
            isHatirlatma: true,
            dk: hatirlatmaDk,
          );
        }
      }
      idSayac++;
    }
  }

  // ⏰ İç Metod: Bildirimi Zamanla
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

    // ✅ SES + TİTREŞİM MANTIĞI
    bool playSound = sesTipi == 2;
    bool enableVibration = sesTipi >= 1;

    await _plugin.zonedSchedule(
      id,
      'Diamond Time',
      mesaj,
      tz.TZDateTime.from(zaman, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'vakit_kanali',
          'Vakit Bildirimleri',
          channelDescription: 'Sesli ve titreşimli vakit uyarıları',
          importance: Importance.max,
          priority: Priority.high,
          playSound: playSound,
          enableVibration: enableVibration,
          // Zarif ve belirgin bir titreşim deseni: Bekle, Titre, Bekle, Titre
          vibrationPattern: enableVibration
              ? Int64List.fromList([0, 500, 200, 500])
              : null,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: playSound,
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> tumBildirimleriIptalEt() async {
    await _plugin.cancelAll();
  }

  static Future<void> pilAyarlariniAc() async {
    try {
      if (await Permission.ignoreBatteryOptimizations.request().isGranted) {}
      await openAppSettings();
    } catch (e) {
      debugPrint("Hata: $e");
    }
  }
}
