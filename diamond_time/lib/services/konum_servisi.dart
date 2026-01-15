import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan/adhan.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KonumServisi {
  static Coordinates? _coords;
  static String _adres = "Konum Alınıyor...";
  static bool _yuklendi = false;

  static Coordinates? get coords => _coords;
  static String get adres => _adres;
  static bool get yuklendi => _yuklendi;

  // ✅ ANA GİRİŞ: 30 dakikalık cache kontrolü yapar
  static Future<void> ilkKurulum() async {
    bool cacheYeterli = await _cacheOku(); //
    if (cacheYeterli) {
      _yuklendi = true;
      return; // 30 dk dolmadıysa GPS'i açma, performansı koru
    }
    await konumuSorgula(); // Süre dolduysa veya ilk açılışsa konumu al
  }

  // ✅ ZORLA GÜNCELLEME: Kullanıcı yer değiştirdiğinde butona basınca tetiklenir
  static Future<void> zorlaGuncelle() async {
    _yuklendi = false;
    await konumuSorgula();
  }

  // 🛰️ GPS SORGULAMA MOTORU
  static Future<void> konumuSorgula() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _varsayilanKonumAtla("İzin Verilmedi");
          return;
        }
      }

      // Hızlı sonuç için düşük doğruluk modu (Pil dostu Diamond seçim)
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.low,
        distanceFilter: 100,
      );

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      _coords = Coordinates(position.latitude, position.longitude);

      // Koordinattan Adres Bulma
      try {
        List<Placemark> yerler = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (yerler.isNotEmpty) {
          Placemark yer = yerler.first;
          String semt = yer.subLocality ?? yer.locality ?? "";
          String ilce = yer.subAdministrativeArea ?? "";
          String sehir = yer.administrativeArea ?? "";

          List<String> bilesenler = [];
          if (semt.isNotEmpty) bilesenler.add(semt);
          if (ilce.isNotEmpty && ilce != semt) bilesenler.add(ilce);
          if (sehir.isNotEmpty && sehir != ilce) bilesenler.add(sehir);
          _adres = bilesenler.join(" / ");
        }
      } catch (_) {
        _adres = "Konum Belirlendi";
      }

      await _cacheKaydet(); // Yeni konumu 30 dakikalık mühürle kaydet
      _yuklendi = true;
    } catch (e) {
      _varsayilanKonumAtla("Hata");
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
    final prefs = await SharedPreferences.getInstance();
    double? lat = prefs.getDouble('lat');
    double? lng = prefs.getDouble('lng');
    String? cachedAdres = prefs.getString('adres');
    int? lastUpdate = prefs.getInt('last_update');

    if (lat != null &&
        lng != null &&
        cachedAdres != null &&
        lastUpdate != null) {
      DateTime sonGuncelleme = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      Duration fark = DateTime.now().difference(sonGuncelleme);

      // ✅ 30 DAKİKA KURALI: Süre geçmediyse doğru (true) döner
      if (fark.inMinutes < 30) {
        _coords = Coordinates(lat, lng);
        _adres = cachedAdres;
        return true;
      }
    }
    return false;
  }

  static void _varsayilanKonumAtla(String mesaj) {
    _coords = Coordinates(39.9334, 32.8597);
    _adres = "Çankaya / Ankara / $mesaj";
    _yuklendi = true;
  }

  static void sifirla() async {
    _yuklendi = false;
    _coords = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
