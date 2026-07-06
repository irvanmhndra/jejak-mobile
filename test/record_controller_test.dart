import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jejak_mobile/src/core/location/location_service.dart';
import 'package:jejak_mobile/src/features/activity/presentation/record_controller.dart';

/// A LocationService whose stream we feed synthetic positions into.
class _FakeLocation extends LocationService {
  _FakeLocation(this.controller);
  final StreamController<Position> controller;

  @override
  Future<String?> ensureReady() async => null;

  @override
  Stream<Position> positionStream() => controller.stream;
}

Position _pos(double lat, double lng, DateTime t, {double speed = 3, double alt = 10}) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: t,
      accuracy: 5,
      altitude: alt,
      altitudeAccuracy: 3,
      heading: 0,
      headingAccuracy: 0,
      speed: speed,
      speedAccuracy: 1,
    );

Future<void> _tick() => Future<void>.delayed(Duration.zero);

void main() {
  test('recording accumulates points + distance and honors pause/resume/finish', () async {
    final positions = StreamController<Position>.broadcast();
    final container = ProviderContainer(
      overrides: [locationServiceProvider.overrideWithValue(_FakeLocation(positions))],
    );
    addTearDown(container.dispose);
    addTearDown(positions.close);

    final notifier = container.read(recordControllerProvider.notifier);

    await notifier.start();
    expect(container.read(recordControllerProvider).status, RecordStatus.recording);

    final base = DateTime.utc(2026, 1, 1, 6);
    positions.add(_pos(-6.20000, 106.80000, base));
    await _tick();
    // ~100 m north (0.0009° lat) 30 s later.
    positions.add(_pos(-6.20090, 106.80000, base.add(const Duration(seconds: 30))));
    await _tick();

    var s = container.read(recordControllerProvider);
    expect(s.points.length, 2);
    expect(s.distanceMeters, greaterThan(90));
    expect(s.distanceMeters, lessThan(110));
    expect(s.current?.latitude, closeTo(-6.20090, 1e-6));

    // Paused: new fixes are ignored.
    notifier.pause();
    positions.add(_pos(-6.20180, 106.80000, base.add(const Duration(seconds: 60))));
    await _tick();
    s = container.read(recordControllerProvider);
    expect(s.status, RecordStatus.paused);
    expect(s.points.length, 2);

    // Resumed: fixes are recorded again.
    notifier.resume();
    positions.add(_pos(-6.20180, 106.80000, base.add(const Duration(seconds: 90))));
    await _tick();
    s = container.read(recordControllerProvider);
    expect(s.points.length, 3);
    expect(s.distanceMeters, greaterThan(190));

    // Finished: recording stops but the track is retained for saving.
    notifier.finish();
    s = container.read(recordControllerProvider);
    expect(s.status, RecordStatus.finished);
    expect(s.points.length, 3);
  });

  test('setType only applies while idle', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(recordControllerProvider.notifier);

    notifier.setType('ride');
    expect(container.read(recordControllerProvider).type, 'ride');
  });
}
