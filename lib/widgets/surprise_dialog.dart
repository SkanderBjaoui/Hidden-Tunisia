import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/place.dart';
import '../providers/place_provider.dart';
import '../screens/place_details_screen.dart';
import '../utils/app_colors.dart';
import 'custom_button.dart';
import 'place_image.dart';

/// "Surprise Me!" dialog. StatefulWidget because it owns an animation and
/// the place currently displayed (the user can ask for another one).
class SurpriseDialog extends StatefulWidget {
  final Place initialPlace;

  const SurpriseDialog({super.key, required this.initialPlace});

  @override
  State<SurpriseDialog> createState() => _SurpriseDialogState();
}

class _SurpriseDialogState extends State<SurpriseDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late Place _place;

  @override
  void initState() {
    super.initState();
    _place = widget.initialPlace;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose(); // always free animation controllers
    super.dispose();
  }

  void _another() {
    final next = context.read<PlaceProvider>().pickSurprise();
    if (next == null) return;
    setState(() => _place = next);
    _controller.forward(from: 0); // replay the animation
  }

  void _discover() {
    final navigator = Navigator.of(context);
    navigator.pop(); // close the dialog
    navigator.push(
      MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: _place)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ScaleTransition(
        scale: _scale,
        child: FadeTransition(
          opacity: _controller,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      PlaceImage(
                        url: _place.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fallbackIcon: _place.category.icon,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.9,
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.forest,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '✨ Your mystery destination',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _place.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _place.city,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _place.description,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        CustomButton(
                          label: 'Discover This Place',
                          icon: Icons.explore_rounded,
                          onPressed: _discover,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          label: 'Try another',
                          icon: Icons.shuffle_rounded,
                          outlined: true,
                          onPressed: _another,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
