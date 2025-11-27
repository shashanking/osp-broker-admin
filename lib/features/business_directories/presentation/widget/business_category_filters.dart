import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/business_directories_notifier.dart';

class BusinessCategoryFilters extends ConsumerWidget {
  const BusinessCategoryFilters({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(businessDirectoriesNotifierProvider);
    final notifier = ref.read(businessDirectoriesNotifierProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Filter label
          const Text(
            'Filter Categories:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(width: 16),
          
          // Show all button
          _FilterChip(
            label: 'All',
            isSelected: !state.showActiveOnly && !state.showDeletedOnly,
            onPressed: () => notifier.showAllCategories(),
          ),
          const SizedBox(width: 8),
          
          // Show active only button
          _FilterChip(
            label: 'Active Only',
            isSelected: state.showActiveOnly,
            onPressed: () => notifier.showActiveOnly(),
          ),
          const SizedBox(width: 8),
          
          // Show deleted only button
          _FilterChip(
            label: 'Deleted Only',
            isSelected: state.showDeletedOnly,
            onPressed: () => notifier.showDeletedOnly(),
          ),
          
          const Spacer(),
          
          // Statistics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Total: ${state.categories.length} | Active: ${state.categories.where((c) => !c.isDeleted).length} | Deleted: ${state.categories.where((c) => c.isDeleted).length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
