import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'exam_runner_notifier.dart';
import 'package:go_router/go_router.dart';

class ExamScreen extends ConsumerStatefulWidget {
  final String id;
  final String? subjectId;
  final String? chapterId;
  final String? topicId;
  final int? limit;
  final int? timeMinutes;

  const ExamScreen({
    super.key,
    required this.id,
    this.subjectId,
    this.chapterId,
    this.topicId,
    this.limit,
    this.timeMinutes,
  });

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timeSpentTracker;

  @override
  void initState() {
    super.initState();

    // Trigger initial session setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(examRunnerProvider.notifier).initializeExam(
            widget.id,
            subjectId: widget.subjectId,
            chapterId: widget.chapterId,
            topicId: widget.topicId,
            limit: widget.limit,
            timeMinutes: widget.timeMinutes,
          );
    });

    // Track active exam timers every second
    _timeSpentTracker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final state = ref.read(examRunnerProvider);
      if (state.exam != null && state.exam!.questions.isNotEmpty) {
        // Increment time spent for all questions or first unanswered
        final activeQId = state.exam!.questions.first.question.id;
        ref.read(examRunnerProvider.notifier).incrementTimeSpent(activeQId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timeSpentTracker?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<bool> _onWillPop() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('পরীক্ষা বাতিল করতে চান?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('এখন বের হয়ে গেলে আপনার বর্তমান উত্তরগুলো সংরক্ষিত জমা হয়ে যাবে।'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ফিরে যাও', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('বাহির হও', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  Future<void> _confirmAndSubmitExam() async {
    final state = ref.read(examRunnerProvider);
    final totalQ = state.exam?.questions.length ?? 0;
    final answeredCount = state.selectedOptions.values.where((opt) => opt != null).length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('পরীক্ষা জমা দিতে চান?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('আপনি $totalQ টি প্রশ্নের মধ্যে $answeredCount টির উত্তর দিয়েছেন।\nনিশ্চিতভাবে পরীক্ষা জমা দিতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('বাতিল', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF017A47),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('জমা দাও', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final submitResult = await ref.read(examRunnerProvider.notifier).submitExam();
      if (submitResult != null && context.mounted) {
        context.pushReplacement('/result/${submitResult.id}');
      }
    }
  }

  String _toBengaliDigit(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String str = '$number';
    for (int i = 0; i < english.length; i++) {
      str = str.replaceAll(english[i], bengali[i]);
    }
    return str;
  }

  String _getOptionLabel(int index) {
    const labels = ['ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examRunnerProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F3),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF017A47)),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F4F3),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage!,
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF017A47),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('ফিরে যান', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.exam == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F4F3),
        body: Center(
          child: Text('পরীক্ষার সময়সূচী লোড হচ্ছে...', style: TextStyle(color: Colors.black87)),
        ),
      );
    }

    final questions = state.exam!.questions;
    final totalQuestions = questions.length;
    final answeredCount = state.selectedOptions.values.where((opt) => opt != null).length;
    final isLowTime = state.timeLeft < 120;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          ref.read(examRunnerProvider.notifier).submitExam();
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F4F3),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            state.exam!.title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                ref.read(examRunnerProvider.notifier).submitExam();
                context.pop();
              }
            },
          ),
          actions: [
            // Timer alert badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: isLowTime ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isLowTime ? Colors.redAccent : const Color(0xFF017A47),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: isLowTime ? Colors.red.shade700 : const Color(0xFF017A47),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(state.timeLeft),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isLowTime ? Colors.red.shade700 : const Color(0xFF017A47),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Top Progress Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'উত্তর দেওয়া হয়েছে: $answeredCount/$totalQuestions টি',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        state.isSaving ? 'সংরক্ষণ হচ্ছে...' : 'ড্রাফট সংরক্ষিত',
                        style: TextStyle(
                          fontSize: 12,
                          color: state.isSaving ? const Color(0xFF017A47) : Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: totalQuestions > 0 ? (answeredCount / totalQuestions) : 0,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE3E7E4),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF017A47)),
                    ),
                  ),
                ],
              ),
            ),

            // Single continuous scroll view with all questions
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                physics: const BouncingScrollPhysics(),
                itemCount: totalQuestions,
                itemBuilder: (context, index) {
                  final eq = questions[index];
                  final q = eq.question;
                  final selectedOptId = state.selectedOptions[q.id];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Optional difficulty tag
                        if (q.difficulty != null) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                q.difficulty!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Question Title Text with highlighted "1. " number
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${index + 1}. ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF017A47),
                                ),
                              ),
                              TextSpan(
                                text: q.questionText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // LaTeX Formula Rendering (using flutter_math_fork)
                        if (q.latexFormula != null && q.latexFormula!.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F9F6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD4E8DC)),
                            ),
                            child: Math.tex(
                              q.latexFormula!,
                              textStyle: const TextStyle(fontSize: 16, color: Color(0xFF017A47)),
                              onErrorFallback: (err) => Text(
                                q.latexFormula!,
                                style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Color(0xFF017A47)),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Question Options List
                        ...q.options.asMap().entries.map((entry) {
                          final optIndex = entry.key;
                          final opt = entry.value;
                          final isSelected = selectedOptId == opt.id;
                          final label = _getOptionLabel(optIndex);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: InkWell(
                              onTap: () {
                                ref.read(examRunnerProvider.notifier).selectOption(
                                      q.id,
                                      isSelected ? null : opt.id,
                                    );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF017A47) : Colors.grey.shade200,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? const Color(0xFF017A47) : Colors.grey.shade100,
                                        border: Border.all(
                                          color: isSelected ? const Color(0xFF017A47) : Colors.grey.shade400,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        opt.optionText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? const Color(0xFF017A47) : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Fixed Bottom Action Bar with Submit Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSubmitting ? null : _confirmAndSubmitExam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF017A47),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'পরীক্ষা জমা দাও',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
