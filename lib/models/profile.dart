/// Row of the `profiles` table (one per registered user).
class Profile {
  final String id;
  final String username;
  final String? avatarUrl;

  const Profile({required this.id, required this.username, this.avatarUrl});

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'] as String,
    username: map['username'] as String? ?? 'Explorer',
    avatarUrl: map['avatar_url'] as String?,
  );
}
