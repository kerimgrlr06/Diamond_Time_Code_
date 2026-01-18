import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri_date_time/hijri_date_time.dart';
import 'package:intl/intl.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/bildirim_servisi.dart';
import '../../services/konum_servisi.dart';
import '../drawer/widgets/gunun_ayeti_kart.dart';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  // HomeWidget etkileşimi için gerekli altyapı
}

class VakitlerSayfasi extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final Function(Color, List<Color>)? onThemeChanged;

  const VakitlerSayfasi({super.key, this.onMenuTap, this.onThemeChanged});

  @override
  State<VakitlerSayfasi> createState() => _VakitlerSayfasiState();
}

class _VakitlerSayfasiState extends State<VakitlerSayfasi>
    with WidgetsBindingObserver {
  PrayerTimes? prayerTimes;
  PrayerTimes? bugununVakitleri;
  Timer? _timer;
  DateTime _secilenTarih = DateTime.now();

  final ValueNotifier<String> _kalanSureNotifier = ValueNotifier<String>(
    "00:00:00",
  );
  final ValueNotifier<double> _carkIlerlemeNotifier = ValueNotifier<double>(
    0.0,
  );

  String _sayacVakitIsmi = "";
  Color _anaRenk = Colors.blueAccent;
  List<Color> _arkaPlanGradient = [
    const Color(0xFF0A0E1A),
    const Color(0xFF161B2E),
  ];
  bool _yukleniyor = true;
  bool _konumGuncelleniyor = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      try {
        HomeWidget.registerInteractivityCallback(backgroundCallback);
      } catch (_) {}
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _verileriYukle());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _kalanSureNotifier.dispose();
    _carkIlerlemeNotifier.dispose();
    super.dispose();
  }

  Future<void> _verileriYukle() async {
    if (!mounted) return;
    setState(() => _yukleniyor = true);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('son_ziyaret', DateTime.now().toIso8601String());
    await KonumServisi.ilkKurulum();
    _hesaplamalariYap();
    _sayaciBaslat();
    if (mounted) setState(() => _yukleniyor = false);
  }

  Future<void> _konumuYenile() async {
    if (_konumGuncelleniyor) return;
    setState(() => _konumGuncelleniyor = true);
    await KonumServisi.zorlaGuncelle();
    _hesaplamalariYap();
    if (mounted) {
      setState(() => _konumGuncelleniyor = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Konum ve vakitler güncellendi"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _hesaplamalariYap() {
    final coords = KonumServisi.coords ?? Coordinates(39.9334, 32.8597);
    final params = CalculationMethod.turkey.getParameters();
    params.madhab = Madhab.shafi;

    prayerTimes = PrayerTimes(
      coords,
      DateComponents.from(_secilenTarih),
      params,
    );
    bugununVakitleri = PrayerTimes(
      coords,
      DateComponents.from(DateTime.now()),
      params,
    );

    // ✅ DÜZELTİLDİ: Bildirim servisine artık PrayerTimes değil, coords ve params gönderiyoruz.
    if (!kIsWeb && bugununVakitleri != null) {
      BildirimServisi.tumVakitleriSenkronizeEt(coords, params);
    }
    _zamanHesapla();
  }

  void _sayaciBaslat() {
    _timer?.cancel();
    _zamanHesapla();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _zamanHesapla());
  }

  void _zamanHesapla() {
    if (!mounted || bugununVakitleri == null) return;
    final simdi = DateTime.now();
    final current = bugununVakitleri!.currentPrayer();
    final next = bugununVakitleri!.nextPrayer();

    DateTime nextTime = (next == Prayer.none)
        ? bugununVakitleri!.fajr.add(const Duration(days: 1))
        : bugununVakitleri!.timeForPrayer(next)!;

    final fark = nextTime.difference(simdi);
    _kalanSureNotifier.value = _formatDuration(fark);

    final baslangic = bugununVakitleri!.timeForPrayer(
      current == Prayer.none ? Prayer.isha : current,
    )!;
    final toplamSaniye = nextTime.difference(baslangic).inSeconds;
    final gecenSaniye = simdi.difference(baslangic).inSeconds;
    _carkIlerlemeNotifier.value = (gecenSaniye / toplamSaniye).clamp(0.0, 1.0);

    String vakitTr = _vakitIsmiTr(
      current == Prayer.none ? Prayer.isha : current,
    );

    // Performans için sadece vakit değiştiğinde setState yapıyoruz
    if (_sayacVakitIsmi != vakitTr) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _sayacVakitIsmi = vakitTr;
            _temaGuncelle(vakitTr);
          });
        }
      });
    }
  }

  void _temaGuncelle(String vakit) {
    _anaRenk = _vakitRengiGetir(vakit);
    _arkaPlanGradient = _vakitGradientGetir(vakit);
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(_anaRenk, _arkaPlanGradient);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_yukleniyor || prayerTimes == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_open_rounded, color: Colors.white),
          onPressed: widget.onMenuTap,
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              DateFormat("d MMMM yyyy", "tr_TR").format(_secilenTarih),
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
            Text(
              _hicriTarihGetir(),
              style: TextStyle(fontSize: 11, color: _anaRenk.withAlpha(180)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _konumuYenile,
            icon: _konumGuncelleniyor
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white38,
                    ),
                  )
                : const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white38,
                    size: 18,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  KonumServisi.adres.split(' / ').first,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  KonumServisi.adres.contains('/')
                      ? KonumServisi.adres.split(' / ').last
                      : "",
                  style: TextStyle(
                    fontSize: 10,
                    color: _anaRenk.withAlpha(230),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _anaSayacAlani(),
            const SizedBox(height: 20),
            _takvimSeridi(),
            const SizedBox(height: 25),
            _vakitListesi(),
            const SizedBox(height: 35),
            const GununAyetiKart(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _anaSayacAlani() {
    return Container(
      width: double.infinity,
      height: 240,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _carkIlerlemeNotifier,
              builder: (context, val, child) {
                return CustomPaint(
                  size: const Size(320, 180),
                  painter: KareIlerlemeBoyaci(ilerleme: val, renk: _anaRenk),
                );
              },
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _anaRenk.withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _anaRenk.withAlpha(50)),
                  ),
                  child: Text(
                    "Şuanki Vakit: $_sayacVakitIsmi",
                    style: TextStyle(
                      color: _anaRenk,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ValueListenableBuilder<String>(
                  valueListenable: _kalanSureNotifier,
                  builder: (context, val, child) => Text(
                    val,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w100,
                      color: Colors.white,
                      letterSpacing: 2,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _hicriTarihGetir() {
    final hicri = HijriDateTime.fromGregorian(_secilenTarih);
    const aylar = {
      1: "Muharrem",
      2: "Safer",
      3: "Rebiülevvel",
      4: "Rebiülahir",
      5: "Cemaziyelevvel",
      6: "Cemaziyelahir",
      7: "Recep",
      8: "Şaban",
      9: "Ramazan",
      10: "Şevval",
      11: "Zilkade",
      12: "Zilhicce",
    };
    return "${hicri.day} ${aylar[hicri.month]} ${hicri.year}";
  }

  Widget _takvimSeridi() {
    bool isBugunSecili = DateUtils.isSameDay(_secilenTarih, DateTime.now());
    return Column(
      children: [
        if (!isBugunSecili)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() {
                _secilenTarih = DateTime.now();
                _hesaplamalariYap();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _anaRenk.withAlpha(50),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  "BUGÜNE DÖN",
                  style: TextStyle(
                    color: _anaRenk,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(8),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white38,
                  size: 16,
                ),
                onPressed: () => setState(() {
                  _secilenTarih = _secilenTarih.subtract(
                    const Duration(days: 1),
                  );
                  _hesaplamalariYap();
                }),
              ),
              ...List.generate(5, (index) {
                DateTime date = _secilenTarih.add(Duration(days: index - 2));
                bool isSelected = DateUtils.isSameDay(date, _secilenTarih);
                bool isRealToday = DateUtils.isSameDay(date, DateTime.now());
                return GestureDetector(
                  onTap: () => setState(() {
                    _secilenTarih = date;
                    _hesaplamalariYap();
                  }),
                  child: Column(
                    children: [
                      Text(
                        DateFormat("E", "tr_TR").format(date).toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? _anaRenk : Colors.white24,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isRealToday
                              ? Border.all(
                                  color: _anaRenk.withAlpha(127),
                                  width: 1.5,
                                )
                              : null,
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [_anaRenk, _anaRenk.withAlpha(127)],
                                )
                              : null,
                        ),
                        child: Text(
                          "${date.day}",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white38,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              IconButton(
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white38,
                  size: 16,
                ),
                onPressed: () => setState(() {
                  _secilenTarih = _secilenTarih.add(const Duration(days: 1));
                  _hesaplamalariYap();
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vakitListesi() {
    return Column(
      children: [
        _vurguSatir("İmsak", prayerTimes!.fajr, Colors.amber),
        _vurguSatir("Güneş", prayerTimes!.sunrise, Colors.orange),
        _vurguSatir("Öğle", prayerTimes!.dhuhr, Colors.cyan),
        _vurguSatir("İkindi", prayerTimes!.asr, Colors.teal),
        _vurguSatir("Akşam", prayerTimes!.maghrib, Colors.deepOrangeAccent),
        _vurguSatir("Yatsı", prayerTimes!.isha, Colors.indigoAccent),
      ],
    );
  }

  Widget _vurguSatir(String ad, DateTime v, Color r) {
    bool isSuAn = _sayacVakitIsmi == ad;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: isSuAn ? r.withAlpha(30) : Colors.white.withAlpha(5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSuAn ? r.withAlpha(200) : Colors.white.withAlpha(13),
          width: isSuAn ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            ad,
            style: TextStyle(
              fontSize: 18,
              color: isSuAn ? Colors.white : Colors.white54,
            ),
          ),
          const Spacer(),
          Text(
            DateFormat.Hm().format(v),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isSuAn ? Colors.white : Colors.white38,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  String _vakitIsmiTr(Prayer p) =>
      {
        Prayer.fajr: "İmsak",
        Prayer.sunrise: "Güneş",
        Prayer.dhuhr: "Öğle",
        Prayer.asr: "İkindi",
        Prayer.maghrib: "Akşam",
        Prayer.isha: "Yatsı",
      }[p] ??
      "İmsak";

  Color _vakitRengiGetir(String v) =>
      {
        "İmsak": Colors.amber,
        "Güneş": Colors.orange,
        "Öğle": Colors.cyan,
        "İkindi": Colors.teal,
        "Akşam": Colors.deepOrangeAccent,
        "Yatsı": Colors.indigoAccent,
      }[v] ??
      Colors.blueAccent;

  List<Color> _vakitGradientGetir(String vakit) {
    switch (vakit) {
      case "İmsak":
      case "Güneş":
        return [const Color(0xFF1A0B2E), const Color(0xFF0A0E1A)];
      case "Öğle":
        return [const Color(0xFF0B243E), const Color(0xFF0A0E1A)];
      case "İkindi":
        return [const Color(0xFF2E1A0B), const Color(0xFF0A0E1A)];
      case "Akşam":
        return [const Color(0xFF3E140B), const Color(0xFF0A0E1A)];
      case "Yatsı":
        return [const Color(0xFF0A0E1A), const Color(0xFF161B2E)];
      default:
        return [const Color(0xFF0A0E1A), const Color(0xFF161B2E)];
    }
  }
}

class KareIlerlemeBoyaci extends CustomPainter {
  final double ilerleme;
  final Color renk;
  KareIlerlemeBoyaci({required this.ilerleme, required this.renk});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paintBase = Paint()
      ..color = Colors.white.withAlpha(5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final paintGlow = Paint()
      ..color = renk.withAlpha(76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final paintIlerleme = Paint()
      ..color = renk.withAlpha(230)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(30));
    canvas.drawRRect(rrect, paintBase);
    Path path = Path()..addRRect(rrect);

    for (PathMetric pathMetric in path.computeMetrics()) {
      Path extractPath = pathMetric.extractPath(
        0.0,
        pathMetric.length * ilerleme,
      );
      canvas.drawPath(extractPath, paintGlow);
      canvas.drawPath(extractPath, paintIlerleme);
    }
  }

  @override
  bool shouldRepaint(KareIlerlemeBoyaci oldDelegate) =>
      oldDelegate.ilerleme != ilerleme || oldDelegate.renk != renk;
}
