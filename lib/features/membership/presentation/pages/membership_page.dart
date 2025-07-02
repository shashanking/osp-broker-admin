import 'package:flutter/material.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import '../widgets/membership_management_header.dart';
import '../widgets/create_membership_card.dart';
import '../widgets/membership_plan_card.dart';
import '../widgets/membership_summary_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/membership_notifier.dart';
import '../widgets/add_membership_dialog.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';

class MembershipPage extends ConsumerStatefulWidget {
  const MembershipPage({super.key});

  @override
  ConsumerState<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends ConsumerState<MembershipPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(membershipNotifierProvider.notifier);

      notifier.fetchMemberships();
    });
  }

  @override
  Widget build(BuildContext context) {
    final membershipState = ref.watch(membershipNotifierProvider);
    return Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) => const AddMembershipDialog(),
          ),
          child: const Icon(Icons.add),
        ),
        body: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TopBar(
              userName: 'Admin',
              userRole: 'Admin',
              notificationCount: '5',
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
              child: MembershipManagementHeader(),
            ),
            SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  CreateMembershipCard(),
                  MembershipSummaryCard(
                    title: 'Total Members',
                    value: '5,448',
                    icon: Icons.group,
                    change: '-2.0%',
                    color: Colors.blue,
                  ),
                  MembershipSummaryCard(
                    title: 'New Members',
                    value: '1,395',
                    icon: Icons.person_add_alt_1,
                    change: '+2.3%',
                    color: Colors.indigo,
                  ),
                  MembershipSummaryCard(
                    title: 'Blocked Members',
                    value: '395',
                    icon: Icons.block,
                    change: '-2.3%',
                    color: Colors.red,
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text('Membership Plans',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (membershipState.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (membershipState.error != null) {
                    return Center(
                        child: Text('Error: ${membershipState.error}'));
                  }
                  if (membershipState.plans.isEmpty) {
                    return const Center(
                        child: Text('No membership plans found.'));
                  }
                  return GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: membershipState.plans
                        .map((plan) => MembershipPlanCard(
                              plan: plan,
                              color: Colors.blueGrey,
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ));
  }
}
