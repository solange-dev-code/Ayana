import 'dart:convert';

/// Profil utilisateur renvoyé par le backend AYANA.
class AppUser {
  final int id;
  final String pseudo;
  final String? fullName;
  final String? phone;
  final String language;
  final bool isGuest;
  final bool consentAccepted;

  const AppUser({
    required this.id,
    required this.pseudo,
    this.fullName,
    this.phone,
    required this.language,
    required this.isGuest,
    required this.consentAccepted,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        pseudo: json['pseudo'] as String,
        fullName: json['full_name'] as String?,
        phone: json['phone'] as String?,
        language: json['language'] as String,
        isGuest: json['is_guest'] as bool,
        consentAccepted: json['consent_accepted'] as bool,
      );

  AppUser copyWith({
    String? pseudo,
    String? fullName,
    String? language,
  }) =>
      AppUser(
        id: id,
        pseudo: pseudo ?? this.pseudo,
        fullName: fullName ?? this.fullName,
        phone: phone,
        language: language ?? this.language,
        isGuest: isGuest,
        consentAccepted: consentAccepted,
      );
}

/// Réponse d'authentification : jeton + profil.
class AuthResult {
  final String accessToken;
  final AppUser user;
  final bool isNewUser;

  const AuthResult({
    required this.accessToken,
    required this.user,
    required this.isNewUser,
  });

  factory AuthResult.fromJson(String body) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return AuthResult(
      accessToken: json['access_token'] as String,
      user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: json['is_new_user'] as bool? ?? false,
    );
  }
}