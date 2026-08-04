import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'practice_notifier.dart';
import '../../academics/data/academics_repository.dart';
import '../../../core/widgets/custom_back_button.dart';

class ExamConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> setupData;

  const ExamConfirmScreen({
    super.key,
    required this.setupData,
  });

  @override
  ConsumerState<ExamConfirmScreen> createState() => _ExamConfirmScreenState();
}

class _ExamConfirmScreenState extends ConsumerState<ExamConfirmScreen> {
  bool _isTopicsExpanded = true;
  late Map<String, int> _subjectQuestionCounts;
  late int _totalTimeMinutes;
  final String _selectedQuestionType = 'MCQ';

  @override
  void initState() {
    super.initState();
    final List<Map<String, dynamic>> selectedSubjects =
        (widget.setupData['selectedSubjects'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

    final int totalQ = widget.setupData['totalQuestions'] ?? 50;

    _subjectQuestionCounts = {};
    if (selectedSubjects.isNotEmpty) {
      final perSubjectQ = (totalQ / selectedSubjects.length).round();
      for (var sub in selectedSubjects) {
        final id = sub['id'] as String? ?? 'sub';
        _subjectQuestionCounts[id] = perSubjectQ > 0 ? perSubjectQ : 25;
      }
    }

    _totalTimeMinutes = _calculatedTotalQuestions; // Dynamic default: 1 min per question
  }

  String? _mapDbQuestionType(String rawType) {
    final upper = rawType.toUpperCase();
    if (upper == 'MCQ' || upper.startsWith('MCQ_') || upper == 'MCQ_N') {
      return 'MCQ';
    }
    if (upper.startsWith('CQ_') || upper == 'CQ') {
      return 'CQ';
    }
    if (upper == 'WRITTEN') {
      return 'WRITTEN';
    }
    if (upper.contains('FILL')) {
      return 'WRITTEN';
    }
    return null;
  }

  int get _calculatedTotalQuestions {
    if (_subjectQuestionCounts.isEmpty) return widget.setupData['totalQuestions'] ?? 50;
    return _subjectQuestionCounts.values.fold(0, (sum, count) => sum + count);
  }

  void _showEditSubjectQuestionCountModal(String id, String name, int currentCount) {
    final controller = TextEditingController(text: '$currentCount');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$name - প্রশ্ন সংখ্যা নির্ধারণ করুন',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'কাস্টম প্রশ্ন সংখ্যা (টি)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      if (val != null && val > 0) {
                        setState(() {
                          _subjectQuestionCounts[id] = val;
                          _totalTimeMinutes = _calculatedTotalQuestions;
                        });
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF017A47),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('নিশ্চিত করো', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditTotalTimeModal() {
    final controller = TextEditingController(text: '$_totalTimeMinutes');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'মোট পরীক্ষা সময় নির্ধারণ করুন',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'কাস্টম সময় (মিনিট)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      if (val != null && val > 0) {
                        setState(() {
                          _totalTimeMinutes = val;
                        });
                      }
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF017A47),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('নিশ্চিত করো', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> selectedSubjects =
        (widget.setupData['selectedSubjects'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
            [];

    final String primarySubjectId = widget.setupData['primarySubjectId'] ?? '';

    // Dynamically retrieve available question types from curriculum data
    final curriculumAsync = ref.watch(studentCurriculumProvider);
    final availableTypes = <String>{};

    final subjectIdStr = (widget.setupData['joinedSubjectIds']?.toString() ?? '').isNotEmpty
        ? widget.setupData['joinedSubjectIds'].toString()
        : primarySubjectId;
    final chapterIdStr = widget.setupData['joinedChapterIds']?.toString() ?? '';
    final topicIdStr = widget.setupData['joinedTopicIds']?.toString() ?? '';

    final selectedSubjectIds = subjectIdStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    final selectedChapterIds = chapterIdStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();
    final selectedTopicIds = topicIdStr.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toSet();

    curriculumAsync.when(
      data: (subjectsList) {
        debugPrint('DEBUG: subjectsList count=${subjectsList.length}');
        for (var subject in subjectsList) {
          final sId = subject['id'] as String? ?? '';
          if (selectedSubjectIds.contains(sId)) {
            debugPrint('DEBUG: Matched subject: ${subject['name']}, questionTypes: ${subject['questionTypes']}');
          }
        }
      },
      error: (err, stack) => debugPrint('DEBUG: curriculumAsync error=$err'),
      loading: () => debugPrint('DEBUG: curriculumAsync loading'),
    );

    curriculumAsync.whenData((subjectsList) {
      for (var subject in subjectsList) {
        final sId = subject['id'] as String? ?? '';
        if (!selectedSubjectIds.contains(sId)) continue;

        // If specific topics are selected
        if (selectedTopicIds.isNotEmpty) {
          final chapters = (subject['chapters'] as List<dynamic>?) ?? [];
          for (var chapter in chapters) {
            final topics = (chapter['topics'] as List<dynamic>?) ?? [];
            for (var topic in topics) {
              final tId = topic['id'] as String? ?? '';
              if (selectedTopicIds.contains(tId)) {
                final types = (topic['questionTypes'] as List<dynamic>?)?.cast<String>() ?? [];
                for (var t in types) {
                  final mapped = _mapDbQuestionType(t);
                  if (mapped != null) {
                    availableTypes.add(mapped);
                  }
                }
              }
            }
          }
        }
        // If no topics are selected but specific chapters are selected
        else if (selectedChapterIds.isNotEmpty) {
          final chapters = (subject['chapters'] as List<dynamic>?) ?? [];
          for (var chapter in chapters) {
            final cId = chapter['id'] as String? ?? '';
            if (selectedChapterIds.contains(cId)) {
              final types = (chapter['questionTypes'] as List<dynamic>?)?.cast<String>() ?? [];
              for (var t in types) {
                final mapped = _mapDbQuestionType(t);
                if (mapped != null) {
                  availableTypes.add(mapped);
                }
              }
            }
          }
        }
        // If only subjects are selected
        else {
          final types = (subject['questionTypes'] as List<dynamic>?)?.cast<String>() ?? [];
          for (var t in types) {
            final mapped = _mapDbQuestionType(t);
            if (mapped != null) {
              availableTypes.add(mapped);
            }
          }
        }
      }
    });

    debugPrint('DEBUG: availableTypes=$availableTypes');

    final isCurriculumLoading = curriculumAsync.isLoading;
    final typesToDisplay = isCurriculumLoading 
        ? <String>[] 
        : availableTypes.toList();

    if (typesToDisplay.isNotEmpty && !typesToDisplay.contains('FULL')) {
      typesToDisplay.add('FULL');
    }

    const sortOrder = ['MCQ', 'CQ', 'WRITTEN', 'FULL'];
    typesToDisplay.sort((a, b) {
      final indexA = sortOrder.indexOf(a);
      final indexB = sortOrder.indexOf(b);
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });

    // Question type locked to MCQ currently

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CustomBackButton(
          color: Colors.black87,
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'নিশ্চিত করো',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                '২/২ স্টেপস',
                style: TextStyle(
                  color: Color(0xFF017A47),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Step Progress bar (2 segments)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF017A47),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFA5D6A7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.5,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFF017A47),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Selected Subjects Section ("সিলেক্টেড বিষয় (২)")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'সিলেক্টেড বিষয় (${selectedSubjects.length})',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          'মোটপ্রশ্ন: $_calculatedTotalQuestionsটি',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF017A47),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (selectedSubjects.length == 1) ...[
                      Builder(
                        builder: (context) {
                          final sub = selectedSubjects.first;
                          final id = sub['id'] as String? ?? '';
                          final name = sub['name'] as String? ?? 'বিষয়';
                          final count = _subjectQuestionCounts[id] ?? 25;

                          return GestureDetector(
                            onTap: () => _showEditSubjectQuestionCountModal(id, name, count),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFEFEF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '$count',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'টি',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      SizedBox(
                        height: 95,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: selectedSubjects.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final sub = selectedSubjects[index];
                            final id = sub['id'] as String? ?? '';
                            final name = sub['name'] as String? ?? 'বিষয়';
                            final count = _subjectQuestionCounts[id] ?? 25;

                            return GestureDetector(
                              onTap: () => _showEditSubjectQuestionCountModal(id, name, count),
                              child: Container(
                                width: 160,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFEFEF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '$count',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const Text(
                                            'টি',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 3. Selected Topics Accordion
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isTopicsExpanded = !_isTopicsExpanded;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'সিলেক্টেড টপিকস দেখতে এখানে ট্যাপ করো',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Icon(
                                    _isTopicsExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_isTopicsExpanded) ...[
                            const Divider(height: 1, color: Color(0xFFEEEEEE)),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: selectedSubjects.map((sub) {
                                  final name = sub['name'] as String? ?? 'বিষয়';
                                  final id = sub['id'] as String? ?? '';
                                  final count = _subjectQuestionCounts[id] ?? 25;
                                  final topicsList = (sub['topics'] as List<dynamic>?)?.cast<String>() ?? [];
                                  final solvedText = sub['solvedText'] as String? ?? '0/500 টি প্রশ্ন সলভ করা হয়েছে';

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.circle,
                                                  size: 8,
                                                  color: Color(0xFF017A47),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF017A47),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '$countটি প্রশ্ন',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF017A47),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16.0),
                                          child: Text(
                                            solvedText,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 16.0),
                                          child: Column(
                                            children: topicsList.map((t) => Padding(
                                                  padding: const EdgeInsets.only(bottom: 4.0),
                                                  child: Text(
                                                    t,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                )).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Section: Total Time & Start Exam Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text(
                        'মোট সময়',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showEditTotalTimeModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBEBEB),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$_totalTimeMinutes',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  'মিনিট',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (typesToDisplay.isEmpty || isCurriculumLoading)
                          ? null
                          : () {
                              final joinedSubjectIds = widget.setupData['joinedSubjectIds'] ?? primarySubjectId;
                        final joinedChapterIds = widget.setupData['joinedChapterIds'];
                        final joinedTopicIds = widget.setupData['joinedTopicIds'];

                        ref.read(practiceProvider.notifier).updateFilters(
                          subjectId: joinedSubjectIds,
                          chapterId: joinedChapterIds,
                          topicId: joinedTopicIds,
                        );

                        final Uri examUri = Uri(
                          path: '/exam/$primarySubjectId',
                          queryParameters: {
                            'limit': '$_calculatedTotalQuestions',
                            'time': '$_totalTimeMinutes',
                            'questionType': _selectedQuestionType,
                            if (joinedSubjectIds != null && joinedSubjectIds.toString().isNotEmpty)
                              'subjectId': joinedSubjectIds.toString(),
                            if (joinedChapterIds != null && joinedChapterIds.toString().isNotEmpty)
                              'chapterId': joinedChapterIds.toString(),
                            if (joinedTopicIds != null && joinedTopicIds.toString().isNotEmpty)
                              'topicId': joinedTopicIds.toString(),
                          },
                        );

                        context.push(examUri.toString());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF017A47),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'পরীক্ষা শুরু করো',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
}
