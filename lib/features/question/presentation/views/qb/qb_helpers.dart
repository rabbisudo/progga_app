import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../widgets/shimmer_skeleton.dart';
import '../../widgets/premium_bottom_nav_bar.dart';

export '../../widgets/premium_bottom_nav_bar.dart' show getFloatingNavBarBottomMargin;

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
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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

      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pull handle bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
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
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: subSeries.map((subObj) {
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
                              final subNameLower = subName.toLowerCase();
                              final isK = subNameLower.contains('kbhandar') || subNameLower.contains('ক ভাণ্ডার');
                              final isKh = subNameLower.contains('khabhandar') || subNameLower.contains('খ ভাণ্ডার');
                              if (isK || isKh) {
                                context.push('/exam-preview/$subIdStr', extra: subName);
                              } else if (hasNestedSubSeries) {
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
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 15.0),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF252528) : Colors.grey.shade50,
                                border: Border.all(
                                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      subName,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                        fontFamily: 'Li Ador Noirrit',
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Map<String, dynamic>? findSeriesRecursively(List<dynamic> list, String targetId) {
  for (final item in list) {
    if (item is Map<String, dynamic>) {
      if (item['id']?.toString() == targetId) {
        return item;
      }
      final subSeries = item['subSeries'];
      if (subSeries is List) {
        final found = findSeriesRecursively(subSeries, targetId);
        if (found != null) {
          return found;
        }
      }
    }
  }
  return null;
}

/// Extracts the best available image URL from a Question Bank Series map.
String? resolveSeriesImageUrl(Map<String, dynamic> map) {
  final logo = map['logo']?.toString().trim();
  if (logo != null && logo.isNotEmpty && logo.startsWith('http')) return logo;

  final banner = map['banner']?.toString().trim();
  if (banner != null && banner.isNotEmpty && banner.startsWith('http')) return banner;

  final dynamic subject = map['subject'];
  if (subject is Map) {
    final sMap = Map<String, dynamic>.from(subject);
    final sImg = sMap['imageUrl']?.toString().trim();
    if (sImg != null && sImg.isNotEmpty && sImg.startsWith('http')) return sImg;
    final sIcon = sMap['icon']?.toString().trim();
    if (sIcon != null && sIcon.isNotEmpty && sIcon.startsWith('http')) return sIcon;
  }

  final icon = map['icon']?.toString().trim();
  if (icon != null && icon.isNotEmpty && icon.startsWith('http')) return icon;

  final imageUrl = map['imageUrl']?.toString().trim();
  if (imageUrl != null && imageUrl.isNotEmpty && imageUrl.startsWith('http')) return imageUrl;

  return null;
}

/// A dedicated, beautiful thumbnail widget for Question Bank Series and Sub-series.
/// Renders CachedNetworkImage with high-performance memory cache sizing,
/// shimmer skeleton while loading, and a gorgeous themed gradient icon fallback.
class QbThumbnailWidget extends StatelessWidget {
  final Map<String, dynamic> seriesMap;
  final int index;
  final double? size;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool hasBorder;
  final bool hasShadow;
  final int? memCacheSize;

  const QbThumbnailWidget({
    super.key,
    required this.seriesMap,
    this.index = 0,
    this.size,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.hasBorder = true,
    this.hasShadow = true,
    this.memCacheSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final name = seriesMap['name']?.toString() ?? '';
    final imageUrl = resolveSeriesImageUrl(seriesMap);

    final double w = width ?? size ?? 52;
    final double h = height ?? size ?? 52;
    final int memCache = memCacheSize ??
        ((w != double.infinity) ? (w * 2.5).toInt().clamp(100, 450) : 360);

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF28282B) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder
            ? Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
                width: 1.0,
              )
            : null,
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: Clip.antiAlias,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                width: w,
                height: h,
                memCacheWidth: memCache,
                memCacheHeight: memCache,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (context, url) => ShimmerSkeleton(
                  width: w,
                  height: h,
                  borderRadius: borderRadius,
                ),
                errorWidget: (context, url, error) => _buildFallback(name, isDark),
              )
            : _buildFallback(name, isDark),
      ),
    );
  }

  Widget _buildFallback(String name, bool isDark) {
    final gradient = _getGradient(index, isDark);
    final iconData = _getSubjectIcon(name, index);

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: Colors.white,
              size: 32,
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Li Ador Noirrit',
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  LinearGradient _getGradient(int idx, bool isDark) {
    final gradients = [
      [const Color(0xFF00B09B), const Color(0xFF96C93D)],
      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
      [const Color(0xFFF12711), const Color(0xFFF5AF19)],
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFFF857A6), const Color(0xFFFF5858)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      [const Color(0xFF654EA3), const Color(0xFFEAAFC8)],
      [const Color(0xFF3A7BD5), const Color(0xFF3A6073)],
    ];
    final selected = gradients[idx % gradients.length];
    return LinearGradient(
      colors: selected.map((c) => isDark ? c.withOpacity(0.9) : c).toList(),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getSubjectIcon(String title, int idx) {
    final lower = title.toLowerCase();
    if (lower.contains('bangla') || lower.contains('বাংলা')) return Icons.auto_stories_rounded;
    if (lower.contains('english') || lower.contains('ইংরেজি')) return Icons.translate_rounded;
    if (lower.contains('ict') || lower.contains('আইসিটি')) return Icons.computer_rounded;
    if (lower.contains('physics') || lower.contains('পদার্থ')) return Icons.science_rounded;
    if (lower.contains('chemistry') || lower.contains('রসায়ন')) return Icons.biotech_rounded;
    if (lower.contains('math') || lower.contains('গণিত')) return Icons.calculate_rounded;
    if (lower.contains('biology') || lower.contains('জীব')) return Icons.nature_people_rounded;
    if (lower.contains('economics') || lower.contains('অর্থনীতি')) return Icons.trending_up_rounded;
    if (lower.contains('islam') || lower.contains('ইসলাম')) return Icons.menu_book_rounded;
    if (lower.contains('logic') || lower.contains('যুক্তি')) return Icons.psychology_rounded;
    if (lower.contains('history') || lower.contains('ইতিহাস')) return Icons.history_edu_rounded;
    if (lower.contains('accounting') || lower.contains('হিসাব')) return Icons.receipt_long_rounded;
    if (lower.contains('management') || lower.contains('ব্যবস্থাপনা')) return Icons.business_center_rounded;
    if (lower.contains('geography') || lower.contains('ভূগোল')) return Icons.public_rounded;

    const fallbackIcons = [
      Icons.school_rounded,
      Icons.menu_book_rounded,
      Icons.emoji_events_rounded,
      Icons.workspace_premium_rounded,
      Icons.assignment_rounded,
    ];
    return fallbackIcons[idx % fallbackIcons.length];
  }
}

/// Calculates the exact bottom padding required for scroll views rendered above the floating bottom navigation bar.
/// Dynamically accounts for device safe area insets and navigation bar height,
/// ensuring a clean, comfortable breathing room [extraClearance] above the bar without double-counting.
double getFloatingBottomBarPadding(BuildContext context, {double extraClearance = 12.0}) {
  final bottomInset = MediaQuery.of(context).padding.bottom;
  // If bottomInset >= 72.0, Scaffold has already injected the bottom navigation bar into MediaQuery.
  // We only need to add extraClearance above it to prevent double-counting.
  if (bottomInset >= 72.0) {
    return bottomInset + extraClearance;
  }
  const navBarHeight = 64.0;
  const navBarTopPadding = 4.0;
  final navBarBottomMargin = getFloatingNavBarBottomMargin(context);
  return navBarHeight + navBarTopPadding + navBarBottomMargin + extraClearance;
}
