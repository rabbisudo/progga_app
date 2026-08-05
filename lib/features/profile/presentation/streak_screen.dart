import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../presentation/profile_notifier.dart';
import '../domain/profile_model.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../leaderboard/data/leaderboard_repository.dart';
import '../../leaderboard/domain/leaderboard_model.dart';

const String _largeFlameSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 24 24">
	<path fill="currentColor" d="M12.832 21.801c3.126-.626 7.168-2.875 7.168-8.69c0-5.291-3.873-8.815-6.658-10.434c-.619-.36-1.342.113-1.342.828v1.828c0 1.442-.606 4.074-2.29 5.169c-.86.559-1.79-.278-1.894-1.298l-.086-.838c-.1-.974-1.092-1.565-1.87-.971C4.461 8.46 3 10.33 3 13.11C3 20.221 8.289 22 10.933 22q.232 0 .484-.015C10.111 21.874 8 21.064 8 18.444c0-2.05 1.495-3.435 2.631-4.11c.306-.18.663.055.663.41v.59c0 .45.175 1.155.59 1.637c.47.546 1.159-.026 1.214-.744c.018-.226.246-.37.442-.256c.641.375 1.46 1.175 1.46 2.473c0 2.048-1.129 2.99-2.168 3.357" />
</svg>''';

const String _smallFlameSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24">
	<path fill="currentColor" d="M12.832 21.801c3.126-.626 7.168-2.875 7.168-8.69c0-5.291-3.873-8.815-6.658-10.434c-.619-.36-1.342.113-1.342.828v1.828c0 1.442-.606 4.074-2.29 5.169c-.86.559-1.79-.278-1.894-1.298l-.086-.838c-.1-.974-1.092-1.565-1.87-.971C4.461 8.46 3 10.33 3 13.11C3 20.221 8.289 22 10.933 22q.232 0 .484-.015C10.111 21.874 8 21.064 8 18.444c0-2.05 1.495-3.435 2.631-4.11c.306-.18.663.055.663.41v.59c0 .45.175 1.155.59 1.637c.47.546 1.159-.026 1.214-.744c.018-.226.246-.37.442-.256c.641.375 1.46 1.175 1.46 2.473c0 2.048-1.129 2.99-2.168 3.357" />
</svg>''';

