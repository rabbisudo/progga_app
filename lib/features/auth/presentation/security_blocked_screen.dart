import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection_plus/flutter_jailbreak_detection_plus.dart';
import 'package:safe_device/safe_device.dart';
import 'package:flutter/foundation.dart';

class SecurityBlockedScreen extends StatefulWidget {
  const SecurityBlockedScreen({super.key});

  @override
  State<SecurityBlockedScreen> createState() => _SecurityBlockedScreenState();
}

class _SecurityBlockedScreenState extends State<SecurityBlockedScreen> {
  bool _isChecking = false;

  Future<void> _performRecheck() async {
    setState(() {
      _isChecking = true;
    });

    try {
      bool isSecure = true;

      // Only enforce checks in release mode, or if debug bypass is disabled
      if (kReleaseMode) {
        final jailbroken = await FlutterJailbreakDetectionPlus.jailbroken;
        final developerMode = await FlutterJailbreakDetectionPlus.developerMode;
        final isRealDevice = await SafeDevice.isRealDevice;
        final isMockLocation = await SafeDevice.isMockLocation;

        if (jailbroken || developerMode || !isRealDevice || isMockLocation) {
          isSecure = false;
        }
      }

      if (isSecure) {
        // Exit screen by restarting or returning if it's safe
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('আপনার ডিভাইসটি এখন নিরাপদ। অনুগ্রহ করে অ্যাপটি পুনরায় চালু করুন।'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('নিরাপত্তা সতর্কতা', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text(
                'আপনার ডিভাইসটিতে এখনো নিরাপত্তা ঝুঁকি রয়েছে। দয়া করে রুট, জেলব্রেক বা ইউএসবি ডিবাগিং অপশন বন্ধ করে পুনরায় চেষ্টা করুন।'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ঠিক আছে', style: TextStyle(color: Color(0xFF017A47), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      }
    } catch (_) {
      // safe bypass
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              
              // Branded warning icon representation
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD1D1), width: 2),
                ),
                child: const Icon(
                  Icons.security_update_warning_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
              ),
              const SizedBox(height: 32),
              
              // Security Header
              const Text(
                'নিরাপত্তা সতর্কতা',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Li Ador Noirrit',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              // Error description
              const Text(
                'নিরাপত্তা জনিত কারণে রুট করা ডিভাইস, জেলব্রোকেন ডিভাইস, এমুলেটর অথবা ডেভেলপার অপশন (USB Debugging) চালু থাকা অবস্থায় এই অ্যাপ্লিকেশনটি চালানো সম্ভব নয়। অনুগ্রহ করে আপনার ডিভাইস সেটিং পরিবর্তন করে পুনরায় চেষ্টা করুন।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Li Ador Noirrit',
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 2),
              
              // Action Buttons
              if (_isChecking)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF017A47)),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _performRecheck,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF017A47),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'পুনরায় পরীক্ষা করুন',
                      style: TextStyle(
                        fontFamily: 'Li Ador Noirrit',
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    if (Platform.isAndroid) {
                      SystemNavigator.pop();
                    } else if (Platform.isIOS) {
                      exit(0);
                    }
                  },
                  child: const Text(
                    'অ্যাপ বন্ধ করুন',
                    style: TextStyle(
                      fontFamily: 'Li Ador Noirrit',
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
