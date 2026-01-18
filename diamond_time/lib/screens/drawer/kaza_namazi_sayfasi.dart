import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class KazaTakipSayfasi extends StatefulWidget {
  final VoidCallback? onGeri;
  final Color anaRenk;

  const KazaTakipSayfasi({super.key, this.onGeri, required this.anaRenk});

  @override
  State<KazaTakipSayfasi> createState() => _KazaTakipState();
}

class _KazaTakipState extends State<KazaTakipSayfasi>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // Takvimde haftalar arası gezinmek için controller
  final PageController _takvimPageController = PageController(initialPage: 500);

  final Map<String, int> namazKazalari = {
    "Sabah": 0,
    "Öğle": 0,
    "İkindi": 0,
    "Akşam": 0,
    "Yatsı": 0,
    "Vitir": 0,
  };
  final Map<String, int> orucKazalari = {
    "Ramazan Orucu": 0,
    "Kefaret Orucu": 0,
  };
  final Map<String, String> gunlukNamazDurumu = {
    "Sabah": "Bekliyor",
    "Öğle": "Bekliyor",
    "İkindi": "Bekliyor",
    "Akşam": "Bekliyor",
    "Yatsı": "Bekliyor",
  };
  final List<int> aylikBasariListesi = List.filled(32, 0);

  int _hedefOruc = 0;
  int _gunlukKazaHedefi = 1;
  DateTime _seciliGun = DateTime.now();
  final DateTime _bugun = DateTime.now(); // Bugünün referansı

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _verileriYukle();
  }

  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    String gunKey = DateFormat('yyyy-MM-dd').format(_seciliGun);
    String ayKey = DateFormat('yyyy-MM').format(_seciliGun);

    if (!mounted) return;

    for (int i = 1; i <= 31; i++) {
      int gunlukKili = 0;
      String tKey = "$ayKey-${i.toString().padLeft(2, '0')}";
      for (var v in gunlukNamazDurumu.keys) {
        if (prefs.getString('durum_${v}_$tKey') == "Kıldı") gunlukKili++;
      }
      aylikBasariListesi[i] = gunlukKili;
    }

    setState(() {
      _hedefOruc = prefs.getInt('kaza_oruc_hedef') ?? 0;
      _gunlukKazaHedefi = prefs.getInt('kaza_gunluk_hedef') ?? 1;

      namazKazalari.forEach(
        (k, v) => namazKazalari[k] = prefs.getInt('kaza_namaz_$k') ?? 0,
      );
      orucKazalari.forEach(
        (k, v) => orucKazalari[k] = prefs.getInt('kaza_oruc_$k') ?? 0,
      );
      gunlukNamazDurumu.forEach(
        (k, v) => gunlukNamazDurumu[k] =
            prefs.getString('durum_${k}_$gunKey') ?? "Bekliyor",
      );
    });
  }

  String _ongoruHesapla(int borc) {
    if (borc <= 0) return "Borç bitti!";
    int kalanGun = (borc / _gunlukKazaHedefi).ceil();
    if (kalanGun > 365)
      return "${(kalanGun / 365).toStringAsFixed(1)} yıl kaldı";
    return "$kalanGun gün kaldı";
  }

  // ✅ Geliştirilmiş Durum Güncelleme: Aynı butona basınca geri alma özelliği eklendi
  Future<void> _durumGuncelle(String vakit, String yeniDurum) async {
    final prefs = await SharedPreferences.getInstance();
    String gunKey = DateFormat('yyyy-MM-dd').format(_seciliGun);
    String eskiDurum = gunlukNamazDurumu[vakit]!;

    // Eğer zaten seçili olan butona basıldıysa durumu "Bekliyor"a çek (Geri al)
    String finalDurum = (eskiDurum == yeniDurum) ? "Bekliyor" : yeniDurum;

    setState(() {
      gunlukNamazDurumu[vakit] = finalDurum;

      // 1. Durum: Kılmadı seçildi (veya kılmadıdan başka bir şeye geçildi)
      if (finalDurum == "Kılmadı" && eskiDurum != "Kılmadı") {
        namazKazalari[vakit] = (namazKazalari[vakit] ?? 0) + 1;
      }
      // 2. Durum: Kılmadıdan vazgeçildi (Geri alındı veya Kıldıya geçildi)
      else if (eskiDurum == "Kılmadı" && finalDurum != "Kılmadı") {
        if (namazKazalari[vakit]! > 0) {
          namazKazalari[vakit] = namazKazalari[vakit]! - 1;
        }
      }

      prefs.setInt('kaza_namaz_$vakit', namazKazalari[vakit]!);
    });

    await prefs.setString('durum_${vakit}_$gunKey', finalDurum);
    _verileriYukle();
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
          "İBADET TAKİBİ",
          style: TextStyle(
            letterSpacing: 2,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: widget.onGeri,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: widget.anaRenk,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
          tabs: const [
            Tab(text: "ÇİZELGE"),
            Tab(text: "NAMAZ KAZA"),
            Tab(text: "ORUÇ KAZA"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCizelgeSekmesi(),
          _buildNamazKazaSekmesi(),
          _buildOrucKazaSekmesi(),
        ],
      ),
    );
  }

  Widget _buildCizelgeSekmesi() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildAylikIstikrarPaneli(),
        const SizedBox(height: 15),
        _buildModernOkTakvimi(), // ✅ Ok butonlu ve bugün parlamalı takvim
        const SizedBox(height: 25),
        const Text(
          "GÜNLÜK TAKİP",
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        ...gunlukNamazDurumu.keys.map((vakit) => _buildCizelgeItem(vakit)),
        const SizedBox(height: 150), // ✅ İstediğin 150px boşluk
      ],
    );
  }

  // ✅ Ok butonlu, sayfa kaydırmalı ve bugün parlamalı takvim
  Widget _buildModernOkTakvimi() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white38,
              size: 16,
            ),
            onPressed: () => _takvimPageController.previousPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _takvimPageController,
              onPageChanged: (index) {
                // Sayfa değiştiğinde istersen secili günü de güncelleyebilirsin
              },
              itemBuilder: (context, pageIndex) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(7, (index) {
                    // Sayfa indeksine göre haftalık tarih hesaplama
                    DateTime gun = _bugun.add(
                      Duration(days: (pageIndex - 500) * 7 + index - 3),
                    );
                    bool isSelected =
                        DateFormat('yyyy-MM-dd').format(gun) ==
                        DateFormat('yyyy-MM-dd').format(_seciliGun);
                    bool isToday =
                        DateFormat('yyyy-MM-dd').format(gun) ==
                        DateFormat('yyyy-MM-dd').format(_bugun);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _seciliGun = gun);
                        _verileriYukle();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 45,
                        decoration: BoxDecoration(
                          // ✅ Bugün parlaması için hafif renk vurgusu
                          color: isToday
                              ? widget.anaRenk.withValues(alpha: 0.15)
                              : (isSelected
                                    ? widget.anaRenk.withValues(alpha: 0.1)
                                    : Colors.transparent),
                          borderRadius: BorderRadius.circular(15),
                          border: isToday
                              ? Border.all(
                                  color: widget.anaRenk.withValues(alpha: 0.4),
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat(
                                'E',
                                'tr_TR',
                              ).format(gun).toUpperCase(),
                              style: TextStyle(
                                color: isToday
                                    ? widget.anaRenk
                                    : (isSelected
                                          ? widget.anaRenk
                                          : Colors.white38),
                                fontSize: 8,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                // ✅ Bugünün dairesi parlıyor
                                color: isToday
                                    ? widget.anaRenk
                                    : (isSelected
                                          ? widget.anaRenk
                                          : Colors.transparent),
                                shape: BoxShape.circle,
                                border: (isSelected || isToday)
                                    ? null
                                    : Border.all(color: Colors.white10),
                                boxShadow: isToday
                                    ? [
                                        BoxShadow(
                                          color: widget.anaRenk.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                "${gun.day}",
                                style: TextStyle(
                                  color: (isSelected || isToday)
                                      ? Colors.black
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
            onPressed: () => _takvimPageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAylikIstikrarPaneli() {
    int ayinGunSayisi = DateTime(_seciliGun.year, _seciliGun.month + 1, 0).day;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "AYLIK İSTİKRAR",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('MMMM', 'tr_TR').format(_seciliGun).toUpperCase(),
                style: TextStyle(
                  color: widget.anaRenk,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(ayinGunSayisi, (index) {
                int gunBasari = aylikBasariListesi[index + 1];
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: gunBasari == 0
                          ? Colors.white.withValues(alpha: 0.1)
                          : widget.anaRenk.withValues(
                              alpha: (gunBasari / 5).clamp(0.2, 1.0),
                            ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCizelgeItem(String vakit) {
    String durum = gunlukNamazDurumu[vakit]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            vakit,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          Row(
            children: [
              _durumButonu(
                vakit,
                "Kıldı",
                Icons.check,
                widget.anaRenk,
                durum == "Kıldı",
              ),
              const SizedBox(width: 5),
              _durumButonu(
                vakit,
                "Kılmadı",
                Icons.close,
                Colors.redAccent,
                durum == "Kılmadı",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _durumButonu(
    String vakit,
    String label,
    IconData icon,
    Color renk,
    bool aktif,
  ) {
    return GestureDetector(
      onTap: () => _durumGuncelle(vakit, label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: aktif ? renk : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: aktif ? renk : renk.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: aktif ? Colors.black : renk),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: aktif ? Colors.black : Colors.white38,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNamazKazaSekmesi() {
    int maxBorc = namazKazalari.values.reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        _buildOngoruHeader(maxBorc),
        _buildHedefHizKart(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildIslemButonu(
                "BORÇLARI DÜZENLE",
                () => _borcGuncellemePaneli("namaz"),
              ),
              ...namazKazalari.keys.map(
                (k) => _buildKazaItem(k, namazKazalari[k]!, "namaz"),
              ),
              const SizedBox(height: 150), // ✅ Kaza sayfasında da boşluk
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrucKazaSekmesi() {
    double yuzde = _hedefOruc <= 0
        ? 0.0
        : ((_hedefOruc - orucKazalari["Ramazan Orucu"]!) / _hedefOruc).clamp(
            0.0,
            1.0,
          );
    return Column(
      children: [
        _buildOrucOzetKart(yuzde),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildIslemButonu(
                "BORÇLARI DÜZENLE",
                () => _borcGuncellemePaneli("oruc"),
              ),
              ...orucKazalari.keys.map(
                (k) => _buildKazaItem(k, orucKazalari[k]!, "oruc"),
              ),
              const SizedBox(height: 150),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOngoruHeader(int maxBorc) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: widget.anaRenk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: widget.anaRenk.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.insights, color: widget.anaRenk),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TAHMİNİ BİTİŞ",
                style: TextStyle(color: Colors.white38, fontSize: 9),
              ),
              Text(
                _ongoruHesapla(maxBorc),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHedefHizKart() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              "Günlük Kaza Hızı",
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ),
          _sayacButonu(Icons.remove, () async {
            if (_gunlukKazaHedefi > 1) {
              setState(() => _gunlukKazaHedefi--);
              (await SharedPreferences.getInstance()).setInt(
                'kaza_gunluk_hedef',
                _gunlukKazaHedefi,
              );
            }
          }),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "$_gunlukKazaHedefi",
              style: TextStyle(
                color: widget.anaRenk,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _sayacButonu(Icons.add, () async {
            setState(() => _gunlukKazaHedefi++);
            (await SharedPreferences.getInstance()).setInt(
              'kaza_gunluk_hedef',
              _gunlukKazaHedefi,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildIslemButonu(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: widget.anaRenk.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(color: widget.anaRenk, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildKazaItem(String key, int deger, String tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                key,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (tip == "namaz" && deger > 0)
                Text(
                  _ongoruHesapla(deger),
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
            ],
          ),
          Row(
            children: [
              _sayacButonu(Icons.remove, () async {
                if (deger > 0) {
                  final p = await SharedPreferences.getInstance();
                  setState(
                    () => tip == "namaz"
                        ? namazKazalari[key] = deger - 1
                        : orucKazalari[key] = deger - 1,
                  );
                  p.setInt('kaza_${tip}_$key', deger - 1);
                  _verileriYukle();
                }
              }),
              SizedBox(
                width: 40,
                child: Text(
                  "$deger",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.anaRenk,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _sayacButonu(Icons.add, () async {
                final p = await SharedPreferences.getInstance();
                setState(
                  () => tip == "namaz"
                      ? namazKazalari[key] = deger + 1
                      : orucKazalari[key] = deger + 1,
                );
                p.setInt('kaza_${tip}_$key', deger + 1);
                _verileriYukle();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrucOzetKart(double yuzde) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: widget.anaRenk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ORUÇ İLERLEME",
                style: TextStyle(color: Colors.white38, fontSize: 9),
              ),
              Text(
                "%${(yuzde * 100).toInt()}",
                style: TextStyle(
                  color: widget.anaRenk,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: yuzde,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(widget.anaRenk),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  void _borcGuncellemePaneli(String tip) {
    final controllers = <String, TextEditingController>{};
    if (tip == "namaz") {
      namazKazalari.forEach(
        (k, v) => controllers[k] = TextEditingController(text: v.toString()),
      );
    } else {
      orucKazalari.forEach(
        (k, v) => controllers[k] = TextEditingController(text: v.toString()),
      );
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F2B),
        title: Text(
          "$tip Borçlarını Düzenle",
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: controllers.entries
                .map(
                  (e) => TextField(
                    controller: e.value,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: e.key,
                      labelStyle: const TextStyle(color: Colors.white38),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.anaRenk),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              if (!mounted) return;
              setState(() {
                controllers.forEach((k, c) {
                  int val = int.tryParse(c.text) ?? 0;
                  if (tip == "namaz") {
                    namazKazalari[k] = val;
                    prefs.setInt('kaza_namaz_$k', val);
                  } else {
                    orucKazalari[k] = val;
                    prefs.setInt('kaza_oruc_$k', val);
                    if (k == "Ramazan Orucu") {
                      _hedefOruc = val;
                      prefs.setInt('kaza_oruc_hedef', val);
                    }
                  }
                });
              });
              Navigator.pop(context);
              _verileriYukle();
            },
            child: const Text("KAYDET", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _sayacButonu(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: widget.anaRenk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: widget.anaRenk, size: 16),
    ),
  );
}
