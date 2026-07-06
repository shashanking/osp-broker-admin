import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';
import 'package:osp_broker_admin/features/users/data/models/pin_model.dart';

class PinManagementPage extends ConsumerStatefulWidget {
  const PinManagementPage({super.key});

  @override
  ConsumerState<PinManagementPage> createState() => _PinManagementPageState();
}

class _PinManagementPageState extends ConsumerState<PinManagementPage> {
  List<PinModel> _pins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPins();
  }

  Future<void> _loadPins() async {
    setState(() => _isLoading = true);
    try {
      final pins = await ref.read(userNotifierProvider.notifier).fetchAllPins();
      if (mounted) {
        setState(() {
          _pins = pins;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddPinDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const _AddPinDialog(),
    );

    if (result == true) {
      _loadPins();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pin Type Management'),
        backgroundColor: const Color(0xFF24439B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Available Pin Types',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddPinDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('New Pin Type'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF24439B),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (_pins.isEmpty)
                    const Center(child: Text('No pin types defined yet.'))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _pins.length,
                        itemBuilder: (context, index) {
                          final pin = _pins[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _parseColor(pin.color),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              title: Text('${pin.color} Pin'),
                              subtitle: Text(
                                'Price: \$${pin.price.toStringAsFixed(2)} | Duration: ${pin.duration} days',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Color _parseColor(String colorName) {
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'yellow': Colors.yellow,
      'purple': Colors.purple,
      'orange': Colors.orange,
      'pink': Colors.pink,
      'teal': Colors.teal,
      'cyan': Colors.cyan,
      'amber': Colors.amber,
    };
    return colorMap[colorName.toLowerCase()] ?? Colors.grey;
  }
}

class _AddPinDialog extends ConsumerStatefulWidget {
  const _AddPinDialog();

  @override
  ConsumerState<_AddPinDialog> createState() => _AddPinDialogState();
}

class _AddPinDialogState extends ConsumerState<_AddPinDialog> {
  final _formKey = GlobalKey<FormState>();
  String _color = 'Blue';
  double _price = 10.0;
  int _duration = 7;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(userNotifierProvider.notifier)
          .createPin(
            color: _color,
            price: _price,
            duration: _duration,
            image: 'https://placeholder.com/pin', // Default placeholder
          );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Pin Type'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Color (e.g. Red, Blue)',
              ),
              initialValue: _color,
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
              onSaved: (v) => _color = v!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Price (\$)'),
              initialValue: _price.toString(),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  double.tryParse(v ?? '') == null ? 'Invalid price' : null,
              onSaved: (v) => _price = double.parse(v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Duration (days)'),
              initialValue: _duration.toString(),
              keyboardType: TextInputType.number,
              validator: (v) =>
                  int.tryParse(v ?? '') == null ? 'Invalid duration' : null,
              onSaved: (v) => _duration = int.parse(v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
