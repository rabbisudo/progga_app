import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fl_chart/fl_chart.dart';
import 'practice_notifier.dart';
import '../domain/question_model.dart';
import '../data/question_repository.dart';
import 'package:go_router/go_router.dart';
import '../../profile/presentation/profile_notifier.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../profile/domain/profile_model.dart';
import '../../leaderboard/presentation/leaderboard_notifier.dart';
import '../../leaderboard/domain/leaderboard_model.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../academics/data/academics_repository.dart';
import '../../ai/presentation/progga_ai_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../exam/data/exam_repository.dart';
import '../../exam/domain/exam_model.dart';
import '../../result/presentation/result_screen.dart';

// SVGs for Premium Bottom Bar Navigation
const String _homeIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-width="1.5">
		<path d="M9 16c.85.63 1.885 1 3 1s2.15-.37 3-1" />
		<path d="M22 12.204v1.521c0 3.9 0 5.851-1.172 7.063S17.771 22 14 22h-4c-3.771 0-5.657 0-6.828-1.212S2 17.626 2 13.725v-1.521c0-2.289 0-3.433.52-4.381c.518-.949 1.467-1.537 3.364-2.715l2-1.241C9.889 2.622 10.892 2 12 2s2.11.622 4.116 1.867l2 1.241c1.897 1.178 2.846 1.766 3.365 2.715" />
	</g>
</svg>''';

const String _homeSelectedIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" fill-rule="evenodd" d="M2.52 7.823C2 8.77 2 9.915 2 12.203v1.522c0 3.9 0 5.851 1.172 7.063S6.229 22 10 22h4c3.771 0 5.657 0 6.828-1.212S22 17.626 22 13.725v-1.521c0-2.289 0-3.433-.52-4.381c-.518-.949-1.467-1.537-3.364-2.715l-2-1.241C14.111 2.622 13.108 2 12 2s-2.11.622-4.116 1.867l-2 1.241C3.987 6.286 3.038 6.874 2.519 7.823m6.927 7.575a.75.75 0 1 0-.894 1.204A5.77 5.77 0 0 0 12 17.75a5.77 5.77 0 0 0 3.447-1.148a.75.75 0 1 0-.894-1.204A4.27 4.27 0 0 1 12 16.25a4.27 4.27 0 0 1-2.553-.852" clip-rule="evenodd" />
</svg>''';

const String _qbIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-width="1.5">
		<path d="M9 12c0-.466 0-.699.076-.883a1 1 0 0 1 .541-.54c.184-.077.417-.077.883-.077h3c.466 0 .699 0 .883.076a1 1 0 0 1 .54.541c.077.184.077.417.077.883s0 .699-.076.883a1 1 0 0 1-.541.54c-.184.077-.417.077-.883.077h-3c-.466 0-.699 0-.883-.076a1 1 0 0 1-.54-.541C9 12.699 9 12.466 9 12Z" />
		<path stroke-linecap="round" d="M20.5 7v6c0 3.771 0 5.657-1.172 6.828S16.271 21 12.5 21h-1m-8-14v6c0 3.771 0 5.657 1.172 6.828c.704.705 1.668.986 3.144 1.098M12 3H4c-.943 0-1.414 0-1.707.293S2 4.057 2 5s0 1.414.293 1.707S3.057 7 4 7h16c.943 0 1.414 0 1.707-.293S22 5.943 22 5s0-1.414-.293-1.707S20.943 3 20 3h-4" />
	</g>
</svg>''';


const String _qbSelectedIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M2 5c0-.943 0-1.414.293-1.707S3.057 3 4 3h16c.943 0 1.414 0 1.707.293S22 4.057 22 5s0 1.414-.293 1.707S20.943 7 20 7H4c-.943 0-1.414 0-1.707-.293S2 5.943 2 5" />
	<path fill="currentColor" fill-rule="evenodd" d="m20.069 8.5l.431-.002V13c0 3.771 0 5.657-1.172 6.828S16.271 21 12.5 21h-1c-3.771 0-5.657 0-6.828-1.172S3.5 16.771 3.5 13V8.498l.431.002zM9 12c0-.466 0-.699.076-.883a1 1 0 0 1 .541-.541c.184-.076.417-.076.883-.076h3c.466 0 .699 0 .883.076a1 1 0 0 1 .54.541c.077.184.077.417.077.883s0 .699-.076.883a1 1 0 0 1-.541.54c-.184.077-.417.077-.883.077h-3c-.466 0-.699 0-.883-.076a1 1 0 0 1-.54-.541C9 12.699 9 12.466 9 12" clip-rule="evenodd" />
</svg>''';

const String _examIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-linecap="round" stroke-width="1.5">
		<path d="M2 12c0 4.714 0 7.071 1.464 8.535C4.93 22 7.286 22 12 22s7.071 0 8.535-1.465C22 19.072 22 16.714 22 12v-1.5M13.5 2H12C7.286 2 4.929 2 3.464 3.464c-.973.974-1.3 2.343-1.409 4.536" />
		<path d="m16.652 3.455l.649-.649A2.753 2.753 0 0 1 21.194 6.7l-.65.649m-3.892-3.893s.081 1.379 1.298 2.595c1.216 1.217 2.595 1.298 2.595 1.298m-3.893-3.893L10.687 9.42c-.404.404-.606.606-.78.829q-.308.395-.524.848c-.121.255-.211.526-.392 1.068L8.412 13.9m12.133-6.552l-2.983 2.982m-2.982 2.983c-.404.404-.606.606-.829.78a4.6 4.6 0 0 1-.848.524c-.255.121-.526.211-1.068.392l-1.735.579m0 0l-1.123.374a.742.742 0 0 1-.939-.94l.374-1.122m1.688 1.688L8.412 13.9" />
	</g>
</svg>''';

const String _examSelectedIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M21.194 2.806a2.753 2.753 0 0 1 0 3.893l-.496.496a5 5 0 0 1-.533-.151a5.2 5.2 0 0 1-1.968-1.241a5.2 5.2 0 0 1-1.241-1.968a5 5 0 0 1-.15-.533l.495-.496a2.753 2.753 0 0 1 3.893 0M14.58 13.313c-.404.404-.606.606-.829.78a4.6 4.6 0 0 1-.848.524c-.255.121-.526.211-1.068.392l-2.858.953a.742.742 0 0 1-.939-.94l.953-2.857c.18-.542.27-.813.392-1.068q.217-.453.524-.848c.174-.223.376-.425.78-.83l4.916-4.915a6.7 6.7 0 0 0 1.533 2.36a6.7 6.7 0 0 0 2.36 1.533z" />
	<path fill="currentColor" d="M20.536 20.536C22 19.07 22 16.714 22 12c0-1.548 0-2.842-.052-3.934l-6.362 6.362c-.351.352-.615.616-.912.847a6 6 0 0 1-1.125.696c-.34.162-.694.28-1.166.437l-2.932.977a2.242 2.242 0 0 1-2.836-2.836l.977-2.932c.157-.472.275-.826.437-1.166q.287-.6.696-1.125c.231-.297.495-.56.847-.912l6.362-6.362C14.842 2 13.548 2 12 2C7.286 2 4.929 2 3.464 3.464C2 4.93 2 7.286 2 12s0 7.071 1.464 8.535C4.93 22 7.286 22 12 22s7.071 0 8.535-1.465" />
</svg>''';

