import 'package:latlong2/latlong.dart';

class TrackPoint {
  const TrackPoint({required this.lat, required this.lng, this.ele, required this.t, this.dist = 0});

  final double lat;
  final double lng;
  final double? ele;
  final DateTime t;
  final double dist;

  LatLng get latLng => LatLng(lat, lng);

  factory TrackPoint.fromJson(Map<String, dynamic> json) => TrackPoint(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        ele: (json['ele'] as num?)?.toDouble(),
        t: DateTime.parse(json['t'] as String),
        dist: (json['dist'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (ele != null) 'ele': ele,
        't': t.toUtc().toIso8601String(),
      };
}

class Activity {
  const Activity({
    required this.id,
    required this.type,
    required this.title,
    this.notes,
    required this.source,
    required this.startedAt,
    required this.elapsedSeconds,
    required this.movingSeconds,
    required this.distanceMeters,
    required this.avgSpeedMps,
    required this.maxSpeedMps,
    required this.elevationGainM,
    required this.elevationLossM,
    required this.polyline,
    required this.pointCount,
  });

  final String id;
  final String type;
  final String title;
  final String? notes;
  final String source;
  final DateTime startedAt;
  final int elapsedSeconds;
  final int movingSeconds;
  final double distanceMeters;
  final double avgSpeedMps;
  final double maxSpeedMps;
  final double elevationGainM;
  final double elevationLossM;
  final String polyline;
  final int pointCount;

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String? ?? '',
        notes: json['notes'] as String?,
        source: json['source'] as String? ?? 'gps',
        startedAt: DateTime.parse(json['started_at'] as String),
        elapsedSeconds: (json['elapsed_seconds'] as num?)?.toInt() ?? 0,
        movingSeconds: (json['moving_seconds'] as num?)?.toInt() ?? 0,
        distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
        avgSpeedMps: (json['avg_speed_mps'] as num?)?.toDouble() ?? 0,
        maxSpeedMps: (json['max_speed_mps'] as num?)?.toDouble() ?? 0,
        elevationGainM: (json['elevation_gain_m'] as num?)?.toDouble() ?? 0,
        elevationLossM: (json['elevation_loss_m'] as num?)?.toDouble() ?? 0,
        polyline: json['polyline'] as String? ?? '',
        pointCount: (json['point_count'] as num?)?.toInt() ?? 0,
      );
}

class ActivityDetail {
  const ActivityDetail({required this.activity, required this.points});
  final Activity activity;
  final List<TrackPoint> points;

  factory ActivityDetail.fromJson(Map<String, dynamic> json) => ActivityDetail(
        activity: Activity.fromJson(json),
        points: ((json['points'] as List<dynamic>?) ?? [])
            .map((e) => TrackPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
