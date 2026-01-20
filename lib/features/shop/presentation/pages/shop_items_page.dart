import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/constants/app_colors.dart';
import 'package:osp_broker_admin/core/utils/csv_export.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/features/shop/application/shop_items_notifier.dart';
import 'package:osp_broker_admin/features/shop/domain/shop_item_model.dart';

enum _ShopRange {
  day,
  sevenDays,
  thirtyDays,
  yearly,
}

enum ShopItemsTab {
  all,
  platform,
  product,
  service,
}

enum _ShopSortField {
  name,
  price,
  stock,
  updatedAt,
}

enum _StockFilter {
  any,
  inStock,
  outOfStock,
  lowStock,
}

class ShopItemsPage extends ConsumerStatefulWidget {
  const ShopItemsPage({super.key});

  @override
  ConsumerState<ShopItemsPage> createState() => _ShopItemsPageState();
}

class _ShopItemsPageState extends ConsumerState<ShopItemsPage> {
  final TextEditingController _searchController = TextEditingController();

  ShopItemsTab _selectedTab = ShopItemsTab.all;
  int _rowsPerPage = 10;
  int _page = 1;
  _ShopRange _range = _ShopRange.sevenDays;

  _ShopSortField _sortField = _ShopSortField.updatedAt;
  bool _sortAscending = false;

  String? _filterCategoryId;
  _StockFilter _stockFilter = _StockFilter.any;
  double? _minPrice;
  double? _maxPrice;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _safePrice(dynamic v) {
    if (v is num) return v.toDouble();
    return 0;
  }

