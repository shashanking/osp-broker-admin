import 'package:flutter/material.dart';

class ForumTabs extends StatelessWidget {
  final int selectedTab;
  final void Function(int) onTabSelected;
  final List<String> badges;
  const ForumTabs({super.key, required this.selectedTab, required this.onTabSelected, required this.badges});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Row(
        children: [
          _buildPillTab('Forum Categories', 0),
          const SizedBox(width: 8),
          _buildPillTab('Forums List', 1),
          const SizedBox(width: 8),
          _buildPillTab('Threads List', 2),
        ],
      ),
    );
  }

  Widget _buildPillTab(String label, int idx) {
    final bool isSelected = selectedTab == idx;
    final badge = badges.length > idx ? badges[idx] : null;
    return GestureDetector(
      onTap: () => onTabSelected(idx),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            if (badge != null && badge.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue[50] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
