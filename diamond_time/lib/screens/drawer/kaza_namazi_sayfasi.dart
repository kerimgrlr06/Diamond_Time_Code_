import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui'; // ✅ Glassmorphism için

class KazaNamaziSayfasi extends StatefulWidget {
  final VoidCallback? onGeri;
  final bool geriButonuVarMi;
  final Color anaRenk; // ✅ HomeShell'den gelen vakit rengi

  const KazaNamaziSayfasi({
    super.key,
    this.onGeri,
    this.geriButonuVarMi = false,
    required this.anaRenk,
  });

  @override
  State<KazaNamaziSayfasi> createState() => _KazaState();
}

class _KazaState extends State<KazaNamaziSayfasi> {
  final Map<String, int> k = {
    "Sabah": 0,
    "Öğle": 0,
    "İkindi": 0,
    "Akşam": 0,
    "Yatsı": 0,
    "Vitir": 0,
  };

  int _toplamKaza = 0;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    final prefs = await SharedPreferences.getInstance();
    int toplam = 0;
    setState(() {
      for (final key in k.keys) {
        k[key] = prefs.getInt('kaza_$key') ?? 0;
        toplam += k[key]!;
      }
      _toplamKaza = toplam;
    });
  }

  Future<void> _kaydet(String key, int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('kaza_$key', val);
    _toplamHesapla();
  }

  void _toplamHesapla() {
    int toplam = 0;
    for (var v in k.values) {
      toplam += v;
    }
    setState(() => _toplamKaza = toplam);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // ✅ Shell Gradienti için
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "KAZA TAKİBİ",
          style: TextStyle(
            letterSpacing: 3,
            fontWeight: FontWeight.w100,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        leading: widget.onGeri != null
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: widget.onGeri,
              )
            : (widget.geriButonuVarMi
                  ? const BackButton(color: Colors.white)
                  : null),
      ),
      body: Stack(
        children: [
          // ✅ ATMOSFERİK IŞIK SIZMASI (Vakit Renginde)
          Positioned(
            bottom: 100,
            left: -150,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.anaRenk.withValues(alpha: 0.08),
                    blurRadius: 150,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              _ozetPanel(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                  physics: const BouncingScrollPhysics(),
                  children: k.keys.map((v) => _kazaKarti(v)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ozetPanel() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        // ✅ Dinamik Gradyan
        gradient: LinearGradient(
          colors: [
            widget.anaRenk.withValues(alpha: 0.2),
            widget.anaRenk.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: widget.anaRenk.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: widget.anaRenk.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: -10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TOPLAM BORÇ",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Namaz Kazası",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$_toplamKaza",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w100,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kazaKarti(String vakit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          // ✅ BUZLU CAM
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      vakit,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        _sayacButonu(Icons.remove, Colors.redAccent, () {
                          if (k[vakit]! > 0) {
                            setState(() => k[vakit] = k[vakit]! - 1);
                            _kaydet(vakit, k[vakit]!);
                          }
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "${k[vakit]}",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w200,
                              color: widget.anaRenk,
                            ),
                          ),
                        ),
                        _sayacButonu(Icons.add, widget.anaRenk, () {
                          setState(() => k[vakit] = k[vakit]! + 1);
                          _kaydet(vakit, k[vakit]!);
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ✅ Dinamik İlerleme Çubuğu
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: k[vakit]! > 1000
                        ? 1.0
                        : k[vakit]! / 1000, // Örnek hedef 1000
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.anaRenk.withValues(alpha: 0.6),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sayacButonu(IconData icon, Color renk, VoidCallback tap) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: renk.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: renk.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, color: renk, size: 22),
      ),
    );
  }
}
