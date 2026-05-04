import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/app_scope.dart';
import '../../../admin/data/models/admin_models.dart';
import '../../data/models/workout_models.dart';

class WorkoutExecutionPage extends StatefulWidget {
  const WorkoutExecutionPage({
    super.key,
    required this.workout,
    required this.records,
  });

  final AdminWorkout workout;
  final List<WorkoutRecord> records;

  @override
  State<WorkoutExecutionPage> createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  final _notesController = TextEditingController();
  late final Stopwatch _stopwatch;

  Timer? _timer;
  WorkoutRecord? _record;
  bool _loading = true;
  int _selectedExerciseIndex = 0;
  int _selectedTab = 0;
  List<_ExerciseExecutionState> _exerciseStates = const [];

  int get _userId =>
      AppScope.of(context).authRepository.currentSession!.user.id;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _start();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final repository = AppScope.of(context).workoutRepository;
      final planned = await repository.createWorkoutRecord(
        usuarioId: _userId,
        treinoId: widget.workout.id,
        plannedFor: DateTime.now(),
      );
      final started = await repository.startWorkoutRecord(
        planned.id,
        DateTime.now(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _record = started;
        final orderedExercises = widget.workout.exercicios.toList()
          ..sort((a, b) => a.ordem.compareTo(b.ordem));
        _exerciseStates = orderedExercises
            .map(
              (exercise) => _ExerciseExecutionState.fromWorkoutExercise(
                exercise,
                widget.records,
              ),
            )
            .toList();
        _loading = false;
      });
      _stopwatch.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() {});
        }
      });
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
      Navigator.of(context).pop();
    }
  }

  Future<void> _completeSeries() async {
    final record = _record;
    if (record == null) {
      return;
    }
    final repository = AppScope.of(context).workoutRepository;
    final exerciseState = _exerciseStates[_selectedExerciseIndex];
    final series = exerciseState.series[exerciseState.currentSeriesIndex];

    try {
      await repository.registerExerciseExecution(
        recordId: record.id,
        exercicioId: exerciseState.exercise.exercicioId,
        treinoExercicioId: exerciseState.exercise.id,
        cargaReal: series.weight,
        repeticoesReal: series.reps,
        concluido:
            exerciseState.currentSeriesIndex == exerciseState.series.length - 1,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        series.completed = true;
        if (exerciseState.currentSeriesIndex <
            exerciseState.series.length - 1) {
          exerciseState.currentSeriesIndex += 1;
        } else if (_selectedExerciseIndex < _exerciseStates.length - 1) {
          _selectedExerciseIndex += 1;
        }
      });
      if (_isWorkoutCompleted) {
        await _finishWorkout();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  bool get _isWorkoutCompleted => _exerciseStates.every(
    (exercise) => exercise.series.every((item) => item.completed),
  );

  Future<void> _finishWorkout() async {
    _stopwatch.stop();
    final repository = AppScope.of(context).workoutRepository;
    final navigator = Navigator.of(context);
    final motivacao = await showDialog<String>(
      context: context,
      builder: (context) {
        String selected = 'ALTA';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Finalizar treino'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    items: const [
                      DropdownMenuItem(
                        value: 'ALTA',
                        child: Text('Motivacao alta'),
                      ),
                      DropdownMenuItem(
                        value: 'MEDIA',
                        child: Text('Motivacao media'),
                      ),
                      DropdownMenuItem(
                        value: 'BAIXA',
                        child: Text('Motivacao baixa'),
                      ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => selected = value ?? 'ALTA'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Observacao'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(selected),
                  child: const Text('Finalizar'),
                ),
              ],
            );
          },
        );
      },
    );
    if (motivacao == null || !mounted || _record == null) {
      return;
    }
    await repository.finishWorkoutRecord(
      recordId: _record!.id,
      finishedAt: DateTime.now(),
      observacao: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      motivacao: motivacao,
    );
    if (!mounted) {
      return;
    }
    navigator.pop();
  }

  Future<bool> _handleBack() async {
    if (_record == null) {
      return true;
    }
    final repository = AppScope.of(context).workoutRepository;
    final shouldAbort = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Abortar treino?'),
          content: const Text(
            'As series ja registradas serao mantidas, mas o treino ficara abortado.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Continuar treino'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Abortar'),
            ),
          ],
        );
      },
    );
    if (shouldAbort != true) {
      return false;
    }
    await repository.abortWorkoutRecord(
      recordId: _record!.id,
      abortedAt: DateTime.now(),
      observacao: 'Treino abortado pelo usuario.',
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF353958),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final exerciseState = _exerciseStates[_selectedExerciseIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        final canLeave = await _handleBack();
        if (canLeave && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF353958),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  _CircleAction(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      final canLeave = await _handleBack();
                      if (canLeave && mounted) {
                        navigator.pop();
                      }
                    },
                  ),
                  const Spacer(),
                  Text(
                    _formatElapsed(_stopwatch.elapsed),
                    style: const TextStyle(color: Colors.white, fontSize: 28),
                  ),
                  const Spacer(),
                  _CircleAction(icon: Icons.hourglass_bottom, onTap: () {}),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _exerciseStates.length; i++)
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _selectedExerciseIndex
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAEE),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFF5C647C),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exerciseState.exercise.exercicioNome,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tempo de descanso • ${_formatRestDuration(const Duration(minutes: 2))}',
                          style: const TextStyle(
                            color: Color(0xFFF1F2F8),
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SegmentedButton<int>(
                style: SegmentedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF444965),
                  selectedBackgroundColor: const Color(0xFF4D8EFF),
                ),
                segments: const [
                  ButtonSegment(value: 0, label: Text('Historico')),
                  ButtonSegment(value: 1, label: Text('Notas')),
                  ButtonSegment(value: 2, label: Text('Estatisticas')),
                ],
                selected: {_selectedTab},
                onSelectionChanged: (value) {
                  setState(() {
                    _selectedTab = value.first;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_selectedTab == 0)
                _ExecutionInfoCard(
                  child: _ExerciseExecutionHistory(
                    exercicioId: exerciseState.exercise.exercicioId,
                    records: widget.records,
                  ),
                )
              else if (_selectedTab == 1)
                _ExecutionInfoCard(
                  child: TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notas do treino',
                    ),
                  ),
                )
              else
                _ExecutionInfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Series planejadas: ${exerciseState.exercise.series}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reps alvo: ${exerciseState.exercise.repeticoes}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              for (var i = 0; i < exerciseState.series.length; i++)
                _SeriesCard(
                  title: 'Serie ${i + 1}',
                  target: '${exerciseState.exercise.repeticoes} reps',
                  series: exerciseState.series[i],
                  active: i == exerciseState.currentSeriesIndex,
                  completed: exerciseState.series[i].completed,
                  onWeightChanged: (delta) {
                    setState(() {
                      exerciseState.series[i].weight =
                          (exerciseState.series[i].weight + delta).clamp(
                            0,
                            999,
                          );
                    });
                  },
                  onRepsChanged: (delta) {
                    setState(() {
                      exerciseState.series[i].reps =
                          (exerciseState.series[i].reps + delta).clamp(0, 999);
                    });
                  },
                  onComplete: i == exerciseState.currentSeriesIndex
                      ? _completeSeries
                      : null,
                ),
              if (_isWorkoutCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: FilledButton(
                    onPressed: _finishWorkout,
                    child: const Text('Finalizar treino'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF5663A0)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _ExecutionInfoCard extends StatelessWidget {
  const _ExecutionInfoCard({required this.child});

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

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({
    required this.title,
    required this.target,
    required this.series,
    required this.active,
    required this.completed,
    required this.onWeightChanged,
    required this.onRepsChanged,
    this.onComplete,
  });

  final String title;
  final String target;
  final _SeriesState series;
  final bool active;
  final bool completed;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<int> onRepsChanged;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF4B506F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFF565D80),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        target,
                        style: const TextStyle(
                          color: Color(0xFFD3D8F2),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz, color: Colors.white),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _StepperField(
                  label: 'Peso (kg)',
                  value: series.weight.toStringAsFixed(1),
                  onDecrease: active && !completed
                      ? () => onWeightChanged(-0.5)
                      : null,
                  onIncrease: active && !completed
                      ? () => onWeightChanged(0.5)
                      : null,
                ),
                const Divider(color: Color(0xFF697089), height: 32),
                _StepperField(
                  label: 'Reps',
                  value: '${series.reps}',
                  onDecrease: active && !completed
                      ? () => onRepsChanged(-1)
                      : null,
                  onIncrease: active && !completed
                      ? () => onRepsChanged(1)
                      : null,
                ),
              ],
            ),
          ),
          if (onComplete != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: completed ? null : onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2EAF73),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                ),
                child: Text(completed ? 'Serie concluida' : 'Completar serie'),
              ),
            ),
        ],
      ),
    );
  }
}

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    this.onDecrease,
    this.onIncrease,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepperButton(icon: Icons.remove_circle_outline, onTap: onDecrease),
        Expanded(
          child: Column(
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 34),
              ),
            ],
          ),
        ),
        _StepperButton(icon: Icons.add_circle_outline, onTap: onIncrease),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white, size: 38),
    );
  }
}

