import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/services.dart' show HapticFeedback;
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
  bool _isHoldingEye = false;
  bool _isGoogleLoading = false;
  String? _formError;
  bool _emailHasError = false;
  bool _passwordHasError = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    String? errorMsg;
    bool emailErr = false;
    bool passwordErr = false;

    if (email.isEmpty && password.isEmpty) {
      errorMsg = 'অনুগ্রহ করে ইমেইল ও পাসওয়ার্ড লিখুন';
      emailErr = true;
      passwordErr = true;
    } else if (email.isEmpty) {
      errorMsg = 'অনুগ্রহ করে ইমেইল ঠিকানা লিখুন';
      emailErr = true;
    } else {
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(email)) {
        errorMsg = 'অনুগ্রহ করে সঠিক ইমেইল ঠিকানা লিখুন';
        emailErr = true;
      }
    }

    if (password.isEmpty && errorMsg == null) {
      errorMsg = 'অনুগ্রহ করে পাসওয়ার্ড লিখুন';
      passwordErr = true;
    }

    if (errorMsg != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _formError = errorMsg;
        _emailHasError = emailErr;
        _passwordHasError = passwordErr;
      });
      return;
    }

    setState(() {
      _formError = null;
      _emailHasError = false;
      _passwordHasError = false;
    });

    FocusScope.of(context).unfocus();
    ref.invalidate(userProfileProvider);
    ref.invalidate(myLeaderboardProvider);
    ref.invalidate(leaderboardProvider);
    await ref.read(authProvider.notifier).loginWithEmailAndPassword(
          email,
          password,
        );
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
    bool hasError = false,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    List<String>? autofillHints,
    void Function(String)? onChanged,
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
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            fontFamily: 'Li Ador Noirrit',
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13.5,
              fontFamily: 'Li Ador Noirrit',
            ),
            suffixIcon: isPassword
                ? Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      onLongPressStart: (_) {
                        HapticFeedback.mediumImpact();
                        setState(() {
                          _isHoldingEye = true;
                          _obscurePassword = false;
                        });
                      },
                      onLongPressEnd: (_) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isHoldingEye = false;
                          _obscurePassword = true;
                        });
                      },
                      onLongPressCancel: () {
                        if (_isHoldingEye) {
                          setState(() {
                            _isHoldingEye = false;
                            _obscurePassword = true;
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _isHoldingEye
                              ? const Color(0xFF0071F9).withValues(alpha: 0.12)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedScale(
                          scale: _isHoldingEye ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 150),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: child,
                              );
                            },
                            child: Icon(
                              _obscurePassword
                                  ? CupertinoIcons.eye_slash
                                  : CupertinoIcons.eye,
                              key: ValueKey<bool>(_obscurePassword),
                              color: _obscurePassword
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF0071F9),
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
            filled: true,
            fillColor: hasError ? const Color(0xFFFFF8F8) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFFDA4AF) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFFDA4AF) : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFF43F5E) : const Color(0xFF0071F9),
                width: 1.8,
              ),
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
                                  'assets/images/progga.svg',
                                  width: 180,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0071F9).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'স্মার্ট প্রস্তুতি • নিশ্চিত সাফল্য',
                                    style: TextStyle(
                                      fontSize: 12.5,
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

                          // Google / GitHub style Form Error Alert Card
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SizeTransition(sizeFactor: animation, child: child),
                              );
                            },
                            child: _formError != null
                                ? Container(
                                    key: ValueKey<String>(_formError!),
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF1F2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFFECDD3), width: 1.0),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFFE4E6),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.error_outline_rounded,
                                            color: Color(0xFFE11D48),
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _formError!,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontFamily: 'Li Ador Noirrit',
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF9F1239),
                                            ),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _formError = null;
                                              _emailHasError = false;
                                              _passwordHasError = false;
                                            });
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.close_rounded,
                                              size: 18,
                                              color: Color(0xFF9F1239),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Email Field
                          _buildModernInput(
                            label: 'ইমেইল',
                            controller: _emailController,
                            hintText: 'আপনার ইমেইল ঠিকানা লিখুন',
                            hasError: _emailHasError,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email, AutofillHints.username],
                            onChanged: (val) {
                              if (_emailHasError || _formError != null) {
                                setState(() {
                                  _emailHasError = false;
                                  if (!_passwordHasError) _formError = null;
                                });
                              }
                            },
                          ),

                          const SizedBox(height: 16),

                          // 4. Password Field
                          _buildModernInput(
                            label: 'পাসওয়ার্ড',
                            controller: _passwordController,
                            hintText: 'আপনার গোপন পাসওয়ার্ড লিখুন',
                            hasError: _passwordHasError,
                            isPassword: true,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onChanged: (val) {
                              if (_passwordHasError || _formError != null) {
                                setState(() {
                                  _passwordHasError = false;
                                  if (!_emailHasError) _formError = null;
                                });
                              }
                            },
                            onFieldSubmitted: (_) => _handleEmailLogin(),
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
                                        'Google',
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
