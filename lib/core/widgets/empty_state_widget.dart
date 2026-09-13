import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? customSvg;
  final VoidCallback? onRetry;
  final String? retryLabel;

  final IconData? retryIcon;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    this.subtitle,
    this.icon,
    this.customSvg,
    this.onRetry,
    this.retryLabel,
    this.retryIcon,
  }) : super(key: key);

  static const String _defaultBookSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24">
	<path d="M0 0h24v24H0z" fill="none" />
	<g fill="none">
		<path stroke="currentColor" stroke-width="1.5" d="M12 5.854V21" />
		<path stroke="currentColor" stroke-linecap="round" stroke-width="1.5" d="m5 9l4 1m-4 3l4 1m10-1l-4 1m4-8.5v4.01c0 .276 0 .414-.095.47s-.224-.007-.484-.13l-1.242-.59c-.088-.042-.132-.062-.179-.062s-.091.02-.179.062l-1.242.59c-.26.123-.39.185-.484.13C15 9.923 15 9.785 15 9.51V6.95" />
		<path fill="currentColor" d="m20.082 3.018l.026.75zm-3.582.47l-.215-.72v.001zm-2.826 1.315l-.376-.65zM3.982 3.075l-.046.748zM7 3.487l.191-.725zm3.282 1.388l-.35.663zm3.346 15.194l.352.662zM17 18.633l-.191-.725zm3.985-.41l.047.748zm-9.613 1.846l-.352.662zM7 18.633l.191-.725zm-2.985-.41l-.047.748zm18.735-7.685a.75.75 0 0 0-1.5 0zM21.25 7a.75.75 0 0 0 1.5 0zm-20 3.57a.75.75 0 0 0 1.5 0zM2.75 14a.75.75 0 0 0-1.5 0zM20.056 2.268c-1.139.04-2.626.158-3.771.501l.43 1.437c.95-.284 2.274-.4 3.393-.439zm-3.771.501c-.995.298-2.114.88-2.987 1.385l.752 1.298c.85-.492 1.845-1 2.665-1.246zM3.936 3.823c.966.06 2.06.175 2.873.39l.382-1.45c-.96-.254-2.176-.376-3.163-.437zm2.873.39c.962.254 2.146.809 3.123 1.325l.7-1.326c-.995-.526-2.304-1.15-3.44-1.45zM13.98 20.73c.991-.528 2.219-1.11 3.211-1.373l-.382-1.45c-1.17.309-2.526.962-3.534 1.5zm3.211-1.373c.803-.211 1.882-.327 2.841-.387l-.094-1.497c-.98.062-2.179.183-3.13.434zm-6.466.05c-1.008-.538-2.363-1.191-3.534-1.5l-.382 1.45c.992.262 2.22.845 3.21 1.373zm-3.534-1.5c-.95-.25-2.15-.372-3.13-.434l-.093 1.497c.959.06 2.038.176 2.84.387zm14.059-1.764c0 .685-.568 1.284-1.312 1.33l.094 1.497c1.474-.092 2.718-1.291 2.718-2.827zm1.5-11.21c0-1.464-1.165-2.719-2.694-2.666l.052 1.5c.615-.022 1.142.484 1.142 1.165zm-21.5 11.21c0 1.536 1.244 2.735 2.718 2.827l.094-1.497c-.744-.046-1.312-.645-1.312-1.33zm12.025 3.263a2.72 2.72 0 0 1-2.55 0l-.705 1.324a4.22 4.22 0 0 0 3.96 0zm.023-15.253a2.77 2.77 0 0 1-2.665.058l-.701 1.326a4.27 4.27 0 0 0 4.118-.086zM2.75 4.998c0-.697.552-1.213 1.186-1.175l.092-1.497C2.47 2.231 1.25 3.5 1.25 4.998zm20 11.146v-5.606h-1.5v5.606zm0-9.144V4.933h-1.5V7zm-20 3.57V4.999h-1.5v5.573zm0 5.574V14h-1.5v2.144z" />
	</g>
</svg>''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Styled Premium Icon/SVG Container
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFF0071F9).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: icon != null
                  ? Icon(
                      icon,
                      size: 64,
                      color: const Color(0xFF0071F9),
                    )
                  : SvgPicture.string(
                      customSvg ?? _defaultBookSvg,
                      width: 64,
                      height: 64,
                      colorFilter: const ColorFilter.mode(Color(0xFF0071F9), BlendMode.srcIn),
                    ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                fontFamily: 'Li Ador Noirrit',
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              // Subtitle
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.white38 : Colors.black54,
                  height: 1.5,
                  fontFamily: 'Li Ador Noirrit',
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              // Premium Retry Button
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: Icon(retryIcon ?? Icons.refresh_rounded, size: 18),
                label: Text(
                  retryLabel ?? 'আবার চেষ্টা করুন',
                  style: const TextStyle(
                    fontFamily: 'Li Ador Noirrit',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0071F9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
