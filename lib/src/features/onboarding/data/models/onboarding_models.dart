import '../../../../core/models/app_user.dart';

class OnboardingPayload {
  const OnboardingPayload({
    required this.objetivo,
    required this.pesoAtual,
    required this.nivelExperiencia,
    this.altura,
    this.frequenciaSemanalMeta,
    this.proteinaDiariaMeta,
    this.caloriaDiariaMeta,
    this.observacaoMeta,
  });

  final String objetivo;
  final double pesoAtual;
  final String nivelExperiencia;
  final double? altura;
  final int? frequenciaSemanalMeta;
  final double? proteinaDiariaMeta;
  final double? caloriaDiariaMeta;
  final String? observacaoMeta;

  Map<String, dynamic> toJson() {
    return {
      'objetivo': objetivo,
      'pesoAtual': pesoAtual,
      'altura': altura,
      'nivelExperiencia': nivelExperiencia,
      'frequenciaSemanalMeta': frequenciaSemanalMeta,
      'proteinaDiariaMeta': proteinaDiariaMeta,
      'caloriaDiariaMeta': caloriaDiariaMeta,
      'observacaoMeta': observacaoMeta,
    };
  }
}

class OnboardingResult {
  const OnboardingResult({
    required this.user,
    required this.metaAtleta,
  });

  final AppUser user;
  final MetaAtletaSummary metaAtleta;

  factory OnboardingResult.fromJson(Map<String, dynamic> json) {
    return OnboardingResult(
      user: AppUser.fromJson(
        Map<String, dynamic>.from(json['usuario'] as Map? ?? const {}),
      ),
      metaAtleta: MetaAtletaSummary.fromJson(
        Map<String, dynamic>.from(json['metaAtleta'] as Map? ?? const {}),
      ),
    );
  }
}

class MetaAtletaSummary {
  const MetaAtletaSummary({
    required this.usuarioId,
    this.objetivoPrincipal,
    this.frequenciaSemanalMeta,
    this.proteinaDiariaMeta,
    this.caloriaDiariaMeta,
    this.observacao,
  });

  final int usuarioId;
  final String? objetivoPrincipal;
  final int? frequenciaSemanalMeta;
  final double? proteinaDiariaMeta;
  final double? caloriaDiariaMeta;
  final String? observacao;

  factory MetaAtletaSummary.fromJson(Map<String, dynamic> json) {
    return MetaAtletaSummary(
      usuarioId: (json['usuarioId'] as num?)?.toInt() ?? 0,
      objetivoPrincipal: json['objetivoPrincipal'] as String?,
      frequenciaSemanalMeta: (json['frequenciaSemanalMeta'] as num?)?.toInt(),
      proteinaDiariaMeta: _toDouble(json['proteinaDiariaMeta']),
      caloriaDiariaMeta: _toDouble(json['caloriaDiariaMeta']),
      observacao: json['observacao'] as String?,
    );
  }

  static double? _toDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}

class OnboardingOptions {
  static const objetivos = [
    'GANHO_MASSA',
    'DEFINICAO',
    'MANUTENCAO',
    'EMAGRECIMENTO',
  ];

  static const niveisExperiencia = [
    'INICIANTE',
    'INTERMEDIARIO',
    'AVANCADO',
  ];
}
