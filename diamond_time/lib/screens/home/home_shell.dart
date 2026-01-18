import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:adhan/adhan.dart';

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

  Color _anaRenk = Colors.blueAccent;
  List<Color> _arkaPlanGradient = [
    const Color(0xFF0A0E1A),
    const Color(0xFF161B2E),
  ];

  @override
  void initState() {
    super.initState();
    final params = CalculationMethod.turkey.getParameters();
    debugPrint("Adhan Sistemi Aktif: ${params.method}");
  }

  // ✅ MERKEZİ GERİ DÖNÜŞ MANTIĞI
  void _anaEkranaDon() {
    setState(() {
      _aktifDigerAltSayfa = null;
      _secilenSayfaIndex = 0;
    });
  }

  void _temaGuncelle(Color yeniRenk, List<Color> yeniGradient) {
    if (mounted && _anaRenk != yeniRenk) {
      setState(() {
        _anaRenk = yeniRenk;
        _arkaPlanGradient = yeniGradient;
      });
    }
  }

  void _sayfaDegistir(int index) {
    setState(() {
      _secilenSayfaIndex = index;
      _aktifDigerAltSayfa = null;
    });
  }

  void _yanMenuSayfasiAc(Widget sayfa) {
    setState(() {
      _aktifDigerAltSayfa = sayfa;
      _secilenSayfaIndex = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ PopScope: Beyaz ekrana düşmeyi engelleyen koruma kalkanı
    return PopScope(
      canPop: false, // Fiziksel geri tuşunun uygulamayı kapatmasını engeller
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Eğer bir alt sayfa (Ayarlar, Kaza vb.) açıksa onu kapat
        if (_aktifDigerAltSayfa != null) {
          setState(() => _aktifDigerAltSayfa = null);
        }
        // Eğer ana sekmelerden birindeyse (Pusula, Zikir vb.) vakitlere dön
        else if (_secilenSayfaIndex != 0) {
          setState(() => _secilenSayfaIndex = 0);
        }
      },
      child: Container(
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
          backgroundColor: Colors.transparent,
          drawer: _modernYanMenu(),
          body: IndexedStack(
            // ✅ Aktif alt sayfa varsa her zaman 4. indexi (Diğer) gösterir
            index: (_aktifDigerAltSayfa != null) ? 4 : _secilenSayfaIndex,
            children: [
              VakitlerSayfasi(
                onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                onThemeChanged: _temaGuncelle,
              ),
              AylikTakvimSayfasi(anaRenk: _anaRenk),
              ZikirmatikSayfasi(anaRenk: _anaRenk),
              PusulaSayfasi(anaRenk: _anaRenk),
              // ✅ 4. Index: Ya menü ya da seçilen yan sayfa görünür
              _aktifDigerAltSayfa ??
                  DigerIslemlerMenu(
                    onSayfaSec: (sayfa) =>
                        setState(() => _aktifDigerAltSayfa = sayfa),
                    anaRenk: _anaRenk,
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
      backgroundColor: const Color(0xFF0A0E1A).withAlpha(240),
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
                  "Dini Günler",
                  DiniGunlerSayfasi(anaRenk: _anaRenk),
                ),
                _drawerItem(
                  Icons.history_edu_outlined,
                  "Kaza Namazı",
                  KazaTakipSayfasi(anaRenk: _anaRenk, onGeri: _anaEkranaDon),
                ),
                const Divider(color: Colors.white10, height: 30),
                _drawerItem(
                  Icons.format_quote,
                  "Günün Sözü",
                  SozlerSayfasi(anaRenk: _anaRenk, onGeri: _anaEkranaDon),
                ),
                _drawerItem(
                  Icons.image_outlined,
                  "Duvar Kağıtları",
                  ManeviPaylasimSayfasi(
                    anaRenk: _anaRenk,
                    onGeri: _anaEkranaDon,
                  ),
                ),
                _drawerItem(
                  Icons.settings_suggest_outlined,
                  "Ayarlar",
                  AyarlarSayfasi(anaRenk: _anaRenk, onGeri: _anaEkranaDon),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, Widget sayfa) {
    return ListTile(
      leading: Icon(icon, color: _anaRenk, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      onTap: () {
        Navigator.pop(context); // Drawer'ı kapat
        _yanMenuSayfasiAc(sayfa);
      },
    );
  }

  Widget _drawerHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 30, left: 20),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: _anaRenk, size: 30),
          const SizedBox(width: 15),
          const Text(
            "Diamond Time",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernOrtaButon() {
    return FloatingActionButton(
      backgroundColor: const Color(0xFF1E293B),
      shape: const CircleBorder(),
      onPressed: () => _sayfaDegistir(2),
      child: Icon(Icons.fingerprint, color: _anaRenk, size: 35),
    );
  }

  Widget _modernAltMenu() {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 20),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withAlpha(180),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _altButon(0, Icons.grid_view_rounded),
              _altButon(1, Icons.calendar_today_rounded),
              const SizedBox(width: 50),
              _altButon(3, Icons.explore_rounded),
              _altButon(4, Icons.more_horiz_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _altButon(int index, IconData icon) {
    return IconButton(
      icon: Icon(
        icon,
        color: _secilenSayfaIndex == index ? _anaRenk : Colors.white38,
      ),
      onPressed: () => _sayfaDegistir(index),
    );
  }
}
