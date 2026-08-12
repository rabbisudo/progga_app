import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../academics/data/academics_repository.dart';
import '../../../../profile/presentation/profile_notifier.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../widgets/bouncing_card.dart';
import '../../widgets/shimmer_skeleton.dart';

class QbSubSeriesScreen extends ConsumerWidget {
  final String seriesId;
  final String? seriesName;

  const QbSubSeriesScreen({
    super.key,
    required this.seriesId,
    this.seriesName,
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
          title: Text(seriesName ?? 'CQ/MCQ'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text('প্রোফাইলে কোনো ক্লাস সিলেক্ট করা নেই।'),
        ),
      );
    }

    final seriesAsync = ref.watch(qbClassSeriesProvider(profile.classId!));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const CustomBackButton(color: Color(0xFF017A47)),
        title: Text(
          seriesName ?? 'CQ/MCQ',
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
          final activeSeries = seriesList.firstWhere(
            (s) => s['id']?.toString() == seriesId,
            orElse: () => null,
          );

          if (activeSeries == null) {
            return const Center(child: Text('সিরিজ পাওয়া যায়নি।'));
          }

          final subSeriesListIds = (activeSeries['subSeries'] as List<dynamic>?) ?? [];
          final validSubSeries = subSeriesListIds.map((subId) {
            return seriesList.firstWhere(
              (s) => s['id']?.toString() == subId.toString(),
              orElse: () => null,
            );
          }).where((s) => s != null).toList();

          if (validSubSeries.isEmpty) {
            return const Center(child: Text('কোনো উপ-সিরিজ পাওয়া যায়নি।'));
          }

          return GridView.count(
            padding: const EdgeInsets.all(16.0),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
            children: validSubSeries.map<Widget>((subSeriesObj) {
              final subSeriesMap = subSeriesObj as Map<String, dynamic>;
              final subName = subSeriesMap['name']?.toString() ?? '';
              final subIdStr = subSeriesMap['id']?.toString() ?? '';

              // Check if this sub-series itself has sub-series (nested levels)
              final nestedSubIds = (subSeriesMap['subSeries'] as List<dynamic>?) ?? [];
              final validNested = nestedSubIds.map((subId) {
                return seriesList.firstWhere(
                  (s) => s['id']?.toString() == subId.toString(),
                  orElse: () => null,
                );
              }).where((s) => s != null).toList();
              final hasNestedSubSeries = validNested.isNotEmpty;

              Color cardColor = Colors.lightBlue.shade50;
              Color textColor = Colors.lightBlue.shade700;
              String icon = '📝';
              String title = subName;

              final subNameLower = subName.toLowerCase();
              if (subNameLower.contains('mcq') || subNameLower.contains('এমসিকিউ')) {
                cardColor = const Color(0xFFE3F2FD);
                textColor = const Color(0xFF1E88E5);
                icon = '📝';
                title = 'MCQ';
              } else if (subNameLower.contains('cq') || subNameLower.contains('সিকিউ') || subNameLower.contains('লিখিত') || subNameLower.contains('written')) {
                cardColor = const Color(0xFFFFF8E1);
                textColor = const Color(0xFFF57F17);
                icon = '📖';
                title = subNameLower.contains('written') || subNameLower.contains('লিখিত') ? 'লিখিত' : 'CQ';
              } else if (subNameLower.contains('kbhandar') || subNameLower.contains('ক ভাণ্ডার')) {
                cardColor = const Color(0xFFE8EAF6);
                textColor = const Color(0xFF3F51B5);
                icon = '📚';
                title = 'ক ভাণ্ডার';
              } else if (subNameLower.contains('khabhandar') || subNameLower.contains('খ ভাণ্ডার')) {
                cardColor = const Color(0xFFE8F5E9);
                textColor = const Color(0xFF4CAF50);
                icon = '📚';
                title = 'খ ভাণ্ডার';
              } else if (subNameLower.contains('short') || subNameLower.contains('সংক্ষিপ্ত')) {
                cardColor = const Color(0xFFF3E5F5);
                textColor = const Color(0xFF9C27B0);
                icon = '⏱️';
                title = 'সংক্ষিপ্ত প্রশ্ন';
              }

              void handleNavigation() {
                if (hasNestedSubSeries) {
                  context.push('/qb-sub-series/$subIdStr', extra: subName);
                } else {
                  context.push('/qb-exams/$subIdStr', extra: subName);
                }
              }

              return BouncingCard(
                onTap: handleNavigation,
                child: Card(
                  elevation: 0,
                  color: isDark ? const Color(0xFF1E1E1E) : cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.05) : textColor.withOpacity(0.15), 
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
        loading: () => GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: 4,
          itemBuilder: (context, index) => const ShimmerSkeleton(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 20,
          ),
        ),
        error: (err, _) => Center(child: Text('ডাটা লোড করা যায়নি: $err')),
      ),
    );
  }
}
