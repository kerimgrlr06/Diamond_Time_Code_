import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

// ✅ EKLEDİĞİMİZ SERVİSİ IMPORT EDİYORUZ
import 'services/bildirim_servisi.dart';
import 'screens/home/home_shell.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  // 1. Flutter motorunu başlat
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Türkçe tarih desteği
  await initializeDateFormatting('tr_TR', null);

  // 3. Saat Dilimi Ayarları
  tz.initializeTimeZones();
  try {
    final dynamic currentTimeZone = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = currentTimeZone.toString();
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  } catch (e) {
    debugPrint("Zaman dilimi alınamadı: $e");
    tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
  }

  // 4. ✅ BİLDİRİM SERVİSİNİ BAŞLAT (Yeni eklenen satır)
  await BildirimServisi.baslat();

  // 5. Android 13+ İzin Talebi (Senin kodunda zaten var, korunuyor)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diamond Time',

      // Dil Ayarları
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),

        // Renk Şeması
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
          primary: Colors.blueAccent,
          secondary: Colors.cyanAccent,
          surface: const Color(0xFF161B2E),
        ),

        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),

        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),

        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.blueAccent
                : Colors.grey,
          ),
          trackColor: WidgetStateProperty.all(
            const Color(0xFF2E3B8F).withValues(alpha: 0.3),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        ),
      ),
      home: const HomeShell(),
    );
  }
}
