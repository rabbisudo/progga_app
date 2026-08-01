import 'dart:async';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/exam_model.dart';
import '../domain/user_exam_model.dart';
import '../data/exam_repository.dart';

part 'exam_runner_notifier.freezed.dart';

@freezed
class ExamRunnerState with _$ExamRunnerState {
  const factory ExamRunnerState({
    ExamModel? exam,
    String? sessionId,
    required int timeLeft,
    required Map<String, String?> selectedOptions,
    required Map<String, bool> markedForReview,
    required Map<String, int> timeSpent,
    required bool isLoading,
    required bool isSaving,
    required bool isSubmitting,
    UserExamModel? result,
    String? errorMessage,
  }) = _ExamRunnerState;
}

class ExamRunnerNotifier extends StateNotifier<ExamRunnerState> {
  final ExamRepository _repository;
  Timer? _timer;
  Timer? _autoSaveTimer;

  ExamRunnerNotifier(this._repository)
      : super(const ExamRunnerState(
          timeLeft: 0,
          selectedOptions: {},
          markedForReview: {},
          timeSpent: {},
          isLoading: false,
          isSaving: false,
          isSubmitting: false,
        ));

  @override
  void dispose() {
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /**
   * Initializes exam templates and allocates attempt session IDs.
   */
  Future<void> initializeExam(
    String examId, {
    String? subjectId,
    String? chapterId,
    String? topicId,
    int? limit,
    int? timeMinutes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, result: null);
    _timer?.cancel();
    _autoSaveTimer?.cancel();

    try {
      ExamModel exam;
      UserExamModel attempt;

      // Check if filter parameters are provided for custom exam generation
      if ((subjectId != null && subjectId.isNotEmpty) ||
          (chapterId != null && chapterId.isNotEmpty) ||
          (topicId != null && topicId.isNotEmpty) ||
          (limit != null && limit > 0)) {
        attempt = await _repository.startCustomExam(
          subjectId: subjectId ?? (examId.isNotEmpty ? examId : null),
          chapterId: chapterId,
          topicId: topicId,
          limit: limit,
          timeMinutes: timeMinutes,
        );
        exam = await _repository.fetchExamDetails(attempt.examId);
      } else {
        exam = await _repository.fetchExamDetails(examId);
        attempt = await _repository.startExam(examId);
      }

      state = ExamRunnerState(
        exam: exam,
        sessionId: attempt.id,
        timeLeft: exam.duration,
        selectedOptions: {},
        markedForReview: {},
        timeSpent: {},
        isLoading: false,
        isSaving: false,
        isSubmitting: false,
      );

      // Start countdown clock
      _startTimer();
      // Start periodic 15s auto-save syncs
      _startAutoSaveTimer();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeLeft <= 1) {
        timer.cancel();
        submitExam();
      } else {
        state = state.copyWith(timeLeft: state.timeLeft - 1);
      }
    });
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      autoSaveProgress();
    });
  }

  void selectOption(String questionId, String? optionId) {
    // Once selected, selection gets locked and cannot be changed
    if (state.selectedOptions[questionId] != null) return;

    final updatedOptions = Map<String, String?>.from(state.selectedOptions);
    updatedOptions[questionId] = optionId;
    state = state.copyWith(selectedOptions: updatedOptions);
  }

  void toggleMarkedForReview(String questionId) {
    final updatedReview = Map<String, bool>.from(state.markedForReview);
    final current = updatedReview[questionId] ?? false;
    updatedReview[questionId] = !current;
    state = state.copyWith(markedForReview: updatedReview);
  }

  void incrementTimeSpent(String questionId) {
    final updatedTime = Map<String, int>.from(state.timeSpent);
    final current = updatedTime[questionId] ?? 0;
    updatedTime[questionId] = current + 1;
    state = state.copyWith(timeSpent: updatedTime);
  }

  /**
   * Dispatches debounced active answer sheet details to the server.
   */
  Future<void> autoSaveProgress() async {
    if (state.sessionId == null || state.isSaving || state.isSubmitting) return;

    state = state.copyWith(isSaving: true);
    try {
      final answersPayload = _buildAnswersPayload();
      await _repository.saveProgress(state.sessionId!, answersPayload);
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false);
    }
  }

  /**
   * Submits sheet, cancels tickers, and calculates results.
   */
  Future<UserExamModel?> submitExam() async {
    if (state.sessionId == null || state.isSubmitting) return null;

    _timer?.cancel();
    _autoSaveTimer?.cancel();
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      // Final flush save before submit
      final answersPayload = _buildAnswersPayload();
      await _repository.saveProgress(state.sessionId!, answersPayload);

      final result = await _repository.submitExam(state.sessionId!);
      state = state.copyWith(isSubmitting: false, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
      return null;
    }
  }

  List<Map<String, dynamic>> _buildAnswersPayload() {
    final List<Map<String, dynamic>> list = [];
    if (state.exam == null) return list;

    for (final eq in state.exam!.questions) {
      final qId = eq.question.id;
      list.push({
        'questionId': qId,
        'selectedOptionId': state.selectedOptions[qId] ?? null,
        'markedForReview': state.markedForReview[qId] ?? false,
        'timeSpent': state.timeSpent[qId] ?? 0,
      });
    }
    return list;
  }
}

// Extends lists helper values
extension ListPush on List {
  void push(dynamic val) => add(val);
}

final examRunnerProvider = StateNotifierProvider<ExamRunnerNotifier, ExamRunnerState>((ref) {
  final repo = ref.watch(examRepositoryProvider);
  return ExamRunnerNotifier(repo);
});
