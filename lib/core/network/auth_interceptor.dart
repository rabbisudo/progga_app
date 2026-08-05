import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final Dio _refreshDio = Dio(); // Isolated client to prevent circular interceptor triggers
  final void Function()? onUnauthenticated;

  // Active future for refreshing token to prevent duplicate concurrent calls
  Future<String?>? _refreshFuture;

  AuthInterceptor(this._storageService, {this.onUnauthenticated});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Intercept only 401 Unauthorized errors
    if (err.response?.statusCode == 401) {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null) {
        try {
          final baseUrl = err.requestOptions.baseUrl;
          
          // Request new token pair or await existing active refresh request
          _refreshFuture ??= _performTokenRefresh(baseUrl);
          final newAccessToken = await _refreshFuture;

          if (newAccessToken != null) {
            // Clone and retry failed request with new token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';
            
            // Initialize retryDio with the baseUrl of the original request
            final retryDio = Dio(BaseOptions(
              baseUrl: options.baseUrl,
              connectTimeout: options.connectTimeout,
              receiveTimeout: options.receiveTimeout,
            ));
            
            final retryResponse = await retryDio.request(
              options.path,
              data: options.data,
              queryParameters: options.queryParameters,
              options: Options(
                method: options.method,
                headers: options.headers,
                contentType: options.contentType,
              ),
            );

            return handler.resolve(retryResponse);
          }
        } catch (refreshError) {
          // Retry failed - we don't clear tokens if it was a temporary network/server error during the retry request itself,
          // but if the token refresh failed (handled inside _performTokenRefresh), it clears tokens.
        }
      } else {
        // No refresh token, clear credentials
        await _storageService.clearTokens();
        onUnauthenticated?.call();
      }
    }
    
    return handler.next(err);
  }

  Future<String?> _performTokenRefresh(String baseUrl) async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        await _storageService.clearTokens();
        onUnauthenticated?.call();
        return null;
      }

      final response = await _refreshDio.post(
        '$baseUrl/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['tokens'];
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;

        // Save tokens
        await _storageService.saveAccessToken(newAccessToken);
        await _storageService.saveRefreshToken(newRefreshToken);

        return newAccessToken;
      }
    } catch (e) {
      // Token refresh failed, purge credentials
      await _storageService.clearTokens();
      onUnauthenticated?.call();
    } finally {
      _refreshFuture = null; // Clear the future so subsequent refreshes can run
    }
    return null;
  }
}
