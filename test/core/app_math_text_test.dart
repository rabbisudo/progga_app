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

  testWidgets('AppMathText renders HTML tables and ordered lists with Roman numerals', (WidgetTester tester) async {
    const tableQuestionHtml = '''
<table><tbody><tr><td colspan="1" rowspan="1"><p>↓পর্যায় \\ শ্রেণি→</p></td><td colspan="1" rowspan="1"><p>II A</p></td><td colspan="1" rowspan="1"><p>IV A</p></td><td colspan="1" rowspan="1"><p>VI A</p></td></tr><tr><td colspan="1" rowspan="1"><p>২য়</p></td><td colspan="1" rowspan="1"><p><br /></p></td><td colspan="1" rowspan="1"><p>X</p></td><td colspan="1" rowspan="1"><p>Z</p></td></tr><tr><td colspan="1" rowspan="1"><p><br /></p></td><td colspan="1" rowspan="1"><p><br /></p></td><td colspan="1" rowspan="1"><p><br /></p></td><td colspan="1" rowspan="1"><p><br /></p></td></tr><tr><td colspan="1" rowspan="1"><p>৪র্থ</p></td><td colspan="1" rowspan="1"><p>M</p></td><td colspan="1" rowspan="1"><p><br /></p></td><td colspan="1" rowspan="1"><p><br /></p></td></tr></tbody></table><p>XZ<sub>2</sub> এর ক্ষেত্রে-</p><ol><li><p>যৌগটি সমযোজী</p></li><li><p>অণুটি চতুস্থলকীয়</p></li><li><p>অণুতে ১টি পাইবন্ধন আছে</p></li></ol><p>নিচের কোনটি সঠিক?</p>
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppMathText(text: tableQuestionHtml),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Table widget is rendered
    expect(find.byType(Table), findsOneWidget);

    // Verify cell contents
    expect(find.text('II A'), findsOneWidget);
    expect(find.text('IV A'), findsOneWidget);
    expect(find.text('VI A'), findsOneWidget);
    expect(find.text('২য়'), findsOneWidget);
    expect(find.text('X'), findsOneWidget);
    expect(find.text('Z'), findsOneWidget);
    expect(find.text('৪র্থ'), findsOneWidget);
    expect(find.text('M'), findsOneWidget);

    // Verify subscript conversion: XZ₂ instead of XZ2
    expect(find.textContaining('XZ₂'), findsOneWidget);

    // Verify Roman numerals from <ol>
    expect(find.textContaining('i. যৌগটি সমযোজী'), findsOneWidget);
    expect(find.textContaining('ii. অণুটি চতুস্থলকীয়'), findsOneWidget);
    expect(find.textContaining('iii. অণুতে ১টি পাইবন্ধন আছে'), findsOneWidget);

    // Verify closing question text
    expect(find.text('নিচের কোনটি সঠিক?'), findsOneWidget);
  });

  testWidgets('AppMathText renders table with th headers, LaTeX math, and uneven cells', (WidgetTester tester) async {
    const tableMathHtml = '''
<p>উদ্দীপকটি পড়ো:</p>
<table><tbody><tr><th colspan="1" rowspan="1"><p>মৌল</p></th><th colspan="1" rowspan="1"><p>ইলেকট্রন বিন্যাস</p></th></tr><tr><td><p>A</p></td><td><p>\\( \\mathrm{ns}^{2} \\mathrm{np}^{1} \\)</p></td></tr><tr><td><p>B</p></td></tr></tbody></table>
<p>কোনটি সঠিক?</p>
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AppMathText(text: tableMathHtml),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Table), findsOneWidget);
    expect(find.text('মৌল'), findsOneWidget);
    expect(find.text('ইলেকট্রন বিন্যাস'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.text('কোনটি সঠিক?'), findsOneWidget);
  });
}


