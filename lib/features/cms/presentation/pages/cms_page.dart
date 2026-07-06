import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import '../../data/cms_image_upload.dart';
import '../../data/site_content_repository.dart';
import '../../domain/cms_section_spec.dart';

class CmsPage extends ConsumerStatefulWidget {
  const CmsPage({super.key});

  @override
  ConsumerState<CmsPage> createState() => _CmsPageState();
}

class _CmsPageState extends ConsumerState<CmsPage> {
  CmsSectionSpec _selected = kCmsSections.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const TopBar(
              userName: 'Admin', userRole: 'Admin', notificationCount: '5'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.web, color: Color(0xFF24439B), size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Website Content (CMS)',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Text(
                                'Edit the marketing pages. Saving auto-translates into all supported languages.',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 260, child: _buildSectionList()),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _SectionEditor(
                            key: ValueKey(_selected.type),
                            spec: _selected,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E2DF)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: kCmsSections.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFEFEEEA)),
        itemBuilder: (context, i) {
          final s = kCmsSections[i];
          final selected = s.type == _selected.type;
          return ListTile(
            selected: selected,
            selectedTileColor: const Color(0xFFEFF3FF),
            title: Text(s.title,
                style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500)),
            subtitle: Text(s.description,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            onTap: () => setState(() => _selected = s),
          );
        },
      ),
    );
  }
}

/// Holds the live controllers for one row of an objectList field, keyed by
/// the row's item-field key. stringList fields inside a row also use a
/// (newline-joined) TextEditingController; boolean fields are stored as bools.
class _ObjectRow {
  final Map<String, TextEditingController> controllers = {};
  final Map<String, bool> bools = {};

  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
  }
}

class _SectionEditor extends ConsumerStatefulWidget {
  final CmsSectionSpec spec;

  const _SectionEditor({super.key, required this.spec});

  @override
  ConsumerState<_SectionEditor> createState() => _SectionEditorState();
}

class _SectionEditorState extends ConsumerState<_SectionEditor> {
  /// Controllers for top-level scalar/text/stringList fields, keyed by field key.
  final Map<String, TextEditingController> _controllers = {};

  /// Top-level boolean field values, keyed by field key.
  final Map<String, bool> _bools = {};

  /// Rows for each top-level objectList field, keyed by field key.
  final Map<String, List<_ObjectRow>> _rows = {};

  bool _loading = true;
  bool _saving = false;
  String? _error;

  /// Controllers whose image is currently uploading (so each Upload button can
  /// show its own spinner independently — including object-list row fields).
  final Set<TextEditingController> _uploading = {};

