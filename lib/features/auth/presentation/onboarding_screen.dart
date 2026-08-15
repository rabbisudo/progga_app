import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../academics/data/academics_repository.dart';
import '../../../core/widgets/custom_back_button.dart';
import '../../academics/domain/academics_model.dart';
import 'auth_notifier.dart';
import 'package:video_player/video_player.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  String? _selectedClass;
  String? _selectedGroup;
  String? _selectedBatch;
  AcademicClassModel? _selectedClassModel;
  SubjectGroupModel? _selectedGroupModel;
  AcademicBatchModel? _selectedBatchModel;
  String _selectedGender = 'ছাত্র'; // 'ছাত্র' (MALE) or 'ছাত্রী' (FEMALE)
  DateTime? _selectedBirthday;
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  
  bool _isSubmitting = false;
  bool _isTalking = true;
  Timer? _talkingTimer;
  VideoPlayerController? _sleepingController;
  bool _isSleepingInitialized = false;
  VideoPlayerController? _happyController;
  bool _isHappyInitialized = false;
  VideoPlayerController? _celebratingController;
  bool _isCelebratingInitialized = false;
  VideoPlayerController? _yawningController;
  bool _isYawningInitialized = false;
  VideoPlayerController? _scaredController;
  bool _isScaredInitialized = false;
  VideoPlayerController? _partyController;
  bool _isPartyInitialized = false;

  @override
  void initState() {
    super.initState();
    _startTalkingTimer();
    _initSleepingController();
    _initHappyController();
    _initCelebratingController();
    _initYawningController();
    _initScaredController();
    _initPartyController();
  }

  void _initSleepingController() {
    _sleepingController = VideoPlayerController.asset('assets/images/panda_sleeping.mp4');
    _sleepingController?.initialize().then((_) {
      _sleepingController?.setLooping(true);
      _sleepingController?.setVolume(0.0);
      _sleepingController?.play();
      _sleepingController?.addListener(() {
        if (_sleepingController != null &&
            _sleepingController!.value.isInitialized &&
            _sleepingController!.value.position >= _sleepingController!.value.duration) {
          _sleepingController?.seekTo(Duration.zero);
          _sleepingController?.play();
        }
      });
      if (mounted) {
        setState(() {
          _isSleepingInitialized = true;
        });
      }
    });
  }

  void _initHappyController() {
    _happyController = VideoPlayerController.asset('assets/images/panda_happy.mp4');
    _happyController?.initialize().then((_) {
      _happyController?.setLooping(true);
      _happyController?.setVolume(0.0);
      _happyController?.addListener(() {
        if (_happyController != null &&
            _happyController!.value.isInitialized &&
            _happyController!.value.position >= _happyController!.value.duration) {
          _happyController?.seekTo(Duration.zero);
          _happyController?.play();
        }
      });
      if (mounted) {
        setState(() {
          _isHappyInitialized = true;
        });
      }
    });
  }

  void _initCelebratingController() {
    _celebratingController = VideoPlayerController.asset('assets/images/panda_celebrating.mp4');
    _celebratingController?.initialize().then((_) {
      _celebratingController?.setLooping(true);
      _celebratingController?.setVolume(0.0);
      _celebratingController?.addListener(() {
        if (_celebratingController != null &&
            _celebratingController!.value.isInitialized &&
            _celebratingController!.value.position >= _celebratingController!.value.duration) {
          _celebratingController?.seekTo(Duration.zero);
          _celebratingController?.play();
        }
      });
      if (mounted) {
        setState(() {
          _isCelebratingInitialized = true;
        });
      }
    });
  }

  void _initYawningController() {
    _yawningController = VideoPlayerController.asset('assets/images/panda_yawning.mp4');
    _yawningController?.initialize().then((_) {
      _yawningController?.setLooping(true);
      _yawningController?.setVolume(0.0);
      _yawningController?.addListener(() {
        if (_yawningController != null &&
            _yawningController!.value.isInitialized &&
            _yawningController!.value.position >= _yawningController!.value.duration) {
          _yawningController?.seekTo(Duration.zero);
          _yawningController?.play();
        }
      });
      if (mounted) {
        setState(() {
          _isYawningInitialized = true;
        });
      }
    });
  }

  void _initScaredController() {
    _scaredController = VideoPlayerController.asset('assets/images/panda_scared.mp4');
    _scaredController?.initialize().then((_) {
      _scaredController?.setLooping(true);
      _scaredController?.setVolume(0.0);
      _scaredController?.addListener(() {
        if (_scaredController != null &&
            _scaredController!.value.isInitialized &&
            _scaredController!.value.position >= _scaredController!.value.duration) {
          _scaredController?.seekTo(Duration.zero);
          _scaredController?.play();
        }
      });
      if (mounted) {
        setState(() {
          _isScaredInitialized = true;
        });
      }
    });
  }

  void _initPartyController() {
    _partyController = VideoPlayerController.asset('assets/images/panda_party.mp4');
    _partyController?.initialize().then((_) {
      _partyController?.setLooping(true);
      _partyController?.setVolume(0.0);
      _partyController?.addListener(() {
        if (_partyController != null &&
            _partyController!.value.isInitialized &&
            _partyController!.value.position >= _partyController!.value.duration) {
          _partyController?.seekTo(Duration.zero);
          _partyController?.play();
        }
      });
      if (mounted) {
        setState(() {
          _isPartyInitialized = true;
        });
      }
    });
  }

  void _startTalkingTimer() {
    setState(() {
      _isTalking = true;
    });
    _talkingTimer?.cancel();
    _talkingTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _isTalking = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _talkingTimer?.cancel();
    _nameController.dispose();
    _addressController.dispose();
    _institutionController.dispose();
    _sleepingController?.dispose();
    _happyController?.dispose();
    _celebratingController?.dispose();
    _yawningController?.dispose();
    _scaredController?.dispose();
    _partyController?.dispose();
    super.dispose();
  }

  void _nextStep() {
    _talkingTimer?.cancel();
    setState(() {
      _isTalking = false;
      _step++;
    });
    if (_step == 5) {
      _startTalkingTimer();
    }
  }

  void _prevStep() {
    _talkingTimer?.cancel();
    if (_step > 0) {
      setState(() {
        _isTalking = false;
        _step--;
      });
    }
  }

  Future<void> _submitOnboarding() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(userProfileProvider.notifier).updateProfileDetails({
        'fullName': _nameController.text.trim(),
        'gender': _selectedGender == 'ছাত্রী' ? 'FEMALE' : 'MALE',
        'birthday': _selectedBirthday?.toUtc().toIso8601String(),
        'address': _addressController.text.trim(),
        'institution': '',
        'className': _selectedClassModel?.name ?? _selectedClass,
        'classId': _selectedClassModel?.id,
        'groupId': _selectedGroupModel?.id,
        'batchId': _selectedBatchModel?.id,
        'targetExam': _selectedGroupModel?.name ?? _selectedGroup ?? '',
        'batch': _selectedBatchModel?.name ?? _selectedBatch ?? '',
      });
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ত্রুটি ঘটেছে: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Preheat activeClassesProvider to load classes in the background and avoid loading screens
    ref.watch(activeClassesProvider);

    // Reactively manage active step video players
    if (_step == 0) {
      if (_sleepingController != null && !_sleepingController!.value.isPlaying) {
        _sleepingController?.play();
      }
    } else {
      _sleepingController?.pause();
    }
    if (_step == 1) {
      if (_happyController != null && !_happyController!.value.isPlaying) {
        _happyController?.play();
      }
    } else {
      _happyController?.pause();
    }
    if (_step == 2) {
      if (_celebratingController != null && !_celebratingController!.value.isPlaying) {
        _celebratingController?.play();
      }
    } else {
      _celebratingController?.pause();
    }
    if (_step == 3) {
      if (_yawningController != null && !_yawningController!.value.isPlaying) {
        _yawningController?.play();
      }
    } else {
      _yawningController?.pause();
    }
    if (_step == 4) {
      if (_scaredController != null && !_scaredController!.value.isPlaying) {
        _scaredController?.play();
      }
    } else {
      _scaredController?.pause();
    }
    if (_step == 5) {
      if (_partyController != null && !_partyController!.value.isPlaying) {
        _partyController?.play();
      }
    } else {
      _partyController?.pause();
    }

    String speechText = '';
    String mascotState = 'wave';

    switch (_step) {
      case 0:
        speechText = 'Hi, I am Pandu..';
        mascotState = 'wave';
        break;
      case 1:
        speechText = 'তোমার ব্যক্তিগত তথ্য দাও বন্ধু!';
        mascotState = 'write';
        break;
      case 2:
        speechText = 'তুমি কোন শ্রেণীতে পড়ো?';
        mascotState = 'read';
        break;
      case 3:
        speechText = 'তোমার বিভাগ কোনটি?';
        mascotState = 'write';
        break;
      case 4:
        speechText = 'তোমার পরীক্ষার ব্যাচ কোনটি?';
        mascotState = 'think';
        break;
      case 5:
        speechText = 'স্বাগতম ${_nameController.text.trim()}!\nProgga-এর সাথে তোমার যাত্রা শুরু হোক!';
        mascotState = 'welcome';
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CustomBackButton(
          color: Colors.black87,
          onPressed: _step > 0 ? _prevStep : () => context.go('/login'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            tooltip: 'লগআউট',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // 1. Speech Bubble
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xFF1E88E5).withOpacity(0.15),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1E88E5).withOpacity(0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: TypewriterText(
                                text: speechText,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E), // deep indigo
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                            // Speech bubble triangle pointing down
                            Transform.translate(
                              offset: const Offset(0, -6),
                              child: Transform.rotate(
                                angle: 0.785, // 45 degrees
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: const Color(0xFF1E88E5).withOpacity(0.15),
                                        width: 1.5,
                                      ),
                                      right: BorderSide(
                                        color: const Color(0xFF1E88E5).withOpacity(0.15),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // 2. Animated Mascot / Panda Videos
                      if (_step == 0)
                        Center(
                          child: SizedBox(
                            height: 250,
                            width: 250,
                            child: _isSleepingInitialized && _sleepingController != null
                                ? ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: _sleepingController!.value.size.width,
                                        height: _sleepingController!.value.size.height,
                                        child: VideoPlayer(_sleepingController!),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1E88E5),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                          ),
                        )
                      else if (_step == 1)
                        Center(
                          child: SizedBox(
                            height: 260,
                            width: 260,
                            child: _isHappyInitialized && _happyController != null
                                ? ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: _happyController!.value.size.width,
                                        height: _happyController!.value.size.height,
                                        child: VideoPlayer(_happyController!),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1E88E5),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                          ),
                        )
                      else if (_step == 2)
                        Center(
                          child: SizedBox(
                            height: 250,
                            width: 250,
                            child: _isCelebratingInitialized && _celebratingController != null
                                ? ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: _celebratingController!.value.size.width,
                                        height: _celebratingController!.value.size.height,
                                        child: VideoPlayer(_celebratingController!),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1E88E5),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                          ),
                        )
                      else if (_step == 3)
                        Center(
                          child: SizedBox(
                            height: 250,
                            width: 250,
                            child: _isYawningInitialized && _yawningController != null
                                ? ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: _yawningController!.value.size.width,
                                        height: _yawningController!.value.size.height,
                                        child: VideoPlayer(_yawningController!),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1E88E5),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                          ),
                        )
                      else if (_step == 4)
                        Center(
                          child: SizedBox(
                            height: 250,
                            width: 250,
                            child: _isScaredInitialized && _scaredController != null
                                ? ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: _scaredController!.value.size.width,
                                        height: _scaredController!.value.size.height,
                                        child: VideoPlayer(_scaredController!),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1E88E5),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                          ),
                        )
                      else if (_step == 5)
                        Center(
                          child: SizedBox(
                            height: 250,
                            width: 250,
                            child: _isPartyInitialized && _partyController != null
                                ? ClipRect(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                      child: SizedBox(
                                        width: _partyController!.value.size.width,
                                        height: _partyController!.value.size.height,
                                        child: VideoPlayer(_partyController!),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFF1E88E5),
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                          ),
                        )
                      else
                        CheeroMascot(state: mascotState, isTalking: _isTalking),
                      const Spacer(flex: 1),
                      // 3. Dynamic options based on Step
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: _buildStepContent(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showInputBottomSheet({
    required String title,
    required String label,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                cursorColor: const Color(0xFF017A47),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(color: Colors.black54),
                  floatingLabelStyle: const TextStyle(color: Color(0xFF017A47), fontWeight: FontWeight.bold),
                  hintText: hint,
                  filled: true,
                  fillColor: const Color(0xFFECEFF1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => controller.clear(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    onSave();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF017A47),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'সংরক্ষণ করুন',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepContent() {
    if (_step == 0) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _nextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF017A47),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'চলো শুরু করি',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      );
    }

    if (_step == 1) {
      // Step 1: Personal Info (Name, Birthday, Gender, Address)
      return SingleChildScrollView(
        child: Column(
          children: [
            // Full Name selector
            InkWell(
              onTap: () {
                _showInputBottomSheet(
                  title: 'আপনার পূর্ণ নাম লিখুন',
                  label: 'পূর্ণ নাম',
                  hint: 'যেমন - তানভীর আহমেদ',
                  controller: _nameController,
                  onSave: () => setState(() {}),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF017A47).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF017A47), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'পূর্ণ নাম',
                            style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _nameController.text.isNotEmpty
                                ? _nameController.text
                                : 'যেমন - তানভীর আহমেদ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _nameController.text.isNotEmpty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _nameController.text.isNotEmpty
                                  ? Colors.black87
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_right, size: 20, color: Colors.black38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedBirthday ?? DateTime(2006, 1, 1),
                        firstDate: DateTime(1970),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF017A47),
                                onPrimary: Colors.white,
                                onSurface: Colors.black87,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF017A47),
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() => _selectedBirthday = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF017A47).withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cake, color: Color(0xFF017A47), size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'জন্মতারিখ',
                                  style: TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _selectedBirthday != null
                                      ? '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'
                                      : 'সিলেক্ট করো',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedBirthday != null
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _selectedBirthday != null
                                        ? Colors.black87
                                        : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Gender Selector
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: ['ছাত্র', 'ছাত্রী'].map((g) {
                        final isSelected = _selectedGender == g;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedGender = g),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF017A47) : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  g,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
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
            const SizedBox(height: 12),
            // Address selector
            InkWell(
              onTap: () {
                _showInputBottomSheet(
                  title: 'আপনার বর্তমান ঠিকানা লিখুন',
                  label: 'বর্তমান ঠিকানা',
                  hint: 'যেমন - ঢাকা, বাংলাদেশ',
                  controller: _addressController,
                  onSave: () => setState(() {}),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF017A47).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Color(0xFF017A47), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'বর্তমান ঠিকানা',
                            style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _addressController.text.isNotEmpty
                                ? _addressController.text
                                : 'যেমন - ঢাকা, বাংলাদেশ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: _addressController.text.isNotEmpty
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: _addressController.text.isNotEmpty
                                  ? Colors.black87
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_right, size: 20, color: Colors.black38),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _nameController.text.trim().isNotEmpty ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF017A47),
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  elevation: _nameController.text.trim().isNotEmpty ? 4 : 0,
                  shadowColor: const Color(0xFF017A47).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'পরবর্তী',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _nameController.text.trim().isNotEmpty ? Colors.white : Colors.black38,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_step == 2) {
      // Step 2: Class Selection (Fetched dynamically from API)
      final activeClassesAsync = ref.watch(activeClassesProvider);

      return activeClassesAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        ),
        error: (err, stack) => Column(
          children: [
            Text('ক্লাস সমূহের তালিকা লোড করতে সমস্যা হয়েছে: $err', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => ref.refresh(activeClassesProvider),
              child: const Text('পুনরায় চেষ্টা করো'),
            ),
          ],
        ),
        data: (classes) {
          if (classes.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black26),
              ),
              child: const Text(
                'বর্তমানে কোনো অ্যাক্টিভ ক্লাস নেই। এডমিন প্যানেল থেকে তৈরি করার পর এখানে দেখাবে।',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            );
          }

          return Column(
            children: classes.map((cls) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedClassModel = cls;
                      _selectedClass = cls.name;
                      _selectedGroupModel = null;
                      _selectedGroup = null;
                      _selectedBatchModel = null;
                      _selectedBatch = null;

                      if (cls.hasGroup && cls.groups.isNotEmpty) {
                        _step = 3; // Jump to group selection
                      } else if (cls.hasBatch && cls.batches.isNotEmpty) {
                        _step = 4; // Jump to batch selection
                      } else {
                        _step = 5; // Jump straight to summary
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF017A47).withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        cls.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF263238),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      );
    }

    if (_step == 3) {
      // Step 3: Group Selection (Dynamic from selected Class)
      final groups = _selectedClassModel?.groups ?? [];

      if (groups.isEmpty) {
        return Column(
          children: [
            const Text('এই ক্লাসের জন্য কোনো সাবজেক্ট গ্রুপ পাওয়া যায়নি।'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() => _step = 2),
              child: const Text('পেছনে যাও'),
            ),
          ],
        );
      }

      return Column(
        children: groups.map((grp) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedGroupModel = grp;
                  _selectedGroup = grp.name;
                  _selectedBatchModel = null;
                  _selectedBatch = null;

                  if (_selectedClassModel?.hasBatch == true && (grp.batches.isNotEmpty || _selectedClassModel!.batches.isNotEmpty)) {
                    _step = 4; // Jump to batch selection
                  } else {
                    _step = 5; // Jump to summary
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF017A47).withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    grp.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (_step == 4) {
      // Step 4: Batch Selection (Dynamic from selected Group or Class)
      List<AcademicBatchModel> availableBatches = [];
      if (_selectedGroupModel != null && _selectedGroupModel!.batches.isNotEmpty) {
        availableBatches = _selectedGroupModel!.batches;
      } else if (_selectedClassModel != null && _selectedClassModel!.batches.isNotEmpty) {
        availableBatches = _selectedClassModel!.batches;
      }

      if (availableBatches.isEmpty) {
        return Column(
          children: [
            const Text('বর্তমানে কোনো অ্যাক্টিভ ব্যাচ পাওয়া যায়নি।'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => setState(() => _step = 5),
              child: const Text('ব্যাচ ছাড়াই এগিয়ে যাও'),
            ),
          ],
        );
      }

      return Column(
        children: availableBatches.map((batch) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedBatchModel = batch;
                    _selectedBatch = batch.name;
                    _step = 5; // Jump to summary
                  });
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFCFD8DC), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  batch.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    // Step 5: Summary and Final Welcome Screen
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('নাম:', _nameController.text.trim()),
              Container(height: 1, color: const Color(0xFFEEEEEE), margin: const EdgeInsets.symmetric(horizontal: 20)),
              _buildSummaryRow('লিঙ্গ:', _selectedGender),
              if (_selectedBirthday != null) Container(height: 1, color: const Color(0xFFEEEEEE), margin: const EdgeInsets.symmetric(horizontal: 20)),
              if (_selectedBirthday != null)
                _buildSummaryRow('জন্মতারিখ:', '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'),
              if (_addressController.text.trim().isNotEmpty) Container(height: 1, color: const Color(0xFFEEEEEE), margin: const EdgeInsets.symmetric(horizontal: 20)),
              if (_addressController.text.trim().isNotEmpty)
                _buildSummaryRow('ঠিকানা:', _addressController.text.trim()),
              Container(height: 1, color: const Color(0xFFEEEEEE), margin: const EdgeInsets.symmetric(horizontal: 20)),
              _buildSummaryRow('শ্রেণী:', _selectedClass ?? 'নির্বাচন করা হয়নি'),
              if (_selectedGroup != null) Container(height: 1, color: const Color(0xFFEEEEEE), margin: const EdgeInsets.symmetric(horizontal: 20)),
              if (_selectedGroup != null) _buildSummaryRow('বিভাগ:', _selectedGroup!),
              if (_selectedBatch != null) Container(height: 1, color: const Color(0xFFEEEEEE), margin: const EdgeInsets.symmetric(horizontal: 20)),
              if (_selectedBatch != null) _buildSummaryRow('ব্যাচ:', _selectedBatch!),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: !_isSubmitting ? _submitOnboarding : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF017A47),
              elevation: 4,
              shadowColor: const Color(0xFF017A47).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'শুরু করি!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF017A47)),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
          ),
        ],
      ),
    );
  }
}

