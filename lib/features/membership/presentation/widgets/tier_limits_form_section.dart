import 'package:flutter/material.dart';
import '../../data/models/membership_plan_model.dart';

/// Shared "Tier & Limits" form section used by the add/edit membership dialogs.
///
/// Parents hold a `GlobalKey<TierLimitsFormSectionState>` and call [toPolicy]
/// on submit. Numeric limit fields left blank mean "unlimited" (sent as null
/// so the API clears the limit on update).
class TierLimitsFormSection extends StatefulWidget {
  final MembershipPlanModel? initial;
  const TierLimitsFormSection({super.key, this.initial});

  @override
  TierLimitsFormSectionState createState() => TierLimitsFormSectionState();
}

class TierLimitsFormSectionState extends State<TierLimitsFormSection> {
  static const _tiers = ['FREE', 'BRONZE', 'SILVER', 'GOLD', 'PLATINUM', 'DIAMOND'];

  String? _tier;
  late final TextEditingController _level;
  late final TextEditingController _messageQuota;
  late final TextEditingController _dailyMessageQuota;
  late final TextEditingController _dailyInMailQuota;
  late final TextEditingController _dailyConnectionQuota;
  late final TextEditingController _maxConnections;
  late final TextEditingController _monthlyEventQuota;
  late final TextEditingController _outreachCredits;
  late final TextEditingController _messageCharLimit;
  late final TextEditingController _maxBidAmount;
  late final TextEditingController _maxAuctions;
  bool _canCreatePrivateAuction = false;
  bool _canGift = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _tier = p?.tier;
    _level = TextEditingController(text: (p?.level ?? 0).toString());
    _messageQuota = TextEditingController(text: p?.monthlyMessageQuota?.toString() ?? '');
    _dailyMessageQuota = TextEditingController(text: p?.dailyMessageQuota?.toString() ?? '');
    _dailyInMailQuota = TextEditingController(text: p?.dailyInMailQuota?.toString() ?? '');
    _dailyConnectionQuota = TextEditingController(text: p?.dailyConnectionQuota?.toString() ?? '');
    _maxConnections = TextEditingController(text: p?.maxConnections?.toString() ?? '');
    _monthlyEventQuota = TextEditingController(text: p?.monthlyEventQuota?.toString() ?? '');
    _outreachCredits = TextEditingController(text: p?.outreachCredits?.toString() ?? '');
    _messageCharLimit = TextEditingController(text: p?.messageCharLimit?.toString() ?? '');
    _maxBidAmount = TextEditingController(text: p?.maxAuctionBidAmount?.toString() ?? '');
    _maxAuctions = TextEditingController(text: p?.maxConcurrentAuctions?.toString() ?? '');
    _canCreatePrivateAuction = p?.canCreatePrivateAuction ?? false;
    _canGift = p?.canGift ?? false;
  }

  @override
  void dispose() {
    _level.dispose();
    _messageQuota.dispose();
    _dailyMessageQuota.dispose();
    _dailyInMailQuota.dispose();
    _dailyConnectionQuota.dispose();
    _maxConnections.dispose();
    _monthlyEventQuota.dispose();
    _outreachCredits.dispose();
    _messageCharLimit.dispose();
    _maxBidAmount.dispose();
    _maxAuctions.dispose();
    super.dispose();
  }

  /// Policy map for the create/update request body.
  Map<String, dynamic> toPolicy() {
    int? asInt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : int.tryParse(c.text.trim());
    double? asDouble(TextEditingController c) =>
        c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

    return {
      'tier': _tier,
      'level': int.tryParse(_level.text.trim()) ?? 0,
      'monthlyMessageQuota': asInt(_messageQuota),
      'dailyMessageQuota': asInt(_dailyMessageQuota),
      'dailyInMailQuota': asInt(_dailyInMailQuota),
      'dailyConnectionQuota': asInt(_dailyConnectionQuota),
      'maxConnections': asInt(_maxConnections),
      'monthlyEventQuota': asInt(_monthlyEventQuota),
      'outreachCredits': asInt(_outreachCredits),
      'messageCharLimit': asInt(_messageCharLimit),
      'maxAuctionBidAmount': asDouble(_maxBidAmount),
      'maxConcurrentAuctions': asInt(_maxAuctions),
      'canCreatePrivateAuction': _canCreatePrivateAuction,
      'canGift': _canGift,
    };
  }

  String? _optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null; // blank = unlimited
    return num.tryParse(value.trim()) == null ? 'Enter a number or leave blank' : null;
  }

  Widget _limitField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Blank = unlimited',
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: _optionalNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 32),
        Text('Tier & Limits', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Limits are enforced platform-wide (chat, auctions, gifting). Blank = unlimited.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _tier,
                decoration: const InputDecoration(
                  labelText: 'Tier',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('None')),
                  ..._tiers.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t))),
                ],
                onChanged: (value) => setState(() => _tier = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _level,
                decoration: const InputDecoration(
                  labelText: 'Level (access rank)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final n = int.tryParse(value?.trim() ?? '');
                  if (n == null || n < 0) return 'Non-negative number required';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _limitField(_messageQuota, 'Messages / month')),
            const SizedBox(width: 16),
            Expanded(child: _limitField(_outreachCredits, 'Outreach credits')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _limitField(_dailyMessageQuota, 'Messages / day')),
            const SizedBox(width: 16),
            Expanded(child: _limitField(_dailyInMailQuota, 'PrimeMails / day')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _limitField(_messageCharLimit, 'Message char limit')),
            const SizedBox(width: 16),
            Expanded(child: _limitField(_maxBidAmount, 'Max bid amount (\$)')),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child: _limitField(_dailyConnectionQuota, 'Connection requests / day')),
            const SizedBox(width: 16),
            Expanded(child: _limitField(_maxConnections, 'Max connections')),
          ],
        ),
        const SizedBox(height: 16),
        _limitField(_monthlyEventQuota, 'Events / month'),
        const SizedBox(height: 16),
        _limitField(_maxAuctions, 'Max active auctions'),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Can create private auctions'),
          value: _canCreatePrivateAuction,
          onChanged: (v) => setState(() => _canCreatePrivateAuction = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Can gift items to other users'),
          value: _canGift,
          onChanged: (v) => setState(() => _canGift = v),
        ),
      ],
    );
  }
}
