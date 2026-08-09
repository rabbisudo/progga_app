import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../academics/data/academics_repository.dart';
import '../../../../profile/presentation/profile_notifier.dart';
import '../../../../../core/widgets/custom_back_button.dart';
import '../../widgets/bouncing_card.dart';
import '../../widgets/shimmer_skeleton.dart';

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

          return GridView.builder(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 100.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: seriesList.length,
            itemBuilder: (context, index) {
              final seriesMap = seriesList[index] as Map<String, dynamic>;
              final name = seriesMap['name']?.toString() ?? '';
              final idStr = seriesMap['id']?.toString() ?? '';
              final logo = seriesMap['logo']?.toString() ?? seriesMap['banner']?.toString() ?? '';
              final subSeriesCount = (seriesMap['subSeries'] as List<dynamic>?)?.length ?? 0;

              void handleNavigation() {
                if (subSeriesCount > 0) {
                  context.push('/qb-sub-series/$idStr', extra: name);
                } else {
                  context.push('/qb-exams/$idStr', extra: name);
                }
              }

              if (logo.isNotEmpty) {
                return BouncingCard(
                  onTap: handleNavigation,
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
                        CachedNetworkImage(
                          imageUrl: logo,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
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
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.teal.shade50,
                            child: Center(
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF017A47),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Removed bottom dark gradient and title overlay to let the full banner show cleanly
                      ],
                    ),
                  ),
                );
              }

              return BouncingCard(
                onTap: handleNavigation,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF017A47),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => _buildGridSkeleton(),
        error: (err, _) => Center(child: Text('ত্রুটি: $err')),
      ),
    );
  }

  Widget _buildGridSkeleton() {
    return GridView.builder(
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
        borderRadius: 24,
      ),
    );
  }
}
