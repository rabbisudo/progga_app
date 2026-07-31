import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../academics/data/academics_repository.dart';
import 'practice_notifier.dart';

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
  final Set<String> _selectedTopicIds = {};
  final Set<String> _selectedChapterIds = {};
  int _selectedQuestionCount = 25;

  void _toggleTopic(String topicId, String chapterId, List<dynamic> chapterTopics) {
    setState(() {
      if (_selectedTopicIds.contains(topicId)) {
        _selectedTopicIds.remove(topicId);
      } else {
        _selectedTopicIds.add(topicId);
      }

      // Check if all topics in chapter are selected
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

  void _showQuestionCountPicker() {
    showModalBottomSheet(
      context: context,
      elevation: 0,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'প্রশ্নের সংখ্যা নির্বাচন করুন',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [10, 15, 20, 25, 30, 40, 50].map((count) {
                  final isSelected = _selectedQuestionCount == count;
                  return ChoiceChip(
                    label: Text('$count টি প্রশ্ন', style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: const Color(0xFF017A47),
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedQuestionCount = count;
                        });
                        Navigator.pop(context);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
        // Find targeted subject data
        final subject = subjects.firstWhere(
          (s) => s['id'] == widget.subjectId,
          orElse: () => <String, dynamic>{},
        );

        final chapters = (subject['chapters'] as List<dynamic>?) ?? [];

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F3),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F3),
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.pop(),
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4E8DC),
                      borderRadius: BorderRadius.circular(20),
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
            ],
          ),
          body: Column(
            children: [
              // Segmented progress indicator bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF017A47),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E7E4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Chapters & Topics List View
              Expanded(
                child: chapters.isEmpty
                    ? const Center(
                        child: Text(
                          'এই বিষয়ের কোনো অধ্যায় পাওয়া যায়নি।',
                          style: TextStyle(color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        physics: const BouncingScrollPhysics(),
                        itemCount: chapters.length,
                        itemBuilder: (context, index) {
                          return _buildChapterBlock(chapters[index]);
                        },
                      ),
              ),

              // Bottom Action Banner matching the exact screenshot layout
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
                      // Question Count Input Selector Row
                      GestureDetector(
                        onTap: _showQuestionCountPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECECEC),
                            borderRadius: BorderRadius.circular(12),
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
                                  Text(
                                    '$_selectedQuestionCount',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.unfold_more, size: 16, color: Colors.black54),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Action Buttons Row: + আরেকটি বিষয় and এগিয়ে যাও
                      Row(
                        children: [
                          // Left Button: + আরেকটি বিষয়
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                context.pop(); // Go back to subject selection to add another subject
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

                          // Right Button: এগিয়ে যাও
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final firstSelectedChapter = _selectedChapterIds.isNotEmpty
                                    ? _selectedChapterIds.first
                                    : (chapters.isNotEmpty ? chapters.first['id'] : null);

                                ref.read(practiceProvider.notifier).updateFilters(
                                  subjectId: widget.subjectId,
                                  chapterId: firstSelectedChapter,
                                );

                                context.push('/exam/${widget.subjectId}');
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

  Widget _buildChapterBlock(Map<String, dynamic> chapter) {
    final chapterId = chapter['id'] as String;
    final chapterName = chapter['name'] ?? 'অধ্যায়';
    final topics = (chapter['topics'] as List<dynamic>?) ?? [];
    final isChapterSelected = _selectedChapterIds.contains(chapterId);

    final solvedChapterQuestions = chapter['solvedQuestions'] ?? 0;
    final totalChapterQuestions = chapter['totalQuestions'] ?? (chapter['questionCount'] ?? 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chapter Main Header Card
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            splashColor: const Color(0xFF017A47).withOpacity(0.12),
            highlightColor: const Color(0xFF017A47).withOpacity(0.05),
            onTap: () => _toggleChapter(chapterId, topics),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildCheckboxWidget(isChapterSelected),
                      const SizedBox(width: 10),
                      Text(
                        chapterName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$solvedChapterQuestions/$totalChapterQuestions টি',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Subtopics Wrapper Container with Left Vertical Tree Line (No separate background color)
        if (topics.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
            child: Stack(
              children: [
                // Vertical branch line on the left
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 12,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                // Indented Subtopic Cards
                Padding(
                  padding: const EdgeInsets.only(left: 14),
                  child: Column(
                    children: topics.map((t) {
                      final topicMap = t as Map<String, dynamic>;
                      final topicId = topicMap['id'] as String;
                      final topicName = topicMap['name'] ?? 'টপিক';
                      final isTopicSelected = _selectedTopicIds.contains(topicId);
                      final solvedTopicQuestions = topicMap['solvedQuestions'] ?? 0;
                      final totalTopicQuestions = topicMap['totalQuestions'] ?? (topicMap['questionCount'] ?? 0);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          splashColor: const Color(0xFF017A47).withOpacity(0.12),
                          highlightColor: const Color(0xFF017A47).withOpacity(0.05),
                          onTap: () => _toggleTopic(topicId, chapterId, topics),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    _buildCheckboxWidget(isTopicSelected),
                                    const SizedBox(width: 10),
                                    Text(
                                      topicName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$solvedTopicQuestions/$totalTopicQuestions',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isChecked ? const Color(0xFF017A47) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isChecked ? const Color(0xFF017A47) : const Color(0xFFB0B0B0),
          width: 1.5,
        ),
      ),
      child: isChecked
          ? const Icon(
              Icons.check,
              size: 14,
              color: Colors.white,
            )
          : null,
    );
  }
}
