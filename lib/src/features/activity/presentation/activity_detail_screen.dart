import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../data/activity_providers.dart';
import '../data/activity_service.dart';
import '../domain/activity.dart';
import '../domain/track_analysis.dart';
import 'home_screen.dart' show activityIcon;
import 'share_screen.dart';

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
            data: (d) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Bagikan gambar',
                  icon: const Icon(Icons.ios_share),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ShareScreen(detail: d)),
                  ),
                ),
                IconButton(
                  tooltip: 'Ekspor GPX',
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: () => _exportGpx(context, ref, d.activity),
                ),
                IconButton(
                  tooltip: 'Hapus',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, d.activity.id),
                ),
              ],
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
              _ElevationChart(points: d.points),
              _Splits(points: d.points),
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

  Future<void> _exportGpx(BuildContext context, WidgetRef ref, Activity a) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await ref.read(activityServiceProvider).exportGpx(a.id);
      final dir = await getTemporaryDirectory();
      final safe = a.title.replaceAll(RegExp('[^a-zA-Z0-9-_ ]'), '').trim();
      final file = File('${dir.path}/${safe.isEmpty ? 'activity' : safe}.gpx');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: a.title));
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
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

class _ElevationChart extends StatelessWidget {
  const _ElevationChart({required this.points});
  final List<TrackPoint> points;

  @override
  Widget build(BuildContext context) {
    final series = elevationSeries(points);
    if (series.length < 2) return const SizedBox.shrink();
    final spots = [for (final e in series) FlSpot(e.km, e.ele)];
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profil Elevasi',
                  style: TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          getTitlesWidget: (v, meta) => Text(
                            '${v.round()}',
                            style: const TextStyle(fontSize: 10, color: AppColors.textSub),
                          ),
                        ),
                      ),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 2,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: AppColors.primary.withValues(alpha: 0.15)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Splits extends StatelessWidget {
  const _Splits({required this.points});
  final List<TrackPoint> points;

  @override
  Widget build(BuildContext context) {
    final splits = computeSplits(points);
    if (splits.isEmpty) return const SizedBox.shrink();
    final slowest = splits.map((s) => s.seconds).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Splits per km',
                  style: TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 12),
              for (final s in splits)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 22,
                        child: Text('${s.km}',
                            style: const TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (s.seconds / slowest).clamp(0.2, 1.0),
                            child: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(s.pace,
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
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
}
