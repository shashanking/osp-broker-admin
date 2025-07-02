import 'package:flutter/material.dart';

class MembershipSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String change;
  final Color color;

  const MembershipSummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.change,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      margin: const EdgeInsets.only(right: 16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                SizedBox(height: 4),
                Text(title, style: TextStyle(color: Colors.grey[900])),
                SizedBox(height: 8),
              ],
            ),
            // Text(change,
            //     style: TextStyle(
            //         color: change.startsWith('+')
            //             ? Colors.green
            //             : Colors.red)),
          ],
        ),
      ),
    );
  }
}
