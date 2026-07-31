import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/question_model.dart';
import '../data/question_repository.dart';

part 'practice_notifier.freezed.dart';

@freezed
class PracticeState with _$PracticeState {
  const factory PracticeState({
    required List<QuestionModel> questions,
    String? nextCursor,
    required bool isLoading,
    required bool isLoadingMore,
    String? subjectId,
    String? chapterId,
    String? topicId,
    String? difficulty,
    String? errorMessage,
  }) = _PracticeState;
}

class PracticeNotifier extends StateNotifier<PracticeState> {
  final QuestionRepository _repository;

  PracticeNotifier(this._repository)
      : super(const PracticeState(
          questions: [],
          isLoading: false,
          isLoadingMore: false,
        ));

  void updateFilters({String? subjectId, String? chapterId, String? topicId, String? difficulty}) {
    state = state.copyWith(
      subjectId: subjectId ?? state.subjectId,
      chapterId: chapterId ?? state.chapterId,
      topicId: topicId ?? state.topicId,
      difficulty: difficulty ?? state.difficulty,
    );
    fetchFirstPage();
  }

  Future<void> fetchFirstPage() async {
    if (state.subjectId == null && state.chapterId == null && state.topicId == null) return;
    
    state = state.copyWith(isLoading: true, errorMessage: null, questions: [], nextCursor: null);

    try {
      final result = await _repository.fetchQuestions(
        subjectId: state.subjectId,
        chapterId: state.chapterId,
        topicId: state.topicId,
        difficulty: state.difficulty,
        limit: 15,
      );

      state = state.copyWith(
        isLoading: false,
        questions: result.questions,
        nextCursor: result.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.isLoadingMore || state.nextCursor == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final result = await _repository.fetchQuestions(
        subjectId: state.subjectId,
        chapterId: state.chapterId,
        topicId: state.topicId,
        difficulty: state.difficulty,
        cursor: state.nextCursor,
        limit: 15,
      );

      state = state.copyWith(
        isLoadingMore: false,
        questions: [...state.questions, ...result.questions],
        nextCursor: result.nextCursor,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, errorMessage: e.toString());
    }
  }
}

final practiceProvider = StateNotifierProvider<PracticeNotifier, PracticeState>((ref) {
  final repo = ref.watch(questionRepositoryProvider);
  return PracticeNotifier(repo);
});
