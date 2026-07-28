import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'checkout_notifier.dart';
import 'package:go_router/go_router.dart';

class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  final TextEditingController _couponController = TextEditingController();
  String _selectedPlanId = 'plan-monthly';
  String _selectedGateway = 'bkash';

  final List<Map<String, dynamic>> _plans = [
    {
      'id': 'plan-monthly',
      'name': 'Pidot Premium Monthly',
      'price': 499.0,
      'cycle': 'Month',
      'features': ['Unlimited Exam Attempts', 'AI Diagnostics Report', 'Incorrect Retries Portal'],
    },
    {
      'id': 'plan-yearly',
      'name': 'Pidot Premium Annual',
      'price': 3999.0,
      'cycle': 'Year',
      'features': ['All Monthly Features', 'Priority AI Tutor Support', '20% Discount Save Match'],
    },
  ];

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  double _calculateFinalPrice(double basePrice, double discountPercent) {
    if (discountPercent <= 0) return basePrice;
    return basePrice * (1.0 - (discountPercent / 100.0));
  }

  void _showGatewayRedirectSheet(BuildContext context, String gateway, double amount) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isDismissible: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Redirecting to ${gateway.toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(sheetCtx).primaryColor)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Please complete the transaction of ৳${amount.toStringAsFixed(2)} on the gateway interface overlay page.',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(sheetCtx).pop(); // Dismiss sheet
                  
                  // Simulate verification hook calls
                  final success = await ref.read(checkoutProvider.notifier).executeCheckout(
                    planId: _selectedPlanId,
                    gateway: _selectedGateway,
                  );

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment Verified! Premium Features Unlocked.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.go('/home');
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(sheetCtx).primaryColor),
                child: const Text('Simulate Successful Callback verify', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkoutProvider);

    // Get active selected plan parameters
    final plan = _plans.firstWhere((p) => p['id'] == _selectedPlanId);
    final basePrice = plan['price'] as double;
    final finalPrice = _calculateFinalPrice(basePrice, state.discountPercentage);

    // Listen to verification error messages
    ref.listen(checkoutProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Get Premium Access', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Subscription Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Plan choices list
            ..._plans.map((p) {
              final isSel = _selectedPlanId == p['id'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  onTap: () => setState(() => _selectedPlanId = p['id']),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSel ? Theme.of(context).primaryColor.withOpacity(0.05) : const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSel ? Theme.of(context).primaryColor : Colors.white12,
                        width: isSel ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(p['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            Text('৳${p['price']}/${p['cycle']}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ... (p['features'] as List<String>).map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.check, size: 14, color: Colors.green),
                              const SizedBox(width: 8),
                              Text(f, style: const TextStyle(fontSize: 12, color: Colors.white60)),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Coupon Code Validation
            const Text(
              'Apply Coupon Discount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: const TextStyle(color: Colors.white30),
                      fillColor: const Color(0xFF1E1E1E),
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      suffixIcon: state.couponCode != null 
                          ? const Icon(Icons.check_circle, color: Colors.green) 
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: state.isValidatingCoupon
                      ? null
                      : () {
                          ref.read(checkoutProvider.notifier).validateCouponCode(_couponController.text.trim());
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  child: state.isValidatingCoupon
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            if (state.discountPercentage > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Coupon applied successfully! Saving ${state.discountPercentage.toStringAsFixed(0)}% Off.',
                style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 24),

            // Payment Gateways choices
            const Text(
              'Select Payment Gateway',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('bKash wallet checkout', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: 'bkash',
                    groupValue: _selectedGateway,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) => setState(() => _selectedGateway = val!),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  RadioListTile<String>(
                    title: const Text('SSLCommerz gateway checkout', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: 'sslcommerz',
                    groupValue: _selectedGateway,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) => setState(() => _selectedGateway = val!),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  RadioListTile<String>(
                    title: const Text('Stripe credit card payment', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: 'stripe',
                    groupValue: _selectedGateway,
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) => setState(() => _selectedGateway = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Total amount summary and proceed button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal Price', style: TextStyle(color: Colors.white60)),
                      Text('৳${basePrice.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  if (state.discountPercentage > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount Applied', style: TextStyle(color: Colors.green)),
                        Text('-৳${(basePrice - finalPrice).toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Payable Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(
                        '৳${finalPrice.toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: state.isLoading 
                        ? null
                        : () => _showGatewayRedirectSheet(context, _selectedGateway, finalPrice),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: state.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text(
                            'Proceed to Payment Gateway',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