const String _iceCrystalSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 128 128">
	<path d="M0 0h128v128H0z" fill="none" />
	<path fill="#FFF" d="M63.03 5.38L16.79 20.85l-6.58 3.79l-.83 24.84l5.95 43.37l30.91 16.7l19.7 7.1l14.53-5.95l34.17-15.67s3.34-.27 1.78-5.38s.42-53.34.42-53.34l.18-11.58s-.02-2.73-9.07-4.71S63.03 5.38 63.03 5.38" opacity=".5" />
	<path fill="#7EC8EE" d="m9.31 25.82l54.45 24.9l52.26-23.8s.27 63.47-.55 63.75c-.41.14-51.16-19.7-51.16-19.7l-49.79 19.7l-4.93-54.73z" opacity=".7" />
	<path fill="#63ABDE" d="m65.95 116.65l-25.45-9.3l-25.17-14.5l-.82-2.19l47.88-21.62l53.08 21.62l-.82 4.38l-21.61 10.39z" opacity=".7" />
	<path fill="#B0E4FF" d="M62.94 5.02L15.33 21.16l-6.02 4.66l8.21 3.83L61.57 48.8l3.56-.55l50.89-24.35z" opacity=".7" />
	<path fill="#37B4E2" d="M116.84 89.59c-1.5-1.5-31.75-13.7-37.53-16.24s-8.33-4.16-9.37-6.71s-3.12-45.8-3.12-48.57s-.33-10.85-3.46-10.86c-2.57-.01-3.12 7.34-3.12 11.19s-1.03 44.81-1.98 48.35c-1.16 4.36-12.04 7.97-21.39 12.37c-9.36 4.4-21.84 7.83-22.36 11.53c-.51 3.7 2.06 4.62 6.83 7.92c1.95 1.35 8.17 4.83 15.41 8.42c10.49 5.2 23.16 10.42 28.38 10.51c7.35.13 18.19-5.83 29.67-11.2c11.27-5.27 21.34-9.5 22.15-11.46c1.25-3.01 1.4-3.75-.11-5.25m-22.96 12.67c-7.5 3.42-24.98 11.1-29.03 11.45s-18.52-6.52-24.98-9.6c-7.29-3.47-21.39-10.76-20.59-12.61c.81-1.85 9.6-4.86 21.74-9.83s23.01-9.14 23.01-9.14s7.52 2.68 20.7 8.33C97.68 86.41 112.83 93 112.83 93s-9.81 5.09-18.95 9.26" />
	<path fill="#58C4FD" d="M63.56 3.92c-4.11-.57-12.68 3.86-24.4 7.86c-12.51 4.27-23.06 7.12-26.74 8.96c-3.03 1.52-4.55 4-4.69 7.31c-.13 3.3-.41 12.67 2.07 36.65c.76 7.3 3.53 25.86 3.89 27.17c1.85 6.73 4.93 1.91 4.24-3.33c-.49-3.7-2.07-12.13-3.45-26.33s-2.76-32.11-1.52-35.15s9.19-5.38 14.75-7.03c17.23-5.1 32.53-11.85 35.84-11.85s25.77 8.13 29.5 9.51c3.72 1.38 19.71 5.93 20.54 8.13s.14 58.58.28 61.61s-.65 6.83 1.59 7.24c2.25.4 2.82-3.38 2.82-6s-.14-27.7.14-39.14s2.07-22.6-1.1-26.6s-12.96-6.06-29.22-11.72C77.96 7.7 67.55 4.47 63.56 3.92" />
	<radialGradient id="SVGE3mfAd0N" cx="61.845" cy="58.67" r="46.169" gradientTransform="matrix(-.7728 .6347 -.8463 -1.0304 159.288 79.872)" gradientUnits="userSpaceOnUse">
		<stop offset=".1" stop-color="#FFF" stop-opacity=".9" />
		<stop offset="1" stop-color="#FCFCFC" stop-opacity="0" />
	</radialGradient>
	<path fill="url(#SVGE3mfAd0N)" d="m15.32 29.69l47.96 21.92l2.48 61.2l-5.36 1.23l-36.54-16.26l-8.53-4.93l-5.74-56.91l1.31-8.31z" />
	<radialGradient id="SVGAeE0ee7W" cx="69.465" cy="53.845" r="54.634" gradientTransform="matrix(.8254 .5645 -.6684 .9774 48.117 -37.996)" gradientUnits="userSpaceOnUse">
		<stop offset=".152" stop-color="#32AFE0" stop-opacity=".9" />
		<stop offset=".963" stop-color="#32AFE0" stop-opacity="0" />
	</radialGradient>
	<path fill="url(#SVGAeE0ee7W)" d="m64.52 51.89l.97 63.54l43.41-17.51l6.48-4.55l-.37-5.52l2.02-63.12l-6.61 1.66z" />
	<radialGradient id="SVG416KxdVW" cx="63.646" cy="49.481" r="47.148" gradientTransform="matrix(-.002 -1 2.0491 -.0041 -37.616 113.33)" gradientUnits="userSpaceOnUse">
		<stop offset=".256" stop-color="#67CCF9" stop-opacity=".9" />
		<stop offset=".416" stop-color="#6CCDF9" stop-opacity=".674" />
		<stop offset=".616" stop-color="#7CD1F9" stop-opacity=".392" />
		<stop offset=".837" stop-color="#95D8F9" stop-opacity=".081" />
		<stop offset=".895" stop-color="#9DDAF9" stop-opacity="0" />
	</radialGradient>
	<path fill="url(#SVG416KxdVW)" d="m15.87 31.2l25.91 11.85l21.71 8.75l51.07-25.7l1.18-1.11L62.67 6.11L13.8 21.96l-4.96 3.59l.14 3.17z" />
	<path fill="#37B5E1" d="M7.81 102.12c.91 2.5 3.8 5.52 9.68 6.45c4.86.77 7.96-.11 10.3-1.49c2.12-1.25 2.74-4.09 2.65-5.39c-.12-1.63-1.83-4.04-3.8-5.05c-1.98-1.02-19.46 3.76-18.83 5.48" />
	<path fill="#B0E3FD" d="M12 93.94c-3.24 1.88-6.55 6.11-3.61 9.05s13.82 3.71 18-.1c4.19-3.8-.77-7.89-4.14-9.39s-6.93-1.49-10.25.44" />
	<path fill="#FDFEFE" d="M10.94 97.31c-1.22.08-3.09 2.86-.14 4.91c3.66 2.55 8.76 1.01 8.42-.53s-3.9-1.44-5.34-2.26c-1.45-.82-1.55-2.22-2.94-2.12" />
	<path fill="#37B5E1" d="M28.71 118.38c-1.01 2.27.05 4.89 4.66 6.03c7.22 1.78 11.83-.8 13.37-2.29s1.73-3.85.91-4.62c-.82-.76-18.94.88-18.94.88" />
	<path fill="#B0E4FF" d="M37.46 113.82c-5.82.3-8.46 3.15-8.7 4.5s2.58 3.95 8.99 3.64c8.71-.42 10.11-4.19 10.11-4.19s-2.07-4.38-10.4-3.95" />
	<path fill="#FFF" d="M35.78 116.32c-1.22-.79-3.03-.29-4.14.48c-.89.62-1.34 2.07-.72 2.84c1.01 1.25 3.03.87 4.24.1c1.19-.77 1.96-2.55.62-3.42m-9.37-94.57c-1.74-2.56-8.72.22-11.4 1.69s-4.25 3.33-3.98 5.4s3.76 3.11 7.58 4.8s32.87 14.9 35.06 16.08c3.12 1.69 6.47 3.86 7.47 10.41c.65 4.31 2.44 45.69 2.51 47.11c.16 3.36-.13 8.23 1.9 8.15c1.78-.07 1.42-4.5 1.37-8.21s.31-44.05.32-46.78c.02-3.41 1.12-7.25 3.41-9.27s6.64-4.58 11.8-7.21c6.18-3.14 19.97-9.92 25.2-12.26s8.23-3.05 8.23-5.62s-11.89-6.11-13.3-6.22c-1.42-.11-2.94.38-2.62 2.13c.33 1.74 1.66 4.71-1.01 7.05s-8.45 5.52-11.75 7.18c-5.69 2.85-19.41 10.09-24.1 9.76s-7.63-1.15-14.67-4.09c-7.03-2.94-15.49-7.2-19.63-9.43c-2.94-1.59-4.96-3.93-4.8-6.38c.18-2.44 3.92-2.08 2.41-4.29m17.34-5.89c.67 1.73 6.71-.05 9.6-.93c2.89-.87 7.85-2.45 10.8-2.62c2.94-.16 12.81 2.84 15.32 3.33s4.69.6 5.23-.27s-3-2.78-7.96-4.47S66 6.54 63.54 6.86c-2.54.34-7.99 2.83-12.32 4.36c-2.62.93-8.29 2.51-7.47 4.64" />
