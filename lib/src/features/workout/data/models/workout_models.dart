class WorkoutRecord {
  const WorkoutRecord({
    required this.id,
    required this.usuarioId,
    required this.treinoId,
    required this.treinoNome,
    required this.status,
    required this.concluido,
    required this.execucoes,
    this.planejadoPara,
    this.iniciadoEm,
    this.dataRegistro,
    this.abortadoEm,
    this.finalizadoEm,
    this.observacao,
    this.motivacao,
  });

  final int id;
  final int usuarioId;
  final int treinoId;
  final String treinoNome;
  final DateTime? planejadoPara;
  final DateTime? iniciadoEm;
  final DateTime? dataRegistro;
  final DateTime? abortadoEm;
  final DateTime? finalizadoEm;
  final String status;
  final String? observacao;
  final String? motivacao;
  final bool concluido;
  final List<WorkoutExecutionRecord> execucoes;

  Duration? get duration {
    if (iniciadoEm == null || finalizadoEm == null) {
      return null;
    }
    return finalizadoEm!.difference(iniciadoEm!);
  }

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) {
    final execucoes = List<dynamic>.from(
      json['execucoes'] as List? ?? const [],
    );
    return WorkoutRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      usuarioId: (json['usuarioId'] as num?)?.toInt() ?? 0,
      treinoId: (json['treinoId'] as num?)?.toInt() ?? 0,
      treinoNome: json['treinoNome'] as String? ?? '',
      planejadoPara: _toDate(json['planejadoPara']),
      iniciadoEm: _toDate(json['iniciadoEm']),
      dataRegistro: _toDate(json['dataRegistro']),
      abortadoEm: _toDate(json['abortadoEm']),
      finalizadoEm: _toDate(json['finalizadoEm']),
      status: json['status'] as String? ?? '',
      observacao: json['observacao'] as String?,
      motivacao: json['motivacao'] as String?,
      concluido: json['concluido'] as bool? ?? false,
      execucoes: execucoes
          .map(
            (item) => WorkoutExecutionRecord.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class WorkoutExecutionRecord {
  const WorkoutExecutionRecord({
    required this.id,
    required this.exercicioId,
    required this.exercicioNome,
    required this.concluido,
    this.treinoExercicioId,
    this.ordemPlanejada,
    this.seriesPlanejadas,
    this.repeticoesPlanejadas,
    this.cargaPlanejada,
    this.cargaReal,
    this.repeticoesReal,
  });

  final int id;
  final int? treinoExercicioId;
  final int exercicioId;
  final String exercicioNome;
  final int? ordemPlanejada;
  final int? seriesPlanejadas;
  final int? repeticoesPlanejadas;
  final double? cargaPlanejada;
  final double? cargaReal;
  final int? repeticoesReal;
  final bool concluido;

  factory WorkoutExecutionRecord.fromJson(Map<String, dynamic> json) {
    return WorkoutExecutionRecord(
      id: (json['id'] as num?)?.toInt() ?? 0,
      treinoExercicioId: (json['treinoExercicioId'] as num?)?.toInt(),
      exercicioId: (json['exercicioId'] as num?)?.toInt() ?? 0,
      exercicioNome: json['exercicioNome'] as String? ?? '',
      ordemPlanejada: (json['ordemPlanejada'] as num?)?.toInt(),
      seriesPlanejadas: (json['seriesPlanejadas'] as num?)?.toInt(),
      repeticoesPlanejadas: (json['repeticoesPlanejadas'] as num?)?.toInt(),
      cargaPlanejada: _toDouble(json['cargaPlanejada']),
      cargaReal: _toDouble(json['cargaReal']),
      repeticoesReal: (json['repeticoesReal'] as num?)?.toInt(),
      concluido: json['concluido'] as bool? ?? false,
    );
  }
}

class WorkoutExerciseDraft {
  const WorkoutExerciseDraft({
    required this.exercicioId,
    required this.ordem,
    required this.series,
    required this.repeticoes,
    required this.dificuldade,
    this.carga,
  });

  final int exercicioId;
  final int ordem;
  final int series;
  final int repeticoes;
  final double? carga;
  final String dificuldade;

  Map<String, dynamic> toPayload() {
    return {
      'exercicioId': exercicioId,
      'ordem': ordem,
      'series': series,
      'repeticoes': repeticoes,
      'carga': carga,
      'dificuldade': dificuldade,
    };
  }
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

DateTime? _toDate(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
