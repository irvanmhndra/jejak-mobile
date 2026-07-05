import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../data/activity_providers.dart';
import '../data/activity_service.dart';
import '../domain/activity.dart';
import 'home_screen.dart' show activityIcon;

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(activityDetailProvider(id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
        actions: [
          detail.maybeWhen(
            data: (d) => IconButton(
              tooltip: 'Hapus',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, d.activity.id),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e is Failure ? e.message : 'Gagal memuat')),
        data: (d) => _body(context, d),
      ),
    );
  }

  Widget _body(BuildContext context, ActivityDetail d) {
    final a = d.activity;
    final route = d.points.map((p) => p.latLng).toList();
    return ListView(
      children: [
        if (route.length > 1) SizedBox(height: 260, child: _map(route)),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(activityIcon(a.type), color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(a.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(formatActivityDate(a.startedAt), style: const TextStyle(color: AppColors.textSub)),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.6,
                children: [
                  _stat('Jarak', '${formatKm(a.distanceMeters)} km'),
                  _stat(isPaceBased(a.type) ? 'Pace' : 'Kecepatan', formatPaceOrSpeed(a.type, a.avgSpeedMps)),
                  _stat('Waktu Gerak', formatDuration(a.movingSeconds)),
                  _stat('Total Waktu', formatDuration(a.elapsedSeconds)),
                  _stat('Elevasi Naik', formatElevation(a.elevationGainM)),
                  _stat('Kecepatan Maks', formatSpeed(a.maxSpeedMps)),
                ],
              ),
              if (a.notes != null && a.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(a.notes!, style: const TextStyle(color: AppColors.textSub)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _map(List<LatLng> route) {
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(route),
          padding: const EdgeInsets.all(40),
        ),
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.irvanmahendra.jejak',
        ),
        PolylineLayer(polylines: [Polyline(points: route, strokeWidth: 5, color: AppColors.primary)]),
        MarkerLayer(markers: [
          _pin(route.first, AppColors.success),
          _pin(route.last, AppColors.danger),
        ]),
      ],
    );
  }

  Marker _pin(LatLng at, Color color) => Marker(
        point: at,
        width: 16,
        height: 16,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, String activityId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus aktivitas?'),
        content: const Text('Aktivitas ini akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(activityServiceProvider).delete(activityId);
      ref.invalidate(activitiesProvider);
      ref.invalidate(statsSummaryProvider);
      ref.invalidate(recordsProvider);
      if (context.mounted) context.pop();
    } on Failure catch (f) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
      }
    }
  }
}
