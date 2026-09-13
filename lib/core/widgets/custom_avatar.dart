import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'progga_animated_avatar.dart';

class CustomAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? fallbackWidget;
  final bool animate;

  const CustomAvatar({
    super.key,
    required this.avatarUrl,
    this.radius = 20,
    this.backgroundColor,
    this.fallbackWidget,
    this.animate = true,
  });

  static const String defaultAvatarKey = 'progga:bg=0071f9&skin=ffdbb4&hair=shortCurly&hairColor=2c1b18&eyes=default&mouth=smile&clothing=shirtCrewNeck&clothingColor=0071f9';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Default fallback color if not specified
    final bg = backgroundColor ?? 
        (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8F1FF));

    // Fallback widget if url fails
    final defaultFallback = fallbackWidget ?? 
        Icon(
          Icons.person_rounded, 
          size: radius * 1.1, 
          color: theme.primaryColor,
        );

    final effectiveUrl = (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
        ? avatarUrl!.trim()
        : defaultAvatarKey;

    // 1. In-House Progga format or legacy DiceBear: Render locally with zero network latency & animations
    if (effectiveUrl.startsWith('progga:') || effectiveUrl.contains('api.dicebear.com') || effectiveUrl.startsWith('avatar:')) {
      return ProggaAnimatedAvatar(
        avatarKey: effectiveUrl,
        radius: radius,
        isAnimated: animate && radius >= 28, // animate for profile / hero, keep lightweight for tiny thumbnails
      );
    }

    // 2. Generic local or external standalone SVG file
    if (effectiveUrl.toLowerCase().endsWith('.svg')) {
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

    // Standard Image URL (Scaled to avatar dimensions to prevent memory bloat)
    final imagePixelDimension = (radius * 4).round();
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: CachedNetworkImageProvider(
        effectiveUrl,
        maxHeight: imagePixelDimension,
        maxWidth: imagePixelDimension,
      ),
      onBackgroundImageError: (exception, stackTrace) {
        // Handled internally by Flutter, falls back to child
      },
      child: null,
    );
  }
}
