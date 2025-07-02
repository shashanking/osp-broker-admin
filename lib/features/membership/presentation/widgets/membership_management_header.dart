import 'package:flutter/material.dart';

class MembershipManagementHeader extends StatelessWidget {
  const MembershipManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.window_rounded, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Membership Management',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('Manage your membership plans and members',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
