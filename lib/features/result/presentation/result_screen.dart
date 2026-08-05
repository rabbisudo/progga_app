import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../exam/data/exam_repository.dart';
import '../../exam/presentation/exam_screen.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/custom_back_button.dart';

// Fetch full exam session result data
final examResultProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, sessionId) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.fetchExamResult(sessionId);
});

// Fetch and format exam questions for previewing
final examDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, examId) async {
  final repo = ref.watch(examRepositoryProvider);
  final exam = await repo.fetchExamDetails(examId);

  final List<Map<String, dynamic>> mappedQuestions = exam.questions.map((eq) {
    return {
      'id': eq.id,
      'examId': eq.examId,
      'questionId': eq.questionId,
      'sortOrder': eq.sortOrder,
      'question': {
        'id': eq.question.id,
        'subjectId': eq.question.subjectId,
        'chapterId': eq.question.chapterId,
        'topicId': eq.question.topicId,
        'questionText': eq.question.questionText,
        'imageKey': eq.question.imageKey,
        'latexFormula': eq.question.latexFormula,
        'type': eq.question.type,
        'marks': eq.question.marks,
        'tags': eq.question.tags,
        'options': eq.question.options.map((opt) => opt.toJson()).toList(),
        'explanations': eq.question.explanations?.map((exp) => exp.toJson()).toList() ?? [],
      },
    };
  }).toList();

  return {
    'exam': {
      'id': exam.id,
      'title': exam.title,
      'description': exam.description,
      'duration': exam.duration,
      'totalMarks': exam.totalMarks,
      'passMarks': exam.passMarks,
      'questions': mappedQuestions,
    },
    'totalQuestions': exam.questions.length,
    'correctCount': 0,
    'wrongCount': 0,
    'skippedCount': exam.questions.length,
    'score': 0.0,
    'timeTaken': 0,
    'answers': [],
  };
});

// Fetch user's actual daily explanation quota
final explanationQuotaProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.fetchExplanationQuota();
});

// Global state provider for daily explanation quota sync
final dailyQuotaProvider = StateNotifierProvider<DailyQuotaNotifier, int>((ref) {
  return DailyQuotaNotifier();
});

class DailyQuotaNotifier extends StateNotifier<int> {
  DailyQuotaNotifier() : super(10);

  void setQuota(int count) {
    state = count;
  }
}

