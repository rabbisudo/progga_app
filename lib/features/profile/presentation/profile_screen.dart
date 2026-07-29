import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_notifier.dart';
import '../../auth/presentation/auth_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: profileAsync.when(
        loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          final profile = user.profile!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card (White theme optimized card)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                          backgroundImage: profile.avatarKey != null ? NetworkImage(profile.avatarKey!) : null,
                          child: profile.avatarKey == null 
                              ? Icon(Icons.person, size: 40, color: theme.colorScheme.primary) 
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '@${user.username}',
                                style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                profile.bio ?? 'EdTech student focusing on exam preparation.',
                                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Stats grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildStatCard(theme, 'XP Points', '${profile.xp}', Icons.bolt, Colors.blue),
                    _buildStatCard(theme, 'Coins Earned', '${profile.coins}', Icons.monetization_on, Colors.orange),
                    _buildStatCard(theme, 'Practice Streak', '${profile.currentStreak} Days', Icons.fireplace, Colors.redAccent),
                    _buildStatCard(theme, 'Active Level', 'Level ${profile.level}', Icons.workspace_premium, Colors.purple),
                  ],
                ),
                const SizedBox(height: 24),

                // Personal & Academic Information Card
                const Text(
                  'ব্যক্তিগত ও অ্যাকাডেমিক তথ্য',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoTile(Icons.person, 'লিঙ্গ', profile.gender == 'FEMALE' ? 'মেয়ে' : 'ছেলে'),
                        if (profile.birthday != null) const Divider(),
                        if (profile.birthday != null) _buildInfoTile(Icons.cake, 'জন্মতারিখ', profile.birthday!.split('T')[0]),
                        if (profile.address != null && profile.address!.isNotEmpty) const Divider(),
                        if (profile.address != null && profile.address!.isNotEmpty) _buildInfoTile(Icons.home, 'ঠিকানা', profile.address!),
                        if (profile.institution != null && profile.institution!.isNotEmpty) const Divider(),
                        if (profile.institution != null && profile.institution!.isNotEmpty) _buildInfoTile(Icons.school, 'প্রতিষ্ঠান', profile.institution!),
                        if (profile.className != null && profile.className!.isNotEmpty) const Divider(),
                        if (profile.className != null && profile.className!.isNotEmpty) _buildInfoTile(Icons.class_, 'শ্রেণী', profile.className!),
                        if (profile.targetExam != null && profile.targetExam!.isNotEmpty) const Divider(),
                        if (profile.targetExam != null && profile.targetExam!.isNotEmpty) _buildInfoTile(Icons.category, 'বিভাগ', profile.targetExam!),
                        if (profile.batch != null && profile.batch!.isNotEmpty) const Divider(),
                        if (profile.batch != null && profile.batch!.isNotEmpty) _buildInfoTile(Icons.group, 'ব্যাচ', profile.batch!),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Settings toggles
                const Text(
                  'Account Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Push Notifications'),
                        subtitle: const Text('Receive practice reminders'),
                        value: profile.pushNotifications,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) {
                          ref.read(userProfileProvider.notifier).updateSettings({'pushNotifications': val});
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Public Profile'),
                        subtitle: const Text('Visible on global leaderboard'),
                        value: profile.profileVisible,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) {
                          ref.read(userProfileProvider.notifier).updateSettings({'profileVisible': val});
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'App Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage('assets/images/logo.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Progga',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Version 1.0.0',
                                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Enterprise MCQ Exam Platform',
                                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text('লগআউট করুন', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF017A47)),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(ThemeData theme, String title, String val, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6))),
                Icon(icon, size: 20, color: color),
              ],
            ),
            Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
