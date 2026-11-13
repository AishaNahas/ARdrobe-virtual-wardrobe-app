class WardrobeItem {
  final String id;
  final String imageUrl;
  final String category; // casual, formal
  final String type; // tops, bottoms, dresses, etc.
  final String color;
  final String season;
  final DateTime createdAt;
  bool isFavorite;

  WardrobeItem({
    required this.id,
    required this.imageUrl,
    required this.category,
    required this.type,
    required this.color,
    required this.season,
    required this.createdAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'category': category,
      'type': type,
      'color': color,
      'season': season,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory WardrobeItem.fromMap(Map<String, dynamic> map) {
    return WardrobeItem(
      id: map['id'],
      imageUrl: map['imageUrl'],
      category: map['category'],
      type: map['type'],
      color: map['color'],
      season: map['season'],
      createdAt: DateTime.parse(map['createdAt']),
      isFavorite: map['isFavorite'] ?? false,
    );
  }
}
