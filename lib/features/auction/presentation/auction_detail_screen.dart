import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../application/auction_notifier.dart';
import '../domain/auction.dart';
import '../domain/bid.dart';
import 'package:intl/intl.dart';
import 'package:osp_broker_admin/features/users/presentation/pages/user_detail_page.dart';

class AuctionDetailScreen extends ConsumerStatefulWidget {
  final String auctionId;

  const AuctionDetailScreen({super.key, required this.auctionId});

  @override
  ConsumerState<AuctionDetailScreen> createState() => _AuctionDetailScreenState();
}

class _AuctionDetailScreenState extends ConsumerState<AuctionDetailScreen> {
  Auction? auction;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    // Move provider call out of initState to avoid modifying provider during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAuction();
    });
  }

  Future<void> _loadAuction() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final fetchedAuction = await ref.read(auctionNotifierProvider.notifier).fetchAuctionById(widget.auctionId);
      // Load bids for this auction
      await ref.read(auctionNotifierProvider.notifier).loadBids(widget.auctionId);
      setState(() {
        auction = fetchedAuction;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null || auction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Auction Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(error ?? 'Auction not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAuction,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(auction!.title)),
            if (auction!.isDeleted)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('Soft Deleted', style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.orange,
                  labelStyle: TextStyle(color: Colors.white),
                  padding: EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
            if (_isAuctionCompleted())
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('Completed', style: TextStyle(fontSize: 11)),
                  backgroundColor: Colors.grey,
                  labelStyle: TextStyle(color: Colors.white),
                  padding: EdgeInsets.symmetric(horizontal: 6),
                ),
              ),
          ],
        ),
        actions: [
          if (!auction!.approved)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () => _approveAuction(),
              tooltip: 'Approve Auction',
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'soft_delete') {
                _showSoftDeleteDialog();
              } else if (value == 'hard_delete') {
                _showHardDeleteDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'soft_delete',
                child: Row(
                  children: [
                    Icon(Icons.visibility_off, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Soft Delete'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'hard_delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Hard Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Indicators Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Approval Status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: auction!.approved ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: auction!.approved ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          auction!.approved ? Icons.check_circle : Icons.pending,
                          color: auction!.approved ? Colors.green[800] : Colors.orange[800],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          auction!.approved ? 'Approved' : 'Pending Approval',
                          style: TextStyle(
                            color: auction!.approved ? Colors.green[800] : Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Soft Delete Status
                  if (auction!.isDeleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_off,
                            color: Colors.orange[800],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Soft Deleted',
                            style: TextStyle(
                              color: Colors.orange[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Completion Status
                  if (_isAuctionCompleted())
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.grey[700],
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Auction Title
              Text(
                auction!.title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Auction Description
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildQuillDescription(auction!.description),

              const SizedBox(height: 24),

              // Auction Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auction Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Starting Bid
                      if (auction!.startingBid != 0) ...[
                        Row(
                          children: [
                            const Icon(Icons.attach_money, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'Starting Bid: \$${auction!.startingBid}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Categories
                      if (auction!.categoryIds.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.category, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Categories: ${auction!.categoryIds.length}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // End Date & Time
                      Row(
                        children: [
                          const Icon(Icons.schedule, color: Colors.purple),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ends: ${DateFormat('MMM dd, yyyy - hh:mm a').format(auction!.timeFrame)}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Created Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Created: ${DateFormat('MMM dd, yyyy').format(auction!.createdAt)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Auctioneer
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(
                            'Auctioneer: ',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserDetailPage(
                                    userId: auction!.userId,
                                    userName: 'User ${auction!.userId}',
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'View Profile',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Bids Section
              _buildBidsSection(),

              const SizedBox(height: 24),

              // Images Section (if available)
              if (auction!.mediaUrls.isNotEmpty) ...[
                Text(
                  'Images',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: auction!.mediaUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = auction!.mediaUrls[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showEditDialog(),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Auction'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to List'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveAuction() async {
    try {
      await ref.read(auctionNotifierProvider.notifier).approveAuction(auction!.id);
      setState(() {
        auction = auction!.copyWith(approved: true);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auction approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving auction: ${e.toString()}')),
      );
    }
  }

  void _showSoftDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soft Delete Auction'),
        content: Text(
          'Are you sure you want to soft delete "${auction!.title}"?\n\nThis will hide the auction but keep it in the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(auctionNotifierProvider.notifier).softDeleteAuction(auction!.id);
                Navigator.pop(context); // Close delete dialog
                Navigator.pop(context); // Go back to auction list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auction soft deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context); // Close delete dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error soft deleting auction: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Soft Delete'),
          ),
        ],
      ),
    );
  }

  void _showHardDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hard Delete Auction'),
        content: Text(
          'Are you sure you want to permanently delete "${auction!.title}"?\n\nThis action cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(auctionNotifierProvider.notifier).hardDeleteAuction(auction!.id);
                Navigator.pop(context); // Close delete dialog
                Navigator.pop(context); // Go back to auction list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auction permanently deleted')),
                );
              } catch (e) {
                Navigator.pop(context); // Close delete dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting auction: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hard Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildBidsSection() {
    final state = ref.watch(auctionNotifierProvider);
    final bids = state.bids;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bids (${bids.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state.isLoadingBids)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => ref.read(auctionNotifierProvider.notifier).loadBids(widget.auctionId),
                    tooltip: 'Refresh Bids',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (bids.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No bids yet'),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bids.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final bid = bids[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: bid.matched ? Colors.green : Colors.grey,
                      child: Icon(
                        bid.matched ? Icons.check : Icons.gavel,
                        color: Colors.white,
                      ),
                    ),
                    title: InkWell(
                      onTap: () {
                        if (bid.user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailPage(
                                userId: bid.userId,
                                userName: bid.user!.fullName,
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        bid.user?.fullName ?? 'Unknown User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: bid.user != null ? Colors.blue : Colors.black,
                          decoration: bid.user != null ? TextDecoration.underline : null,
                        ),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(bid.user?.email ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          bid.response,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                        if (bid.bidAmount != null)
                          Text(
                            'Amount: \$${bid.bidAmount!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        Text(
                          'Placed: ${DateFormat('MMM dd, yyyy - hh:mm a').format(bid.createdAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: bid.matched
                        ? const Chip(
                            label: Text('Winner'),
                            backgroundColor: Colors.green,
                            labelStyle: TextStyle(color: Colors.white),
                          )
                        : ElevatedButton(
                            onPressed: () => _selectWinner(bid),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                            ),
                            child: const Text('Select Winner'),
                          ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectWinner(Bid bid) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Winner'),
        content: Text(
          'Are you sure you want to select ${bid.user?.fullName ?? 'this user'} as the winner?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(auctionNotifierProvider.notifier).selectWinner(
          auctionId: widget.auctionId,
          bidId: bid.id,
          userId: bid.userId,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Winner selected successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting winner: ${e.toString()}')),
        );
      }
    }
  }

  void _showEditDialog() {
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  /// Check if auction is completed (timeFrame has passed or winner selected)
  bool _isAuctionCompleted() {
    // Check if timeFrame has passed
    if (auction!.timeFrame.isBefore(DateTime.now())) {
      return true;
    }
    
    // Check if a winner has been selected (any bid is matched)
    final state = ref.read(auctionNotifierProvider);
    return state.bids.any((bid) => bid.matched);
  }

  /// Build Quill description viewer
  Widget _buildQuillDescription(String description) {
    try {
      // Try to parse as Quill delta JSON
      final document = Document.fromJson(jsonDecode(description));
      final controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );

      return QuillEditor.basic(
        controller: controller,
        focusNode: FocusNode(),
      );
    } catch (e) {
      // Fallback to plain text if not valid Quill JSON
      return Text(
        description,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }
  }
}
