import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'forgot_password_screen.dart';
import 'language_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isSignup;
  const LoginScreen({super.key, required this.isSignup});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _consent = false;
  bool _loading = false;

  final _nameController = TextEditingController();
  final _pseudoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  Future<void> _submit() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    if (widget.isSignup) {
      if (_pseudoController.text.trim().length < 2) {
        _message('Choisis un pseudonyme d’au moins 2 caractères.');
        return;
      }
      if (phone.length < 8) {
        _message('Entre un numéro de téléphone valide.');
        return;
      }
      if (password.length < 6) {
        _message('Le mot de passe doit faire au moins 6 caractères.');
        return;
      }
      if (password != _confirmController.text) {
        _message('Les deux mots de passe ne correspondent pas.');
        return;
      }
      if (!_consent) {
        _message('Merci d’accepter les conditions d’utilisation.');
        return;
      }
    }
    setState(() => _loading = true);
    try {
      if (widget.isSignup) {
        await ApiService.register(
          pseudo: _pseudoController.text.trim(),
          fullName: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
          phone: phone,
          password: password,
          language: 'fr',
        );
      } else {
        await ApiService.login(phone: phone, password: password);
      }
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LanguageScreen()),
      );
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pseudoController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isSignup ? 'Créer un compte' : 'Se connecter';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const AyanaLogo(mark: true, height: 46),
                  const SizedBox(height: 12),
                  Text(
                    widget.isSignup
                        ? 'Crée ton espace en 2 minutes'
                        : 'Content de te revoir',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            if (widget.isSignup) ...[
              const SectionLabel('NOM & PRÉNOM'),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Ex. Ama Mènou'),
              ),
              const SizedBox(height: 18),
              const SectionLabel('PSEUDONYME'),
              const SizedBox(height: 10),
              TextField(
                controller: _pseudoController,
                decoration: const InputDecoration(
                  hintText: 'Ex. Jolie 🌸',
                  helperText: 'Tu peux rester anonyme, un pseudo suffit.',
                  helperStyle: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 18),
            ],
            const SectionLabel('NUMÉRO DE TÉLÉPHONE'),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('TG  +228',
                      style:
                          TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: '97 89 25 06'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const SectionLabel('MOT DE PASSE'),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            if (!widget.isSignup) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Text('Connexion par code ?',
                      style: TextStyle(color: AppColors.plum)),
                ),
              ),
            ],
            if (widget.isSignup) ...[
              const SizedBox(height: 18),
              const SectionLabel('CONFIRMER LE MOT DE PASSE'),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _consent,
                      activeColor: AppColors.plum,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      onChanged: (v) => setState(() => _consent = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      "J'accepte les conditions d'utilisation et la politique "
                      "de confidentialité d'AYANA.",
                      style:
                          TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            GradientButton(
              label: _loading
                  ? 'Chargement…'
                  : (widget.isSignup ? 'Créer mon compte' : title),
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LoginScreen(isSignup: !widget.isSignup)),
                ),
                child: Text.rich(TextSpan(
                  text: widget.isSignup
                      ? 'Déjà un compte ? '
                      : "Pas encore de compte ? ",
                  style: const TextStyle(color: AppColors.textMuted),
                  children: [
                    TextSpan(
                      text: widget.isSignup ? 'Se connecter' : 'Créer un compte',
                      style: const TextStyle(
                          color: AppColors.plum, fontWeight: FontWeight.w700),
                    ),
                  ],
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}