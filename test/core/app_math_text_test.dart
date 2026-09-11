import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:progga/core/widgets/app_math_text.dart';

void main() {
  testWidgets('AppMathText renders Bengali fraction without breaking', (WidgetTester tester) async {
    const input = r'i. আপেক্ষিক ত্রুটি = \frac{চূড়ান্ত ত্রুটি}{পরিমাপ করা মান}';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppMathText(text: input),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Bengali text in numerator and denominator are rendered as Text widgets
    expect(find.text('চূড়ান্ত ত্রুটি'), findsOneWidget);
    expect(find.text('পরিমাপ করা মান'), findsOneWidget);
    expect(find.byType(AppMathText), findsWidgets);
  });

  testWidgets('AppMathText handles multiline Bengali question with multiple fractions', (WidgetTester tester) async {
    const multilineInput = '''
7. পরিমাপের ক্ষেত্রে -
i. আপেক্ষিক ত্রুটি = \\frac{চূড়ান্ত ত্রুটি}{পরিমাপ করা মান}
ii. ভার্নিয়ার ধ্রুবক = \\frac{প্রধান স্কেলের ক্ষুদ্রতম 1 ঘরের মান}{ভার্নিয়ার স্কেলের মোট ভাগ সংখ্যা}
iii. লঘিষ্ঠ গণন = \\frac{বৃত্তাকার স্কেলের ভাগ সংখ্যা}{পিচ}
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppMathText(text: multilineInput),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('চূড়ান্ত ত্রুটি'), findsOneWidget);
    expect(find.text('পরিমাপ করা মান'), findsOneWidget);
    expect(find.text('প্রধান স্কেলের ক্ষুদ্রতম 1 ঘরের মান'), findsOneWidget);
    expect(find.text('ভার্নিয়ার স্কেলের মোট ভাগ সংখ্যা'), findsOneWidget);
    expect(find.text('বৃত্তাকার স্কেলের ভাগ সংখ্যা'), findsOneWidget);
    expect(find.text('পিচ'), findsOneWidget);
  });

  testWidgets('AppMathText cleanly strips \\text { ... } with spaces and renders clean Bengali words', (WidgetTester tester) async {
    const inputWithTextSpaces = r'''
7. পরিমাপের ক্ষেত্রে -
i. আপেক্ষিক ত্রুটি - \frac{\text { চূড়ান্ত ত্রুটি }}{\text { পরিমাপ করা মান }}
ii. ভার্নিয়ার ধ্রুবক - \frac{\text { প্রধান স্কেলের ক্ষুদ্রতম 1 ঘরের মান }}{\text { ভার্নিয়ার স্কেলে মোট ভাগ সংখ্যা }}
iii. লঘিষ্ঠ গণন = \frac{\text { বৃত্তাকার স্কেলের ভাগ সংখ্যা }}{\text { পিচ }}
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppMathText(text: inputWithTextSpaces),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify raw \text { is NOT rendered
    expect(find.textContaining(r'\text'), findsNothing);
    expect(find.textContaining('{'), findsNothing);
    expect(find.textContaining('}'), findsNothing);

    // Verify clean Bengali words are rendered
    expect(find.text('চূড়ান্ত ত্রুটি'), findsOneWidget);
    expect(find.text('পরিমাপ করা মান'), findsOneWidget);
    expect(find.text('প্রধান স্কেলের ক্ষুদ্রতম 1 ঘরের মান'), findsOneWidget);
    expect(find.text('ভার্নিয়ার স্কেলে মোট ভাগ সংখ্যা'), findsOneWidget);
    expect(find.text('বৃত্তাকার স্কেলের ভাগ সংখ্যা'), findsOneWidget);
    expect(find.text('পিচ'), findsOneWidget);
  });
}
