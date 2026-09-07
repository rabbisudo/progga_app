
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../../core/widgets/app_math_text.dart';
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

  String _formatMarks(dynamic marks) {
    if (marks == null) return '';
    final num val = num.tryParse(marks.toString()) ?? 0;
    if (val == 0) return '';
    if (val == val.toInt()) {
      return ' [মান: ${_toBengaliDigit(val.toInt())}]';
    }
    return ' [মান: ${_toBengaliDigit(val)}]';
  }

  // Get Bengali options label (ক, খ, গ, ঘ, ঙ, চ)
  String _getOptionLabel(int index) {
    const labels = ['ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ'];
    if (index >= 0 && index < labels.length) {
      return labels[index];
    }
    return '${index + 1}';
  }

  bool _isFitbQuestion(String? rawType, String questionText) {
    final type = (rawType ?? '').toUpperCase().trim();
    if (type == 'FILL_IN_THE_GAP' ||
        type == 'FILL_IN_THE_GAPS' ||
        type == 'FILL_IN_THE_GAPS_WITHOUT_CLUES' ||
        type == 'FILL' ||
        type.contains('FILL_IN') ||
        type.contains('CLOZE')) {
      return true;
    }
    return questionText.contains('(a)') &&
        RegExp(r'\(([a-z0-9])\)\s*(——|___+|_+|&mdash;|&ndash;|[\u2014\u2013\u002d]+)', caseSensitive: false)
            .hasMatch(questionText);
  }

  String _getPassageWithoutTable(String html) {
    final clean = html.replaceAll(RegExp(r'<table[^>]*>([\s\S]*?)<\/table>', caseSensitive: false), '').trim();
    return clean.replaceAll(RegExp(r'</?span[^>]*>', caseSensitive: false), '');
  }

  List<String> _extractFitbClues(String questionText, List<dynamic> optionsList) {
    final List<String> clues = [];
    final tdRegex = RegExp(r'<td[^>]*>(?:<p>)?(.*?)(?:</p>)?</td>', caseSensitive: false);
    final matches = tdRegex.allMatches(questionText);
    for (final m in matches) {
      final text = m.group(1)!
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', ' ')
          .trim();
      if (text.isNotEmpty && !RegExp(r'^\([a-z0-9]\)$', caseSensitive: false).hasMatch(text)) {
        clues.add(text);
      }
    }
    if (clues.isNotEmpty) return clues;

    final Set<String> seen = {};
    for (final opt in optionsList) {
      final rawText = opt is Map
          ? (opt['optionText'] ?? opt['text'] ?? '')
          : opt.toString();
      final clean = rawText.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (clean.isNotEmpty &&
          !RegExp(r'^option\s+[a-e]$', caseSensitive: false).hasMatch(clean)) {
        seen.add(clean);
      }
    }
    return seen.toList();
  }

  Map<String, String> _parseFitbAnswers(Map<String, dynamic> qData) {
    final Map<String, String> correctMap = {};
    final optionsList = (qData['options'] as List<dynamic>?) ?? [];

    for (final opt in optionsList) {
      if (opt is Map) {
        final isCorr = opt['isCorrect'];
        final num? idx = (isCorr is num) ? isCorr : num.tryParse(isCorr?.toString() ?? '');
        if (idx != null && idx >= 0 && idx < 26) {
          final key = String.fromCharCode(97 + idx.toInt());
          final val = (opt['optionText'] ?? opt['text'] ?? '')
              .toString()
              .replaceAll(RegExp(r'<[^>]*>'), '')
              .trim();
          if (val.isNotEmpty) {
            correctMap[key] = val;
          }
        }
      }
    }
    if (correctMap.isNotEmpty) return correctMap;

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

    if (solutionHtml.isNotEmpty) {
      final pRegex = RegExp(r'\(([a-z0-9])\)\s*([^<;.,\)\n\r]+)', caseSensitive: false);
      final matches = pRegex.allMatches(solutionHtml).toList();
      for (int i = 0; i < matches.length; i++) {
        final m = matches[i];
        var label = m.group(1)!.toLowerCase();
        if (RegExp(r'^\d+$').hasMatch(label)) {
          label = String.fromCharCode(97 + i);
        }
        final val = m.group(2)!.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (val.isNotEmpty) {
          correctMap[label] = val;
        }
      }
    }

    return correctMap;
  }

  Widget _buildFitbContent(Map<String, dynamic> qData, bool isDark, Color textColor) {
    final rawQuestionText = qData['questionText'] as String? ?? '';
    final qType = (qData['type'] as String? ?? '').toUpperCase().trim();
    final isWithoutClues = qType == 'FILL_IN_THE_GAPS_WITHOUT_CLUES';
    final optionsList = (qData['options'] as List<dynamic>?) ?? [];
    final clues = isWithoutClues ? <String>[] : _extractFitbClues(rawQuestionText, optionsList);
    final answersMap = _parseFitbAnswers(qData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (clues.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B2A20) : const Color(0xFFF1F8F5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFD4E8DC),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 17,
                      color: isDark ? const Color(0xFF00C569) : const Color(0xFF017A47),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'ক্লুসমূহ (শব্দ ভাণ্ডার):',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF00C569) : const Color(0xFF017A47),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: clues.map((clue) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF24382B) : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark ? const Color(0xFF00C569).withOpacity(0.3) : const Color(0xFF017A47).withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        clue,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        if (_showSolutions && answersMap.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF00381C).withOpacity(0.5) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: Color(0xFF017A47),
                    ),
                    SizedBox(width: 7),
                    Text(
                      'সঠিক উত্তরসমূহ:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF017A47),
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: answersMap.entries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1B3B2B) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF00C569).withOpacity(0.3) : const Color(0xFF81C784),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '(${entry.key}) ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF00C569) : const Color(0xFF017A47),
                            ),
                          ),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Math Widget Builder supporting mixed inline TeX & Bengali text
  Widget _buildMathWidget(
    String rawText, {
    TextStyle? textStyle,
    Color? mathColor,
    double fontSize = 14,
  }) {
    return AppMathText(
      text: rawText,
      textStyle: textStyle,
      mathColor: mathColor,
      fontSize: fontSize,
      customImageBuilder: (url) => _buildQuestionImage(url),
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
      imageUrl = 'https://proggadata.twelvemind.com$cleanKey';
    } else {
      imageUrl = 'https://proggadata.twelvemind.com/api/v1/questions/file/$cleanKey';
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

  Widget _buildSubOptionsGrid(List<dynamic> optionsList, bool isDark, Color textColor) {
    if (optionsList.isEmpty) return const SizedBox.shrink();

    bool useSingleColumn = false;
    for (var opt in optionsList) {
      final optData = opt as Map<String, dynamic>;
      final text = optData['optionText'] as String? ?? '';
      final img = optData['imageKey'] as String?;
      if (text.length > 30 || (img != null && img.isNotEmpty)) {
        useSingleColumn = true;
        break;
      }
    }

    if (useSingleColumn) {
      return Column(
        children: optionsList.asMap().entries.map((entry) {
          return _buildOptionRow(entry.key, entry.value as Map<String, dynamic>, isDark, textColor);
        }).toList(),
      );
    }

    final List<Widget> rows = [];
    for (int i = 0; i < optionsList.length; i += 2) {
      final leftOpt = optionsList[i] as Map<String, dynamic>;
      final rightOpt = (i + 1 < optionsList.length) ? optionsList[i + 1] as Map<String, dynamic> : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildOptionRow(i, leftOpt, isDark, textColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: rightOpt != null 
                  ? _buildOptionRow(i + 1, rightOpt, isDark, textColor) 
                  : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildOptionRow(int optIdx, Map<String, dynamic> optData, bool isDark, Color textColor) {
    final optionText = optData['optionText'] as String? ?? '';
    final optImageKey = optData['imageKey'] as String?;
    final isCorrect = optData['isCorrect'] as bool? ?? false;
    final showGreen = _showSolutions && isCorrect;

    final label = _getOptionLabel(optIdx);

    final bgColor = showGreen
        ? (isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9))
        : (isDark ? Colors.white.withOpacity(0.015) : const Color(0xFFFAFAFA));

    final labelBgColor = showGreen ? const Color(0xFF017A47) : (isDark ? Colors.white10 : Colors.white);
    final labelTextColor = showGreen ? Colors.white : (isDark ? Colors.white70 : Colors.black54);
    final labelBorder = showGreen ? null : Border.all(color: isDark ? Colors.white24 : const Color(0xFFCFD8DC), width: 1.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: labelBgColor,
                  border: labelBorder,
                ),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: labelTextColor,
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMathWidget(
                  optionText,
                  textStyle: TextStyle(
                    fontSize: 12.5,
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
                  size: 16,
                ),
            ],
          ),
          if (optImageKey != null && optImageKey.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildQuestionImage(optImageKey),
          ],
        ],
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
              final isFitb = _isFitbQuestion(qData['type']?.toString(), questionText);
              final cleanPassage = _getPassageWithoutTable(questionText);
              final displayQuestionText = (isFitb && cleanPassage.isNotEmpty) ? cleanPassage : questionText;

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
                            displayQuestionText,
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

                    if (qData['subQuestions'] != null && (qData['subQuestions'] as List).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...(qData['subQuestions'] as List).asMap().entries.map((subEntry) {
                        final subIdx = subEntry.key;
                        final subQ = subEntry.value as Map<String, dynamic>;
                        final rawSubQText = subQ['questionText'] as String? ?? '';
                        final subMarks = subQ['marks'] ?? subQ['point'];
                        final marksStr = _formatMarks(subMarks);
                        String subQText = rawSubQText;
                        if (marksStr.isNotEmpty) {
                          if (subQText.endsWith('</p>')) {
                            subQText = subQText.substring(0, subQText.length - 4) + marksStr + '</p>';
                          } else {
                            subQText = subQText + marksStr;
                          }
                        }
                        final subOptions = (subQ['options'] as List<dynamic>?) ?? [];

                        return Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.015) : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFECEFF1),
                              width: 1.2,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Sub-question Header
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${qData['type']?.toString().toUpperCase().startsWith('CQ') == true ? '${subIdx == 0 ? "ক" : subIdx == 1 ? "খ" : subIdx == 2 ? "গ" : subIdx == 3 ? "ঘ" : "ঙ"}' : '${_toBengaliDigit(index + 1)}.${_toBengaliDigit(subIdx + 1)}'}. ',
                                    style: const TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF017A47),
                                      fontFamily: 'Li Ador Noirrit',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildMathWidget(
                                      subQText,
                                      textStyle: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                        height: 1.4,
                                        fontFamily: 'Li Ador Noirrit',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (subQ['type']?.toString().toUpperCase() != 'WRITTEN') ...[
                                const SizedBox(height: 12),
                                _buildSubOptionsGrid(subOptions, isDark, textColor),
                              ],
                              if (_showSolutions && (subQ['hasExplanation'] == true ||
                                  (subQ['explanations'] != null && (subQ['explanations'] as List).isNotEmpty))) ...[
                                const SizedBox(height: 10),
                                _ExplanationCard(
                                  questionId: subQ['id']?.toString() ?? subQ['_id']?.toString() ?? '',
                                  remainingQuota: ref.watch(dailyQuotaProvider),
                                  buildMath: _buildMathWidget,
                                  buildImage: _buildQuestionImage,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ] else if (isFitb) ...[
                      _buildFitbContent(qData, isDark, textColor),
                      if (_showSolutions && (qData['hasExplanation'] == true ||
                          (qData['explanations'] != null && (qData['explanations'] as List).isNotEmpty))) ...[
                        const SizedBox(height: 12),
                        _ExplanationCard(
                          questionId: qData['id']?.toString() ?? qData['_id']?.toString() ?? '',
                          remainingQuota: ref.watch(dailyQuotaProvider),
                          buildMath: _buildMathWidget,
                          buildImage: _buildQuestionImage,
                        ),
                      ],
                    ] else ...[
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

                      if (_showSolutions && (qData['hasExplanation'] == true ||
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
