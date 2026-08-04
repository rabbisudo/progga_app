import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Default fallback color if not specified
    final bg = backgroundColor ?? 
        (isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE8F5E9));

    // Fallback widget if url is null/empty
    final defaultFallback = fallbackWidget ?? 
        Icon(
          Icons.person_rounded, 
          size: radius * 1.1, 
          color: theme.primaryColor,
        );

    if (avatarUrl == null || avatarUrl!.trim().isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: defaultFallback,
      );
    }

    final cleanedUrl = avatarUrl!.trim();

    // Check if it is an SVG from Dicebear or similar
    if (cleanedUrl.toLowerCase().contains('.svg') || cleanedUrl.contains('api.dicebear.com')) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
        ),
        clipBehavior: Clip.antiAlias,
        child: SvgPicture.network(
          cleanedUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => SizedBox(
            width: radius * 2,
            height: radius * 2,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
          errorBuilder: (context, error, stackTrace) => defaultFallback,
        ),
      );
    }

    // Standard Image URL
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      backgroundImage: NetworkImage(cleanedUrl),
      onBackgroundImageError: (exception, stackTrace) {
        // Handled internally by Flutter, falls back to child
      },
      child: null,
    );
  }
}
