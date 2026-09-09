import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bouncing_card.dart';
import '../views/spaced_repetition_notifier.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/widgets/app_math_text.dart';

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
  late List<dynamic> _sessionCards;
  int _currentIndex = 0;
  String? _selectedOptionId;
  bool _hasAnswered = false;
  final Map<String, Widget> _mathWidgetCache = {};

  @override
  void initState() {
    super.initState();
    _sessionCards = List.from(widget.cards);
  }

  @override
  void didUpdateWidget(covariant SpacedRepetitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only refresh session cards if previous session completed or was empty
    if ((_sessionCards.isEmpty || _currentIndex >= _sessionCards.length) && widget.cards.isNotEmpty) {
      setState(() {
        _sessionCards = List.from(widget.cards);
        _currentIndex = 0;
        _selectedOptionId = null;
        _hasAnswered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionCards.isEmpty || _currentIndex >= _sessionCards.length) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _sessionCards[_currentIndex];
    final question = card['question'];
    if (question == null) return const SizedBox.shrink();

    final options = question['options'] as List<dynamic>? ?? [];
    final isTypeMcq = (question['type'] as String? ?? 'MCQ').trim().toUpperCase() == 'MCQ';
    if (!isTypeMcq || options.length < 2) return const SizedBox.shrink();

    final questionText = question['questionText'] ?? 'প্রশ্ন';

    // Flexible explanation extraction
    final explanations = question['explanations'] as List<dynamic>? ?? [];
    String? explanationText;
    String? explanationImageKey;
    if (explanations.isNotEmpty) {
      final first = explanations[0];
      if (first is Map) {
        explanationText = first['text']?.toString();
        explanationImageKey = first['imageKey']?.toString();
      } else if (first is String) {
        explanationText = first;
      }
    } else if (question['explanation'] != null) {
      explanationText = question['explanation'].toString();
    }

    final isQB = question['isQB'] ?? false;
    final consecutiveCorrect = card['consecutiveCorrect'] ?? 0;
    final interval = card['interval'] ?? 1;

    final isSelectedCorrect = _hasAnswered && _selectedOptionId != null &&
        options.any((o) => o['id'] == _selectedOptionId && o['isCorrect'] == true);

    // Identify correct option
    final correctOption = options.firstWhere(
      (o) => o['isCorrect'] == true,
      orElse: () => null,
    );
    const optionPrefixes = ['ক', 'খ', 'গ', 'ঘ', 'ঙ', 'চ'];
    final correctOptionIndex = correctOption != null ? options.indexOf(correctOption) : -1;
    final correctPrefix = correctOptionIndex >= 0 && correctOptionIndex < optionPrefixes.length
        ? optionPrefixes[correctOptionIndex]
        : '';
    
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
                      const Text(
                        'স্পেসড রিপিটেশন রিভিশন 🧠',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF017A47),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${toBengali((_currentIndex + 1).toString())}/${toBengali(_sessionCards.length.toString())}',
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

              // Context Tip
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
                final isUserSelected = _selectedOptionId == optionId;

                final prefix = index < optionPrefixes.length ? optionPrefixes[index] : '';

                Color tileColor = Colors.transparent;
                Color borderColor = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200;
                
                Color prefixBgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9);
                Color prefixTextColor = isDark ? Colors.white70 : Colors.black54;
                Widget? statusIcon;

                if (_hasAnswered) {
                  if (isCorrect) {
                    // Correct answer always highlighted in Green
                    tileColor = const Color(0xFF017A47).withOpacity(isDark ? 0.12 : 0.07);
                    borderColor = const Color(0xFF017A47).withOpacity(0.4);
                    prefixBgColor = const Color(0xFF017A47);
                    prefixTextColor = Colors.white;
                    statusIcon = const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF017A47),
                      size: 20,
                    );
                  } else if (isUserSelected) {
                    // Wrong selection highlighted in Red
                    tileColor = const Color(0xFFD32F2F).withOpacity(isDark ? 0.12 : 0.07);
                    borderColor = const Color(0xFFD32F2F).withOpacity(0.4);
                    prefixBgColor = const Color(0xFFD32F2F);
                    prefixTextColor = Colors.white;
                    statusIcon = const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFD32F2F),
                      size: 20,
                    );
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

                            // Submit to spaced repetition engine in background without resetting active card
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
                          if (statusIcon != null) ...[
                            const SizedBox(width: 8),
                            statusIcon,
                          ],
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
                  padding: const EdgeInsets.all(14),
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
                      // Status row
                      Row(
                        children: [
                          Icon(
                            isSelectedCorrect ? Icons.verified_rounded : Icons.info_outline_rounded,
                            color: isSelectedCorrect ? const Color(0xFF017A47) : const Color(0xFFD32F2F),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isSelectedCorrect
                                  ? 'অভিনন্দন! আপনার উত্তর সঠিক হয়েছে।'
                                  : 'আপনার উত্তর ভুল হয়েছে।',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isSelectedCorrect ? const Color(0xFF017A47) : const Color(0xFFD32F2F),
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSelectedCorrect
                            ? 'পরবর্তী রিভিশন ${toBengali((interval * 2).clamp(3, 30).toString())} দিন পর।'
                            : 'আগামীকাল এই প্রশ্নটি পুনরায় প্র্যাকটিস করবেন।',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : Colors.black54,
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),

                      // Highlight Correct Answer if user selected wrong
                      if (!isSelectedCorrect && correctOption != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF017A47).withOpacity(isDark ? 0.12 : 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF017A47).withOpacity(0.25),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'সঠিক উত্তর: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF017A47),
                                  fontFamily: 'Li Ador Noirrit',
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '$correctPrefix. ${correctOption['optionText'] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF017A47),
                                    fontFamily: 'Li Ador Noirrit',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Explanation section
                      if (explanationText != null && explanationText.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 15,
                              color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'ব্যাখ্যা:',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildMathWidget(
                          explanationText,
                          textStyle: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white60 : Colors.black87,
                            height: 1.4,
                          ),
                          mathColor: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 11.5,
                        ),
                        if (explanationImageKey != null && explanationImageKey.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          _buildQuestionImage(explanationImageKey),
                        ],
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
                        if (_currentIndex + 1 < _sessionCards.length) {
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
                              _currentIndex + 1 < _sessionCards.length ? 'পরবর্তী প্রশ্ন' : 'রিভিউ সম্পন্ন',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _currentIndex + 1 < _sessionCards.length
                                  ? Icons.arrow_forward_rounded
                                  : Icons.check_circle_rounded,
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

  // --- Math Parsing Widget ---
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

    final parsedWidget = AppMathText(
      text: rawText,
      textStyle: textStyle,
      mathColor: mathColor,
      fontSize: fontSize,
      customImageBuilder: (url) => _buildQuestionImage(url),
    );

    _mathWidgetCache[cacheKey] = parsedWidget;
    return parsedWidget;
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
          memCacheWidth: 800,
          maxWidthDiskCache: 1200,
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
