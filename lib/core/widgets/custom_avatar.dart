import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? fallbackWidget;

  const CustomAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 20,
    this.backgroundColor,
    this.fallbackWidget,
  });

  static const String defaultAvatarUrl =
      'https://api.dicebear.com/9.x/avataaars/svg?top=dreads02&topProbability=100&hairColor=2c1b18&hatColor=262e33&eyes=default&eyebrows=default&mouth=smile&skinColor=ffdbb4&clothing=shirtCrewNeck&clothesColor=3c4f76&accessoriesProbability=0&facialHairProbability=0&backgroundColor=b1c9ef';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Default fallback color if not specified
    final bg = backgroundColor ?? 
        (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE8F5E9));

    // Fallback widget if url fails
    final defaultFallback = fallbackWidget ?? 
        Icon(
          Icons.person_rounded, 
          size: radius * 1.1, 
          color: theme.primaryColor,
        );

    final effectiveUrl = (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
        ? avatarUrl!.trim()
        : defaultAvatarUrl;

    // Check if it is an SVG from Dicebear or similar
    if (effectiveUrl.toLowerCase().contains('.svg') || effectiveUrl.contains('api.dicebear.com')) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
        ),
        clipBehavior: Clip.antiAlias,
        child: SvgPicture.network(
          effectiveUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => Container(
            width: radius * 2,
            height: radius * 2,
            color: bg,
            child: Center(
              child: SizedBox(
                width: radius * 0.8,
                height: radius * 0.8,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          errorBuilder: (context, error, stackTrace) => defaultFallback,
        ),
      );
    }

    // Standard Image URL
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: CachedNetworkImageProvider(effectiveUrl),
      onBackgroundImageError: (exception, stackTrace) {
        // Handled internally by Flutter, falls back to child
      },
      child: null,
    );
  }
}
