import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DiniGunlerSayfasi extends StatefulWidget {
  final VoidCallback? onGeri;
  final Color anaRenk;

  const DiniGunlerSayfasi({
    super.key,
    this.onGeri,
    this.anaRenk = Colors.blueAccent,
  });

  @override
  State<DiniGunlerSayfasi> createState() => _DiniGunlerSayfasiState();
}

class _DiniGunlerSayfasiState extends State<DiniGunlerSayfasi> {
  late int seciliYil;

  @override
  void initState() {
    super.initState();
    int currentYear = DateTime.now().year;
    seciliYil = tumYillar.containsKey(currentYear) ? currentYear : 2025;
  }

  // ✅ 2025 ve 2026 TAM DOĞRU TARİHLER (Diyanet Takvimi)
  final Map<int, List<Map<String, dynamic>>> tumYillar = {
    2025: [
      {
        "ad": "Üç Ayların Başlangıcı",
        "t": DateTime(2025, 1, 1),
        "desc": "Manevi bahar mevsimi Recep ayı ile başlıyor.",
      },
      {
        "ad": "Regaip Kandili",
        "t": DateTime(2025, 1, 2),
        "desc": "Üç ayların müjdeleyicisi ilk kandil gecesi.",
      },
      {
        "ad": "Miraç Kandili",
        "t": DateTime(2025, 1, 26),
        "desc": "Efendimizin ilahi huzura yükseldiği gece.",
      },
      {
        "ad": "Berat Kandili",
        "t": DateTime(2025, 2, 13),
        "desc": "Af ve mağfiret gecesi.",
      },
      {
        "ad": "Ramazan Başlangıcı",
        "t": DateTime(2025, 3, 1),
        "desc": "On bir ayın sultanına merhaba.",
      },
      {
        "ad": "Kadir Gecesi",
        "t": DateTime(2025, 3, 26),
        "desc": "Bin aydan hayırlı gece.",
      },
      {
        "ad": "Ramazan Bayramı Arefesi",
        "t": DateTime(2025, 3, 29),
        "desc": "Orucun son günü.",
      },
      {
        "ad": "Ramazan Bayramı (1. Gün)",
        "t": DateTime(2025, 3, 30),
        "desc": "Şevval ayı başı.",
      },
      {
        "ad": "Ramazan Bayramı (2. Gün)",
        "t": DateTime(2025, 3, 31),
        "desc": "Bayramın ikinci günü.",
      },
      {
        "ad": "Ramazan Bayramı (3. Gün)",
        "t": DateTime(2025, 4, 1),
        "desc": "Bayramın son günü.",
      },
      {
        "ad": "Kurban Bayramı Arefesi",
        "t": DateTime(2025, 6, 5),
        "desc": "Vakfe günü.",
      },
      {
        "ad": "Kurban Bayramı (1. Gün)",
        "t": DateTime(2025, 6, 6),
        "desc": "Kurban ibadeti başlangıcı.",
      },
      {
        "ad": "Kurban Bayramı (2. Gün)",
        "t": DateTime(2025, 6, 7),
        "desc": "Bayramın ikinci günü.",
      },
      {
        "ad": "Kurban Bayramı (3. Gün)",
        "t": DateTime(2025, 6, 8),
        "desc": "Bayramın üçüncü günü.",
      },
      {
        "ad": "Kurban Bayramı (4. Gün)",
        "t": DateTime(2025, 6, 9),
        "desc": "Bayramın son günü.",
      },
      {
        "ad": "Hicri Yılbaşı",
        "t": DateTime(2025, 6, 26),
        "desc": "Yeni Hicri yıl başlangıcı.",
      },
      {
        "ad": "Aşure Günü",
        "t": DateTime(2025, 7, 5),
        "desc": "Paylaşma simgesi.",
      },
      {
        "ad": "Mevlid Kandili",
        "t": DateTime(2025, 9, 3),
        "desc": "Efendimizin kutlu doğumu.",
      },
      {
        "ad": "Üç Ayların Başlangıcı (2.)",
        "t": DateTime(2025, 12, 21),
        "desc": "Yeni manevi sezon başlangıcı.",
      },
      {
        "ad": "Regaip Kandili (2.)",
        "t": DateTime(2025, 12, 25),
        "desc": "Yılın son mübarek gecesi.",
      },
    ],
    2026: [
      {
        "ad": "Miraç Kandili",
        "t": DateTime(2026, 1, 15),
        "desc": "Göklere yükseliş gecesi.",
      },
      {
        "ad": "Berat Kandili",
        "t": DateTime(2026, 2, 2),
        "desc": "Günahların döküldüğü gece.",
      },
      {
        "ad": "Ramazan Başlangıcı",
        "t": DateTime(2026, 2, 19),
        "desc": "Oruç ayı başlar.",
      },
      {
        "ad": "Kadir Gecesi",
        "t": DateTime(2026, 3, 16),
        "desc": "Kur'an'ın indirildiği gece.",
      },
      {
        "ad": "Arefe (Ramazan)",
        "t": DateTime(2026, 3, 19),
        "desc": "Bayram hazırlığı.",
      },
      {
        "ad": "Ramazan Bayramı (1. Gün)",
        "t": DateTime(2026, 3, 20),
        "desc": "Şeker Bayramı başlangıcı.",
      },
      {
        "ad": "Arefe (Kurban)",
        "t": DateTime(2026, 5, 26),
        "desc": "Arafat günü.",
      },
      {
        "ad": "Kurban Bayramı (1. Gün)",
        "t": DateTime(2026, 5, 27),
        "desc": "Kurban kesimi başlar.",
      },
      {
        "ad": "Hicri Yılbaşı (1 Muharrem)",
        "t": DateTime(2026, 6, 16),
        "desc": "1448 Hicri yıl başlar.",
      },
      {
        "ad": "Aşure Günü",
        "t": DateTime(2026, 6, 25),
        "desc": "Paylaşma ve bereket günü.",
      },
      {
        "ad": "Mevlid Kandili",
        "t": DateTime(2026, 8, 24),
        "desc": "Alemlere rahmetin doğumu.",
      },
      {
        "ad": "Üç Ayların Başlangıcı",
        "t": DateTime(2026, 12, 10),
        "desc": "Manevi sezon başlar.",
      },
      {
        "ad": "Regaip Kandili",
        "t": DateTime(2026, 12, 10),
        "desc": "Rahmet kapıları aralanır.",
      },
    ],
  };

