import 'package:dio/dio.dart' show FormData, MultipartFile, DioMediaType;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';

import '../../application/forum_media_notifier.dart';
import '../../domain/forum_media_model.dart';

/// Uploads a picked image to the shop upload endpoint and returns its URL.
///
/// The backend expects a multipart form field named `image` and returns
/// `{ data: { url } }`. Mirrors the upload pattern used in shop_page.dart.
Future<String> _uploadMediaImage(BaseApiService api, PlatformFile file) async {
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw Exception('Selected image has no data');
  }

  final fileName = file.name;
  final ext =
      fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
  const extToMime = {
    'jpg': 'jpeg',
    'jpeg': 'jpeg',
    'png': 'png',
    'gif': 'gif',
    'webp': 'webp',
  };
  final subtype = extToMime[ext] ?? 'png';

  final formData = FormData.fromMap({
    'image': MultipartFile.fromBytes(
      bytes,
      filename: fileName,
      contentType: DioMediaType('image', subtype),
    ),
  });

  final response = await api.post(
    '/shop/upload-image',
    data: formData,
    requireAuth: true,
  );
  return (response.data['data']?['url'] ?? '').toString();
}

/// Forum "Media" management section, embedded in the forums page Media tab.
class ForumMediaSection extends ConsumerStatefulWidget {
  const ForumMediaSection({super.key});

  @override
  ConsumerState<ForumMediaSection> createState() => _ForumMediaSectionState();
}

class _ForumMediaSectionState extends ConsumerState<ForumMediaSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(forumMediaNotifierProvider.notifier).fetchMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forumMediaNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const _AddMediaDialog(),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add media'),
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) {
            if (state.isLoading && state.items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (state.error != null && state.items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(forumMediaNotifierProvider.notifier)
                            .fetchMedia(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: Text('No media items found')),
              );
            }

            final items = [...state.items]
              ..sort((a, b) => a.order.compareTo(b.order));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final media = items[index];
                return _MediaCard(media: media);
              },
            );
          },
        ),
      ],
    );
  }
}

