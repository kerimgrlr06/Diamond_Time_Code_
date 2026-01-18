import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VakitServisi {
  static const String baseUrl = "https://ezanvakti.herokuapp.com";

  /// ✅ VAKİTLERİ GETİR (Gelişmiş Cache Mantığı)
  /// İnternet olmasa bile son çekilen 1 aylık veriyi saniyeler içinde yükler.
  static Future<List<dynamic>> vakitleriGetir(String ilceId) async {
    final prefs = await SharedPreferences.getInstance();
    final String cacheKey = 'vakitler_cache_$ilceId';

    // 1. Önce Hafızadaki Veriye Bak (Performans için)
    String? cachedData = prefs.getString(cacheKey);

    try {
      // 2. İnternetten Güncel Veriyi Çekmeye Çalış
      final response = await http
          .get(Uri.parse("$baseUrl/vakitler/$ilceId"))
          .timeout(
            const Duration(seconds: 8),
          ); // 8 saniye sınırı (Donmayı engeller)

      if (response.statusCode == 200) {
        // Yeni veriyi kaydet ve dön
        await prefs.setString(cacheKey, response.body);
        return json.decode(response.body);
      }
    } catch (e) {
      // İnternet hatası veya zaman aşımı durumunda sessizce cache'e dön
      print("Vakit API Hatası: $e");
    }

    // 3. Eğer internet yoksa veya hata alındıysa eski veriyi döndür
    return cachedData != null ? json.decode(cachedData) : [];
  }

  /// ✅ BUGÜNÜN VERİSİNİ BUL (Hatasız Filtreleme)
  static Map<String, dynamic>? bugununVerisiniBul(
    List<dynamic> tumVakitler, {
    DateTime? tarih,
  }) {
    if (tumVakitler.isEmpty) return null;

    DateTime hedefTarih = tarih ?? DateTime.now();

    // Diyanet formatı GG.AA.YYYY olduğundan emin oluyoruz
    String gun = hedefTarih.day.toString().padLeft(2, '0');
    String ay = hedefTarih.month.toString().padLeft(2, '0');
    String yil = hedefTarih.year.toString();
    String hedefStr = "$gun.$ay.$yil";

    try {
      return tumVakitler.firstWhere(
        (v) => v['MiladiTarihKisa'] == hedefStr,
        orElse: () => _enYakinVeriyiBul(tumVakitler, hedefTarih),
      );
    } catch (e) {
      return tumVakitler.isNotEmpty ? tumVakitler.first : null;
    }
  }

  /// Eğer tam tarih bulunamazsa (gece yarısı geçişleri vb.) listedeki ilk geçerli veriyi alır
  static Map<String, dynamic> _enYakinVeriyiBul(
    List<dynamic> liste,
    DateTime hedef,
  ) {
    return liste.first;
  }

  // --- Dinamik Seçim Menüleri İçin Performanslı Metodlar ---

  static Future<List<dynamic>> ulkeleriGetir() async {
    return _fetchHelper("$baseUrl/ulkeler");
  }

  static Future<List<dynamic>> sehirleriGetir(String ulkeId) async {
    return _fetchHelper("$baseUrl/sehirler/$ulkeId");
  }

  static Future<List<dynamic>> ilceleriGetir(String sehirId) async {
    return _fetchHelper("$baseUrl/ilceler/$sehirId");
  }

  /// Tekrarlayan HTTP istekleri için yardımcı metod
  static Future<List<dynamic>> _fetchHelper(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return json.decode(res.body);
    } catch (e) {
      print("API Fetch Error: $e");
    }
    return [];
  }
}
