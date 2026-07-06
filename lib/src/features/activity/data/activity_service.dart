import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/activity.dart';
import '../domain/stats.dart';

class ActivityListPage {
  const ActivityListPage({required this.items, required this.total});
  final List<Activity> items;
  final int total;
}

class ActivityService {
  const ActivityService(this._dio);
  final Dio _dio;

  Future<Activity> createGPS({
    required String type,
    String? title,
    String? notes,
    required List<TrackPoint> points,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/activities', data: {
        'type': type,
        if (title != null && title.isNotEmpty) 'title': title,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'points': points.map((p) => p.toJson()).toList(),
      });
      return Activity.fromJson(res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Activity> createManual({
    required String type,
    String? title,
    String? notes,
    required DateTime startedAt,
    required int elapsedSeconds,
    required double distanceMeters,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/activities/manual', data: {
        'type': type,
        if (title != null && title.isNotEmpty) 'title': title,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'started_at': startedAt.toUtc().toIso8601String(),
        'elapsed_seconds': elapsedSeconds,
        'distance_meters': distanceMeters,
      });
      return Activity.fromJson(res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ActivityListPage> list({String? type, int limit = 20, int offset = 0}) async {
    try {
      final qp = <String, dynamic>{'limit': limit, 'offset': offset};
      if (type != null) qp['type'] = type;
      final res = await _dio.get<Map<String, dynamic>>('/activities', queryParameters: qp);
      final data = (res.data!['data'] as List<dynamic>? ?? [])
          .map((e) => Activity.fromJson(e as Map<String, dynamic>))
          .toList();
      final total = (res.data!['meta']?['total'] as num?)?.toInt() ?? data.length;
      return ActivityListPage(items: data, total: total);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<ActivityDetail> get(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/activities/$id');
      return ActivityDetail.fromJson(res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<Activity> update(String id, {required String type, required String title, String? notes}) async {
    try {
      final body = <String, dynamic>{'type': type, 'title': title};
      if (notes != null) body['notes'] = notes;
      final res = await _dio.put<Map<String, dynamic>>('/activities/$id', data: body);
      return Activity.fromJson(res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/activities/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<StatsSummary> statsSummary() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/stats/summary');
      return StatsSummary.fromJson(res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Fetches the activity's GPX as raw bytes.
  Future<List<int>> exportGpx(String id) async {
    try {
      final res = await _dio.get<List<int>>(
        '/activities/$id/gpx',
        options: Options(responseType: ResponseType.bytes),
      );
      return res.data ?? const [];
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  /// Uploads a GPX file (multipart) and returns the created activity.
  Future<Activity> importGpx(List<int> bytes, {String filename = 'import.gpx'}) async {
    try {
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });
      final res = await _dio.post<Map<String, dynamic>>('/activities/import', data: form);
      return Activity.fromJson(res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<List<PersonalRecord>> records() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/records');
      return (res.data!['data'] as List<dynamic>? ?? [])
          .map((e) => PersonalRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final activityServiceProvider = Provider<ActivityService>(
  (ref) => ActivityService(ref.watch(dioProvider)),
);
