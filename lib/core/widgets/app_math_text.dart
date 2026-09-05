import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Strips HTML tags and decodes common HTML entities
String stripHtmlTags(String htmlString) {
  if (htmlString.isEmpty) return htmlString;
  String result = htmlString;

  // 1. Replace block-level tags or line breaks first with newlines
  result = result.replaceAll(RegExp(r'</p>\s*<p>', caseSensitive: false), '\n');
  result = result.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  result = result.replaceAll(RegExp(r'</li>\s*<li>', caseSensitive: false), '\n');
  result = result.replaceAll(RegExp(r'</div>\s*<div>', caseSensitive: false), '\n');
  result = result.replaceAll(RegExp(r'</tr>\s*<tr>', caseSensitive: false), '\n');

  // 2. Remove all HTML tags FIRST before decoding &lt; and &gt;!
  // (Prevents mathematical inequalities like < and > from being mistakenly stripped as HTML tags)
  result = result.replaceAll(RegExp(r'<[^>]*>'), '');

  // 3. Now safely decode HTML entities
  result = result.replaceAll('&nbsp;', ' ');
  result = result.replaceAll('&amp;', '&');
  result = result.replaceAll('&lt;', '<');
  result = result.replaceAll('&gt;', '>');
  result = result.replaceAll('&quot;', '"');
  result = result.replaceAll('&#39;', "'");
  result = result.replaceAll('&#27;', "'");
  result = result.replaceAll('&deg;', '°');
  result = result.replaceAll('&times;', '×');
  result = result.replaceAll('&divide;', '÷');
  result = result.replaceAll('&plusmn;', '±');
  result = result.replaceAll('&hellip;', '...');
  result = result.replaceAll('&mdash;', '—');
  result = result.replaceAll('&ndash;', '–');

  return result.trim();
}

/// Helper to check if a character position is inside an active $ ... $ math block
bool _isInsideDollar(String text, int pos) {
  int count = 0;
  for (int i = 0; i < pos; i++) {
    if (text[i] == '\$') {
      count++;
    }
  }
  return count % 2 == 1;
}

final Map<String, String> _mathCache = {};
const int _maxMathCacheEntries = 1000;

