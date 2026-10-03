import 'package:flutter/material.dart';
import '../models/parcours.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';

/// Affiche le contenu d'un parcours de la base de connaissances (module 4).
///
/// Le contenu vient du backend : chaque bloc porte sa source, et les blocs
/// d'urgence sont remontes en haut car ils appellent une consultation rapide.
class ParcoursScreen extends StatefulWidget {
  final String slug;

  const ParcoursScreen({super.key, required this.slug});

  @override
  State<ParcoursScreen> createState() => _ParcoursScreenState();
}

class _ParcoursScreenState extends State<ParcoursScreen> {
  Parcours? _parcours;
  String? _erreur;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final parcours = await ApiService.getParcours(widget.slug);
      if (!mounted) return;
      setState(() {
        _parcours = parcours;
        _chargement = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur =
            'Impossible de charger ce parcours. Vérifie que le backend est '
            'lancé et que l’URL est correcte.';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final parcours = _parcours;

    return Scaffold(
      appBar: AppBar(
        title: Text(parcours == null ? 'Parcours' : parcours.titre),
        backgroundColor: AppColors.plum,
        foregroundColor: Colors.white,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _erreur != null
              ? _Erreur(contexte: _erreur!, onReessayer: _charger)
              : parcours == null
                  ? const SizedBox.shrink()
                  : _contenu(parcours),
    );
  }

  Widget _contenu(Parcours parcours) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(parcours.resume,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4)),
        if (parcours.avertissement.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.sageLight,
              border: Border.all(color: AppColors.sage.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(parcours.avertissement,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    height: 1.35)),
          ),
        ],
        const SizedBox(height: 20),
        ...parcours.blocsOrdonnes.map(_bloc),
        const SizedBox(height: 28),
        const Center(
          child: Text(
            'Contenu à but informatif. En cas de doute, '
            'consulte un professionnel de santé.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 11.5, height: 1.3),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _bloc(ParcoursBloc bloc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        color: bloc.urgence ? AppColors.dangerBg : AppColors.surface,
        borderColor: bloc.urgence
            ? AppColors.dangerText.withValues(alpha: 0.45)
            : AppColors.border,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bloc.urgence) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.dangerText,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('CONSULTE UN PROFESSIONNEL',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3)),
              ),
              const SizedBox(height: 10),
            ],
            Text(bloc.titre,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 15, height: 1.2)),
            const SizedBox(height: 8),
            ...bloc.points.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Text('•',
                            style: TextStyle(
                                color: AppColors.plum, fontSize: 14)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(p,
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                                height: 1.35)),
                      ),
                    ],
                  ),
                )),
            if (bloc.source.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Source : ${bloc.source}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10.5)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Erreur extends StatelessWidget {
  final String contexte;
  final VoidCallback onReessayer;

  const _Erreur({required this.contexte, required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(contexte,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onReessayer,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bandeau proposé dans le chat quand le moteur de classification identifie
/// un parcours (module 3). Relie la réponse de l'IA au contenu de référence.
class ParcoursSuggestion extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const ParcoursSuggestion({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.sageLight,
          border: Border.all(color: AppColors.sage.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.article_rounded, size: 17, color: AppColors.sage),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Parcours « $label »',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5)),
            ),
            const Text('Voir',
                style: TextStyle(
                    color: AppColors.sage,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
            const Icon(Icons.chevron_right, size: 17, color: AppColors.sage),
          ],
        ),
      ),
    );
  }
}
