import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/parcours.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../theme/ui_widgets.dart';
import 'parcours_screen.dart';

/// Onglet « Ressources ».
///
/// Les modules ne sont pas des fiches locales : chacun ouvre l'un des quatre
/// parcours de la base de connaissances, seul contenu médical réel et sourcé
/// de l'application. Le backend est aussi interrogé au démarrage pour connaître
/// le nombre de blocs de chaque parcours et afficher la bonne destination.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<ParcoursSummary> _parcours = const [];
  bool _chargement = true;
  String _recherche = '';

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
        _chargement = false;
      });
    } catch (_) {
      // Les modules restent navigables même sans le compte : c'est
      // l'écran du parcours qui affichera l'erreur de connexion si besoin.
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  ParcoursSummary? _parcoursDe(String slug) {
    for (final p in _parcours) {
      if (p.slug == slug) return p;
    }
    return null;
  }

  /// Modules correspondant à la recherche.
  ///
  /// La recherche porte sur le nom du module et ses [LibraryTheme.motsCles],
  /// pas sur le parcours de destination : trois modules partagent `corps`, et
  /// une recherche sur « règles » ne doit pas remonter « Cycle menstruel ».
  List<LibraryTheme> get _modulesFiltres {
    final requete = _normaliser(_recherche);
    if (requete.isEmpty) return libraryThemes;
    return libraryThemes.where((t) {
      final cible = [t.title, ...t.motsCles].join(' ');
      return _normaliser(cible).contains(requete);
    }).toList();
  }

  /// Met la recherche en forme comparable : minuscules, sans accents et sans
  /// ponctuation. Sur un clavier de téléphone les accents sont longs à saisir,
  /// « regles » doit donc trouver « Règles », et « reglesetmenstruations »
  /// comme « Règles & menstruations ».
  static String _normaliser(String texte) {
    var s = texte.toLowerCase();
    for (final entree in _accents.entries) {
      s = s.replaceAll(entree.key, entree.value);
    }
    return s.replaceAll(RegExp('[^a-z0-9]'), '');
  }

  static const Map<String, String> _accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'å': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i',
    'ô': 'o', 'ö': 'o', 'ò': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  void _ouvrirParcours(String slug) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ParcoursScreen(slug: slug)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modules = _modulesFiltres;
    final rechercheActive = _recherche.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TabHeader(
              title: 'Ressources',
              subtitle: 'Contenu médical vérifiable, hors du chat',
            ),
            const SizedBox(height: 16),
            TextField(
              onChanged: (v) => setState(() => _recherche = v),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Rechercher un sujet…',
                prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              rechercheActive
                  ? '${modules.length} module${modules.length > 1 ? 's' : ''} '
                      'pour « ${_recherche.trim()} »'
                  : '${libraryThemes.length} modules, '
                      '${_parcours.length} parcours médicaux',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: modules.isEmpty
                  ? _AucunResultat(recherche: _recherche.trim())
                  : GridView.builder(
                      itemCount: modules.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.05,
                      ),
                      itemBuilder: (context, i) {
                        final t = modules[i];
                        return _ModuleCard(
                          theme: t,
                          parcours: _parcoursDe(t.slug),
                          chargement: _chargement,
                          onTap: () => _ouvrirParcours(t.slug),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tuile d'un module : nom du sujet, parcours qui sera ouvert, et volume réel
/// de ce parcours quand le backend a répondu.
class _ModuleCard extends StatelessWidget {
  final LibraryTheme theme;
  final ParcoursSummary? parcours;
  final bool chargement;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.theme,
    required this.parcours,
    required this.chargement,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final blocs = parcours?.nbBlocs ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.bg,
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              theme.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  fontSize: 15,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            // Destination réelle, servie par le backend : l'app et le contenu
            // ne peuvent pas afficher deux parcours différents.
            Text(
              parcours?.titre ?? 'Contenu médical',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.2,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            if (chargement)
              SizedBox(
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: theme.accent),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  blocs > 0 ? '$blocs blocs' : 'Parcours',
                  style: TextStyle(
                      color: theme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AucunResultat extends StatelessWidget {
  final String recherche;

  const _AucunResultat({required this.recherche});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 34, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              'Aucun module ne correspond à « $recherche ».',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14),
            ),
            const SizedBox(height: 6),
            const Text(
              'Essaie un mot plus court : « cycle », « contraception », '
              '« grossesse ».',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
