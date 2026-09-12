import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../avatar/progga_avatar_engine.dart';

/// Highly-polished, in-house animated vector avatar for Progga.
/// Features:
/// - Zero external network calls (100% locally generated vector SVG).
/// - Idle breathing/floating micro-animation.
/// - Realistic periodic eye blinking (every ~3-4 seconds).
/// - Smooth glowing aura ring.
class ProggaAnimatedAvatar extends StatefulWidget {
  final ProggaAvatarConfig? config;
  final String? avatarKey;
  final double radius;
  final bool isAnimated;
  final bool showAura;
  final bool isCircle;
  final bool hasBg;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const ProggaAnimatedAvatar({
    super.key,
    this.config,
    this.avatarKey,
    this.radius = 40,
    this.isAnimated = true,
    this.showAura = false,
    this.isCircle = true,
    this.hasBg = true,
    this.borderRadius,
    this.onTap,
  });

  @override
  State<ProggaAnimatedAvatar> createState() => _ProggaAnimatedAvatarState();
}

class _ProggaAnimatedAvatarState extends State<ProggaAnimatedAvatar> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  late AnimationController _glassesGlintController;
  Timer? _glassesGlintTimer;

  Timer? _blinkTimer;
  bool _isBlinking = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 1. Idle breathing float animation (smooth sine-like movement)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _floatAnimation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    // 2. Premium Glasses Glint & Shimmer animation
    _glassesGlintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.isAnimated) {
      _floatController.repeat(reverse: true);
      _scheduleNextBlink();
      _scheduleNextGlassesGlint();
    }
  }

  @override
  void didUpdateWidget(covariant ProggaAnimatedAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimated != oldWidget.isAnimated) {
      if (widget.isAnimated) {
        _floatController.repeat(reverse: true);
        _scheduleNextBlink();
        _scheduleNextGlassesGlint();
      } else {
        _floatController.stop();
        _glassesGlintController.stop();
        _blinkTimer?.cancel();
        _glassesGlintTimer?.cancel();
        setState(() => _isBlinking = false);
      }
    }

    // Trigger instant shine if glasses style changed
    final oldGlasses = oldWidget.config?.glasses ?? ProggaAvatarConfig.fromKey(oldWidget.avatarKey).glasses;
    final newGlasses = _effectiveConfig.glasses;
    if (widget.isAnimated && newGlasses != 'none' && newGlasses != oldGlasses) {
      _triggerGlassesGlint();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glassesGlintController.dispose();
    _blinkTimer?.cancel();
    _glassesGlintTimer?.cancel();
    super.dispose();
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    if (!mounted || !widget.isAnimated) return;

    // Natural human eye blinking interval: 3000ms - 4500ms
    final delay = 3000 + _random.nextInt(1500);
    _blinkTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      setState(() => _isBlinking = true);

      // Blink duration ~130ms
      Timer(const Duration(milliseconds: 130), () {
        if (!mounted) return;
        setState(() => _isBlinking = false);
        _scheduleNextBlink();
      });
    });
  }

  void _scheduleNextGlassesGlint() {
    _glassesGlintTimer?.cancel();
    if (!mounted || !widget.isAnimated) return;
    if (_effectiveConfig.glasses == 'none') return;

    // Natural glint interval every 4000ms - 6000ms
    final delay = 4000 + _random.nextInt(2000);
    _glassesGlintTimer = Timer(Duration(milliseconds: delay), () {
      if (!mounted) return;
      _triggerGlassesGlint();
    });
  }

  void _triggerGlassesGlint() {
    if (!mounted || _effectiveConfig.glasses == 'none') return;
    if (_glassesGlintController.isAnimating) return;

    _glassesGlintController.forward(from: 0.0).then((_) {
      if (mounted && widget.isAnimated) {
        _scheduleNextGlassesGlint();
      }
    });
  }

  ProggaAvatarConfig get _effectiveConfig {
    if (widget.config != null) return widget.config!;
    return ProggaAvatarConfig.fromKey(widget.avatarKey);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveConfig = _effectiveConfig;
    final diameter = widget.radius * 2;
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(diameter * 0.22);
    final svgRadius = effectiveBorderRadius.topLeft.x * (260 / diameter);

    // Generate local SVG string directly from RAM
    final svgString = ProggaAvatarSvgBuilder.buildSvg(
      effectiveConfig,
      isBlinking: widget.isAnimated ? _isBlinking : false,
      isCircle: widget.isCircle,
      hasBg: widget.hasBg,
      borderRadius: svgRadius,
    );

    Widget avatarWidget = !widget.hasBg
        ? SizedBox(
            width: diameter,
            height: diameter,
            child: SvgPicture.string(
              svgString,
              width: diameter,
              height: diameter,
              fit: BoxFit.contain,
            ),
          )
        : (widget.isCircle
            ? ClipOval(
                child: SizedBox(
                  width: diameter,
                  height: diameter,
                  child: SvgPicture.string(
                    svgString,
                    width: diameter,
                    height: diameter,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : (effectiveConfig.bgStyle == 'cloud'
                ? SizedBox(
                    width: diameter,
                    height: diameter,
                    child: SvgPicture.string(
                      svgString,
                      width: diameter,
                      height: diameter,
                      fit: BoxFit.contain,
                    ),
                  )
                : ClipRRect(
                    borderRadius: effectiveBorderRadius,
                    child: SizedBox(
                      width: diameter,
                      height: diameter,
                      child: SvgPicture.string(
                        svgString,
                        width: diameter,
                        height: diameter,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )));

    // Stack glasses dynamic glint/shine animation directly over the avatar
    if (widget.isAnimated && effectiveConfig.glasses != 'none') {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _glassesGlintController,
                builder: (context, _) {
                  final progress = _glassesGlintController.value;
                  if (progress <= 0.0 || progress >= 1.0) {
                    return const SizedBox.shrink();
                  }
                  return CustomPaint(
                    size: Size(diameter, diameter),
                    painter: _GlassesGlintPainter(
                      progress: progress,
                      glassesStyle: effectiveConfig.glasses,
                      glassesColorHex: effectiveConfig.glassesColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // Apply floating bob animation if enabled
    if (widget.isAnimated) {
      avatarWidget = AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: child,
          );
        },
        child: avatarWidget,
      );
    }

    if (widget.showAura && widget.hasBg) {
      avatarWidget = Stack(
        alignment: Alignment.center,
        children: [
          // Soft ambient glow
          Container(
            width: diameter + 10,
            height: diameter + 10,
            decoration: BoxDecoration(
              shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: widget.isCircle ? null : effectiveBorderRadius.add(BorderRadius.circular(4)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF086057).withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          avatarWidget,
        ],
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        _triggerGlassesGlint();
        widget.onTap?.call();
      },
      child: avatarWidget,
    );
  }
}

/// Custom painter rendering a luminous lens light sweep and anime sparkle glint
class _GlassesGlintPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final String glassesStyle;
  final String glassesColorHex;

  _GlassesGlintPainter({
    required this.progress,
    required this.glassesStyle,
    required this.glassesColorHex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (glassesStyle == 'none' || progress <= 0.0 || progress >= 1.0) return;

    final scale = size.width / 260.0;

    if (glassesStyle == 'cyberVisor') {
      _paintCyberVisorEffect(canvas, size, scale);
    } else {
      _paintClassicGlassesEffect(canvas, size, scale);
    }
  }

  void _paintCyberVisorEffect(Canvas canvas, Size size, double scale) {
    final visorRect = Rect.fromLTRB(82 * scale, 105 * scale, 178 * scale, 126 * scale);
    final visorRRect = RRect.fromRectAndRadius(visorRect, Radius.circular(4 * scale));

    canvas.save();
    canvas.clipRRect(visorRRect);

    // 1. Moving neon laser beam
    final yScan = (105 + (126 - 105) * progress) * scale;
    final laserPaint = Paint()
      ..color = const Color(0xFF00FFCC).withValues(alpha: 0.9)
      ..strokeWidth = 2.4 * scale
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 * scale);
    canvas.drawLine(Offset(80 * scale, yScan), Offset(180 * scale, yScan), laserPaint);

    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0 * scale;
    canvas.drawLine(Offset(80 * scale, yScan), Offset(180 * scale, yScan), corePaint);

    // 2. Horizontal luminous sweep
    final xSweep = (60 + (200 - 60) * progress) * scale;
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00FFCC).withValues(alpha: 0.35),
          Colors.white.withValues(alpha: 0.75),
          const Color(0xFF00FFCC).withValues(alpha: 0.35),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(xSweep - 25 * scale, 105 * scale, 50 * scale, 21 * scale))
      ..blendMode = BlendMode.screen;

    canvas.drawRect(Rect.fromLTWH(xSweep - 25 * scale, 105 * scale, 50 * scale, 21 * scale), sweepPaint);

    canvas.restore();
  }

  void _paintClassicGlassesEffect(Canvas canvas, Size size, double scale) {
    final Path lensClipPath = Path();

    final isRound = glassesStyle == 'roundWire' || glassesStyle == 'roundShades' || glassesStyle == 'round';
    final isAviator = glassesStyle == 'aviator';

    if (isRound) {
      lensClipPath.addOval(Rect.fromCircle(center: Offset(106 * scale, 116 * scale), radius: 15.5 * scale));
      lensClipPath.addOval(Rect.fromCircle(center: Offset(154 * scale, 116 * scale), radius: 15.5 * scale));
    } else if (isAviator) {
      lensClipPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(106 * scale, 117 * scale), width: 34 * scale, height: 22 * scale),
        Radius.circular(10 * scale),
      ));
      lensClipPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(154 * scale, 117 * scale), width: 34 * scale, height: 22 * scale),
        Radius.circular(10 * scale),
      ));
    } else {
      lensClipPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(106 * scale, 116 * scale), width: 34 * scale, height: 22 * scale),
        Radius.circular(4 * scale),
      ));
      lensClipPath.addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(154 * scale, 116 * scale), width: 34 * scale, height: 22 * scale),
        Radius.circular(4 * scale),
      ));
    }

    // 1. Diagonal Lens Glare Sheen Sweep across both lenses
    canvas.save();
    canvas.clipPath(lensClipPath);

    final sweepProgress = (progress / 0.82).clamp(0.0, 1.0);
    final sweepX = (70 + (190 - 70) * sweepProgress) * scale;
    final sweepWidth = 44.0 * scale;

    final glarePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(sweepX - sweepWidth / 2, 100 * scale, sweepWidth, 32 * scale))
      ..blendMode = BlendMode.screen;

    // Angled light stripe
    final beamPath = Path();
    beamPath.moveTo((sweepX - 16 * scale), 98 * scale);
    beamPath.lineTo((sweepX + 16 * scale), 98 * scale);
    beamPath.lineTo((sweepX + 6 * scale), 134 * scale);
    beamPath.lineTo((sweepX - 26 * scale), 134 * scale);
    beamPath.close();

    canvas.drawPath(beamPath, glarePaint);
    canvas.restore();

    // 2. Primary Anime Glasses Glint Sparkle Star ✨ (Left upper corner)
    if (progress >= 0.25 && progress <= 0.65) {
      final s = (progress - 0.25) / 0.40;
      final intensity = sin(s * pi);
      final glintCenter = Offset(91 * scale, 106 * scale);
      _drawSparkleStar(canvas, glintCenter, intensity, scale, s * 0.35);
    }

    // 3. Secondary Complementary Glint (Right upper corner)
    if (progress >= 0.55 && progress <= 0.90) {
      final s2 = (progress - 0.55) / 0.35;
      final intensity2 = sin(s2 * pi) * 0.85;
      final glintCenter2 = Offset(169 * scale, 106 * scale);
      _drawSparkleStar(canvas, glintCenter2, intensity2, scale, -s2 * 0.3);
    }
  }

  void _drawSparkleStar(Canvas canvas, Offset center, double intensity, double scale, double rotation) {
    if (intensity <= 0.01) return;

    final rayLen = 13.0 * scale * intensity;
    final miniLen = 5.5 * scale * intensity;
    final coreRadius = 2.4 * scale * intensity;
    final haloRadius = 7.5 * scale * intensity;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Soft glowing ambient halo
    final haloPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55 * intensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * scale);
    canvas.drawCircle(Offset.zero, haloRadius, haloPaint);

    // Vertical and Horizontal rays with sharp needle points
    final starPath = Path();
    starPath.moveTo(0, -rayLen);
    starPath.quadraticBezierTo(0.6 * scale, -coreRadius, coreRadius, 0);
    starPath.quadraticBezierTo(coreRadius, 0.6 * scale, 0, rayLen);
    starPath.quadraticBezierTo(-0.6 * scale, coreRadius, -coreRadius, 0);
    starPath.quadraticBezierTo(-coreRadius, -0.6 * scale, 0, -rayLen);
    starPath.close();

    final starCross = Path();
    starCross.moveTo(rayLen, 0);
    starCross.quadraticBezierTo(coreRadius, 0.6 * scale, 0, coreRadius);
    starCross.quadraticBezierTo(-coreRadius, 0.6 * scale, -rayLen, 0);
    starCross.quadraticBezierTo(-coreRadius, -0.6 * scale, 0, -coreRadius);
    starCross.quadraticBezierTo(coreRadius, -0.6 * scale, rayLen, 0);
    starCross.close();

    // Mini diagonal 45-deg diamond sparkles
    final diagStar = Path();
    diagStar.moveTo(miniLen * 0.7, -miniLen * 0.7);
    diagStar.lineTo(-miniLen * 0.7, miniLen * 0.7);
    diagStar.moveTo(-miniLen * 0.7, -miniLen * 0.7);
    diagStar.lineTo(miniLen * 0.7, miniLen * 0.7);

    final rayPaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.95 * intensity).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawPath(starPath, rayPaint);
    canvas.drawPath(starCross, rayPaint);

    final diagPaint = Paint()
      ..color = Colors.white.withValues(alpha: (0.75 * intensity).clamp(0.0, 1.0))
      ..strokeWidth = 1.2 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(diagStar, diagPaint);

    // Brilliant central diamond core
    final corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, coreRadius, corePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassesGlintPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glassesStyle != glassesStyle ||
        oldDelegate.glassesColorHex != glassesColorHex;
  }
}
