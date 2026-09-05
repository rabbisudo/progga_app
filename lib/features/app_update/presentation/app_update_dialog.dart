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
      barrierColor: Colors.black54,
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

    final bgColor = isDark ? const Color(0xFF1E2621) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C3831) : const Color(0xFFE5E7EB);
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final messageColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563);
    const primaryColor = Color(0xFF017A47);

    return PopScope(
      canPop: !isForceUpdate,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Version Pill (Simple)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'ভার্সন ${_toBengaliDigits(updateInfo.latestVersion)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF34D399) : primaryColor,
                        fontFamily: 'Li Ador Noirrit',
                      ),
                    ),
                  ),
                  if (isForceUpdate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'জরুরি আপডেট',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // Title
              Text(
                updateInfo.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  fontFamily: 'Li Ador Noirrit',
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                updateInfo.message,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.normal,
                  color: messageColor,
                  fontFamily: 'Li Ador Noirrit',
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              // Action Buttons
              Row(
                children: [
                  if (!isForceUpdate) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: messageColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'পরে',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Li Ador Noirrit',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _launchUpdateUrl(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'আপডেট করুন',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Li Ador Noirrit',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


