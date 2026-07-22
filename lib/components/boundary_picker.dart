import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

/// Shared map-based geofence picker. Returns `{lat, lng, radiusMeters}` or null
/// if cancelled. Used to set an admin's presence location from the Office Admin
/// and Dean screens.
Future<Map<String, dynamic>?> showBoundaryPicker(
  BuildContext context, {
  required Color accent,
  Map<String, dynamic>? existing,
  String title = 'Set Presence Location',
}) async {
  LatLng pos;
  if (existing != null) {
    pos = LatLng((existing['lat'] as num).toDouble(),
        (existing['lng'] as num).toDouble());
  } else {
    try {
      final loc = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      pos = LatLng(loc.latitude, loc.longitude);
    } catch (_) {
      pos = const LatLng(20.59, 78.96);
    }
  }
  double radius =
      existing != null ? (existing['radiusMeters'] as num).toDouble() : 100.0;
  LatLng current = pos;
  final mapController = MapController();
  if (!context.mounted) return null;

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        height: 560,
        width: 600,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: accent,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.my_location, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(dialogCtx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StatefulBuilder(builder: (_, setSt) {
                return Stack(
                  children: [
                    FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: pos,
                        initialZoom: 16,
                        onTap: (_, p) => setSt(() => current = p),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.virtualvision.admin',
                        ),
                        CircleLayer(circles: [
                          CircleMarker(
                            point: current,
                            radius: radius,
                            useRadiusInMeter: true,
                            color: accent.withValues(alpha: 0.18),
                            borderColor: accent,
                            borderStrokeWidth: 2,
                          ),
                        ]),
                        MarkerLayer(markers: [
                          Marker(
                            point: current,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.location_on,
                                color: Colors.red, size: 40),
                          ),
                        ]),
                      ],
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              const Icon(Icons.my_location,
                                  size: 13, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                "${current.latitude.toStringAsFixed(5)}, ${current.longitude.toStringAsFixed(5)}",
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Row(children: [
                              Icon(Icons.radio_button_checked,
                                  size: 13, color: accent),
                              const SizedBox(width: 6),
                              Text("Radius: ${radius.toStringAsFixed(0)} m",
                                  style: const TextStyle(
                                      fontSize: 12, fontWeight: FontWeight.w600)),
                              Expanded(
                                child: Slider(
                                  value: radius,
                                  min: 30,
                                  max: 500,
                                  divisions: 47,
                                  activeColor: accent,
                                  onChanged: (v) => setSt(() => radius = v),
                                ),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => Navigator.pop(dialogCtx, {
                                  'lat': current.latitude,
                                  'lng': current.longitude,
                                  'radiusMeters': radius,
                                }),
                                child: const Text("Confirm Location",
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    ),
  );
}
