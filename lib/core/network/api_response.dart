class ApiResponse<T> {
  final bool status;
  final int? statusCode;
  final String message;
  final T? data;
  final String? timestamp;
  final dynamic error;

  ApiResponse({
    required this.status,
    this.statusCode,
    required this.message,
    this.data,
    this.timestamp,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      status: json['status'] is bool ? json['status'] : (json['statusCode'] == 200 || json['statusCode'] == 201),
      statusCode: json['statusCode'] as int?,
      message: json['message']?.toString() ?? '',
      data: (json['data'] != null && fromJsonT != null)
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      timestamp: json['timestamp']?.toString(),
      error: json['error'],
    );
  }
}
