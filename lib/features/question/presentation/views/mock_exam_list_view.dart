import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../academics/data/academics_repository.dart';
import '../../../profile/presentation/profile_notifier.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/bouncing_card.dart';

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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📚', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  Text(
                    '$className ($groupName)-এর জন্য কোনো বিষয় পাওয়া যায়নি।',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'প্রোফাইল থেকে অন্য বিষয়/ক্লাস নির্বাচন করুন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/profile'),
                    icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                    label: const Text('ক্লাস পরিবর্তন করুন', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF017A47)),
                  ),
                ],
              ),
            ),
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
