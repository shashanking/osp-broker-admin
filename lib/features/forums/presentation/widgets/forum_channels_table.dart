import 'package:flutter/material.dart';

import '../../domain/forum_models.dart';

/// Read-only table of the fixed, membership-bound channels.
/// Styling is copied 1:1 from [ForumForumsTable] (same container, header
/// gradient, row striping, pill chrome). No edit/delete affordances.
class ForumChannelsTable extends StatelessWidget {
  final List<Channel> channels;
  const ForumChannelsTable({super.key, required this.channels});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7F8FA), Color(0xFFE4ECF7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: const [
                Expanded(
                    flex: 1,
                    child: Text('Icon',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 3,
                    child: Text('Channel Name',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 2,
                    child: Text('Level',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 2,
                    child: Text('Visibility',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 1,
                    child: Text('Topics',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 1,
                    child: Text('Comments',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 1,
                    child: Text('Views',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 1,
                    child: Text('Likes',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
                Expanded(
                    flex: 2,
                    child: Text('Created',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222B45),
                            fontSize: 16,
                            letterSpacing: 0.2))),
              ],
            ),
          ),
          // Rows
          ...channels.asMap().entries.map((entry) {
            final idx = entry.key;
            final channel = entry.value;
            return Column(
              children: [
                _ChannelRow(
                  channel: channel,
                  rowColor:
                      idx % 2 == 0 ? const Color(0xFFF7F9FC) : Colors.white,
                ),
                if (idx != channels.length - 1)
                  const Divider(
                      height: 0, thickness: 1, color: Color(0xFFE9EDF5)),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _ChannelRow extends StatelessWidget {
  final Channel channel;
  final Color? rowColor;
  const _ChannelRow({required this.channel, this.rowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: rowColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Icon/avatar
            Expanded(
              flex: 1,
              child: const CircleAvatar(
                backgroundColor: Color(0xFFEDF1FA),
                radius: 22,
                child: Icon(Icons.forum, color: Color(0xFFB0B8C1), size: 22),
              ),
            ),
            // Name
            Expanded(
              flex: 3,
              child: Text(
                channel.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            // Level / tier
            Expanded(
              flex: 2,
              child: Text(
                'Tier ${channel.level}',
                style: const TextStyle(
                    color: Colors.blueGrey, fontWeight: FontWeight.w500),
              ),
            ),
            // Visibility pill (reuses the existing badge pill chrome)
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    channel.isPublic ? 'Public' : 'Members',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            // Topics count
            Expanded(
              flex: 1,
              child: Text(
                channel.topicCount.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            // Comments count
            Expanded(
              flex: 1,
              child: Text(
                channel.commentCount.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            // Views count
            Expanded(
              flex: 1,
              child: Text(
                channel.viewCount.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            // Likes count
            Expanded(
              flex: 1,
              child: Text(
                channel.likeCount.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            // Created
            Expanded(
              flex: 2,
              child: Text(
                channel.createdAt.toIso8601String().substring(0, 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
