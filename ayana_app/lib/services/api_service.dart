import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

/// Erreur renvoyée par l'API (message `detail` du backend).
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Client HTTP vers le backend FastAPI AYANA.
///
/// URL de base configurable au build :
///   flutter run --dart-define=API_URL=http://<IP_DU_BACKEND>:8000
/// (10.0.2.2 = localhost vu depuis l'émulateur Android).
class ApiService {
  ApiService._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.119.91:8000',
  );

  static const String _tokenKey = 'ayana_access_token';
  static const String _userKey = 'ayana_user';

  /// Dernier profil connu, chargé depuis la session locale.
  static AppUser? currentUser;

  static String? get token => _token;

  static String? _token;

  static Future<void> _loadSession() async {
    if (_token != null) return;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final rawUser = prefs.getString(_userKey);
    if (rawUser != null) {
      currentUser = AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
    }
  }

  static Future<bool> hasSession() async {
    await _loadSession();
    return _token != null && currentUser != null;
  }

  static Future<void> _saveSession(AuthResult result) async {
    _token = result.accessToken;
    currentUser = result.user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, result.accessToken);
    await prefs.setString(_userKey, jsonEncode({
          'id': result.user.id,
          'pseudo': result.user.pseudo,
          'full_name': result.user.fullName,
          'phone': result.user.phone,
          'language': result.user.language,
          'is_guest': result.user.isGuest,
          'consent_accepted': result.user.consentAccepted,
        }));
  }

  static Future<void> clearSession() async {
    _token = null;
    currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  static Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
      };

  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  static Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      String message = 'Erreur inattendue (${response.statusCode}).';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = body['detail'];
        if (detail is String) message = detail;
      } catch (_) {}
      throw ApiException(message, statusCode: response.statusCode);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Impossible de joindre le serveur. Vérifie que le backend est lancé '
        'et que l’URL est correcte.',
      );
    }
  }

  /// Inscription (POST /api/auth/register).
  static Future<AuthResult> register({
    required String pseudo,
    required String phone,
    required String password,
    String? fullName,
    required String language,
  }) async {
    final response = await _send(() => http.post(
          Uri.parse('$baseUrl/api/auth/register'),
          headers: _jsonHeaders,
          body: jsonEncode({
            'pseudo': pseudo,
            'phone': phone,
            'password': password,
            'full_name': fullName,
            'language': language,
            'consent': true,
          }),
        ));
    final result = _parseAuth(response.body);
    await _saveSession(result);
    return result;
  }

  /// Connexion (POST /api/auth/login) — le backend attend un formulaire.
  static Future<AuthResult> login({
    required String phone,
    required String password,
  }) async {
    final response = await _send(() => http.post(
          Uri.parse('$baseUrl/api/auth/login'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'username': phone, 'password': password},
        ));
    final result = _parseAuth(response.body);
    await _saveSession(result);
    return result;
  }

  /// Mode anonyme « Continuer sans compte » (POST /api/auth/guest).
  static Future<AuthResult> guest() async {
    final response = await _send(() => http.post(
          Uri.parse('$baseUrl/api/auth/guest'),
          headers: _jsonHeaders,
        ));
    final result = _parseAuth(response.body);
    await _saveSession(result);
    return result;
  }

  /// Demande d'un code OTP (POST /api/auth/otp/request).
  static Future<String> requestOtp(String phone) async {
    final response = await _send(() => http.post(
          Uri.parse('$baseUrl/api/auth/otp/request'),
          headers: _jsonHeaders,
          body: jsonEncode({'phone': phone}),
        ));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['detail'] as String? ?? 'Code envoyé.';
  }

  /// Profil courant (GET /api/users/me).
  static Future<AppUser> getMe() async {
    final response = await _send(() => http.get(
          Uri.parse('$baseUrl/api/users/me'),
          headers: _authHeaders,
        ));
    final user = AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    currentUser = user;
    await _persistUser(user);
    return user;
  }

  /// Mise à jour du profil (PATCH /api/users/me).
  static Future<AppUser> updateMe({
    String? pseudo,
    String? fullName,
    String? language,
  }) async {
    final body = <String, dynamic>{
      'pseudo': ?pseudo,
      'full_name': ?fullName,
      'language': ?language,
    };
    final response = await _send(() => http.patch(
          Uri.parse('$baseUrl/api/users/me'),
          headers: _authHeaders,
          body: jsonEncode(body),
        ));
    final user = AppUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    currentUser = user;
    await _persistUser(user);
    return user;
  }

  static AuthResult _parseAuth(String body) => AuthResult.fromJson(body);

  static Future<void> _persistUser(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode({
          'id': user.id,
          'pseudo': user.pseudo,
          'full_name': user.fullName,
          'phone': user.phone,
          'language': user.language,
          'is_guest': user.isGuest,
          'consent_accepted': user.consentAccepted,
        }));
  }
}