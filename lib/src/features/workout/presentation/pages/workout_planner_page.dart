import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_scope.dart';
import '../../../admin/data/models/admin_models.dart';

class WorkoutPlannerPage extends StatefulWidget {
  const WorkoutPlannerPage({super.key});

  @override
  State<WorkoutPlannerPage> createState() => _WorkoutPlannerPageState();
}

class _WorkoutPlannerPageState extends State<WorkoutPlannerPage> {
  bool _loading = true;
  String? _error;
  List<AdminWorkout> _workouts = const [];
  List<AdminExercise> _exercises = const [];

  int get _userId =>
      AppScope.of(context).authRepository.currentSession!.user.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repository = AppScope.of(context).adminRepository;
      final results = await Future.wait([
        repository.loadWorkouts(_userId),
        repository.loadExercises(),
      ]);

      if (!mounted) {
        return;
      }
      setState(() {
        _workouts = results[0] as List<AdminWorkout>;
        _exercises = results[1] as List<AdminExercise>;
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

  Future<void> _createWorkout() async {
    final repository = AppScope.of(context).adminRepository;
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
      _showMessage('Treino criado com sucesso.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString(), error: true);
    }
  }

  Future<void> _addExercise(AdminWorkout workout) async {
    if (_exercises.isEmpty) {
      _showMessage(
        'Nao ha exercicios cadastrados. Crie um exercicio personalizado primeiro.',
        error: true,
      );
      return;
    }

    final repository = AppScope.of(context).adminRepository;
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _WorkoutExerciseDialog(exercises: _exercises),
    );
    if (!mounted || payload == null) {
      return;
    }

    try {
      await repository.addWorkoutExercise(workout.id, payload);
      await _load();
      if (!mounted) {
        return;
      }
      _showMessage('Exercicio adicionado ao treino.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString(), error: true);
    }
  }

  Future<void> _createCustomExercise() async {
    final repository = AppScope.of(context).adminRepository;
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
      _showMessage('Exercicio criado e disponivel para seus treinos.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(error.toString(), error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).authRepository.currentSession!;
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu treino'),
        actions: [
          TextButton.icon(
            onPressed: _createCustomExercise,
            icon: const Icon(Icons.fitness_center),
            label: const Text('Novo exercicio'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
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
                            'Monte sua rotina',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use exercicios ja existentes ou cadastre um personalizado quando precisar. Usuario atual: ${session.user.nome}.',
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              FilledButton.icon(
                                onPressed: _createWorkout,
                                icon: const Icon(Icons.add),
                                label: const Text('Criar treino'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _createCustomExercise,
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text(
                                  'Adicionar exercicio personalizado',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_workouts.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Voce ainda nao possui treinos. Crie o primeiro para comecar.',
                        ),
                      ),
                    )
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workout.nome,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${workout.tipoTreino} • ${workout.dataTreino != null ? formatter.format(workout.dataTreino!) : 'Sem agenda'}',
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _addExercise(workout),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Adicionar exercicio'),
                                  ),
                                ],
                              ),
                              if ((workout.descricao ?? '').isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(workout.descricao!),
                              ],
                              const SizedBox(height: 16),
                              if (workout.exercicios.isEmpty)
                                const Text('Nenhum exercicio neste treino.')
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
              ),
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
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String _tipo = 'A';
  bool _ativo = true;
  bool _publico = false;
  bool _recorrente = true;
  DateTime _dataTreino = DateTime.now();

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

class _WorkoutExerciseDialog extends StatefulWidget {
  const _WorkoutExerciseDialog({required this.exercises});

  final List<AdminExercise> exercises;

  @override
  State<_WorkoutExerciseDialog> createState() => _WorkoutExerciseDialogState();
}

class _WorkoutExerciseDialogState extends State<_WorkoutExerciseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _orderController = TextEditingController(text: '1');
  final _seriesController = TextEditingController(text: '4');
  final _repsController = TextEditingController(text: '10');
  final _loadController = TextEditingController();

  int? _exerciseId;
  String _dificuldade = 'MODERADA';

  @override
  void initState() {
    super.initState();
    _exerciseId = widget.exercises.first.id;
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
      title: const Text('Adicionar exercicio'),
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
                _NumberField(controller: _orderController, label: 'Ordem'),
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
            Navigator.of(context).pop({
              'exercicioId': _exerciseId,
              'ordem': int.parse(_orderController.text),
              'series': int.parse(_seriesController.text),
              'repeticoes': int.parse(_repsController.text),
              'carga': _loadController.text.trim().isEmpty
                  ? null
                  : double.parse(_loadController.text.replaceAll(',', '.')),
              'dificuldade': _dificuldade,
            });
          },
          child: const Text('Adicionar'),
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