  /// Picks an image, uploads it to S3 via the shared admin endpoint, and writes
  /// the returned URL into [controller].
  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    setState(() => _uploading.add(controller));
    try {
      final api = ref.read(baseApiServiceProvider);
      final url = await uploadCmsImage(api, result.files.first);
      controller.text = url;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading.remove(controller));
    }
  }

  /// Live thumbnail preview that updates as the URL field changes.
  Widget _imageThumb(TextEditingController controller) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final url = value.text.trim();
        final isUrl = url.startsWith('http://') || url.startsWith('https://');
        if (!isUrl) return const SizedBox(height: 4);
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 64,
              width: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 64,
                width: 64,
                color: const Color(0xFFEFEEEA),
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    for (final f in widget.spec.fields) {
      switch (f.kind) {
        case CmsFieldKind.boolean:
          _bools[f.key] = false;
          break;
        case CmsFieldKind.objectList:
          _rows[f.key] = [];
          break;
        default:
          _controllers[f.key] = TextEditingController();
      }
    }
    _load();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final list in _rows.values) {
      for (final r in list) {
        r.dispose();
      }
    }
    super.dispose();
  }

  // --- (de)serialisation helpers --------------------------------------------

  String _asString(dynamic v) => v == null ? '' : v.toString();

  String _stringListToText(dynamic v) {
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').join('\n');
    }
    return '';
  }

  bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return false;
  }

  /// Creates a populated row for an objectList field from a stored map.
  _ObjectRow _buildRow(CmsFieldSpec field, Map<String, dynamic> data) {
    final row = _ObjectRow();
    for (final f in field.itemFields) {
      switch (f.kind) {
        case CmsFieldKind.boolean:
          row.bools[f.key] = _asBool(data[f.key]);
          break;
        case CmsFieldKind.stringList:
          row.controllers[f.key] =
              TextEditingController(text: _stringListToText(data[f.key]));
          break;
        default:
          row.controllers[f.key] =
              TextEditingController(text: _asString(data[f.key]));
      }
    }
    return row;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(siteContentRepositoryProvider);
      final value = await repo.fetchSource(widget.spec.type);
      for (final f in widget.spec.fields) {
        switch (f.kind) {
          case CmsFieldKind.boolean:
            _bools[f.key] = _asBool(value[f.key]);
            break;
          case CmsFieldKind.stringList:
            _controllers[f.key]?.text = _stringListToText(value[f.key]);
            break;
          case CmsFieldKind.objectList:
            // Replace any existing rows.
            for (final r in _rows[f.key] ?? const <_ObjectRow>[]) {
              r.dispose();
            }
            final raw = value[f.key];
            final list = <_ObjectRow>[];
            if (raw is List) {
              for (final item in raw) {
                final map = item is Map
                    ? Map<String, dynamic>.from(item)
                    : <String, dynamic>{};
                list.add(_buildRow(f, map));
              }
            }
            _rows[f.key] = list;
            break;
          default:
            _controllers[f.key]?.text = _asString(value[f.key]);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _parseStringList(String text) => text
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Map<String, dynamic> _rowToMap(CmsFieldSpec field, _ObjectRow row) {
    final map = <String, dynamic>{};
    for (final f in field.itemFields) {
      switch (f.kind) {
        case CmsFieldKind.number:
          map[f.key] =
              int.tryParse((row.controllers[f.key]?.text ?? '').trim()) ?? 0;
          break;
        case CmsFieldKind.boolean:
          map[f.key] = row.bools[f.key] ?? false;
          break;
        case CmsFieldKind.stringList:
          map[f.key] = _parseStringList(row.controllers[f.key]?.text ?? '');
          break;
        default:
          map[f.key] = (row.controllers[f.key]?.text ?? '').trim();
      }
    }
    return map;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final value = <String, dynamic>{};
      for (final f in widget.spec.fields) {
        switch (f.kind) {
          case CmsFieldKind.number:
            value[f.key] =
                int.tryParse((_controllers[f.key]?.text ?? '').trim()) ?? 0;
            break;
          case CmsFieldKind.boolean:
            value[f.key] = _bools[f.key] ?? false;
            break;
          case CmsFieldKind.stringList:
            value[f.key] = _parseStringList(_controllers[f.key]?.text ?? '');
            break;
          case CmsFieldKind.objectList:
            value[f.key] = [
              for (final r in _rows[f.key] ?? const <_ObjectRow>[])
                _rowToMap(f, r),
            ];
            break;
          default:
            value[f.key] = (_controllers[f.key]?.text ?? '').trim();
        }
      }
      await ref
          .read(siteContentRepositoryProvider)
          .save(widget.spec.type, value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved. Translations generated for all languages.'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addRow(CmsFieldSpec field) {
    setState(() {
      _rows[field.key]!.add(_buildRow(field, const {}));
    });
  }

  void _removeRow(CmsFieldSpec field, int index) {
    setState(() {
      final row = _rows[field.key]!.removeAt(index);
      row.dispose();
    });
  }

  // --- rendering -------------------------------------------------------------

  InputDecoration _decoration(String hint, {String? helper}) {
    return InputDecoration(
      isDense: true,
      helperText: helper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      hintText: hint,
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  /// Renders a simple (non-objectList) field, used both at the top level and
  /// inside objectList rows. For boolean/stringList, [controller]/[boolGet]/
  /// [boolSet] tie into the appropriate state container.
  Widget _buildSimpleField(
    CmsFieldSpec f, {
    required TextEditingController? controller,
    required bool boolValue,
    required ValueChanged<bool> onBoolChanged,
  }) {
    switch (f.kind) {
      case CmsFieldKind.boolean:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Checkbox(
                value: boolValue,
                onChanged: (v) => onBoolChanged(v ?? false),
              ),
              Expanded(child: Text(f.label)),
            ],
          ),
        );
      case CmsFieldKind.multiline:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(f.label),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: _decoration(f.label),
            ),
          ],
        );
      case CmsFieldKind.image:
        final uploading = controller != null && _uploading.contains(controller);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(f.label),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: 1,
                    decoration: _decoration(
                      'Image URL',
                      helper: 'Upload an image or paste a URL / asset path',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: (controller == null || uploading)
                        ? null
                        : () => _pickAndUploadImage(controller),
                    icon: uploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.upload, size: 18),
                    label: Text(uploading ? 'Uploading…' : 'Upload'),
                  ),
                ),
              ],
            ),
            if (controller != null) _imageThumb(controller),
          ],
        );
      case CmsFieldKind.number:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(f.label),
            TextField(
              controller: controller,
              maxLines: 1,
              keyboardType: TextInputType.number,
              decoration: _decoration(f.label),
            ),
          ],
        );
      case CmsFieldKind.stringList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(f.label),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: _decoration(f.label, helper: 'One per line'),
            ),
          ],
        );
      case CmsFieldKind.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label(f.label),
            TextField(
              controller: controller,
              maxLines: 1,
              decoration: _decoration(f.label),
            ),
          ],
        );
      case CmsFieldKind.objectList:
        // Not expected here; objectList is only rendered at the top level.
        return const SizedBox.shrink();
    }
  }

  Widget _buildTopLevelField(CmsFieldSpec f) {
    if (f.kind == CmsFieldKind.objectList) {
      return _buildObjectList(f);
    }
    return _buildSimpleField(
      f,
      controller: _controllers[f.key],
      boolValue: _bools[f.key] ?? false,
      onBoolChanged: (v) => setState(() => _bools[f.key] = v),
    );
  }

  Widget _buildObjectList(CmsFieldSpec field) {
    final rows = _rows[field.key] ?? const <_ObjectRow>[];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE3E2DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          for (var i = 0; i < rows.length; i++) ...[
            _buildObjectRow(field, rows[i], i),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _addRow(field),
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add ${field.label} item'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectRow(CmsFieldSpec field, _ObjectRow row, int index) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE3E2DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('#${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: Colors.grey)),
              ),
              IconButton(
                tooltip: 'Remove',
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeRow(field, index),
              ),
            ],
          ),
          for (final itemField in field.itemFields) ...[
            _buildSimpleField(
              itemField,
              controller: row.controllers[itemField.key],
              boolValue: row.bools[itemField.key] ?? false,
              onBoolChanged: (v) =>
                  setState(() => row.bools[itemField.key] = v),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE3E2DF)),
      ),
      padding: const EdgeInsets.all(24),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.spec.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving…' : 'Save & translate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF24439B),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final f in widget.spec.fields) ...[
                          _buildTopLevelField(f),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
