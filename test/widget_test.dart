import 'package:flutter_test/flutter_test.dart';
import 'package:hidden_tunisia/models/place.dart';
import 'package:hidden_tunisia/utils/validators.dart';

void main() {
  test('Place.fromMap parses a Supabase row with nested reviews', () {
    final place = Place.fromMap({
      'id': 'p1',
      'name': 'Cap Serrat Wild Beach',
      'city': 'Sejnane',
      'description': 'A wild beach.',
      'category': 'beaches',
      'image_url': null,
      'base_rating': 4.0,
      'latitude': 37.2333,
      'longitude': 9.2167,
      'created_by': 'u1',
      'reviews': [
        {
          'id': 'r1',
          'user_id': 'u2',
          'rating': 5,
          'comment': 'Superb place',
          'created_at': '2025-06-01T10:00:00Z',
          'profiles': {'username': 'Amira'},
        },
      ],
    });
    expect(place.category, PlaceCategory.beaches);
    expect(place.imageUrl, '');
    expect(place.reviews.single.author, 'Amira');
    expect(place.rating, 4.5); // (4.0 base + 5) / 2
  });

  test('validators accept good input and reject bad input', () {
    expect(Validators.email('a@b.tn'), isNull);
    expect(Validators.email('nope'), isNotNull);
    expect(Validators.password('12345'), isNotNull);
    expect(Validators.password('123456'), isNull);
    expect(Validators.confirmation(() => 'abc123')('abc124'), isNotNull);
    expect(Validators.confirmation(() => 'abc123')('abc123'), isNull);
  });
}
