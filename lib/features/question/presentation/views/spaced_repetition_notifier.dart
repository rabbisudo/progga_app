import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/hive_service.dart';
import '../../data/question_repository.dart';

class SpacedRepetitionNotifier extends AsyncNotifier<List<dynamic>> {
  final Set<String> _answeredQuestionIds = {};

  static bool _isOnlyMcq(dynamic card) {
    if (card == null || card is! Map) return false;
    final q = card['question'];
    if (q == null || q is! Map) return false;
    final type = (q['type'] as String? ?? 'MCQ').trim().toUpperCase();
    final options = q['options'];
    return type == 'MCQ' && options is List && options.length >= 2;
  }

  bool _isValidAndUnanswered(dynamic card) {
    if (!_isOnlyMcq(card)) return false;
    final q = card['question'];
    final qId = q?['id']?.toString();
    if (qId != null && _answeredQuestionIds.contains(qId)) {
      return false;
    }
    return true;
  }

  @override
  FutureOr<List<dynamic>> build() async {
    final hiveService = ref.read(hiveServiceProvider);
    final cached = hiveService.getCachedList('spaced_repetition_pending');
    final filteredCached = (cached ?? []).where(_isValidAndUnanswered).toList();
    
    // Asynchronously revalidate in background without blocking initial cached render
    _fetchFresh();
    
    return filteredCached;
  }

  Future<void> _fetchFresh() async {
    try {
      final repository = ref.read(questionRepositoryProvider);
      final fresh = await repository.fetchPendingSpacedRepetition();
      final filteredFresh = fresh.where(_isValidAndUnanswered).toList();
      
      final hiveService = ref.read(hiveServiceProvider);

      // If server returned active cards, persist to cache & update state
      if (filteredFresh.isNotEmpty) {
        await hiveService.cacheList('spaced_repetition_pending', filteredFresh);
        state = AsyncValue.data(filteredFresh);
      } else {
        // If server returns empty list (no new review due), check if local cache has unanswered cards.
        // Retain cached cards so pulling down to reload never wipes them away!
        final cached = hiveService.getCachedList('spaced_repetition_pending');
        final filteredCached = (cached ?? []).where(_isValidAndUnanswered).toList();
        if (filteredCached.isNotEmpty) {
          state = AsyncValue.data(filteredCached);
        } else {
          state = const AsyncValue.data([]);
        }
      }
    } catch (e, stackTrace) {
      final hiveService = ref.read(hiveServiceProvider);
      final cached = hiveService.getCachedList('spaced_repetition_pending');
      final filteredCached = (cached ?? []).where(_isValidAndUnanswered).toList();
      if (filteredCached.isNotEmpty) {
        state = AsyncValue.data(filteredCached);
      } else if (state.value == null || state.value!.isEmpty) {
        state = AsyncValue.error(e, stackTrace);
      }
    }
  }

  Future<void> submitAttempt({
    String? questionId,
    String? qbQuestionId,
    required bool isCorrect,
  }) async {
    if (questionId != null) _answeredQuestionIds.add(questionId);
    if (qbQuestionId != null) _answeredQuestionIds.add(qbQuestionId);

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
    // Keep existing cached state intact - DO NOT set AsyncLoading() so card stays visible without flicker!
    await _fetchFresh();
  }
}

final spacedRepetitionProvider = AsyncNotifierProvider<SpacedRepetitionNotifier, List<dynamic>>(() {
  return SpacedRepetitionNotifier();
});
