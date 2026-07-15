import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════
/// AMBER-PAPER DESIGN SYSTEM
/// ═══════════════════════════════════════════════════════════════════════
/// See Amber-Paper.md for the reasoning behind these values — this file
/// turns that doc into code you can actually import.
///
/// This pass takes every token the doc allows and pushes it as far as it
/// goes: a full 3-tier Material 3 tonal surface ramp (not just the 3 flat
/// canvas/raised/sunken steps), a ThemeExtension for the companion status
/// colors so call sites don't have to reach into AmberColors directly,
/// shadow/gradient/motion tokens, and a theme for basically every widget
/// Material ships. Still exactly the same public shape as before -
/// AmberTheme.light() / AmberTheme.dark(), AmberColors.*, AmberRadius.*,
/// AmberSpace.* - so nothing that already imports this file needs to
/// change. It just looks a lot better now.
///
/// light() and dark() both funnel through one private `_build()` so the
/// two modes can't quietly drift out of sync with each other - every
/// widget theme is defined exactly once, parameterized by brightness.

// ─────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────
class AmberColors {
  AmberColors._();

  // Light mode neutrals — straight, clean white instead of the old beige
  // paper tint. Cards/canvas share the same white and separate purely
  // through elevation (shadow), which reads as cleaner and more "booking
  // app" than a tonal step.
  static const canvasLight = Color(0xFFFFFFFF);
  static const raisedLight = Color(0xFFFFFFFF);
  static const sunkenLight = Color(0xFFEEF1F6);
  static const inkPrimaryLight = Color(0xFF141924);
  static const inkSecondaryLight = Color(0xFF5C6474);
  static const inkTertiaryLight = Color(0xFF98A0AF);

  // Dark mode neutrals — a soft, comfy blackish-blue (not a harsh navy,
  // not warm brown-black). This is the palette the error page and the
  // cosmos screen both pull from, so they read as one continuous "night"
  // surface instead of two mismatched dark screens.
  static const canvasDark = Color(0xFF10131C);
  static const raisedDark = Color(0xFF1A1F2C);
  static const sunkenDark = Color(0xFF0A0C12);
  static const inkPrimaryDark = Color(0xFFEDEFF5);
  static const inkSecondaryDark = Color(0xFFA9B0C2);
  static const inkTertiaryDark = Color(0xFF6C7387);

  // Accent — a confident, comfy blue instead of the old amber/gold.
  static const accentLight = Color(0xFF3D6FE0);
  static const accentDark = Color(0xFF7C9BF0);
  static const inkOnAccentLight = Color(0xFFFFFFFF);
  static const inkOnAccentDark = Color(0xFF10131C);

  // Companions — duller than accent, for tags/status/calendar categories
  static const dustyBlue = Color(0xFF4A9FB8); // info / "has a booking" dot (teal-blue, distinct from primary)
  static const sage = Color(0xFF4CAF7D); // confirmed / success
  static const dustyPlum = Color(0xFF8B6CC4); // secondary category
  static const terracotta = Color(0xFFD98C4A); // pending
  static const brick = Color(0xFFD9564F); // cancelled / error

  // Full Material 3 tonal ramp, hand-tuned instead of algorithmically
  // generated - one extra step lighter/darker than canvas/raised/sunken
  // in each direction so surfaceContainer* has somewhere to go, all
  // within the same cool white/blackish-blue family.
  static const surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const surfaceContainerLowLight = Color(0xFFF7F9FB);
  static const surfaceContainerHighLight = Color(0xFFEEF1F5);
  static const outlineLight = inkTertiaryLight;
  static const outlineVariantLight = Color(0xFFDCE1E8);
  static const inverseSurfaceLight = inkPrimaryLight;
  static const onInverseSurfaceLight = canvasLight;

  static const surfaceContainerLowestDark = sunkenDark;
  static const surfaceContainerLowDark = Color(0xFF151A25);
  static const surfaceContainerHighDark = Color(0xFF232939);
  static const surfaceContainerHighestDark = Color(0xFF2C3345);
  static const outlineDark = inkTertiaryDark;
  static const outlineVariantDark = Color(0xFF3A4152);
  static const inverseSurfaceDark = inkPrimaryDark;
  static const onInverseSurfaceDark = canvasDark;

