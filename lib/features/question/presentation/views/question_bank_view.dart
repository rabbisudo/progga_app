import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    final classId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.classId));
    if (classId == null || classId.isEmpty) {
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
                // padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.shade300,
                      width: 1.2,
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: TabBar(
                    isScrollable: sectionsList.length > 3,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    overlayColor: WidgetStateProperty.all(Colors.transparent),
                    indicator: BoxDecoration(
                      color: const Color(0xFF017A47),
                      borderRadius: BorderRadius.circular(22),
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
      loading: () => _buildSubjectListSkeleton(context),
      error: (err, _) => _buildErrorWidget('ডাটা লোড করা যায়নি: $err'),
    );
  }

  Widget _buildSeriesList(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> seriesList,
    bool isDark,
  ) {
    if (seriesList.isEmpty) {
      return const EmptyStateWidget(
        title: 'কোনো সিরিজ পাওয়া যায়নি',
        subtitle: 'এই বিভাগের অধীনে কোনো প্রশ্নব্যাংক সিরিজ সচল নেই।',
        icon: Icons.layers_clear_rounded,
      );
    }

    // Precache first few images for instant, 120fps stutter-free scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final count = seriesList.length > 8 ? 8 : seriesList.length;
      for (int i = 0; i < count; i++) {
        final sMap = seriesList[i] as Map<String, dynamic>;
        final imgUrl = resolveSeriesImageUrl(sMap);
        if (imgUrl != null && imgUrl.isNotEmpty) {
          precacheImage(
            CachedNetworkImageProvider(
              imgUrl,
              maxHeight: 360,
              maxWidth: 360,
            ),
            context,
          );
        }
      }
    });

    final bottomPadding = getFloatingBottomBarPadding(context, extraClearance: 16.0);

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      cacheExtent: 600,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 14.0, bottom: bottomPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemCount: seriesList.length,
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

        return RepaintBoundary(
          child: BouncingCard(
            onTap: handleNavigation,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: QbThumbnailWidget(
                seriesMap: seriesMap,
                index: index,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 22,
                hasBorder: false,
                hasShadow: false,
                memCacheSize: 360,
              ),
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

  Widget _buildSubjectListSkeleton(BuildContext context) {
    final bottomPadding = getFloatingBottomBarPadding(context, extraClearance: 16.0);

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.0, 14.0, 16.0, bottomPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.0,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => const ShimmerSkeleton(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 22,
      ),
    );
  }
}
