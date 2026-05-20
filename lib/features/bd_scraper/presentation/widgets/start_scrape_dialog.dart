import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/bd_scraper/application/scraper_notifier.dart';

// US state codes — kept inline (no external dep).
const List<String> _usStates = [
  'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN','IA','KS','KY','LA','ME','MD',
  'MA','MI','MN','MS','MO','MT','NE','NV','NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC',
  'SD','TN','TX','UT','VT','VA','WA','WV','WI','WY','DC',
];

class StartScrapeDialog extends ConsumerStatefulWidget {
  const StartScrapeDialog({super.key});
  @override
  ConsumerState<StartScrapeDialog> createState() => _StartScrapeDialogState();
}

class _StartScrapeDialogState extends ConsumerState<StartScrapeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _categoryCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _state;
  int _target = 25;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _submitting = true; _error = null; });
    try {
      await ref.read(scraperJobsProvider.notifier).startJob(
            category: _categoryCtrl.text.trim(),
            state: _state,
            city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
            targetCount: _target,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() { _error = e.toString(); _submitting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Start business directory scrape'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category / niche',
                  hintText: 'e.g. "dentists", "hvac contractors", "law firms"',
                ),
                validator: (v) => (v == null || v.trim().length < 2) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _state,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'US state (optional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Any —')),
                      ..._usStates.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: (v) => setState(() => _state = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: const InputDecoration(labelText: 'City (optional)'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Target count:'),
                const SizedBox(width: 12),
                Expanded(
                  child: Slider(
                    min: 5, max: 100, divisions: 19,
                    value: _target.toDouble(),
                    label: '$_target',
                    onChanged: (v) => setState(() => _target = v.toInt()),
                  ),
                ),
                SizedBox(width: 40, child: Text('$_target', textAlign: TextAlign.end)),
              ]),
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
        TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Start scrape'),
        ),
      ],
    );
  }
}
