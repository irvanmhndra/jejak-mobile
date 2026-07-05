import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/location/location_service.dart';
import '../domain/activity.dart';

enum RecordStatus { idle, recording, paused, finished }

class RecordState {
  const RecordState({
    this.status = RecordStatus.idle,
    this.type = 'run',
    this.points = const [],
    this.elapsedSeconds = 0,
    this.distanceMeters = 0,
    this.currentSpeedMps = 0,
    this.current,
    this.errorMessage,
  });

  final RecordStatus status;
  final String type;
  final List<TrackPoint> points;
  final int elapsedSeconds;
  final double distanceMeters;
  final double currentSpeedMps;
  final LatLng? current;
  final String? errorMessage;

  bool get isActive => status == RecordStatus.recording || status == RecordStatus.paused;

  /// Live average speed (m/s) over elapsed time.
  double get avgSpeedMps => elapsedSeconds > 0 ? distanceMeters / elapsedSeconds : 0;

  RecordState copyWith({
    RecordStatus? status,
    String? type,
    List<TrackPoint>? points,
    int? elapsedSeconds,
    double? distanceMeters,
    double? currentSpeedMps,
    LatLng? current,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecordState(
      status: status ?? this.status,
      type: type ?? this.type,
      points: points ?? this.points,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      currentSpeedMps: currentSpeedMps ?? this.currentSpeedMps,
      current: current ?? this.current,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RecordController extends Notifier<RecordState> {
  Timer? _ticker;
  StreamSubscription<Position>? _sub;
  static const _distance = Distance();

  @override
  RecordState build() {
    ref.onDispose(_teardown);
    return const RecordState();
  }

  void setType(String type) {
    if (state.status == RecordStatus.idle) {
      state = state.copyWith(type: type);
    }
  }

  Future<void> start() async {
    final err = await ref.read(locationServiceProvider).ensureReady();
    if (err != null) {
      state = state.copyWith(errorMessage: err);
      return;
    }
    state = RecordState(status: RecordStatus.recording, type: state.type);
    _sub = ref.read(locationServiceProvider).positionStream().listen(_onPosition);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == RecordStatus.recording) {
        state = state.copyWith(elapsedSeconds: state.elapsedSeconds + 1);
      }
    });
  }

  void pause() {
    if (state.status == RecordStatus.recording) {
      state = state.copyWith(status: RecordStatus.paused);
    }
  }

  void resume() {
    if (state.status == RecordStatus.paused) {
      state = state.copyWith(status: RecordStatus.recording);
    }
  }

  /// Stops recording and moves to the "finished" state (points retained for save).
  void finish() {
    _teardown();
    state = state.copyWith(status: RecordStatus.finished);
  }

  /// Discards the current recording and returns to idle.
  void reset() {
    _teardown();
    state = RecordState(type: state.type);
  }

  void clearError() => state = state.copyWith(clearError: true);

  void _onPosition(Position pos) {
    if (state.status != RecordStatus.recording) return;
    final point = TrackPoint(
      lat: pos.latitude,
      lng: pos.longitude,
      ele: pos.altitude,
      t: pos.timestamp,
    );
    var dist = state.distanceMeters;
    if (state.points.isNotEmpty) {
      final last = state.points.last;
      dist += _distance(LatLng(last.lat, last.lng), LatLng(pos.latitude, pos.longitude));
    }
    state = state.copyWith(
      points: [...state.points, point],
      distanceMeters: dist,
      currentSpeedMps: pos.speed < 0 ? 0 : pos.speed,
      current: LatLng(pos.latitude, pos.longitude),
    );
  }

  void _teardown() {
    _ticker?.cancel();
    _ticker = null;
    _sub?.cancel();
    _sub = null;
  }
}

final recordControllerProvider =
    NotifierProvider<RecordController, RecordState>(RecordController.new);
