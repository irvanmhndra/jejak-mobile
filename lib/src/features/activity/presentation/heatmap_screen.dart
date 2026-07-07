import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/polyline.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/activity_providers.dart';

class HeatmapScreen extends ConsumerWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(activitiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Heatmap Rute')),
      body: activities.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is Failure ? e.message : 'Gagal memuat')),
        data: (items) {
          final routes = <List<LatLng>>[];
          for (final a in items) {
            if (a.polyline.isEmpty) continue;
            final pts = decodePolyline(a.polyline);
            if (pts.length > 1) routes.add(pts);
          }
          if (routes.isEmpty) {
            return const EmptyState(
              icon: Icons.map_outlined,
              message: 'Belum ada rute ber-GPS',
              hint: 'Rekam aktivitas untuk mengisi heatmap.',
            );
          }
          final all = [for (final r in routes) ...r];
          return FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(all),
                padding: const EdgeInsets.all(32),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.irvanmahendra.jejak',
              ),
              PolylineLayer(
                polylines: [
                  for (final r in routes)
                    Polyline(points: r, strokeWidth: 4, color: AppColors.primary.withValues(alpha: 0.35)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
