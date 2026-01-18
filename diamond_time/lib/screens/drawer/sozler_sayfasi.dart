import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SozlerSayfasi extends StatefulWidget {
  final VoidCallback? onGeri;
  final Color anaRenk;

  const SozlerSayfasi({
    super.key,
    this.onGeri,
    this.anaRenk = Colors.blueAccent,
  });

  @override
  State<SozlerSayfasi> createState() => _SozlerSayfasiState();
}

class _SozlerSayfasiState extends State<SozlerSayfasi> {
  List<String> _sozlerListesi = [];
  String _gununSozu = "Hikmetli bir söz yükleniyor...";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Önce Local Cache'den veriyi oku (Hız için)
    final String? cachedData = prefs.getString('sozler_cache');
    if (cachedData != null) {
      if (mounted) {
        setState(() {
          _sozlerListesi = List<String>.from(json.decode(cachedData));
          _gununSozuBelirle();
        });
      }
    }

    // 2. Güncel listeyi GitHub'dan çek
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://raw.githubusercontent.com/kerimgrlr06/Diamond_Time_Code_/refs/heads/main/diamond_time/sozler.json',
            ),
          )
          .timeout(const Duration(seconds: 10)); // Bağlantı zaman aşımı eklendi

      if (response.statusCode == 200) {
        // Türkçe karakter desteği için utf8.decode kullanımı önemli
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        final List<String> yeniListe = List<String>.from(data);

        await prefs.setString('sozler_cache', json.encode(yeniListe));

        if (mounted) {
          setState(() {
            _sozlerListesi = yeniListe;
            _gununSozuBelirle();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Veri çekme hatası: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _gununSozuBelirle() {
    if (_sozlerListesi.isNotEmpty) {
      // Listenin uzunluğu değişse bile hata almamak için mod işlemi
      int index = DateTime.now().day % _sozlerListesi.length;
      setState(() {
        _gununSozu = _sozlerListesi[index];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "HİKMETLİ SÖZLER",
          style: TextStyle(
            letterSpacing: 3,
            fontWeight: FontWeight.w200, // Biraz daha zarif bir görünüm
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
          onPressed: widget.onGeri ?? () => Navigator.maybePop(context),
        ),
      ),
      body: _isLoading && _sozlerListesi.isEmpty
          ? Center(child: CircularProgressIndicator(color: widget.anaRenk))
          : Stack(
              children: [
                _arkaPlanIsigi(),
                RefreshIndicator(
                  // Aşağı çekerek yenileme özelliği eklendi
                  onRefresh: _verileriYukle,
                  color: widget.anaRenk,
                  backgroundColor: Colors.grey[900],
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                    children: [
                      _gununSozuBolumu(),
                      const SizedBox(height: 35),
                      _listeBasligi("SÖZLER KÜTÜPHANESİ"),
                      const SizedBox(height: 15),
                      ..._sozlerListesi.map((soz) => _sozKarti(soz)).toList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _arkaPlanIsigi() {
    return Positioned(
      top: 100,
      left: -150,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.anaRenk.withOpacity(0.1),
              blurRadius: 200,
              spreadRadius: 50,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gununSozuBolumu() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.anaRenk.withOpacity(0.2),
            widget.anaRenk.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: widget.anaRenk.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, color: widget.anaRenk, size: 45),
          const SizedBox(height: 15),
          Text(
            "GÜNÜN İLHAMI",
            style: TextStyle(
              color: widget.anaRenk.withOpacity(0.7),
              letterSpacing: 3,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 25),
          Text(
            _gununSozu,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Share.share("$_gununSozu\n\nDiamond Time ✨"),
            icon: const Icon(
              Icons.share_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: const Text(
              "HİKMETİ PAYLAŞ",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.anaRenk.withOpacity(0.3),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: widget.anaRenk.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _listeBasligi(String metin) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Text(
        metin,
        style: TextStyle(
          color: widget.anaRenk,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _sozKarti(String soz) {
    bool isGununSozu = soz == _gununSozu;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isGununSozu
            ? widget.anaRenk.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGununSozu
              ? widget.anaRenk.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: Icon(
          isGununSozu ? Icons.auto_awesome : Icons.format_quote_rounded,
          color: isGununSozu ? widget.anaRenk : Colors.white24,
          size: 24,
        ),
        title: Text(
          soz,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        onTap: () => Share.share("$soz\n\nDiamond Time"),
      ),
    );
  }
}
