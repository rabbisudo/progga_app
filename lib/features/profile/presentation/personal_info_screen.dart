import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'profile_notifier.dart';
import '../domain/profile_model.dart';
import '../../academics/data/academics_repository.dart';
import '../../academics/domain/academics_model.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../question/presentation/practice_notifier.dart';
import '../../../core/widgets/custom_back_button.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
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
  bool _showValidationErrors = false;

  static const Color brandTealColor = Color(0xFF086057); // Deep teal color

  void _initialize(UserProfile profile) {
    if (_isInitialized) return;
    _nameController = TextEditingController(text: profile.fullName);
    _phoneController = TextEditingController(text: profile.phoneNumber ?? '');
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
    if (_selectedClass == null && profile.className != null && profile.className!.trim().isNotEmpty) {
      try {
        _selectedClass = classes.firstWhere(
          (c) => c.name.trim().toLowerCase() == profile.className!.trim().toLowerCase(),
        );
      } catch (_) {}
    }

    // 2. Initialize Group
    if (_selectedClass != null) {
      if (profile.groupId != null) {
        try {
          _selectedGroup = _selectedClass!.groups.firstWhere((g) => g.id == profile.groupId);
        } catch (_) {}
      }
      if (_selectedGroup == null && profile.targetExam != null && profile.targetExam!.trim().isNotEmpty) {
        try {
          _selectedGroup = _selectedClass!.groups.firstWhere(
            (g) => g.name.trim().toLowerCase() == profile.targetExam!.trim().toLowerCase(),
          );
        } catch (_) {}
      }
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
    if (_selectedBatch == null && profile.batch != null && profile.batch!.trim().isNotEmpty) {
      if (_selectedGroup != null) {
        try {
          _selectedBatch = _selectedGroup!.batches.firstWhere(
            (b) => b.name.trim().toLowerCase() == profile.batch!.trim().toLowerCase(),
          );
        } catch (_) {}
      }
      if (_selectedBatch == null && _selectedClass != null) {
        try {
          _selectedBatch = _selectedClass!.batches.firstWhere(
            (b) => b.name.trim().toLowerCase() == profile.batch!.trim().toLowerCase(),
          );
        } catch (_) {}
      }
    }

    _isAcademicsInitialized = true;
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _nameController.dispose();
      _phoneController.dispose();
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
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: brandTealColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                    surface: Color(0xFF1E1E1E),
                  )
                : const ColorScheme.light(
                    primary: brandTealColor,
                    onPrimary: Colors.white,
                    onSurface: Colors.black87,
                    surface: Colors.white,
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
    final formValid = _formKey.currentState?.validate() ?? false;

    final availableClasses = ref.read(activeClassesProvider).value ?? [];
    bool hasAcademicError = false;
    String? academicErrorMessage;

    if (availableClasses.isNotEmpty) {
      if (_selectedClass == null) {
        hasAcademicError = true;
        academicErrorMessage = 'অনুগ্রহ করে শ্রেণী নির্বাচন করুন';
      } else {
        final availableGroups = _selectedClass!.groups;
        if (availableGroups.isNotEmpty && _selectedGroup == null) {
          hasAcademicError = true;
          academicErrorMessage = 'অনুগ্রহ করে বিভাগ / গ্রুপ নির্বাচন করুন';
        } else {
          List<AcademicBatchModel> availableBatches = [];
          if (_selectedGroup != null && _selectedGroup!.batches.isNotEmpty) {
            availableBatches = _selectedGroup!.batches;
          } else if (_selectedClass!.batches.isNotEmpty) {
            availableBatches = _selectedClass!.batches;
          }

          if (availableBatches.isNotEmpty && _selectedBatch == null) {
            hasAcademicError = true;
            academicErrorMessage = 'অনুগ্রহ করে ব্যাচ নির্বাচন করুন';
          }
        }
      }
    }

    if (!formValid || hasAcademicError) {
      setState(() => _showValidationErrors = true);
      if (academicErrorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              academicErrorMessage,
              style: const TextStyle(fontFamily: 'Li Ador Noirrit'),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final cleanPhone = _phoneController.text.trim();
    if (cleanPhone.isNotEmpty) {
      if (cleanPhone.length != 11 || !RegExp(r'^01[3-9]\d{8}$').hasMatch(cleanPhone)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'অনুগ্রহ করে সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)',
              style: TextStyle(fontFamily: 'Li Ador Noirrit'),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final payload = <String, dynamic>{
        'fullName': _nameController.text.trim(),
        'phoneNumber': cleanPhone.isNotEmpty ? cleanPhone : null,
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
      } else if (_selectedClass != null && _selectedClass!.groups.isEmpty) {
        payload['groupId'] = null;
        payload['targetExam'] = null;
      }
      if (_selectedBatch != null) {
        payload['batchId'] = _selectedBatch!.id;
        payload['batch'] = _selectedBatch!.name;
      } else {
        payload['batchId'] = null;
        payload['batch'] = null;
      }

      await ref.read(userProfileProvider.notifier).updateProfileDetails(payload);

      ref.invalidate(studentCurriculumProvider);
      ref.invalidate(studentQbCurriculumProvider);
      ref.invalidate(qbClassSectionsProvider);
      ref.invalidate(qbClassSeriesProvider);
      ref.invalidate(leaderboardProvider);
      ref.invalidate(practiceProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'প্রোফাইল সফলভাবে আপডেট করা হয়েছে!',
              style: TextStyle(fontFamily: 'Li Ador Noirrit'),
            ),
            backgroundColor: Color(0xFF017A47),
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
              style: const TextStyle(fontFamily: 'Li Ador Noirrit'),
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Li Ador Noirrit',
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: CustomBackButton(
          color: isDark ? Colors.white : Colors.black87,
          onPressed: () => Navigator.pop(context),
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

          final availableClasses = activeClassesAsync.value ?? [];
          
          bool isAcademicComplete = true;
          if (availableClasses.isNotEmpty) {
            if (_selectedClass == null) {
              isAcademicComplete = false;
            } else {
              final availableGroups = _selectedClass!.groups;
              if (availableGroups.isNotEmpty && _selectedGroup == null) {
                isAcademicComplete = false;
              } else {
                List<AcademicBatchModel> availableBatches = [];
                if (_selectedGroup != null && _selectedGroup!.batches.isNotEmpty) {
                  availableBatches = _selectedGroup!.batches;
                } else if (_selectedClass!.batches.isNotEmpty) {
                  availableBatches = _selectedClass!.batches;
                }

                if (availableBatches.isNotEmpty && _selectedBatch == null) {
                  isAcademicComplete = false;
                }
              }
            }
          } else if (activeClassesAsync.isLoading) {
            isAcademicComplete = false;
          }

          final String phoneText = _phoneController.text.trim();
          final bool isPhoneValid = phoneText.isEmpty ||
              (phoneText.length == 11 && RegExp(r'^01[3-9]\d{8}$').hasMatch(phoneText));
          final bool isNameFilled = _nameController.text.trim().isNotEmpty;
          final bool canSave = !_isSaving && isAcademicComplete && isNameFilled && isPhoneValid;

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
                    onChanged: (val) => setState(() {}),
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
                    controller: _phoneController,
                    label: 'মোবাইল নম্বর',
                    hintText: '01XXXXXXXXX',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11),
                    ],
                    onChanged: (val) => setState(() {}),
                    validator: (val) {
                      if (val != null && val.trim().isNotEmpty) {
                        final clean = val.trim();
                        if (clean.length != 11) {
                          return 'মোবাইল নম্বর অবশ্যই ১১ ডিজিট হতে হবে';
                        }
                        if (!RegExp(r'^01[3-9]\d{8}$').hasMatch(clean)) {
                          return 'সঠিক বিডি মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)';
                        }
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
                  _buildCustomDropdown<String>(
                    context: context,
                    label: 'লিঙ্গ',
                    value: _gender,
                    items: [
                      DropdownMenuItem(
                        value: 'MALE', 
                        child: Text(
                          'ছাত্র', 
                          style: TextStyle(fontSize: 14, fontFamily: 'Li Ador Noirrit', color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'FEMALE', 
                        child: Text(
                          'ছাত্রী', 
                          style: TextStyle(fontSize: 14, fontFamily: 'Li Ador Noirrit', color: isDark ? Colors.white : Colors.black87),
                        ),
                      ),
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

                      final String? classError = (_showValidationErrors && _selectedClass == null)
                          ? 'শ্রেণী নির্বাচন করা আবশ্যক'
                          : null;

                      final String? groupError = (_showValidationErrors && availableGroups.isNotEmpty && _selectedGroup == null)
                          ? 'বিভাগ / গ্রুপ নির্বাচন করা আবশ্যক'
                          : null;

                      final String? batchError = (_showValidationErrors && availableBatches.isNotEmpty && _selectedBatch == null)
                          ? 'ব্যাচ নির্বাচন করা আবশ্যক'
                          : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionHeader('অ্যাকাডেমিক বিবরণী', theme, isRequired: true),
                          const SizedBox(height: 12),
                          _buildTextField(
                            context: context,
                            controller: _institutionController,
                            label: 'শিক্ষা প্রতিষ্ঠান (স্কুল / কলেজ)',
                          ),
                          const SizedBox(height: 16),
                          _buildCustomDropdown<AcademicClassModel>(
                            context: context,
                            label: 'শ্রেণী',
                            isRequired: true,
                            value: _selectedClass,
                            hintText: 'শ্রেণী নির্বাচন করুন',
                            errorText: classError,
                            items: classes
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c.name, 
                                        style: TextStyle(fontSize: 14, fontFamily: 'Li Ador Noirrit', color: isDark ? Colors.white : Colors.black87),
                                      ),
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
                            _buildCustomDropdown<SubjectGroupModel>(
                              context: context,
                              label: 'বিভাগ / গ্রুপ',
                              isRequired: true,
                              value: _selectedGroup,
                              hintText: 'বিভাগ নির্বাচন করুন',
                              errorText: groupError,
                              items: availableGroups
                                  .map((g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(
                                          g.name, 
                                          style: TextStyle(fontSize: 14, fontFamily: 'Li Ador Noirrit', color: isDark ? Colors.white : Colors.black87),
                                        ),
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
                            _buildCustomDropdown<AcademicBatchModel>(
                              context: context,
                              label: 'ব্যাচ',
                              isRequired: true,
                              value: _selectedBatch,
                              hintText: 'ব্যাচ নির্বাচন করুন',
                              errorText: batchError,
                              items: availableBatches
                                  .map((b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(
                                          b.name, 
                                          style: TextStyle(fontSize: 14, fontFamily: 'Li Ador Noirrit', color: isDark ? Colors.white : Colors.black87),
                                        ),
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
                    height: 48,
                    child: ElevatedButton(
                      onPressed: canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandTealColor,
                        disabledBackgroundColor: isDark ? Colors.white12 : const Color(0xFFE0E0E0),
                        disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: canSave ? 2 : 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              'সংরক্ষণ করুন',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: canSave ? Colors.white : (isDark ? Colors.white38 : Colors.black38),
                                fontSize: 15,
                                fontFamily: 'Li Ador Noirrit',
                              ),
                            ),
                    ),
                  ),
                  if (!canSave && !_isSaving) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        !isAcademicComplete
                            ? '* শ্রেণী, বিভাগ ও ব্যাচ নির্বাচন করলে বাটন সক্রিয় হবে'
                            : (!isNameFilled
                                ? '* অনুগ্রহ করে আপনার নাম প্রদান করুন'
                                : '* সঠিক ১১ ডিজিটের মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme, {bool isRequired = false}) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey.shade700,
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
          if (isRequired) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'বাধ্যতামূলক',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _getInputDecoration(
    BuildContext context,
    String label, {
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      hintText: hintText,
      hintStyle: TextStyle(
        color: isDark ? Colors.white30 : Colors.black38,
        fontSize: 13,
        fontFamily: 'Li Ador Noirrit',
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      labelStyle: TextStyle(
        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
        fontSize: 13,
        fontFamily: 'Li Ador Noirrit',
      ),
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: brandTealColor, width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(
        color: theme.textTheme.bodyLarge?.color,
        fontSize: 14,
        fontFamily: 'Li Ador Noirrit',
      ),
      validator: validator,
      decoration: _getInputDecoration(
        context,
        label,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  Widget _buildCustomDropdown<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? hintText,
    String? errorText,
    bool isRequired = false,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasError = errorText != null && errorText.isNotEmpty;

    String displayText = hintText ?? '';
    if (value != null) {
      final selectedItem = items.firstWhere(
        (item) => item.value == value,
        orElse: () => items.first,
      );
      if (selectedItem.child is Text) {
        displayText = (selectedItem.child as Text).data ?? '';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey.shade700,
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        MenuAnchor(
          style: MenuStyle(
            backgroundColor: MaterialStateProperty.all(isDark ? const Color(0xFF1E1E1E) : Colors.white),
            surfaceTintColor: MaterialStateProperty.all(Colors.transparent),
            shape: MaterialStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: hasError ? Colors.redAccent : (isDark ? Colors.white10 : Colors.grey.shade200),
                  width: hasError ? 1.5 : 1.2,
                ),
              ),
            ),
            elevation: MaterialStateProperty.all(4),
          ),
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return InkWell(
              onTap: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasError
                        ? Colors.redAccent
                        : (controller.isOpen
                            ? brandTealColor
                            : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))),
                    width: (hasError || controller.isOpen) ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 14,
                          color: value == null 
                              ? (isDark ? Colors.white30 : Colors.black38) 
                              : (isDark ? Colors.white : Colors.black87),
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down_rounded, 
                      color: hasError
                          ? Colors.redAccent
                          : (isDark ? Colors.white54 : Colors.black45),
                      size: 20,
                    ),
                  ],
                ),
              ),
            );
          },
          menuChildren: items.map((item) {
            final isSelected = item.value == value;
            return MenuItemButton(
              onPressed: () => onChanged(item.value),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  isSelected 
                      ? (isDark ? brandTealColor.withOpacity(0.15) : const Color(0xFFE6FCF5))
                      : Colors.transparent
                ),
                padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 48,
                child: item.child,
              ),
            );
          }).toList(),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                const SizedBox(width: 4),
                Text(
                  errorText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.redAccent,
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
