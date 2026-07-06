import 'package:dio/dio.dart'
    show FormData, MultipartFile, DioMediaType, DioException;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/infrastructure/base_api_service.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';

import '../../application/shop_badge_notifier.dart';
import '../../application/shop_bundle_notifier.dart';
import '../../application/shop_items_notifier.dart';
import '../../application/shop_kudo_coin_notifier.dart';
import '../../application/shop_pin_notifier.dart';
import '../../application/shop_review_notifier.dart';
import 'shop_items_page.dart';

/// Uploads a picked image to the shop upload endpoint and returns its URL.
///
/// Mirrors the multipart upload pattern used elsewhere in the app
/// (see forum_repository.upload-icon / auction_notifier). The backend expects
/// a multipart form field named `image` and returns `{ data: { url } }`.
Future<String> _uploadShopImage(BaseApiService api, PlatformFile file) async {
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    throw Exception('Selected image has no data');
  }

  final fileName = file.name;
  final ext = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : '';
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

final GoRoute goRouteShop = GoRoute(
  path: ShopPage.routePath,
  name: ShopPage.routeName,
  pageBuilder: (context, state) =>
      MaterialPage(key: state.pageKey, child: const ShopPage()),
);

class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  static const String routeName = 'shop';
  static const String routePath = '/shop';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _ShopPage();
  }
}

class _ShopPage extends ConsumerStatefulWidget {
  const _ShopPage();

  @override
  ConsumerState<_ShopPage> createState() => _ShopPageState();
}

// LEGACY SHOP (Pins / Badges / Kudo Coins)
// Restored for kudo coins and badges management

/// Extracts a human-readable message from a failed kudo-coin request so the
/// real cause (e.g. duplicate price, missing permission, server error) is shown
/// instead of a generic "failed" message.
String _kudoErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return 'You do not have permission to manage kudo coins (admin only).';
    }
    return 'Request failed${code != null ? ' ($code)' : ''}. Please try again.';
  }
  return 'Failed to save kudo coin. Please try again.';
}

class _AddKudoCoinDialog extends ConsumerStatefulWidget {
  const _AddKudoCoinDialog();

  @override
  ConsumerState<_AddKudoCoinDialog> createState() => _AddKudoCoinDialogState();
}

class _AddKudoCoinDialogState extends ConsumerState<_AddKudoCoinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopKudoCoinNotifierProvider.notifier).createKudoCoin(
            price: int.parse(_priceController.text.trim()),
            amount: int.parse(_amountController.text.trim()),
            description: _descriptionController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_kudoErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Kudo Coin'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (USD)',
                  helperText: 'What the buyer pays',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Please enter a valid number';
                  if (parsed < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kudos granted',
                  helperText: 'How many kudo coins the buyer receives',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/icons/KudoCoins.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.monetization_on, size: 20),
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Please enter a valid number';
                  if (parsed <= 0) return 'Kudos must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
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

class _EditKudoCoinDialog extends ConsumerStatefulWidget {
  final String kudoCoinId;
  const _EditKudoCoinDialog({required this.kudoCoinId});

  @override
  ConsumerState<_EditKudoCoinDialog> createState() =>
      _EditKudoCoinDialogState();
}

class _EditKudoCoinDialogState extends ConsumerState<_EditKudoCoinDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final coin = ref
        .read(shopKudoCoinNotifierProvider)
        .kudoCoins
        .firstWhere((c) => c.id == widget.kudoCoinId);
    _priceController = TextEditingController(text: coin.price.toString());
    _amountController =
        TextEditingController(text: coin.amount?.toString() ?? '');
    _descriptionController = TextEditingController(text: coin.description);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopKudoCoinNotifierProvider.notifier).updateKudoCoin(
            id: widget.kudoCoinId,
            price: int.parse(_priceController.text.trim()),
            amount: int.parse(_amountController.text.trim()),
            description: _descriptionController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_kudoErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Kudo Coin'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (USD)',
                  helperText: 'What the buyer pays',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Please enter a valid number';
                  if (parsed < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Kudos granted',
                  helperText: 'How many kudo coins the buyer receives',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/icons/KudoCoins.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.monetization_on, size: 20),
                    ),
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Please enter a valid number';
                  if (parsed <= 0) return 'Kudos must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
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

