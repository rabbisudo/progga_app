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
    final currentData = state.value;
    state = AsyncLoading<UserData>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final updatedProfile = await repository.updateSettings(settings);
      if (currentData == null) {
        return repository.fetchMyProfile();
      }
      return currentData.copyWith(profile: updatedProfile);
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> updateProfileDetails(Map<String, dynamic> data) async {
    final repository = ref.read(profileRepositoryProvider);
    final currentData = state.value;
    state = AsyncLoading<UserData>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final updatedProfile = await repository.updateProfile(data);
      if (currentData == null) {
        return repository.fetchMyProfile();
      }
      return currentData.copyWith(profile: updatedProfile);
    });
    if (state.hasError) {
      throw state.error!;
    }
  }
}

final userProfileProvider = AsyncNotifierProvider<ProfileNotifier, UserData>(() {
  return ProfileNotifier();
});
