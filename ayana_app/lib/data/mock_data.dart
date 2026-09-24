import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Données fictives du MVP, centralisées.
///
/// À remplacer progressivement par les appels au backend Django prévu.
/// Chaque source de données est documentée avec le module du cahier des
/// charges qu'elle remplacera.

/* ------------------------------------------------------------------ */
/* Onboarding                                                          */
/* ------------------------------------------------------------------ */

class OnboardingPageData {
  final String emoji;
  final String title;
  final String description;
  final LinearGradient gradient;
  final String buttonLabel;

  const OnboardingPageData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.gradient,
    required this.buttonLabel,
  });
}

final List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    emoji: '🌸',
    title: 'Bienvenue sur AYANA',
    description:
        "Je suis ton assistante santé intelligente. Je t'accompagne avec "
        "bienveillance pour toutes tes questions sur la santé sexuelle, "
        "reproductive et maternelle.",
    gradient: brandGradient(),
    buttonLabel: 'Suivant →',
  ),
  OnboardingPageData(
    emoji: '🔒',
    title: '100% Confidentiel',
    description:
        "Tu peux poser toutes tes questions librement, sans peur du jugement. "
        "Tu peux utiliser un pseudonyme et rester anonyme.",
    gradient: violetGradient(),
    buttonLabel: 'Suivant →',
  ),
  OnboardingPageData(
    emoji: '🏥',
    title: 'Pas un médecin, mais une alliée',
    description:
        "Je t'informe et t'oriente, mais je ne remplace jamais un "
        "professionnel de santé. Quand c'est nécessaire, je t'aide à "
        "trouver de l'aide qualifiée.",
    gradient: coralGradient(),
    buttonLabel: 'Commencer 🌸',
  ),
];

/* ------------------------------------------------------------------ */
/* Accueil — parcours                                                  */
/* ------------------------------------------------------------------ */

class ParcoursData {
  final String emoji;
  final String title;
  final String subtitle;
  final Color bg;
  final Color border;
  final Color accent;

  const ParcoursData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bg,
    required this.border,
    required this.accent,
  });
}

const parcoursList = [
  ParcoursData(
    emoji: '❤️',
    title: 'Je comprends\nmon corps',
    subtitle: 'Règles, cycle, puberté',
    bg: AppColors.roseLight,
    border: AppColors.rose,
    accent: AppColors.rose,
  ),
  ParcoursData(
    emoji: '💜',
    title: 'Je me\nprotège',
    subtitle: 'Contraception, IST, consentement',
    bg: AppColors.aubergineLight,
    border: AppColors.aubergine,
    accent: AppColors.aubergine,
  ),
  ParcoursData(
    emoji: '🤰🏾',
    title: 'Je vis ma\ngrossesse',
    subtitle: 'Suivi, info, rappels',
    bg: AppColors.terracottaLight,
    border: AppColors.terracotta,
    accent: AppColors.terracotta,
  ),
];

/* ------------------------------------------------------------------ */
/* Chat                                                                */
/* ------------------------------------------------------------------ */

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage(this.text, this.isUser, this.time);
}

const String welcomeMessage =
    "Bonjour 👋🏾 Je suis AYANA, ton assistante santé. Je suis là pour "
    "t'accompagner avec bienveillance et confidentialité.\n\nComment "
    "puis-je t'aider aujourd'hui ?";

const Map<String, String> quickReplies = {
  'Mes règles':
      "🌸 Le cycle menstruel dure en moyenne 28 jours, mais des variations "
      "entre 21 et 35 jours sont normales. Sur quoi veux-tu en savoir plus : "
      "la durée, l'hygiène, ou les douleurs ?",
  'Ma santé sexuelle':
      "💜 Je peux t'informer sur la contraception, la prévention des IST ou "
      "le consentement. Quel sujet t'intéresse ?",
  'Ma grossesse':
      "🤰🏾 Je peux t'accompagner à chaque étape de ta grossesse et te "
      "rappeler tes rendez-vous prénataux. À combien de semaines en es-tu ?",
  'Mes rendez-vous':
      "📅 Je peux t'aider à ne pas oublier tes rendez-vous médicaux "
      "importants.\n\nVeux-tu que je te rappelle tes prochaines "
      "consultations prénatales ou gynécologiques ?",
  "Trouver de l'aide":
      "🏥 Je peux t'orienter vers un professionnel ou une structure de "
      "santé près de toi. Va voir l'onglet \"Aide\" pour la liste complète.",
};

