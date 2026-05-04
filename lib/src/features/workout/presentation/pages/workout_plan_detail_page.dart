import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_scope.dart';
import '../../../admin/data/models/admin_models.dart';
import '../../data/models/workout_models.dart';
import 'workout_execution_page.dart';

class WorkoutPlanDetailPage extends StatefulWidget {
  const WorkoutPlanDetailPage({
    super.key,
    required this.workoutId,
    required this.initialWorkout,
  });

  final int workoutId;
  final AdminWorkout initialWorkout;

  @override
  State<WorkoutPlanDetailPage> createState() => _WorkoutPlanDetailPageState();
}

class _WorkoutPlanDetailPageState extends State<WorkoutPlanDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  bool _editMode = false;
  String? _error;
  late AdminWorkout _workout;
  List<AdminExercise> _exercisePool = const [];
  List<WorkoutRecord> _records = const [];
  List<AdminWorkoutExercise> _editableExercises = const [];

  int get _userId =>
      AppScope.of(context).authRepository.currentSession!.user.id;

  @override
  void initState() {
    super.initState();
    _workout = widget.initialWorkout;
    _editableExercises = [...widget.initialWorkout.exercicios]
      ..sort((a, b) => a.ordem.compareTo(b.ordem));
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repository = AppScope.of(context).workoutRepository;
      final results = await Future.wait([
        repository.loadWorkoutById(widget.workoutId),
        repository.loadExercises(),
        repository.loadRecords(
          usuarioId: _userId,
          start: DateTime.now().subtract(const Duration(days: 365)),
          end: DateTime.now().add(const Duration(days: 1)),
        ),
      ]);
      if (!mounted) {
        return;
      }
      final workout = results[0] as AdminWorkout;
      setState(() {
        _workout = workout;
        _exercisePool = results[1] as List<AdminExercise>;
        _records = results[2] as List<WorkoutRecord>;
        _editableExercises = [...workout.exercicios]
          ..sort((a, b) => a.ordem.compareTo(b.ordem));
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _editWorkout() async {
    final repository = AppScope.of(context).workoutRepository;
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _WorkoutDialog(userId: _userId, existing: _workout),
    );
    if (!mounted || payload == null) {
      return;
    }
    try {
      await repository.updateWorkout(_workout.id, payload);
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _addExercise() async {
    if (_exercisePool.isEmpty) {
      _showError('Cadastre exercicios antes de montar o treino.');
      return;
    }
    final repository = AppScope.of(context).workoutRepository;
    final payload = await showDialog<_ExerciseConfigResult>(
      context: context,
      builder: (_) => _WorkoutExerciseDialog(
        exercises: _exercisePool,
        order: _editableExercises.length + 1,
      ),
    );
    if (!mounted || payload == null) {
      return;
    }
    try {
      await repository.addWorkoutExercise(_workout.id, payload.toPayload());
      await _load();
      setState(() {
        _editMode = true;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _editExercise(AdminWorkoutExercise exercise) async {
    final payload = await showDialog<_ExerciseConfigResult>(
      context: context,
      builder: (_) => _WorkoutExerciseDialog(
        exercises: _exercisePool,
        existing: exercise,
        order: exercise.ordem,
      ),
    );
    if (payload == null) {
      return;
    }
    final updatedList = _editableExercises
        .map(
          (item) => item.id == exercise.id
              ? AdminWorkoutExercise(
                  id: item.id,
                  exercicioId: payload.exercicioId,
                  exercicioNome:
                      _exercisePool
                          .where((element) => element.id == payload.exercicioId)
                          .firstOrNull
                          ?.nome ??
                      item.exercicioNome,
                  ordem: item.ordem,
                  series: payload.series,
                  repeticoes: payload.repeticoes,
                  carga: payload.carga,
                  dificuldade: payload.dificuldade,
                )
              : item,
        )
        .toList();
    await _persistExercises(updatedList);
  }

  Future<void> _deleteExercise(AdminWorkoutExercise exercise) async {
    try {
      await AppScope.of(
        context,
      ).workoutRepository.deleteWorkoutExercise(_workout.id, exercise.id);
      await _load();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _persistExercises(List<AdminWorkoutExercise> exercises) async {
    final drafts = exercises
        .asMap()
        .entries
        .map(
          (entry) => WorkoutExerciseDraft(
            exercicioId: entry.value.exercicioId,
            ordem: entry.key + 1,
            series: entry.value.series,
            repeticoes: entry.value.repeticoes,
            carga: entry.value.carga,
            dificuldade: entry.value.dificuldade,
          ),
        )
        .toList();
    try {
      final updated = await AppScope.of(
        context,
      ).workoutRepository.replaceWorkoutExercises(_workout, drafts);
      if (!mounted) {
        return;
      }
      setState(() {
        _workout = updated;
        _editableExercises = [...updated.exercicios]
          ..sort((a, b) => a.ordem.compareTo(b.ordem));
      });
      _showSuccess('Exercicios atualizados.');
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _startWorkout() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutExecutionPage(
          workout: _workout,
          records: _records
              .where((item) => item.treinoId == _workout.id)
              .toList(),
        ),
      ),
    );
    await _load();
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF353958),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF353958),
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(_error!, style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF353958),
      floatingActionButton: _editMode
          ? FloatingActionButton(
              onPressed: _addExercise,
              child: const Icon(Icons.add),
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _DetailHero(
              workout: _workout,
              onBack: () => Navigator.of(context).pop(),
              onEditWorkout: _editWorkout,
              onToggleEditMode: () {
                setState(() {
                  _editMode = !_editMode;
                });
              },
              editMode: _editMode,
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4D8EFF),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFFBAC1EA),
              tabs: const [
                Tab(text: 'Visao geral'),
                Tab(text: 'Estatisticas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildOverview(), _buildStats()],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: SizedBox(
          height: 58,
          child: ElevatedButton(
            onPressed: _workout.exercicios.isEmpty ? null : _startWorkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2EAF73),
              foregroundColor: Colors.white,
            ),
            child: const Text('Comecar treino'),
          ),
        ),
      ),
    );
  }

  Widget _buildOverview() {
    if (_editMode) {
      return Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _editableExercises.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _editableExercises.removeAt(oldIndex);
                  _editableExercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final exercise = _editableExercises[index];
                return _ExerciseTile(
                  key: ValueKey(exercise.id),
                  exercise: exercise,
                  onTap: () => _openExerciseDetails(exercise),
                  onEdit: () => _editExercise(exercise),
                  onDelete: () => _deleteExercise(exercise),
                  showDragHandle: true,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _persistExercises(_editableExercises),
                child: const Text('Salvar ordem dos exercicios'),
              ),
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final exercise
            in _workout.exercicios..sort((a, b) => a.ordem.compareTo(b.ordem)))
          _ExerciseTile(
            exercise: exercise,
            onTap: () => _openExerciseDetails(exercise),
            onEdit: _editMode ? () => _editExercise(exercise) : null,
            onDelete: _editMode ? () => _deleteExercise(exercise) : null,
          ),
      ],
    );
  }

  Widget _buildStats() {
    final workoutRecords = _records
        .where((item) => item.treinoId == _workout.id)
        .toList();
    final sessions = workoutRecords.length;
    final totalDuration = workoutRecords
        .map((item) => item.duration?.inSeconds ?? 0)
        .fold<int>(0, (sum, value) => sum + value);
    final completedSeries = workoutRecords
        .expand((item) => item.execucoes)
        .where((item) => item.concluido)
        .fold<int>(0, (sum, item) => sum + (item.seriesPlanejadas ?? 0));
    final totalReps = workoutRecords
        .expand((item) => item.execucoes)
        .fold<int>(0, (sum, item) => sum + (item.repeticoesReal ?? 0));
    final totalVolume = workoutRecords
        .expand((item) => item.execucoes)
        .fold<double>(
          0,
          (sum, item) =>
              sum + ((item.cargaReal ?? 0) * (item.repeticoesReal ?? 0)),
        );
    final avgDuration = sessions == 0 ? 0 : totalDuration ~/ sessions;
    final monthlyVolumes = <String, double>{};
    final monthFormat = DateFormat('MMM/yy');
    for (final record in workoutRecords) {
      final date =
          record.finalizadoEm ?? record.iniciadoEm ?? record.planejadoPara;
      if (date == null) {
        continue;
      }
      final key = monthFormat.format(date);
      monthlyVolumes[key] =
          (monthlyVolumes[key] ?? 0) +
          record.execucoes.fold<double>(
            0,
            (sum, item) =>
                sum + ((item.cargaReal ?? 0) * (item.repeticoesReal ?? 0)),
          );
    }
    final maxVolume = monthlyVolumes.values.isEmpty
        ? 1.0
        : monthlyVolumes.values.reduce((a, b) => a > b ? a : b);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(label: 'Sessoes de treinos', value: '$sessions'),
            _MetricCard(
              label: 'Tempo total (h)',
              value: (totalDuration / 3600).toStringAsFixed(1),
            ),
            _MetricCard(
              label: 'Duracao media',
              value: _formatDuration(Duration(seconds: avgDuration)),
            ),
            _MetricCard(label: 'Series concluidas', value: '$completedSeries'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF4B506F),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Volume',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text(
                '${totalVolume.toStringAsFixed(1)} kg',
                style: const TextStyle(color: Colors.white, fontSize: 40),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalReps reps registradas',
                style: const TextStyle(color: Color(0xFFD3D8F2)),
              ),
              const SizedBox(height: 18),
              for (final entry in monthlyVolumes.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: entry.value / maxVolume,
                            minHeight: 12,
                            backgroundColor: const Color(0xFF656A87),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFE24B6A),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        entry.value.toStringAsFixed(0),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openExerciseDetails(AdminWorkoutExercise exercise) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutExerciseDetailPage(
          exercise: exercise,
          exerciseInfo: _exercisePool
              .where((item) => item.id == exercise.exercicioId)
              .firstOrNull,
          records: _records,
        ),
      ),
    );
  }
}

