import '../../../../core/models/app_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiraEm,
    required this.onboardingPendente,
    required this.user,
  });

  final String accessToken;
  final String tokenType;
  final DateTime? expiraEm;
  final bool onboardingPendente;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiraEm: _parseDate(json['expiraEm']),
      onboardingPendente: json['onboardingPendente'] as bool? ?? false,
      user: AppUser.fromJson(
        Map<String, dynamic>.from(json['usuario'] as Map? ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'expiraEm': expiraEm?.toIso8601String(),
      'onboardingPendente': onboardingPendente,
      'usuario': user.toJson(),
    };
  }

  AuthSession copyWith({
    String? accessToken,
    String? tokenType,
    DateTime? expiraEm,
    bool? onboardingPendente,
    AppUser? user,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      expiraEm: expiraEm ?? this.expiraEm,
      onboardingPendente: onboardingPendente ?? this.onboardingPendente,
      user: user ?? this.user,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
