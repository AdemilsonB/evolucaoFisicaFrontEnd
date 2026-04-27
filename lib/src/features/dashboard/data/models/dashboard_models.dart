class DashboardOverview {
  const DashboardOverview({
    required this.xpTotal,
    required this.nivelAtual,
    required this.tierAtual,
    required this.treinosRealizados,
    required this.sequenciaAtual,
    required this.medalhasUnicas,
    required this.medalhasRepetiveis,
    required this.missoesSemanais,
    required this.historicoXp,
  });

  final int xpTotal;
  final int nivelAtual;
  final String tierAtual;
  final int treinosRealizados;
  final int sequenciaAtual;
  final int medalhasUnicas;
  final int medalhasRepetiveis;
  final int missoesSemanais;
  final int historicoXp;

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    final perfil = Map<String, dynamic>.from(json['perfil'] as Map? ?? const {});
    final medalhasUnicas = List<dynamic>.from(
      json['medalhasUnicas'] as List? ?? const [],
    );
    final medalhasRepetiveis = List<dynamic>.from(
      json['medalhasRepetiveis'] as List? ?? const [],
    );
    final missoesSemanais = List<dynamic>.from(
      json['missoesSemanais'] as List? ?? const [],
    );
    final historicoXp = List<dynamic>.from(
      json['historicoXp'] as List? ?? const [],
    );

    return DashboardOverview(
      xpTotal: (perfil['xpTotal'] as num?)?.toInt() ?? 0,
      nivelAtual: (perfil['nivelAtual'] as num?)?.toInt() ?? 0,
      tierAtual: perfil['tierAtual'] as String? ?? '-',
      treinosRealizados: (perfil['treinosRealizados'] as num?)?.toInt() ?? 0,
      sequenciaAtual: (perfil['sequenciaAtual'] as num?)?.toInt() ?? 0,
      medalhasUnicas: medalhasUnicas.length,
      medalhasRepetiveis: medalhasRepetiveis.length,
      missoesSemanais: missoesSemanais.length,
      historicoXp: historicoXp.length,
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
