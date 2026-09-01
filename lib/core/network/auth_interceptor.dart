import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _storageService;
  final void Function()? onUnauthenticated;

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
  Future<void> onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) async {
    final renewedToken = response.headers.value('x-renewed-token');
    if (renewedToken != null && renewedToken.isNotEmpty) {
      await _storageService.saveAccessToken(renewedToken);
    }
    return handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Intercept 401 Unauthorized errors only on authenticated endpoints (ignore /auth/*)
    final path = err.requestOptions.path;
    final isPublicAuthEndpoint = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/forgot-password');

    if (err.response?.statusCode == 401 && !isPublicAuthEndpoint) {
      await _storageService.clearTokens();
      onUnauthenticated?.call();
    }
    return handler.next(err);
  }
}
