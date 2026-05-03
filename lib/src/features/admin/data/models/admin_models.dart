class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.nome,
    required this.username,
    required this.email,
    required this.roleSistema,
    required this.ativo,
  });

  final int id;
  final String nome;
  final String username;
  final String email;
  final String? roleSistema;
  final bool ativo;

  String get displayName => '$nome (@$username)';

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      roleSistema: json['roleSistema'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

class AdminExercise {
  const AdminExercise({
    required this.id,
    required this.nome,
    required this.grupoMuscular,
    required this.equipamento,
    required this.descricao,
    required this.ativo,
  });

  final int id;
  final String nome;
  final String grupoMuscular;
  final String? equipamento;
  final String? descricao;
  final bool ativo;

  factory AdminExercise.fromJson(Map<String, dynamic> json) {
    return AdminExercise(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      grupoMuscular: json['grupoMuscular'] as String? ?? '',
      equipamento: json['equipamento'] as String?,
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

class AdminFood {
  const AdminFood({
    required this.id,
    required this.nome,
    required this.calorias,
    required this.proteina,
    required this.carboidrato,
    required this.gordura,
    required this.acucares,
  });

  final int id;
  final double calorias;
  final double proteina;
  final double carboidrato;
  final double gordura;
  final double acucares;
  final String nome;

  factory AdminFood.fromJson(Map<String, dynamic> json) {
    return AdminFood(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      calorias: _toDouble(json['calorias']),
      proteina: _toDouble(json['proteina']),
      carboidrato: _toDouble(json['carboidrato']),
      gordura: _toDouble(json['gordura']),
      acucares: _toDouble(json['acucares']),
    );
  }
}

class AdminWorkout {
  const AdminWorkout({
    required this.id,
    required this.nome,
    required this.tipoTreino,
    required this.usuarioId,
    required this.dataTreino,
    required this.exercicios,
    this.descricao,
    this.observacoes,
    this.diaSemana,
    this.ativo,
    this.publico,
    this.recorrente,
  });

  final int id;
  final String nome;
  final String? descricao;
  final String? observacoes;
  final String tipoTreino;
  final int usuarioId;
  final String? diaSemana;
  final bool? ativo;
  final bool? publico;
  final bool? recorrente;
  final DateTime? dataTreino;
  final List<AdminWorkoutExercise> exercicios;

  factory AdminWorkout.fromJson(Map<String, dynamic> json) {
    final exercicios = List<dynamic>.from(
      json['exercicios'] as List? ?? const [],
    );
    return AdminWorkout(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      observacoes: json['observacoes'] as String?,
      tipoTreino: json['tipoTreino'] as String? ?? '',
      usuarioId: (json['usuarioId'] as num?)?.toInt() ?? 0,
      diaSemana: json['diaSemana'] as String?,
      ativo: json['ativo'] as bool?,
      publico: json['publico'] as bool?,
      recorrente: json['recorrente'] as bool?,
      dataTreino: _toDateTime(json['dataTreino']),
      exercicios: exercicios
          .map(
            (item) => AdminWorkoutExercise.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class AdminWorkoutExercise {
  const AdminWorkoutExercise({
    required this.id,
    required this.exercicioId,
    required this.exercicioNome,
    required this.ordem,
    required this.series,
    required this.repeticoes,
    required this.dificuldade,
    this.carga,
  });

  final int id;
  final int exercicioId;
  final String exercicioNome;
  final int ordem;
  final int series;
  final int repeticoes;
  final double? carga;
  final String dificuldade;

  factory AdminWorkoutExercise.fromJson(Map<String, dynamic> json) {
    return AdminWorkoutExercise(
      id: (json['id'] as num?)?.toInt() ?? 0,
      exercicioId: (json['exercicioId'] as num?)?.toInt() ?? 0,
      exercicioNome: json['exercicioNome'] as String? ?? '',
      ordem: (json['ordem'] as num?)?.toInt() ?? 0,
      series: (json['series'] as num?)?.toInt() ?? 0,
      repeticoes: (json['repeticoes'] as num?)?.toInt() ?? 0,
      carga: _toNullableDouble(json['carga']),
      dificuldade: json['dificuldade'] as String? ?? '',
    );
  }
}

class AdminMealPlan {
  const AdminMealPlan({
    required this.id,
    required this.usuarioId,
    required this.nome,
    required this.dias,
    this.descricao,
    this.ativo,
    this.publico,
    this.principal,
    this.dataInicio,
    this.dataFim,
  });

  final int id;
  final int usuarioId;
  final String nome;
  final String? descricao;
  final bool? ativo;
  final bool? publico;
  final bool? principal;
  final DateTime? dataInicio;
  final DateTime? dataFim;
  final List<AdminMealPlanDay> dias;

  factory AdminMealPlan.fromJson(Map<String, dynamic> json) {
    final dias = List<dynamic>.from(json['dias'] as List? ?? const []);
    return AdminMealPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      usuarioId: (json['usuarioId'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] as bool?,
      publico: json['publico'] as bool?,
      principal: json['principal'] as bool?,
      dataInicio: _toDateTime(json['dataInicio']),
      dataFim: _toDateTime(json['dataFim']),
      dias: dias
          .map(
            (item) => AdminMealPlanDay.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class AdminMealPlanDay {
  const AdminMealPlanDay({
    required this.id,
    required this.diaSemana,
    required this.titulo,
    required this.refeicoes,
  });

  final int id;
  final String diaSemana;
  final String titulo;
  final List<AdminMealPlanMeal> refeicoes;

  factory AdminMealPlanDay.fromJson(Map<String, dynamic> json) {
    final refeicoes = List<dynamic>.from(
      json['refeicoes'] as List? ?? const [],
    );
    return AdminMealPlanDay(
      id: (json['id'] as num?)?.toInt() ?? 0,
      diaSemana: json['diaSemana'] as String? ?? '',
      titulo: json['titulo'] as String? ?? '',
      refeicoes: refeicoes
          .map(
            (item) => AdminMealPlanMeal.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class AdminMealPlanMeal {
  const AdminMealPlanMeal({
    required this.id,
    required this.tipoRefeicao,
    required this.alimentos,
    this.horarioSugerido,
    this.observacao,
  });

  final int id;
  final String tipoRefeicao;
  final String? horarioSugerido;
  final String? observacao;
  final List<AdminMealPlanMealFood> alimentos;

  factory AdminMealPlanMeal.fromJson(Map<String, dynamic> json) {
    final alimentos = List<dynamic>.from(
      json['alimentos'] as List? ?? const [],
    );
    return AdminMealPlanMeal(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tipoRefeicao: json['tipoRefeicao'] as String? ?? '',
      horarioSugerido: json['horarioSugerido'] as String?,
      observacao: json['observacao'] as String?,
      alimentos: alimentos
          .map(
            (item) => AdminMealPlanMealFood.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}

class AdminMealPlanMealFood {
  const AdminMealPlanMealFood({
    required this.id,
    required this.alimentoId,
    required this.alimentoNome,
    required this.quantidade,
  });

  final int id;
  final int alimentoId;
  final String alimentoNome;
  final double quantidade;

  factory AdminMealPlanMealFood.fromJson(Map<String, dynamic> json) {
    return AdminMealPlanMealFood(
      id: (json['id'] as num?)?.toInt() ?? 0,
      alimentoId: (json['alimentoId'] as num?)?.toInt() ?? 0,
      alimentoNome: json['alimentoNome'] as String? ?? '',
      quantidade: _toDouble(json['quantidade']),
    );
  }
}

class AdminXpRule {
  const AdminXpRule({
    required this.id,
    required this.nome,
    required this.tipoRegra,
    required this.xpConcedido,
    required this.ativo,
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

  factory AdminXpRule.fromJson(Map<String, dynamic> json) {
    return AdminXpRule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      tipoRegra: json['tipoRegra'] as String? ?? '',
      xpConcedido: (json['xpConcedido'] as num?)?.toInt(),
      percentualBonus: _toNullableDouble(json['percentualBonus']),
      descricao: json['descricao'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

class AdminMedal {
  const AdminMedal({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.tipoRegra,
    required this.valorMeta,
    required this.ativo,
    this.descricao,
    this.valorReferencia,
  });

  final int id;
  final String nome;
  final String? descricao;
  final String tipo;
  final String tipoRegra;
  final double valorMeta;
  final String? valorReferencia;
  final bool ativo;

  factory AdminMedal.fromJson(Map<String, dynamic> json) {
    return AdminMedal(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      tipo: json['tipo'] as String? ?? '',
      tipoRegra: json['tipoRegra'] as String? ?? '',
      valorMeta: _toDouble(json['valorMeta']),
      valorReferencia: json['valorReferencia'] as String?,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

class AdminWeeklyMission {
  const AdminWeeklyMission({
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

  factory AdminWeeklyMission.fromJson(Map<String, dynamic> json) {
    return AdminWeeklyMission(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      tipoRegra: json['tipoRegra'] as String? ?? '',
      metaValor: _toDouble(json['metaValor']),
      xpRecompensa: (json['xpRecompensa'] as num?)?.toInt() ?? 0,
      ativo: json['ativo'] as bool? ?? true,
    );
  }
}

double _toDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _toNullableDouble(Object? value) {
  if (value == null) {
    return null;
  }
  return _toDouble(value);
}

DateTime? _toDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value.toString());
}
