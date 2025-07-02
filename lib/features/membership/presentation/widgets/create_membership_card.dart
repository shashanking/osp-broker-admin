import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/add_membership_dialog.dart';

class CreateMembershipCard extends ConsumerWidget {
  const CreateMembershipCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      margin: const EdgeInsets.only(right: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => showDialog(
          context: context,
          builder: (context) => const AddMembershipDialog(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.amber, size: 32),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Create Membership',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  SizedBox(height: 4),
                  Text('Add new membership plan',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
