import 'package:intl/intl.dart';

/// Distance: meters -> "5.20 km" (>=1km) or "820 m".
String formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.round()} m';
}

/// Distance value only, in km, e.g. "5.20".
String formatKm(double meters) => (meters / 1000).toStringAsFixed(2);

/// Duration: seconds -> "1:23:45" or "23:45".
String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:$mm:$ss';
  return '$mm:$ss';
}

/// Pace from average speed (m/s) -> "5:30 /km". Returns "--:--" when stopped.
String formatPace(double speedMps) {
  if (speedMps <= 0) return "--:-- /km";
  final total = (1000 / speedMps).round(); // seconds per km, rounded first
  final m = total ~/ 60;
  final s = total % 60;
  return '$m:${s.toString().padLeft(2, '0')} /km';
}

/// Speed from m/s -> "24.3 km/h".
String formatSpeed(double speedMps) => '${(speedMps * 3.6).toStringAsFixed(1)} km/h';

/// Whether a type is pace-based (run/walk/hike) vs speed-based (ride).
bool isPaceBased(String type) => type != 'ride';

/// Pace or speed depending on activity type.
String formatPaceOrSpeed(String type, double speedMps) =>
    isPaceBased(type) ? formatPace(speedMps) : formatSpeed(speedMps);

String formatElevation(double meters) => '${meters.round()} m';

String formatActivityDate(DateTime dt) =>
    DateFormat("d MMM yyyy • HH:mm").format(dt.toLocal());

String formatShortDate(DateTime dt) => DateFormat('d MMM').format(dt.toLocal());

const activityTypeLabels = {
  'run': 'Lari',
  'ride': 'Bersepeda',
  'walk': 'Jalan',
  'hike': 'Hiking',
  'other': 'Aktivitas',
};

String activityTypeLabel(String type) => activityTypeLabels[type] ?? 'Aktivitas';
