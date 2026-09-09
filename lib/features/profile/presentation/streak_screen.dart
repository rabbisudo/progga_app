import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../presentation/profile_notifier.dart';
import '../domain/profile_model.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../leaderboard/data/leaderboard_repository.dart';
import '../../leaderboard/domain/leaderboard_model.dart';

// --- Premium Vector SVG Assets ---
const String _heroFlameSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24">
	<path fill="currentColor" d="M12.832 21.801c3.126-.626 7.168-2.875 7.168-8.69c0-5.291-3.873-8.815-6.658-10.434c-.619-.36-1.342.113-1.342.828v1.828c0 1.442-.606 4.074-2.29 5.169c-.86.559-1.79-.278-1.894-1.298l-.086-.838c-.1-.974-1.092-1.565-1.87-.971C4.461 8.46 3 10.33 3 13.11C3 20.221 8.289 22 10.933 22q.232 0 .484-.015C10.111 21.874 8 21.064 8 18.444c0-2.05 1.495-3.435 2.631-4.11c.306-.18.663.055.663.41v.59c0 .45.175 1.155.59 1.637c.47.546 1.159-.026 1.214-.744c.018-.226.246-.37.442-.256c.641.375 1.46 1.175 1.46 2.473c0 2.048-1.129 2.99-2.168 3.357" />
</svg>''';

const String _checkTicSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24">
	<path fill="currentColor" d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10s10-4.5 10-10S17.5 2 12 2m-2 15l-5-5l1.41-1.41L10 14.17l7.59-7.59L19 8z" />
</svg>''';

String _toBengaliDigits(String input) {
  const Map<String, String> digits = {
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
    '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
  };
  return input.split('').map((char) => digits[char] ?? char).join();
}

String _getBengaliMonthYear(DateTime date) {
  const months = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
  ];
  final monthName = months[date.month - 1];
  final yearStr = _toBengaliDigits(date.year.toString());
  return '$monthName $yearStr';
}

Color _getAvatarColor(String name) {
  final colors = [
    const Color(0xFF9333EA), // Purple
    const Color(0xFF0D9488), // Teal
    const Color(0xFFEA580C), // Orange
    const Color(0xFF16A34A), // Green
    const Color(0xFF2563EB), // Blue
    const Color(0xFF7C3AED), // Violet
    const Color(0xFFDB2777), // Pink
    const Color(0xFF0284C7), // Sky
    const Color(0xFFD97706), // Amber
  ];
  if (name.isEmpty) return colors[0];
  final hash = name.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
  return colors[hash % colors.length];
}

String _getInitials(String name) {
  if (name.trim().isEmpty) return 'U';
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
    final first = parts[0].characters.first;
    final second = parts[1].characters.first;
    return '$first$second'.toUpperCase();
  }
  return name.trim().characters.first.toUpperCase();
}

final globalStreakLeaderboardProvider = FutureProvider.autoDispose<List<LeaderboardEntryModel>>((ref) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return repo.fetchStreakLeaderboard();
});

class StreakScreen extends ConsumerStatefulWidget {
  const StreakScreen({super.key});

