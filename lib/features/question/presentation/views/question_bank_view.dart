import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../academics/data/academics_repository.dart';
import '../../../profile/presentation/profile_notifier.dart';
import '../widgets/shimmer_skeleton.dart';

// Local Qb Sub-Views
import 'qb/qb_root_series_view.dart';
import 'qb/qb_sub_series_view.dart';
import 'qb/qb_exams_list_view.dart';

class QuestionBankView extends ConsumerStatefulWidget {
  final List<String> seriesStack;
  final ValueChanged<List<String>> onStackChanged;
  final String? activeExamTab;
  final ValueChanged<String?> onActiveExamTabChanged;
  final String examSearchQuery;
  final ValueChanged<String> onExamSearchQueryChanged;

  const QuestionBankView({
    super.key,
    required this.seriesStack,
    required this.onStackChanged,
    required this.activeExamTab,
    required this.onActiveExamTabChanged,
    required this.examSearchQuery,
    required this.onExamSearchQueryChanged,
  });

  @override
  ConsumerState<QuestionBankView> createState() => _QuestionBankViewState();
}

class _QuestionBankViewState extends ConsumerState<QuestionBankView> {
  @override
  Widget build(BuildContext context) {
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
    final seriesAsync = ref.watch(qbClassSeriesProvider(classId));

    return seriesAsync.when(
      data: (seriesList) {
        if (seriesList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'এই ক্লাসের জন্য কোনো প্রশ্নব্যাংক সিরিজ পাওয়া যায়নি।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          );
        }

        Widget activeBody;
        if (widget.seriesStack.isEmpty) {
          activeBody = QbRootSeriesView(
            seriesList: seriesList,
            seriesStack: widget.seriesStack,
            onStackChanged: widget.onStackChanged,
            onActiveExamTabChanged: widget.onActiveExamTabChanged,
            onExamSearchQueryChanged: widget.onExamSearchQueryChanged,
          );
        } else {
          final activeId = widget.seriesStack.last;
          final activeSeries = seriesList.firstWhere(
            (s) => s['id']?.toString() == activeId,
            orElse: () => null,
          );

          if (activeSeries == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onStackChanged([]);
            });
            activeBody = const Center(child: CircularProgressIndicator(color: Color(0xFF017A47)));
          } else {
            final subSeriesListIds = (activeSeries['subSeries'] as List<dynamic>?) ?? [];
            final validSubSeries = subSeriesListIds.map((subId) {
              return seriesList.firstWhere(
                (s) => s['id']?.toString() == subId.toString(),
                orElse: () => null,
              );
            }).where((s) => s != null).toList();

            if (validSubSeries.isNotEmpty) {
              activeBody = QbSubSeriesView(
                activeSeries: activeSeries,
                seriesList: seriesList,
                seriesStack: widget.seriesStack,
                onStackChanged: widget.onStackChanged,
                onActiveExamTabChanged: widget.onActiveExamTabChanged,
                onExamSearchQueryChanged: widget.onExamSearchQueryChanged,
              );
            } else {
              activeBody = QbExamsListView(
                activeSeries: activeSeries,
                seriesStack: widget.seriesStack,
                activeExamTab: widget.activeExamTab,
                onActiveExamTabChanged: widget.onActiveExamTabChanged,
                examSearchQuery: widget.examSearchQuery,
                onExamSearchQueryChanged: widget.onExamSearchQueryChanged,
                onStackChanged: widget.onStackChanged,
              );
            }
          }
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: KeyedSubtree(
            key: ValueKey(widget.seriesStack.length),
            child: activeBody,
          ),
        );
      },
      loading: () => _buildSubjectGridSkeleton(),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'ডাটা লোড করা যায়নি: $err',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
