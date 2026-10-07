import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MoviePoster extends StatelessWidget {
  const MoviePoster({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final String url;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final hasImage = url.trim().isNotEmpty && url.toUpperCase() != 'N/A';
    if (!hasImage) return _placeholder();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(showSpinner: true);
        },
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      ),
    );
  }

  Widget _placeholder({bool showSpinner = false}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF263B4C), Color(0xFF142330)],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.local_movies_rounded,
                color: AppColors.muted,
                size: 32,
              ),
      ),
    );
  }
}