  // Container/on-container pairs for the Material roles that need them.
  // Each is the base hue folded ~85% toward canvas (container) or ~80%
  // toward ink (on-container), computed once by eye and hardcoded rather
  // than derived at runtime - keeps every build deterministic and keeps
  // this file dependency-free.
  static const primaryContainerLight = Color(0xFFDCE6FB);
  static const onPrimaryContainerLight = Color(0xFF1D3E85);
  static const primaryContainerDark = Color(0xFF1D3E85);
  static const onPrimaryContainerDark = Color(0xFFDCE6FB);

  static const secondaryContainerLight = Color(0xFFD7EDF0);
  static const onSecondaryContainerLight = Color(0xFF1E4A52);
  static const secondaryContainerDark = Color(0xFF1E4A52);
  static const onSecondaryContainerDark = Color(0xFFD7EDF0);

  static const tertiaryContainerLight = Color(0xFFEAE1F5);
  static const onTertiaryContainerLight = Color(0xFF44315E);
  static const tertiaryContainerDark = Color(0xFF44315E);
  static const onTertiaryContainerDark = Color(0xFFEAE1F5);

  static const errorContainerLight = Color(0xFFF9E1DF);
  static const onErrorContainerLight = Color(0xFF6B241E);
  static const errorContainerDark = Color(0xFF6B241E);
  static const onErrorContainerDark = Color(0xFFF9E1DF);

  // "on-companion" text/icon colors, for when a companion color is used
  // as a solid chip/badge background and needs something legible on top.
  static const onDustyBlue = Color(0xFFFFFFFF);
  static const onSage = Color(0xFFFFFFFF);
  static const onDustyPlum = Color(0xFFFFFFFF);
  static const onTerracotta = Color(0xFFFFFFFF);
  static const onBrick = Color(0xFFFFFFFF);
}

// ─────────────────────────────────────────────────────────────────────────
// SHAPE — 4px boxes, pill bars/chips, nothing else. Per Amber-Paper §2.3,
// that's the whole vocabulary, so this class stays exactly that small on
// purpose. The semantic getters below don't add new radii, they just name
// the existing one per where it's used.
// ─────────────────────────────────────────────────────────────────────────
class AmberRadius {
  AmberRadius._();

  static const box = 4.0;
  static BorderRadius get boxRadius => BorderRadius.circular(box);
  static BorderRadius pill(double height) => BorderRadius.circular(height / 2);

  // semantic aliases - same 4px value, just named for where it's applied
  static BorderRadius get card => boxRadius;
  static BorderRadius get field => boxRadius;
  static BorderRadius get button => boxRadius;
  static BorderRadius get dialog => boxRadius;
  static BorderRadius get sheetTop => const BorderRadius.vertical(top: Radius.circular(box));
}

// ─────────────────────────────────────────────────────────────────────────
// SPACE — 8px base unit, straight from PaperDesign §2.2. Aliases below
// are the same steps, named for common layout roles.
// ─────────────────────────────────────────────────────────────────────────
class AmberSpace {
  AmberSpace._();

  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 16.0;
  static const s4 = 24.0;
  static const s5 = 32.0;
  static const s6 = 48.0;
  static const s8 = 64.0;

  static const stack = s2; // gap between tightly related items (icon + label)
  static const page = s3; // standard page/panel padding
  static const section = s5; // gap between distinct sections on a page
}

// ─────────────────────────────────────────────────────────────────────────
// MOTION — durations + curves, so every push/fade/expand in the app moves
// at the same handful of speeds instead of every widget inventing its own.
// ─────────────────────────────────────────────────────────────────────────
class AmberMotion {
  AmberMotion._();

  static const fast = Duration(milliseconds: 120); // hover/press feedback
  static const base = Duration(milliseconds: 220); // most transitions
  static const slow = Duration(milliseconds: 340); // panel/sheet expansion
  static const lazy = Duration(milliseconds: 480); // full-screen transitions

