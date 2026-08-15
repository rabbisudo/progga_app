import '../../../core/network/api_client.dart';
import '../domain/profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<UserData> fetchMyProfile() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return UserData.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.patch('/users/me/profile', data: data);
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<UserProfile> updateSettings(Map<String, dynamic> settings) async {
    try {
      final response = await _apiClient.dio.patch('/users/me/settings', data: settings);
      return UserProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<void> setPassword({String? oldPassword, required String newPassword}) async {
    try {
      await _apiClient.dio.patch('/users/me/password', data: {
        if (oldPassword != null && oldPassword.isNotEmpty) 'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProfileRepository(client);
});
