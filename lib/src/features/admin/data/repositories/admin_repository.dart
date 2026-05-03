import '../../../../core/constants/api_paths.dart';
import '../../../../core/network/api_client.dart';
import '../models/admin_models.dart';

class AdminRepository {
  AdminRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<AdminUserSummary>> loadUsers() async {
    final response = await _apiClient.getList(ApiPaths.usuarios);
    return response
        .map(
          (item) =>
              AdminUserSummary.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
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

  Future<void> deleteExercise(int id) {
    return _apiClient.deleteVoid('${ApiPaths.exercicios}/$id');
  }

  Future<List<AdminFood>> loadFoods() async {
    final response = await _apiClient.getList(ApiPaths.alimentos);
    return response
        .map(
          (item) => AdminFood.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AdminFood> createFood(Map<String, dynamic> payload) async {
    final response = await _apiClient.postMap(
      ApiPaths.alimentos,
      data: payload,
    );
    return AdminFood.fromJson(response);
  }

  Future<AdminFood> updateFood(int id, Map<String, dynamic> payload) async {
    final response = await _apiClient.putMap(
      '${ApiPaths.alimentos}/$id',
      data: payload,
    );
    return AdminFood.fromJson(response);
  }

  Future<void> deleteFood(int id) {
    return _apiClient.deleteVoid('${ApiPaths.alimentos}/$id');
  }

  Future<List<AdminWorkout>> loadWorkouts(int usuarioId) async {
    final response = await _apiClient.getList(
      ApiPaths.treinos,
      queryParameters: {'usuarioId': usuarioId},
    );
    return response
        .map(
          (item) =>
              AdminWorkout.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
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

  Future<List<AdminMealPlan>> loadMealPlans(int usuarioId) async {
    final response = await _apiClient.getList(
      ApiPaths.planosAlimentares,
      queryParameters: {'usuarioId': usuarioId},
    );
    return response
        .map(
          (item) =>
              AdminMealPlan.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AdminMealPlan> createMealPlan(Map<String, dynamic> payload) async {
    final response = await _apiClient.postMap(
      ApiPaths.planosAlimentares,
      data: payload,
    );
    return AdminMealPlan.fromJson(response);
  }

  Future<AdminMealPlanDay> addMealPlanDay(
    int planId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.postMap(
      '${ApiPaths.planosAlimentares}/$planId/dias',
      data: payload,
    );
    return AdminMealPlanDay.fromJson(response);
  }

  Future<AdminMealPlanMeal> addMealPlanMeal(
    int dayId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.postMap(
      '${ApiPaths.planosAlimentares}/dias/$dayId/refeicoes',
      data: payload,
    );
    return AdminMealPlanMeal.fromJson(response);
  }

  Future<AdminMealPlanMealFood> addMealPlanFood(
    int mealId,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.postMap(
      '${ApiPaths.planosAlimentares}/refeicoes/$mealId/alimentos',
      data: payload,
    );
    return AdminMealPlanMealFood.fromJson(response);
  }

  Future<List<AdminXpRule>> loadXpRules() async {
    final response = await _apiClient.getList(ApiPaths.adminXpRules);
    return response
        .map(
          (item) =>
              AdminXpRule.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AdminXpRule> createXpRule(Map<String, dynamic> payload) async {
    final response = await _apiClient.postMap(
      ApiPaths.adminXpRules,
      data: payload,
    );
    return AdminXpRule.fromJson(response);
  }

  Future<AdminXpRule> updateXpRule(int id, Map<String, dynamic> payload) async {
    final response = await _apiClient.putMap(
      '${ApiPaths.adminXpRules}/$id',
      data: payload,
    );
    return AdminXpRule.fromJson(response);
  }

  Future<List<AdminMedal>> loadMedals() async {
    final response = await _apiClient.getList(ApiPaths.adminMedals);
    return response
        .map(
          (item) => AdminMedal.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  Future<AdminMedal> createMedal(Map<String, dynamic> payload) async {
    final response = await _apiClient.postMap(
      ApiPaths.adminMedals,
      data: payload,
    );
    return AdminMedal.fromJson(response);
  }

  Future<AdminMedal> updateMedal(int id, Map<String, dynamic> payload) async {
    final response = await _apiClient.putMap(
      '${ApiPaths.adminMedals}/$id',
      data: payload,
    );
    return AdminMedal.fromJson(response);
  }

  Future<List<AdminWeeklyMission>> loadWeeklyMissions() async {
    final response = await _apiClient.getList(ApiPaths.adminWeeklyMissions);
    return response
        .map(
          (item) => AdminWeeklyMission.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<AdminWeeklyMission> createWeeklyMission(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.postMap(
      ApiPaths.adminWeeklyMissions,
      data: payload,
    );
    return AdminWeeklyMission.fromJson(response);
  }

  Future<AdminWeeklyMission> updateWeeklyMission(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.putMap(
      '${ApiPaths.adminWeeklyMissions}/$id',
      data: payload,
    );
    return AdminWeeklyMission.fromJson(response);
  }
}
