import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../academics/data/academics_repository.dart';
import '../../../../profile/presentation/profile_notifier.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../widgets/shimmer_skeleton.dart';
import '../../widgets/bouncing_card.dart';
import 'qb_helpers.dart';

class QbExamsListScreen extends ConsumerStatefulWidget {
  final String subSeriesId;
  final String? subSeriesName;

  const QbExamsListScreen({
    super.key,
    required this.subSeriesId,
    this.subSeriesName,
  });

  @override
  ConsumerState<QbExamsListScreen> createState() => _QbExamsListScreenState();
}

class _QbExamsListScreenState extends ConsumerState<QbExamsListScreen> {
  String _activeTab = 'সব';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final classId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.classId));
    if (classId == null || classId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(color: Color(0xFF017A47)),
          title: Text(widget.subSeriesName ?? 'পরীক্ষাসমূহ'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('প্রোফাইলে কোনো ক্লাস সিলেক্ট করা নেই।'),
        ),
      );
    }

    final seriesAsync = ref.watch(qbClassSeriesProvider(classId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(color: Color(0xFF017A47)),
        title: Text(
          widget.subSeriesName ?? 'পরীক্ষাসমূহ',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: seriesAsync.when(
        data: (seriesList) {
          final activeSeries = findSeriesRecursively(seriesList, widget.subSeriesId);

          if (activeSeries == null) {
            return const Center(child: Text('পরীক্ষা সিরিজ পাওয়া যায়নি।'));
          }

          var labelNameMap = Map<String, dynamic>.from(activeSeries['labelName'] as Map? ?? {});
          if (labelNameMap.isEmpty && activeSeries['exams'] != null) {
            final examsVal = activeSeries['exams'];
            if (examsVal is String && examsVal.isNotEmpty) {
              labelNameMap = {
                'Exams': examsVal.split(','),
              };
            } else if (examsVal is List && examsVal.isNotEmpty) {
              labelNameMap = {
                'Exams': examsVal.map((e) => e.toString()).toList(),
              };
            }
          }

          if (labelNameMap.isEmpty) {
            return const Center(
              child: Text(
                'কোনো পরীক্ষা পাওয়া যায়নি।',
                style: TextStyle(color: Colors.black54),
              ),
            );
          }

          final tabKeys = labelNameMap.keys.toList();
          final displayTabs = ['সব', ...tabKeys];
          final hasMultipleLevels = tabKeys.length > 1;

          // Adjust active tab if it's no longer valid
          if (!displayTabs.contains(_activeTab)) {
            _activeTab = 'সব';
          }

          final List<String> idsToLoad;
          if (hasMultipleLevels) {
            if (_activeTab == 'সব') {
              idsToLoad = tabKeys
                  .expand((k) => List<String>.from(labelNameMap[k] ?? []))
                  .toSet()
                  .toList();
            } else {
              idsToLoad = List<String>.from(labelNameMap[_activeTab] ?? []);
            }
          } else {
            idsToLoad = List<String>.from(labelNameMap[tabKeys.first] ?? []);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (hasMultipleLevels) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                        fontFamily: 'Li Ador Noirrit',
                      ),
                      decoration: InputDecoration(
                        hintText: 'পরীক্ষা খুঁজে বের করো...',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontFamily: 'Li Ador Noirrit'),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF017A47), width: 1.5),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F5),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: displayTabs.map<Widget>((key) {
                      final isSelected = _activeTab == key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _activeTab = key;
                              _searchQuery = '';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF017A47)
                                  : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F5)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF017A47)
                                    : Colors.transparent,
                                width: 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF017A47).withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                key,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                  fontFamily: 'Li Ador Noirrit',
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final examsAsync = ref.watch(qbExamsProvider(idsToLoad.join(',')));
                    return examsAsync.when(
                      data: (examsList) {
                        if (examsList.length == 1) {
                          final ex = examsList.first as Map<String, dynamic>;
                          final examId = ex['id']?.toString() ?? '';
                          final title = ex['title']?.toString() ?? '';
                          final cleanTitle = _getCleanTitle(title);
                          if (examId.isNotEmpty) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              context.pushReplacement('/exam-preview/$examId', extra: cleanTitle);
                            });
                          }
                          return _buildSkeleton(context, isDark, showSearchAndTabs: false);
                        }

                        var filteredList = examsList;
                        if (hasMultipleLevels && _searchQuery.isNotEmpty) {
                          filteredList = examsList.where((ex) {
                            final title = ex['title']?.toString() ?? '';
                            return title.toLowerCase().contains(_searchQuery.toLowerCase());
                          }).toList();
                        }

                        final sortedList = List<Map<String, dynamic>>.from(
                          filteredList.map((e) => Map<String, dynamic>.from(e as Map)),
                        );
                        sortedList.sort((a, b) {
                          final yearA = _getExamYear(a);
                          final yearB = _getExamYear(b);
                          if (yearA != yearB) {
                            return yearB.compareTo(yearA); // Descending
                          }
                          final titleA = a['title']?.toString() ?? '';
                          final titleB = b['title']?.toString() ?? '';
                          return titleA.compareTo(titleB);
                        });

                        if (sortedList.isEmpty) {
                          return const Center(child: Text('কোনো পরীক্ষা পাওয়া যায়নি।'));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: sortedList.length,
                          itemBuilder: (context, idx) {
                            final ex = sortedList[idx];
                            final title = _getCleanTitle(ex['title']?.toString() ?? '');
                            final duration = ex['duration'] as int? ?? 1500;
                            final durationMin = (duration / 60).round();
                            final qCount = ex['qCount'] as int? ?? 25;

                            final createdAt = ex['createdAt'];
                            final dateStr = getExamDateStr(createdAt, title);

                            return BouncingCard(
                              onTap: () {
                                _showExamConfirmSheet(context, ex);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          height: 1.35,
                                          color: isDark ? Colors.white : const Color(0xFF212529),
                                          fontFamily: 'Li Ador Noirrit',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        alignment: WrapAlignment.start,
                                        children: [
                                          // Time Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF3D1616) : const Color(0xFFFFF5F5),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: isDark ? const Color(0xFF731D1D) : const Color(0xFFFFE3E3), width: 1),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.timer_outlined,
                                                  size: 13,
                                                  color: isDark ? const Color(0xFFF87171) : const Color(0xFFE03131),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${toBengaliDigits(durationMin.toString())} মিনিট',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A),
                                                    fontFamily: 'Li Ador Noirrit',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Questions Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF00381C) : const Color(0xFFE6FCF5),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFC3FAE8), width: 1),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.edit_note_outlined,
                                                  size: 14,
                                                  color: isDark ? const Color(0xFF00C569) : const Color(0xFF099268),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${toBengaliDigits(qCount.toString())}টি প্রশ্ন',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? const Color(0xFF00C569) : const Color(0xFF087F5B),
                                                    fontFamily: 'Li Ador Noirrit',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Date Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0xFF1E2B5C) : const Color(0xFFEDF2FF),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: isDark ? const Color(0xFF2D3B73) : const Color(0xFFDBE4FF), width: 1),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.calendar_month_outlined,
                                                  size: 13,
                                                  color: isDark ? const Color(0xFF8DA2FB) : const Color(0xFF364FC7),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  dateStr,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? const Color(0xFF8DA2FB) : const Color(0xFF2B4C7E),
                                                    fontFamily: 'Li Ador Noirrit',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => _buildSkeleton(context, isDark, showSearchAndTabs: false),
                      error: (err, _) => Center(child: Text('পরীক্ষা লোড করতে ব্যর্থ হয়েছে: $err')),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => _buildSkeleton(context, isDark, showSearchAndTabs: true),
        error: (err, _) => Center(child: Text('ডাটা লোড করা যায়নি: $err')),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context, bool isDark, {bool showSearchAndTabs = false}) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSearchAndTabs) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ShimmerSkeleton(
                width: MediaQuery.of(context).size.width - 32,
                height: 44,
                borderRadius: 12,
              ),
            ),
            Container(
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: const [
                  ShimmerSkeleton(width: 55, height: 38, borderRadius: 12),
                  SizedBox(width: 8),
                  ShimmerSkeleton(width: 70, height: 38, borderRadius: 12),
                  SizedBox(width: 8),
                  ShimmerSkeleton(width: 60, height: 38, borderRadius: 12),
                  SizedBox(width: 8),
                  ShimmerSkeleton(width: 65, height: 38, borderRadius: 12),
                ],
              ),
            ),
          ],
          ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerSkeleton(
                      width: 180,
                      height: 16,
                      borderRadius: 4,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFFFF5F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const ShimmerSkeleton(width: 50, height: 11, borderRadius: 3),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFE6FCF5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const ShimmerSkeleton(width: 50, height: 11, borderRadius: 3),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFEDF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const ShimmerSkeleton(width: 65, height: 11, borderRadius: 3),
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
    );
  }

  String _getCleanTitle(String title) {
    if (title.trim().isEmpty || title.toLowerCase().contains('undefined')) {
      return widget.subSeriesName ?? 'কোয়েশ্চেন ব্যাংক প্র্যাকটিস';
    }
    return title;
  }

  void _showExamConfirmSheet(BuildContext context, Map<String, dynamic> ex) {
    final title = _getCleanTitle(ex['title']?.toString() ?? '');
    final duration = ex['duration'] as int? ?? 1500;
    final durationMin = (duration / 60).round();
    final qCount = ex['qCount'] as int? ?? 25;
    final examId = ex['id'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 10.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${toBengaliDigits(durationMin.toString())} মিনিট',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1.5,
                        height: 24,
                        color: borderColor,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: isDark ? const Color(0xFF00C569) : const Color(0xFF2B8A3E),
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${toBengaliDigits(qCount.toString())}টি প্রশ্ন',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/exam/$examId');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF017A47),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'পরীক্ষা শুরু করো',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/exam-preview/$examId', extra: title);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF00C569) : const Color(0xFF017A47),
                    side: BorderSide(color: isDark ? const Color(0xFF00C569) : const Color(0xFF017A47), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFECEFF1).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text(
                    'প্রশ্ন দেখো',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int _extractYearFromTitle(String title) {
    // 1. Check for range of Bengali years (e.g. '২৪-২৫')
    final RegExp bnRangeRegExp = RegExp(r'([০-৯]{2})-[০-৯]{2}');
    final bnRangeMatch = bnRangeRegExp.firstMatch(title);
    if (bnRangeMatch != null) {
      final bnYearStr = bnRangeMatch.group(1)!;
      final englishDigits = bnYearStr.split('').map((char) {
        const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
        return bnDigits.indexOf(char).toString();
      }).join();
      final shortYear = int.tryParse(englishDigits) ?? 0;
      if (shortYear > 0) return 2000 + shortYear;
    }

    // 2. Check for range of English years (e.g. '24-25')
    final RegExp enRangeRegExp = RegExp(r'\b(\d{2})-(\d{2})\b');
    final enRangeMatch = enRangeRegExp.firstMatch(title);
    if (enRangeMatch != null) {
      final shortYear = int.tryParse(enRangeMatch.group(1)!) ?? 0;
      if (shortYear > 0) return 2000 + shortYear;
    }

    // 3. Check for 4-digit Bengali years (e.g. '২০২৬')
    final RegExp bnYearRegExp = RegExp(r'[০-৯]{4}');
    final bnMatch = bnYearRegExp.firstMatch(title);
    if (bnMatch != null) {
      final bnYearStr = bnMatch.group(0)!;
      final englishDigits = bnYearStr.split('').map((char) {
        const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
        return bnDigits.indexOf(char).toString();
      }).join();
      return int.tryParse(englishDigits) ?? 0;
    }

    // 4. Check for 4-digit English years (e.g. '2026')
    final RegExp enYearRegExp = RegExp(r'\b(20\d{2})\b');
    final enMatch = enYearRegExp.firstMatch(title);
    if (enMatch != null) {
      return int.tryParse(enMatch.group(0)!) ?? 0;
    }

    return 0;
  }

  int _getExamYear(Map<String, dynamic> ex) {
    final title = ex['title']?.toString() ?? '';
    final yearFromTitle = _extractYearFromTitle(title);
    if (yearFromTitle > 0) {
      return yearFromTitle;
    }
    
    final createdAtVal = ex['createdAt'];
    if (createdAtVal != null) {
      try {
        return DateTime.parse(createdAtVal.toString()).year;
      } catch (_) {}
    }
    
    return 0;
  }
}
