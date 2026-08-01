import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/personal_info_screen.dart';
import '../../features/question/presentation/practice_dashboard_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';

import '../../features/exam/presentation/exam_screen.dart';
import '../../features/result/presentation/result_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/premium/presentation/premium_screen.dart';
import '../../features/question/presentation/topic_selection_screen.dart';
import '../../features/question/presentation/exam_confirm_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final token = await secureStorage.getAccessToken();
      final isLoggingIn = state.matchedLocation == '/login';

      if (token == null) {
        // Force redirect to login if attempting protected dashboards
        return isLoggingIn ? null : '/login';
      }

      // Force forward from login if already authenticated
      if (isLoggingIn) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const PracticeDashboardScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/personal-info',
        builder: (context, state) => const PersonalInfoScreen(),
      ),
      GoRoute(
        path: '/topic-selection/:subjectId',
        builder: (context, state) {
          final subjectId = state.pathParameters['subjectId'] ?? '';
          final subjectName = state.extra as String?;
          return TopicSelectionScreen(subjectId: subjectId, subjectName: subjectName);
        },
      ),
      GoRoute(
        path: '/exam-confirm',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ExamConfirmScreen(setupData: extra);
        },
      ),
      GoRoute(
        path: '/exam/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final qParams = state.uri.queryParameters;
          return ExamScreen(
            id: id,
            subjectId: qParams['subjectId'],
            chapterId: qParams['chapterId'],
            topicId: qParams['topicId'],
            limit: int.tryParse(qParams['limit'] ?? ''),
            timeMinutes: int.tryParse(qParams['time'] ?? ''),
          );
        },
      ),
      GoRoute(
        path: '/result/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          return ResultScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) => const PremiumScreen(),
      ),
    ],
  );
});
