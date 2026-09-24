import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Bouton principal plein-largeur avec le dégradé violet -> rose de la maquette.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final LinearGradient? gradient;
  final bool outlined;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient,
    this.outlined = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final bg = (gradient == null || gradient!.colors.length < 2)
        ? brandGradient()
        : gradient!;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.sage, width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                foregroundColor: AppColors.sage,
              ),
              child: Text(label,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: bg,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: bg.colors.first.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                child: Text(label),
              ),
            ),
    );
  }
}

/// Petit libellé de section, style « MES PARCOURS » / « ACCÈS RAPIDE ».
class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;

  const SectionLabel(this.text, {super.key, this.color = AppColors.textSecondary});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.8,
      ),
    );
  }
}

/// Carte sombre standard du design system.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final BorderRadius? radius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: radius ?? BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(
      onTap: onTap,
      borderRadius: radius ?? BorderRadius.circular(16),
      child: box,
    );
  }
}

/// Logo AYANA (wordmark prune sur crème) pour tous les écrans.
class AyanaLogo extends StatelessWidget {
  final double height;
  final bool mark;

  const AyanaLogo({super.key, this.height = 40, this.mark = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      mark ? 'assets/images/logo_mark.png' : 'assets/images/logo.jpeg',
      height: height,
      fit: BoxFit.contain,
    );
  }
}

/// En-tête de tab : lettrage AYANA (logo) + titre contextuel.
class TabHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const TabHeader({
    super.key,
    required this.title,
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AyanaLogo(mark: true, height: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              if (subtitle.isNotEmpty)
                Text(subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}