class _AddBadgeDialog extends ConsumerStatefulWidget {
  const _AddBadgeDialog();

  @override
  ConsumerState<_AddBadgeDialog> createState() => _AddBadgeDialogState();
}

class _AddBadgeDialogState extends ConsumerState<_AddBadgeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _imageUrl = '';
  PlatformFile? _pickedImage;
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
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
      final url = await _uploadShopImage(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopBadgeNotifierProvider.notifier).createBadge(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            price: int.parse(_priceController.text.trim()),
            image: _imageUrl,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create badge')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Badge'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Please enter a valid number';
                  if (parsed < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _PinImagePicker(
                imageUrl: _imageUrl,
                pickedFileName: _pickedImage?.name,
                uploading: _uploadingImage,
                onPick: _uploadingImage || _submitting
                    ? null
                    : _pickAndUploadImage,
              ),
            ],
          ),
        ),
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

class _EditBadgeDialog extends ConsumerStatefulWidget {
  final String badgeId;
  const _EditBadgeDialog({required this.badgeId});

  @override
  ConsumerState<_EditBadgeDialog> createState() => _EditBadgeDialogState();
}

class _EditBadgeDialogState extends ConsumerState<_EditBadgeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String _imageUrl = '';
  PlatformFile? _pickedImage;
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final badge = ref
        .read(shopBadgeNotifierProvider)
        .badges
        .firstWhere((b) => b.id == widget.badgeId);
    _nameController = TextEditingController(text: badge.name);
    _descriptionController = TextEditingController(text: badge.description);
    _imageUrl = badge.image;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
      final url = await _uploadShopImage(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopBadgeNotifierProvider.notifier).updateBadge(
            id: widget.badgeId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            image: _imageUrl,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update badge')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Badge'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              const SizedBox(height: 12),
              _PinImagePicker(
                imageUrl: _imageUrl,
                pickedFileName: _pickedImage?.name,
                uploading: _uploadingImage,
                onPick: _uploadingImage || _submitting
                    ? null
                    : _pickAndUploadImage,
              ),
            ],
          ),
        ),
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

