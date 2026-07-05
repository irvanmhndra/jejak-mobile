import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/activity.dart';
import '../domain/stats.dart';
import 'activity_service.dart';

/// History list (most recent first). Invalidate after creating/deleting.
final activitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final page = await ref.watch(activityServiceProvider).list(limit: 50);
  return page.items;
});

final activityDetailProvider = FutureProvider.family<ActivityDetail, String>((ref, id) async {
  return ref.watch(activityServiceProvider).get(id);
});

final statsSummaryProvider = FutureProvider<StatsSummary>((ref) async {
  return ref.watch(activityServiceProvider).statsSummary();
});

final recordsProvider = FutureProvider<List<PersonalRecord>>((ref) async {
  return ref.watch(activityServiceProvider).records();
});
