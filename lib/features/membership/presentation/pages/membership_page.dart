import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import '../../application/membership_notifier.dart';
import '../widgets/membership_plan_card.dart';
import '../widgets/add_membership_dialog.dart';

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
      ref.read(membershipNotifierProvider.notifier).fetchMemberships();
    });
  }

  void _openAddPlan() {
    showDialog(
      context: context,
      builder: (context) => const AddMembershipDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipNotifierProvider);
    final plans = state.plans;

    final totalSubscribers =
        plans.fold<int>(0, (sum, p) => sum + p.userMembership.length);
    final paidPlans = plans.where((p) => p.price > 0).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          TopBar(userName: 'Admin', userRole: 'Admin', notificationCount: '5'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.card_membership,
                          color: Color(0xFF24439B), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Membership Management',
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Create plans and control what each tier can do',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openAddPlan,
                        icon: const Icon(Icons.add),
                        label: const Text('New plan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF24439B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Real summary
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _summary('Plans', '${plans.length}',
                          Icons.workspaces_outline, const Color(0xFF24439B)),
                      _summary('Paid plans', '$paidPlans',
                          Icons.workspace_premium, const Color(0xFFE0A23B)),
                      _summary('Subscribers', '$totalSubscribers',
                          Icons.group_outlined, const Color(0xFF2EC4B6)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  const Text('Membership Plans',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  _buildPlans(state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlans(MembershipState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('Error: ${state.error}')),
      );
    }
    if (state.plans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.card_membership_outlined,
                  size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              const Text('No membership plans yet'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _openAddPlan,
                icon: const Icon(Icons.add),
                label: const Text('Create your first plan'),
              ),
            ],
          ),
        ),
      );
    }

    // Responsive columns based on available width.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cols = w >= 1200 ? 3 : (w >= 760 ? 2 : 1);
        const gap = 16.0;
        final cardW = (w - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: state.plans
              .map((plan) => SizedBox(
                    width: cardW,
                    child: MembershipPlanCard(plan: plan),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _summary(String label, String value, IconData icon, Color color) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}