class _ShopPageState extends ConsumerState<_ShopPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopPinNotifierProvider.notifier).fetchPins();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            TopBar(
              userName: 'Admin',
              userRole: 'Admin',
              notificationCount: '5',
            ),
            const SizedBox(height: 16),
            // const Padding(
            //   padding: EdgeInsets.symmetric(horizontal: 16.0),
            //   child: Align(
            //     alignment: Alignment.centerLeft,
            //     child: Text(
            //       'Shop',
            //       style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Products'),
                  Tab(text: 'Pins'),
                  Tab(text: 'Bundles'),
                  Tab(text: 'Badges'),
                  Tab(text: 'Kudo Coins'),
                  Tab(text: 'Reviews'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: TabBarView(
                children: [
                  ShopItemsPage(),
                  _PinsTab(),
                  _BundlesTab(),
                  _BadgesTab(),
                  _KudoCoinsTab(),
                  _ReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KudoCoinsTab extends ConsumerStatefulWidget {
  const _KudoCoinsTab();

  @override
  ConsumerState<_KudoCoinsTab> createState() => _KudoCoinsTabState();
}

class _KudoCoinsTabState extends ConsumerState<_KudoCoinsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopKudoCoinNotifierProvider.notifier).fetchKudoCoins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopKudoCoinNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const _AddKudoCoinDialog(),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Kudo Coin'),
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(shopKudoCoinNotifierProvider.notifier)
                            .fetchKudoCoins(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state.kudoCoins.isEmpty) {
                return const Center(child: Text('No kudo coins found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: state.kudoCoins.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final coin = state.kudoCoins[index];
                  return Card(
                    child: ListTile(
                      leading: Image.asset(
                        'assets/icons/KudoCoins.png',
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.monetization_on, size: 40),
                      ),
                      title: Row(
                        children: [
                          Text(
                            coin.amount != null
                                ? '${coin.amount} kudos'
                                : 'Kudos not set',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/icons/KudoCoins.png',
                            width: 16,
                            height: 16,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.monetization_on, size: 16),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        'Price: \$${coin.price}\n${coin.description}'
                        '${coin.isDeleted ? '\n(Deleted)' : ''}',
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
                              builder: (_) =>
                                  _EditKudoCoinDialog(kudoCoinId: coin.id),
                            ),
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Soft delete',
                            onPressed: coin.isDeleted
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text(
                                          'Soft delete kudo coin',
                                        ),
                                        content: const Text(
                                          'Are you sure you want to soft delete this kudo coin?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Soft delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await ref
                                          .read(
                                            shopKudoCoinNotifierProvider
                                                .notifier,
                                          )
                                          .softDeleteKudoCoin(coin.id);
                                    }
                                  },
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete kudo coin'),
                                  content: const Text(
                                    'Are you sure you want to permanently delete this kudo coin?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ref
                                    .read(shopKudoCoinNotifierProvider.notifier)
                                    .deleteKudoCoin(coin.id);
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BadgesTab extends ConsumerStatefulWidget {
  const _BadgesTab();

  @override
  ConsumerState<_BadgesTab> createState() => _BadgesTabState();
}

class _BadgesTabState extends ConsumerState<_BadgesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopBadgeNotifierProvider.notifier).fetchBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopBadgeNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const _AddBadgeDialog(),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Badge'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete all badges'),
                      content: const Text(
                        'Are you sure you want to delete all badges?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete all'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await ref
                        .read(shopBadgeNotifierProvider.notifier)
                        .deleteAllBadges();
                  }
                },
                icon: const Icon(Icons.delete_forever, size: 16),
                label: const Text('Delete All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(shopBadgeNotifierProvider.notifier)
                            .fetchBadges(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state.badges.isEmpty) {
                return const Center(child: Text('No badges found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: state.badges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final badge = state.badges[index];
                  return Card(
                    child: ListTile(
                      leading: _badgeThumbnail(badge.image),
                      title: Text(badge.name),
                      subtitle: Text(
                        '${badge.description}\nPrice: ${badge.price} | Deleted: ${badge.isDeleted}',
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
                              builder: (_) =>
                                  _EditBadgeDialog(badgeId: badge.id),
                            ),
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Soft delete',
                            onPressed: badge.isDeleted
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Soft delete badge'),
                                        content: const Text(
                                          'Are you sure you want to soft delete this badge?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Soft delete'),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await ref
                                          .read(
                                            shopBadgeNotifierProvider.notifier,
                                          )
                                          .softDeleteBadge(badge.id);
                                    }
                                  },
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete badge'),
                                  content: const Text(
                                    'Are you sure you want to permanently delete this badge?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await ref
                                    .read(shopBadgeNotifierProvider.notifier)
                                    .deleteBadge(badge.id);
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PinsTab extends ConsumerWidget {
  const _PinsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shopPinNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const _AddPinDialog(),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Pin'),
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(shopPinNotifierProvider.notifier)
                            .fetchPins(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state.pins.isEmpty) {
                return const Center(child: Text('No pins found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: state.pins.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pin = state.pins[index];
                  final pinColor = _parsePinColor(pin.color);
                  return Card(
                    child: ListTile(
                      leading: _pinThumbnail(pin.image, pinColor),
                      title: Text('Color: ${pin.color}'),
                      subtitle: Text(
                        'Price: ${pin.price} | Duration: ${pin.duration} days | Deleted: ${pin.isDeleted}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // (Removed the "Bought / Not bought" chip — `pin.bought`
                          // is a legacy global flag on the catalog type, not
                          // per-user ownership, so it was always misleading.)
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) =>
                                  _EditPinDialog(pinId: pin.id),
                            ),
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Soft delete',
                            onPressed: pin.isDeleted
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Soft delete pin'),
                                        content: const Text(
                                          'Are you sure you want to soft delete this pin?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Soft delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      await ref
                                          .read(
                                            shopPinNotifierProvider.notifier,
                                          )
                                          .softDeletePin(pin.id);
                                    }
                                  },
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete pin'),
                                  content: const Text(
                                    'Are you sure you want to permanently delete this pin?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                await ref
                                    .read(shopPinNotifierProvider.notifier)
                                    .deletePin(pin.id);
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A small thumbnail for a pin: shows the uploaded image when available,
/// otherwise falls back to a colored circle derived from the pin color.
Widget _pinThumbnail(String image, Color fallbackColor) {
  final isUrl = image.startsWith('http://') || image.startsWith('https://');
  if (isUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        image,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _pinColorCircle(fallbackColor),
      ),
    );
  }
  return _pinColorCircle(fallbackColor);
}

Widget _pinColorCircle(Color color) {
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: Border.all(color: Colors.black12),
    ),
  );
}

/// A small thumbnail for a badge: shows the uploaded image when available,
/// otherwise falls back to a neutral trophy icon.
Widget _badgeThumbnail(String image) {
  final isUrl = image.startsWith('http://') || image.startsWith('https://');
  if (isUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        image,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _badgeFallbackIcon(),
      ),
    );
  }
  return _badgeFallbackIcon();
}

Widget _badgeFallbackIcon() {
  return Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      color: Colors.blueGrey.shade100,
      border: Border.all(color: Colors.black12),
    ),
    child: const Icon(Icons.emoji_events, size: 18, color: Colors.blueGrey),
  );
}

Color _parsePinColor(String raw) {
  final v = raw.trim().toLowerCase();

  const named = <String, Color>{
    'yellow': Colors.yellow,
    'red': Colors.red,
    'green': Colors.green,
    'blue': Colors.blue,
    'purple': Colors.purple,
    'pink': Colors.pink,
    'orange': Colors.orange,
    'black': Colors.black,
    'white': Colors.white,
    'grey': Colors.grey,
    'gray': Colors.grey,
    'brown': Colors.brown,
    'cyan': Colors.cyan,
    'teal': Colors.teal,
    'lime': Colors.lime,
    'amber': Colors.amber,
    'indigo': Colors.indigo,
  };

  final mapped = named[v];
  if (mapped != null) return mapped;

  if (v.startsWith('#')) {
    final hex = v.substring(1);
    if (hex.length == 6 || hex.length == 8) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) {
        return Color(hex.length == 6 ? (0xFF000000 | value) : value);
      }
    }
  }

  return Colors.blueGrey;
}

class _EditPinDialog extends ConsumerStatefulWidget {
  final String pinId;
  const _EditPinDialog({required this.pinId});

  @override
  ConsumerState<_EditPinDialog> createState() => _EditPinDialogState();
}

class _EditPinDialogState extends ConsumerState<_EditPinDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _colorController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  String _imageUrl = '';
  PlatformFile? _pickedImage;
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final pin = ref
        .read(shopPinNotifierProvider)
        .pins
        .firstWhere((p) => p.id == widget.pinId);

    _colorController = TextEditingController(text: pin.color);
    _priceController = TextEditingController(text: pin.price.toString());
    _durationController = TextEditingController(text: pin.duration.toString());
    _imageUrl = pin.image;
  }

  @override
  void dispose() {
    _colorController.dispose();
    _priceController.dispose();
    _durationController.dispose();
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
      final url = await _uploadShopImage(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopPinNotifierProvider.notifier).updatePin(
            id: widget.pinId,
            color: _colorController.text.trim(),
            price: int.parse(_priceController.text.trim()),
            duration: int.parse(_durationController.text.trim()),
            image: _imageUrl,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update pin')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Pin'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: const ['Red', 'Yellow', 'Blue']
                        .contains(_colorController.text.trim())
                    ? _colorController.text.trim()
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
                items: const ['Red', 'Yellow', 'Blue']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _colorController.text = value ?? ''),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please select a color'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Please enter a valid number';
                  if (parsed < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (days)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Please enter a valid number';
                  if (parsed <= 0) return 'Duration must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _PinImagePicker(
                imageUrl: _imageUrl,
                pickedFileName: _pickedImage?.name,
                uploading: _uploadingImage,
                onPick: _uploadingImage || _submitting
                    ? null
                    : _pickAndUploadImage,
              ),
            ],
          ),
        ),
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

/// Shared image picker + preview control used by the pin and bundle dialogs.
class _PinImagePicker extends StatelessWidget {
  final String imageUrl;
  final String? pickedFileName;
  final bool uploading;
  final VoidCallback? onPick;

  const _PinImagePicker({
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

class _AddPinDialog extends ConsumerStatefulWidget {
  const _AddPinDialog();

  @override
  ConsumerState<_AddPinDialog> createState() => _AddPinDialogState();
}

class _AddPinDialogState extends ConsumerState<_AddPinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _colorController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  String _imageUrl = '';
  PlatformFile? _pickedImage;
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void dispose() {
    _colorController.dispose();
    _priceController.dispose();
    _durationController.dispose();
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
      final url = await _uploadShopImage(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopPinNotifierProvider.notifier).createPin(
            color: _colorController.text.trim(),
            price: int.parse(_priceController.text.trim()),
            duration: int.parse(_durationController.text.trim()),
            image: _imageUrl,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create pin')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Pin'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: const ['Red', 'Yellow', 'Blue']
                        .contains(_colorController.text.trim())
                    ? _colorController.text.trim()
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
                items: const ['Red', 'Yellow', 'Blue']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => _colorController.text = value ?? ''),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please select a color'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Please enter a valid number';
                  if (parsed < 0) return 'Price cannot be negative';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (days)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  if (parsed == null) return 'Please enter a valid number';
                  if (parsed <= 0) return 'Duration must be greater than 0';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _PinImagePicker(
                imageUrl: _imageUrl,
                pickedFileName: _pickedImage?.name,
                uploading: _uploadingImage,
                onPick: _uploadingImage || _submitting
                    ? null
                    : _pickAndUploadImage,
              ),
            ],
          ),
        ),
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

// ===========================================================================
// BUNDLES
// ===========================================================================

class _BundlesTab extends ConsumerStatefulWidget {
  const _BundlesTab();

  @override
  ConsumerState<_BundlesTab> createState() => _BundlesTabState();
}

class _BundlesTabState extends ConsumerState<_BundlesTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopBundleNotifierProvider.notifier).fetchBundles();
      ref.read(shopPinNotifierProvider.notifier).fetchPins();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopBundleNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const _AddBundleDialog(),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Bundle'),
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(shopBundleNotifierProvider.notifier)
                            .fetchBundles(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state.bundles.isEmpty) {
                return const Center(child: Text('No bundles found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: state.bundles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final bundle = state.bundles[index];
                  return Card(
                    child: ListTile(
                      leading: _pinThumbnail(bundle.image, Colors.blueGrey),
                      title: Text(bundle.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (bundle.description.isNotEmpty)
                            Text(bundle.description),
                          Text(
                            'Pins: ${bundle.totalPins} | Total price: ${bundle.totalPrice} | '
                            'Active: ${bundle.isActive} | Deleted: ${bundle.isDeleted}',
                          ),
                        ],
                      ),
                      isThreeLine: bundle.description.isNotEmpty,
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) =>
                                  _EditBundleDialog(bundleId: bundle.id),
                            ),
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Soft delete',
                            onPressed: bundle.isDeleted
                                ? null
                                : () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Soft delete bundle'),
                                        content: const Text(
                                          'Are you sure you want to soft delete this bundle?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Soft delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true) {
                                      await ref
                                          .read(
                                            shopBundleNotifierProvider.notifier,
                                          )
                                          .softDeleteBundle(bundle.id);
                                    }
                                  },
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete bundle'),
                                  content: const Text(
                                    'Are you sure you want to permanently delete this bundle?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                await ref
                                    .read(shopBundleNotifierProvider.notifier)
                                    .deleteBundle(bundle.id);
                              }
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Multi-select list of pins used when composing a bundle.
class _BundlePinSelector extends ConsumerWidget {
  final Set<String> selectedPinIds;
  final ValueChanged<String> onToggle;

  const _BundlePinSelector({
    required this.selectedPinIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinState = ref.watch(shopPinNotifierProvider);

    if (pinState.isLoading && pinState.pins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final pins = pinState.pins.where((p) => !p.isDeleted).toList();
    if (pins.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No pins available'),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: pins.length,
        itemBuilder: (context, index) {
          final pin = pins[index];
          final selected = selectedPinIds.contains(pin.id);
          return CheckboxListTile(
            value: selected,
            onChanged: (_) => onToggle(pin.id),
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            secondary: _pinThumbnail(pin.image, _parsePinColor(pin.color)),
            title: Text('Color: ${pin.color}'),
            subtitle: Text(
              'Price: ${pin.price} | Duration: ${pin.duration} days',
            ),
          );
        },
      ),
    );
  }
}

class _AddBundleDialog extends ConsumerStatefulWidget {
  const _AddBundleDialog();

  @override
  ConsumerState<_AddBundleDialog> createState() => _AddBundleDialogState();
}

class _AddBundleDialogState extends ConsumerState<_AddBundleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedPinIds = {};
  String _imageUrl = '';
  PlatformFile? _pickedImage;
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
      final url = await _uploadShopImage(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPinIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pin')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(shopBundleNotifierProvider.notifier).createBundle(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            image: _imageUrl,
            pinIds: _selectedPinIds.toList(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to create bundle')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Bundle'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter a name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 12),
                _PinImagePicker(
                  imageUrl: _imageUrl,
                  pickedFileName: _pickedImage?.name,
                  uploading: _uploadingImage,
                  onPick: _uploadingImage || _submitting
                      ? null
                      : _pickAndUploadImage,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pins',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _BundlePinSelector(
                  selectedPinIds: _selectedPinIds,
                  onToggle: (id) => setState(() {
                    if (!_selectedPinIds.remove(id)) {
                      _selectedPinIds.add(id);
                    }
                  }),
                ),
              ],
            ),
          ),
        ),
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

