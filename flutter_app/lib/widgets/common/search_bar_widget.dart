import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final bool isSearching;
  final String? hint;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    this.isSearching = false,
    this.hint,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final surface = scheme.surface;
    final borderColor = _hasFocus
        ? scheme.primary.withValues(alpha: 0.45)
        : scheme.outline.withValues(alpha: 0.12);
    final shadowColor = theme.shadowColor.withValues(
      alpha: theme.brightness == Brightness.dark ? 0.35 : 0.10,
    );

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: _hasFocus ? 18 : 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
      ),
      child: Focus(
        onFocusChange: (focus) => setState(() => _hasFocus = focus),
        child: TextField(
          controller: widget.controller,
          onSubmitted: widget.onSearch,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint ?? 'Search recipes, ingredients...',
            hintStyle: TextStyle(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.75),
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                Iconsax.search_normal,
                color: _hasFocus ? scheme.primary : scheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIcon: widget.isSearching
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                  )
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: scheme.onSurfaceVariant,
                          size: 18,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          widget.onSearch('');
                        },
                      )
                    : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 16,
            ),
          ),
        ),
      ),
    );
  }
}
