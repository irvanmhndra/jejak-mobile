import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Thin wrapper around geolocator: permission handling + a background-capable
/// position stream tuned for activity tracking.
class LocationService {
  const LocationService();

  /// Ensures location services are on and permission is granted.
  /// Returns null on success, or a user-facing error message.
  Future<String?> ensureReady() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return 'Layanan lokasi mati. Nyalakan GPS dulu.';
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      return 'Izin lokasi ditolak.';
    }
    if (perm == LocationPermission.deniedForever) {
      return 'Izin lokasi ditolak permanen. Aktifkan di Pengaturan.';
    }
    return null;
  }

  Stream<Position> positionStream() {
    const accuracy = LocationAccuracy.best;
    const distanceFilter = 4; // meters
    LocationSettings settings;
    if (Platform.isIOS) {
      settings = AppleSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        // Keep recording with the screen off / app backgrounded.
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    } else if (Platform.isAndroid) {
      settings = AndroidSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Jejak sedang merekam',
          notificationText: 'Melacak rute aktivitasmu',
          enableWakeLock: true,
        ),
      );
    } else {
      settings = const LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
    }
    return Geolocator.getPositionStream(locationSettings: settings);
  }

  Future<Position> current() => Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
}

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());
