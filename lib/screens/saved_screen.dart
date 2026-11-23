import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/place_provider.dart';
import '../utils/app_colors.dart';
import '../utils/ui.dart';
import '../widgets/place_card.dart';
import 'place_details_screen.dart';

/// Lists the favorite places. Stateless: the data lives in PlaceProvider.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PlaceProvider>();
    final saved = provider.favorites;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: saved.isEmpty
            ? const _EmptyState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  const Text(
                    'Saved Places',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${saved.length} place${saved.length == 1 ? '' : 's'} saved',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  ...saved.map(
                    (place) => Dismissible(
                      // Swipe a card to remove it from the favorites.
                      key: ValueKey(place.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.only(right: 24),
                        alignment: Alignment.centerRight,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.delete_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onDismissed: (_) =>
                          toggleFavoriteWithFeedback(context, provider, place),
                      child: PlaceCard(
                        place: place,
                        isFavorite: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PlaceDetailsScreen(place: place),
                          ),
                        ),
                        onFavorite: () => toggleFavoriteWithFeedback(
                          context,
                          provider,
                          place,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: const BoxDecoration(
                color: AppColors.light,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Nothing saved yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the heart on any place in Explore to keep it here for later.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
