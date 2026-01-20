import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'shop_items_page.dart';

final GoRoute goRouteShop = GoRoute(
  path: ShopPage.routePath,
  name: ShopPage.routeName,
  pageBuilder: (context, state) => MaterialPage(
    key: state.pageKey,
    child: const ShopPage(),
  ),
);

class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  static const String routeName = 'shop';
  static const String routePath = '/shop';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ShopItemsPage();
  }
}

/*

 LEGACY SHOP (Pins / Badges / Kudo Coins)
 Kept commented as requested.

class _AddKudoCoinDialog extends ConsumerStatefulWidget {
  const _AddKudoCoinDialog();

  @override
  ConsumerState<_AddKudoCoinDialog> createState() => _AddKudoCoinDialogState();
}

class _AddKudoCoinDialogState extends ConsumerState<_AddKudoCoinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopKudoCoinNotifierProvider.notifier).createKudoCoin(
            price: int.parse(_priceController.text.trim()),
            description: _descriptionController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create kudo coin')),
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
    _descriptionController = TextEditingController(text: coin.description);
  }

  @override
  void dispose() {
    _priceController.dispose();
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
            description: _descriptionController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update kudo coin')),
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
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopBadgeNotifierProvider.notifier).createBadge(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            price: int.parse(_priceController.text.trim()),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create badge')),
      );
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopBadgeNotifierProvider.notifier).updateBadge(
            id: widget.badgeId,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update badge')),
      );
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

class _ShopPageState extends ConsumerState<ShopPage> {
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
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            TopBar(
              userName: 'Admin',
              userRole: 'Admin',
              notificationCount: '5',
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Shop',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: TabBar(
                tabs: [
                  Tab(text: 'Pins'),
                  Tab(text: 'Badges'),
                  Tab(text: 'Kudo Coins'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Expanded(
              child: TabBarView(
                children: [
                  _PinsTab(),
                  _BadgesTab(),
                  _KudoCoinsTab(),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: state.kudoCoins.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final coin = state.kudoCoins[index];
                  return Card(
                    child: ListTile(
                      title: Text('Price: ${coin.price}'),
                      subtitle: Text(
                        '${coin.description}\nDeleted: ${coin.isDeleted}',
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
                                        title:
                                            const Text('Soft delete kudo coin'),
                                        content: const Text(
                                            'Are you sure you want to soft delete this kudo coin?'),
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
                                          .read(shopKudoCoinNotifierProvider
                                              .notifier)
                                          .softDeleteKudoCoin(coin.id);
                                    }
                                  },
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete kudo coin'),
                                  content: const Text(
                                      'Are you sure you want to permanently delete this kudo coin?'),
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
                          'Are you sure you want to delete all badges?'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: state.badges.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final badge = state.badges[index];
                  return Card(
                    child: ListTile(
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
                                            'Are you sure you want to soft delete this badge?'),
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
                                          .read(shopBadgeNotifierProvider
                                              .notifier)
                                          .softDeleteBadge(badge.id);
                                    }
                                  },
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete badge'),
                                  content: const Text(
                                      'Are you sure you want to permanently delete this badge?'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: state.pins.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final pin = state.pins[index];
                  final pinColor = _parsePinColor(pin.color);
                  return Card(
                    child: ListTile(
                      leading: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: pinColor,
                          border: Border.all(color: Colors.black12),
                        ),
                      ),
                      title: Text('Color: ${pin.color}'),
                      subtitle: Text(
                        'Price: ${pin.price} | Duration: ${pin.duration} days | Deleted: ${pin.isDeleted}',
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          pin.bought
                              ? const Chip(label: Text('Bought'))
                              : const Chip(label: Text('Not bought')),
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
                                            'Are you sure you want to soft delete this pin?'),
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
                                              shopPinNotifierProvider.notifier)
                                          .softDeletePin(pin.id);
                                    }
                                  },
                            icon: const Icon(Icons.remove_circle_outline,
                                size: 18),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete pin'),
                                  content: const Text(
                                      'Are you sure you want to permanently delete this pin?'),
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
  }

  @override
  void dispose() {
    _colorController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
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
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update pin')),
      );
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
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a color'
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
  bool _submitting = false;

  @override
  void dispose() {
    _colorController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(shopPinNotifierProvider.notifier).createPin(
            color: _colorController.text.trim(),
            price: int.parse(_priceController.text.trim()),
            duration: int.parse(_durationController.text.trim()),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create pin')),
      );
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
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter a color'
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

*/