class WorkoutExerciseDetailPage extends StatefulWidget {
  const WorkoutExerciseDetailPage({
    super.key,
    required this.exercise,
    required this.records,
    this.exerciseInfo,
  });

  final AdminWorkoutExercise exercise;
  final AdminExercise? exerciseInfo;
  final List<WorkoutRecord> records;

  @override
  State<WorkoutExerciseDetailPage> createState() =>
      _WorkoutExerciseDetailPageState();
}

class _WorkoutExerciseDetailPageState extends State<WorkoutExerciseDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history =
        widget.records
            .where(
              (record) => record.execucoes.any(
                (item) => item.exercicioId == widget.exercise.exercicioId,
              ),
            )
            .toList()
          ..sort((a, b) {
            final aDate = a.finalizadoEm ?? a.iniciadoEm ?? a.planejadoPara;
            final bDate = b.finalizadoEm ?? b.iniciadoEm ?? b.planejadoPara;
            if (aDate == null || bDate == null) {
              return 0;
            }
            return bDate.compareTo(aDate);
          });
    final totalVolume = history
        .expand((item) => item.execucoes)
        .where((item) => item.exercicioId == widget.exercise.exercicioId)
        .fold<double>(
          0,
          (sum, item) =>
              sum + ((item.cargaReal ?? 0) * (item.repeticoesReal ?? 0)),
        );
    final totalReps = history
        .expand((item) => item.execucoes)
        .where((item) => item.exercicioId == widget.exercise.exercicioId)
        .fold<int>(0, (sum, item) => sum + (item.repeticoesReal ?? 0));

    return Scaffold(
      backgroundColor: const Color(0xFF353958),
      appBar: AppBar(title: Text(widget.exercise.exercicioNome)),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFF4D8EFF),
            ),
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFD3D8F2),
            padding: const EdgeInsets.all(16),
            tabs: const [
              Tab(text: 'Resumo'),
              Tab(text: 'Historico'),
              Tab(text: 'Estatisticas'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEEEFF3), Color(0xFFD7DCE8)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center,
                          size: 96,
                          color: Color(0xFF59627C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.exercise.exercicioNome,
                      style: const TextStyle(color: Colors.white, fontSize: 22),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.exerciseInfo?.descricao ??
                          'Exercicio planejado com ${widget.exercise.series} series de ${widget.exercise.repeticoes} repeticoes. Ajuste carga e reps conforme sua execucao.',
                      style: const TextStyle(
                        color: Color(0xFFF1F2F8),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Musculos primarios',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.exerciseInfo?.grupoMuscular ?? 'Nao informado',
                      style: const TextStyle(color: Color(0xFFD3D8F2)),
                    ),
                    if ((widget.exerciseInfo?.equipamento ?? '')
                        .isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Equipamento',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.exerciseInfo!.equipamento!,
                        style: const TextStyle(color: Color(0xFFD3D8F2)),
                      ),
                    ],
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (history.isEmpty)
                      const _InfoCard(
                        child: Text(
                          'Nenhum historico encontrado para este exercicio.',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    else
                      for (final record in history)
                        _ExerciseHistoryGroup(
                          record: record,
                          exercicioId: widget.exercise.exercicioId,
                        ),
                  ],
                ),
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _MetricCard(
                      label: 'Volume total',
                      value: '${totalVolume.toStringAsFixed(1)} kg',
                    ),
                    const SizedBox(height: 12),
                    _MetricCard(label: 'Reps registradas', value: '$totalReps'),
                    const SizedBox(height: 12),
                    _MetricCard(
                      label: 'Ultima carga',
                      value: history.isEmpty
                          ? '-'
                          : '${history.first.execucoes.where((item) => item.exercicioId == widget.exercise.exercicioId).first.cargaReal?.toStringAsFixed(1) ?? '-'} kg',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  const _DetailHero({
    required this.workout,
    required this.onBack,
    required this.onEditWorkout,
    required this.onToggleEditMode,
    required this.editMode,
  });

  final AdminWorkout workout;
  final VoidCallback onBack;
  final VoidCallback onEditWorkout;
  final VoidCallback onToggleEditMode;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat("d 'de' MMMM", 'pt_BR');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF131416), Color(0xFF505050)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ActionIcon(onTap: onBack, icon: Icons.arrow_back_ios_new),
              const Spacer(),
              _ActionIcon(onTap: onEditWorkout, icon: Icons.edit_outlined),
              const SizedBox(width: 12),
              _ActionIcon(
                onTap: onToggleEditMode,
                icon: editMode ? Icons.check : Icons.more_horiz,
              ),
            ],
          ),
          const SizedBox(height: 120),
          Text(
            workout.nome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            workout.dataTreino != null
                ? 'Comeca em ${dateFormat.format(workout.dataTreino!)}'
                : 'Plano sem data definida',
            style: const TextStyle(color: Color(0xFFF1F2F8), fontSize: 18),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    super.key,
    required this.exercise,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showDragHandle = false,
  });

  final AdminWorkoutExercise exercise;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4B506F),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAEE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.fitness_center, color: Color(0xFF5C647C)),
        ),
        title: Text(
          exercise.exercicioNome,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        subtitle: Text(
          '${exercise.series} series x ${exercise.repeticoes} reps',
          style: const TextStyle(color: Color(0xFFD3D8F2), fontSize: 16),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDragHandle)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.drag_handle, color: Colors.white70),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit' && onEdit != null) {
                  onEdit!();
                }
                if (value == 'delete' && onDelete != null) {
                  onDelete!();
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Editar exercicio'),
                  ),
                if (onDelete != null)
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Excluir exercicio'),
                  ),
              ],
              icon: const Icon(Icons.more_horiz, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF4B506F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFD3D8F2))),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 34),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF4B506F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _ExerciseHistoryGroup extends StatelessWidget {
  const _ExerciseHistoryGroup({
    required this.record,
    required this.exercicioId,
  });

  final WorkoutRecord record;
  final int exercicioId;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
    final date =
        record.finalizadoEm ?? record.iniciadoEm ?? record.planejadoPara;
    final items = record.execucoes
        .where((item) => item.exercicioId == exercicioId)
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF4B506F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date != null ? formatter.format(date) : 'Data nao informada',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    child: Text('${i + 1}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${items[i].cargaReal?.toStringAsFixed(1) ?? '-'} kg x ${items[i].repeticoesReal ?? '-'} reps',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
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

  String _tipo = 'A';
  bool _ativo = true;
  bool _publico = false;
  bool _recorrente = true;
  DateTime _dataTreino = DateTime.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameController = TextEditingController(text: existing?.nome ?? '');
    _descriptionController = TextEditingController(
      text: existing?.descricao ?? '',
    );
    _notesController = TextEditingController(text: existing?.observacoes ?? '');
    _tipo = existing?.tipoTreino ?? 'A';
    _ativo = existing?.ativo ?? true;
    _publico = existing?.publico ?? false;
    _recorrente = existing?.recorrente ?? true;
    _dataTreino = existing?.dataTreino ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dataTreino,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataTreino),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _dataTreino = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return AlertDialog(
      title: Text(widget.existing == null ? 'Criar treino' : 'Editar treino'),
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
                  decoration: const InputDecoration(
                    labelText: 'Nome do treino',
                  ),
                  validator: _requiredField,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'A', child: Text('A')),
                    DropdownMenuItem(value: 'B', child: Text('B')),
                    DropdownMenuItem(value: 'C', child: Text('C')),
                    DropdownMenuItem(
                      value: 'FULL_BODY',
                      child: Text('FULL_BODY'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _tipo = value ?? 'A'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Descricao'),
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
                  title: const Text('Agendamento'),
                  subtitle: Text(formatter.format(_dataTreino)),
                  trailing: TextButton(
                    onPressed: _pickDateTime,
                    child: const Text('Alterar'),
                  ),
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
              'tipoTreino': _tipo,
              'usuarioId': widget.userId,
              'ativo': _ativo,
              'publico': _publico,
              'recorrente': _recorrente,
              'dataTreino': _dataTreino.toIso8601String(),
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _WorkoutExerciseDialog extends StatefulWidget {
  const _WorkoutExerciseDialog({
    required this.exercises,
    required this.order,
    this.existing,
  });

  final List<AdminExercise> exercises;
  final int order;
  final AdminWorkoutExercise? existing;

  @override
  State<_WorkoutExerciseDialog> createState() => _WorkoutExerciseDialogState();
}

class _WorkoutExerciseDialogState extends State<_WorkoutExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _seriesController;
  late final TextEditingController _repsController;
  late final TextEditingController _loadController;
  int? _exerciseId;
  String _dificuldade = 'MODERADA';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _exerciseId = existing?.exercicioId ?? widget.exercises.first.id;
    _seriesController = TextEditingController(text: '${existing?.series ?? 4}');
    _repsController = TextEditingController(
      text: '${existing?.repeticoes ?? 10}',
    );
    _loadController = TextEditingController(
      text: existing?.carga?.toStringAsFixed(1) ?? '',
    );
    _dificuldade = existing?.dificuldade ?? 'MODERADA';
  }

  @override
  void dispose() {
    _seriesController.dispose();
    _repsController.dispose();
    _loadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Adicionar exercicio' : 'Editar exercicio',
      ),
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
                _NumberField(controller: _seriesController, label: 'Series'),
                const SizedBox(height: 12),
                _NumberField(controller: _repsController, label: 'Repeticoes'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _loadController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Carga (kg)'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _dificuldade,
                  decoration: const InputDecoration(labelText: 'Dificuldade'),
                  items: const [
                    DropdownMenuItem(value: 'LEVE', child: Text('LEVE')),
                    DropdownMenuItem(
                      value: 'MODERADA',
                      child: Text('MODERADA'),
                    ),
                    DropdownMenuItem(value: 'ALTA', child: Text('ALTA')),
                  ],
                  onChanged: (value) =>
                      setState(() => _dificuldade = value ?? 'MODERADA'),
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
            Navigator.of(context).pop(
              _ExerciseConfigResult(
                exercicioId: _exerciseId!,
                order: widget.order,
                series: int.parse(_seriesController.text),
                repeticoes: int.parse(_repsController.text),
                carga: _loadController.text.trim().isEmpty
                    ? null
                    : double.parse(_loadController.text.replaceAll(',', '.')),
                dificuldade: _dificuldade,
              ),
            );
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

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
          return 'Informe um numero valido';
        }
        return null;
      },
    );
  }
}

class _ExerciseConfigResult {
  const _ExerciseConfigResult({
    required this.exercicioId,
    required this.order,
    required this.series,
    required this.repeticoes,
    required this.dificuldade,
    this.carga,
  });

  final int exercicioId;
  final int order;
  final int series;
  final int repeticoes;
  final double? carga;
  final String dificuldade;

  Map<String, dynamic> toPayload() {
    return {
      'exercicioId': exercicioId,
      'ordem': order,
      'series': series,
      'repeticoes': repeticoes,
      'carga': carga,
      'dificuldade': dificuldade,
    };
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

String? _requiredField(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Campo obrigatorio';
  }
  return null;
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
