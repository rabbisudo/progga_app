import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../academics/data/academics_repository.dart';
import '../../../profile/presentation/profile_notifier.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/bouncing_card.dart';
import 'qb/qb_helpers.dart';

const String _editPenSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-width="1.5">
		<path stroke-linecap="round" d="M4 22h16" opacity=".5" />
		<path d="m14.63 2.921l-.742.742l-6.817 6.817c-.462.462-.693.692-.891.947a5.2 5.2 0 0 0-.599.969c-.139.291-.242.601-.449 1.22l-.875 2.626l-.213.641a.848.848 0 0 0 1.073 1.073l.641-.213l2.625-.875c.62-.207.93-.31 1.221-.45q.518-.246.969-.598c.255-.199.485-.43.947-.891l6.817-6.817l.742-.742a3.146 3.146 0 0 0-4.45-4.449Z" />
		<path d="M13.888 3.664S13.98 5.24 15.37 6.63s2.966 1.483 2.966 1.483m-12.579 9.63l-1.5-1.5" opacity=".5" />
	</g>
</svg>''';

class MockExamListView extends ConsumerWidget {
  const MockExamListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final className = ref.watch(userProfileProvider.select((u) => u.value?.profile?.className)) ?? 'HSC 2026';
    final groupName = ref.watch(userProfileProvider.select((u) => u.value?.profile?.batch ?? u.value?.profile?.targetExam)) ?? 'বিজ্ঞান';

    final curriculumAsync = ref.watch(studentCurriculumProvider);

    return curriculumAsync.when(
      loading: () => _buildExamSubjectGridSkeleton(context),
      error: (err, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text(
                'পরীক্ষা লোড করতে সমস্যা হয়েছে: $err',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.refresh(studentCurriculumProvider),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF017A47)),
                child: const Text('পুনরায় চেষ্টা করুন', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
      data: (subjects) {
        if (subjects.isEmpty) {
          return EmptyStateWidget(
            title: '$className ($groupName)-এর জন্য কোনো বিষয় পাওয়া যায়নি',
            subtitle: 'প্রোফাইল থেকে অন্য বিষয়/ক্লাস নির্বাচন করুন।',
            customSvg: _editPenSvg,
          );
        }

        // Precache subject icons so they are loaded instantly from disk/memory cache with 0 delay
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final sub in subjects) {
            if (sub is Map) {
              final rawIcon = sub['icon'] as String?;
              final rawImageUrl = sub['imageUrl'] as String?;
              final url = (rawIcon != null && (rawIcon.startsWith('http://') || rawIcon.startsWith('https://')))
                  ? rawIcon
                  : ((rawImageUrl != null && rawImageUrl.isNotEmpty && (rawImageUrl.startsWith('http://') || rawImageUrl.startsWith('https://')))
                      ? rawImageUrl
                      : null);
              if (url != null && url.isNotEmpty) {
                precacheImage(
                  CachedNetworkImageProvider(url, maxHeight: 66, maxWidth: 66),
                  context,
                );
              }
            }
          }
        });

        return ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, 16, 16, getFloatingBottomBarPadding(context, extraClearance: 16.0)),
          itemCount: subjects.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final subject = subjects[index] as Map<String, dynamic>;
            final subjectName = subject['name'] ?? 'বিষয়';
            final rawIcon = subject['icon'] as String?;
            final rawImageUrl = subject['imageUrl'] as String?;

            final iconImageUrl = (rawIcon != null && (rawIcon.startsWith('http://') || rawIcon.startsWith('https://')))
                ? rawIcon
                : ((rawImageUrl != null && rawImageUrl.isNotEmpty && (rawImageUrl.startsWith('http://') || rawImageUrl.startsWith('https://')))
                    ? rawImageUrl
                    : null);
            final emojiIcon = (rawIcon != null && !rawIcon.startsWith('http')) ? rawIcon : '📚';

            return BouncingCard(
              onTap: () {
                context.push(
                  '/topic-selection/${subject['id']}',
                  extra: subjectName,
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200,
                    width: 1.2,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: _getLeftIconGradient(index, isDark),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: iconImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: iconImageUrl,
                                width: 22,
                                height: 22,
                                memCacheWidth: 66,
                                memCacheHeight: 66,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.medium,
                                fadeInDuration: const Duration(milliseconds: 150),
                                errorWidget: (context, error, stackTrace) => Text(
                                  emojiIcon,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              )
                            : Text(
                                emojiIcon,
                                style: const TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        subjectName,
                        style: TextStyle(
                          fontSize: 15.5,
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
            );
          },
        );
      },
    );
  }

  Widget _buildExamSubjectGridSkeleton(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 16, 16, getFloatingBottomBarPadding(context, extraClearance: 16.0)),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const ShimmerSkeleton(
        width: double.infinity,
        height: 72,
        borderRadius: 20,
      ),
    );
  }

  LinearGradient _getLeftIconGradient(int index, bool isDark) {
    final gradients = [
      [const Color(0xFF00B09B), const Color(0xFF96C93D)],
      [const Color(0xFF4A00E0), const Color(0xFF8E2DE2)],
      [const Color(0xFFF12711), const Color(0xFFF5AF19)],
      [const Color(0xFF00C6FF), const Color(0xFF0072FF)],
      [const Color(0xFFF857A6), const Color(0xFFFF5858)],
      [const Color(0xFF11998E), const Color(0xFF38EF7D)],
    ];
    final selected = gradients[index % gradients.length];
    final opacity = isDark ? 0.22 : 0.12;
    return LinearGradient(
      colors: selected.map((c) => c.withOpacity(opacity)).toList(),
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}
