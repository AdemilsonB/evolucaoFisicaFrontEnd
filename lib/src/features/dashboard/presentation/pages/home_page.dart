import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/app_scope.dart';
import '../../../../core/models/app_user.dart';
import '../../data/models/dashboard_models.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<DashboardOverview>? _future;
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

  Future<DashboardOverview> _load() {
    final dependencies = AppScope.of(context);
    final session = dependencies.authRepository.currentSession!;
    return dependencies.dashboardRepository.loadDashboard(session.user.id);
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

    final canManage = _canOpenAdmin(session.user.roleSistema);

    return Scaffold(
      backgroundColor: const Color(0xFF090805),
      body: SafeArea(
        child: FutureBuilder<DashboardOverview>(
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
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              );
            }

            final dashboard = snapshot.requireData;

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _future = _load();
                });
                await _future;
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _DashboardHeader(
                    user: session.user,
                    onLogout: _logout,
                    onOpenWorkout: () {
                      Navigator.of(context).pushNamed(AppRouter.workouts);
                    },
                    onOpenAdmin: canManage
                        ? () {
                            Navigator.of(context).pushNamed(AppRouter.admin);
                          }
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _GoldPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          title: 'Medalhas',
                          subtitle: 'Suas conquistas atuais',
                        ),
                        const SizedBox(height: 16),
                        if (dashboard.conqueredMedals.isEmpty)
                          const _EmptyDashboardState(
                            message: 'Nenhuma medalha conquistada ainda.',
                          )
                        else
                          Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              for (final medal in dashboard.conqueredMedals)
                                _MedalCard(medal: medal),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 920;
                      final tierCard = _TierProgressCard(
                        profile: dashboard.profile,
                      );
                      final statusCard = _StatusCard(
                        profile: dashboard.profile,
                        user: session.user,
                      );

                      if (stacked) {
                        return Column(
                          children: [
                            tierCard,
                            const SizedBox(height: 20),
                            statusCard,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: tierCard),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: statusCard),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 920;
                      final missions = _WeeklyMissionsCard(
                        missions: dashboard.weeklyMissions,
                      );
                      final xpRules = _XpRulesCard(rules: dashboard.xpRules);

                      if (stacked) {
                        return Column(
                          children: [
                            missions,
                            const SizedBox(height: 20),
                            xpRules,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: missions),
                          const SizedBox(width: 20),
                          Expanded(flex: 2, child: xpRules),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.user,
    required this.onLogout,
    required this.onOpenWorkout,
    this.onOpenAdmin,
  });

  final AppUser user;
  final VoidCallback onLogout;
  final VoidCallback onOpenWorkout;
  final VoidCallback? onOpenAdmin;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15110B), Color(0xFF050402)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF74521B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runAlignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAINEL DE EVOLUCAO',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFFF4C35B),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bem-vindo, ${user.nome}. Sua jornada continua hoje.',
                    style: const TextStyle(color: Color(0xFFF3E3B0)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF8F6A26)),
                  color: const Color(0xFF0E0A06),
                ),
                child: Text(
                  'Atualizado em $today',
                  style: const TextStyle(
                    color: Color(0xFFF4C35B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onOpenWorkout,
                icon: const Icon(Icons.fitness_center),
                label: const Text('Montar meu treino'),
              ),
              if (onOpenAdmin != null)
                OutlinedButton.icon(
                  onPressed: onOpenAdmin,
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Painel admin'),
                ),
              TextButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Sair'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoldPanel extends StatelessWidget {
  const _GoldPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0A06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6A4B16)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: const Color(0xFFF4C35B),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFFCEBC88))),
      ],
    );
  }
}

class _MedalCard extends StatelessWidget {
  const _MedalCard({required this.medal});

