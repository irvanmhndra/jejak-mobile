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
import 'record_controller.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  final _map = MapController();
  static const _fallbackCenter = LatLng(-6.2088, 106.8456); // Jakarta

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordControllerProvider);

    ref.listen(recordControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        ref.read(recordControllerProvider.notifier).clearError();
      }
      if (next.current != null && next.current != prev?.current) {
        _map.move(next.current!, _map.camera.zoom < 15 ? 16 : _map.camera.zoom);
      }
      if (next.status == RecordStatus.finished && prev?.status != RecordStatus.finished) {
        _showSaveSheet(state);
      }
    });

    final route = state.points.map((p) => p.latLng).toList();

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: state.current ?? _fallbackCenter,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.irvanmahendra.jejak',
              ),
              if (route.length > 1)
                PolylineLayer(
                  polylines: [Polyline(points: route, strokeWidth: 5, color: AppColors.primary)],
                ),
              if (state.current != null)
                MarkerLayer(markers: [
                  Marker(
                    point: state.current!,
                    width: 22,
                    height: 22,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                      ),
                    ),
                  ),
                ]),
            ],
          ),
          SafeArea(child: _topBar(state)),
          Align(alignment: Alignment.bottomCenter, child: _bottomPanel(state)),
        ],
      ),
    );
  }

  Widget _topBar(RecordState state) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _circleButton(Icons.close, () {
            if (state.isActive || state.status == RecordStatus.finished) {
              ref.read(recordControllerProvider.notifier).reset();
            }
            context.pop();
          }),
          const Spacer(),
          if (state.status == RecordStatus.idle) _typeChips(state),
        ],
      ),
    );
  }

  Widget _typeChips(RecordState state) {
    const types = ['run', 'ride', 'walk', 'hike'];
    return Wrap(
      spacing: 6,
      children: [
        for (final t in types)
          ChoiceChip(
            label: Text(activityTypeLabel(t)),
            selected: state.type == t,
            onSelected: (_) => ref.read(recordControllerProvider.notifier).setType(t),
          ),
      ],
    );
  }

  Widget _bottomPanel(RecordState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('Waktu', formatDuration(state.elapsedSeconds)),
              _stat('Jarak', formatKm(state.distanceMeters), unit: 'km'),
              _stat(isPaceBased(state.type) ? 'Pace' : 'Speed',
                  formatPaceOrSpeed(state.type, state.avgSpeedMps)),
            ],
          ),
          const SizedBox(height: 20),
          _controls(state),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, {String? unit}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            children: [
              TextSpan(text: value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              if (unit != null) TextSpan(text: ' $unit', style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _controls(RecordState state) {
    final notifier = ref.read(recordControllerProvider.notifier);
    switch (state.status) {
      case RecordStatus.idle:
        return SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: notifier.start,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Mulai'),
          ),
        );
      case RecordStatus.recording:
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: notifier.pause,
                  icon: const Icon(Icons.pause),
                  label: const Text('Jeda'),
                ),
              ),
            ),
          ],
        );
      case RecordStatus.paused:
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: notifier.resume,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Lanjut'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: notifier.finish,
                  icon: const Icon(Icons.stop),
                  label: const Text('Selesai'),
                ),
              ),
            ),
          ],
        );
      case RecordStatus.finished:
        return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
    }
  }

  Widget _circleButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 22)),
      ),
    );
  }

  Future<void> _showSaveSheet(RecordState state) async {
    final titleCtrl = TextEditingController();
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sheetCtx, setSheet) {
          Future<void> save() async {
            setSheet(() => saving = true);
            try {
              await ref.read(activityServiceProvider).createGPS(
                    type: state.type,
                    title: titleCtrl.text.trim(),
                    points: state.points,
                  );
              ref.invalidate(activitiesProvider);
              ref.invalidate(statsSummaryProvider);
              ref.invalidate(recordsProvider);
              ref.read(recordControllerProvider.notifier).reset();
              if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
              if (mounted) context.go('/');
            } on Failure catch (f) {
              setSheet(() => saving = false);
              if (sheetCtx.mounted) {
                ScaffoldMessenger.of(sheetCtx).showSnackBar(SnackBar(content: Text(f.message)));
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Simpan Aktivitas', style: Theme.of(sheetCtx).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '${activityTypeLabel(state.type)} • ${formatDistance(state.distanceMeters)} • ${formatDuration(state.elapsedSeconds)}',
                  style: const TextStyle(color: AppColors.textSub),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Judul (opsional)'),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: saving
                            ? null
                            : () {
                                ref.read(recordControllerProvider.notifier).reset();
                                Navigator.of(sheetCtx).pop();
                                if (mounted) context.pop();
                              },
                        child: const Text('Buang'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: saving ? null : save,
                        child: saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
