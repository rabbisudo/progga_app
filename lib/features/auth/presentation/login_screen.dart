import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'auth_notifier.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

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
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('ত্রুটি', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(authProvider.notifier).resetState();
                  },
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
                orElse: () => Column(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          GoogleSignInAccount? googleUser;
                          try {
                            final GoogleSignIn googleSignIn = GoogleSignIn(
                              serverClientId: '781610946731-1fuqgnrmh6gr2f3kssmn2aefbh9298r6.apps.googleusercontent.com',
                              scopes: ['email', 'profile'],
                            );
                            try {
                              await googleSignIn.signOut();
                            } catch (_) {}

                            googleUser = await googleSignIn.signIn();
                          } catch (e) {
                            debugPrint('Native Google sign in prompt error: $e');
                          }

                          if (googleUser != null) {
                            final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                            final String? idToken = googleAuth.idToken;
                            if (idToken != null) {
                              ref.invalidate(userProfileProvider);
                              ref.invalidate(myLeaderboardProvider);
                              ref.invalidate(leaderboardProvider);
                              await ref.read(authProvider.notifier).loginWithGoogle(idToken);
                              return;
                            }
                          }

                          // Fallback to dev token API hit if native Google prompt returned null or failed
                          ref.invalidate(userProfileProvider);
                          ref.invalidate(myLeaderboardProvider);
                          ref.invalidate(leaderboardProvider);
                          await ref.read(authProvider.notifier).loginWithGoogle('dev-mock-token');
                        } catch (e) {
                          // Fallback to dev token API hit on error
                          ref.invalidate(userProfileProvider);
                          ref.invalidate(myLeaderboardProvider);
                          ref.invalidate(leaderboardProvider);
                          await ref.read(authProvider.notifier).loginWithGoogle('dev-mock-token');
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
                        minimumSize: const Size(double.infinity, 54),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
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