const String _aiIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 11h6m-6 4h3m1-12h-1a9 9 0 0 0-9 9v8a1 1 0 0 0 1 1h8a9 9 0 0 0 9-9v-1m-2-9l.13.378a4 4 0 0 0 2.492 2.493L22 5l-.378.13a4 4 0 0 0-2.493 2.492L19 8l-.13-.378a4 4 0 0 0-2.492-2.493L16 5l.378-.13a4 4 0 0 0 2.493-2.492z" />
</svg>''';

const String _aiSelectedIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M12 2c.901 0 1.774.12 2.605.344a3 3 0 0 0 .425 5.495l.378.129a1 1 0 0 1 .624.624l.13.378a3 3 0 0 0 5.493.425A10 10 0 0 1 22 12c0 5.523-4.477 10-10 10H4a2 2 0 0 1-2-2v-8C2 6.477 6.477 2 12 2M9 14a1 1 0 1 0 0 2h3a1 1 0 1 0 0-2zm0-4a1 1 0 1 0 0 2h6a1 1 0 1 0 0-2zm10-9a1 1 0 0 1 .946.677l.13.378c.3.879.99 1.57 1.87 1.87l.377.129a1 1 0 0 1 0 1.892l-.378.13c-.879.3-1.57.99-1.87 1.87l-.129.377a1 1 0 0 1-1.892 0l-.13-.378a3 3 0 0 0-1.87-1.87l-.377-.129a1 1 0 0 1 0-1.892l.378-.13c.879-.3 1.57-.99 1.87-1.87l.129-.377A1 1 0 0 1 19 1" />
</svg>''';

const String _profileIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none" stroke="currentColor" stroke-width="1.5">
		<circle cx="12" cy="6" r="4" />
		<path stroke-linecap="round" d="M19.998 18q.002-.246.002-.5c0-2.485-3.582-4.5-8-4.5s-8 2.015-8 4.5S4 22 12 22c2.231 0 3.84-.157 5-.437" />
	</g>
</svg>''';

const String _profileSelectedIcon = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<circle cx="12" cy="6" r="4" fill="currentColor" />
	<path fill="currentColor" d="M20 17.5c0 2.485 0 4.5-8 4.5s-8-2.015-8-4.5S7.582 13 12 13s8 2.015 8 4.5" />
</svg>''';

