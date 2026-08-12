import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    final profile = ref.watch(userProfileProvider).value?.profile;
    if (profile == null || profile.classId == null || profile.classId!.isEmpty) {
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

    final sectionsAsync = ref.watch(qbClassSectionsProvider(profile.classId!));

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

          return ListView.separated(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
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
                    title: name,
                    subSeries: subSeriesList,
                    isDark: isDark,
                  );
                } else {
                  context.push('/qb-exams/$idStr', extra: name);
                }
              }

              return _SeriesListTile(
                seriesMap: seriesMap,
                onTap: handleNavigation,
                isDark: isDark,
              );
            },
          );
        },
        loading: () => _buildListSkeleton(),
        error: (err, _) => Center(child: Text('ত্রুটি: $err')),
      ),
    );
  }

  Widget _buildListSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
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

class _SeriesListTile extends StatelessWidget {
  final Map<String, dynamic> seriesMap;
  final VoidCallback onTap;
  final bool isDark;

  const _SeriesListTile({
    required this.seriesMap,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final name = seriesMap['name']?.toString() ?? '';
    final subSeriesCount = (seriesMap['subSeries'] as List<dynamic>?)?.length ?? 0;
    
    // Calculate count of items
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
      onTap: onTap,
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
  }
}
