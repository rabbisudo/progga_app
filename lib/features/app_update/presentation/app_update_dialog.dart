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
      barrierColor: Colors.black.withValues(alpha: 0.75),
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

    final bgColor = isDark ? const Color(0xFF141A17) : Colors.white;
    final borderColor = isDark ? const Color(0xFF233228) : const Color(0xFFE2EBE5);
    const brandGreen = Color(0xFF017A47);
    const brandTeal = Color(0xFF0D9488);

    return PopScope(
      canPop: !isForceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top 3D / Gradient Rocket Icon with Glow
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [brandGreen, brandTeal],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: brandGreen.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🚀',
                      style: TextStyle(fontSize: 34),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Version Badge Pill
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: brandGreen.withValues(alpha: isDark ? 0.20 : 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: brandGreen.withValues(alpha: isDark ? 0.40 : 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF34D399) : brandGreen,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'ভার্সন ${_toBengaliDigits(updateInfo.latestVersion)} উপলব্ধ',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFF34D399) : brandGreen,
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                updateInfo.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontFamily: 'Li Ador Noirrit',
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 6),

              // Subtitle / Description Message
              Text(
                updateInfo.message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  fontFamily: 'Li Ador Noirrit',
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 22),

              // Primary "Update Now" Action Button
              ElevatedButton(
                onPressed: () => _launchUpdateUrl(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'এখনই আপডেট করুন',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
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
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Li Ador Noirrit',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
