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
  static List<Map<String, dynamic>> _cachedMosques = [];
  bool _loading = true;
  String? _errorMessage;
  final MapController _mapController = MapController();
  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  Future<void> _initSequence() async {
    if (!KonumServisi.yuklendi) {
      await KonumServisi.ilkKurulum();
    }
    await _fetchMosquesFromAPI();
  }

  void _camiyeOdakla(int index, double lat, double lon) {
    HapticFeedback.lightImpact();
    _mapController.move(lat_lng.LatLng(lat, lon), 16.5);

    if (_itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _yolTarifiBaslat(double lat, double lon) async {
    HapticFeedback.heavyImpact();
    final googleUrl = Uri.parse("google.navigation:q=$lat,$lon&mode=d");
    final appleUrl = Uri.parse("https://maps.apple.com/?daddr=$lat,$lon");

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else if (await canLaunchUrl(appleUrl)) {
      await launchUrl(appleUrl);
    } else {
      final webUrl = Uri.parse(
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lon",
      );
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _fetchMosquesFromAPI() async {
    final coords = KonumServisi.coords;
    if (coords == null) {
      setState(() {
        _loading = false;
        _errorMessage = "Konum bilgisi alınamadı.";
      });
      return;
    }

    final url = Uri.parse('https://overpass-api.de/api/interpreter');
    const int yariCap = 5000; // 5 km

    final query =
        '''
    [out:json][timeout:90];
    (
      node["amenity"="mosque"](around:$yariCap,${coords.latitude},${coords.longitude});
      way["amenity"="mosque"](around:$yariCap,${coords.latitude},${coords.longitude});
      relation["amenity"="mosque"](around:$yariCap,${coords.latitude},${coords.longitude});
      
      node["religion"="islam"]["amenity"="place_of_worship"](around:$yariCap,${coords.latitude},${coords.longitude});
      way["religion"="islam"]["amenity"="place_of_worship"](around:$yariCap,${coords.latitude},${coords.longitude});
      relation["religion"="islam"]["amenity"="place_of_worship"](around:$yariCap,${coords.latitude},${coords.longitude});
      
      node["building"="mosque"](around:$yariCap,${coords.latitude},${coords.longitude});
      way["building"="mosque"](around:$yariCap,${coords.latitude},${coords.longitude});
      
      node["historic"="mosque"](around:$yariCap,${coords.latitude},${coords.longitude});
      way["historic"="mosque"](around:$yariCap,${coords.latitude},${coords.longitude});
    );
    out center;
    ''';

    try {
      final res = await http
          .post(url, body: {'data': query})
          .timeout(const Duration(seconds: 90));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final List elements = data['elements'] ?? [];

        final Set<String> seenKeys = {};
        final List<Map<String, dynamic>> newList = [];

        for (var e in elements) {
          final tags = e['tags'] ?? {};

          String? rawName =
              tags['name'] ??
              tags['name:tr'] ??
              tags['official_name'] ??
              tags['alt_name'] ??
              tags['short_name'];

          String fallback =
              tags['addr:quarter'] ??
              tags['addr:suburb'] ??
              tags['addr:neighbourhood'] ??
              tags['addr:street'] ??
              tags['addr:place'] ??
              "Yakın Bölge";

          String camiAdi = rawName ?? "$fallback Cami";

          double lat = (e['lat'] ?? e['center']?['lat'] ?? 0.0).toDouble();
          double lon = (e['lon'] ?? e['center']?['lon'] ?? 0.0).toDouble();

          if (lat == 0.0 || lon == 0.0) continue;

          String key = "${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}";
          if (seenKeys.contains(key)) continue;
          seenKeys.add(key);

          double distance =
              Geolocator.distanceBetween(
                coords.latitude,
                coords.longitude,
                lat,
                lon,
              ) /
              1000;

          if (distance <= 5.0) {
            newList.add({
              'ad': camiAdi,
              'lat': lat,
              'lon': lon,
              'mesafe': distance,
            });
          }
        }

        newList.sort((a, b) => a['mesafe'].compareTo(b['mesafe']));

        if (mounted) {
          setState(() {
            _cachedMosques = newList;
            _loading = false;
            _errorMessage = newList.isEmpty
                ? "5 km içinde cami bulunamadı."
                : null;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = "Sunucu hatası: ${res.statusCode}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = "Bağlantı hatası: $e";
        });
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
          "YAKINDAKİ CAMİLER",
          style: TextStyle(
            fontSize: 14,
            letterSpacing: 3,
            fontWeight: FontWeight.w100,
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
      body: _loading
          ? Center(child: CircularProgressIndicator(color: widget.anaRenk))
          : Column(
              children: [
                _buildLocationChip(),
                _buildMapArea(),
                Expanded(
                  flex: 4,
                  child: _errorMessage != null
                      ? _buildErrorView()
                      : _cachedMosques.isEmpty
                      ? _buildEmptyView()
                      : _buildMosqueList(),
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  Widget _buildLocationChip() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
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
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    final coords = KonumServisi.coords;
    if (coords == null) return const SizedBox();

    return Expanded(
      flex: 3,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: widget.anaRenk.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: lat_lng.LatLng(coords.latitude, coords.longitude),
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: lat_lng.LatLng(coords.latitude, coords.longitude),
                    child: Icon(
                      Icons.my_location,
                      color: widget.anaRenk,
                      size: 28,
                    ),
                  ),
                  ..._cachedMosques.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var m = entry.value;
                    return Marker(
                      point: lat_lng.LatLng(m['lat'], m['lon']),
                      child: GestureDetector(
                        onTap: () => _camiyeOdakla(idx, m['lat'], m['lon']),
                        child: Icon(
                          Icons.mosque,
                          color: widget.anaRenk,
                          size: 36,
                          shadows: const [
                            Shadow(color: Colors.black54, blurRadius: 8),
                          ],
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
    return ScrollablePositionedList.separated(
      itemScrollController: _itemScrollController,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _cachedMosques.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: 12), // DÜZELTİLDİ: __ → _
      itemBuilder: (context, i) {
        final cami = _cachedMosques[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            onTap: () => _camiyeOdakla(i, cami['lat'], cami['lon']),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.anaRenk.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.mosque, color: widget.anaRenk, size: 24),
            ),
            title: Text(
              cami['ad'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "${cami['mesafe'].toStringAsFixed(2)} km uzaklıkta",
              style: TextStyle(
                color: widget.anaRenk.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.directions_car, color: widget.anaRenk, size: 28),
              onPressed: () => _yolTarifiBaslat(cami['lat'], cami['lon']),
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
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 56),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _loading = true);
              _fetchMosquesFromAPI();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Tekrar Dene"),
            style: ElevatedButton.styleFrom(backgroundColor: widget.anaRenk),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mosque_outlined, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          const Text(
            "5 km içinde cami verisi bulunamadı.\n(OpenStreetMap'te kayıtlı olmayabilir)",
            style: TextStyle(color: Colors.white54, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() => _loading = true);
              _fetchMosquesFromAPI();
            },
            icon: const Icon(Icons.refresh),
            label: const Text("Tekrar Ara"),
            style: ElevatedButton.styleFrom(backgroundColor: widget.anaRenk),
          ),
        ],
      ),
    );
  }
}
