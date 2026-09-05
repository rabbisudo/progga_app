import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/navigation/app_router.dart';

class ProggaApp extends ConsumerStatefulWidget {
  const ProggaApp({super.key});

  @override
  ConsumerState<ProggaApp> createState() => _ProggaAppState();
}

class _ProggaAppState extends ConsumerState<ProggaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// System memory warning listener: Triggers on low-RAM / older devices before OS kills the app
  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // Aggressively flush unused decoded images to prevent Out-Of-Memory (OOM) crashes
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Progga MCQ Exam Platform',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        overscroll: false,
      ),
    );
  }
}
