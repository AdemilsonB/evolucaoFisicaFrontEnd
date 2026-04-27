import '../../../../core/constants/api_paths.dart';
import '../../../../core/network/api_client.dart';
import '../models/onboarding_models.dart';

class OnboardingRepository {
  OnboardingRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<OnboardingResult> concluir({
    required int usuarioId,
    required OnboardingPayload payload,
  }) async {
    final response = await _apiClient.postMap(
      ApiPaths.onboarding(usuarioId),
      data: payload.toJson(),
    );
    return OnboardingResult.fromJson(response);
  }
}
