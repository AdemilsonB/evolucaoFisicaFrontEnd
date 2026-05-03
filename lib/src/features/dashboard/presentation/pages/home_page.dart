import 'package:flutter/material.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/app_scope.dart';
import '../../data/models/dashboard_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<_HomeData>? _future;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    _future = _load();
    _initialized = true;
  }

  Future<_HomeData> _load() async {
    final dependencies = AppScope.of(context);
    final session = dependencies.authRepository.currentSession!;
    final dashboard = await dependencies.dashboardRepository.loadDashboard(
      session.user.id,
    );
    final ranking = await dependencies.dashboardRepository.loadRankingGeral();
    return _HomeData(dashboard: dashboard, ranking: ranking.take(5).toList());
  }

  Future<void> _logout() async {
    await AppScope.of(context).authRepository.logout();
    if (!mounted) {
      return;
    }
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).authRepository.currentSession;
    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Evolucao Fisica')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRouter.login, (_) => false);
            },
            child: const Text('Voltar para login'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ola, ${session.user.nome}'),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.requireData;
          final canManage = _canOpenAdmin(session.user.roleSistema);

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _future = _load();
              });
              await _future!;
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _MetricGrid(dashboard: data.dashboard),
                const SizedBox(height: 20),
                if (canManage) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Area administrativa',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Cadastre exercicios, alimentos, treinos, planos alimentares e regras de gamificacao a partir dos contratos do back-end.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed(AppRouter.admin);
                            },
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            label: const Text('Abrir painel admin'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modulos prioritarios',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        const Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _FeatureChip(label: 'Auth'),
                            _FeatureChip(label: 'Onboarding'),
                            _FeatureChip(label: 'Treinos'),
                            _FeatureChip(label: 'Execucao real'),
                            _FeatureChip(label: 'Planos alimentares'),
                            _FeatureChip(label: 'Gamificacao'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top 5 do ranking geral',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        for (final item in data.ranking)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(item.posicao.toString()),
                            ),
                            title: Text(item.username),
                            subtitle: Text(
                              'Nivel ${item.nivelAtual} - ${item.tierAtual}',
                            ),
                            trailing: Text('${item.xpTotal} XP'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

bool _canOpenAdmin(String? roleSistema) {
  return roleSistema == 'ADMIN' || roleSistema == 'GESTOR';
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.dashboard});

  final DashboardOverview dashboard;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _MetricCard(label: 'XP total', value: '${dashboard.xpTotal}'),
        _MetricCard(label: 'Nivel', value: '${dashboard.nivelAtual}'),
        _MetricCard(label: 'Tier', value: dashboard.tierAtual),
        _MetricCard(label: 'Treinos', value: '${dashboard.treinosRealizados}'),
        _MetricCard(label: 'Sequencia', value: '${dashboard.sequenciaAtual}'),
        _MetricCard(label: 'Missoes', value: '${dashboard.missoesSemanais}'),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}

class _HomeData {
  const _HomeData({required this.dashboard, required this.ranking});

  final DashboardOverview dashboard;
  final List<RankingEntry> ranking;
}
