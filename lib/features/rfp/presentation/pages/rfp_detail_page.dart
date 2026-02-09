import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
      return Scaffold(
        appBar: AppBar(
          title: const Text('RFP Details'),
          backgroundColor: const Color(0xFF24439B),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null && rfp == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('RFP Details'),
          backgroundColor: const Color(0xFF24439B),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(state.error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(rfpNotifierProvider.notifier)
                    .loadRfpById(widget.rfpId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (rfp == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('RFP Details'),
          backgroundColor: const Color(0xFF24439B),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('RFP not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          rfp.projectTitle.isNotEmpty ? rfp.projectTitle : 'RFP Details',
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color(0xFF24439B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/rfps'),
        ),
        actions: [
          if (rfp.isDeleted)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Chip(
                label: Text('Soft Deleted', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white),
                padding: EdgeInsets.symmetric(horizontal: 6),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Title Card
            _buildProjectTitleCard(rfp),
            const SizedBox(height: 16),

            // Contact Information Card
            _buildContactInfoCard(rfp),
            const SizedBox(height: 16),

            // Project Details Card
            _buildProjectDetailsCard(rfp),
            const SizedBox(height: 16),

            // Description Card
            if (rfp.description.isNotEmpty) ...[
              _buildDescriptionCard(rfp),
              const SizedBox(height: 16),
            ],

            // Message Card
            if (rfp.message.isNotEmpty) ...[
              _buildMessageCard(rfp),
              const SizedBox(height: 16),
            ],

            // Files Card
            if (rfp.additionalFiles.isNotEmpty) ...[
              _buildFilesCard(rfp),
              const SizedBox(height: 16),
            ],

            // Timestamps Card
            _buildTimestampsCard(rfp),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTitleCard(rfp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Title',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rfp.projectTitle.isNotEmpty ? rfp.projectTitle : 'Untitled Project',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(rfp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person, 'Name', rfp.name),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email, 'Email', rfp.email),
          const SizedBox(height: 12),
          if (rfp.phoneNumber != null)
            _buildInfoRow(Icons.phone, 'Phone', rfp.phoneNumber.toString()),
        ],
      ),
    );
  }

  Widget _buildProjectDetailsCard(rfp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Project Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (rfp.price != null)
            _buildInfoRow(
                Icons.attach_money, 'Price', '\$${rfp.price.toString()}'),
          if (rfp.price != null) const SizedBox(height: 12),
          if (rfp.deadline.isNotEmpty)
            _buildInfoRow(Icons.schedule, 'Deadline', rfp.deadline),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(rfp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rfp.description,
            style: const TextStyle(
                fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(rfp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Message',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rfp.message,
            style: const TextStyle(
                fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesCard(rfp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Files',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rfp.additionalFiles,
            style: const TextStyle(
                fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampsCard(rfp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timestamps',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (rfp.createdAt != null)
            _buildInfoRow(
                Icons.access_time, 'Created', _formatDate(rfp.createdAt!)),
          if (rfp.createdAt != null) const SizedBox(height: 12),
          if (rfp.updatedAt != null)
            _buildInfoRow(Icons.update, 'Updated', _formatDate(rfp.updatedAt!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy \'at\' h:mm a').format(dateTime);
  }
}
