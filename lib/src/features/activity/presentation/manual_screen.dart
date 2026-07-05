import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../core/utils/format.dart';
import '../data/activity_providers.dart';
import '../data/activity_service.dart';

class ManualScreen extends ConsumerStatefulWidget {
  const ManualScreen({super.key});

  @override
  ConsumerState<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends ConsumerState<ManualScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _distanceKm = TextEditingController();
  final _minutes = TextEditingController();
  String _type = 'run';
  DateTime _startedAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _distanceKm.dispose();
    _minutes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_startedAt));
    setState(() {
      _startedAt = DateTime(date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final km = double.tryParse(_distanceKm.text.replaceAll(',', '.')) ?? 0;
    final minutes = int.tryParse(_minutes.text) ?? 0;
    setState(() => _saving = true);
    try {
      await ref.read(activityServiceProvider).createManual(
            type: _type,
            title: _title.text.trim(),
            startedAt: _startedAt,
            elapsedSeconds: minutes * 60,
            distanceMeters: km * 1000,
          );
      ref.invalidate(activitiesProvider);
      ref.invalidate(statsSummaryProvider);
      ref.invalidate(recordsProvider);
      if (mounted) context.pop();
    } on Failure catch (f) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Input Manual')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final t in const ['run', 'ride', 'walk', 'hike'])
                  ChoiceChip(
                    label: Text(activityTypeLabel(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Judul (opsional)'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: Text(formatActivityDate(_startedAt)),
              trailing: const Icon(Icons.edit),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _distanceKm,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(labelText: 'Jarak (km)', suffixText: 'km'),
              validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) ?? 0) <= 0 ? 'Isi jarak' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Durasi (menit)', suffixText: 'menit'),
              validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0 ? 'Isi durasi' : null,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
