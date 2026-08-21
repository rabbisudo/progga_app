import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../exam/data/exam_repository.dart';
import '../../question/presentation/widgets/shimmer_skeleton.dart';
import '../../../core/widgets/custom_back_button.dart';

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
                      color: const Color(0xFF017A47).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_toBengaliDigits(questions.length.toString())}টি প্রশ্ন',
                      style: const TextStyle(
                        color: Color(0xFF017A47),
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
        color: const Color(0xFF017A47),
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
                        backgroundColor: const Color(0xFF017A47),
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
                            color: const Color(0xFF017A47).withOpacity(0.08),
                          ),
                          child: const Icon(
                            Icons.bookmark_border_rounded,
                            color: Color(0xFF017A47),
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
                            selectedColor: const Color(0xFF017A47),
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
                                      color: const Color(0xFF017A47)
                                          .withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'প্রশ্ন ${_toBengaliDigits((index + 1).toString())}',
                                      style: const TextStyle(
                                        color: Color(0xFF017A47),
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
                                questionText,
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
                                        ? const Color(0xFF14221A)
                                        : const Color(0xFFF4F9F6),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF0D5E35)
                                            : const Color(0xFFD4E8DC)),
                                  ),
                                  child: Math.tex(
                                    latexFormula,
                                    textStyle: const TextStyle(
                                        fontSize: 16, color: Color(0xFF017A47)),
                                    onErrorFallback: (err) => Text(
                                      latexFormula,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontStyle: FontStyle.italic,
                                          color: Color(0xFF017A47)),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Options list with Correct Answer Highlighted
                              if (options.isNotEmpty) ...[
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
                                        ? const Color(0xFF00381C)
                                        : const Color(0xFFE8F5E9);
                                    labelBgColor = const Color(0xFF017A47);
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
                                              ? const Color(0xFF017A47)
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
                                                            0xFF017A47)
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
                                                  color: Color(0xFF017A47),
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

  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return htmlString;
    String result = htmlString;
    // Replace block-level tags or line breaks first
    result = result.replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp(r'</li>\s*<li>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp(r'</div>\s*<div>', caseSensitive: false), '\n');
    // Replace common HTML entities
    result = result.replaceAll('&nbsp;', ' ');
    result = result.replaceAll('&amp;', '&');
    result = result.replaceAll('&lt;', '<');
    result = result.replaceAll('&gt;', '>');
    result = result.replaceAll('&quot;', '"');
    result = result.replaceAll('&#39;', "'");
    result = result.replaceAll('&#27;', "'");
    result = result.replaceAll('&deg;', '°');
    result = result.replaceAll('&times;', '×');
    result = result.replaceAll('&divide;', '÷');
    result = result.replaceAll('&plusmn;', '±');
    result = result.replaceAll('&hellip;', '...');
    result = result.replaceAll('&mdash;', '—');
    result = result.replaceAll('&ndash;', '–');
    // Remove all remaining HTML tags
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    return result.trim();
  }

  String _fixBrokenLatex(String text) {
    if (text.isEmpty) return text;

    // 1. Restore control characters escaped during JSON transmission (\f -> \frac, \t -> \text / \times)
    String cleaned = text
        .replaceAll('\x0C', r'\f')
        .replaceAll('\f', r'\f')
        .replaceAll('\x09', r'\t')
        .replaceAll('\t', r'\t');

    // 2. Auto-repair stripped backslashes in common KaTeX/LaTeX keywords
    cleaned = cleaned
        .replaceAll(RegExp(r'(?<!\\)\brac\{'), r'\frac{')
        .replaceAll(RegExp(r'(?<!\\)\bext\{'), r'\text{')
        .replaceAll(RegExp(r'(?<!\\)\bimes\b'), r'\times')
        .replaceAll(RegExp(r'(?<!\\)\bsqrt\{'), r'\sqrt{')
        .replaceAll(RegExp(r'(?<!\\)\balpha\b'), r'\alpha')
        .replaceAll(RegExp(r'(?<!\\)\bbeta\b'), r'\beta')
        .replaceAll(RegExp(r'(?<!\\)\btheta\b'), r'\theta')
        .replaceAll(RegExp(r'(?<!\\)\bpi\b'), r'\pi');

    // 3. Auto-wrap subscripts like v_{avg}, v_{1}, x_{max} into $v_{avg}$ if not inside $
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\$)\b([a-zA-Z])_\{([^\}]+)\}(?!\$)'),
      (m) => '\$${m.group(1)}_${m.group(2)}\$',
    );

    // 4. Auto-wrap superscripts like x^2, t^2 into $x^2$ if not inside $
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\$)\b([a-zA-Z0-9]+)\^\{?([a-zA-Z0-9\+\-]+)\}?(?!\$)'),
      (m) => '\$${m.group(1)}^${m.group(2)}\$',
    );

    // 5. Advanced brace-matching scanner for nested \frac{...}{...} and \sqrt{...}
    final sb = StringBuffer();
    int i = 0;

    while (i < cleaned.length) {
      if (cleaned[i] == '\$') {
        int nextDollar = cleaned.indexOf('\$', i + 1);
        if (nextDollar != -1) {
          sb.write(cleaned.substring(i, nextDollar + 1));
          i = nextDollar + 1;
          continue;
        }
      }

      if (cleaned.startsWith(r'\frac', i) || cleaned.startsWith(r'\sqrt', i)) {
        int start = i;
        int cmdLen = 5;
        i += cmdLen;

        int openBraces = 0;
        bool foundAnyBrace = false;

        while (i < cleaned.length) {
          if (cleaned[i] == '{') {
            openBraces++;
            foundAnyBrace = true;
          } else if (cleaned[i] == '}') {
            openBraces--;
          }

          i++;

          if (foundAnyBrace && openBraces == 0) {
            int tempPeek = i;
            while (tempPeek < cleaned.length && cleaned[tempPeek].trim().isEmpty) {
              tempPeek++;
            }
            if (tempPeek < cleaned.length && cleaned[tempPeek] == '{') {
              i = tempPeek;
              continue;
            }
            break;
          }
        }

        String texExpr = cleaned.substring(start, i);
        sb.write('\$$texExpr\$');
      } else {
        sb.write(cleaned[i]);
        i++;
      }
    }

    cleaned = sb.toString();

    // 6. Replace raw \times, \div, \pm in text with clean symbols if outside $
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\$)\\times(?!\$)'),
      (m) => '×',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\$)\\div(?!\$)'),
      (m) => '÷',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\$)\\pm(?!\$)'),
      (m) => '±',
    );

    return cleaned;
  }

  Widget _buildResultMathWidget(
    String rawText, {
    TextStyle? textStyle,
    Color? mathColor,
    double fontSize = 14,
  }) {
    if (rawText.isEmpty) return const SizedBox.shrink();

    final imgConverted = rawText.replaceAllMapped(
      RegExp(r'''<img[^>]+src=["']([^"']+)["'][^>]*>''', caseSensitive: false),
      (match) => '[IMAGE: ${match.group(1)}]',
    );
    final text = _fixBrokenLatex(_stripHtml(imgConverted));

    // 1. Check for embedded [IMAGE: url] tags
    final imageRegex = RegExp(r'\[IMAGE:\s*([^\]]+)\]', caseSensitive: false);
    if (imageRegex.hasMatch(text)) {
      final List<Widget> widgets = [];
      int lastIndex = 0;

      for (final Match match in imageRegex.allMatches(text)) {
        if (match.start > lastIndex) {
          final textPart = text.substring(lastIndex, match.start).trim();
          if (textPart.isNotEmpty) {
            widgets.add(_buildResultMathWidget(
              textPart,
              textStyle: textStyle,
              mathColor: mathColor,
              fontSize: fontSize,
            ));
          }
        }

        final imageUrl = match.group(1)!.trim();
        widgets.add(_buildQuestionImage(imageUrl));

        lastIndex = match.end;
      }

      if (lastIndex < text.length) {
        final remainingText = text.substring(lastIndex).trim();
        if (remainingText.isNotEmpty) {
          widgets.add(_buildResultMathWidget(
            remainingText,
            textStyle: textStyle,
            mathColor: mathColor,
            fontSize: fontSize,
          ));
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    }

    // Handle multiline text with individual math lines
    if (text.contains('\n')) {
      final lines = text.split('\n');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lines.map((line) {
          if (line.trim().isEmpty) return const SizedBox(height: 4);
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: _buildResultMathWidget(
              line,
              textStyle: textStyle,
              mathColor: mathColor,
              fontSize: fontSize,
            ),
          );
        }).toList(),
      );
    }

    // 3. Normalize delimiters: $$, \(...\), \[...\] to $...$
    String normalizedText = text
        .replaceAll(RegExp(r'\$\$(.*?)\$\$', dotAll: true), r'$ $1 $')
        .replaceAll(RegExp(r'\\\((.*?)\\\)', dotAll: true), r'$ $1 $')
        .replaceAll(RegExp(r'\\\[(.*?)\\\]', dotAll: true), r'$ $1 $');

    final activeColor = mathColor ?? textStyle?.color ?? Colors.black87;
    final defaultStyle = textStyle ??
        TextStyle(
            fontSize: fontSize,
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            height: 1.4);

    // 4. If text has explicit $...$ inline math delimiters
    if (normalizedText.contains('\$')) {
      final List<InlineSpan> spans = [];
      final RegExp regex = RegExp(r'\$([^\$]+)\$');
      int lastMatchEnd = 0;

      for (final Match match in regex.allMatches(normalizedText)) {
        if (match.start > lastMatchEnd) {
          spans.add(TextSpan(
            text: normalizedText.substring(lastMatchEnd, match.start),
            style: defaultStyle,
          ));
        }

        final latexStr = match.group(1)!.trim();
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Math.tex(
                latexStr,
                textStyle:
                    TextStyle(fontSize: fontSize + 1, color: activeColor),
                onErrorFallback: (err) => Text(
                  latexStr,
                  style: TextStyle(
                      fontSize: fontSize,
                      color: activeColor,
                      fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ),
        ));

        lastMatchEnd = match.end;
      }

      if (lastMatchEnd < normalizedText.length) {
        spans.add(TextSpan(
          text: normalizedText.substring(lastMatchEnd),
          style: defaultStyle,
        ));
      }

      return RichText(
        softWrap: true,
        text: TextSpan(children: spans),
      );
    }

    // 5. Bengali mixed with LaTeX patterns
    final hasBengali = normalizedText.contains(RegExp(r'[\u0980-\u09FF]'));
    if (hasBengali) {
      final texMatch = RegExp(
          r'(\\(frac|sqrt|text|times|div|pm|degree)\{[^\}]*\}(?:\{[^\}]*\})?|[a-zA-Z]\s*=\s*\\[a-zA-Z]+[^\s,]*)');
      if (texMatch.hasMatch(normalizedText)) {
        final List<InlineSpan> spans = [];
        int lastEnd = 0;

        for (final Match m in texMatch.allMatches(normalizedText)) {
          if (m.start > lastEnd) {
            spans.add(TextSpan(
              text: normalizedText.substring(lastEnd, m.start),
              style: defaultStyle,
            ));
          }

          final mathCode = m.group(0)!;
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: Math.tex(
                mathCode,
                textStyle:
                    TextStyle(fontSize: fontSize + 1, color: activeColor),
                onErrorFallback: (err) =>
                    Text(mathCode, style: defaultStyle),
              ),
            ),
          ));

          lastEnd = m.end;
        }

        if (lastEnd < normalizedText.length) {
          spans.add(TextSpan(
            text: normalizedText.substring(lastEnd),
            style: defaultStyle,
          ));
        }

        return RichText(
          softWrap: true,
          text: TextSpan(children: spans),
        );
      }

      return Text(
        normalizedText,
        style: defaultStyle,
      );
    }

    // 6. Pure math expressions
    if (normalizedText.trim().startsWith('\\') ||
        normalizedText.contains(RegExp(
            r'\\(frac|sqrt|sum|int|lim|alpha|beta|theta|pi|infty|vec|times|div|pm|degree)')) ||
        normalizedText
            .contains(RegExp(r'^[a-zA-Z0-9\s=\+\-\*/\^_\(\)\{\}\\]+$'))) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Math.tex(
          normalizedText.trim(),
          textStyle: TextStyle(fontSize: fontSize + 1, color: activeColor),
          onErrorFallback: (err) => Text(
            normalizedText,
            style: defaultStyle,
          ),
        ),
      );
    }

    return Text(
      normalizedText,
      style: defaultStyle,
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
                  color: const Color(0xFF017A47).withOpacity(0.7),
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
                    backgroundColor: const Color(0xFF017A47),
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
        color: isDark ? const Color(0xFF1E3A24) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)),
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
                      color: const Color(0xFF017A47).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF017A47), size: 18),
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
                            color: Color(0xFF017A47),
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF017A47)),
                    )
                  else
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF017A47),
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
                  const Divider(color: Color(0xFFA7F3D0)),
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

