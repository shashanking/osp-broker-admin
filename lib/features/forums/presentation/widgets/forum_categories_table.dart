import 'package:flutter/material.dart';
import '../../domain/forum_models.dart';

class ForumCategoriesTable extends StatelessWidget {
  final List<Category> categories;
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
  final Category category;
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
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Icon(Icons.category_outlined, size: 20),
          ),
          Expanded(
            child: Text(
              // Show number of threads if available in category.count['threads']
              (category.count != null && category.count?['threads'] != null)
                  ? category.count!['threads']?.toString()??'0'
                  : '-',
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              category.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: category.isActive ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                  
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
