import 'package:flutter/material.dart';

class ForumForumsTable extends StatelessWidget {
  final List<Map<String, dynamic>> forums;
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
                Expanded(child: Text('Threads', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.left)),
                Expanded(child: Text('Posts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.left)),
                Expanded(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54), textAlign: TextAlign.left)),
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
  final Map<String, dynamic> forum;
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
              forum['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              forum['description'] as String,
              style: const TextStyle(color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              forum['threads'].toString(),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              forum['posts'].toString(),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              forum['status'] as String,
              style: TextStyle(
                color: forum['status'] == 'Private' ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
