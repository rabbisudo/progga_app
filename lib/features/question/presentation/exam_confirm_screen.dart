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
  String _selectedQuestionType = 'MCQ';
  final Set<String> _selectedStandardKeys = {};
  bool _hasInitializedStandards = false;

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
    if (upper == 'CQ_N') {
      return 'WRITTEN';
    }
    if (upper.startsWith('CQ_') || upper == 'CQ') {
      return 'CQ';
    }
    if (upper == 'FILL_IN_THE_GAP' || upper == 'FILL_IN_THE_GAPS_WITHOUT_CLUES' || upper.contains('FILL')) {
      return 'FILL';
    }
    if (upper == 'WRITTEN') {
      return 'WRITTEN';
    }
    return null;
  }

  int get _calculatedTotalQuestions {
    if (_subjectQuestionCounts.isEmpty) return widget.setupData['totalQuestions'] ?? 50;
    return _subjectQuestionCounts.values.fold(0, (sum, count) => sum + count);
  }

  void _showEditSubjectQuestionCountModal(String id, String name, int currentCount) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade300;
    final counterBgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F4F1);
    final textInputBgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7F6);

    final controller = TextEditingController(text: '$currentCount');
    int localCount = currentCount;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
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
                          '$name - প্রশ্ন সংখ্যা',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: subTextColor),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrement
                      GestureDetector(
                        onTap: () {
                          if (localCount > 5) {
                            setModalState(() {
                              localCount -= 5;
                              controller.text = '$localCount';
                            });
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: counterBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: const Icon(Icons.remove, size: 20, color: Color(0xFF017A47)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 90,
                        height: 50,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: textInputBgColor,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF017A47), width: 1.8),
                            ),
                          ),
                          onChanged: (val) {
                            final num = int.tryParse(val);
                            if (num != null && num > 0) {
                              setModalState(() {
                                localCount = num;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Increment
                      GestureDetector(
                        onTap: () {
                          if (localCount < 200) {
                            setModalState(() {
                              localCount += 5;
                              controller.text = '$localCount';
                            });
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: counterBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: const Icon(Icons.add, size: 20, color: Color(0xFF017A47)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _subjectQuestionCounts[id] = localCount;
                          _totalTimeMinutes = _calculatedTotalQuestions;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF017A47),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'নিশ্চিত করো',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showEditTotalTimeModal() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade300;
    final counterBgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F4F1);
    final textInputBgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7F6);

    final controller = TextEditingController(text: '$_totalTimeMinutes');
    int localTime = _totalTimeMinutes;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'মোট সময় (মিনিট)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: subTextColor),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Decrement
                      GestureDetector(
                        onTap: () {
                          if (localTime > 5) {
                            setModalState(() {
                              localTime -= 5;
                              controller.text = '$localTime';
                            });
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: counterBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: const Icon(Icons.remove, size: 20, color: Color(0xFF017A47)),
                        ),
                      ),
                      const SizedBox(width: 20),
                      SizedBox(
                        width: 90,
                        height: 50,
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: textInputBgColor,
                            contentPadding: EdgeInsets.zero,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF017A47), width: 1.8),
                            ),
                          ),
                          onChanged: (val) {
                            final num = int.tryParse(val);
                            if (num != null && num > 0) {
                              setModalState(() {
                                localTime = num;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Increment
                      GestureDetector(
                        onTap: () {
                          if (localTime < 300) {
                            setModalState(() {
                              localTime += 5;
                              controller.text = '$localTime';
                            });
                          }
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: counterBgColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: const Icon(Icons.add, size: 20, color: Color(0xFF017A47)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _totalTimeMinutes = localTime;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF017A47),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'নিশ্চিত করো',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
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

    final uniqueTopicStandards = <String>{};
    curriculumAsync.whenData((subjectsList) {
      const allowedStandardNames = {'Engineering', 'Varsity', 'Medical', 'Academic', 'Main Book'};
      for (var subject in subjectsList) {
        final sId = subject['id'] as String? ?? '';
        if (!selectedSubjectIds.contains(sId)) continue;
        
        final chapters = (subject['chapters'] as List<dynamic>?) ?? [];
        for (var chapter in chapters) {
          final cId = chapter['id'] as String? ?? '';
          final isChSelected = selectedChapterIds.contains(cId);
          final topics = (chapter['topics'] as List<dynamic>?) ?? [];

          bool anyTopicSelected = false;
          for (var topic in topics) {
            final tId = topic['id'] as String? ?? '';
            if (selectedTopicIds.isEmpty || selectedTopicIds.contains(tId)) {
              anyTopicSelected = true;
              final stds = (topic['standards'] as List<dynamic>?)?.cast<String>() ?? [];
              for (var std in stds) {
                if (allowedStandardNames.contains(std)) {
                  uniqueTopicStandards.add(std);
                }
              }
            }
          }

          // If chapter is selected or topics in chapter are selected, also check chapter standards
          if (isChSelected || anyTopicSelected || selectedTopicIds.isEmpty) {
            final chStds = (chapter['standards'] as List<dynamic>?)?.cast<String>() ?? [];
            for (var std in chStds) {
              if (allowedStandardNames.contains(std)) {
                uniqueTopicStandards.add(std);
              }
            }
          }
        }
      }
    });

    if (!_hasInitializedStandards && uniqueTopicStandards.isNotEmpty) {
      _hasInitializedStandards = true;
      final standardKeyMap = {
        'Engineering': 'engineering',
        'Varsity': 'varsity',
        'Medical': 'medical',
        'Academic': 'hsc',
        'Main Book': 'main_book',
      };
      for (var stdName in uniqueTopicStandards) {
        final key = standardKeyMap[stdName];
        if (key != null) {
          _selectedStandardKeys.add(key);
        }
      }
    }

    curriculumAsync.whenData((subjectsList) {
      for (var subject in subjectsList) {
        final sId = subject['id'] as String? ?? '';
        if (!selectedSubjectIds.contains(sId)) continue;

        final chapters = (subject['chapters'] as List<dynamic>?) ?? [];
        for (var chapter in chapters) {
          final cId = chapter['id'] as String? ?? '';
          final isChSelected = selectedChapterIds.contains(cId);
          final topics = (chapter['topics'] as List<dynamic>?) ?? [];

          bool anyTopicSelected = false;
          for (var topic in topics) {
            final tId = topic['id'] as String? ?? '';
            if (selectedTopicIds.isEmpty || selectedTopicIds.contains(tId)) {
              anyTopicSelected = true;
              final types = (topic['questionTypes'] as List<dynamic>?)?.cast<String>() ?? [];
              for (var t in types) {
                final mapped = _mapDbQuestionType(t);
                if (mapped != null) {
                  availableTypes.add(mapped);
                }
              }
            }
          }

          // If chapter is selected, or any topic in this chapter was selected, or if availableTypes is empty:
          // ALSO collect from chapter['questionTypes'] (handles direct chapter questions added via admin panel)
          if (isChSelected || anyTopicSelected || selectedChapterIds.isEmpty || selectedTopicIds.isEmpty) {
            final types = (chapter['questionTypes'] as List<dynamic>?)?.cast<String>() ?? [];
            for (var t in types) {
              final mapped = _mapDbQuestionType(t);
              if (mapped != null) {
                availableTypes.add(mapped);
              }
            }
          }
        }

        // Also check subject questionTypes
        final types = (subject['questionTypes'] as List<dynamic>?)?.cast<String>() ?? [];
        for (var t in types) {
          final mapped = _mapDbQuestionType(t);
          if (mapped != null) {
            availableTypes.add(mapped);
          }
        }
      }
    });

    // Default fallback: Always ensure MCQ is available so question types never disappear
    if (availableTypes.isEmpty) {
      availableTypes.add('MCQ');
    }

    final isCurriculumLoading = curriculumAsync.isLoading;
    final typesToDisplay = availableTypes.isNotEmpty ? availableTypes.toList() : <String>['MCQ'];

    const sortOrder = ['MCQ', 'CQ', 'WRITTEN', 'FILL'];
    typesToDisplay.sort((a, b) {
      final indexA = sortOrder.indexOf(a);
      final indexB = sortOrder.indexOf(b);
      if (indexA == -1) return 1;
      if (indexB == -1) return -1;
      return indexA.compareTo(indexB);
    });

    if (!typesToDisplay.contains(_selectedQuestionType)) {
      _selectedQuestionType = typesToDisplay.first;
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF4F5F7);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white70 : Colors.black54;
    final mutedTextColor = isDark ? Colors.white54 : Colors.black45;
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFECEFF1);
    final progressTrackBg = isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE3E7E4);
    final stepsBgColor = isDark ? const Color(0xFF017A47).withOpacity(0.2) : const Color(0xFFD4E8DC);
    final selectPillBgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F4F1);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CustomBackButton(
          color: textColor,
          onPressed: () => context.pop(),
        ),
        title: Text(
          'নিশ্চিত করো',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TweenAnimationBuilder<double>(
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
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: stepsBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF017A47).withOpacity(0.12)),
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
          ),
        ],
      ),
      body: Column(
        children: [
            // Step Progress bar (2 segments) with smooth fill animations
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF017A47),
                        borderRadius: BorderRadius.circular(2.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF017A47).withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: progressTrackBg,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 0.5),
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
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Selected Subjects Section ("সিলেক্টেড বিষয়")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'সিলেক্টেড বিষয় (${selectedSubjects.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textColor,
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
                    Column(
                      children: List.generate(selectedSubjects.length, (index) {
                        final sub = selectedSubjects[index];
                        final id = sub['id'] as String? ?? '';
                        final name = sub['name'] as String? ?? 'বিষয়';
                        final count = _subjectQuestionCounts[id] ?? 25;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GestureDetector(
                            onTap: () => _showEditSubjectQuestionCountModal(id, name, count),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: borderColor),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.015),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF017A47),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF017A47).withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF017A47).withOpacity(0.12)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF017A47)),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$count',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF017A47),
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        const Text(
                                          'টি',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF017A47),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // 2. Question Type Selection ("প্রশ্নের ধরন")
                    Text(
                      'প্রশ্নের ধরন',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final totalWidth = constraints.maxWidth;
                        final totalItems = typesToDisplay.length;
                        if (totalItems == 0) return const SizedBox.shrink();

                        final itemWidth = totalWidth / totalItems;
                        final selectedIndex = typesToDisplay.indexOf(_selectedQuestionType);

                        return Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: selectPillBgColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Sliding Green Indicator Pill
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                left: selectedIndex * itemWidth + 2.0,
                                top: 2.0,
                                width: itemWidth - 4.0,
                                height: 38,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF017A47),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),

                              // Text Items Layer
                              Row(
                                children: List.generate(totalItems, (index) {
                                  final type = typesToDisplay[index];
                                  final isSelected = _selectedQuestionType == type;

                                  return Expanded(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        setState(() {
                                          _selectedQuestionType = type;
                                        });
                                      },
                                      child: Center(
                                        child: AnimatedDefaultTextStyle(
                                          duration: const Duration(milliseconds: 200),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : subTextColor,
                                          ),
                                          child: Text(type),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    if (uniqueTopicStandards.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'স্ট্যান্ডার্ডস',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final standardsList = uniqueTopicStandards.toList();
                          final totalItems = standardsList.length;
                          if (totalItems == 0) return const SizedBox.shrink();

                          final standardKeyMap = {
                            'Engineering': 'engineering',
                            'Varsity': 'varsity',
                            'Medical': 'medical',
                            'Academic': 'hsc',
                            'Main Book': 'main_book',
                          };

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 4.5,
                            ),
                            itemCount: totalItems,
                            itemBuilder: (context, index) {
                              final stdName = standardsList[index];
                              final key = standardKeyMap[stdName] ?? '';
                              final isSelected = _selectedStandardKeys.contains(key);

                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? const Color(0xFF017A47).withOpacity(0.04) 
                                      : cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected 
                                        ? const Color(0xFF017A47) 
                                        : borderColor,
                                    width: isSelected ? 1.5 : 1.0,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        if (_selectedStandardKeys.length > 1) {
                                          _selectedStandardKeys.remove(key);
                                        }
                                      } else {
                                        _selectedStandardKeys.add(key);
                                      }
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Center(
                                    child: Text(
                                      stdName,
                                      style: TextStyle(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected 
                                            ? const Color(0xFF017A47) 
                                            : textColor.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // 3. Selected Topics Accordion (with smooth AnimatedSize and AnimatedRotation)
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.01),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
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
                                  Text(
                                    'সিলেক্টেড টপিকস দেখতে এখানে ট্যাপ করো',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                  AnimatedRotation(
                                    turns: _isTopicsExpanded ? 0.5 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      color: subTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: _isTopicsExpanded
                                ? Column(
                                    children: [
                                      Divider(height: 1, color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFEEEEEE)),
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
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: mutedTextColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Padding(
                                                    padding: const EdgeInsets.only(left: 16.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: topicsList.map((t) => Padding(
                                                            padding: const EdgeInsets.only(bottom: 4.0),
                                                            child: Text(
                                                              t,
                                                              style: TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w600,
                                                                color: textColor,
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
                                  )
                                : const SizedBox(width: double.infinity, height: 0),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Section: Total Time & Start Exam Button with rounded top corners matching TopicSelectionScreen
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                    children: [
                      Text(
                        'মোট সময়',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showEditTotalTimeModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selectPillBgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$_totalTimeMinutes',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF017A47),
                                  ),
                                ),
                                const Row(
                                  children: [
                                    Text(
                                      'মিনিট',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF017A47),
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF017A47)),
                                  ],
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
                                  if (_selectedStandardKeys.isNotEmpty)
                                    'quesStandard': _selectedStandardKeys.join(','),
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
            ),
          ],
        ),
    );
  }
}
