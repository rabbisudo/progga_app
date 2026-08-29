import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'profile_notifier.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../question/presentation/practice_notifier.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/custom_back_button.dart';

const String _logoutSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-width="1.5">
		<path stroke-linejoin="round" d="M10 12h10m0 0l-3-3m3 3l-3 3" />
		<path d="M4 12a8 8 0 0 1 8-8m0 16a7.99 7.99 0 0 1-6.245-3" />
	</g>
</svg>''';

const String _sunSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-width="1.5" d="M12 2v1m0 18v1m10-10h-1M3 12H2m17.07-7.07l-.392.393M5.322 18.678l-.393.393m14.141-.001l-.392-.393M5.322 5.322l-.393-.393M6.341 10A6 6 0 1 0 10 6.341" />
</svg>''';

const String _moonSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="m21.067 11.857l-.642-.388zm-8.924-8.924l-.388-.642zm-4.767 17.08a.75.75 0 1 0-.752 1.298zm-4.687-2.638a.75.75 0 1 0 1.298-.75zM21.25 12A9.25 9.25 0 0 1 12 21.25v1.5c5.937 0 10.75-4.813 10.75-10.75zm-18.5 0A9.25 9.25 0 0 1 12 2.75v-1.5C6.063 1.25 1.25 6.063 1.25 12zm12.75 2.25A5.75 5.75 0 0 1 9.75 8.5h-1.5a7.25 7.25 0 0 0 7.25 7.25zm4.925-2.781A5.75 5.75 0 0 1 15.5 14.25v1.5a7.25 7.25 0 0 0 6.21-3.505zM9.75 8.5a5.75 5.75 0 0 1 2.781-4.925l-.776-1.284A7.25 7.25 0 0 0 8.25 8.5zM12 2.75a.38.38 0 0 1-.268-.118a.3.3 0 0 1-.082-.155c-.004-.031-.002-.121.105-.186l.776 1.284c.503-.304.665-.861.606-1.299c-.062-.455-.42-1.026-1.137-1.026zm9.71 9.495c-.066.107-.156.109-.187.105a.3.3 0 0 1-.155-.082a.38.38 0 0 1-.118-.268h1.5c0-.717-.571-1.075-1.026-1.137c-.438-.059-.995.103-1.299.606zM12 21.25a9.2 9.2 0 0 1-4.624-1.237l-.752 1.298A10.7 10.7 0 0 0 12 22.75zm-8.013-4.625A9.2 9.2 0 0 1 2.75 12h-1.5a10.7 10.7 0 0 0 1.439 5.375z" />
</svg>''';

const String _avatarEditSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-width="1.5" d="m14.36 4.079l.927-.927a3.932 3.932 0 0 1 5.561 5.561l-.927.927m-5.56-5.561s.115 1.97 1.853 3.707C17.952 9.524 19.92 9.64 19.92 9.64m-5.56-5.561L12 6.439m7.921 3.2l-5.26 5.262L11.56 18l-.16.161c-.578.577-.867.866-1.185 1.114a6.6 6.6 0 0 1-1.211.749c-.364.173-.751.302-1.526.56l-3.281 1.094m0 0l-.802.268a1.06 1.06 0 0 1-1.342-1.342l.268-.802m1.876 1.876l-1.876-1.876m0 0l1.094-3.281c.258-.775.387-1.162.56-1.526q.309-.647.749-1.211c.248-.318.537-.607 1.114-1.184L8.5 9.939" />
</svg>''';

const String _privacySvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-width="1.5">
		<circle cx="12" cy="16" r="2" />
		<path stroke-linecap="round" d="M6 10V8q0-.511.083-1M18 10V8A6 6 0 0 0 7.5 4.031M11 22H8c-2.828 0-4.243 0-5.121-.879C2 20.243 2 18.828 2 16s0-4.243.879-5.121C3.757 10 5.172 10 8 10h8c2.828 0 4.243 0 5.121.879C22 11.757 22 13.172 22 16s0 4.243-.879 5.121C20.243 22 18.828 22 16 22h-1" />
	</g>
</svg>''';

const String _termsSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-width="1.5" d="m14.163 18.488l-.721.72a6.117 6.117 0 0 1-8.65-8.65l.72-.72m4.325 4.325l4.326-4.326M9.837 5.512l.721-.72a6.117 6.117 0 0 1 8.65 0m-.72 9.37l.72-.72A6.1 6.1 0 0 0 20.998 9" />
</svg>''';