/// Normalizes math delimiters, cleans escaped control characters, and prepares clean LaTeX string
String cleanAndNormalizeMath(String rawText) {
  if (rawText.isEmpty) return rawText;

  // Check in-memory memoization cache first (Instant O(1) return during scrolling)
  final cached = _mathCache[rawText];
  if (cached != null) return cached;

  // 1. Convert <img ...> to [IMAGE: url]
  String text = rawText.replaceAllMapped(
    RegExp(r'''<img[^>]+src=["']([^"']+)["'][^>]*>''', caseSensitive: false),
    (match) => '[IMAGE: ${match.group(1)}]',
  );

  // 2. Strip HTML tags and safely decode HTML entities
  text = stripHtmlTags(text);

  // 3. Convert LaTeX delimiters \( ... \), \[ ... \], and $$ ... $$ to normalized $ ... $
  text = text
      .replaceAllMapped(RegExp(r'\${2,}(.*?)\${2,}', dotAll: true), (m) => '\$${m.group(1)}\$')
      .replaceAllMapped(RegExp(r'\\{1,2}\[(.*?)\\{1,2}\]', dotAll: true), (m) => '\$${m.group(1)}\$')
      .replaceAllMapped(RegExp(r'\\{1,2}\((.*?)\\{1,2}\)', dotAll: true), (m) => '\$${m.group(1)}\$');

  // 4. Fix escaped control characters during JSON parsing (\f -> \frac, \t -> \times, etc.)
  text = text
      .replaceAll('\x0C', r'\f')
      .replaceAll('\f', r'\f')
      .replaceAll('\x09', r'\t')
      .replaceAll('\t', r'\t');

  // 5. Auto-repair stripped backslashes in common keywords
  text = text
      .replaceAll(RegExp(r'(?<!\\)\brac\{'), r'\frac{')
      .replaceAll(RegExp(r'(?<!\\)\bext\{'), r'\text{')
      .replaceAll(RegExp(r'(?<!\\)\bimes\b'), r'\times')
      .replaceAll(RegExp(r'(?<!\\)\bsqrt\{'), r'\sqrt{')
      .replaceAll(RegExp(r'(?<!\\)\balpha\b'), r'\alpha')
      .replaceAll(RegExp(r'(?<!\\)\bbeta\b'), r'\beta')
      .replaceAll(RegExp(r'(?<!\\)\btheta\b'), r'\theta')
      .replaceAll(RegExp(r'(?<!\\)\bgamma\b'), r'\gamma')
      .replaceAll(RegExp(r'(?<!\\)\blambda\b'), r'\lambda')
      .replaceAll(RegExp(r'(?<!\\)\bmu\b'), r'\mu')
      .replaceAll(RegExp(r'(?<!\\)\bomega\b'), r'\omega')
      .replaceAll(RegExp(r'(?<!\\)\bDelta\b'), r'\Delta')
      .replaceAll(RegExp(r'(?<!\\)\bsigma\b'), r'\sigma')
      .replaceAll(RegExp(r'(?<!\\)\brho\b'), r'\rho')
      .replaceAll(RegExp(r'(?<!\\)\bepsilon\b'), r'\epsilon')
      .replaceAll(RegExp(r'(?<!\\)\binfty\b'), r'\infty')
      .replaceAll(RegExp(r'(?<!\\)\bapprox\b'), r'\approx')
      .replaceAll(RegExp(r'(?<!\\)\bcdot\b'), r'\cdot')
      .replaceAll(RegExp(r'(?<!\\)\bdegree\b'), r'\degree')
      .replaceAll(RegExp(r'(?<!\\)\bpi\b'), r'\pi');

  // 6. Wrap raw math environments like \begin{vmatrix}...\end{vmatrix} into $...$ if not already inside $
  final envRegex = RegExp(
    r'\\begin\{(vmatrix|matrix|pmatrix|bmatrix|Bmatrix|array|aligned|cases)\}(.*?)\\end\{\1\}',
    dotAll: true,
  );
  final List<Match> envMatches = envRegex.allMatches(text).toList();
  if (envMatches.isNotEmpty) {
    final sb = StringBuffer();
    int lastPos = 0;
    for (final m in envMatches) {
      if (m.start > lastPos) {
        sb.write(text.substring(lastPos, m.start));
      }
      if (!_isInsideDollar(text, m.start)) {
        sb.write('\$${m.group(0)}\$');
      } else {
        sb.write(m.group(0));
      }
      lastPos = m.end;
    }
    if (lastPos < text.length) {
      sb.write(text.substring(lastPos));
    }
    text = sb.toString();
  }

  // 7. Auto-wrap raw math commands like \frac{...}{...} or \sqrt{...} into $...$ if not already inside $
  final sb = StringBuffer();
  int i = 0;
  while (i < text.length) {
    if (text[i] == '\$') {
      int nextDollar = text.indexOf('\$', i + 1);
      if (nextDollar != -1) {
        sb.write(text.substring(i, nextDollar + 1));
        i = nextDollar + 1;
        continue;
      }
    }

    if (text.startsWith(r'\frac', i) || text.startsWith(r'\sqrt', i)) {
      int start = i;
      int cmdLen = 5;
      i += cmdLen;

      int openBraces = 0;
      bool foundAnyBrace = false;

      while (i < text.length) {
        if (text[i] == '{') {
          openBraces++;
          foundAnyBrace = true;
        } else if (text[i] == '}') {
          openBraces--;
        }
        i++;
        if (foundAnyBrace && openBraces == 0) {
          int tempPeek = i;
          while (tempPeek < text.length && text[tempPeek].trim().isEmpty) {
            tempPeek++;
          }
          if (tempPeek < text.length && text[tempPeek] == '{') {
            i = tempPeek;
            continue;
          }
          break;
        }
      }

      String texExpr = text.substring(start, i);
      sb.write('\$$texExpr\$');
    } else {
      sb.write(text[i]);
      i++;
    }
  }

  text = sb.toString();

  // 8. Clean up double $$ and empty $ $
  text = text
      .replaceAll(RegExp(r'\${2,}'), r'$')
      .replaceAll(RegExp(r'\$\s*\$'), ' ');

  // 9. Normalize excessive backslashes inside LaTeX row breaks
  text = text.replaceAll(r'\\\\', r'\\');

  final normalized = text.trim();
  if (_mathCache.length >= _maxMathCacheEntries) {
    _mathCache.remove(_mathCache.keys.first);
  }
  _mathCache[rawText] = normalized;

  return normalized;
}

/// Splits multiline text by \n while preserving LaTeX math blocks (matrices, environments) intact
List<String> _splitLinesPreservingMath(String text) {
  final List<String> lines = [];
  final sb = StringBuffer();
  bool insideMath = false;

  for (int i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == '\$') {
      insideMath = !insideMath;
      sb.write(char);
    } else if (char == '\n' && !insideMath) {
      lines.add(sb.toString());
      sb.clear();
    } else {
      sb.write(char);
    }
  }
  if (sb.isNotEmpty || lines.isEmpty) {
    lines.add(sb.toString());
  }
  return lines;
}

