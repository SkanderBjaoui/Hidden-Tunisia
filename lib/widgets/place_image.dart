import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Network image with a loading state and a green placeholder if the image
/// is missing or cannot be loaded (no internet, broken link...).
class PlaceImage extends StatelessWidget {
  final String url;
  final double? height;
  final double? width;
  final IconData fallbackIcon;

  const PlaceImage({
    super.key,
    required this.url,
    this.height,
    this.width,
    this.fallbackIcon = Icons.landscape_rounded,
  });

  Widget _placeholder() => Container(
    height: height,
    width: width,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppColors.primary, AppColors.forest],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Icon(fallbackIcon, color: Colors.white70, size: 48),
  );

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) return _placeholder();
    return Image.network(
      url,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: height,
          width: width,
          color: AppColors.light,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );
  }
}
