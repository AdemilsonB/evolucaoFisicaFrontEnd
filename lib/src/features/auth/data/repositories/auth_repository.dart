import '../../../../core/constants/api_paths.dart';
import '../../../../core/models/app_user.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/auth_token_storage.dart';
import '../models/auth_session.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required AuthTokenStorage tokenStorage,
    AuthSession? initialSession,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage,
        _currentSession = initialSession;

  final ApiClient _apiClient;
  final AuthTokenStorage _tokenStorage;

  AuthSession? _currentSession;

  AuthSession? get currentSession => _currentSession;

  bool get hasSession => _currentSession != null;

  Future<AuthSession> loginLocal({
    required String email,
    required String senha,
  }) async {
    final response = await _apiClient.postMap(
      ApiPaths.authLogin,
      data: {
        'email': email,
        'senha': senha,
      },
    );

    final session = AuthSession.fromJson(response);
    await _tokenStorage.saveSession(session);
    _currentSession = session;
    return session;
  }

  Future<AuthSession> cadastrarLocal({
    required String nome,
    required String email,
    required String senha,
    required String username,
  }) async {
    final response = await _apiClient.postMap(
      ApiPaths.authCadastro,
      data: {
        'nome': nome,
        'email': email,
        'senha': senha,
        'username': username,
      },
    );

    final session = AuthSession.fromJson(response);
    await _tokenStorage.saveSession(session);
    _currentSession = session;
    return session;
  }

  Future<AuthSession> loginGoogle(String idToken) async {
    final response = await _apiClient.postMap(
      ApiPaths.authGoogle,
      data: {
        'idToken': idToken,
      },
    );

    final session = AuthSession.fromJson(response);
    await _tokenStorage.saveSession(session);
    _currentSession = session;
    return session;
  }

  Future<void> updateCurrentUser(
    AppUser user, {
    bool? onboardingPendente,
  }) async {
    final session = _currentSession;
    if (session == null) {
      return;
    }

    final updatedSession = session.copyWith(
      user: user,
      onboardingPendente: onboardingPendente,
    );
    _currentSession = updatedSession;
    await _tokenStorage.saveSession(updatedSession);
  }

  Future<void> logout() async {
    _currentSession = null;
    await _tokenStorage.clear();
  }
}