  final UserMedal medal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: const Color(0xFF14100A),
        border: Border.all(color: const Color(0xFF89601E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF4C35B), width: 2),
            ),
            child: Center(
              child: Text(
                medal.quantity > 1 ? '${medal.quantity}x' : '1x',
                style: const TextStyle(
                  color: Color(0xFFF4C35B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            medal.nome,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            medal.progressLabel,
            style: const TextStyle(color: Color(0xFFF4C35B)),
          ),
          const SizedBox(height: 6),
          Text(
            medal.descricao ?? 'Meta ${medal.valorMeta.toStringAsFixed(0)}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFCFBE8F), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TierProgressCard extends StatelessWidget {
  const _TierProgressCard({required this.profile});

  final DashboardProfile profile;

  @override
  Widget build(BuildContext context) {
    return _GoldPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Tier e Nivel',
            subtitle: 'Acompanhe seu progresso real',
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFF4C35B), Color(0xFF3A2506)],
                  ),
                  border: Border.all(color: const Color(0xFFC99A3E), width: 4),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'NIVEL',
                        style: TextStyle(
                          color: Color(0xFF2E1C01),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${profile.nivelAtual}',
                        style: const TextStyle(
                          color: Color(0xFF1E1200),
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.tierAtual,
                        style: const TextStyle(
                          color: Color(0xFF2E1C01),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tier atual: ${profile.tierAtual}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFF4C35B),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'XP total: ${profile.xpTotal}',
                      style: const TextStyle(color: Color(0xFFF3E3B0)),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value:
                            (profile.percentualProgressoNivel.clamp(0, 100)) /
                            100,
                        minHeight: 16,
                        backgroundColor: const Color(0xFF2A1D0A),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFF4C35B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${profile.percentualProgressoNivel}% de progresso no nivel atual',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${profile.xpAtualNivel} XP no nivel atual • faltam ${profile.xpRestante > 0 ? profile.xpRestante : 0} XP para o proximo nivel',
                      style: const TextStyle(color: Color(0xFFCEBC88)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Meta do proximo nivel: ${profile.xpNecessarioProximoNivel} XP',
                      style: const TextStyle(color: Color(0xFFCEBC88)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.profile, required this.user});

  final DashboardProfile profile;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    return _GoldPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Meu Status',
            subtitle: 'Informacoes basicas e indicadores principais',
          ),
          const SizedBox(height: 18),
          _StatusItem(label: 'Nome', value: user.nome),
          _StatusItem(label: 'Email', value: user.email),
          _StatusItem(
            label: 'Objetivo',
            value: _formatEnum(user.objetivo) ?? 'Nao definido',
          ),
          _StatusItem(
            label: 'Nivel de experiencia',
            value: _formatEnum(user.nivelExperiencia) ?? 'Nao definido',
          ),
          _StatusItem(
            label: 'Peso atual',
            value: profile.pesoAtual != null
                ? '${profile.pesoAtual!.toStringAsFixed(1)} kg'
                : 'Nao informado',
          ),
          _StatusItem(
            label: 'Peso inicial',
            value: profile.pesoInicial != null
                ? '${profile.pesoInicial!.toStringAsFixed(1)} kg'
                : 'Nao informado',
          ),
          _StatusItem(
            label: 'Treinos realizados',
            value: '${profile.treinosRealizados}',
          ),
          _StatusItem(
            label: 'Sequencia atual',
            value: '${profile.sequenciaAtual} dias',
          ),
          _StatusItem(
            label: 'Melhor sequencia',
            value: '${profile.melhorSequencia} dias',
          ),
        ],
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFFF4C35B)),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyMissionsCard extends StatelessWidget {
  const _WeeklyMissionsCard({required this.missions});

  final List<WeeklyMissionProgress> missions;

  @override
  Widget build(BuildContext context) {
    return _GoldPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Missoes da Semana',
            subtitle: 'Regras dinamicas carregadas do back-end',
          ),
          const SizedBox(height: 16),
          if (missions.isEmpty)
            const _EmptyDashboardState(
              message: 'Nenhuma missao semanal configurada.',
            )
          else
            for (final mission in missions)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF15100A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF654715)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mission.nome,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mission.descricao ??
                                'Meta ${mission.metaValor.toStringAsFixed(0)}',
                            style: const TextStyle(color: Color(0xFFCEBC88)),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF4C35B)),
                      ),
                      child: Text(
                        '+${mission.xpRecompensa} XP',
                        style: const TextStyle(
                          color: Color(0xFFF4C35B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _XpRulesCard extends StatelessWidget {
  const _XpRulesCard({required this.rules});

  final List<XpRuleInfo> rules;

  @override
  Widget build(BuildContext context) {
    return _GoldPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Como ganhar XP',
            subtitle: 'Pontuacoes ativas da sua temporada',
          ),
          const SizedBox(height: 16),
          if (rules.isEmpty)
            const _EmptyDashboardState(
              message: 'Nenhuma regra ativa encontrada.',
            )
          else
            for (final rule in rules.where((item) => item.ativo))
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        rule.nome,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Text(
                      rule.xpConcedido != null
                          ? '+${rule.xpConcedido} XP'
                          : '${rule.percentualBonus?.toStringAsFixed(0) ?? '0'}%',
                      style: const TextStyle(
                        color: Color(0xFFF4C35B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _EmptyDashboardState extends StatelessWidget {
  const _EmptyDashboardState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4E3812)),
        color: const Color(0xFF14100A),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFFCFBE8F))),
    );
  }
}

bool _canOpenAdmin(String? roleSistema) {
  return roleSistema == 'ADMIN' || roleSistema == 'GESTOR';
}

String? _formatEnum(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return value
      .toLowerCase()
      .split('_')
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