  @override
  ConsumerState<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends ConsumerState<StreakScreen> with SingleTickerProviderStateMixin {
  late DateTime _selectedMonth;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF0D120F) : const Color(0xFFF8FAF9);
    final cardBg = isDark ? const Color(0xFF141C17) : Colors.white;
    final borderColor = isDark ? const Color(0xFF222F26) : const Color(0xFFE5ECE8);
    const brandGreen = Color(0xFF017A47);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: CustomBackButton(
          color: isDark ? Colors.white : Colors.black87,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ডেইলি স্ট্রিক',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF16241C),
            fontWeight: FontWeight.bold,
            fontSize: 17,
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF162019) : const Color(0xFFEEF4F0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: TabBar(
              controller: _tabController,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              splashBorderRadius: BorderRadius.circular(10),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? const Color(0xFF213227) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: brandGreen,
              unselectedLabelColor: isDark ? Colors.white38 : const Color(0xFF5E7A69),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                fontFamily: 'Li Ador Noirrit',
              ),
              tabs: const [
                Tab(text: 'আমার স্ট্রিক'),
                Tab(text: 'লিডারবোর্ড'),
              ],
            ),
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => TabBarView(
          controller: _tabController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildPersonalTabSkeleton(isDark, borderColor),
            _buildLeaderboardSkeleton(isDark, cardBg, borderColor),
          ],
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 36),
                const SizedBox(height: 12),
                Text(
                  'তথ্য লোড করা সম্ভব হয়নি',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => ref.refresh(userProfileProvider),
                  style: TextButton.styleFrom(
                    backgroundColor: brandGreen.withValues(alpha: 0.1),
                    foregroundColor: brandGreen,
                  ),
                  child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(fontFamily: 'Li Ador Noirrit')),
                ),
              ],
            ),
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
            controller: _tabController,
            children: [
              _buildPersonalTab(
                context,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                streakHistory: streakHistory,
                streakFreezes: streakFreezes,
                usedStreakFreezes: usedStreakFreezes,
                monthlyActiveDates: monthlyActiveDates,
                frozenStreakDates: frozenStreakDates,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                selectedMonth: _selectedMonth,
                onPrevMonth: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
                  });
                },
                onNextMonth: () {
                  setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
                  });
                },
              ),
              _buildGlobalTab(
                context,
                ref: ref,
                myUserId: userData.id,
                profile: profile,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
              ),
            ],
          );
        },
      ),
    );
  }

  // --- Personal Tab Screen ---
  Widget _buildPersonalTab(
    BuildContext context, {
    required int currentStreak,
    required int longestStreak,
    required List<bool> streakHistory,
    required int streakFreezes,
    required int usedStreakFreezes,
    required List<String> monthlyActiveDates,
    required List<String> frozenStreakDates,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required DateTime selectedMonth,
    required VoidCallback onPrevMonth,
    required VoidCallback onNextMonth,
  }) {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final isTodayCompleted = monthlyActiveDates.contains(todayKey);
    final isNextMonthDisabled = selectedMonth.year > now.year ||
        (selectedMonth.year == now.year && selectedMonth.month >= now.month);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        children: [
          // 1. HERO SPOTLIGHT: Fluid, organic display with breathing aura
          _buildHeroSpotlight(currentStreak, isTodayCompleted, isDark, cardBg, borderColor),
          const SizedBox(height: 16),

          // 2. 7-DAY WEEKLY HORIZON
          _buildWeeklyHorizon(streakHistory, frozenStreakDates, isDark, cardBg, borderColor),
          const SizedBox(height: 16),

          // 3. ASYMMETRICAL BENTO STATS
          Row(
            children: [
              Expanded(
                child: _buildBentoStatCard(
                  icon: Icons.emoji_events_outlined,
                  iconColor: const Color(0xFFD97706),
                  badgeText: 'ব্যক্তিগত রেকর্ড',
                  title: 'সর্বোচ্চ স্ট্রিক',
                  value: '${_toBengaliDigits(longestStreak.toString())} দিন',
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBentoStatCard(
                  icon: Icons.shield_moon_outlined,
                  iconColor: const Color(0xFF0284C7),
                  badgeText: 'সক্রিয় ব্যাকআপ',
                  title: 'স্ট্রিক ফ্রিজ',
                  value: '${_toBengaliDigits(streakFreezes.toString())} টি বাকি',
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. MONTHLY HEATMAP MATRIX
          _buildMonthlyCalendarCard(
            context: context,
            selectedMonth: selectedMonth,
            currentStreak: currentStreak,
            streakHistory: streakHistory,
            monthlyActiveDates: monthlyActiveDates,
            frozenStreakDates: frozenStreakDates,
            isDark: isDark,
            cardBg: cardBg,
            borderColor: borderColor,
            isNextMonthDisabled: isNextMonthDisabled,
            onPrevMonth: onPrevMonth,
            onNextMonth: onNextMonth,
          ),
        ],
      ),
    );
  }

  // --- 1. Hero Spotlight (Master Design) ---
  Widget _buildHeroSpotlight(
    int currentStreak,
    bool isTodayCompleted,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    const brandGreen = Color(0xFF017A47);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Breathing Flame Centerpiece
          const _BreathingFlameWidget(),
          const SizedBox(height: 14),

          // Confident Large Bengali Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: currentStreak),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, val, child) {
                  return Text(
                    _toBengaliDigits(val.toString()),
                    style: TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF111D15),
                      fontFamily: 'Li Ador Noirrit',
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'দিনের স্ট্রিক',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF4A6052),
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Contextual Motivational Status Pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isTodayCompleted
                  ? brandGreen.withValues(alpha: isDark ? 0.2 : 0.1)
                  : (isDark ? const Color(0xFF261D12) : const Color(0xFFFFF7ED)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isTodayCompleted
                    ? brandGreen.withValues(alpha: 0.4)
                    : const Color(0xFFFDBA74).withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTodayCompleted ? Icons.check_circle_rounded : Icons.schedule_rounded,
                  size: 14,
                  color: isTodayCompleted ? brandGreen : const Color(0xFFEA580C),
                ),
                const SizedBox(width: 6),
                Text(
                  isTodayCompleted ? 'আজকের লক্ষ্য সম্পন্ন হয়েছে ✓' : 'আজ অন্তত ১টি পরীক্ষা সম্পন্ন করে স্ট্রিক রাখো',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isTodayCompleted ? brandGreen : const Color(0xFFEA580C),
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. 7-Day Weekly Horizon ---
  Widget _buildWeeklyHorizon(
    List<bool> streakHistory,
    List<String> frozenStreakDates,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    const days = ['শনি', 'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র'];
    final now = DateTime.now();
    final currentDay = now.getDayBanglaIndex();
    const brandGreen = Color(0xFF017A47);
    const freezeCyan = Color(0xFF0284C7);
    final completedCount = streakHistory.where((e) => e).length;
    final saturday = now.subtract(Duration(days: currentDay));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'এই সপ্তাহের ধারাবাহিকতা',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : const Color(0xFF4A6052),
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: brandGreen.withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_toBengaliDigits(completedCount.toString())}/৭ দিন',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: brandGreen,
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isCompleted = index < streakHistory.length && streakHistory[index];
              final isToday = index == currentDay;
              final dayDate = saturday.add(Duration(days: index));
              final yr = dayDate.year;
              final mn = dayDate.month.toString().padLeft(2, '0');
              final dy = dayDate.day.toString().padLeft(2, '0');
              final dateStr = '$yr-$mn-$dy';
              final isFrozen = frozenStreakDates.contains(dateStr);

              return Column(
                children: [
                  Text(
                    days[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                      color: isToday
                          ? brandGreen
                          : (isDark ? Colors.white38 : const Color(0xFF6B7280)),
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? (isFrozen ? freezeCyan : brandGreen)
                          : (isToday
                              ? brandGreen.withValues(alpha: isDark ? 0.18 : 0.1)
                              : (isDark ? const Color(0xFF19231D) : const Color(0xFFF3F6F4))),
                      shape: BoxShape.circle,
                      border: isToday && !isCompleted
                          ? Border.all(color: brandGreen, width: 1.5)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? (isFrozen
                              ? const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 16)
                              : const Icon(Icons.check_rounded, color: Colors.white, size: 18))
                          : (isToday
                              ? Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: brandGreen,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : null),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- 3. Asymmetrical Bento Stat Card ---
  Widget _buildBentoStatCard({
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required String title,
    required String value,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: iconColor, size: 20),
              Text(
                badgeText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Monthly Calendar Card with Pro Design & Uniform Day Tokens ---
  Widget _buildMonthlyCalendarCard({
    required BuildContext context,
    required DateTime selectedMonth,
    required int currentStreak,
    required List<bool> streakHistory,
    required List<String> monthlyActiveDates,
    required List<String> frozenStreakDates,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
    required bool isNextMonthDisabled,
    required VoidCallback onPrevMonth,
    required VoidCallback onNextMonth,
  }) {
    const brandGreen = Color(0xFF017A47);
    const List<String> weekdays = ['শনি', 'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র'];
    final now = DateTime.now();

    final firstDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);
    final totalDays = lastDayOfMonth.day;

    final int startOffset = (firstDayOfMonth.weekday == 6)
        ? 0
        : (firstDayOfMonth.weekday == 7)
            ? 1
            : firstDayOfMonth.weekday + 1;

    final gridCellsCount = totalDays + startOffset;

    // Calculate active days in this specific month
    final monthPrefix = '${selectedMonth.year}-${selectedMonth.month.toString().padLeft(2, '0')}';
    final thisMonthActiveCount = monthlyActiveDates.where((d) => d.startsWith(monthPrefix)).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Month Navigator Row with Subtitle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E2A22) : const Color(0xFFF1F5F2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.chevron_left_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF374151)),
                ),
                onPressed: onPrevMonth,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                child: Column(
                  key: ValueKey('${selectedMonth.year}-${selectedMonth.month}'),
                  children: [
                    Text(
                      _getBengaliMonthYear(selectedMonth),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thisMonthActiveCount > 0
                          ? 'এই মাসে ${_toBengaliDigits(thisMonthActiveCount.toString())} দিন স্ট্রিক সক্রিয়'
                          : 'এই মাসে কোনো স্ট্রিক নেই',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: thisMonthActiveCount > 0 ? brandGreen : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isNextMonthDisabled
                        ? (isDark ? Colors.white10 : Colors.grey.shade100)
                        : (isDark ? const Color(0xFF1E2A22) : const Color(0xFFF1F5F2)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isNextMonthDisabled
                        ? (isDark ? Colors.white12 : Colors.grey.shade300)
                        : (isDark ? Colors.white70 : const Color(0xFF374151)),
                  ),
                ),
                onPressed: isNextMonthDisabled ? null : onNextMonth,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Styled Weekday Header Pill Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A251E) : const Color(0xFFF2F6F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (index) {
                return Expanded(
                  child: Center(
                    child: Text(
                      weekdays[index],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : const Color(0xFF526359),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),

          // Days Grid with Tactile Uniform Tokens
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: GridView.builder(
              key: ValueKey('grid-${selectedMonth.year}-${selectedMonth.month}'),
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

                Widget dayWidget;
                if (isActive) {
                  dayWidget = Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: brandGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _toBengaliDigits(dayNumber.toString()),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.white,
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                  );
                } else if (isFreeze) {
                  dayWidget = Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0284C7), width: 1.2),
                    ),
                    child: Center(
                      child: SvgPicture.string(
                        _checkTicSvg,
                        colorFilter: const ColorFilter.mode(Color(0xFF0284C7), BlendMode.srcIn),
                        width: 16,
                        height: 16,
                      ),
                    ),
                  );
                } else if (isToday) {
                  dayWidget = Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: brandGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: brandGreen, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        _toBengaliDigits(dayNumber.toString()),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: brandGreen,
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                  );
                } else if (!isFuture) {
                  dayWidget = Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF19231D) : const Color(0xFFF3F6F4),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _toBengaliDigits(dayNumber.toString()),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : const Color(0xFF4B5563),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                  );
                } else {
                  dayWidget = SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: Text(
                        _toBengaliDigits(dayNumber.toString()),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white12 : const Color(0xFFD1D5DB),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                  );
                }

                return InkWell(
                  onTap: () => _showDayInfoSheet(
                    context,
                    dayNumber: dayNumber,
                    month: selectedMonth,
                    isActive: isActive,
                    isFreeze: isFreeze,
                    isToday: isToday,
                    isFuture: isFuture,
                    isDark: isDark,
                  ),
                  customBorder: const CircleBorder(),
                  child: Center(child: dayWidget),
                );
              },
            ),
          ),
          const SizedBox(height: 18),

          // Clean Minimal Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDotLegend(brandGreen, 'পরীক্ষা সম্পন্ন', isDark),
              const SizedBox(width: 20),
              _buildDotLegend(const Color(0xFF0284C7), 'স্ট্রিক ফ্রিজ', isDark),
              const SizedBox(width: 20),
              _buildDotLegend(isDark ? const Color(0xFF28362D) : const Color(0xFFE5ECE8), 'ছুটি / বাকি', isDark),
            ],
          ),
        ],
      ),
    );
  }

  void _showDayInfoSheet(
    BuildContext context, {
    required int dayNumber,
    required DateTime month,
    required bool isActive,
    required bool isFreeze,
    required bool isToday,
    required bool isFuture,
    required bool isDark,
  }) {
    final dateFormatted = '${_toBengaliDigits(dayNumber.toString())} ${_getBengaliMonthYear(month)}';
    String message = 'এই দিনে কোনো পরীক্ষা সম্পন্ন করা হয়নি।';
    IconData icon = Icons.info_outline_rounded;
    Color iconColor = Colors.grey;

    if (isActive) {
      message = 'সফলভাবে পরীক্ষা দিয়ে স্ট্রিক সক্রিয় রেখেছ!';
      icon = Icons.local_fire_department_rounded;
      iconColor = const Color(0xFF017A47);
    } else if (isFreeze) {
      message = 'স্ট্রিক ফ্রিজ ব্যবহার করে স্ট্রিক সুরক্ষিত রাখা হয়েছিল।';
      icon = Icons.shield_rounded;
      iconColor = const Color(0xFF0284C7);
    } else if (isToday) {
      message = 'আজ অন্তত ১টি পরীক্ষা সফলভাবে সম্পন্ন করে স্ট্রিক বৃদ্ধি করো!';
      icon = Icons.timer_outlined;
      iconColor = const Color(0xFFEA580C);
    } else if (isFuture) {
      message = 'ভবিষ্যতের দিন। নিয়মিত পড়াশোনায় যুক্ত থাকো!';
      icon = Icons.calendar_today_rounded;
      iconColor = Colors.grey;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: isDark ? const Color(0xFF1E2922) : const Color(0xFF16241C),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateFormatted,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, fontFamily: 'Li Ador Noirrit'),
                  ),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 11.5, color: Colors.white70, fontFamily: 'Li Ador Noirrit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotLegend(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
      ],
    );
  }

  // --- Leaderboard Tab Screen ---
  Widget _buildGlobalTab(
    BuildContext context, {
    required WidgetRef ref,
    required String myUserId,
    required UserProfile? profile,
    required bool isDark,
    required Color cardBg,
    required Color borderColor,
  }) {
    return GlobalStreakLeaderboardView(
      myUserId: myUserId,
      profile: profile,
      isDark: isDark,
      cardBg: cardBg,
      borderColor: borderColor,
    );
  }

  // --- Personal Tab Skeleton Loading View ---
  Widget _buildPersonalTabSkeleton(bool isDark, Color borderColor) {
    final cardBg = isDark ? const Color(0xFF141C17) : Colors.white;
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      child: Column(
        children: [
          // Hero Skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              children: [
                _ShimmerBox(width: 68, height: 68, shape: BoxShape.circle),
                SizedBox(height: 14),
                _ShimmerBox(width: 140, height: 40, borderRadius: 8),
                SizedBox(height: 14),
                _ShimmerBox(width: 180, height: 28, borderRadius: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Weekly Bar Skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ShimmerBox(width: 110, height: 14, borderRadius: 4),
                    _ShimmerBox(width: 50, height: 14, borderRadius: 4),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    7,
                    (index) => const Column(
                      children: [
                        _ShimmerBox(width: 20, height: 10, borderRadius: 3),
                        SizedBox(height: 8),
                        _ShimmerBox(width: 32, height: 32, shape: BoxShape.circle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats Skeleton
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 24, height: 24, borderRadius: 6),
                      SizedBox(height: 10),
                      _ShimmerBox(width: 70, height: 12, borderRadius: 4),
                      SizedBox(height: 6),
                      _ShimmerBox(width: 50, height: 18, borderRadius: 4),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(width: 24, height: 24, borderRadius: 6),
                      SizedBox(height: 10),
                      _ShimmerBox(width: 80, height: 12, borderRadius: 4),
                      SizedBox(height: 6),
                      _ShimmerBox(width: 60, height: 18, borderRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Leaderboard Skeleton Loader Widget ---
Widget _buildLeaderboardSkeleton(bool isDark, Color cardBg, Color borderColor) {
  return SingleChildScrollView(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
    child: Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const _ShimmerBox(width: 38, height: 38, shape: BoxShape.circle),
                const SizedBox(width: 14),
                Expanded(
                  child: _ShimmerBox(
                    width: index % 2 == 0 ? 120 : 90,
                    height: 14,
                    borderRadius: 4,
                  ),
                ),
                const SizedBox(width: 30),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ShimmerBox(width: 20, height: 16, borderRadius: 4),
                    SizedBox(height: 4),
                    _ShimmerBox(width: 44, height: 10, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// --- Smooth Shimmer Box Component ---
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1B261F) : const Color(0xFFE8EFEA);
    final highlightColor = isDark ? const Color(0xFF26382D) : const Color(0xFFF4F9F5);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle ? null : BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                math.max(0.0, _controller.value - 0.3),
                _controller.value,
                math.min(1.0, _controller.value + 0.3),
              ],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
            ),
          ),
        );
      },
    );
  }
}

// --- Breathing Flame Micro-Animation ---
class _BreathingFlameWidget extends StatefulWidget {
  const _BreathingFlameWidget();

  @override
  State<_BreathingFlameWidget> createState() => _BreathingFlameWidgetState();
}

class _BreathingFlameWidgetState extends State<_BreathingFlameWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
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
    const brandGreen = Color(0xFF017A47);

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: brandGreen.withValues(alpha: isDark ? 0.16 : 0.08),
            ),
            child: Center(
              child: SvgPicture.string(
                _heroFlameSvg,
                width: 44,
                height: 44,
                colorFilter: const ColorFilter.mode(brandGreen, BlendMode.srcIn),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Global Streak Leaderboard View ---
class GlobalStreakLeaderboardView extends ConsumerStatefulWidget {
  final String myUserId;
  final UserProfile? profile;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;

  const GlobalStreakLeaderboardView({
    super.key,
    required this.myUserId,
    required this.profile,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  ConsumerState<GlobalStreakLeaderboardView> createState() => _GlobalStreakLeaderboardViewState();
}

class _GlobalStreakLeaderboardViewState extends ConsumerState<GlobalStreakLeaderboardView>
    with AutomaticKeepAliveClientMixin {
  final List<LeaderboardEntryModel> _entries = [];
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  int _offset = 0;
  static const int _limit = 30;
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

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
      final newEntries = await repo.fetchStreakLeaderboard(
        limit: _limit,
        offset: _offset,
        forceRefresh: isInitial,
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
    super.build(context);
    const brandGreen = Color(0xFF017A47);

    if (_isLoadingInitial) {
      return _buildLeaderboardSkeleton(widget.isDark, widget.cardBg, widget.borderColor);
    }

    if (_errorMessage != null && _entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'তথ্য লোড করতে ত্রুটি ঘটেছে',
                style: TextStyle(
                  fontFamily: 'Li Ador Noirrit',
                  color: widget.isDark ? Colors.white70 : Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _fetchPage(isInitial: true),
                style: TextButton.styleFrom(
                  backgroundColor: brandGreen.withValues(alpha: 0.1),
                  foregroundColor: brandGreen,
                ),
                child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(fontFamily: 'Li Ador Noirrit')),
              ),
            ],
          ),
        ),
      );
    }

    final sortedList = _entries.map((entry) {
      final isMe = entry.userId == widget.myUserId;
      final streakCount = isMe
          ? (widget.profile?.currentStreak ?? entry.currentStreak)
          : entry.currentStreak;
      return MapEntry(entry, streakCount);
    }).toList();

    sortedList.sort((a, b) => b.value.compareTo(a.value));

    final reRanked = List<MapEntry<LeaderboardEntryModel, int>>.generate(sortedList.length, (idx) {
      final entry = sortedList[idx].key;
      final streakVal = sortedList[idx].value;
      final updatedEntry = LeaderboardEntryModel(
        rank: idx + 1,
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
          'লিডারবোর্ডে কেউ নেই',
          style: TextStyle(fontFamily: 'Li Ador Noirrit'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchPage(isInitial: true),
      color: brandGreen,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.borderColor, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Text(
                  'গ্লোবাল স্ট্রিক লিডারবোর্ড',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: widget.isDark ? Colors.white : const Color(0xFF111827),
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
              ),

              // Rows
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reRanked.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == reRanked.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(
                        child: CircularProgressIndicator(color: brandGreen, strokeWidth: 2),
                      ),
                    );
                  }

                  final entry = reRanked[index].key;
                  final rank = entry.rank;
                  final name = entry.fullName.isNotEmpty ? entry.fullName : entry.username;
                  final streakCount = reRanked[index].value;
                  final isMe = entry.userId == widget.myUserId;
                  final initials = _getInitials(name);
                  final avatarColor = _getAvatarColor(entry.userId.isNotEmpty ? entry.userId : name);

                  return Container(
                    color: isMe
                        ? brandGreen.withValues(alpha: widget.isDark ? 0.12 : 0.06)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        // Round Avatar
                        if (entry.avatarKey != null && entry.avatarKey!.isNotEmpty)
                          CustomAvatar(
                            avatarUrl: entry.avatarKey!,
                            radius: 19,
                            backgroundColor: avatarColor,
                            fallbackWidget: Text(
                              initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: avatarColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(width: 14),

                        // User Name
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isMe ? FontWeight.w800 : FontWeight.w700,
                              fontSize: 14,
                              color: widget.isDark ? Colors.white : const Color(0xFF111827),
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Rank Number & Streak Days (Aligned Right, matching Screenshot)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rank.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: rank == 1
                                    ? const Color(0xFFD97706)
                                    : (widget.isDark ? Colors.white : const Color(0xFF111827)),
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${_toBengaliDigits(streakCount.toString())} দিন',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: widget.isDark ? Colors.white54 : const Color(0xFF6B7280),
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to map DateTime to Saturday-first index (0 = Sat, 6 = Fri)
extension _DateTimeExt on DateTime {
  int getDayBanglaIndex() {
    if (weekday == 6) return 0; // Saturday
    if (weekday == 7) return 1; // Sunday
    return weekday + 1; // Mon=2, Tue=3, Wed=4, Thu=5, Fri=6
  }
}
