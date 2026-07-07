import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/activity_providers.dart';
import '../data/activity_service.dart';
import '../domain/activity.dart';
import '../domain/stats.dart';

IconData activityIcon(String type) => switch (type) {
      'run' => Icons.directions_run,
      'ride' => Icons.directions_bike,
      'walk' => Icons.directions_walk,
      'hike' => Icons.terrain,
      _ => Icons.timer_outlined,
    };

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsSummaryProvider);
    final activities = ref.watch(activitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jejak'),
        actions: [
          IconButton(
            tooltip: 'Heatmap',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.push('/heatmap'),
          ),
          IconButton(
            tooltip: 'Target',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => context.push('/goals'),
          ),
          IconButton(
            tooltip: 'Statistik',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/stats'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'manual':
                  context.push('/manual');
                case 'import':
                  _importGpx(context, ref);
                case 'logout':
                  ref.read(authControllerProvider.notifier).logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'manual', child: Text('Input manual')),
              PopupMenuItem(value: 'import', child: Text('Impor GPX')),
              PopupMenuItem(value: 'logout', child: Text('Keluar')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/record'),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Rekam'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsSummaryProvider);
          ref.invalidate(activitiesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            stats.when(
              loading: () => const _WeekCardSkeleton(),
              error: (e, _) => const SizedBox.shrink(),
              data: (s) => _WeekCard(totals: s.week),
            ),
            const SizedBox(height: 20),
            Text('Aktivitas Terbaru', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            activities.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(e is Failure ? e.message : 'Gagal memuat aktivitas'),
              ),
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.directions_run,
                      message: 'Belum ada aktivitas',
                      hint: 'Tekan Rekam untuk mulai melacak.',
                    )
                  : Column(
                      children: [for (final a in list) _ActivityTile(activity: a)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importGpx(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gpx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    final bytes = picked.bytes;
    if (bytes == null) return;
    try {
      final activity = await ref
          .read(activityServiceProvider)
          .importGpx(bytes, filename: picked.name);
      ref.invalidate(activitiesProvider);
      ref.invalidate(statsSummaryProvider);
      ref.invalidate(recordsProvider);
      if (context.mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Diimpor: ${activity.title}')));
      }
    } on Failure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.totals});
  final PeriodTotals totals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Minggu Ini', style: TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                _metric(context, formatKm(totals.distanceMeters), 'km'),
                _metric(context, formatDuration(totals.movingSeconds), 'waktu'),
                _metric(context, '${totals.count}', 'aktivitas'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
        ],
      ),
    );
  }
}

class _WeekCardSkeleton extends StatelessWidget {
  const _WeekCardSkeleton();
  @override
  Widget build(BuildContext context) => const Card(
        child: SizedBox(height: 108, child: Center(child: CircularProgressIndicator())),
      );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final Activity activity;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: () => context.push('/activities/${activity.id}'),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(activityIcon(activity.type), color: AppColors.primary),
        ),
        title: Text(activity.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(formatActivityDate(activity.startedAt)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${formatKm(activity.distanceMeters)} km',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(formatDuration(activity.movingSeconds),
                style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
