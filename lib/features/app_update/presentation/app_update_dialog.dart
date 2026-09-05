import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/app_update_model.dart';

class AppUpdateDialog extends StatelessWidget {
  final AppUpdateModel updateInfo;
  final bool isForceUpdate;
  final String currentVersion;

  const AppUpdateDialog({
    super.key,
    required this.updateInfo,
    required this.isForceUpdate,
    required this.currentVersion,
  });

  static Future<void> show({
    required BuildContext context,
    required AppUpdateModel updateInfo,
    required bool isForceUpdate,
    required String currentVersion,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: !isForceUpdate,
      barrierColor: Colors.black.withValues(alpha: 0.80),
      builder: (context) => AppUpdateDialog(
        updateInfo: updateInfo,
        isForceUpdate: isForceUpdate,
        currentVersion: currentVersion,
      ),
    );
  }

  Future<void> _launchUpdateUrl(BuildContext context) async {
    final uri = Uri.tryParse(updateInfo.updateUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _toBengaliDigits(String input) {
    const Map<String, String> digits = {
      '0': '০', '1': '১', '2': '২', '3': '৩', '4': '৪',
      '5': '৫', '6': '৬', '7': '৭', '8': '৮', '9': '৯'
    };
    return input.split('').map((char) => digits[char] ?? char).join();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF131B16) : Colors.white;
    final cardBorderColor = isDark ? const Color(0xFF22382C) : const Color(0xFFE2EBE5);
    final messageBoxBg = isDark ? const Color(0xFF19251E) : const Color(0xFFF2FBF6);
    final messageBoxBorder = isDark ? const Color(0xFF254131) : const Color(0xFFD6EFE1);

    const brandGreen = Color(0xFF017A47);
    const brandTeal = Color(0xFF0D9488);

    return PopScope(
      canPop: !isForceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: cardBorderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.20),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: brandGreen.withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 30,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Curved Hero Header with Glowing Rocket Illustration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF015A34),
                      Color(0xFF017A47),
                      Color(0xFF0D9488),
                    ],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Decorative Background Sparkle Dots
                    Positioned(
                      top: 4,
                      left: 30,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 24,
                      right: 40,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 50,
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),

                    // Central Glowing Rocket Shield Visual
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: const Color(0xFF34D399).withValues(alpha: 0.40),
                                blurRadius: 30,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF047857),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  '🚀',
                                  style: TextStyle(fontSize: 36),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Shimmering Version Badge Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.30),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.30),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 6),
                              Text(
                                'নতুন সংস্করণ v${_toBengaliDigits(updateInfo.latestVersion)}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                  fontFamily: 'Li Ador Noirrit',
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

              // 2. Card Body Content
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    Text(
                      updateInfo.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontFamily: 'Li Ador Noirrit',
                        letterSpacing: 0.1,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Information Box for Message
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: messageBoxBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: messageBoxBorder, width: 1.2),
                      ),
                      child: Text(
                        updateInfo.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFD1E7DD) : const Color(0xFF2D5A43),
                          fontFamily: 'Li Ador Noirrit',
                          height: 1.45,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. Primary "Update Now" Action Button with Glowing Gradient
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF00A86B),
                            brandGreen,
                            brandTeal,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: brandGreen.withValues(alpha: 0.40),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () => _launchUpdateUrl(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'এখনই আপডেট করুন',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Li Ador Noirrit',
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),

                    // Optional "Update Later" button if not force update
                    if (!isForceUpdate) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'পরে আপডেট করব',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Li Ador Noirrit',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

