class ShopItem {
  final int id;
  final String name;
  final String description;
  final double price;
  final String abilityCode;

  ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.abilityCode,
  });

  factory ShopItem.fromMap(Map<String, dynamic> map) {
    return ShopItem(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      price: (map['price_usd'] as num).toDouble(),
      abilityCode: map['ability_code'],
    );
  }

  String get videoPath {
    const videoMap = {
      'PARALYZE_CHANCE': 'cana_rayo.mp4',
      'EXTRA_POINT_CHANCE': 'cana_madera.mp4',
      'DOUBLE_POINTS_CHANCE': 'cana_chichen.mp4',
      'DEFAULT': 'cana_madera.mp4', // Default video
    };
    return 'assets/videos/${videoMap[abilityCode] ?? 'cana_madera.mp4'}';
  }
}
