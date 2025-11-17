import 'package:flutter/material.dart';
import 'package:pesca_game/src/features/shop/domain/models/shop_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

class ShopPlaceholderScreen extends StatefulWidget {
  final Function(ShopItem) onRodEquipped;
  final ShopItem? equippedRod;
  const ShopPlaceholderScreen({super.key, required this.onRodEquipped, this.equippedRod});

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
              return ShopItemCard(
                item: items[index],
                onRodEquipped: widget.onRodEquipped,
                equippedRod: widget.equippedRod,
              );
            },
          );
        },
      ),
    );
  }
}

class ShopItemCard extends StatefulWidget {
  final ShopItem item;
  final Function(ShopItem) onRodEquipped;
  final ShopItem? equippedRod;

  const ShopItemCard({super.key, required this.item, required this.onRodEquipped, this.equippedRod});

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

  void _handlePurchase() {
    // Prevent buying the same equipped rod again
    if (widget.equippedRod?.id == widget.item.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya tienes esta caña equipada.')),
      );
      return;
    }

    final bool isReplacement = widget.equippedRod != null;

    if (isReplacement) {
      // Show replacement warning first
      _showReplacementWarning().then((confirmed) {
        if (confirmed == true) {
          // If confirmed, show purchase details
          _showPurchaseConfirmation();
        }
      });
    } else {
      // Not a replacement, just show purchase confirmation
      _showPurchaseConfirmation();
    }
  }

  // Shows the replacement warning dialog
  Future<bool?> _showReplacementWarning() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Comprar otra caña?'),
        content: const Text('¿Estás seguro de comprar otra caña? Esto hará que tu caña anterior desaparezca.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Not confirmed
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirmed
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  // Shows the purchase confirmation dialog
  void _showPurchaseConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalles del pedido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: ${widget.item.name}'),
            Text('Precio: \$${widget.item.price.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('¿Estás seguro de proceder con el pago?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Compra cancelada.')),
              );
            },
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRodEquipped(widget.item);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Compra exitosa!')),
              );
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );
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
                        onPressed: _handlePurchase,
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
