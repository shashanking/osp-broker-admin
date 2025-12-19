import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auction_notifier.dart';
import 'auction_detail_screen.dart';
import 'dart:io';
import 'dart:math';

class AuctionScreen extends ConsumerStatefulWidget {
  const AuctionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends ConsumerState<AuctionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auctionNotifierProvider.notifier).loadCategories();
      ref.read(auctionNotifierProvider.notifier).loadAuctions();
    });
  }

  Future<void> _loadData() async {
    await ref.read(auctionNotifierProvider.notifier).refreshData();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auctionNotifierProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Auctions'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Categories'),
              Tab(text: 'Auctions'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildCategoriesTab(),
            _buildAuctionsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final state = ref.watch(auctionNotifierProvider);

    if (state.isLoadingCategories && state.categories.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.categories.isEmpty) {
      return Center(child: Text('Error: ${state.error}'));
    }

    final categories = state.categories;
    final categoryCount = categories.length;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(auctionNotifierProvider.notifier).loadCategories(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Categories: $categoryCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showCreateCategoryDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Category'),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(category.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created: ${category.createdAt.day}/${category.createdAt.month}/${category.createdAt.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          _showEditCategoryDialog(category);
                        },
                        color: Colors.blue,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () {
                          _showDeleteCategoryDialog(category);
                        },
                        color: Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildAuctionsTab() {
    final state = ref.watch(auctionNotifierProvider);

    if (state.isLoadingAuctions && state.auctions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.auctions.isEmpty) {
      return Center(child: Text('Error: ${state.error}'));
    }

    final auctions = state.auctions;
    final auctionCount = auctions.length;

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(auctionNotifierProvider.notifier).loadAuctions(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Auctions: $auctionCount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showCreateAuctionDialog();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Auction'),
                ),
              ],
            ),
          ),
          Expanded(
            child: auctions.isEmpty
                ? const Center(child: Text('No auctions found'))
                : ListView.builder(
                    itemCount: auctions.length,
                    itemBuilder: (context, index) {
                      final auction = auctions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => AuctionDetailScreen(auctionId: auction.id),
                              ),
                            );
                          },
                          child: ListTile(
                            leading: _buildStatusIndicator(auction),
                            title: Row(
                              children: [
                                Expanded(child: Text(auction.title)),
                                if (auction.isDeleted)
                                  const Chip(
                                    label: Text('Soft Deleted', style: TextStyle(fontSize: 10)),
                                    backgroundColor: Colors.orange,
                                    labelStyle: TextStyle(color: Colors.white),
                                    padding: EdgeInsets.symmetric(horizontal: 4),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                if (_isAuctionCompleted(auction))
                                  const Padding(
                                    padding: EdgeInsets.only(left: 4),
                                    child: Chip(
                                      label: Text('Completed', style: TextStyle(fontSize: 10)),
                                      backgroundColor: Colors.grey,
                                      labelStyle: TextStyle(color: Colors.white),
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getPlainTextFromDescription(auction.description),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Categories: ${auction.categoryIds.length}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Approved: ${auction.approved ? 'Yes' : 'No'}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: auction.approved
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!auction.approved)
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: () {
                                      _approveAuction(auction);
                                    },
                                    tooltip: 'Approve',
                                  ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _showDeleteAuctionDialog(auction);
                                  },
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCreateCategoryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                try {
                  await ref
                      .read(auctionNotifierProvider.notifier)
                      .createCategory(
                        name: nameController.text,
                        description: descriptionController.text,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Category created successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Error creating category: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(category) {
    final nameController = TextEditingController(text: category.name);
    final descriptionController =
        TextEditingController(text: category.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  descriptionController.text.isNotEmpty) {
                try {
                  await ref
                      .read(auctionNotifierProvider.notifier)
                      .updateCategory(
                        id: category.id,
                        name: nameController.text,
                        description: descriptionController.text,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Category updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Error creating category: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(auctionNotifierProvider.notifier)
                    .deleteCategory(category.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Category deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Error deleting category: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateAuctionDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final startingBidController = TextEditingController();
    final selectedCategories = <String>{};
    final selectedImages = <dynamic>[];

    // Time frame state - default to tomorrow
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Auction'),
          content: Container(
            width: double.minPositive,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              minWidth: MediaQuery.of(context).size.width * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: startingBidController,
                    decoration: const InputDecoration(
                      labelText: 'Starting Bid',
                      hintText: 'Enter starting bid amount',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Categories:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(auctionNotifierProvider);
                      return state.isLoadingCategories
                          ? const SizedBox(
                              height: 50,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : SizedBox(
                              height: 100,
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: state.categories.map((category) {
                                    final isSelected = selectedCategories
                                        .contains(category.id);
                                    return FilterChip(
                                      label: Text(category.name),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedCategories.add(category.id);
                                          } else {
                                            selectedCategories
                                                .remove(category.id);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Auction End Date & Time:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      'Select Date & Time\n${selectedDateTime.toString().split('.')[0]}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Media Files:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                        allowMultiple: true,
                      );
                      if (result != null) {
                        setState(() {
                          selectedImages
                              .addAll(result.files.map((file) => file));
                        });
                      }
                    },
                    icon: const Icon(Icons.image),
                    label: const Text('Select Images'),
                  ),
                  if (selectedImages.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text('Selected ${selectedImages.length} image(s)'),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedImages.length,
                            itemBuilder: (context, index) {
                              final file = selectedImages[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    // Handle both File (mobile) and PlatformFile (web)
                                    if (file is File)
                                      Image.file(
                                        file,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    else if (file is PlatformFile &&
                                        file.bytes != null)
                                      // For web, show a placeholder or filename
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.image,
                                            size: 40, color: Colors.grey),
                                      )
                                    else
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Text(
                                            (file.name ?? 'File').substring(
                                                0,
                                                min<int>(
                                                    10,
                                                    (file.name ?? 'File')
                                                        .length)),
                                            style:
                                                const TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: IconButton(
                                        icon: const Icon(Icons.remove_circle,
                                            color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            selectedImages.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedCategories.isEmpty ||
                      titleController.text.isEmpty
                  ? null
                  : () async {
                      if (titleController.text.isNotEmpty &&
                          descriptionController.text.isNotEmpty &&
                          selectedCategories.isNotEmpty &&
                          startingBidController.text.isNotEmpty) {
                        try {
                          // TODO: Upload images to AWS S3 and get URLs
                          final imageUrls =
                              await _uploadImagesToS3(selectedImages);

                          await ref
                              .read(auctionNotifierProvider.notifier)
                              .createAuction(
                                title: titleController.text,
                                description: descriptionController.text,
                                categoryIds: selectedCategories.toList(),
                                timeFrame: selectedDateTime
                                        .toUtc()
                                        .toIso8601String()
                                        .split('.')[0] +
                                    'Z', // ISO format without milliseconds for Prisma
                                files: imageUrls,
                                startingBid:
                                    int.parse(startingBidController.text),
                              );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Auction created successfully')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Error creating auction: ${e.toString()}')),
                          );
                        }
                      }
                    },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _uploadImagesToS3(List<dynamic> images) async {
    // TODO: Implement AWS S3 upload
    // For now, return empty list or placeholder URLs
    // This should be implemented based on your AWS S3 configuration
    return [];
  }

  void _approveAuction(auction) async {
    try {
      await ref
          .read(auctionNotifierProvider.notifier)
          .approveAuction(auction.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auction approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Error approving auction: ${e.toString()}')),
      );
    }
  }

  void _showDeleteAuctionDialog(auction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Auction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose deletion type for "${auction.title}":'),
            const SizedBox(height: 16),
            const Text(
              'Soft Delete: Hides the auction but keeps it in database',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hard Delete: Permanently removes the auction',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(auctionNotifierProvider.notifier)
                    .softDeleteAuction(auction.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auction soft deleted successfully')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Error soft deleting auction: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Soft Delete'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(auctionNotifierProvider.notifier)
                    .hardDeleteAuction(auction.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auction permanently deleted')),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Error deleting auction: ${e.toString()}')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hard Delete'),
          ),
        ],
      ),
    );
  }

  /// Check if auction is completed (timeFrame has passed or winner selected)
  bool _isAuctionCompleted(auction) {
    // Check if timeFrame has passed
    if (auction.timeFrame.isBefore(DateTime.now())) {
      return true;
    }
    
    // Check if a winner has been selected by loading bids for this auction
    // Note: This is a simplified check. For better performance, consider adding
    // a 'hasWinner' field to the Auction model from the backend
    final state = ref.read(auctionNotifierProvider);
    
    // If we have the selected auction and its bids loaded, check for matched bids
    if (state.selectedAuction?.id == auction.id) {
      return state.bids.any((bid) => bid.matched);
    }
    
    // Default to time-based completion only
    return false;
  }

  /// Build status indicator icon
  Widget _buildStatusIndicator(auction) {
    if (auction.isDeleted) {
      return const CircleAvatar(
        backgroundColor: Colors.orange,
        radius: 20,
        child: Icon(Icons.visibility_off, color: Colors.white, size: 20),
      );
    } else if (_isAuctionCompleted(auction)) {
      return const CircleAvatar(
        backgroundColor: Colors.grey,
        radius: 20,
        child: Icon(Icons.check_circle, color: Colors.white, size: 20),
      );
    } else if (!auction.approved) {
      return const CircleAvatar(
        backgroundColor: Colors.red,
        radius: 20,
        child: Icon(Icons.pending, color: Colors.white, size: 20),
      );
    } else {
      return const CircleAvatar(
        backgroundColor: Colors.green,
        radius: 20,
        child: Icon(Icons.gavel, color: Colors.white, size: 20),
      );
    }
  }

  /// Extract plain text from Quill JSON description
  String _getPlainTextFromDescription(String description) {
    try {
      final deltaJson = jsonDecode(description);
      if (deltaJson is List) {
        // Extract text from ops array
        final buffer = StringBuffer();
        for (final op in deltaJson) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        return buffer.toString().trim();
      }
      return description;
    } catch (e) {
      // Fallback to original description if parsing fails
      return description;
    }
  }
}
