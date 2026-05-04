import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_paths.dart';
import '../../../../core/network/api_client.dart';
import '../../../admin/data/models/admin_models.dart';
import '../models/workout_models.dart';

class WorkoutRepository {
  WorkoutRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  static const _orderPrefix = 'workout_order_';

  final ApiClient _apiClient;

  Future<List<AdminWorkout>> loadWorkouts(int usuarioId) async {
    final response = await _apiClient.getList(
      ApiPaths.treinos,
      queryParameters: {'usuarioId': usuarioId},
    );
    final items = response
        .map(
          (item) =>
              AdminWorkout.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    return _applyOrder(usuarioId, items);
  }

  Future<AdminWorkout> loadWorkoutById(int id) async {
    final response = await _apiClient.getMap('${ApiPaths.treinos}/$id');
    return AdminWorkout.fromJson(response);
  }

  Future<AdminWorkout> createWorkout(Map<String, dynamic> payload) async {
    final response = await _apiClient.postMap(ApiPaths.treinos, data: payload);
    return AdminWorkout.fromJson(response);
  }

  Future<AdminWorkout> updateWorkout(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.putMap(
      '${ApiPaths.treinos}/$id',
      data: payload,
    );
    return AdminWorkout.fromJson(response);
  }

  Future<void> deleteWorkout(int id) {
    return _apiClient.deleteVoid('${ApiPaths.treinos}/$id');
  }

  Future<AdminWorkoutExercise> addWorkoutExercise(
    int workoutId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.postMap(
      '${ApiPaths.treinos}/$workoutId/exercicios',
      data: payload,
    );
    return AdminWorkoutExercise.fromJson(response);
  }

  Future<void> deleteWorkoutExercise(int workoutId, int workoutExerciseId) {
    return _apiClient.deleteVoid(
      '${ApiPaths.treinos}/$workoutId/exercicios/$workoutExerciseId',
    );
  }

  Future<AdminWorkout> replaceWorkoutExercises(
    AdminWorkout workout,
    List<WorkoutExerciseDraft> drafts,
  ) async {
    for (final exercise in workout.exercicios) {
      await deleteWorkoutExercise(workout.id, exercise.id);
    }
    for (final draft in drafts) {
      await addWorkoutExercise(workout.id, draft.toPayload());
    }
    return loadWorkoutById(workout.id);
  }

  Future<List<AdminExercise>> loadExercises() async {
    final response = await _apiClient.getList(ApiPaths.exercicios);
    return response
        .map(
          (item) =>
              AdminExercise.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AdminExercise> createExercise(Map<String, dynamic> payload) async {
    final response = await _apiClient.postMap(
      ApiPaths.exercicios,
      data: payload,
    );
    return AdminExercise.fromJson(response);
  }

  Future<AdminExercise> updateExercise(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.putMap(
      '${ApiPaths.exercicios}/$id',
      data: payload,
    );
    return AdminExercise.fromJson(response);
  }

  Future<List<WorkoutRecord>> loadRecords({
    required int usuarioId,
    required DateTime start,
    required DateTime end,
  }) async {
    final response = await _apiClient.getList(
      ApiPaths.registrosTreino,
      queryParameters: {
        'usuarioId': usuarioId,
        'dataInicio': start.toIso8601String(),
        'dataFim': end.toIso8601String(),
      },
    );
    return response
        .map(
          (item) =>
              WorkoutRecord.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<WorkoutRecord> createWorkoutRecord({
    required int usuarioId,
    required int treinoId,
    required DateTime plannedFor,
    String? observacao,
  }) async {
    final response = await _apiClient.postMap(
      ApiPaths.registrosTreino,
      data: {
        'usuarioId': usuarioId,
        'treinoId': treinoId,
        'planejadoPara': plannedFor.toIso8601String(),
        'observacao': observacao,
      },
    );
    return WorkoutRecord.fromJson(response);
  }

  Future<WorkoutRecord> startWorkoutRecord(
    int recordId,
    DateTime startedAt,
  ) async {
    final response = await _apiClient.putMap(
      '${ApiPaths.registrosTreino}/$recordId/inicio',
      data: {'iniciadoEm': startedAt.toIso8601String()},
    );
    return WorkoutRecord.fromJson(response);
  }

  Future<WorkoutExecutionRecord> registerExerciseExecution({
    required int recordId,
    required int exercicioId,
    int? treinoExercicioId,
    double? cargaReal,
    required int repeticoesReal,
    required bool concluido,
  }) async {
    final response = await _apiClient.postMap(
      '${ApiPaths.registrosTreino}/$recordId/execucoes',
      data: {
        'treinoExercicioId': treinoExercicioId,
        'exercicioId': exercicioId,
        'cargaReal': cargaReal,
        'repeticoesReal': repeticoesReal,
        'concluido': concluido,
      },
    );
    return WorkoutExecutionRecord.fromJson(response);
  }

  Future<WorkoutRecord> finishWorkoutRecord({
    required int recordId,
    required DateTime finishedAt,
    String? observacao,
    String? motivacao,
  }) async {
    final response = await _apiClient.putMap(
      '${ApiPaths.registrosTreino}/$recordId/finalizacao',
      data: {
        'finalizadoEm': finishedAt.toIso8601String(),
        'observacao': observacao,
        'motivacao': motivacao,
      },
    );
    return WorkoutRecord.fromJson(response);
  }

  Future<WorkoutRecord> abortWorkoutRecord({
    required int recordId,
    required DateTime abortedAt,
    String? observacao,
  }) async {
    final response = await _apiClient.putMap(
      '${ApiPaths.registrosTreino}/$recordId/aborto',
      data: {
        'abortadoEm': abortedAt.toIso8601String(),
        'observacao': observacao,
      },
    );
    return WorkoutRecord.fromJson(response);
  }

  Future<void> saveWorkoutOrder(int usuarioId, List<int> workoutIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      '$_orderPrefix$usuarioId',
      jsonEncode(workoutIds),
    );
  }

  Future<List<AdminWorkout>> _applyOrder(
    int usuarioId,
    List<AdminWorkout> workouts,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('$_orderPrefix$usuarioId');
    if (raw == null || raw.isEmpty) {
      workouts.sort((a, b) {
        final aDate = a.dataTreino ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.dataTreino ?? DateTime.fromMillisecondsSinceEpoch(0);
        return aDate.compareTo(bDate);
      });
      return workouts;
    }

    final decoded = jsonDecode(raw);
    final orderedIds = List<int>.from(decoded as List);
    final orderMap = <int, int>{
      for (var i = 0; i < orderedIds.length; i++) orderedIds[i]: i,
    };

    workouts.sort((a, b) {
      final aOrder = orderMap[a.id];
      final bOrder = orderMap[b.id];
      if (aOrder != null && bOrder != null) {
        return aOrder.compareTo(bOrder);
      }
      if (aOrder != null) {
        return -1;
      }
      if (bOrder != null) {
        return 1;
      }
      final aDate = a.dataTreino ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.dataTreino ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return workouts;
  }
}