class _EditBundleDialog extends ConsumerStatefulWidget {
  final String bundleId;
  const _EditBundleDialog({required this.bundleId});

  @override
  ConsumerState<_EditBundleDialog> createState() => _EditBundleDialogState();
}

class _EditBundleDialogState extends ConsumerState<_EditBundleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final Set<String> _selectedPinIds = {};
  String _imageUrl = '';
  PlatformFile? _pickedImage;
  bool _uploadingImage = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final bundle = ref
        .read(shopBundleNotifierProvider)
        .bundles
        .firstWhere((b) => b.id == widget.bundleId);

    _nameController = TextEditingController(text: bundle.name);
    _descriptionController = TextEditingController(text: bundle.description);
    _imageUrl = bundle.image;
    _selectedPinIds.addAll(bundle.pinIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
      final url = await _uploadShopImage(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload image: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPinIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pin')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(shopBundleNotifierProvider.notifier).updateBundle(
            id: widget.bundleId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            image: _imageUrl,
            pinIds: _selectedPinIds.toList(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update bundle')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Bundle'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter a name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 12),
                _PinImagePicker(
                  imageUrl: _imageUrl,
                  pickedFileName: _pickedImage?.name,
                  uploading: _uploadingImage,
                  onPick: _uploadingImage || _submitting
                      ? null
                      : _pickAndUploadImage,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Pins',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _BundlePinSelector(
                  selectedPinIds: _selectedPinIds,
                  onToggle: (id) => setState(() {
                    if (!_selectedPinIds.remove(id)) {
                      _selectedPinIds.add(id);
                    }
                  }),
                ),
              ],
            ),
          ),
        ),
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

