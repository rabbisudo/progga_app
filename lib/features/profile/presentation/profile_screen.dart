import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'profile_notifier.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../question/presentation/practice_notifier.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_avatar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color brandTealColor = Color(0xFF086057); // Deep teal color

  Widget _buildFlatMenuTile({
    required ThemeData theme,
    required Color color,
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.35),
      ),
      onTap: onTap,
    );
  }

  Widget _buildAcademicBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: brandTealColor.withOpacity(0.06),
        border: Border.all(color: brandTealColor.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: brandTealColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
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
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: (ModalRoute.of(context)?.canPop ?? false)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.light_mode_outlined,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).setThemeMode(
                isDark ? ThemeMode.light : ThemeMode.dark,
              );
              ref.read(userProfileProvider.notifier).updateSettings({'darkMode': !isDark});
            },
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: brandTealColor)),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          final profile = user.profile!;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Centered Avatar, Name & Batch Chip with Glowing Polish
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: brandTealColor.withOpacity(0.08),
                              boxShadow: [
                                BoxShadow(
                                  color: brandTealColor.withOpacity(0.15),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          Hero(
                            tag: 'user_avatar_hero',
                            child: CustomAvatar(
                              avatarUrl: profile.avatarKey,
                              radius: 48,
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
                                  border: Border.all(color: theme.colorScheme.surface, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.fullName,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        alignment: WrapAlignment.center,
                        children: [
                          if (profile.className != null && profile.className!.isNotEmpty)
                            _buildAcademicBadge(profile.className!),
                          if (profile.targetExam != null && profile.targetExam!.isNotEmpty)
                            _buildAcademicBadge(profile.targetExam!),
                          _buildAcademicBadge(profile.batch ?? "SSC-27"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // 2. Flat-colored settings list
                Column(
                  children: [
                    // row 1
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF00C569),
                      icon: Icons.person_rounded,
                      title: 'ব্যক্তিগত তথ্য',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Text(
                              '+Add Phone number',
                              style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.withOpacity(0.6)),
                        ],
                      ),
                      onTap: () => context.push('/personal-info'),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF017A47),
                      icon: Icons.speed_rounded,
                      title: 'আমার প্রোগ্রেস',
                      onTap: () => context.push('/progress'),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFFB300),
                      icon: Icons.emoji_events_rounded,
                      title: 'লিডারবোর্ড',
                      onTap: () => context.push('/leaderboard'),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFE53935),
                      icon: Icons.flag_rounded,
                      title: 'আমার রিপোর্টসমূহ',
                      onTap: () => context.push('/my-reports'),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                    // row 2
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF00B8),
                      icon: Icons.brush_rounded,
                      title: 'অ্যাভাটার এডিট',
                      onTap: () => context.push('/avatar-editor'),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                    // row 3
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFFA500),
                      icon: Icons.workspace_premium_rounded,
                      title: 'আপগ্রেড',
                      onTap: () => context.push('/premium'),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                    // row 4
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF007AFF),
                      icon: Icons.credit_card_rounded,
                      title: 'সাবস্ক্রিপশন',
                      onTap: () => context.push('/premium'),
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                    // row 5
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF8A00),
                      icon: Icons.equalizer_rounded,
                      title: 'অ্যাক্টিভিটি',
                      onTap: () {},
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                    // row 6
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF3B30),
                      icon: Icons.notifications_rounded,
                      title: 'নোটিফিকেশনস',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD1D1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '0',
                              style: const TextStyle(color: Color(0xFFFF3B30), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, color: Colors.grey.withOpacity(0.6)),
                        ],
                      ),
                      onTap: () {},
                    ),
                    Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                    // row 7
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF3B30),
                      icon: Icons.logout_rounded,
                      title: 'লগআউট করুন',
                      onTap: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                const Icon(Icons.logout_rounded, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Text(
                                  'লগআউট',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            content: Text(
                              'আপনি কি নিশ্চিত যে আপনি অ্যাকাউন্ট থেকে লগআউট করতে চান?',
                              style: const TextStyle(),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(
                                  'বাতিল',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: Text(
                                  'লগআউট',
                                  style: const TextStyle(color: Colors.white),
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
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
