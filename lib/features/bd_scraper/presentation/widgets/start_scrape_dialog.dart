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
  // Source ids the admin has selected. Null = "let backend pick all".
  final Set<String> _sources = {};

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
            sources: _sources.isEmpty ? null : _sources.toList(),
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
              const SizedBox(height: 12),
              _SourcePicker(
                selected: _sources,
                onToggle: (id) => setState(() {
                  if (_sources.contains(id)) {
                    _sources.remove(id);
                  } else {
                    _sources.add(id);
                  }
                }),
              ),
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

// Multi-select chip group for scrape sources. If the user picks none, the
// dialog sends `null` and the backend defaults to "run every ready adapter".
class _SourcePicker extends ConsumerWidget {
  final Set<String> selected;
  final void Function(String id) onToggle;
  const _SourcePicker({required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(scraperSourcesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Sources', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Text(
              selected.isEmpty ? '(all ready adapters)' : '(${selected.length} selected)',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 6),
        sources.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(8),
            child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (err, _) => Text('Failed to load sources: $err', style: const TextStyle(color: Colors.red, fontSize: 12)),
          data: (items) => Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items.map((s) {
              final isSelected = selected.contains(s.id);
              return FilterChip(
                label: Text(
                  s.label,
                  style: TextStyle(color: s.ready ? null : Colors.grey),
                ),
                selected: isSelected,
                onSelected: s.ready ? (_) => onToggle(s.id) : null,
                avatar: s.ready ? null : const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                tooltip: s.ready ? null : 'Adapter not configured (missing API key)',
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