// ===========================================================================
// REVIEWS
// ===========================================================================

/// Extracts a human-readable message from a failed review request so the real
/// cause is surfaced instead of a generic "failed" message.
String _reviewErrorMessage(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    final code = e.response?.statusCode;
    if (code == 401 || code == 403) {
      return 'You do not have permission to manage reviews (admin only).';
    }
    return 'Request failed${code != null ? ' ($code)' : ''}. Please try again.';
  }
  return 'Failed to save review. Please try again.';
}

/// A non-interactive 1-5 star row used to render a review's rating.
class _StarRating extends StatelessWidget {
  final int rating;

  const _StarRating({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 18,
          color: filled ? AppColors.accent : Colors.grey,
        );
      }),
    );
  }
}

/// A tappable 1-5 star selector used in the Add Review dialog. No external
/// package — just five tappable star icons.
class _StarPicker extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const _StarPicker({required this.rating, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = i + 1;
        final filled = value <= rating;
        return IconButton(
          tooltip: '$value star${value == 1 ? '' : 's'}',
          onPressed: () => onChanged(value),
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            size: 28,
            color: filled ? AppColors.accent : Colors.grey,
          ),
        );
      }),
    );
  }
}

class _ReviewsTab extends ConsumerStatefulWidget {
  const _ReviewsTab();

