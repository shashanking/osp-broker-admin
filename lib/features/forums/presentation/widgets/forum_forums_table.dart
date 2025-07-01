import 'package:flutter/material.dart';

import '../../domain/forum_models.dart';

class ForumForumsTable extends StatelessWidget {
  final List<Forum> forums;
  const ForumForumsTable({Key? key, required this.forums}) : super(key: key);

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
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Forum Name', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                Expanded(flex: 5, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                Expanded(child: Text('Author', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.left)),
                Expanded(child: Text('Topics', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.left)),
                Expanded(child: Text('Created', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.left)),
              ],
            ),
          ),
          const Divider(height: 32),
          ...forums.map((forum) => _ForumRow(forum: forum)).toList(),
        ],
      ),
    );
  }
}

class _ForumRow extends StatelessWidget {
  final Forum forum;
  const _ForumRow({required this.forum});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              forum.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              forum.description,
              style: const TextStyle(color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              forum.author,
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              (forum.count['topics'] ?? 0).toString(),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              forum.createdAt.toIso8601String().substring(0, 10),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
