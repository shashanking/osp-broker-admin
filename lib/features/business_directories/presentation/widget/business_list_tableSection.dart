import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/business_directories/domain/business_directories_model.dart';
import 'dart:math' as math;
import '../../domain/business_list_model.dart';
import '../../application/business_directories_notifier.dart';

class BusinessListTableSection extends ConsumerStatefulWidget {
  const BusinessListTableSection({super.key});

  @override
  ConsumerState<BusinessListTableSection> createState() =>
      _BusinessListTableSectionState();
}

class _BusinessListTableSectionState
    extends ConsumerState<BusinessListTableSection> {
  List<BusinessCategory> _categories = []; // Store categories for lookup
  bool _isLoading = false;
  String? _error;
  List<BusinessModel> _businesses = [];
  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _horizontalBodyController = ScrollController();
  final ScrollController _verticalLeftController = ScrollController();
  final ScrollController _verticalRightController = ScrollController();

  bool _isSyncingScroll = false;

  static const double _colCheckbox = 40;
  static const double _colIndex = 60;
  static const double _colBusinessName = 220;
  static const double _colOwner = 150;
  static const double _colCategory = 160;
  static const double _colIndustry = 160;
  static const double _colCompanyType = 160;
  static const double _colIsp = 80;
  static const double _colSlogan = 220;
  static const double _colJoinDate = 120;
  static const double _colHqCity = 140;
  static const double _colHqCountry = 140;
  static const double _colRevenue = 140;
  static const double _colEmployees = 110;
  static const double _colProducts = 220;
  static const double _colServices = 220;
  static const double _colServingAreas = 220;
  static const double _colWebsite = 240;
  static const double _colStatus = 160;

  double _minLeftTableWidth() {
    return 32 +
        _colCheckbox +
        _colIndex +
        _colBusinessName +
        _colOwner +
        _colCategory +
        _colIndustry +
        _colCompanyType +
        _colIsp +
        _colSlogan +
        _colJoinDate +
        _colHqCity +
        _colHqCountry +
        _colRevenue +
        _colEmployees +
        _colProducts +
        _colServices +
        _colServingAreas +
        _colWebsite +
        _colStatus;
  }

  String _previewList(List<String> items) {
    if (items.isEmpty) return '-';
    final shown = items.take(2).toList();
    final remaining = items.length - shown.length;
    final base = shown.join(', ');
    if (remaining <= 0) return base;
    return '$base +$remaining';
  }

  String _formatListMultiline(List<String> items) {
    if (items.isEmpty) return '-';
    return items.map((e) => '• $e').join('\n');
  }

  void _showBusinessDetails(
    BusinessModel business,
    Map<String, String> categoryIdToName,
  ) {
    final categoryName = categoryIdToName[business.businessCategoryId] ??
        business.businessCategoryId;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          business.businessName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('Owner', business.accountOwnerUsername),
                          _detailRow('Business ID', business.id),
                          _detailRow('Admin ID', business.businessAdminId),
                          _detailRow('Category', categoryName),
                          _detailRow('Industry', business.industry),
                          _detailRow('Company Type', business.companyType),
                          _detailRow('Founded Year', business.foundedYear),
                          _detailRow(
                              'Last Year Revenue', business.lastYearRevenue),
                          _detailRow(
                              'Employees', business.employeeCount.toString()),
                          _detailRow('ISP', business.isIsp ? 'Yes' : 'No'),
                          _detailRow('Status',
                              business.authorizedUser ? 'Approved' : 'Pending'),
                          const SizedBox(height: 12),
                          _detailBlock('Slogan', business.slogan),
                          _detailBlock('Mission', business.mission),
                          _detailBlock('History', business.history),
                          const SizedBox(height: 12),
                          _detailRow('HQ City', business.hqLocation.city),
                          _detailRow('HQ Country', business.hqLocation.country),
                          _detailBlock(
                              'HQ Address', business.hqLocation.address),
                          const SizedBox(height: 12),
                          _detailBlock(
                            'Products',
                            _formatListMultiline(business.products),
                          ),
                          _detailBlock(
                            'Services',
                            _formatListMultiline(business.services),
                          ),
                          _detailBlock(
                            'Serving Areas',
                            _formatListMultiline(business.servingAreas),
                          ),
                          _detailBlock(
                            'Key People',
                            _formatListMultiline(business.keyPeople),
                          ),
                          _detailBlock(
                            'Ownership',
                            _formatListMultiline(business.ownership),
                          ),
                          _detailBlock(
                            'Acquisitions',
                            _formatListMultiline(business.acquisitions),
                          ),
                          _detailBlock(
                            'Strategic Partners',
                            _formatListMultiline(business.strategicPartners),
                          ),
                          _detailBlock(
                            'Website Links',
                            _formatListMultiline(business.websiteLinks),
                          ),
                          _detailRow('Sale Deck URL', business.saleDeckUrl),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBlock(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6EF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7E2D8)),
            ),
            child: SelectableText(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Color(0xFF1E293B), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _horizontalHeaderController.addListener(_syncHorizontalFromHeader);
    _horizontalBodyController.addListener(_syncHorizontalFromBody);
    _verticalLeftController.addListener(_syncVerticalScrollFromLeft);
    _verticalRightController.addListener(_syncVerticalScrollFromRight);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBusinesses();
    });
  }

  void _syncHorizontalFromHeader() {
    if (_isSyncingScroll) return;
    if (!_horizontalBodyController.hasClients) return;

    _isSyncingScroll = true;
    _horizontalBodyController.jumpTo(
      _horizontalHeaderController.offset.clamp(
        _horizontalBodyController.position.minScrollExtent,
        _horizontalBodyController.position.maxScrollExtent,
      ),
    );
    _isSyncingScroll = false;
  }

  void _syncHorizontalFromBody() {
    if (_isSyncingScroll) return;
    if (!_horizontalHeaderController.hasClients) return;

    _isSyncingScroll = true;
    _horizontalHeaderController.jumpTo(
      _horizontalBodyController.offset.clamp(
        _horizontalHeaderController.position.minScrollExtent,
        _horizontalHeaderController.position.maxScrollExtent,
      ),
    );
    _isSyncingScroll = false;
  }

  void _syncVerticalScrollFromLeft() {
    if (_isSyncingScroll) return;
    if (!_verticalRightController.hasClients) return;

    _isSyncingScroll = true;
    _verticalRightController.jumpTo(
      _verticalLeftController.offset.clamp(
        _verticalRightController.position.minScrollExtent,
        _verticalRightController.position.maxScrollExtent,
      ),
    );
    _isSyncingScroll = false;
  }

  void _syncVerticalScrollFromRight() {
    if (_isSyncingScroll) return;
    if (!_verticalLeftController.hasClients) return;

    _isSyncingScroll = true;
    _verticalLeftController.jumpTo(
      _verticalRightController.offset.clamp(
        _verticalLeftController.position.minScrollExtent,
        _verticalLeftController.position.maxScrollExtent,
      ),
    );
    _isSyncingScroll = false;
  }

  @override
  void dispose() {
    _horizontalHeaderController
      ..removeListener(_syncHorizontalFromHeader)
      ..dispose();
    _horizontalBodyController
      ..removeListener(_syncHorizontalFromBody)
      ..dispose();
    _verticalLeftController
      ..removeListener(_syncVerticalScrollFromLeft)
      ..dispose();
    _verticalRightController
      ..removeListener(_syncVerticalScrollFromRight)
      ..dispose();
    super.dispose();
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
      final result = await ref
          .read(businessDirectoriesNotifierProvider.notifier)
          .fetchAllBusinesses();
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const actionsWidth = 260.0;
          final availableLeftWidth =
              math.max(0.0, constraints.maxWidth - actionsWidth);
          final leftContentWidth =
              math.max(availableLeftWidth, _minLeftTableWidth());

          final Widget body = _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text('Error: $_error'))
                  : _businesses.isEmpty
                      ? const Center(child: Text('No businesses found'))
                      : Row(
                          children: [
                            Expanded(
                              child: Scrollbar(
                                controller: _horizontalBodyController,
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _horizontalBodyController,
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints.tightFor(
                                      width: leftContentWidth,
                                    ),
                                    child: ListView.builder(
                                      controller: _verticalLeftController,
                                      itemCount: _businesses.length,
                                      itemBuilder: (context, index) {
                                        return _buildLeftRow(
                                          _businesses[index],
                                          categoryIdToName,
                                          index: index,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: actionsWidth,
                              child: ListView.builder(
                                controller: _verticalRightController,
                                itemCount: _businesses.length,
                                itemBuilder: (context, index) {
                                  return _buildActionsRow(
                                    _businesses[index],
                                    categoryIdToName,
                                  );
                                },
                              ),
                            ),
                          ],
                        );

          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _horizontalHeaderController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints.tightFor(width: leftContentWidth),
                        child: _buildLeftHeader(),
                      ),
                    ),
                  ),
                  _buildActionsHeader(actionsWidth),
                ],
              ),
              Expanded(child: body),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F2ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _colCheckbox,
            child: Checkbox(
              value: false,
              onChanged: (value) {},
              shape: const CircleBorder(),
              fillColor: MaterialStateProperty.all(Colors.white),
              side: const BorderSide(color: Color(0xFFBCBCBC)),
            ),
          ),
          _buildHeaderCellFixed('#', width: _colIndex),
          _buildHeaderCellFixed('Business Name', width: _colBusinessName),
          _buildHeaderCellFixed('Owner Name', width: _colOwner),
          _buildHeaderCellFixed('Category', width: _colCategory),
          _buildHeaderCellFixed('Industry', width: _colIndustry),
          _buildHeaderCellFixed('Company Type', width: _colCompanyType),
          _buildHeaderCellFixed('ISP', width: _colIsp),
          _buildHeaderCellFixed('Slogan', width: _colSlogan),
          _buildHeaderCellFixed('Join Date', width: _colJoinDate),
          _buildHeaderCellFixed('HQ (City)', width: _colHqCity),
          _buildHeaderCellFixed('HQ (Country)', width: _colHqCountry),
          _buildHeaderCellFixed('Revenue', width: _colRevenue),
          _buildHeaderCellFixed('Employees', width: _colEmployees),
          _buildHeaderCellFixed('Products', width: _colProducts),
          _buildHeaderCellFixed('Services', width: _colServices),
          _buildHeaderCellFixed('Serving Areas', width: _colServingAreas),
          _buildHeaderCellFixed('Website', width: _colWebsite),
          _buildHeaderCellFixed('Status', width: _colStatus),
        ],
      ),
    );
  }

  Widget _buildActionsHeader(double width) {
    return Container(
      width: width,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F2ED),
        borderRadius: BorderRadius.only(topRight: Radius.circular(16)),
      ),
      alignment: Alignment.centerLeft,
      child: const Text(
        'Actions',
        style: TextStyle(
          color: Color(0xFF333333),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHeaderCellFixed(String text, {required double width}) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.unfold_more, size: 16, color: Color(0xFF333333)),
        ],
      ),
    );
  }

  Widget _buildLeftRow(
    BusinessModel business,
    Map<String, String> categoryIdToName, {
    required int index,
  }) {
    // Lookup category name from map; fallback to ID if not found
    final categoryName = categoryIdToName[business.businessCategoryId] ??
        business.businessCategoryId;
    // You can adjust these mappings as needed
    final status = business.authorizedUser ? 'Approved' : 'Pending';
    final statusColor = business.authorizedUser
        ? const Color(0xFF80C02A).withOpacity(0.2)
        : const Color(0xFFD59823).withOpacity(0.2);

    final hqCity = business.hqLocation.city;
    final hqCountry = business.hqLocation.country;
    final ispText = business.isIsp ? 'Yes' : 'No';
    final productsText = _previewList(business.products);
    final servicesText = _previewList(business.services);
    final servingAreasText = _previewList(business.servingAreas);
    final websiteText =
        business.websiteLinks.isEmpty ? '-' : business.websiteLinks.first;
    final revenueText = business.lastYearRevenue;
    final employeesText = business.employeeCount.toString();

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
            width: _colCheckbox,
            child: Checkbox(
              value: false,
              onChanged: (value) {},
              shape: const CircleBorder(),
              fillColor: MaterialStateProperty.all(Colors.white),
              side: const BorderSide(color: Color(0xFFBCBCBC)),
            ),
          ),
          _buildCellFixed(
            '${index + 1}',
            width: _colIndex,
            fontWeight: FontWeight.w400,
          ),
          // Business Name
          _buildCellFixed(business.businessName,
              width: _colBusinessName, fontWeight: FontWeight.w400),
          // Owner Name
          _buildCellFixed(business.accountOwnerUsername,
              width: _colOwner, fontWeight: FontWeight.w400),
          // Category (show name instead of ID)
          _buildCellFixed(categoryName,
              width: _colCategory, fontWeight: FontWeight.w700),
          _buildCellFixed(business.industry,
              width: _colIndustry, fontWeight: FontWeight.w400),
          _buildCellFixed(business.companyType,
              width: _colCompanyType, fontWeight: FontWeight.w400),
          _buildCellFixed(ispText, width: _colIsp, fontWeight: FontWeight.w400),
          _buildCellFixed(business.slogan,
              width: _colSlogan, fontWeight: FontWeight.w400),
          // Join Date (not present in model, show foundedYear)
          _buildCellFixed(business.foundedYear,
              width: _colJoinDate, fontWeight: FontWeight.w400),
          _buildCellFixed(hqCity,
              width: _colHqCity, fontWeight: FontWeight.w400),
          _buildCellFixed(hqCountry,
              width: _colHqCountry, fontWeight: FontWeight.w400),
          _buildCellFixed(revenueText,
              width: _colRevenue, fontWeight: FontWeight.w400),
          _buildCellFixed(employeesText,
              width: _colEmployees, fontWeight: FontWeight.w400),
          _buildCellFixed(productsText,
              width: _colProducts, fontWeight: FontWeight.w400),
          _buildCellFixed(servicesText,
              width: _colServices, fontWeight: FontWeight.w400),
          _buildCellFixed(servingAreasText,
              width: _colServingAreas, fontWeight: FontWeight.w400),
          _buildCellFixed(websiteText,
              width: _colWebsite, fontWeight: FontWeight.w400),
          // Status
          SizedBox(
            width: _colStatus,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(
    BusinessModel business,
    Map<String, String> categoryIdToName,
  ) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Tooltip(
            message: 'View',
            child: IconButton(
              onPressed: () => _showBusinessDetails(business, categoryIdToName),
              icon: const Icon(Icons.visibility_outlined),
              color: const Color(0xFF333333),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
          ),
          if (!business.authorizedUser)
            Tooltip(
              message: 'Verify',
              child: IconButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(businessDirectoriesNotifierProvider.notifier)
                        .verifyBusiness(business.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Business verified successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                    await _fetchBusinesses();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to verify: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.verified_rounded),
                color: const Color(0xFF80C02A),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints.tightFor(width: 36, height: 36),
              ),
            ),
          Tooltip(
            message: 'Edit',
            child: IconButton(
              onPressed: () {
                // TODO: wire edit flow
              },
              icon: const Icon(Icons.edit_outlined),
              color: const Color(0xFF333333),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
          ),
          Tooltip(
            message: 'Delete',
            child: IconButton(
              onPressed: () {
                // TODO: wire delete flow
              },
              icon: const Icon(Icons.delete_outline),
              color: const Color(0xFFC02A2A),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCellFixed(String text,
      {required double width, required FontWeight fontWeight}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF1E293B),
          fontSize: 16,
          fontWeight: fontWeight,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