  DateTime _safeUpdatedAt(ShopItemModel item) {
    return item.updatedAt ??
        item.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool get _hasActiveFilters {
    return _filterCategoryId != null ||
        _stockFilter != _StockFilter.any ||
        _minPrice != null ||
        _maxPrice != null;
  }

  List<ShopItemModel> _applyFilters(List<ShopItemModel> items) {
    final query = _searchController.text.trim().toLowerCase();

    Iterable<ShopItemModel> filtered = items;

    if (_selectedTab != ShopItemsTab.all) {
      final categoryName = switch (_selectedTab) {
        ShopItemsTab.platform => 'Platform',
        ShopItemsTab.product => 'Product',
        ShopItemsTab.service => 'Service',
        ShopItemsTab.all => 'All',
      };
      filtered = filtered.where(
          (e) => e.category?.name.toLowerCase() == categoryName.toLowerCase());
    }

    if (query.isNotEmpty) {
      filtered = filtered.where(
        (e) =>
            e.name.toLowerCase().contains(query) ||
            e.id.toLowerCase().contains(query) ||
            (e.category?.name.toLowerCase().contains(query) ?? false),
      );
    }

    if (_filterCategoryId != null) {
      filtered = filtered.where((e) => e.categoryId == _filterCategoryId);
    }

    if (_stockFilter != _StockFilter.any) {
      filtered = filtered.where((e) {
        final stock = e.stock;
        return switch (_stockFilter) {
          _StockFilter.any => true,
          _StockFilter.inStock => stock > 0,
          _StockFilter.outOfStock => stock <= 0,
          _StockFilter.lowStock => stock > 0 && stock < 10,
        };
      });
    }

    if (_minPrice != null) {
      filtered = filtered.where((e) => _safePrice(e.price) >= _minPrice!);
    }

    if (_maxPrice != null) {
      filtered = filtered.where((e) => _safePrice(e.price) <= _maxPrice!);
    }

    final list = filtered.toList();
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case _ShopSortField.name:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case _ShopSortField.price:
          cmp = _safePrice(a.price).compareTo(_safePrice(b.price));
          break;
        case _ShopSortField.stock:
          cmp = a.stock.compareTo(b.stock);
          break;
        case _ShopSortField.updatedAt:
          cmp = _safeUpdatedAt(a).compareTo(_safeUpdatedAt(b));
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  Future<void> _openSortSheet() async {
    final result =
        await showModalBottomSheet<({_ShopSortField field, bool asc})>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        var field = _sortField;
        var asc = _sortAscending;

        String label(_ShopSortField f) {
          return switch (f) {
            _ShopSortField.name => 'Name',
            _ShopSortField.price => 'Price',
            _ShopSortField.stock => 'Stock',
            _ShopSortField.updatedAt => 'Last Update',
          };
        }

        return StatefulBuilder(
          builder: (context, setLocal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sort',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  ..._ShopSortField.values.map(
                    (f) => RadioListTile<_ShopSortField>(
                      value: f,
                      groupValue: field,
                      onChanged: (v) {
                        if (v == null) return;
                        setLocal(() => field = v);
                      },
                      title: Text(label(f)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: asc,
                    onChanged: (v) => setLocal(() => asc = v),
                    title: Text(asc ? 'Ascending' : 'Descending'),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context)
                              .pop((field: field, asc: asc)),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;
    setState(() {
      _sortField = result.field;
      _sortAscending = result.asc;
      _page = 1;
    });
  }

  Future<void> _openFilterDialog(List<ShopCategoryModel> categories) async {
    final minController =
        TextEditingController(text: _minPrice?.toString() ?? '');
    final maxController =
        TextEditingController(text: _maxPrice?.toString() ?? '');

    final result = await showDialog<
        ({
          String? categoryId,
          _StockFilter stock,
          double? minPrice,
          double? maxPrice,
        })>(
      context: context,
      builder: (context) {
        var categoryId = _filterCategoryId;
        var stock = _stockFilter;

        double? parseDouble(String v) {
          final t = v.trim();
          if (t.isEmpty) return null;
          return double.tryParse(t);
        }

        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Filter'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: categoryId,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All categories'),
                          ),
                          ...categories.map(
                            (c) => DropdownMenuItem<String>(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (v) => setLocal(() => categoryId = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<_StockFilter>(
                        value: stock,
                        decoration: const InputDecoration(
                          labelText: 'Stock',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: _StockFilter.any, child: Text('Any')),
                          DropdownMenuItem(
                              value: _StockFilter.inStock,
                              child: Text('In stock')),
                          DropdownMenuItem(
                              value: _StockFilter.lowStock,
                              child: Text('Low stock (<10)')),
                          DropdownMenuItem(
                              value: _StockFilter.outOfStock,
                              child: Text('Out of stock')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setLocal(() => stock = v);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Min Price',
                                border: OutlineInputBorder(),
                                prefixText: '\$ ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Max Price',
                                border: OutlineInputBorder(),
                                prefixText: '\$ ',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    minController.dispose();
                    maxController.dispose();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    minController.text = '';
                    maxController.text = '';
                    setLocal(() {
                      categoryId = null;
                      stock = _StockFilter.any;
                    });
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final minP = parseDouble(minController.text);
                    final maxP = parseDouble(maxController.text);
                    minController.dispose();
                    maxController.dispose();
                    Navigator.of(context).pop((
                      categoryId: categoryId,
                      stock: stock,
                      minPrice: minP,
                      maxPrice: maxP,
                    ));
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _filterCategoryId = result.categoryId;
      _stockFilter = result.stock;
      _minPrice = result.minPrice;
      _maxPrice = result.maxPrice;
      _page = 1;
    });
  }

  List<ShopItemModel> _paged(List<ShopItemModel> items) {
    final start = (_page - 1) * _rowsPerPage;
    if (start >= items.length) return const [];
    return items.sublist(start, min(start + _rowsPerPage, items.length));
  }

  int _totalPages(int totalItems) {
    return max(1, (totalItems / _rowsPerPage).ceil());
  }

  String _getCategoryName(ShopItemModel item) {
    return item.category?.name ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopItemsNotifierProvider);
    final allItems = _applyFilters(state.items);
    final pagedItems = _paged(allItems);
    final totalPages = _totalPages(allItems.length);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          TopBar(
            userName: 'Admin',
            userRole: 'Admin',
            notificationCount: '5',
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShopManagementHeader(
                    selectedRange: _range,
                    onRangeChanged: (r) => setState(() => _range = r),
                    onExportCsv: () async {
                      final rows = allItems
                          .map(
                            (e) => <String, Object?>{
                              'name': e.name,
                              'id': e.id,
                              'category': _getCategoryName(e),
                              'price': e.price,
                              'description': e.description,
                              'stock': e.stock,
                              'updatedAt': e.updatedAt,
                            },
                          )
                          .toList();
                      await exportCsv(fileName: 'shop_items.csv', rows: rows);
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 950;
                      final cards = <Widget>[
                        _AddNewShopItemCard(
                          onAdd: () async {
                            final result =
                                await showDialog<_ShopItemDialogResult>(
                              context: context,
                              builder: (context) => const _AddShopItemDialog(),
                            );
                            if (result != null && mounted) {
                              try {
                                await ref
                                    .read(shopItemsNotifierProvider.notifier)
                                    .createItem(
                                      name: result.name,
                                      description: result.description,
                                      price: result.price,
                                      stock: result.stock,
                                      categoryId: result.categoryId,
                                    );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        _StatCard(
                          title: 'Total Items',
                          value: '${state.items.length}',
                          accent: const Color(0xFF1E3A8A),
                        ),
                        _StatCard(
                          title: 'Total Stock',
                          value:
                              '${state.items.fold<int>(0, (sum, e) => sum + e.stock)}',
                          accent: const Color(0xFF1E3A8A),
                        ),
                        _StatCard(
                          title: 'Low Stock',
                          value:
                              '${state.items.where((e) => e.stock < 10).length}',
                          accent: const Color(0xFF1E3A8A),
                        ),
                      ];

                      if (isNarrow) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: cards
                              .map(
                                (c) => SizedBox(
                                  width: min(
                                    420,
                                    (constraints.maxWidth - 16) / 2,
                                  ),
                                  child: c,
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Row(
                        children: cards
                            .map(
                              (c) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: c,
                                ),
                              ),
                            )
                            .toList()
                          ..removeLast(),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _TabsBar(
                    selected: _selectedTab,
                    onChanged: (t) {
                      setState(() {
                        _selectedTab = t;
                        _page = 1;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 820;
                      final search = SizedBox(
                        width: isNarrow ? double.infinity : 340,
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() => _page = 1),
                          decoration: InputDecoration(
                            hintText: 'Search for Shop Items...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.shade300,
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      );

                      final actions = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PillButton(
                            onPressed: _openSortSheet,
                            icon: Icons.sort,
                            label: 'Sort',
                            filled: true,
                          ),
                          const SizedBox(width: 10),
                          _PillButton(
                            onPressed: () =>
                                _openFilterDialog(state.categories),
                            icon: Icons.filter_alt_outlined,
                            label: 'Filter',
                            filled: _hasActiveFilters,
                          ),
                          const SizedBox(width: 10),
                          _PillButton(
                            onPressed: () => ref
                                .read(shopItemsNotifierProvider.notifier)
                                .refresh(),
                            icon: Icons.refresh,
                            label: 'Refresh',
                            filled: false,
                          ),
                        ],
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            search,
                            const SizedBox(height: 12),
                            actions,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          search,
                          const Spacer(),
                          actions,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _TableHeaderRow(
                          totalCount: allItems.length,
                          rowsPerPage: _rowsPerPage,
                          onRowsPerPageChanged: (v) {
                            setState(() {
                              _rowsPerPage = v;
                              _page = 1;
                            });
                          },
                        ),
                        const Divider(height: 1),
                        if (state.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Text(state.error!),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () => ref
                                      .read(shopItemsNotifierProvider.notifier)
                                      .refresh(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        else if (pagedItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('No items found.'),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowHeight: 44,
                              dataRowMinHeight: 56,
                              dataRowMaxHeight: 56,
                              columns: const [
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Price')),
                                DataColumn(label: Text('Stock')),
                                DataColumn(label: Text('Category')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: pagedItems
                                  .map(
                                    (e) => DataRow(
                                      cells: [
                                        DataCell(
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF2563EB),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                e.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(
                                            '#${e.id.substring(0, min(8, e.id.length))}')),
                                        DataCell(
                                          Text(
                                            '\$${e.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${e.stock}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: e.stock < 10
                                                  ? Colors.red
                                                  : Colors.black,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          _CategoryPill(
                                            label: _getCategoryName(e),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _ManagePillButton(
                                                onPressed: () async {
                                                  final result =
                                                      await showDialog<
                                                          _ShopItemDialogResult>(
                                                    context: context,
                                                    builder: (context) =>
                                                        _AddShopItemDialog(
                                                      initialItem: e,
                                                    ),
                                                  );

                                                  if (result == null ||
                                                      !mounted) return;
                                                  try {
                                                    await ref
                                                        .read(
                                                            shopItemsNotifierProvider
                                                                .notifier)
                                                        .updateItem(
                                                          id: e.id,
                                                          name: result.name,
                                                          description: result
                                                              .description,
                                                          price: result.price,
                                                          stock: result.stock,
                                                          categoryId:
                                                              result.categoryId,
                                                        );
                                                  } catch (err) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Error: $err')),
                                                      );
                                                    }
                                                  }
                                                },
                                                label: 'Manage',
                                              ),
                                              const SizedBox(width: 8),
                                              _CircleIconButton(
                                                onPressed: () async {
                                                  final confirm =
                                                      await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                            'Delete item'),
                                                        content: Text(
                                                          'Are you sure you want to delete "${e.name}"?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(false),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  const Color(
                                                                      0xFFDC2626),
                                                              foregroundColor:
                                                                  Colors.white,
                                                            ),
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(true),
                                                            child: const Text(
                                                                'Delete'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (confirm != true ||
                                                      !mounted) return;
                                                  try {
                                                    await ref
                                                        .read(
                                                            shopItemsNotifierProvider
                                                                .notifier)
                                                        .softDeleteItem(e.id);
                                                  } catch (err) {
                                                    if (mounted) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                            content: Text(
                                                                'Error: $err')),
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: Icons.delete,
                                                background:
                                                    const Color(0xFFDC2626),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        const Divider(height: 1),
                        _PaginationBar(
                          page: _page,
                          totalPages: totalPages,
                          onPrev:
                              _page <= 1 ? null : () => setState(() => _page--),
                          onNext: _page >= totalPages
                              ? null
                              : () => setState(() => _page++),
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
}

class _ShopItemDialogResult {
  final String name;
  final String description;
  final double price;
  final int stock;
  final String categoryId;

  _ShopItemDialogResult({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.categoryId,
  });
}

class _TabsBar extends StatelessWidget {
  final ShopItemsTab selected;
  final ValueChanged<ShopItemsTab> onChanged;

  const _TabsBar({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, ShopItemsTab value) {
      final isSelected = selected == value;
      return InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF111827) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isSelected ? const Color(0xFF111827) : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        tab('All Items', ShopItemsTab.all),
        tab('Platform Items', ShopItemsTab.platform),
        tab('Product Items', ShopItemsTab.product),
        tab('Service Items', ShopItemsTab.service),
      ],
    );
  }
}

class _ShopManagementHeader extends StatelessWidget {
  final _ShopRange selectedRange;
  final ValueChanged<_ShopRange> onRangeChanged;
  final VoidCallback onExportCsv;

  const _ShopManagementHeader({
    required this.selectedRange,
    required this.onRangeChanged,
    required this.onExportCsv,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, _ShopRange range) {
      final selected = selectedRange == range;
      return InkWell(
        onTap: () => onRangeChanged(range),
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 950;

        final right = Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: onExportCsv,
              child: const Text(
                'Export CSV',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            chip('1 day', _ShopRange.day),
            chip('7 days', _ShopRange.sevenDays),
            chip('30 days', _ShopRange.thirtyDays),
            chip('Yearly', _ShopRange.yearly),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Shop Management',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              right,
            ],
          );
        }

        return Row(
          children: [
            const Text(
              'Shop Management',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            right,
          ],
        );
      },
    );
  }
}

class _AddNewShopItemCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _AddNewShopItemCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E3A8A),
            Color(0xFF0891B2),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Add New\nShop Item',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          InkWell(
            onTap: onAdd,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool filled;

  const _PillButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? const Color(0xFF111827) : Colors.white;
    final fg = filled ? Colors.white : const Color(0xFF111827);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color background;

  const _CircleIconButton({
    required this.onPressed,
    required this.icon,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _ManagePillButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _ManagePillButton({required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;

  const _CategoryPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accent;

  const _StatCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  final int totalCount;
  final int rowsPerPage;
  final ValueChanged<int> onRowsPerPageChanged;

  const _TableHeaderRow({
    required this.totalCount,
    required this.rowsPerPage,
    required this.onRowsPerPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Items',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$totalCount',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Spacer(),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: rowsPerPage,
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 / page')),
                DropdownMenuItem(value: 10, child: Text('10 / page')),
                DropdownMenuItem(value: 20, child: Text('20 / page')),
              ],
              onChanged: (v) {
                if (v == null) return;
                onRowsPerPageChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Page $page of $totalPages',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Previous'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

class _AddShopItemDialog extends ConsumerStatefulWidget {
  final ShopItemModel? initialItem;

  const _AddShopItemDialog({
    this.initialItem,
  });

  @override
  ConsumerState<_AddShopItemDialog> createState() => _AddShopItemDialogState();
}

class _AddShopItemDialogState extends ConsumerState<_AddShopItemDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _categoryId;
  bool _isCreatingCategory = false;
  final _categoryNameController = TextEditingController();
  final _categoryDescController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialItem;
    if (initial != null) {
      _nameController.text = initial.name;
      _priceController.text = initial.price.toStringAsFixed(2);
      _stockController.text = initial.stock.toString();
      _descriptionController.text = initial.description;
      _categoryId = initial.categoryId;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _categoryNameController.dispose();
    _categoryDescController.dispose();
    super.dispose();
  }

  Future<void> _createCategory() async {
    final name = _categoryNameController.text.trim();
    final desc = _categoryDescController.text.trim();
    if (name.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill category name and description')),
      );
      return;
    }

    try {
      final category =
          await ref.read(shopItemsNotifierProvider.notifier).createCategory(
                name: name,
                description: desc,
              );
      setState(() {
        _categoryId = category.id;
        _isCreatingCategory = false;
        _categoryNameController.clear();
        _categoryDescController.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialItem != null;
    final state = ref.watch(shopItemsNotifierProvider);
    final categories = state.categories;

    // Set default category if available and not set
    if (_categoryId == null && categories.isNotEmpty) {
      _categoryId = categories.first.id;
    }

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Item' : 'Add Item',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter item name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  if (_isCreatingCategory) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Create New Category',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _categoryNameController,
                            decoration: const InputDecoration(
                              labelText: 'Category Name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _categoryDescController,
                            decoration: const InputDecoration(
                              labelText: 'Category Description',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () =>
                                    setState(() => _isCreatingCategory = false),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: state.isLoadingCategories
                                    ? null
                                    : _createCategory,
                                child: state.isLoadingCategories
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Create'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: categories.any((c) => c.id == _categoryId)
                                ? _categoryId
                                : null,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                            ),
                            items: categories
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _categoryId = v);
                            },
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Please select a category'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _isCreatingCategory = true),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('New'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                    if (categories.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'No categories found. Click "New" to create one.',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(),
                            prefixText: '\$ ',
                          ),
                          validator: (v) {
                            final parsed = double.tryParse((v ?? '').trim());
                            if (parsed == null) return 'Enter valid price';
                            if (parsed < 0) return 'Price cannot be negative';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stock',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final parsed = int.tryParse((v ?? '').trim());
                            if (parsed == null) return 'Enter valid stock';
                            if (parsed < 0) return 'Stock cannot be negative';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter description'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!_formKey.currentState!.validate()) return;
                            if (_categoryId == null ||
                                !categories.any((c) => c.id == _categoryId)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Please select a valid category')),
                              );
                              return;
                            }

                            final result = _ShopItemDialogResult(
                              name: _nameController.text.trim(),
                              description: _descriptionController.text.trim(),
                              price: double.parse(_priceController.text.trim()),
                              stock: int.parse(_stockController.text.trim()),
                              categoryId: _categoryId!,
                            );
                            Navigator.of(context).pop(result);
                          },
                          child: Text(isEditing ? 'Save' : 'Create'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
