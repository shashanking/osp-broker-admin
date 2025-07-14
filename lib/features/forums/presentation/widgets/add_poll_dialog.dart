import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/forum_admin_notifier.dart';

class AddPollDialog extends ConsumerStatefulWidget {
  const AddPollDialog({super.key});

  @override
  ConsumerState<AddPollDialog> createState() => _AddPollDialogState();
}

class _AddPollDialogState extends ConsumerState<AddPollDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();

    if (options.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least 2 options')),
        );
      }
      return;
    }

    try {
      await ref.read(forumAdminNotifierProvider.notifier).createPoll(
            question: question,
            options: options,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Poll created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create poll: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(forumAdminNotifierProvider).isLoading;

    return AlertDialog(
      title: const Text('Create New Poll'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...List.generate(_optionControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            border: const OutlineInputBorder(),
                            suffixIcon: _optionControllers.length > 2
                                ? IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _removeOption(index),
                                  )
                                : null,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter option text';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Add Option'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('CREATE'),
        ),
      ],
    );
  }
}
