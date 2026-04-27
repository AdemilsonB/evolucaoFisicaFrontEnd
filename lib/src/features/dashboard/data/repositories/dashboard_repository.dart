import '../../../../core/constants/api_paths.dart';
import '../../../../core/network/api_client.dart';
import '../models/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<DashboardOverview> loadDashboard(int usuarioId) async {
    final response = await _apiClient.getMap(
      ApiPaths.dashboardGamificacao(usuarioId),
    );
    return DashboardOverview.fromJson(response);
  }

  Future<List<RankingEntry>> loadRankingGeral() async {
    final response = await _apiClient.getList(ApiPaths.rankingGeral);
    return response
        .map((item) => RankingEntry.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }
}
