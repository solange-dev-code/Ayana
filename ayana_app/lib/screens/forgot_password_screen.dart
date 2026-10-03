import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'language_screen.dart';

/// Connexion par code à usage unique.
///
/// Le backend transforme le couple numéro + code en session
/// (`POST /api/auth/otp/verify`), exactement comme `login`. L'écran ne promet
/// donc pas de « réinitialiser un mot de passe » — il n'existe pas
/// d'endpoint de réinitialisation — mais offre une vraie connexion sans mot
/// passe, ce qui est le bon motif pour une utilisatrice qui l'a oublié.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String? _pendingPhone;
  String? _demoCode;
  bool _sending = false;
  bool _verifying = false;

  bool get _codeSent => _pendingPhone != null;

  Future<void> _requestCode() async {
    if (_sending) return;
    final phone = _phoneController.text.trim();
    FocusScope.of(context).unfocus();
    if (phone.length < 8) {
      _message('Entre un numéro de téléphone valide.');
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await ApiService.requestOtp(phone);
      if (!mounted) return;
      setState(() {
        _pendingPhone = phone;
        _demoCode = result.demoCode;
      });
      // En production, aucun code ne revient du backend : il arrive par SMS.
      // Le backend n'annonçant pas le mode dans sa réponse, l'écran affiche le
      // code pour que la démonstration reste faisable.
      _message(result.message);
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _verifyCode() async {
    if (_verifying) return;
    final code = _codeController.text.trim();
    FocusScope.of(context).unfocus();
    if (code.length < 4) {
      _message('Saisis le code reçu par SMS.');
      return;
    }
    setState(() => _verifying = true);
    try {
      await ApiService.verifyOtp(phone: _pendingPhone!, code: code);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LanguageScreen()),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: violetGradient(),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.sms_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 22),
            const Text('Connexion par code',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              "Pas besoin de mot de passe : on t'envoie un code par SMS, "
              "valable 10 minutes.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 28),
            const SectionLabel('NUMÉRO DE TÉLÉPHONE'),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              enabled: !_codeSent,
              decoration: const InputDecoration(hintText: '97 89 25 06'),
            ),
            const SizedBox(height: 24),
            if (_codeSent) ...[
              const SectionLabel('CODE REÇU'),
              const SizedBox(height: 10),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '6 chiffres',
                  counterText: '',
                ),
              ),
              if (_demoCode != null) ...[
                const SizedBox(height: 4),
                Text('Mode démonstration — code : ${_demoCode!}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 20),
              GradientButton(
                label: _verifying ? 'Vérification…' : 'Ouvrir ma session',
                gradient: violetGradient(),
                onPressed: _verifyCode,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _verifying ? null : _requestCode,
                  child: const Text('Renvoyer un code',
                      style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ] else
              GradientButton(
                label: _sending ? 'Envoi…' : 'Envoyer le code',
                gradient: violetGradient(),
                onPressed: _requestCode,
              ),
            const SizedBox(height: 20),
            const Text(
              "Ce code sert uniquement à ouvrir ta session. Il ne change pas "
              "ton mot de passe.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
