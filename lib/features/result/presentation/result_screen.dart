import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../exam/data/exam_repository.dart';
import '../../exam/domain/user_exam_model.dart';
import 'package:go_router/go_router.dart';

// Fetch wrong answers for review retries
final wrongAnswersProvider = FutureProvider.family<List<UserAnswerModel>, String>((ref, sessionId) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.fetchWrongAnswers(sessionId);
});

Widget _buildResultMathWidget(
  String text, {
  TextStyle? textStyle,
  Color? mathColor,
  double fontSize = 14,
}) {
  if (text.isEmpty) return const SizedBox.shrink();

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

  final activeColor = mathColor ?? textStyle?.color ?? Colors.black87;

  if (text.contains('\$')) {
    final List<InlineSpan> spans = [];
    final RegExp regex = RegExp(r'\$([^\$]+)\$');
    int lastMatchEnd = 0;

    for (final Match match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: textStyle ?? TextStyle(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.4),
        ));
      }

      final latexStr = match.group(1)!;
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Math.tex(
            latexStr,
            textStyle: TextStyle(fontSize: fontSize + 1, color: activeColor),
            onErrorFallback: (err) => Text(
              latexStr,
              style: TextStyle(fontSize: fontSize, color: activeColor, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ));

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: textStyle ?? TextStyle(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.4),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  if (text.trim().startsWith('\\') || text.contains(RegExp(r'\\(frac|sqrt|sum|int|lim|alpha|beta|theta|pi|infty)'))) {
    return Math.tex(
      text,
      textStyle: TextStyle(fontSize: fontSize + 1, color: activeColor),
      onErrorFallback: (err) => Text(
        text,
        style: textStyle ?? TextStyle(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.bold),
      ),
    );
  }

  return Text(
    text,
    style: textStyle ?? TextStyle(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.4),
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
    imageUrl = 'http://192.168.31.101:3000$cleanKey';
  } else {
    imageUrl = 'http://192.168.31.101:3000/api/v1/questions/file/$cleanKey';
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
                Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 20),
                const SizedBox(width: 8),
                Text(
                  'ছবি লোড করা যায়নি',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        cacheExtent: 500,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverToBoxAdapter(
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
                ],
              ),
            ),
          ),

          // Wrong answers loader list
          wrongAnswersAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(color: Color(0xFF017A47)),
              )),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(child: Text('রিভিউ লোড করতে সমস্যা: $err', style: const TextStyle(color: Colors.black54))),
            ),
            data: (answers) {
              if (answers.isEmpty) {
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
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
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList.builder(
                  itemCount: answers.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
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
                            _buildResultMathWidget(
                              question.questionText,
                              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            if (question.imageKey != null && question.imageKey!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _buildQuestionImage(question.imageKey),
                            ],
                            const SizedBox(height: 12),
                            
                            // User selection (Wrong)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBEE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.cancel, color: Colors.redAccent, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildResultMathWidget(
                                          'আপনার দেওয়া উত্তর: ${selectedOpt.optionText}',
                                          textStyle: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600),
                                          mathColor: Colors.redAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (selectedOpt.imageKey != null && selectedOpt.imageKey!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    _buildQuestionImage(selectedOpt.imageKey),
                                  ],
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.check_circle, color: Color(0xFF017A47), size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildResultMathWidget(
                                          'সঠিক উত্তর: ${correctOpt.optionText}',
                                          textStyle: const TextStyle(color: Color(0xFF017A47), fontSize: 13, fontWeight: FontWeight.w600),
                                          mathColor: const Color(0xFF017A47),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (correctOpt.imageKey != null && correctOpt.imageKey!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    _buildQuestionImage(correctOpt.imageKey),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
