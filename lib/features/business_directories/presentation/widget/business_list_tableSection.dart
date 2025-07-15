import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/business_directories/domain/business_directories_model.dart';
import '../../domain/business_list_model.dart';
import '../../application/business_directories_notifier.dart';

class BusinessListTableSection extends ConsumerStatefulWidget {
  const BusinessListTableSection({super.key});

  @override
  ConsumerState<BusinessListTableSection> createState() =>
      _BusinessListTableSectionState();
}

class _BusinessListTableSectionState extends ConsumerState<BusinessListTableSection> {
  List<BusinessCategory> _categories = []; // Store categories for lookup
  bool _isLoading = false;
  String? _error;
  List<BusinessModel> _businesses = [];
  

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBusinesses();
    });
  }

  Future<void> _fetchBusinesses() async {
    // Also fetch categories from provider state
    final categoryState = ref.read(businessDirectoriesNotifierProvider);
    _categories = categoryState.categories;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ref.read(businessDirectoriesNotifierProvider.notifier).fetchAllBusinesses();
      setState(() {
        _businesses = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build a map from category ID to name for fast lookup
    final Map<String, String> categoryIdToName = {
      for (final c in _categories) c.id: c.name
    };
    return Container(
      width: 1526,
      height: 668,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with tabs and search
          // Table header
          _buildTableHeader(),
          // Table content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _businesses.isEmpty
                        ? const Center(child: Text('No businesses found'))
                        : ListView.builder(
                            itemCount: _businesses.length,
                            itemBuilder: (context, index) {
                              return _buildTableRow(_businesses[index], categoryIdToName);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  
  
  
  Widget _buildTableHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F2ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 30,
            child: Checkbox(
              value: false,
              onChanged: (value) {},
              shape: const CircleBorder(),
              fillColor: MaterialStateProperty.all(Colors.white),
              side: const BorderSide(color: Color(0xFFBCBCBC)),
            ),
          ),
          
          // Business Name
          _buildHeaderCell('Business Name', 390),
          
          // Handle
          _buildHeaderCell('Owner Name', 210),
          
          // Number of Schools
          _buildHeaderCell('Category', 200),
          
          // Join Date
          _buildHeaderCell('Join Date', 150),
          
          // Status
          _buildHeaderCell('Status', 150),
          
          // Actions
          const Expanded(
            child: Text(
              'Actions',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeaderCell(String text, double width) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF333333),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.unfold_more, size: 16, color: Color(0xFF333333)),
        ],
      ),
    );
  }
  
  Widget _buildTableRow(BusinessModel business, Map<String, String> categoryIdToName) {
    // Lookup category name from map; fallback to ID if not found
    final categoryName = categoryIdToName[business.businessCategoryId] ?? business.businessCategoryId;
    // You can adjust these mappings as needed
    final status = business.authorizedUser ? 'Approved' : 'Pending';
    final statusColor = business.authorizedUser
        ? const Color(0xFF80C02A).withOpacity(0.2)
        : const Color(0xFFD59823).withOpacity(0.2);
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 30,
            child: Checkbox(
              value: false,
              onChanged: (value) {},
              shape: const CircleBorder(),
              fillColor: MaterialStateProperty.all(Colors.white),
              side: const BorderSide(color: Color(0xFFBCBCBC)),
            ),
          ),
          // Business Name
          _buildCell(business.businessName, 390, FontWeight.w400),
          // Owner Name
          _buildCell(business.accountOwnerUsername, 210, FontWeight.w400),
          // Category (show name instead of ID)
          _buildCell(categoryName, 200, FontWeight.w700),
          // Join Date (not present in model, show foundedYear)
          _buildCell(business.foundedYear, 150, FontWeight.w400),
          // Status
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(29),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Color(0xFF4D4D4D),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Actions
          Expanded(
            child: Row(
              children: [
                // Edit button
                Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(29),
                  ),
                  child: const Center(
                    child: Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Delete button
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFFC02A2A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCell(String text, double width, FontWeight fontWeight) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF1E293B),
          fontSize: 16,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
