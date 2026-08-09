import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../academics/data/academics_repository.dart';
import '../../../profile/presentation/profile_notifier.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/bouncing_card.dart';

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
                    return _buildSeriesGrid(context, seriesList, isDark);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildSubjectGridSkeleton(),
      error: (err, _) => _buildErrorWidget('ডাটা লোড করা যায়নি: $err'),
    );
  }

  Widget _buildSeriesGrid(BuildContext context, List<dynamic> seriesList, bool isDark) {
    if (seriesList.isEmpty) {
      return const EmptyStateWidget(
        title: 'কোনো সিরিজ পাওয়া যায়নি',
        subtitle: 'এই বিভাগের অধীনে কোনো প্রশ্নব্যাংক সিরিজ সচল নেই।',
        icon: Icons.layers_clear_rounded,
      );
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
                            fontFamily: 'Li Ador Noirrit',
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

  LinearGradient _getGradientForSection(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('physics') || nameLower.contains('পদার্থ')) {
      return const LinearGradient(
        colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (nameLower.contains('chemistry') || nameLower.contains('রসায়ন')) {
      return const LinearGradient(
        colors: [Color(0xFF1D976C), Color(0xFF93F9B9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (nameLower.contains('math') || nameLower.contains('গণিত')) {
      return const LinearGradient(
        colors: [Color(0xFF3A6073), Color(0xFF3A6073)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (nameLower.contains('biology') || nameLower.contains('জীব')) {
      return const LinearGradient(
        colors: [Color(0xFF134E5E), Color(0xFF71B280)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildSubjectGridSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
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
