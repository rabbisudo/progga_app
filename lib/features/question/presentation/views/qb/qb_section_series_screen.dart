import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../academics/data/academics_repository.dart';
import '../../../../profile/presentation/profile_notifier.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../widgets/bouncing_card.dart';
import '../../widgets/shimmer_skeleton.dart';
import 'qb_helpers.dart';

class QbSectionSeriesScreen extends ConsumerWidget {
  final String sectionId;
  final String? sectionName;

  const QbSectionSeriesScreen({
    super.key,
    required this.sectionId,
    this.sectionName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final classId = ref.watch(userProfileProvider.select((u) => u.value?.profile?.classId));
    if (classId == null || classId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(color: Color(0xFF017A47)),
          title: Text(sectionName ?? 'প্রশ্নব্যাংক'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('প্রোফাইলে কোনো ক্লাস সিলেক্ট করা নেই।'),
        ),
      );
    }

    final sectionsAsync = ref.watch(qbClassSectionsProvider(classId));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(color: Color(0xFF017A47)),
        title: Text(
          sectionName ?? 'প্রশ্নব্যাংক',
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
      body: sectionsAsync.when(
        data: (sectionsList) {
          final activeSection = sectionsList.firstWhere(
            (s) => s['id']?.toString() == sectionId,
            orElse: () => null,
          );

          if (activeSection == null) {
            return const Center(child: Text('ম্যাপিং পাওয়া যায়নি।'));
          }

          final seriesList = (activeSection['series'] as List<dynamic>?) ?? [];
          if (seriesList.isEmpty) {
            return const Center(child: Text('কোনো সিরিজ পাওয়া যায়নি।'));
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

            final bottomInset = MediaQuery.of(context).padding.bottom;
            final bottomPadding = bottomInset > 0 ? bottomInset + 20.0 : 28.0;

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
                final nameLower = name.toLowerCase();
                final isK = nameLower.contains('kbhandar') || nameLower.contains('ক ভাণ্ডার');
                final isKh = nameLower.contains('khabhandar') || nameLower.contains('খ ভাণ্ডার');
                if (isK || isKh) {
                  context.push('/exam-preview/$idStr', extra: name);
                } else if (subSeriesCount > 0) {
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

              return _SeriesListTile(
                index: index,
                seriesMap: seriesMap,
                onTap: handleNavigation,
                isDark: isDark,
              );
            },
          );
        },
        loading: () => _buildListSkeleton(context),
        error: (err, _) => Center(child: Text('ত্রুটি: $err')),
      ),
    );
  }

  Widget _buildListSkeleton(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final bottomPadding = bottomInset > 0 ? bottomInset + 20.0 : 28.0;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 14.0, bottom: bottomPadding),
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

class _SeriesListTile extends StatelessWidget {
  final int index;
  final Map<String, dynamic> seriesMap;
  final VoidCallback onTap;
  final bool isDark;

  const _SeriesListTile({
    required this.index,
    required this.seriesMap,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: BouncingCard(
        onTap: onTap,
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
  }
}
