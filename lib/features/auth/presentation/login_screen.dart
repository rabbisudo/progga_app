import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'auth_notifier.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Listen to authentication & error states
    ref.listen(authProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user, token) {
          context.go('/home');
        },
        error: (message) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('ত্রুটি', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              
              Center(
                child: SvgPicture.asset(
                  'assets/images/logo_vector.svg',
                  height: 60,
                ),
              ),
              const SizedBox(height: 12),
              
              const Center(
                child: Text(
                  'Enterprise MCQ Exam Platform',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ),
              
              const Spacer(flex: 2),

              // Single Provider: Continue with Google Button
              authState.maybeWhen(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
                ),
                orElse: () => OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      final GoogleSignIn googleSignIn = GoogleSignIn(
                        serverClientId: '781610946731-1fuqgnrmh6gr2f3kssmn2aefbh9298r6.apps.googleusercontent.com',
                        scopes: ['email', 'profile'],
                      );
                      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
                      if (googleUser != null) {
                        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                        final String? idToken = googleAuth.idToken;
                        if (idToken != null) {
                          await ref.read(authProvider.notifier).loginWithGoogle(idToken);
                        } else {
                          throw Exception('গুগল সাইন-ইন থেকে টোকেন পাওয়া যায়নি।');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('ত্রুটি', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Text(e.toString()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text(
                                  'ঠিক আছে',
                                  style: TextStyle(color: Color(0xFF1E88E5), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    }
                  },
                  icon: const Image(
                    image: AssetImage('assets/images/google_logo.png'),
                    height: 24,
                    width: 24,
                    errorBuilder: _googleLogoFallback,
                  ),
                  label: const Text(
                    'Google দিয়ে এগিয়ে যান',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212529),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _googleLogoFallback(BuildContext context, Object error, StackTrace? stackTrace) {
    return const Icon(Icons.g_mobiledata, color: Color(0xFF1E88E5), size: 28);
  }
}
