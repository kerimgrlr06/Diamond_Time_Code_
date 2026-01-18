import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

class ManeviPaylasimSayfasi extends StatefulWidget {
  final VoidCallback? onGeri;
  final Color anaRenk;

  const ManeviPaylasimSayfasi({
    super.key,
    this.onGeri,
    this.anaRenk = Colors.blueAccent,
  });

  @override
  State<ManeviPaylasimSayfasi> createState() => _ManeviPaylasimSayfasiState();
}

class _ManeviPaylasimSayfasiState extends State<ManeviPaylasimSayfasi> {
  List<dynamic> _images = [];
  bool _isLoading = true;
  String? _error;
  final String _apiKey = "53954658-140b97118f37fe6383085f6b6";
  String? _downloadingUrl;

  @override
  void initState() {
    super.initState();
    _fetchManeviGorseller();
  }

  Future<void> _fetchManeviGorseller() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    const String query =
        "mosque+kaaba+arabic+calligraphy+ramadan+dua+islamic+art-church-cross";
    final String url =
        "https://pixabay.com/api/?key=$_apiKey&q=$query&image_type=photo&orientation=vertical&category=religion&editors_choice=true&safesearch=true&per_page=40";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted)
          setState(() {
            _images = data['hits'];
            _isLoading = false;
          });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _error = "Huzura giden yolda bir engel oluştu.";
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: widget.onGeri ?? () => Navigator.pop(context),
        ),
        title: Text(
          "MANEVİ KEŞİF",
          style: TextStyle(
            letterSpacing: 6,
            fontSize: 14,
            fontWeight: FontWeight.w200,
            color: widget.anaRenk,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
          ? _buildError()
          : _buildModernList(),
    );
  }

  Widget _buildModernList() {
    return PageView.builder(
      scrollDirection:
          Axis.vertical, // 👈 Alışılmadık: Aşağı doğru kayan tam ekran deneyimi
      physics: const BouncingScrollPhysics(),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final item = _images[index];
        return _buildModernCard(item);
      },
    );
  }

  Widget _buildModernCard(dynamic item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Arka Plan Görseli
        Image.network(item['largeImageURL'], fit: BoxFit.cover),

        // Karartma ve Gradyan
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(150),
                Colors.transparent,
                Colors.black.withAlpha(200),
              ],
            ),
          ),
        ),

        // Alt Panel (Etkileşim)
        Positioned(
          bottom: 120,
          left: 30,
          right: 30,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "NUR ${item['id']}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Bu manevi kareyi sevdiklerinle paylaşarak hayra vesile olabilirsin.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  _circleAction(
                    Icons.share_outlined,
                    () => _dosyaIsle(item['largeImageURL'], paylas: true),
                  ),
                  const SizedBox(width: 20),
                  _circleAction(
                    Icons.file_download_outlined,
                    () => _dosyaIsle(item['largeImageURL'], paylas: false),
                  ),
                  const Spacer(),
                  if (_downloadingUrl == item['largeImageURL'])
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _circleAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(50)),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  // İşlem Metodu (Paylaş/Kaydet)
  Future<void> _dosyaIsle(String url, {required bool paylas}) async {
    if (_downloadingUrl != null) return;
    setState(() => _downloadingUrl = url);
    try {
      final tempDir = Directory.systemTemp;
      final tempPath =
          '${tempDir.path}/diamond_${DateTime.now().msSinceEpoch}.jpg';
      await Dio().download(url, tempPath);
      if (paylas) {
        await Share.shareXFiles([XFile(tempPath)], text: 'Diamond Time ✨');
      } else {
        await Gal.putImage(tempPath);
        _msg("Huzur galerinize kaydedildi.");
      }
    } catch (e) {
      _msg("İşlem tamamlanamadı.");
    }
    setState(() => _downloadingUrl = null);
  }

  void _msg(String txt) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(txt),
        backgroundColor: widget.anaRenk,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildLoading() =>
      Center(child: CircularProgressIndicator(color: widget.anaRenk));
  Widget _buildError() => Center(
    child: Text(_error!, style: const TextStyle(color: Colors.white54)),
  );
}

extension DateExt on DateTime {
  int get msSinceEpoch => millisecondsSinceEpoch;
}
