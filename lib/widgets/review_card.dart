import 'package:flutter/material.dart';

import '../models/review.dart';
import '../utils/app_colors.dart';
import 'rating_stars.dart';

/// Displays one user review.
class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final d = review.date;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.light,
                child: Text(
                  review.author.isEmpty ? '?' : review.author[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.author,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RatingStars(rating: review.rating.toDouble(), size: 16),
          const SizedBox(height: 6),
          Text(review.comment, style: const TextStyle(color: AppColors.text)),
        ],
      ),
    );
  }
}
