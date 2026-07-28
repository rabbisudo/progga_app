import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../domain/profile_model.dart';

class ProfileNotifier extends AsyncNotifier<UserData> {
  late final ProfileRepository _repository;

  @override
  FutureOr<UserData> build() async {
    _repository = ref.watch(profileRepositoryProvider);
    return _repository.fetchMyProfile();
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedProfile = await _repository.updateSettings(settings);
      final currentData = state.value!;
      return currentData.copyWith(profile: updatedProfile);
    });
  }

  Future<void> updateProfileDetails(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final updatedProfile = await _repository.updateProfile(data);
      final currentData = state.value!;
      return currentData.copyWith(profile: updatedProfile);
    });
  }
}

final userProfileProvider = AsyncNotifierProvider<ProfileNotifier, UserData>(() {
  return ProfileNotifier();
});
