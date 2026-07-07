import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/empty_state.dart';
import '../data/goal_service.dart';
import '../domain/goal.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target'),
        actions: [
          IconButton(
            tooltip: 'Tambah target',
            icon: const Icon(Icons.add),
            onPressed: () => _showAdd(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(goalsProvider),
        child: goals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e is Failure ? e.message : 'Gagal memuat')),
          data: (list) => list.isEmpty
              ? const EmptyState(
                  icon: Icons.flag_outlined,
                  message: 'Belum ada target',
                  hint: 'Tekan + untuk menambah target mingguan/bulanan.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [for (final g in list) _GoalCard(goal: g, onDelete: () => _delete(context, ref, g.id))],
                ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async {
    try {
      await ref.read(goalServiceProvider).delete(id);
      ref.invalidate(goalsProvider);
    } on Failure catch (f) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
      }
    }
  }

  Future<void> _showAdd(BuildContext context, WidgetRef ref) async {
    var period = 'weekly';
    String? type;
    final kmCtrl = TextEditingController();
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          Future<void> save() async {
            final km = double.tryParse(kmCtrl.text.replaceAll(',', '.')) ?? 0;
            if (km <= 0) return;
            setSheet(() => saving = true);
            try {
              await ref.read(goalServiceProvider).create(
                    period: period,
                    activityType: type,
                    targetMeters: km * 1000,
                  );
              ref.invalidate(goalsProvider);
              if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
            } on Failure catch (f) {
              setSheet(() => saving = false);
              if (sheetCtx.mounted) {
                ScaffoldMessenger.of(sheetCtx).showSnackBar(SnackBar(content: Text(f.message)));
              }
            }
          }

          Widget chips<T>(List<(T, String)> options, T selected, void Function(T) onPick) => Wrap(
                spacing: 8,
                children: [
                  for (final o in options)
                    ChoiceChip(
                      label: Text(o.$2),
                      selected: selected == o.$1,
                      onSelected: (_) => setSheet(() => onPick(o.$1)),
                    ),
                ],
              );

          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah Target', style: Theme.of(sheetCtx).textTheme.titleLarge),
                const SizedBox(height: 16),
                const Text('Periode', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                chips<String>(const [('weekly', 'Mingguan'), ('monthly', 'Bulanan')], period, (v) => period = v),
                const SizedBox(height: 16),
                const Text('Tipe', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                chips<String?>(
                  const [(null, 'Semua'), ('run', 'Lari'), ('ride', 'Sepeda'), ('walk', 'Jalan'), ('hike', 'Hiking')],
                  type,
                  (v) => type = v,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: kmCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: const InputDecoration(labelText: 'Target (km)', suffixText: 'km'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: saving ? null : save,
                    child: saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Simpan'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onDelete});
  final Goal goal;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final label = goal.period == 'weekly' ? 'Mingguan' : 'Bulanan';
    final title = goal.activityType != null ? '$label · ${activityTypeLabel(goal.activityType!)}' : label;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                Text('${formatKm(goal.currentMeters)} / ${formatKm(goal.targetMeters)} km',
                    style: const TextStyle(color: AppColors.textSub, fontSize: 13)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: goal.done ? AppColors.success : AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              goal.done ? '🎉 Tercapai!' : '${(goal.progress * 100).round()}%',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: goal.done ? AppColors.success : AppColors.textSub,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
