import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../exam/data/exam_repository.dart';

final myReportsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final repo = ref.watch(examRepositoryProvider);
  return repo.getMyReports();
});

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = [
        'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
        'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
      ];
      // Convert numbers to Bengali
      final String day = _toBengaliNumber(date.day);
      final String year = _toBengaliNumber(date.year);
      final String month = months[date.month - 1];
      final String hour = _toBengaliNumber(date.hour.toString().padLeft(2, '0'));
      final String minute = _toBengaliNumber(date.minute.toString().padLeft(2, '0'));
      
      return '$day $month, $year (সময়: $hour:$minute)';
    } catch (_) {
      return dateStr;
    }
  }

  static String _toBengaliNumber(dynamic input) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(myReportsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF3F4F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'আমার রিপোর্টসমূহ',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
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
                    Text(
                      'রিপোর্ট লোড করতে সমস্যা হয়েছে!',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
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
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'পরীক্ষার ফলাফল পেইজে কোনো প্রশ্নে সমস্যা মনে হলে ফ্ল্যাগ আইকনে ট্যাপ করে রিপোর্ট করতে পারেন।',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white30 : Colors.black38,
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
                final String questionText = report['questionText'] ?? '';
                final String reason = report['reason'] ?? '';
                final String? details = report['details'];
                final String status = report['status'] ?? 'PENDING';
                final String createdAt = report['createdAt'] ?? '';
                final List<dynamic> options = report['options'] ?? [];
                final List<dynamic> explanations = report['explanations'] ?? [];

                final isResolved = status == 'RESOLVED';
                final statusText = isResolved ? 'সমাধান করা হয়েছে' : 'পেন্ডিং';
                final statusBgColor = isResolved
                    ? const Color(0xFFE8F5E9)
                    : const Color(0xFFFFF3E0);
                final statusTextColor = isResolved
                    ? const Color(0xFF017A47)
                    : const Color(0xFFE65100);

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
                        const SizedBox(height: 12),
                        // Question text
                        Text(
                          'প্রশ্ন:',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF017A47),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          questionText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Options
                        if (options.isNotEmpty) ...[
                          Text(
                            'অপশনসমূহ:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ...options.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final opt = entry.value;
                            final String optionText = opt['optionText'] ?? '';
                            final bool isCorrect = opt['isCorrect'] ?? false;
                            final prefixes = ['ক', 'খ', 'গ', 'ঘ'];
                            final prefix = idx < prefixes.length ? prefixes[idx] : '${idx + 1}';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isCorrect
                                    ? (isDark ? const Color(0xFF00381C) : const Color(0xFFE8F5E9))
                                    : (isDark ? Colors.white.withOpacity(0.02) : const Color(0xFFF9FAFB)),
                                border: Border.all(
                                  color: isCorrect
                                      ? const Color(0xFF017A47)
                                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: isCorrect
                                          ? const Color(0xFF017A47)
                                          : (isDark ? Colors.white10 : Colors.grey.shade200),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: isCorrect
                                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                                        : Text(
                                            prefix,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                        color: isCorrect
                                            ? (isDark ? Colors.white : const Color(0xFF017A47))
                                            : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                        // Explanations Accordion
                        ReportedExplanationWidget(explanations: explanations),
                        const SizedBox(height: 12),
                        // Divider
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
                              ),
                            ),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white60 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (details != null && details.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          // Details
                          Text(
                            'অতিরিক্ত বিবরণ:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black54,
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

class ReportedExplanationWidget extends StatefulWidget {
  final List<dynamic> explanations;

  const ReportedExplanationWidget({super.key, required this.explanations});

  @override
  State<ReportedExplanationWidget> createState() => _ReportedExplanationWidgetState();
}

class _ReportedExplanationWidgetState extends State<ReportedExplanationWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.explanations.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A24) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFD1FAE5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF017A47), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ব্যাখ্যা',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF017A47),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF017A47),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: isDark ? const Color(0xFF0D5E35) : const Color(0xFFA7F3D0)),
                  const SizedBox(height: 6),
                  ...widget.explanations.map((exp) {
                    final String expText = exp['text'] ?? '';
                    final String? expImageKey = exp['imageKey'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expText,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                            ),
                          ),
                          if (expImageKey != null && expImageKey.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                expImageKey,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
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
