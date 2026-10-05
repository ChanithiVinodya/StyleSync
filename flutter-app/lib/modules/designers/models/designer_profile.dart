class DesignerProfile {
  final String id;
  final String userId;
  final String name;
  final String specialty;
  final String location;
  final double matchRate;
  final double rating;
  final int reviews;
  final String about;
  final String avatarUrl;
  final String coverUrl;

  DesignerProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.specialty,
    required this.location,
    required this.matchRate,
    required this.rating,
    required this.reviews,
    required this.about,
    required this.avatarUrl,
    required this.coverUrl,
  });

  factory DesignerProfile.fromJson(Map<String, dynamic> json) {
    return DesignerProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      specialty: json['specialty'] as String,
      location: json['location'] as String,
      matchRate: (json['matchRate'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviews: json['reviews'] as int,
      about: json['about'] as String,
      avatarUrl: json['avatarUrl'] as String,
      coverUrl: json['coverUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'specialty': specialty,
      'location': location,
      'matchRate': matchRate,
      'rating': rating,
      'reviews': reviews,
      'about': about,
      'avatarUrl': avatarUrl,
      'coverUrl': coverUrl,
    };
  }
}
