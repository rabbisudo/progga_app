import '../../../core/network/api_client.dart';
import '../domain/subscription_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository(this._apiClient);

  Future<Map<String, dynamic>> validateCoupon(String code) async {
    try {
      final response = await _apiClient.dio.post(
        '/payments/coupon/validate',
        data: {'code': code},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<UserSubscriptionModel> startCheckout({
    required String planId,
    required String gateway,
    String? couponCode,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/payments/checkout',
        data: {
          'planId': planId,
          'gateway': gateway,
          if (couponCode != null) 'couponCode': couponCode,
        },
      );
      return UserSubscriptionModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PaymentRepository(client);
});
