import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'library_screen.dart';
import 'help_screen.dart';
import 'reminders_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _tabIndex = 0;

  final _tabs = const [
    HomeScreen(),
    ChatScreen(),
    LibraryScreen(),
    HelpScreen(),
    RemindersScreen(),
    ProfileScreen(),
  ];

  final _items = const [
    _NavItem('Accueil', Icons.home_rounded),
    _NavItem('Chat', Icons.chat_bubble_rounded),
    _NavItem('Ressources', Icons.menu_book_rounded),
    _NavItem('Aide', Icons.local_hospital_rounded),
    _NavItem('Rappels', Icons.calendar_month_rounded),
    _NavItem('Profil', Icons.person_rounded),
  ];

  /// Permet aux écrans enfants (ex: Accueil) de naviguer vers un autre onglet.
  void goToTab(int index) => setState(() => _tabIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: List.generate(_items.length, (i) {
                final item = _items[i];
                final active = i == _tabIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () => goToTab(i),
                    splashColor: AppColors.plum.withValues(alpha: 0.12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: active ? brandGradient() : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: active ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight:
                                active ? FontWeight.w700 : FontWeight.w500,
                            color: active ? AppColors.plum : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

/// Widget utilitaire pour trouver l'état de MainNavigation depuis un écran
/// enfant (ex: HomeScreen) et changer d'onglet par programmation.
extension MainNavigationFinder on BuildContext {
  void switchToTab(int index) {
    final state = findAncestorStateOfType<_MainNavigationState>();
    state?.goToTab(index);
  }
}