import 'package:flutter/material.dart';

class ForumCategoriesTable extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  const ForumCategoriesTable({Key? key, required this.categories}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: const [
                Expanded(flex: 4, child: Text('Category Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                Expanded(child: Icon(Icons.category_outlined, size: 20)),
                Expanded(child: Text('Threads', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.left)),
                Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.left)),
                Expanded(child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.left)),
              ],
            ),
          ),
          const Divider(height: 32),
          ...categories.map((category) => _CategoryRow(category: category)).toList(),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final Map<String, dynamic> category;
  const _CategoryRow({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              category['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Expanded(child: Icon(Icons.category_outlined, size: 20)),
          Expanded(
            child: Text(
              category['threads'] as String,
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (category['isPrivate'] as bool) ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                category['status'] as String,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: (category['isPrivate'] as bool) ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Manage'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
