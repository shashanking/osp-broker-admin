import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';
import 'package:osp_broker_admin/features/users/data/models/user_pin_model.dart';
import 'package:osp_broker_admin/features/users/presentation/pages/pin_management_page.dart';
import 'package:osp_broker_admin/features/users/presentation/widgets/assign_pin_dialog.dart';

class UserPinsSection extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const UserPinsSection({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<UserPinsSection> createState() => _UserPinsSectionState();
}

class _UserPinsSectionState extends ConsumerState<UserPinsSection> {
  List<UserPinModel> _userPins = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPins();
  }

  Future<void> _loadUserPins() async {
    setState(() => _isLoading = true);
    try {
      final pins = await ref
          .read(userNotifierProvider.notifier)
          .fetchUserPins(widget.userId);
      if (mounted) {
        setState(() {
          _userPins = pins;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAssignPinDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) =>
          AssignPinDialog(userId: widget.userId, userName: widget.userName),
    );

    if (result == true) {
      _loadUserPins(); // Reload pins after successful assignment
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.push_pin, color: Color(0xFF24439B), size: 24),
              const SizedBox(width: 8),
              const Text(
                'User Pins',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (!_isLoading) ...[
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinManagementPage(),
                      ),
                    ).then((_) => _loadUserPins());
                  },
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Manage Pin Types'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _showAssignPinDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Pins'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24439B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_userPins.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.push_pin_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No pins found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _showAssignPinDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add First Pin'),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: _userPins.map((pin) => _buildPinCard(pin)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPinCard(UserPinModel pin) {
    final isExpired = pin.isExpired;
    final isActive = pin.isActive;
    final pinIdShort = (pin.pinId.isNotEmpty && pin.pinId.length >= 8)
        ? '${pin.pinId.substring(0, 8)}...'
        : (pin.pinId.isNotEmpty ? pin.pinId : 'N/A');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.red.shade50
            : isActive
                ? Colors.green.shade50
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? Colors.red.shade200
              : isActive
                  ? Colors.green.shade200
                  : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.push_pin,
                      size: 20,
                      color: isExpired
                          ? Colors.red.shade700
                          : isActive
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pin ID: $pinIdShort',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isExpired
                      ? Colors.red
                      : isActive
                          ? Colors.green
                          : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isExpired
                      ? 'EXPIRED'
                      : isActive
                          ? 'ACTIVE'
                          : 'INACTIVE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(Icons.numbers, 'Count: ${pin.count}'),
              ),
              Expanded(
                child: _buildInfoChip(
                  Icons.attach_money,
                  '\$${pin.totalCost.toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoChip(
            Icons.calendar_today,
            'Expires: ${_formatDate(pin.expirationDate)}',
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
