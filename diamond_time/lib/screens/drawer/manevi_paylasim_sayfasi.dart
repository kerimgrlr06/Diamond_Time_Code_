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

  // Sadece İslamî içerik getir + alakasızları exclude et
  Future<void> _fetchManeviGorseller() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _downloadingUrl = null;
    });

    // Saf İslamî sorgu + exclude alakasız kelimeler
    const String sabitSorgu =
        "mosque+kaaba+medina+arabic+calligraphy+ramadan+kandil+cuma+eid+mubarak+dua+prayer+islamic+art+lantern+masjid+nabawi"
        "-church-christian-jesus-cross-bible-cathedral-buddha-buddhist-temple-hindu-krishna-sikh";

    final String url =
        "https://pixabay.com/api/?key=$_apiKey&q=$sabitSorgu&image_type=photo&orientation=vertical&category=religion&editors_choice=true&safesearch=true&per_page=80&min_width=800";

    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _images = data['hits'];
            _isLoading = false;
            if (_images.isEmpty) {
              _error = "Şu anda görsel yüklenemedi. Lütfen tekrar deneyin.";
            }
          });
        }
      } else {
        throw Exception("Sunucu hatası");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = "Bağlantı sorunu oluştu.";
        });
      }
    }
  }

  Future<void> _dosyaIsle(String url, {required bool paylas}) async {
    if (_downloadingUrl != null) return;

    setState(() => _downloadingUrl = url);

    try {
      final Directory tempDir = Directory.systemTemp;
      final String fileName =
          'diamond_manevi_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String tempPath = '${tempDir.path}/$fileName';

      await Dio().download(url, tempPath);

      final File file = File(tempPath);
      if (await file.exists()) {
        if (paylas) {
          await Share.shareXFiles([
            XFile(file.path),
          ], text: 'Mübarek olsun... ✨ #DiamondTime');
        } else {
          await Gal.putImage(tempPath);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text("Galeriye kaydedildi! 💎"),
                  ],
                ),
                backgroundColor: widget.anaRenk,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            );
          }
        }
        await file.delete();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("İşlem başarısız oldu.")));
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingUrl = null);
      }
    }
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
          "MANEVİ PAYLAŞIM",
          style: TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w100,
            fontSize: 13,
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.anaRenk))
          : _error != null
          ? _buildError()
          : _buildGrid(),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: _images.length,
      itemBuilder: (context, i) {
        final item = _images[i];
        final bool isDownloading = _downloadingUrl == item['largeImageURL'];

        return GestureDetector(
          onTap: () => _detailView(item['largeImageURL']),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  item['webformatURL'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.white.withValues(alpha: 0.08),
                    );
                  },
                  errorBuilder: (_, _, _) => Container(
                    color: Colors.white.withValues(alpha: 0.08),
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white24,
                    ),
                  ),
                ),
              ),
              if (isDownloading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          "İndirildi!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _detailView(String url) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: const Color(0xFF0A0E1A).withValues(alpha: 0.97),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _actionButton(
                      icon: Icons.share_rounded,
                      label: "Paylaş",
                      color: Colors.greenAccent,
                      onTap: () => _dosyaIsle(url, paylas: true),
                    ),
                    _actionButton(
                      icon: Icons.download_rounded,
                      label: "Kaydet",
                      color: widget.anaRenk,
                      onTap: () => _dosyaIsle(url, paylas: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
              ],
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 34),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            color: widget.anaRenk.withValues(alpha: 0.4),
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            _error ?? "Bir sorun oluştu",
            style: const TextStyle(color: Colors.white54, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _fetchManeviGorseller,
            icon: const Icon(Icons.refresh),
            label: const Text("Tekrar Yükle"),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.anaRenk,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
