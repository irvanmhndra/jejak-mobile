import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/activity_providers.dart';
import '../domain/stats.dart';
import 'home_screen.dart' show activityIcon;

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsSummaryProvider);
    final records = ref.watch(recordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(statsSummaryProvider);
          ref.invalidate(recordsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            stats.when(
              loading: () => const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text(e is Failure ? e.message : 'Gagal memuat statistik'),
              data: (s) => Column(
                children: [
                  _periodCard('Minggu Ini', s.week),
                  const SizedBox(height: 12),
                  _periodCard('Bulan Ini', s.month),
                  const SizedBox(height: 12),
                  _periodCard('Tahun Ini', s.year),
                  const SizedBox(height: 12),
                  _periodCard('Sepanjang Waktu', s.allTime),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Rekor Pribadi', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            records.when(
              loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text(e is Failure ? e.message : 'Gagal memuat rekor'),
              data: (list) => list.isEmpty
                  ? const EmptyState(icon: Icons.emoji_events_outlined, message: 'Belum ada rekor')
                  : Column(children: [for (final r in list) _recordTile(r)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodCard(String label, PeriodTotals t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSub, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              children: [
                _metric('${formatKm(t.distanceMeters)} km', 'jarak'),
                _metric(formatDuration(t.movingSeconds), 'waktu'),
                _metric('${t.count}', 'aktivitas'),
                _metric(formatElevation(t.elevationGainM), 'elevasi'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _recordTile(PersonalRecord r) {
    final (label, value) = _describe(r);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Icon(activityIcon(r.activityType), color: AppColors.primary),
        ),
        title: Text('${activityTypeLabel(r.activityType)} — $label'),
        subtitle: Text(formatShortDate(r.achievedAt)),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
      ),
    );
  }

  (String, String) _describe(PersonalRecord r) {
    switch (r.recordType) {
      case 'longest_distance':
        return ('Jarak terjauh', formatDistance(r.value));
      case 'longest_duration':
        return ('Durasi terlama', formatDuration(r.value.round()));
      case 'most_elevation':
        return ('Elevasi terbanyak', formatElevation(r.value));
      case 'fastest_speed':
        return ('Tercepat', formatPaceOrSpeed(r.activityType, r.value));
      case 'fastest_5k':
        return ('5K tercepat', formatDuration(r.value.round()));
      case 'fastest_10k':
        return ('10K tercepat', formatDuration(r.value.round()));
      case 'fastest_half':
        return ('Half tercepat', formatDuration(r.value.round()));
      case 'fastest_full':
        return ('Full tercepat', formatDuration(r.value.round()));
      default:
        return (r.recordType, r.value.toStringAsFixed(0));
    }
  }
}