String _toBengaliDigit(dynamic number) {
  if (number == null) return '০';
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

String _stripHtml(String htmlString) {
  if (htmlString.isEmpty) return htmlString;
  String result = htmlString;
  // Replace block-level tags or line breaks first
  result = result.replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n');
  result = result.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  result = result.replaceAll(RegExp(r'</li>\s*<li>', caseSensitive: false), '\n');
  // Replace common HTML entities
  result = result.replaceAll('&nbsp;', ' ');
  result = result.replaceAll('&amp;', '&');
  result = result.replaceAll('&lt;', '<');
  result = result.replaceAll('&gt;', '>');
  result = result.replaceAll('&quot;', '"');
  result = result.replaceAll('&#39;', "'");
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
      int cmdLen = cleaned.startsWith(r'\frac', i) ? 5 : 5;
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

  final text = _fixBrokenLatex(_stripHtml(rawText));

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
  final defaultStyle = textStyle ?? TextStyle(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.4);

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
              textStyle: TextStyle(fontSize: fontSize + 1, color: activeColor),
              onErrorFallback: (err) => Text(
                latexStr,
                style: TextStyle(fontSize: fontSize, color: activeColor, fontStyle: FontStyle.italic),
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

  // 5. If line contains Bengali characters (\u0980-\u09FF)
  final hasBengali = normalizedText.contains(RegExp(r'[\u0980-\u09FF]'));
  if (hasBengali) {
    // If Bengali line ALSO contains inline TeX formulas (like \frac, \sqrt, t = \frac{...})
    final texMatch = RegExp(r'(\\(frac|sqrt|text|times|div|pm|degree)\{[^\}]*\}(?:\{[^\}]*\})?|[a-zA-Z]\s*=\s*\\[a-zA-Z]+[^\s,]*)');
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
              textStyle: TextStyle(fontSize: fontSize + 1, color: activeColor),
              onErrorFallback: (err) => Text(mathCode, style: defaultStyle),
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

    // Pure Bengali text line with no TeX
    return Text(
      normalizedText,
      style: defaultStyle,
    );
  }

  // 6. Non-Bengali line: Check if pure TeX math
  if (normalizedText.trim().startsWith('\\') ||
      normalizedText.contains(RegExp(r'\\(frac|sqrt|sum|int|lim|alpha|beta|theta|pi|infty|vec|times|div|pm|degree)')) ||
      normalizedText.contains(RegExp(r'^[a-zA-Z0-9\s=\+\-\*/\^_\(\)\{\}\\]+$'))) {
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

  // Standard plain text
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

class _ExplanationCard extends ConsumerStatefulWidget {
  final String questionId;
  final int remainingQuota;

  const _ExplanationCard({
    required this.questionId,
    required this.remainingQuota,
  });

  @override
  ConsumerState<_ExplanationCard> createState() => _ExplanationCardState();
}

class _ExplanationCardState extends ConsumerState<_ExplanationCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isUnlocked = false;
  List<dynamic> _explanations = [];

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
        final newRemaining = (res['remainingDaily'] as num?)?.toInt();
        if (newRemaining != null) {
          ref.read(dailyQuotaProvider.notifier).setQuota(newRemaining);
        }

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনি আজকের ১০টি দৈনিক ব্যাখ্যা দেখার সীমা সম্পূর্ণ করেছেন। আগামীকাল নতুন করে ১০টি ব্যাখ্যা আনলক করতে পারবেন।',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600, height: 1.4),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
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
    final currentQuota = ref.watch(dailyQuotaProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFF0FDF4),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ব্যাখ্যা',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF017A47),
                            fontFamily: 'Noto Sans Bengali',
                          ),
                        ),
                        Text(
                          currentQuota > 0
                              ? 'দৈনিক ব্যাখ্যা বাকি - ${_toBengaliDigit(currentQuota)}'
                              : 'আজকের ১০টি সীমার সবগুলো দেখা শেষ!',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                            fontFamily: 'Noto Sans Bengali',
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
                  Divider(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)),
                  const SizedBox(height: 6),
                  ..._explanations.map((expData) {
                    final expMap = expData as Map<String, dynamic>;
                    final expText = expMap['text'] as String? ?? '';
                    final expImgKey = expMap['imageKey'] as String?;

                     return Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         _buildResultMathWidget(
                           expText,
                           textStyle: TextStyle(
                             fontSize: 13.5,
                             color: isDark ? Colors.white70 : Colors.black87,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                         if (expImgKey != null && expImgKey.isNotEmpty)
                           _buildQuestionImage(expImgKey),
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

class ResultScreen extends ConsumerWidget {
  final String? sessionId;
  final String? examId;
  final bool isPreview;

  const ResultScreen({
    super.key,
    this.sessionId,
    this.examId,
    this.isPreview = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = isPreview
        ? ref.watch(examDetailsProvider(examId ?? ''))
        : ref.watch(examResultProvider(sessionId ?? ''));

    ref.listen<AsyncValue<Map<String, dynamic>>>(explanationQuotaProvider, (previous, next) {
      next.whenOrNull(
        data: (quotaData) {
          final remainingDaily = (quotaData['remainingDaily'] as num?)?.toInt() ?? 0;
          ref.read(dailyQuotaProvider.notifier).setQuota(remainingDaily);
        },
      );
    });

    return resultAsync.when(
      loading: () => const _SkeletonResultScreen(),
      error: (err, stack) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;
        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            elevation: 0,
            leading: CustomBackButton(
              color: textColor,
              onPressed: () => context.go('/home'),
            ),
          ),
          body: Center(
            child: Text(
              'ফলাফল সম্বলিত ডেটা লোড করতে সমস্যা: $err',
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        );
      },
      data: (data) {
        final examData = data['exam'] as Map<String, dynamic>?;
        final title = examData?['title'] as String? ?? 'মক পরীক্ষা';
        final durationSeconds = examData?['duration'] as int? ?? 0;
        final durationMinutes = (durationSeconds / 60).round();

        final totalQuestions = (data['totalQuestions'] as num?)?.toInt() ?? 0;
        final correctCount = (data['correctCount'] as num?)?.toInt() ?? 0;
        final wrongCount = (data['wrongCount'] as num?)?.toInt() ?? 0;
        final skippedCount = (data['skippedCount'] as num?)?.toInt() ?? 0;
        final score = (data['score'] as num?)?.toDouble() ?? 0.0;
        final timeTakenSeconds = (data['timeTaken'] as num?)?.toInt() ?? 0;
        final timeTakenMinutes = (timeTakenSeconds / 60).round();

        final initialQuota = ref.read(explanationQuotaProvider).value?['remainingDaily'] as int?;
        if (initialQuota != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(dailyQuotaProvider.notifier).setQuota(initialQuota);
          });
        }

        // Points earned (XP coins calculation)
        final points = correctCount * 10;

        // Answers sheet map
        final answersList = (data['answers'] as List<dynamic>?) ?? [];
        final answersMap = <String, Map<String, dynamic>>{};
        for (final ans in answersList) {
          if (ans is Map<String, dynamic>) {
            final qId = ans['questionId'] as String?;
            if (qId != null) {
              answersMap[qId] = ans;
            }
          }
        }

        // Exam questions list
        final examQuestionsList = (examData?['questions'] as List<dynamic>?) ?? [];

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: CustomBackButton(
              color: textColor,
              onPressed: () => context.go('/home'),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontSize: 18,
                  ),
                ),
                Text(
                  isPreview
                      ? 'প্রশ্নপত্র (${_toBengaliDigit(examQuestionsList.length)}টি প্রশ্ন)'
                      : 'সময়: ${_toBengaliDigit(durationMinutes)} মিনিট',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            centerTitle: true,
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            cacheExtent: 500,
            slivers: [
              // Top Stats Cards & Status Pills Header
              if (!isPreview)
                SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // 3 Top Stats Cards (Vibrant EdTech Style)
                      Row(
                        children: [
                          // Card 1: পয়েন্ট
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2B2516) : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? const Color(0xFF5D4A16) : const Color(0xFFFDE68A), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.2 : 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF59E0B),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                                    ),
                                    child: const Text(
                                      'পয়েন্ট',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 22),
                                        const SizedBox(width: 4),
                                        Text(
                                          _toBengaliDigit(points),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF78350F),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Card 2: মার্কস
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF162E24) : const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? const Color(0xFF1D5A3F) : const Color(0xFFA7F3D0), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF017A47).withOpacity(isDark ? 0.2 : 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF017A47),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                                    ),
                                    child: const Text(
                                      'মার্কস',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF017A47), size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_toBengaliDigit(score.toInt())} / ${_toBengaliDigit(totalQuestions)}',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF064E3B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Card 3: সময়
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF162D3D) : const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? const Color(0xFF1D5273) : const Color(0xFFBAE6FD), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9).withOpacity(isDark ? 0.2 : 0.06),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0EA5E9),
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                                    ),
                                    child: const Text(
                                      'সময়',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.timer_outlined, color: Color(0xFF0284C7), size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_toBengaliDigit(timeTakenMinutes)} মি.',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0C4A6E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3 Filled Status Count Pills
                      Row(
                        children: [
                          // Pill 1: সঠিক
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF00381C) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFF86EFAC), width: 1.2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_toBengaliDigit(correctCount)} সঠিক',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF00C569) : const Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Pill 2: ভুল
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF3D1616) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: isDark ? const Color(0xFF731D1D) : const Color(0xFFFECACA), width: 1.2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDC2626),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_toBengaliDigit(wrongCount)} ভুল',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Pill 3: স্কিপ
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFE5E7EB), width: 1.2),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF6B7280),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_toBengaliDigit(skippedCount)} স্কিপ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Question items sliver list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList.builder(
                  itemCount: examQuestionsList.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  itemBuilder: (context, index) {
                    final eqItem = examQuestionsList[index] as Map<String, dynamic>;
                    return _QuestionReviewCard(
                      eqItem: eqItem,
                      index: index,
                      answersMap: answersMap,
                      remainingQuota: ref.watch(dailyQuotaProvider),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuestionActionButtons extends ConsumerStatefulWidget {
  final String questionId;
  const _QuestionActionButtons({required this.questionId});

  @override
  ConsumerState<_QuestionActionButtons> createState() => _QuestionActionButtonsState();
}

class _QuestionActionButtonsState extends ConsumerState<_QuestionActionButtons> {
  bool _isBookmarked = false;

  Future<void> _toggleBookmark() async {
    final nextState = !_isBookmarked;
    setState(() {
      _isBookmarked = nextState;
    });

    try {
      final repo = ref.read(examRepositoryProvider);
      final res = await repo.toggleBookmark(widget.questionId);
      final message = res['message'] as String? ?? (_isBookmarked ? 'প্রশ্নটি বুকমার্কে সংরক্ষিত হয়েছে!' : 'বুকমার্ক থেকে সরিয়ে ফেলা হয়েছে');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_remove_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  message,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            backgroundColor: _isBookmarked ? const Color(0xFF017A47) : Colors.grey.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBookmarked = !nextState;
        });
      }
    }
  }

  void _showReportDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String selectedReason = 'প্রশ্নে বা উত্তরে ভুল আছে';
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'প্রশ্ন রিপোর্ট করুন',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...[
                    'প্রশ্নে বা উত্তরে ভুল আছে',
                    'অপশনগুলো অস্পষ্ট বা অসম্পূর্ণ',
                    'ছবি বা গাণিতিক সংকেত লোড হচ্ছে না',
                    'অন্যান্য সমস্যা',
                  ].map((reason) {
                    return RadioListTile<String>(
                      value: reason,
                      groupValue: selectedReason,
                      activeColor: const Color(0xFF017A47),
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        reason,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : Colors.black87),
                      ),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedReason = val;
                          });
                        }
                      },
                    );
                  }),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    maxLines: 2,
                    maxLength: 500,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    onChanged: (val) {
                      setModalState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'অতিরিক্ত তথ্য লিখুন (ন্যূনতম ২০ অক্ষর)...',
                      counterText: '',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : Colors.grey.shade500),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF017A47)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.text.trim().length >= 20
                          ? () async {
                              final detailsText = controller.text.trim();
                              final messenger = ScaffoldMessenger.of(context);
                              Navigator.pop(context);

                              try {
                                final repo = ref.read(examRepositoryProvider);
                                final res = await repo.reportQuestion(
                                  widget.questionId,
                                  selectedReason,
                                  details: detailsText.isNotEmpty ? detailsText : null,
                                );
                                final msg = res['message'] as String? ?? 'আপনার রিপোর্ট সফলভাবে জমা হয়েছে! ধন্যবাদ।';

                                messenger.hideCurrentSnackBar();
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                        const SizedBox(width: 10),
                                        Text(
                                          msg,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF017A47),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 3),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              } catch (e) {
                                // Ignore
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF017A47),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade300,
                        disabledForegroundColor: isDark ? Colors.white30 : Colors.grey.shade500,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'রিপোর্ট জমা দিন',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            size: 19,
            color: _isBookmarked ? const Color(0xFF017A47) : Colors.grey.shade600,
          ),
          onPressed: _toggleBookmark,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
          tooltip: 'বুকমার্ক করুন',
        ),
        const SizedBox(width: 6),
        IconButton(
          icon: Icon(
            Icons.outlined_flag_rounded,
            size: 19,
            color: Colors.grey.shade600,
          ),
          onPressed: _showReportDialog,
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6),
          tooltip: 'রিপোর্ট করুন',
        ),
      ],
    );
  }
}

