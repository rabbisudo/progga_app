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

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F3),
      appBar: AppBar(
        title: const Text('ফলাফল বিশ্লেষণ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
        backgroundColor: const Color(0xFFF3F4F3),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.black87),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Analytics Score Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF017A47), Color(0xFF019B5A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF017A47).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    'সম্পন্ন হয়েছে',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.5),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'পরীক্ষা সফলভাবে জমা হয়েছে',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'আপনার উত্তর মূল্যায়ন করা হয়েছে। ভুল উত্তর সমূহের তালিকা নিচে দেওয়া হলো।',
                    style: TextStyle(fontSize: 13, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'ভুল উত্তর সমূহের রিভিউ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            // Wrong answers loader list
            wrongAnswersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF017A47))),
              error: (err, stack) => Center(child: Text('রিভিউ লোড করতে সমস্যা: $err', style: const TextStyle(color: Colors.black54))),
              data: (answers) {
                if (answers.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF017A47)),
                          SizedBox(height: 12),
                          Text('চমৎকার! সব উত্তর সঠিক!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          SizedBox(height: 4),
                          Text('আপনি কোনো ভুল উত্তর প্রদান করেননি।', style: TextStyle(color: Colors.black54, fontSize: 13)),
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'প্রশ্ন ${index + 1}',
                              style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question.questionText,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            
                            // User selection (Wrong)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'আপনার দেওয়া উত্তর: ${selectedOpt.optionText}',
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
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
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF017A47).withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF017A47), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'সঠিক উত্তর: ${correctOpt.optionText}',
                                      style: const TextStyle(color: Color(0xFF017A47), fontSize: 13, fontWeight: FontWeight.w600),
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
