import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';
import 'device_service.dart';
import '../storage/secure_storage_service.dart';

class DeviceInfoInterceptor extends Interceptor {
  DeviceMetadata? _cache;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      _cache ??= await DeviceService.getDeviceMetadata();
      if (_cache != null) {
        options.headers['User-Agent'] = _cache!.userAgent;
        options.headers['X-App-Version'] = _cache!.appVersion;
        options.headers['X-App-Build'] = _cache!.buildNumber;
        options.headers['X-Device-Os'] = _cache!.osName;
        options.headers['X-Device-Os-Version'] = _cache!.osVersion;
        options.headers['X-Device-Model'] = _cache!.deviceModel;
        options.headers['X-Device-Manufacturer'] = _cache!.manufacturer;
      }
    } catch (_) {}
    handler.next(options);
  }
}

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  NetworkException({required this.message, this.statusCode, this.data});

  @override
  String toString() => 'NetworkException: $message (Status: $statusCode)';
}

class ApiClient {
  final Dio dio;

  ApiClient(this.dio);
  
  void init(SecureStorageService storageService) {
    dio.options = BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.31.101:3000/api/v1'),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    dio.interceptors.add(DeviceInfoInterceptor());
    dio.interceptors.add(AuthInterceptor(storageService));
  }

  /**
   * Helper that evaluates and normalizes client exception types.
   */
  NetworkException handleError(DioException error) {
    String message = 'An unexpected connection error occurred';
    int? code = error.response?.statusCode;
    Map<String, dynamic>? responseData;

    if (error.response?.data is Map<String, dynamic>) {
      responseData = error.response?.data as Map<String, dynamic>;
      message = responseData['message'] ?? message;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Check your network link stability.';
        break;
      case DioExceptionType.badResponse:
        if (code == 401) {
          message = 'Authentication failed. Please login again.';
        } else if (code == 403) {
          message = 'Access forbidden. Verification permissions missing.';
        } else if (code == 404) {
          message = 'Resource not found in target directories.';
        } else if (code == 429) {
          message = 'Too many requests. Please wait a moment.';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request cancelled.';
        break;
      case DioExceptionType.connectionError:
        message = 'Network connection failed. Check your internet link.';
        break;
      default:
        break;
    }

    return NetworkException(
      message: message,
      statusCode: code,
      data: responseData,
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageServiceProvider);
  final client = ApiClient(Dio());
  client.init(storage);
  return client;
});
