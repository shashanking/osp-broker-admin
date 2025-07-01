import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import '../widgets/membership_management_header.dart';
import '../widgets/create_membership_card.dart';
import '../widgets/membership_summary_card.dart';
import '../widgets/membership_plan_card.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TopBar(
          userName: 'Admin',
          userRole: 'Admin',
          notificationCount: '5',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: MembershipManagementHeader(),
        ),
        SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CreateMembershipCard(
                onTap: () {
                  // TODO: Implement create membership action
                },
              ),
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
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.2,
            children: [
              MembershipPlanCard(
                  planName: 'Free Plan',
                  price: '0',
                  subscribers: '1200',
                  color: Colors.black,
                  benefits: 'Lorem ipsum dolor sit amet...'),
              MembershipPlanCard(
                  planName: 'Bronze Plan',
                  price: '49',
                  subscribers: '443',
                  color: Colors.orange,
                  benefits: 'Lorem ipsum dolor sit amet...'),
              MembershipPlanCard(
                  planName: 'Silver Plan',
                  price: '59',
                  subscribers: '730',
                  color: Colors.blueGrey,
                  benefits: 'Lorem ipsum dolor sit amet...'),
              MembershipPlanCard(
                  planName: 'Gold Plan',
                  price: '79',
                  subscribers: '380',
                  color: Colors.amber,
                  benefits: 'Lorem ipsum dolor sit amet...'),
              MembershipPlanCard(
                  planName: 'Platinum Plan',
                  price: '99',
                  subscribers: '104',
                  color: Colors.teal,
                  benefits: 'Lorem ipsum dolor sit amet...'),
              MembershipPlanCard(
                  planName: 'Diamond Plan',
                  price: '149',
                  subscribers: '98',
                  color: Colors.lightBlueAccent,
                  benefits: 'Lorem ipsum dolor sit amet...'),
            ],
          ),
        ),
      ],
    );
  }
}
