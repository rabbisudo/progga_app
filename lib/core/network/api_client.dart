import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_interceptor.dart';
import 'device_service.dart';
import '../storage/secure_storage_service.dart';

const String _isrgRootX1PEM = '''
-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIRAIIQz7DSQONZRGPgu2OCiwAwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMTUwNjA0MTEwNDM4
WhcNMzUwNjA0MTEwNDM4WjBPMQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJu
ZXQgU2VjdXJpdHkgUmVzZWFyY2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBY
MTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAK3oJHP0FDfzm54rVygc
h77ct984kIxuPOZXoHj3dcKi/vVqbvYATyjb3miGbESTtrFj/RQSa78f0uoxmyF+
0TM8ukj13Xnfs7j/EvEhmkvBioZxaUpmZmyPfjxwv60pIgbz5MDmgK7iS4+3mX6U
A5/TR5d8mUgjU+g4rk8Kb4Mu0UlXjIB0ttov0DiNewNwIRt18jA8+o+u3dpjq+sW
T8KOEUt+zwvo/7V3LvSye0rgTBIlDHCNAymg4VMk7BPZ7hm/ELNKjD+Jo2FR3qyH
B5T0Y3HsLuJvW5iB4YlcNHlsdu87kGJ55tukmi8mxdAQ4Q7e2RCOFvu396j3x+UC
B5iPNgiV5+I3lg02dZ77DnKxHZu8A/lJBdiB3QW0KtZB6awBdpUKD9jf1b0SHzUv
KBds0pjBqAlkd25HN7rOrFleaJ1/ctaJxQZBKT5ZPt0m9STJEadao0xAH0ahmbWn
OlFuhjuefXKnEgV4We0+UXgVCwOPjdAvBbI+e0ocS3MFEvzG6uBQE3xDk3SzynTn
jh8BCNAw1FtxNrQHusEwMFxIt4I7mKZ9YIqioymCzLq9gwQbooMDQaHWBfEbwrbw
qHyGO0aoSCqI3Haadr8faqU9GY/rOPNk3sgrDQoo//fb4hVC1CLQJ13hef4Y53CI
rU7m2Ys6xt0nUW7/vGT1M0NPAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBBjAPBgNV
HRMBAf8EBTADAQH/MB0GA1UdDgQWBBR5tFnme7bl5AFzgAiIyBpY9umbbjANBgkq
hkiG9w0BAQsFAAOCAgEAVR9YqbyyqFDQDLHYGmkgJykIrGF1XIpu+ILlaS/V9lZL
ubhzEFnTIZd+50xx+7LSYK05qAvqFyFWhfFQDlnrzuBZ6brJFe+GnY+EgPbk6ZGQ
3BebYhtF8GaV0nxvwuo77x/Py9auJ/GpsMiu/X1+mvoiBOv/2X/qkSsisRcOj/KK
NFtY2PwByVS5uCbMiogziUwthDyC3+6WVwW6LLv3xLfHTjuCvjHIInNzktHCgKQ5
ORAzI4JMPJ+GslWYHb4phowim57iaztXOoJwTdwJx4nLCgdNbOhdjsnvzqvHu7Ur
TkXWStAmzOVyyghqpZXjFaH3pO3JLF+l+/+sKAIuvtd7u+Nxe5AW0wdeRlN8NwdC
jNPElpzVmbUq4JUagEiuTDkHzsxHpFKVK7q4+63SM1N95R1NbdWhscdCb+ZAJzVc
oyi3B43njTOQ5yOf+1CceWxG1bQVs5ZufpsMljq4Ui0/1lvh+wjChP4kqKOJ2qxq
4RgqsahDYVvTH9w7jXbyLeiNdd8XM2w9U/t7y0Ff/9yi0GE44Za4rF2LN9d11TPA
mRGunUHBcnWEvgJBQl9nJEiU0Zsnvgc/ubhPgXRR4Xq37Z0j4r7g1SgEEzwxA57d
emyPxgcYxn/eR44/KJ4EBs+lVDR3veyJm+kXQ99b21/+jh5Xos1AnX5iItreGCc=
-----END CERTIFICATE-----
''';

void configureDioSslPinning(Dio dio) {
  if (kIsWeb) return;
  
  if (dio.httpClientAdapter is IOHttpClientAdapter) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final context = SecurityContext(withTrustedRoots: true);
      try {
        context.setTrustedCertificatesBytes(utf8.encode(_isrgRootX1PEM));
      } catch (_) {}
      final client = HttpClient(context: context);
      return client;
    };
  }
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
    if (!SecurityConfig.isDeviceSecure) {
      debugPrint('Security warning on device environment.');
    }
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

  /**
   * Helper that evaluates and normalizes client exception types.
   */
  NetworkException handleError(DioException error) {
    String message = 'একটি অপ্রত্যাশিত নেটওয়ার্ক সমস্যা ঘটেছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
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