/// Helper widget that renders math, latex, Bengali text, and images seamlessly
class AppMathText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final Color? mathColor;
  final double fontSize;
  final Widget Function(String imageUrl)? customImageBuilder;

  const AppMathText({
    super.key,
    required this.text,
    this.textStyle,
    this.mathColor,
    this.fontSize = 14,
    this.customImageBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final cleanedText = cleanAndNormalizeMath(text);

    // 1. Check for embedded [IMAGE: url] tags
    final imageRegex = RegExp(r'\[IMAGE:\s*([^\]]+)\]', caseSensitive: false);
    if (imageRegex.hasMatch(cleanedText)) {
      final List<Widget> widgets = [];
      int lastIndex = 0;

      for (final Match match in imageRegex.allMatches(cleanedText)) {
        if (match.start > lastIndex) {
          final textPart = cleanedText.substring(lastIndex, match.start).trim();
          if (textPart.isNotEmpty) {
            widgets.add(AppMathText(
              text: textPart,
              textStyle: textStyle,
              mathColor: mathColor,
              fontSize: fontSize,
              customImageBuilder: customImageBuilder,
            ));
          }
        }

        final imageUrl = match.group(1)!.trim();
        if (customImageBuilder != null) {
          widgets.add(customImageBuilder!(imageUrl));
        } else {
          widgets.add(_buildDefaultImage(imageUrl));
        }

        lastIndex = match.end;
      }

      if (lastIndex < cleanedText.length) {
        final remainingText = cleanedText.substring(lastIndex).trim();
        if (remainingText.isNotEmpty) {
          widgets.add(AppMathText(
            text: remainingText,
            textStyle: textStyle,
            mathColor: mathColor,
            fontSize: fontSize,
            customImageBuilder: customImageBuilder,
          ));
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      );
    }

    // 2. Handle multiline text while preserving math blocks
    if (cleanedText.contains('\n')) {
      final lines = _splitLinesPreservingMath(cleanedText);
      if (lines.length > 1) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines.map((line) {
            if (line.trim().isEmpty) return const SizedBox(height: 4);
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: AppMathText(
                text: line,
                textStyle: textStyle,
                mathColor: mathColor,
                fontSize: fontSize,
                customImageBuilder: customImageBuilder,
              ),
            );
          }).toList(),
        );
      }
    }

    final activeColor = mathColor ?? textStyle?.color ?? Colors.black87;
    final defaultStyle = textStyle ??
        TextStyle(
          fontSize: fontSize,
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          height: 1.4,
          fontFamily: 'Li Ador Noirrit',
        );

    // 3. If text contains $ inline math delimiters (e.g. "$y^2 = -x$ এর দিকাক্ষের সমীকরণ কোনটি?")
    if (cleanedText.contains('\$')) {
      final List<InlineSpan> spans = [];
      final RegExp regex = RegExp(r'\$([^\$]+)\$', dotAll: true);
      int lastMatchEnd = 0;

      for (final Match match in regex.allMatches(cleanedText)) {
        if (match.start > lastMatchEnd) {
          spans.add(TextSpan(
            text: cleanedText.substring(lastMatchEnd, match.start),
            style: defaultStyle,
          ));
        }

        final latexStr = match.group(1)!.trim();
        if (latexStr.isNotEmpty) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Math.tex(
                  latexStr,
                  textStyle: TextStyle(
                    fontSize: fontSize + 1,
                    color: activeColor,
                    fontWeight: textStyle?.fontWeight ?? FontWeight.normal,
                  ),
                  onErrorFallback: (err) => Text(
                    latexStr,
                    style: TextStyle(
                      fontSize: fontSize,
                      color: activeColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ),
          ));
        }

        lastMatchEnd = match.end;
      }

      if (lastMatchEnd < cleanedText.length) {
        spans.add(TextSpan(
          text: cleanedText.substring(lastMatchEnd),
          style: defaultStyle,
        ));
      }

      return RepaintBoundary(
        child: RichText(
          softWrap: true,
          text: TextSpan(children: spans),
        ),
      );
    }

    // 4. Non-Bengali line or pure math formula (e.g. "4x - 1 = 0" or "y^2 = -x" or "m + n + p")
    final hasBengali = cleanedText.contains(RegExp(r'[\u0980-\u09FF]'));
    if (!hasBengali &&
        (cleanedText.contains(RegExp(r'[=+\-*/^_{}\\]')) || cleanedText.startsWith('\\')) &&
        cleanedText.trim().length > 1) {
      return RepaintBoundary(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Math.tex(
            cleanedText.trim(),
            textStyle: TextStyle(
              fontSize: fontSize + 1,
              color: activeColor,
              fontWeight: textStyle?.fontWeight ?? FontWeight.normal,
            ),
            onErrorFallback: (err) => Text(
              cleanedText,
              style: defaultStyle,
            ),
          ),
        ),
      );
    }

    // 5. Standard plain text
    return Text(
      cleanedText,
      style: defaultStyle,
    );
  }

  Widget _buildDefaultImage(String imageKey) {
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
          memCacheWidth: 600,
          maxWidthDiskCache: 800,
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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Text(
                  'ছবিটি লোড করা যায়নি',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
