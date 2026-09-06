import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';
import 'device_service.dart';
import 'ssl_pinning_config.dart';
import '../storage/secure_storage_service.dart';

void configureDioSslPinning(Dio dio) {
  SslPinningConfig.configureDio(dio);
}

Map<String, dynamic> sortMapKeys(Map<String, dynamic> map) {
  final sortedKeys = map.keys.toList()..sort();
  final sortedMap = <String, dynamic>{};
  for (final key in sortedKeys) {
    final value = map[key];
    if (value is Map) {
      sortedMap[key] = sortMapKeys(Map<String, dynamic>.from(value));
    } else if (value is List) {
      sortedMap[key] = value.map((item) {
        if (item is Map) {
          return sortMapKeys(Map<String, dynamic>.from(item));
        }
        return item;
      }).toList();
    } else {
      sortedMap[key] = value;
    }
  }
  return sortedMap;
}

class HmacSigningInterceptor extends Interceptor {
  static const String _hmacSecret = 'progga-secure-hmac-shared-secret-key-signature';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      final timestamp = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
      
      String bodyStr = '';
      final contentType = options.contentType ?? options.headers['Content-Type'] ?? '';
      final isMultipart = (options.data is FormData) ||
          contentType.toString().toLowerCase().contains('multipart/form-data');
      
      if (!isMultipart && options.data != null) {
        if (options.data is Map) {
          bodyStr = jsonEncode(sortMapKeys(Map<String, dynamic>.from(options.data)));
        } else if (options.data is List) {
          bodyStr = jsonEncode(options.data);
        } else if (options.data is String) {
          bodyStr = options.data as String;
        }
      }

      // Calculate signature: SHA256 of path + timestamp + body
      final keyBytes = utf8.encode(_hmacSecret);
      final messageBytes = utf8.encode('${options.uri.path}$timestamp$bodyStr');
      final hmac = Hmac(sha256, keyBytes);
      final signature = hmac.convert(messageBytes).toString();

      // Set headers
      options.headers['X-Signature'] = signature;
      options.headers['X-Timestamp'] = timestamp;
    } catch (_) {
      // safe bypass
    }
    handler.next(options);
  }
}

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

class SecurityConfig {
  static bool isDeviceSecure = true;
}

class SecurityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }
}

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  NetworkException({required this.message, this.statusCode, this.data});

  @override
  String toString() => message;
}

class ApiClient {
  final Dio dio;
  void Function()? onUnauthenticated;

  ApiClient(this.dio);
  
  void init(SecureStorageService storageService) {
    dio.options = BaseOptions(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://proggadata.twelvemind.com/api/v1'),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    configureDioSslPinning(dio);
    dio.interceptors.add(SecurityInterceptor());
    dio.interceptors.add(HmacSigningInterceptor());
    dio.interceptors.add(DeviceInfoInterceptor());
    dio.interceptors.add(AuthInterceptor(
      storageService,
      onUnauthenticated: () => onUnauthenticated?.call(),
    ));
  }

  /// Helper that evaluates and normalizes client exception types.
  NetworkException handleError(DioException error) {
    String message = 'একটি অপ্রত্যাশিত সমস্যা ঘটেছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
    int? code = error.response?.statusCode;
    Map<String, dynamic>? responseData;

    if (error.response?.data is Map<String, dynamic>) {
      responseData = error.response?.data as Map<String, dynamic>;
      final rawMsg = responseData['message'];
      if (rawMsg is List) {
        message = rawMsg.map((e) => e.toString()).join('\n');
      } else if (rawMsg is String) {
        message = rawMsg;
      }
    } else if (error.response?.data is Map) {
      responseData = Map<String, dynamic>.from(error.response?.data as Map);
      final rawMsg = responseData['message'];
      if (rawMsg is List) {
        message = rawMsg.map((e) => e.toString()).join('\n');
      } else if (rawMsg is String) {
        message = rawMsg;
      }
    } else if (error.response?.data is String && (error.response?.data as String).isNotEmpty) {
      message = error.response?.data as String;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'সংযোগের সময়সীমা পার হয়ে গেছে। অনুগ্রহ করে ইন্টারনেট সংযোগটি পরীক্ষা করুন।';
        break;
      case DioExceptionType.badResponse:
        if (responseData?['message'] != null) {
          final serverMsg = responseData!['message'].toString();
          if (serverMsg.toLowerCase().contains('invalid email or password') ||
              serverMsg.toLowerCase().contains('invalid credentials')) {
            message = 'ভুল ইমেইল অথবা পাসওয়ার্ড। অনুগ্রহ করে সঠিক তথ্য দিয়ে আবার চেষ্টা করুন।';
          } else if (serverMsg.toLowerCase().contains('user account is deactivated')) {
            message = 'অ্যাকাউন্টটি নিষ্ক্রিয় করা হয়েছে। অনুগ্রহ করে সাপোর্টে যোগাযোগ করুন।';
          } else {
            message = serverMsg;
          }
        } else if (code == 401) {
          message = 'লগইন সেশন শেষ হয়েছে। অনুগ্রহ করে আবার লগইন করুন।';
        } else if (code == 403) {
          message = 'প্রবেশাধিকার সংরক্ষিত। প্রয়োজনীয় পারমিশন নেই।';
        } else if (code == 404) {
          message = 'অনুরোধকৃত তথ্যটি খুঁজে পাওয়া যায়নি।';
        } else if (code == 429) {
          message = 'অতিরিক্ত অনুরোধ পাঠানো হয়েছে। অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন।';
        }
        break;
      case DioExceptionType.cancel:
        message = (error.error != null && error.error.toString().isNotEmpty)
            ? error.error.toString()
            : 'অনুরোধ বাতিল করা হয়েছে।';
        break;
      case DioExceptionType.connectionError:
        message = 'নেটওয়ার্ক সংযোগ ব্যর্থ হয়েছে। আপনার ইন্টারনেট চেক করুন।';
        break;
      case DioExceptionType.badCertificate:
        message = 'নিরাপত্তা সতর্কতা: নিরাপদ সংযোগ স্থাপন সম্ভব হয়নি (SSL Certificate Verification Failed)। কোনো অননুমোদিত প্রক্সি বা নেটওয়ার্ক সংযোগ শনাক্ত হয়েছে।';
        break;
      default:
        if (error.message != null && error.message!.isNotEmpty) {
          message = error.message!;
        }
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