// Custom paint vector widget drawing Cheero Mascot
class CheeroMascot extends StatelessWidget {
  final String state;
  final bool isTalking;

  const CheeroMascot({Key? key, required this.state, this.isTalking = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBobbingBody(
      child: SizedBox(
        height: 180,
        width: 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ears
            Positioned(
              top: 22,
              left: 32,
              child: Transform.rotate(
                angle: -0.25,
                child: Container(
                  width: 32,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 22,
              right: 32,
              child: Transform.rotate(
                angle: 0.25,
                child: Container(
                  width: 32,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            // Main Body
            Container(
              width: 135,
              height: 135,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            // Belly
            Positioned(
              bottom: 12,
              child: Container(
                width: 95,
                height: 70,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF9C4),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(45),
                    topRight: Radius.circular(45),
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
              ),
            ),
            // Celebrating arms (dual raised waving arms)
            if (state == 'celebrate') ...[
              Positioned(
                top: 22,
                left: 4,
                child: AnimatedCelebratingArm(
                  isLeft: true,
                  child: Container(
                    width: 26,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 22,
                right: 4,
                child: AnimatedCelebratingArm(
                  isLeft: false,
                  child: Container(
                    width: 26,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            // Waving hand (Animated)
            if (state == 'wave' || state == 'welcome')
              Positioned(
                top: 22,
                left: 2,
                child: AnimatedWavingHand(
                  child: Container(
                    width: 28,
                    height: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            // Golden Trophy in right hand if state == 'welcome'
            if (state == 'welcome')
              Positioned(
                bottom: 16,
                right: 4,
                child: AnimatedTrophy(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 8, color: Colors.amber[400]),
                          Icon(Icons.star, size: 12, color: Colors.amber[400]),
                          Icon(Icons.star, size: 8, color: Colors.amber[400]),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 32,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.amber[600],
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          border: Border.all(color: Colors.black87, width: 1.5),
                        ),
                        child: Center(
                          child: Icon(Icons.emoji_events, size: 16, color: Colors.amber[200]),
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          border: const Border(
                            left: BorderSide(color: Colors.black87, width: 1.5),
                            right: BorderSide(color: Colors.black87, width: 1.5),
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: Colors.black87, width: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Thinking arm (Animated)
            if (state == 'think')
              Positioned(
                bottom: 40,
                right: 20,
                child: AnimatedThinkingArm(
                  child: Container(
                    width: 24,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            // Face details - Glasses
            Positioned(
              top: 52,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87, width: 3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 3,
                    color: Colors.black87,
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black87, width: 3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Nose
            Positioned(
              top: 88,
              child: Container(
                width: 16,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // Mouth (Animated Talking Mouth if isTalking is true)
            Positioned(
              top: 100,
              child: AnimatedTalkingMouth(
                isTalking: isTalking,
                child: Container(
                  width: 26,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFF880E4F),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 12,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF8A80),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(5),
                          bottomRight: Radius.circular(5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Book if state == 'read' (Animated spring open)
            if (state == 'read')
              Positioned(
                bottom: 12,
                child: AnimatedBook(
                  child: Transform.rotate(
                    angle: -0.05,
                    child: Container(
                      width: 72,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B0FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.black87, width: 2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              color: Colors.white,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(3, (index) => Container(height: 2, color: Colors.grey[300])),
                              ),
                            ),
                          ),
                          Container(width: 2, color: Colors.black87),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              color: Colors.white,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(3, (index) => Container(height: 2, color: Colors.grey[300])),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Clipboard/Note if state == 'write' (Animated pencil scribble)
            if (state == 'write') ...[
              Positioned(
                bottom: 12,
                child: Container(
                  width: 65,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black87, width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 45, height: 2, color: Colors.grey[400]),
                      Container(width: 35, height: 2, color: Colors.grey[400]),
                      Container(width: 40, height: 2, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                right: 48,
                child: AnimatedWritingPencil(
                  child: Transform.rotate(
                    angle: -0.5,
                    child: Container(
                      width: 6,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.amber[800],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 6,
                          height: 4,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// Mascot Micro-Animation Loop Helper Widgets (Stable Ticker Controllers)
// ----------------------------------------------------

class AnimatedBobbingBody extends StatefulWidget {
  final Widget child;
  const AnimatedBobbingBody({Key? key, required this.child}) : super(key: key);

  @override
  State<AnimatedBobbingBody> createState() => _AnimatedBobbingBodyState();
}

class _AnimatedBobbingBodyState extends State<AnimatedBobbingBody> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedWavingHand extends StatefulWidget {
  final Widget child;
  const AnimatedWavingHand({Key? key, required this.child}) : super(key: key);

  @override
  State<AnimatedWavingHand> createState() => _AnimatedWavingHandState();
}

class _AnimatedWavingHandState extends State<AnimatedWavingHand> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -0.3, end: -0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          alignment: Alignment.bottomRight,
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedTalkingMouth extends StatefulWidget {
  final Widget child;
  final bool isTalking;
  const AnimatedTalkingMouth({Key? key, required this.child, required this.isTalking}) : super(key: key);

  @override
  State<AnimatedTalkingMouth> createState() => _AnimatedTalkingMouthState();
}

class _AnimatedTalkingMouthState extends State<AnimatedTalkingMouth> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(begin: 1.0, end: 0.35).animate(_controller);
    if (widget.isTalking) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedTalkingMouth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTalking != oldWidget.isTalking) {
      if (widget.isTalking) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 0.0; // Reset scale to 1.0
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scaleY: _animation.value,
          alignment: Alignment.topCenter,
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedBook extends StatefulWidget {
  final Widget child;
  const AnimatedBook({Key? key, required this.child}) : super(key: key);

  @override
  State<AnimatedBook> createState() => _AnimatedBookState();
}

class _AnimatedBookState extends State<AnimatedBook> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: Alignment.bottomCenter,
      child: widget.child,
    );
  }
}

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  const TypewriterText({Key? key, required this.text, required this.style}) : super(key: key);

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text) {
      _startTypewriter();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTypewriter() {
    _timer?.cancel();
    _displayedText = '';
    int index = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (index < widget.text.length) {
        setState(() {
          _displayedText += widget.text[index];
        });
        index++;
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      textAlign: TextAlign.center,
      style: widget.style,
    );
  }
}

class AnimatedCelebratingArm extends StatefulWidget {
  final Widget child;
  final bool isLeft;
  const AnimatedCelebratingArm({Key? key, required this.child, required this.isLeft}) : super(key: key);

  @override
  State<AnimatedCelebratingArm> createState() => _AnimatedCelebratingArmState();
}

class _AnimatedCelebratingArmState extends State<AnimatedCelebratingArm> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: widget.isLeft ? -0.8 : 0.8,
      end: widget.isLeft ? -1.3 : 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          alignment: widget.isLeft ? Alignment.bottomRight : Alignment.bottomLeft,
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedWritingPencil extends StatefulWidget {
  final Widget child;
  const AnimatedWritingPencil({Key? key, required this.child}) : super(key: key);

  @override
  State<AnimatedWritingPencil> createState() => _AnimatedWritingPencilState();
}

class _AnimatedWritingPencilState extends State<AnimatedWritingPencil> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(4, -4),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: _animation.value,
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedThinkingArm extends StatefulWidget {
  final Widget child;
  const AnimatedThinkingArm({Key? key, required this.child}) : super(key: key);

  @override
  State<AnimatedThinkingArm> createState() => _AnimatedThinkingArmState();
}

class _AnimatedThinkingArmState extends State<AnimatedThinkingArm> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _animation.value,
          alignment: Alignment.bottomCenter,
          child: widget.child,
        );
      },
    );
  }
}

class AnimatedTrophy extends StatefulWidget {
  final Widget child;
  const AnimatedTrophy({Key? key, required this.child}) : super(key: key);

  @override
  State<AnimatedTrophy> createState() => _AnimatedTrophyState();
}

class _AnimatedTrophyState extends State<AnimatedTrophy> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
}
