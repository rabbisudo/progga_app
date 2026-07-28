import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/payment_repository.dart';
import '../../profile/presentation/profile_notifier.dart';

part 'checkout_notifier.freezed.dart';

@freezed
class CheckoutState with _$CheckoutState {
  const factory CheckoutState({
    required bool isLoading,
    required bool isValidatingCoupon,
    String? couponCode,
    required double discountPercentage,
    String? errorMessage,
    required bool checkoutSuccess,
  }) = _CheckoutState;
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final PaymentRepository _repository;
  final Ref _ref;

  CheckoutNotifier(this._repository, this._ref)
      : super(const CheckoutState(
          isLoading: false,
          isValidatingCoupon: false,
          discountPercentage: 0.0,
          checkoutSuccess: false,
        ));

  Future<void> validateCouponCode(String code) async {
    if (code.isEmpty) return;
    
    state = state.copyWith(isValidatingCoupon: true, errorMessage: null);

    try {
      final result = await _repository.validateCoupon(code);
      final discount = (result['discountPercent'] as num).toDouble();
      
      state = state.copyWith(
        isValidatingCoupon: false,
        couponCode: code,
        discountPercentage: discount,
      );
    } catch (e) {
      state = state.copyWith(
        isValidatingCoupon: false,
        discountPercentage: 0.0,
        errorMessage: 'Invalid coupon code or expired threshold.',
      );
    }
  }

  Future<bool> executeCheckout({required String planId, required String gateway}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _repository.startCheckout(
        planId: planId,
        gateway: gateway,
        couponCode: state.couponCode,
      );

      state = state.copyWith(isLoading: false, checkoutSuccess: true);
      
      // Dynamic reload profile dashboard settings to refresh active subscriptions status immediately
      await _ref.read(userProfileProvider.notifier).build();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  final repo = ref.watch(paymentRepositoryProvider);
  return CheckoutNotifier(repo, ref);
});
