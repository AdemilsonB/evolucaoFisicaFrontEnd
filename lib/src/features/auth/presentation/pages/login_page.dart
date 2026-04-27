import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/app_scope.dart';
import '../../data/models/auth_session.dart';
import '../controllers/login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  LoginController? _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    _controller = LoginController(AppScope.of(context).authRepository);
    _initialized = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = AppScope.of(context).authRepository.currentSession;
      if (session != null && mounted) {
        _navigateAfterLogin(session);
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final session = await _controller?.submit();
    if (!mounted || session == null) {
      return;
    }
    _navigateAfterLogin(session);
  }

  void _navigateAfterLogin(AuthSession session) {
    final route = session.onboardingPendente ? AppRouter.onboarding : AppRouter.home;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Evolucao Fisica',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Base pronta para autenticar com o back-end Spring Boot e seguir para onboarding, treino, alimentacao e gamificacao.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'usuario@dominio.com',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller.senhaController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (controller.erro != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            controller.erro!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: controller.carregando ? null : _handleSubmit,
                        child: Text(
                          controller.carregando ? 'Entrando...' : 'Entrar',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'API atual: ${AppConfig.apiBaseUrl}',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
