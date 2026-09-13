import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/bouncing_card.dart';
import 'qb_helpers.dart';

class QbRootSeriesView extends ConsumerWidget {
  final List<dynamic> seriesList;

  const QbRootSeriesView({
    super.key,
    required this.seriesList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subSeriesIds = seriesList
        .expand((s) => (s['subSeries'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .toSet();

    final rootSeriesList = seriesList.where((s) {
      final id = s['id']?.toString() ?? '';
      return !subSeriesIds.contains(id);
    }).toList();

    final Map<String, List<Map<String, dynamic>>> groupedBySubject = {};
    for (final s in rootSeriesList) {
      if (s is Map<String, dynamic>) {
        final rawSubId = s['subjectId']?.toString();
        // If subjectId is set → group by subject; otherwise each series gets its own card
        final groupKey = (rawSubId != null && rawSubId.isNotEmpty)
            ? rawSubId
            : 'series_${s['id']}'; // unique key per series
        groupedBySubject.putIfAbsent(groupKey, () => []).add(s);
      }
    }

    final sortedSubjectIds = groupedBySubject.keys.toList()
      ..sort((a, b) {
        final subA = groupedBySubject[a]!.first['subject'] as Map<String, dynamic>?;
        final subB = groupedBySubject[b]!.first['subject'] as Map<String, dynamic>?;
        final orderA = subA?['sortOrder'] as int? ?? 100;
        final orderB = subB?['sortOrder'] as int? ?? 100;
        if (orderA != orderB) return orderA.compareTo(orderB);
        // Fallback: sort by series name
        final nameA = groupedBySubject[a]!.first['name']?.toString() ?? '';
        final nameB = groupedBySubject[b]!.first['name']?.toString() ?? '';
        return nameA.compareTo(nameB);
      });

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            itemCount: sortedSubjectIds.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final subjectId = sortedSubjectIds[index];
              final subjectSeries = groupedBySubject[subjectId]!;
              final firstSeries = subjectSeries.first;
              final subjectObj = firstSeries['subject'] as Map<String, dynamic>?;
              final subjectName = subjectObj?['name']?.toString() ?? firstSeries['name']?.toString() ?? 'অন্যান্য';
              final subjectIcon = subjectObj?['icon']?.toString() ?? '📚';
              final count = _getCategoryCount(firstSeries);

              void handleNavigation() {
                final subSeriesList = (firstSeries['subSeries'] as List<dynamic>?) ?? [];
                final idStr = firstSeries['id']?.toString() ?? '';
                final nameLower = subjectName.toLowerCase();
                final isK = nameLower.contains('kbhandar') || nameLower.contains('ক ভাণ্ডার');
                final isKh = nameLower.contains('khabhandar') || nameLower.contains('খ ভাণ্ডার');

                if (isK || isKh) {
                  context.push('/exam-preview/$idStr', extra: subjectName);
                } else if (subSeriesList.isNotEmpty) {
                  showQbSubSeriesBottomSheet(
                    context: context,
                    ref: ref,
                    title: subjectName,
                    subSeries: subSeriesList,
                    isDark: isDark,
                  );
                } else {
                  final resolvedList = (firstSeries['examsResolvedList'] as List<dynamic>?) ?? [];
                  if (resolvedList.length == 1) {
                    context.push('/exam-preview/${resolvedList.first}', extra: subjectName);
                  } else {
                    context.push('/qb-exams/$idStr', extra: subjectName);
                  }
                }
              }

              final subSeriesListIds = (firstSeries['subSeries'] as List<dynamic>?) ?? [];
              String subtitleText = 'অনুশীলন শুরু করুন';
              if (subSeriesListIds.isNotEmpty) {
                subtitleText = '${toBengaliDigits(subSeriesListIds.length.toString())}টি অধ্যায় বা ক্যাটাগরি';
              } else if (count > 0) {
                subtitleText = '${toBengaliDigits(count.toString())}টি পরীক্ষা রয়েছে';
              }

              return BouncingCard(
                onTap: handleNavigation,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                      width: 1,
                    ),
                    boxShadow: isDark
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.025),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
                  child: Row(
                    children: [
                      // Leading Thumbnail
                      QbThumbnailWidget(
                        seriesMap: firstSeries,
                        index: index,
                        size: 50,
                        borderRadius: 16,
                      ),
                      const SizedBox(width: 14),
                      // Middle Title & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subjectName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Styled info badge
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: subSeriesListIds.isNotEmpty
                                        ? const Color(0xFF0071F9).withOpacity(isDark ? 0.16 : 0.08)
                                        : const Color(0xFF1E88E5).withOpacity(isDark ? 0.16 : 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    subtitleText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: subSeriesListIds.isNotEmpty
                                          ? const Color(0xFF02A25F)
                                          : const Color(0xFF1E88E5),
                                      fontFamily: 'Li Ador Noirrit',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Right Chevron Arrow with circular plate
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white30 : Colors.grey.shade400,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: getFloatingBottomBarPadding(context, extraClearance: 16.0)),
        ],
      ),
    );
  }

  int _getCategoryCount(Map<String, dynamic> series) {
    final subSeriesList = (series['subSeries'] as List<dynamic>?) ?? [];
    if (subSeriesList.isNotEmpty) {
      return subSeriesList.length;
    }
    final labelNameMap = Map<String, dynamic>.from(series['labelName'] as Map? ?? {});
    if (labelNameMap.isNotEmpty) {
      int count = 0;
      for (final val in labelNameMap.values) {
        if (val is List) count += val.length;
      }
      if (count > 0) return count;
    }
    final examsStr = series['exams']?.toString() ?? '';
    if (examsStr.isNotEmpty) {
      return examsStr.split(',').where((x) => x.trim().isNotEmpty).length;
    }
    return 0;
  }

  LinearGradient _getLeftIconGradient(int index, bool isDark) {
    final gradients = [
      [const Color(0xFF00B09B), const Color(0xFF96C93D)],
      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
      [const Color(0xFFF12711), const Color(0xFFF5AF19)],
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFFF857A6), const Color(0xFFFF5858)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    ];
    final selected = gradients[index % gradients.length];
    return LinearGradient(
      colors: selected.map((c) => isDark ? c.withOpacity(0.85) : c).toList(),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getLeftIcon(int index) {
    final icons = [
      Icons.menu_book_rounded,
      Icons.school_rounded,
      Icons.emoji_events_rounded,
      Icons.workspace_premium_rounded,
      Icons.assignment_rounded,
      Icons.auto_stories_rounded,
    ];
    return icons[index % icons.length];
  }
}
