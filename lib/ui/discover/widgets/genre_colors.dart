import 'package:material_ui/material_ui.dart';

import '../../core/themes/theme.dart';

// tags list a song's main genre first
int? mainSlot(List<String?> slots, List<String> genres) {
  for (final genre in genres) {
    final slot = slots.indexOf(genre);
    if (slot != -1) return slot;
  }
  return null;
}

Color matchColor(AppColors colors, List<String?> slots, List<String> genres) {
  final slot = mainSlot(slots, genres);
  if (slot == null) return colors.noMatch;
  return colors.genres[slot];
}
