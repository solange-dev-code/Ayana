import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/parcours.dart';
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
/// L'adresse du serveur est modifiable depuis l'application (Profil → Serveur)
/// et conservée sur l'appareil. En effet, l'adresse IP du PC de développement
/// change dès que l'on change de Wi-Fi : sans réglage dans l'app, il faudrait
/// recompiler à chaque démonstration.
///
/// Ordre de priorité de l'adresse utilisée :
///   1. l'adresse saisie par l'utilisateur dans l'app ;
///   2. la valeur --dart-define=API_URL=... fournie au build ;
///   3. la valeur par défaut ci-dessous, propre à ce poste de développement.
class ApiService {
  ApiService._();

  /// Valeur figée à la compilation, sert de repli.
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://192.168.1.67:8000',
  );

  static const String _baseUrlKey = 'ayana_base_url';

  /// Adresse courante. Initialisée à la compilation, puis remplacée par
  /// [loadBaseUrl] au démarrage si l'utilisateur a enregistré une adresse.
  static String baseUrl = defaultBaseUrl;

  /// Adresse saisie par l'utilisateur, si elle existe.
  static String? _userBaseUrl;

  /// Charge l'adresse enregistrée sur l'appareil. À appeler au démarrage,
  /// avant le premier appel réseau.
  static Future<void> loadBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _userBaseUrl = prefs.getString(_baseUrlKey);
    if (_userBaseUrl != null) baseUrl = _userBaseUrl!;
  }

  /// Vrai lorsque l'adresse provient d'un réglage de l'utilisateur et non du
  /// code : utile pour proposer de revenir à la valeur par défaut.
  static bool get usesCustomBaseUrl => _userBaseUrl != null;

  /// Enregistre une nouvelle adresse après l'avoir testée.
  ///
  /// Renvoie l'erreur si l'adresse ne répond pas. La session est alors
  /// conservée : changer de serveur ne doit pas déconnecter l'utilisatrice,
  /// mais le jeton obtenu sur l'ancien serveur ne sera pas accepté par le
  /// nouveau, qui répondra 401. Voir [ApiService.clearSession].
  static Future<void> setBaseUrl(String url) async {
    final normalisee = normaliserBaseUrl(url);
    final testee = '$normalisee/api/health';
    late final http.Response reponse;
    try {
      reponse = await http
          .get(Uri.parse(testee))
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      throw ApiException(
        'Aucun serveur ne répond à $normalisee : ${_networkHint(e)}',
      );
    }
    if (reponse.statusCode != 200) {
      throw ApiException(
        'Le serveur a répondu ${reponse.statusCode} à la sonde de santé. '
        'Vérifie qu’il s’agit bien du backend AYANA.',
      );
    }
    _userBaseUrl = normalisee;
    baseUrl = normalisee;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, normalisee);
  }

  /// Revient à l'adresse prévue par le build ou celle du poste de dev.
  static Future<void> resetBaseUrl() async {
    _userBaseUrl = null;
    baseUrl = defaultBaseUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
  }

  /// Complète une adresse saisie à la main : `10.0.0.5` devient
  /// `http://10.0.0.5:8000`, le port et le schéma par défaut.
  static String normaliserBaseUrl(String saisie) {
    var url = saisie.trim();
    if (url.isEmpty) return defaultBaseUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    final uri = Uri.parse(url);
    final port = uri.hasPort ? uri.port : 8000;
    return '${uri.scheme}://${uri.host}:$port';
  }

  static const String _tokenKey = 'ayana_access_token';
  static const String _userKey = 'ayana_user';

  /// Délai au-delà duquel une requête est considérée comme perdue.
  static const Duration _requestTimeout = Duration(seconds: 30);

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

  /// Explique une panne réseau en termes actionnables.
  ///
  /// [error] est l'exception d'origine, ou `null` si elle n'a pas pu être
  /// identifiée. `package:http` y encapsule l'erreur socket, dont le libellé
  /// diffère entre Windows et Android : la cause est donc cherchée dans le
  /// texte plutôt que dans un type, ce qui évite aussi d'importer `dart:io`
  /// (incompatible avec la compilation web).
  static String _networkHint(Object? error) {
    final detail = (error?.toString() ?? '').toLowerCase();
    String reason;
    if (detail.contains('cleartext')) {
      reason = "Android bloque les connexions HTTP non chiffrées.";
    } else if (detail.contains('connection refused')) {
      reason = "aucun service n'écoute à cette adresse. Le backend n'est "
          "peut-être pas démarré : lance `demarrer.ps1` à la racine du projet.";
    } else if (detail.contains('no route to host') ||
        detail.contains('unreachable')) {
      reason = "le téléphone n'atteint pas ce réseau. Vérifie que le PC et le "
          "téléphone sont connectés au même Wi-Fi.";
    } else if (detail.contains('failed host lookup')) {
      reason = "le nom de domaine est introuvable.";
    } else if (detail.contains('timed out') || detail.contains('timeout')) {
      reason = "la connexion expire. Un pare-feu bloque probablement le port.";
    } else if (detail.contains('connection reset')) {
      reason = "la connexion a été coupée par le serveur.";
    } else {
      reason = "la connexion a échoué.";
    }
    return 'Serveur injoignable ($baseUrl) : $reason';
  }

  static Future<http.Response> _send(
    Future<http.Response> Function() request,
  ) async {
    try {
      final response = await request().timeout(_requestTimeout);
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
    } on TimeoutException {
      throw const ApiException(
        'Le serveur met trop de temps à répondre. Vérifie ta connexion.',
      );
    } on http.ClientException catch (e) {
      throw ApiException(_networkHint(e));
    } catch (e) {
      throw ApiException(_networkHint(e));
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
  static Future<({String message, String? demoCode})> requestOtp(
    String phone,
  ) async {
    final response = await _send(() => http.post(
          Uri.parse('$baseUrl/api/auth/otp/request'),
          headers: _jsonHeaders,
          body: jsonEncode({'phone': phone}),
        ));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = (json['detail'] as String?)?.trim();
    final message = (raw == null || raw.isEmpty) ? 'Code envoyé.' : raw;
    final demo = RegExp(r'code\s*:\s*(\d{4,10})').firstMatch(message);
    return (message: message, demoCode: demo?.group(1));
  }

  /// Connexion par code a usage unique (POST /api/auth/otp/verify).
  ///
  /// Le backend repond exactement comme [login] : le couple numero + code
  /// ouvre une session, et un compte est cree si le numero est inconnu. C'est
  /// ce qui permet d'ajouter une connexion sans mot de passe sans backend.
  static Future<AuthResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final response = await _send(() => http.post(
          Uri.parse('$baseUrl/api/auth/otp/verify'),
          headers: _jsonHeaders,
          body: jsonEncode({'phone': phone, 'code': code}),
        ));
    final result = _parseAuth(response.body);
    await _saveSession(result);
    return result;
  }

  /// Envoie la conversation à l'assistante IA (POST /api/chat).
  ///
  /// [history] : messages déjà échangés (``role`` : "user" | "assistant").
  ///
  /// Renvoie la réponse affichable et le parcours identifié par le moteur de
  /// classification (cahier des charges, module 3). Le parcours peut être
  /// absent : la question n'entre alors dans aucun des quatre parcours.
  static Future<({String reply, String? parcours})> sendMessage(
    List<({String role, String text})> history,
  ) async {
    final response = await _send(() => http.post(
          Uri.parse('$baseUrl/api/chat'),
          headers: _authHeaders,
          body: jsonEncode({
            'messages': [
              for (final m in history) {'role': m.role, 'text': m.text},
            ],
          }),
        ));
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return (
      reply: json['reply'] as String? ?? '',
      parcours: json['parcours'] as String?,
    );
  }

  /// Liste des parcours de la base de connaissances (GET /api/contenus).
  ///
  /// Contenu public : aucune authentification n'est requise, et aucune donnée
  /// personnelle n'est renvoyée.
  static Future<List<ParcoursSummary>> listParcours() async {
    final response = await _send(() => http.get(
          Uri.parse('$baseUrl/api/contenus'),
        ));
    final json = jsonDecode(response.body) as List<dynamic>;
    return json
        .map((e) => ParcoursSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Contenu complet d'un parcours (GET /api/contenus/{slug}).
  static Future<Parcours> getParcours(String slug) async {
    final response = await _send(() => http.get(
          Uri.parse('$baseUrl/api/contenus/$slug'),
        ));
    return Parcours.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
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

  /// Verifie que le backend repond (GET /api/health).
  ///
  /// Permet d'afficher un etat de connexion reel plutot qu'un indicateur fige
  /// dans l'interface. Une panne reseau est ici un resultat attendu, pas une
  /// erreur a remonter : la fonction repond `false`.
  static Future<bool> ping() async {
    try {
      await _send(() => http.get(Uri.parse('$baseUrl/api/health')));
      return true;
    } on ApiException {
      return false;
    }
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