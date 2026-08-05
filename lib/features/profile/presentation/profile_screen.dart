import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_notifier.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../question/presentation/practice_notifier.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/custom_back_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color brandTealColor = Color(0xFF086057); // Deep teal color

  Widget _buildSectionCard({required List<Widget> children, required bool isDark}) {
    final List<Widget> items = [];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(
          Divider(
            height: 1,
            indent: 56,
            endIndent: 16,
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
          ),
        );
      }
    }

    return Column(
      children: items,
    );
  }

  Widget _buildFlatMenuTile({
    required ThemeData theme,
    required Color color,
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
          color: isDark ? Colors.white : Colors.black87,
          fontFamily: 'Noto Sans Bengali',
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDark ? Colors.white30 : Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildAcademicBadge(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? brandTealColor.withOpacity(0.15) : const Color(0xFFE6FCF5),
        border: Border.all(color: isDark ? brandTealColor.withOpacity(0.3) : const Color(0xFFC3FAE8)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? const Color(0xFF00C569) : const Color(0xFF086057),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          fontFamily: 'Noto Sans Bengali',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'প্রোফাইল ও সেটিংস',
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            fontFamily: 'Noto Sans Bengali',
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? CustomBackButton(
                color: isDark ? Colors.white : Colors.black87,
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: brandTealColor)),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          final profile = user.profile!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header Card
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: brandTealColor.withOpacity(0.05),
                              boxShadow: [
                                BoxShadow(
                                  color: brandTealColor.withOpacity(0.08),
                                  blurRadius: 16,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          Hero(
                            tag: 'user_avatar_hero',
                            child: CustomAvatar(
                              avatarUrl: profile.avatarKey,
                              radius: 44,
                              backgroundColor: brandTealColor.withOpacity(0.1),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => context.push('/avatar-editor'),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: brandTealColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.fullName,
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          fontFamily: 'Noto Sans Bengali',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Settings Menu Card
                _buildSectionCard(
                  isDark: isDark,
                  children: [
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF00C569),
                      icon: Icons.person_rounded,
                      title: 'ব্যক্তিগত তথ্য',
                      isDark: isDark,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.green.withOpacity(0.15) : const Color(0xFFE6FCF5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
                            ),
                            child: const Text(
                              '+Add Phone number',
                              style: TextStyle(color: Color(0xFF087F5B), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.grey.shade400),
                        ],
                      ),
                      onTap: () => context.push('/personal-info'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFFB300),
                      icon: Icons.emoji_events_rounded,
                      title: 'লিডারবোর্ড',
                      isDark: isDark,
                      onTap: () => context.push('/leaderboard'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFE53935),
                      icon: Icons.flag_rounded,
                      title: 'আমার রিপোর্টসমূহ',
                      isDark: isDark,
                      onTap: () => context.push('/my-reports'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF00B8),
                      icon: Icons.brush_rounded,
                      title: 'অ্যাভাটার এডিট',
                      isDark: isDark,
                      onTap: () => context.push('/avatar-editor'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFFA500),
                      icon: Icons.workspace_premium_rounded,
                      title: 'আপগ্রেড',
                      isDark: isDark,
                      onTap: () => context.push('/premium'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF007AFF),
                      icon: Icons.credit_card_rounded,
                      title: 'সাবস্ক্রিপশন',
                      isDark: isDark,
                      onTap: () => context.push('/premium'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF8A00),
                      icon: Icons.equalizer_rounded,
                      title: 'অ্যাক্টিভিটি',
                      isDark: isDark,
                      onTap: () {},
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF3B30),
                      icon: Icons.notifications_rounded,
                      title: 'নোটিফিকেশনস',
                      isDark: isDark,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD1D1),
                              shape: BoxShape.circle,
                            ),
                            child: const Text(
                              '0',
                              style: TextStyle(color: Color(0xFFFF3B30), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white30 : Colors.grey.shade400),
                        ],
                      ),
                      onTap: () {},
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF007AFF),
                      icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      title: 'ডার্ক মোড',
                      isDark: isDark,
                      trailing: Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: isDark,
                          activeColor: const Color(0xFF017A47),
                          onChanged: (val) {
                            ref.read(themeModeProvider.notifier).setThemeMode(
                              val ? ThemeMode.dark : ThemeMode.light,
                            );
                            ref.read(userProfileProvider.notifier).updateSettings({'darkMode': val});
                          },
                        ),
                      ),
                      onTap: () {
                        ref.read(themeModeProvider.notifier).setThemeMode(
                          isDark ? ThemeMode.light : ThemeMode.dark,
                        );
                        ref.read(userProfileProvider.notifier).updateSettings({'darkMode': !isDark});
                      },
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF009688),
                      icon: Icons.privacy_tip_rounded,
                      title: 'প্রাইভেসি পলিসি',
                      isDark: isDark,
                      onTap: () async {
                        final url = Uri.parse('https://chorcha.net/privacy-policy');
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Error launching url: $e');
                        }
                      },
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF607D8B),
                      icon: Icons.description_rounded,
                      title: 'শর্তাবলী ও নিয়মাবলী',
                      isDark: isDark,
                      onTap: () async {
                        final url = Uri.parse('https://chorcha.net/terms-and-conditions');
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          debugPrint('Error launching url: $e');
                        }
                      },
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF3B30),
                      icon: Icons.logout_rounded,
                      title: 'লগআউট করুন',
                      isDark: isDark,
                      onTap: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                const Text(
                                  'লগআউট',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Noto Sans Bengali'),
                                ),
                              ],
                            ),
                            content: const Text(
                              'আপনি কি নিশ্চিত যে আপনি অ্যাকাউন্ট থেকে লগআউট করতে চান?',
                              style: TextStyle(fontFamily: 'Noto Sans Bengali'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'বাতিল',
                                  style: TextStyle(color: Colors.grey, fontFamily: 'Noto Sans Bengali'),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'লগআউট',
                                  style: TextStyle(color: Colors.white, fontFamily: 'Noto Sans Bengali'),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout == true) {
                          ref.invalidate(userProfileProvider);
                          ref.invalidate(leaderboardProvider);
                          ref.invalidate(practiceProvider);
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
