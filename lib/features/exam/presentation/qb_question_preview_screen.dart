
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../result/presentation/result_screen.dart';
import '../../question/presentation/widgets/shimmer_skeleton.dart';
import '../data/exam_repository.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A premium, distraction-free reading screen for Question Bank exam previewing.
/// It renders the entire question paper with correct answers and explanations directly visible.
class QbQuestionPreviewScreen extends ConsumerStatefulWidget {
  final String examId;
  final String? title;

  const QbQuestionPreviewScreen({
    super.key,
    required this.examId,
    this.title,
  });

  @override
  ConsumerState<QbQuestionPreviewScreen> createState() => _QbQuestionPreviewScreenState();
}

class _QbQuestionPreviewScreenState extends ConsumerState<QbQuestionPreviewScreen> {
  bool _showSolutions = false;

  // Convert standard digits to Bengali digits
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

  // Get Bengali options label (ক, খ, গ, ঘ, ঙ, চ)
  String _getOptionLabel(int index) {
    const labels = ['ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '${index + 1}';
  }

  // Strip html formatting tags
  String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return htmlString;
    String result = htmlString;
    result = result.replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp(r'</li>\s*<li>', caseSensitive: false), '\n');
    result = result.replaceAll('&nbsp;', ' ');
    result = result.replaceAll('&amp;', '&');
    result = result.replaceAll('&lt;', '<');
    result = result.replaceAll('&gt;', '>');
    result = result.replaceAll('&quot;', '"');
    result = result.replaceAll('&#39;', "'");
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');
    return result.trim();
  }

  // Restore LaTeX symbols and control sequences
  String _fixBrokenLatex(String text) {
    if (text.isEmpty) return text;
    String cleaned = text
        .replaceAll('\x0C', r'\f')
        .replaceAll('\f', r'\f')
        .replaceAll('\x09', r'\t')
        .replaceAll('\t', r'\t');

    cleaned = cleaned
        .replaceAll(RegExp(r'(?<!\\)\brac\{'), r'\frac{')
        .replaceAll(RegExp(r'(?<!\\)\bext\{'), r'\text{')
        .replaceAll(RegExp(r'(?<!\\)\bimes\b'), r'\times')
        .replaceAll(RegExp(r'(?<!\\)\bsqrt\{'), r'\sqrt{')
        .replaceAll(RegExp(r'(?<!\\)\balpha\b'), r'\alpha')
        .replaceAll(RegExp(r'(?<!\\)\bbeta\b'), r'\beta')
        .replaceAll(RegExp(r'(?<!\\)\btheta\b'), r'\theta')
        .replaceAll(RegExp(r'(?<!\\)\bpi\b'), r'\pi');

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\$)\b([a-zA-Z])_\{([^\}]+)\}(?!\$)'),
      (m) => '\$${m.group(1)}_${m.group(2)}\$',
    );

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'(?<!\$)\b([a-zA-Z0-9]+)\^\{?([a-zA-Z0-9\+\-]+)\}?(?!\$)'),
      (m) => '\$${m.group(1)}^${m.group(2)}\$',
    );

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

  // Math Widget Builder supporting mixed inline TeX & Bengali text
  Widget _buildMathWidget(
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

    // Handle embedded image tags
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

    // Handle multiline layout
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

    // Delimiter normalization
    String normalizedText = text
        .replaceAll(RegExp(r'\$\$(.*?)\$\$', dotAll: true), r'$ $1 $')
        .replaceAll(RegExp(r'\\\((.*?)\\\)', dotAll: true), r'$ $1 $')
        .replaceAll(RegExp(r'\\\[(.*?)\\\]', dotAll: true), r'$ $1 $');

    final activeColor = mathColor ?? textStyle?.color ?? Colors.black87;
    final defaultStyle = textStyle ?? TextStyle(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.w600, height: 1.4);

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

    // Non-bengali LaTeX lines validation
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

    return Text(
      normalizedText,
      style: defaultStyle,
    );
  }

  // Question bank media image builder
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
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFECEFF1),
                width: 1.2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_toBengaliDigit(index + 1)}. ',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF017A47),
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                  const Expanded(
                    child: ShimmerSkeleton(
                      width: double.infinity,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...List.generate(4, (optIdx) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0, left: 16.0),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const ShimmerSkeleton(
                      width: 120,
                      height: 12,
                      borderRadius: 3,
                    ),
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(explanationQuotaProvider.future).then((quotaMap) {
        final remaining = (quotaMap['remainingDaily'] as num?)?.toInt() ?? 10;
        ref.read(dailyQuotaProvider.notifier).setQuota(remaining);
      }).catchError((_) {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF121212) : Colors.white;

    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white60 : Colors.black54;

    final examAsync = ref.watch(examDetailsProvider(widget.examId));

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: CustomBackButton(
          color: textColor,
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title ?? 'প্রশ্নপত্র রিডিং',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 16,
            fontFamily: 'Li Ador Noirrit',
          ),
        ),
      ),
      body: examAsync.when(
        loading: () => _buildSkeleton(isDark),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  'প্রশ্নপত্র লোড করা সম্ভব হয়নি: $err',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final examMap = data['exam'] as Map<String, dynamic>? ?? {};
          final examQuestionsList = (examMap['questions'] as List<dynamic>?) ?? [];

          if (examQuestionsList.isEmpty) {
            return Center(
              child: Text(
                'এই প্রশ্নপত্রে কোনো প্রশ্ন পাওয়া যায়নি।',
                style: TextStyle(color: textSecondary, fontSize: 14),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: examQuestionsList.length,
            itemBuilder: (context, index) {
              final eqItem = examQuestionsList[index] as Map<String, dynamic>;
              final qData = (eqItem['question'] as Map<String, dynamic>?) ?? {};

              final questionText = qData['questionText'] as String? ?? '';
              final imageKey = qData['imageKey'] as String?;
              final latexFormula = qData['latexFormula'] as String?;
              final optionsList = (qData['options'] as List<dynamic>?) ?? [];
              final explanationsList = (qData['explanations'] as List<dynamic>?) ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
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
                    // Question Header Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_toBengaliDigit(index + 1)}. ',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF017A47),
                            fontFamily: 'Li Ador Noirrit',
                          ),
                        ),
                        Expanded(
                          child: _buildMathWidget(
                            questionText,
                            textStyle: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.4,
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                        ),
                      ],
                    ),

                    // LaTeX / Image Media
                    if (imageKey != null && imageKey.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildQuestionImage(imageKey),
                    ],
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
                          onErrorFallback: (err) => Text(latexFormula),
                        ),
                      ),
                    ],

                    if (qData['type']?.toString().toUpperCase() != 'WRITTEN') ...[
                      const SizedBox(height: 16),

                      // Options List
                      ...optionsList.asMap().entries.map((optEntry) {
                        final optIdx = optEntry.key;
                        final optData = optEntry.value as Map<String, dynamic>;
                        final optionText = optData['optionText'] as String? ?? '';
                        final optImageKey = optData['imageKey'] as String?;
                        final isCorrect = optData['isCorrect'] as bool? ?? false;
                        final showGreen = _showSolutions && isCorrect;

                        final label = _getOptionLabel(optIdx);

                        // Design styles for option cards
                        final bgColor = showGreen
                            ? (isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9))
                            : (isDark ? Colors.white.withOpacity(0.015) : const Color(0xFFFAFAFA));

                        final labelBgColor = showGreen ? const Color(0xFF017A47) : (isDark ? Colors.white10 : Colors.white);
                        final labelTextColor = showGreen ? Colors.white : (isDark ? Colors.white70 : Colors.black54);
                        final labelBorder = showGreen ? null : Border.all(color: isDark ? Colors.white24 : const Color(0xFFCFD8DC), width: 1.5);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(12),
                              border: showGreen
                                  ? Border.all(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0), width: 1.5)
                                  : Border.all(color: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade100, width: 1.0),
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
                                            fontFamily: 'Li Ador Noirrit',
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMathWidget(
                                        optionText,
                                        textStyle: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: showGreen ? FontWeight.bold : FontWeight.w500,
                                          color: showGreen
                                              ? (isDark ? const Color(0xFF00C569) : const Color(0xFF017A47))
                                              : (isDark ? Colors.white70 : Colors.black87),
                                          fontFamily: 'Li Ador Noirrit',
                                        ),
                                      ),
                                    ),
                                    if (showGreen)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF017A47),
                                        size: 18,
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

                    if (_showSolutions &&
                        (qData['hasExplanation'] == true ||
                         (qData['explanations'] != null && (qData['explanations'] as List).isNotEmpty))) ...[
                      const SizedBox(height: 12),
                      _ExplanationCard(
                        questionId: qData['id']?.toString() ?? qData['_id']?.toString() ?? '',
                        remainingQuota: ref.watch(dailyQuotaProvider),
                        buildMath: _buildMathWidget,
                        buildImage: _buildQuestionImage,
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _showSolutions = !_showSolutions;
          });
        },
        backgroundColor: const Color(0xFF017A47),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SvgPicture.string(
          _showSolutions
              ? '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M0 0h24v24H0z" fill="none" /><path fill="currentColor" d="M9.75 12a2.25 2.25 0 1 1 4.5 0a2.25 2.25 0 0 1-4.5 0" /><path fill="currentColor" fill-rule="evenodd" d="M2 12c0 1.64.425 2.191 1.275 3.296C4.972 17.5 7.818 20 12 20s7.028-2.5 8.725-4.704C21.575 14.192 22 13.639 22 12c0-1.64-.425-2.191-1.275-3.296C19.028 6.5 16.182 4 12 4S4.972 6.5 3.275 8.704C2.425 9.81 2 10.361 2 12m10-3.75a3.75 3.75 0 1 0 0 7.5a3.75 3.75 0 0 0 0-7.5" clip-rule="evenodd" /></svg>'''
              : '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"><path d="M0 0h24v24H0z" fill="none" /><g fill="none" stroke="currentColor" stroke-width="1.5"><path stroke-linecap="round" d="M9 4.46A9.8 9.8 0 0 1 12 4c4.182 0 7.028 2.5 8.725 4.704C21.575 9.81 22 10.361 22 12c0 1.64-.425 2.191-1.275 3.296C19.028 17.5 16.182 20 12 20s-7.028-2.5-8.725-4.704C2.425 14.192 2 13.639 2 12c0-1.64.425-2.191 1.275-3.296A14.5 14.5 0 0 1 5 6.821" /><path d="M15 12a3 3 0 1 1-6 0a3 3 0 0 1 6 0Z" /></g></svg>''',
          width: 24,
          height: 24,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _ExplanationCard extends ConsumerStatefulWidget {
  final String questionId;
  final int remainingQuota;
  final Widget Function(String, {TextStyle? textStyle, Color? mathColor, double fontSize}) buildMath;
  final Widget Function(String?) buildImage;

  const _ExplanationCard({
    required this.questionId,
    required this.remainingQuota,
    required this.buildMath,
    required this.buildImage,
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

  // Convert numbers to Bengali digits
  String _toBengaliDigitLocal(dynamic number) {
    if (number == null) return '০';
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String str = '$number';
    for (int i = 0; i < english.length; i++) {
      str = str.replaceAll(english[i], bengali[i]);
    }
    return str;
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
                            fontFamily: 'Li Ador Noirrit',
                          ),
                        ),
                        Text(
                          currentQuota > 0
                              ? 'দৈনিক ব্যাখ্যা বাকি - ${_toBengaliDigitLocal(currentQuota)}'
                              : 'আজকের ১০টি সীমার সবগুলো দেখা শেষ!',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
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
                  Divider(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)),
                  const SizedBox(height: 6),
                  ..._explanations.map((expData) {
                    final expMap = expData as Map<String, dynamic>;
                    final expText = expMap['text'] as String? ?? '';
                    final expImgKey = expMap['imageKey'] as String?;

                     return Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         widget.buildMath(
                           expText,
                           textStyle: TextStyle(
                             fontSize: 13.5,
                             color: isDark ? Colors.white70 : Colors.black87,
                             fontWeight: FontWeight.w500,
                           ),
                         ),
                         if (expImgKey != null && expImgKey.isNotEmpty)
                           widget.buildImage(expImgKey),
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
