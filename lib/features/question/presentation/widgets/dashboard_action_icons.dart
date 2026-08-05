import 'package:flutter/material.dart';
import 'micro_animations.dart';

class QuestionBankIcon extends StatelessWidget {
  final Color color;
  const QuestionBankIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 5,
            child: Container(
              width: 14,
              height: 18,
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            top: 5,
            left: 2,
            child: FloatingWidget(
              child: Container(
                width: 14,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 8, height: 1.5, color: Colors.white),
                    Container(width: 6, height: 1.5, color: Colors.white),
                    Container(width: 4, height: 1.5, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuickPracticeIcon extends StatelessWidget {
  final Color color;
  const QuickPracticeIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 0,
            child: PulseWidget(
              child: Icon(Icons.flash_on, size: 24, color: color),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 2,
            child: Container(width: 3, height: 3, decoration: BoxDecoration(color: color.withOpacity(0.5), shape: BoxShape.circle)),
          ),
          Positioned(
            top: 4,
            right: 2,
            child: Container(width: 2.5, height: 2.5, decoration: BoxDecoration(color: color.withOpacity(0.5), shape: BoxShape.circle)),
          ),
        ],
      ),
    );
  }
}

class MockExamIcon extends StatelessWidget {
  final Color color;
  const MockExamIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 4,
            child: Container(
              width: 15,
              height: 19,
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Positioned(
            top: 1,
            left: 8,
            child: Container(
              width: 7,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
          Positioned(
            top: 7,
            left: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 7, height: 1.5, color: color),
                const SizedBox(height: 2),
                Container(width: 5, height: 1.5, color: color),
                const SizedBox(height: 2),
                Container(width: 7, height: 1.5, color: color),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.5),
              ),
              child: Center(
                child: RotateWidget(
                  duration: const Duration(seconds: 4),
                  child: Transform.translate(
                    offset: const Offset(0, -1.5),
                    child: Container(
                      width: 1.2,
                      height: 3.5,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AIGuideIcon extends StatelessWidget {
  final Color color;
  const AIGuideIcon({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: [
          RotateWidget(
            duration: const Duration(seconds: 8),
            child: Stack(
              children: [
                Positioned(
                  top: 1,
                  left: 5,
                  child: Container(width: 3.5, height: 3.5, decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle)),
                ),
                Positioned(
                  bottom: 2,
                  right: 5,
                  child: Container(width: 3.5, height: 3.5, decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle)),
                ),
                Positioned(
                  top: 8,
                  right: 1,
                  child: Container(width: 2.5, height: 2.5, decoration: BoxDecoration(color: color.withOpacity(0.4), shape: BoxShape.circle)),
                ),
              ],
            ),
          ),
          PulseWidget(
            child: Icon(Icons.auto_awesome, size: 18, color: color),
          ),
        ],
      ),
    );
  }
}
