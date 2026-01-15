import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class ZikirmatikSayfasi extends StatefulWidget {
  // ✅ HomeShell'den gelen dinamik rengi alıyoruz
  final Color anaRenk;
  const ZikirmatikSayfasi({super.key, this.anaRenk = Colors.blueAccent});

  @override
  State<ZikirmatikSayfasi> createState() => _ZikirmatikSayfasiState();
}

class _ZikirmatikSayfasiState extends State<ZikirmatikSayfasi>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  int _target = 33;
  bool _titresimAcik = true;
  late SharedPreferences _prefs;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.90,
      upperBound: 1.0,
    );
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _count = _prefs.getInt('zikir_count') ?? 0;
      _target = _prefs.getInt('zikir_target') ?? 33;
      _titresimAcik = _prefs.getBool('titresim') ?? true;
    });
  }

  // ✅ GARANTİ TİTREŞİM VE TEBRİK MANTIĞI
  void _artir() {
    _animationController.forward().then(
      (value) => _animationController.reverse(),
    );

    setState(() {
      _count++;
      _prefs.setInt('zikir_count', _count);
    });

    if (_titresimAcik) {
      if (_count % _target == 0) {
        // 🎯 Hedefte çok güçlü geri bildirim
        HapticFeedback.vibrate();
        Future.delayed(
          const Duration(milliseconds: 100),
          () => HapticFeedback.vibrate(),
        );
        _tebrikDialogGoster();
      } else {
        // ⚙️ Her tıkta "Tık" hissi veren stabil metod
        HapticFeedback.mediumImpact();
      }
    }
  }

  // 🏆 HEDEF KUTLAMA EKRANI (Hata Giderildi)
  void _tebrikDialogGoster() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B).withValues(alpha: 0.9),
          // ✅ HATA DÜZELTİLDİ: border yerine shape side kullanıldı
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: BorderSide(color: widget.anaRenk.withValues(alpha: 0.3)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: widget.anaRenk, size: 60),
              const SizedBox(height: 20),
              const Text(
                "MAŞALLAH",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$_target zikirlik hedefinize ulaştınız.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.anaRenk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
                onPressed: () {
                  setState(() => _count = 0);
                  _prefs.setInt('zikir_count', 0);
                  Navigator.pop(context);
                },
                child: const Text(
                  "BAŞTAN BAŞLA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "DEVAM ET",
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sifirla() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.white10),
          ),
          title: const Text(
            "Sıfırlansın mı?",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İPTAL"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                setState(() => _count = 0);
                _prefs.setInt('zikir_count', 0);
                Navigator.pop(context);
              },
              child: const Text(
                "SIFIRLA",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_count % _target) / _target;
    if (_count > 0 && _count % _target == 0) progress = 1.0;

    return Scaffold(
      backgroundColor:
          Colors.transparent, // ✅ HomeShell'in gradientini kullanır
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "ZİKİRMATİK",
          style: TextStyle(
            letterSpacing: 3,
            fontWeight: FontWeight.w100,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white38),
            onPressed: _sifirla,
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Arkaplan Neon Dokunuşu (Hata Giderildi)
          Positioned(
            top: 100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ✅ HATA DÜZELTİLDİ: blurRadius boxShadow içine taşındı
                boxShadow: [
                  BoxShadow(
                    color: widget.anaRenk.withValues(alpha: 0.1),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hedef Göstergesi
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: widget.anaRenk.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  "HEDEF: $_target",
                  style: TextStyle(
                    color: widget.anaRenk,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 50),

              // ✅ ANA ZİKİR BUTONU
              GestureDetector(
                onTap: _artir,
                child: ScaleTransition(
                  scale: _animationController,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dış Neon Halka
                      SizedBox(
                        width: 300,
                        height: 300,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.anaRenk,
                          ),
                        ),
                      ),
                      // İç Buton
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.anaRenk.withValues(alpha: 0.15),
                              blurRadius: 40,
                              spreadRadius: 5,
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(10, 10),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "$_count",
                              style: const TextStyle(
                                fontSize: 90,
                                fontWeight: FontWeight.w100,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              "ZİKİR",
                              style: TextStyle(
                                color: widget.anaRenk.withValues(alpha: 0.5),
                                letterSpacing: 8,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),

              // Alt Kontroller
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _altButon(Icons.track_changes, _hedefSec),
                  const SizedBox(width: 40),
                  _altButon(
                    _titresimAcik ? Icons.vibration : Icons.vibration_outlined,
                    () {
                      setState(() => _titresimAcik = !_titresimAcik);
                      _prefs.setBool('titresim', _titresimAcik);
                      if (_titresimAcik) HapticFeedback.mediumImpact();
                    },
                    isActive: _titresimAcik,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _altButon(IconData icon, VoidCallback tap, {bool isActive = false}) {
    return GestureDetector(
      onTap: tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isActive
              ? widget.anaRenk.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? widget.anaRenk.withValues(alpha: 0.4)
                : Colors.white10,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? widget.anaRenk : Colors.white38,
          size: 26,
        ),
      ),
    );
  }

  void _hedefSec() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "HEDEF SEÇİN",
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [33, 99, 100, 1000]
                  .map(
                    (v) => GestureDetector(
                      onTap: () {
                        setState(() => _target = v);
                        _prefs.setInt('zikir_target', v);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 15,
                        ),
                        decoration: BoxDecoration(
                          color: _target == v
                              ? widget.anaRenk
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          "$v",
                          style: TextStyle(
                            color: _target == v ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
