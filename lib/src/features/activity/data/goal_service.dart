import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/goal.dart';

class GoalService {
  const GoalService(this._dio);
  final Dio _dio;

  Future<List<Goal>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/goals');
      return (res.data!['data'] as List<dynamic>? ?? [])
          .map((e) => Goal.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> create({required String period, String? activityType, required double targetMeters}) async {
    try {
      final body = <String, dynamic>{'period': period, 'target_meters': targetMeters};
      if (activityType != null) body['activity_type'] = activityType;
      await _dio.post<Map<String, dynamic>>('/goals', data: body);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/goals/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final goalServiceProvider = Provider<GoalService>((ref) => GoalService(ref.watch(dioProvider)));

final goalsProvider = FutureProvider<List<Goal>>((ref) => ref.watch(goalServiceProvider).list());
