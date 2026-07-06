import 'dart:convert';
// Conditional import for web
import 'dart:html' as html show Blob, Url, AnchorElement;
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:osp_broker_admin/features/rfp/application/rfp_notifier.dart';
import 'package:osp_broker_admin/features/rfp/domain/rfp_model.dart';
import 'package:path_provider/path_provider.dart';

class RfpsPage extends ConsumerStatefulWidget {
  const RfpsPage({super.key});

  static const String routeName = 'rfps';
  static const String routePath = '/rfps';

  @override
  ConsumerState<RfpsPage> createState() => _RfpsPageState();
}

class _RfpsPageState extends ConsumerState<RfpsPage> {
  String _searchQuery = '';
  String _sortBy = 'createdAt';
  bool _sortAscending = false;
  String _filterStatus = 'all'; // all, active, deleted
  bool _isTableView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rfpNotifierProvider.notifier).loadRfps();
    });
  }

  List<RfpModel> get _filteredRfps {
    final state = ref.read(rfpNotifierProvider);
    List<RfpModel> rfps = List.from(state.rfps);

    // Filter by status
    if (_filterStatus == 'active') {
      rfps = rfps.where((r) => !r.isDeleted).toList();
    } else if (_filterStatus == 'deleted') {
      rfps = rfps.where((r) => r.isDeleted).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      rfps = rfps.where((r) {
        final query = _searchQuery.toLowerCase();
        return r.projectTitle.toLowerCase().contains(query) ||
            r.name.toLowerCase().contains(query) ||
            r.email.toLowerCase().contains(query) ||
            (r.description.toLowerCase().contains(query)) ||
            (r.message.toLowerCase().contains(query));
      }).toList();
    }

    // Sort
    rfps.sort((a, b) {
      int cmp;
      switch (_sortBy) {
        case 'projectTitle':
          cmp = a.projectTitle
              .toLowerCase()
              .compareTo(b.projectTitle.toLowerCase());
          break;
        case 'name':
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'email':
          cmp = a.email.toLowerCase().compareTo(b.email.toLowerCase());
          break;
        case 'deadline':
          cmp = a.deadline.compareTo(b.deadline);
          break;
        case 'createdAt':
          cmp = (a.createdAt ?? DateTime.now())
              .compareTo(b.createdAt ?? DateTime.now());
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return rfps;
  }

  List<RfpModel> get _paginatedRfps {
    final filtered = _filteredRfps;
    final currentPage = ref.watch(_currentPageProvider);
    final rowsPerPage = ref.watch(_rowsPerPageProvider);
    final startIndex = (currentPage - 1) * rowsPerPage;

    return filtered.skip(startIndex).take(rowsPerPage).toList();
  }

  Future<void> _exportToCsv() async {
    final filteredRfps = _filteredRfps;

    // Create CSV data
    final headers = [
      'ID',
      'Project Title',
      'Name',
      'Email',
      'Phone Number',
      'Price',
      'Deadline',
      'Description',
      'Message',
      'Additional Files',
      'Status',
      'Created At',
      'Updated At'
    ];

    final rows = filteredRfps
        .map((rfp) => [
              rfp.id,
              rfp.projectTitle,
              rfp.name,
              rfp.email,
              rfp.phoneNumber?.toString() ?? '',
              rfp.price?.toString() ?? '',
              rfp.deadline,
              rfp.description,
              rfp.message,
              rfp.additionalFiles,
              rfp.isDeleted ? 'Deleted' : 'Active',
              rfp.createdAt?.toIso8601String() ?? '',
              rfp.updatedAt?.toIso8601String() ?? '',
            ])
        .toList();

    // Build CSV string
    final csvData = StringBuffer();
    csvData.writeln(headers.map((header) => _escapeCsvValue(header)).join(','));

    for (final row in rows) {
      csvData.writeln(row.map((cell) => _escapeCsvValue(cell)).join(','));
    }

    final csvString = csvData.toString();
    final filename = 'rfps_${DateTime.now().millisecondsSinceEpoch}.csv';

    if (kIsWeb) {
      // Web download using HTML download
      final bytes = utf8.encode(csvString);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename);
      anchor.click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Desktop/Mobile download
      try {
        final directory = await getDownloadsDirectory();
        final file = File('${directory?.path ?? '.'}/$filename');
        await file.writeAsString(csvString);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CSV exported to ${file.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to export CSV: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<Directory?> getDownloadsDirectory() async {
    if (Platform.isMacOS || Platform.isLinux) {
      return Directory('${Platform.environment['HOME']}/Downloads');
    } else if (Platform.isWindows) {
      return Directory('${Platform.environment['USERPROFILE']}\\Downloads');
    } else {
      // For mobile platforms, return app documents directory
      return await getApplicationDocumentsDirectory();
    }
  }

  String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rfpNotifierProvider);
    final filteredRfps = _filteredRfps;
    final totalRfps = state.rfps.length;
    final activeRfps = state.rfps.where((r) => !r.isDeleted).length;
    final deletedRfps = state.rfps.where((r) => r.isDeleted).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with stats and actions
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'RFPs',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: () =>
                        ref.read(rfpNotifierProvider.notifier).loadRfps(),
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  // Export CSV button
                  IconButton(
                    tooltip: 'Export CSV',
                    onPressed: _exportToCsv,
                    icon: const Icon(Icons.download),
                  ),
                  const SizedBox(width: 8),
                  // View toggle
                  ToggleButtons(
                    isSelected: [_isTableView, !_isTableView],
                    onPressed: (index) {
                      setState(() {
                        _isTableView = index == 0;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    selectedColor: Colors.white,
                    fillColor: const Color(0xFF24439B),
                    color: Colors.grey[600],
                    constraints: const BoxConstraints(
                      minHeight: 36,
                      minWidth: 36,
                    ),
                    children: const [
                      Icon(Icons.table_chart, size: 20),
                      Icon(Icons.view_list, size: 20),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats cards
              Row(
                children: [
                  _StatCard(
                    title: 'Total',
                    value: totalRfps.toString(),
                    color: const Color(0xFF24439B),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: 'Active',
                    value: activeRfps.toString(),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: 'Deleted',
                    value: deletedRfps.toString(),
                    color: Colors.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Search, filter, and sort controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RFPs Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Search field
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller:
                                TextEditingController(text: _searchQuery),
                            decoration: InputDecoration(
                              labelText: 'Search RFPs...',
                              hintText: 'Search by title, name, or email...',
                              prefixIcon: const Icon(Icons.search,
                                  color: Color(0xFF6B7280)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF24439B), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Filter dropdown
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _filterStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              prefixIcon: const Icon(Icons.filter_list,
                                  color: Color(0xFF6B7280)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF24439B), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'all', child: Text('All Status')),
                              DropdownMenuItem(
                                  value: 'active', child: Text('Active')),
                              DropdownMenuItem(
                                  value: 'deleted', child: Text('Deleted')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _filterStatus = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Sort dropdown
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _sortBy,
                            decoration: InputDecoration(
                              labelText: 'Sort By',
                              prefixIcon: const Icon(Icons.sort,
                                  color: Color(0xFF6B7280)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: Color(0xFF24439B), width: 2),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'createdAt',
                                  child: Text('Created Date')),
                              DropdownMenuItem(
                                  value: 'projectTitle', child: Text('Title')),
                              DropdownMenuItem(
                                  value: 'name', child: Text('Name')),
                              DropdownMenuItem(
                                  value: 'email', child: Text('Email')),
                              DropdownMenuItem(
                                  value: 'price', child: Text('Price')),
                              DropdownMenuItem(
                                  value: 'deadline', child: Text('Deadline')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _sortBy = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Sort direction button
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _sortAscending = !_sortAscending;
                              });
                            },
                            icon: Icon(
                              _sortAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: const Color(0xFF24439B),
                            ),
                            tooltip:
                                _sortAscending ? 'Ascending' : 'Descending',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Content
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(state.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(rfpNotifierProvider.notifier).loadRfps(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (filteredRfps.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty || _filterStatus != 'all'
                            ? Icons.search_off
                            : Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _filterStatus != 'all'
                            ? 'No RFPs found matching your criteria'
                            : 'No RFPs found',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return _isTableView
                  ? _RfpTable(
                      rfps: _paginatedRfps, totalItems: filteredRfps.length)
                  : _RfpListView(rfps: _paginatedRfps);
            },
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RfpTable extends StatelessWidget {
  final List<RfpModel> rfps;
  final int totalItems;

  const _RfpTable({required this.rfps, required this.totalItems});

  @override
  Widget build(BuildContext context) {
    const dividerColor = Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table content
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;

                // Fractions add up to 1.0
                final titleW = availableWidth * 0.22;
                final nameW = availableWidth * 0.14;
                final emailW = availableWidth * 0.24;
                final priceW = availableWidth * 0.12;
                final createdW = availableWidth * 0.14;
                final statusW = availableWidth * 0.08;
                final actionsW = availableWidth * 0.06;

                const headerStyle = TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                );

                return DataTable(
                  columnSpacing: 0,
                  horizontalMargin: 0,
                  headingRowColor:
                      MaterialStateProperty.all(const Color(0xFFF8F9FA)),
                  dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.hovered)) {
                        return const Color(0xFFF5F5F5);
                      }
                      return null;
                    },
                  ),
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: dividerColor, width: 1),
                    verticalInside: BorderSide(color: dividerColor, width: 1),
                  ),
                  columns: [
                    DataColumn(
                      label: SizedBox(
                        width: titleW,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Title', style: headerStyle),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: nameW,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Name', style: headerStyle),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: emailW,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Email', style: headerStyle),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: priceW,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Price', style: headerStyle),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: createdW,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Created', style: headerStyle),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: statusW,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Status', style: headerStyle),
                        ),
                      ),
                    ),
                    DataColumn(
                      label: SizedBox(
                        width: actionsW,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Actions', style: headerStyle),
                        ),
                      ),
                    ),
                  ],
                  rows: rfps
                      .map(
                        (rfp) => _buildRfpDataRow(
                          context,
                          rfp,
                          titleW: titleW,
                          nameW: nameW,
                          emailW: emailW,
                          priceW: priceW,
                          createdW: createdW,
                          statusW: statusW,
                          actionsW: actionsW,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          // Table footer - always show if there are items
          if (totalItems > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: _TableFooter(totalItems: totalItems),
            ),
        ],
      ),
    );
  }

  DataRow _buildRfpDataRow(
    BuildContext context,
    RfpModel rfp, {
    required double titleW,
    required double nameW,
    required double emailW,
    required double priceW,
    required double createdW,
    required double statusW,
    required double actionsW,
  }) {
    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: titleW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                rfp.projectTitle.isNotEmpty ? rfp.projectTitle : 'Untitled',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: nameW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                rfp.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: emailW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rfp.email,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Copy email',
                    icon: const Icon(Icons.copy, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: rfp.email));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Email copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: priceW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                rfp.price != null ? '\$${rfp.price}' : 'N/A',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: createdW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                DateFormat('MMM dd, yyyy')
                    .format(rfp.createdAt ?? DateTime.now()),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: statusW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rfp.isDeleted
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: rfp.isDeleted
                        ? Colors.orange.withOpacity(0.3)
                        : Colors.green.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  rfp.isDeleted ? 'Deleted' : 'Active',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        rfp.isDeleted ? Colors.orange[700] : Colors.green[700],
                  ),
                ),
              ),
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: actionsW,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: IconButton(
                icon: const Icon(Icons.visibility, size: 18),
                onPressed: () => context.go('/rfps/${rfp.id}'),
                tooltip: 'View Details',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableFooter extends ConsumerWidget {
  final int totalItems;

  const _TableFooter({required this.totalItems});

  static const List<int> _rowsPerPageOptions = [5, 10, 25, 50, 100];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(_currentPageProvider);
    final rowsPerPage = ref.watch(_rowsPerPageProvider);
    final totalPages = (totalItems / rowsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Rows per page selector
          Row(
            children: [
              const Text('Show '),
              DropdownButton<int>(
                value: rowsPerPage,
                items: _rowsPerPageOptions.map((rows) {
                  return DropdownMenuItem(
                    value: rows,
                    child: Text('$rows'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    ref.read(_rowsPerPageProvider.notifier).state = value;
                    ref.read(_currentPageProvider.notifier).state = 1;
                  }
                },
              ),
              const Text(' entries'),
            ],
          ),

          // Page info
          Text(
            'Showing ${((currentPage - 1) * rowsPerPage) + 1} to '
            '${(currentPage * rowsPerPage).clamp(0, totalItems)} of $totalItems entries',
          ),

          // Pagination controls
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 1
                    ? () => ref.read(_currentPageProvider.notifier).state--
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous',
              ),
              const SizedBox(width: 8),
              ...List.generate(totalPages, (index) {
                final page = index + 1;
                final isCurrentPage = page == currentPage;

                if (totalPages <= 7 ||
                    page == 1 ||
                    page == totalPages ||
                    (page >= currentPage - 1 && page <= currentPage + 1)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: InkWell(
                      onTap: () =>
                          ref.read(_currentPageProvider.notifier).state = page,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isCurrentPage
                              ? const Color(0xFF24439B)
                              : Colors.transparent,
                          border: Border.all(
                            color: isCurrentPage
                                ? const Color(0xFF24439B)
                                : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            '$page',
                            style: TextStyle(
                              color:
                                  isCurrentPage ? Colors.white : Colors.black,
                              fontWeight: isCurrentPage
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                } else if (page == currentPage - 2 || page == currentPage + 2) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('...'),
                  );
                }
                return const SizedBox.shrink();
              }),
              const SizedBox(width: 8),
              IconButton(
                onPressed: currentPage < totalPages
                    ? () => ref.read(_currentPageProvider.notifier).state++
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Providers for pagination state
final _currentPageProvider = StateProvider<int>((ref) => 1);
final _rowsPerPageProvider = StateProvider<int>((ref) => 10);

class _RfpListView extends StatelessWidget {
  final List<RfpModel> rfps;

  const _RfpListView({required this.rfps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        itemCount: rfps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final rfp = rfps[index];
          return Card(
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                rfp.projectTitle.isNotEmpty ? rfp.projectTitle : 'Untitled RFP',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Name: ${rfp.name}'),
                  Text('Email: ${rfp.email}'),
                  if (rfp.price != null) Text('Price: \$${rfp.price}'),
                  if (rfp.deadline.isNotEmpty)
                    Text('Deadline: ${rfp.deadline}'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          rfp.isDeleted ? 'Deleted' : 'Active',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor:
                            rfp.isDeleted ? Colors.orange : Colors.green,
                        labelStyle: const TextStyle(color: Colors.white),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Created: ${DateFormat('MMM dd, yyyy').format(rfp.createdAt ?? DateTime.now())}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/rfps/${rfp.id}'),
            ),
          );
        },
      ),
    );
  }
}