const String fallbackReply =
    "Merci pour ta question 🌸 Je suis en train de chercher la meilleure "
    "information pour toi. N'oublie pas que je ne remplace pas un médecin "
    "— pour toute situation urgente, consulte un professionnel de santé.";

/* ------------------------------------------------------------------ */
/* Bibliothèque                                                        */
/* ------------------------------------------------------------------ */

class LibraryTheme {
  final String emoji;
  final String title;
  final int cardCount;
  final Color bg;
  final Color accent;

  const LibraryTheme(this.emoji, this.title, this.cardCount, this.bg, this.accent);
}

final libraryThemes = [
  LibraryTheme('💧', 'Règles &\nmenstruations', 12, AppColors.roseLight, AppColors.rose),
  LibraryTheme('🔄', 'Cycle menstruel', 8, AppColors.roseLight, AppColors.rose),
  LibraryTheme('🛡️', 'Contraception', 15, AppColors.aubergineLight, AppColors.aubergine),
  LibraryTheme('❤️', 'IST & prévention', 10, AppColors.aubergineLight, AppColors.aubergine),
  LibraryTheme('🤝', 'Consentement', 6, AppColors.terracottaLight, AppColors.terracotta),
  LibraryTheme('🤰🏾', 'Grossesse', 18, AppColors.terracottaLight, AppColors.terracotta),
  LibraryTheme('💊', 'Santé\nreproductive', 9, AppColors.successBg, AppColors.successText),
  LibraryTheme('🌿', 'Hygiène &\nbien-être', 7, AppColors.successBg, AppColors.successText),
];

/* ------------------------------------------------------------------ */
/* Aide — professionnels                                               */
/* ------------------------------------------------------------------ */

class Professional {
  final String emoji;
  final String role;
  final String place;
  final String distance;
  final bool available;

  const Professional(this.emoji, this.role, this.place, this.distance, this.available);
}

final professionals = [
  Professional('🧑🏾‍⚕️', 'Sage-femme', 'Centre de santé Lomé', '1.2 km', true),
  Professional('🏥', 'Gynécologue', 'CHU Sylvanus Olympio', '3.5 km', false),
  Professional('💉', 'Infirmière', 'Clinique Biasa', '0.8 km', true),
  Professional('🌸', 'Conseillère SSR', 'ATBEF Lomé', '2.1 km', true),
];

/* ------------------------------------------------------------------ */
/* Rappels                                                            */
/* ------------------------------------------------------------------ */

class ReminderItem {
  final String emoji;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final bool done;

  const ReminderItem(this.emoji, this.title, this.subtitle, this.tag, this.tagColor, this.done);
}

final reminders = [
  ReminderItem('🩺', 'Consultation prénatale', '15 sept. 2026 • 10h00', 'RDV médical',
      AppColors.rose, false),
  ReminderItem('💊', 'Prise de fer + acide folique', 'Chaque matin • 08h00', 'Médicament',
      AppColors.aubergine, false),
  ReminderItem('🔬', 'Analyse de sang', '20 sept. 2026 • 08h30', 'Examen',
      AppColors.terracotta, false),
  ReminderItem('✅', 'Consultation gynéco', '5 sept. 2026 • 14h00', 'Terminé',
      AppColors.successText, true),
];

/* ------------------------------------------------------------------ */
/* Langues                                                            */
/* ------------------------------------------------------------------ */

class AppLanguage {
  final String code;
  final String flagEmoji;
  final String label;

  const AppLanguage(this.code, this.flagEmoji, this.label);
}

const List<AppLanguage> availableLanguages = [
  AppLanguage('fr', '🇫🇷', 'Français'),
  AppLanguage('ewe', '🇹🇬', 'Éwé'),
  AppLanguage('kbp', '🇹🇬', 'Kabyè'),
];