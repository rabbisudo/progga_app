import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_notifier.dart';
import '../domain/profile_model.dart';
import '../../academics/data/academics_repository.dart';
import '../../academics/domain/academics_model.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../question/presentation/practice_notifier.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _institutionController;
  late TextEditingController _addressController;
  late TextEditingController _birthdayController;

  String _gender = 'MALE';
  AcademicClassModel? _selectedClass;
  SubjectGroupModel? _selectedGroup;
  AcademicBatchModel? _selectedBatch;

  bool _isSaving = false;
  bool _isInitialized = false;
  bool _isAcademicsInitialized = false;

  static const Color brandTealColor = Color(0xFF086057); // Deep teal color

  void _initialize(UserProfile profile) {
    if (_isInitialized) return;
    _nameController = TextEditingController(text: profile.fullName);
    _bioController = TextEditingController(text: profile.bio ?? '');
    _institutionController = TextEditingController(text: profile.institution ?? '');
    _addressController = TextEditingController(text: profile.address ?? '');
    _birthdayController = TextEditingController(
      text: profile.birthday != null ? profile.birthday!.split('T')[0] : '',
    );
    _gender = profile.gender ?? 'MALE';
    _isInitialized = true;
  }

  void _initializeAcademics(UserProfile profile, List<AcademicClassModel> classes) {
    if (_isAcademicsInitialized || classes.isEmpty) return;

    // 1. Initialize Class
    if (profile.classId != null) {
      try {
        _selectedClass = classes.firstWhere((c) => c.id == profile.classId);
      } catch (_) {}
    }

    // 2. Initialize Group
    if (_selectedClass != null && profile.groupId != null) {
      try {
        _selectedGroup = _selectedClass!.groups.firstWhere((g) => g.id == profile.groupId);
      } catch (_) {}
    }

    // 3. Initialize Batch
    if (profile.batchId != null) {
      if (_selectedGroup != null) {
        try {
          _selectedBatch = _selectedGroup!.batches.firstWhere((b) => b.id == profile.batchId);
        } catch (_) {}
      }
      if (_selectedBatch == null && _selectedClass != null) {
        try {
          _selectedBatch = _selectedClass!.batches.firstWhere((b) => b.id == profile.batchId);
        } catch (_) {}
      }
    }

    _isAcademicsInitialized = true;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _nameController.dispose();
      _bioController.dispose();
      _institutionController.dispose();
      _addressController.dispose();
      _birthdayController.dispose();
    }
    super.dispose();
  }

  Future<void> _selectBirthday(BuildContext context) async {
    DateTime initialDate = DateTime(2005);
    if (_birthdayController.text.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(_birthdayController.text.trim());
      if (parsed != null) {
        initialDate = parsed;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: brandTealColor,
              onPrimary: Colors.white,
              onSurface: isDark ? Colors.white : Colors.black87,
              surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            ),
            dialogBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthdayController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'institution': _institutionController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _gender,
        'birthday': _birthdayController.text.trim().isNotEmpty
            ? '${_birthdayController.text.trim()}T00:00:00.000Z'
            : null,
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

      ref.invalidate(leaderboardProvider);
      ref.invalidate(practiceProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'প্রোফাইল সফলভাবে আপডেট করা হয়েছে!',
              style: GoogleFonts.notoSansBengali(),
            ),
            backgroundColor: const Color(0xFF017A47),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'আপডেট করতে সমস্যা হয়েছে: $e',
              style: GoogleFonts.notoSansBengali(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final activeClassesAsync = ref.watch(activeClassesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ব্যক্তিগত তথ্য ও অ্যাকাডেমিক',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: brandTealColor)),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (user) {
          final profile = user.profile!;
          _initialize(profile);

          if (activeClassesAsync.hasValue) {
            _initializeAcademics(profile, activeClassesAsync.value!);
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('ব্যক্তিগত তথ্য বিবরণী', theme),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context: context,
                    controller: _nameController,
                    label: 'পূর্ণ নাম',
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'নাম দেওয়া আবশ্যক';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context: context,
                    controller: _bioController,
                    label: 'বায়ো (Bio)',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    style: GoogleFonts.notoSansBengali(
                      color: theme.textTheme.bodyLarge?.color,
                      fontSize: 14,
                    ),
                    decoration: _getInputDecoration(context, 'লিঙ্গ'),
                    items: [
                      DropdownMenuItem(value: 'MALE', child: Text('ছেলে', style: GoogleFonts.notoSansBengali())),
                      DropdownMenuItem(value: 'FEMALE', child: Text('মেয়ে', style: GoogleFonts.notoSansBengali())),
                    ],
                    onChanged: (val) => setState(() => _gender = val ?? 'MALE'),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _selectBirthday(context),
                    child: AbsorbPointer(
                      child: _buildTextField(
                        context: context,
                        controller: _birthdayController,
                        label: 'জন্মতারিখ',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context: context,
                    controller: _institutionController,
                    label: 'শিক্ষা প্রতিষ্ঠান (স্কুল / কলেজ)',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context: context,
                    controller: _addressController,
                    label: 'ঠিকানা',
                  ),
                  const SizedBox(height: 28),

                  // 3. Academic Details Form Card Block
                  activeClassesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: brandTealColor)),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionHeader('অ্যাকাডেমিক বিবরণী', theme),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<AcademicClassModel>(
                            value: _selectedClass,
                            style: GoogleFonts.notoSansBengali(
                              color: theme.textTheme.bodyLarge?.color,
                              fontSize: 14,
                            ),
                            hint: Text(
                              profile.className ?? 'শ্রেণী নির্বাচন করুন',
                              style: GoogleFonts.notoSansBengali(),
                            ),
                            decoration: _getInputDecoration(context, 'শ্রেণী'),
                            items: classes
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c.name, style: GoogleFonts.notoSansBengali()),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedClass = val;
                                _selectedGroup = null;
                                _selectedBatch = null;
                              });
                            },
                          ),
                          if (availableGroups.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<SubjectGroupModel>(
                              value: _selectedGroup,
                              style: GoogleFonts.notoSansBengali(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 14,
                              ),
                              hint: Text(
                                profile.targetExam ?? 'বিভাগ নির্বাচন করুন',
                                style: GoogleFonts.notoSansBengali(),
                              ),
                              decoration: _getInputDecoration(context, 'বিভাগ / গ্রুপ'),
                              items: availableGroups
                                  .map((g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g.name, style: GoogleFonts.notoSansBengali()),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedGroup = val;
                                  _selectedBatch = null;
                                });
                              },
                            ),
                          ],
                          if (availableBatches.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            DropdownButtonFormField<AcademicBatchModel>(
                              value: _selectedBatch,
                              style: GoogleFonts.notoSansBengali(
                                color: theme.textTheme.bodyLarge?.color,
                                fontSize: 14,
                              ),
                              hint: Text(
                                profile.batch ?? 'ব্যাচ নির্বাচন করুন',
                                style: GoogleFonts.notoSansBengali(),
                              ),
                              decoration: _getInputDecoration(context, 'ব্যাচ'),
                              items: availableBatches
                                  .map((b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b.name, style: GoogleFonts.notoSansBengali()),
                                      ))
                                  .toList(),
                              onChanged: (val) => setState(() => _selectedBatch = val),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save Details Button
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandTealColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'সংরক্ষণ করুন',
                              style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Text(
        title,
        style: GoogleFonts.notoSansBengali(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8),
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.notoSansBengali(
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
        fontSize: 13,
      ),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: brandTealColor, width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      style: GoogleFonts.notoSansBengali(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: 14,
      ),
      validator: validator,
      decoration: _getInputDecoration(context, label),
    );
  }
}
