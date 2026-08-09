import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../exam/data/exam_repository.dart';
import '../../../core/widgets/custom_back_button.dart';

final myReportsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.getMyReports();
});

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'আমার রিপোর্টসমূহ',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Noto Sans Bengali',
          ),
        ),
        leading: CustomBackButton(
          color: isDark ? Colors.white : Colors.black87,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF017A47),
        onRefresh: () => ref.refresh(myReportsProvider.future),
        child: reportsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
          error: (err, stack) => Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'রিপোর্ট লোড করতে সমস্যা হয়েছে!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                        fontFamily: 'Noto Sans Bengali',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      err.toString(),
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (reports) {
            if (reports.isEmpty) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_turned_in_outlined,
                          color: isDark ? Colors.white30 : Colors.black26,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'আপনি কোনো প্রশ্ন রিপোর্ট করেননি।',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontFamily: 'Noto Sans Bengali',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'পরীক্ষার ফলাফল পেইজে কোনো প্রশ্নে সমস্যা মনে হলে ফ্ল্যাগ আইকনে ট্যাপ করে রিপোর্ট করতে পারেন।',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white30 : Colors.black38,
                            fontFamily: 'Noto Sans Bengali',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final String qId = report['questionId'] ?? '';
                final String questionText = report['questionText'] ?? '';
                final String? imageKey = report['imageKey'];
                final String? latexFormula = report['latexFormula'];
                final String reason = report['reason'] ?? '';
                final String? details = report['details'];
                final String status = report['status'] ?? 'PENDING';
                final String createdAt = report['createdAt'] ?? '';
                final List<dynamic> options = report['options'] ?? [];
                final List<dynamic> explanations = report['explanations'] ?? [];

                final isResolved = status == 'RESOLVED';
                final statusText = isResolved ? 'সমাধান করা হয়েছে' : 'পেন্ডিং';
                final statusBgColor = isResolved
                    ? (isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9))
                    : (isDark ? const Color(0xFF3E2200) : const Color(0xFFFFF3E0));
                final statusTextColor = isResolved
                    ? const Color(0xFF00C569)
                    : const Color(0xFFFFA726);

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
                    ),
                  ),
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row: Status & Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusTextColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Noto Sans Bengali',
                                ),
                              ),
                            ),
                            Text(
                              _formatDate(createdAt),
                              style: TextStyle(
                                color: isDark ? Colors.white30 : Colors.black38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Question Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${index + 1}. ',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF017A47),
                                fontFamily: 'Noto Sans Bengali',
                              ),
                            ),
                            Expanded(
                              child: _buildResultMathWidget(
                                questionText,
                                textStyle: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                  height: 1.4,
                                  fontFamily: 'Noto Sans Bengali',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (imageKey != null && imageKey.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildQuestionImage(imageKey),
                        ],
                        if (latexFormula != null && latexFormula.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF14221A) : const Color(0xFFF4F9F6),
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
                        // Options list
                        if (options.isNotEmpty) ...[
                          Text(
                            'অপশনসমূহ:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...options.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final opt = entry.value;
                            final String optionText = opt['optionText'] ?? '';
                            final String? optImageKey = opt['imageKey'];
                            final bool isCorrect = opt['isCorrect'] ?? false;
                            
                            final label = _getOptionLabel(idx);

                            Color bgColor = isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFFAFAFA);
                            Color labelBgColor = isDark ? Colors.white10 : Colors.white;
                            Color labelTextColor = isDark ? Colors.white70 : Colors.black54;
                            Border? labelBorder = Border.all(color: const Color(0xFFCFD8DC), width: 1.5);

                            if (isCorrect) {
                              bgColor = isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9);
                              labelBgColor = const Color(0xFF017A47);
                              labelTextColor = Colors.white;
                              labelBorder = null;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCorrect 
                                        ? const Color(0xFF017A47) 
                                        : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
                                    width: 1,
                                  ),
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
                                              fontWeight: isCorrect ? FontWeight.w600 : FontWeight.w400,
                                              color: isCorrect
                                                  ? const Color(0xFF017A47)
                                                  : (isDark ? Colors.white70 : Colors.black87),
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
                          const SizedBox(height: 12),
                        ],
                        if (report['hasExplanation'] == true || 
                            explanations.isNotEmpty) ...[
                          ReportedExplanationCard(
                            questionId: qId,
                            initialExplanations: explanations,
                          ),
                          const SizedBox(height: 12),
                        ],
                        Divider(
                          color: isDark ? Colors.white12 : Colors.grey.shade100,
                          height: 1,
                        ),
                        const SizedBox(height: 12),
                        // Reason
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'অভিযোগের কারণ: ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontFamily: 'Noto Sans Bengali',
                              ),
                            ),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black87,
                                  fontFamily: 'Noto Sans Bengali',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (details != null && details.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'অতিরিক্ত বিবরণ:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                              ),
                            ),
                            child: Text(
                              details,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black87,
                                  fontFamily: 'Noto Sans Bengali',
                                ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ReportedExplanationCard extends ConsumerStatefulWidget {
  final String questionId;
  final List<dynamic> initialExplanations;

  const ReportedExplanationCard({
    super.key,
    required this.questionId,
    required this.initialExplanations,
  });

  @override
  ConsumerState<ReportedExplanationCard> createState() => _ReportedExplanationCardState();
}

class _ReportedExplanationCardState extends ConsumerState<ReportedExplanationCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isUnlocked = false;
  List<dynamic> _explanations = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialExplanations.isNotEmpty) {
      _explanations = widget.initialExplanations;
      _isUnlocked = true;
    }
  }

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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87, fontFamily: 'Noto Sans Bengali'),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনি আজকের ১০টি দৈনিক ব্যাখ্যা দেখার সীমা সম্পূর্ণ করেছেন। আগামীকাল নতুন করে ১০টি ব্যাখ্যা আনলক করতে পারবেন।',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600, height: 1.4, fontFamily: 'Noto Sans Bengali'),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Noto Sans Bengali'),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A24) : const Color(0xFFF0FDF4),
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ব্যাখ্যা',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF017A47),
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
                  const Divider(color: Color(0xFFA7F3D0)),
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
                            fontSize: 13,
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                            fontFamily: 'Noto Sans Bengali',
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

