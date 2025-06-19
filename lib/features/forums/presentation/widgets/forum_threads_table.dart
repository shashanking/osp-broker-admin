import 'package:flutter/material.dart';

class ForumThreadsTable extends StatelessWidget {
  final List<Map<String, dynamic>> threads;
  const ForumThreadsTable({Key? key, required this.threads}) : super(key: key);

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
          // Header row
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
                SizedBox(width: 32, child: Checkbox(value: false, onChanged: null)),
                Expanded(flex: 3, child: Text('Title', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), textAlign: TextAlign.left)),
                Expanded(flex: 2, child: Text('Author', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), textAlign: TextAlign.left)),
                Expanded(flex: 1, child: Text('Likes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), textAlign: TextAlign.left)),
                Expanded(flex: 2, child: Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), textAlign: TextAlign.left)),
                Expanded(flex: 1, child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), textAlign: TextAlign.left)),
                Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), textAlign: TextAlign.left)),
                Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), textAlign: TextAlign.left)),
                Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13), textAlign: TextAlign.left)),
              ],
            ),
          ),
          const Divider(height: 0),
          // Table rows
          ...threads.map((thread) => _ForumThreadRow(thread: thread)).toList(),
        ],
      ),
    );
  }
}

class _ForumThreadRow extends StatelessWidget {
  final Map<String, dynamic> thread;
  const _ForumThreadRow({required this.thread});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: thread['selected'] as bool,
              onChanged: (v) {},
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              thread['title'] as String,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              thread['author'] as String,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              thread['likes'].toString(),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              thread['comments'].toString(),
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              thread['date'] as String,
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (thread['isPrivate'] as bool) ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                thread['category'] as String,
                style: TextStyle(
                  color: (thread['isPrivate'] as bool) ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (thread['isPrivate'] as bool) ? Colors.red[50] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                thread['status'] as String,
                style: TextStyle(
                  color: (thread['isPrivate'] as bool) ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF232323),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Manage'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