class _ExerciseExecutionHistory extends StatelessWidget {
  const _ExerciseExecutionHistory({
    required this.exercicioId,
    required this.records,
  });

  final int exercicioId;
  final List<WorkoutRecord> records;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat("d 'de' MMMM", 'pt_BR');
    final filtered =
        records
            .where(
              (record) => record.execucoes.any(
                (item) => item.exercicioId == exercicioId,
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

    if (filtered.isEmpty) {
      return const Text(
        'Nenhum historico encontrado para este exercicio.',
        style: TextStyle(color: Colors.white),
      );
    }

    final last = filtered.first.execucoes
        .where((item) => item.exercicioId == exercicioId)
        .first;
    final date =
        filtered.first.finalizadoEm ??
        filtered.first.iniciadoEm ??
        filtered.first.planejadoPara;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date != null ? formatter.format(date) : 'Ultima execucao',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 10),
        Text(
          '${last.cargaReal?.toStringAsFixed(1) ?? '-'} kg x ${last.repeticoesReal ?? '-'} reps',
          style: const TextStyle(color: Color(0xFFD3D8F2), fontSize: 18),
        ),
      ],
    );
  }
}

class _ExerciseExecutionState {
  _ExerciseExecutionState({required this.exercise, required this.series});

  final AdminWorkoutExercise exercise;
  final List<_SeriesState> series;
  int currentSeriesIndex = 0;

  factory _ExerciseExecutionState.fromWorkoutExercise(
    AdminWorkoutExercise exercise,
    List<WorkoutRecord> records,
  ) {
    final lastExecution =
        records
            .expand((record) => record.execucoes)
            .where(
              (item) =>
                  item.exercicioId == exercise.exercicioId &&
                  item.cargaReal != null,
            )
            .toList()
          ..sort((a, b) => (b.id).compareTo(a.id));
    final suggestedWeight = lastExecution.isNotEmpty
        ? lastExecution.first.cargaReal ?? exercise.carga ?? 0
        : exercise.carga ?? 0;
    final suggestedReps = lastExecution.isNotEmpty
        ? lastExecution.first.repeticoesReal ?? exercise.repeticoes
        : exercise.repeticoes;
    return _ExerciseExecutionState(
      exercise: exercise,
      series: List.generate(
        exercise.series,
        (_) => _SeriesState(weight: suggestedWeight, reps: suggestedReps),
      ),
    );
  }
}

class _SeriesState {
  _SeriesState({required this.weight, required this.reps});

  double weight;
  int reps;
  bool completed = false;
}

String _formatElapsed(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hours = duration.inHours;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
  }
  return '$minutes:$seconds';
}

String _formatRestDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
