import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'profile_notifier.dart';
import '../domain/profile_model.dart';
import '../../academics/data/academics_repository.dart';
import '../../academics/domain/academics_model.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../question/presentation/practice_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _openEditProfileSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileBottomSheet(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          profileAsync.maybeWhen(
            data: (user) => IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF017A47)),
              tooltip: 'এডিট করুন',
              onPressed: () => _openEditProfileSheet(context, user.profile!),
            ),
            orElse: () => const SizedBox(),
          ),
        ],
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
                    child: Column(
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
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
                                    style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    profile.bio ?? 'EdTech student focusing on exam preparation.',
                                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openEditProfileSheet(context, profile),
                            icon: const Icon(Icons.edit_note, size: 20, color: Color(0xFF017A47)),
                            label: const Text('প্রোফাইল এডিট করুন', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF017A47))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF017A47), width: 1.2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text('লগআউট', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: const Text('আপনি কি নিশ্চিত যে আপনি অ্যাকাউন্ট থেকে লগআউট করতে চান?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('বাতিল', style: TextStyle(color: Colors.grey)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('লগআউট', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );

                      if (shouldLogout == true) {
                        ref.invalidate(userProfileProvider);
                        ref.invalidate(leaderboardProvider);
                        ref.invalidate(practiceProvider);
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text('লগআউট করুন', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                Text(title, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6))),
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

class EditProfileBottomSheet extends ConsumerStatefulWidget {
  final UserProfile profile;

  const EditProfileBottomSheet({super.key, required this.profile});

  @override
  ConsumerState<EditProfileBottomSheet> createState() => _EditProfileBottomSheetState();
}

class _EditProfileBottomSheetState extends ConsumerState<EditProfileBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _institutionController;
  late TextEditingController _addressController;

  String _gender = 'MALE';
  AcademicClassModel? _selectedClass;
  SubjectGroupModel? _selectedGroup;
  AcademicBatchModel? _selectedBatch;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _institutionController = TextEditingController(text: widget.profile.institution ?? '');
    _addressController = TextEditingController(text: widget.profile.address ?? '');
    _gender = widget.profile.gender ?? 'MALE';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _institutionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'institution': _institutionController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _gender,
      };

      if (_selectedClass != null) {
        payload['classId'] = _selectedClass!.id;
        payload['className'] = _selectedClass!.name;
      }
      if (_selectedGroup != null) {
        payload['groupId'] = _selectedGroup!.id;
        payload['targetExam'] = _selectedGroup!.name;
      }
      if (_selectedBatch != null) {
        payload['batchId'] = _selectedBatch!.id;
        payload['batch'] = _selectedBatch!.name;
      }

      await ref.read(userProfileProvider.notifier).updateProfileDetails(payload);

      // Instantly refresh dependent providers so home page updates immediately
      ref.invalidate(leaderboardProvider);
      ref.invalidate(practiceProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('প্রোফাইল সফলভাবে আপডেট করা হয়েছে!'), backgroundColor: Color(0xFF017A47)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('আপডেট করতে সমস্যা হয়েছে: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeClassesAsync = ref.watch(activeClassesProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('প্রোফাইল এডিট করুন', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'পূর্ণ নাম', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'বায়ো (Bio)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _institutionController,
              decoration: const InputDecoration(labelText: 'শিক্ষা প্রতিষ্ঠান', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'ঠিকানা', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'লিঙ্গ', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('ছেলে')),
                DropdownMenuItem(value: 'FEMALE', child: Text('মেয়ে')),
              ],
              onChanged: (val) => setState(() => _gender = val ?? 'MALE'),
            ),
            const SizedBox(height: 16),

            // Dynamic Academics Selection
            activeClassesAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
              error: (err, s) => const SizedBox(),
              data: (classes) {
                if (classes.isEmpty) return const SizedBox();

                final availableGroups = _selectedClass?.groups ?? [];
                List<AcademicBatchModel> availableBatches = [];
                if (_selectedGroup != null && _selectedGroup!.batches.isNotEmpty) {
                  availableBatches = _selectedGroup!.batches;
                } else if (_selectedClass != null && _selectedClass!.batches.isNotEmpty) {
                  availableBatches = _selectedClass!.batches;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('অ্যাকাডেমিক পছন্দ পরিবর্তন করুন:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AcademicClassModel>(
                      value: _selectedClass,
                      hint: Text(widget.profile.className ?? 'শ্রেণী নির্বাচন করুন'),
                      decoration: const InputDecoration(labelText: 'শ্রেণী', border: OutlineInputBorder()),
                      items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedClass = val;
                          _selectedGroup = null;
                          _selectedBatch = null;
                        });
                      },
                    ),
                    if (availableGroups.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<SubjectGroupModel>(
                        value: _selectedGroup,
                        hint: Text(widget.profile.targetExam ?? 'বিভাগ নির্বাচন করুন'),
                        decoration: const InputDecoration(labelText: 'বিভাগ / গ্রুপ', border: OutlineInputBorder()),
                        items: availableGroups.map((g) => DropdownMenuItem(value: g, child: Text(g.name))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedGroup = val;
                            _selectedBatch = null;
                          });
                        },
                      ),
                    ],
                    if (availableBatches.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<AcademicBatchModel>(
                        value: _selectedBatch,
                        hint: Text(widget.profile.batch ?? 'ব্যাচ নির্বাচন করুন'),
                        decoration: const InputDecoration(labelText: 'ব্যাচ', border: OutlineInputBorder()),
                        items: availableBatches.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
                        onChanged: (val) => setState(() => _selectedBatch = val),
                      ),
                    ],
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF017A47),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('সংরক্ষণ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
