import 'package:flutter/material.dart';

class UserStatCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String value;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool dense;

  const UserStatCard({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    this.actionLabel,
    this.onAction,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = dense ? 22.0 : 36.0;
    final padding = dense ? const EdgeInsets.all(10.0) : const EdgeInsets.all(20.0);
    final titleStyle = TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.w500,
      fontSize: dense ? 12 : 15,
    );
    final valueStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: dense ? 15 : 24,
    );
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: color,
      minimumSize: dense ? const Size(28, 28) : null,
      padding: dense ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: iconSize),
            SizedBox(width: dense ? 8 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: titleStyle),
                  SizedBox(height: dense ? 2 : 4),
                  Text(value, style: valueStyle),
                ],
              ),
            ),
            if (actionLabel != null && onAction != null)
              ElevatedButton(
                onPressed: onAction,
                style: buttonStyle,
                child: Text(actionLabel!, style: TextStyle(fontSize: dense ? 12 : 14)),
              ),
          ],
        ),
      ),
    );
  }
}
