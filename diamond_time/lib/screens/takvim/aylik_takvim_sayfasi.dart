import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan/adhan.dart';
import '../../services/konum_servisi.dart';

class AylikTakvimSayfasi extends StatefulWidget {
  final Color anaRenk; // ✅ HomeShell'den gelen dinamik renk
  const AylikTakvimSayfasi({super.key, this.anaRenk = Colors.cyanAccent});

  @override
  State<AylikTakvimSayfasi> createState() => _AylikTakvimSayfasiState();
}

class _AylikTakvimSayfasiState extends State<AylikTakvimSayfasi> {
  static List<PrayerTimes> _takvimHafizasi = [];
  static int _kayitliAy = -1;
  static String _kayitliAdres = "";

  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _verileriHazirla();
  }

  Future<void> _verileriHazirla() async {
    DateTime simdi = DateTime.now();
    // Eğer aynı ay içindeysek ve konum değişmediyse hafızadan getir (Performans)
    if (_takvimHafizasi.isNotEmpty &&
        _kayitliAy == simdi.month &&
        _kayitliAdres == KonumServisi.adres) {
      if (mounted) setState(() => _yukleniyor = false);
      return;
    }
    _hesapla(simdi);
  }

  void _hesapla(DateTime n) {
    final coords = KonumServisi.coords ?? Coordinates(39.9334, 32.8597);
    final params = CalculationMethod.turkey.getParameters();
    params.madhab = Madhab.shafi;

    List<PrayerTimes> yeniListe = [];
    int ayinGunSayisi = DateTime(n.year, n.month + 1, 0).day;

    for (int i = 1; i <= ayinGunSayisi; i++) {
      yeniListe.add(
        PrayerTimes(
          coords,
          DateComponents.from(DateTime(n.year, n.month, i)),
          params,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _takvimHafizasi = yeniListe;
        _kayitliAy = n.month;
        _kayitliAdres = KonumServisi.adres;
        _yukleniyor = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor) {
      return Center(child: CircularProgressIndicator(color: widget.anaRenk));
    }

    final int bugun = DateTime.now().day;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          DateFormat('MMMM yyyy', 'tr_TR').format(DateTime.now()).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w100,
            letterSpacing: 4,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _tabloBasligi(),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 100),
              itemCount: _takvimHafizasi.length,
              itemBuilder: (context, index) {
                final vakit = _takvimHafizasi[index];
                final gun = index + 1;
                final isBugun = gun == bugun;
                return _vakitSatiri(vakit, gun, isBugun);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabloBasligi() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      margin: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.anaRenk.withAlpha(25)),
      ),
      child: Row(
        children: [
          _HicreHicre("GÜN", renk: widget.anaRenk.withAlpha(150)),
          const _HicreHicre("İMS"),
          const _HicreHicre("GNŞ"),
          const _HicreHicre("ÖĞL"),
          const _HicreHicre("İKN"),
          const _HicreHicre("AKŞ"),
          const _HicreHicre("YAT"),
        ],
      ),
    );
  }

  Widget _vakitSatiri(PrayerTimes v, int gn, bool isBugun) {
    final Color aktifRenk = isBugun ? widget.anaRenk : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: isBugun
            ? widget.anaRenk.withAlpha(13)
            : Colors.white.withAlpha(3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isBugun
              ? widget.anaRenk.withAlpha(127)
              : Colors.white.withAlpha(13),
          width: isBugun ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Text(
                "$gn",
                style: TextStyle(
                  color: isBugun ? widget.anaRenk : Colors.white54,
                  fontWeight: isBugun ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          _zamanHucre(v.fajr, isBugun, aktifRenk),
          _zamanHucre(v.sunrise, isBugun, aktifRenk),
          _zamanHucre(v.dhuhr, isBugun, aktifRenk),
          _zamanHucre(v.asr, isBugun, aktifRenk),
          _zamanHucre(v.maghrib, isBugun, aktifRenk),
          _zamanHucre(v.isha, isBugun, aktifRenk),
        ],
      ),
    );
  }

  Widget _zamanHucre(DateTime s, bool b, Color r) {
    return Expanded(
      child: Center(
        child: Text(
          DateFormat('HH:mm').format(s),
          style: TextStyle(
            color: b ? r : Colors.white70,
            fontSize: 13,
            fontWeight: b ? FontWeight.bold : FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

class _HicreHicre extends StatelessWidget {
  final String metin;
  final Color renk;
  const _HicreHicre(this.metin, {this.renk = Colors.white38});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          metin,
          style: TextStyle(
            color: renk,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
