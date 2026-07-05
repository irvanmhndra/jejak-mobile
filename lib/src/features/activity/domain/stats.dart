class StatBucket {
  const StatBucket({
    required this.type,
    required this.count,
    required this.distanceMeters,
    required this.movingSeconds,
    required this.elevationGainM,
  });

  final String type;
  final int count;
  final double distanceMeters;
  final int movingSeconds;
  final double elevationGainM;

  factory StatBucket.fromJson(Map<String, dynamic> json) => StatBucket(
        type: json['type'] as String,
        count: (json['count'] as num?)?.toInt() ?? 0,
        distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
        movingSeconds: (json['moving_seconds'] as num?)?.toInt() ?? 0,
        elevationGainM: (json['elevation_gain_m'] as num?)?.toDouble() ?? 0,
      );
}

class PeriodTotals {
  const PeriodTotals({
    required this.count,
    required this.distanceMeters,
    required this.movingSeconds,
    required this.elevationGainM,
    required this.byType,
  });

  final int count;
  final double distanceMeters;
  final int movingSeconds;
  final double elevationGainM;
  final List<StatBucket> byType;

  factory PeriodTotals.fromJson(Map<String, dynamic> json) => PeriodTotals(
        count: (json['count'] as num?)?.toInt() ?? 0,
        distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
        movingSeconds: (json['moving_seconds'] as num?)?.toInt() ?? 0,
        elevationGainM: (json['elevation_gain_m'] as num?)?.toDouble() ?? 0,
        byType: ((json['by_type'] as List<dynamic>?) ?? [])
            .map((e) => StatBucket.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class StatsSummary {
  const StatsSummary({required this.week, required this.month, required this.year, required this.allTime});

  final PeriodTotals week;
  final PeriodTotals month;
  final PeriodTotals year;
  final PeriodTotals allTime;

  factory StatsSummary.fromJson(Map<String, dynamic> json) => StatsSummary(
        week: PeriodTotals.fromJson(json['week'] as Map<String, dynamic>),
        month: PeriodTotals.fromJson(json['month'] as Map<String, dynamic>),
        year: PeriodTotals.fromJson(json['year'] as Map<String, dynamic>),
        allTime: PeriodTotals.fromJson(json['all_time'] as Map<String, dynamic>),
      );
}

class PersonalRecord {
  const PersonalRecord({
    required this.activityType,
    required this.recordType,
    required this.value,
    required this.activityId,
    required this.achievedAt,
  });

  final String activityType;
  final String recordType;
  final double value;
  final String activityId;
  final DateTime achievedAt;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => PersonalRecord(
        activityType: json['activity_type'] as String,
        recordType: json['record_type'] as String,
        value: (json['value'] as num?)?.toDouble() ?? 0,
        activityId: json['activity_id'] as String,
        achievedAt: DateTime.parse(json['achieved_at'] as String),
      );
}
