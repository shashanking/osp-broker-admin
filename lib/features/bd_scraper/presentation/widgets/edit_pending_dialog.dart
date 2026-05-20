import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/bd_scraper/application/scraper_notifier.dart';
import 'package:osp_broker_admin/features/bd_scraper/domain/scraper_models.dart';
import 'package:osp_broker_admin/features/business_directories/application/business_directories_notifier.dart';

class EditPendingDialog extends ConsumerStatefulWidget {
  final ScrapedBusiness record;
  const EditPendingDialog({super.key, required this.record});
  @override
  ConsumerState<EditPendingDialog> createState() => _EditPendingDialogState();
}

class _EditPendingDialogState extends ConsumerState<EditPendingDialog> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _website;
  late final TextEditingController _addressLine;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zip;
  late final TextEditingController _description;
  String? _categoryId;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.record.businessName);
    _email = TextEditingController(text: widget.record.email ?? '');
    _phone = TextEditingController(text: widget.record.phone ?? '');
    _website = TextEditingController(text: widget.record.website ?? '');
    _addressLine = TextEditingController(text: widget.record.addressLine ?? '');
    _city = TextEditingController(text: widget.record.city ?? '');
    _state = TextEditingController(text: widget.record.state ?? '');
    _zip = TextEditingController(text: widget.record.postalCode ?? '');
    _description = TextEditingController(text: widget.record.description ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _website.dispose();
    _addressLine.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _description.dispose();
    super.dispose();
  }

  Map<String, dynamic> _patch() => {
        'businessName': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'website': _website.text.trim(),
        'addressLine': _addressLine.text.trim(),
        'city': _city.text.trim(),
        'state': _state.text.trim().toUpperCase(),
        'postalCode': _zip.text.trim(),
        'description': _description.text.trim(),
      };

  Future<void> _saveOnly() async {
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(scraperPendingProvider.notifier).updateRecord(widget.record.id, _patch());
      if (!mounted) return;
      Navigator.of(context).pop('saved');
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  Future<void> _saveAndApprove() async {
    if (_categoryId == null) {
      setState(() => _error = 'Pick a business category to approve');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      await ref.read(scraperPendingProvider.notifier).updateRecord(widget.record.id, _patch());
      await ref.read(scraperPendingProvider.notifier).approve(widget.record.id, _categoryId!);
      if (!mounted) return;
      Navigator.of(context).pop('approved');
    } catch (e) {
      setState(() { _error = e.toString(); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(businessDirectoriesNotifierProvider);
    final categories = categoriesState.categories.where((c) => !c.isDeleted).toList();

    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Review scraped business')),
          _confidenceChip(widget.record.confidence),
        ],
      ),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.record.flags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 6,
                    children: widget.record.flags
                        .map((f) => Chip(label: Text(f), backgroundColor: Colors.orange.shade50))
                        .toList(),
                  ),
                ),
              Row(children: [
                Expanded(child: _tf('Business name', _name)),
                const SizedBox(width: 12),
                Expanded(child: _tf('Website', _website)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _tf(
                    'Email${widget.record.emailConfidence == ScrapedEmailConfidence.guessed ? "  (guessed)" : ""}',
                    _email,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _tf('Phone', _phone)),
              ]),
              const SizedBox(height: 12),
              _tf('Address line', _addressLine),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _tf('City', _city)),
                const SizedBox(width: 12),
                SizedBox(width: 100, child: _tf('State', _state)),
                const SizedBox(width: 12),
                Expanded(child: _tf('ZIP', _zip)),
              ]),
              const SizedBox(height: 12),
              _tf('Description', _description, maxLines: 3),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _categoryId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Business category (required for approve)',
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 12),
              if (widget.record.sourceUrl.isNotEmpty)
                Text('Source: ${widget.record.sourceUrl}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(null), child: const Text('Cancel')),
        TextButton(onPressed: _saving ? null : _saveOnly, child: const Text('Save changes')),
        FilledButton(
          onPressed: _saving ? null : _saveAndApprove,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save & approve'),
        ),
      ],
    );
  }

  Widget _tf(String label, TextEditingController c, {int maxLines = 1}) {
    return TextFormField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _confidenceChip(double score) {
    final pct = (score * 100).round();
    final color = pct >= 70 ? Colors.green : pct >= 45 ? Colors.orange : Colors.red;
    return Chip(label: Text('confidence $pct%'), backgroundColor: color.withOpacity(0.12), labelStyle: TextStyle(color: color));
  }
}
