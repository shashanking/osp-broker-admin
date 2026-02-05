import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/rfp/application/rfp_notifier.dart';

class RfpDetailPage extends ConsumerStatefulWidget {
  final String rfpId;

  const RfpDetailPage({
    super.key,
    required this.rfpId,
  });

  @override
  ConsumerState<RfpDetailPage> createState() => _RfpDetailPageState();
}

class _RfpDetailPageState extends ConsumerState<RfpDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rfpNotifierProvider.notifier).loadRfpById(widget.rfpId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfpNotifierProvider);
    final rfp = state.selectedRfp;

    if (state.isLoading && rfp == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && rfp == null) {
      return Center(child: Text(state.error!));
    }

    if (rfp == null) {
      return const Center(child: Text('RFP not found'));
    }

    Widget row(String label, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 160,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(value.isNotEmpty ? value : 'N/A')),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            rfp.projectTitle.isNotEmpty ? rfp.projectTitle : 'RFP Details',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          row('Name', rfp.name),
          row('Email', rfp.email),
          row('Phone', rfp.phoneNumber?.toString() ?? ''),
          row('Price', rfp.price?.toString() ?? ''),
          row('Deadline', rfp.deadline),
          row('Description', rfp.description),
          row('Message', rfp.message),
          row('Additional Files', rfp.additionalFiles),
          row('Created At', rfp.createdAt?.toIso8601String() ?? ''),
          row('Updated At', rfp.updatedAt?.toIso8601String() ?? ''),
        ],
      ),
    );
  }
}
