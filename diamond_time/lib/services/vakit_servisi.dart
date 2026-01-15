import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VakitServisi {
  static const String baseUrl = "https://ezanvakti.herokuapp.com";

  // ✅ HATA 1 ÇÖZÜMÜ: vakitleriGetir metodu eklendi
  static Future<List<dynamic>> vakitleriGetir(String ilceId) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final response = await http.get(Uri.parse("$baseUrl/vakitler/$ilceId"));
      if (response.statusCode == 200) {
        await prefs.setString('son_vakitler_$ilceId', response.body);
        return json.decode(response.body);
      }
    } catch (e) {
      String? yedek = prefs.getString('son_vakitler_$ilceId');
      if (yedek != null) return json.decode(yedek);
    }
    return [];
  }

  // ✅ HATA 2 ÇÖZÜMÜ: bugununVerisiniBul metodu eklendi
  static Map<String, dynamic>? bugununVerisiniBul(
    List<dynamic> tumVakitler, {
    DateTime? tarih,
  }) {
    if (tumVakitler.isEmpty) return null;

    DateTime hedefTarih = tarih ?? DateTime.now();
    // Diyanet formatı: GG.AA.YYYY (Örn: 27.12.2025)
    String hedefStr =
        "${hedefTarih.day.toString().padLeft(2, '0')}.${hedefTarih.month.toString().padLeft(2, '0')}.${hedefTarih.year}";

    try {
      return tumVakitler.firstWhere(
        (v) => v['MiladiTarihKisa'] == hedefStr,
        orElse: () => tumVakitler.first,
      );
    } catch (e) {
      return tumVakitler.first;
    }
  }

  // Alt menüler için gerekli olan diğer metodlar
  static Future<List<dynamic>> ulkeleriGetir() async {
    final response = await http.get(Uri.parse("$baseUrl/ulkeler"));
    return json.decode(response.body);
  }

  static Future<List<dynamic>> sehirleriGetir(String ulkeId) async {
    final response = await http.get(Uri.parse("$baseUrl/sehirler/$ulkeId"));
    return json.decode(response.body);
  }

  static Future<List<dynamic>> ilceleriGetir(String sehirId) async {
    final response = await http.get(Uri.parse("$baseUrl/ilceler/$sehirId"));
    return json.decode(response.body);
  }
}