</svg>''';

const String _checkTicSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10s10-4.5 10-10S17.5 2 12 2m-2 15l-5-5l1.41-1.41L10 14.17l7.59-7.59L19 8z" />
</svg>''';

String _toBengaliDigits(String input) {
  final Map<String, String> digits = {
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
    '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
  };
  return input.split('').map((char) => digits[char] ?? char).join();
}

String _getBengaliMonthYear(DateTime date) {
  final months = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
  ];
  final monthName = months[date.month - 1];
  final yearStr = _toBengaliDigits(date.year.toString());
  return '$monthName $yearStr';
}

final globalStreakLeaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntryModel>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchLeaderboard(scope: 'global');
});

class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
          centerTitle: true,
          title: Text(
            'স্ট্রিক',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'Noto Sans Bengali',
            ),
          ),

          bottom: TabBar(
            indicatorColor: const Color(0xFF017A47),
            indicatorWeight: 3,
            labelColor: const Color(0xFF017A47),
            unselectedLabelColor: isDark ? Colors.white30 : Colors.black38,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'Noto Sans Bengali',
            ),
            tabs: const [
              Tab(text: 'ব্যক্তিগত'),
              Tab(text: 'গ্লোবাল'),
            ],
          ),
        ),
        body: profileAsync.when(
          loading: () => TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildPersonalTabSkeleton(context, isDark),
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF017A47)),
              ),
            ],
          ),
          error: (err, stack) => Center(
            child: Text(
              'তথ্য লোড করতে ত্রুটি: $err',
              style: const TextStyle(color: Colors.redAccent, fontFamily: 'Noto Sans Bengali'),
            ),
          ),
          data: (userData) {
            final profile = userData.profile;
            final currentStreak = profile?.currentStreak ?? 0;
            final longestStreak = profile?.longestStreak ?? 0;
            final streakFreezes = profile?.streakFreezes ?? 5;
            final usedStreakFreezes = profile?.usedStreakFreezes ?? 0;
            final streakHistory = userData.streakHistory ?? List.filled(7, false);
            final monthlyActiveDates = userData.monthlyActiveDates ?? [];
            final frozenStreakDates = userData.frozenStreakDates ?? [];

            return TabBarView(
              children: [
                _buildPersonalTab(
                  context,
                  currentStreak,
                  longestStreak,
                  streakHistory,
                  streakFreezes,
                  usedStreakFreezes,
                  monthlyActiveDates,
                  frozenStreakDates,
                  isDark,
                  _selectedMonth,
                  () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                    });
                  },
                  () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                    });
                  },
                ),
                _buildGlobalTab(context, ref, userData.id, profile, isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPersonalTabSkeleton(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // 1. Green top banner placeholder
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerSkeleton(width: 80, height: 48, borderRadius: 8),
                          SizedBox(height: 10),
                          ShimmerSkeleton(width: 120, height: 20, borderRadius: 4),
                        ],
                      ),
                    ),
                    const ShimmerSkeleton(width: 80, height: 80, borderRadius: 40),
                  ],
                ),
                const SizedBox(height: 20),
                // Banner white warning card placeholder
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: const [
                      ShimmerSkeleton(width: 24, height: 24, borderRadius: 12),
                      SizedBox(width: 10),
                      Expanded(
                        child: ShimmerSkeleton(width: double.infinity, height: 16, borderRadius: 4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Month Calendar Title placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                ShimmerSkeleton(width: 32, height: 32, borderRadius: 16),
                ShimmerSkeleton(width: 120, height: 22, borderRadius: 4),
                ShimmerSkeleton(width: 32, height: 32, borderRadius: 16),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Status card row placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 90,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: const [
                        ShimmerSkeleton(width: 36, height: 36, borderRadius: 18),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShimmerSkeleton(width: 60, height: 24, borderRadius: 4),
                              SizedBox(height: 4),
                              ShimmerSkeleton(width: 80, height: 14, borderRadius: 3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 90,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: const [
                        ShimmerSkeleton(width: 36, height: 36, borderRadius: 18),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ShimmerSkeleton(width: 60, height: 24, borderRadius: 4),
                              SizedBox(height: 4),
                              ShimmerSkeleton(width: 80, height: 14, borderRadius: 3),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Calendar container placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: 35,
                    itemBuilder: (context, index) => const Center(
                      child: ShimmerSkeleton(width: 30, height: 30, borderRadius: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPersonalTab(
    BuildContext context,
    int currentStreak,
    int longestStreak,
    List<bool> streakHistory,
    int streakFreezes,
    int usedStreakFreezes,
    List<String> monthlyActiveDates,
    List<String> frozenStreakDates,
    bool isDark,
    DateTime selectedMonth,
    VoidCallback onPrevMonth,
    VoidCallback onNextMonth,
  ) {
    // 1. Green top banner
    final streakText = currentStreak.toString();
    final now = DateTime.now();
    final isNextMonthDisabled = selectedMonth.year > now.year ||
        (selectedMonth.year == now.year && selectedMonth.month >= now.month);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF122317) : const Color(0xFFE8F5E9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            streakText,
                            style: const TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF017A47),
                            ),
                          ),
                          const Text(
                            'দিনের স্ট্রিক!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF017A47),
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Svg glowing flame
                    SvgPicture.string(
                      _largeFlameSvg,
                      width: 100,
                      height: 100,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF017A47),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Banner white warning card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : const Color(0xFFB9D8C9),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'এই পারফেক্ট স্ট্রিকের শিখা জ্বালিয়ে রাখতে সপ্তাহের প্রতিদিন অন্তত একটি পরীক্ষা দাও!',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.4,
                            fontFamily: 'Noto Sans Bengali',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Month Calendar Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  onPressed: onPrevMonth,
                ),
                Text(
                  _getBengaliMonthYear(selectedMonth),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Noto Sans Bengali',
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: isNextMonthDisabled
                        ? (isDark ? Colors.white12 : Colors.grey.shade300)
                        : (isDark ? Colors.white : Colors.black87),
                  ),
                  onPressed: isNextMonthDisabled ? null : onNextMonth,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Status card row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    svgContent: _checkTicSvg,
                    colorFilterColor: const Color(0xFF017A47),
                    value: _toBengaliDigits(currentStreak.toString()),
                    label: 'দিন প্রাকটিস করেছ',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    svgContent: _iceCrystalSvg,
                    value: _toBengaliDigits('$usedStreakFreezes/${usedStreakFreezes + streakFreezes}'),
                    label: 'ব্যবহৃত স্ট্রিক ফ্রিজ',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Calendar container
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                ),
              ),
              child: _buildMonthlyCalendar(
                currentStreak,
                streakHistory,
                monthlyActiveDates,
                frozenStreakDates,
                isDark,
                selectedMonth,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String svgContent,
    Color? colorFilterColor,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          SvgPicture.string(
            svgContent,
            width: 36,
            height: 36,
            colorFilter: colorFilterColor != null
                ? ColorFilter.mode(colorFilterColor, BlendMode.srcIn)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontFamily: 'Noto Sans Bengali',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar(
    int currentStreak,
    List<bool> streakHistory,
    List<String> monthlyActiveDates,
    List<String> frozenStreakDates,
    bool isDark,
    DateTime selectedMonth,
  ) {
    const List<String> weekdays = ['শনি', 'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র'];
    final now = DateTime.now();
    
    // Days in selected month calculation
    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final totalDays = lastDayOfMonth.day;

    // Saturday-first start index calculation
    final int startOffset = (firstDayOfMonth.weekday == 6)
        ? 0
        : (firstDayOfMonth.weekday == 7)
            ? 1
            : firstDayOfMonth.weekday + 1;

    final gridCellsCount = totalDays + startOffset;

    return Column(
      children: [
        // Weekday header row
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: 7,
          itemBuilder: (context, index) {
            final isTodayWeekday = (selectedMonth.year == now.year && selectedMonth.month == now.month) &&
                now.weekday == (index == 0 ? 6 : (index == 1 ? 7 : index - 1));
            return Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isTodayWeekday
                      ? const Color(0xFF017A47)
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontFamily: 'Noto Sans Bengali',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // Days calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: gridCellsCount,
          itemBuilder: (context, index) {
            if (index < startOffset) {
              return const SizedBox.shrink();
            }

            final dayNumber = index - startOffset + 1;
            final dayDate = DateTime(selectedMonth.year, selectedMonth.month, dayNumber);
            final isToday = (selectedMonth.year == now.year && selectedMonth.month == now.month && dayNumber == now.day);
            final isFuture = dayDate.isAfter(now);
            bool isActive = false;
            bool isFreeze = false;

            if (!isFuture) {
              final yr = dayDate.year;
              final mn = dayDate.month.toString().padLeft(2, '0');
              final dy = dayDate.day.toString().padLeft(2, '0');
              final dateStr = '$yr-$mn-$dy';

              if (monthlyActiveDates.contains(dateStr)) {
                isActive = true;
              } else if (frozenStreakDates.contains(dateStr)) {
                isFreeze = true;
              }
            }

            // Styling variables
            Widget cellContent;
            BoxDecoration? decoration;
            Color textColor = isDark ? Colors.white : Colors.black87;

            // Determine if connectable (active, freeze, or today)
            bool currentConnectable = (isActive || isFreeze || isToday);
            bool prevConnectable = false;
            bool nextConnectable = false;

            if (currentConnectable) {
              if (dayNumber > 1) {
                final prevDate = DateTime(selectedMonth.year, selectedMonth.month, dayNumber - 1);
                final prevDateStr = '${prevDate.year}-${prevDate.month.toString().padLeft(2, '0')}-${prevDate.day.toString().padLeft(2, '0')}';
                final isPrevToday = (selectedMonth.year == now.year && selectedMonth.month == now.month && (dayNumber - 1) == now.day);
                prevConnectable = monthlyActiveDates.contains(prevDateStr) || frozenStreakDates.contains(prevDateStr) || isPrevToday;
              }
              if (dayNumber < totalDays) {
                final nextDate = DateTime(selectedMonth.year, selectedMonth.month, dayNumber + 1);
                final nextDateStr = '${nextDate.year}-${nextDate.month.toString().padLeft(2, '0')}-${nextDate.day.toString().padLeft(2, '0')}';
                final isNextToday = (selectedMonth.year == now.year && selectedMonth.month == now.month && (dayNumber + 1) == now.day);
                nextConnectable = monthlyActiveDates.contains(nextDateStr) || frozenStreakDates.contains(nextDateStr) || isNextToday;
              }
            }

            final isPartofSequence = prevConnectable || nextConnectable;

            if (isToday) {
              if (isActive) {
                // Today completed: show solid brand green circle with white text number
                decoration = const BoxDecoration(
                  color: Color(0xFF017A47),
                  shape: BoxShape.circle,
                );
                textColor = Colors.white;
                cellContent = Center(
                  child: Text(
                    _toBengaliDigits(dayNumber.toString()),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                );
              } else {
                // Today not completed: show bordered circle with day number in brand green
                decoration = BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF017A47), width: 1.5),
                );
                textColor = const Color(0xFF017A47);
                cellContent = Center(
                  child: Text(
                    _toBengaliDigits(dayNumber.toString()),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF017A47)),
                  ),
                );
              }
            } else if (isFreeze) {
              // Freeze day: show blue circle checkmark badge
              cellContent = Center(
                child: SvgPicture.string(
                  _checkTicSvg,
                  colorFilter: const ColorFilter.mode(Color(0xFF29B6F6), BlendMode.srcIn),
                  width: 28,
                  height: 28,
                ),
              );
            } else if (isActive) {
              // Active day
              if (isPartofSequence) {
                // Connected active day: transparent background (just digits sitting in capsule)
                textColor = isDark ? Colors.white : const Color(0xFF017A47);
                decoration = null;
              } else {
                // Isolated active day: show circular light green outline/background
                decoration = BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFB9D8C9), width: 1),
                );
                textColor = const Color(0xFF017A47);
              }
              cellContent = Center(
                child: Text(
                  _toBengaliDigits(dayNumber.toString()),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor),
                ),
              );
            } else {
              // Inactive/Future day
              textColor = isFuture
                  ? (isDark ? Colors.white24 : Colors.grey.shade400)
                  : (isDark ? Colors.white70 : Colors.black87);
              cellContent = Center(
                child: Text(
                  _toBengaliDigits(dayNumber.toString()),
                  style: TextStyle(fontSize: 15, color: textColor),
                ),
              );
            }

            // Connection capsule background logic
            final connectionColor = const Color(0xFF017A47).withOpacity(isDark ? 0.15 : 0.08);
            Widget? connectionWidget;
            if (currentConnectable) {
              if (prevConnectable && nextConnectable) {
                // Middle of connection
                connectionWidget = Positioned(
                  left: 0,
                  right: 0,
                  height: 32,
                  child: Container(
                    color: connectionColor,
                  ),
                );
              } else if (nextConnectable) {
                // Start of connection: rounded left side
                connectionWidget = Positioned(
                  left: 8,
                  right: 0,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: connectionColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                );
              } else if (prevConnectable) {
                // End of connection: rounded right side
                connectionWidget = Positioned(
                  left: 0,
                  right: 8,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: connectionColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                );
              }
            }

            return Stack(
              alignment: Alignment.center,
              children: [
                if (connectionWidget != null) connectionWidget,
                Container(
                  width: 32,
                  height: 32,
                  decoration: decoration,
                  child: cellContent,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildGlobalTab(
    BuildContext context,
    WidgetRef ref,
    String myUserId,
    UserProfile? profile,
    bool isDark,
  ) {
    return GlobalStreakLeaderboardView(
      myUserId: myUserId,
      profile: profile,
      isDark: isDark,
    );
  }
}

class GlobalStreakLeaderboardView extends ConsumerStatefulWidget {
  final String myUserId;
  final UserProfile? profile;
  final bool isDark;

  const GlobalStreakLeaderboardView({
    super.key,
    required this.myUserId,
    required this.profile,
    required this.isDark,
  });

  @override
  ConsumerState<GlobalStreakLeaderboardView> createState() => _GlobalStreakLeaderboardViewState();
}

class _GlobalStreakLeaderboardViewState extends ConsumerState<GlobalStreakLeaderboardView> {
  final List<LeaderboardEntryModel> _entries = [];
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _offset = 0;
  static const int _limit = 30;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPage(isInitial: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && _errorMessage == null) {
        _fetchPage(isInitial: false);
      }
    }
  }

  Future<void> _fetchPage({required bool isInitial}) async {
    if (isInitial) {
      setState(() {
        _isLoadingInitial = true;
        _errorMessage = null;
        _entries.clear();
        _offset = 0;
        _hasMore = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final repo = ref.read(leaderboardRepositoryProvider);
      final newEntries = await repo.fetchLeaderboard(
        scope: 'global',
        limit: _limit,
        offset: _offset,
      );

      if (mounted) {
        setState(() {
          _entries.addAll(newEntries);
          _offset += _limit;
          _isLoadingInitial = false;
          _isLoadingMore = false;
          if (newEntries.length < _limit) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingInitial = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingInitial) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF017A47)),
      );
    }

    if (_errorMessage != null && _entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'তথ্য লোড করতে ত্রুটি: $_errorMessage',
              style: const TextStyle(fontFamily: 'Noto Sans Bengali', color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _fetchPage(isInitial: true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF017A47)),
              child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(fontFamily: 'Noto Sans Bengali', color: Colors.white)),
            ),
          ],
        ),
      );
    }

    // Map and sort rankings by computed streak count descending
    final sortedList = _entries.map((entry) {
      final isMe = entry.userId == widget.myUserId;
      final streakCount = isMe
          ? (widget.profile?.currentStreak ?? entry.currentStreak)
          : (entry.currentStreak > 3 ? entry.currentStreak : (entry.xp / 100 + 2).round());
      return MapEntry(entry, streakCount);
    }).toList();

    sortedList.sort((a, b) => b.value.compareTo(a.value));

    // Re-assign ranks based on index in list
    final reRanked = List<MapEntry<LeaderboardEntryModel, int>>.generate(sortedList.length, (idx) {
      final entry = sortedList[idx].key;
      final streakVal = sortedList[idx].value;
      final updatedEntry = LeaderboardEntryModel(
        rank: entry.rank,
        userId: entry.userId,
        username: entry.username,
        fullName: entry.fullName,
        institution: entry.institution,
        avatarKey: entry.avatarKey,
        xp: entry.xp,
        level: entry.level,
        solvedQuestionsCount: entry.solvedQuestionsCount,
        league: entry.league,
        currentStreak: streakVal,
        batch: entry.batch,
      );
      return MapEntry(updatedEntry, streakVal);
    });

    if (reRanked.isEmpty) {
      return const Center(
        child: Text(
          'গ্লোবাল তালিকায় কেউ নেই',
          style: TextStyle(fontFamily: 'Noto Sans Bengali'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPage(isInitial: true),
      color: const Color(0xFF017A47),
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        itemCount: reRanked.length + (_hasMore ? 1 : 0),
        separatorBuilder: (context, index) => Divider(
          color: widget.isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          height: 1,
          indent: 70,
        ),
        itemBuilder: (context, index) {
          if (index == reRanked.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF017A47)),
              ),
            );
          }

          final entry = reRanked[index].key;
          final rank = entry.rank;
          final fullName = entry.fullName;
          final batchName = entry.batch ?? 'HSC-25';
          final streakCount = reRanked[index].value;

          final String avatar = (entry.avatarKey != null && entry.avatarKey!.isNotEmpty)
              ? entry.avatarKey!
              : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${Uri.encodeComponent(entry.userId)}';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CustomAvatar(
                      avatarUrl: avatar,
                      radius: 22,
                      backgroundColor: const Color(0xFF017A47).withOpacity(0.12),
                      fallbackWidget: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Color(0xFF017A47),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -4,
                      right: -4,
                      child: _buildRankOverlayBadge(rank, widget.isDark),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                          fontFamily: 'Noto Sans Bengali',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        batchName,
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDark ? Colors.white30 : Colors.black38,
                          fontFamily: 'Noto Sans Bengali',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFF017A47),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _toBengaliDigits(streakCount.toString()),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'দিন',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF017A47),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Noto Sans Bengali',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Widget _buildRankOverlayBadge(int rank, bool isDark) {
  if (rank == 1) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFFFFD700), // Gold
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '১',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
    );
  }
  if (rank == 2) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFFC0C0C0), // Silver
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '২',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
    );
  }
  if (rank == 3) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: Color(0xFFCD7F32), // Bronze
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '৩',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ),
    );
  }
  // Rank 4 or below shows a status dot
  return Container(
    width: 11,
    height: 11,
    decoration: BoxDecoration(
      color: rank % 4 == 0 ? const Color(0xFF017A47) : Colors.grey.shade400,
      shape: BoxShape.circle,
      border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 1.5),
    ),
  );
}

class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.35, 0.5, 0.65],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              transform: _SlidingGradientTransform(slidePercent: _animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
