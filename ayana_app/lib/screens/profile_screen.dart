import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'server_settings_screen.dart';
import 'welcome_auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _user = ApiService.currentUser;
    if (_user != null) {
      try {
        final fresh = await ApiService.getMe();
        if (mounted) {
          setState(() {
            _user = fresh;
            _loading = false;
          });
        }
        return;
      } on ApiException {
        // On garde le profil en cache si le serveur est injoignable.
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _Header(user: user),
            const SizedBox(height: 20),
            _ProfileTile(
              title: 'Modifier mon profil',
              subtitle: user?.fullName ??
                  'Nom, pseudonyme, numéro',
              onTap: user == null ? null : () => _editProfile(context),
            ),
            _ProfileTile(
              title: 'Langue de l’application',
              subtitle: _languageLabel(user?.language),
              onTap: user == null ? null : () => _selectLanguage(context),
            ),
            _ProfileTile(
              title: 'Serveur',
              subtitle: ApiService.baseUrl,
              onTap: () => _openServerSettings(context),
            ),
            _ProfileTile(
              title: 'Confidentialité & données',
              subtitle: 'Anonymat, consentement, suppression',
              onTap: () {},
            ),
            const SizedBox(height: 10),
            AppCard(
              color: AppColors.dangerBg,
              borderColor: AppColors.dangerText.withValues(alpha: 0.35),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              onTap: () => _confirmLogout(context),
              child: const Row(
                children: [
                  Text('Se déconnecter',
                      style: TextStyle(
                          color: AppColors.dangerText,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String _languageLabel(String? code) {
    for (final lang in availableLanguages) {
      if (lang.code == code) return '${lang.flagEmoji} ${lang.label}';
    }
    return 'Français 🇫🇷';
  }

  Future<void> _editProfile(BuildContext context) async {
    final user = _user;
    if (user == null) return;
    final pseudoController = TextEditingController(text: user.pseudo);
    final fullNameController = TextEditingController(text: user.fullName ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Modifier mon profil',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pseudoController,
              decoration: const InputDecoration(labelText: 'PSEUDONYME'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'NOM & PRÉNOM'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enregistrer',
                style: TextStyle(
                    color: AppColors.plum, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) {
      pseudoController.dispose();
      fullNameController.dispose();
      return;
    }
    final pseudo = pseudoController.text.trim();
    final fullName = fullNameController.text.trim();
    if (pseudo.length < 2) {
      _message('Le pseudonyme doit faire au moins 2 caractères.');
      pseudoController.dispose();
      fullNameController.dispose();
      return;
    }
    try {
      final updated = await ApiService.updateMe(
        pseudo: pseudo,
        fullName: fullName.isEmpty ? null : fullName,
      );
      if (mounted) {
        setState(() => _user = updated);
        _message('Profil mis à jour ✅');
      }
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    }
    pseudoController.dispose();
    fullNameController.dispose();
  }

  Future<void> _selectLanguage(BuildContext context) async {
    final user = _user;
    if (user == null) return;
    var selected = user.language;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Langue de l’application',
              style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: availableLanguages.map((lang) {
              final active = lang.code == selected;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setDialogState(() => selected = lang.code),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      Text(lang.flagEmoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(lang.label,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                      ),
                      if (active)
                        const Icon(Icons.check_circle,
                            color: AppColors.plum, size: 22),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Enregistrer',
                  style: TextStyle(
                      color: AppColors.plum, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
    if (saved != true || !mounted || selected == user.language) return;
    try {
      final updated = await ApiService.updateMe(language: selected);
      if (mounted) setState(() => _user = updated);
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    }
  }

  /// Ouvre le réglage du backend.
  ///
  /// Après un changement d'adresse, la session locale n'est plus valable : le
  /// jeton a été émis par l'ancien serveur. On la supprime et on renvoie vers
  /// l'accueil, sinon chaque appel suivant échouerait en 401 sans explication.
  Future<void> _openServerSettings(BuildContext context) async {
    final navigateur = Navigator.of(context);
    final ancien = ApiService.baseUrl;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ServerSettingsScreen()),
    );
    if (!mounted || ApiService.baseUrl == ancien) return;
    await ApiService.clearSession();
    if (!mounted) return;
    _message('Serveur changé. Reconnecte-toi pour continuer.');
    navigateur.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeAuthScreen()),
      (route) => false,
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _confirmLogout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Se déconnecter ?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Tu pourras te reconnecter avec ton numéro et ton mot de passe.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ApiService.clearSession();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const WelcomeAuthScreen()),
                (route) => false,
              );
            },
            child: const Text('Déconnexion',
                style: TextStyle(
                    color: AppColors.dangerText, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AppUser? user;

  const _Header({this.user});

  @override
  Widget build(BuildContext context) {
    final pseudo = user?.pseudo ?? 'Invité';
    final phone = user?.phone;
    final isGuest = user?.isGuest ?? true;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const AyanaLogo(mark: true, height: 34),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGuest && (user?.fullName ?? '').isEmpty ? pseudo : (user?.fullName ?? pseudo),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  isGuest && phone == null
                      ? 'Compte anonyme'
                      : (phone != null ? '+228 $phone' : '@${user?.pseudo ?? ''}'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Langue : ${languageByCode(user?.language) ?? 'Français 🇫🇷'}',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? languageByCode(String? code) {
    for (final lang in availableLanguages) {
      if (lang.code == code) return '${lang.flagEmoji} ${lang.label}';
    }
    return null;
  }
}

class _ProfileTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}