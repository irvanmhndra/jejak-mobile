import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../domain/activity.dart';
import 'home_screen.dart' show activityIcon;

/// A full-screen preview of a shareable image card for an activity, with a
/// button that captures the card and opens the OS share sheet. The route is
/// drawn from GPS points (no map tiles) so capture is CORS/tile-free.
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.detail});
  final ActivityDetail detail;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/jejak-${widget.detail.activity.id}.png');
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], subject: widget.detail.activity.title),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bagikan')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _ShareCard(detail: widget.detail),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sharing ? null : _share,
                  icon: _sharing
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.ios_share),
                  label: Text(_sharing ? 'Menyiapkan…' : 'Bagikan Gambar'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({required this.detail});
  final ActivityDetail detail;

  @override
  Widget build(BuildContext context) {
    final a = detail.activity;
    final route = detail.points.map((p) => p.latLng).toList();
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Route (or a branded band for manual activities).
          Container(
            height: 200,
            color: AppColors.primary.withValues(alpha: 0.06),
            child: route.length > 1
                ? CustomPaint(painter: _RoutePainter(route))
                : Center(child: Icon(activityIcon(a.type), size: 64, color: AppColors.primary.withValues(alpha: 0.4))),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(activityIcon(a.type), size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(a.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(formatActivityDate(a.startedAt), style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _stat('${formatKm(a.distanceMeters)} km', 'Jarak'),
                    _stat(formatDuration(a.movingSeconds), 'Waktu'),
                    _stat(formatPaceOrSpeed(a.type, a.avgSpeedMps).replaceAll(' /km', '').replaceAll(' km/h', ''),
                        isPaceBased(a.type) ? 'Pace' : 'km/h'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.directions_run, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    const Text('Jejak', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 11)),
        ],
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.points);
  final List<LatLng> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    var minLat = 90.0, maxLat = -90.0, minLng = 180.0, maxLng = -180.0;
    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    final latRange = (maxLat - minLat).abs() < 1e-9 ? 1e-9 : (maxLat - minLat);
    final lngRange = (maxLng - minLng).abs() < 1e-9 ? 1e-9 : (maxLng - minLng);
    const pad = 24.0;
    final w = size.width - 2 * pad;
    final h = size.height - 2 * pad;
    final scale = math.min(w / lngRange, h / latRange);
    final offX = pad + (w - lngRange * scale) / 2;
    final offY = pad + (h - latRange * scale) / 2;

    Offset project(LatLng p) => Offset(
          offX + (p.longitude - minLng) * scale,
          offY + (maxLat - p.latitude) * scale, // flip Y (north up)
        );

    final path = ui.Path()..moveTo(project(points.first).dx, project(points.first).dy);
    for (final p in points.skip(1)) {
      final o = project(p);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(project(points.first), 5, Paint()..color = AppColors.success);
    canvas.drawCircle(project(points.last), 5, Paint()..color = AppColors.danger);
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.points != points;
}