  void _gunDetayiniGoster(Map<String, dynamic> gun) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E1A).withValues(alpha: 0.97),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border.all(color: widget.anaRenk.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              gun["ad"],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.anaRenk,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              DateFormat("d MMMM yyyy, EEEE", "tr_TR").format(gun["t"]),
              style: const TextStyle(color: Colors.white60, fontSize: 15),
            ),
            const SizedBox(height: 25),
            Text(
              gun["desc"],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.anaRenk,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "KAPAT",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> gunler = tumYillar[seciliYil] ?? [];
    final DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "DİNİ GÜNLER",
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
            : null,
      ),
      body: Stack(
        children: [
          // Hafif glow efekti
          Positioned(
            top: 80,
            right: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.anaRenk.withValues(alpha: 0.08),
                    blurRadius: 180,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              // Yıl seçici
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [2025, 2026].map((yil) {
                    bool secili = seciliYil == yil;
                    return GestureDetector(
                      onTap: () => setState(() => seciliYil = yil),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: secili
                              ? widget.anaRenk.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: secili
                                ? widget.anaRenk
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          "$yil",
                          style: TextStyle(
                            color: secili ? Colors.white : Colors.white60,
                            fontSize: 17,
                            fontWeight: secili
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Liste
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                  itemCount: gunler.length,
                  itemBuilder: (context, index) {
                    final gun = gunler[index];
                    final DateTime gunTarihi = DateTime(
                      gun["t"].year,
                      gun["t"].month,
                      gun["t"].day,
                    );
                    final bool bugunMu = gunTarihi.isAtSameMomentAs(today);
                    final bool gectiMi = gunTarihi.isBefore(today);
                    final int kalanGun = gunTarihi
                        .difference(today)
                        .inDays
                        .abs();

                    return Opacity(
                      opacity: gectiMi ? 0.4 : 1.0,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        color: bugunMu
                            ? widget.anaRenk.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.04),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(
                            color: bugunMu
                                ? widget.anaRenk
                                : Colors.white.withValues(alpha: 0.1),
                            width: bugunMu ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () => _gunDetayiniGoster(gun),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 22,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  bugunMu ? Icons.auto_awesome : Icons.event,
                                  color: bugunMu
                                      ? widget.anaRenk
                                      : Colors.white60,
                                  size: 30,
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        gun["ad"],
                                        style: TextStyle(
                                          color: bugunMu
                                              ? widget.anaRenk
                                              : Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        DateFormat(
                                          "d MMMM yyyy",
                                          "tr_TR",
                                        ).format(gun["t"]),
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (bugunMu)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.anaRenk,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      "BUGÜN",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  )
                                else if (!gectiMi)
                                  Text(
                                    "$kalanGun gün",
                                    style: TextStyle(
                                      color: widget.anaRenk.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
