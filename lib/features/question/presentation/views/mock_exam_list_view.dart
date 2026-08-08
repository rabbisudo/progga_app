import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../academics/data/academics_repository.dart';
import '../../../profile/presentation/profile_notifier.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/bouncing_card.dart';

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

    final profile = ref.watch(userProfileProvider).value?.profile;
    final className = profile?.className ?? 'HSC 2026';
    final groupName = profile?.batch ?? profile?.targetExam ?? 'বিজ্ঞান';

    final curriculumAsync = ref.watch(studentCurriculumProvider);

    return curriculumAsync.when(
      loading: () => _buildExamSubjectGridSkeleton(),
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

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.0,
          ),
          itemCount: subjects.length,
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
              child: Card(
                margin: EdgeInsets.zero,
                elevation: 0,
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFECEFF1),
                    width: 1.2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF017A47).withOpacity(0.12) 
                              : const Color(0xFF017A47).withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: iconImageUrl != null
                              ? Image.network(
                                  iconImageUrl,
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    emojiIcon,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                )
                              : Text(
                                  emojiIcon,
                                  style: const TextStyle(fontSize: 15),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExamSubjectGridSkeleton() {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.0,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => const ShimmerSkeleton(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 16,
      ),
    );
  }
}
