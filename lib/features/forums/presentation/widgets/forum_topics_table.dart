import 'package:flutter/material.dart';
import '../../domain/forum_models.dart';

import '../../domain/forum_models.dart';

class ForumTopicsTable extends StatelessWidget {
  final List<Topic> topics;
  final List<Forum> forums;
  const ForumTopicsTable({Key? key, required this.topics, required this.forums})
      : super(key: key);

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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
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
                Expanded(
                    flex: 2,
                    child: Text('Title',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54))),
                Expanded(
                    child: Text('Content',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54))),
                Expanded(
                    child: Text('Forum',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54))),
                Expanded(
                    child: Text('Views',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54))),
                Expanded(
                    child: Text('Comments',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54))),
                Expanded(
                    child: Text('Created',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54))),
                Expanded(
                    child: Text('Updated',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54))),
              ],
            ),
          ),
          const Divider(height: 32),
          ...topics
              .map((topic) => _TopicRow(topic: topic, forums: forums))
              .toList(),
        ],
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final Topic topic;
  final List<Forum> forums;
  const _TopicRow({required this.topic, required this.forums});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              topic.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              topic.content,
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
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
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      topics: [],
                      count: {},
                    ),
                  )
                  .title,
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              topic.views.toString(),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              topic.comments.length.toString(),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              topic.createdAt.toIso8601String().substring(0, 10),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Text(
              topic.updatedAt.toIso8601String().substring(0, 10),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}
