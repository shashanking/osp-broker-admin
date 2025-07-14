import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/forum_admin_notifier.dart';

class EventsListDialog extends ConsumerStatefulWidget {
  const EventsListDialog({super.key});

  @override
  ConsumerState<EventsListDialog> createState() => _EventsListDialogState();
}

class _EventsListDialogState extends ConsumerState<EventsListDialog> {
  @override
  void initState() {
    super.initState();
    // Load events when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumAdminNotifierProvider.notifier).fetchAllEvents();
    });
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM d, y h:mm a').format(dateTime);
    } catch (e) {
      return dateString; // Return original string if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final forumState = ref.watch(forumAdminNotifierProvider);
    final events = forumState.events;
    final isLoading = forumState.isLoading;

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Events'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEventDialog(context, ref),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: isLoading && events.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : events.isEmpty
                ? const Center(child: Text('No events available'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(event.description),
                              const SizedBox(height: 4),
                              Text(
                                'Date: ${_formatDate(event.date)}',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
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
                              if (value == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text(
                                        'Are you sure you want to delete this event?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(true),
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
                                        .read(forumAdminNotifierProvider.notifier)
                                        .deleteEvent(event.id);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Event deleted'),
                                        ),
                                      );
                                      await ref
                                          .read(forumAdminNotifierProvider.notifier)
                                          .fetchAllEvents();
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to delete event: $e'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              }
                            },
                          ),
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

  void _showAddEventDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: Text(
                              selectedDate == null
                                  ? 'Select Date'
                                  : 'Date: ${DateFormat('MMM d, y').format(selectedDate!)}',
                            ),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (date != null) {
                                setState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: Text(
                              selectedTime == null
                                  ? 'Select Time'
                                  : 'Time: ${selectedTime!.format(context)}',
                            ),
                            trailing: const Icon(Icons.access_time),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() {
                                  selectedTime = time;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a title')),
                      );
                      return;
                    }

                    if (selectedDate == null || selectedTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select date and time')),
                      );
                      return;
                    }

                    // Combine date and time
                    final dateTime = DateTime(
                      selectedDate!.year,
                      selectedDate!.month,
                      selectedDate!.day,
                      selectedTime!.hour,
                      selectedTime!.minute,
                    );

                    // Format as ISO 8601 string
                    final dateString = dateTime.toUtc().toIso8601String();

                    try {
                      await ref
                          .read(forumAdminNotifierProvider.notifier)
                          .createEvent(
                            title: titleController.text,
                            description: descriptionController.text,
                            date: dateString,
                          );

                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event created')),
                        );
                        await ref
                            .read(forumAdminNotifierProvider.notifier)
                            .fetchAllEvents();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to create event: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('CREATE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
