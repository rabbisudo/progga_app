import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exam/data/exam_repository.dart';
import '../../exam/domain/user_exam_model.dart';
import 'package:go_router/go_router.dart';

// Fetch wrong answers for review retries
final wrongAnswersProvider = FutureProvider.family<List<UserAnswerModel>, String>((ref, sessionId) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.fetchWrongAnswers(sessionId);
});

class ResultScreen extends ConsumerWidget {
  final String sessionId;
  const ResultScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrongAnswersAsync = ref.watch(wrongAnswersProvider(sessionId));

    // For demonstration, we construct result metrics. In production, we fetch session details,
    // or retrieve from the notifier state. Let's make it robust by adding a simple mock fetch
    // if full attempt profile mapping is needed. But display stats dynamically.
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Result Analysis', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Analytics Score Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD9746E), Color(0xFFF18881)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF18881).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'COMPLETED',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: 1.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Exam Submitted Successfully',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Results have been computed and synced. Check the detailed summary list of incorrect answers below to practice.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Incorrect Answers Review',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // Wrong answers loader list
            wrongAnswersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFF18881))),
              error: (err, stack) => Center(child: Text('Error loading review: $err', style: const TextStyle(color: Colors.white60))),
              data: (answers) {
                if (answers.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                          SizedBox(height: 12),
                          Text('Perfect Score!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(height: 4),
                          Text('You made zero incorrect selections.', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: answers.length,
                  itemBuilder: (context, index) {
                    final item = answers[index];
                    final question = item.question!;
                    
                    // Identify correct option text
                    final correctOpt = question.options.firstWhere(
                      (o) => o.isCorrect,
                      orElse: () => question.options.first,
                    );
                    
                    // Identify selected option text
                    final selectedOpt = question.options.firstWhere(
                      (o) => o.id == item.selectedOptionId,
                      orElse: () => correctOpt,
                    );

                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Question ${index + 1}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFF18881), fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question.questionText,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            
                            // User selection (Wrong)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cancel, color: Colors.redAccent, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Your Answer: ${selectedOpt.optionText}',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Correct choice selection
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Correct Answer: ${correctOpt.optionText}',
                                      style: const TextStyle(color: Colors.green, fontSize: 13),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
