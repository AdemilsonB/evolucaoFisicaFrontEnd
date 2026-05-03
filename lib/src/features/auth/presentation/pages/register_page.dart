import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/app_scope.dart';
import '../../data/models/auth_session.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();

  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nomeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      final session = await AppScope.of(context).authRepository.cadastrarLocal(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        senha: _senhaController.text,
        username: _usernameController.text.trim(),
      );

      if (!mounted) {
        return;
      }
      _navigateAfterRegister(session);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _erro = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  void _navigateAfterRegister(AuthSession session) {
    final route = session.onboardingPendente
        ? AppRouter.onboarding
        : AppRouter.home;
    Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cadastre seu acesso',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ao concluir o cadastro, usuarios novos seguem direto para a tela de objetivos.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nomeController,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o email.';
                        }
                        if (!value.contains('@')) {
                          return 'Informe um email valido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Informe a senha.';
                        }
                        if (value.length < 8) {
                          return 'Use pelo menos 8 caracteres.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmacaoController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirmar senha',
                      ),
                      validator: (value) {
                        if (value != _senhaController.text) {
                          return 'As senhas nao coincidem.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_erro != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _erro!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _salvando ? null : _submit,
                      child: Text(_salvando ? 'Criando conta...' : 'Cadastrar'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Ja tenho conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Campo obrigatorio.';
  }
  return null;
}