const String _personSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-width="1.5">
		<circle cx="12" cy="6" r="4" />
		<path stroke-linecap="round" d="M19.998 18q.002-.246.002-.5c0-2.485-3.582-4.5-8-4.5s-8 2.015-8 4.5S4 22 12 22c2.231 0 3.84-.157 5-.437" />
	</g>
</svg>''';

const String _reportSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-width="1.5" d="M5 22v-8m0 0l2.47-.494a8.7 8.7 0 0 1 4.925.452a8.68 8.68 0 0 0 5.327.361l.214-.053A1.404 1.404 0 0 0 19 12.904V5.537a1.2 1.2 0 0 0-1.49-1.164a8 8 0 0 1-4.911-.334l-.204-.081a8.7 8.7 0 0 0-4.924-.452L5 4m0 10v-3m0-7V2m0 2v3" />
</svg>''';

const String _cameraSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-width="1.5">
		<circle cx="12" cy="13" r="3" />
		<path stroke-linecap="round" d="M3 13c0-2.809 0-4.213.674-5.222a4 4 0 0 1 1.104-1.104C5.787 6 7.19 6 10 6h4c2.809 0 4.213 0 5.222.674a4 4 0 0 1 1.104 1.104C21 8.787 21 10.19 21 13s0 4.213-.674 5.222a4 4 0 0 1-1.104 1.104C18.213 20 16.81 20 14 20h-4c-2.809 0-4.213 0-5.222-.674a4 4 0 0 1-1.104-1.104c-.232-.347-.384-.74-.484-1.222M18 10h-.5m-3-6.5h-5" />
	</g>