class _MediaCard extends ConsumerWidget {
  final ForumMediaModel media;
  const _MediaCard({required this.media});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasImage = media.image.startsWith('http://') ||
        media.image.startsWith('https://');
    return Card(
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: hasImage
              ? Image.network(
                  media.image,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_outlined),
                ),
        ),
        title: Text(
          media.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (media.subtitle.isNotEmpty) Text(media.subtitle),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Chip('Order: ${media.order}'),
                _Chip(
                  media.isActive ? 'Active' : 'Inactive',
                  color: media.isActive ? Colors.green : Colors.grey,
                ),
                if (media.isDeleted)
                  const _Chip('Deleted', color: Colors.red),
              ],
            ),
          ],
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Edit',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _EditMediaDialog(mediaId: media.id),
              ),
              icon: const Icon(Icons.edit, size: 18),
            ),
            IconButton(
              tooltip: 'Soft delete',
              onPressed: media.isDeleted
                  ? null
                  : () async {
                      final confirmed = await _confirm(
                        context,
                        title: 'Soft delete media',
                        message:
                            'Are you sure you want to soft delete this media item?',
                        confirmLabel: 'Soft delete',
                      );
                      if (confirmed == true) {
                        await ref
                            .read(forumMediaNotifierProvider.notifier)
                            .softDeleteMedia(media.id);
                      }
                    },
              icon: const Icon(Icons.remove_circle_outline, size: 18),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: () async {
                final confirmed = await _confirm(
                  context,
                  title: 'Delete media',
                  message:
                      'Are you sure you want to permanently delete this media item?',
                  confirmLabel: 'Delete',
                );
                if (confirmed == true) {
                  await ref
                      .read(forumMediaNotifierProvider.notifier)
                      .deleteMedia(media.id);
                }
              },
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? color;
  const _Chip(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MediaImagePicker extends StatelessWidget {
  final String imageUrl;
  final String? pickedFileName;
  final bool uploading;
  final VoidCallback? onPick;

  const _MediaImagePicker({
    required this.imageUrl,
    required this.pickedFileName,
    required this.uploading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final hasUrl =
        imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Image',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton.icon(
              onPressed: onPick,
              icon: uploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.file_upload_outlined, size: 18),
              label: Text(uploading ? 'Uploading…' : 'Upload Image'),
            ),
          ],
        ),
        if (hasUrl)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  width: 64,
                  height: 64,
                  child: Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ),
        if (pickedFileName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              pickedFileName!,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _AddMediaDialog extends ConsumerStatefulWidget {
  const _AddMediaDialog();

  @override
  ConsumerState<_AddMediaDialog> createState() => _AddMediaDialogState();
}

class _AddMediaDialogState extends ConsumerState<_AddMediaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _linkController = TextEditingController();
  final _orderController = TextEditingController(text: '0');
  bool _isActive = true;
  String _imageUrl = '';
  PlatformFile? _pickedImage;
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _linkController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (!mounted) return;
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      setState(() {
        _pickedImage = file;
        _uploadingImage = true;
      });
      final url = await _uploadMediaImage(
        ref.read(baseApiServiceProvider),
        file,
      );
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _uploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(forumMediaNotifierProvider.notifier).createMedia(
            title: _titleController.text.trim(),
            subtitle: _subtitleController.text.trim(),
            link: _linkController.text.trim(),
            order: int.tryParse(_orderController.text.trim()) ?? 0,
            isActive: _isActive,
            image: _imageUrl,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create media')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Media'),
      content: _MediaFormBody(
        formKey: _formKey,
        titleController: _titleController,
        subtitleController: _subtitleController,
        linkController: _linkController,
        orderController: _orderController,
        isActive: _isActive,
        onActiveChanged: (v) => setState(() => _isActive = v),
        imageUrl: _imageUrl,
        pickedFileName: _pickedImage?.name,
        uploading: _uploadingImage,
        onPick:
            _uploadingImage || _submitting ? null : _pickAndUploadImage,
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_submitting || _uploadingImage) ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _EditMediaDialog extends ConsumerStatefulWidget {
  final String mediaId;
  const _EditMediaDialog({required this.mediaId});

  @override
  ConsumerState<_EditMediaDialog> createState() => _EditMediaDialogState();
}

class _EditMediaDialogState extends ConsumerState<_EditMediaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _linkController;
  late final TextEditingController _orderController;
  late bool _isActive;
  String _imageUrl = '';
  PlatformFile? _pickedImage;
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final media = ref
        .read(forumMediaNotifierProvider)
        .items
        .firstWhere((m) => m.id == widget.mediaId);
    _titleController = TextEditingController(text: media.title);
    _subtitleController = TextEditingController(text: media.subtitle);
    _linkController = TextEditingController(text: media.link);
    _orderController = TextEditingController(text: media.order.toString());
    _isActive = media.isActive;
    _imageUrl = media.image;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _linkController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (!mounted) return;
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      setState(() {
        _pickedImage = file;
        _uploadingImage = true;
      });
      final url = await _uploadMediaImage(
        ref.read(baseApiServiceProvider),
        file,
      );
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
        _uploadingImage = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(forumMediaNotifierProvider.notifier).updateMedia(
            id: widget.mediaId,
            title: _titleController.text.trim(),
            subtitle: _subtitleController.text.trim(),
            link: _linkController.text.trim(),
            order: int.tryParse(_orderController.text.trim()) ?? 0,
            isActive: _isActive,
            image: _imageUrl,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update media')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Media'),
      content: _MediaFormBody(
        formKey: _formKey,
        titleController: _titleController,
        subtitleController: _subtitleController,
        linkController: _linkController,
        orderController: _orderController,
        isActive: _isActive,
        onActiveChanged: (v) => setState(() => _isActive = v),
        imageUrl: _imageUrl,
        pickedFileName: _pickedImage?.name,
        uploading: _uploadingImage,
        onPick:
            _uploadingImage || _submitting ? null : _pickAndUploadImage,
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (_submitting || _uploadingImage) ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _MediaFormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController linkController;
  final TextEditingController orderController;
  final bool isActive;
  final ValueChanged<bool> onActiveChanged;
  final String imageUrl;
  final String? pickedFileName;
  final bool uploading;
  final VoidCallback? onPick;

  const _MediaFormBody({
    required this.formKey,
    required this.titleController,
    required this.subtitleController,
    required this.linkController,
    required this.orderController,
    required this.isActive,
    required this.onActiveChanged,
    required this.imageUrl,
    required this.pickedFileName,
    required this.uploading,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: subtitleController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Subtitle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: linkController,
                decoration: const InputDecoration(
                  labelText: 'Link',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: orderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Order',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isEmpty) return null;
                  if (int.tryParse(v) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: onActiveChanged,
              ),
              const SizedBox(height: 4),
              _MediaImagePicker(
                imageUrl: imageUrl,
                pickedFileName: pickedFileName,
                uploading: uploading,
                onPick: onPick,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
