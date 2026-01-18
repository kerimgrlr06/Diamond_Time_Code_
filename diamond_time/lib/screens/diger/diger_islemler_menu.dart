import 'package:flutter/material.dart';
import 'dart:ui';

// Sayfalar
import '../drawer/camiler_sayfasi.dart';
import '../drawer/kaza_namazi_sayfasi.dart';
import '../drawer/dini_gunler_sayfasi.dart';
import '../drawer/sozler_sayfasi.dart';
import '../drawer/manevi_paylasim_sayfasi.dart';
import '../drawer/ayarlar_sayfasi.dart';

class DigerIslemlerMenu extends StatelessWidget {
  final Function(Widget) onSayfaSec;
  final Color anaRenk; // ✅ HomeShell'den gelen dinamik renk

  const DigerIslemlerMenu({
    super.key,
    required this.onSayfaSec,
    this.anaRenk = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menu = [
      {
        "icon": Icons.mosque_rounded,
        "title": "Camiler",
        "desc": "Yakındaki Camiler",
      },
      {
        "icon": Icons.history_edu_rounded,
        "title": "Kaza Takip",
        "desc": "Eksik Namaz , Oruç Takibi ve Günlük Namaz Çizelgesi",
      },
      {
        "icon": Icons.nights_stay_rounded,
        "title": "Dini Günler",
        "desc": "Mübarek Tarihler",
      },
      {
        "icon": Icons.format_quote_rounded,
        "title": "Günün Sözü",
        "desc": "Kalbe Şifa Sözler",
      },
      {
        "icon": Icons.image_rounded,
        "title": "Manevi Paylaşım",
        "desc": "İslami Postlar",
      },
      {
        "icon": Icons.settings_suggest_rounded,
        "title": "Ayarlar",
        "desc": "Uygulama Yapısı",
      },
    ];

    // ✅ Geri dönüldüğünde ana rengin korunması sağlandı
    Widget sayfaGetir(String title) {
      void geri() => onSayfaSec(
        DigerIslemlerMenu(onSayfaSec: onSayfaSec, anaRenk: anaRenk),
      );

      switch (title) {
        case "Camiler":
          return CamilerSayfasi(onGeri: geri, anaRenk: anaRenk);
        case "Kaza Takip":
          return KazaTakipSayfasi(onGeri: geri, anaRenk: anaRenk);
        case "Dini Günler":
          return DiniGunlerSayfasi(onGeri: geri, anaRenk: anaRenk);
        case "Günün Sözü":
          return SozlerSayfasi(onGeri: geri, anaRenk: anaRenk);
        case "Manevi Paylaşım":
          return ManeviPaylasimSayfasi(onGeri: geri, anaRenk: anaRenk);
        case "Ayarlar":
          return AyarlarSayfasi(onGeri: geri, anaRenk: anaRenk);
        default:
          return const SizedBox();
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          "DİĞER ÖZELLİKLER",
          style: TextStyle(
            letterSpacing: 3,
            fontWeight: FontWeight.w100,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 1.1,
        ),
        itemCount: menu.length,
        itemBuilder: (context, i) {
          final item = menu[i];
          return ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(8), // withValues -> withAlpha
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withAlpha(13)),
                ),
                child: InkWell(
                  onTap: () => onSayfaSec(sayfaGetir(item['title'])),
                  splashColor: anaRenk.withAlpha(25),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: anaRenk.withAlpha(20),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(item['icon'], color: anaRenk, size: 28),
                        ),
                        const Spacer(),
                        Text(
                          item['title'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['desc'],
                          style: TextStyle(
                            color: Colors.white.withAlpha(102),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
