import 'package:flutter/material.dart';

import '../../data/models/auth_session.dart';
import '../../data/repositories/auth_repository.dart';

class LoginController extends ChangeNotifier {
  LoginController(this._repository);

  final AuthRepository _repository;

  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool carregando = false;
  String? erro;

  Future<AuthSession?> submit() async {
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      erro = 'Informe email e senha.';
      notifyListeners();
      return null;
    }

    carregando = true;
    erro = null;
    notifyListeners();

    try {
      final session = await _repository.loginLocal(email: email, senha: senha);
      return session;
    } catch (exception) {
      erro = exception.toString();
      return null;
    } finally {
      carregando = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }
}
