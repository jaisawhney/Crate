import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/discover_view_model.dart';

class SearchField extends ConsumerStatefulWidget {
  const SearchField({super.key});

  @override
  ConsumerState<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<SearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _search(String text) {
    _debounce?.cancel();
    ref.read(discoverViewModelProvider.notifier).search(text);
  }

  void _searchSoon(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(text));
  }

  void _clear() {
    _controller.clear();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(queryProvider);

    return SearchBar(
      controller: _controller,
      hintText: 'Describe a sound',
      leading: const Icon(Icons.search),
      trailing: [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Clear',
            onPressed: _clear,
          ),
      ],
      onChanged: _searchSoon,
      onSubmitted: _search,
    );
  }
}
