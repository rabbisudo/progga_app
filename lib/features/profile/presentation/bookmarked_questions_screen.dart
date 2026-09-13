import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../exam/data/exam_repository.dart';
import '../../question/presentation/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/app_math_text.dart';

final bookmarkedQuestionsProvider = StateNotifierProvider.autoDispose<
    BookmarkedQuestionsNotifier, AsyncValue<List<dynamic>>>((ref) {
  final repo = ref.watch(examRepositoryProvider);
  return BookmarkedQuestionsNotifier(repo);
});

class BookmarkedQuestionsNotifier
    extends StateNotifier<AsyncValue<List<dynamic>>> {
  final ExamRepository _repo;

  BookmarkedQuestionsNotifier(this._repo) : super(const AsyncValue.loading()) {
    fetchBookmarks();
  }

  Future<void> fetchBookmarks({bool isSilent = false}) async {
    // Only show full loading if we have no existing data or if explicitly requested
    if (!isSilent && state.valueOrNull == null) {
      state = const AsyncValue.loading();
    }
    try {
      final list = await _repo.getBookmarkedQuestions();
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (state.valueOrNull == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> removeBookmark(String questionId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic local update
    state = AsyncValue.data(
      current.where((q) => q['id'] != questionId).toList(),
    );

    try {
      await _repo.toggleBookmark(questionId);
    } catch (_) {
      // Revert if error occurs
      state = AsyncValue.data(current);
    }
  }
}

class BookmarkedQuestionsScreen extends ConsumerStatefulWidget {
  const BookmarkedQuestionsScreen({super.key});

  @override
  ConsumerState<BookmarkedQuestionsScreen> createState() =>
      _BookmarkedQuestionsScreenState();
}

class _BookmarkedQuestionsScreenState
    extends ConsumerState<BookmarkedQuestionsScreen> {
  String _selectedSubject = 'ALL';

  String _toBengaliDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(english[i], bengali[i]);
    }
    return result;
  }

  String _getOptionLabel(int index) {
    const bengaliLetters = ['ক', 'খ', 'গ', 'ঘ', 'ঙ'];
    if (index >= 0 && index < bengaliLetters.length) {
      return bengaliLetters[index];
    }
    return String.fromCharCode(65 + index);
  }

  bool _isFitbQuestion(String? rawType, String questionText) {
    final type = (rawType ?? '').toUpperCase().trim();
    if (type == 'FILL_IN_THE_GAP' ||
        type == 'FILL_IN_THE_GAPS' ||
        type == 'FILL_IN_THE_GAPS_WITHOUT_CLUES' ||
        type == 'FILL' ||
        type.contains('FILL_IN') ||
        type.contains('CLOZE')) {
      return true;
    }
    return questionText.contains('(a)') &&
        RegExp(r'\(([a-z0-9])\)\s*(——|___+|_+|&mdash;|&ndash;|[\u2014\u2013\u002d]+)', caseSensitive: false)
            .hasMatch(questionText);
  }

  String _getPassageWithoutTable(String html) {
    final clean = html.replaceAll(RegExp(r'<table[^>]*>([\s\S]*?)<\/table>', caseSensitive: false), '').trim();
    return clean.replaceAll(RegExp(r'</?span[^>]*>', caseSensitive: false), '');
  }

  List<String> _extractFitbClues(String questionText, List<dynamic> optionsList) {
    final List<String> clues = [];
    final tdRegex = RegExp(r'<td[^>]*>(?:<p>)?(.*?)(?:</p>)?</td>', caseSensitive: false);
    final matches = tdRegex.allMatches(questionText);
    for (final m in matches) {
      final text = m.group(1)!
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .trim();
      if (text.isNotEmpty && !RegExp(r'^\([a-z0-9]\)$', caseSensitive: false).hasMatch(text)) {
        clues.add(text);
      }
    }
    if (clues.isNotEmpty) return clues;

    final Set<String> seen = {};
    for (final opt in optionsList) {
      final rawText = opt is Map
          ? (opt['optionText'] ?? opt['text'] ?? '')
          : opt.toString();
      final clean = rawText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (clean.isNotEmpty &&
          !RegExp(r'^option\s+[a-e]$', caseSensitive: false).hasMatch(clean)) {
        seen.add(clean);
      }
    }
    return seen.toList();
  }

  Map<String, String> _parseFitbAnswers(Map<String, dynamic> qData) {
    final Map<String, String> correctMap = {};
    final optionsList = (qData['options'] as List<dynamic>?) ?? [];

    for (final opt in optionsList) {
      if (opt is Map) {
        final isCorr = opt['isCorrect'];
        final num? idx = (isCorr is num) ? isCorr : num.tryParse(isCorr?.toString() ?? '');
        if (idx != null && idx >= 0 && idx < 26) {
          final key = String.fromCharCode(97 + idx.toInt());
          final val = (opt['optionText'] ?? opt['text'] ?? '')
              .toString()
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          if (val.isNotEmpty) {
            correctMap[key] = val;
          }
        }
      }
    }
    if (correctMap.isNotEmpty) return correctMap;

    var solutionHtml = qData['solution'] as String? ?? '';
    if (solutionHtml.isEmpty && qData['explanations'] != null) {
      final exList = qData['explanations'] as List?;
      if (exList != null && exList.isNotEmpty) {
        final firstEx = exList[0];
        if (firstEx is Map) {
          solutionHtml = firstEx['text'] as String? ?? '';
        }
      }
    }

    if (solutionHtml.isNotEmpty) {
      final pRegex = RegExp(r'\(([a-z0-9])\)\s*([^<;.,\)\n\r]+)', caseSensitive: false);
      final matches = pRegex.allMatches(solutionHtml).toList();
      for (int i = 0; i < matches.length; i++) {
        final m = matches[i];
        var label = m.group(1)!.toLowerCase();
        if (RegExp(r'^\d+$').hasMatch(label)) {
          label = String.fromCharCode(97 + i);
        }
        final val = m.group(2)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (val.isNotEmpty) {
          correctMap[label] = val;
        }
      }
    }

    return correctMap;
  }

  Widget _buildFitbContent(Map<String, dynamic> qData, bool isDark) {
    final rawQuestionText = qData['questionText'] as String? ?? '';
    final qType = (qData['type'] as String? ?? '').toUpperCase().trim();
    final isWithoutClues = qType == 'FILL_IN_THE_GAPS_WITHOUT_CLUES';
    final optionsList = (qData['options'] as List<dynamic>?) ?? [];
    final clues = isWithoutClues ? <String>[] : _extractFitbClues(rawQuestionText, optionsList);
    final answersMap = _parseFitbAnswers(qData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (clues.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C273D) : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 17,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0071F9),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'ক্লুসমূহ (শব্দ ভাণ্ডার):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0071F9),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: clues.map((clue) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFF0071F9).withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        clue,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        if (answersMap.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C203D).withValues(alpha: 0.5) : const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: Color(0xFF0071F9),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'সঠিক উত্তরসমূহ:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0071F9),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: answersMap.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0C273D) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.3) : const Color(0xFF81C784),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '(${entry.key}) ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0071F9),
                            ),
                          ),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksAsync = ref.watch(bookmarkedQuestionsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'বুকমার্ক করা প্রশ্নসমূহ',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
        leading: CustomBackButton(
          color: isDark ? Colors.white : Colors.black87,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          bookmarksAsync.maybeWhen(
            data: (questions) {
              if (questions.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071F9).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_toBengaliDigits(questions.length.toString())}টি প্রশ্ন',
                      style: const TextStyle(
                        color: Color(0xFF0071F9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF0071F9),
        onRefresh: () =>
            ref.read(bookmarkedQuestionsProvider.notifier).fetchBookmarks(isSilent: true),
        child: bookmarksAsync.when(
          loading: () => _buildSkeletonLoading(isDark),
          error: (err, stack) => Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'বুকমার্ক লোড করতে সমস্যা হয়েছে!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0071F9),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => ref
                          .read(bookmarkedQuestionsProvider.notifier)
                          .fetchBookmarks(),
                      child: const Text(
                        'আবার চেষ্টা করুন',
                        style: TextStyle(
                            color: Colors.white, fontFamily: 'Li Ador Noirrit'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (questions) {
            if (questions.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0071F9).withOpacity(0.08),
                          ),
                          child: const Icon(
                            Icons.bookmark_border_rounded,
                            color: Color(0xFF0071F9),
                            size: 64,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'কোনো বুকমার্ক করা প্রশ্ন নেই',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontFamily: 'Li Ador Noirrit',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'পরীক্ষার ফলাফল পেইজে যেকোনো প্রশ্নের বুকমার্ক আইকনে ট্যাপ করে তা এখানে সংরক্ষণ করতে পারেন।',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white38 : Colors.black45,
                            fontFamily: 'Li Ador Noirrit',
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // Extract subjects for filtering
            final Map<String, String> subjectsMap = {'ALL': 'সবগুলো'};
            for (final q in questions) {
              final sub = q['subject'];
              if (sub != null && sub['name'] != null) {
                subjectsMap[sub['id'] ?? sub['name']] = sub['name'];
              }
            }

            final filteredQuestions = _selectedSubject == 'ALL'
                ? questions
                : questions.where((q) {
                    final sub = q['subject'];
                    if (sub == null) return false;
                    final sId = sub['id'] ?? sub['name'];
                    return sId == _selectedSubject;
                  }).toList();

            return Column(
              children: [
                // Subject Filter Bar if multiple subjects
                if (subjectsMap.length > 2)
                  Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: subjectsMap.entries.map((entry) {
                        final isSelected = _selectedSubject == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.white70
                                        : Colors.black87),
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                _selectedSubject = entry.key;
                              });
                            },
                            backgroundColor: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            selectedColor: const Color(0xFF0071F9),
                            checkmarkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isDark
                                        ? Colors.white.withOpacity(0.08)
                                        : Colors.grey.shade200),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredQuestions.length,
                    itemBuilder: (context, index) {
                      final q = filteredQuestions[index];
                      final String qId = q['id'] ?? '';
                      final String questionText = q['questionText'] ?? '';
                      final isFitb = _isFitbQuestion(q['type']?.toString(), questionText);
                      final displayQuestionText = isFitb
                          ? _getPassageWithoutTable(questionText)
                          : questionText;
                      final String? passage = q['passage'];
                      final String? imageKey = q['imageKey'];
                      final String? latexFormula = q['latexFormula'];
                      final List<dynamic> options = q['options'] ?? [];
                      final List<dynamic> explanations = q['explanations'] ?? [];

                      // Badges
                      final subjectName = q['subject']?['name'];
                      final chapterName = q['chapter']?['name'];
                      final boardName = q['board']?['name'];
                      final varsityName = q['varsity']?['name'];
                      final year = q['year'];
                      final source = q['source'];

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.grey.shade200,
                          ),
                        ),
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Bar: Number, Badges, & Unbookmark Button
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0071F9)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'প্রশ্ন ${_toBengaliDigits((index + 1).toString())}',
                                      style: const TextStyle(
                                        color: Color(0xFF0071F9),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Li Ador Noirrit',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (subjectName != null &&
                                      subjectName.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.06)
                                            : Colors.grey.shade100,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        subjectName,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black54,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Li Ador Noirrit',
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  // Unbookmark Button
                                  IconButton(
                                    icon: const Icon(
                                      Icons.bookmark_remove_rounded,
                                      color: Colors.redAccent,
                                      size: 22,
                                    ),
                                    tooltip: 'বুকমার্ক সরান',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      ref
                                          .read(bookmarkedQuestionsProvider
                                              .notifier)
                                          .removeBookmark(qId);
                                    },
                                  ),
                                ],
                              ),

                              // Secondary Info Tags (Chapter, Board, Year, Source)
                              if (chapterName != null ||
                                  boardName != null ||
                                  varsityName != null ||
                                  year != null ||
                                  source != null) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (chapterName != null &&
                                        chapterName.isNotEmpty)
                                      _buildPillTag(
                                          chapterName, isDark, Colors.blue),
                                    if (boardName != null &&
                                        boardName.isNotEmpty)
                                      _buildPillTag(
                                          boardName, isDark, Colors.purple),
                                    if (varsityName != null &&
                                        varsityName.isNotEmpty)
                                      _buildPillTag(varsityName, isDark,
                                          Colors.deepOrange),
                                    if (year != null)
                                      _buildPillTag(
                                          _toBengaliDigits(year.toString()),
                                          isDark,
                                          Colors.teal),
                                    if (source != null &&
                                        source.toString().isNotEmpty)
                                      _buildPillTag(
                                          source.toString(), isDark, Colors.brown),
                                  ],
                                ),
                              ],

                              // Passage / Context if available
                              if (passage != null && passage.trim().isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.04)
                                        : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.grey.shade200,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'উদ্দীপক:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white60
                                              : Colors.black54,
                                          fontFamily: 'Li Ador Noirrit',
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      _buildResultMathWidget(
                                        passage,
                                        textStyle: TextStyle(
                                          fontSize: 13.5,
                                          color: isDark
                                              ? Colors.white70
                                              : Colors.black87,
                                          height: 1.45,
                                          fontFamily: 'Li Ador Noirrit',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),

                              // Question Text
                              _buildResultMathWidget(
                                displayQuestionText,
                                textStyle: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.92)
                                      : Colors.black87,
                                  height: 1.45,
                                  fontFamily: 'Li Ador Noirrit',
                                ),
                              ),

                              if (imageKey != null && imageKey.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildQuestionImage(imageKey),
                              ],

                              if (latexFormula != null &&
                                  latexFormula.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF0C273D)
                                        : const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF0284C7)
                                            : const Color(0xFFBAE6FD)),
                                  ),
                                  child: AppMathText(
                                    text: latexFormula,
                                    fontSize: 16,
                                    mathColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0071F9),
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0071F9),
                                      fontFamily: 'Li Ador Noirrit',
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // FITB clues & answers OR Options list with Correct Answer Highlighted
                              if (isFitb) ...[
                                _buildFitbContent(q, isDark),
                              ] else if (options.isNotEmpty) ...[
                                ...options.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final opt = entry.value;
                                  final String optionText =
                                      opt['optionText'] ?? '';
                                  final String? optImageKey = opt['imageKey'];
                                  final bool isCorrect =
                                      opt['isCorrect'] ?? false;

                                  final label = _getOptionLabel(idx);

                                  Color bgColor = isDark
                                      ? Colors.white.withOpacity(0.02)
                                      : const Color(0xFFFAFAFA);
                                  Color labelBgColor =
                                      isDark ? Colors.white10 : Colors.white;
                                  Color labelTextColor =
                                      isDark ? Colors.white70 : Colors.black54;
                                  Border? labelBorder = Border.all(
                                      color: const Color(0xFFCFD8DC),
                                      width: 1.5);

                                  if (isCorrect) {
                                    bgColor = isDark
                                        ? const Color(0xFF0C203D)
                                        : const Color(0xFFE8F1FF);
                                    labelBgColor = const Color(0xFF0071F9);
                                    labelTextColor = Colors.white;
                                    labelBorder = null;
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 11),
                                      decoration: BoxDecoration(
                                        color: bgColor,
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isCorrect
                                              ? const Color(0xFF0071F9)
                                              : (isDark
                                                  ? Colors.white
                                                      .withOpacity(0.04)
                                                  : Colors.grey.shade100),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                width: 26,
                                                height: 26,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: labelBgColor,
                                                  border: labelBorder,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    label,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: labelTextColor,
                                                      fontFamily:
                                                          'Li Ador Noirrit',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _buildResultMathWidget(
                                                  optionText,
                                                  textStyle: TextStyle(
                                                    fontSize: 13.5,
                                                    fontWeight: isCorrect
                                                        ? FontWeight.w600
                                                        : FontWeight.w400,
                                                    color: isCorrect
                                                        ? const Color(
                                                            0xFF0071F9)
                                                        : (isDark
                                                            ? Colors.white70
                                                            : Colors.black87),
                                                    fontFamily:
                                                        'Li Ador Noirrit',
                                                  ),
                                                ),
                                              ),
                                              if (isCorrect)
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Color(0xFF0071F9),
                                                  size: 18,
                                                ),
                                            ],
                                          ),
                                          if (optImageKey != null &&
                                              optImageKey.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            _buildQuestionImage(optImageKey),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],

                              // Explanation Collapsible Trigger (with daily limit)
                              if (q['hasExplanation'] == true ||
                                  explanations.isNotEmpty) ...[
                                BookmarkedExplanationCard(
                                  questionId: qId,
                                  initialExplanations: explanations,
                                  buildResultMathWidget: _buildResultMathWidget,
                                  buildQuestionImage: _buildQuestionImage,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading(bool isDark) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
            ),
          ),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Question Number badge & Subject badge shimmer
                const Row(
                  children: [
                    ShimmerSkeleton(
                      width: 70,
                      height: 24,
                      borderRadius: 10,
                    ),
                    SizedBox(width: 8),
                    ShimmerSkeleton(
                      width: 60,
                      height: 22,
                      borderRadius: 8,
                    ),
                    Spacer(),
                    ShimmerSkeleton(
                      width: 22,
                      height: 22,
                      borderRadius: 11,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Question text lines shimmer
                const ShimmerSkeleton(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const ShimmerSkeleton(
                  width: 200,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 18),
                // Option cards shimmer
                ...List.generate(4, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade100,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const ShimmerSkeleton(
                          width: 26,
                          height: 26,
                          borderRadius: 13,
                        ),
                        const SizedBox(width: 12),
                        ShimmerSkeleton(
                          width: i % 2 == 0 ? 140 : 180,
                          height: 14,
                          borderRadius: 4,
                        ),
                      ],
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                // Explanation button shimmer
                const ShimmerSkeleton(
                  width: double.infinity,
                  height: 40,
                  borderRadius: 12,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillTag(String text, bool isDark, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? color.withOpacity(0.9) : color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'Li Ador Noirrit',
        ),
      ),
    );
  }


  Widget _buildResultMathWidget(
    String rawText, {
    TextStyle? textStyle,
    Color? mathColor,
    double fontSize = 14,
  }) {
    return AppMathText(
      text: rawText,
      textStyle: textStyle,
      mathColor: mathColor,
      fontSize: fontSize,
      customImageBuilder: (url) => _buildQuestionImage(url),
    );
  }

  Widget _buildQuestionImage(String? imageKey) {
    if (imageKey == null || imageKey.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final String imageUrl;
    final cleanKey = imageKey.trim();
    if (cleanKey.startsWith('http://') || cleanKey.startsWith('https://')) {
      imageUrl = cleanKey;
    } else if (cleanKey.startsWith('/')) {
      imageUrl = 'https://proggadata.twelvemind.com$cleanKey';
    } else {
      imageUrl =
          'https://proggadata.twelvemind.com/api/v1/questions/file/$cleanKey';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: const Color(0xFF0071F9).withOpacity(0.7),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined,
                      color: Colors.grey.shade400, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ছবি লোড করা যায়নি',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'Li Ador Noirrit'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class BookmarkedExplanationCard extends ConsumerStatefulWidget {
  final String questionId;
  final List<dynamic> initialExplanations;
  final Widget Function(String rawText, {TextStyle? textStyle, Color? mathColor, double fontSize}) buildResultMathWidget;
  final Widget Function(String? imageKey) buildQuestionImage;

  const BookmarkedExplanationCard({
    super.key,
    required this.questionId,
    required this.initialExplanations,
    required this.buildResultMathWidget,
    required this.buildQuestionImage,
  });

  @override
  ConsumerState<BookmarkedExplanationCard> createState() => _BookmarkedExplanationCardState();
}

class _BookmarkedExplanationCardState extends ConsumerState<BookmarkedExplanationCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isUnlocked = false;
  List<dynamic> _explanations = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialExplanations.isNotEmpty) {
      _explanations = widget.initialExplanations;
      _isUnlocked = true;
    }
  }

  Future<void> _handleTap() async {
    if (_isUnlocked) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(examRepositoryProvider);
      final res = await repo.unlockExplanation(widget.questionId);

      if (mounted) {
        setState(() {
          _explanations = res['explanations'] as List<dynamic>? ?? [];
          _isUnlocked = true;
          _isExpanded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showLimitDialog(context);
      }
    }
  }

  void _showLimitDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3E2D00) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_outlined, color: Color(0xFFF59E0B), size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'দৈনিক ব্যাখ্যা সীমা অতিক্রান্ত!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Li Ador Noirrit'),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনি আজকের ১০টি দৈনিক ব্যাখ্যা দেখার সীমা সম্পূর্ণ করেছেন। আগামীকাল নতুন করে ১০টি ব্যাখ্যা আনলক করতে পারবেন।',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600, height: 1.4, fontFamily: 'Li Ador Noirrit'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0071F9),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Li Ador Noirrit'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0C273D) : const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _isLoading ? null : _handleTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0071F9).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF0071F9), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ব্যাখ্যা',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0071F9),
                            fontFamily: 'Li Ador Noirrit',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0071F9)),
                    )
                  else
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF0071F9),
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded && _explanations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFBAE6FD)),
                  const SizedBox(height: 6),
                  ..._explanations.map((expData) {
                    final expMap = expData as Map<String, dynamic>;
                    final expText = expMap['text'] as String? ?? '';
                    final expImgKey = expMap['imageKey'] as String?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        widget.buildResultMathWidget(
                          expText,
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                            fontFamily: 'Li Ador Noirrit',
                          ),
                        ),
                        if (expImgKey != null && expImgKey.isNotEmpty)
                          widget.buildQuestionImage(expImgKey),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