const String _streakFireSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<path fill="currentColor" d="M12.832 21.801c3.126-.626 7.168-2.875 7.168-8.69c0-5.291-3.873-8.815-6.658-10.434c-.619-.36-1.342.113-1.342.828v1.828c0 1.442-.606 4.074-2.29 5.169c-.86.559-1.79-.278-1.894-1.298l-.086-.838c-.1-.974-1.092-1.565-1.87-.971C4.461 8.46 3 10.33 3 13.11C3 20.221 8.289 22 10.933 22q.232 0 .484-.015C10.111 21.874 8 21.064 8 18.444c0-2.05 1.495-3.435 2.631-4.11c.306-.18.663.055.663.41v.59c0 .45.175 1.155.59 1.637c.47.546 1.159-.026 1.214-.744c.018-.226.246-.37.442-.256c.641.375 1.46 1.175 1.46 2.473c0 2.048-1.129 2.99-2.168 3.357" />
</svg>''';

String _getTimeOfDayGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'শুভ সকাল';
  } else if (hour >= 12 && hour < 15) {
    return 'শুভ দুপুর';
  } else if (hour >= 15 && hour < 18) {
    return 'শুভ বিকেল';
  } else {
    return 'শুভ সন্ধ্যা';
  }
}

// ----------------------------------------------------
// Riverpod Providers (Unaltered API calls/Business Logic)
// ----------------------------------------------------
final activeBannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.dio.get('/banners');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
  } catch (_) {}
  return [];
});

final activeBoardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.dio.get('/academics/boards');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
  } catch (_) {}
  return [];
});

final activeCollegesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.dio.get('/academics/colleges');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
  } catch (_) {}
  return [];
});

final activeVarsitiesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.dio.get('/academics/varsities');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
  } catch (_) {}
  return [];
});

final allSubjectsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.dio.get('/academics/subjects');
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> list = response.data;
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
  } catch (_) {}
  return [];
});

// ----------------------------------------------------
// UI Helper Widgets: Skeleton and Scale Interactions
// ----------------------------------------------------
class ShimmerSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
  });

  @override
  State<ShimmerSkeleton> createState() => _ShimmerSkeletonState();
}

class _ShimmerSkeletonState extends State<ShimmerSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: const [0.35, 0.5, 0.65],
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              transform: _SlidingGradientTransform(slidePercent: _animation.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}

class BouncingCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor;

  const BouncingCard({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.96,
  });

  @override
  State<BouncingCard> createState() => _BouncingCardState();
}

class _BouncingCardState extends State<BouncingCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0 - widget.scaleFactor,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - _controller.value;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// ----------------------------------------------------
// Premium Custom Navigation Dock
// ----------------------------------------------------
class PremiumBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const PremiumBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 72,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark 
                  ? const Color(0xFF1E1E1E).withOpacity(0.8) 
                  : Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.08) 
                    : const Color(0xFF017A47).withOpacity(0.12),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.4) 
                      : const Color(0xFF017A47).withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / 4;
                return Stack(
                  children: [
                    // Sliding active capsule background with a soft gradient
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutBack,
                      left: selectedIndex * tabWidth + 6,
                      top: 6,
                      width: tabWidth - 12,
                      height: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFFF18881).withOpacity(0.18),
                                    const Color(0xFFD9746E).withOpacity(0.08)
                                  ]
                                : [
                                    const Color(0xFFE0ECE6),
                                    const Color(0xFFB9D8C9).withOpacity(0.4)
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark 
                                ? const Color(0xFFF18881).withOpacity(0.15) 
                                : const Color(0xFF017A47).withOpacity(0.06),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                    // Tab Items
                    Row(
                      children: [
                        _buildTab(context, 0, 'হোম', 
                          iconStr: _homeIcon, 
                          selectedIconStr: _homeSelectedIcon,
                        ),
                        _buildTab(context, 1, 'প্রশ্নব্যাংক', 
                          iconStr: _qbIcon, 
                          selectedIconStr: _qbSelectedIcon,
                        ),
                        _buildTab(context, 2, 'পরীক্ষা', 
                          iconStr: _examIcon, 
                          selectedIconStr: _examSelectedIcon,
                        ),
                        _buildTab(context, 3, 'প্রোফাইল', 
                          iconStr: _profileIcon, 
                          selectedIconStr: _profileSelectedIcon,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, 
    int index, 
    String label, {
    required String iconStr, 
    required String selectedIconStr,
  }) {
    final isSelected = selectedIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final activeColor = isDark ? const Color(0xFFF18881) : const Color(0xFF017A47);
    final inactiveColor = isDark ? Colors.grey[400]! : const Color(0xFF495057);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onDestinationSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: SvgPicture.string(
                isSelected ? selectedIconStr : iconStr,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  isSelected ? activeColor : inactiveColor, 
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// Main Dashboard Screen State Lifecycle
// ----------------------------------------------------
class PracticeDashboardScreen extends ConsumerStatefulWidget {
  const PracticeDashboardScreen({super.key});

  @override
  ConsumerState<PracticeDashboardScreen> createState() => _PracticeDashboardScreenState();
}

class _PracticeDashboardScreenState extends ConsumerState<PracticeDashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  int _currentNavIndex = 0;

  // Question Bank States (Cascading flow)
  String? _selectedQbSubjectId;
  String? _selectedQbSubjectName;
  String? _selectedQbItemType; // 'Board', 'College', 'Varsity'
  String? _selectedQbItemId;
  String? _selectedQbItemName;
  int? _selectedQbYear;
  String _qbSearchText = '';
  List<QuestionModel> _qbQuestions = [];
  bool _qbLoading = false;
  String? _qbNextCursor;
  final ScrollController _qbScrollController = ScrollController();

  // Question Bank Series & Exams States
  final List<String> _selectedSeriesStack = [];
  String? _activeExamTab;
  String _examSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _qbScrollController.addListener(_onQbScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _qbScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(practiceProvider.notifier).fetchNextPage();
    }
  }

  void _onQbScroll() {
    if (_qbScrollController.position.pixels >= _qbScrollController.position.maxScrollExtent - 200) {
      _fetchQbQuestions(refresh: false);
    }
  }

  Future<void> _fetchQbQuestions({bool refresh = true}) async {
    if (_qbLoading) return;
    if (_selectedQbSubjectId == null || _selectedQbItemId == null) return;
    if (!refresh && _qbNextCursor == null) return;

    setState(() {
      _qbLoading = true;
      if (refresh) {
        _qbQuestions.clear();
        _qbNextCursor = null;
      }
    });

    try {
      final profile = ref.read(userProfileProvider).value?.profile;
      final repository = ref.read(questionRepositoryProvider);
      final result = await repository.fetchQuestions(
        subjectId: _selectedQbSubjectId,
        boardId: _selectedQbItemType == 'Board' ? _selectedQbItemId : null,
        collegeId: _selectedQbItemType == 'College' ? _selectedQbItemId : null,
        varsityId: _selectedQbItemType == 'Varsity' ? _selectedQbItemId : null,
        year: _selectedQbYear?.toString(),
        classId: profile?.classId,
        groupId: profile?.groupId,
        cursor: _qbNextCursor,
        limit: 15,
      );

      List<QuestionModel> newQuestions = result.questions;
      if (_qbSearchText.isNotEmpty) {
        final query = _qbSearchText.toLowerCase();
        newQuestions = newQuestions.where((q) => q.questionText.toLowerCase().contains(query)).toList();
      }

      setState(() {
        _qbQuestions.addAll(newQuestions);
        _qbNextCursor = result.nextCursor;
        _qbLoading = false;
      });
    } catch (_) {
      setState(() {
        _qbLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(practiceProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final leaderboardAsync = ref.watch(myLeaderboardProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (profileAsync.isLoading && profileAsync.value == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF017A47)),
        ),
      );
    }

    if (profileAsync is AsyncError) {
      final error = profileAsync.error;
      if (error is NetworkException && error.statusCode == 401) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/login');
        });
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        );
      }
    }

    // Redirect to onboarding if not set up yet
    if (profileAsync.value != null) {
      final userData = profileAsync.value!;
      if (userData.profile?.className == null || userData.profile!.className!.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go('/onboarding');
        });
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF017A47)),
          ),
        );
      }
    }

    // List of page view bodies matching each bottom navigation index
    final List<Widget> views = [
      _buildHomeDashboardView(state, theme, profileAsync, leaderboardAsync),
      _buildQuestionBankView(theme),
      _buildExamListView(theme),
      const ProfileScreen(),
    ];

    // Greeting calculations for personalized header
    final profile = profileAsync.value?.profile;
    final displayName = profile?.fullName.split(' ').first ?? '';
    final String greetingText = _getTimeOfDayGreeting();

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _currentNavIndex == 0
          ? AppBar(
              backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
              elevation: 0,
              scrolledUnderElevation: 0,
              surfaceTintColor: Colors.transparent,
              leadingWidth: 100,
              // Redesigned premium streak fire widget
              leading: Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: InkWell(
                    onTap: () => context.push('/streak'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFFF18881).withOpacity(0.15) : const Color(0xFFE0ECE6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0xFFF18881).withOpacity(0.3) : const Color(0xFFB9D8C9),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PulseWidget(
                            child: SvgPicture.string(
                              _streakFireSvg,
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(Color(0xFF017A47), BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            profileAsync.maybeWhen(
                              data: (user) => _toBengaliDigits('${user.profile?.currentStreak ?? 1}'),
                              orElse: () => '১',
                            ),
                            style: TextStyle(
                              color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              title: displayName.isNotEmpty
                  ? Text(
                      '$greetingText, $displayName',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    )
                  : const SizedBox.shrink(),
              // Right: Profile Avatar with a glowing ring outline
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: GestureDetector(
                    onTap: () {
                      context.push('/profile');
                    },
                    child: Hero(
                      tag: 'user_avatar_hero',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                            width: 2,
                          ),
                        ),
                        child: CustomAvatar(
                          avatarUrl: profileAsync.value?.profile?.avatarKey,
                          radius: 17,
                          backgroundColor: const Color(0xFFF18881),
                          fallbackWidget: const Text(
                            '👨‍🎓',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : ((_currentNavIndex == 3 || (_currentNavIndex == 1 && _selectedSeriesStack.isNotEmpty))
              ? null
              : AppBar(
                  backgroundColor: theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  title: Text(
                    _currentNavIndex == 1 ? 'প্রশ্নব্যাংক' : 'মক পরীক্ষা',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  centerTitle: true,
                )),
      body: SafeArea(
        top: (_currentNavIndex == 1 && _selectedSeriesStack.isNotEmpty) ||
            _currentNavIndex == 3,
        bottom: (_currentNavIndex == 1 && _selectedSeriesStack.isNotEmpty),
        child: IndexedStack(
          index: _currentNavIndex,
          children: views,
        ),
      ),
      bottomNavigationBar: (_currentNavIndex == 1 && _selectedSeriesStack.isNotEmpty)
          ? null
          : PremiumBottomNavBar(
              selectedIndex: _currentNavIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentNavIndex = index;
                  if (index != 1) {
                    _selectedSeriesStack.clear();
                    _activeExamTab = null;
                  }
                });
              },
            ),
    );
  }

  // ----------------------------------------------------
  // View 0: Home Dashboard
  // ----------------------------------------------------
  Widget _buildHomeDashboardView(state, ThemeData theme, profileAsync, leaderboardAsync) {
    final profile = profileAsync.value?.profile;
    final myUserId = profileAsync.value?.id;
    final bannersAsync = ref.watch(activeBannersProvider);
    final isDark = theme.brightness == Brightness.dark;
    final curriculumAsync = ref.watch(studentCurriculumProvider);

    // Read league name dynamically
    String leagueName = 'আয়রন লীগ';
    int currentXp = profile?.xp ?? 0;
    if (leaderboardAsync.value != null && myUserId != null) {
      final myEntry = leaderboardAsync.value!.firstWhere(
        (e) => e.userId == myUserId,
        orElse: () => LeaderboardEntryModel(
          rank: 0,
          userId: '',
          username: '',
          fullName: '',
          xp: currentXp,
          level: profile?.level ?? 1,
          solvedQuestionsCount: 0,
          league: 'IRON',
          currentStreak: profile?.currentStreak ?? 0,
        ),
      );
      if (myEntry.xp > 0) currentXp = myEntry.xp;
    }

    if (currentXp >= 5000) {
      leagueName = 'ইনফিনিটি লীগ';
    } else if (currentXp >= 3000) {
      leagueName = 'ডায়মন্ড লীগ';
    } else if (currentXp >= 1500) {
      leagueName = 'গোল্ড লীগ';
    } else if (currentXp >= 800) {
      leagueName = 'সিলভার লীগ';
    } else if (currentXp >= 300) {
      leagueName = 'ব্রোঞ্জ লীগ';
    } else {
      leagueName = 'আয়রন লীগ';
    }

    final userName = profile?.fullName ?? 'Rabbi failure';
    final userScore = profile?.xp ?? 3981;
    final starPoints = profile != null ? (profile.xp % 100) : 0;
    final progressVal = profile != null ? (profile.xp % 100) / 100.0 : 0.0;

    return RefreshIndicator(
      color: const Color(0xFF017A47),
      onRefresh: () async {
        try {
          await Future.wait([
            ref.refresh(userProfileProvider.future),
            ref.refresh(myLeaderboardProvider.future),
            ref.refresh(activeBannersProvider.future),
          ]);
        } catch (_) {}
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // 1. Promo Banners Carousel Slider with Skeleton shimmer
            bannersAsync.when(
              data: (banners) => banners.isNotEmpty
                  ? BannerSliderWidget(banners: banners)
                  : const SizedBox.shrink(),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: ShimmerSkeleton(width: double.infinity, height: 160, borderRadius: 20),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // 2. Premium Grid Action Cards (Clean gradients + shadows + micro scales)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Row(
                children: [
                  _buildGridAction(
                    iconWidget: _buildImageIconAsset('assets/icons/qsbank.png', Icons.inventory_2_outlined),
                    label: 'প্রশ্নব্যাংক',
                    onTap: () => setState(() => _currentNavIndex = 1),
                    context: context,
                    gradientColors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFE0F2FE), const Color(0xFFBAE6FD)],
                  ),
                  _buildGridAction(
                    iconWidget: _buildImageIconAsset('assets/icons/exam.png', Icons.edit_note_outlined),
                    label: 'মক পরীক্ষা',
                    onTap: () => setState(() => _currentNavIndex = 2),
                    context: context,
                    gradientColors: isDark
                        ? [const Color(0xFF065F46), const Color(0xFF064E3B)]
                        : [const Color(0xFFDCFCE7), const Color(0xFFBBF7D0)],
                  ),
                  _buildGridAction(
                    iconWidget: _buildImageIconAsset('assets/icons/report.png', Icons.bar_chart_outlined),
                    label: 'পরীক্ষার হিস্ট্রি',
                    onTap: () => context.push('/exam-history'),
                    context: context,
                    gradientColors: isDark
                        ? [const Color(0xFF7F1D1D), const Color(0xFF991B1B)]
                        : [const Color(0xFFFEE2E2), const Color(0xFFFECACA)],
                  ),
                  _buildGridAction(
                    iconWidget: _buildImageIconAsset('assets/icons/ai.png', Icons.psychology_outlined),
                    label: 'প্রজ্ঞা এআই',
                    onTap: () => context.push('/progga-ai'),
                    context: context,
                    gradientColors: isDark
                        ? [const Color(0xFF581C87), const Color(0xFF4C1D95)]
                        : [const Color(0xFFF3E8FF), const Color(0xFFE9D5FF)],
                  ),
                ],
              ),
            ),

            // My Subjects (আমার বিষয়সমূহ) Header & Horizontal List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'আমার বিষয়সমূহ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _currentNavIndex = 2; // Swapping to Mock Exam tab
                      });
                    },
                    child: Row(
                      children: [
                        Text(
                          'সবগুলো',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 10,
                          color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 105,
              child: curriculumAsync.when(
                data: (subjects) {
                  if (subjects.isEmpty) {
                    return const Center(
                      child: Text(
                        'কোনো বিষয় পাওয়া যায়নি',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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

                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: BouncingCard(
                          onTap: () {
                            context.push(
                              '/topic-selection/${subject['id']}',
                              extra: subjectName,
                            );
                          },
                          child: Container(
                            width: 135,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFECEFF1),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.015),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? const Color(0xFFF18881).withOpacity(0.12) 
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
                                              style: const TextStyle(fontSize: 16),
                                            ),
                                          )
                                        : Text(
                                            emojiIcon,
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  subjectName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 4,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: ShimmerSkeleton(
                      width: 135,
                      height: 105,
                      borderRadius: 20,
                    ),
                  ),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'লোড ব্যর্থ হয়েছে',
                    style: TextStyle(fontSize: 11, color: Colors.red[300]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Premium Redesigned Leaderboard Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFECEFF1),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.02),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Leaderboard header
                    InkWell(
                      onTap: () => context.push('/leaderboard'),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'লিডারবোর্ড',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark 
                                        ? const Color(0xFFF18881).withOpacity(0.15) 
                                        : const Color(0xFF017A47).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    leagueName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  'সবগুলো দেখুন',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios, 
                                  size: 12, 
                                  color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Star progress track bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFECEFF1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'লেভেল ${profile?.level ?? 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                                Text(
                                  '${_toBengaliDigits((100 - starPoints).toString())} XP পরবর্তী লেভেলের জন্য',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${_toBengaliDigits(starPoints.toString())} XP', 
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold, 
                                    fontSize: 13, 
                                    color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progressVal == 0.0 ? 0.02 : progressVal,
                                      minHeight: 8,
                                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Onboarding suggestion box when star points is 0 (or XP is low)
                    if (userScore == 0) ...[
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFFFFB300).withOpacity(0.08) 
                              : const Color(0xFFFFB300).withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark 
                                ? const Color(0xFFFFB300).withOpacity(0.2) 
                                : const Color(0xFFFFB300).withOpacity(0.25),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🚀', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'কুইজ বা মক পরীক্ষায় অংশ নিয়ে XP অর্জন করুন এবং লিডারবোর্ডে এগিয়ে যান!',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.amber[200] : const Color(0xFFE65100),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    
                    // Shimmer loading inside leaderboard cards
                    if (leaderboardAsync is AsyncLoading && (leaderboardAsync.value == null || leaderboardAsync.value!.isEmpty)) ...[
                      ...List.generate(3, (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        child: Row(
                          children: const [
                            ShimmerSkeleton(width: 24, height: 24, borderRadius: 12),
                            SizedBox(width: 12),
                            ShimmerSkeleton(width: 32, height: 32, borderRadius: 16),
                            SizedBox(width: 12),
                            ShimmerSkeleton(width: 120, height: 16, borderRadius: 4),
                            Spacer(),
                            ShimmerSkeleton(width: 50, height: 14, borderRadius: 4),
                          ],
                        ),
                      )),
                    ] else if (leaderboardAsync is AsyncError || leaderboardAsync.value == null) ...[
                      _buildLeaderboardRow(
                        name: userName,
                        score: userScore,
                        avatarText: '😎',
                        avatarBg: const Color(0xFF81C784),
                        isCurrentUser: true,
                        rank: 1,
                        context: context,
                      ),
                    ] else ...[
                      Builder(
                        builder: (context) {
                          final entries = leaderboardAsync.value!;
                          final List<LeaderboardPlayer> allPlayers = entries.map<LeaderboardPlayer>((e) {
                            final isMe = e.userId == myUserId;
                            final avatarDisplay = e.avatarKey != null && e.avatarKey!.isNotEmpty
                                ? e.avatarKey!
                                : (e.fullName.isNotEmpty ? e.fullName[0].toUpperCase() : '?');
                            return LeaderboardPlayer(
                              name: e.fullName.isNotEmpty ? e.fullName : e.username,
                              score: e.xp,
                              avatarText: avatarDisplay,
                              avatarBg: isMe ? const Color(0xFF81C784) : const Color(0xFF26A69A),
                              isCurrentUser: isMe,
                            );
                          }).toList();

                          // Add current user fallback if missing
                          final hasMe = allPlayers.any((p) => p.isCurrentUser);
                          if (!hasMe && profile != null) {
                            allPlayers.add(
                              LeaderboardPlayer(
                                name: userName,
                                score: userScore,
                                avatarText: '😎',
                                avatarBg: const Color(0xFF81C784),
                                isCurrentUser: true,
                              ),
                            );
                          }

                          // Sort and assign rankings
                          allPlayers.sort((a, b) => b.score.compareTo(a.score));
                          
                          // Create key mapping for user ranking
                          final Map<String, int> ranksMap = {};
                          for (int i = 0; i < allPlayers.length; i++) {
                            ranksMap[allPlayers[i].name] = i + 1;
                          }

                          int myIndex = allPlayers.indexWhere((p) => p.isCurrentUser);

                          List<LeaderboardPlayer> displayPlayers = [];
                          if (allPlayers.length < 3) {
                            displayPlayers = allPlayers.where((p) => p.isCurrentUser).toList();
                          } else if (myIndex == 0) {
                            displayPlayers = [allPlayers[0], allPlayers[1], allPlayers[2]];
                          } else if (myIndex == allPlayers.length - 1) {
                            displayPlayers = [allPlayers[myIndex - 2], allPlayers[myIndex - 1], allPlayers[myIndex]];
                          } else if (myIndex != -1) {
                            displayPlayers = [allPlayers[myIndex - 1], allPlayers[myIndex], allPlayers[myIndex + 1]];
                          } else {
                            displayPlayers = allPlayers.take(3).toList();
                          }

                          return Column(
                            children: displayPlayers.map((player) {
                              final int rank = ranksMap[player.name] ?? 4;
                              return _buildLeaderboardRow(
                                name: player.name,
                                score: player.score,
                                avatarText: player.avatarText,
                                avatarBg: player.avatarBg,
                                isCurrentUser: player.isCurrentUser,
                                rank: rank,
                                context: context,
                              );
                            }).toList(),
                          );
                        }
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildImageIconAsset(String assetPath, IconData fallbackIcon) {
    return Image.asset(
      assetPath,
      width: 44,
      height: 44,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(fallbackIcon, size: 36, color: const Color(0xFF017A47));
      },
    );
  }

  Widget _buildGridAction({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
    required BuildContext context,
    required List<Color> gradientColors,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: BouncingCard(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradientColors.last.withOpacity(isDark ? 0.15 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: iconWidget,
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Row helper for building individual leaderboard entries with ranking medals
  Widget _buildLeaderboardRow({
    required String name,
    required int score,
    required String avatarText,
    required Color avatarBg,
    required bool isCurrentUser,
    required int rank,
    required BuildContext context,
  }) {
    final bool isUrl = avatarText.startsWith('http') || avatarText.startsWith('https');
    final bool isSingleChar = avatarText.length == 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget rankWidget;
    if (rank == 1) {
      rankWidget = const Text('🥇', style: TextStyle(fontSize: 18));
    } else if (rank == 2) {
      rankWidget = const Text('🥈', style: TextStyle(fontSize: 18));
    } else if (rank == 3) {
      rankWidget = const Text('🥉', style: TextStyle(fontSize: 18));
    } else {
      rankWidget = Container(
        width: 24,
        alignment: Alignment.center,
        child: Text(
          _toBengaliDigits(rank.toString()),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser
              ? (isDark ? const Color(0xFFF18881).withOpacity(0.12) : const Color(0xFF017A47).withOpacity(0.06))
              : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCurrentUser
                ? (isDark ? const Color(0xFFF18881).withOpacity(0.3) : const Color(0xFF017A47).withOpacity(0.2))
                : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFECEFF1)),
            width: 1.5,
          ),
          boxShadow: isCurrentUser
              ? [
                  BoxShadow(
                    color: isDark 
                        ? const Color(0xFFF18881).withOpacity(0.04) 
                        : const Color(0xFF017A47).withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: InkWell(
          onTap: () => context.push('/leaderboard'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                rankWidget,
                const SizedBox(width: 10),
                isUrl
                    ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isCurrentUser
                              ? Border.all(
                                  color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: CustomAvatar(
                          avatarUrl: avatarText,
                          radius: 18,
                          backgroundColor: avatarBg,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isCurrentUser
                              ? Border.all(
                                  color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                                  width: 2,
                                )
                              : null,
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: avatarBg,
                          child: Text(
                            isSingleChar ? avatarText : (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                      color: isCurrentUser 
                          ? (isDark ? const Color(0xFFF18881) : const Color(0xFF017A47)) 
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                Text(
                  '${_toBengaliDigits(score.toString())} XP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LinearGradient _getSubjectGradient(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('পদার্থ') || name.contains('physics')) {
      return const LinearGradient(
        colors: [Color(0xFF001F4D), Color(0xFF004080)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('উচ্চতর') || name.contains('higher')) {
      return const LinearGradient(
        colors: [Color(0xFF4D2600), Color(0xFF804000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('জীববিজ্ঞান') || name.contains('biology')) {
      return const LinearGradient(
        colors: [Color(0xFF330033), Color(0xFF660066)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('রসায়ন') || name.contains('chemistry')) {
      return const LinearGradient(
        colors: [Color(0xFF1F003D), Color(0xFF400080)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('গণিত') || name.contains('math')) {
      return const LinearGradient(
        colors: [Color(0xFF4D3D00), Color(0xFF806600)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (name.contains('ইংরেজী') || name.contains('english')) {
      return const LinearGradient(
        colors: [Color(0xFF4D0000), Color(0xFF800000)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [Color(0xFF003D24), Color(0xFF00804C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildSubjectTitle(String title) {
    List<String> parts = [];
    if (title.contains('ইংরেজী ১ম')) {
      parts = ['ইংরেজী', '১ম পত্র'];
    } else if (title.contains('ইংরেজী ২য়')) {
      parts = ['ইংরেজী', '২য় পত্র'];
    } else if (title.contains('English 1st')) {
      parts = ['English', '1st Paper'];
    } else if (title.contains('English 2nd')) {
      parts = ['English', '2nd Paper'];
    } else if (title.contains('বাংলা ১ম')) {
      parts = ['বাংলা', '১ম পত্র'];
    } else if (title.contains('বাংলা ২য়')) {
      parts = ['বাংলা', '২য় পত্র'];
    } else {
      parts = [title];
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parts.map((part) => Text(
        part,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          fontFamily: 'Noto Sans Bengali',
          height: 1.15,
        ),
      )).toList(),
    );
  }

  int _getCategoryCount(Map<String, dynamic> series) {
    final subSeriesList = (series['subSeries'] as List<dynamic>?) ?? [];
    if (subSeriesList.isNotEmpty) {
      return subSeriesList.length;
    }
    final labelNameMap = Map<String, dynamic>.from(series['labelName'] as Map? ?? {});
    if (labelNameMap.isNotEmpty) {
      int count = 0;
      for (final val in labelNameMap.values) {
        if (val is List) count += val.length;
      }
      if (count > 0) return count;
    }
    final examsStr = series['exams']?.toString() ?? '';
    if (examsStr.isNotEmpty) {
      return examsStr.split(',').where((x) => x.trim().isNotEmpty).length;
    }
    return 0;
  }

  String _toBengaliDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(english[i], bengali[i]);
    }
    return result;
  }

  String _getExamDateStr(dynamic createdAt, String examTitle) {
    try {
      if (createdAt != null) {
        final dt = DateTime.parse(createdAt.toString());
        final months = [
          'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
          'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
        ];
        final dayStr = _toBengaliDigits(dt.day.toString());
        final monthStr = months[dt.month - 1];
        final yearStr = _toBengaliDigits(dt.year.toString());
        return '$dayStr $monthStr, $yearStr';
      }
    } catch (_) {}

    final regExp = RegExp(r'\d{4}');
    final match = regExp.firstMatch(examTitle);
    if (match != null) {
      final year = match.group(0)!;
      return '${_toBengaliDigits("২৪")} মে, ${_toBengaliDigits(year)}';
    }
    final bnRegExp = RegExp(r'[০-৯]{4}');
    final bnMatch = bnRegExp.firstMatch(examTitle);
    if (bnMatch != null) {
      final year = bnMatch.group(0)!;
      return '২৪ মে, $year';
    }
    return '২৪ মে, ২০২৬';
  }

  // Skeleton loading helper for subject grid
  Widget _buildSubjectGridSkeleton() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: 4,
      itemBuilder: (context, index) => const ShimmerSkeleton(
        width: double.infinity,
        height: double.infinity,
        borderRadius: 24,
      ),
    );
  }

  // Skeleton loading helper for exams subjects
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

  // ----------------------------------------------------
  // View 1: Question Bank View (Hierarchical)
  // ----------------------------------------------------
  Widget _buildQuestionBankView(ThemeData theme) {
    final profile = ref.watch(userProfileProvider).value?.profile;
    if (profile == null || profile.classId == null || profile.classId!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'প্রোফাইলে কোনো ক্লাস সিলেক্ট করা নেই। অনুগ্রহ করে প্রোফাইল আপডেট করুন।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
      );
    }

    final classId = profile.classId!;
    final seriesAsync = ref.watch(qbClassSeriesProvider(classId));

    return seriesAsync.when(
      data: (seriesList) {
        if (seriesList.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'এই ক্লাসের জন্য কোনো প্রশ্নব্যাংক সিরিজ পাওয়া যায়নি।',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          );
        }
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          child: KeyedSubtree(
            key: ValueKey(_selectedSeriesStack.length),
            child: _buildHierarchicalSeriesFlow(seriesList),
          ),
        );
      },
      loading: () => _buildSubjectGridSkeleton(),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'ডাটা লোড করা যায়নি: $err',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
        ),
      ),
    );
  }

  // Stack-based hierarchical series browser
  Widget _buildHierarchicalSeriesFlow(List<dynamic> seriesList) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final subSeriesIds = seriesList
        .expand((s) => (s['subSeries'] as List<dynamic>?) ?? [])
        .map((e) => e.toString())
        .toSet();

    final rootSeriesList = seriesList.where((s) {
      final id = s['id']?.toString() ?? '';
      return !subSeriesIds.contains(id);
    }).toList();

    // Level 0: Top-level Series Browse
    if (_selectedSeriesStack.isEmpty) {
      final Map<String, List<Map<String, dynamic>>> groupedBySubject = {};
      for (final s in rootSeriesList) {
        if (s is Map<String, dynamic>) {
          final subId = s['subjectId']?.toString() ?? 'other';
          groupedBySubject.putIfAbsent(subId, () => []).add(s);
        }
      }

      final sortedSubjectIds = groupedBySubject.keys.toList()
        ..sort((a, b) {
          final subA = groupedBySubject[a]!.first['subject'] as Map<String, dynamic>?;
          final subB = groupedBySubject[b]!.first['subject'] as Map<String, dynamic>?;
          final orderA = subA?['sortOrder'] as int? ?? 100;
          final orderB = subB?['sortOrder'] as int? ?? 100;
          return orderA.compareTo(orderB);
        });

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: sortedSubjectIds.length,
              itemBuilder: (context, index) {
                final subjectId = sortedSubjectIds[index];
                final subjectSeries = groupedBySubject[subjectId]!;
                final firstSeries = subjectSeries.first;
                final subjectObj = firstSeries['subject'] as Map<String, dynamic>?;
                final subjectName = subjectObj?['name']?.toString() ?? firstSeries['name']?.toString() ?? 'অন্যান্য';
                final subjectIcon = subjectObj?['icon']?.toString();
                final imageUrl = firstSeries['logo']?.toString() ?? firstSeries['banner']?.toString() ?? subjectObj?['imageUrl']?.toString() ?? '';
                final count = _getCategoryCount(firstSeries);

                return BouncingCard(
                  onTap: () {
                    setState(() {
                      _selectedSeriesStack.add(firstSeries['id']?.toString() ?? '');
                      _activeExamTab = null;
                      _examSearchQuery = '';
                    });
                  },
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl.isNotEmpty)
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: child,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade50,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF017A47),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, _, __) => Container(
                              decoration: BoxDecoration(
                                gradient: _getSubjectGradient(subjectName),
                              ),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: _getSubjectGradient(subjectName),
                            ),
                          ),

                        if (imageUrl.isEmpty)
                          Positioned(
                            top: 16,
                            left: 16,
                            right: 16,
                            child: _buildSubjectTitle(subjectName),
                          ),
                        if (imageUrl.isEmpty)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Text(
                              subjectIcon ?? '📚',
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),

                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 14,
                                  color: isDark ? Colors.white70 : const Color(0xFF495057),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _toBengaliDigits('$count'),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF212529),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    // Level N: Navigating inside series
    final activeId = _selectedSeriesStack.last;
    final activeSeries = seriesList.firstWhere(
      (s) => s['id']?.toString() == activeId,
      orElse: () => null,
    );

    if (activeSeries == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedSeriesStack.clear();
        });
      });
      return const Center(child: CircularProgressIndicator(color: Color(0xFF017A47)));
    }

    final subSeriesListIds = (activeSeries['subSeries'] as List<dynamic>?) ?? [];
    final validSubSeries = subSeriesListIds.map((subId) {
      return seriesList.firstWhere(
        (s) => s['id']?.toString() == subId.toString(),
        orElse: () => null,
      );
    }).where((s) => s != null).toList();

    // Grid of Sub-Series (MCQ, CQ etc)
    if (validSubSeries.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47)),
                  onPressed: () {
                    setState(() {
                      _selectedSeriesStack.removeLast();
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    activeSeries['name']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16.0),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.0,
              children: validSubSeries.map<Widget>((subSeriesObj) {
                final subSeriesMap = subSeriesObj as Map<String, dynamic>;
                final subName = subSeriesMap['name']?.toString() ?? '';
                final subIdStr = subSeriesMap['id']?.toString() ?? '';

                Color cardColor = Colors.lightBlue.shade50;
                Color textColor = Colors.lightBlue.shade700;
                String icon = '📝';
                String title = subName;

                if (subName.toLowerCase().contains('mcq')) {
                  cardColor = const Color(0xFFE3F2FD);
                  textColor = const Color(0xFF1E88E5);
                  icon = '📝';
                  title = 'MCQ';
                } else if (subName.toLowerCase().contains('cq')) {
                  cardColor = const Color(0xFFFFF8E1);
                  textColor = const Color(0xFFF57F17);
                  icon = '📖';
                  title = 'CQ';
                } else if (subName.toLowerCase().contains('kbhandar')) {
                  cardColor = const Color(0xFFE8EAF6);
                  textColor = const Color(0xFF3F51B5);
                  icon = '📚';
                  title = 'ক ভাণ্ডার';
                } else if (subName.toLowerCase().contains('khabhandar')) {
                  cardColor = const Color(0xFFE8F5E9);
                  textColor = const Color(0xFF4CAF50);
                  icon = '📚';
                  title = 'খ ভাণ্ডার';
                } else if (subName.toLowerCase().contains('short') || subName.toLowerCase().contains('সংক্ষিপ্ত')) {
                  cardColor = const Color(0xFFF3E5F5);
                  textColor = const Color(0xFF9C27B0);
                  icon = '⏱️';
                  title = 'সংক্ষিপ্ত প্রশ্ন';
                }

                final subLogo = subSeriesMap['logo']?.toString() ?? subSeriesMap['banner']?.toString() ?? '';

                if (subLogo.isNotEmpty) {
                  return BouncingCard(
                    onTap: () {
                      setState(() {
                        _selectedSeriesStack.add(subIdStr);
                        _activeExamTab = null;
                        _examSearchQuery = '';
                      });
                    },
                    child: Card(
                      elevation: 0,
                      margin: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            subLogo,
                            fit: BoxFit.cover,
                            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                              if (wasSynchronouslyLoaded) return child;
                              return AnimatedOpacity(
                                opacity: frame == null ? 0 : 1,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                child: child,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade50,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF017A47),
                                    ),
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, _, __) => Container(
                              color: cardColor,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(icon, style: const TextStyle(fontSize: 32)),
                                    const SizedBox(height: 8),
                                    Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return BouncingCard(
                  onTap: () {
                    setState(() {
                      _selectedSeriesStack.add(subIdStr);
                      _activeExamTab = null;
                    });
                  },
                  child: Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E1E1E) : cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isDark ? Colors.white.withOpacity(0.05) : textColor.withOpacity(0.15), 
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 8),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    }

    // Tabbed Exams List selector
    var labelNameMap = Map<String, dynamic>.from(activeSeries['labelName'] as Map? ?? {});
    if (labelNameMap.isEmpty && activeSeries['exams'] != null) {
      final examsVal = activeSeries['exams'];
      if (examsVal is String && examsVal.isNotEmpty) {
        labelNameMap = {
          'Exams': examsVal.split(','),
        };
      } else if (examsVal is List && examsVal.isNotEmpty) {
        labelNameMap = {
          'Exams': examsVal.map((e) => e.toString()).toList(),
        };
      }
    }

    if (labelNameMap.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47)),
                  onPressed: () {
                    setState(() {
                      _selectedSeriesStack.removeLast();
                    });
                  },
                ),
                Expanded(
                  child: Text(
                    activeSeries['name']?.toString() ?? '',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'কোনো পরীক্ষা পাওয়া যায়নি।',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      );
    }

    final tabKeys = labelNameMap.keys.toList();
    final displayTabs = ['সব', ...tabKeys];
    _activeExamTab ??= 'সব';
    if (!displayTabs.contains(_activeExamTab)) {
      _activeExamTab = 'সব';
    }
    final hasMultipleLevels = tabKeys.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47),
                ),
                onPressed: () {
                  setState(() {
                    _selectedSeriesStack.removeLast();
                    _examSearchQuery = '';
                  });
                },
              ),
              Expanded(
                child: Text(
                  activeSeries['name']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    fontFamily: 'Noto Sans Bengali',
                  ),
                ),
              ),
            ],
          ),
        ),

        if (hasMultipleLevels) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SizedBox(
              height: 44,
              child: TextField(
                onChanged: (val) {
                  setState(() {
                    _examSearchQuery = val;
                  });
                },
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                  fontFamily: 'Noto Sans Bengali',
                ),
                decoration: InputDecoration(
                  hintText: 'পরীক্ষা খুঁজে বের করো...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontFamily: 'Noto Sans Bengali'),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500, size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? const Color(0xFFF18881) : const Color(0xFF017A47), width: 1.5),
                  ),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F5),
                ),
              ),
            ),
          ),
          Container(
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: displayTabs.map<Widget>((key) {
                final isSelected = _activeExamTab == key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _activeExamTab = key;
                        _examSearchQuery = '';
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFFF18881) : const Color(0xFF017A47))
                            : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F3F5)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? (isDark ? const Color(0xFFF18881) : const Color(0xFF017A47))
                              : Colors.transparent,
                          width: 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: (isDark ? const Color(0xFFF18881) : const Color(0xFF017A47)).withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                            fontFamily: 'Noto Sans Bengali',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],

        Expanded(
          child: Consumer(
            builder: (context, ref, _) {
              final List<String> idsToLoad;
              if (hasMultipleLevels) {
                if (_activeExamTab == 'সব') {
                  idsToLoad = tabKeys
                      .expand((k) => List<String>.from(labelNameMap[k] ?? []))
                      .toSet()
                      .toList();
                } else {
                  idsToLoad = List<String>.from(labelNameMap[_activeExamTab] ?? []);
                }
              } else {
                idsToLoad = List<String>.from(labelNameMap[tabKeys.first] ?? []);
              }

              final examsAsync = ref.watch(qbExamsProvider(idsToLoad.join(',')));
              return examsAsync.when(
                data: (examsList) {
                  var filteredList = examsList;
                  if (hasMultipleLevels && _examSearchQuery.isNotEmpty) {
                    filteredList = examsList.where((ex) {
                      final title = ex['title']?.toString() ?? '';
                      return title.toLowerCase().contains(_examSearchQuery.toLowerCase());
                    }).toList();
                  }

                  if (filteredList.isEmpty) {
                    return const Center(child: Text('কোনো পরীক্ষা পাওয়া যায়নি।'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredList.length,
                    itemBuilder: (context, idx) {
                      final ex = filteredList[idx] as Map<String, dynamic>;
                      final title = ex['title']?.toString() ?? '';
                      final duration = ex['duration'] as int? ?? 1500;
                      final durationMin = (duration / 60).round();
                      final qCount = ex['qCount'] as int? ?? 25;

                      final createdAt = ex['createdAt'];
                      final dateStr = _getExamDateStr(createdAt, title);

                      return BouncingCard(
                        onTap: () {
                          _showExamConfirmSheet(context, ex);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.015),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1.35,
                                    color: isDark ? Colors.white : const Color(0xFF212529),
                                    fontFamily: 'Noto Sans Bengali',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  alignment: WrapAlignment.start,
                                  children: [
                                    // Time Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF5F5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFFFE3E3), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.timer_outlined,
                                            size: 13,
                                            color: Color(0xFFE03131),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${_toBengaliDigits(durationMin.toString())} মিনিট',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFC92A2A),
                                              fontFamily: 'Noto Sans Bengali',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Questions Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6FCF5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFC3FAE8), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.edit_note_outlined,
                                            size: 14,
                                            color: Color(0xFF099268),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_toBengaliDigits(qCount.toString())}টি প্রশ্ন',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF087F5B),
                                              fontFamily: 'Noto Sans Bengali',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Date Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDF2FF),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFDBE4FF), width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.calendar_month_outlined,
                                            size: 13,
                                            color: Color(0xFF364FC7),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2B4C7E),
                                              fontFamily: 'Noto Sans Bengali',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200, width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ShimmerSkeleton(
                            width: 180,
                            height: 16,
                            borderRadius: 4,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFFFF5F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const ShimmerSkeleton(width: 50, height: 11, borderRadius: 3),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFE6FCF5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const ShimmerSkeleton(width: 50, height: 11, borderRadius: 3),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFEDF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const ShimmerSkeleton(width: 65, height: 11, borderRadius: 3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                error: (err, _) => Center(child: Text('পরীক্ষা লোড করতে ব্যর্থ হয়েছে: $err')),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper institutions expansions
  Widget _buildInstitutionsList(List<Map<String, dynamic>> list, String type) {
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('কোনো প্রতিষ্ঠান যোগ করা হয়নি।', style: TextStyle(color: Colors.black45, fontSize: 12)),
      );
    }

    final years = [2025, 2024, 2023, 2022, 2021, 2020];

    return Column(
      children: list.map((item) {
        final id = item['id']?.toString() ?? '';
        final name = item['name']?.toString() ?? '';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            title: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
            leading: const Icon(Icons.business_center, size: 18, color: Color(0xFF017A47)),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 12.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: years.map((year) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedQbItemType = type;
                          _selectedQbItemId = id;
                          _selectedQbItemName = name;
                          _selectedQbYear = year;
                        });
                        _fetchQbQuestions(refresh: true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF017A47).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF017A47).withOpacity(0.2)),
                        ),
                        child: Text(
                          '$year',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF017A47),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Dropdown helper
  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13, color: Colors.black54)),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Detail Modal Sheet
  void _showQuestionDetailSheet(BuildContext context, QuestionModel question, String sourceLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF017A47).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF017A47).withOpacity(0.2)),
                    ),
                    child: Text(
                      sourceLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF017A47),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.4,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (question.imageKey != null && question.imageKey!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        question.imageKey!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Text(
                    'বিকল্পসমূহ:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                      fontSize: 13,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: question.options.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final opt = entry.value;
                      final prefixes = ['ক', 'খ', 'গ', 'ঘ'];
                      final prefix = idx < prefixes.length ? prefixes[idx] : '${idx + 1}';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: opt.isCorrect ? const Color(0xFFE8F5E9) : const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: opt.isCorrect ? const Color(0xFF017A47) : Colors.white,
                                shape: BoxShape.circle,
                                border: opt.isCorrect
                                    ? null
                                    : Border.all(color: const Color(0xFFCFD8DC), width: 1.5),
                              ),
                              alignment: Alignment.center,
                              child: opt.isCorrect
                                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                                  : Text(
                                      prefix,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                        fontFamily: 'Noto Sans Bengali',
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                opt.optionText,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: opt.isCorrect ? FontWeight.w600 : FontWeight.w400,
                                  color: opt.isCorrect ? const Color(0xFF017A47) : Colors.black87,
                                  fontFamily: 'Noto Sans Bengali',
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  _QbExplanationCard(
                    questionId: question.id,
                    initialExplanations: question.explanations,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // View 2: Mock Exam List View
  // ----------------------------------------------------
  Widget _buildExamListView(ThemeData theme) {
    final profile = ref.watch(userProfileProvider).value?.profile;
    final className = profile?.className ?? 'HSC 2026';
    final groupName = profile?.batch ?? profile?.targetExam ?? 'বিজ্ঞান';
    final isDark = theme.brightness == Brightness.dark;

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
                              ? const Color(0xFFF18881).withOpacity(0.12) 
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

  void _showExamConfirmSheet(BuildContext context, Map<String, dynamic> ex) {
    final title = ex['title']?.toString() ?? '';
    final duration = ex['duration'] as int? ?? 1500;
    final durationMin = (duration / 60).round();
    final qCount = ex['qCount'] as int? ?? 25;
    final examId = ex['id'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 10.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Noto Sans Bengali',
                  ),
                ),
                const SizedBox(height: 20),
                // Overview Card
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Time
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            color: Color(0xFFC92A2A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_toBengaliDigits(durationMin.toString())} মিনিট',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                        ],
                      ),
                      // Divider
                      Container(
                        width: 1.5,
                        height: 24,
                        color: Colors.grey.shade200,
                      ),
                      // Question Count
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            color: Color(0xFF2B8A3E),
                            size: 24,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_toBengaliDigits(qCount.toString())}টি প্রশ্ন',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: 'Noto Sans Bengali',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Start Exam Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/exam/$examId');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF017A47),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'পরীক্ষা শুরু করো',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // View Questions Button
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/exam-preview/$examId', extra: title);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF017A47),
                    side: const BorderSide(color: Color(0xFF017A47), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFECEFF1).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text(
                    'প্রশ্ন দেখো',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Noto Sans Bengali',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------
// UI Supporting Entities & Micro Loops
// ----------------------------------------------------
class LeaderboardPlayer {
  final String name;
  final int score;
  final String avatarText;
  final Color avatarBg;
  final bool isCurrentUser;

  LeaderboardPlayer({
    required this.name,
    required this.score,
    required this.avatarText,
    required this.avatarBg,
    this.isCurrentUser = false,
  });
}

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

// Micro-animation Loops
class FloatingWidget extends StatefulWidget {
  final Widget child;
  const FloatingWidget({super.key, required this.child});

  @override
  State<FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<FloatingWidget> {
  double _value = 0.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _value),
      duration: const Duration(seconds: 1),
      onEnd: () {
        setState(() {
          _value = _value == 0.0 ? 3.0 : 0.0;
        });
      },
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, -offset),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class PulseWidget extends StatefulWidget {
  final Widget child;
  const PulseWidget({super.key, required this.child});

  @override
  State<PulseWidget> createState() => _PulseWidgetState();
}

class _PulseWidgetState extends State<PulseWidget> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1.0, end: _scale),
      duration: const Duration(milliseconds: 900),
      onEnd: () {
        setState(() {
          _scale = _scale == 1.0 ? 1.15 : 1.0;
        });
      },
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class RotateWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  const RotateWidget({super.key, required this.child, this.duration = const Duration(seconds: 4)});

  @override
  State<RotateWidget> createState() => _RotateWidgetState();
}

class _RotateWidgetState extends State<RotateWidget> {
  double _angle = 0.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: _angle),
      duration: widget.duration,
      onEnd: () {
        setState(() {
          _angle += 6.28318;
        });
      },
      builder: (context, angle, child) {
        return Transform.rotate(
          angle: angle,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ----------------------------------------------------
// Banners Slider Carousel Widget
// ----------------------------------------------------
class BannerSliderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  const BannerSliderWidget({super.key, required this.banners});

  @override
  State<BannerSliderWidget> createState() => _BannerSliderWidgetState();
}

class _BannerSliderWidgetState extends State<BannerSliderWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _startAutoTimer();
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    if (widget.banners.length > 1) {
      _autoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients && widget.banners.isNotEmpty) {
          final nextPage = (_currentIndex + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.banners.length,
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                final String title = banner['title'] ?? '';
                final String badgeText = banner['badgeText'] ?? 'OFFER';
                final String? imageUrl = banner['imageUrl'];
                final String? rawTargetUrl = banner['targetUrl'];
                final bool isClickable = rawTargetUrl != null &&
                    rawTargetUrl.isNotEmpty &&
                    rawTargetUrl.trim() != '#' &&
                    rawTargetUrl.trim() != 'javascript:void(0)';
                final String targetUrl = isClickable ? rawTargetUrl.trim() : '';

                final List<Color> gradientColors = banner['colors'] ?? [const Color(0xFF004D40), const Color(0xFF00796B)];
                final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: GestureDetector(
                    onTap: isClickable
                        ? () {
                            if (targetUrl.startsWith('/')) {
                              context.push(targetUrl);
                            }
                          }
                        : null,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: !hasImage
                            ? LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        image: hasImage
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: hasImage
                          ? const SizedBox.expand()
                          : Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFD9746E), Color(0xFFF18881)],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: isClickable
                                              ? () {
                                                  if (targetUrl.startsWith('/')) {
                                                    context.push(targetUrl);
                                                  }
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            elevation: 0,
                                            minimumSize: const Size(0, 30),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Get now',
                                            style: TextStyle(
                                              color: Color(0xFF004D40),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(banner['icon'] ?? '🦖', style: const TextStyle(fontSize: 38)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),

            // Premium Floating Indicator Capsule Overlay
            if (widget.banners.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        widget.banners.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QbExplanationCard extends ConsumerStatefulWidget {
  final String questionId;
  final List<dynamic>? initialExplanations;

  const _QbExplanationCard({
    required this.questionId,
    this.initialExplanations,
  });

  @override
  ConsumerState<_QbExplanationCard> createState() => _QbExplanationCardState();
}

class _QbExplanationCardState extends ConsumerState<_QbExplanationCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _isUnlocked = false;
  List<dynamic> _explanations = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialExplanations != null && widget.initialExplanations!.isNotEmpty) {
      _explanations = widget.initialExplanations!;
      _isUnlocked = true;
    }
  }

  Future<void> _handleTap() async {
    if (_isUnlocked) {
      setState(() {
        _isExpanded = !_isExpanded;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final repo = ref.read(examRepositoryProvider);
      final res = await repo.unlockExplanation(widget.questionId);

      if (mounted) {
        final newRemaining = (res['remainingDaily'] as num?)?.toInt();
        if (newRemaining != null) {
          ref.read(dailyQuotaProvider.notifier).setQuota(newRemaining);
        }

        setState(() {
          _explanations = res['explanations'] as List<dynamic>? ?? [];
          _isUnlocked = true;
          _isExpanded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showLimitDialog(context);
      }
    }
  }

  void _showLimitDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_outlined, color: Color(0xFFF59E0B), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'দৈনিক ব্যাখ্যা সীমা অতিক্রান্ত!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'আপনি আজকের ১০টি দৈনিক ব্যাখ্যা দেখার সীমা সম্পূর্ণ করেছেন। আগামীকাল নতুন করে ১০টি ব্যাখ্যা আনলক করতে পারবেন।',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF017A47),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _toBengaliDigit(int number) {
    const englishToBengali = {
      '0': '০',
      '1': '১',
      '2': '২',
      '3': '৩',
      '4': '৪',
      '5': '৫',
      '6': '৬',
      '7': '৭',
      '8': '৮',
      '9': '৯',
    };
    return number.toString().split('').map((char) => englishToBengali[char] ?? char).join();
  }

  @override
  Widget build(BuildContext context) {
    int currentQuota = 10;
    try {
      currentQuota = ref.watch(dailyQuotaProvider);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _isLoading ? null : _handleTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF017A47).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Color(0xFF017A47), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ব্যাখ্যা',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF017A47),
                            fontFamily: 'Noto Sans Bengali',
                          ),
                        ),
                        Text(
                          currentQuota > 0
                              ? 'দৈনিক ব্যাখ্যা বাকি - ${_toBengaliDigit(currentQuota)}'
                              : 'আজকের ১০টি সীমার সবগুলো দেখা শেষ!',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.grey.shade700,
                            fontFamily: 'Noto Sans Bengali',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF017A47)),
                    )
                  else
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: const Color(0xFF017A47),
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded && _explanations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Color(0xFFA7F3D0)),
                  const SizedBox(height: 6),
                  ..._explanations.map((expData) {
                    final expMap = expData is Map<String, dynamic>
                        ? expData
                        : (expData as dynamic).toJson() as Map<String, dynamic>;
                    final expText = expMap['text'] as String? ?? '';
                    final expImgKey = expMap['imageKey'] as String?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.45,
                            fontFamily: 'Noto Sans Bengali',
                          ),
                        ),
                        if (expImgKey != null && expImgKey.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              expImgKey,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
