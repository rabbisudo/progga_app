import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'auth_notifier.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('assets/images/panda_login.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
        }
      });
    _controller.setLooping(true);
    _controller.setVolume(0.0);
    _controller.play();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _getInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.black.withOpacity(0.4),
        fontSize: 13,
        fontFamily: 'Li Ador Noirrit',
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF086057).withOpacity(0.7)),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.05),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF086057), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(
        fontFamily: 'Li Ador Noirrit',
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        
                        // Logo
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/logo_vector.svg',
                            height: 44,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        const Center(
                          child: Text(
                            'Enterprise MCQ Exam Platform',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black38,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Panda Video Container
                        Center(
                          child: SizedBox(
                            height: 240,
                            width: 320,
                            child: _isInitialized
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Transform.scale(
                                      scale: 1.15,
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: _controller.value.size.width,
                                          height: _controller.value.size.height,
                                          child: VideoPlayer(_controller),
                                        ),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF086057),
                                      strokeWidth: 2,
                                    ),
                                  ),
                          ),
                        ),
                        
                        const SizedBox(height: 36),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontFamily: 'Li Ador Noirrit',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'অনুগ্রহ করে ইমেইল লিখুন';
                            }
                            final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegExp.hasMatch(value.trim())) {
                              return 'সঠিক ইমেইল ঠিকানা লিখুন';
                            }
                            return null;
                          },
                          decoration: _getInputDecoration('ইমেইল', Icons.email_outlined),
                        ),
                        const SizedBox(height: 14),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontFamily: 'Li Ador Noirrit',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'অনুগ্রহ করে পাসওয়ার্ড লিখুন';
                            }
                            return null;
                          },
                          decoration: _getInputDecoration('পাসওয়ার্ড', Icons.lock_outlined).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF086057).withOpacity(0.6),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action Buttons (Email login, divider, Google login)
                        authState.maybeWhen(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: CircularProgressIndicator(color: Color(0xFF086057)),
                            ),
                          ),
                          orElse: () => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    ref.invalidate(userProfileProvider);
                                    ref.invalidate(myLeaderboardProvider);
                                    ref.invalidate(leaderboardProvider);
                                    await ref.read(authProvider.notifier).loginWithEmailAndPassword(
                                          _emailController.text.trim(),
                                          _passwordController.text.trim(),
                                        );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF086057),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 54),
                                  elevation: 2,
                                  shadowColor: const Color(0xFF086057).withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'লগইন করুন',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Li Ador Noirrit',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                    child: Text(
                                      'অথবা',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade400,
                                        fontFamily: 'Li Ador Noirrit',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                ],
                              ),
                              const SizedBox(height: 24),
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
                                      throw 'গুগল সাইন-ইন প্রম্পট ওপেন করা যায়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';
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
                                      } else {
                                        throw 'গুগল আইডি টোকেন পাওয়া যায়নি।';
                                      }
                                    }
                                  } catch (e) {
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
                                icon: const Image(
                                  image: AssetImage('assets/images/google_logo.png'),
                                  height: 22,
                                  width: 22,
                                  errorBuilder: _googleLogoFallback,
                                ),
                                label: const Text(
                                  'Google দিয়ে এগিয়ে যান',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF212529),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 54),
                                  side: BorderSide(color: Colors.grey.shade200, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _googleLogoFallback(BuildContext context, Object error, StackTrace? stackTrace) {
    return const Icon(Icons.g_mobiledata, color: Color(0xFF1E88E5), size: 28);
  }
}
