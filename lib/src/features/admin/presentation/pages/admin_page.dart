import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_router.dart';
import '../../../../core/di/app_scope.dart';
import '../../../auth/data/models/auth_session.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/admin_repository.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  bool _loading = true;
  bool _loadingWorkouts = true;
  bool _loadingMealPlans = true;
  String? _error;
  int? _selectedUserId;

  List<AdminUserSummary> _users = const [];
  List<AdminExercise> _exercises = const [];
  List<AdminFood> _foods = const [];
  List<AdminWorkout> _workouts = const [];
  List<AdminMealPlan> _mealPlans = const [];
  List<AdminXpRule> _xpRules = const [];
  List<AdminMedal> _medals = const [];
  List<AdminWeeklyMission> _missions = const [];

  AdminRepository get _repository => AppScope.of(context).adminRepository;
  AuthSession? get _session =>
      AppScope.of(context).authRepository.currentSession;

  bool get _canManage {
    final role = _session?.user.roleSistema;
    return role == 'ADMIN' || role == 'GESTOR';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  Future<void> _loadInitial() async {
    if (!_canManage) {
      setState(() {
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _repository.loadUsers(),
        _repository.loadExercises(),
        _repository.loadFoods(),
        _repository.loadXpRules(),
        _repository.loadMedals(),
        _repository.loadWeeklyMissions(),
      ]);

      final users = results[0] as List<AdminUserSummary>;
      final selectedUserId = _resolveSelectedUser(
        users,
        preferred: _selectedUserId ?? _session?.user.id,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _users = users;
        _exercises = results[1] as List<AdminExercise>;
        _foods = results[2] as List<AdminFood>;
        _xpRules = results[3] as List<AdminXpRule>;
        _medals = results[4] as List<AdminMedal>;
        _missions = results[5] as List<AdminWeeklyMission>;
        _selectedUserId = selectedUserId;
        _loading = false;
        _loadingWorkouts = true;
        _loadingMealPlans = true;
      });

      await Future.wait([
        _loadWorkouts(selectedUserId),
        _loadMealPlans(selectedUserId),
      ]);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
        _loadingWorkouts = false;
        _loadingMealPlans = false;
      });
    }
  }

  int? _resolveSelectedUser(List<AdminUserSummary> users, {int? preferred}) {
    if (users.isEmpty) {
      return null;
    }
    if (preferred != null && users.any((user) => user.id == preferred)) {
      return preferred;
    }
    return users.first.id;
  }

  Future<void> _loadWorkouts(int? usuarioId) async {
    if (usuarioId == null) {
      setState(() {
        _workouts = const [];
        _loadingWorkouts = false;
      });
      return;
    }

    setState(() {
      _loadingWorkouts = true;
    });

    try {
      final workouts = await _repository.loadWorkouts(usuarioId);
      if (!mounted) {
        return;
      }
      setState(() {
        _workouts = workouts;
        _loadingWorkouts = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingWorkouts = false;
      });
      _showError(error);
    }
  }

  Future<void> _loadMealPlans(int? usuarioId) async {
    if (usuarioId == null) {
      setState(() {
        _mealPlans = const [];
        _loadingMealPlans = false;
      });
      return;
    }

    setState(() {
      _loadingMealPlans = true;
    });

    try {
      final plans = await _repository.loadMealPlans(usuarioId);
      if (!mounted) {
        return;
      }
      setState(() {
        _mealPlans = plans;
        _loadingMealPlans = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingMealPlans = false;
      });
      _showError(error);
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _saveExercise({AdminExercise? existing}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _ExerciseDialog(existing: existing),
    );
    if (payload == null) {
      return;
    }

    try {
      if (existing == null) {
        await _repository.createExercise(payload);
        _showSuccess('Exercicio cadastrado.');
      } else {
        await _repository.updateExercise(existing.id, payload);
        _showSuccess('Exercicio atualizado.');
      }
      final items = await _repository.loadExercises();
      if (!mounted) {
        return;
      }
      setState(() {
        _exercises = items;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteExercise(AdminExercise item) async {
    final confirmed = await _confirmAction(
      'Excluir exercicio',
      'Deseja remover "${item.nome}"?',
    );
    if (!confirmed) {
      return;
    }
    try {
      await _repository.deleteExercise(item.id);
      final items = await _repository.loadExercises();
      if (!mounted) {
        return;
      }
      setState(() {
        _exercises = items;
      });
      _showSuccess('Exercicio removido.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _saveFood({AdminFood? existing}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FoodDialog(existing: existing),
    );
    if (payload == null) {
      return;
    }

    try {
      if (existing == null) {
        await _repository.createFood(payload);
        _showSuccess('Alimento cadastrado.');
      } else {
        await _repository.updateFood(existing.id, payload);
        _showSuccess('Alimento atualizado.');
      }
      final items = await _repository.loadFoods();
      if (!mounted) {
        return;
      }
      setState(() {
        _foods = items;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteFood(AdminFood item) async {
    final confirmed = await _confirmAction(
      'Excluir alimento',
      'Deseja remover "${item.nome}"?',
    );
    if (!confirmed) {
      return;
    }
    try {
      await _repository.deleteFood(item.id);
      final items = await _repository.loadFoods();
      if (!mounted) {
        return;
      }
      setState(() {
        _foods = items;
      });
      _showSuccess('Alimento removido.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _saveWorkout({AdminWorkout? existing}) async {
    if (_selectedUserId == null) {
      _showError('Selecione um usuario antes de criar um treino.');
      return;
    }

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) =>
          _WorkoutDialog(userId: _selectedUserId!, existing: existing),
    );
    if (payload == null) {
      return;
    }

    try {
      if (existing == null) {
        await _repository.createWorkout(payload);
        _showSuccess('Treino cadastrado.');
      } else {
        await _repository.updateWorkout(existing.id, payload);
        _showSuccess('Treino atualizado.');
      }
      await _loadWorkouts(_selectedUserId);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deleteWorkout(AdminWorkout workout) async {
    final confirmed = await _confirmAction(
      'Excluir treino',
      'Deseja remover "${workout.nome}"?',
    );
    if (!confirmed) {
      return;
    }
    try {
      await _repository.deleteWorkout(workout.id);
      await _loadWorkouts(_selectedUserId);
      _showSuccess('Treino removido.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _addWorkoutExercise(AdminWorkout workout) async {
    if (_exercises.isEmpty) {
      _showError('Cadastre exercicios antes de montar o treino.');
      return;
    }

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _WorkoutExerciseDialog(exercises: _exercises),
    );
    if (payload == null) {
      return;
    }
    try {
      await _repository.addWorkoutExercise(workout.id, payload);
      await _loadWorkouts(_selectedUserId);
      _showSuccess('Exercicio vinculado ao treino.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _createMealPlan() async {
    if (_selectedUserId == null) {
      _showError('Selecione um usuario antes de criar um plano alimentar.');
      return;
    }

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MealPlanDialog(userId: _selectedUserId!),
    );
    if (payload == null) {
      return;
    }

    try {
      await _repository.createMealPlan(payload);
      await _loadMealPlans(_selectedUserId);
      _showSuccess('Plano alimentar cadastrado.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _addMealPlanDay(AdminMealPlan plan) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _MealPlanDayDialog(),
    );
    if (payload == null) {
      return;
    }

    try {
      await _repository.addMealPlanDay(plan.id, payload);
      await _loadMealPlans(_selectedUserId);
      _showSuccess('Dia adicionado ao plano.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _addMealPlanMeal(AdminMealPlanDay day) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _MealPlanMealDialog(),
    );
    if (payload == null) {
      return;
    }

    try {
      await _repository.addMealPlanMeal(day.id, payload);
      await _loadMealPlans(_selectedUserId);
      _showSuccess('Refeicao adicionada ao dia.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _addMealPlanFood(AdminMealPlanMeal meal) async {
    if (_foods.isEmpty) {
      _showError('Cadastre alimentos antes de montar o plano.');
      return;
    }

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MealPlanFoodDialog(foods: _foods),
    );
    if (payload == null) {
      return;
    }

    try {
      await _repository.addMealPlanFood(meal.id, payload);
      await _loadMealPlans(_selectedUserId);
      _showSuccess('Alimento adicionado a refeicao.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _saveXpRule({AdminXpRule? existing}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _XpRuleDialog(existing: existing),
    );
    if (payload == null) {
      return;
    }

    try {
      if (existing == null) {
        await _repository.createXpRule(payload);
        _showSuccess('Regra de XP cadastrada.');
      } else {
        await _repository.updateXpRule(existing.id, payload);
        _showSuccess('Regra de XP atualizada.');
      }
      final items = await _repository.loadXpRules();
      if (!mounted) {
        return;
      }
      setState(() {
        _xpRules = items;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _saveMedal({AdminMedal? existing}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MedalDialog(existing: existing),
    );
    if (payload == null) {
      return;
    }

    try {
      if (existing == null) {
        await _repository.createMedal(payload);
        _showSuccess('Medalha cadastrada.');
      } else {
        await _repository.updateMedal(existing.id, payload);
        _showSuccess('Medalha atualizada.');
      }
      final items = await _repository.loadMedals();
      if (!mounted) {
        return;
      }
      setState(() {
        _medals = items;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _saveMission({AdminWeeklyMission? existing}) async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MissionDialog(existing: existing),
    );
    if (payload == null) {
      return;
    }

    try {
      if (existing == null) {
        await _repository.createWeeklyMission(payload);
        _showSuccess('Missao semanal cadastrada.');
      } else {
        await _repository.updateWeeklyMission(existing.id, payload);
        _showSuccess('Missao semanal atualizada.');
      }
      final items = await _repository.loadWeeklyMissions();
      if (!mounted) {
        return;
      }
      setState(() {
        _missions = items;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<bool> _confirmAction(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Painel admin')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Seu perfil atual nao possui permissao para acessar a area administrativa.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil(AppRouter.home, (_) => false);
                  },
                  child: const Text('Voltar para home'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel admin'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Resumo'),
              Tab(text: 'Exercicios'),
              Tab(text: 'Alimentos'),
              Tab(text: 'Treinos'),
              Tab(text: 'Planos'),
              Tab(text: 'Gamificacao'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _loadInitial)
            : TabBarView(
                children: [
                  _buildOverviewTab(),
                  _buildExercisesTab(),
                  _buildFoodsTab(),
                  _buildWorkoutsTab(),
                  _buildMealPlansTab(),
                  _buildGamificationTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cobertura administrativa do app',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'As telas abaixo seguem os contratos mapeados no back-end para catalogos, montagem de treinos, montagem de planos alimentares e configuracoes dinamicas de gamificacao.',
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _StatCard(label: 'Usuarios', value: '${_users.length}'),
                      _StatCard(
                        label: 'Exercicios',
                        value: '${_exercises.length}',
                      ),
                      _StatCard(label: 'Alimentos', value: '${_foods.length}'),
                      _StatCard(label: 'Treinos', value: '${_workouts.length}'),
                      _StatCard(label: 'Planos', value: '${_mealPlans.length}'),
                      _StatCard(
                        label: 'XP regras',
                        value: '${_xpRules.length}',
                      ),
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
                    'Direcionamento dos arquivos .md',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Treino agent: biblioteca de exercicios, cadastro de treinos e composicao de exercicios por treino.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Alimentacao agent: biblioteca de alimentos, cadastro de planos, dias, refeicoes e itens de refeicao.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gamification agent: regras de XP, medalhas e missoes configuraveis em runtime.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesTab() {
    return RefreshIndicator(
      onRefresh: () async {
        final items = await _repository.loadExercises();
        if (!mounted) {
          return;
        }
        setState(() {
          _exercises = items;
        });
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(
            title: 'Catalogo de exercicios',
            subtitle:
                'CRUD para a biblioteca utilizada nos treinos planejados.',
            actionLabel: 'Novo exercicio',
            onAction: () => _saveExercise(),
          ),
          const SizedBox(height: 16),
          if (_exercises.isEmpty)
            const _EmptyCard(message: 'Nenhum exercicio encontrado.')
          else
            for (final item in _exercises)
              Card(
                child: ListTile(
                  title: Text(item.nome),
                  subtitle: Text(
                    '${item.grupoMuscular} • ${item.equipamento ?? 'Sem equipamento'}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => _saveExercise(existing: item),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        onPressed: () => _deleteExercise(item),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Excluir',
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildFoodsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        final items = await _repository.loadFoods();
        if (!mounted) {
          return;
        }
        setState(() {
          _foods = items;
        });
      },
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(
            title: 'Catalogo de alimentos',
            subtitle:
                'CRUD para a base nutricional usada nos planos alimentares.',
            actionLabel: 'Novo alimento',
            onAction: () => _saveFood(),
          ),
          const SizedBox(height: 16),
          if (_foods.isEmpty)
            const _EmptyCard(message: 'Nenhum alimento encontrado.')
          else
            for (final item in _foods)
              Card(
                child: ListTile(
                  title: Text(item.nome),
                  subtitle: Text(
                    '${item.calorias.toStringAsFixed(0)} kcal • P ${item.proteina.toStringAsFixed(1)} • C ${item.carboidrato.toStringAsFixed(1)} • G ${item.gordura.toStringAsFixed(1)}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        onPressed: () => _saveFood(existing: item),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        onPressed: () => _deleteFood(item),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildWorkoutsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _UserSelector(
          users: _users,
          value: _selectedUserId,
          label: 'Usuario alvo dos treinos',
          onChanged: (value) async {
            setState(() {
              _selectedUserId = value;
            });
            await _loadWorkouts(value);
          },
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'Treinos planejados',
          subtitle:
              'Cadastro do treino e associacao de exercicios conforme o modulo M1.',
          actionLabel: 'Novo treino',
          onAction: _saveWorkout,
        ),
        const SizedBox(height: 16),
        if (_loadingWorkouts)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_workouts.isEmpty)
          const _EmptyCard(message: 'Nenhum treino para o usuario selecionado.')
        else
          for (final workout in _workouts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workout.nome,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${workout.tipoTreino} • ${workout.diaSemana ?? 'Sem dia fixo'} • ${workout.dataTreino != null ? _dateTimeFormat.format(workout.dataTreino!) : 'Sem agenda'}',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _saveWorkout(existing: workout),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () => _deleteWorkout(workout),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    if ((workout.descricao ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(workout.descricao!),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            workout.ativo == true ? 'Ativo' : 'Inativo',
                          ),
                        ),
                        Chip(
                          label: Text(
                            workout.publico == true ? 'Publico' : 'Privado',
                          ),
                        ),
                        Chip(
                          label: Text(
                            workout.recorrente == true
                                ? 'Recorrente'
                                : 'Avulso',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Exercicios do treino',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _addWorkoutExercise(workout),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar exercicio'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (workout.exercicios.isEmpty)
                      const Text('Nenhum exercicio vinculado ainda.')
                    else
                      for (final exercise in workout.exercicios)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Text('${exercise.ordem}'),
                          ),
                          title: Text(exercise.exercicioNome),
                          subtitle: Text(
                            '${exercise.series} series • ${exercise.repeticoes} reps • ${exercise.dificuldade}${exercise.carga != null ? ' • ${exercise.carga!.toStringAsFixed(1)} kg' : ''}',
                          ),
                        ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildMealPlansTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _UserSelector(
          users: _users,
          value: _selectedUserId,
          label: 'Usuario alvo dos planos',
          onChanged: (value) async {
            setState(() {
              _selectedUserId = value;
            });
            await _loadMealPlans(value);
          },
        ),
        const SizedBox(height: 16),
        _SectionHeader(
          title: 'Planos alimentares',
          subtitle:
              'Cadastro hierarquico de planos, dias, refeicoes e alimentos.',
          actionLabel: 'Novo plano',
          onAction: _createMealPlan,
        ),
        const SizedBox(height: 16),
        if (_loadingMealPlans)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_mealPlans.isEmpty)
          const _EmptyCard(
            message: 'Nenhum plano alimentar para o usuario selecionado.',
          )
        else
          for (final plan in _mealPlans)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.nome,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${plan.dataInicio != null ? _dateFormat.format(plan.dataInicio!) : 'Sem inicio'} • ${plan.dataFim != null ? _dateFormat.format(plan.dataFim!) : 'Sem fim'}',
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _addMealPlanDay(plan),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar dia'),
                        ),
                      ],
                    ),
                    if ((plan.descricao ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(plan.descricao!),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(plan.ativo == true ? 'Ativo' : 'Inativo'),
                        ),
                        Chip(
                          label: Text(
                            plan.publico == true ? 'Publico' : 'Privado',
                          ),
                        ),
                        Chip(
                          label: Text(
                            plan.principal == true
                                ? 'Principal'
                                : 'Complementar',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (plan.dias.isEmpty)
                      const Text('Nenhum dia cadastrado ainda.')
                    else
                      for (final day in plan.dias)
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text('${day.diaSemana} • ${day.titulo}'),
                          subtitle: Text('${day.refeicoes.length} refeicoes'),
                          childrenPadding: const EdgeInsets.only(bottom: 12),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => _addMealPlanMeal(day),
                                icon: const Icon(Icons.add),
                                label: const Text('Adicionar refeicao'),
                              ),
                            ),
                            if (day.refeicoes.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('Nenhuma refeicao cadastrada.'),
                              )
                            else
                              for (final meal in day.refeicoes)
                                Card(
                                  margin: const EdgeInsets.only(top: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                meal.tipoRefeicao,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  _addMealPlanFood(meal),
                                              icon: const Icon(Icons.add),
                                              label: const Text(
                                                'Adicionar alimento',
                                              ),
                                            ),
                                          ],
                                        ),
                                        if ((meal.horarioSugerido ?? '')
                                            .isNotEmpty)
                                          Text(
                                            'Horario sugerido: ${meal.horarioSugerido}',
                                          ),
                                        if ((meal.observacao ?? '')
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(meal.observacao!),
                                        ],
                                        const SizedBox(height: 8),
                                        if (meal.alimentos.isEmpty)
                                          const Text(
                                            'Nenhum alimento vinculado.',
                                          )
                                        else
                                          for (final food in meal.alimentos)
                                            ListTile(
                                              contentPadding: EdgeInsets.zero,
                                              title: Text(food.alimentoNome),
                                              trailing: Text(
                                                '${food.quantidade.toStringAsFixed(0)} g',
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildGamificationTab() {
    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(
            title: 'Regras de XP',
            subtitle:
                'Configuracoes dinamicas consumidas pelo modulo de gamificacao.',
            actionLabel: 'Nova regra',
            onAction: _saveXpRule,
          ),
          const SizedBox(height: 12),
          if (_xpRules.isEmpty)
            const _EmptyCard(message: 'Nenhuma regra de XP configurada.')
          else
            for (final item in _xpRules)
              _ConfigTile(
                title: item.nome,
                subtitle:
                    '${item.tipoRegra} • XP ${item.xpConcedido ?? 0}${item.percentualBonus != null ? ' • Bonus ${item.percentualBonus!.toStringAsFixed(2)}%' : ''}',
                badge: item.ativo ? 'Ativo' : 'Inativo',
                onEdit: () => _saveXpRule(existing: item),
              ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Medalhas',
            subtitle: 'Definicoes para medalhas unicas ou repetiveis.',
            actionLabel: 'Nova medalha',
            onAction: _saveMedal,
          ),
          const SizedBox(height: 12),
          if (_medals.isEmpty)
            const _EmptyCard(message: 'Nenhuma medalha configurada.')
          else
            for (final item in _medals)
              _ConfigTile(
                title: item.nome,
                subtitle:
                    '${item.tipo} • ${item.tipoRegra} • Meta ${item.valorMeta.toStringAsFixed(2)}',
                badge: item.ativo ? 'Ativo' : 'Inativo',
                onEdit: () => _saveMedal(existing: item),
              ),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Missoes semanais',
            subtitle:
                'Cadastros alinhados ao fluxo configuravel descrito no back-end.',
            actionLabel: 'Nova missao',
            onAction: _saveMission,
          ),
          const SizedBox(height: 12),
          if (_missions.isEmpty)
            const _EmptyCard(message: 'Nenhuma missao configurada.')
          else
            for (final item in _missions)
              _ConfigTile(
                title: item.nome,
                subtitle:
                    '${item.tipoRegra} • Meta ${item.metaValor.toStringAsFixed(2)} • ${item.xpRecompensa} XP',
                badge: item.ativo ? 'Ativo' : 'Inativo',
                onEdit: () => _saveMission(existing: item),
              ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(subtitle),
                ],
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add),
              label: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

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
              Text(label),
              const SizedBox(height: 8),
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

class _ConfigTile extends StatelessWidget {
  const _ConfigTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(badge)),
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserSelector extends StatelessWidget {
  const _UserSelector({
    required this.users,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final List<AdminUserSummary> users;
  final int? value;
  final String label;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: DropdownButtonFormField<int>(
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            for (final user in users)
              DropdownMenuItem<int>(
                value: user.id,
                child: Text(
                  '${user.displayName} • ${user.roleSistema ?? 'USUARIO'}',
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog({this.existing});

  final AdminExercise? existing;

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _groupController;
  late final TextEditingController _equipmentController;
  late final TextEditingController _descriptionController;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.nome ?? '');
    _groupController = TextEditingController(
      text: existing?.grupoMuscular ?? '',
    );
    _equipmentController = TextEditingController(
      text: existing?.equipamento ?? '',
    );
    _descriptionController = TextEditingController(
      text: existing?.descricao ?? '',
    );
    _active = existing?.ativo ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _equipmentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Novo exercicio' : 'Editar exercicio',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _groupController,
                  decoration: const InputDecoration(
                    labelText: 'Grupo muscular',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _equipmentController,
                  decoration: const InputDecoration(labelText: 'Equipamento'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Exercicio ativo'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop({
              'nome': _nameController.text.trim(),
              'grupoMuscular': _groupController.text.trim(),
              'equipamento': _nullable(_equipmentController.text),
              'descricao': _nullable(_descriptionController.text),
              'ativo': _active,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _FoodDialog extends StatefulWidget {
  const _FoodDialog({this.existing});

  final AdminFood? existing;

  @override
  State<_FoodDialog> createState() => _FoodDialogState();
}

class _FoodDialogState extends State<_FoodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late final TextEditingController _sugarController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.nome ?? '');
    _caloriesController = TextEditingController(
      text: _numberText(existing?.calorias),
    );
    _proteinController = TextEditingController(
      text: _numberText(existing?.proteina),
    );
    _carbsController = TextEditingController(
      text: _numberText(existing?.carboidrato),
    );
    _fatController = TextEditingController(
      text: _numberText(existing?.gordura),
    );
    _sugarController = TextEditingController(
      text: _numberText(existing?.acucares),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _sugarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Novo alimento' : 'Editar alimento',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                _DecimalField(
                  controller: _caloriesController,
                  label: 'Calorias',
                ),
                const SizedBox(height: 12),
                _DecimalField(
                  controller: _proteinController,
                  label: 'Proteina',
                ),
                const SizedBox(height: 12),
                _DecimalField(
                  controller: _carbsController,
                  label: 'Carboidrato',
                ),
                const SizedBox(height: 12),
                _DecimalField(controller: _fatController, label: 'Gordura'),
                const SizedBox(height: 12),
                _DecimalField(controller: _sugarController, label: 'Acucares'),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop({
              'nome': _nameController.text.trim(),
              'calorias': _parseDecimal(_caloriesController.text),
              'proteina': _parseDecimal(_proteinController.text),
              'carboidrato': _parseDecimal(_carbsController.text),
              'gordura': _parseDecimal(_fatController.text),
              'acucares': _parseDecimal(_sugarController.text),
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _WorkoutDialog extends StatefulWidget {
  const _WorkoutDialog({required this.userId, this.existing});

  final int userId;
  final AdminWorkout? existing;

  @override
  State<_WorkoutDialog> createState() => _WorkoutDialogState();
}

class _WorkoutDialogState extends State<_WorkoutDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  final List<String> _tipos = const ['A', 'B', 'C', 'FULL_BODY'];
  final List<String> _days = const [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  String _selectedType = 'A';
  String? _selectedDay;
  bool _active = true;
  bool _isPublic = false;
  bool _recurrent = false;
  late DateTime _scheduledAt;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.nome ?? '');
    _descriptionController = TextEditingController(
      text: existing?.descricao ?? '',
    );
    _notesController = TextEditingController(text: existing?.observacoes ?? '');
    _selectedType = existing?.tipoTreino ?? 'A';
    _selectedDay = existing?.diaSemana;
    _active = existing?.ativo ?? true;
    _isPublic = existing?.publico ?? false;
    _recurrent = existing?.recorrente ?? false;
    _scheduledAt = existing?.dataTreino ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() {
      _scheduledAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return AlertDialog(
      title: Text(widget.existing == null ? 'Novo treino' : 'Editar treino'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo do treino',
                  ),
                  items: [
                    for (final item in _tipos)
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedType = value ?? 'A'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDay,
                  decoration: const InputDecoration(labelText: 'Dia da semana'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Sem recorrencia fixa'),
                    ),
                    for (final item in _days)
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                  ],
                  onChanged: (value) => setState(() => _selectedDay = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Observacoes'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Agenda do treino'),
                  subtitle: Text(formatter.format(_scheduledAt)),
                  trailing: TextButton(
                    onPressed: _pickDateTime,
                    child: const Text('Alterar'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Treino ativo'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Treino publico'),
                  value: _isPublic,
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Treino recorrente'),
                  value: _recurrent,
                  onChanged: (value) => setState(() => _recurrent = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop({
              'nome': _nameController.text.trim(),
              'descricao': _nullable(_descriptionController.text),
              'observacoes': _nullable(_notesController.text),
              'tipoTreino': _selectedType,
              'usuarioId': widget.userId,
              'diaSemana': _selectedDay,
              'ativo': _active,
              'publico': _isPublic,
              'recorrente': _recurrent,
              'dataTreino': _scheduledAt.toIso8601String(),
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _WorkoutExerciseDialog extends StatefulWidget {
  const _WorkoutExerciseDialog({required this.exercises});

  final List<AdminExercise> exercises;

  @override
  State<_WorkoutExerciseDialog> createState() => _WorkoutExerciseDialogState();
}

class _WorkoutExerciseDialogState extends State<_WorkoutExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _orderController;
  late final TextEditingController _seriesController;
  late final TextEditingController _repsController;
  late final TextEditingController _loadController;
  final List<String> _levels = const ['LEVE', 'MODERADA', 'ALTA'];
  int? _exerciseId;
  String _level = 'MODERADA';

  @override
  void initState() {
    super.initState();
    _exerciseId = widget.exercises.first.id;
    _orderController = TextEditingController(text: '1');
    _seriesController = TextEditingController(text: '4');
    _repsController = TextEditingController(text: '10');
    _loadController = TextEditingController();
  }

  @override
  void dispose() {
    _orderController.dispose();
    _seriesController.dispose();
    _repsController.dispose();
    _loadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar exercicio ao treino'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _exerciseId,
                  decoration: const InputDecoration(labelText: 'Exercicio'),
                  items: [
                    for (final item in widget.exercises)
                      DropdownMenuItem<int>(
                        value: item.id,
                        child: Text(item.nome),
                      ),
                  ],
                  onChanged: (value) => setState(() => _exerciseId = value),
                ),
                const SizedBox(height: 12),
                _IntegerField(controller: _orderController, label: 'Ordem'),
                const SizedBox(height: 12),
                _IntegerField(controller: _seriesController, label: 'Series'),
                const SizedBox(height: 12),
                _IntegerField(controller: _repsController, label: 'Repeticoes'),
                const SizedBox(height: 12),
                _DecimalField(
                  controller: _loadController,
                  label: 'Carga (kg)',
                  required: false,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: const InputDecoration(labelText: 'Dificuldade'),
                  items: [
                    for (final item in _levels)
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                  ],
                  onChanged: (value) =>
                      setState(() => _level = value ?? 'MODERADA'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate() || _exerciseId == null) {
              return;
            }
            Navigator.of(context).pop({
              'exercicioId': _exerciseId,
              'ordem': int.parse(_orderController.text),
              'series': int.parse(_seriesController.text),
              'repeticoes': int.parse(_repsController.text),
              'carga': _loadController.text.trim().isEmpty
                  ? null
                  : _parseDecimal(_loadController.text),
              'dificuldade': _level,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _MealPlanDialog extends StatefulWidget {
  const _MealPlanDialog({required this.userId});

  final int userId;

  @override
  State<_MealPlanDialog> createState() => _MealPlanDialogState();
}

class _MealPlanDialogState extends State<_MealPlanDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _active = true;
  bool _public = false;
  bool _principal = true;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    return AlertDialog(
      title: const Text('Novo plano alimentar'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome do plano'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data de inicio'),
                  subtitle: Text(formatter.format(_start)),
                  trailing: TextButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: const Text('Alterar'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Data de fim'),
                  subtitle: Text(formatter.format(_end)),
                  trailing: TextButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: const Text('Alterar'),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Plano ativo'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Plano publico'),
                  value: _public,
                  onChanged: (value) => setState(() => _public = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Plano principal'),
                  value: _principal,
                  onChanged: (value) => setState(() => _principal = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop({
              'usuarioId': widget.userId,
              'nome': _nameController.text.trim(),
              'descricao': _nullable(_descriptionController.text),
              'ativo': _active,
              'publico': _public,
              'principal': _principal,
              'dataInicio': _start.toIso8601String().split('T').first,
              'dataFim': _end.toIso8601String().split('T').first,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _MealPlanDayDialog extends StatefulWidget {
  const _MealPlanDayDialog();

  @override
  State<_MealPlanDayDialog> createState() => _MealPlanDayDialogState();
}

class _MealPlanDayDialogState extends State<_MealPlanDayDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final List<String> _days = const [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  String _selectedDay = 'MONDAY';

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar dia ao plano'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                decoration: const InputDecoration(labelText: 'Dia da semana'),
                items: [
                  for (final item in _days)
                    DropdownMenuItem<String>(value: item, child: Text(item)),
                ],
                onChanged: (value) =>
                    setState(() => _selectedDay = value ?? 'MONDAY'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titulo do dia'),
                validator: _requiredValidator,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop({
              'diaSemana': _selectedDay,
              'titulo': _titleController.text.trim(),
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _MealPlanMealDialog extends StatefulWidget {
  const _MealPlanMealDialog();

  @override
  State<_MealPlanMealDialog> createState() => _MealPlanMealDialogState();
}

class _MealPlanMealDialogState extends State<_MealPlanMealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final List<String> _mealTypes = const [
    'CAFE_DA_MANHA',
    'CAFE_DA_TARDE',
    'ALMOCO',
    'JANTAR',
    'LANCHE',
    'CEIA',
    'PRE_TREINO',
    'POS_TREINO',
  ];
  String _selectedType = 'ALMOCO';
  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _selectedTime = time;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar refeicao'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo da refeicao',
                ),
                items: [
                  for (final item in _mealTypes)
                    DropdownMenuItem<String>(value: item, child: Text(item)),
                ],
                onChanged: (value) =>
                    setState(() => _selectedType = value ?? 'ALMOCO'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Horario sugerido'),
                subtitle: Text(
                  _selectedTime == null
                      ? 'Nao definido'
                      : _selectedTime!.format(context),
                ),
                trailing: TextButton(
                  onPressed: _pickTime,
                  child: const Text('Alterar'),
                ),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Observacao'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop({
              'tipoRefeicao': _selectedType,
              'horarioSugerido': _selectedTime == null
                  ? null
                  : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00',
              'observacao': _nullable(_notesController.text),
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _MealPlanFoodDialog extends StatefulWidget {
  const _MealPlanFoodDialog({required this.foods});

  final List<AdminFood> foods;

  @override
  State<_MealPlanFoodDialog> createState() => _MealPlanFoodDialogState();
}

class _MealPlanFoodDialogState extends State<_MealPlanFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  int? _foodId;

  @override
  void initState() {
    super.initState();
    _foodId = widget.foods.first.id;
    _quantityController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar alimento'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: _foodId,
                decoration: const InputDecoration(labelText: 'Alimento'),
                items: [
                  for (final item in widget.foods)
                    DropdownMenuItem<int>(
                      value: item.id,
                      child: Text(item.nome),
                    ),
                ],
                onChanged: (value) => setState(() => _foodId = value),
              ),
              const SizedBox(height: 12),
              _DecimalField(
                controller: _quantityController,
                label: 'Quantidade (g)',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate() || _foodId == null) {
              return;
            }
            Navigator.of(context).pop({
              'alimentoId': _foodId,
              'quantidade': _parseDecimal(_quantityController.text),
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _XpRuleDialog extends StatefulWidget {
  const _XpRuleDialog({this.existing});

  final AdminXpRule? existing;

  @override
  State<_XpRuleDialog> createState() => _XpRuleDialogState();
}

class _XpRuleDialogState extends State<_XpRuleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _xpController = TextEditingController();
  final _bonusController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _types = const [
    'TREINO_COMPLETO',
    'TREINO_SEM_VONTADE',
    'PROGRESSAO_REAL',
    'PROTEINA_DIARIA',
    'TREINOS_SEMANA',
    'SONO_ADEQUADO',
    'SONO_CONSISTENTE_SEMANA',
    'RETORNO_APOS_PAUSA',
    'REGISTRO_DIARIO',
    'SEMANA_COMPLETA_REGISTRADA',
    'DIAS_TREINADOS_TOTAL',
    'PESO_ATINGIDO',
    'CARGA_EXERCICIO_ATINGIDA',
    'SEQUENCIA_ATUAL',
    'TREINOS_SEM_VONTADE_TOTAL',
    'PROGRESSOES_TOTAL',
    'ALIMENTACAO_ALINHADA',
    'DIAS_ALIMENTACAO_ALINHADA',
    'RETORNOS_APOS_PAUSA_TOTAL',
    'NIVEIS_SUBIDOS_TOTAL',
    'REGISTROS_SEMANA',
    'NIVEL_ATUAL',
    'XP_TOTAL',
  ];
  String _selectedType = 'TREINO_COMPLETO';
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController.text = existing?.nome ?? '';
    _xpController.text = existing?.xpConcedido?.toString() ?? '';
    _bonusController.text = _numberText(existing?.percentualBonus);
    _descriptionController.text = existing?.descricao ?? '';
    _selectedType = existing?.tipoRegra ?? 'TREINO_COMPLETO';
    _active = existing?.ativo ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _xpController.dispose();
    _bonusController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Nova regra de XP' : 'Editar regra de XP',
      ),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo da regra'),
                  items: [
                    for (final item in _types)
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                  ],
                  onChanged: (value) => setState(
                    () => _selectedType = value ?? 'TREINO_COMPLETO',
                  ),
                ),
                const SizedBox(height: 12),
                _IntegerField(controller: _xpController, label: 'XP concedido'),
                const SizedBox(height: 12),
                _DecimalField(
                  controller: _bonusController,
                  label: 'Percentual bonus',
                  required: false,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Regra ativa'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop({
              'nome': _nameController.text.trim(),
              'tipoRegra': _selectedType,
              'xpConcedido': int.parse(_xpController.text),
              'percentualBonus': _bonusController.text.trim().isEmpty
                  ? null
                  : _parseDecimal(_bonusController.text),
              'descricao': _nullable(_descriptionController.text),
              'ativo': _active,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _MedalDialog extends StatefulWidget {
  const _MedalDialog({this.existing});

  final AdminMedal? existing;

  @override
  State<_MedalDialog> createState() => _MedalDialogState();
}

class _MedalDialogState extends State<_MedalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();
  final _referenceController = TextEditingController();
  final List<String> _medalTypes = const ['UNICA', 'REPETIVEL'];
  final List<String> _ruleTypes = const [
    'TREINO_COMPLETO',
    'PROGRESSAO_REAL',
    'PROTEINA_DIARIA',
    'TREINOS_SEMANA',
    'REGISTRO_DIARIO',
    'DIAS_TREINADOS_TOTAL',
    'PESO_ATINGIDO',
    'CARGA_EXERCICIO_ATINGIDA',
    'SEQUENCIA_ATUAL',
    'ALIMENTACAO_ALINHADA',
    'NIVEIS_SUBIDOS_TOTAL',
    'NIVEL_ATUAL',
    'XP_TOTAL',
  ];
  String _selectedMedalType = 'UNICA';
  String _selectedRuleType = 'TREINO_COMPLETO';
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController.text = existing?.nome ?? '';
    _descriptionController.text = existing?.descricao ?? '';
    _goalController.text = _numberText(existing?.valorMeta);
    _referenceController.text = existing?.valorReferencia ?? '';
    _selectedMedalType = existing?.tipo ?? 'UNICA';
    _selectedRuleType = existing?.tipoRegra ?? 'TREINO_COMPLETO';
    _active = existing?.ativo ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Nova medalha' : 'Editar medalha'),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedMedalType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo da medalha',
                  ),
                  items: [
                    for (final item in _medalTypes)
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedMedalType = value ?? 'UNICA'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRuleType,
                  decoration: const InputDecoration(labelText: 'Tipo da regra'),
                  items: [
                    for (final item in _ruleTypes)
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                  ],
                  onChanged: (value) => setState(
                    () => _selectedRuleType = value ?? 'TREINO_COMPLETO',
                  ),
                ),
                const SizedBox(height: 12),
                _DecimalField(controller: _goalController, label: 'Valor meta'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Valor de referencia',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Medalha ativa'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop({
              'nome': _nameController.text.trim(),
              'descricao': _nullable(_descriptionController.text),
              'tipo': _selectedMedalType,
              'tipoRegra': _selectedRuleType,
              'valorMeta': _parseDecimal(_goalController.text),
              'valorReferencia': _nullable(_referenceController.text),
              'ativo': _active,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _MissionDialog extends StatefulWidget {
  const _MissionDialog({this.existing});

  final AdminWeeklyMission? existing;

  @override
  State<_MissionDialog> createState() => _MissionDialogState();
}

class _MissionDialogState extends State<_MissionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _goalController = TextEditingController();
  final _xpController = TextEditingController();
  final List<String> _ruleTypes = const [
    'TREINO_COMPLETO',
    'TREINO_SEM_VONTADE',
    'PROGRESSAO_REAL',
    'PROTEINA_DIARIA',
    'TREINOS_SEMANA',
    'REGISTRO_DIARIO',
    'ALIMENTACAO_ALINHADA',
    'REGISTROS_SEMANA',
  ];
  String _selectedRuleType = 'TREINO_COMPLETO';
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController.text = existing?.nome ?? '';
    _descriptionController.text = existing?.descricao ?? '';
    _goalController.text = _numberText(existing?.metaValor);
    _xpController.text = existing?.xpRecompensa.toString() ?? '';
    _selectedRuleType = existing?.tipoRegra ?? 'TREINO_COMPLETO';
    _active = existing?.ativo ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Nova missao semanal'
            : 'Editar missao semanal',
      ),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedRuleType,
                  decoration: const InputDecoration(labelText: 'Tipo da regra'),
                  items: [
                    for (final item in _ruleTypes)
                      DropdownMenuItem<String>(value: item, child: Text(item)),
                  ],
                  onChanged: (value) => setState(
                    () => _selectedRuleType = value ?? 'TREINO_COMPLETO',
                  ),
                ),
                const SizedBox(height: 12),
                _DecimalField(controller: _goalController, label: 'Meta'),
                const SizedBox(height: 12),
                _IntegerField(
                  controller: _xpController,
                  label: 'XP recompensa',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Missao ativa'),
                  value: _active,
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop({
              'nome': _nameController.text.trim(),
              'descricao': _nullable(_descriptionController.text),
              'tipoRegra': _selectedRuleType,
              'metaValor': _parseDecimal(_goalController.text),
              'xpRecompensa': int.parse(_xpController.text),
              'ativo': _active,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _DecimalField extends StatelessWidget {
  const _DecimalField({
    required this.controller,
    required this.label,
    this.required = true,
  });

  final TextEditingController controller;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (!required && (value == null || value.trim().isEmpty)) {
          return null;
        }
        if (value == null || value.trim().isEmpty) {
          return 'Campo obrigatorio';
        }
        if (double.tryParse(value.replaceAll(',', '.')) == null) {
          return 'Informe um numero valido';
        }
        return null;
      },
    );
  }
}

class _IntegerField extends StatelessWidget {
  const _IntegerField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Campo obrigatorio';
        }
        if (int.tryParse(value) == null) {
          return 'Informe um inteiro valido';
        }
        return null;
      },
    );
  }
}

String? _requiredValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Campo obrigatorio';
  }
  return null;
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _numberText(num? value) {
  if (value == null) {
    return '';
  }
  return value % 1 == 0 ? value.toInt().toString() : value.toString();
}

double _parseDecimal(String value) {
  return double.parse(value.replaceAll(',', '.'));
}
