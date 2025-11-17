import 'package:flutter/material.dart';
import 'package:pesca_game/src/features/shop/domain/models/shop_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class ShopPlaceholderScreen extends StatefulWidget {
  const ShopPlaceholderScreen({super.key});

  @override
  State<ShopPlaceholderScreen> createState() => _ShopPlaceholderScreenState();
}

class _ShopPlaceholderScreenState extends State<ShopPlaceholderScreen> {
  late Future<List<ShopItem>> _shopItemsFuture;

  @override
  void initState() {
    super.initState();
    _shopItemsFuture = _fetchShopItems();
  }

  Future<List<ShopItem>> _fetchShopItems() async {
    final response = await Supabase.instance.client.from('shop_items').select();
    final items = (response as List).map((item) => ShopItem.fromMap(item)).toList();
    // Filter out the default rod for now
    return items.where((item) => item.abilityCode != 'DEFAULT').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      backgroundColor: Colors.blueGrey.shade800,
      body: FutureBuilder<List<ShopItem>>(
        future: _shopItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final items = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return ShopItemCard(item: items[index]);
            },
          );
        },
      ),
    );
  }
}

class ShopItemCard extends StatefulWidget {
  final ShopItem item;

  const ShopItemCard({super.key, required this.item});

  @override
  State<ShopItemCard> createState() => _ShopItemCardState();
}

class _ShopItemCardState extends State<ShopItemCard> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.asset(widget.item.videoPath)
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.setVolume(0);
        _videoController.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.blueGrey.shade700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: _videoController.value.isInitialized
                ? VideoPlayer(_videoController)
                : const Center(child: CircularProgressIndicator()),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${widget.item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.greenAccent,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Implement buy logic
                        },
                        child: const Text('Comprar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
