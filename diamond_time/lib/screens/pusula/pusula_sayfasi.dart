import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import '../../services/konum_servisi.dart';

class PusulaSayfasi extends StatefulWidget {
  final Color anaRenk; // ✅ HomeShell'den gelen dinamik renk
  const PusulaSayfasi({super.key, this.anaRenk = Colors.blueAccent});

  @override
  State<PusulaSayfasi> createState() => _PusulaSayfasiState();
}

class _PusulaSayfasiState extends State<PusulaSayfasi> {
  Coordinates? _coords;
  double? _qiblaDirection;
  double? _heading;
  String _durum = "Konum ve sensör bekleniyor...";
  bool _isVibrating = false;

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    // Performans: Önce servisteki hazır konumu kontrol et
    if (KonumServisi.coords != null) {
      _coords = KonumServisi.coords;
      _qiblaDirection = Qibla(_coords!).direction;
      _dinlemeyeBasla();
      return;
    }

    try {
      Position p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      _coords = Coordinates(p.latitude, p.longitude);
      _qiblaDirection = Qibla(_coords!).direction;
      _dinlemeyeBasla();
    } catch (e) {
      if (mounted) setState(() => _durum = "Konum alınamadı. GPS açık mı?");
    }
  }

  void _dinlemeyeBasla() {
    FlutterCompass.events?.listen((event) {
      if (!mounted) return;

      // Performans: Sadece 1 dereceden fazla değişim olduğunda ekranı yenile
      if (_heading == null || (event.heading! - _heading!).abs() > 1) {
        setState(() {
          _heading = event.heading;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Kabe hassasiyeti (5 derece tolerans)
    bool kabeBulundu =
        (_heading != null && _qiblaDirection != null) &&
        ((_heading! - _qiblaDirection!).abs() < 5);

    if (kabeBulundu && !_isVibrating) {
      _isVibrating = true;
      HapticFeedback.lightImpact();
      Future.delayed(
        const Duration(milliseconds: 1500),
        () => _isVibrating = false,
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
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
      body: SizedBox.expand(
        child: _heading == null || _qiblaDirection == null
            ? _yuklemeEkrani()
            : Stack(
                alignment: Alignment.center,
                children: [
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
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: aktif
                ? Colors.greenAccent.withAlpha(40)
                : widget.anaRenk.withAlpha(20),
            blurRadius: 100,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _durumPaneli(bool aktif) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
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
              const Text(
                "N",
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
        ),

        // Kabe Göstergesi
        Transform.rotate(
          angle: ((_heading! - _qiblaDirection!) * math.pi / 180) * -1,
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
                ),
              ),
              const SizedBox(height: 10),
              Icon(
                Icons.mosque,
                color: aktif ? Colors.greenAccent : Colors.orangeAccent,
                size: 40,
              ),
              const SizedBox(height: 200),
            ],
          ),
        ),

        // Merkez Nokta
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: widget.anaRenk.withAlpha(150), blurRadius: 10),
            ],
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
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _bilgiKutusu("CİHAZ AÇISI", "${_heading?.toInt() ?? 0}°"),
          Container(width: 1, height: 30, color: Colors.white10),
          _bilgiKutusu("KIBLE AÇISI", "${_qiblaDirection?.toInt() ?? 0}°"),
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
            style: const TextStyle(color: Colors.white38, fontSize: 11),
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
      ..color = Colors.white.withAlpha(25)
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