  @override
  ConsumerState<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends ConsumerState<_ReviewsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shopReviewNotifierProvider.notifier).fetchReviews();
      // Ensure items are loaded for the Add Review picker.
      if (ref.read(shopItemsNotifierProvider).items.isEmpty) {
        ref.read(shopItemsNotifierProvider.notifier).loadItems();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopReviewNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Reviews (${state.reviews.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => const _AddReviewDialog(),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Review'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: ${state.error}'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => ref
                            .read(shopReviewNotifierProvider.notifier)
                            .fetchReviews(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state.reviews.isEmpty) {
                return const Center(child: Text('No reviews found'));
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: state.reviews.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final review = state.reviews[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.rate_review_outlined, size: 32),
                      title: Row(
                        children: [
                          _StarRating(rating: review.rating),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              review.itemName.isNotEmpty
                                  ? review.itemName
                                  : 'Unknown item',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (review.isAdmin) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (review.userName.isNotEmpty)
                            Text(
                              review.userName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          if (review.text.isNotEmpty) Text(review.text),
                        ],
                      ),
                      isThreeLine: review.userName.isNotEmpty &&
                          review.text.isNotEmpty,
                      trailing: IconButton(
                        tooltip: 'Delete',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete review'),
                              content: const Text(
                                'Are you sure you want to delete this review?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.of(ctx).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              await ref
                                  .read(shopReviewNotifierProvider.notifier)
                                  .deleteReview(review.id);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(_reviewErrorMessage(e))),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 18),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AddReviewDialog extends ConsumerStatefulWidget {
  const _AddReviewDialog();

  @override
  ConsumerState<_AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends ConsumerState<_AddReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _textController = TextEditingController();
  String? _selectedItemId;
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedItemId == null || _selectedItemId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item')),
      );
      return;
    }
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a rating between 1 and 5')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref.read(shopReviewNotifierProvider.notifier).createReview(
            itemId: _selectedItemId!,
            rating: _rating,
            text: _textController.text.trim(),
            reviewerName: _nameController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_reviewErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsState = ref.watch(shopItemsNotifierProvider);
    final items = itemsState.items.where((i) => !i.isDeleted).toList();

    return AlertDialog(
      title: const Text('Add Review'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (itemsState.isLoading && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedItemId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Item',
                      border: OutlineInputBorder(),
                    ),
                    items: items
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              item.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedItemId = value),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please select an item'
                        : null,
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Rating',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                _StarPicker(
                  rating: _rating,
                  onChanged: (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Reviewer name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter a reviewer name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Review text',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter the review text'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
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
