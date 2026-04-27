import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/app_scope.dart';
import '../../data/models/onboarding_models.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();
  final _alturaController = TextEditingController();
  final _frequenciaController = TextEditingController();
  final _proteinaController = TextEditingController();
  final _caloriaController = TextEditingController();
  final _observacaoController = TextEditingController();

  String _objetivo = OnboardingOptions.objetivos.first;
  String _nivelExperiencia = OnboardingOptions.niveisExperiencia.first;
  bool _salvando = false;

  @override
  void dispose() {
    _pesoController.dispose();
    _alturaController.dispose();
    _frequenciaController.dispose();
    _proteinaController.dispose();
    _caloriaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final dependencies = AppScope.of(context);
    final session = dependencies.authRepository.currentSession;
    if (session == null) {
      Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
      return;
    }

    final payload = OnboardingPayload(
      objetivo: _objetivo,
      pesoAtual: _parseDouble(_pesoController.text)!,
      altura: _parseDouble(_alturaController.text),
      nivelExperiencia: _nivelExperiencia,
      frequenciaSemanalMeta: _parseInt(_frequenciaController.text),
      proteinaDiariaMeta: _parseDouble(_proteinaController.text),
      caloriaDiariaMeta: _parseDouble(_caloriaController.text),
      observacaoMeta: _observacaoController.text.trim().isEmpty
          ? null
          : _observacaoController.text.trim(),
    );

    setState(() => _salvando = true);

    try {
      final result = await dependencies.onboardingRepository.concluir(
        usuarioId: session.user.id,
        payload: payload,
      );

      await dependencies.authRepository.updateCurrentUser(
        result.user,
        onboardingPendente: false,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
    } catch (exception) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(exception.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).authRepository.currentSession;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Onboarding')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRouter.login,
                (_) => false,
              );
            },
            child: const Text('Ir para login'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding inicial'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Vamos configurar sua base no app',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Esses campos seguem o contrato atual de onboarding do back-end e alimentam metas do atleta e gamificacao.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      initialValue: _objetivo,
                      decoration: const InputDecoration(labelText: 'Objetivo'),
                      items: OnboardingOptions.objetivos
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(_labelForEnum(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _objetivo = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _nivelExperiencia,
                      decoration: const InputDecoration(
                        labelText: 'Nivel de experiencia',
                      ),
                      items: OnboardingOptions.niveisExperiencia
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(_labelForEnum(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _nivelExperiencia = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pesoController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Peso atual'),
                      validator: (value) {
                        if (_parseDouble(value) == null) {
                          return 'Informe um peso valido.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alturaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Altura'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _frequenciaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Meta semanal de treinos',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _proteinaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Meta diaria de proteina',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _caloriaController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Meta diaria de calorias',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _observacaoController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Observacao da meta',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _salvando ? null : _submit,
                      child: Text(_salvando ? 'Salvando...' : 'Concluir onboarding'),
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

  String _labelForEnum(String value) {
    return value
        .toLowerCase()
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  double? _parseDouble(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) {
      return null;
    }
    return double.tryParse(normalized);
  }

  int? _parseInt(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return int.tryParse(normalized);
  }
}
