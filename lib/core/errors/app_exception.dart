import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory AppException.fromDioError(DioException dioError) {
    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return AppException(
          message: 'Koneksi ke server timeout. Silakan periksa jaringan Anda.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final response = dioError.response;
        final statusCode = response?.statusCode;
        String errorMessage = 'Terjadi kesalahan pada server ($statusCode)';

        if (response?.data is Map<String, dynamic>) {
          final map = response!.data as Map<String, dynamic>;
          if (map.containsKey('message')) {
            final msg = map['message'];
            if (msg is List) {
              errorMessage = msg.join(', ');
            } else {
              errorMessage = msg.toString();
            }
          } else if (map.containsKey('error')) {
            errorMessage = map['error'].toString();
          }
        }

        return AppException(
          message: errorMessage,
          statusCode: statusCode,
          data: response?.data,
        );
      case DioExceptionType.cancel:
        return AppException(message: 'Permintaan dibatalkan.');
      case DioExceptionType.connectionError:
        return AppException(
          message: 'Tidak dapat terhubung ke server. Pastikan URL server benar dan perangkat terhubung ke internet.',
          statusCode: 503,
        );
      default:
        return AppException(
          message: dioError.message ?? 'Terjadi kesalahan yang tidak terduga.',
        );
    }
  }

  @override
  String toString() => message;
}
