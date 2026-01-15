import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:adhan/adhan.dart'; // ✅ AKTİF: Başlangıç parametreleri için

// ALT SAYFALAR
import '../vakitler/vakitler_sayfasi.dart';
import '../takvim/aylik_takvim_sayfasi.dart';
import '../zikir/zikirmatik_sayfasi.dart';
import '../pusula/pusula_sayfasi.dart';
import '../diger/diger_islemler_menu.dart';

// DRAWER SAYFALARI
import '../drawer/camiler_sayfasi.dart';
import '../drawer/dini_gunler_sayfasi.dart';
import '../drawer/kaza_namazi_sayfasi.dart';
import '../drawer/sozler_sayfasi.dart';
import '../drawer/manevi_paylasim_sayfasi.dart';
import '../drawer/ayarlar_sayfasi.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _secilenSayfaIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Widget? _aktifDigerAltSayfa;

  // ✅ DİNAMİK TEMA DEĞİŞKENLERİ
  Color _anaRenk = Colors.blueAccent;
  List<Color> _arkaPlanGradient = [
    const Color(0xFF0A0E1A),
    const Color(0xFF161B2E),
  ];

  @override
  void initState() {
    super.initState();
    _baslangicAyarlariniYap();
  }

  // ✅ adhan IMPORTU BURADA AKTİF
  void _baslangicAyarlariniYap() {
    // Türkiye için Diyanet hesaplama parametrelerini önbelleğe hazırla
    final params = CalculationMethod.turkey.getParameters();
    params.madhab = Madhab.shafi;
  }

  // ✅ TEMA MOTORU: Vakitler sayfasından gelen rengi tüm uygulamaya yayar
  void _temaGuncelle(Color yeniRenk, List<Color> yeniGradient) {
    if (mounted) {
      setState(() {
        _anaRenk = yeniRenk;
        _arkaPlanGradient = yeniGradient;
      });
    }
  }

  void _sayfaDegistir(int index) {
    setState(() {
      _secilenSayfaIndex = index;
      if (index != 4) _aktifDigerAltSayfa = null;
    });
  }

  void _digerAltSayfaAc(Widget sayfa) {
    setState(() => _aktifDigerAltSayfa = sayfa);
  }

  void _digerMenuyeDon() {
    setState(() => _aktifDigerAltSayfa = null);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _secilenSayfaIndex == 0 && _aktifDigerAltSayfa == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_aktifDigerAltSayfa != null) {
          _digerMenuyeDon();
        } else if (_secilenSayfaIndex != 0) {
          _sayfaDegistir(0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(
          seconds: 2,
        ), // Diamond kalitesinde yumuşak geçiş
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _arkaPlanGradient,
          ),
        ),
        child: Scaffold(
          key: _scaffoldKey,
          extendBody: true,
          backgroundColor: Colors.transparent, // Gradientin görünmesi için şart
          drawer: _modernYanMenu(),
          body: Stack(
            children: [
              // Sağ üstteki neon parlama vakit rengine duyarlı
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _anaRenk.withValues(alpha: 0.08),
                  ),
                ),
              ),
              // ✅ PERFORMANS MÜHRÜ: IndexedStack sayfaları bellekte tutar, geçişler 0ms sürer
              IndexedStack(
                index: _secilenSayfaIndex,
                children: [
                  VakitlerSayfasi(
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                    onThemeChanged: _temaGuncelle, // Tema bağlantısı
                  ),
                  const AylikTakvimSayfasi(),
                  const ZikirmatikSayfasi(),
                  const PusulaSayfasi(),
                  _aktifDigerAltSayfa ??
                      DigerIslemlerMenu(onSayfaSec: _digerAltSayfaAc),
                ],
              ),
            ],
          ),
          floatingActionButton: _modernOrtaButon(),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: _modernAltMenu(),
        ),
      ),
    );
  }

  Widget _modernYanMenu() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0E1A).withValues(alpha: 0.95),
      child: Column(
        children: [
          _drawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _drawerItem(
                  Icons.mosque_outlined,
                  "Yakındaki Camiler",
                  const CamilerSayfasi(),
                ),
                _drawerItem(
                  Icons.nights_stay_outlined,
                  "Dini Gün ve Geceler",
                  DiniGunlerSayfasi(
                    anaRenk: _anaRenk,
                  ), // ✅ anaRenk parametresini buraya ekledik
                ),
                _drawerItem(
                  Icons.history_edu_outlined,
                  "Kaza Namazı Takibi",
                  const KazaNamaziSayfasi(anaRenk: Colors.blueAccent),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Divider(color: Colors.white10),
                ),
                _drawerItem(
                  Icons.format_quote,
                  "Günün Sözü",
                  const SozlerSayfasi(anaRenk: Colors.blueAccent),
                ),
                _drawerItem(
                  Icons.image_outlined,
                  "Duvar Kağıtları",
                  const ManeviPaylasimSayfasi(anaRenk: Colors.blueAccent),
                ),
                _drawerItem(
                  Icons.settings_suggest_outlined,
                  "Ayarlar",
                  const AyarlarSayfasi(),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "DIAMOND TIME v2.1",
              style: TextStyle(
                color: Colors.white24,
                letterSpacing: 2,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_anaRenk.withValues(alpha: 0.15), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: _anaRenk),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF0F172A),
              child: Icon(Icons.auto_awesome, color: _anaRenk),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Diamond Time",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                "Diamond Müminler İçin",
                style: TextStyle(color: _anaRenk, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modernOrtaButon() {
    return Container(
      height: 75,
      width: 75,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _anaRenk.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        backgroundColor: const Color(0xFF1E293B),
        shape: const CircleBorder(),
        elevation: 0,
        onPressed: () => _sayfaDegistir(2),
        child: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [_anaRenk, Colors.cyanAccent],
          ).createShader(bounds),
          child: const Icon(Icons.fingerprint, size: 40, color: Colors.white),
        ),
      ),
    );
  }

  Widget _modernAltMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _altMenuButonu(0, Icons.grid_view_rounded, "Vakitler"),
              _altMenuButonu(1, Icons.calendar_today_rounded, "Takvim"),
              const SizedBox(width: 50),
              _altMenuButonu(3, Icons.explore_rounded, "Kıble"),
              _altMenuButonu(4, Icons.more_horiz_rounded, "Diğer"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _altMenuButonu(int index, IconData icon, String label) {
    final bool secili = _secilenSayfaIndex == index;
    return GestureDetector(
      onTap: () => _sayfaDegistir(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: secili
                    ? _anaRenk.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: secili ? _anaRenk : Colors.white38,
                size: 26,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: secili ? Colors.white : Colors.white38,
                fontSize: 9,
                fontWeight: secili ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, Widget sayfa) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white.withValues(alpha: 0.03),
      ),
      child: ListTile(
        leading: Icon(icon, color: _anaRenk, size: 22),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.white24,
          size: 18,
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => sayfa));
        },
      ),
    );
  }
}
