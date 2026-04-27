class AppUser {
  const AppUser({
    required this.id,
    required this.nome,
    required this.email,
    required this.username,
    this.telefone,
    this.bio,
    this.fotoPerfilUrl,
    this.pesoAtual,
    this.altura,
    this.objetivo,
    this.nivelExperiencia,
    this.cidade,
    this.estado,
    this.perfilPrivado,
    this.onboardingConcluido,
    this.roleSistema,
  });

  final int id;
  final String nome;
  final String email;
  final String username;
  final String? telefone;
  final String? bio;
  final String? fotoPerfilUrl;
  final double? pesoAtual;
  final double? altura;
  final String? objetivo;
  final String? nivelExperiencia;
  final String? cidade;
  final String? estado;
  final bool? perfilPrivado;
  final bool? onboardingConcluido;
  final String? roleSistema;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nome: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      telefone: json['telefone'] as String?,
      bio: json['bio'] as String?,
      fotoPerfilUrl: json['fotoPerfilUrl'] as String?,
      pesoAtual: _toDouble(json['pesoAtual']),
      altura: _toDouble(json['altura']),
      objetivo: json['objetivo'] as String?,
      nivelExperiencia: json['nivelExperiencia'] as String?,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      perfilPrivado: json['perfilPrivado'] as bool?,
      onboardingConcluido: json['onboardingConcluido'] as bool?,
      roleSistema: json['roleSistema'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'username': username,
      'telefone': telefone,
      'bio': bio,
      'fotoPerfilUrl': fotoPerfilUrl,
      'pesoAtual': pesoAtual,
      'altura': altura,
      'objetivo': objetivo,
      'nivelExperiencia': nivelExperiencia,
      'cidade': cidade,
      'estado': estado,
      'perfilPrivado': perfilPrivado,
      'onboardingConcluido': onboardingConcluido,
      'roleSistema': roleSistema,
    };
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
