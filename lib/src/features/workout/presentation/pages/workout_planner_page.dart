import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_scope.dart';
import '../../../admin/data/models/admin_models.dart';
import '../../data/models/workout_models.dart';
import 'workout_plan_detail_page.dart';

class WorkoutPlannerPage extends StatefulWidget {
  const WorkoutPlannerPage({super.key});

  @override
  State<WorkoutPlannerPage> createState() => _WorkoutPlannerPageState();
}

class _WorkoutPlannerPageState extends State<WorkoutPlannerPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  bool _loading = true;
  bool _orderingWorkouts = false;
  String? _error;
  List<AdminWorkout> _workouts = const [];
  List<AdminExercise> _exercises = const [];
  List<WorkoutRecord> _records = const [];

  int get _userId =>
      AppScope.of(context).authRepository.currentSession!.user.id;

  @override
  void initState() {
    super.initState();
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
        repository.loadWorkouts(_userId),
        repository.loadExercises(),
        repository.loadRecords(
          usuarioId: _userId,
          start: DateTime.now().subtract(const Duration(days: 180)),
          end: DateTime.now().add(const Duration(days: 1)),
        ),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _workouts = results[0] as List<AdminWorkout>;
        _exercises = results[1] as List<AdminExercise>;
        _records = results[2] as List<WorkoutRecord>;
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

  Future<void> _openWorkout(AdminWorkout workout) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WorkoutPlanDetailPage(
          workoutId: workout.id,
          initialWorkout: workout,
        ),
      ),
    );
    await _load();
  }

  Future<void> _createWorkout() async {
    final repository = AppScope.of(context).workoutRepository;
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _WorkoutDialog(userId: _userId),
    );
    if (!mounted || payload == null) {
      return;
    }
    try {
      await repository.createWorkout(payload);
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Treino criado com sucesso.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _createExercise() async {
    final repository = AppScope.of(context).workoutRepository;
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _ExerciseDialog(),
    );
    if (!mounted || payload == null) {
      return;
    }

    try {
      await repository.createExercise(payload);
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercicio personalizado cadastrado.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _deleteWorkout(AdminWorkout workout) async {
    final repository = AppScope.of(context).workoutRepository;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir treino'),
          content: Text('Deseja excluir "${workout.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      await repository.deleteWorkout(workout.id);
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _saveWorkoutOrder() async {
    await AppScope.of(context).workoutRepository.saveWorkoutOrder(
      _userId,
      _workouts.map((item) => item.id).toList(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _orderingWorkouts = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ordem dos treinos atualizada.')),
    );
  }

  List<DateTime> get _weekDates {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(7, (index) => start.add(Duration(days: index)));
  }

  int get _completedWeekDays {
    final week = _weekDates;
    final completedDates = _records
        .where((record) => record.concluido && record.finalizadoEm != null)
        .map((record) => DateUtils.dateOnly(record.finalizadoEm!))
        .toSet();
    return week
        .where(
          (day) =>
              day.weekday <= DateTime.friday &&
              completedDates.contains(DateUtils.dateOnly(day)),
        )
        .length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF353958),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                children: [
                  _PlannerHeader(
                    weekDates: _weekDates,
                    completedDays: _completedWeekDays,
                    onCreateWorkout: _createWorkout,
                    onCreateExercise: _createExercise,
                    onToggleOrdering: () {
                      setState(() {
                        _orderingWorkouts = !_orderingWorkouts;
                      });
                    },
                    orderingWorkouts: _orderingWorkouts,
                    exerciseCount: _exercises.length,
                  ),
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF4F87FF),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFFBAC1EA),
                    tabs: const [
                      Tab(text: 'Planos'),
                      Tab(text: 'Historico'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildPlansTab(), _buildHistoryTab()],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlansTab() {
    if (_workouts.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _EmptyCard(
            message:
                'Voce ainda nao possui treinos. Crie um plano e adicione exercicios para comecar.',
          ),
        ],
      );
    }

    if (_orderingWorkouts) {
      return Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _workouts.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = _workouts.removeAt(oldIndex);
                  _workouts.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final workout = _workouts[index];
                return _WorkoutPlanTile(
                  key: ValueKey(workout.id),
                  workout: workout,
                  onTap: () => _openWorkout(workout),
                  onDelete: () => _deleteWorkout(workout),
                  showDragHandle: true,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saveWorkoutOrder,
                child: const Text('Salvar ordem dos treinos'),
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final workout in _workouts)
            _WorkoutPlanTile(
              workout: workout,
              onTap: () => _openWorkout(workout),
              onDelete: () => _deleteWorkout(workout),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final records = [..._records]
      ..sort((a, b) {
        final aDate = a.finalizadoEm ?? a.iniciadoEm ?? a.planejadoPara;
        final bDate = b.finalizadoEm ?? b.iniciadoEm ?? b.planejadoPara;
        if (aDate == null || bDate == null) {
          return 0;
        }
        return bDate.compareTo(aDate);
      });

    if (records.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _EmptyCard(
            message:
                'Seu historico de treinos aparecera aqui depois das primeiras execucoes.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _HistoryMonthBanner(records: records),
        const SizedBox(height: 16),
        for (final record in records) _HistoryRecordTile(record: record),
      ],
    );
  }
}

class _PlannerHeader extends StatelessWidget {
  const _PlannerHeader({
    required this.weekDates,
    required this.completedDays,
    required this.onCreateWorkout,
    required this.onCreateExercise,
    required this.onToggleOrdering,
    required this.orderingWorkouts,
    required this.exerciseCount,
  });

  final List<DateTime> weekDates;
  final int completedDays;
  final VoidCallback onCreateWorkout;
  final VoidCallback onCreateExercise;
  final VoidCallback onToggleOrdering;
  final bool orderingWorkouts;
  final int exerciseCount;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final labels = ['seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sab.', 'dom.'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Treinos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _CircleIconButton(
                icon: orderingWorkouts ? Icons.check : Icons.reorder,
                onTap: onToggleOrdering,
              ),
              const SizedBox(width: 12),
              _CircleIconButton(icon: Icons.add, onTap: onCreateWorkout),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < weekDates.length; i++)
                _WeekDayChip(
                  label: labels[i],
                  date: weekDates[i],
                  active: DateUtils.isSameDay(weekDates[i], now),
                  completed:
                      weekDates[i].weekday <= DateTime.friday &&
                      weekDates[i].isBefore(now.add(const Duration(days: 1))),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                '$completedDays/5 dias concluidos',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onCreateExercise,
                icon: const Icon(Icons.fitness_center),
                label: Text('Exercicios ($exerciseCount)'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayChip extends StatelessWidget {
  const _WeekDayChip({
    required this.label,
    required this.date,
    required this.active,
    required this.completed,
  });

  final String label;
  final DateTime date;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF4D8EFF)
        : completed
        ? const Color(0xFF5E7AC5)
        : const Color(0xFF52556F);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF67A1FF) : Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: active ? Border.all(color: const Color(0xFF92B8FF)) : null,
          ),
          child: Center(
            child: Text(
              '${date.day}',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutPlanTile extends StatelessWidget {
  const _WorkoutPlanTile({
    super.key,
    required this.workout,
    required this.onTap,
    required this.onDelete,
    this.showDragHandle = false,
  });

  final AdminWorkout workout;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF4B506F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF18B3A1),
          ),
          child: Text(
            workout.tipoTreino,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          workout.nome,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        subtitle: Text(
          '${workout.exercicios.length} exercicios • ${workout.dataTreino != null ? formatter.format(workout.dataTreino!) : 'sem agenda'}',
          style: const TextStyle(color: Color(0xFFD3D8F2)),
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
                if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Excluir treino'),
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

class _HistoryMonthBanner extends StatelessWidget {
  const _HistoryMonthBanner({required this.records});

  final List<WorkoutRecord> records;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMMM yyyy', 'pt_BR');
    final selected =
        records.first.finalizadoEm ??
        records.first.iniciadoEm ??
        records.first.planejadoPara ??
        DateTime.now();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4B506F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historico',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              formatter.format(selected),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRecordTile extends StatelessWidget {
  const _HistoryRecordTile({required this.record});

  final WorkoutRecord record;

  @override
  Widget build(BuildContext context) {
    final date =
        record.finalizadoEm ??
        record.iniciadoEm ??
        record.planejadoPara ??
        DateTime.now();
    final formatter = DateFormat("EEEE, d 'de' MMMM", 'pt_BR');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF4B506F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: record.concluido
                      ? const Color(0xFF18B3A1)
                      : const Color(0xFF4D8EFF),
                ),
              ),
              Container(width: 3, height: 70, color: const Color(0xFF4D8EFF)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatter.format(date),
                  style: const TextStyle(
                    color: Color(0xFFD3D8F2),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  record.treinoNome,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  '${record.execucoes.where((item) => item.concluido).length}/${record.execucoes.length} exercicios concluidos • ${record.status}',
                  style: const TextStyle(color: Color(0xFFD3D8F2)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF5663A0)),
          color: const Color(0xFF3A3E5D),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _WorkoutDialog extends StatefulWidget {
  const _WorkoutDialog({required this.userId});

  final int userId;

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
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _notesController = TextEditingController();
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
      title: const Text('Criar treino'),
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _ativo,
                  onChanged: (value) => setState(() => _ativo = value),
                  title: const Text('Treino ativo'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _publico,
                  onChanged: (value) => setState(() => _publico = value),
                  title: const Text('Treino publico'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _recorrente,
                  onChanged: (value) => setState(() => _recorrente = value),
                  title: const Text('Treino recorrente'),
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

class _ExerciseDialog extends StatefulWidget {
  const _ExerciseDialog();

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _groupController = TextEditingController();
  final _equipmentController = TextEditingController();
  final _descriptionController = TextEditingController();

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
      title: const Text('Novo exercicio personalizado'),
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
                  validator: _requiredField,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _groupController,
                  decoration: const InputDecoration(
                    labelText: 'Grupo muscular',
                  ),
                  validator: _requiredField,
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
              'ativo': true,
            });
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF4B506F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
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
