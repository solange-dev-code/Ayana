import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';

/// Réglage de l'adresse du backend.
///
/// L'IP du PC de développement change dès que l'on change de Wi-Fi, et la
/// connexion est le premier écran affiché dans l'application : impossible de
/// proposer un réglage plus tard, l'utilisatrice n'atteindrait jamais l'écran
/// de profil. Ce réglage est donc aussi accessible depuis l'écran de connexion.
class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  late final TextEditingController _controller;
  bool _testEnCours = false;
  String? _erreur;
  String? _succes;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ApiService.baseUrl);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Teste l'adresse saisie puis ne l'enregistre que si elle répond.
  ///
  /// Enregistrer une adresse injoignable ferait échouer toutes les requêtes
  /// ensuite, avec un message d'erreur trompeur : mieux vaut refuser ici.
  Future<void> _enregistrer() async {
    setState(() {
      _testEnCours = true;
      _erreur = null;
      _succes = null;
    });
    try {
      await ApiService.setBaseUrl(_controller.text);
      if (!mounted) return;
      setState(() {
        _testEnCours = false;
        _succes = 'Serveur enregistré ✅';
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _testEnCours = false;
        _erreur = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _testEnCours = false;
        _erreur = 'Adresse invalide. Exemple : 192.168.1.67:8000';
      });
    }
  }

  Future<void> _reinitialiser() async {
    await ApiService.resetBaseUrl();
    if (!mounted) return;
    setState(() {
      _controller.text = ApiService.baseUrl;
      _erreur = null;
      _succes = 'Adresse par défaut restaurée.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Serveur'),
        backgroundColor: AppColors.plum,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                border:
                    Border.all(color: AppColors.sage.withValues(alpha: 0.4)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡', style: TextStyle(fontSize: 17)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'L’adresse du backend change selon le réseau. '
                      'Trouve l’IP du PC avec « ipconfig » dans l’invite de '
                      'commandes, puis saisis-la ici.',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const SectionLabel('ADRESSE DU BACKEND'),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                hintText: '192.168.1.67:8000',
                prefixIcon: Icon(Icons.dns_outlined),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Le port 8000 est ajouté automatiquement si tu ne le saisis pas.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
            ),
            const SizedBox(height: 20),
            if (_erreur != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _Message(
                  texte: _erreur!,
                  couleur: AppColors.dangerText,
                  fond: AppColors.dangerBg,
                ),
              )
            else if (_succes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _Message(
                  texte: _succes!,
                  couleur: AppColors.successText,
                  fond: AppColors.successBg,
                ),
              ),
            FilledButton.icon(
              onPressed: _testEnCours ? null : _enregistrer,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.plum,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: _testEnCours
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(_testEnCours ? 'Test en cours…' : 'Tester et enregistrer'),
            ),
            if (ApiService.usesCustomBaseUrl) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _testEnCours ? null : _reinitialiser,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Revenir à l’adresse par défaut'),
              ),
            ],
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 14),
            const Row(
              children: [
                Icon(Icons.info_outline, size: 15, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le téléphone et le PC doivent être sur le même Wi-Fi.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String texte;
  final Color couleur;
  final Color fond;

  const _Message({
    required this.texte,
    required this.couleur,
    required this.fond,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 17, color: couleur),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: TextStyle(
                color: couleur,
                fontSize: 12.5,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
