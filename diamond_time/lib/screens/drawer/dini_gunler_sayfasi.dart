import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<Map<String, dynamic>> _tumGunler = [];
  bool _yukleniyor = true;
  int _seciliYil = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString('dini_gunler_cache');
    if (cached != null) {
      setState(() => _tumGunler = _jsonToList(json.decode(cached)));
    }

    try {
      final res = await http.get(
        Uri.parse(
          'https://raw.githubusercontent.com/kerimgrlr06/Diamond_Time_Code_/refs/heads/main/dini_gunler.json',
        ),
      );
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        await prefs.setString('dini_gunler_cache', json.encode(data));
        setState(() => _tumGunler = _jsonToList(data));
      }
    } catch (_) {}
    setState(() => _yukleniyor = false);
  }

  List<Map<String, dynamic>> _jsonToList(List<dynamic> data) {
    return data
        .map(
          (e) => {
            "ad": e["ad"],
            "t": DateTime.parse(e["t"]),
            "desc": e["desc"],
          },
        )
        .toList()
      ..sort((a, b) => (a["t"] as DateTime).compareTo(b["t"] as DateTime));
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    // ✅ Sadece seçili yıla ait günleri filtrele
    final filtered = _tumGunler
        .where((g) => (g["t"] as DateTime).year == _seciliYil)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "DİNİ GÜNLER",
          style: TextStyle(letterSpacing: 3, fontSize: 16, color: Colors.white),
        ),
        leading: widget.onGeri != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: widget.onGeri,
              )
            : null,
      ),
      body: Column(
        children: [
          // ✅ Yıl butonları (Sadece ihtiyacımız olan yılları gösterir)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [2026, 2027].map((y) => _yilButonu(y)).toList(),
          ),
          Expanded(
            child: _yukleniyor
                ? Center(
                    child: CircularProgressIndicator(color: widget.anaRenk),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final gun = filtered[i];
                      final DateTime dt = gun["t"];
                      final bool bugun = dt.isAtSameMomentAs(today);
                      final bool gecti = dt.isBefore(today);
                      final int fark = dt.difference(today).inDays.abs();

                      return Opacity(
                        opacity: gecti ? 0.5 : 1.0,
                        child: Card(
                          color: bugun
                              ? widget.anaRenk.withAlpha(30)
                              : Colors.white.withAlpha(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: bugun ? widget.anaRenk : Colors.white10,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            leading: Icon(
                              bugun ? Icons.auto_awesome : Icons.event,
                              color: bugun ? widget.anaRenk : Colors.white38,
                            ),
                            title: Text(
                              gun["ad"],
                              style: TextStyle(
                                color: bugun ? widget.anaRenk : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              DateFormat("d MMMM yyyy", "tr_TR").format(dt),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Text(
                              bugun
                                  ? "BUGÜN"
                                  : (gecti
                                        ? "$fark gün önceydi"
                                        : "$fark gün kaldı"),
                              style: TextStyle(
                                color: bugun
                                    ? widget.anaRenk
                                    : (gecti
                                          ? Colors.white24
                                          : widget.anaRenk.withAlpha(150)),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
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
    );
  }

  Widget _yilButonu(int y) {
    bool s = _seciliYil == y;
    return GestureDetector(
      onTap: () => setState(() => _seciliYil = y),
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
        decoration: BoxDecoration(
          color: s ? widget.anaRenk.withAlpha(40) : Colors.white.withAlpha(10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: s ? widget.anaRenk : Colors.transparent),
        ),
        child: Text(
          "$y",
          style: TextStyle(
            color: s ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
