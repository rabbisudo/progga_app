import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/profile_repository.dart';
import '../domain/profile_model.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../../core/storage/hive_service.dart';

class ProfileNotifier extends AsyncNotifier<UserData> {
  @override
  FutureOr<UserData> build() {
    final repository = ref.read(profileRepositoryProvider);
    final authState = ref.watch(authProvider);

    UserData? initialUser;

    authState.maybeWhen(
      authenticated: (user, token) {
        if (user.isNotEmpty) {
          try {
            initialUser = UserData.fromJson(user);
          } catch (_) {}
        }
      },
      orElse: () {},
    );

    initialUser ??= _loadCachedProfile();

    // Trigger silent background synchronization automatically
    _fetchFreshProfileSilently(repository);

    // Return instant local/cached or fallback data synchronously
    return initialUser ?? const UserData(
      id: '',
      email: '',
      username: '',
      isActive: true,
      createdAt: '',
    );
  }

  void _fetchFreshProfileSilently(ProfileRepository repository) {
    repository.fetchMyProfile().then((fresh) {
      _cacheProfile(_toMap(fresh));
      ref.read(authProvider.notifier).updateUserData(_toMap(fresh));
      state = AsyncData(fresh);
    }).catchError((_) {
      // Silently ignore background network errors without disturbing local UI
    });
  }

  /// Manually refresh profile from backend (e.g. pull-to-refresh)
  Future<void> refreshProfile() async {
    final repository = ref.read(profileRepositoryProvider);
    try {
      final fresh = await repository.fetchMyProfile();
      _cacheProfile(_toMap(fresh));
      ref.read(authProvider.notifier).updateUserData(_toMap(fresh));
      state = AsyncData(fresh);
    } catch (_) {}
  }

  void _cacheProfile(Map<String, dynamic> json) {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      hiveService.getSettingsBox().put('cached_user_profile', json);
    } catch (e) {
      // safe bypass
    }
  }

  Map<String, dynamic> _toMap(UserData data) {
    return {
      ...data.toJson(),
      'profile': data.profile?.toJson(),
    };
  }

  UserData? _loadCachedProfile() {
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final json = hiveService.getSettingsBox().get('cached_user_profile');
      if (json != null && json is Map) {
        return UserData.fromJson(_recursivelyCastMap(json));
      }
    } catch (e) {
      // safe bypass
    }
    return null;
  }

  Map<String, dynamic> _recursivelyCastMap(Map<dynamic, dynamic> source) {
    return source.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _recursivelyCastMap(value));
      } else if (value is List) {
        return MapEntry(
          key.toString(),
          value.map((item) {
            if (item is Map) {
              return _recursivelyCastMap(item);
            }
            return item;
          }).toList(),
        );
      }
      return MapEntry(key.toString(), value);
    });
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final repository = ref.read(profileRepositoryProvider);
    final currentData = state.value;
    state = const AsyncLoading<UserData>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final updatedProfile = await repository.updateSettings(settings);
      final data = currentData == null
          ? await repository.fetchMyProfile()
          : currentData.copyWith(profile: updatedProfile);
      _cacheProfile(_toMap(data));
      ref.read(authProvider.notifier).updateUserData(_toMap(data));
      return data;
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> updateProfileDetails(Map<String, dynamic> data) async {
    final repository = ref.read(profileRepositoryProvider);
    final currentData = state.value;
    state = const AsyncLoading<UserData>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final updatedProfile = await repository.updateProfile(data);
      final resData = currentData == null
          ? await repository.fetchMyProfile()
          : currentData.copyWith(profile: updatedProfile);
      _cacheProfile(_toMap(resData));
      ref.read(authProvider.notifier).updateUserData(_toMap(resData));
      return resData;
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> setPassword({String? oldPassword, required String newPassword}) async {
    final repository = ref.read(profileRepositoryProvider);
    state = const AsyncLoading<UserData>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await repository.setPassword(oldPassword: oldPassword, newPassword: newPassword);
      
      // Fetch latest profile state so cached_user_profile is updated with the password field set
      final data = await repository.fetchMyProfile();
      _cacheProfile(_toMap(data));
      ref.read(authProvider.notifier).updateUserData(_toMap(data));
      return data;
    });
    if (state.hasError) {
      throw state.error!;
    }
  }
}

final userProfileProvider = AsyncNotifierProvider<ProfileNotifier, UserData>(() {
  return ProfileNotifier();
});
