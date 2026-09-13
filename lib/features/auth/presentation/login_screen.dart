import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'auth_notifier.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      ref.invalidate(userProfileProvider);
      ref.invalidate(myLeaderboardProvider);
      ref.invalidate(leaderboardProvider);
      await ref.read(authProvider.notifier).loginWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS
            ? '781610946731-fmgsqp1qdq6tt2nfook96g65a0psihhm.apps.googleusercontent.com'
            : null,
        serverClientId: '781610946731-1fuqgnrmh6gr2f3kssmn2aefbh9298r6.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      try {
        await googleSignIn.signOut().timeout(
              const Duration(seconds: 1),
              onTimeout: () => null,
            );
      } catch (_) {}
      try {
        await googleSignIn.disconnect();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        if (mounted) setState(() => _isGoogleLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken != null) {
        ref.invalidate(userProfileProvider);
        ref.invalidate(myLeaderboardProvider);
        ref.invalidate(leaderboardProvider);
        await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      } else {
        throw 'গুগল আইডি টোকেন পাওয়া যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('ApiException: 10')
                  ? 'Google Play App Signing SHA-1 কনফিগারেশন সমস্যা। Firebase-এ SHA-1 যোগ করুন।'
                  : e.toString().replaceAll('Exception:', '').trim(),
              style: const TextStyle(fontFamily: 'Li Ador Noirrit'),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Widget _buildModernInput({
    required String label,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    List<String>? autofillHints,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Li Ador Noirrit',
              color: Color(0xFF334155),
              letterSpacing: 0.2,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword ? _obscurePassword : false,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            fontFamily: 'Li Ador Noirrit',
          ),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
              fontFamily: 'Li Ador Noirrit',
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                prefixIcon,
                color: const Color(0xFF0071F9),
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            suffixIcon: isPassword
                ? IconButton(
                    splashRadius: 20,
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF0071F9), width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFDA4AF), width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFF43F5E), width: 1.6),
            ),
            errorStyle: const TextStyle(
              fontFamily: 'Li Ador Noirrit',
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFFDC2626),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthLoading = authState.maybeWhen(loading: () => true, orElse: () => false);

    // Listen to authentication & error states
    ref.listen(authProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user, token) {
          ref.invalidate(userProfileProvider);
          ref.invalidate(myLeaderboardProvider);
          ref.invalidate(leaderboardProvider);
          context.go('/home');
        },
        error: (message) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text(
                    'লগইন ব্যর্থ হয়েছে',
                    style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Li Ador Noirrit'),
                  ),
                ],
              ),
              content: Text(
                message,
                style: const TextStyle(fontFamily: 'Li Ador Noirrit', fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(authProvider.notifier).resetState();
                  },
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(
                      color: Color(0xFF0071F9),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 12),

                          // 1. Brand Logo & Identity
                          Center(
                            child: Column(
                              children: [
                                SvgPicture.asset(
                                  'assets/images/logo_vector.svg',
                                  height: 54,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF0F172A),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'প্রজ্ঞা',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Li Ador Noirrit',
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0071F9).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'স্মার্ট প্রস্তুতি • নিশ্চিত সাফল্য',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Li Ador Noirrit',
                                      color: Color(0xFF0071F9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 2. Welcome Headline
                          const Text(
                            'স্বাগতম!',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Li Ador Noirrit',
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'আপনার অ্যাকাউন্টে লগইন করে অনুশীলন শুরু করুন',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),

                          const SizedBox(height: 24),

                          // 3. Email Field
                          _buildModernInput(
                            label: 'ইমেইল বা মোবাইল নম্বর',
                            controller: _emailController,
                            hintText: 'আপনার ইমেইল ঠিকানা লিখুন',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email, AutofillHints.username],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'অনুগ্রহ করে ইমেইল বা মোবাইল নম্বর লিখুন';
                              }
                              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegExp.hasMatch(value.trim())) {
                                return 'সঠিক ইমেইল ঠিকানা লিখুন';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // 4. Password Field
                          _buildModernInput(
                            label: 'পাসওয়ার্ড',
                            controller: _passwordController,
                            hintText: 'আপনার গোপন পাসওয়ার্ড লিখুন',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _handleEmailLogin(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'অনুগ্রহ করে পাসওয়ার্ড লিখুন';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // 5. Primary Submit Button
                          ElevatedButton(
                            onPressed: (isAuthLoading || _isGoogleLoading) ? null : _handleEmailLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0071F9),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isAuthLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'যাচাই করা হচ্ছে...',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Li Ador Noirrit',
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'লগইন করুন',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Li Ador Noirrit',
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 22),

                          // 6. Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'অথবা',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontFamily: 'Li Ador Noirrit',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade200, thickness: 1)),
                            ],
                          ),

                          const SizedBox(height: 22),

                          // 7. Google Login Button
                          OutlinedButton(
                            onPressed: (_isGoogleLoading || isAuthLoading) ? null : _handleGoogleSignIn,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 52),
                              side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isGoogleLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Color(0xFF0071F9),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'গুগল সংযোগ হচ্ছে...',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Li Ador Noirrit',
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image(
                                        image: AssetImage('assets/images/google_logo.png'),
                                        height: 22,
                                        width: 22,
                                        errorBuilder: _googleLogoFallback,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Google দিয়ে সরাসরি এগিয়ে যান',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Li Ador Noirrit',
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget _googleLogoFallback(BuildContext context, Object error, StackTrace? stackTrace) {
    return const Icon(Icons.g_mobiledata, color: Color(0xFF1E88E5), size: 28);
  }
}