  // signature "paper settling into place" ease - decelerates hard at the
  // very end instead of a generic easeOut, gives motion a slight weight
  static const settle = Cubic(0.16, 1.0, 0.3, 1.0);
  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
}

// ─────────────────────────────────────────────────────────────────────────
// SHADOWS — tinted with ink, not pure black, so elevation reads as a soft
// lift rather than a generic Material drop shadow.
// ─────────────────────────────────────────────────────────────────────────
class AmberShadows {
  AmberShadows._();

  static List<BoxShadow> soft(Brightness b) => [
        BoxShadow(
          color: (b == Brightness.light ? AmberColors.inkPrimaryLight : Colors.black).withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> lifted(Brightness b) => [
        BoxShadow(
          color: (b == Brightness.light ? AmberColors.inkPrimaryLight : Colors.black).withValues(alpha: 0.10),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: (b == Brightness.light ? AmberColors.inkPrimaryLight : Colors.black).withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> glow(Brightness b) => [
        BoxShadow(
          color: (b == Brightness.light ? AmberColors.accentLight : AmberColors.accentDark).withValues(alpha: 0.35),
          blurRadius: 24,
          spreadRadius: -4,
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────
// GRADIENTS — subtle, tonal, still reads as "paper" not "app icon".
// ─────────────────────────────────────────────────────────────────────────
class AmberGradients {
  AmberGradients._();

  static LinearGradient canvasGlow(Brightness b) {
    final canvas = b == Brightness.light ? AmberColors.canvasLight : AmberColors.canvasDark;
    final accent = b == Brightness.light ? AmberColors.accentLight : AmberColors.accentDark;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [accent.withValues(alpha: 0.10), canvas],
      stops: const [0.0, 0.6],
    );
  }

  static LinearGradient accentSheen(Brightness b) {
    final accent = b == Brightness.light ? AmberColors.accentLight : AmberColors.accentDark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [accent, Color.lerp(accent, Colors.white, 0.18)!],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// STATUS EXTENSION — the companion colors, exposed through the theme
// itself. Call sites can do `Theme.of(context).extension<AmberStatus>()`
// instead of importing AmberColors directly for status chips/dots.
// AmberColors.dustyBlue etc. are unchanged and still work everywhere
// they're already used - this is purely additive.
// ─────────────────────────────────────────────────────────────────────────
class AmberStatus extends ThemeExtension<AmberStatus> {
  final Color info;
  final Color onInfo;
  final Color success;
  final Color onSuccess;
  final Color secondary;
  final Color onSecondary;
  final Color pending;
  final Color onPending;
  final Color danger;
  final Color onDanger;

  const AmberStatus({
    required this.info,
    required this.onInfo,
    required this.success,
    required this.onSuccess,
    required this.secondary,
    required this.onSecondary,
    required this.pending,
    required this.onPending,
    required this.danger,
    required this.onDanger,
  });

  static const light = AmberStatus(
    info: AmberColors.dustyBlue,
    onInfo: AmberColors.onDustyBlue,
    success: AmberColors.sage,
    onSuccess: AmberColors.onSage,
    secondary: AmberColors.dustyPlum,
    onSecondary: AmberColors.onDustyPlum,
    pending: AmberColors.terracotta,
    onPending: AmberColors.onTerracotta,
    danger: AmberColors.brick,
    onDanger: AmberColors.onBrick,
  );

  // same companion hues in dark mode - they already sit in a mid-tone
  // that reads fine against a dark canvas, no separate dark set needed
  static const dark = light;

  @override
  AmberStatus copyWith({
    Color? info,
    Color? onInfo,
    Color? success,
    Color? onSuccess,
    Color? secondary,
    Color? onSecondary,
    Color? pending,
    Color? onPending,
    Color? danger,
    Color? onDanger,
  }) {
    return AmberStatus(
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      pending: pending ?? this.pending,
      onPending: onPending ?? this.onPending,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
    );
  }

  @override
  AmberStatus lerp(ThemeExtension<AmberStatus>? other, double t) {
    if (other is! AmberStatus) return this;
    return AmberStatus(
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      onPending: Color.lerp(onPending, other.onPending, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// GLASS PANEL — reusable translucent-panel-over-art widget, the exact
// pattern the Amber-Paper doc calls for behind the login form. Not wired
// into any page yet (out of scope this pass, one file only) but drop it
// around anything sitting on top of the Lile wave or Lonely-Cosmos art.
// ─────────────────────────────────────────────────────────────────────────
class AmberGlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double opacity;

  const AmberGlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AmberSpace.s4),
    this.blur = 18,
    this.opacity = 0.72,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: AmberRadius.boxRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: opacity),
            borderRadius: AmberRadius.boxRadius,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// DECORATIONS — a couple of context-aware BoxDecoration presets so pages
// don't have to hand-roll the same raised/sunken card look every time.
// ─────────────────────────────────────────────────────────────────────────
class AmberDecorations {
  AmberDecorations._();

  static BoxDecoration raised(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: AmberRadius.boxRadius,
      boxShadow: AmberShadows.soft(theme.brightness),
    );
  }

  static BoxDecoration sunken(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return BoxDecoration(
      color: isLight ? AmberColors.sunkenLight : AmberColors.sunkenDark,
      borderRadius: AmberRadius.boxRadius,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────
class AmberTheme {
  AmberTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final canvas = isLight ? AmberColors.canvasLight : AmberColors.canvasDark;
    final raised = isLight ? AmberColors.raisedLight : AmberColors.raisedDark;
    final sunken = isLight ? AmberColors.sunkenLight : AmberColors.sunkenDark;
    final inkPrimary = isLight ? AmberColors.inkPrimaryLight : AmberColors.inkPrimaryDark;
    final inkSecondary = isLight ? AmberColors.inkSecondaryLight : AmberColors.inkSecondaryDark;
    final inkTertiary = isLight ? AmberColors.inkTertiaryLight : AmberColors.inkTertiaryDark;
    final accent = isLight ? AmberColors.accentLight : AmberColors.accentDark;
    final inkOnAccent = isLight ? AmberColors.inkOnAccentLight : AmberColors.inkOnAccentDark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: inkOnAccent,
      primaryContainer: isLight ? AmberColors.primaryContainerLight : AmberColors.primaryContainerDark,
      onPrimaryContainer: isLight ? AmberColors.onPrimaryContainerLight : AmberColors.onPrimaryContainerDark,
      secondary: AmberColors.dustyBlue,
      onSecondary: isLight ? AmberColors.onDustyBlue : AmberColors.inkOnAccentDark,
      secondaryContainer: isLight ? AmberColors.secondaryContainerLight : AmberColors.secondaryContainerDark,
      onSecondaryContainer: isLight ? AmberColors.onSecondaryContainerLight : AmberColors.onSecondaryContainerDark,
      tertiary: AmberColors.dustyPlum,
      onTertiary: isLight ? AmberColors.onDustyPlum : AmberColors.inkOnAccentDark,
      tertiaryContainer: isLight ? AmberColors.tertiaryContainerLight : AmberColors.tertiaryContainerDark,
      onTertiaryContainer: isLight ? AmberColors.onTertiaryContainerLight : AmberColors.onTertiaryContainerDark,
      error: AmberColors.brick,
      onError: isLight ? AmberColors.onBrick : AmberColors.inkOnAccentDark,
      errorContainer: isLight ? AmberColors.errorContainerLight : AmberColors.errorContainerDark,
      onErrorContainer: isLight ? AmberColors.onErrorContainerLight : AmberColors.onErrorContainerDark,
      surface: raised,
      onSurface: inkPrimary,
      surfaceContainerLowest: isLight ? AmberColors.surfaceContainerLowestLight : AmberColors.surfaceContainerLowestDark,
      surfaceContainerLow: isLight ? AmberColors.surfaceContainerLowLight : AmberColors.surfaceContainerLowDark,
      surfaceContainer: raised,
      surfaceContainerHigh: isLight ? AmberColors.surfaceContainerHighLight : AmberColors.surfaceContainerHighDark,
      surfaceContainerHighest: isLight ? sunken : AmberColors.surfaceContainerHighestDark,
      onSurfaceVariant: inkSecondary,
      outline: isLight ? AmberColors.outlineLight : AmberColors.outlineDark,
      outlineVariant: isLight ? AmberColors.outlineVariantLight : AmberColors.outlineVariantDark,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isLight ? AmberColors.inverseSurfaceLight : AmberColors.inverseSurfaceDark,
      onInverseSurface: isLight ? AmberColors.onInverseSurfaceLight : AmberColors.onInverseSurfaceDark,
      inversePrimary: isLight ? AmberColors.accentDark : AmberColors.accentLight,
      // stops Material 3's default primary-tinted wash from bleeding into
      // every elevated surface (cards, app bars, sheets) - without this,
      // the whole app picks up a faint blue-ish cast on top of our warm
      // palette, which is exactly what we don't want here.
      surfaceTint: Colors.transparent,
    );

    final textTheme = _textTheme(inkPrimary, inkSecondary, inkTertiary);
    final outlineVariant = scheme.outlineVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      splashFactory: InkRipple.splashFactory, // InkSparkle.splash looks nicer but needs shader support emulators often lack - this is the safe universal choice
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: const [AmberStatus.light],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),

      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: inkPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0.0,
        scrolledUnderElevation: 0.0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
        iconTheme: IconThemeData(color: inkPrimary),
        actionsIconTheme: IconThemeData(color: inkSecondary),
      ),

      cardTheme: CardThemeData(
        color: raised,
        surfaceTintColor: Colors.transparent,
        elevation: 1.0,
        shadowColor: inkPrimary.withValues(alpha: 0.12),
        margin: const EdgeInsets.symmetric(vertical: AmberSpace.s1),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: AmberRadius.card),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sunken,
        contentPadding: const EdgeInsets.symmetric(horizontal: AmberSpace.s3, vertical: AmberSpace.s3),
        hintStyle: textTheme.bodyMedium?.copyWith(color: inkTertiary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: inkSecondary),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(color: accent, fontWeight: FontWeight.w600),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
        prefixIconColor: inkTertiary,
        suffixIconColor: inkTertiary,
        border: OutlineInputBorder(
          borderRadius: AmberRadius.field,
          borderSide: BorderSide(color: inkTertiary.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AmberRadius.field,
          borderSide: BorderSide(color: inkTertiary.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AmberRadius.field,
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AmberRadius.field,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AmberRadius.field,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AmberRadius.field,
          borderSide: BorderSide(color: inkTertiary.withValues(alpha: 0.2)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return inkTertiary.withValues(alpha: 0.25);
            if (states.contains(WidgetState.pressed)) return Color.lerp(accent, Colors.black, 0.12);
            if (states.contains(WidgetState.hovered)) return Color.lerp(accent, Colors.white, 0.08);
            return accent;
          }),
          foregroundColor: WidgetStateProperty.all(inkOnAccent),
          overlayColor: WidgetStateProperty.all(inkOnAccent.withValues(alpha: 0.08)),
          elevation: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.pressed) ? 0.0 : 1.0),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: AmberSpace.s4, vertical: AmberSpace.s3)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: AmberRadius.button)),
          textStyle: WidgetStateProperty.all(textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: inkOnAccent,
          padding: const EdgeInsets.symmetric(horizontal: AmberSpace.s4, vertical: AmberSpace.s3),
          shape: RoundedRectangleBorder(borderRadius: AmberRadius.button),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inkPrimary,
          side: BorderSide(color: inkTertiary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: AmberSpace.s4, vertical: AmberSpace.s3),
          shape: RoundedRectangleBorder(borderRadius: AmberRadius.button),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          padding: const EdgeInsets.symmetric(horizontal: AmberSpace.s3, vertical: AmberSpace.s2),
          shape: RoundedRectangleBorder(borderRadius: AmberRadius.button),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: inkSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: sunken,
        selectedColor: accent,
        disabledColor: inkTertiary.withValues(alpha: 0.15),
        labelStyle: textTheme.bodySmall?.copyWith(color: inkPrimary),
        secondaryLabelStyle: textTheme.bodySmall?.copyWith(color: inkOnAccent),
        padding: const EdgeInsets.symmetric(horizontal: AmberSpace.s2, vertical: AmberSpace.s1),
        shape: RoundedRectangleBorder(borderRadius: AmberRadius.pill(32)),
        side: BorderSide.none,
      ),

      dividerTheme: DividerThemeData(
        color: outlineVariant,
        thickness: 1,
        space: AmberSpace.s5,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        elevation: 3.0,
        shape: RoundedRectangleBorder(borderRadius: AmberRadius.dialog),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: AmberRadius.sheetTop),
        showDragHandle: true,
        dragHandleColor: inkTertiary,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isLight ? AmberColors.inverseSurfaceLight : AmberColors.inverseSurfaceDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight ? AmberColors.onInverseSurfaceLight : AmberColors.onInverseSurfaceDark,
        ),
        actionTextColor: isLight ? AmberColors.accentDark : AmberColors.accentLight,
        shape: RoundedRectangleBorder(borderRadius: AmberRadius.card),
        insetPadding: const EdgeInsets.all(AmberSpace.s3),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: inkPrimary, borderRadius: BorderRadius.circular(AmberRadius.box)),
        textStyle: textTheme.bodySmall?.copyWith(color: canvas),
        padding: const EdgeInsets.symmetric(horizontal: AmberSpace.s2, vertical: AmberSpace.s1),
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68.0,
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0.0,
        indicatorColor: accent.withValues(alpha: 0.16),
        indicatorShape: RoundedRectangleBorder(borderRadius: AmberRadius.pill(40)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? accent : inkTertiary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? accent : inkTertiary);
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: inkTertiary,
        labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.bodyMedium,
        indicatorColor: accent,
        dividerColor: outlineVariant,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: inkSecondary,
        textColor: inkPrimary,
        tileColor: Colors.transparent,
        selectedTileColor: sunken,
        contentPadding: const EdgeInsets.symmetric(horizontal: AmberSpace.s3, vertical: AmberSpace.s1),
        shape: RoundedRectangleBorder(borderRadius: AmberRadius.boxRadius),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent : inkTertiary),
        trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? accent.withValues(alpha: 0.4) : sunken),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent : Colors.transparent),
        checkColor: WidgetStateProperty.all(inkOnAccent),
        side: BorderSide(color: inkTertiary, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? accent : inkTertiary),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: sunken,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.15),
        valueIndicatorColor: inkPrimary,
        trackHeight: 3.0,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: sunken,
        circularTrackColor: sunken,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(inkTertiary.withValues(alpha: 0.6)),
        thickness: WidgetStateProperty.all(6.0),
        radius: const Radius.circular(3.0),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: raised,
        surfaceTintColor: Colors.transparent,
        elevation: 3.0,
        shape: RoundedRectangleBorder(borderRadius: AmberRadius.card),
        textStyle: textTheme.bodyMedium,
      ),

      iconTheme: IconThemeData(color: inkSecondary, size: 22),
      primaryIconTheme: IconThemeData(color: inkOnAccent, size: 22),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary, Color tertiary) {
    // Swap fontFamily for your chosen serif once you add it via pubspec.
    // Full Material 3 role set (not just the handful the app currently
    // uses) so nothing downstream falls back to Flutter's generic default
    // if a page reaches for displayLarge or labelLarge later.
    // Sizes follow Amber-Paper's 14px-base, 1.2-ratio scale; letter
    // spacing tightens as size goes up and loosens for small caps/labels,
    // per normal type-scale practice.
    return TextTheme(
      displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.1, color: primary),
      displayMedium: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.4, height: 1.15, color: primary),
      displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.2, color: primary),
      headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, height: 1.2, color: primary),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25, color: primary), // h1
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3, color: primary), // h2
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.3, color: primary),
      titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.35, color: primary), // h3
      titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4, color: primary),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: primary),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5, color: primary), // body
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.45, color: secondary), // body-sm
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1, color: primary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.2, color: secondary),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, letterSpacing: 0.3, color: tertiary), // caption
    );
  }
}