class _SkeletonResultScreen extends StatefulWidget {
  const _SkeletonResultScreen();

  @override
  State<_SkeletonResultScreen> createState() => _SkeletonResultScreenState();
}

class _SkeletonResultScreenState extends State<_SkeletonResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;
    final skeletonColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return Scaffold(
          backgroundColor: scaffoldBg,
          appBar: AppBar(
            backgroundColor: scaffoldBg,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'ফলাফল প্রস্তুত হচ্ছে...',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            leading: CustomBackButton(
              color: textColor,
              onPressed: () => context.go('/home'),
            ),
          ),
          body: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3-card stats row
                  Row(
                    children: [
                      // Card 1: Points
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBBF24).withOpacity(0.15), // soft orange
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 50,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: skeletonColor.withOpacity(opacity),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Card 2: Marks
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.15), // soft green
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 50,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: skeletonColor.withOpacity(opacity),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Card 3: Time
                      Expanded(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0EA5E9).withOpacity(0.15), // soft blue
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Container(
                                    width: 50,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: skeletonColor.withOpacity(opacity),
                                      borderRadius: BorderRadius.circular(4),
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
                  const SizedBox(height: 16),
                  
                  // 3-pills row
                  Row(
                    children: [
                      // Correct Pill
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9).withOpacity(0.8), // light green
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: (isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)).withOpacity(0.5)),
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFF017A47).withOpacity(opacity * 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Wrong Pill
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF3D1616) : const Color(0xFFFFEBEE).withOpacity(0.8), // light red
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: (isDark ? const Color(0xFF731D1D) : const Color(0xFFFECACA)).withOpacity(0.5)),
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(opacity * 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Skipped Pill
                      Expanded(
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100, // light grey
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 12,
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white30 : Colors.grey.shade400).withOpacity(opacity * 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Question Cards Placeholders (2 of them)
                  ...List.generate(2, (qIndex) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 24,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.grey.shade700 : Colors.grey.shade300).withOpacity(opacity),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: skeletonColor.withOpacity(opacity),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 200,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: skeletonColor.withOpacity(opacity),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ...List.generate(4, (optIndex) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: (isDark ? Colors.grey.shade800 : Colors.grey.shade100).withOpacity(opacity),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 100 + (optIndex * 20 % 60),
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: skeletonColor.withOpacity(opacity),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          // Explanation Accordion placeholder
                          Container(
                            height: 44,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: (isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)).withOpacity(0.5)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF00381C) : const Color(0xFFD1FAE5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 80,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF017A47).withOpacity(opacity * 0.3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Spacer(),
                                Icon(Icons.keyboard_arrow_down, color: const Color(0xFF017A47).withOpacity(opacity)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Bottom tags and actions placeholder
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: (isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)).withOpacity(0.5)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 50,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: (isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)).withOpacity(0.5)),
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.bookmark_border_rounded, color: Colors.grey.shade400, size: 19),
                              const SizedBox(width: 12),
                              Icon(Icons.outlined_flag_rounded, color: Colors.grey.shade400, size: 19),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuestionReviewCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> eqItem;
  final int index;
  final Map<String, Map<String, dynamic>> answersMap;
  final int remainingQuota;

  const _QuestionReviewCard({
    super.key,
    required this.eqItem,
    required this.index,
    required this.answersMap,
    required this.remainingQuota,
  });

  @override
  ConsumerState<_QuestionReviewCard> createState() => _QuestionReviewCardState();
}

