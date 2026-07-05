import 'package:dio/dio.dart';

/// Domain-level error type. The UI only ever sees a [Failure] (never a raw
/// DioException), so error handling stays consistent across the app.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Sesi berakhir, silakan masuk lagi']);
}

class ApiFailure extends Failure {
  const ApiFailure(super.message, {this.statusCode});
  final int? statusCode;
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Terjadi kesalahan']);
}

/// Maps a low-level [DioException] into a domain [Failure].
Failure mapDioError(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final status = e.response?.statusCode;
      final message = _messageFromResponse(e.response?.data) ?? 'Permintaan gagal';
      if (status == 401) return AuthFailure(message);
      return ApiFailure(message, statusCode: status);
    default:
      return const UnknownFailure();
  }
}

String? _messageFromResponse(dynamic data) {
  if (data is Map && data['message'] is String) return data['message'] as String;
  return null;
}
