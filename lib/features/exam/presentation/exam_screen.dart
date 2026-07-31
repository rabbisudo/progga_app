import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'exam_runner_notifier.dart';
import 'package:go_router/go_router.dart';

class ExamScreen extends ConsumerStatefulWidget {
  final String id;
  const ExamScreen({super.key, required this.id});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;
  Timer? _timeSpentTracker;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Trigger initial session setup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(examRunnerProvider.notifier).initializeExam(widget.id);
    });

    // Track active question timers every second
    _timeSpentTracker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final state = ref.read(examRunnerProvider);
      if (state.exam != null && state.exam!.questions.isNotEmpty) {
        final activeQId = state.exam!.questions[_currentIndex].question.id;
        ref.read(examRunnerProvider.notifier).incrementTimeSpent(activeQId);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
        title: const Text('Quit Exam Session?'),
        content: const Text('Exiting now will discard your progress and submit your answers in their current state.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('Quit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(examRunnerProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF18881))),
      );
    }

    if (state.errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(state.errorMessage!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                  child: const Text('Go Back', style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.exam == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: Text('Loading session details...', style: TextStyle(color: Colors.white70))),
      );
    }

    final questions = state.exam!.questions;
    final totalQuestions = questions.length;

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
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: Text(state.exam!.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
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
                color: state.timeLeft < 120 ? Colors.red.withOpacity(0.2) : Colors.white10,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: state.timeLeft < 120 ? Colors.redAccent : Colors.white24,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: state.timeLeft < 120 ? Colors.redAccent : Colors.white70,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(state.timeLeft),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: state.timeLeft < 120 ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_currentIndex + 1} of $totalQuestions',
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                      Text(
                        state.isSaving ? 'Saving...' : 'Draft Saved',
                        style: const TextStyle(color: Colors.white30, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (_currentIndex + 1) / totalQuestions,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),

            // Active Page View Question layout
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  // Auto save on page shifts
                  ref.read(examRunnerProvider.notifier).autoSaveProgress();
                },
                itemCount: totalQuestions,
                itemBuilder: (context, index) {
                  final q = questions[index].question;
                  final selectedOptId = state.selectedOptions[q.id];
                  final isFlagged = state.markedForReview[q.id] ?? false;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Question Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      q.difficulty ?? 'MEDIUM',
                                      style: TextStyle(fontSize: 10, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isFlagged ? Icons.bookmark : Icons.bookmark_border,
                                      color: isFlagged ? Theme.of(context).primaryColor : Colors.white60,
                                    ),
                                    onPressed: () {
                                      ref.read(examRunnerProvider.notifier).toggleMarkedForReview(q.id);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                q.questionText,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
                              ),
                              if (q.latexFormula != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  q.latexFormula!,
                                  style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Theme.of(context).primaryColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Options choices lists
                        ...q.options.map((opt) {
                          final isSelected = selectedOptId == opt.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () {
                                ref.read(examRunnerProvider.notifier).selectOption(q.id, isSelected ? null : opt.id);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.15) : const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.white10,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Text(
                                  opt.optionText,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Theme.of(context).primaryColor : Colors.white,
                                  ),
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

            // Footer controls bar
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF1E1E1E),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Prev button
                  ElevatedButton(
                    onPressed: _currentIndex > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      disabledBackgroundColor: Colors.white10,
                    ),
                    child: const Text('Previous', style: TextStyle(color: Colors.white)),
                  ),

                  // Submit button
                  if (_currentIndex == totalQuestions - 1)
                    ElevatedButton(
                      onPressed: state.isSubmitting
                          ? null
                          : () async {
                              final submitResult = await ref.read(examRunnerProvider.notifier).submitExam();
                              if (submitResult != null && context.mounted) {
                                context.pushReplacement('/result/${submitResult.id}');
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Submit Exam', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    )
                  else
                    // Next button
                    ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                      child: const Text('Next', style: TextStyle(color: Colors.black)),
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
