import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../academics/data/academics_repository.dart';
import '../../../../profile/presentation/profile_notifier.dart';

String toBengaliDigits(String input) {
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  String result = input;
  for (int i = 0; i < 10; i++) {
    result = result.replaceAll(english[i], bengali[i]);
  }
  return result;
}

String getExamDateStr(dynamic createdAt, String examTitle) {
  try {
    if (createdAt != null) {
      final dt = DateTime.parse(createdAt.toString());
      final months = [
        'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
        'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
      ];
      final dayStr = toBengaliDigits(dt.day.toString());
      final monthStr = months[dt.month - 1];
      final yearStr = toBengaliDigits(dt.year.toString());
      return '$dayStr $monthStr, $yearStr';
    }
  } catch (_) {}

  final regExp = RegExp(r'\d{4}');
  final match = regExp.firstMatch(examTitle);
  if (match != null) {
    final year = match.group(0)!;
    return '${toBengaliDigits("২৪")} মে, ${toBengaliDigits(year)}';
  }
  final bnRegExp = RegExp(r'[০-৯]{4}');
  final bnMatch = bnRegExp.firstMatch(examTitle);
  if (bnMatch != null) {
    final year = bnMatch.group(0)!;
    return '২৪ মে, $year';
  }
  return '২৪ মে, ২০২৬';
}

void showQbSubSeriesBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required List<dynamic> subSeries,
  required bool isDark,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      if (subSeries.isEmpty) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'কোনো ক্যাটাগরি পাওয়া যায়নি।',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pull handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'Li Ador Noirrit',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'অনুশীলনের বিভাগ নির্বাচন করুন',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontFamily: 'Li Ador Noirrit',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // List of sub-series
              ...subSeries.map((subObj) {
                final subMap = subObj as Map<String, dynamic>;
                final subName = subMap['name']?.toString() ?? '';
                final subIdStr = subMap['id']?.toString() ?? '';

                final nestedSubSeries = (subMap['subSeries'] as List<dynamic>?) ?? [];
                final hasNestedSubSeries = nestedSubSeries.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      if (hasNestedSubSeries) {
                        showQbSubSeriesBottomSheet(
                          context: context,
                          ref: ref,
                          title: subName,
                          subSeries: nestedSubSeries,
                          isDark: isDark,
                        );
                      } else {
                        final resolvedList = (subMap['examsResolvedList'] as List<dynamic>?) ?? [];
                        if (resolvedList.length == 1) {
                          context.push('/exam-preview/${resolvedList.first}', extra: subName);
                        } else {
                          context.push('/qb-exams/$subIdStr', extra: subName);
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            subName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isDark ? Colors.white30 : Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}
