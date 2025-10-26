import 'package:flutter/material.dart';

class ItemGrid<T> extends StatelessWidget {
  final List<T> items;
  final double size;
  final Widget Function(T item, double size) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const ItemGrid({
    super.key,
    required this.items,
    required this.size,
    required this.itemBuilder,
    this.crossAxisCount = 5,
    this.crossAxisSpacing = 10,
    this.mainAxisSpacing = 10,
  });

  @override
  Widget build(BuildContext context) {
    final rowCount = (items.length / crossAxisCount).ceil();
    final gridHeight = (rowCount * size) + ((rowCount - 1) * mainAxisSpacing) + 10;

    return SizedBox(
      height: gridHeight,
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 10, bottom: 0, right: 15),
        physics: const AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: crossAxisSpacing,
          mainAxisSpacing: mainAxisSpacing,
          childAspectRatio: 1,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return KeyedSubtree(key: ValueKey<int>(index), child: itemBuilder(items[index], size));
        },
      ),
    );
  }
}
