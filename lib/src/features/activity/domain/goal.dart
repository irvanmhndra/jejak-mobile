class Goal {
  const Goal({
    required this.id,
    required this.period,
    this.activityType,
    required this.targetMeters,
    required this.currentMeters,
  });

  final String id;
  final String period; // 'weekly' | 'monthly'
  final String? activityType;
  final double targetMeters;
  final double currentMeters;

  double get progress => targetMeters > 0 ? (currentMeters / targetMeters).clamp(0.0, 1.0) : 0;
  bool get done => currentMeters >= targetMeters && targetMeters > 0;

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] as String,
        period: json['period'] as String,
        activityType: json['activity_type'] as String?,
        targetMeters: (json['target_meters'] as num?)?.toDouble() ?? 0,
        currentMeters: (json['current_meters'] as num?)?.toDouble() ?? 0,
      );
}
