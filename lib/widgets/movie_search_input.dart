import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MovieSearchInput extends StatelessWidget {
  const MovieSearchInput({
    super.key,
    required this.controller,
    required this.onSearch,
    this.compact = false,
    this.loading = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final bool compact;
  final bool loading;

  void _submit() {
    final value = controller.text.trim();
    if (value.isNotEmpty && !loading) onSearch(value);
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        hintText: 'Digite um título',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.surfaceRaised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );

    final button = ElevatedButton(
      onPressed: loading ? null : _submit,
      style: compact
          ? ElevatedButton.styleFrom(
              minimumSize: const Size(94, 48),
              padding: const EdgeInsets.symmetric(horizontal: 15),
            )
          : null,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : compact
          ? const Text('Buscar')
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Buscar'),
                SizedBox(width: 9),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
    );

    if (compact) {
      return Row(
        children: [
          Expanded(child: field),
          const SizedBox(width: 10),
          button,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field,
        const SizedBox(height: 10),
        SizedBox(height: 52, child: button),
      ],
    );
  }
}
