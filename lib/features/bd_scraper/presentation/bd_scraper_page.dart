// Main page for the Business Directory Scraper feature.
//   - Tab 1: scrape jobs (recent runs + start new)
//   - Tab 2: pending review (edit, approve, reject)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/features/bd_scraper/application/scraper_notifier.dart';
import 'package:osp_broker_admin/features/bd_scraper/domain/scraper_models.dart';
import 'package:osp_broker_admin/features/bd_scraper/presentation/widgets/start_scrape_dialog.dart';
import 'package:osp_broker_admin/features/bd_scraper/presentation/widgets/edit_pending_dialog.dart';
import 'package:osp_broker_admin/features/business_directories/application/business_directories_notifier.dart';

final GoRoute goRouteBdScraper = GoRoute(
  path: BdScraperPage.routePath,
  name: BdScraperPage.routeName,
  pageBuilder: (context, state) => NoTransitionPage(
    key: state.pageKey,
    child: const BdScraperPage(),
  ),
);

class BdScraperPage extends ConsumerStatefulWidget {
  const BdScraperPage({super.key});
  static const String routeName = 'bd-scraper';
  static const String routePath = '/bd-scraper';

  @override
  ConsumerState<BdScraperPage> createState() => _BdScraperPageState();
}

class _BdScraperPageState extends ConsumerState<BdScraperPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scraperJobsProvider.notifier).load();
      ref.read(scraperPendingProvider.notifier).load();
      // Categories are needed by the approve dialog
      ref.read(businessDirectoriesNotifierProvider.notifier).loadBusinessCategories();
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Business Directory Scraper',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => const StartScrapeDialog(),
                        );
                        if (ok == true) {
                          _tab.animateTo(0);
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Scrape job queued — progress will update live')),
                          );
                        }
                      },
                      icon: const Icon(Icons.travel_explore),
                      label: const Text('Start new scrape'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Discover US businesses from public directories, review and approve before they hit the listings.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tab,
                  tabs: const [
                    Tab(text: 'Scrape jobs'),
                    Tab(text: 'Pending review'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _JobsTab(),
                _PendingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Jobs tab ----------

class _JobsTab extends ConsumerWidget {
  const _JobsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scraperJobsProvider);
    if (state.loading && state.jobs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.jobs.isEmpty) {
      return _ErrorView(
        error: state.error!,
        onRetry: () => ref.read(scraperJobsProvider.notifier).load(),
      );
    }
    if (state.jobs.isEmpty) {
      return const Center(child: Text('No scrape jobs yet. Click "Start new scrape" to begin.'));
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(scraperJobsProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: state.jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _JobCard(job: state.jobs[i]),
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final ScrapeJob job;
  const _JobCard({required this.job});

  Color _statusColor() {
    switch (job.status) {
      case ScrapeJobStatus.completed: return Colors.green;
      case ScrapeJobStatus.failed: return Colors.red;
      case ScrapeJobStatus.cancelled: return Colors.grey;
      case ScrapeJobStatus.running: return Colors.blue;
      case ScrapeJobStatus.queued: return Colors.orange;
    }
  }

  String _statusLabel() => job.status.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final loc = [job.locationCity, job.locationState].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    final progress = job.targetCount > 0 ? (job.savedCount / job.targetCount).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${job.category}${loc.isNotEmpty ? "  ·  $loc" : ""}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Chip(
                  label: Text(_statusLabel()),
                  backgroundColor: _statusColor().withOpacity(0.12),
                  labelStyle: TextStyle(color: _statusColor()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _stat('Target', '${job.targetCount}'),
                _stat('Discovered', '${job.discoveredCount}'),
                _stat('Extracted', '${job.extractedCount}'),
                _stat('Saved', '${job.savedCount}'),
                _stat('Duplicates', '${job.duplicateCount}'),
                _stat('Brave calls', '${job.braveQuotaUsed}'),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: job.status == ScrapeJobStatus.completed ? 1.0 : progress,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
            if (job.error != null) ...[
              const SizedBox(height: 8),
              Text(job.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
            const SizedBox(height: 8),
            Text(
              'Started ${_relativeTime(job.startedAt ?? job.createdAt)}'
              '${job.completedAt != null ? "  ·  Done ${_relativeTime(job.completedAt!)}" : ""}',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return '${d.inSeconds}s ago';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}

// ---------- Pending tab ----------

class _PendingTab extends ConsumerStatefulWidget {
  const _PendingTab();
  @override
  ConsumerState<_PendingTab> createState() => _PendingTabState();
}

class _PendingTabState extends ConsumerState<_PendingTab> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scraperPendingProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search, size: 18),
                    hintText: 'Search name / email / city',
                  ),
                  onSubmitted: (v) => ref.read(scraperPendingProvider.notifier).applyFilter(
                        state.filter.copyWith(search: v, page: 1),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<ScrapedBusinessStatus>(
                value: state.filter.status,
                items: ScrapedBusinessStatus.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(scraperPendingProvider.notifier).applyFilter(
                          state.filter.copyWith(status: v, page: 1),
                        );
                  }
                },
              ),
              const Spacer(),
              if (_selected.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => _bulkApprove(),
                  icon: const Icon(Icons.done_all, size: 18),
                  label: Text('Approve ${_selected.length} selected'),
                ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(scraperPendingProvider.notifier).load(),
              ),
            ],
          ),
        ),
        if (state.loading && state.items.isEmpty)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (state.error != null && state.items.isEmpty)
          Expanded(
            child: _ErrorView(error: state.error!, onRetry: () => ref.read(scraperPendingProvider.notifier).load()),
          )
        else if (state.items.isEmpty)
          const Expanded(child: Center(child: Text('No records match the current filter')))
        else
          Expanded(child: _pendingTable(state)),
      ],
    );
  }

  Widget _pendingTable(ScraperPendingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 56,
          dataRowMaxHeight: 64,
          columns: const [
            DataColumn(label: Text('Sel')),
            DataColumn(label: Text('Business')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Phone')),
            DataColumn(label: Text('Location')),
            DataColumn(label: Text('Source')),
            DataColumn(label: Text('Conf')),
            DataColumn(label: Text('Flags')),
            DataColumn(label: Text('Actions')),
          ],
          rows: state.items.map((b) {
            final isSelected = _selected.contains(b.id);
            return DataRow(
              selected: isSelected,
              cells: [
                DataCell(Checkbox(
                  value: isSelected,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _selected.add(b.id);
                    } else {
                      _selected.remove(b.id);
                    }
                  }),
                )),
                DataCell(SizedBox(width: 200, child: Text(b.businessName, overflow: TextOverflow.ellipsis))),
                DataCell(SizedBox(
                  width: 180,
                  child: Row(
                    children: [
                      Flexible(child: Text(b.email ?? '—', overflow: TextOverflow.ellipsis)),
                      if (b.emailConfidence == ScrapedEmailConfidence.guessed)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Tooltip(message: 'Guessed from domain', child: Icon(Icons.help_outline, size: 14, color: Colors.orange)),
                        ),
                    ],
                  ),
                )),
                DataCell(Text(b.phone ?? '—')),
                DataCell(Text([b.city, b.state].whereType<String>().where((s) => s.isNotEmpty).join(', '))),
                DataCell(Text(b.sourceDirectory ?? '—')),
                DataCell(_confChip(b.confidence)),
                DataCell(SizedBox(
                  width: 120,
                  child: Text(b.flags.join(', '), overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.orange)),
                )),
                DataCell(Row(children: [
                  IconButton(
                    tooltip: 'Edit / approve',
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _openEdit(b),
                  ),
                  IconButton(
                    tooltip: 'Reject',
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    onPressed: () => _confirmReject(b),
                  ),
                ])),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _confChip(double score) {
    final pct = (score * 100).round();
    final color = pct >= 70 ? Colors.green : pct >= 45 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
      child: Text('$pct%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _openEdit(ScrapedBusiness b) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => EditPendingDialog(record: b),
    );
    if (result == 'approved') {
      setState(() => _selected.remove(b.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Approved — listing created')),
        );
      }
    }
  }

  Future<void> _confirmReject(ScrapedBusiness b) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reject "${b.businessName}"?'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(scraperPendingProvider.notifier).reject(b.id, reasonCtrl.text.trim());
      setState(() => _selected.remove(b.id));
    }
  }

  Future<void> _bulkApprove() async {
    final categoriesState = ref.read(businessDirectoriesNotifierProvider);
    final categories = categoriesState.categories.where((c) => !c.isDeleted).toList();
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No business categories available. Create one first.')),
      );
      return;
    }
    String? chosen;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateInner) {
        return AlertDialog(
          title: Text('Approve ${_selected.length} records'),
          content: DropdownButtonFormField<String>(
            value: chosen,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Business category'),
            items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
            onChanged: (v) => setStateInner(() => chosen = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: chosen == null ? null : () => Navigator.pop(ctx, true),
              child: const Text('Approve all'),
            ),
          ],
        );
      }),
    );
    if (ok == true && chosen != null) {
      final results = await ref.read(scraperPendingProvider.notifier).bulkApprove(_selected.toList(), chosen!);
      setState(_selected.clear);
      final okCount = results.where((r) => (r as Map)['ok'] == true).length;
      final failCount = results.length - okCount;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approved $okCount${failCount > 0 ? ", $failCount failed" : ""}')),
        );
      }
    }
  }
}

// ---------- Shared ----------

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(error, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
