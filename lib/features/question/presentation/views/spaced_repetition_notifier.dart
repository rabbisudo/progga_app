import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_service.dart';
import '../../data/question_repository.dart';

class SpacedRepetitionNotifier extends AsyncNotifier<List<dynamic>> {
  @override
  FutureOr<List<dynamic>> build() async {
    final hiveService = ref.read(hiveServiceProvider);
    final cached = hiveService.getCachedList('spaced_repetition_pending');
    
    // Asynchronously fetch from server and update cache
    _fetchFresh();
    
    return cached ?? [];
  }

  Future<void> _fetchFresh() async {
    try {
      final repository = ref.read(questionRepositoryProvider);
      final fresh = await repository.fetchPendingSpacedRepetition();
      
      final hiveService = ref.read(hiveServiceProvider);
      await hiveService.cacheList('spaced_repetition_pending', fresh);
      
      state = AsyncValue.data(fresh);
    } catch (e, stackTrace) {
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<void> submitAttempt({
    String? questionId,
    String? qbQuestionId,
    required bool isCorrect,
  }) async {
    final currentList = state.value ?? [];
    
    // Immediately remove the answered card from the active list for instant local feedback
    final updatedList = currentList.where((card) {
      final q = card['question'];
      if (q == null) return true;
      final qId = q['id'];
      if (questionId != null && qId == questionId) return false;
      if (qbQuestionId != null && qId == qbQuestionId) return false;
      return true;
    }).toList();

    state = AsyncValue.data(updatedList);
    
    final hiveService = ref.read(hiveServiceProvider);
    await hiveService.cacheList('spaced_repetition_pending', updatedList);

    // Call server API in background to save attempt
    try {
      final repository = ref.read(questionRepositoryProvider);
      await repository.submitSpacedRepetitionAttempt(
        questionId: questionId,
        qbQuestionId: qbQuestionId,
        isCorrect: isCorrect,
      );
    } catch (_) {
      // Offline fallback: update local scheduling if API fails
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    await _fetchFresh();
  }
}

final spacedRepetitionProvider = AsyncNotifierProvider<SpacedRepetitionNotifier, List<dynamic>>(() {
  return SpacedRepetitionNotifier();
});
