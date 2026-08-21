import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_service.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/personal_info_screen.dart';
import '../../features/profile/presentation/my_reports_screen.dart';
import '../../features/profile/presentation/streak_screen.dart';
import '../../features/profile/presentation/avatar_editor_screen.dart';
import '../../features/profile/presentation/notifications_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/question/presentation/practice_dashboard_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';

import '../../features/exam/presentation/exam_screen.dart';
import '../../features/exam/presentation/qb_question_preview_screen.dart';
import '../../features/result/presentation/result_screen.dart';
import '../../features/leaderboard/presentation/leaderboard_screen.dart';
import '../../features/question/presentation/topic_selection_screen.dart';
import '../../features/question/presentation/exam_confirm_screen.dart';
import '../../features/question/presentation/views/qb/qb_sub_series_screen.dart';
import '../../features/question/presentation/views/qb/qb_exams_list_screen.dart';
import '../../features/question/presentation/views/qb/qb_section_series_screen.dart';
import '../../features/ai/presentation/progga_ai_screen.dart';
import '../../features/profile/presentation/exam_history_screen.dart';
import '../../features/profile/presentation/bookmarked_questions_screen.dart';

class RouterTransitionNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterTransitionNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      final prevAuth = previous?.maybeWhen(authenticated: (_, __) => true, orElse: () => false) ?? false;
      final nextAuth = next.maybeWhen(authenticated: (_, __) => true, orElse: () => false);
      if (prevAuth != nextAuth) {
        notifyListeners();
      }
    });
  }
}

final initialLocationProvider = Provider<String>((ref) => '/login');

final routerProvider = Provider<GoRouter>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final notifier = RouterTransitionNotifier(ref);
  final initialLocation = ref.watch(initialLocationProvider);

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isLoggingIn = state.matchedLocation == '/login';

      final isAuthenticated = authState.maybeWhen(
        authenticated: (_, __) => true,
        orElse: () => false,
      );

      if (!isAuthenticated) {
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
        path: '/avatar-editor',
        builder: (context, state) => const AvatarEditorScreen(),
      ),

      GoRoute(
        path: '/my-reports',
        builder: (context, state) => const MyReportsScreen(),
      ),
      GoRoute(
        path: '/bookmarked-questions',
        builder: (context, state) => const BookmarkedQuestionsScreen(),
      ),
      GoRoute(
        path: '/streak',
        builder: (context, state) => const StreakScreen(),
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
        path: '/qb-sub-series/:seriesId',
        builder: (context, state) {
          final seriesId = state.pathParameters['seriesId'] ?? '';
          final seriesName = state.extra as String?;
          return QbSubSeriesScreen(seriesId: seriesId, seriesName: seriesName);
        },
      ),
      GoRoute(
        path: '/qb-section/:sectionId',
        builder: (context, state) {
          final sectionId = state.pathParameters['sectionId'] ?? '';
          final sectionName = state.extra as String?;
          return QbSectionSeriesScreen(sectionId: sectionId, sectionName: sectionName);
        },
      ),
      GoRoute(
        path: '/qb-exams/:subSeriesId',
        builder: (context, state) {
          final subSeriesId = state.pathParameters['subSeriesId'] ?? '';
          final subSeriesName = state.extra as String?;
          return QbExamsListScreen(subSeriesId: subSeriesId, subSeriesName: subSeriesName);
        },
      ),
      GoRoute(
        path: '/exam/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final qParams = state.uri.queryParameters;
          final quesStandardParam = qParams['quesStandard'];
          final quesStandardList = (quesStandardParam != null && quesStandardParam.isNotEmpty)
              ? quesStandardParam.split(',').map((s) => s.trim()).toList()
              : null;
          return ExamScreen(
            id: id,
            subjectId: qParams['subjectId'],
            chapterId: qParams['chapterId'],
            topicId: qParams['topicId'],
            limit: int.tryParse(qParams['limit'] ?? ''),
            timeMinutes: int.tryParse(qParams['time'] ?? ''),
            questionType: qParams['questionType'],
            quesStandard: quesStandardList,
          );
        },
      ),
      GoRoute(
        path: '/exam-preview/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final title = state.extra as String?;
          return QbQuestionPreviewScreen(
            examId: id,
            title: title,
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
        path: '/progga-ai',
        builder: (context, state) => const ProggaAiScreen(),
      ),
      GoRoute(
        path: '/exam-history',
        builder: (context, state) => const ExamHistoryScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
    ],
  );
});
