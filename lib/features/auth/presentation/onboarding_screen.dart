import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/custom_back_button.dart';
import '../../academics/data/academics_repository.dart';
import '../../academics/domain/academics_model.dart';
import '../../profile/presentation/profile_notifier.dart';
import 'auth_notifier.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  final List<int> _history = [0];

  // User Profile Data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _selectedGender = 'ছাত্র'; // 'ছাত্র' or 'ছাত্রী'

  // Academic Selections
  AcademicClassModel? _selectedClassModel;
  SubjectGroupModel? _selectedGroupModel;
  AcademicBatchModel? _selectedBatchModel;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    HapticFeedback.lightImpact();
    setState(() {
      _history.add(step);
      _step = step;
    });
  }

  void _prevStep() {
    HapticFeedback.lightImpact();
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _step = _history.last;
      });
    } else if (_step > 0) {
      setState(() {
        _step = 0;
        _history.clear();
        _history.add(0);
      });
    } else {
      context.go('/login');
    }
  }

  Future<void> _submitOnboarding() async {
    if (_nameController.text.trim().isEmpty) {
      _showToast('অনুগ্রহ করে তোমার নাম লিখো');
      _goToStep(1);
      return;
    }

    if (_selectedClassModel == null) {
      _showToast('অনুগ্রহ করে তোমার শ্রেণী নির্বাচন করো');
      _goToStep(2);
      return;
    }

    if (_selectedClassModel!.hasGroup &&
        _selectedClassModel!.groups.isNotEmpty &&
        _selectedGroupModel == null) {
      _showToast('অনুগ্রহ করে তোমার বিভাগ নির্বাচন করো');
      _goToStep(3);
      return;
    }

    List<AcademicBatchModel> availableBatches = [];
    if (_selectedGroupModel != null && _selectedGroupModel!.batches.isNotEmpty) {
      availableBatches = _selectedGroupModel!.batches;
    } else if (_selectedClassModel!.batches.isNotEmpty) {
      availableBatches = _selectedClassModel!.batches;
    }

    if (availableBatches.isNotEmpty && _selectedBatchModel == null) {
      _showToast('অনুগ্রহ করে তোমার ব্যাচ নির্বাচন করো');
      _goToStep(4);
      return;
    }

    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && (phone.length != 11 || !RegExp(r'^01[3-9]\d{8}$').hasMatch(phone))) {
      _showToast('১১ ডিজিটের সঠিক মোবাইল নম্বর দিন (যেমন: 017XXXXXXXX)');
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      await ref.read(userProfileProvider.notifier).updateProfileDetails({
        'fullName': _nameController.text.trim(),
        'phoneNumber': phone.isNotEmpty ? phone : null,
        'gender': _selectedGender == 'ছাত্রী' ? 'FEMALE' : 'MALE',
        'address': '',
        'institution': '',
        'className': _selectedClassModel!.name,
        'classId': _selectedClassModel!.id,
        'groupId': _selectedGroupModel?.id,
        'batchId': _selectedBatchModel?.id,
        'targetExam': _selectedGroupModel?.name ?? '',
        'batch': _selectedBatchModel?.name ?? '',
      });

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        _showToast('ত্রুটি: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Li Ador Noirrit',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isError ? const Color(0xFFE11D48) : const Color(0xFF0071F9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(activeClassesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Top Slim Segmented Progress Bar (Only for steps 1-5)
            if (_step > 0) _buildProgressBar(),

            // Main Dynamic Step Body
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildStepView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: CustomBackButton(
        color: const Color(0xFF1E293B),
        onPressed: _prevStep,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Color(0xFF94A3B8), size: 20),
          tooltip: 'লগআউট',
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (mounted) {
              context.go('/login');
            }
          },
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    const int totalSteps = 5;
    final int currentStep = _step.clamp(1, totalSteps);
    final double progressRatio = currentStep / totalSteps;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: progressRatio,
          minHeight: 4,
          backgroundColor: const Color(0xFFF1F5F9),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0071F9)),
        ),
      ),
    );
  }

  Widget _buildStepView() {
    switch (_step) {
      case 0:
        return KeyedSubtree(
          key: const ValueKey<int>(0),
          child: _buildWelcomeScreen(),
        );
      case 1:
        return KeyedSubtree(
          key: const ValueKey<int>(1),
          child: _buildNameAndGenderScreen(),
        );
      case 2:
        return KeyedSubtree(
          key: const ValueKey<int>(2),
          child: _buildClassScreen(),
        );
      case 3:
        return KeyedSubtree(
          key: const ValueKey<int>(3),
          child: _buildGroupScreen(),
        );
      case 4:
        return KeyedSubtree(
          key: const ValueKey<int>(4),
          child: _buildBatchScreen(),
        );
      case 5:
      default:
        return KeyedSubtree(
          key: const ValueKey<int>(5),
          child: _buildStudentPassScreen(),
        );
    }
  }

  // ==========================================
  // 🌟 STEP 0: MINIMALIST & BOLD WELCOME SCREEN
  // ==========================================
  Widget _buildWelcomeScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Progga Unified Logo
          SvgPicture.asset(
            'assets/images/progga.svg',
            width: 190,
          ),

          const SizedBox(height: 36),

          // Catchy Headline
          const Text(
            'পড়াশোনা হোক সহজ ও আনন্দদায়ক ✨',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: 'Li Ador Noirrit',
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'তোমার পছন্দের বিষয়গুলো নির্ভুলভাবে অনুশীলন করো, দুর্বলতা দূর করো এবং পরীক্ষায় সেরা সাফল্য অর্জন করো।',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xFF64748B),
              height: 1.5,
              fontFamily: 'Li Ador Noirrit',
            ),
          ),

          const SizedBox(height: 36),

          // 3 Clean Floating Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFeatureBadge('🎯 প্রশ্নব্যাংক'),
              const SizedBox(width: 8),
              _buildFeatureBadge('⚡ মডেল টেস্ট'),
              const SizedBox(width: 8),
              _buildFeatureBadge('🏆 লিডারবোর্ড'),
            ],
          ),

          const Spacer(flex: 3),

          // Bottom Primary Button
          _buildBottomButton(
            text: 'যাত্রা শুরু করো',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => _goToStep(1),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
          fontFamily: 'Li Ador Noirrit',
        ),
      ),
    );
  }

  // ==========================================
  // 👤 STEP 1: "তোমার নাম কী?" (NAME & GENDER)
  // ==========================================
  Widget _buildNameAndGenderScreen() {
    final bool hasName = _nameController.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'তোমার নাম কী? ✍️',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'প্রোফাইল তৈরি করতে তোমার পূর্ণ নামটি লিখো।',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),

          const SizedBox(height: 28),

          // Name Input Box (Clean, no icon, modern placeholder)
          TextField(
            controller: _nameController,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              fontFamily: 'Li Ador Noirrit',
            ),
            decoration: InputDecoration(
              hintText: 'তোমার পূর্ণ নাম লিখো...',
              hintStyle: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.normal,
                color: Color(0xFF94A3B8),
                fontFamily: 'Li Ador Noirrit',
              ),
              suffixIcon: _nameController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
                      onPressed: () {
                        _nameController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF0071F9), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 28),

          const Text(
            'তুমি কোন শিক্ষার্থী?',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF475569),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
          const SizedBox(height: 12),

          // Two Simple & Refined Identity Cards
          Row(
            children: [
              Expanded(
                child: _buildGenderCard(
                  gender: 'ছাত্র',
                  label: 'ছাত্র',
                  imagePath: 'assets/images/boy.png',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildGenderCard(
                  gender: 'ছাত্রী',
                  label: 'ছাত্রী',
                  imagePath: 'assets/images/girl.png',
                ),
              ),
            ],
          ),

          const Spacer(),

          // Bottom Button
          _buildBottomButton(
            text: 'পরবর্তী ধাপ',
            icon: Icons.arrow_forward_rounded,
            onPressed: hasName ? () => _goToStep(2) : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGenderCard({
    required String gender,
    required String label,
    required String imagePath,
  }) {
    final bool isSelected = _selectedGender == gender;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedGender = gender);
      },
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xFF0071F9) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0071F9).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0071F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  imagePath,
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF0071F9) : const Color(0xFF0F172A),
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🏫 STEP 2: CLASS SELECTION (TACTILE GRID)
  // ==========================================
  Widget _buildClassScreen() {
    final activeClassesAsync = ref.watch(activeClassesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'তুমি কোন শ্রেণীতে পড়ো? 🏫',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'তোমার শ্রেণী অনুযায়ী প্রশ্নব্যাংক ও পরীক্ষা লোড হবে।',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: activeClassesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF0071F9)),
              ),
              error: (err, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('তালিকা লোড করা যায়নি: $err', style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => ref.refresh(activeClassesProvider),
                      child: const Text('আবার চেষ্টা করো'),
                    ),
                  ],
                ),
              ),
              data: (classes) {
                if (classes.isEmpty) {
                  return const Center(
                    child: Text('বর্তমানে কোনো ক্লাস তালিকাভুক্ত নেই।'),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    final isSelected = _selectedClassModel?.id == cls.id;

                    return _buildModernCardOption(
                      title: cls.name,
                      isSelected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedClassModel = cls;
                          _selectedGroupModel = null;
                          _selectedBatchModel = null;
                        });
                        // Smoothly proceed to next step
                        if (cls.hasGroup && cls.groups.isNotEmpty) {
                          _goToStep(3);
                        } else if (cls.hasBatch && cls.batches.isNotEmpty) {
                          _goToStep(4);
                        } else {
                          _goToStep(5);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),

          if (_selectedClassModel != null) ...[
            const SizedBox(height: 12),
            _buildBottomButton(
              text: 'পরবর্তী ধাপ',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                if (_selectedClassModel!.hasGroup && _selectedClassModel!.groups.isNotEmpty) {
                  _goToStep(3);
                } else if (_selectedClassModel!.hasBatch && _selectedClassModel!.batches.isNotEmpty) {
                  _goToStep(4);
                } else {
                  _goToStep(5);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 🔬 STEP 3: DEPARTMENT / GROUP SELECTION
  // ==========================================
  Widget _buildGroupScreen() {
    final groups = _selectedClassModel?.groups ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'তোমার বিভাগ / গ্রুপ কোনটি? 🔬',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_selectedClassModel?.name ?? 'শ্রেণী'}-এর জন্য সঠিক বিভাগটি নির্বাচন করো।',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final group = groups[index];
                final isSelected = _selectedGroupModel?.id == group.id;

                return _buildModernCardOption(
                  title: group.name,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedGroupModel = group;
                      _selectedBatchModel = null;
                    });
                    if (_selectedClassModel?.hasBatch == true &&
                        (group.batches.isNotEmpty || _selectedClassModel!.batches.isNotEmpty)) {
                      _goToStep(4);
                    } else {
                      _goToStep(5);
                    }
                  },
                );
              },
            ),
          ),

          if (_selectedGroupModel != null) ...[
            const SizedBox(height: 12),
            _buildBottomButton(
              text: 'পরবর্তী ধাপ',
              icon: Icons.arrow_forward_rounded,
              onPressed: () {
                if (_selectedClassModel?.hasBatch == true &&
                    (_selectedGroupModel!.batches.isNotEmpty || _selectedClassModel!.batches.isNotEmpty)) {
                  _goToStep(4);
                } else {
                  _goToStep(5);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 🎯 STEP 4: BATCH SELECTION
  // ==========================================
  Widget _buildBatchScreen() {
    List<AcademicBatchModel> availableBatches = [];
    if (_selectedGroupModel != null && _selectedGroupModel!.batches.isNotEmpty) {
      availableBatches = _selectedGroupModel!.batches;
    } else if (_selectedClassModel != null && _selectedClassModel!.batches.isNotEmpty) {
      availableBatches = _selectedClassModel!.batches;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const Text(
            'তোমার ব্যাচ কোনটি? 🎯',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'তোমার পরীক্ষার সাল ও টার্গেট ব্যাচ নির্বাচন করো।',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: availableBatches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'বর্তমানে কোনো ব্যাচ উপলব্ধ নেই। তুমি সরাসরি এগিয়ে যেতে পারো।',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontFamily: 'Li Ador Noirrit'),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _goToStep(5),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0071F9)),
                          child: const Text('এগিয়ে যাও', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: availableBatches.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final batch = availableBatches[index];
                      final isSelected = _selectedBatchModel?.id == batch.id;

                      return _buildModernCardOption(
                        title: batch.name,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() => _selectedBatchModel = batch);
                          _goToStep(5);
                        },
                      );
                    },
                  ),
          ),

          if (_selectedBatchModel != null) ...[
            const SizedBox(height: 12),
            _buildBottomButton(
              text: 'পরবর্তী ধাপ',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => _goToStep(5),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // 💳 STEP 5: WELCOME HUB & CONFIRMATION
  // ==========================================
  Widget _buildStudentPassScreen() {
    final name = _nameController.text.trim();
    final className = _selectedClassModel?.name ?? 'অনির্দিষ্ট';
    final groupName = _selectedGroupModel?.name;
    final batchName = _selectedBatchModel?.name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),

          // 🌟 CELEBRATION STATUS BADGE
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF16A34A)),
                  SizedBox(width: 6),
                  Text(
                    'প্রোফাইল সেটআপ সম্পন্ন',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            name.isNotEmpty ? 'স্বাগতম, $name! 🎉' : 'সব প্রস্তুত! 🎉',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'তোমার ডিজিটাল অ্যাকাডেমিক কার্ড প্রস্তুত হয়েছে',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontFamily: 'Li Ador Noirrit',
            ),
          ),

          const SizedBox(height: 28),

          // 💎 PREMIUM STUDENT ID PASS CARD
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0071F9).withValues(alpha: 0.07),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Card Top: Brand Logo + Student Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SvgPicture.asset(
                      'assets/images/progga.svg',
                      width: 100,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF0071F9).withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded, size: 14, color: Color(0xFF0071F9)),
                          SizedBox(width: 4),
                          Text(
                            'স্টুডেন্ট আইডি',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0071F9),
                              fontFamily: 'Li Ador Noirrit',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Student Personal Identity
                Text(
                  name.isNotEmpty ? name : 'শিক্ষার্থী',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    fontFamily: 'Li Ador Noirrit',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedGender == 'ছাত্রী' ? 'নিয়মিত ছাত্রী' : 'নিয়মিত ছাত্র',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontFamily: 'Li Ador Noirrit',
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),

                // 3 Profile Info Tiles (Class, Group, Batch)
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileInfoTile(
                        label: 'শ্রেণী',
                        value: className,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (groupName != null && groupName.isNotEmpty) ...[
                      Expanded(
                        child: _buildProfileInfoTile(
                          label: 'বিভাগ',
                          value: groupName,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (batchName != null && batchName.isNotEmpty)
                      Expanded(
                        child: _buildProfileInfoTile(
                          label: 'ব্যাচ',
                          value: batchName,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Change / Edit Link
          Center(
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _goToStep(1);
              },
              icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF64748B)),
              label: const Text(
                'তথ্য পরিবর্তন করতে চাও? এখানে ট্যাপ করো',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
            ),
          ),

          const Spacer(),

          // High Impact Main CTA
          _buildBottomButton(
            text: 'হোম স্ক্রিনে প্রবেশ করো',
            icon: Icons.rocket_launch_rounded,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submitOnboarding,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileInfoTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontFamily: 'Li Ador Noirrit',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              fontFamily: 'Li Ador Noirrit',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ⚡ REUSABLE CARD OPTION WIDGET
  // ==========================================
  Widget _buildModernCardOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0071F9) : const Color(0xFFE2E8F0),
            width: isSelected ? 2.0 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF0071F9).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF0071F9) : const Color(0xFF0F172A),
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF0071F9) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF0071F9) : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🔘 PINNED BOTTOM BUTTON WIDGET
  // ==========================================
  Widget _buildBottomButton({
    required String text,
    IconData? icon,
    bool isLoading = false,
    VoidCallback? onPressed,
  }) {
    final bool isEnabled = onPressed != null;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0071F9),
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF94A3B8),
          elevation: isEnabled ? 3 : 0,
          shadowColor: const Color(0xFF0071F9).withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 18),
                  ],
                ],
              ),
      ),
    );
  }
}
