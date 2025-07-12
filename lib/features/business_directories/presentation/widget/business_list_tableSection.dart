import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BusinessListTableSection extends ConsumerStatefulWidget {
  const BusinessListTableSection({super.key});

  @override
  ConsumerState<BusinessListTableSection> createState() =>
      _BusinessListTableSectionState();
}

class _BusinessListTableSectionState
    extends ConsumerState<BusinessListTableSection> {
  // Sample data - replace with your actual data
  final List<Map<String, dynamic>> _businesses = [
    {
      'name': 'Community name',
      'handle': '@foodie',
      'schools': '12,305',
      'joinDate': '12.12.2022',
      'status': 'Approved',
      'statusColor': const Color(0xFF80C02A).withOpacity(0.2),
    },
    {
      'name': 'Community name',
      'handle': '@legalgeek',
      'schools': '12,305',
      'joinDate': '12.12.2022',
      'status': 'Approved',
      'statusColor': const Color(0xFF80C02A).withOpacity(0.2),
    },
    {
      'name': 'Community name',
      'handle': '@legalgeek',
      'schools': '12,305',
      'joinDate': '12.12.2022',
      'status': 'Pending',
      'statusColor': const Color(0xFFD59823).withOpacity(0.2),
    },
    {
      'name': 'Community name',
      'handle': '@legalgeek',
      'schools': '12,305',
      'joinDate': '12.12.2022',
      'status': 'Rejected',
      'statusColor': const Color(0xFFCC1919).withOpacity(0.2),
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          _buildHeader(),
          
          // Table header
          _buildTableHeader(),
          
          // Table content
          Expanded(
            child: ListView.builder(
              itemCount: _businesses.length,
              itemBuilder: (context, index) {
                return _buildTableRow(_businesses[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Tabs
          Container(
            width: 327,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F2ED),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              children: [
                // Business Category Tab
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF24439B),
                      borderRadius: BorderRadius.circular(35),
                    ),
                    child: const Center(
                      child: Text(
                        'Business List',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Business Category Tab (Inactive)
                const Expanded(
                  child: Center(
                    child: Text(
                      'Business Category',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search and filter
          Row(
            children: [
              // Search bar
              Container(
                width: 390,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6EF),
                  borderRadius: BorderRadius.circular(35),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, size: 16, color: Color(0xFF333333)),
                    SizedBox(width: 12),
                    Text(
                      'Search for Business Lists....',
                      style: TextStyle(
                        color: Color(0xFF333333),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 24),
              
              // Sort and filter buttons
              Row(
                children: [
                  // Sort button
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF333333)),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(42),
                        right: Radius.circular(0),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sort, size: 14, color: Color(0xFF333333)),
                        SizedBox(width: 8),
                        Text(
                          'Sort',
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Filter button
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF333333),
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(0),
                        right: Radius.circular(42),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_alt_outlined, 
                            size: 14, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Filter',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                child: const Icon(Icons.delete_outline, 
                    size: 16, color: Colors.white),
              ),
            ],
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
          _buildHeaderCell('Handle', 210),
          
          // Number of Schools
          _buildHeaderCell('Number of Schools', 200),
          
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
  
  Widget _buildTableRow(Map<String, dynamic> business) {
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
          _buildCell(business['name'], 390, FontWeight.w400),
          
          // Handle
          _buildCell(business['handle'], 210, FontWeight.w400),
          
          // Number of Schools
          _buildCell(business['schools'], 200, FontWeight.w700),
          
          // Join Date
          _buildCell(business['joinDate'], 150, FontWeight.w400),
          
          // Status
          Container(
            width: 150,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            decoration: BoxDecoration(
              color: business['statusColor'] ?? Colors.grey[200],
              borderRadius: BorderRadius.circular(29),
            ),
            child: Text(
              business['status'],
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
                  child: const Icon(Icons.delete_outline, 
                      size: 16, color: Colors.white),
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
