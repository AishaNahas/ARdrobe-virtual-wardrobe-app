import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import '../services/wardrobe_service.dart';
import 'add_item_screen.dart';

class TypeItemsScreen extends StatefulWidget {
  final String type;
  final List<WardrobeItem> items;
  final String email;

  const TypeItemsScreen({
    super.key,
    required this.type,
    required this.items,
    required this.email,
  });

  @override
  State<TypeItemsScreen> createState() => _TypeItemsScreenState();
}

class _TypeItemsScreenState extends State<TypeItemsScreen> {
  final WardrobeService _wardrobeService = WardrobeService();
  late List<WardrobeItem> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  Future<void> _toggleFavorite(WardrobeItem item) async {
    try {
      await _wardrobeService.toggleFavorite(widget.email, item.id);
      setState(() {
        final index = _items.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          _items[index] = WardrobeItem(
            id: item.id,
            imageUrl: item.imageUrl,
            category: item.category,
            type: item.type,
            color: item.color,
            season: item.season,
            createdAt: item.createdAt,
            isFavorite: !item.isFavorite,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _deleteItem(WardrobeItem item) async {
    try {
      await _wardrobeService.deleteWardrobeItem(widget.email, item.id);
      setState(() {
        _items.removeWhere((i) => i.id == item.id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting item: $e')),
      );
    }
  }

  Future<void> _editItem(WardrobeItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(
          email: widget.email,
          item: item,
        ),
      ),
    );

    if (result == true) {
      // Refresh items
      final updatedItems =
          await _wardrobeService.getWardrobeItems(widget.email);
      setState(() {
        _items = updatedItems.where((i) => i.type == widget.type).toList();
      });
    }
  }

  void _showDeleteConfirmation(WardrobeItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3E0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.type,
          style: const TextStyle(
            color: Color(0xFF4B4B4B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.checkroom_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.type} items yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image
                        if (item.imageUrl.isNotEmpty)
                          Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.error_outline,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          )
                        else
                          Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        // Action buttons
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  item.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: item.isFavorite
                                      ? Colors.red
                                      : Colors.black,
                                ),
                                onPressed: () => _toggleFavorite(item),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                ),
                                onPressed: () => _editItem(item),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.black,
                                ),
                                onPressed: () => _showDeleteConfirmation(item),
                              ),
                            ],
                          ),
                        ),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.color} • ${item.season}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
