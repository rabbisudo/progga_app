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
