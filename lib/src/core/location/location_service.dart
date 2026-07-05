import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Thin wrapper around geolocator: permission handling + a position stream
/// tuned for activity tracking.
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

  Stream<Position> positionStream() => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 4, // meters
        ),
      );

  Future<Position> current() => Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
      );
}

final locationServiceProvider = Provider<LocationService>((ref) => const LocationService());
