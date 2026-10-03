import 'package:flutter/material.dart';
import '../models/parcours.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'main_navigation.dart';
import 'parcours_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// Les 4 parcours du cahier des charges, charges depuis le backend.
  List<ParcoursSummary> _parcours = const [];
  bool _chargementParcours = true;
  String? _erreurParcours;

  @override
  void initState() {
    super.initState();
    _chargerParcours();
  }

  Future<void> _chargerParcours() async {
    try {
      final parcours = await ApiService.listParcours();
      if (!mounted) return;
      setState(() {
        _parcours = parcours;
        _chargementParcours = false;
        _erreurParcours = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _chargementParcours = false;
        _erreurParcours = 'Parcours indisponibles';
      });
    }
  }

  void _ouvrirParcours(String slug) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ParcoursScreen(slug: slug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => context.switchToTab(5),
              child: const Align(
                alignment: Alignment.centerLeft,
                child: AyanaLogo(mark: true, height: 40),
              ),
            ),
            const SizedBox(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.switchToTab(1),
              child: Ink(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: brandGradient(),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.plum.withValues(alpha: 0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Pose-moi ta question…',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600)),
                    ),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.arrow_forward, size: 16, color: AppColors.plum),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionLabel('MES PARCOURS'),
            const SizedBox(height: 12),
            if (_chargementParcours)
              const _ParcoursSkeletons()
            else if (_erreurParcours != null)
              _ParcoursErreur(message: _erreurParcours!, onReessayer: _chargerParcours)
            else
              ..._parcours.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ParcoursCarte(
                      parcours: p,
                      onTap: () => _ouvrirParcours(p.slug),
                    ),
                  )),
            const SizedBox(height: 12),
            const SectionLabel('ACCÈS RAPIDE'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    title: 'Bibliothèque',
                    subtitle: 'Fiches & ressources',
                    onTap: () => context.switchToTab(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    title: 'Professionnels',
                    subtitle: "Trouver de l'aide",
                    onTap: () => context.switchToTab(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAccessCard(
                    title: 'Rappels',
                    subtitle: 'Mes rendez-vous',
                    onTap: () => context.switchToTab(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickAccessCard(
                    title: 'Discuter',
                    subtitle: 'Avec AYANA',
                    gradient: true,
                    onTap: () => context.switchToTab(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Carte d'un parcours, alimentée par la base de connaissances (module 4).
/// Le libellé de l'émergence provient du backend : le contenu de l'app et
/// celui de l'assistante ne peuvent pas diverger.
class _ParcoursCarte extends StatelessWidget {
  final ParcoursSummary parcours;
  final VoidCallback onTap;

  const _ParcoursCarte({required this.parcours, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          parcours.titre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              height: 1.15,
                              color: AppColors.textPrimary),
                        ),
                      ),
                      if (parcours.aUrgence) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text('URGENCE',
                              style: TextStyle(
                                  color: AppColors.dangerText,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    parcours.resume,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Squelette de chargement : évite un saut de mise en page quand le backend
/// répond, et rend visible que les parcours sont attendus du serveur.
class _ParcoursSkeletons extends StatelessWidget {
  const _ParcoursSkeletons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            height: 78,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _ParcoursErreur extends StatelessWidget {
  final String message;
  final VoidCallback onReessayer;

  const _ParcoursErreur({required this.message, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        border: Border.all(color: AppColors.dangerText.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 17)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12.5)),
          ),
          TextButton(
            onPressed: onReessayer,
            child: const Text('Réessayer',
                style: TextStyle(
                    color: AppColors.dangerText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool gradient;

  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = gradient
        ? BoxDecoration(gradient: brandGradient())
        : BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
          );
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: bg.copyWith(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: gradient ? Colors.white : AppColors.textPrimary)),
            Text(subtitle,
                style: TextStyle(
                    color: gradient
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}