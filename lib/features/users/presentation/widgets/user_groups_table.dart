import 'package:flutter/material.dart';

class UserGroupsTable extends StatelessWidget {
  const UserGroupsTable({super.key});

  @override
  Widget build(BuildContext context) {
    // Replace with actual groups data table
    return Card(
      margin: const EdgeInsets.all(24.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Groups', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Expanded(
              child: Center(child: Text('Groups list goes here.')),
            ),
          ],
        ),
      ),
    );
  }
}
