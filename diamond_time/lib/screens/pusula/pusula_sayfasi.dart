import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import '../../services/konum_servisi.dart'; // ✅ Mevcut servis entegrasyonu

class PusulaSayfasi extends StatefulWidget {
  final Color anaRenk; // ✅ Vakte göre değişen dinamik renk
  const PusulaSayfasi({super.key, this.anaRenk = Colors.blueAccent});

  @override
  State<PusulaSayfasi> createState() => _PusulaSayfasiState();
}

class _PusulaSayfasiState extends State<PusulaSayfasi>
    with SingleTickerProviderStateMixin {
  static Coordinates? _cachedC;
  static double? _cachedQibla;
  double? _heading;
  String _durum = "Konum ve sensör bekleniyor...";

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    // ✅ PERFORMANS: KonumServisi'ndeki hazır veriyi kullanıyoruz
    if (KonumServisi.coords != null) {
      _cachedC = KonumServisi.coords;
      _cachedQibla = Qibla(_cachedC!).direction;
      _dinlemeyeBasla();
      return;
    }

    try {
      Position p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _cachedC = Coordinates(p.latitude, p.longitude);
      _cachedQibla = Qibla(_cachedC!).direction;
      _dinlemeyeBasla();
    } catch (e) {
      if (mounted) setState(() => _durum = "Konum alınamadı. GPS açık mı?");
    }
  }

  void _dinlemeyeBasla() {
    FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      setState(() => _heading = event.heading);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kabe hassasiyeti (5 derece tolerans)
    bool kabeBulundu =
        (_heading != null && _cachedQibla != null) &&
        ((_heading! - _cachedQibla!).abs() < 5);

    if (kabeBulundu) {
      HapticFeedback.selectionClick(); // ✅ Bulunduğunda pırlanta gibi titret
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // ✅ Shell gradientini kullanır
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "KIBLE PUSULASI",
          style: TextStyle(
            letterSpacing: 3,
            fontWeight: FontWeight.w100,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: _heading == null || _cachedQibla == null
            ? _yuklemeEkrani()
            : Stack(
                alignment: Alignment.center,
                children: [
                  // 1. Arka Plan Glow Efekti (Diamond Dokunuş)
                  _glowHalkasi(kabeBulundu),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _durumPaneli(kabeBulundu),
                      const SizedBox(height: 50),
                      _modernPusula(kabeBulundu),
                      const SizedBox(height: 60),
                      _bilgiPaneli(),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _glowHalkasi(bool aktif) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      width: 350,
      height: 350,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: aktif
                ? Colors.greenAccent.withValues(alpha: 0.2)
                : widget.anaRenk.withValues(alpha: 0.1),
            blurRadius: 120,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _durumPaneli(bool aktif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: aktif ? Colors.greenAccent : Colors.white10),
      ),
      child: Text(
        aktif ? "KIBLEYE YÖNELDİNİZ" : "CİHAZI ÇEVİRİN",
        style: TextStyle(
          color: aktif ? Colors.greenAccent : Colors.white54,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _modernPusula(bool aktif) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Dış Neon Halka
        Container(
          width: 320,
          height: 320,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.03),
              width: 1,
            ),
          ),
        ),

        // Dönen Pusula Diski
        Transform.rotate(
          angle: (_heading! * math.pi / 180) * -1,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(painter: PusulaCizici(widget.anaRenk)),
              ),
              Text(
                "N",
                style: TextStyle(
                  color: Colors.redAccent.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),

        // Kabe Göstergesi (Statik değil, Kıbleye göre yön bulur)
        Transform.rotate(
          angle: ((_heading! - _cachedQibla!) * math.pi / 180) * -1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 4,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      aktif ? Colors.greenAccent : Colors.orangeAccent,
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    if (aktif)
                      BoxShadow(
                        color: Colors.greenAccent.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Icon(
                Icons.mosque,
                color: aktif ? Colors.greenAccent : Colors.orangeAccent,
                size: 40,
              ),
              const SizedBox(height: 200), // Okun merkezden kaçıklığını ayarlar
            ],
          ),
        ),

        // Merkez Diamond Core
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E1A),
            shape: BoxShape.circle,
            border: Border.all(color: widget.anaRenk, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.anaRenk.withValues(alpha: 0.5),
                blurRadius: 15,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bilgiPaneli() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bilgiKutusu("PUSULA", "${_heading?.toInt() ?? 0}°"),
          Container(width: 1, height: 30, color: Colors.white10),
          _bilgiKutusu("KIBLE", "${_cachedQibla?.toInt() ?? 0}°"),
        ],
      ),
    );
  }

  Widget _bilgiKutusu(String baslik, String deger) {
    return Column(
      children: [
        Text(
          baslik,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          deger,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w200,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _yuklemeEkrani() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: widget.anaRenk, strokeWidth: 1),
          const SizedBox(height: 25),
          Text(
            _durum,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class PusulaCizici extends CustomPainter {
  final Color cizgiRengi;
  PusulaCizici(this.cizgiRengi);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 360; i += 10) {
      final double angle = i * math.pi / 180;
      final double startR = size.width / 2 - (i % 90 == 0 ? 25 : 12);
      final double endR = size.width / 2;
      canvas.drawLine(
        Offset(
          size.width / 2 + startR * math.cos(angle),
          size.height / 2 + startR * math.sin(angle),
        ),
        Offset(
          size.width / 2 + endR * math.cos(angle),
          size.height / 2 + endR * math.sin(angle),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
