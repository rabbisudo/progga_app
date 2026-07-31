import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../domain/profile_model.dart';

class ProfileNotifier extends AsyncNotifier<UserData> {
  @override
  FutureOr<UserData> build() async {
    final repository = ref.read(profileRepositoryProvider);
    return repository.fetchMyProfile();
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final repository = ref.read(profileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedProfile = await repository.updateSettings(settings);
      final currentData = state.value!;
      return currentData.copyWith(profile: updatedProfile);
    });
  }

  Future<void> updateProfileDetails(Map<String, dynamic> data) async {
    final repository = ref.read(profileRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedProfile = await repository.updateProfile(data);
      final currentData = state.value!;
      return currentData.copyWith(profile: updatedProfile);
    });
  }
}

final userProfileProvider = AsyncNotifierProvider<ProfileNotifier, UserData>(() {
  return ProfileNotifier();
});
