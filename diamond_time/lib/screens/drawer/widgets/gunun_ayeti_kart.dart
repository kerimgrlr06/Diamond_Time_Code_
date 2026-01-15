import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

class GununAyetiKart extends StatefulWidget {
  const GununAyetiKart({super.key});

  @override
  State<GununAyetiKart> createState() => _GununAyetiKartState();
}

class _GununAyetiKartState extends State<GununAyetiKart> {
  String _ayet = "Yükleniyor...";
  String _kaynak = "";
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAyet();
  }

  Future<void> _fetchAyet() async {
    try {
      final int ayetNo = (DateTime.now().day * 13) % 500 + 1;
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/ayah/$ayetNo/tr.diyanet'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _ayet = data['data']['text'];
            _kaynak =
                "${data['data']['surah']['englishName']} - ${data['data']['numberInSurah']}";
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ayet = "Şüphesiz güçlükle beraber bir kolaylık vardır.";
          _kaynak = "İnşirah - 5";
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        20,
        20,
        20,
        100,
      ), // Alt tarafı 100 yaptık ki BottomNav'a çarpmasın
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          const Icon(Icons.format_quote, color: Colors.blueAccent, size: 24),
          const SizedBox(height: 10),
          _loading
              ? const SizedBox(
                  width: 50,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    color: Colors.blueAccent,
                  ),
                )
              : Text(
                  _ayet,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _kaynak,
                style: const TextStyle(
                  color: Colors.blueAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 15),
              GestureDetector(
                // ignore: deprecated_member_use
                onTap: () => Share.share("$_ayet\n($_kaynak)\n\nDiamond Time"),
                child: const Icon(
                  Icons.ios_share,
                  color: Colors.white24,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
