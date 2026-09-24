import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  bool _loading = false;

  Future<void> _submit() async {
    if (_loading) return;
    final phone = _phoneController.text.trim();
    FocusScope.of(context).unfocus();
    if (phone.length < 8) {
      _message('Entre un numéro de téléphone valide.');
      return;
    }
    setState(() => _loading = true);
    try {
      final detail = await ApiService.requestOtp(phone);
      if (mounted) _message(detail);
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
    _phoneController.dispose();
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
              child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 22),
            const Text('Mot de passe oublié ?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              "Saisis ton numéro de téléphone et nous t'enverrons un code "
              "pour réinitialiser ton mot de passe.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 28),
            const SectionLabel('NUMÉRO DE TÉLÉPHONE'),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(hintText: '97 89 25 06'),
            ),
            const SizedBox(height: 28),
            GradientButton(
              label: _loading ? 'Envoi…' : 'Envoyer le code',
              gradient: violetGradient(),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}