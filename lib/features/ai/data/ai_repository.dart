import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class AiRepository {
  final ApiClient _apiClient;

  AiRepository(this._apiClient);

  Future<Map<String, dynamic>> fetchTokenStatus() async {
    try {
      final response = await _apiClient.dio.get('/ai/token-status');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<List<dynamic>> fetchHistory() async {
    try {
      final response = await _apiClient.dio.get('/ai/history');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }

  Future<Map<String, dynamic>> solveDoubt({
    required String subject,
    String? prompt,
    String? imagePath,
    String? historyJson,
  }) async {
    try {
      final formData = FormData.fromMap({
        'subject': subject,
        if (prompt != null && prompt.trim().isNotEmpty) 'prompt': prompt.trim(),
        if (historyJson != null && historyJson.isNotEmpty) 'history': historyJson,
        if (imagePath != null && imagePath.isNotEmpty)
          'image': await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split('/').last,
          ),
      });

      final response = await _apiClient.dio.post(
        '/ai/solve-doubt',
        data: formData,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _apiClient.handleError(e);
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return AiRepository(client);
});

final aiTokenStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(aiRepositoryProvider);
  return repo.fetchTokenStatus();
});
