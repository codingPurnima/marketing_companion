import 'package:flutter/material.dart';

/// Artisan Marketplace — Design System
///
/// Colour palette, typography, and shared widget helpers for the
/// traditional-yet-modern Indian artisan marketplace aesthetic.
class AppColors {
  AppColors._();

  // Backgrounds
  static const Color pageBackground = Color(0xFFFAF7F2);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFF5EFE6);
  static const Color surfaceCard = Color(0xFFFFFBF7);

  // Terracotta & Earth primaries
  static const Color primary = Color(0xFF8B4513); // rich terracotta-brown
  static const Color primaryLight = Color(0xFFB56A3A);
  static const Color primaryMuted = Color(0xFFC4845C);
  static const Color primaryContainer = Color(0xFFF5E4D7);

  // Secondary — muted olive/sage
  static const Color secondary = Color(0xFF6B7A5C);
  static const Color secondaryLight = Color(0xFF8C9B78);
  static const Color secondaryContainer = Color(0xFFE8EDDF);

  // Category chip accent
  static const Color chipSelected = Color(0xFF8B4513);
  static const Color chipSelectedFg = Color(0xFFFFFFFF);
  static const Color chipUnselected = Color(0xFFEDE7DE);
  static const Color chipUnselectedFg = Color(0xFF5C4033);

  // Text
  static const Color textHeading = Color(0xFF2C1A0E);
  static const Color textBody = Color(0xFF4A3728);
  static const Color textSubtle = Color(0xFF7D6358);
  static const Color textMuted = Color(0xFFA08C80);

  // Borders & dividers
  static const Color border = Color(0xFFE8DDD5);
  static const Color borderStrong = Color(0xFFCFC0B3);
  static const Color divider = Color(0xFFF0EAE3);

  // WhatsApp
  static const Color whatsapp = Color(0xFF25D366);
  static const Color whatsappDark = Color(0xFF128C7E);
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle displayLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textHeading,
    letterSpacing: 0,
    height: 1.4,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryMuted,
    letterSpacing: 1.8,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.65,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textBody,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSubtle,
    height: 1.55,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSubtle,
    letterSpacing: 0.3,
  );

  static const TextStyle price = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 0,
  );

  static const TextStyle priceSmall = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 0,
  );

  static const TextStyle navBrand = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textHeading,
    letterSpacing: -0.3,
  );

  static const TextStyle craftTag = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryMuted,
    letterSpacing: 0.6,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.textHeading,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.surfaceWhite,
        surfaceContainerHighest: AppColors.surfaceWarm,
        onSurface: AppColors.textBody,
        outline: AppColors.border,
        outlineVariant: AppColors.divider,
      ),
      scaffoldBackgroundColor: AppColors.pageBackground,
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.textHeading,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 68,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIconColor: AppColors.textSubtle,
        suffixIconColor: AppColors.textSubtle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.chipUnselected,
        selectedColor: AppColors.chipSelected,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.chipUnselectedFg,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.chipSelectedFg,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
          side: BorderSide.none,
        ),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  Shared Spacing constants
// ───────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

// ───────────────────────────────────────────────
//  Reusable UI helpers
// ───────────────────────────────────────────────

/// A subtle decorative divider with a small diamond motif.
class OrnamentsiveDivider extends StatelessWidget {
  final double width;

  const OrnamentsiveDivider({super.key, this.width = 48});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width / 2,
          height: 1,
          color: AppColors.primaryMuted.withAlpha(100),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: AppColors.primaryMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(
          width: width / 2,
          height: 1,
          color: AppColors.primaryMuted.withAlpha(100),
        ),
      ],
    );
  }
}

/// Soft shadow wrapper used for elevated cards.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? color;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surfaceCard,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        hoverColor: AppColors.primaryContainer.withAlpha(80),
        splashColor: AppColors.primaryContainer,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.border),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// Craft badge — small coloured label for artisan specialty.
class CraftBadge extends StatelessWidget {
  final String label;

  const CraftBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTextStyles.craftTag,
      ),
    );
  }
}

/// Category chip tag — small readable label.
class CategoryTag extends StatelessWidget {
  final String label;

  const CategoryTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Artisan avatar placeholder.
class ArtisanAvatar extends StatelessWidget {
  final double radius;

  const ArtisanAvatar({super.key, this.radius = 28});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primaryContainer,
        border: Border.all(color: AppColors.primaryMuted.withAlpha(80), width: 1.5),
      ),
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          size: radius * 0.9,
          color: AppColors.primaryMuted,
        ),
      ),
    );
  }
}

/// Image placeholder for products.
class ProductImagePlaceholder extends StatelessWidget {
  const ProductImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceWarm,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 40,
          color: AppColors.primaryMuted,
        ),
      ),
    );
  }
}

/// Full-screen loading scaffold.
class LoadingScaffold extends StatelessWidget {
  final String title;

  const LoadingScaffold({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: AppColors.pageBackground,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Full-screen error scaffold.
class ErrorScaffold extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorScaffold({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: AppColors.pageBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
