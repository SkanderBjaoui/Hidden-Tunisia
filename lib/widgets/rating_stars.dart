import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Shows a rating as stars. If [onChanged] is given, the stars are tappable
/// (used by the forms to let the user choose 1 to 5).
class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final position = index + 1;
        final IconData icon = rating >= position
            ? Icons.star_rounded
            : rating >= position - 0.5
            ? Icons.star_half_rounded
            : Icons.star_outline_rounded;
        final star = Icon(icon, color: AppColors.star, size: size);
        if (onChanged == null) return star;
        return GestureDetector(
          onTap: () => onChanged!(position),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: star,
          ),
        );
      }),
    );
  }
}