class _QuestionReviewCardState extends ConsumerState<_QuestionReviewCard> {
  bool _isUnlocked = false;
  bool _isLoading = false;
  String? _activeSubKey;
  final Map<String, bool> _subExplanationExpanded = {
    'A': false,
    'B': false,
    'C': false,
    'D': false,
    'E': false,
    'F': false,
  };
  final Map<String, String> _parsedExplanations = {};

  String _getSubKey(int index) {
    const keys = ['A', 'B', 'C', 'D', 'E', 'F'];
    if (index >= 0 && index < keys.length) {
      return keys[index];
    }
    return 'A';
  }

  // --- FITB Review Helpers ---

  bool _isFitbAnswerCorrect(String? uAns, String? cAns) {
    if (uAns == null || cAns == null) return false;
    final cleanUser = uAns.trim().toLowerCase();
    final cleanCorrect = cAns.trim().toLowerCase();
    final acceptedAnswers = cleanCorrect.split(RegExp(r'/|\s+or\s+'));
    return acceptedAnswers.any((ans) => cleanUser == ans.trim());
  }

  Map<String, String> _parseCorrectAnswers(String solutionHtml) {
    final Map<String, String> correctMap = {};
    final pRegex = RegExp(r'\(([a-z0-9])\)\s*([^<;.,\)]+)', caseSensitive: false);
    final matches = pRegex.allMatches(solutionHtml).toList();
    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      var label = m.group(1)!.toLowerCase();
      if (RegExp(r'^\d+$').hasMatch(label)) {
        label = String.fromCharCode(97 + i); // 0 -> a, 1 -> b, etc.
      }
      final val = m.group(2)!.trim();
      correctMap[label] = val;
    }
    return correctMap;
  }

  WidgetSpan _buildFitbReviewGapSpan(String gapLabel, Map<String, String> userMap, Map<String, String> correctMap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final uAns = userMap[gapLabel];
    final cAns = correctMap[gapLabel];
    final isCorrect = _isFitbAnswerCorrect(uAns, cAns);
    final isSkipped = uAns == null || uAns.trim().isEmpty;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (isCorrect) {
      bgColor = isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9);
      borderColor = isDark ? const Color(0xFF0D5E35) : const Color(0xFF81C784);
      textColor = isDark ? const Color(0xFF00C569) : const Color(0xFF017A47);
    } else if (isSkipped) {
      bgColor = isDark ? const Color(0xFF2B2516) : const Color(0xFFFFFBEB);
      borderColor = isDark ? const Color(0xFF5D4A16) : const Color(0xFFFCD34D);
      textColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
    } else {
      bgColor = isDark ? const Color(0xFF3D1616) : const Color(0xFFFFEBEE);
      borderColor = isDark ? const Color(0xFF731D1D) : const Color(0xFFEF5350);
      textColor = isDark ? const Color(0xFFF87171) : Colors.red.shade900;
    }

    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '($gapLabel) ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Text(
              uAns ?? '________',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isCorrect ? (isDark ? Colors.white : Colors.black87) : textColor,
              ),
            ),
            // Removed inline correct answer text as requested
          ],
        ),
      ),
    );
  }

  Widget _buildFitbReviewPassage(String qId, String rawPassage, Map<String, String> userMap, Map<String, String> correctMap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cleanPassage = rawPassage
        .replaceAll(RegExp(r'<table[^>]*>([\s\S]*?)<\/table>', caseSensitive: false), '')
        .replaceAll(RegExp(r'</?span[^>]*>', caseSensitive: false), '')
        .trim();
    final paragraphs = cleanPassage.split(RegExp(r'</p>|<p>|<br\s*/?>'));

    final List<Widget> paragraphWidgets = [];

    for (var para in paragraphs) {
      final trimmed = para.trim();
      if (trimmed.isEmpty) continue;

      final List<InlineSpan> spans = [];
      int lastEnd = 0;
      
      final gapRegex = RegExp(
        r'\(([a-z])\)\s*(——|___+|_+|&mdash;|&ndash;|[\u2014\u2013\u002d]+)',
        caseSensitive: false
      );
      final matches = gapRegex.allMatches(trimmed);

      for (final m in matches) {
        if (m.start > lastEnd) {
          spans.add(TextSpan(
            text: trimmed.substring(lastEnd, m.start).replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim(),
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.6),
          ));
        }

        final gapLabel = m.group(1)!.toLowerCase();
        spans.add(_buildFitbReviewGapSpan(gapLabel, userMap, correctMap));

        lastEnd = m.end;
      }

      if (lastEnd < trimmed.length) {
        spans.add(TextSpan(
          text: trimmed.substring(lastEnd).replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim(),
          style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87, height: 1.6),
        ));
      }

      if (spans.isNotEmpty) {
        paragraphWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text.rich(
              TextSpan(children: spans),
              softWrap: true,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: paragraphWidgets,
    );
  }

  Widget _buildFitbReviewCard(Map<String, dynamic> qData, Map<String, dynamic>? userAns) {
    final qId = qData['id'] as String? ?? '';
    final questionText = qData['questionText'] as String? ?? '';
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
    
    // Parse user answers from serialized JSON
    Map<String, String> userMap = {};
    final textAnswer = userAns?['textAnswer'] as String?;
    final selectedOptionId = userAns?['selectedOptionId'] as String?;
    final rawAns = textAnswer ?? selectedOptionId;
    if (rawAns != null && rawAns.startsWith('{')) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(rawAns);
        userMap = decoded.map((k, v) => MapEntry(k, v.toString()));
      } catch (_) {}
    }
    
    // Parse correct answers from solution
    final correctMap = _parseCorrectAnswers(solutionHtml);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFitbReviewPassage(qId, questionText, userMap, correctMap),
      ],
    );
  }

  String _getCqLabel(int index) {
    const labels = ['ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '${index + 1}';
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনি আজকের ১০টি দৈনিক ব্যাখ্যা দেখার সীমা সম্পূর্ণ করেছেন। আগামীকাল নতুন করে ১০টি ব্যাখ্যা আনলক করতে পারবেন।',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600, height: 1.4),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleSubExplanation(String questionId, String subKey) async {
    if (_isUnlocked) {
      setState(() {
        _subExplanationExpanded[subKey] = !(_subExplanationExpanded[subKey] ?? false);
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _activeSubKey = subKey;
    });

    try {
      final repo = ref.read(examRepositoryProvider);
      final res = await repo.unlockExplanation(questionId);

      if (mounted) {
        final newRemaining = (res['remainingDaily'] as num?)?.toInt();
        if (newRemaining != null) {
          ref.read(dailyQuotaProvider.notifier).setQuota(newRemaining);
        }

        final rawExplanations = res['explanations'] as List<dynamic>? ?? [];
        if (rawExplanations.isNotEmpty) {
          final expText = rawExplanations[0]['text'] as String? ?? '';
          try {
            final Map<String, dynamic> parsed = jsonDecode(expText);
            parsed.forEach((key, value) {
              _parsedExplanations[key] = value.toString();
            });
          } catch (e) {
            _parsedExplanations['A'] = expText;
          }
        }

        setState(() {
          _isUnlocked = true;
          _subExplanationExpanded[subKey] = true;
          _isLoading = false;
          _activeSubKey = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _activeSubKey = null;
        });
        _showLimitDialog(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qData = (widget.eqItem['question'] as Map<String, dynamic>?) ?? {};
    final qId = qData['id'] as String? ?? '';
    final questionText = qData['questionText'] as String? ?? '';
    final imageKey = qData['imageKey'] as String?;
    final latexFormula = qData['latexFormula'] as String?;
    final qType = qData['type'] as String?;
    final qMarks = (qData['marks'] as num?)?.toDouble() ?? 1.0;

    final userAns = widget.answersMap[qId];
    final selectedOptionId = userAns?['selectedOptionId'] as String?;

    final optionsList = (qData['options'] as List<dynamic>?) ?? [];
    final List<String> localPaths = globalCqUploadedImages[qId] ?? [];

    final isWrittenOrCq = qType == 'CQ_4' ||
        qType == 'CQ_3' ||
        qType == 'CQ' ||
        qType == 'WRITTEN' ||
        qType == 'CQ_N' ||
        (qType?.startsWith('CQ_') ?? false) ||
        qMarks > 1.1;

    final isFitb = qType == 'FILL_IN_THE_GAP' ||
        qType == 'FILL_IN_THE_GAPS' ||
        qType == 'FILL_IN_THE_GAPS_WITHOUT_CLUES' ||
        ((qType == 'WRITTEN' || qType == 'FILL') &&
        questionText.contains('(a)') &&
        RegExp(r'\(([a-z0-9])\)\s*(——|___+|_+|&mdash;|&ndash;|[\u2014\u2013\u002d]+)', caseSensitive: false).hasMatch(questionText));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFECEFF1),
            width: 1.2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header Row (Title)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${widget.index + 1}. ',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF017A47),
                  fontFamily: 'Noto Sans Bengali',
                ),
              ),
              if (!isFitb)
                Expanded(
                  child: _buildResultMathWidget(
                    questionText,
                    textStyle: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                ),
            ],
          ),

          // Question Media Image
          if (imageKey != null && imageKey.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildQuestionImage(imageKey),
          ],

          // LaTeX Formula (if present)
          if (latexFormula != null && latexFormula.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFF4F9F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFD4E8DC)),
              ),
              child: Math.tex(
                latexFormula,
                textStyle: const TextStyle(fontSize: 16, color: Color(0xFF017A47)),
                onErrorFallback: (err) => Text(
                  latexFormula,
                  style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Color(0xFF017A47)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Uploaded Pages List
          if (isWrittenOrCq && !isFitb && localPaths.isNotEmpty) ...[
            Text(
              'আপনার আপলোডকৃত উত্তরসমূহ:',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: localPaths.length,
                separatorBuilder: (context, idx) => const SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final path = localPaths[idx];
                  return Container(
                    width: 100,
                    height: 130,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(path),
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${idx + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Content body based on type
          if (isFitb) ...[
            _buildFitbReviewCard(qData, userAns),
          ] else if (isWrittenOrCq) ...[
            // Written / CQ Content: Flat text subquestions with separate explanation button
            if (qType != 'WRITTEN')
              ...optionsList.asMap().entries.map((optEntry) {
                final optIdx = optEntry.key;
                final optData = optEntry.value as Map<String, dynamic>;
              final optionText = optData['optionText'] as String? ?? '';
              final label = _getCqLabel(optIdx);
              final subKey = _getSubKey(optIdx);
              final isExpanded = _subExplanationExpanded[subKey] ?? false;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$label. ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: _buildResultMathWidget(
                            optionText,
                            textStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => _toggleSubExplanation(qId, subKey),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B3B2B) : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLoading && _activeSubKey == subKey)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF017A47)),
                                )
                              else
                                const Icon(Icons.auto_awesome, color: Color(0xFF017A47), size: 13),
                              const SizedBox(width: 6),
                              Text(
                                isExpanded ? 'ব্যাখ্যা বন্ধ করো' : '$label এর ব্যাখ্যা',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF017A47),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: const Color(0xFF017A47),
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isExpanded) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                        ),
                        child: _buildResultMathWidget(
                          _parsedExplanations[subKey] ?? 'কোনো ব্যাখ্যা পাওয়া যায়নি।',
                          textStyle: TextStyle(
                            fontSize: 13.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ] else ...[
            // MCQ Content: Selectable Options review
            ...optionsList.asMap().entries.map((optEntry) {
              final optIdx = optEntry.key;
              final optData = optEntry.value as Map<String, dynamic>;
              final optId = optData['id'] as String?;
              final optionText = optData['optionText'] as String? ?? '';
              final optImageKey = optData['imageKey'] as String?;
              final isCorrect = optData['isCorrect'] as bool? ?? false;
              final isUserSelected = selectedOptionId == optId;

              final label = _getOptionLabel(optIdx);

              Color bgColor = isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFFAFAFA);
              Color labelBgColor = isDark ? Colors.white10 : Colors.white;
              Color labelTextColor = isDark ? Colors.white60 : Colors.black54;
              Border? labelBorder = Border.all(color: isDark ? Colors.white30 : const Color(0xFFCFD8DC), width: 1.5);

              if (isCorrect) {
                bgColor = isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9);
                labelBgColor = const Color(0xFF017A47);
                labelTextColor = Colors.white;
                labelBorder = null;
              } else if (isUserSelected) {
                bgColor = isDark ? const Color(0xFF3D1616) : const Color(0xFFFFEBEE);
                labelBgColor = Colors.redAccent;
                labelTextColor = Colors.white;
                labelBorder = null;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  fontWeight: FontWeight.bold,
                                  color: labelTextColor,
                                  fontFamily: 'Noto Sans Bengali',
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
                                fontWeight: (isCorrect || isUserSelected) ? FontWeight.w600 : FontWeight.w400,
                                color: isCorrect
                                    ? (isDark ? const Color(0xFF00C569) : const Color(0xFF017A47))
                                    : (isUserSelected
                                        ? (isDark ? Colors.red.shade300 : Colors.red.shade900)
                                        : (isDark ? Colors.white70 : Colors.black87)),
                                fontFamily: 'Noto Sans Bengali',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (optImageKey != null && optImageKey.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildQuestionImage(optImageKey),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],

          _ExplanationCard(
            questionId: qId,
            remainingQuota: widget.remainingQuota,
          ),
          const SizedBox(height: 12),

          // Footer Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...((qData['tags'] as List<dynamic>?) ?? [])
                        .map((t) => t.toString().trim())
                        .where((tStr) => RegExp(r'^[A-Za-z]+\s+\d{2}$').hasMatch(tStr))
                        .map((tStr) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF017A47).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: const Color(0xFF017A47).withOpacity(0.15), width: 1.0),
                        ),
                        child: Text(
                          tStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF017A47),
                            fontFamily: 'Noto Sans Bengali',
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _QuestionActionButtons(questionId: qId),
            ],
          ),
        ],
      ),
    );
  }
}
