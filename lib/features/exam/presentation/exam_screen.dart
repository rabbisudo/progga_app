import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'exam_runner_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final Map<String, Widget> _mathWidgetCache = {};

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

  Widget _buildMathWidget(
    String rawText, {
    TextStyle? textStyle,
    Color? mathColor,
    double fontSize = 14,
  }) {
    if (rawText.isEmpty) return const SizedBox.shrink();

    final cacheKey = '${rawText}_${fontSize}_${mathColor?.value}_${textStyle?.color?.value}_${textStyle?.fontWeight?.index}';
    if (_mathWidgetCache.containsKey(cacheKey)) {
      return _mathWidgetCache[cacheKey]!;
    }

    final parsedWidget = _buildMathWidgetImpl(
      rawText,
      textStyle: textStyle,
      mathColor: mathColor,
      fontSize: fontSize,
    );

    _mathWidgetCache[cacheKey] = parsedWidget;
    return parsedWidget;
  }

  Widget _buildMathWidgetImpl(
    String rawText, {
    TextStyle? textStyle,
    Color? mathColor,
    double fontSize = 14,
  }) {
    final text = _fixBrokenLatex(rawText);

    // Check if text contains embedded [IMAGE: url] tags
    final imageRegex = RegExp(r'\[IMAGE:\s*([^\]]+)\]', caseSensitive: false);
    if (imageRegex.hasMatch(text)) {
      final List<Widget> widgets = [];
      int lastIndex = 0;

      for (final Match match in imageRegex.allMatches(text)) {
        if (match.start > lastIndex) {
          final textPart = text.substring(lastIndex, match.start).trim();
          if (textPart.isNotEmpty) {
            widgets.add(_buildMathWidget(
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
          widgets.add(_buildMathWidget(
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
            child: _buildMathWidget(
              line,
              textStyle: textStyle,
              mathColor: mathColor,
              fontSize: fontSize,
            ),
          );
        }).toList(),
      );
    }

    // Normalize all math delimiters: $$, \(...\), \[...\] to $...$
    String normalizedText = text
        .replaceAll(RegExp(r'\$\$(.*?)\$\$', dotAll: true), r'$ $1 $')
        .replaceAll(RegExp(r'\\\((.*?)\\\)', dotAll: true), r'$ $1 $')
        .replaceAll(RegExp(r'\\\[(.*?)\\\]', dotAll: true), r'$ $1 $');

    final activeColor = mathColor ?? textStyle?.color ?? Colors.black87;
    final defaultStyle = textStyle ?? TextStyle(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.4);

    // If text contains $ inline math delimiters (e.g. "solve $x^2 + y^2 = 1$")
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

    // If line contains Bengali characters (\u0980-\u09FF)
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

    // Non-Bengali line: Check if pure TeX math
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
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F3),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF3F4F3),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'পরীক্ষা লোড হচ্ছে...',
            style: GoogleFonts.notoSansBengali(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) => const _SkeletonQuestionCard(),
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
            style: GoogleFonts.notoSansBengali(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                ref.read(examRunnerProvider.notifier).submitExam();
                context.pop();
              }
            },
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isLowTime ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: (isLowTime ? Colors.redAccent : const Color(0xFF017A47)).withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isLowTime ? Colors.red.shade700 : const Color(0xFF017A47),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(state.timeLeft),
                    style: GoogleFonts.notoSansBengali(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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


            // Single continuous scroll view with all questions (Virtualized for 1000+ items)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                physics: const BouncingScrollPhysics(),
                cacheExtent: 500,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
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

                        // Question Title Text with highlighted "1. " number and full math support
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF017A47),
                              ),
                            ),
                            Expanded(
                              child: _buildMathWidget(
                                q.questionText,
                                textStyle: const TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Question Media Image (if present)
                        if (q.imageKey != null && q.imageKey!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildQuestionImage(q.imageKey),
                        ],

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
                              textStyle: const TextStyle(fontSize: 17.5, color: Color(0xFF017A47)),
                              onErrorFallback: (err) => Text(
                                q.latexFormula!,
                                style: const TextStyle(fontSize: 16.5, fontStyle: FontStyle.italic, color: Color(0xFF017A47)),
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
                              onTap: selectedOptId != null
                                  ? null
                                  : () {
                                      ref.read(examRunnerProvider.notifier).selectOption(
                                            q.id,
                                            opt.id,
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
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
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildMathWidget(
                                            opt.optionText,
                                            textStyle: TextStyle(
                                              fontSize: 15.5,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                              color: isSelected ? const Color(0xFF017A47) : Colors.black87,
                                            ),
                                            mathColor: isSelected ? const Color(0xFF017A47) : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (opt.imageKey != null && opt.imageKey!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      _buildQuestionImage(opt.imageKey),
                                    ],
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

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: SafeArea(
                top: false,
                bottom: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isSubmitting ? null : _confirmAndSubmitExam,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF017A47),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _formatTime(state.timeLeft),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                height: 16,
                                width: 1.5,
                                color: Colors.white24,
                              ),
                              const Expanded(
                                flex: 2,
                                child: Text(
                                  'সাবমিট করো',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                height: 16,
                                width: 1.5,
                                color: Colors.white24,
                              ),
                              Expanded(
                                child: Text(
                                  '$answeredCount/$totalQuestions',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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

class _SkeletonQuestionCard extends StatefulWidget {
  const _SkeletonQuestionCard({super.key});

  @override
  State<_SkeletonQuestionCard> createState() => _SkeletonQuestionCardState();
}

class _SkeletonQuestionCardState extends State<_SkeletonQuestionCard>
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
              // Question Index & Text placeholder
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFF017A47).withOpacity(opacity * 0.2),
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
                          width: 150,
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
              const SizedBox(height: 24),
              // Options placeholders (4 of them)
              ...List.generate(4, (index) {
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
                          width: 120 + (index * 20 % 50),
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
            ],
          ),
        );
      },
    );
  }
}
