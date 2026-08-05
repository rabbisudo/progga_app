import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../academics/data/academics_repository.dart';
import '../../../core/widgets/custom_back_button.dart';

class TopicSelectionScreen extends ConsumerStatefulWidget {
  final String subjectId;
  final String? subjectName;

  const TopicSelectionScreen({
    super.key,
    required this.subjectId,
    this.subjectName,
  });

  @override
  ConsumerState<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends ConsumerState<TopicSelectionScreen> {
  final Set<String> _selectedSubjectIds = {};
  final Set<String> _selectedTopicIds = {};
  final Set<String> _selectedChapterIds = {};
  final Set<String> _collapsedChapterIds = {};
  final TextEditingController _questionCountController = TextEditingController(text: '25');
  int _selectedQuestionCount = 25;
  bool _isTopicsExpanded = true;
  bool _showMultiSubjectHeader = false;
  late String _activeSubjectId;

  @override
  void initState() {
    super.initState();
    _activeSubjectId = widget.subjectId;
    _selectedSubjectIds.add(widget.subjectId);
  }

  @override
  void dispose() {
    _questionCountController.dispose();
    super.dispose();
  }

  void _toggleChapterCollapse(String chapterId) {
    setState(() {
      if (_collapsedChapterIds.contains(chapterId)) {
        _collapsedChapterIds.remove(chapterId);
      } else {
        _collapsedChapterIds.add(chapterId);
      }
    });
  }

  void _toggleTopic(String topicId, String chapterId, List<dynamic> chapterTopics) {
    setState(() {
      if (_selectedTopicIds.contains(topicId)) {
        _selectedTopicIds.remove(topicId);
      } else {
        _selectedTopicIds.add(topicId);
      }

      final allTopicIds = chapterTopics.map((t) => t['id'] as String).toSet();
      if (allTopicIds.isNotEmpty && allTopicIds.every((id) => _selectedTopicIds.contains(id))) {
        _selectedChapterIds.add(chapterId);
      } else {
        _selectedChapterIds.remove(chapterId);
      }
    });
  }

  void _toggleChapter(String chapterId, List<dynamic> chapterTopics) {
    setState(() {
      final topicIds = chapterTopics.map((t) => t['id'] as String).toList();
      if (_selectedChapterIds.contains(chapterId)) {
        _selectedChapterIds.remove(chapterId);
        _selectedTopicIds.removeAll(topicIds);
      } else {
        _selectedChapterIds.add(chapterId);
        _selectedTopicIds.addAll(topicIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final curriculumAsync = ref.watch(studentCurriculumProvider);

    return curriculumAsync.when(
      loading: () => Scaffold(
        backgroundColor: const Color(0xFFF3F4F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F4F3),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: CustomBackButton(
            color: Colors.black87,
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'টপিক সিলেক্ট করো',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF017A47)),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: const Color(0xFFF3F4F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F4F3),
          elevation: 0,
          leading: CustomBackButton(
            color: Colors.black87,
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'টপিক সিলেক্ট করো',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text('তথ্য লোড করতে সমস্যা হয়েছে: $err', style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(studentCurriculumProvider),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF017A47)),
                child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      data: (subjects) {
        final activeSubjects = subjects.where((s) => _selectedSubjectIds.contains(s['id'])).toList();
        final currentSubject = subjects.firstWhere(
          (s) => s['id'] == _activeSubjectId,
          orElse: () => subjects.isNotEmpty ? subjects.first : <String, dynamic>{},
        );
        final singleSubjectChapters = (currentSubject['chapters'] as List<dynamic>?) ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F3),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F3),
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: CustomBackButton(
              color: Colors.black87,
              onPressed: () {
                if (_showMultiSubjectHeader) {
                  setState(() {
                    _showMultiSubjectHeader = false;
                  });
                } else {
                  context.pop();
                }
              },
            ),
            title: const Text(
              'টপিক সিলেক্ট করো',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
             actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4E8DC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF017A47).withOpacity(0.12)),
                      ),
                      child: const Text(
                        '১/২ স্টেপস',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF017A47),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Segmented progress indicator bar with smooth loading fill animation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E7E4),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF017A47),
                                  borderRadius: BorderRadius.circular(2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF017A47).withOpacity(0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E7E4),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Main Content (Single Subject Detailed View OR Multi-Subject Overview)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showMultiSubjectHeader) ...[
                        // Top Multi-Subject Selector Chips Grid matching Screenshot 1
                        _buildSubjectSelectionChips(subjects),

                        const SizedBox(height: 12),

                        // Collapsible "সিলেক্টেড টপিকস দেখতে এখানে ট্যাপ করো" Bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () {
                              setState(() {
                                _isTopicsExpanded = !_isTopicsExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'সিলেক্টেড টপিকস দেখতে এখানে ট্যাপ করো',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Icon(
                                    _isTopicsExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: Colors.black87,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (_isTopicsExpanded) ...[
                          const SizedBox(height: 16),
                          ...activeSubjects.map((s) => _buildMultiSubjectSummaryBlock(s)),
                        ],
                      ] else ...[
                        // Direct Single Subject Detailed View matching Screenshot 2
                        ...singleSubjectChapters.map((c) => _buildChapterBlock(c)),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Banner
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Editable Question Count Input Row with - and + increment circle controllers
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'প্রশ্নের সংখ্যা',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Row(
                              children: [
                                // Decrement Button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedQuestionCount > 5) {
                                        _selectedQuestionCount -= 5;
                                        _questionCountController.text = _selectedQuestionCount.toString();
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFECEFF1)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.remove, size: 16, color: Color(0xFF017A47)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60,
                                  height: 38,
                                  child: TextField(
                                    controller: _questionCountController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: EdgeInsets.zero,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: Color(0xFF017A47), width: 1.5),
                                      ),
                                    ),
                                    onChanged: (val) {
                                      final num = int.tryParse(val);
                                      if (num != null && num > 0) {
                                        _selectedQuestionCount = num;
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Increment Button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (_selectedQuestionCount < 200) {
                                        _selectedQuestionCount += 5;
                                        _questionCountController.text = _selectedQuestionCount.toString();
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFECEFF1)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(Icons.add, size: 16, color: Color(0xFF017A47)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action Buttons Row: + আরেকটি বিষয় and এগিয়ে যাও
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _showMultiSubjectHeader = !_showMultiSubjectHeader;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '+ আরেকটি বিষয়',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final joinedSubjectIds = _selectedSubjectIds.join(',');
                                final joinedChapterIds = _selectedChapterIds.join(',');
                                final joinedTopicIds = _selectedTopicIds.join(',');

                                final primarySubject = _selectedSubjectIds.isNotEmpty
                                    ? _selectedSubjectIds.first
                                    : widget.subjectId;

                                final allSubjectsList = curriculumAsync.asData?.value ?? [];

                                // Build selected subjects info dynamically
                                final List<Map<String, dynamic>> selectedSubjectsInfo = [];
                                final targetSubjectIds = _selectedSubjectIds.isEmpty ? [widget.subjectId] : _selectedSubjectIds;

                                for (var sId in targetSubjectIds) {
                                  String sName = (sId == widget.subjectId && widget.subjectName != null)
                                      ? widget.subjectName!
                                      : 'বিষয়';
                                  final List<String> topicNames = [];

                                  String solvedTextStr = '0/507 টি প্রশ্ন সলভ করা হয়েছে';

                                  for (var sItem in allSubjectsList) {
                                    if (sItem is Map<String, dynamic> && sItem['id'] == sId) {
                                      sName = sItem['name'] as String? ?? sName;
                                      
                                      int solvedCount = (sItem['solvedCount'] ?? sItem['userSolvedCount'] ?? sItem['userSolved'] ?? 0) as int;
                                      int totalQ = (sItem['totalQuestions'] ?? sItem['questionCount'] ?? sItem['totalQuestionsCount'] ?? 0) as int;

                                      final chapters = (sItem['chapters'] as List<dynamic>?) ?? [];
                                      if (totalQ == 0) {
                                        for (var ch in chapters) {
                                          if (ch is Map<String, dynamic>) {
                                            totalQ += (ch['totalQuestions'] ?? ch['questionCount'] ?? 0) as int;
                                            solvedCount += (ch['solvedCount'] ?? ch['userSolvedCount'] ?? 0) as int;
                                          }
                                        }
                                      }

                                      if (totalQ == 0) totalQ = 507;

                                      String formatCount(int count) {
                                        if (count >= 1000) {
                                          double k = count / 1000;
                                          return '${k.toStringAsFixed(k.truncateToDouble() == k ? 0 : 1)}K';
                                        }
                                        return '$count';
                                      }

                                      solvedTextStr = '$solvedCount/${formatCount(totalQ)} টি প্রশ্ন সলভ করা হয়েছে';

                                      for (var ch in chapters) {
                                        if (ch is Map<String, dynamic>) {
                                          final chId = ch['id'] as String;
                                          final chName = ch['name'] as String? ?? '';
                                          final topics = (ch['topics'] as List<dynamic>?) ?? [];

                                          if (_selectedChapterIds.contains(chId)) {
                                            topicNames.add(chName);
                                          } else {
                                            for (var tp in topics) {
                                              if (tp is Map<String, dynamic> && _selectedTopicIds.contains(tp['id'])) {
                                                topicNames.add(tp['name'] as String? ?? chName);
                                              }
                                            }
                                          }
                                        }
                                      }
                                      break;
                                    }
                                  }

                                  selectedSubjectsInfo.add({
                                    'id': sId,
                                    'name': sName,
                                    'solvedText': solvedTextStr,
                                    'topics': topicNames.isEmpty ? ['সকল অধ্যায় ও টপিক'] : topicNames,
                                  });
                                }

                                context.push(
                                  '/exam-confirm',
                                  extra: {
                                    'primarySubjectId': primarySubject,
                                    'joinedSubjectIds': joinedSubjectIds.isNotEmpty ? joinedSubjectIds : primarySubject,
                                    'joinedChapterIds': joinedChapterIds.isNotEmpty ? joinedChapterIds : null,
                                    'joinedTopicIds': joinedTopicIds.isNotEmpty ? joinedTopicIds : null,
                                    'totalQuestions': _selectedQuestionCount,
                                    'selectedSubjects': selectedSubjectsInfo,
                                  },
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF017A47),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'এগিয়ে যাও',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubjectSelectionChips(List<dynamic> allSubjects) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: allSubjects.map((s) {
          final subMap = s as Map<String, dynamic>;
          final sId = subMap['id'] as String;
          final sName = subMap['name'] ?? 'বিষয়';
          final isSelected = _selectedSubjectIds.contains(sId);

          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  if (_selectedSubjectIds.length > 1) {
                    _selectedSubjectIds.remove(sId);
                  }
                } else {
                  _selectedSubjectIds.add(sId);
                }
                _activeSubjectId = sId;
                _showMultiSubjectHeader = false; // Opens Detailed Checkbox View for this subject!
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF017A47) : Colors.grey.shade200,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Text(
                sName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF017A47) : Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMultiSubjectSummaryBlock(Map<String, dynamic> subject) {
    final sId = subject['id'] as String;
    final subjectName = subject['name'] ?? 'বিষয়';
    final chapters = (subject['chapters'] as List<dynamic>?) ?? [];
    final totalSubjectQuestions = subject['totalQuestions'] ?? 0;
    final solvedSubjectQuestions = subject['solvedQuestions'] ?? 0;

    return InkWell(
      onTap: () {
        setState(() {
          _activeSubjectId = sId;
          _showMultiSubjectHeader = false; // Opens Detailed Checkbox View for this subject!
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Green Dot + Subject Title and Right Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF017A47),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subjectName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF017A47),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4E8DC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '$_selectedQuestionCountটি প্রশ্ন',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF017A47),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Solved stats ratio line
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                '$solvedSubjectQuestions/$totalSubjectQuestions টি প্রশ্ন সলভ করা হয়েছে',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Left Vertical Guide Line + Chapters and Selected Topics
            Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Stack(
                children: [
                  Positioned(
                    left: 3,
                    top: 4,
                    bottom: 4,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Builder(
                      builder: (context) {
                        final List<Map<String, dynamic>> filteredChapters = [];
                        for (var c in chapters) {
                          if (c is! Map<String, dynamic>) continue;
                          final cId = c['id'] as String;
                          final cName = c['name'] ?? 'অধ্যায়';
                          final topicsList = (c['topics'] as List<dynamic>?) ?? [];
                          
                          final isChSelected = _selectedChapterIds.contains(cId);
                          final List<dynamic> selTopics = topicsList.where((t) => _selectedTopicIds.contains(t['id'] as String)).toList();
                          
                          if (isChSelected || selTopics.isNotEmpty) {
                            filteredChapters.add({
                              'name': cName,
                              'topics': selTopics,
                            });
                          }
                        }

                        if (filteredChapters.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              'সকল অধ্যায় ও টপিক',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: filteredChapters.map((fc) {
                            final cName = fc['name'] as String;
                            final selTopics = fc['topics'] as List<dynamic>;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (selTopics.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    ...selTopics.map((t) {
                                      final tMap = t as Map<String, dynamic>;
                                      final tName = tMap['name'] ?? 'টপিক';
                                      return Padding(
                                        padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                                        child: Text(
                                          tName,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterBlock(Map<String, dynamic> chapter) {
    final chapterId = chapter['id'] as String;
    final chapterName = chapter['name'] ?? 'অধ্যায়';
    final topics = (chapter['topics'] as List<dynamic>?) ?? [];
    final isChapterSelected = _selectedChapterIds.contains(chapterId);
    final isCollapsed = _collapsedChapterIds.contains(chapterId);

    final solvedChapterQuestions = chapter['solvedQuestions'] ?? 0;
    final totalChapterQuestions = chapter['totalQuestions'] ?? (chapter['questionCount'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chapter Main Header Card (Clean outline and collapsible toggle chevron)
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: isChapterSelected 
                ? const Color(0xFF017A47).withOpacity(0.04) 
                : const Color(0xFFF9FBF9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isChapterSelected 
                  ? const Color(0xFF017A47).withOpacity(0.3) 
                  : const Color(0xFFECEFF1),
              width: isChapterSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                  splashColor: const Color(0xFF017A47).withOpacity(0.12),
                  highlightColor: const Color(0xFF017A47).withOpacity(0.05),
                  onTap: () => _toggleChapter(chapterId, topics),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                    child: Row(
                      children: [
                        _buildCheckboxWidget(isChapterSelected),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            chapterName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isChapterSelected ? const Color(0xFF017A47) : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$solvedChapterQuestions/$totalChapterQuestions টি',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isChapterSelected ? const Color(0xFF017A47) : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Separator and Collapse Toggle button
              Container(
                width: 1,
                height: 24,
                color: Colors.grey.shade300,
              ),
              IconButton(
                icon: AnimatedRotation(
                  turns: isCollapsed ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_up_rounded, size: 22, color: Colors.black54),
                ),
                onPressed: () => _toggleChapterCollapse(chapterId),
              ),
            ],
          ),
        ),

        // Subtopics Wrapper Container with Left Vertical Tree Line
        if (topics.isNotEmpty && !isCollapsed)
          Padding(
            padding: const EdgeInsets.only(left: 18, top: 4, bottom: 4),
            child: Stack(
              children: [
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 16,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF017A47).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Column(
                    children: topics.map((t) {
                      final topicMap = t as Map<String, dynamic>;
                      final topicId = topicMap['id'] as String;
                      final topicName = topicMap['name'] ?? 'টপিক';
                      final isTopicSelected = _selectedTopicIds.contains(topicId);
                      final solvedTopicQuestions = topicMap['solvedQuestions'] ?? 0;
                      final totalTopicQuestions = topicMap['totalQuestions'] ?? (topicMap['questionCount'] ?? 0);

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isTopicSelected 
                              ? const Color(0xFF017A47).withOpacity(0.03) 
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTopicSelected 
                                ? const Color(0xFF017A47).withOpacity(0.2) 
                                : const Color(0xFFECEFF1),
                            width: isTopicSelected ? 1.2 : 1.0,
                          ),
                          boxShadow: isTopicSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF017A47).withOpacity(0.02),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFF017A47).withOpacity(0.12),
                          highlightColor: const Color(0xFF017A47).withOpacity(0.05),
                          onTap: () => _toggleTopic(topicId, chapterId, topics),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 11.0),
                            child: Row(
                              children: [
                                _buildCheckboxWidget(isTopicSelected),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    topicName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isTopicSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isTopicSelected ? const Color(0xFF017A47) : Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$solvedTopicQuestions/$totalTopicQuestions',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isTopicSelected ? const Color(0xFF017A47) : Colors.black54,
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
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxWidget(bool isChecked) {
    return AnimatedScale(
      scale: isChecked ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isChecked ? const Color(0xFF017A47) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isChecked ? const Color(0xFF017A47) : const Color(0xFFCFD8DC),
            width: isChecked ? 0.0 : 1.5,
          ),
          boxShadow: isChecked
              ? [
                  BoxShadow(
                    color: const Color(0xFF017A47).withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: isChecked
            ? const Icon(
                Icons.check_rounded,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
