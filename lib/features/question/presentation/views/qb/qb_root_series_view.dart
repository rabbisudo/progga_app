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

                if (subSeriesList.isNotEmpty) {
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
                    context.push('/qb-exams/${firstSeries['id']}', extra: subjectName);
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  child: Row(
                    children: [
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitleText,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black45,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Right Chevron Arrow
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 100),
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
}
