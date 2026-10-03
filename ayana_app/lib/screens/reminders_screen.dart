import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'main_navigation.dart';

/// Écran « Mes rappels ».
///
/// Le cahier des charges (§ 6.6) autorise un système simple pour le MVP, mais
/// aucun modèle de rendez-vous n'existe côté backend. Plutôt que d'afficher
/// des consultations prénatales inventées — de fausses données de santé dans
/// une app de santé — l'écran affiche explicitement un état vide.
///
/// Le calendrier des CPN sera alimenté par la base de connaissances (Module 4)
/// dès qu'elle existera ; les notifications réelles exigeront un paquet dédié.
class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const TabHeader(title: 'Mes rappels'),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.plumLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.event_note_rounded,
                      size: 34, color: AppColors.plum),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aucun rappel enregistré',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Les rappels de rendez-vous ne sont pas encore disponibles. "
                  "En attendant, demande à AYANA : elle peut te rappeler le "
                  "calendrier des consultations prénatales et te dire quoi "
                  "préparer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: 'Demander à AYANA',
                  height: 48,
                  onPressed: () => context.switchToTab(1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const SectionLabel('CE QUI ARRIVERA PLUS TARD'),
          const SizedBox(height: 12),
          const AppCard(
            child: Row(
              children: [
                Text('📅', style: TextStyle(fontSize: 20)),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    "Suivi des consultations prénatales et rappels de prise de "
                    "comprimés.",
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
