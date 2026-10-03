/// Modèles de la base de connaissances (cahier des charges, module 4).
///
/// Les données proviennent du backend (`GET /api/contenus`), pas d'une liste
/// en dur : le contenu doit rester révisable et sourcé côté serveur.
library;

/// Version courte d'un parcours, utilisée pour les boutons de l'accueil.
class ParcoursSummary {
  final String slug;
  final String titre;
  final String resume;
  final int nbBlocs;

  /// Vrai si le parcours contient des signes imposant une consultation.
  final bool aUrgence;

  const ParcoursSummary({
    required this.slug,
    required this.titre,
    required this.resume,
    required this.nbBlocs,
    required this.aUrgence,
  });

  factory ParcoursSummary.fromJson(Map<String, dynamic> json) {
    return ParcoursSummary(
      slug: json['slug'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      resume: json['resume'] as String? ?? '',
      nbBlocs: (json['nb_blocs'] as num?)?.toInt() ?? 0,
      aUrgence: json['a_urgence'] as bool? ?? false,
    );
  }
}

/// Un bloc de contenu structuré.
class ParcoursBloc {
  final String id;
  final String titre;
  final List<String> points;
  final String source;
  final bool urgence;

  const ParcoursBloc({
    required this.id,
    required this.titre,
    required this.points,
    required this.source,
    required this.urgence,
  });

  factory ParcoursBloc.fromJson(Map<String, dynamic> json) {
    return ParcoursBloc(
      id: json['id'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      points: (json['points'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      source: json['source'] as String? ?? '',
      urgence: json['urgence'] as bool? ?? false,
    );
  }
}

/// Contenu complet d'un parcours.
class Parcours {
  final String slug;
  final String titre;
  final String resume;
  final String avertissement;
  final List<ParcoursBloc> blocs;

  const Parcours({
    required this.slug,
    required this.titre,
    required this.resume,
    required this.avertissement,
    required this.blocs,
  });

  factory Parcours.fromJson(Map<String, dynamic> json) {
    return Parcours(
      slug: json['slug'] as String? ?? '',
      titre: json['titre'] as String? ?? '',
      resume: json['resume'] as String? ?? '',
      avertissement: json['avertissement'] as String? ?? '',
      blocs: (json['blocs'] as List<dynamic>? ?? const [])
          .map((e) => ParcoursBloc.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Les blocs d'urgence sont remontés en tête : ce sont ceux qui demandent
  /// une consultation rapide, ils ne doivent pas être noyés dans la page.
  List<ParcoursBloc> get blocsOrdonnes {
    final urgentes = blocs.where((b) => b.urgence).toList();
    final autres = blocs.where((b) => !b.urgence).toList();
    return [...urgentes, ...autres];
  }
}