</svg>''';

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
    IconData? icon,
    Widget? customIcon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        splashColor: color.withOpacity(isDark ? 0.16 : 0.08),
        hoverColor: color.withOpacity(isDark ? 0.10 : 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: customIcon ?? Icon(icon, size: 18, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
        trailing: trailing ?? Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: isDark ? Colors.white30 : Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
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
          fontFamily: 'Li Ador Noirrit',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
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
            fontFamily: 'Li Ador Noirrit',
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
                          CustomAvatar(
                            avatarUrl: profile.avatarKey,
                            radius: 44,
                            backgroundColor: brandTealColor.withOpacity(0.1),
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
                                child: SvgPicture.string(
                                  _cameraSvg,
                                  width: 11,
                                  height: 11,
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
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
                          fontFamily: 'Li Ador Noirrit',
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
                      customIcon: SvgPicture.string(
                        _personSvg,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(Color(0xFF00C569), BlendMode.srcIn),
                      ),
                      title: 'ব্যক্তিগত তথ্য',
                      isDark: isDark,

                      onTap: () => context.push('/personal-info'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFE53935),
                      customIcon: SvgPicture.string(
                        _reportSvg,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(Color(0xFFE53935), BlendMode.srcIn),
                      ),
                      title: 'আমার রিপোর্টসমূহ',
                      isDark: isDark,
                      onTap: () => context.push('/my-reports'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF00B4D8),
                      icon: Icons.bookmark_rounded,
                      title: 'বুকমার্ক করা প্রশ্নসমূহ',
                      isDark: isDark,
                      onTap: () => context.push('/bookmarked-questions'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF9F0A),
                      icon: Icons.history_rounded,
                      title: 'পরীক্ষার ইতিহাস',
                      isDark: isDark,
                      onTap: () => context.push('/exam-history'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF00B8),
                      customIcon: SvgPicture.string(
                        _avatarEditSvg,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(Color(0xFFFF00B8), BlendMode.srcIn),
                      ),
                      title: 'অ্যাভাটার এডিট',
                      isDark: isDark,
                      onTap: () => context.push('/avatar-editor'),
                    ),

                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF007AFF),
                      customIcon: SvgPicture.string(
                        isDark ? _moonSvg : _sunSvg,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(Color(0xFF007AFF), BlendMode.srcIn),
                      ),
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
                      color: const Color(0xFF5856D6),
                      icon: Icons.notifications_active_rounded,
                      title: 'নোটিফিকেশন',
                      isDark: isDark,
                      onTap: () => context.push('/notifications'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF9500),
                      icon: Icons.lock_outline_rounded,
                      title: user.password == null ? 'পাসওয়ার্ড সেট করুন' : 'পাসওয়ার্ড পরিবর্তন করুন',
                      isDark: isDark,
                      onTap: () => context.push('/change-password'),
                    ),
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFF009688),
                      customIcon: SvgPicture.string(
                        _privacySvg,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(Color(0xFF009688), BlendMode.srcIn),
                      ),
                      title: 'প্রাইভেসি পলিসি',
                      isDark: isDark,
                      onTap: () async {
                        final url = Uri.parse('https://docs.google.com/document/d/1oEjbo0TDtJGli0NFh5of3BWfltaHQe7CFxSd9b5OxDQ/edit?usp=sharing');
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
                      customIcon: SvgPicture.string(
                        _termsSvg,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(Color(0xFF607D8B), BlendMode.srcIn),
                      ),
                      title: 'শর্তাবলী ও নিয়মাবলী',
                      isDark: isDark,
                      onTap: () async {
                        final url = Uri.parse('https://docs.google.com/document/d/1DZv8vTIpetDxGPr--vpLTtuotA2ZrgkiSZyQjj1uu7Q/edit?usp=sharing');
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
                      customIcon: SvgPicture.string(
                        _logoutSvg,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(Color(0xFFFF3B30), BlendMode.srcIn),
                      ),
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
                                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Li Ador Noirrit'),
                                ),
                              ],
                            ),
                            content: const Text(
                              'আপনি কি নিশ্চিত যে আপনি অ্যাকাউন্ট থেকে লগআউট করতে চান?',
                              style: TextStyle(fontFamily: 'Li Ador Noirrit'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'বাতিল',
                                  style: TextStyle(color: Colors.grey, fontFamily: 'Li Ador Noirrit'),
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
                                  style: TextStyle(color: Colors.white, fontFamily: 'Li Ador Noirrit'),
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
                    _buildFlatMenuTile(
                      theme: theme,
                      color: const Color(0xFFFF3B30),
                      icon: Icons.delete_forever_rounded,
                      title: 'অ্যাকাউন্ট ডিলিট করুন',
                      isDark: isDark,
                      onTap: () async {
                        final shouldDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Row(
                              children: [
                                const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                const Text(
                                  'অ্যাকাউন্ট ডিলিট',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Li Ador Noirrit'),
                                ),
                              ],
                            ),
                            content: const Text(
                              'আপনি কি নিশ্চিত যে আপনি স্থায়ীভাবে আপনার অ্যাকাউন্ট ডিলিট করতে চান? আপনার সব স্কোর, মক পরীক্ষার ইতিহাস এবং প্রগ্রেস চিরতরে মুছে যাবে এবং এটি আর ফিরে পাওয়া যাবে না।',
                              style: TextStyle(fontFamily: 'Li Ador Noirrit'),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text(
                                  'বাতিল',
                                  style: TextStyle(color: Colors.grey, fontFamily: 'Li Ador Noirrit'),
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
                                  'ডিলিট করুন',
                                  style: TextStyle(color: Colors.white, fontFamily: 'Li Ador Noirrit'),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (shouldDelete == true) {
                          ref.invalidate(userProfileProvider);
                          ref.invalidate(leaderboardProvider);
                          ref.invalidate(practiceProvider);
                          await ref.read(authProvider.notifier).deleteAccount();
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

  void _showPasswordUpdateDialog(BuildContext context, WidgetRef ref, bool isFirstTime) {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isFirstTime ? 'পাসওয়ার্ড সেট করুন' : 'পাসওয়ার্ড পরিবর্তন করুন',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Li Ador Noirrit',
                  fontSize: 18,
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isFirstTime) ...[
                        TextFormField(
                          controller: oldPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'বর্তমান পাসওয়ার্ড',
                            labelStyle: const TextStyle(fontFamily: 'Li Ador Noirrit', fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: brandTealColor, width: 2),
                            ),
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
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'নতুন পাসওয়ার্ড',
                          labelStyle: const TextStyle(fontFamily: 'Li Ador Noirrit', fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: brandTealColor, width: 2),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'নতুন পাসওয়ার্ড দিন';
                          }
                          if (val.trim().length < 6) {
                            return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'পাসওয়ার্ড নিশ্চিত করুন',
                          labelStyle: const TextStyle(fontFamily: 'Li Ador Noirrit', fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: brandTealColor, width: 2),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'পাসওয়ার্ডটি পুনরায় লিখুন';
                          }
                          if (val.trim() != newPasswordController.text.trim()) {
                            return 'পাসওয়ার্ড দুটি মেলেনি';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(context),
                  child: Text(
                    'বাতিল',
                    style: TextStyle(
                      fontFamily: 'Li Ador Noirrit',
                      color: isDark ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandTealColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setState(() => isSaving = true);
                          try {
                            await ref.read(userProfileProvider.notifier).setPassword(
                                  oldPassword: isFirstTime ? null : oldPasswordController.text.trim(),
                                  newPassword: newPasswordController.text.trim(),
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
                            setState(() => isSaving = false);
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
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'সংরক্ষণ',
                          style: TextStyle(
                            fontFamily: 'Li Ador Noirrit',
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
