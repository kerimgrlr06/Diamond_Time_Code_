import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class KonumServisi {
  static Coordinates? _coords;
  static String _adres = "Konum Alınıyor...";
  static bool _yuklendi = false;

  static Coordinates? get coords => _coords;
  static String get adres => _adres;
  static bool get yuklendi => _yuklendi;

  /// ✅ Uygulama açılışında çalışır. Önce hafızadaki konumu yükler,
  /// sonra arka planda güncel konumu sorgular (Sıfır bekleme/donma).
  static Future<void> ilkKurulum() async {
    bool cacheVarMi = await _cacheOku();

    if (cacheVarMi) {
      _yuklendi = true;
      // Hafızada veri varsa kullanıcı beklemez, arka planda sessizce güncelleme denenir
      _sessizGuncelle();
    } else {
      // Eğer uygulama ilk kez kurulduysa mecburen GPS beklenir
      await konumuSorgula();
    }
  }

  /// Kullanıcıyı bekletmeden arka planda konumu tazeler
  static void _sessizGuncelle() async {
    try {
      await konumuSorgula();
    } catch (e) {
      debugPrint("Arka plan konum güncelleme başarısız: $e");
    }
  }

  /// ✅ ZORLA GÜNCELLEME: Kullanıcı butona bastığında tetiklenir
  static Future<void> zorlaGuncelle() async {
    _yuklendi = false;
    await konumuSorgula();
  }

  /// 🛰️ GPS SORGULAMA MOTORU
  static Future<void> konumuSorgula() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (_coords == null)
            _varsayilanKonumuYukle(); // Hiç veri yoksa Ankara
          return;
        }
      }

      // Hızlı ve pil dostu sorgulama (10 saniye limitli)
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          distanceFilter: 500,
        ),
      ).timeout(const Duration(seconds: 10));

      _coords = Coordinates(position.latitude, position.longitude);

      // Koordinattan Adres Bulma (İnternet yavaşsa beklemez)
      try {
        List<Placemark> yerler = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(const Duration(seconds: 5));

        if (yerler.isNotEmpty) {
          Placemark yer = yerler.first;
          String ilce = yer.subAdministrativeArea ?? yer.locality ?? "";
          String sehir = yer.administrativeArea ?? "";
          _adres = ilce.isNotEmpty ? "$ilce / $sehir" : sehir;
        }
      } catch (_) {
        if (_adres == "Konum Alınıyor...") _adres = "Konum Belirlendi";
      }

      await _cacheKaydet();
      _yuklendi = true;
    } catch (e) {
      // ✅ KRİTİK DÜZELTME: Hata olsa bile Ankara'ya dönme!
      if (_coords != null) {
        debugPrint("Yeni konum alınamadı, eski konum korunuyor.");
        _yuklendi = true;
      } else {
        _varsayilanKonumuYukle(); // Sadece ilk açılışta ve veri yoksa
      }
    }
  }

  static Future<void> _cacheKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    if (_coords != null) {
      await prefs.setDouble('lat', _coords!.latitude);
      await prefs.setDouble('lng', _coords!.longitude);
      await prefs.setString('adres', _adres);
      await prefs.setInt('last_update', DateTime.now().millisecondsSinceEpoch);
    }
  }

  static Future<bool> _cacheOku() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      double? lat = prefs.getDouble('lat');
      double? lng = prefs.getDouble('lng');
      String? cachedAdres = prefs.getString('adres');

      if (lat != null && lng != null && cachedAdres != null) {
        _coords = Coordinates(lat, lng);
        _adres = cachedAdres;
        return true;
      }
    } catch (e) {
      debugPrint("Cache Hatası: $e");
    }
    return false;
  }

  /// Sadece veritabanı tamamen boşsa çalışır
  static void _varsayilanKonumuYukle() {
    _coords = Coordinates(39.9334, 32.8597);
    _adres = "Çankaya / Ankara";
    _yuklendi = true;
  }

  static Future<void> sifirla() async {
    _yuklendi = false;
    _coords = null;
    _adres = "Konum Alınıyor...";
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
