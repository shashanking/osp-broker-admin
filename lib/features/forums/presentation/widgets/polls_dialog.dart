import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/forum_admin_notifier.dart';
import '../../domain/forum_models.dart';
import 'add_poll_dialog.dart';

class PollsListDialog extends ConsumerStatefulWidget {
  const PollsListDialog({super.key});

  @override
  ConsumerState<PollsListDialog> createState() => _PollsListDialogState();
}

class _PollsListDialogState extends ConsumerState<PollsListDialog> {
  @override
  void initState() {
    super.initState();
    // Load polls when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumAdminNotifierProvider.notifier).fetchAllPolls();
    });
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM d, y h:mm a').format(dateTime);
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumAdminNotifierProvider);
    final polls = forumState.polls;
    final isLoading = forumState.isLoading;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Polls'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const AddPollDialog(),
              );

              // Always refresh the polls list when the dialog is closed
              if (mounted) {
                await ref
                    .read(forumAdminNotifierProvider.notifier)
                    .fetchAllPolls();
              }
            },
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: isLoading && polls.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : polls.isEmpty
                ? const Center(child: Text('No polls found'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: polls.length,
                    itemBuilder: (context, index) {
                      final poll = polls[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          onTap: () => _showPollAnalytics(context, poll, ref),
                          title: Text(
                            poll.question,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              ...poll.options
                                  .asMap()
                                  .entries
                                  .take(2)
                                  .map((entry) {
                                final optionNumber = entry.key + 1;
                                final option = entry.value;
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    children: [
                                      Text(
                                        '$optionNumber. ',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: const TextStyle(fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              if (poll.options.length > 2) ...[
                                Padding(
                                  padding: EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    '... and ${poll.options.length - 2} more options',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                              const Divider(height: 16, thickness: 1),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tap to view results',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Created: ${_formatDate(poll.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'analytics',
                                      child: Row(
                                        children: [
                                          Icon(Icons.analytics, size: 20),
                                          SizedBox(width: 8),
                                          Text('View Analytics'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, size: 20),
                                          SizedBox(width: 8),
                                          Text('Edit'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete,
                                              size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                              onSelected: (value) async {
                                if (value == 'analytics') {
                                  _showPollAnalytics(context, poll, ref);
                                } else if (value == 'edit') {
                                  // TODO: Implement edit poll
                                } else if (value == 'delete') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Confirm Delete'),
                                      content: const Text(
                                          'Are you sure you want to delete this poll?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: const Text('CANCEL'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('DELETE'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await ref
                                          .read(forumAdminNotifierProvider
                                              .notifier)
                                          .deletePoll(poll.id);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text('Poll deleted'),
                                          ),
                                        );
                                        await ref
                                            .read(forumAdminNotifierProvider
                                                .notifier)
                                            .fetchAllPolls();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Failed to delete poll: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                }
                              }),
                        ),
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CLOSE'),
        ),
      ],
    );
  }

// Show poll analytics in a dialog
  Future<void> _showPollAnalytics(
      BuildContext context, Poll poll, WidgetRef ref) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final analytics = await ref
          .read(forumAdminNotifierProvider.notifier)
          .getPollAnalytics(poll.id);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Remove loading indicator

      final totalVotes = analytics.votes.fold<int>(0, (a, b) => a + b);
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
      ];

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(poll.question),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...poll.options.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final option = entry.value;
                  final votes =
                      idx < analytics.votes.length ? analytics.votes[idx] : 0;
                  final percent =
                      totalVotes > 0 ? (votes / totalVotes * 100) : 0.0;
                  final color = colors[idx % colors.length];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          children: [
                            LinearProgressIndicator(
                              value: totalVotes > 0 ? votes / totalVotes : 0,
                              backgroundColor: Colors.grey[400],
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              minHeight: 24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  '${percent.toStringAsFixed(1)}% ($votes ${votes == 1 ? 'vote' : 'votes'})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 3,
                                          color: Colors.black45),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Votes: $totalVotes',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Updated: ${_formatDate(analytics.updatedAt)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CLOSE'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Remove loading indicator
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load analytics: $e')),
        );
      }
    }
  }
}
