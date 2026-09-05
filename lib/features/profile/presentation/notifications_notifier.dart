import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/user_notification_model.dart';

class NotificationsNotifier extends StateNotifier<AsyncValue<List<UserNotificationModel>>> {
  final ApiClient _apiClient;

  NotificationsNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications({bool isRefresh = false}) async {
    if (!isRefresh && state is! AsyncLoading) {
      state = const AsyncValue.loading();
    }

    try {
      final response = await _apiClient.dio.get('/notifications/my');
      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .map((item) => UserNotificationModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
        state = AsyncValue.data(list);
      } else {
        state = const AsyncValue.data([]);
      }
    } catch (e, stack) {
      // If error occurs, keep existing data if available or set error
      state.when(
        data: (existing) => state = AsyncValue.data(existing),
        loading: () => state = AsyncValue.error(e, stack),
        error: (_, __) => state = AsyncValue.error(e, stack),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((item) {
      if (item.id == notificationId) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    state = AsyncValue.data(updatedList);

    try {
      await _apiClient.dio.post('/notifications/$notificationId/read');
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    final currentList = state.value ?? [];
    final updatedList = currentList.map((item) => item.copyWith(isRead: true)).toList();

    state = AsyncValue.data(updatedList);

    try {
      await _apiClient.dio.post('/notifications/read-all');
    } catch (_) {}
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, AsyncValue<List<UserNotificationModel>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsNotifier(apiClient);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});
