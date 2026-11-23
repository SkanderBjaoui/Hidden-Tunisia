import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/place.dart';
import '../providers/place_provider.dart';
import '../services/location_service.dart';
import '../services/app_exception.dart';
import '../utils/app_colors.dart';
import '../utils/ui.dart';
import '../widgets/auth_layout.dart' show FormErrorBox;
import '../widgets/custom_button.dart';
import '../widgets/place_image.dart';
import '../widgets/rating_stars.dart';
import '../widgets/review_card.dart';

/// Full information about one place.
class PlaceDetailsScreen extends StatelessWidget {
  final Place place;

  const PlaceDetailsScreen({super.key, required this.place});

  /// Bridge to the native maps app.
  Future<void> _openDirections(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await LocationService().openDirections(
        latitude: place.latitude,
        longitude: place.longitude,
        label: place.name,
      );
    } on LocationException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _writeReview(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // lets the sheet move up with the keyboard
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ReviewForm(place: place),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consumer rebuilds when favorites or reviews change.
    return Consumer<PlaceProvider>(
      builder: (context, provider, _) {
        // Always show the latest version from the database (new reviews...).
        final place = provider.resolve(this.place);
        final isFavorite = provider.isFavorite(place.id);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    tooltip: isFavorite ? 'Remove from saved' : 'Save',
                    onPressed: () =>
                        toggleFavoriteWithFeedback(context, provider, place),
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? Colors.redAccent : Colors.white,
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: PlaceImage(
                    url: place.imageUrl,
                    fallbackIcon: place.category.icon,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.city,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Chip(
                            avatar: Icon(
                              place.category.icon,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            label: Text(place.category.label),
                            backgroundColor: AppColors.light,
                            side: BorderSide.none,
                          ),
                          const SizedBox(width: 12),
                          RatingStars(rating: place.rating, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${place.rating.toStringAsFixed(1)} (${place.reviews.length})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.description,
                        style: const TextStyle(
                          color: AppColors.text,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.light,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.pin_drop_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(place.addressOrCoordinates),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.my_location_rounded,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${place.latitude.toStringAsFixed(5)}, '
                                  '${place.longitude.toStringAsFixed(5)}',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        label: 'Get Directions',
                        icon: Icons.directions_rounded,
                        onPressed: () => _openDirections(context),
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        label: isFavorite
                            ? 'Remove from favorites'
                            : 'Save to favorites',
                        icon: isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        outlined: true,
                        onPressed: () => toggleFavoriteWithFeedback(
                          context,
                          provider,
                          place,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Reviews',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _writeReview(context),
                            icon: const Icon(Icons.rate_review_rounded),
                            label: const Text('Write a review'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (place.reviews.isEmpty)
                        const Text(
                          'No reviews yet. Be the first!',
                          style: TextStyle(color: AppColors.textMuted),
                        )
                      else
                        ...place.reviews.map((r) => ReviewCard(review: r)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet with a form to submit a review. Stateful: owns the form key,
/// the text controllers and the chosen rating.
class _ReviewForm extends StatefulWidget {
  final Place place;

  const _ReviewForm({required this.place});

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _ratingError = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // One review per user per place: start from the existing one, if any.
    final existing = context.read<PlaceProvider>().myReviewFor(widget.place);
    if (existing != null) {
      _rating = existing.rating;
      _commentController.text = existing.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    setState(() => _ratingError = _rating == 0);
    if (!valid || _rating == 0) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<PlaceProvider>().addReview(
        widget.place,
        _rating,
        _commentController.text.trim(),
      );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Thank you! Your review was saved.')),
      );
    } on AppException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keep the form above the keyboard.
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Review ${widget.place.name}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) FormErrorBox(message: _error!),
              const Text('Your rating'),
              const SizedBox(height: 6),
              RatingStars(
                rating: _rating.toDouble(),
                size: 36,
                onChanged: (value) => setState(() {
                  _rating = value;
                  _ratingError = false;
                }),
              ),
              if (_ratingError)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Please choose a rating from 1 to 5',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Your comment',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please write a comment';
                  }
                  if (value.trim().length < 5) {
                    return 'The comment is too short (min 5 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              CustomButton(
                label: 'Submit review',
                icon: Icons.send_rounded,
                loading: _saving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
