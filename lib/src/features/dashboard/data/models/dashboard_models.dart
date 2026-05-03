class DashboardOverview {
  const DashboardOverview({
    required this.profile,
    required this.uniqueMedals,
    required this.repeatableMedals,
    required this.weeklyMissions,
    required this.xpRules,
    required this.xpHistory,
  });

  final DashboardProfile profile;
  final List<UserMedal> uniqueMedals;
  final List<UserMedal> repeatableMedals;
  final List<WeeklyMissionProgress> weeklyMissions;
  final List<XpRuleInfo> xpRules;
  final List<XpHistoryEntry> xpHistory;

  List<UserMedal> get conqueredMedals => [
    ...uniqueMedals,
    ...repeatableMedals,
  ].where((medal) => medal.quantity > 0).toList();

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      profile: DashboardProfile.fromJson(
        Map<String, dynamic>.from(json['perfil'] as Map? ?? const {}),
      ),
      uniqueMedals: _mapList(json['medalhasUnicas'], UserMedal.fromJson),
      repeatableMedals: _mapList(
        json['medalhasRepetiveis'],
        UserMedal.fromJson,
      ),
      weeklyMissions: _mapList(
        json['missoesSemanais'],
        WeeklyMissionProgress.fromJson,
      ),
      xpRules: _mapList(json['regrasXp'], XpRuleInfo.fromJson),
      xpHistory: _mapList(json['historicoXp'], XpHistoryEntry.fromJson),
    );
  }
}

class DashboardProfile {
  const DashboardProfile({
    required this.userId,
    required this.treinosRealizados,
    required this.sequenciaAtual,
    required this.melhorSequencia,
    required this.xpTotal,
    required this.nivelAtual,
    required this.tierAtual,
    required this.xpAtualNivel,
    required this.xpNecessarioProximoNivel,
    required this.percentualProgressoNivel,
    this.dataInicio,
    this.pesoInicial,
    this.pesoAtual,
  });

  final int userId;
  final DateTime? dataInicio;
  final double? pesoInicial;
  final double? pesoAtual;
  final int treinosRealizados;
  final int sequenciaAtual;
  final int melhorSequencia;
  final int xpTotal;
  final int nivelAtual;
  final String tierAtual;
  final int xpAtualNivel;
  final int xpNecessarioProximoNivel;
  final int percentualProgressoNivel;

  int get xpRestante => xpNecessarioProximoNivel - xpAtualNivel;

  factory DashboardProfile.fromJson(Map<String, dynamic> json) {
    return DashboardProfile(
      userId: (json['usuarioId'] as num?)?.toInt() ?? 0,
      dataInicio: _parseDate(json['dataInicio']),
      pesoInicial: _toDouble(json['pesoInicial']),
      pesoAtual: _toDouble(json['pesoAtual']),
      treinosRealizados: (json['treinosRealizados'] as num?)?.toInt() ?? 0,
      sequenciaAtual: (json['sequenciaAtual'] as num?)?.toInt() ?? 0,
      melhorSequencia: (json['melhorSequencia'] as num?)?.toInt() ?? 0,
      xpTotal: (json['xpTotal'] as num?)?.toInt() ?? 0,
      nivelAtual: (json['nivelAtual'] as num?)?.toInt() ?? 0,
      tierAtual: json['tierAtual'] as String? ?? '-',
      xpAtualNivel: (json['xpAtualNivel'] as num?)?.toInt() ?? 0,
      xpNecessarioProximoNivel:
          (json['xpNecessarioProximoNivel'] as num?)?.toInt() ?? 0,
      percentualProgressoNivel:
          (json['percentualProgressoNivel'] as num?)?.toInt() ?? 0,
    );
  }
}

class UserMedal {
  const UserMedal({
    required this.medalhaId,
    required this.nome,
    required this.tipo,
    required this.quantity,
    required this.valorMeta,
    this.descricao,
    this.ultimaConquistaEm,
  });

  final int medalhaId;
  final String nome;
  final String? descricao;
  final String tipo;
  final int quantity;
  final double valorMeta;
  final DateTime? ultimaConquistaEm;

  String get progressLabel {
    if (quantity <= 1) {
      return 'Conquistada';
    }
    return '${quantity}x conquistada';
  }

  factory UserMedal.fromJson(Map<String, dynamic> json) {
    return UserMedal(
      medalhaId: (json['medalhaId'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      tipo: json['tipo'] as String? ?? '',
      quantity: (json['quantidade'] as num?)?.toInt() ?? 0,
      valorMeta: _toDouble(json['valorMeta']) ?? 0,
      ultimaConquistaEm: _parseDate(json['ultimaConquistaEm']),
    );
  }
}

class WeeklyMissionProgress {
  const WeeklyMissionProgress({
    required this.id,
    required this.nome,
    required this.tipoRegra,
    required this.metaValor,
    required this.xpRecompensa,
    required this.ativo,
    this.descricao,
  });

  final int id;
  final String nome;
  final String? descricao;
  final String tipoRegra;
  final double metaValor;
  final int xpRecompensa;
  final bool ativo;

  factory WeeklyMissionProgress.fromJson(Map<String, dynamic> json) {
    return WeeklyMissionProgress(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      tipoRegra: json['tipoRegra'] as String? ?? '',
      metaValor: _toDouble(json['metaValor']) ?? 0,
      xpRecompensa: (json['xpRecompensa'] as num?)?.toInt() ?? 0,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

class XpRuleInfo {
  const XpRuleInfo({
    required this.id,
    required this.nome,
    required this.tipoRegra,
    required this.ativo,
    this.xpConcedido,
    this.percentualBonus,
    this.descricao,
  });

  final int id;
  final String nome;
  final String tipoRegra;
  final int? xpConcedido;
  final double? percentualBonus;
  final String? descricao;
  final bool ativo;

  factory XpRuleInfo.fromJson(Map<String, dynamic> json) {
    return XpRuleInfo(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      tipoRegra: json['tipoRegra'] as String? ?? '',
      xpConcedido: (json['xpConcedido'] as num?)?.toInt(),
      percentualBonus: _toDouble(json['percentualBonus']),
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

class XpHistoryEntry {
  const XpHistoryEntry({
    required this.id,
    required this.tipoRegra,
    required this.xpConcedido,
    this.referenciaId,
  });

  final int id;
  final String tipoRegra;
  final int xpConcedido;
  final int? referenciaId;

  factory XpHistoryEntry.fromJson(Map<String, dynamic> json) {
    return XpHistoryEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipoRegra: json['tipoRegra'] as String? ?? '',
      xpConcedido: (json['xpConcedido'] as num?)?.toInt() ?? 0,
      referenciaId: (json['referenciaId'] as num?)?.toInt(),
    );
  }
}

class RankingEntry {
  const RankingEntry({
    required this.posicao,
    required this.username,
    required this.xpTotal,
    required this.nivelAtual,
    required this.tierAtual,
  });

  final int posicao;
  final String username;
  final int xpTotal;
  final int nivelAtual;
  final String tierAtual;

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      posicao: (json['posicao'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      xpTotal: (json['xpTotal'] as num?)?.toInt() ?? 0,
      nivelAtual: (json['nivelAtual'] as num?)?.toInt() ?? 0,
      tierAtual: json['tierAtual'] as String? ?? '-',
    );
  }
}

List<T> _mapList<T>(
  Object? source,
  T Function(Map<String, dynamic> json) mapper,
) {
  final items = List<dynamic>.from(source as List? ?? const []);
  return items
      .map((item) => mapper(Map<String, dynamic>.from(item as Map)))
      .toList();
}

double? _toDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

DateTime? _parseDate(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
