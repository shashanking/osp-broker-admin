import 'dart:convert';

import 'package:flutter/material.dart';

import '../../domain/forum_models.dart';
import '../pages/topic_detail_page.dart';

String _stripHtml(String input) {
  // Remove tags
  var text = input.replaceAll(RegExp(r'<[^>]*>'), ' ');
  // Decode a few common entities without adding dependencies
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  // Collapse whitespace
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return text;
}

String _quillDeltaToText(dynamic decoded) {
  // Quill delta is typically a List of ops: [{'insert': 'text'}, ...]
  if (decoded is! List) return '';
  final buffer = StringBuffer();
  for (final op in decoded) {
    if (op is Map) {
      final insert = op['insert'];
      if (insert is String) {
        buffer.write(insert);
      }
    }
  }
  return buffer.toString();
}

String _contentPreview(String raw) {
  final content = raw.trim();
  if (content.isEmpty) return '';

  // Try Quill delta JSON first
  if ((content.startsWith('[') && content.endsWith(']')) ||
      (content.startsWith('{') && content.endsWith('}'))) {
    try {
      final decoded = jsonDecode(content);
      // Some APIs wrap delta under {"ops": [...]}
      final delta =
          (decoded is Map && decoded['ops'] != null) ? decoded['ops'] : decoded;
      final text = _quillDeltaToText(delta);
      if (text.trim().isNotEmpty) {
        return text.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    } catch (_) {
      // Not valid JSON; fall through
    }
  }

  // If it looks like HTML, strip tags
  if (content.contains('<') && content.contains('>')) {
    return _stripHtml(content);
  }

  // Plain text
  return content;
}

class ForumTopicsTable extends StatelessWidget {
  final List<Topic> topics;
  final List<Forum> forums;
  const ForumTopicsTable(
      {super.key, required this.topics, required this.forums});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEDF1FA), Color(0xFFD6E4FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 2,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 1,
                  child: SizedBox(width: 40),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Title',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Content',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Forum',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                Expanded(
                  child: Text('Views',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                Expanded(
                  child: Text('Comments',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                Expanded(
                  child: Text('Created',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                Expanded(
                  child: Text('Updated',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
              ],
            ),
          ),
          const Divider(height: 0, thickness: 1, color: Color(0xFFE9EDF5)),
          ...topics.asMap().entries.map((entry) {
            final idx = entry.key;
            final topic = entry.value;
            return _TopicRow(
              topic: topic,
              forums: forums,
              rowColor: idx % 2 == 0 ? const Color(0xFFF7F9FC) : Colors.white,
            );
          }),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final Topic topic;
  final List<Forum> forums;
  final Color? rowColor;
  const _TopicRow({required this.topic, required this.forums, this.rowColor});

  @override
  Widget build(BuildContext context) {
    final forumName = forums
        .firstWhere(
          (f) => f.id == topic.forumId,
          orElse: () => Forum(
            id: topic.forumId,
            title: 'Unknown Forum',
            description: '',
            categoryId: '',
            userId: '',
            author: '',
            comments: 0,
            isDeleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            topics: const [],
            count: {},
          ),
        )
        .title;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        color: rowColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.blue.withOpacity(0.06),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicDetailPage(
                  topic: topic,
                  forumName: forumName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                // Icon/avatar
                Expanded(
                  flex: 1,
                  child: const CircleAvatar(
                    backgroundColor: Color(0xFFEDF1FA),
                    radius: 18,
                    child:
                        Icon(Icons.forum, color: Color(0xFFB0B8C1), size: 18),
                  ),
                ),
                // Title
                Expanded(
                  flex: 2,
                  child: Text(
                    topic.title,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Content
                Expanded(
                  flex: 2,
                  child: Text(
                    _contentPreview(topic.content),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
                // Forum
                Expanded(
                  flex: 2,
                  child: Text(
                    forums
                        .firstWhere(
                          (f) => f.id == topic.forumId,
                          orElse: () => Forum(
                            id: topic.forumId,
                            title: 'No Forum Found',
                            description: '',
                            categoryId: '',
                            userId: '',
                            author: '',
                            comments: 0,
                            isDeleted: false,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            topics: const [],
                            count: {},
                          ),
                        )
                        .title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Views
                Expanded(
                  child: Text(
                    topic.views.toString(),
                    textAlign: TextAlign.left,
                  ),
                ),
                // Comments
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.comment_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        topic.comments.length.toString(),
                        textAlign: TextAlign.left,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                // Created
                Expanded(
                  child: Text(
                    topic.createdAt.toIso8601String().substring(0, 10),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.left,
                  ),
                ),
                // Updated
                Expanded(
                  child: Text(
                    topic.updatedAt.toIso8601String().substring(0, 10),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
