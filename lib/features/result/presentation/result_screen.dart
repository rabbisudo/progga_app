import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../exam/data/exam_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Fetch full exam session result data
final examResultProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, sessionId) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.fetchExamResult(sessionId);
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_outlined, color: Color(0xFFF59E0B), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'দৈনিক ব্যাখ্যা সীমা অতিক্রান্ত!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনি আজকের ১০টি দৈনিক ব্যাখ্যা দেখার সীমা সম্পূর্ণ করেছেন। আগামীকাল নতুন করে ১০টি ব্যাখ্যা আনলক করতে পারবেন।',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
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

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _isLoading ? null : _handleTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF017A47), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ব্যাখ্যা',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF017A47),
                          ),
                        ),
                        Text(
                          currentQuota > 0
                              ? 'দৈনিক ব্যাখ্যা বাকি - ${_toBengaliDigit(currentQuota)}'
                              : 'আজকের ১০টি সীমার সবগুলো দেখা শেষ!',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
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
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: _buildResultMathWidget(expText),
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
  final String sessionId;
  const ResultScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(examResultProvider(sessionId));

    return resultAsync.when(
      loading: () => const _SkeletonResultScreen(),
      error: (err, stack) => Scaffold(
        backgroundColor: const Color(0xFFF3F4F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F4F3),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Center(
          child: Text('ফলাফল সম্বলিত ডেটা লোড করতে সমস্যা: $err', style: const TextStyle(color: Colors.black54)),
        ),
      ),
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

        final quotaData = data['dailyExplanationQuota'] as Map<String, dynamic>?;
        final remainingDaily = (quotaData?['remainingDaily'] as num?)?.toInt() ?? 10;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(dailyQuotaProvider.notifier).setQuota(remainingDaily);
        });

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

        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F3),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F3),
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => context.go('/home'),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'সময়: ${_toBengaliDigit(durationMinutes)} মিনিট',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
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
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withOpacity(0.06),
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
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF78350F),
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
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF017A47).withOpacity(0.06),
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
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF064E3B),
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
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0EA5E9).withOpacity(0.06),
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
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0C4A6E),
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
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
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
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
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
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: const Color(0xFFFECACA), width: 1.2),
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
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB91C1C),
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
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
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
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
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
                    final qData = (eqItem['question'] as Map<String, dynamic>?) ?? {};
                    final qId = qData['id'] as String? ?? '';
                    final questionText = qData['questionText'] as String? ?? '';
                    final imageKey = qData['imageKey'] as String?;
                    final latexFormula = qData['latexFormula'] as String?;
                    final board = qData['board'] as String?;
                    final year = qData['year'] as int?;

                    final userAns = answersMap[qId];
                    final selectedOptionId = userAns?['selectedOptionId'] as String?;

                    final optionsList = (qData['options'] as List<dynamic>?) ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Question Header Row (Title + Marks Badge)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${index + 1}. ',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Expanded(
                                child: _buildResultMathWidget(
                                  questionText,
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    height: 1.4,
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
                                color: const Color(0xFFF4F9F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD4E8DC)),
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

                          // Options List
                          ...optionsList.asMap().entries.map((optEntry) {
                            final optIdx = optEntry.key;
                            final optData = optEntry.value as Map<String, dynamic>;
                            final optId = optData['id'] as String?;
                            final optionText = optData['optionText'] as String? ?? '';
                            final optImageKey = optData['imageKey'] as String?;
                            final isCorrect = optData['isCorrect'] as bool? ?? false;
                            final isUserSelected = selectedOptionId == optId;

                            final label = _getOptionLabel(optIdx);

                            // Background and border colors matching screenshot
                            Color bgColor = const Color(0xFFF8F9FA);
                            Color borderColor = Colors.transparent;
                            Color labelBgColor = Colors.grey.shade200;
                            Color labelTextColor = Colors.black87;

                            if (isCorrect) {
                              // Correct answer highlight (Golden Yellow / Amber)
                              bgColor = const Color(0xFFFFFBEB);
                              borderColor = const Color(0xFFF59E0B);
                              labelBgColor = const Color(0xFFF59E0B);
                              labelTextColor = Colors.white;
                            } else if (isUserSelected) {
                              // User wrong choice highlight (Light Red)
                              bgColor = const Color(0xFFFFEBEE);
                              borderColor = Colors.redAccent;
                              labelBgColor = Colors.redAccent;
                              labelTextColor = Colors.white;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1.2),
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
                                          ),
                                          child: Center(
                                            child: Text(
                                              label,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: labelTextColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildResultMathWidget(
                                            optionText,
                                            textStyle: TextStyle(
                                              fontSize: 14,
                                              fontWeight: (isCorrect || isUserSelected) ? FontWeight.bold : FontWeight.w500,
                                              color: Colors.black87,
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

                          // Secure On-Demand Explanation Unlock Widget
                          _ExplanationCard(
                            questionId: qId,
                            remainingQuota: remainingDaily,
                          ),

                          const SizedBox(height: 12),

                          // Footer Row (Board/Year & Tags + Action Icons)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Board / Year & Custom Tags
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (board != null || year != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE5E7EB),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${board ?? ''} ${year != null ? _toBengaliDigit(year) : ''}'.trim(),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ...((qData['tags'] as List<dynamic>?) ?? []).map((t) {
                                      final tStr = t.toString().trim();
                                      if (tStr.isEmpty) return const SizedBox.shrink();
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF86EFAC)),
                                        ),
                                        child: Text(
                                          tStr,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF166534),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Action icons (Bookmark & Report Flag)
                              _QuestionActionButtons(questionId: qId),
                            ],
                          ),
                        ],
                      ),
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
    String selectedReason = 'প্রশ্নে বা উত্তরে ভুল আছে';
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'প্রশ্ন রিপোর্ট করুন',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
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
                    onChanged: (val) {
                      setModalState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'অতিরিক্ত তথ্য লিখুন (ন্যূনতম ২০ অক্ষর)...',
                      counterText: '',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
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
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade500,
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;
        return Scaffold(
          backgroundColor: const Color(0xFFF3F4F3),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF3F4F3),
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              'ফলাফল প্রস্তুত হচ্ছে...',
              style: GoogleFonts.notoSansBengali(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
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
                                      color: Colors.grey.shade200.withOpacity(opacity),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
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
                                      color: Colors.grey.shade200.withOpacity(opacity),
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade100),
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
                                      color: Colors.grey.shade200.withOpacity(opacity),
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
                            color: const Color(0xFFE8F5E9).withOpacity(0.8), // light green
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFFA7F3D0).withOpacity(0.5)),
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
                            color: const Color(0xFFFFEBEE).withOpacity(0.8), // light red
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: const Color(0xFFFECACA).withOpacity(0.5)),
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
                            color: Colors.grey.shade100, // light grey
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Container(
                              width: 50,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400.withOpacity(opacity * 0.3),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
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
                                  color: Colors.grey.shade300.withOpacity(opacity),
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
                                        color: Colors.grey.shade200.withOpacity(opacity),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 200,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200.withOpacity(opacity),
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
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade100,
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
                                        color: Colors.grey.shade100.withOpacity(opacity),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 100 + (optIndex * 20 % 60),
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200.withOpacity(opacity),
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
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0).withOpacity(0.5)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD1FAE5),
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
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFA7F3D0).withOpacity(0.5)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 50,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFA7F3D0).withOpacity(0.5)),
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
