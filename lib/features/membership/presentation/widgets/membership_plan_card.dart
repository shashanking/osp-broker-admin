import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/membership/data/models/membership_plan_model.dart';
import 'package:osp_broker_admin/features/membership/application/membership_notifier.dart';
import 'edit_membership_dialog.dart';

/// A clean management card for a single membership plan: tier, price,
/// subscriber count, the full limit/permission settings, and edit/delete.
class MembershipPlanCard extends ConsumerWidget {
  final MembershipPlanModel plan;
  final Color color; // unused now; kept for call-site compatibility

  const MembershipPlanCard({
    super.key,
    required this.plan,
    this.color = const Color(0xFF24439B),
  });

  static const _tierColors = <String, Color>{
    'FREE': Color(0xFF9AA0A6),
    'BRONZE': Color(0xFFB08D57),
    'SILVER': Color(0xFF9EA7B3),
    'GOLD': Color(0xFFE0A23B),
    'PLATINUM': Color(0xFF5B7C99),
    'DIAMOND': Color(0xFF00B4D8),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = (plan.tier ?? '').toUpperCase();
    final accent = _tierColors[tier] ?? const Color(0xFF24439B);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // colored header
          Container(
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              plan.name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _tierBadge(tier.isEmpty ? 'NO TIER' : tier, accent),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${plan.price.toStringAsFixed(2)} · ${plan.billingCycle}'
                        '   ·   ${plan.userMembership.length} subscribers',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Limits grid
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _limitChip('Messages/mo', _num(plan.monthlyMessageQuota)),
                    _limitChip('Messages/day', _num(plan.dailyMessageQuota)),
                    _limitChip('PrimeMails/day', _num(plan.dailyInMailQuota)),
                    _limitChip('Outreach', _num(plan.outreachCredits)),
                    _limitChip('Msg length',
                        plan.messageCharLimit == null ? '∞' : '${plan.messageCharLimit}'),
                    _limitChip(
                        'Max bid',
                        plan.maxAuctionBidAmount == null
                            ? '∞'
                            : (plan.maxAuctionBidAmount == 0
                                ? '—'
                                : '\$${plan.maxAuctionBidAmount!.toStringAsFixed(0)}')),
                    _limitChip(
                        'Auctions',
                        plan.maxConcurrentAuctions == null
                            ? '∞'
                            : '${plan.maxConcurrentAuctions}'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _flag('Private auctions', plan.canCreatePrivateAuction),
                    const SizedBox(width: 16),
                    _flag('Gifting', plan.canGift),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => EditMembershipDialog(plan: plan),
                        ),
                        icon: const Icon(Icons.tune, size: 18),
                        label: const Text('Edit settings'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: accent,
                          side: BorderSide(color: accent.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Delete plan',
                      onPressed: () => _confirmDelete(context, ref),
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red[400],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _num(int? v) => v == null ? '∞' : '$v';

  Widget _tierBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 10.5, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _limitChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(fontSize: 10.5, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _flag(String label, bool on) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(on ? Icons.check_circle : Icons.cancel,
            size: 16, color: on ? Colors.green : Colors.grey[400]),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12.5, color: Colors.grey[700])),
      ],
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete membership plan'),
        content: Text('Delete "${plan.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(membershipNotifierProvider.notifier)
                  .deleteMembership(plan.id);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
