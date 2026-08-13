import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bouncing_card.dart';
import '../views/spaced_repetition_notifier.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SpacedRepetitionWidget extends ConsumerStatefulWidget {
  final List<dynamic> cards;
  final VoidCallback onFinished;

  const SpacedRepetitionWidget({
    Key? key,
    required this.cards,
    required this.onFinished,
  }) : super(key: key);

  @override
  ConsumerState<SpacedRepetitionWidget> createState() => _SpacedRepetitionWidgetState();
}

class _SpacedRepetitionWidgetState extends ConsumerState<SpacedRepetitionWidget> {
  int _currentIndex = 0;
  String? _selectedOptionId;
  bool _hasAnswered = false;
  final Map<String, Widget> _mathWidgetCache = {};

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty || _currentIndex >= widget.cards.length) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = widget.cards[_currentIndex];
    final question = card['question'];
    if (question == null) return const SizedBox.shrink();

    final questionText = question['questionText'] ?? 'প্রশ্ন';
    final options = question['options'] as List<dynamic>? ?? [];
    final explanations = question['explanations'] as List<dynamic>? ?? [];
    final explanationText = explanations.isNotEmpty ? explanations[0]['text'] : null;

    final isQB = question['isQB'] ?? false;
    final consecutiveCorrect = card['consecutiveCorrect'] ?? 0;
    final interval = card['interval'] ?? 1;

    final isSelectedCorrect = _hasAnswered && _selectedOptionId != null &&
        options.any((o) => o['id'] == _selectedOptionId && o['isCorrect'] == true);
    
    final feedbackBgColor = isSelectedCorrect
        ? const Color(0xFF017A47).withOpacity(isDark ? 0.08 : 0.04)
        : const Color(0xFFD32F2F).withOpacity(isDark ? 0.08 : 0.04);
        
    final feedbackBorderColor = isSelectedCorrect
        ? const Color(0xFF017A47).withOpacity(0.25)
        : const Color(0xFFD32F2F).withOpacity(0.25);

    // Formatting Bengali digits
    String toBengali(String input) {
      const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      String result = input;
      for (int i = 0; i < 10; i++) {
        result = result.replaceAll(english[i], bengali[i]);
      }
      return result;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Container(
          key: ValueKey(_currentIndex),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top indicator row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF017A47).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Color(0xFF017A47),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'স্পেসড রিপিটেশন রিভিশন 🧠',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF017A47),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${toBengali((_currentIndex + 1).toString())}/${toBengali(widget.cards.length.toString())}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : Colors.black45,
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Anki Context Tip
              Text(
                consecutiveCorrect == 0
                    ? 'আগে এই প্রশ্নটি ভুল করেছিলেন। আজ মনে আছে তো?'
                    : 'পরবর্তী ধাপের রিভিশন। সূত্রটি ঝালিয়ে নিন!',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black45,
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
              const SizedBox(height: 8),

              // Question Text
              _buildMathWidget(
                questionText,
                textStyle: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'Li Ador Noirrit',
                  height: 1.4,
                ),
                mathColor: isDark ? Colors.white : Colors.black87,
                fontSize: 14.5,
              ),
              const SizedBox(height: 16),

              // Options List
              ...options.asMap().entries.map((entry) {
                final index = entry.key;
                final opt = entry.value;
                final optionId = opt['id'];
                final optionText = opt['optionText'] ?? '';
                final isCorrect = opt['isCorrect'] as bool? ?? false;

                final optionPrefixes = ['ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ'];
                final prefix = index < optionPrefixes.length ? optionPrefixes[index] : '';

                Color tileColor = Colors.transparent;
                Color borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200;
                
                Color prefixBgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9);
                Color prefixTextColor = isDark ? Colors.white70 : Colors.black54;

                if (_hasAnswered) {
                  if (isCorrect) {
                    tileColor = const Color(0xFF017A47).withOpacity(isDark ? 0.08 : 0.04);
                    borderColor = const Color(0xFF017A47).withOpacity(0.3);
                    prefixBgColor = const Color(0xFF017A47);
                    prefixTextColor = Colors.white;
                  } else if (_selectedOptionId == optionId) {
                    tileColor = const Color(0xFFD32F2F).withOpacity(isDark ? 0.08 : 0.04);
                    borderColor = const Color(0xFFD32F2F).withOpacity(0.3);
                    prefixBgColor = const Color(0xFFD32F2F);
                    prefixTextColor = Colors.white;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: _hasAnswered
                        ? null
                        : () {
                            setState(() {
                              _selectedOptionId = optionId;
                              _hasAnswered = true;
                            });

                            // Submit to spaced repetition engine
                            ref.read(spacedRepetitionProvider.notifier).submitAttempt(
                                  questionId: isQB ? null : question['id'],
                                  qbQuestionId: isQB ? question['id'] : null,
                                  isCorrect: isCorrect,
                                );
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: prefixBgColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              prefix,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: prefixTextColor,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMathWidget(
                              optionText,
                              textStyle: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                              mathColor: isDark ? Colors.white : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              // Answer feedback & explanation
              if (_hasAnswered) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: feedbackBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: feedbackBorderColor,
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Interval calculation tip
                      Row(
                        children: [
                          Icon(
                            isSelectedCorrect ? Icons.verified_rounded : Icons.info_outline_rounded,
                            color: isSelectedCorrect ? const Color(0xFF017A47) : const Color(0xFFD32F2F),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isSelectedCorrect
                                ? 'অভিনন্দন! পরবর্তী রিভিশন ${toBengali((interval * 2).clamp(3, 30).toString())} দিন পর।'
                                : 'ভুল হয়েছে। আগামীকাল এটি আবার প্র্যাকটিস করবেন।',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelectedCorrect ? const Color(0xFF017A47) : const Color(0xFFD32F2F),
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                        ],
                      ),
                      if (explanationText != null && explanationText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'ব্যাখ্যা:',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontFamily: 'Li Ador Noirrit',
                          ),
                        ),
                        const SizedBox(height: 3),
                        _buildMathWidget(
                          explanationText,
                          textStyle: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white38 : Colors.black45,
                            height: 1.35,
                          ),
                          mathColor: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 11.5,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Next Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    BouncingCard(
                      onTap: () {
                        if (_currentIndex + 1 < widget.cards.length) {
                          setState(() {
                            _currentIndex += 1;
                            _selectedOptionId = null;
                            _hasAnswered = false;
                          });
                        } else {
                          widget.onFinished();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF017A47),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentIndex + 1 < widget.cards.length ? 'পরবর্তী প্রশ্ন' : 'রিভিউ সম্পন্ন',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- HTML & LaTeX Parsing helpers ---
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
    cleaned = cleaned.replaceAllMapped(RegExp(r'(?<!\$)\\times(?!\$)'), (m) => '×');
    cleaned = cleaned.replaceAllMapped(RegExp(r'(?<!\$)\\div(?!\$)'), (m) => '÷');
    cleaned = cleaned.replaceAllMapped(RegExp(r'(?<!\$)\\pm(?!\$)'), (m) => '±');

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
    final imgConverted = rawText.replaceAllMapped(
      RegExp(r'''<img[^>]+src=["']([^"']+)["'][^>]*>''', caseSensitive: false),
      (match) => '[IMAGE: ${match.group(1)}]',
    );
    final text = _fixBrokenLatex(_stripHtml(imgConverted));
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

    String normalizedText = text
        .replaceAll(RegExp(r'\$\$(.*?)\$\$', dotAll: true), r'$ $1 $')
        .replaceAll(RegExp(r'\\\((.*?)\\\)', dotAll: true), r'$ $1 $')
        .replaceAll(RegExp(r'\\\[(.*?)\\\]', dotAll: true), r'$ $1 $');

    final activeColor = mathColor ?? textStyle?.color ?? Colors.black87;
    final defaultStyle = textStyle ?? TextStyle(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.4, fontFamily: 'Li Ador Noirrit');

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

    final hasBengali = normalizedText.contains(RegExp(r'[\u0980-\u09FF]'));
    if (hasBengali) {
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

      return Text(
        normalizedText,
        style: defaultStyle,
      );
    }

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
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFF017A47),
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
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
          ),
        ),
      ),
    );
  }
}
