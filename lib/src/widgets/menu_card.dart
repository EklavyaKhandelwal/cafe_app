import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_item.dart';

class MenuCard extends StatelessWidget {
  final MenuItem menuItem;
  final VoidCallback? onAddToCart;

  const MenuCard({
    super.key,
    required this.menuItem,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    const greenAccent = Color(0xFF4A3C31); // Match MenuScreen's theme
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Section
        AspectRatio(
          aspectRatio: 1.2, // Adjusted to better fit childAspectRatio: 0.7
          child: CachedNetworkImage(
            imageUrl: menuItem.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[200],
              child: const Center(child: CircularProgressIndicator(color: greenAccent)),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[200],
              child: const Icon(Icons.fastfood, size: 40, color: Color(0xFF7A6A5D)),
            ),
          ),
        ),
        // Content Section
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Reduced padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Item Name
                Text(
                  menuItem.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A3C31),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Item Description (if available)
                if (menuItem.description?.isNotEmpty ?? false)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        menuItem.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7A6A5D),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                const Spacer(), // Push price and button to bottom
                // Price and Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${menuItem.price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: greenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: greenAccent,
                      onPressed: onAddToCart,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}