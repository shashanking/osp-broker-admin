import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/core/widgets/layout/top_bar.dart';
import 'package:osp_broker_admin/features/orders/application/orders_notifier.dart';
import 'package:osp_broker_admin/features/orders/domain/order_model.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  String _typeFilter = 'ALL';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Column(
        children: [
          const TopBar(userName: 'Admin', userRole: 'Admin', notificationCount: '5'),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load orders: $e')),
              data: (all) => _buildContent(all),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<OrderModel> all) {
    final q = _search.text.trim().toLowerCase();
    final filtered = all.where((o) {
      if (_typeFilter != 'ALL' && o.type != _typeFilter) return false;
      if (q.isEmpty) return true;
      return o.itemLabel.toLowerCase().contains(q) ||
          (o.buyerEmail ?? '').toLowerCase().contains(q) ||
          (o.buyerName ?? '').toLowerCase().contains(q) ||
          o.transactionId.toLowerCase().contains(q);
    }).toList();

    // Revenue totals per currency (only COMPLETED orders).
    final Map<String, double> revenueByCurrency = {};
    for (final o in all) {
      if (o.status.toUpperCase() == 'COMPLETED') {
        revenueByCurrency.update(
            o.currency.toUpperCase(), (v) => v + o.amount,
            ifAbsent: () => o.amount);
      }
    }
    final revenueText = revenueByCurrency.entries
        .map((e) => '${e.value.toStringAsFixed(0)} ${e.key}')
        .join('  ·  ');

    final types = ['ALL', 'MEMBERSHIP', 'SHOP_ITEM', 'PIN', 'BADGE', 'KUDO_COIN'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Color(0xFF24439B), size: 26),
              const SizedBox(width: 10),
              const Text('Orders & Receipts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => ref.read(ordersProvider.notifier).refresh(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _summary('Total orders', '${all.length}', Icons.shopping_bag_outlined,
                  const Color(0xFF24439B)),
              _summary('Revenue (completed)',
                  revenueText.isEmpty ? '—' : revenueText, Icons.payments_outlined,
                  const Color(0xFF2EC4B6)),
            ],
          ),
          const SizedBox(height: 20),
          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search item, buyer email, or transaction id…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _typeFilter,
                items: types
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t == 'ALL' ? 'All types' : t),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _typeFilter = v ?? 'ALL'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
            ),
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('No orders found')),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Type')),
                        DataColumn(label: Text('Item')),
                        DataColumn(label: Text('Buyer')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Transaction')),
                      ],
                      rows: filtered.map(_row).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  DataRow _row(OrderModel o) {
    return DataRow(cells: [
      DataCell(Text(_fmtDate(o.createdAt))),
      DataCell(_typeChip(o)),
      DataCell(ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(o.itemLabel, overflow: TextOverflow.ellipsis),
      )),
      DataCell(ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((o.buyerName ?? '').isNotEmpty)
              Text(o.buyerName!, overflow: TextOverflow.ellipsis),
            Text(o.buyerEmail ?? '—',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      )),
      DataCell(Text('${o.amount.toStringAsFixed(2)} ${o.currency.toUpperCase()}',
          style: const TextStyle(fontWeight: FontWeight.w600))),
      DataCell(_statusChip(o.status)),
      DataCell(SelectableText(o.transactionId,
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
    ]);
  }

  Widget _typeChip(OrderModel o) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF24439B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(o.typeLabel,
          style: const TextStyle(
              fontSize: 12, color: Color(0xFF24439B), fontWeight: FontWeight.w600)),
    );
  }

  Widget _statusChip(String status) {
    final s = status.toUpperCase();
    final color = s == 'COMPLETED'
        ? const Color(0xFF2E9E4F)
        : (s == 'PENDING' ? const Color(0xFFD59823) : const Color(0xFFC02A2A));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _summary(String label, String value, IconData icon, Color color) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    final l = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)} ${two(l.hour)}:${two(l.minute)}';
  }
}
