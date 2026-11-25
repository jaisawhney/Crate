import 'package:material_ui/material_ui.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color accentWarm;
  final List<Color> genres;
  final Color noMatch;

  const AppColors({
    required this.accentWarm,
    required this.genres,
    required this.noMatch,
  });

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>()!;

  @override
  AppColors copyWith({Color? accentWarm, List<Color>? genres, Color? noMatch}) {
    return AppColors(
      accentWarm: accentWarm ?? this.accentWarm,
      genres: genres ?? this.genres,
      noMatch: noMatch ?? this.noMatch,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      genres: [
        for (var idx = 0; idx < genres.length; idx++)
          Color.lerp(genres[idx], other.genres[idx], t)!,
      ],
      noMatch: Color.lerp(noMatch, other.noMatch, t)!,
    );
  }
}

ThemeData buildAppTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF8B6CEF),
    brightness: brightness,
  );
  // light shades and the bright amber fade into light backgrounds
  var shade = 700;
  var warm = const Color(0xFFAE7015);
  var noMatch = Colors.grey.shade400;
  if (brightness == Brightness.dark) {
    shade = 400;
    warm = const Color(0xFFE8A33D);
    noMatch = Colors.grey.shade600;
  }
  final base = ThemeData(colorScheme: scheme);
  final border = BorderSide(
    color: scheme.outlineVariant.withValues(alpha: 0.5),
  );

  return base.copyWith(
    extensions: [
      AppColors(
        accentWarm: warm,
        // primaries run around the color wheel, so every other one stays apart
        genres: [
          for (var idx = 0; idx < Colors.primaries.length; idx += 2)
            Colors.primaries[idx][shade]!,
        ],
        noMatch: noMatch,
      ),
    ],
    scaffoldBackgroundColor: scheme.surface,
    dividerColor: border.color,
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: border,
      ),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
      side: WidgetStatePropertyAll(border),
      constraints: const BoxConstraints(minHeight: 52),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
    ),
    drawerTheme: DrawerThemeData(width: 220, shape: Border(right: border)),
    navigationDrawerTheme: NavigationDrawerThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      elevation: 0,
      tileHeight: 44,
      indicatorColor: scheme.secondaryContainer,
      indicatorSize: const Size(196, 44),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: DividerThemeData(color: border.color, space: 1),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      selectedColor: scheme.onSurface,
      selectedTileColor: scheme.surfaceContainerHighest,
    ),
  );
}
