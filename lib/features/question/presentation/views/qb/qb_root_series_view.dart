import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/bouncing_card.dart';
import 'qb_helpers.dart';

class QbRootSeriesView extends StatelessWidget {
  final List<dynamic> seriesList;

  const QbRootSeriesView({
    super.key,
    required this.seriesList,
  });

  @override
  Widget build(BuildContext context) {
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
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: sortedSubjectIds.length,
            itemBuilder: (context, index) {
              final subjectId = sortedSubjectIds[index];
              final subjectSeries = groupedBySubject[subjectId]!;
              final firstSeries = subjectSeries.first;
              final subjectObj = firstSeries['subject'] as Map<String, dynamic>?;
              final subjectName = subjectObj?['name']?.toString() ?? firstSeries['name']?.toString() ?? 'অন্যান্য';
              final subjectIcon = subjectObj?['icon']?.toString();
              final imageUrl = firstSeries['logo']?.toString() ?? firstSeries['banner']?.toString() ?? subjectObj?['imageUrl']?.toString() ?? '';
              final count = _getCategoryCount(firstSeries);

              return BouncingCard(
                onTap: () {
                  final subSeriesListIds = (firstSeries['subSeries'] as List<dynamic>?) ?? [];
                  final validSubSeries = subSeriesListIds.map((subId) {
                    return seriesList.firstWhere(
                      (s) => s['id']?.toString() == subId.toString(),
                      orElse: () => null,
                    );
                  }).where((s) => s != null).toList();

                  if (validSubSeries.isNotEmpty) {
                    context.push('/qb-sub-series/${firstSeries['id']}', extra: subjectName);
                  } else {
                    context.push('/qb-exams/${firstSeries['id']}', extra: subjectName);
                  }
                },
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                            if (wasSynchronouslyLoaded) return child;
                            return AnimatedOpacity(
                              opacity: frame == null ? 0 : 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              child: child,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade50,
                              child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF017A47),
                                    ),
                                  ),
                                ),
                            );
                          },
                          errorBuilder: (context, _, __) => Container(
                            decoration: BoxDecoration(
                              gradient: _getSubjectGradient(subjectName),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: _getSubjectGradient(subjectName),
                          ),
                        ),

                      if (imageUrl.isEmpty)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: _buildSubjectTitle(subjectName),
                        ),
                      if (imageUrl.isEmpty)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Text(
                            subjectIcon ?? '📚',
                            style: const TextStyle(fontSize: 48),
                          ),
                        ),

                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: isDark ? Colors.white70 : const Color(0xFF495057),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                toBengaliDigits('$count'),
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF212529),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  LinearGradient _getSubjectGradient(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('পদার্থ') || name.contains('physics')) {
      return const LinearGradient(
        colors: [Color(0xFF001F4D), Color(0xFF004080)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('উচ্চতর') || name.contains('higher')) {
      return const LinearGradient(
        colors: [Color(0xFF4D2600), Color(0xFF804000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('জীববিজ্ঞান') || name.contains('biology')) {
      return const LinearGradient(
        colors: [Color(0xFF330033), Color(0xFF660066)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('রসায়ন') || name.contains('chemistry')) {
      return const LinearGradient(
        colors: [Color(0xFF1F003D), Color(0xFF400080)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('গণিত') || name.contains('math')) {
      return const LinearGradient(
        colors: [Color(0xFF4D3D00), Color(0xFF806600)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('ইংরেজী') || name.contains('english')) {
      return const LinearGradient(
        colors: [Color(0xFF4D0000), Color(0xFF800000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF003D24), Color(0xFF00804C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildSubjectTitle(String title) {
    List<String> parts = [];
    if (title.contains('ইংরেজী ১ম')) {
      parts = ['ইংরেজী', '১ম পত্র'];
    } else if (title.contains('ইংরেজী ২য়')) {
      parts = ['ইংরেজী', '২য় পত্র'];
    } else if (title.contains('English 1st')) {
      parts = ['English', '1st Paper'];
    } else if (title.contains('English 2nd')) {
      parts = ['English', '2nd Paper'];
    } else if (title.contains('বাংলা ১ম')) {
      parts = ['বাংলা', '১ম পত্র'];
    } else if (title.contains('বাংলা ২য়')) {
      parts = ['বাংলা', '২য় পত্র'];
    } else {
      parts = [title];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) => Text(
        part,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Li Ador Noirrit',
          height: 1.15,
        ),
      )).toList(),
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
