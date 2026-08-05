import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../academics/data/academics_repository.dart';
import '../../../profile/presentation/profile_notifier.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/bouncing_card.dart';

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
        return PopScope(
          canPop: widget.seriesStack.isEmpty,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            if (widget.seriesStack.isNotEmpty) {
              final newStack = List<String>.from(widget.seriesStack)..removeLast();
              widget.onStackChanged(newStack);
              widget.onExamSearchQueryChanged('');
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: KeyedSubtree(
              key: ValueKey(widget.seriesStack.length),
              child: _buildHierarchicalSeriesFlow(seriesList),
            ),
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

  // Stack-based hierarchical series browser
  Widget _buildHierarchicalSeriesFlow(List<dynamic> seriesList) {
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

    // Level 0: Top-level Series Browse
    if (widget.seriesStack.isEmpty) {
      final Map<String, List<Map<String, dynamic>>> groupedBySubject = {};
      for (final s in rootSeriesList) {
        if (s is Map<String, dynamic>) {
          final subId = s['subjectId']?.toString() ?? 'other';
          groupedBySubject.putIfAbsent(subId, () => []).add(s);
        }
      }

      final sortedSubjectIds = groupedBySubject.keys.toList()
        ..sort((a, b) {
          final subA = groupedBySubject[a]!.first['subject'] as Map<String, dynamic>?;
          final subB = groupedBySubject[b]!.first['subject'] as Map<String, dynamic>?;
          final orderA = subA?['sortOrder'] as int? ?? 100;
          final orderB = subB?['sortOrder'] as int? ?? 100;
          return orderA.compareTo(orderB);
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
                    final newStack = List<String>.from(widget.seriesStack)..add(firstSeries['id']?.toString() ?? '');
                    widget.onStackChanged(newStack);
                    widget.onActiveExamTabChanged(null);
                    widget.onExamSearchQueryChanged('');
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
                                  _toBengaliDigits('$count'),
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

    // Level N: Navigating inside series
    final activeId = widget.seriesStack.last;
    final activeSeries = seriesList.firstWhere(
      (s) => s['id']?.toString() == activeId,
      orElse: () => null,
    );

    if (activeSeries == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onStackChanged([]);
      });
      return const Center(child: CircularProgressIndicator(color: Color(0xFF017A47)));
    }

    final subSeriesListIds = (activeSeries['subSeries'] as List<dynamic>?) ?? [];
    final validSubSeries = subSeriesListIds.map((subId) {
      return seriesList.firstWhere(
        (s) => s['id']?.toString() == subId.toString(),
        orElse: () => null,
      );
    }).where((s) => s != null).toList();

    // Grid of Sub-Series (MCQ, CQ etc)
    if (validSubSeries.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF017A47)),
                  onPressed: () {
                    final newStack = List<String>.from(widget.seriesStack)..removeLast();
                    widget.onStackChanged(newStack);
                  },
                ),
                Expanded(
                  child: Text(
                    activeSeries['name']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16.0),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: validSubSeries.map<Widget>((subSeriesObj) {
                final subSeriesMap = subSeriesObj as Map<String, dynamic>;
                final subName = subSeriesMap['name']?.toString() ?? '';
                final subIdStr = subSeriesMap['id']?.toString() ?? '';

                Color cardColor = Colors.lightBlue.shade50;
                Color textColor = Colors.lightBlue.shade700;
                String icon = '📝';
                String title = subName;

                if (subName.toLowerCase().contains('mcq')) {
                  cardColor = const Color(0xFFE3F2FD);
                  textColor = const Color(0xFF1E88E5);
                  icon = '📝';
                  title = 'MCQ';
                } else if (subName.toLowerCase().contains('cq')) {
                  cardColor = const Color(0xFFFFF8E1);
                  textColor = const Color(0xFFF57F17);
                  icon = '📖';
                  title = 'CQ';
                } else if (subName.toLowerCase().contains('kbhandar')) {
                  cardColor = const Color(0xFFE8EAF6);
                  textColor = const Color(0xFF3F51B5);
                  icon = '📚';
                  title = 'ক ভাণ্ডার';
                } else if (subName.toLowerCase().contains('khabhandar')) {
                  cardColor = const Color(0xFFE8F5E9);
                  textColor = const Color(0xFF4CAF50);
                  icon = '📚';
                  title = 'খ ভাণ্ডার';
                } else if (subName.toLowerCase().contains('short') || subName.toLowerCase().contains('সংক্ষিপ্ত')) {
                  cardColor = const Color(0xFFF3E5F5);
                  textColor = const Color(0xFF9C27B0);
                  icon = '⏱️';
                  title = 'সংক্ষিপ্ত প্রশ্ন';
                }

                final subLogo = subSeriesMap['logo']?.toString() ?? subSeriesMap['banner']?.toString() ?? '';

                if (subLogo.isNotEmpty) {
                  return BouncingCard(
                    onTap: () {
                      final newStack = List<String>.from(widget.seriesStack)..add(subIdStr);
                      widget.onStackChanged(newStack);
                      widget.onActiveExamTabChanged(null);
                      widget.onExamSearchQueryChanged('');
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
                          Image.network(
                            subLogo,
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
                              color: cardColor,
                              child: Center(
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
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return BouncingCard(
                  onTap: () {
                    final newStack = List<String>.from(widget.seriesStack)..add(subIdStr);
                    widget.onStackChanged(newStack);
                    widget.onActiveExamTabChanged(null);
                  },
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
            ),
          ),
        ],
      );
    }

    // Tabbed Exams List selector
    var labelNameMap = Map<String, dynamic>.from(activeSeries['labelName'] as Map? ?? {});
    if (labelNameMap.isEmpty && activeSeries['exams'] != null) {
      final examsVal = activeSeries['exams'];
      if (examsVal is String && examsVal.isNotEmpty) {
        labelNameMap = {
          'Exams': examsVal.split(','),
        };
      } else if (examsVal is List && examsVal.isNotEmpty) {
        labelNameMap = {
          'Exams': examsVal.map((e) => e.toString()).toList(),
        };
      }
    }

    if (labelNameMap.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF017A47)),
                  onPressed: () {
                    final newStack = List<String>.from(widget.seriesStack)..removeLast();
                    widget.onStackChanged(newStack);
                  },
                ),
                Expanded(
                  child: Text(
                    activeSeries['name']?.toString() ?? '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'কোনো পরীক্ষা পাওয়া যায়নি।',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      );
    }

    final tabKeys = labelNameMap.keys.toList();
    final displayTabs = ['সব', ...tabKeys];
    final activeTab = widget.activeExamTab ?? 'সব';
    final hasMultipleLevels = tabKeys.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: const Color(0xFF017A47),
                ),
                onPressed: () {
                  final newStack = List<String>.from(widget.seriesStack)..removeLast();
                  widget.onStackChanged(newStack);
                  widget.onExamSearchQueryChanged('');
                },
              ),
              Expanded(
                child: Text(
                  activeSeries['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Noto Sans Bengali',
                  ),
                ),
              ),
            ],
          ),
        ),

        if (hasMultipleLevels) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              height: 44,
              child: TextField(
                onChanged: widget.onExamSearchQueryChanged,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'Noto Sans Bengali',
                ),
                decoration: InputDecoration(
                  hintText: 'পরীক্ষা খুঁজে বের করো...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontFamily: 'Noto Sans Bengali'),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF017A47), width: 1.5),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F5),
                ),
              ),
            ),
          ),
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: displayTabs.map<Widget>((key) {
                final isSelected = activeTab == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      widget.onActiveExamTabChanged(key);
                      widget.onExamSearchQueryChanged('');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF017A47)
                            : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F5)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF017A47)
                              : Colors.transparent,
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF017A47).withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontFamily: 'Noto Sans Bengali',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final List<String> idsToLoad;
              if (hasMultipleLevels) {
                if (activeTab == 'সব') {
                  idsToLoad = tabKeys
                      .expand((k) => List<String>.from(labelNameMap[k] ?? []))
                      .toSet()
                      .toList();
                } else {
                  idsToLoad = List<String>.from(labelNameMap[activeTab] ?? []);
                }
              } else {
                idsToLoad = List<String>.from(labelNameMap[tabKeys.first] ?? []);
              }

              final examsAsync = ref.watch(qbExamsProvider(idsToLoad.join(',')));
              return examsAsync.when(
                data: (examsList) {
                  var filteredList = examsList;
                  if (hasMultipleLevels && widget.examSearchQuery.isNotEmpty) {
                    filteredList = examsList.where((ex) {
                      final title = ex['title']?.toString() ?? '';
                      return title.toLowerCase().contains(widget.examSearchQuery.toLowerCase());
                    }).toList();
                  }

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('কোনো পরীক্ষা পাওয়া যায়নি।'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredList.length,
                    itemBuilder: (context, idx) {
                      final ex = filteredList[idx] as Map<String, dynamic>;
                      final title = ex['title']?.toString() ?? '';
                      final duration = ex['duration'] as int? ?? 1500;
                      final durationMin = (duration / 60).round();
                      final qCount = ex['qCount'] as int? ?? 25;

                      final createdAt = ex['createdAt'];
                      final dateStr = _getExamDateStr(createdAt, title);

                      return BouncingCard(
                        onTap: () {
                          _showExamConfirmSheet(context, ex);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.015),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1.35,
                                    color: isDark ? Colors.white : const Color(0xFF212529),
                                    fontFamily: 'Noto Sans Bengali',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    // Time Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF3D1616) : const Color(0xFFFFF5F5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isDark ? const Color(0xFF731D1D) : const Color(0xFFFFE3E3), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.timer_outlined,
                                            size: 13,
                                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFE03131),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${_toBengaliDigits(durationMin.toString())} মিনিট',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A),
                                              fontFamily: 'Noto Sans Bengali',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Questions Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF00381C) : const Color(0xFFE6FCF5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFC3FAE8), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.edit_note_outlined,
                                            size: 14,
                                            color: isDark ? const Color(0xFF00C569) : const Color(0xFF099268),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_toBengaliDigits(qCount.toString())}টি প্রশ্ন',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFF00C569) : const Color(0xFF087F5B),
                                              fontFamily: 'Noto Sans Bengali',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Date Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E2B5C) : const Color(0xFFEDF2FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isDark ? const Color(0xFF2D3B73) : const Color(0xFFDBE4FF), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_month_outlined,
                                            size: 13,
                                            color: isDark ? const Color(0xFF8DA2FB) : const Color(0xFF364FC7),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            dateStr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? const Color(0xFF8DA2FB) : const Color(0xFF2B4C7E),
                                              fontFamily: 'Noto Sans Bengali',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerSkeleton(
                            width: 180,
                            height: 16,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFFFF5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const ShimmerSkeleton(width: 50, height: 11, borderRadius: 3),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFE6FCF5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const ShimmerSkeleton(width: 50, height: 11, borderRadius: 3),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFEDF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const ShimmerSkeleton(width: 65, height: 11, borderRadius: 3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                error: (err, _) => Center(child: Text('পরীক্ষা লোড করতে ব্যর্থ হয়েছে: $err')),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showExamConfirmSheet(BuildContext context, Map<String, dynamic> ex) {
    final title = ex['title']?.toString() ?? '';
    final duration = ex['duration'] as int? ?? 1500;
    final durationMin = (duration / 60).round();
    final qCount = ex['qCount'] as int? ?? 25;
    final examId = ex['id'] as String? ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 10.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Noto Sans Bengali',
                  ),
                ),
                const SizedBox(height: 20),
                // Overview Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF121212) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Time
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: isDark ? const Color(0xFFF87171) : const Color(0xFFC92A2A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_toBengaliDigits(durationMin.toString())} মিনিট',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                        ],
                      ),
                      // Divider
                      Container(
                        width: 1.5,
                        height: 24,
                        color: borderColor,
                      ),
                      // Question Count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            color: isDark ? const Color(0xFF00C569) : const Color(0xFF2B8A3E),
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_toBengaliDigits(qCount.toString())}টি প্রশ্ন',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Start Exam Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/exam/$examId');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF017A47),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'পরীক্ষা শুরু করো',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // View Questions Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/exam-preview/$examId', extra: title);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF00C569) : const Color(0xFF017A47),
                    side: BorderSide(color: isDark ? const Color(0xFF00C569) : const Color(0xFF017A47), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFECEFF1).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text(
                    'প্রশ্ন দেখো',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
          fontFamily: 'Noto Sans Bengali',
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

  String _toBengaliDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(english[i], bengali[i]);
    }
    return result;
  }

  String _getExamDateStr(dynamic createdAt, String examTitle) {
    try {
      if (createdAt != null) {
        final dt = DateTime.parse(createdAt.toString());
        final months = [
          'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
          'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
        ];
        final dayStr = _toBengaliDigits(dt.day.toString());
        final monthStr = months[dt.month - 1];
        final yearStr = _toBengaliDigits(dt.year.toString());
        return '$dayStr $monthStr, $yearStr';
      }
    } catch (_) {}

    final regExp = RegExp(r'\d{4}');
    final match = regExp.firstMatch(examTitle);
    if (match != null) {
      final year = match.group(0)!;
      return '${_toBengaliDigits("২৪")} মে, ${_toBengaliDigits(year)}';
    }
    final bnRegExp = RegExp(r'[০-৯]{4}');
    final bnMatch = bnRegExp.firstMatch(examTitle);
    if (bnMatch != null) {
      final year = bnMatch.group(0)!;
      return '২৪ মে, $year';
    }
    return '২৪ মে, ২০২৬';
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
