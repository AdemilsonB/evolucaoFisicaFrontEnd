import '../../features/admin/data/repositories/admin_repository.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/dashboard/data/repositories/dashboard_repository.dart';
import '../../features/onboarding/data/repositories/onboarding_repository.dart';
import '../network/api_client.dart';
import '../storage/auth_token_storage.dart';

class AppDependencies {
  AppDependencies._({
    required this.tokenStorage,
    required this.apiClient,
    required this.authRepository,
    required this.adminRepository,
    required this.onboardingRepository,
    required this.dashboardRepository,
  });

  final AuthTokenStorage tokenStorage;
  final ApiClient apiClient;
  final AuthRepository authRepository;
  final AdminRepository adminRepository;
  final OnboardingRepository onboardingRepository;
  final DashboardRepository dashboardRepository;

  static Future<AppDependencies> bootstrap() async {
    final tokenStorage = await AuthTokenStorage.create();
    final session = await tokenStorage.loadSession();
    final apiClient = ApiClient(tokenStorage);
    final authRepository = AuthRepository(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
      initialSession: session,
    );

    return AppDependencies._(
      tokenStorage: tokenStorage,
      apiClient: apiClient,
      authRepository: authRepository,
      adminRepository: AdminRepository(apiClient: apiClient),
      onboardingRepository: OnboardingRepository(apiClient: apiClient),
      dashboardRepository: DashboardRepository(apiClient: apiClient),
    );
  }
}