// Global Standalone Math and Image Helpers
String _formatDate(String dateStr) {
  try {
    final date = DateTime.parse(dateStr).toLocal();
    final months = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final String day = _toBengaliNumber(date.day);
    final String year = _toBengaliNumber(date.year);
    final String month = months[date.month - 1];
    final String hour = _toBengaliNumber(date.hour.toString().padLeft(2, '0'));
    final String minute = _toBengaliNumber(date.minute.toString().padLeft(2, '0'));
    
    return '$day $month, $year (সময়: $hour:$minute)';
  } catch (_) {
    return dateStr;
  }
}

String _toBengaliNumber(dynamic input) {
  final Map<String, String> numbers = {
    '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
    '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
  };
  final String str = input.toString();
  var output = '';
  for (var i = 0; i < str.length; i++) {
    output += numbers[str[i]] ?? str[i];
  }
  return output;
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

  String normalizedText = text
      .replaceAll(RegExp(r'\$\$(.*?)\$\$', dotAll: true), r'$ $1 $')
      .replaceAll(RegExp(r'\\\((.*?)\\\)', dotAll: true), r'$ $1 $')
      .replaceAll(RegExp(r'\\\[(.*?)\\\]', dotAll: true), r'$ $1 $');

  final activeColor = mathColor ?? textStyle?.color ?? Colors.black87;
  final defaultStyle = textStyle ?? TextStyle(fontSize: fontSize, color: Colors.black87, fontWeight: FontWeight.bold, height: 1.4);

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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'Noto Sans Bengali'),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
