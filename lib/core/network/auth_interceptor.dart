import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final Dio _refreshDio = Dio(); // Isolated client to prevent circular interceptor triggers

  AuthInterceptor(this._storageService);

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
          
          // Request new token pair
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

            // Clone and retry failed request with new token
            final options = err.requestOptions;
            options.headers['Authorization'] = 'Bearer $newAccessToken';
            
            final retryDio = Dio();
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
          // Token refresh failed, purge credentials
          await _storageService.clearTokens();
        }
      } else {
        // No refresh token, clear credentials
        await _storageService.clearTokens();
      }
    }
    
    return handler.next(err);
  }
}
