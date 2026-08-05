import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BannerSliderWidget extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  const BannerSliderWidget({super.key, required this.banners});

  @override
  State<BannerSliderWidget> createState() => _BannerSliderWidgetState();
}

class _BannerSliderWidgetState extends State<BannerSliderWidget> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _startAutoTimer();
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    if (widget.banners.length > 1) {
      _autoTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_pageController.hasClients && widget.banners.isNotEmpty) {
          final nextPage = (_currentIndex + 1) % widget.banners.length;
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.banners.length,
              itemBuilder: (context, index) {
                final banner = widget.banners[index];
                final String title = banner['title'] ?? '';
                final String badgeText = banner['badgeText'] ?? 'OFFER';
                final String? imageUrl = banner['imageUrl'];
                final String? rawTargetUrl = banner['targetUrl'];
                final bool isClickable = rawTargetUrl != null &&
                    rawTargetUrl.isNotEmpty &&
                    rawTargetUrl.trim() != '#' &&
                    rawTargetUrl.trim() != 'javascript:void(0)';
                final String targetUrl = isClickable ? rawTargetUrl.trim() : '';

                final List<Color> gradientColors = banner['colors'] ?? [const Color(0xFF004D40), const Color(0xFF00796B)];
                final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: GestureDetector(
                    onTap: isClickable
                        ? () {
                            if (targetUrl.startsWith('/')) {
                               context.push(targetUrl);
                            }
                          }
                        : null,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        gradient: !hasImage
                            ? LinearGradient(
                                colors: gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        image: hasImage
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: hasImage
                          ? const SizedBox.expand()
                          : Padding(
                              padding: const EdgeInsets.all(18),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFD9746E), Color(0xFFF18881)],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            height: 1.25,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ElevatedButton(
                                          onPressed: isClickable
                                              ? () {
                                                  if (targetUrl.startsWith('/')) {
                                                    context.push(targetUrl);
                                                  }
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            elevation: 0,
                                            minimumSize: const Size(0, 30),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Get now',
                                            style: TextStyle(
                                              color: Color(0xFF004D40),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                                    ),
                                    child: Center(
                                      child: Text(banner['icon'] ?? '🦖', style: const TextStyle(fontSize: 38)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),

            // Premium Floating Indicator Capsule Overlay
            if (widget.banners.length > 1)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        widget.banners.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentIndex == i ? 16 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _currentIndex == i
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
