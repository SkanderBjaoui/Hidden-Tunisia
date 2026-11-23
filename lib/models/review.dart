/// A review (comment + 1-5 star rating) written by a user about a place.
class Review {
  final String id;
  final String userId;
  final String author; // the reviewer's username
  final int rating; // 1 to 5 stars
  final String comment;
  final DateTime date;

  const Review({
    required this.id,
    required this.userId,
    required this.author,
    required this.rating,
    required this.comment,
    required this.date,
  });

  /// Builds a Review from a row of the `reviews` table, with the reviewer's
  /// profile nested under `profiles`.
  factory Review.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return Review(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      author: profile?['username'] as String? ?? 'Traveller',
      rating: (map['rating'] as num).toInt(),
      comment: map['comment'] as String? ?? '',
      date:
          DateTime.tryParse(map['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
    );
  }
}
