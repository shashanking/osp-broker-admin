import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:osp_broker_admin/features/users/data/models/user_model.dart';
import 'package:osp_broker_admin/features/users/data/models/user_membership_model.dart';
import 'package:osp_broker_admin/features/users/application/user_notifier.dart';
import 'package:osp_broker_admin/features/chat/presentation/pages/chat_screen.dart';
import 'package:osp_broker_admin/features/users/presentation/widgets/user_pins_section.dart';
import 'package:timeago/timeago.dart' as timeago;

class UserDetailPage extends ConsumerStatefulWidget {
  final String userId;
  final String userName;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  ConsumerState<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends ConsumerState<UserDetailPage> {
  UserModel? _userProfile;
  List<UserMembershipModel> _memberships = [];
  Map<String, dynamic>? _profileDetails;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch user profile, memberships, and profile details
      final profile = await ref
          .read(userNotifierProvider.notifier)
          .fetchUserProfile(widget.userId);

      final memberships = await ref
          .read(userNotifierProvider.notifier)
          .getUserMemberships(widget.userId);

      final profileDetails = await ref
          .read(userNotifierProvider.notifier)
          .fetchUserProfileDetails(widget.userId);

      if (mounted) {
        setState(() {
          _userProfile = profile;
          _memberships = memberships;
          _profileDetails = profileDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        backgroundColor: const Color(0xFF24439B),
        foregroundColor: Colors.white,
        actions: [
          // Chat button
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat with user',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    recipientId: widget.userId,
                    recipientName: widget.userName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $_error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _userProfile == null
          ? const Center(child: Text('User not found'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Profile Card
                  _buildProfileCard(),
                  const SizedBox(height: 24),

                  // Account Information
                  _buildAccountInfoCard(),
                  const SizedBox(height: 24),

                  // Profile Details Section
                  if (_profileDetails != null) ...[
                    _buildProfileDetailsSection(),
                    const SizedBox(height: 24),
                  ],

                  // Memberships Section
                  _buildMembershipsSection(),
                  const SizedBox(height: 24),

                  // Pins Section
                  UserPinsSection(
                    userId: widget.userId,
                    userName: widget.userName,
                  ),
                  const SizedBox(height: 24),

                  // Actions Section
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
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
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF24439B),
            child: Text(
              _userProfile!.fullName.isNotEmpty
                  ? _userProfile!.fullName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 24),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _userProfile!.fullName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildStatusBadge(),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      _userProfile!.email,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      _userProfile!.phone,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _userProfile!.isBanned
            ? Colors.red.shade50
            : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _userProfile!.isBanned
              ? Colors.red.shade200
              : Colors.green.shade200,
        ),
      ),
      child: Text(
        _userProfile!.isBanned ? 'BANNED' : 'ACTIVE',
        style: TextStyle(
          color: _userProfile!.isBanned
              ? Colors.red.shade700
              : Colors.green.shade700,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard() {
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
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildInfoRow('User ID', _userProfile!.id),
          const SizedBox(height: 12),
          _buildInfoRow('Role', _userProfile!.role),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Account Created',
            timeago.format(_userProfile!.createdAt),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Last Updated',
            timeago.format(_userProfile!.updatedAt),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipsSection() {
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
              const Icon(
                Icons.card_membership,
                color: Color(0xFF24439B),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Memberships',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Text(
                '${_memberships.length} active',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          if (_memberships.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.card_membership_outlined,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No memberships found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._memberships.map(
              (membership) => _buildMembershipCard(membership),
            ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(UserMembershipModel membership) {
    final isActive = membership.status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Membership Plan ID: ${membership.membershipPlanId}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  membership.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'Start: ${membership.startDate.toString().split(' ')[0]}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(width: 16),
              Icon(Icons.event, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                'End: ${membership.endDate.toString().split(' ')[0]}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
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
          const Text(
            'Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                          _userProfile!.isBanned ? 'Unban User' : 'Ban User',
                        ),
                        content: Text(
                          'Are you sure you want to ${_userProfile!.isBanned ? 'unban' : 'ban'} ${_userProfile!.fullName}?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _userProfile!.isBanned
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            child: Text(
                              _userProfile!.isBanned ? 'Unban' : 'Ban',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      try {
                        // currently banned → unban; otherwise ban
                        final notifier =
                            ref.read(userNotifierProvider.notifier);
                        if (_userProfile!.isBanned) {
                          await notifier.unbanUser(widget.userId);
                        } else {
                          await notifier.banUser(widget.userId);
                        }
                        _loadUserData(); // Reload data
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _userProfile!.isBanned
                                    ? 'User unbanned successfully'
                                    : 'User banned successfully',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: Icon(
                    _userProfile!.isBanned ? Icons.check_circle : Icons.block,
                  ),
                  label: Text(
                    _userProfile!.isBanned ? 'Unban User' : 'Ban User',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _userProfile!.isBanned
                        ? Colors.green
                        : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          recipientId: widget.userId,
                          recipientName: widget.userName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Start Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF24439B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailsSection() {
    final userProfile =
        _profileDetails?['userProfile'] as Map<String, dynamic>?;
    if (userProfile == null) return const SizedBox.shrink();

    final headline = userProfile['headLine'] as String? ?? '';
    final location = userProfile['location'] as String? ?? '';
    final about = userProfile['about'] as String? ?? '';
    final skills = (userProfile['skills'] as List?)?.cast<String>() ?? [];
    final education =
        (userProfile['education'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final experience =
        (userProfile['experience'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    final profileImageUrl = userProfile['profileImageUrl'] as String?;

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
          const Text(
            'Profile Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // Profile Image
          if (profileImageUrl != null && profileImageUrl.isNotEmpty) ...[
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(profileImageUrl),
                onBackgroundImageError: (_, __) {},
                child: profileImageUrl.contains('placeholder')
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Headline
          if (headline.isNotEmpty) ...[
            _buildInfoRow('Headline', headline),
            const SizedBox(height: 12),
          ],

          // Location
          if (location.isNotEmpty) ...[
            _buildInfoRow('Location', location),
            const SizedBox(height: 12),
          ],

          // About
          if (about.isNotEmpty) ...[
            const Text(
              'About',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              about,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 12),
          ],

          // Skills
          if (skills.isNotEmpty) ...[
            const Text(
              'Skills',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map(
                    (skill) => Chip(
                      label: Text(skill),
                      backgroundColor: Colors.blue.shade50,
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Education
          if (education.isNotEmpty) ...[
            const Text(
              'Education',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...education.map(
              (edu) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edu['degree'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${edu['school']} - ${edu['fieldOfStudy']}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    Text(
                      '${edu['startYear']} - ${edu['endYear']} | Grade: ${edu['grade']}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Experience
          if (experience.isNotEmpty) ...[
            const Text(
              'Experience',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            ...experience.map(
              (exp) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exp['company']} - ${exp['location']}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    if (exp['description'] != null &&
                        exp['description'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          exp['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
