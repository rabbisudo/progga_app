import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

/// Calculates the ergonomically optimized bottom margin for the floating navigation bar.
///
/// Handles all platform navigation styles seamlessly:
/// 1. iOS (iPhone X..16 with Home Indicator, bottom safe area inset ~34.0):
///    The home indicator is a thin gesture line (~13pt from bottom).
///    We float comfortably above it (~14-16pt) to eliminate excessive blank voids.
/// 2. Android 3-Button Navigation (bottomInset >= 36dp, typically 48dp):
///    The 3 hardware/system buttons (Back, Home, Recents) physically occupy the bottom 0..bottomInset.
///    The floating pill sits completely above it (bottomInset + 8dp) so the 3 buttons
///    NEVER overlap, touch, or block any tab buttons.
/// 3. Android Gesture Navigation (bottomInset ~16..24dp):
///    The bar floats with comfortable clearance above the gesture handle (bottomInset + 6dp).
/// 4. Devices with no inset (iPhone SE, hardware buttons, desktop/web):
///    Returns a standard 8dp margin.
double getFloatingNavBarBottomMargin(BuildContext context) {
  final bottomInset = MediaQuery.of(context).padding.bottom;
  if (bottomInset <= 0) return 8.0;

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return (bottomInset * 0.44).clamp(12.0, 16.0);
  }

  // Android 3-button navigation (typically 48dp):
  // System buttons must not be touched. Provide clean 8dp clearance above them.
  if (bottomInset >= 36.0) {
    return bottomInset + 8.0;
  }

  // Android Gesture navigation (typically 16-24dp):
  // Provide clean 6dp clearance above the gesture pill.
  return bottomInset + 6.0;
}

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

    final effectiveBottom = getFloatingNavBarBottomMargin(context);

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // 1. Subtle bottom fade starting halfway behind the bar to cleanly conceal the bottom inset
        // without casting any dark shadow or haze over the content above the bar.
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
                    theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                    theme.scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.45, 0.8],
                ),
              ),
            ),
          ),
        ),

        // 2. Floating Navigation Bar Pill with clean white background and soft subtle shadow
        Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, effectiveBottom),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.35) 
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withValues(alpha: 0.2) 
                      : Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF1E1E1E) 
                        : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.08) 
                          : const Color(0xFFE9ECEF),
                      width: 1.0,
                    ),
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
                            left: selectedIndex * tabWidth + 5,
                            top: 5,
                            width: tabWidth - 10,
                            height: 54,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF017A47).withValues(alpha: 0.18),
                                          const Color(0xFF017A47).withValues(alpha: 0.08)
                                        ]
                                      : [
                                          const Color(0xFFE0ECE6),
                                          const Color(0xFFB9D8C9).withValues(alpha: 0.4)
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isDark 
                                      ? const Color(0xFF017A47).withValues(alpha: 0.15) 
                                      : const Color(0xFF017A47).withValues(alpha: 0.06),
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
          ),
        ),
      ],
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
    
    const activeColor = Color(0xFF017A47);
    final inactiveColor = isDark ? Colors.grey[400]! : const Color(0xFF495057);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onDestinationSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.10 : 1.0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: SvgPicture.string(
                isSelected ? selectedIconStr : iconStr,
                width: 23,
                height: 23,
                colorFilter: ColorFilter.mode(
                  isSelected ? activeColor : inactiveColor, 
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.2,
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

