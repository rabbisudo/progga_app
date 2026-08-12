 import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../academics/data/academics_repository.dart';
import '../../../profile/presentation/profile_notifier.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/bouncing_card.dart';
import 'qb/qb_helpers.dart';

class QuestionBankView extends ConsumerWidget {
  const QuestionBankView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value?.profile;
    if (profile == null || profile.classId == null || profile.classId!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'প্রোফাইলে কোনো ক্লাস সিলেক্ট করা নেই। অনুগ্রহ করে প্রোফাইল আপডেট করুন।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      );
    }

    final classId = profile.classId!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _buildDynamicTabbedSections(context, ref, classId, isDark, theme);
  }

  Widget _buildDynamicTabbedSections(
    BuildContext context,
    WidgetRef ref,
    String classId,
    bool isDark,
    ThemeData theme,
  ) {
    final sectionsAsync = ref.watch(qbClassSectionsProvider(classId));

    return sectionsAsync.when(
      data: (sectionsList) {
        if (sectionsList.isEmpty) {
          return const EmptyStateWidget(
            title: 'কোনো প্রশ্নব্যাংক পাওয়া যায়নি',
            subtitle: 'আপনার সিলেক্ট করা ক্লাসের জন্য কোনো প্রশ্নব্যাংক পাওয়া যায়নি। অনুগ্রহ করে অন্য কোনো ক্লাস সিলেক্ট করে দেখুন।',
          );
        }

        return DefaultTabController(
          length: sectionsList.length,
          child: Column(
            children: [
              // Premium Dynamic Subject TabBar (Balanced size)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                color: theme.scaffoldBackgroundColor,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    isScrollable: sectionsList.length > 3,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: const Color(0xFF017A47),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF017A47).withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 1.5),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.white38 : Colors.black54,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Li Ador Noirrit',
                    ),
                    tabs: sectionsList.map((sec) {
                      final name = (sec as Map<String, dynamic>)['name']?.toString() ?? '';
                      return Tab(
                        height: 38,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(name, textAlign: TextAlign.center),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // TabBarView displaying corresponding series
              Expanded(
                child: TabBarView(
                  children: sectionsList.map((sec) {
                    final sectionMap = sec as Map<String, dynamic>;
                    final seriesList = (sectionMap['series'] as List<dynamic>?) ?? [];
                    return _buildSeriesList(context, ref, seriesList, isDark);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildSubjectListSkeleton(),
      error: (err, _) => _buildErrorWidget('ডাটা লোড করা যায়নি: $err'),
    );
  }

  Widget _buildSeriesList(BuildContext context, WidgetRef ref, List<dynamic> seriesList, bool isDark) {
    if (seriesList.isEmpty) {
      return const EmptyStateWidget(
        title: 'কোনো সিরিজ পাওয়া যায়নি',
        subtitle: 'এই বিভাগের অধীনে কোনো প্রশ্নব্যাংক সিরিজ সচল নেই।',
        icon: Icons.layers_clear_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0, bottom: 100.0),
      itemCount: seriesList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final seriesMap = seriesList[index] as Map<String, dynamic>;
        final name = seriesMap['name']?.toString() ?? '';
        final idStr = seriesMap['id']?.toString() ?? '';
        final subSeriesCount = (seriesMap['subSeries'] as List<dynamic>?)?.length ?? 0;

        void handleNavigation() {
          if (subSeriesCount > 0) {
            final subSeriesList = (seriesMap['subSeries'] as List<dynamic>?) ?? [];
            showQbSubSeriesBottomSheet(
              context: context,
              ref: ref,
              title: name,
              subSeries: subSeriesList,
              isDark: isDark,
            );
          } else {
            final resolvedList = (seriesMap['examsResolvedList'] as List<dynamic>?) ?? [];
            if (resolvedList.length == 1) {
              context.push('/exam-preview/${resolvedList.first}', extra: name);
            } else {
              context.push('/qb-exams/$idStr', extra: name);
            }
          }
        }

        int itemsCount = subSeriesCount;
        if (itemsCount == 0) {
          final labelNameMap = Map<String, dynamic>.from(seriesMap['labelName'] as Map? ?? {});
          if (labelNameMap.isNotEmpty) {
            for (final val in labelNameMap.values) {
              if (val is List) itemsCount += val.length;
            }
          }
        }
        if (itemsCount == 0) {
          final examsStr = seriesMap['exams']?.toString() ?? '';
          if (examsStr.isNotEmpty) {
            itemsCount = examsStr.split(',').where((x) => x.trim().isNotEmpty).length;
          }
        }

        String subtitleText = 'অনুশীলন শুরু করুন';
        if (subSeriesCount > 0) {
          subtitleText = '${toBengaliDigits(subSeriesCount.toString())}টি অধ্যায় বা ক্যাটাগরি';
        } else if (itemsCount > 0) {
          subtitleText = '${toBengaliDigits(itemsCount.toString())}টি পরীক্ষা রয়েছে';
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
                        name,
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
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.red),
        ),
      ),
    );
  }



  Widget _buildSubjectListSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const ShimmerSkeleton(
        width: double.infinity,
        height: 80,
        borderRadius: 20,
      ),
    );
  }
}
