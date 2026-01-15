import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import '../../services/bildirim_servisi.dart';
import '../../services/konum_servisi.dart';

class AyarlarSayfasi extends StatefulWidget {
  final VoidCallback? onGeri;
  final bool geriButonuVarMi;
  final Color anaRenk; // ✅ Vakte göre değişen dinamik rengi buraya aldık

  const AyarlarSayfasi({
    super.key,
    this.onGeri,
    this.geriButonuVarMi = false,
    this.anaRenk = Colors.blueAccent, // Varsayılan renk
  });

  @override
  State<AyarlarSayfasi> createState() => _AyarlarSayfasiState();
}

class _AyarlarSayfasiState extends State<AyarlarSayfasi> {
  Map<String, bool> vakitBildirimleri = {
    'imsak': true,
    'ogle': true,
    'ikindi': true,
    'aksam': true,
    'yatsi': true,
  };

  int sesTipi = 2;
  int hatirlatmaDk = 15;
  bool uygulamaSesi = true;
  bool yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _ayarlariYukle();
  }

  Future<void> _ayarlariYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      vakitBildirimleri = {
        'imsak': prefs.getBool('imsak_bildirim') ?? true,
        'ogle': prefs.getBool('ogle_bildirim') ?? true,
        'ikindi': prefs.getBool('ikindi_bildirim') ?? true,
        'aksam': prefs.getBool('aksam_bildirim') ?? true,
        'yatsi': prefs.getBool('yatsi_bildirim') ?? true,
      };
      sesTipi = prefs.getInt('ses_tipi') ?? 2;
      hatirlatmaDk = prefs.getInt('hatirlatma_dk') ?? 15;
      uygulamaSesi = prefs.getBool('ses') ?? true;
      yukleniyor = false;
    });
  }

  Future<void> _ayarKaydet(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);

    if (KonumServisi.coords != null) {
      final params = CalculationMethod.turkey.getParameters();
      params.madhab = Madhab.shafi;
      final vakitler = PrayerTimes(
        KonumServisi.coords!,
        DateComponents.from(DateTime.now()),
        params,
      );
      await BildirimServisi.tumVakitleriSenkronizeEt(vakitler);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.transparent, // ✅ Arka plan gradientini kesmesin diye şeffaf
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "AYARLAR",
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
            : (widget.geriButonuVarMi
                  ? const BackButton(color: Colors.white)
                  : null),
      ),
      body: yukleniyor
          ? Center(child: CircularProgressIndicator(color: widget.anaRenk))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _bolumBasligi("VAKİT BİLDİRİMLERİ"),
                ...vakitBildirimleri.keys.map((vakit) => _vakitSwitch(vakit)),

                const SizedBox(height: 30),
                _bolumBasligi("SES VE HATIRLATMA"),

                _ayarKarti(
                  icon: Icons.timer_outlined,
                  baslik: "Vakit Öncesi Uyarı",
                  altBaslik: hatirlatmaDk == 0
                      ? "Kapalı"
                      : "$hatirlatmaDk dakika kala hatırlat",
                  kontroller: DropdownButton<int>(
                    value: hatirlatmaDk,
                    dropdownColor: const Color(0xFF1E293B),
                    underline: const SizedBox(),
                    items: [0, 5, 10, 15, 30].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(
                          value == 0 ? "Kapalı" : "$value dk",
                          style: TextStyle(color: widget.anaRenk, fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => hatirlatmaDk = val!);
                      _ayarKaydet('hatirlatma_dk', val);
                    },
                  ),
                ),

                const SizedBox(height: 15),

                _ayarKarti(
                  icon: Icons.music_note_outlined,
                  baslik: "Bildirim Modu",
                  altBaslik: _sesTipiAdi(sesTipi),
                  kontroller: DropdownButton<int>(
                    value: sesTipi,
                    dropdownColor: const Color(0xFF1E293B),
                    underline: const SizedBox(),
                    items: [0, 1, 2, 3].map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(
                          _sesTipiAdi(value),
                          style: TextStyle(color: widget.anaRenk, fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => sesTipi = val!);
                      _ayarKaydet('ses_tipi', val);
                    },
                  ),
                ),

                const SizedBox(height: 15),

                _ayarKarti(
                  icon: Icons.volume_up_outlined,
                  baslik: "Uygulama Sesleri",
                  altBaslik: "Efekt ve buton sesleri",
                  kontroller: Switch(
                    activeThumbColor: widget.anaRenk,
                    activeTrackColor: widget.anaRenk.withValues(alpha: 0.3),
                    value: uygulamaSesi,
                    onChanged: (v) {
                      setState(() => uygulamaSesi = v);
                      _ayarKaydet('ses', v);
                    },
                  ),
                ),

                const SizedBox(height: 30),
                _bolumBasligi("HAKKINDA"),
                _ayarKarti(
                  icon: Icons.info_outline_rounded,
                  baslik: "Sürüm",
                  altBaslik: "2.1.0 (Diamond Premium)",
                  kontroller: Icon(
                    Icons.verified,
                    color: widget.anaRenk,
                    size: 20,
                  ),
                ),

                // ✅ İSTEDİĞİN 100 PX BOŞLUK
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _vakitSwitch(String vakit) {
    String baslik = vakit[0].toUpperCase() + vakit.substring(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _ayarKarti(
        icon: Icons.notifications_none_rounded,
        baslik: baslik,
        altBaslik: "$baslik vaktinde bildirim al",
        kontroller: Switch(
          activeThumbColor: widget.anaRenk,
          activeTrackColor: widget.anaRenk.withValues(alpha: 0.3),
          value: vakitBildirimleri[vakit]!,
          onChanged: (v) {
            setState(() => vakitBildirimleri[vakit] = v);
            _ayarKaydet('${vakit}_bildirim', v);
          },
        ),
      ),
    );
  }

  String _sesTipiAdi(int tip) {
    switch (tip) {
      case 0:
        return "Sessiz";
      case 1:
        return "Sadece Titreşim";
      case 2:
        return "Sistem Sesi";
      case 3:
        return "Ses + Titreşim";
      default:
        return "Ses + Titreşim";
    }
  }

  Widget _ayarKarti({
    required IconData icon,
    required String baslik,
    required String altBaslik,
    required Widget kontroller,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03), // ✅ Glassmorphism dokunuşu
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.anaRenk.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: widget.anaRenk, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  baslik,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  altBaslik,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
          kontroller,
        ],
      ),
    );
  }

  Widget _bolumBasligi(String metin) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 12, top: 10),
      child: Text(
        metin,
        style: TextStyle(
          color: widget.anaRenk,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
    );
  }
}
