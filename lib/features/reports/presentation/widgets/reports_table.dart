import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/auction/presentation/auction_detail_screen.dart';
import 'package:osp_broker_admin/features/forums/application/forum_admin_notifier.dart';
import 'package:osp_broker_admin/features/forums/domain/forum_models.dart';
import 'package:osp_broker_admin/features/forums/presentation/pages/topic_detail_page.dart';
import 'package:osp_broker_admin/features/reports/application/reports_notifier.dart';
import 'package:osp_broker_admin/features/reports/domain/flagged_content_report.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';

Future<void> openReportTarget(
  BuildContext context,
  WidgetRef ref,
  FlaggedContentReport report,
) async {
  final kind = report.targetKind;
  final id = report.targetId;

  if (id.isEmpty) return;

  if (kind == 'TOPIC') {
    try {
      final base = ref.read(forumAdminNotifierProvider);
      final forums = base.forums;

      final topic = await ref
          .read(forumAdminNotifierProvider.notifier)
          .fetchTopicById(id);

      if (!context.mounted) return;

      if (topic != null) {
        final forumName = forums
            .firstWhere(
              (f) => f.id == topic.forumId,
              orElse: () => Forum(
                id: topic.forumId,
                title: 'Unknown Forum',
                description: '',
                categoryId: '',
                userId: '',
                author: '',
                comments: 0,
                isDeleted: false,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                topics: const [],
                count: const {},
              ),
            )
            .title;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TopicDetailPage(topic: topic, forumName: forumName),
          ),
        );
        return;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open topic: $e')));
      }
    }
    return;
  }

  if (kind == 'COMMENT') {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment management view is not available yet'),
      ),
    );
    return;
  }

  if (kind == 'USER') {
    await ref.read(userNotifierProvider.notifier).fetchUserProfile(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User profile fetched (open Users page to manage)'),
        ),
      );
    }
    return;
  }

  if (kind == 'AUCTION') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuctionDetailScreen(auctionId: id)),
    );
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open target not supported for $kind yet')),
    );
  }
}

class ReportsTable extends ConsumerWidget {
  final Set<String>? allowedTargetKinds;

  const ReportsTable({super.key, this.allowedTargetKinds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsNotifierProvider);
    final reports = allowedTargetKinds == null
        ? state.reports
        : state.reports
              .where((r) => allowedTargetKinds!.contains(r.targetKind))
              .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEDF1FA), Color(0xFFD6E4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Reason',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Target',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Created',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Text(
                    'Actions',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 1, color: Color(0xFFE9EDF5)),
          if (state.isLoading && reports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.error != null && reports.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('Error: ${state.error}')),
            )
          else if (reports.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('No reports found')),
            )
          else
            ...reports.asMap().entries.map((entry) {
              final idx = entry.key;
              final report = entry.value;
              return _ReportRow(
                report: report,
                rowColor: idx % 2 == 0 ? const Color(0xFFF7F9FC) : Colors.white,
              );
            }),
        ],
      ),
    );
  }
}

class _ReportRow extends ConsumerWidget {
  final FlaggedContentReport report;
  final Color? rowColor;
  const _ReportRow({required this.report, this.rowColor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final targetLabel = report.targetKind;
    final targetId = report.targetId;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        color: rowColor,
        child: InkWell(
          hoverColor: Colors.blue.withOpacity(0.06),
          onTap: () async {
            final notifier = ref.read(reportsNotifierProvider.notifier);
            final loaded = await notifier.loadReportById(report.id);
            if (context.mounted && loaded != null) {
              await showDialog<void>(
                context: context,
                builder: (ctx) => _ReportDetailDialog(reportId: report.id),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    report.contentType.isNotEmpty
                        ? report.contentType
                        : report.targetKind,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    report.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$targetLabel${targetId.isNotEmpty ? ' • $targetId' : ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (targetId.isNotEmpty)
                        Tooltip(
                          message: 'Copy target id',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              await Clipboard.setData(
                                ClipboardData(text: targetId),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied'),
                                    duration: Duration(milliseconds: 900),
                                  ),
                                );
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(4.0),
                              child: Icon(Icons.copy, size: 16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    report.createdAt.toIso8601String().substring(0, 10),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Tooltip(
                        message: 'View',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            final notifier = ref.read(
                              reportsNotifierProvider.notifier,
                            );
                            final loaded = await notifier.loadReportById(
                              report.id,
                            );
                            if (context.mounted && loaded != null) {
                              await showDialog<void>(
                                context: context,
                                builder: (ctx) =>
                                    _ReportDetailDialog(reportId: report.id),
                              );
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.visibility, size: 20),
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Open target',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: targetId.isEmpty
                              ? null
                              : () async {
                                  await openReportTarget(context, ref, report);
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.open_in_new,
                              size: 20,
                              color: targetId.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
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
}

class _ReportDetailDialog extends ConsumerWidget {
  final String reportId;
  const _ReportDetailDialog({required this.reportId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsNotifierProvider);
    final report = state.selectedReport;

    final idLabel = report?.id ?? reportId;

    return AlertDialog(
      title: const Text('Report Details'),
      content: SizedBox(
        width: 560,
        child: state.isLoading && report == null
            ? const Center(child: CircularProgressIndicator())
            : report == null
            ? const Text('No report data')
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv(context, 'Report ID', idLabel, copy: true),
                  _kv(context, 'Type', report.contentType),
                  _kv(context, 'Reason', report.reason),
                  _kv(context, 'Flagged By', report.flaggedBy, copy: true),
                  _kv(context, 'Target Kind', report.targetKind),
                  _kv(context, 'Target ID', report.targetId, copy: true),
                  _kv(context, 'Category ID', report.categoryId ?? ''),
                  _kv(
                    context,
                    'Created',
                    report.createdAt.toIso8601String().replaceFirst('T', ' '),
                  ),
                  _kv(
                    context,
                    'Updated',
                    report.updatedAt.toIso8601String().replaceFirst('T', ' '),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Error: ${state.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (report != null && report.targetId.isNotEmpty)
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await openReportTarget(context, ref, report);
            },
            child: const Text('Open target'),
          ),
      ],
    );
  }

  Widget _kv(BuildContext context, String k, String v, {bool copy = false}) {
    if (v.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: SelectableText(v)),
          if (copy)
            Tooltip(
              message: 'Copy',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: v));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied'),
                        duration: Duration(milliseconds: 900),
                      ),
                    );
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.copy, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
