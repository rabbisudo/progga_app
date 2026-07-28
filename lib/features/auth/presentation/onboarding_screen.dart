import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/profile_notifier.dart';
import 'auth_notifier.dart';

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
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;
  bool _isTalking = true;
  Timer? _talkingTimer;

  @override
  void initState() {
    super.initState();
    _startTalkingTimer();
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
      if (_step == 0 || _step == 5) {
        _startTalkingTimer();
      }
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
        'className': _selectedClass,
        'targetExam': _selectedGroup ?? '',
        'batch': _selectedBatch ?? '',
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
    String speechText = '';
    String mascotState = 'wave';

    switch (_step) {
      case 0:
        speechText = 'HI, I am Cheero';
        mascotState = 'wave';
        break;
      case 1:
        speechText = 'তুমি কোন শ্রেণীতে পড়ো?';
        mascotState = 'read';
        break;
      case 2:
        speechText = 'তোমার বিভাগ কোনটি?';
        mascotState = 'write';
        break;
      case 3:
        speechText = 'তোমার পরীক্ষার ব্যাচ কোনটি?';
        mascotState = 'think';
        break;
      case 4:
        speechText = 'তোমার নাম কি বন্ধু?';
        mascotState = 'think';
        break;
      case 5:
        speechText = 'স্বাগতম ${_nameController.text.trim()}!\nPidot-এর সাথে তোমার চর্চা শুরু হোক!';
        mascotState = 'welcome';
        break;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
        child: Column(
          children: [
            const Spacer(flex: 1),
            // 1. Speech Bubble
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black45, width: 1.2),
                    ),
                    child: TypewriterText(
                      text: speechText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
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
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.black45, width: 1.2),
                            right: BorderSide(color: Colors.black45, width: 1.2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 2. Animated Cheero Mascot
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
      final options = [
        {'title': 'ক্লাস ৬-৮', 'icon': Icons.menu_book, 'color': const Color(0xFFFFF9C4)},
        {'title': 'এসএসসি / দাখিল', 'icon': Icons.backpack, 'color': const Color(0xFFE3F2FD)},
        {'title': 'এইচএসসি / আলিম / অ্যাডমিশন', 'icon': Icons.school, 'color': const Color(0xFFECEFF1)},
        {'title': 'বিসিএস / জবস', 'icon': Icons.work, 'color': const Color(0xFFFFE0B2)},
      ];

      return Column(
        children: options.map((opt) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedClass = opt['title'] as String;
                  // If Class 6-8 or BCS/Jobs is selected, skip group selection step
                  if (_selectedClass == 'ক্লাস ৬-৮' || _selectedClass == 'বিসিএস / জবস') {
                    _selectedGroup = null;
                    _step = 3; // Jump directly to batch
                  } else {
                    _step = 2; // Jump to group selection
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCFD8DC), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: opt['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(opt['icon'] as IconData, color: const Color(0xFF017A47), size: 24),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        opt['title'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (_step == 2) {
      final groups = [
        {'title': 'বিজ্ঞান', 'icon': Icons.biotech, 'color': const Color(0xFFE8F5E9)},
        {'title': 'মানবিক', 'icon': Icons.public, 'color': const Color(0xFFFFF3E0)},
        {'title': 'বাণিজ্য', 'icon': Icons.calculate, 'color': const Color(0xFFF3E5F5)},
      ];

      return Column(
        children: groups.map((grp) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedGroup = grp['title'] as String;
                  _step = 3;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFCFD8DC), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: grp['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(grp['icon'] as IconData, color: const Color(0xFF017A47), size: 24),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        grp['title'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (_step == 3) {
      List<String> batches = [];
      if (_selectedClass == 'এসএসসি / দাখিল') {
        batches = ['কলেজ অ্যাডমিশন', 'এসএসসি ২০২৭', 'এসএসসি ২০২৮'];
      } else if (_selectedClass == 'এইচএসসি / আলিম / অ্যাডমিশন') {
        batches = ['ভার্সিটি অ্যাডমিশন', 'এইচএসসি ২০২৬', 'এইচএসসি ২০২৭'];
      } else {
        batches = ['জব প্রিপারেশন', 'চলতি সেশন'];
      }

      return Column(
        children: batches.map((batch) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedBatch = batch;
                    _step = 4;
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
                  batch,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    if (_step == 4) {
      return Column(
        children: [
          TextField(
            controller: _nameController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'উদা - জেমস বন্ড',
              filled: true,
              fillColor: const Color(0xFFECEFF1),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF017A47), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF017A47), width: 2.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFCFD8DC), width: 1.2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_nameController.text.trim().isNotEmpty)
                  ? _nextStep
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF017A47),
                disabledBackgroundColor: Colors.grey[500],
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'পরবর্তী',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      );
    }

    // Step 5: Summary and Final Welcome Screen
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECEFF1), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('শ্রেণী:', _selectedClass ?? 'নির্বাচন করা হয়নি'),
              if (_selectedGroup != null) const Divider(),
              if (_selectedGroup != null) _buildSummaryRow('বিভাগ:', _selectedGroup!),
              const Divider(),
              _buildSummaryRow('ব্যাচ:', _selectedBatch ?? 'নির্বাচন করা হয়নি'),
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
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'চর্চা শুরু করি!',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
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
