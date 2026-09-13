import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_notifier.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  static const Color brandTealColor = Color(0xFF0071F9);

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _getInputDecoration(BuildContext context, String label, IconData icon, bool obscureText, VoidCallback onSuffixPressed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontFamily: 'Li Ador Noirrit',
        fontSize: 13,
      ),
      prefixIcon: Icon(icon, color: brandTealColor.withOpacity(0.7)),
      suffixIcon: IconButton(
        icon: Icon(
          obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: brandTealColor.withOpacity(0.6),
        ),
        onPressed: onSuffixPressed,
      ),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: brandTealColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Li Ador Noirrit',
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfileState = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: _isSaving ? null : () => Navigator.pop(context),
        ),
        title: userProfileState.when(
          data: (user) => Text(
            user.password == null ? 'পাসওয়ার্ড সেট করুন' : 'পাসওয়ার্ড পরিবর্তন করুন',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontFamily: 'Li Ador Noirrit',
              fontSize: 18,
            ),
          ),
          error: (_, __) => const Text('পাসওয়ার্ড পরিবর্তন'),
          loading: () => const Text('লোডিং...'),
        ),
      ),
      body: userProfileState.when(
        data: (user) {
          final isFirstTime = user.password == null;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      isFirstTime 
                        ? 'আপনার অ্যাকাউন্ট সুরক্ষিত করতে একটি নতুন পাসওয়ার্ড সেট করুন। পরবর্তীতে আপনি এই পাসওয়ার্ড দিয়ে লগইন করতে পারবেন।'
                        : 'আপনার পাসওয়ার্ড পরিবর্তন করতে বর্তমান পাসওয়ার্ড এবং নতুন পাসওয়ার্ডটি প্রদান করুন।',
                      style: TextStyle(
                        fontFamily: 'Li Ador Noirrit',
                        fontSize: 14,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!isFirstTime) ...[
                      TextFormField(
                        controller: _oldPasswordController,
                        obscureText: _obscureOld,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _getInputDecoration(
                          context,
                          'বর্তমান পাসওয়ার্ড',
                          Icons.lock_open_outlined,
                          _obscureOld,
                          () => setState(() => _obscureOld = !_obscureOld),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'বর্তমান পাসওয়ার্ড দিন';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _getInputDecoration(
                        context,
                        'নতুন পাসওয়ার্ড',
                        Icons.lock_outline_rounded,
                        _obscureNew,
                        () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'নতুন পাসওয়ার্ড দিন';
                        }
                        if (val.trim().length < 8) {
                          return 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _getInputDecoration(
                        context,
                        'পাসওয়ার্ড নিশ্চিত করুন',
                        Icons.lock_rounded,
                        _obscureConfirm,
                        () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'পাসওয়ার্ডটি পুনরায় লিখুন';
                        }
                        if (val.trim() != _newPasswordController.text.trim()) {
                          return 'পাসওয়ার্ড দুটি মেলেনি';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandTealColor,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: _isSaving
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _isSaving = true);
                              try {
                                await ref.read(userProfileProvider.notifier).setPassword(
                                      oldPassword: isFirstTime ? null : _oldPasswordController.text.trim(),
                                      newPassword: _newPasswordController.text.trim(),
                                    );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'পাসওয়ার্ড সফলভাবে সেট হয়েছে',
                                        style: TextStyle(fontFamily: 'Li Ador Noirrit'),
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => _isSaving = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e.toString().replaceAll('Exception:', '').trim(),
                                        style: const TextStyle(fontFamily: 'Li Ador Noirrit'),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'সংরক্ষণ করুন',
                              style: TextStyle(
                                fontFamily: 'Li Ador Noirrit',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        error: (error, _) => Center(
          child: Text(
            'ত্রুটি: $error',
            style: const TextStyle(fontFamily: 'Li Ador Noirrit', color: Colors.red),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: brandTealColor),
        ),
      ),
    );
  }
}
