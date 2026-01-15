import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';

class SozlerSayfasi extends StatefulWidget {
  final VoidCallback? onGeri;
  final Color anaRenk;

  const SozlerSayfasi({
    super.key,
    this.onGeri,
    this.anaRenk = Colors.blueAccent,
  });

  @override
  State<SozlerSayfasi> createState() => _SozlerSayfasiState();
}

class _SozlerSayfasiState extends State<SozlerSayfasi> {
  final List<String> _sozlerListesi = [
    "Sizin en hayırlınız, Kur'an'ı öğrenen ve öğretendir. (Buhârî)",
    "Ameller niyetlere göredir. (Buhârî)",
    "Dua ibadetin özüdür. (Tirmizî)",
    "İman, yetmiş küsur şubedir; en üstünü 'Lâ ilâhe illallah' demektir. (Müslim)",
    "Temizlik imanın yarısıdır. (Müslim)",
    "İslam, güzel ahlaktır. (Kenzü’l-Ummal)",
    "Namaz dinin direğidir. (Beyhakî)",
    "Dua müminin silahıdır. (Hâkim)",
    "Cennetin anahtarı namazdır. (Tirmizî)",
    "İlim öğrenmek her Müslüman üzerine farzdır. (İbn Mâce)",
    // ... (tüm sözler aynı kalıyor, kısaltma için burada kesiyorum)
    "Kalpler ancak Allah'ı anmakla huzur bulur. (Kur'an)",
    "Rızık Allah'tandır.",
    "Gayret bizden tevfik Allah'tandır.",
    "Güzel söz sadakadır. (Buhârî)",
    "Her vaktin bir namazı vardır.",
  ];

  late String gununSozu;

  @override
  void initState() {
    super.initState();
    gununSozu = _sozlerListesi[DateTime.now().day % _sozlerListesi.length];
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
          "HİKMETLİ SÖZLER",
          style: TextStyle(
            letterSpacing: 3,
            fontWeight: FontWeight.w100,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.white,
          ),
          onPressed: widget.onGeri ?? () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Hafif neon glow efekti (performans dostu)
          Positioned(
            top: 150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.anaRenk.withValues(alpha: 0.08),
                    blurRadius: 200,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Akıcı ListView
          ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
            children: [
              _gununSozuKarti(),
              const SizedBox(height: 30),
              Text(
                "SÖZLER KÜTÜPHANESİ",
                style: TextStyle(
                  color: widget.anaRenk,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              ..._sozlerListesi
                  .map((soz) => _sozKarti(soz, soz == gununSozu))
                  .toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gununSozuKarti() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.anaRenk.withValues(alpha: 0.25),
            widget.anaRenk.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: widget.anaRenk.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.anaRenk.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome, color: widget.anaRenk, size: 50),
          const SizedBox(height: 20),
          const Text(
            "GÜNÜN İLHAMI",
            style: TextStyle(
              color: Colors.white60,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 30),
          Text(
            gununSozu,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 35),
          ElevatedButton.icon(
            onPressed: () => Share.shareXFiles(
              [],
              text: "$gununSozu\n\nDiamond Time - Huzur Vakti ✨",
            ),
            icon: Icon(Icons.share_rounded, color: widget.anaRenk, size: 20),
            label: const Text(
              "HİKMETİ PAYLAŞ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(color: widget.anaRenk.withValues(alpha: 0.4)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sozKarti(String soz, bool isGununSozu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isGununSozu
          ? widget.anaRenk.withValues(alpha: 0.12)
          : Colors.white.withValues(alpha: 0.03),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: isGununSozu
              ? widget.anaRenk.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => Share.shareXFiles([], text: "$soz\n\nDiamond Time"),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Icon(
                isGununSozu ? Icons.auto_awesome : Icons.format_quote,
                color: isGununSozu ? widget.anaRenk : Colors.white38,
                size: 28,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  soz,
                  style: TextStyle(
                    color: isGununSozu
                        ? Colors.white
                        : Colors.white.withOpacity(0.8),
                    fontSize: 15,
                    height: 1.6,
                    fontWeight: isGununSozu ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Icon(Icons.share_outlined, color: Colors.white24, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
