import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/utils/csv_export.dart';
import 'package:osp_broker_admin/core/utils/role_utils.dart';
import 'package:osp_broker_admin/features/auth/application/auth_notifier.dart';
import 'package:osp_broker_admin/features/reports/application/reports_notifier.dart';
import 'package:osp_broker_admin/features/reports/presentation/widgets/reports_table.dart';

import '../application/auction_notifier.dart';
import 'auction_detail_screen.dart';

class AuctionScreen extends ConsumerStatefulWidget {
  const AuctionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends ConsumerState<AuctionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auctionNotifierProvider.notifier).loadCategories();
      ref.read(auctionNotifierProvider.notifier).loadAuctions();

      final authState = ref.read(authNotifierProvider);
      final shouldLoadReports = authState.maybeWhen(
        authenticated: (_, user) =>
            userHasRole(Map<String, dynamic>.from(user), 'MODERATOR'),
        orElse: () => false,
      );
      if (shouldLoadReports) {
        ref.read(reportsNotifierProvider.notifier).loadReports();
      }
    });
  }

  Future<void> _loadData() async {
    await ref.read(auctionNotifierProvider.notifier).loadCategories();
    await ref.read(auctionNotifierProvider.notifier).loadAuctions();

    final authState = ref.read(authNotifierProvider);
    final shouldLoadReports = authState.maybeWhen(
      authenticated: (_, user) =>
          userHasRole(Map<String, dynamic>.from(user), 'MODERATOR'),
      orElse: () => false,
    );
    if (shouldLoadReports) {
      await ref.read(reportsNotifierProvider.notifier).loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auctionNotifierProvider);
    final auctions = state.auctions;
    final live = auctions
        .where((a) => a.approved && !a.isDeleted && !_isAuctionCompleted(a))
        .length;
    final pending = auctions.where((a) => !a.approved && !a.isDeleted).length;
    final completed =
        auctions.where((a) => !a.isDeleted && _isAuctionCompleted(a)).length;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildStatCards(
                  total: auctions.length,
                  live: live,
                  pending: pending,
                  completed: completed,
                ),
                const SizedBox(height: 20),
                _buildTabBar(),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildAuctionsTab(),
                      _buildCategoriesTab(),
                      _buildReportsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.gavel_rounded, color: AppColors.sidebarSelected),
                  SizedBox(width: 10),
                  Text(
                    'Auction Management',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Review, approve and moderate auctions, bids and categories',
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loadData,
          icon: const Icon(Icons.refresh_rounded),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.black.withOpacity(0.08)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Export CSV',
          onSelected: (value) async {
            final state = ref.read(auctionNotifierProvider);
            if (value == 'categories') {
              final rows = state.categories
                  .map((c) =>
                      (c.toJson()).map((k, v) => MapEntry(k, v as Object?)))
                  .toList();
              await exportCsv(fileName: 'auction_categories.csv', rows: rows);
              return;
            }
            if (value == 'auctions') {
              final rows = state.auctions
                  .map((a) =>
                      (a.toJson()).map((k, v) => MapEntry(k, v as Object?)))
                  .toList();
              await exportCsv(fileName: 'auctions.csv', rows: rows);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
                value: 'auctions', child: Text('Export Auctions (CSV)')),
            PopupMenuItem(
                value: 'categories', child: Text('Export Categories (CSV)')),
          ],
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black.withOpacity(0.08)),
            ),
            child: Row(
              children: const [
                Icon(Icons.download_rounded, size: 18),
                SizedBox(width: 8),
                Text('Export', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _showCreateAuctionDialog,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Create Auction'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.sidebarSelected,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards({
    required int total,
    required int live,
    required int pending,
    required int completed,
  }) {
    final cards = [
      _StatCard(
          label: 'Total Auctions',
          value: '$total',
          icon: Icons.inventory_2_outlined,
          color: AppColors.info),
      _StatCard(
          label: 'Live',
          value: '$live',
          icon: Icons.bolt_rounded,
          color: AppColors.success),
      _StatCard(
          label: 'Pending Approval',
          value: '$pending',
          icon: Icons.hourglass_bottom_rounded,
          color: AppColors.warning),
      _StatCard(
          label: 'Completed',
          value: '$completed',
          icon: Icons.verified_rounded,
          color: AppColors.sidebarSelected),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoPerRow = constraints.maxWidth < 720;
        final width = twoPerRow
            ? (constraints.maxWidth - 16) / 2
            : (constraints.maxWidth - 48) / 4;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final c in cards) SizedBox(width: width, child: c),
          ],
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.sidebarSelected.withOpacity(0.16),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppColors.sidebarSelected.withOpacity(0.5)),
        ),
        tabs: const [
          Tab(text: 'Auctions'),
          Tab(text: 'Categories'),
          Tab(text: 'Reports'),
        ],
      ),
    );
  }

  String _statusLabel(auction) {
    if (auction.isDeleted) return 'Deleted';
    if (_isAuctionCompleted(auction)) return 'Completed';
    if (!auction.approved) return 'Pending';
    return 'Live';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Live':
        return AppColors.success;
      case 'Pending':
        return AppColors.warning;
      case 'Completed':
        return AppColors.info;
      case 'Deleted':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildReportsTab() {
    final authState = ref.watch(authNotifierProvider);
    final canViewReports = authState.maybeWhen(
      authenticated: (_, user) =>
          userHasRole(Map<String, dynamic>.from(user), 'MODERATOR'),
      orElse: () => false,
    );

    if (!canViewReports) {
      return const Center(
        child: Text('Reports are available to MODERATOR accounts only.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ReportsTable(allowedTargetKinds: {'AUCTION', 'AUCTION_BID'}),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final state = ref.watch(auctionNotifierProvider);

    if (state.isLoadingCategories && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.categories.isEmpty) {
      return Center(child: Text('Error: ${state.error}'));
    }

    final categories = state.categories;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        children: [
          Row(
            children: [
              Text(
                '${categories.length} categor${categories.length == 1 ? 'y' : 'ies'}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showCreateCategoryDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Category'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.sidebarSelected,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: _EmptyState(
                icon: Icons.category_outlined,
                title: 'No categories yet',
                subtitle: 'Create a category to organise auctions.',
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final perRow = constraints.maxWidth < 700 ? 1 : 3;
                final width =
                    (constraints.maxWidth - (16 * (perRow - 1))) / perRow;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    for (final category in categories)
                      SizedBox(
                        width: width,
                        child: _buildCategoryCard(category),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(category) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.sidebarSelected.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_open_rounded,
                    color: AppColors.sidebarSelected, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            category.description.isEmpty
                ? 'No description'
                : category.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                _formatDate(category.createdAt as DateTime),
                style:
                    TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: AppColors.info,
                visualDensity: VisualDensity.compact,
                tooltip: 'Edit',
                onPressed: () => _showEditCategoryDialog(category),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                color: AppColors.error,
                visualDensity: VisualDensity.compact,
                tooltip: 'Delete',
                onPressed: () => _showDeleteCategoryDialog(category),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionsTab() {
    final state = ref.watch(auctionNotifierProvider);

    if (state.isLoadingAuctions && state.auctions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.auctions.isEmpty) {
      return _ErrorState(message: state.error!, onRetry: _loadData);
    }

    final q = _searchQuery.trim().toLowerCase();
    final filtered = state.auctions.where((a) {
      final matchesStatus =
          _statusFilter == 'All' || _statusLabel(a) == _statusFilter;
      if (!matchesStatus) return false;
      if (q.isEmpty) return true;
      final desc = _getPlainTextFromDescription(a.description).toLowerCase();
      return a.title.toLowerCase().contains(q) || desc.contains(q);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Column(
        children: [
          _buildAuctionToolbar(),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState(
                    icon: Icons.gavel_rounded,
                    title: 'No auctions found',
                    subtitle: 'Try a different search or filter.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildAuctionCard(filtered[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuctionToolbar() {
    const statuses = ['All', 'Live', 'Pending', 'Completed', 'Deleted'];
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search auctions by title or description…',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.sidebarSelected, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              borderRadius: BorderRadius.circular(10),
              items: [
                for (final s in statuses)
                  DropdownMenuItem(
                    value: s,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (s != 'All') ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _statusColor(s),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(s),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuctionCard(auction) {
    final status = _statusLabel(auction);
    final color = _statusColor(status);
    final desc = _getPlainTextFromDescription(auction.description);
    final endsAt = auction.timeFrame as DateTime;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  AuctionDetailScreen(auctionId: auction.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.gavel_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            auction.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusBadge(label: status, color: color),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      desc.isEmpty ? 'No description' : desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _meta(Icons.sell_outlined,
                            'Start \$${auction.startingBid.toStringAsFixed(0)}'),
                        _meta(Icons.category_outlined,
                            '${auction.categoryIds.length} categor${auction.categoryIds.length == 1 ? 'y' : 'ies'}'),
                        _meta(Icons.event_outlined, _formatDate(endsAt)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  if (!auction.approved && !auction.isDeleted)
                    _actionButton(
                      icon: Icons.check_rounded,
                      color: AppColors.success,
                      tooltip: 'Approve',
                      onPressed: () => _approveAuction(auction),
                    ),
                  _actionButton(
                    icon: Icons.delete_outline_rounded,
                    color: AppColors.error,
                    tooltip: 'Delete',
                    onPressed: () => _showDeleteAuctionDialog(auction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(backgroundColor: color.withOpacity(0.08)),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                try {
                  await ref
                      .read(auctionNotifierProvider.notifier)
                      .createCategory(
                        name: nameController.text,
                        description: descriptionController.text,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category created successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating category: ${e.toString()}'),
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(
      text: category.description,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                try {
                  await ref
                      .read(auctionNotifierProvider.notifier)
                      .updateCategory(
                        id: category.id,
                        name: nameController.text,
                        description: descriptionController.text,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category updated successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error creating category: ${e.toString()}'),
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(auctionNotifierProvider.notifier)
                    .deleteCategory(category.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category deleted successfully'),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting category: ${e.toString()}'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateAuctionDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final startingBidController = TextEditingController();
    final selectedCategories = <String>{};
    final selectedImages = <dynamic>[];

    // Time frame state - default to tomorrow
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Auction'),
          content: Container(
            width: double.minPositive,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              minWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: startingBidController,
                    decoration: const InputDecoration(
                      labelText: 'Starting Bid',
                      hintText: 'Enter starting bid amount',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select Categories:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(auctionNotifierProvider);
                      return state.isLoadingCategories
                          ? const SizedBox(
                              height: 50,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : SizedBox(
                              height: 100,
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: state.categories.map((category) {
                                    final isSelected = selectedCategories
                                        .contains(category.id);
                                    return FilterChip(
                                      label: Text(category.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedCategories.add(category.id);
                                          } else {
                                            selectedCategories.remove(
                                              category.id,
                                            );
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Auction End Date & Time:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Select Date & Time\n${selectedDateTime.toString().split('.')[0]}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Media Files:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: true,
                      );
                      if (result != null) {
                        setState(() {
                          selectedImages.addAll(
                            result.files.map((file) => file),
                          );
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Select Images'),
                  ),
                  if (selectedImages.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Selected ${selectedImages.length} image(s)'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedImages.length,
                            itemBuilder: (context, index) {
                              final file = selectedImages[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    // Handle both File (mobile) and PlatformFile (web)
                                    if (file is File)
                                      Image.file(
                                        file,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    else if (file is PlatformFile &&
                                        file.bytes != null)
                                      // For web, show a placeholder or filename
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.image,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          border: Border.all(
                                            color: Colors.grey,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            (file.name ?? 'File').substring(
                                              0,
                                              min<int>(
                                                10,
                                                (file.name ?? 'File').length,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            selectedImages.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  selectedCategories.isEmpty || titleController.text.isEmpty
                  ? null
                  : () async {
                      if (titleController.text.isNotEmpty &&
                          descriptionController.text.isNotEmpty &&
                          selectedCategories.isNotEmpty &&
                          startingBidController.text.isNotEmpty) {
                        try {
                          await ref
                              .read(auctionNotifierProvider.notifier)
                              .createAuction(
                                title: titleController.text,
                                description: descriptionController.text,
                                categoryIds: selectedCategories.toList(),
                                timeFrame:
                                    selectedDateTime
                                        .toUtc()
                                        .toIso8601String()
                                        .split('.')[0] +
                                    'Z', // ISO format without milliseconds for Prisma
                                files:
                                    selectedImages, // Pass PlatformFile objects directly
                                startingBid: int.parse(
                                  startingBidController.text,
                                ),
                              );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Auction created successfully'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error creating auction: ${e.toString()}',
                              ),
                            ),
                          );
                        }
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _uploadImagesToS3(List<dynamic> images) async {
    // TODO: Implement AWS S3 upload
    // For now, return empty list or placeholder URLs
    // This should be implemented based on your AWS S3 configuration
    return [];
  }

  void _approveAuction(auction) async {
    try {
      await ref
          .read(auctionNotifierProvider.notifier)
          .approveAuction(auction.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auction approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving auction: ${e.toString()}')),
      );
    }
  }

  void _showDeleteAuctionDialog(auction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Auction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose deletion type for "${auction.title}":'),
            const SizedBox(height: 16),
            const Text(
              'Soft Delete: Hides the auction but keeps it in database',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hard Delete: Permanently removes the auction',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(auctionNotifierProvider.notifier)
                    .softDeleteAuction(auction.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Auction soft deleted successfully'),
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error soft deleting auction: ${e.toString()}',
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Soft Delete'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(auctionNotifierProvider.notifier)
                    .hardDeleteAuction(auction.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auction permanently deleted')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting auction: ${e.toString()}'),
                  ),
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

  /// Check if auction is completed (timeFrame has passed or winner selected)
  bool _isAuctionCompleted(auction) {
    // Check if timeFrame has passed
    if (auction.timeFrame.isBefore(DateTime.now())) {
      return true;
    }

    // Check if a winner has been selected by loading bids for this auction
    // Note: This is a simplified check. For better performance, consider adding
    // a 'hasWinner' field to the Auction model from the backend
    final state = ref.read(auctionNotifierProvider);

    // If we have the selected auction and its bids loaded, check for matched bids
    if (state.selectedAuction?.id == auction.id) {
      return state.bids.any((bid) => bid.matched);
    }

    // Default to time-based completion only
    return false;
  }

  /// Extract plain text from Quill JSON description
  String _getPlainTextFromDescription(String description) {
    try {
      final deltaJson = jsonDecode(description);
      if (deltaJson is List) {
        // Extract text from ops array
        final buffer = StringBuffer();
        for (final op in deltaJson) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        return buffer.toString().trim();
      }
      return description;
    } catch (e) {
      // Fallback to original description if parsing fails
      return description;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.error.withOpacity(0.6)),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sidebarSelected,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
