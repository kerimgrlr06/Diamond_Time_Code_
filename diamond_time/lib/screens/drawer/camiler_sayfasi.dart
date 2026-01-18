import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as lat_lng;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../services/konum_servisi.dart';

class CamilerSayfasi extends StatefulWidget {
  final VoidCallback? onGeri;
  final Color anaRenk;

  const CamilerSayfasi({
    super.key,
    this.onGeri,
    this.anaRenk = Colors.blueAccent,
  });

  @override
  State<CamilerSayfasi> createState() => _CamilerSayfasiState();
}

class _CamilerSayfasiState extends State<CamilerSayfasi> {
  // ✅ Lint Düzeltmesi: Field artık 'final' olarak işaretlendi
  static final List<Map<String, dynamic>> _cachedMosques = [];
  bool _loading = false;
  String? _errorMessage;

  final MapController _mapController = MapController();
  final ItemScrollController _itemScrollController = ItemScrollController();

  static const List<String> _overpassInstances = [
    'https://overpass-api.de/api/interpreter',
    'https://z.overpass-api.de/api/interpreter',
  ];

  @override
  void initState() {
    super.initState();
    _baslat();
  }

  Future<void> _baslat() async {
    if (!KonumServisi.yuklendi) {
      await KonumServisi.ilkKurulum();
    }

    if (_cachedMosques.isEmpty) {
      _fetchMosques();
    }
  }

  void _camiyeOdakla(int index, double lat, double lon) {
    HapticFeedback.lightImpact();
    _mapController.move(lat_lng.LatLng(lat, lon), 16.0);

    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.decelerate,
      );
    }
  }

  Future<void> _yolTarifi(double lat, double lon) async {
    HapticFeedback.heavyImpact();
    final url = Uri.parse("google.navigation:q=$lat,$lon&mode=d");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final webUrl = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$lat,$lon",
      );
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _fetchMosques() async {
    final coords = KonumServisi.coords;

    if (coords == null) {
      if (mounted) {
        setState(() {
          _errorMessage = "Konum bilgisi henüz hazır değil.";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    final query =
        '''
    [out:json][timeout:15];
    (
      nwr["amenity"="mosque"](around:3500,${coords.latitude},${coords.longitude});
      nwr["amenity"="place_of_worship"]["religion"~"muslim|islam"](around:3500,${coords.latitude},${coords.longitude});
    );
    out center qt;
    ''';

    for (var instanceUrl in _overpassInstances) {
      try {
        final response = await http
            .post(Uri.parse(instanceUrl), body: {'data': query})
            .timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final elements = data['elements'] as List<dynamic>? ?? [];
          _parseMosques(elements, coords, newList: _cachedMosques);
          if (_cachedMosques.isNotEmpty) break;
        }
      } catch (e) {
        debugPrint('Sunucu hatası ($instanceUrl): $e');
      }
    }

    if (mounted) {
      setState(() {
        _loading = false;
        _errorMessage = _cachedMosques.isEmpty
            ? "3.5km yakınınızda cami bulunamadı."
            : null;
      });
    }
  }

  void _parseMosques(
    List<dynamic> elements,
    dynamic userCoords, {
    required List<Map<String, dynamic>> newList,
  }) {
    final Set<String> seen = {};
    newList.clear();

    for (var e in elements) {
      final tags = (e['tags'] as Map?) ?? {};
      double lat = (e['lat'] ?? e['center']?['lat'] ?? 0.0).toDouble();
      double lon = (e['lon'] ?? e['center']?['lon'] ?? 0.0).toDouble();

      if (lat == 0 || lon == 0) {
        continue;
      }

      final key = "${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}";
      if (seen.contains(key)) {
        continue;
      }
      seen.add(key);

      newList.add({
        'ad': tags['name'] ?? tags['name:tr'] ?? 'Cami',
        'lat': lat,
        'lon': lon,
        'mesafe':
            Geolocator.distanceBetween(
              userCoords.latitude,
              userCoords.longitude,
              lat,
              lon,
            ) /
            1000,
      });
    }
    newList.sort((a, b) => a['mesafe'].compareTo(b['mesafe']));
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
          "YAKINDAKİ CAMİLER",
          style: TextStyle(
            letterSpacing: 1.5,
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: widget.onGeri ?? () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: widget.anaRenk,
                strokeWidth: 2,
              ),
            )
          : Column(
              children: [
                _buildLocationChip(),
                _buildMapArea(),
                const SizedBox(height: 12),
                Expanded(
                  child: _errorMessage != null
                      ? _buildErrorView()
                      : _buildMosqueList(),
                ),
              ],
            ),
    );
  }

  Widget _buildLocationChip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ✅ Lint Düzeltmesi: withValues kullanımı
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.anaRenk.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: widget.anaRenk, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              KonumServisi.adres,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    final coords = KonumServisi.coords;
    if (coords == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 200,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          // ✅ Lint Düzeltmesi: withValues kullanımı
          border: Border.all(color: widget.anaRenk.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: lat_lng.LatLng(coords.latitude, coords.longitude),
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                tileDisplay: const TileDisplay.fadeIn(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: lat_lng.LatLng(coords.latitude, coords.longitude),
                    child: Icon(
                      Icons.my_location,
                      color: widget.anaRenk,
                      size: 22,
                    ),
                  ),
                  ..._cachedMosques.asMap().entries.map((entry) {
                    return Marker(
                      point: lat_lng.LatLng(
                        entry.value['lat'],
                        entry.value['lon'],
                      ),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _camiyeOdakla(
                          entry.key,
                          entry.value['lat'],
                          entry.value['lon'],
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: widget.anaRenk,
                          size: 30,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMosqueList() {
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: _cachedMosques.length,
      itemBuilder: (context, i) {
        final cami = _cachedMosques[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            // ✅ Lint Düzeltmesi: withValues kullanımı
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            onTap: () => _camiyeOdakla(i, cami['lat'], cami['lon']),
            leading: Icon(Icons.mosque, color: widget.anaRenk, size: 24),
            title: Text(
              cami['ad'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              "${cami['mesafe'].toStringAsFixed(2)} km",
              // ✅ Lint Düzeltmesi: withValues kullanımı
              style: TextStyle(
                color: widget.anaRenk.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.directions_car, color: widget.anaRenk, size: 22),
              // ✅ Lint Düzeltmesi: _yolTarifi artık kullanılıyor
              onPressed: () => _yolTarifi(cami['lat'], cami['lon']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, color: Colors.white12, size: 40),
          const SizedBox(height: 12),
          // ✅ Lint Düzeltmesi: Süslü parantez içine alındı
          if (_errorMessage != null)
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _fetchMosques(),
            child: Text("Tekrar Dene", style: TextStyle(color: widget.anaRenk)),
          ),
        ],
      ),
    );
  }
}
